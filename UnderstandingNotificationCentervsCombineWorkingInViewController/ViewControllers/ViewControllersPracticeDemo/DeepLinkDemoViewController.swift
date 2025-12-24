//
//  DeepLinkDemoViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

// ═══════════════════════════════════════════════════════════════════════════
// DEEP LINK HANDLER - Parses URLs and determines where to go
// ═══════════════════════════════════════════════════════════════════════════

class DeepLinkHandler {

    // Singleton
    static let shared = DeepLinkHandler()
    private init() {}

    // Define all possible destinations
    enum Destination {
        case home
        case product(id: String)
        case user(id: String)
        case search(query: String)
        case settings
    }

    // Parse URL and return destination
    func parse(url: URL) -> Destination? {
        print("🔗 Parsing URL: \(url)")

        // URL Scheme format: deeplink-demo://products/123
        // - scheme: "deeplink-demo"
        // - host: "products"
        // - path: "/123"

        // OR for path-based: deeplink-demo://app/products/123
        // - scheme: "deeplink-demo"
        // - host: "app"
        // - path: "/products/123"

        guard let host = url.host else {
            print("❌ No host in URL")
            return nil
        }

        // Get path components (remove empty strings)
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        print("   Host: \(host)")
        print("   Path: \(pathComponents)")

        // Route based on host
        switch host {
        case "products", "product":
            // deeplink-demo://products/123
            if let productId = pathComponents.first {
                return .product(id: productId)
            }

        case "users", "user":
            // deeplink-demo://user/456
            if let userId = pathComponents.first {
                return .user(id: userId)
            }

        case "search":
            // deeplink-demo://search?q=iphone
            if let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
               let query = queryItems.first(where: { $0.name == "q" })?.value {
                return .search(query: query)
            }

        case "settings":
            // deeplink-demo://settings
            return .settings

        case "home":
            return .home

        default:
            print("❌ Unknown host: \(host)")
        }

        return nil
    }
}



// ═══════════════════════════════════════════════════════════════════════════
// MAIN VIEW CONTROLLER
// ═══════════════════════════════════════════════════════════════════════════

class DeepLinkDemoViewController: UIViewController {

    // MARK: - UI Elements

    private let titleLabel = UILabel()
    private let statusLabel = UILabel()
    private let testLinksStack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        // Listen for deep link navigation
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDeepLinkNavigation),
            name: .didReceiveDeepLink,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Handle Deep Link

    @objc private func handleDeepLinkNavigation(_ notification: Notification) {
        guard let destination = notification.userInfo?["destination"] as? DeepLinkHandler.Destination else {
            return
        }

        navigate(to: destination)
    }

    func navigate(to destination: DeepLinkHandler.Destination) {
        var message = ""
        var color = UIColor.systemBlue

        switch destination {
        case .home:
            message = "🏠 Navigated to HOME"
            color = .systemGreen

        case .product(let id):
            message = "🛍️ Navigated to PRODUCT #\(id)"
            color = .systemOrange
            showProductScreen(id: id)

        case .user(let id):
            message = "👤 Navigated to USER #\(id)"
            color = .systemPurple

        case .search(let query):
            message = "🔍 Searching for: \"\(query)\""
            color = .systemTeal

        case .settings:
            message = "⚙️ Navigated to SETTINGS"
            color = .systemGray
        }

        // Update status
        statusLabel.text = message
        statusLabel.textColor = color

        print(message)
    }

    private func showProductScreen(id: String) {
        let productVC = ProductDetailViewController(productId: id)
        navigationController?.pushViewController(productVC, animated: true)
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Deep Link Demo"

        // Title
        titleLabel.text = "🔗 Deep Linking Demo"
        titleLabel.font = .systemFont(ofSize: 28, weight: .bold)
        titleLabel.textAlignment = .center

        // Status
        statusLabel.text = "Open a deep link to see navigation"
        statusLabel.font = .systemFont(ofSize: 16)
        statusLabel.textAlignment = .center
        statusLabel.numberOfLines = 0
        statusLabel.textColor = .secondaryLabel

        // Instructions
        let instructionLabel = UILabel()
        instructionLabel.text = """
        HOW TO TEST:
        
        1. Open Safari
        2. Type one of these URLs:
        
        • deeplink-demo://products/123
        • deeplink-demo://user/456
        • deeplink-demo://search?q=iphone
        • deeplink-demo://settings
        
        3. Tap "Open" when prompted
        """
        instructionLabel.numberOfLines = 0
        instructionLabel.font = .monospacedSystemFont(ofSize: 13, weight: .regular)
        instructionLabel.backgroundColor = .secondarySystemBackground
        instructionLabel.textColor = .label

        // Add padding to instruction label
        let instructionContainer = UIView()
        instructionContainer.backgroundColor = .secondarySystemBackground
        instructionContainer.layer.cornerRadius = 12
        instructionContainer.addSubview(instructionLabel)

        // Test buttons (simulate deep links)
        let productBtn = createButton(title: "📦 Test Product Link", action: #selector(testProductLink))
        let userBtn = createButton(title: "👤 Test User Link", action: #selector(testUserLink))
        let searchBtn = createButton(title: "🔍 Test Search Link", action: #selector(testSearchLink))

        testLinksStack.axis = .vertical
        testLinksStack.spacing = 12
        testLinksStack.addArrangedSubview(productBtn)
        testLinksStack.addArrangedSubview(userBtn)
        testLinksStack.addArrangedSubview(searchBtn)

        // Add to view
        [titleLabel, statusLabel, instructionContainer, testLinksStack].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }

        instructionLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            titleLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            statusLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            instructionContainer.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 30),
            instructionContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            instructionContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            instructionLabel.topAnchor.constraint(equalTo: instructionContainer.topAnchor, constant: 16),
            instructionLabel.leadingAnchor.constraint(equalTo: instructionContainer.leadingAnchor, constant: 16),
            instructionLabel.trailingAnchor.constraint(equalTo: instructionContainer.trailingAnchor, constant: -16),
            instructionLabel.bottomAnchor.constraint(equalTo: instructionContainer.bottomAnchor, constant: -16),

            testLinksStack.topAnchor.constraint(equalTo: instructionContainer.bottomAnchor, constant: 30),
            testLinksStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            testLinksStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40)
        ])
    }

    private func createButton(title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    // MARK: - Test Actions (Simulate Deep Links)

    @objc private func testProductLink() {
        let url = URL(string: "deeplink-demo://products/789")!
        handleIncomingURL(url)
    }

    @objc private func testUserLink() {
        let url = URL(string: "deeplink-demo://user/john123")!
        handleIncomingURL(url)
    }

    @objc private func testSearchLink() {
        let url = URL(string: "deeplink-demo://search?q=swift+tutorial")!
        handleIncomingURL(url)
    }

    private func handleIncomingURL(_ url: URL) {
        if let destination = DeepLinkHandler.shared.parse(url: url) {
            navigate(to: destination)
        }
    }
}

// MARK: - Notification Extension

extension Notification.Name {
    static let didReceiveDeepLink = Notification.Name("didReceiveDeepLink")
}

class ProductDetailViewController: UIViewController {

    let productId: String

    init(productId: String) {
        self.productId = productId
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemOrange.withAlphaComponent(0.2)
        title = "Product #\(productId)"

        let label = UILabel()
        label.text = "🛍️\n\nProduct Details\n\nID: \(productId)"
        label.font = .systemFont(ofSize: 24, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)

        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }
}
