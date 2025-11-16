//
//  NotificationModel.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 16/11/25.
//

// NotificationModels.swift

import Foundation
import Combine

/// Represents a push notification payload
struct PushNotificationPayload {
    let id: UUID
    let title: String
    let message: String
    let badge: Int?
    let timestamp: Date
    let userInfo: [String: Any]

    init(title: String, message: String, badge: Int? = nil, userInfo: [String: Any] = [:]) {
        self.id = UUID()
        self.title = title
        self.message = message
        self.badge = badge
        self.timestamp = Date()
        self.userInfo = userInfo
    }
}

/// Notification Names (for NotificationCenter)
extension Notification.Name {
    static let pushNotificationReceived = Notification.Name("pushNotificationReceived")
}


//import Foundation
//import Combine
//
//struct PushNotificationPayload {
//    let id: UUID
//    let title: String
//    let message: String
//    let badge: Int?
//    let timestamp: Date
//    let userInfo: [String: Any]
//
//    init(id: UUID, title: String, message: String, badge: Int?, timestamp: Date, userInfo: [String : Any]) {
//        self.id = id
//        self.title = title
//        self.message = message
//        self.badge = badge
//        self.timestamp = timestamp
//        self.userInfo = userInfo
//    }
//}
//
//extension Notification.Name {
//    static let pushNotificationReceived = Notification.Name("pushNotificationReceived")
//}
