import Foundation
import UserNotifications

final class NotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()
    private let center = UNUserNotificationCenter.current()
    // Accessed on the main queue; retains a cold-launch tap until SwiftUI is ready.
    private var pendingPresentation: ChecklistPresentation?
    var onOpen: ((ChecklistPresentation) -> Void)? {
        didSet {
            if let pendingPresentation, let onOpen {
                onOpen(pendingPresentation)
                self.pendingPresentation = nil
            }
        }
    }

    func install() { center.delegate = self }

    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }

    func settings() async -> UNNotificationSettings {
        await center.notificationSettings()
    }

    func sendExit(zone: TestZone, simulated: Bool = false) async throws {
        let content = UNMutableNotificationContent()
        content.title = simulated ? "Simulated departure" : "You left the zone."
        content.body = "Before you go, double-check: laptop, charger, and keys."
        content.sound = .default
        content.userInfo = ["zoneID": zone.id.uuidString, "simulation": simulated]
        // A stable identifier keeps at most one outstanding proof alert per zone.
        let request = UNNotificationRequest(
            identifier: "\(zone.regionIdentifier).\(simulated ? "simulation" : "exit")",
            content: content, trigger: nil
        )
        try await center.add(request)
    }

    func clear(zone: TestZone) {
        let ids = ["\(zone.regionIdentifier).exit", "\(zone.regionIdentifier).simulation"]
        center.removePendingNotificationRequests(withIdentifiers: ids)
        center.removeDeliveredNotifications(withIdentifiers: ids)
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier,
              let id = response.notification.request.content.userInfo["zoneID"] as? String else {
            completionHandler()
            return
        }
        let simulated = response.notification.request.content.userInfo["simulation"] as? Bool ?? false
        let presentation = ChecklistPresentation(zoneID: id, isSimulation: simulated)
        DispatchQueue.main.async {
            if let onOpen = self.onOpen {
                onOpen(presentation)
            } else {
                self.pendingPresentation = presentation
            }
            completionHandler()
        }
    }
}
