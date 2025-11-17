//
//  NotificationService.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/11/25.
//

// NotificationService.swift

import Foundation
import Combine

/// Reactive notification service using Combine
class NotificationService {
    static let shared = NotificationService()

    // MARK: - Publishers

    /// Publishes push notifications
    private let notificationSubject = PassthroughSubject<PushNotification, Never>()
    var notificationPublisher: AnyPublisher<PushNotification, Never> {
        notificationSubject.eraseToAnyPublisher()
    }

    /// Publishes deep links extracted from notifications
    private let deepLinkSubject = PassthroughSubject<DeepLink, Never>()
    var deepLinkPublisher: AnyPublisher<DeepLink, Never> {
        deepLinkSubject.eraseToAnyPublisher()
    }

    /// Current notification count
    @Published var notificationCount: Int = 0

    private init() {
        setupPipeline()
    }

    // MARK: - Setup

    private func setupPipeline() {
        // Automatically extract deep links from notifications
        notificationPublisher
            .compactMap { $0.deepLink }
            .sink { [weak self] deepLink in
                self?.deepLinkSubject.send(deepLink)
            }
            .store(in: &cancellables)
    }

    // MARK: - Methods

    /// Receive a push notification (called by AppDelegate)
    func receivePushNotification(_ notification: PushNotification) {
        print("\n📩 [NotificationService] Received push notification")
        print("   Title: \(notification.title)")
        print("   Body: \(notification.body)")
        print("   DeepLink: \(notification.deepLink.urlString)")

        notificationCount += 1
        notificationSubject.send(notification)
    }

    /// Navigate to deep link (called manually or from notification)
    func navigateToDeepLink(_ deepLink: DeepLink) {
        print("\n🔗 [NotificationService] Navigating to: \(deepLink.urlString)")
        deepLinkSubject.send(deepLink)
    }

    private var cancellables = Set<AnyCancellable>()
}
