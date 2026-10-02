import Combine
import CoreLocation
import UIKit

/// Ends exactly once, including when iOS expires the available background time.
private final class NotificationBackgroundTask {
    private var identifier: UIBackgroundTaskIdentifier = .invalid
    private(set) var expired = false

    init() {
        identifier = UIApplication.shared.beginBackgroundTask(withName: "Departure notification") { [weak self] in
            self?.expired = true
            self?.end()
        }
    }

    func end() {
        guard identifier != .invalid else { return }
        let active = identifier
        identifier = .invalid
        UIApplication.shared.endBackgroundTask(active)
    }
}

/// Owned for the application's entire lifetime, including a background relaunch.
/// CLLocationManager is created on the main queue and delivers delegates there.
final class GeofenceProofController: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var authorization: CLAuthorizationStatus = .notDetermined
    @Published private(set) var fullAccuracy = false
    @Published private(set) var notificationStatus = "Checking"
    @Published private(set) var notificationsAllowed = false
    @Published private(set) var backgroundRefreshAvailable = false
    @Published private(set) var location: CLLocation?
    @Published private(set) var locating = false
    @Published private(set) var zone: TestZone?
    @Published private(set) var monitoringStatus = "Not armed"
    @Published private(set) var boundaryState = "Unknown"
    @Published private(set) var events: [DiagnosticEvent] = []
    @Published private(set) var storageHealthy = true
    @Published var errorMessage: String?
    @Published var checklist: ChecklistPresentation?

    private let manager = CLLocationManager()
    private let notifications = NotificationService.shared
    private let store = ProofStore()
    private var state = ProofState()
    private var delivering = false
    private var started = false
    private let cooldown: TimeInterval = 300

    var locationPermissionLabel: String {
        switch authorization {
        case .notDetermined: return "Not requested"
        case .restricted: return "Restricted by device policy"
        case .denied: return "Denied — change in Settings"
        case .authorizedWhenInUse: return "While Using — Always needed for this test"
        case .authorizedAlways: return "Always"
        @unknown default: return "Unknown"
        }
    }

    var canArm: Bool {
        storageHealthy && authorization == .authorizedAlways && fullAccuracy
            && notificationsAllowed && backgroundRefreshAvailable
            && CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
            && location != nil
    }

    func start() {
        guard !started else { return }
        started = true
        do {
            state = try store.load()
            zone = state.zone
        } catch {
            storageHealthy = false
            report("Saved test zone could not be read. Monitoring stopped; saved data was preserved.")
        }
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        notifications.onOpen = { [weak self] presentation in
            guard let self else { return }
            guard presentation.zoneID == self.zone?.id.uuidString else {
                self.report("That test zone has been removed. Arm a new zone to test again.")
                return
            }
            self.checklist = presentation
        }
        refreshLocationStatus()
        reconcileMonitoring()
        refreshPermissions()
        log("Prototype started. Core Location events and manual simulations are labeled separately.")
    }

    func refreshPermissions() {
        refreshLocationStatus()
        backgroundRefreshAvailable = UIApplication.shared.backgroundRefreshStatus == .available
        Task { @MainActor [weak self] in
            guard let self else { return }
            let settings = await self.notifications.settings()
            switch settings.authorizationStatus {
            case .authorized: self.notificationStatus = "Allowed"
            case .provisional: self.notificationStatus = "Quiet delivery only"
            case .ephemeral: self.notificationStatus = "Temporary"
            case .denied: self.notificationStatus = "Denied — change in Settings"
            case .notDetermined: self.notificationStatus = "Not requested"
            @unknown default: self.notificationStatus = "Unknown"
            }
            self.notificationsAllowed = settings.authorizationStatus == .authorized
                && settings.alertSetting == .enabled
            if settings.authorizationStatus == .authorized && settings.alertSetting != .enabled {
                self.notificationStatus = "Alerts disabled — change in Settings"
            }
        }
        reconcileMonitoring()
    }

    func requestLocationPermission() { manager.requestWhenInUseAuthorization() }

    func requestAlwaysPermission() {
        guard authorization == .authorizedWhenInUse else { return }
        // An explicit second user action after the initial permission explanation.
        manager.requestAlwaysAuthorization()
    }

    func requestNotificationPermission() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                _ = try await self.notifications.requestPermission()
                self.refreshPermissions()
            } catch {
                self.report("Notification permission failed: \(error.localizedDescription)")
            }
        }
    }

    func useCurrentLocation() {
        guard authorization == .authorizedAlways || authorization == .authorizedWhenInUse else {
            report("Allow location access before choosing the zone center.")
            return
        }
        locating = true
        manager.requestLocation() // One fix only; never runs continuous GPS in background.
    }

    func arm(radius: Double) {
        guard canArm, let location else {
            report("Allow Always location, Precise Location, notifications, and Background App Refresh, then get your current location.")
            return
        }
        guard abs(location.timestamp.timeIntervalSinceNow) < 120 else {
            report("Your location is over two minutes old. Refresh it before arming.")
            return
        }
        guard location.horizontalAccuracy >= 0,
              location.horizontalAccuracy <= radius else {
            report("Location uncertainty exceeds this radius. Wait for a better fix or choose a larger radius.")
            return
        }
        guard radius <= manager.maximumRegionMonitoringDistance else {
            report("That radius exceeds this device's monitoring limit.")
            return
        }
        let candidate = TestZone(
            latitude: location.coordinate.latitude, longitude: location.coordinate.longitude,
            radiusMeters: radius
        )
        guard candidate.isValid else { report("Invalid test zone."); return }
        let nextState = ProofState(zone: candidate, lastRealNotificationAt: nil)
        do {
            try store.save(nextState)
        } catch {
            report("Could not save the test zone: \(error.localizedDescription)")
            return
        }
        if let zone { notifications.clear(zone: zone) }
        state = nextState
        zone = candidate
        boundaryState = "Waiting for state"
        reconcileMonitoring()
        log("Saved a \(Int(radius)) m test zone at the selected current location.")
    }

    func disarm() {
        let nextState = ProofState()
        do {
            try store.save(nextState)
        } catch {
            report("Could not remove saved zone: \(error.localizedDescription)")
            return
        }
        if let zone { notifications.clear(zone: zone) }
        state = nextState
        zone = nil
        checklist = nil
        storageHealthy = true
        boundaryState = "Unknown"
        reconcileMonitoring()
        log("Test zone removed.")
    }

    private func refreshLocationStatus() {
        authorization = manager.authorizationStatus
        fullAccuracy = manager.accuracyAuthorization == .fullAccuracy
    }

    private func reconcileMonitoring() {
        let ours = manager.monitoredRegions.filter { $0.identifier.hasPrefix("unforgeter.proof.") }
        for old in ours where !storageHealthy || old.identifier != zone?.regionIdentifier {
            manager.stopMonitoring(for: old)
        }
        guard storageHealthy, let zone else { monitoringStatus = "Not armed"; return }
        guard authorization == .authorizedAlways && fullAccuracy else {
            for old in ours { manager.stopMonitoring(for: old) }
            monitoringStatus = "Saved — needs Always and Precise Location"
            return
        }
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            monitoringStatus = "Region monitoring unavailable"
            return
        }
        guard zone.radiusMeters <= manager.maximumRegionMonitoringDistance else {
            monitoringStatus = "Saved radius exceeds device limit"
            return
        }
        if let existing = manager.monitoredRegions.first(where: { $0.identifier == zone.regionIdentifier }) {
            monitoringStatus = "Monitoring registered"
            manager.requestState(for: existing)
            return
        }
        guard manager.monitoredRegions.count < 20 else {
            monitoringStatus = "Device's 20-region limit reached"
            return
        }
        let region = CLCircularRegion(
            center: CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude),
            radius: zone.radiusMeters, identifier: zone.regionIdentifier
        )
        region.notifyOnExit = true
        region.notifyOnEntry = true // Records re-entry; only exit sends an alert.
        monitoringStatus = "Registering…"
        manager.startMonitoring(for: region)
    }

    private func handleExit(for region: CLRegion) {
        guard storageHealthy, let zone, region.identifier == zone.regionIdentifier else { return }
        log("CORE LOCATION: Exit callback received. Physical departure must be verified separately.")
        boundaryState = "Outside"
        guard authorization == .authorizedAlways && fullAccuracy else {
            log("Exit ignored: location authorization is not sufficient.")
            return
        }
        guard !delivering else { log("Duplicate ignored: notification in progress."); return }
        let now = Date()
        if let last = state.lastRealNotificationAt, now.timeIntervalSince(last) < cooldown {
            log("Duplicate ignored: five-minute cooldown.")
            return
        }
        delivering = true
        // A short task gives the local notification request time to finish on a background callback.
        let backgroundTask = NotificationBackgroundTask()
        Task { @MainActor [weak self] in
            guard let self else {
                backgroundTask.end()
                return
            }
            defer {
                self.delivering = false
                backgroundTask.end()
            }
            let settings = await self.notifications.settings()
            guard !backgroundTask.expired, self.zone?.id == zone.id else { return }
            guard settings.authorizationStatus == .authorized && settings.alertSetting == .enabled else {
                self.log("Core Location exit received, but notification alerts are disabled.")
                return
            }
            do {
                try await self.notifications.sendExit(zone: zone)
                guard self.zone?.id == zone.id else {
                    self.notifications.clear(zone: zone)
                    return
                }
                self.state.lastRealNotificationAt = now
                do {
                    try self.store.save(self.state)
                } catch {
                    self.report("Notification queued, but cooldown could not be saved. Monitoring stopped to avoid duplicate alerts.")
                    self.storageHealthy = false
                    self.reconcileMonitoring()
                    return
                }
                self.log("CORE LOCATION notification queued. Verify actual banner delivery on the phone.")
            } catch {
                self.report("Could not queue notification: \(error.localizedDescription)")
            }
        }
    }

    #if DEBUG
    func simulateExit() {
        guard let zone else { report("Arm a test zone first."); return }
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                try await self.notifications.sendExit(zone: zone, simulated: true)
                guard self.zone?.id == zone.id else {
                    self.notifications.clear(zone: zone)
                    return
                }
                self.log("SIMULATED notification queued. This does not test Core Location or alter real cooldown.")
            } catch {
                self.report("Simulation failed: \(error.localizedDescription)")
            }
        }
    }
    #endif

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refreshLocationStatus()
        guard started else { return }
        log("Location authorization: \(locationPermissionLabel); precise: \(fullAccuracy).")
        reconcileMonitoring()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locating = false
        guard let fix = locations.last, fix.horizontalAccuracy >= 0,
              abs(fix.timestamp.timeIntervalSinceNow) < 120 else {
            report("No recent location fix. Try again outdoors.")
            return
        }
        location = fix
        log("Location updated; reported uncertainty ±\(Int(fix.horizontalAccuracy)) m.")
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locating = false
        report("Location failed: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        guard storageHealthy, manager.authorizationStatus == .authorizedAlways,
              manager.accuracyAuthorization == .fullAccuracy,
              region.identifier == zone?.regionIdentifier else {
            manager.stopMonitoring(for: region)
            return
        }
        monitoringStatus = "Monitoring registered"
        log("Region registration confirmed. Waiting for inside/outside state.")
        manager.requestState(for: region)
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        guard region.identifier == zone?.regionIdentifier else { return }
        switch state {
        case .inside: boundaryState = "Inside — ready to depart"
        case .outside: boundaryState = "Outside — enter the zone before testing"
        case .unknown: boundaryState = "Unknown — wait for a location fix"
        @unknown default: boundaryState = "Unknown — unsupported state"
        }
        log("State: \(boundaryState). State queries never trigger notifications.")
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard region.identifier == zone?.regionIdentifier else { return }
        boundaryState = "Inside — ready to depart"
        log("CORE LOCATION: Entry callback received. No alert sent.")
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        handleExit(for: region)
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        guard region == nil || region?.identifier == zone?.regionIdentifier else { return }
        monitoringStatus = "Monitoring failed"
        report("Monitoring failed: \(error.localizedDescription)")
    }

    private func report(_ message: String) { errorMessage = message; log(message) }
    private func log(_ message: String) {
        events.insert(DiagnosticEvent(message: message), at: 0)
        if events.count > 60 { events.removeLast(events.count - 60) }
    }
}
