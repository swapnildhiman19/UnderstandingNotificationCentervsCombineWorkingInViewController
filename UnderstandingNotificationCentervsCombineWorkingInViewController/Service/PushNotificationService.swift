//
//  PushNotificationService.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 16/11/25.
//

// PushNotificationService.swift

import Foundation
import Combine

/// This service demonstrates BOTH NotificationCenter and Combine approaches
class PushNotificationService {

    static let shared = PushNotificationService()

    // ============================================
    // COMBINE APPROACH - Modern, Reactive
    // ============================================

    /// Published property - automatically broadcasts changes to subscribers
    /// Think of this as a "live stream" that anyone can watch
    @Published var latestNotification: PushNotificationPayload?

    /// Publisher - explicitly broadcasts notification stream
    /// Think of this as a "TV channel" that broadcasts events
    let notificationPublisher = PassthroughSubject<PushNotificationPayload, Never>()

    /// Current count of notifications (also reactive)
    @Published var notificationCount: Int = 0

    private init() {
        print("🏗️ [Service] Initialized with both NotificationCenter and Combine support")
    }

    // ============================================
    // SEND NOTIFICATION - Updates BOTH systems
    // ============================================

    func sendNotification(title: String, message: String, badge: Int? = nil) {
        let payload = PushNotificationPayload(
            title: title,
            message: message,
            badge: badge,
            userInfo: ["source": "demo"]
        )

        print("\n📡 [Service] Sending notification via BOTH systems:")
        print("   Title: \(title)")
        print("   Message: \(message)")

        // ----------------------------------------
        // METHOD 1: NotificationCenter (OLD WAY)
        // ----------------------------------------
        NotificationCenter.default.post(
            name: .pushNotificationReceived,
            object: nil,
            userInfo: ["payload": payload]
        )
        print("   ✅ Posted to NotificationCenter")

        // ----------------------------------------
        // METHOD 2: Combine @Published (NEW WAY #1)
        // ----------------------------------------
        latestNotification = payload
        print("   ✅ Updated @Published property")

        // ----------------------------------------
        // METHOD 3: Combine Publisher (NEW WAY #2)
        // ----------------------------------------
        notificationPublisher.send(payload)
        print("   ✅ Sent to Combine publisher")

        // Update count
        notificationCount += 1
    }

    func sendRandomNotification() {
        let notifications = [
            ("New Message 📧", "You have a new message from John"),
            ("Order Update 📦", "Your order has been shipped!"),
            ("Sale Alert 💰", "50% off on your favorite items!"),
            ("Friend Request 👋", "Sarah wants to connect"),
            ("Achievement 🏆", "You've earned a new badge!")
        ]

        let random = notifications.randomElement()!
        sendNotification(title: random.0, message: random.1, badge: Int.random(in: 1...5))
    }
}

//import Foundation
//import Combine
//
//class PushNotificationService {
//    static let shared = PushNotificationService()
//
//    @Published var latestNotification: PushNotificationPayload?
//
//    let notificationPublisher = PassthroughSubject<PushNotificationPayload, Never>()
//
//    @Published var notificationCount: Int = 0
//
//    private init() {
//        print("🏗️ [Service] Initialized with both NotificationCenter and Combine support")
//    }
//
//    func sendNotification(title: String, message: String, badge: Int) {
//
//        let payload = PushNotificationPayload(
//            title: title,
//            message: message,
//            badge: badge,
//            userInfo: ["source": "demo"]
//        )
//
//        NotificationCenter.default.post(
//            name: .pushNotificationReceived,
//            object: nil,
//            userInfo: ["payload": payload]
//        )
//
//        latestNotification = payload
//
//        notificationPublisher.send(payload)
//
//        notificationCount += 1
//    }
//
//    func sendRandomNotification() {
//        let notifications = [
//            ("New Message 📧", "You have a new message from John"),
//            ("Order Update 📦", "Your order has been shipped!"),
//            ("Sale Alert 💰", "50% off on your favorite items!"),
//            ("Friend Request 👋", "Sarah wants to connect"),
//            ("Achievement 🏆", "You've earned a new badge!")
//        ]
//
//        let random = notifications.randomElement()!
//
//        sendNotification(title: random.0, message: random.1, badge: Int.random(in: 1...5))
//    }
//}
