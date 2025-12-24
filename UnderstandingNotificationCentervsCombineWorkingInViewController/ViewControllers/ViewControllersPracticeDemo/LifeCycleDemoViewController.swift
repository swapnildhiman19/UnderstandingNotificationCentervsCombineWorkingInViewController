//
//  LifeCycleDemoViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

// ═══════════════════════════════════════════════════════════════════════════
// MAIN VIEW CONTROLLER - Shows all lifecycle events
// ═══════════════════════════════════════════════════════════════════════════

class LifecycleDemoViewController: UIViewController {

    // MARK: - Properties

    private var foregroundObserver: NSObjectProtocol?
    private var backgroundObserver: NSObjectProtocol?
    private var lastUpdateTime: Date?

    private let statusLabel = UILabel()
    private let logTextView = UITextView()
    private let refreshButton = UIButton(type: .system)

    // MARK: - Lifecycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        log("1️⃣ viewDidLoad() - Called ONCE")
        log("   View loaded, setting up UI...")
        log("   view.bounds = \(view.bounds)")

        setupUI()
        setupNotifications()
        loadData()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        log("2️⃣ viewWillAppear() - Called EACH time VC appears")
        log("   View about to appear on screen")

        // Good place to refresh data when coming back from another VC
        refreshDataIfNeeded()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        // Called multiple times - don't log every time in real app
        // log("3️⃣ viewWillLayoutSubviews() - Before layout")
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        log("4️⃣ viewDidLayoutSubviews() - Layout complete!")
        log("   view.bounds = \(view.bounds) ← NOW HAS SIZE!")

        // Safe to set cornerRadius here
        refreshButton.layer.cornerRadius = refreshButton.bounds.height / 2
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        log("5️⃣ viewDidAppear() - View is now ON SCREEN")
        log("   Start animations, analytics here")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        log("6️⃣ viewWillDisappear() - About to leave screen")
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        log("7️⃣ viewDidDisappear() - No longer visible")
    }

    deinit {
        log("8️⃣ deinit - VC is being deallocated")
        removeNotifications()
    }

    // MARK: - App Lifecycle Notifications

    private func setupNotifications() {
        log("📱 Setting up App Lifecycle notifications...")

        // When app becomes active (comes to foreground)
        foregroundObserver = NotificationCenter.default
            .addObserver(
                forName: UIApplication.didBecomeActiveNotification,
                object: nil,
                queue: .main,
                using: { [weak self] _ in
                    self?.log("didEnterForegroundNotification")
                    self?.log("App entered Foreground")
                    self?.log("viewWillAppear will not be called")
                    self?.saveState()
                }
            )

        // When app goes to background
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.log("📱 didEnterBackgroundNotification")
            self?.log("   App entered BACKGROUND")
            self?.log("   ⚠️ viewWillDisappear was NOT called!")
            self?.saveState()
        }

        // When app WILL enter foreground (before active)
        NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.log("📱 willEnterForegroundNotification")
            self?.log("   App WILL enter foreground")
        }
    }

    private func removeNotifications() {
        if let observer = foregroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        if let observer = backgroundObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    // MARK: - Data Methods

    private func loadData() {
        log("🔄 loadData() - Fetching fresh data...")
        lastUpdateTime = Date()

        // Simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.log("✅ Data loaded successfully!")
            self?.updateStatus("Data loaded at: \(self?.formattedTime() ?? "")")
        }
    }

    private func refreshDataIfNeeded() {
        guard let lastUpdate = lastUpdateTime else {
            loadData()
            return
        }

        let timeSinceUpdate = Date().timeIntervalSince(lastUpdate)
        let staleThreshold: TimeInterval = 60 // 1 minute for demo

        if timeSinceUpdate > staleThreshold {
            log("⏰ Data is STALE (\(Int(timeSinceUpdate))s old)")
            loadData()
        } else {
            log("✅ Data is FRESH (\(Int(timeSinceUpdate))s old)")
        }
    }

    private func saveState() {
        log("💾 Saving state before background...")
        UserDefaults.standard.set(lastUpdateTime, forKey: "lastUpdate")
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Lifecycle Demo"

        // Status Label
        statusLabel.text = "Try pressing HOME button and coming back!"
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        view.addSubview(statusLabel)

        // Log TextView
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.isEditable = false
        logTextView.backgroundColor = .secondarySystemBackground
        logTextView.layer.cornerRadius = 10
        view.addSubview(logTextView)

        // Refresh Button
        refreshButton.setTitle("  Force Refresh  ", for: .normal)
        refreshButton.backgroundColor = .systemBlue
        refreshButton.setTitleColor(.white, for: .normal)
        refreshButton.clipsToBounds = true
        refreshButton.addTarget(self, action: #selector(forceRefresh), for: .touchUpInside)
        view.addSubview(refreshButton)

        // Push VC Button (to test viewWillAppear)
        let pushButton = UIButton(type: .system)
        pushButton.setTitle("Push New VC (test viewWillAppear)", for: .normal)
        pushButton.addTarget(self, action: #selector(pushNewVC), for: .touchUpInside)
        view.addSubview(pushButton)

        // Constraints
        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        pushButton.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            statusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            logTextView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 20),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.heightAnchor.constraint(equalToConstant: 350),

            refreshButton.topAnchor.constraint(equalTo: logTextView.bottomAnchor, constant: 20),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.heightAnchor.constraint(equalToConstant: 44),

            pushButton.topAnchor.constraint(equalTo: refreshButton.bottomAnchor, constant: 20),
            pushButton.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }

    // MARK: - Actions

    @objc private func forceRefresh() {
        log("👆 Force refresh button tapped")
        loadData()
    }

    @objc private func pushNewVC() {
        log("👆 Pushing new ViewController...")
        let newVC = SimpleViewController()
        navigationController?.pushViewController(newVC, animated: true)
    }

    // MARK: - Helpers

    private func log(_ message: String) {
        let timestamp = formattedTime()
        let logMessage = "[\(timestamp)] \(message)\n"

        DispatchQueue.main.async { [weak self] in
            self?.logTextView.text += logMessage

            // Auto-scroll to bottom
            let range = NSRange(location: (self?.logTextView.text.count ?? 1) - 1, length: 1)
            self?.logTextView.scrollRangeToVisible(range)
        }

        print(logMessage)
    }

    private func updateStatus(_ text: String) {
        statusLabel.text = text
    }

    private func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: Date())
    }
}


// ═══════════════════════════════════════════════════════════════════════════
// SIMPLE VC - To test navigation lifecycle
// ═══════════════════════════════════════════════════════════════════════════

class SimpleViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBlue
        title = "Second VC"

        let label = UILabel()
        label.text = "Tap Back to see\nviewWillAppear called\non previous VC"
        label.textColor = .white
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
