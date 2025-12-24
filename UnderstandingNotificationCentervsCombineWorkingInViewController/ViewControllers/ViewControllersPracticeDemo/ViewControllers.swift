////////
////////  ViewController.swift
////////  UnderstandingNotificationCentervsCombineWorkingInViewController
////////
////////  Created by Swapnil Dhiman on 16/11/25.
////////
//////
//////// ViewController.swift
//////
////import UIKit
////import Combine
////
////class ViewController: UIViewController {
////
////    // ============================================
////    // UI COMPONENTS
////    // ============================================
////
////    private let titleLabel: UILabel = {
////        let label = UILabel()
////        label.text = "NotificationCenter vs Combine"
////        label.font = .boldSystemFont(ofSize: 20)
////        label.textAlignment = .center
////        label.translatesAutoresizingMaskIntoConstraints = false
////        return label
////    }()
////
////    // NotificationCenter Section
////    private let notificationCenterLabel: UILabel = {
////        let label = UILabel()
////        label.text = "📻 NotificationCenter (Old Way)"
////        label.font = .boldSystemFont(ofSize: 16)
////        label.textColor = .systemBlue
////        label.translatesAutoresizingMaskIntoConstraints = false
////        return label
////    }()
////
////    private let notificationCenterTextView: UITextView = {
////        let textView = UITextView()
////        textView.font = .systemFont(ofSize: 12)
////        textView.isEditable = false
////        textView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
////        textView.layer.cornerRadius = 8
////        textView.text = "Waiting for notifications..."
////        textView.translatesAutoresizingMaskIntoConstraints = false
////        return textView
////    }()
////
////    // Combine @Published Section
////    private let publishedLabel: UILabel = {
////        let label = UILabel()
////        label.text = "📺 Combine @Published (New Way #1)"
////        label.font = .boldSystemFont(ofSize: 16)
////        label.textColor = .systemGreen
////        label.translatesAutoresizingMaskIntoConstraints = false
////        return label
////    }()
////
////    private let publishedTextView: UITextView = {
////        let textView = UITextView()
////        textView.font = .systemFont(ofSize: 12)
////        textView.isEditable = false
////        textView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
////        textView.layer.cornerRadius = 8
////        textView.text = "Waiting for notifications..."
////        textView.translatesAutoresizingMaskIntoConstraints = false
////        return textView
////    }()
////
////    // Combine Publisher Section
////    private let publisherLabel: UILabel = {
////        let label = UILabel()
////        label.text = "🎬 Combine Publisher (New Way #2)"
////        label.font = .boldSystemFont(ofSize: 16)
////        label.textColor = .systemOrange
////        label.translatesAutoresizingMaskIntoConstraints = false
////        return label
////    }()
////
////    private let publisherTextView: UITextView = {
////        let textView = UITextView()
////        textView.font = .systemFont(ofSize: 12)
////        textView.isEditable = false
////        textView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
////        textView.layer.cornerRadius = 8
////        textView.text = "Waiting for notifications..."
////        textView.translatesAutoresizingMaskIntoConstraints = false
////        return textView
////    }()
////
////    // Count Label (shows Combine reactivity)
////    private let countLabel: UILabel = {
////        let label = UILabel()
////        label.text = "Total: 0"
////        label.font = .boldSystemFont(ofSize: 18)
////        label.textAlignment = .center
////        label.textColor = .systemPurple
////        label.translatesAutoresizingMaskIntoConstraints = false
////        return label
////    }()
////
////    private let sendButton: UIButton = {
////        let button = UIButton(type: .system)
////        button.setTitle("📱 Send Notification to ALL", for: .normal)
////        button.backgroundColor = .systemIndigo
////        button.setTitleColor(.white, for: .normal)
////        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
////        button.layer.cornerRadius = 12
////        button.translatesAutoresizingMaskIntoConstraints = false
////        return button
////    }()
////
////    // ============================================
////    // PROPERTIES
////    // ============================================
////
////    private let service = PushNotificationService.shared
////
////    // Combine: Store subscriptions (like a "DVR" that records your streams)
////    private var cancellables = Set<AnyCancellable>()
////
////    private var notificationCenterCount = 0
////    private var publishedCount = 0
////    private var publisherCount = 0
////
////    // ============================================
////    // LIFECYCLE
////    // ============================================
////
////    override func viewDidLoad() {
////        super.viewDidLoad()
////        setupUI()
////
////        // Setup BOTH approaches
////        setupNotificationCenter()  // Old way
////        setupCombine()             // New way
////
////        print("\n📚 [ViewController] Ready - Listening via 3 different methods!")
////    }
////
////    deinit {
////        print("\n🧹 [ViewController] deinit")
////
////        // NotificationCenter cleanup (MANUAL)
////        NotificationCenter.default.removeObserver(self)
////        print("   ✅ Removed NotificationCenter observer")
////
////        // Combine cleanup (AUTOMATIC when cancellables go out of scope)
////        cancellables.removeAll()
////        print("   ✅ Cancelled Combine subscriptions")
////    }
////
////    // ============================================
////    // SETUP UI
////    // ============================================
////
////    private func setupUI() {
////        view.backgroundColor = .systemBackground
////
////        let scrollView = UIScrollView()
////        scrollView.translatesAutoresizingMaskIntoConstraints = false
////        view.addSubview(scrollView)
////
////        let contentStack = UIStackView(arrangedSubviews: [
////            titleLabel,
////            countLabel,
////            createSeparator(),
////            notificationCenterLabel,
////            notificationCenterTextView,
////            createSeparator(),
////            publishedLabel,
////            publishedTextView,
////            createSeparator(),
////            publisherLabel,
////            publisherTextView
////        ])
////        contentStack.axis = .vertical
////        contentStack.spacing = 12
////        contentStack.translatesAutoresizingMaskIntoConstraints = false
////        scrollView.addSubview(contentStack)
////
////        view.addSubview(sendButton)
////
////        NSLayoutConstraint.activate([
////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
////            scrollView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -16),
////
////            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
////            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
////            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
////            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
////            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
////
////            notificationCenterTextView.heightAnchor.constraint(equalToConstant: 120),
////            publishedTextView.heightAnchor.constraint(equalToConstant: 120),
////            publisherTextView.heightAnchor.constraint(equalToConstant: 120),
////
////            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
////            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
////            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
////            sendButton.heightAnchor.constraint(equalToConstant: 50)
////        ])
////
////        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
////    }
////
////    private func createSeparator() -> UIView {
////        let separator = UIView()
////        separator.backgroundColor = .separator
////        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
////        return separator
////    }
////
////    // ============================================
////    // SETUP: NotificationCenter (OLD WAY)
////    // ============================================
////
////    private func setupNotificationCenter() {
////        print("\n📝 [Setup] NotificationCenter approach:")
////        print("   - Using addObserver with selector")
////        print("   - Manual cleanup required in deinit")
////
////        NotificationCenter.default.addObserver(
////            self,
////            selector: #selector(handleNotificationCenterNotification(_:)),
////            name: .pushNotificationReceived,
////            object: nil
////        )
////
////        print("   ✅ Registered observer")
////    }
////
////    @objc private func handleNotificationCenterNotification(_ notification: Notification) {
////        print("\n📻 [NotificationCenter] Received!")
////
////        guard let payload = notification.userInfo?["payload"] as? PushNotificationPayload else {
////            return
////        }
////
////        notificationCenterCount += 1
////
////        let text = """
////        [NotificationCenter Method]
////        Received: #\(notificationCenterCount)
////
////        Title: \(payload.title)
////        Message: \(payload.message)
////        Time: \(formatTime(payload.timestamp))
////
////        ⚠️ OLD WAY:
////        • Uses selector (@objc method)
////        • Manual cleanup needed
////        • Type-unsafe userInfo
////        """
////
////        notificationCenterTextView.text = text
////        print("   Updated NotificationCenter UI")
////    }
////
////    // ============================================
////    // SETUP: Combine (NEW WAY)
////    // ============================================
////
////    private func setupCombine() {
////        print("\n📝 [Setup] Combine approaches:")
////
////        // ----------------------------------------
////        // APPROACH 1: @Published Property
////        // ----------------------------------------
////        print("\n   Method 1: @Published")
////        print("   - Observing latestNotification property")
////        print("   - Automatically receives updates")
////
////        service.$latestNotification
////            .compactMap { $0 }  // Filter out nil values
////            .sink { [weak self] payload in
////                self?.handlePublishedNotification(payload)
////            }
////            .store(in: &cancellables)
////
////        print("   ✅ Subscribed to @Published")
////
////        // ----------------------------------------
////        // APPROACH 2: PassthroughSubject Publisher
////        // ----------------------------------------
////        print("\n   Method 2: Publisher")
////        print("   - Observing notificationPublisher stream")
////        print("   - Receives events as they're sent")
////
////        service.notificationPublisher
////            .sink { [weak self] payload in
////                self?.handlePublisherNotification(payload)
////            }
////            .store(in: &cancellables)
////
////        print("   ✅ Subscribed to Publisher")
////
////        // ----------------------------------------
////        // BONUS: Observe Count Changes
////        // ----------------------------------------
////        print("\n   Bonus: Observing count")
////
////        service.$notificationCount
////            .map { "Total: \($0)" }
////            .assign(to: \.text, on: countLabel)
////            .store(in: &cancellables)
////
////        print("   ✅ Auto-updating count label")
////
////        print("\n   🎉 All Combine subscriptions active!")
////        print("   📦 Stored in cancellables Set (auto-cleanup)")
////    }
////
////    private func handlePublishedNotification(_ payload: PushNotificationPayload) {
////        print("\n📺 [Combine @Published] Received!")
////
////        publishedCount += 1
////
////        let text = """
////        [@Published Method]
////        Received: #\(publishedCount)
////
////        Title: \(payload.title)
////        Message: \(payload.message)
////        Time: \(formatTime(payload.timestamp))
////
////        ✨ NEW WAY #1:
////        • Reactive property
////        • Auto cleanup
////        • Type-safe
////        • Modern Swift
////        """
////
////        publishedTextView.text = text
////        print("   Updated @Published UI")
////    }
////
////    private func handlePublisherNotification(_ payload: PushNotificationPayload) {
////        print("\n🎬 [Combine Publisher] Received!")
////
////        publisherCount += 1
////
////        let text = """
////        [Publisher Method]
////        Received: #\(publisherCount)
////
////        Title: \(payload.title)
////        Message: \(payload.message)
////        Time: \(formatTime(payload.timestamp))
////
////        ✨ NEW WAY #2:
////        • Event stream
////        • Auto cleanup
////        • Type-safe
////        • Composable
////        """
////
////        publisherTextView.text = text
////        print("   Updated Publisher UI")
////    }
////
////    // ============================================
////    // ACTIONS
////    // ============================================
////
////    @objc private func sendButtonTapped() {
////        print("\n" + String(repeating: "=", count: 60))
////        print("🎬 [User Action] Send button tapped")
////        print(String(repeating: "=", count: 60))
////
////        service.sendRandomNotification()
////
////        print("\n💡 RESULT: All 3 methods received the same notification!")
////        print("   • NotificationCenter: via selector")
////        print("   • @Published: via property observer")
////        print("   • Publisher: via stream")
////    }
////
////    private func formatTime(_ date: Date) -> String {
////        let formatter = DateFormatter()
////        formatter.dateFormat = "HH:mm:ss.SSS"
////        return formatter.string(from: date)
////    }
////}
////
//////import UIKit
//////import Combine
//////
//////class ViewController : UIViewController {
//////
//////    private let titleLabel : UILabel = {
//////        let label = UILabel()
//////        label.text = "NotificationCenter vs Combine"
//////        label.font = .boldSystemFont(ofSize: 20)
//////        label.textAlignment = .center
//////        label.translatesAutoresizingMaskIntoConstraints = false
//////        return label
//////    }()
//////
//////    private let notificationCenterLabel : UILabel = {
//////        let label = UILabel()
//////        label.text = "📻 NotificationCenter (Old Way)"
//////        label.font = .boldSystemFont(ofSize: 16)
//////        label.textColor = .systemBlue
//////        label.translatesAutoresizingMaskIntoConstraints = false
//////        return label
//////    }()
//////
//////    private let notificationCenterTextView : UITextView = {
//////        let textView = UITextView()
//////        textView.font = .systemFont(ofSize: 12)
//////        textView.isEditable = false
//////        textView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
//////        textView.layer.cornerRadius = 8
//////        textView.text = "Waiting for notifications..."
//////        textView.translatesAutoresizingMaskIntoConstraints = false
//////        return textView
//////    }()
//////
//////    // Combine @Published Section
//////    private let publishedLabel: UILabel = {
//////        let label = UILabel()
//////        label.text = "📺 Combine @Published (New Way #1)"
//////        label.font = .boldSystemFont(ofSize: 16)
//////        label.textColor = .systemGreen
//////        label.translatesAutoresizingMaskIntoConstraints = false
//////        return label
//////    }()
//////
//////    private let publishedTextView: UITextView = {
//////        let textView = UITextView()
//////        textView.font = .systemFont(ofSize: 12)
//////        textView.isEditable = false
//////        textView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
//////        textView.layer.cornerRadius = 8
//////        textView.text = "Waiting for notifications..."
//////        textView.translatesAutoresizingMaskIntoConstraints = false
//////        return textView
//////    }()
//////
//////    // Combine Publisher Section
//////    private let publisherLabel: UILabel = {
//////        let label = UILabel()
//////        label.text = "🎬 Combine Publisher (New Way #2)"
//////        label.font = .boldSystemFont(ofSize: 16)
//////        label.textColor = .systemOrange
//////        label.translatesAutoresizingMaskIntoConstraints = false
//////        return label
//////    }()
//////
//////    private let publisherTextView: UITextView = {
//////        let textView = UITextView()
//////        textView.font = .systemFont(ofSize: 12)
//////        textView.isEditable = false
//////        textView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
//////        textView.layer.cornerRadius = 8
//////        textView.text = "Waiting for notifications..."
//////        textView.translatesAutoresizingMaskIntoConstraints = false
//////        return textView
//////    }()
//////
//////    private let countLabel: UILabel = {
//////        let label = UILabel()
//////        label.text = "Total: 0"
//////        label.font = .boldSystemFont(ofSize: 18)
//////        label.textAlignment = .center
//////        label.textColor = .systemPurple
//////        label.translatesAutoresizingMaskIntoConstraints = false
//////        return label
//////    }()
//////
//////    private let sendButton: UIButton = {
//////        let button = UIButton(type: .system)
//////        button.setTitle("📱 Send Notification to ALL", for: .normal)
//////        button.backgroundColor = .systemIndigo
//////        button.setTitleColor(.white, for: .normal)
//////        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
//////        button.layer.cornerRadius = 12
//////        button.translatesAutoresizingMaskIntoConstraints = false
//////        return button
//////    }()
//////
//////    private let sharedService = PushNotificationService.shared
//////
//////    private var cancellables = Set<AnyCancellable>()
//////
//////    private var notificationCenterCount = 0
//////    private var publishedCount = 0
//////    private var publisherCount = 0
//////
//////    override func viewDidLoad() {
//////        super.viewDidLoad()
//////        setupUI()
//////        setupNotificationCenter()
//////        setupCombine()
//////    }
//////
//////
//////    private func setupUI() {
//////        view.backgroundColor = .systemBackground
//////
//////        let scrollView = UIScrollView()
//////        scrollView.translatesAutoresizingMaskIntoConstraints = false
//////        view.addSubview(scrollView)
//////
//////        let contentStack = UIStackView(arrangedSubviews: [
//////            titleLabel,
//////            countLabel,
//////            createSeparator(),
//////            notificationCenterLabel,
//////            notificationCenterTextView,
//////            createSeparator(),
//////            publishedLabel,
//////            publishedTextView,
//////            createSeparator(),
//////            publisherLabel,
//////            publisherTextView
//////        ])
//////        contentStack.axis = .vertical
//////        contentStack.spacing = 12
//////        contentStack.translatesAutoresizingMaskIntoConstraints = false
//////        scrollView.addSubview(contentStack)
//////
//////        view.addSubview(sendButton)
//////
//////        NSLayoutConstraint.activate([
//////            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//////            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//////            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//////            scrollView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -16),
//////
//////            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
//////            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
//////            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
//////            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
//////            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
//////
//////            notificationCenterTextView.heightAnchor.constraint(equalToConstant: 120),
//////            publishedTextView.heightAnchor.constraint(equalToConstant: 120),
//////            publisherTextView.heightAnchor.constraint(equalToConstant: 120),
//////
//////            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//////            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//////            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//////            sendButton.heightAnchor.constraint(equalToConstant: 50)
//////        ])
//////
//////        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
//////    }
//////
//////    @objc private func sendButtonTapped() {
//////        sharedService.sendRandomNotification()
//////    }
//////
//////    private func createSeparator() -> UIView {
//////        let separator = UIView()
//////        separator.backgroundColor = .separator
//////        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
//////        return separator
//////    }
//////
//////    private func setupNotificationCenter() {
//////        NotificationCenter.default.addObserver(
//////            self,
//////            selector: #selector(handleNotificationCenter(_ : )),
//////            name: .pushNotificationReceived,
//////            object: nil
//////        )
//////    }
//////
//////    @objc func handleNotificationCenter(_ notificationPayload : Notification){
//////        guard let payload = notificationPayload.userInfo?["payload"] as? PushNotificationPayload else {
//////            return
//////        }
//////        notificationCenterCount += 1
//////        let text = """
//////            Title : \(payload.title)
//////        """
//////        notificationCenterTextView.text = text
//////    }
//////
//////    private func setupCombine() {
//////        sharedService.$latestNotification
//////            .compactMap { $0 }
//////            .sink {
//////                [weak self] payload in
//////                self?.publishedCount += 1
//////                self?.publishedTextView.text = "Title : \(payload.title)"
//////            }
//////            .store(in: &cancellables)
//////
//////        sharedService.notificationPublisher
//////            .sink { [weak self] payload in
//////                <#code#>
//////            }
//////    }
//////}
/////
/////
//// ViewControllers.swift
//
//import UIKit
//import Combine
//
//// MARK: - Home View Controller
//
//class HomeViewController: UIViewController {
//
//    private var cancellables = Set<AnyCancellable>()
//
//    // UI Components
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "🏠 Home Screen"
//        label.font = .boldSystemFont(ofSize: 28)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let notificationCountLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Notifications: 0"
//        label.font = .systemFont(ofSize: 16)
//        label.textAlignment = .center
//        label.textColor = .gray
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let historyTextView: UITextView = {
//        let textView = UITextView()
//        textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
//        textView.isEditable = false
//        textView.backgroundColor = .systemGray6
//        textView.layer.cornerRadius = 8
//        textView.text = "Waiting for notifications..."
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }()
//
//    private let sendHomeButton = createButton(
//        title: "📱 Send Home Notification",
//        color: .systemBlue
//    )
//
//    private let sendProfileButton = createButton(
//        title: "👤 Send Profile Notification",
//        color: .systemGreen
//    )
//
//    private let sendSettingsButton = createButton(
//        title: "⚙️ Send Settings Notification",
//        color: .systemOrange
//    )
//
//    private let sendRandomButton = createButton(
//        title: "🎲 Send Random Notification",
//        color: .systemPurple
//    )
//
//    private var notificationHistory: [String] = []
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupBindings()
//    }
//
//    // MARK: - Setup
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "Deep Link Demo"
//
//        let buttonStack = UIStackView(arrangedSubviews: [
//            sendHomeButton,
//            sendProfileButton,
//            sendSettingsButton,
//            sendRandomButton
//        ])
//        buttonStack.axis = .vertical
//        buttonStack.spacing = 12
//        buttonStack.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(titleLabel)
//        view.addSubview(notificationCountLabel)
//        view.addSubview(historyTextView)
//        view.addSubview(buttonStack)
//
//        NSLayoutConstraint.activate([
//            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            notificationCountLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
//            notificationCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            notificationCountLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//
//            historyTextView.topAnchor.constraint(equalTo: notificationCountLabel.bottomAnchor, constant: 16),
//            historyTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            historyTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            historyTextView.heightAnchor.constraint(equalToConstant: 200),
//
//            buttonStack.topAnchor.constraint(equalTo: historyTextView.bottomAnchor, constant: 16),
//            buttonStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            buttonStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            buttonStack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16)
//        ])
//
//        sendHomeButton.addTarget(self, action: #selector(sendHomeNotification), for: .touchUpInside)
//        sendProfileButton.addTarget(self, action: #selector(sendProfileNotification), for: .touchUpInside)
//        sendSettingsButton.addTarget(self, action: #selector(sendSettingsNotification), for: .touchUpInside)
//        sendRandomButton.addTarget(self, action: #selector(sendRandomNotification), for: .touchUpInside)
//    }
//
//    private func setupBindings() {
//        // Subscribe to notification count
//        NotificationService.shared.$notificationCount
//            .map { "Notifications: \($0)" }
//            .receive(on: DispatchQueue.main)
//            .assign(to: \.text, on: notificationCountLabel)
//            .store(in: &cancellables)
//
//        // Subscribe to notifications
//        NotificationService.shared.notificationPublisher
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] notification in
//                self?.addToHistory(notification)
//            }
//            .store(in: &cancellables)
//    }
//
//    private func addToHistory(_ notification: PushNotification) {
//        let formatter = DateFormatter()
//        formatter.dateFormat = "HH:mm:ss"
//        let time = formatter.string(from: notification.timestamp)
//
//        let entry = """
//        [\(time)] 📬
//        \(notification.title)
//        \(notification.body)
//        Link: \(notification.deepLink.urlString)
//        ────────────────────────────
//        """
//
//        notificationHistory.insert(entry, at: 0)
//        historyTextView.text = notificationHistory.joined(separator: "\n")
//    }
//
//    // MARK: - Actions
//
//    @objc private func sendHomeNotification() {
//        MockAPNSServer.shared.sendHomeNotification()
//    }
//
//    @objc private func sendProfileNotification() {
//        MockAPNSServer.shared.sendProfileNotification(userId: "user\(Int.random(in: 100...999))")
//    }
//
//    @objc private func sendSettingsNotification() {
//        MockAPNSServer.shared.sendSettingsNotification()
//    }
//
//    @objc private func sendRandomNotification() {
//        MockAPNSServer.shared.sendRandomNotification()
//    }
//
//    private static func createButton(title: String, color: UIColor) -> UIButton {
//        let button = UIButton(type: .system)
//        button.setTitle(title, for: .normal)
//        button.backgroundColor = color
//        button.setTitleColor(.white, for: .normal)
//        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
//        button.layer.cornerRadius = 12
//        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
//        return button
//    }
//}
//
//// MARK: - Profile View Controller
//
//class ProfileViewController: UIViewController {
//
//    private let userId: String
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.font = .boldSystemFont(ofSize: 28)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let messageLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 18)
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    init(userId: String) {
//        self.userId = userId
//        super.init(nibName: nil, bundle: nil)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//    }
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "Profile"
//
//        titleLabel.text = "👤 Profile Screen"
//        messageLabel.text = """
//        Navigated via Deep Link!
//        
//        User ID: \(userId)
//        
//        This screen was opened from
//        a push notification containing
//        the deep link:
//        
//        myapp://profile/\(userId)
//        """
//
//        view.addSubview(titleLabel)
//        view.addSubview(messageLabel)
//
//        NSLayoutConstraint.activate([
//            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
//
//            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
//            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
//        ])
//    }
//}
//
//// MARK: - Settings View Controller
//
//class SettingsViewController: UIViewController {
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "⚙️ Settings Screen"
//        label.font = .boldSystemFont(ofSize: 28)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let messageLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 18)
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.text = """
//        Navigated via Deep Link!
//        
//        myapp://settings
//        """
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//    }
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//        title = "Settings"
//
//        view.addSubview(titleLabel)
//        view.addSubview(messageLabel)
//
//        NSLayoutConstraint.activate([
//            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60),
//
//            messageLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            messageLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 40),
//            messageLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
//            messageLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32)
//        ])
//    }
//}
//
//
