////
////  ViewController.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 16/11/25.
////
//
//// ViewController.swift
//
import UIKit
import Combine

class ViewController: UIViewController {

    // ============================================
    // UI COMPONENTS
    // ============================================

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "NotificationCenter vs Combine"
        label.font = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // NotificationCenter Section
    private let notificationCenterLabel: UILabel = {
        let label = UILabel()
        label.text = "📻 NotificationCenter (Old Way)"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let notificationCenterTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 12)
        textView.isEditable = false
        textView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        textView.layer.cornerRadius = 8
        textView.text = "Waiting for notifications..."
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // Combine @Published Section
    private let publishedLabel: UILabel = {
        let label = UILabel()
        label.text = "📺 Combine @Published (New Way #1)"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .systemGreen
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let publishedTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 12)
        textView.isEditable = false
        textView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
        textView.layer.cornerRadius = 8
        textView.text = "Waiting for notifications..."
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // Combine Publisher Section
    private let publisherLabel: UILabel = {
        let label = UILabel()
        label.text = "🎬 Combine Publisher (New Way #2)"
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .systemOrange
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let publisherTextView: UITextView = {
        let textView = UITextView()
        textView.font = .systemFont(ofSize: 12)
        textView.isEditable = false
        textView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
        textView.layer.cornerRadius = 8
        textView.text = "Waiting for notifications..."
        textView.translatesAutoresizingMaskIntoConstraints = false
        return textView
    }()

    // Count Label (shows Combine reactivity)
    private let countLabel: UILabel = {
        let label = UILabel()
        label.text = "Total: 0"
        label.font = .boldSystemFont(ofSize: 18)
        label.textAlignment = .center
        label.textColor = .systemPurple
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let sendButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("📱 Send Notification to ALL", for: .normal)
        button.backgroundColor = .systemIndigo
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    // ============================================
    // PROPERTIES
    // ============================================

    private let service = PushNotificationService.shared

    // Combine: Store subscriptions (like a "DVR" that records your streams)
    private var cancellables = Set<AnyCancellable>()

    private var notificationCenterCount = 0
    private var publishedCount = 0
    private var publisherCount = 0

    // ============================================
    // LIFECYCLE
    // ============================================

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Setup BOTH approaches
        setupNotificationCenter()  // Old way
        setupCombine()             // New way

        print("\n📚 [ViewController] Ready - Listening via 3 different methods!")
    }

    deinit {
        print("\n🧹 [ViewController] deinit")

        // NotificationCenter cleanup (MANUAL)
        NotificationCenter.default.removeObserver(self)
        print("   ✅ Removed NotificationCenter observer")

        // Combine cleanup (AUTOMATIC when cancellables go out of scope)
        cancellables.removeAll()
        print("   ✅ Cancelled Combine subscriptions")
    }

    // ============================================
    // SETUP UI
    // ============================================

    private func setupUI() {
        view.backgroundColor = .systemBackground

        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentStack = UIStackView(arrangedSubviews: [
            titleLabel,
            countLabel,
            createSeparator(),
            notificationCenterLabel,
            notificationCenterTextView,
            createSeparator(),
            publishedLabel,
            publishedTextView,
            createSeparator(),
            publisherLabel,
            publisherTextView
        ])
        contentStack.axis = .vertical
        contentStack.spacing = 12
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        view.addSubview(sendButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -16),

            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),

            notificationCenterTextView.heightAnchor.constraint(equalToConstant: 120),
            publishedTextView.heightAnchor.constraint(equalToConstant: 120),
            publisherTextView.heightAnchor.constraint(equalToConstant: 120),

            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            sendButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
    }

    private func createSeparator() -> UIView {
        let separator = UIView()
        separator.backgroundColor = .separator
        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
        return separator
    }

    // ============================================
    // SETUP: NotificationCenter (OLD WAY)
    // ============================================

    private func setupNotificationCenter() {
        print("\n📝 [Setup] NotificationCenter approach:")
        print("   - Using addObserver with selector")
        print("   - Manual cleanup required in deinit")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleNotificationCenterNotification(_:)),
            name: .pushNotificationReceived,
            object: nil
        )

        print("   ✅ Registered observer")
    }

    @objc private func handleNotificationCenterNotification(_ notification: Notification) {
        print("\n📻 [NotificationCenter] Received!")

        guard let payload = notification.userInfo?["payload"] as? PushNotificationPayload else {
            return
        }

        notificationCenterCount += 1

        let text = """
        [NotificationCenter Method]
        Received: #\(notificationCenterCount)

        Title: \(payload.title)
        Message: \(payload.message)
        Time: \(formatTime(payload.timestamp))

        ⚠️ OLD WAY:
        • Uses selector (@objc method)
        • Manual cleanup needed
        • Type-unsafe userInfo
        """

        notificationCenterTextView.text = text
        print("   Updated NotificationCenter UI")
    }

    // ============================================
    // SETUP: Combine (NEW WAY)
    // ============================================

    private func setupCombine() {
        print("\n📝 [Setup] Combine approaches:")

        // ----------------------------------------
        // APPROACH 1: @Published Property
        // ----------------------------------------
        print("\n   Method 1: @Published")
        print("   - Observing latestNotification property")
        print("   - Automatically receives updates")

        service.$latestNotification
            .compactMap { $0 }  // Filter out nil values
            .sink { [weak self] payload in
                self?.handlePublishedNotification(payload)
            }
            .store(in: &cancellables)

        print("   ✅ Subscribed to @Published")

        // ----------------------------------------
        // APPROACH 2: PassthroughSubject Publisher
        // ----------------------------------------
        print("\n   Method 2: Publisher")
        print("   - Observing notificationPublisher stream")
        print("   - Receives events as they're sent")

        service.notificationPublisher
            .sink { [weak self] payload in
                self?.handlePublisherNotification(payload)
            }
            .store(in: &cancellables)

        print("   ✅ Subscribed to Publisher")

        // ----------------------------------------
        // BONUS: Observe Count Changes
        // ----------------------------------------
        print("\n   Bonus: Observing count")

        service.$notificationCount
            .map { "Total: \($0)" }
            .assign(to: \.text, on: countLabel)
            .store(in: &cancellables)

        print("   ✅ Auto-updating count label")

        print("\n   🎉 All Combine subscriptions active!")
        print("   📦 Stored in cancellables Set (auto-cleanup)")
    }

    private func handlePublishedNotification(_ payload: PushNotificationPayload) {
        print("\n📺 [Combine @Published] Received!")

        publishedCount += 1

        let text = """
        [@Published Method]
        Received: #\(publishedCount)

        Title: \(payload.title)
        Message: \(payload.message)
        Time: \(formatTime(payload.timestamp))

        ✨ NEW WAY #1:
        • Reactive property
        • Auto cleanup
        • Type-safe
        • Modern Swift
        """

        publishedTextView.text = text
        print("   Updated @Published UI")
    }

    private func handlePublisherNotification(_ payload: PushNotificationPayload) {
        print("\n🎬 [Combine Publisher] Received!")

        publisherCount += 1

        let text = """
        [Publisher Method]
        Received: #\(publisherCount)

        Title: \(payload.title)
        Message: \(payload.message)
        Time: \(formatTime(payload.timestamp))

        ✨ NEW WAY #2:
        • Event stream
        • Auto cleanup
        • Type-safe
        • Composable
        """

        publisherTextView.text = text
        print("   Updated Publisher UI")
    }

    // ============================================
    // ACTIONS
    // ============================================

    @objc private func sendButtonTapped() {
        print("\n" + String(repeating: "=", count: 60))
        print("🎬 [User Action] Send button tapped")
        print(String(repeating: "=", count: 60))

        service.sendRandomNotification()

        print("\n💡 RESULT: All 3 methods received the same notification!")
        print("   • NotificationCenter: via selector")
        print("   • @Published: via property observer")
        print("   • Publisher: via stream")
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: date)
    }
}

//import UIKit
//import Combine
//
//class ViewController : UIViewController {
//
//    private let titleLabel : UILabel = {
//        let label = UILabel()
//        label.text = "NotificationCenter vs Combine"
//        label.font = .boldSystemFont(ofSize: 20)
//        label.textAlignment = .center
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let notificationCenterLabel : UILabel = {
//        let label = UILabel()
//        label.text = "📻 NotificationCenter (Old Way)"
//        label.font = .boldSystemFont(ofSize: 16)
//        label.textColor = .systemBlue
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let notificationCenterTextView : UITextView = {
//        let textView = UITextView()
//        textView.font = .systemFont(ofSize: 12)
//        textView.isEditable = false
//        textView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
//        textView.layer.cornerRadius = 8
//        textView.text = "Waiting for notifications..."
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }()
//
//    // Combine @Published Section
//    private let publishedLabel: UILabel = {
//        let label = UILabel()
//        label.text = "📺 Combine @Published (New Way #1)"
//        label.font = .boldSystemFont(ofSize: 16)
//        label.textColor = .systemGreen
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let publishedTextView: UITextView = {
//        let textView = UITextView()
//        textView.font = .systemFont(ofSize: 12)
//        textView.isEditable = false
//        textView.backgroundColor = .systemGreen.withAlphaComponent(0.1)
//        textView.layer.cornerRadius = 8
//        textView.text = "Waiting for notifications..."
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }()
//
//    // Combine Publisher Section
//    private let publisherLabel: UILabel = {
//        let label = UILabel()
//        label.text = "🎬 Combine Publisher (New Way #2)"
//        label.font = .boldSystemFont(ofSize: 16)
//        label.textColor = .systemOrange
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let publisherTextView: UITextView = {
//        let textView = UITextView()
//        textView.font = .systemFont(ofSize: 12)
//        textView.isEditable = false
//        textView.backgroundColor = .systemOrange.withAlphaComponent(0.1)
//        textView.layer.cornerRadius = 8
//        textView.text = "Waiting for notifications..."
//        textView.translatesAutoresizingMaskIntoConstraints = false
//        return textView
//    }()
//
//    private let countLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Total: 0"
//        label.font = .boldSystemFont(ofSize: 18)
//        label.textAlignment = .center
//        label.textColor = .systemPurple
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private let sendButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("📱 Send Notification to ALL", for: .normal)
//        button.backgroundColor = .systemIndigo
//        button.setTitleColor(.white, for: .normal)
//        button.titleLabel?.font = .boldSystemFont(ofSize: 16)
//        button.layer.cornerRadius = 12
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//
//    private let sharedService = PushNotificationService.shared
//
//    private var cancellables = Set<AnyCancellable>()
//
//    private var notificationCenterCount = 0
//    private var publishedCount = 0
//    private var publisherCount = 0
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupNotificationCenter()
//        setupCombine()
//    }
//
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//
//        let scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(scrollView)
//
//        let contentStack = UIStackView(arrangedSubviews: [
//            titleLabel,
//            countLabel,
//            createSeparator(),
//            notificationCenterLabel,
//            notificationCenterTextView,
//            createSeparator(),
//            publishedLabel,
//            publishedTextView,
//            createSeparator(),
//            publisherLabel,
//            publisherTextView
//        ])
//        contentStack.axis = .vertical
//        contentStack.spacing = 12
//        contentStack.translatesAutoresizingMaskIntoConstraints = false
//        scrollView.addSubview(contentStack)
//
//        view.addSubview(sendButton)
//
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: sendButton.topAnchor, constant: -16),
//
//            contentStack.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 16),
//            contentStack.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
//            contentStack.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
//            contentStack.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -16),
//            contentStack.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32),
//
//            notificationCenterTextView.heightAnchor.constraint(equalToConstant: 120),
//            publishedTextView.heightAnchor.constraint(equalToConstant: 120),
//            publisherTextView.heightAnchor.constraint(equalToConstant: 120),
//
//            sendButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            sendButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
//            sendButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
//            sendButton.heightAnchor.constraint(equalToConstant: 50)
//        ])
//
//        sendButton.addTarget(self, action: #selector(sendButtonTapped), for: .touchUpInside)
//    }
//
//    @objc private func sendButtonTapped() {
//        sharedService.sendRandomNotification()
//    }
//
//    private func createSeparator() -> UIView {
//        let separator = UIView()
//        separator.backgroundColor = .separator
//        separator.heightAnchor.constraint(equalToConstant: 1).isActive = true
//        return separator
//    }
//
//    private func setupNotificationCenter() {
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleNotificationCenter(_ : )),
//            name: .pushNotificationReceived,
//            object: nil
//        )
//    }
//
//    @objc func handleNotificationCenter(_ notificationPayload : Notification){
//        guard let payload = notificationPayload.userInfo?["payload"] as? PushNotificationPayload else {
//            return
//        }
//        notificationCenterCount += 1
//        let text = """
//            Title : \(payload.title)
//        """
//        notificationCenterTextView.text = text
//    }
//
//    private func setupCombine() {
//        sharedService.$latestNotification
//            .compactMap { $0 }
//            .sink {
//                [weak self] payload in
//                self?.publishedCount += 1
//                self?.publishedTextView.text = "Title : \(payload.title)"
//            }
//            .store(in: &cancellables)
//
//        sharedService.notificationPublisher
//            .sink { [weak self] payload in
//                <#code#>
//            }
//    }
//}
