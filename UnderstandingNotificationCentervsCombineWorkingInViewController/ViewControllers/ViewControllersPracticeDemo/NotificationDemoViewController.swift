//
//  NotificationDemoViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

// ═══════════════════════════════════════════════════════════════════════════
// NOTIFICATION CENTER - Internal messaging between objects
// User NEVER sees this. It's just code talking to code.
// ═══════════════════════════════════════════════════════════════════════════

class NotificationCenterDemoViewController: UIViewController {

    let label = UILabel()

    override func viewDidLoad(){
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "NotificationsVC"

        setupUI()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleUserLoggedIn),
            name: Notification.Name("UserLoggedIn"),
            object: nil
        )
    }

    private func setupUI(){
        label.text = "Waiting for login"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(type:.system)
        button.setTitle("Simulate Login", for: .normal)
        button
            .addTarget(
                self,
                action: #selector(simulateLoginTapped),
                for: .touchUpInside
            )
        button.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(label)
        view.addSubview(button)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),

            button.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 20),
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    @objc func handleUserLoggedIn(_ notification: Notification) {
        if let text = notification.userInfo?["userName"] as? String {
            if Thread.isMainThread {
                label.text = text
            } else {
                DispatchQueue.main.async { [weak self] in
                    self?.label.text = text
                }
            }
        }
    }

    @objc func simulateLoginTapped(){
        //Post the notification
        NotificationCenter.default
            .post(
                name: Notification.Name("UserLoggedIn"),
                object: nil,
                userInfo: ["userName":"Swapnil Dhiman"]
            )
    }
}
