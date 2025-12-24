//
//  PushNotificationDemoViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit
import UserNotifications

// ═══════════════════════════════════════════════════════════════════════════
// PUSH NOTIFICATIONS - User SEES these! Banners, sounds, badges.
// ═══════════════════════════════════════════════════════════════════════════

class PushNotificationDemoVC: UIViewController {

    let statusLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Push Notification Demo"

        setupUI()
    }

    func setupUI() {
        // Status Label
        statusLabel.text = "Tap button to send notification"
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.frame = CGRect(x: 20, y: 150, width: view.bounds.width - 40, height: 100)
        view.addSubview(statusLabel)

        // Request Permission Button
        let permissionBtn = UIButton(type: .system)
        permissionBtn.setTitle("1. Request Permission", for: .normal)
        permissionBtn.frame = CGRect(x: 50, y: 280, width: 300, height: 50)
        permissionBtn.addTarget(self, action: #selector(requestPermission), for: .touchUpInside)
        view.addSubview(permissionBtn)

        // Send Notification Button
        let sendBtn = UIButton(type: .system)
        sendBtn.setTitle("2. Send Local Notification", for: .normal)
        sendBtn.frame = CGRect(x: 50, y: 340, width: 300, height: 50)
        sendBtn.addTarget(self, action: #selector(sendLocalNotification), for: .touchUpInside)
        view.addSubview(sendBtn)

        // Instructions
        let instructionLabel = UILabel()
        instructionLabel.text = """
        Instructions:
        1. Tap "Request Permission"
        2. Allow notifications
        3. Tap "Send Local Notification"
        4. BACKGROUND the app (press HOME)
        5. Wait 3 seconds - you'll see the banner!
        """
        instructionLabel.numberOfLines = 0
        instructionLabel.font = .systemFont(ofSize: 14)
        instructionLabel.textColor = .secondaryLabel
        instructionLabel.frame = CGRect(x: 20, y: 420, width: view.bounds.width - 40, height: 200)
        view.addSubview(instructionLabel)
    }

    // MARK: - Step 1: Request Permission

    @objc func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                if granted {
                    self?.statusLabel.text = "✅ Permission granted!\nNow tap 'Send Local Notification'"
                } else {
                    self?.statusLabel.text = "❌ Permission denied.\nGo to Settings > Notifications"
                }
            }
        }
    }

    // MARK: - Step 2: Send Local Notification

    @objc func sendLocalNotification() {
//         Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Hello from your app! 👋"
        content.body = "This is a LOCAL push notification. User SEES this!"
        content.sound = .default
        content.badge = 1

        // Trigger after 3 seconds
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 3,
            repeats: false
        )

        // Create the request
        let request = UNNotificationRequest(
            identifier: "demo-notification",
            content: content,
            trigger: trigger
        )

        // Schedule it
        UNUserNotificationCenter.current().add(request) { [weak self] error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.statusLabel.text = "❌ Error: \(error.localizedDescription)"
                } else {
                    self?.statusLabel.text = "✅ Notification scheduled!\n\n⚠️ NOW PRESS HOME BUTTON!\nWait 3 seconds for banner."
                }
            }
        }
    }
}
