//
//  MockAPNSServer.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/11/25.
//

// MockAPNSServer.swift

import Foundation

/// Simulates sending push notifications from a backend server
class MockAPNSServer {
    static let shared = MockAPNSServer()

    private init() {}

    // MARK: - Send Notifications

    func sendNotification(title: String, body: String, deepLink: DeepLink) {
        print("\n" + String(repeating: "=", count: 60))
        print("🚀 [Mock APNS Server] Sending notification")
        print(String(repeating: "=", count: 60))
        print("   Title: \(title)")
        print("   Body: \(body)")
        print("   DeepLink: \(deepLink.urlString)")

        // Simulate network delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let notification = PushNotification(
                title: title,
                body: body,
                deepLink: deepLink,
                badge: Int.random(in: 1...5)
            )

            // In real app: APNS → AppDelegate didReceiveRemoteNotification
            // Here: Direct to service for simulation
            NotificationService.shared.receivePushNotification(notification)

            print("✅ [Mock APNS Server] Notification delivered")
        }
    }

    // MARK: - Predefined Notifications

    func sendHomeNotification() {
        sendNotification(
            title: "Welcome Back! 🏠",
            body: "Tap to return to home screen",
            deepLink: .home
        )
    }

    func sendProfileNotification(userId: String = "user123") {
        sendNotification(
            title: "Profile Update 👤",
            body: "You have a new message from \(userId)",
            deepLink: .profile(userId: userId)
        )
    }

    func sendSettingsNotification() {
        sendNotification(
            title: "Settings ⚙️",
            body: "Update your preferences",
            deepLink: .settings
        )
    }

    func sendRandomNotification() {
        let random = Int.random(in: 0...2)
        switch random {
        case 0:
            sendHomeNotification()
        case 1:
            sendProfileNotification(userId: "user\(Int.random(in: 100...999))")
        case 2:
            sendSettingsNotification()
        default:
            sendHomeNotification()
        }
    }
}
