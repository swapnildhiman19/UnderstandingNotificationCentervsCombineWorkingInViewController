////
////  AppDelegate.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 16/11/25.
////
//
//import UIKit
//
//@main
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//
//
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        // Override point for customization after application launch.
//        return true
//    }
//
//    // MARK: UISceneSession Lifecycle
//
//    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
//        // Called when a new scene session is being created.
//        // Use this method to select a configuration to create the new scene with.
//        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
//    }
//
//    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
//        // Called when the user discards a scene session.
//        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
//        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
//    }
//
//
//}
//

// AppDelegate.swift

//import UIKit
//
//@main
//class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    func application(
//        _ application: UIApplication,
//        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
//    ) -> Bool {
//
//        print("🚀 [AppDelegate] App launched")
//
//        // Register for push notifications
//        registerForPushNotifications(application)
//
//        // Check if launched from notification
//        if let notification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
//            print("📱 [AppDelegate] Launched from notification")
//            handleRemoteNotification(notification)
//        }
//
//        return true
//    }
//
//    // MARK: - UISceneSession Lifecycle
//
//    func application(
//        _ application: UIApplication,
//        configurationForConnecting connectingSceneSession: UISceneSession,
//        options: UIScene.ConnectionOptions
//    ) -> UISceneConfiguration {
//        print("⚙️ [AppDelegate] Configuring scene session")
//
//        let configuration = UISceneConfiguration(
//            name: "Default Configuration",
//            sessionRole: connectingSceneSession.role
//        )
//        configuration.delegateClass = SceneDelegate.self
//        return configuration
//    }
//
//    func application(
//        _ application: UIApplication,
//        didDiscardSceneSessions sceneSessions: Set<UISceneSession>
//    ) {
//        print("🗑️ [AppDelegate] Discarded scene sessions: \(sceneSessions.count)")
//    }
//
//    // MARK: - Push Notifications
//
//    private func registerForPushNotifications(_ application: UIApplication) {
//        print("📝 [AppDelegate] Registering for push notifications")
//
//        UNUserNotificationCenter.current().requestAuthorization(
//            options: [.alert, .badge, .sound]
//        ) { granted, error in
//            if granted {
//                print("✅ [AppDelegate] Push notification permission granted")
//                DispatchQueue.main.async {
//                    application.registerForRemoteNotifications()
//                }
//            } else {
//                print("❌ [AppDelegate] Push notification permission denied")
//            }
//        }
//    }
//
//    func application(
//        _ application: UIApplication,
//        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
//    ) {
//        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
//        print("✅ [AppDelegate] Registered for remote notifications")
//        print("   Device Token: \(token)")
//    }
//
//    func application(
//        _ application: UIApplication,
//        didFailToRegisterForRemoteNotificationsWithError error: Error
//    ) {
//        print("❌ [AppDelegate] Failed to register for remote notifications: \(error)")
//    }
//
//    // MARK: - Handle Remote Notification
//
//    func application(
//        _ application: UIApplication,
//        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
//    ) {
//        print("\n📩 [AppDelegate] Received remote notification")
//        handleRemoteNotification(userInfo)
//        completionHandler(.newData)
//    }
//
//    private func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
//        print("   UserInfo: \(userInfo)")
//
//        // Extract deep link
//        guard let deepLinkString = userInfo["deepLink"] as? String,
//              let url = URL(string: deepLinkString),
//              let deepLink = DeepLink.parse(url) else {
//            print("   ⚠️ No valid deep link found")
//            return
//        }
//
//        // Extract notification details
//        let aps = userInfo["aps"] as? [String: Any]
//        let alert = aps?["alert"] as? [String: Any]
//        let title = alert?["title"] as? String ?? "Notification"
//        let body = alert?["body"] as? String ?? ""
//        let badge = aps?["badge"] as? Int
//
//        // Create notification object
//        let notification = PushNotification(
//            title: title,
//            body: body,
//            deepLink: deepLink,
//            badge: badge
//        )
//
//        // Send to notification service
//        NotificationService.shared.receivePushNotification(notification)
//    }
//}

import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

//    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        let shouldUseSafeMode = CrashLoopDetector.shared.checkOnLaunch()
        
        if shouldUseSafeMode {
            SafeModeManager.shared.activateSafeMode()
            setupSafeModeUI()
        } else {
            //setupNormalApp()
        }
        
        
        // Set ourselves as the notification delegate
        UNUserNotificationCenter.current().delegate = self
        OOMDetector.shared.applicationDidLaunch()
        MetricKitManager.shared.startMonitoring()

        // Setup window
//        window = UIWindow(frame: UIScreen.main.bounds)
//        window?.rootViewController = UINavigationController(
//            rootViewController: PushNotificationDemoVC()
//        )
//        window?.makeKeyAndVisible()

        return true
    }
    
    func setupSafeModeUI(){
        NotificationCenter.default.post(name: .safeModeActivated, object: nil)
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        OOMDetector.shared.applicationDidEnterBackground()
        CrashLoopDetector.shared.markCleanShutDown()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        OOMDetector.shared.applicationDidEnterForeground()
        CrashLoopDetector.shared.markBecomingActive()
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        OOMDetector.shared.applicationWillTerminate()
        CrashLoopDetector.shared.markCleanShutDown()
    }
    
    func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
        OOMPreventionManager.shared.evaluateMemoryPressure()
    }
}

// MARK: - Handle Notifications

//extension AppDelegate: UNUserNotificationCenterDelegate {
//
//    // Called when notification arrives while app is in FOREGROUND
//    func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        willPresent notification: UNNotification,
//        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
//    ) {
//        print("📱 Notification received in FOREGROUND")
//
//        // Show the banner even when app is open
//        completionHandler([.banner, .sound, .badge])
//    }
//
//    // Called when user TAPS the notification
//    func userNotificationCenter(
//        _ center: UNUserNotificationCenter,
//        didReceive response: UNNotificationResponse,
//        withCompletionHandler completionHandler: @escaping () -> Void
//    ) {
//        print("👆 User TAPPED the notification!")
//
//        // You can navigate to a specific screen here
//        let title = response.notification.request.content.title
//        print("   Title was: \(title)")
//
//        completionHandler()
//    }
//}

extension AppDelegate : UNUserNotificationCenterDelegate {

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping @Sendable (UNNotificationPresentationOptions) -> Void) {
        print("Notification received in FOREGROUND")
        completionHandler([.badge,.sound,.banner])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping @Sendable () -> Void) {
        print("User tapped on the notification")
        let title = response.notification.request.content.title
        print("Title was \(title)")
        completionHandler()
    }
}

class SafeModeBannerView : UIView {
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "We're experiencing issues. Some features may be limited"
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI(){
        backgroundColor = UIColor.orange
        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}

class SafeModeAwareViewController : UIViewController {
    private var safeModeObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        //Observing
        safeModeObserver = NotificationCenter.default.addObserver(forName: .safeModeActivated, object: nil, queue: .main, using: { [weak self] _ in
            self?.handleSafeModeActivation()
        })
        
        //Current state
        if SafeModeManager.shared.isInSafeMode {
            handleSafeModeActivation()
        }
    }
    
    private func handleSafeModeActivation(){
        let banner = SafeModeBannerView()
        view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        disableUnsafeFeatures()
    }
    
    private func disableUnsafeFeatures(){
        if !SafeModeManager.shared.isFeatureEnabled(.videoPlayback) {
            //Hide video player
        }
        if !SafeModeManager.shared.isFeatureEnabled(.animatedBanners){
            //Stop animations
        }
    }
}
