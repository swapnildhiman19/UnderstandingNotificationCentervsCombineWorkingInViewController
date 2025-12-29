//////
//////  SceneDelegate.swift
//////  UnderstandingNotificationCentervsCombineWorkingInViewController
//////
//////  Created by Swapnil Dhiman on 16/11/25.
//////
////
////import UIKit
////
////class SceneDelegate: UIResponder, UIWindowSceneDelegate {
////
////    var window: UIWindow?
////
////
////    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
////        // Use this method to optionally configure and attach the UIWindow `window` to the provided UIWindowScene `scene`.
////        // If using a storyboard, the `window` property will automatically be initialized and attached to the scene.
////        // This delegate does not imply the connecting scene or session are new (see `application:configurationForConnectingSceneSession` instead).
////        guard let windowScene = (scene as? UIWindowScene) else { return }
////
////        window = UIWindow(windowScene: windowScene)
////        let viewController = ViewController()
////        let navigationController = UINavigationController(rootViewController: viewController)
////        window?.rootViewController = navigationController
////        window?.makeKeyAndVisible()
////
////        // Send a welcome notification after 1 second
////        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
////            print("\n🎯 Sending welcome notification...")
////            PushNotificationService.shared.sendNotification(
////                title: "Welcome! 👋",
////                message: "Watch all 3 sections receive this notification!",
////                badge: 1
////            )
////        }
////    }
////
////    func sceneDidDisconnect(_ scene: UIScene) {
////        // Called as the scene is being released by the system.
////        // This occurs shortly after the scene enters the background, or when its session is discarded.
////        // Release any resources associated with this scene that can be re-created the next time the scene connects.
////        // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
////    }
////
////    func sceneDidBecomeActive(_ scene: UIScene) {
////        // Called when the scene has moved from an inactive state to an active state.
////        // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
////    }
////
////    func sceneWillResignActive(_ scene: UIScene) {
////        // Called when the scene will move from an active state to an inactive state.
////        // This may occur due to temporary interruptions (ex. an incoming phone call).
////    }
////
////    func sceneWillEnterForeground(_ scene: UIScene) {
////        // Called as the scene transitions from the background to the foreground.
////        // Use this method to undo the changes made on entering the background.
////    }
////
////    func sceneDidEnterBackground(_ scene: UIScene) {
////        // Called as the scene transitions from the foreground to the background.
////        // Use this method to save data, release shared resources, and store enough scene-specific state information
////        // to restore the scene back to its current state.
////    }
////
////
////}
////
//
//// SceneDelegate.swift

import UIKit
import Combine

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
//    private var router: DeepLinkRouter?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Scene Lifecycle

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        print("\n🎬 [SceneDelegate] Scene connecting")

        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Setup window
        window = UIWindow(windowScene: windowScene)

        /*
        // Create navigation controller
        let homeVC = HomeViewController()
        let navigationController = UINavigationController(rootViewController: homeVC)

        // Setup router
        router = DeepLinkRouter(navigationController: navigationController)

        // Set root and show
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

        print("✅ [SceneDelegate] Window setup complete")

        // Handle deep link if launched from notification
        if let urlContext = connectionOptions.urlContexts.first {
            handleDeepLink(urlContext.url)
        }

        // Send welcome notification after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            print("\n🎉 [SceneDelegate] Sending welcome notification...")
            MockAPNSServer.shared.sendNotification(
                title: "Welcome! 🎉",
                body: "Try tapping the notification buttons!",
                deepLink: .home
            )
        }
         */

//        let basicTableViewWithReuseIdentifierViewController = BasicTableViewWithReuseIdentifierViewController()
//        let photoCollectionViewController = PhotoCollectionViewController()
//        let simpleCollectionViewController = HorizontalScrollViewController()
////        let gestureViewController = GestureViewController()
//        window?.rootViewController = gestureViewController
//        window?.makeKeyAndVisible()

//        let taskListVC = TaskListViewController(style: .plain)
//        let urlSessionSharedDataTaskVC = URLSessionSharedDataTaskViewController()
//        let downloadViewController = DownloadViewController()
//        let oAuthViewController = OAuthViewController()
//        let networkDemoViewController = NetworkDemoViewController()
//        let mvvmArchVC = MVVMArchitectureUnderstandingViewController()
//        let paymentDelegateUnderstandingVC = PaymentViewController()
//        let observeNotificationUnderstandingVC = ObserveNotificationUnderstandingViewController()
//        let builderPatternDemoVC = BuilderPatternDemoViewController()
//        let frameBoundsVC = FrameBoundsViewController()
//        let scrollBoundVC = ScrollBoundsViewController()
//        let drawingDemoVC = DrawingDemoViewController()
//        let escapingClosureVC = UserEscapingViewController()
//        let lifeCycleDemoVC = LifecycleDemoViewController()
//        let notificationsDemoVC = NotificationCenterDemoViewController()
//        let pushNotificationsDemoVC = PushNotificationDemoVC()
//        let deepLinkDemoVC = DeepLinkDemoViewController()
//        let simpleTimerVC = SimpleTimerViewController()
//        let runLoopDemoVC = RunLoopDemoViewController()
//        let multipleTimersVC = MultipleTimersViewController()
//        let gestureVC = GestureViewController()
//        let productDetailWithPageLoadTrackingVC = ProductDetailViewControllerWithPageLoadTracking(productId: "123")
        let serverDrivenUIViewController = SDUIDemoViewController()
        let navigationController = UINavigationController(
            rootViewController: serverDrivenUIViewController
        )
        navigationController.navigationBar.prefersLargeTitles = true

        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()

    }

    // MARK: - Deep Link Handling

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        print("\n🔗 [SceneDelegate] Opening URL contexts")
//
//        guard let url = URLContexts.first?.url else { return }
//        handleDeepLink(url)
//        guard let url = URLContexts.first?.url else { return }
//        print("📱 App received callback URL: \(url.absoluteString)")
        // ASWebAuthenticationSession handles this automatically!
        guard let url = URLContexts.first?.url else { return }
          handleIncomingURL(url)
    }

    private func handleIncomingURL(_ url: URL) {
        print("📱 App received URL: \(url)")
/*
        if let destination = DeepLinkHandler.shared.parse(url: url) {
            // Post notification to main VC
            NotificationCenter.default.post(
                name: .didReceiveDeepLink,
                object: nil,
                userInfo: ["destination": destination]
            )
        }
 */
    }

    private func handleDeepLink(_ url: URL) {
        print("🔗 [SceneDelegate] Handling deep link: \(url)")

        guard let deepLink = DeepLink.parse(url) else {
            print("   ⚠️ Invalid deep link format")
            return
        }

        print("   ✅ Parsed as: \(deepLink)")
        NotificationService.shared.navigateToDeepLink(deepLink)
    }

    // MARK: - Scene State Transitions

    func sceneDidDisconnect(_ scene: UIScene) {
        print("\n👋 [SceneDelegate] Scene disconnected")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        print("\n✅ [SceneDelegate] Scene became active")
    }

    func sceneWillResignActive(_ scene: UIScene) {
        print("\n⚠️ [SceneDelegate] Scene will resign active")
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        print("\n🌅 [SceneDelegate] Scene entering foreground")
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        print("\n🌙 [SceneDelegate] Scene entered background")
    }
}


//import UIKit
//
//class SceneDelegate: UIResponder, UIWindowSceneDelegate {
//
//    var window: UIWindow?
//
//    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
//        guard let windowScene = (scene as? UIWindowScene) else { return }
//
//        window = UIWindow(windowScene: windowScene)
//        window?.rootViewController = UINavigationController(
//            rootViewController: DeepLinkTestViewController()
//        )
//        window?.makeKeyAndVisible()
//
//        // ✅ Handle URL if app was LAUNCHED via deep link
//        if let urlContext = connectionOptions.urlContexts.first {
//            print("🚀 App LAUNCHED with URL: \(urlContext.url)")
//            handleURL(urlContext.url)
//        }
//    }
//
//    // ✅ Handle URL when app is ALREADY RUNNING
//    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
//        guard let url = URLContexts.first?.url else {
//            print("❌ No URL in context")
//            return
//        }
//
//        print("📱 App RECEIVED URL while running: \(url)")
//        handleURL(url)
//    }
//
//    private func handleURL(_ url: URL) {
//        print("═══════════════════════════════════════")
//        print("🔗 DEEP LINK RECEIVED!")
//        print("   Full URL: \(url.absoluteString)")
//        print("   Scheme: \(url.scheme ?? "nil")")
//        print("   Host: \(url.host ?? "nil")")
//        print("   Path: \(url.path)")
//        print("═══════════════════════════════════════")
//
//        // Post notification
//        NotificationCenter.default.post(
//            name: Notification.Name("DeepLinkReceived"),
//            object: nil,
//            userInfo: ["url": url]
//        )
//    }
//
//    func sceneDidDisconnect(_ scene: UIScene) {}
//    func sceneDidBecomeActive(_ scene: UIScene) {}
//    func sceneWillResignActive(_ scene: UIScene) {}
//    func sceneWillEnterForeground(_ scene: UIScene) {}
//    func sceneDidEnterBackground(_ scene: UIScene) {}
//}
