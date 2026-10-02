import SwiftUI
import UIKit

/// Initializes services during launch, including an iOS location-event relaunch.
final class AppDelegate: NSObject, UIApplicationDelegate {
    let controller = GeofenceProofController()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationService.shared.install()
        controller.start()
        return true
    }
}

@main
struct UnforgeterApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            GeofenceProofView(controller: appDelegate.controller)
        }
    }
}
