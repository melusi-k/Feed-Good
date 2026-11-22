import Foundation
import SwiftUI
import UserNotifications
import UIKit

struct CareNotificationDestination: Identifiable, Equatable, Hashable {
    let taskID: UUID
    let plantID: UUID
    var id: String { "\(taskID.uuidString):\(plantID.uuidString)" }
}

@MainActor
final class CareNotificationRouter: ObservableObject {
    static let shared = CareNotificationRouter()
    @Published private(set) var destination: CareNotificationDestination?

    init() {}

    func open(userInfo: [AnyHashable: Any]) {
        guard let value = CareNotificationPayload.destination(from: userInfo) else {
            destination = nil
            return
        }
        destination = CareNotificationDestination(taskID: value.taskID, plantID: value.plantID)
    }

    func consume(_ destination: CareNotificationDestination) {
        guard self.destination == destination else { return }
        self.destination = nil
    }
}

final class FeedGoodAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        Task { @MainActor in
            CareNotificationRouter.shared.open(userInfo: userInfo)
            completionHandler()
        }
    }
}
