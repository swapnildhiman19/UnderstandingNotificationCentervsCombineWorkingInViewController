//
//  DeepLinkTestViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

class DeepLinkTestViewController: UIViewController {

    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let urlLabel = UILabel()
    private let testButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Deep Link Test"

        setupUI()

        // Listen for deep links
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didReceiveDeepLink(_:)),
            name: Notification.Name("DeepLinkReceived"),
            object: nil
        )
    }

    @objc private func didReceiveDeepLink(_ notification: Notification) {
        guard let url = notification.userInfo?["url"] as? URL else { return }

        DispatchQueue.main.async { [weak self] in
            self?.statusLabel.text = "✅ DEEP LINK RECEIVED!"
            self?.statusLabel.textColor = .systemGreen

            self?.urlLabel.text = """
            Full URL: \(url.absoluteString)
            
            Scheme: \(url.scheme ?? "nil")
            Host: \(url.host ?? "nil")  
            Path: \(url.path)
            """

            // Show alert
            let alert = UIAlertController(
                title: "Deep Link Received! 🎉",
                message: url.absoluteString,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self?.present(alert, animated: true)
        }
    }

    @objc private func copyTestURL() {
        UIPasteboard.general.string = "demoapp://product/123"

        let alert = UIAlertController(
            title: "Copied!",
            message: "URL copied to clipboard.\n\nNow:\n1. Press HOME\n2. Open Safari\n3. Paste and Go",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func setupUI() {
        // Title
        titleLabel.text = "🔗 Deep Link Tester"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        // Status
        statusLabel.text = "⏳ Waiting for deep link..."
        statusLabel.font = .systemFont(ofSize: 18, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.textColor = .secondaryLabel

        // URL Label
        urlLabel.text = "No URL received yet"
        urlLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        urlLabel.numberOfLines = 0
        urlLabel.textAlignment = .left
        urlLabel.backgroundColor = .secondarySystemBackground
        urlLabel.layer.cornerRadius = 8
        urlLabel.clipsToBounds = true

        // Test Button
        testButton.setTitle("📋 Copy Test URL to Clipboard", for: .normal)
        testButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        testButton.backgroundColor = .systemBlue
        testButton.setTitleColor(.white, for: .normal)
        testButton.layer.cornerRadius = 10
        testButton.addTarget(self, action: #selector(copyTestURL), for: .touchUpInside)

        // Instructions
        let instructionsLabel = UILabel()
        instructionsLabel.text = """
        📋 HOW TO TEST:
        
        METHOD 1 (Easiest):
        1. Tap "Copy Test URL" button above
        2. Press HOME (Cmd+Shift+H on simulator)
        3. Open Safari
        4. Paste URL in address bar
        5. Tap Go
        6. Tap "Open" when prompted
        
        METHOD 2 (Terminal):
        Run in Terminal:
        xcrun simctl openurl booted "demoapp://product/123"
        
        TEST URLs:
        • demoapp://product/123
        • demoapp://user/456
        • demoapp://home
        """
        instructionsLabel.font = .systemFont(ofSize: 13)
        instructionsLabel.numberOfLines = 0
        instructionsLabel.textColor = .secondaryLabel

        // Stack View
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel, statusLabel, urlLabel, testButton, instructionsLabel
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            testButton.heightAnchor.constraint(equalToConstant: 50),
            urlLabel.heightAnchor.constraint(greaterThanOrEqualToConstant: 80)
        ])
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
