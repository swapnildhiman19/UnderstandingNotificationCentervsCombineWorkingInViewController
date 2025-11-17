//
//  DeepLinkRouter.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/11/25.
//

// DeepLinkRouter.swift

import UIKit
import Combine

/// Handles navigation based on deep links
class DeepLinkRouter {
    private weak var navigationController: UINavigationController?
    private var cancellables = Set<AnyCancellable>()

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
        setupSubscriptions()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to deep links from NotificationService
        NotificationService.shared.deepLinkPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] deepLink in
                self?.handle(deepLink)
            }
            .store(in: &cancellables)
    }

    // MARK: - Navigation

    func handle(_ deepLink: DeepLink) {
        print("\n🧭 [Router] Handling deep link: \(deepLink.urlString)")

        guard let navigationController = navigationController else {
            print("   ⚠️ No navigation controller available")
            return
        }

        // Pop to root if needed
        if navigationController.viewControllers.count > 1 {
            navigationController.popToRootViewController(animated: false)
        }

        // Navigate based on deep link
        switch deepLink {
        case .home:
            print("   → Already on home")
            // Already on root

        case .profile(let userId):
            print("   → Navigating to profile: \(userId)")
            let profileVC = ProfileViewController(userId: userId)
            navigationController.pushViewController(profileVC, animated: true)

        case .settings:
            print("   → Navigating to settings")
            let settingsVC = SettingsViewController()
            navigationController.pushViewController(settingsVC, animated: true)
        }
    }
}
