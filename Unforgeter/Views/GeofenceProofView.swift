import CoreLocation
import MapKit
import SwiftUI

struct GeofenceProofView: View {
    @ObservedObject var controller: GeofenceProofController
    @Environment(\.scenePhase) private var scenePhase
    @State private var radius = 200.0
    @State private var confirmRemoval = false
    @State private var position: MapCameraPosition = .automatic

    private var previewCoordinate: CLLocationCoordinate2D? {
        if let zone = controller.zone {
            return CLLocationCoordinate2D(latitude: zone.latitude, longitude: zone.longitude)
        }
        return controller.location?.coordinate
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Remember before you’re too far to turn back.", systemImage: "bell.badge")
                            .font(.headline)
                        Text("Geofence proof · One test zone, all days, all times. Scheduled Rules are the next milestone.")
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 6)
                }

                Section {
                    LabeledContent("Location", value: controller.locationPermissionLabel)
                    LabeledContent("Precise Location", value: controller.fullAccuracy ? "On" : "Off")
                    LabeledContent("Notifications", value: controller.notificationStatus)
                    LabeledContent("Background App Refresh", value: controller.backgroundRefreshAvailable ? "Available" : "Unavailable")
                    if controller.authorization == .notDetermined {
                        Button("1. Allow location while using") { controller.requestLocationPermission() }
                    }
                    if controller.authorization == .authorizedWhenInUse {
                        Button("2. Allow departure detection in background") { controller.requestAlwaysPermission() }
                    }
                    if !controller.notificationsAllowed {
                        Button("Allow notification alerts") { controller.requestNotificationPermission() }
                    }
                    Button("Open app settings", systemImage: "gearshape") {
                        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
                        UIApplication.shared.open(url)
                    }
                } header: {
                    Text("1 · Permissions")
                } footer: {
                    Text("Always location lets iOS report departures when the app is not open. This prototype stores one zone on your phone and requests a single location fix to place it. If a permission prompt no longer appears, use Settings.")
                }

                Section {
                    Button {
                        controller.useCurrentLocation()
                    } label: {
                        Label(controller.locating ? "Finding location…" : "Use my current location", systemImage: "location")
                    }
                    .disabled(controller.locating)

                    if let fix = controller.location {
                        LabeledContent("Location uncertainty", value: "±\(Int(fix.horizontalAccuracy)) m")
                    }
                    Picker("Radius for new zone", selection: $radius) {
                        Text("25 m · experimental").tag(25.0)
                        Text("50 m · experimental").tag(50.0)
                        Text("100 m").tag(100.0)
                        Text("200 m · initial test").tag(200.0)
                        Text("500 m").tag(500.0)
                    }
                    if let coordinate = previewCoordinate {
                        Map(position: $position) {
                            MapCircle(center: coordinate, radius: controller.zone?.radiusMeters ?? radius)
                                .foregroundStyle(.teal.opacity(0.2))
                                .stroke(.teal, lineWidth: 2)
                            Marker("Test zone center", coordinate: coordinate)
                                .tint(.teal)
                        }
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .accessibilityLabel("Map of the test zone and its radius")
                    }
                    Button(controller.zone == nil ? "Arm test zone here" : "Replace zone with current location") {
                        controller.arm(radius: radius)
                        position = .automatic
                    }
                    .disabled(!controller.canArm)
                } header: {
                    Text("2 · Place a test zone")
                } footer: {
                    Text("Start with 200 m for testing. iOS uses a boundary buffer and may deliver events later; no radius guarantees an immediate alert. The map shows the saved zone while armed.")
                }

                Section("3 · Walk outside the zone") {
                    LabeledContent("Monitoring", value: controller.monitoringStatus)
                    LabeledContent("Boundary", value: controller.boundaryState)
                    if let zone = controller.zone {
                        LabeledContent("Saved radius", value: "\(Int(zone.radiusMeters)) m")
                        Text("Wait for Inside, lock your phone, and travel safely beyond the circle. A real exit should queue ‘You left the zone.’ Tap it to open the sample checklist.")
                            .font(.subheadline)
                        Button("Remove test zone", role: .destructive) { confirmRemoval = true }
                    }
                    if !controller.storageHealthy {
                        Text("Saved data could not be used. It has been preserved. Reset only if you want to discard the saved proof zone.")
                            .foregroundStyle(.red)
                        Button("Reset saved proof data", role: .destructive) { confirmRemoval = true }
                    }
                }

                #if DEBUG
                Section {
                    Button("Send simulated departure notification", systemImage: "ladybug") {
                        controller.simulateExit()
                    }
                    .disabled(controller.zone == nil)
                } header: {
                    Text("Developer tools")
                } footer: {
                    Text("Checks notification delivery and checklist opening only. It does not test GPS, background geofencing, or real departure reliability. Excluded from Release builds.")
                }
                #endif

                Section {
                    if controller.events.isEmpty {
                        Text("Events appear here during testing.").foregroundStyle(.secondary)
                    }
                    ForEach(controller.events) { event in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(event.message).font(.subheadline)
                            Text(event.date, format: .dateTime.hour().minute().second())
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Session event log")
                } footer: {
                    Text("The latest 60 events stay in memory for this launch only. Record real test results separately. An event log entry is not proof that a notification was seen.")
                }
            }
            .navigationTitle("Unforgeter")
            .tint(.teal)
            .sheet(item: $controller.checklist) { presentation in
                TriggeredChecklistView(isSimulation: presentation.isSimulation)
                    .id(presentation.id)
            }
            .confirmationDialog("Remove the saved test zone and stop monitoring?", isPresented: $confirmRemoval, titleVisibility: .visible) {
                Button("Remove test zone", role: .destructive) { controller.disarm() }
            }
            .alert("Test needs attention", isPresented: Binding(
                get: { controller.errorMessage != nil },
                set: { if !$0 { controller.errorMessage = nil } }
            )) {
                Button("OK") { controller.errorMessage = nil }
            } message: {
                Text(controller.errorMessage ?? "")
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { controller.refreshPermissions() }
            }
            .onChange(of: controller.location?.timestamp) { _, _ in position = .automatic }
        }
    }
}
