//
//  Model.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/11/25.
//

// Models.swift

import Foundation
import Combine

// MARK: - Deep Link Types

enum DeepLink {
    case home
    case profile(userId: String)
    case settings

    var urlString: String {
        switch self {
        case .home:
            return "myapp://home"
        case .profile(let userId):
            return "myapp://profile/\(userId)"
        case .settings:
            return "myapp://settings"
        }
    }

    // Parse URL into DeepLink
    static func parse(_ url: URL) -> DeepLink? {
        guard url.scheme == "myapp" else { return nil }

        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch url.host {
        case "home":
            return .home
        case "profile":
            if let userId = pathComponents.first {
                return .profile(userId: userId)
            }
        case "settings":
            return .settings
        default:
            return nil
        }

        return nil
    }
}

// MARK: - Push Notification Payload

struct PushNotification {
    let id: UUID
    let title: String
    let body: String
    let deepLink: DeepLink
    let timestamp: Date
    let badge: Int?

    init(title: String, body: String, deepLink: DeepLink, badge: Int? = nil) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.deepLink = deepLink
        self.timestamp = Date()
        self.badge = badge
    }

    // Simulates APNS userInfo dictionary
    var userInfo: [AnyHashable: Any] {
        return [
            "aps": [
                "alert": [
                    "title": title,
                    "body": body
                ],
                "badge": badge as Any,
                "sound": "default"
            ],
            "deepLink": deepLink.urlString,
            "notificationId": id.uuidString
        ]
    }
}
