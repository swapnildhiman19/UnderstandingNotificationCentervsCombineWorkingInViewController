//
//  ObserverNotificationUnderstandingViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 14/12/25.
//

import UIKit

extension Notification.Name {
    static let userDidLogin = Notification.Name("userDidLogin")
    static let userDidLogout = Notification.Name("userDidLogout")
    static let cartDidUpdate = Notification.Name("cartDidUpdate")
}

struct User {
    let id : Int
    let name: String
    let email: String
}

class AuthService {
    static let shared = AuthService()

    private(set) var currentUser: User?

    func login(name: String, email: String){
        //mock login
        let user = User(
            id: Int.random(in: 1...1000),
            name: name,
            email: email
        )
        currentUser = user

        print("AuthService: User logged in : \(user.name)")

        NotificationCenter.default
            .post(
                name: .userDidLogin,
                object: self,
                userInfo: ["user":user]
            )
    }

    func logout() {
        let userName = currentUser?.name ?? "unknown"
        currentUser = nil
        print("AuthSerice: User logged out : \(userName)")
        NotificationCenter.default
            .post(name: .userDidLogout, object: self)
    }
}

// Broadcaster
class CartService {
    static let shared = CartService()

    private init() {}
    private(set) var items : [String] = []

    var itemCount : Int {items.count}

    func addItem(_ item: String) {
        items.append(item)
        print("Cart Service : Added item \(item) : Total : \(items.count)")
        NotificationCenter.default
            .post(
                name: .cartDidUpdate,
                object: self,
                userInfo: ["itemCount": itemCount]
            )
    }

    func clearCart() {
        items.removeAll()
        print("CartService: Cart cleared")
        NotificationCenter.default
            .post(name: .cartDidUpdate, object: self, userInfo: ["itemCount": 0])
    }
}

class MainViewController : UIViewController {
    // MARK: - UI Elements

        private let statusLabel: UILabel = {
            let label = UILabel()
            label.text = "Not logged in"
            label.font = .systemFont(ofSize: 18, weight: .medium)
            label.textAlignment = .center
            label.numberOfLines = 0
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let cartBadgeLabel: UILabel = {
            let label = UILabel()
            label.text = "🛒 Cart: 0 items"
            label.font = .systemFont(ofSize: 16)
            label.textAlignment = .center
            label.translatesAutoresizingMaskIntoConstraints = false
            return label
        }()

        private let loginButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Login", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = .systemBlue
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        private let logoutButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Logout", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = .systemRed
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.isHidden = true
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        private let addToCartButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Add Item to Cart", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
            button.backgroundColor = .systemGreen
            button.setTitleColor(.white, for: .normal)
            button.layer.cornerRadius = 8
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        private let clearCartButton: UIButton = {
            let button = UIButton(type: .system)
            button.setTitle("Clear Cart", for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14)
            button.setTitleColor(.systemOrange, for: .normal)
            button.translatesAutoresizingMaskIntoConstraints = false
            return button
        }()

        private let logTextView: UITextView = {
            let textView = UITextView()
            textView.isEditable = false
            textView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
            textView.backgroundColor = .secondarySystemBackground
            textView.layer.cornerRadius = 8
            textView.text = "📝 Event Log:\n"
            textView.translatesAutoresizingMaskIntoConstraints = false
            return textView
        }()

    override func viewDidLoad(){
        super.viewDidLoad()
        setupUI()
        setupActions()
        setupNotificationObservers()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        print("MainViewController has been deallocated")
    }

    private func setupUI() {
        title = "Observer Pattern Demo"
        view.backgroundColor = .systemBackground

        let stackView = UIStackView(arrangedSubviews: [
            statusLabel,
            cartBadgeLabel,
            loginButton,
            logoutButton,
            addToCartButton,
            clearCartButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stackView)
        view.addSubview(logTextView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            loginButton.heightAnchor.constraint(equalToConstant: 44),
            logoutButton.heightAnchor.constraint(equalToConstant: 44),
            addToCartButton.heightAnchor.constraint(equalToConstant: 44),

            logTextView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            logTextView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            logTextView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            logTextView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20)
        ])
    }

    private func setupActions(){
        loginButton
            .addTarget(
                self,
                action: #selector(loginTapped),
                for: .touchUpInside
            )
        logoutButton.addTarget(self, action: #selector(logoutTapped), for: .touchUpInside)
        addToCartButton.addTarget(self, action: #selector(addToCartTapped), for: .touchUpInside)
        clearCartButton.addTarget(self, action: #selector(clearCartTapped), for: .touchUpInside)
    }

    private func setupNotificationObservers() {
        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(handleUserLogin(_:)),
                name: .userDidLogin,
                object: nil //recieve from any sender
            )

        NotificationCenter.default
            .addObserver(
                self,
                selector: #selector(handleUserLogout(_:)),
                name: .userDidLogout,
                object: nil
            )

        NotificationCenter.default
            .addObserver(
                forName: .cartDidUpdate,
                object: nil,
                queue: .main) { [weak self] notification in
                    self?.handleCartUpdate(notification)
                }
    }

    // MARK: - ✅ HANDLE NOTIFICATIONS (When broadcasts arrive)

    @objc private func handleUserLogin(_ notification: Notification) {
        // ✅ Extract data from notification
        guard let user = notification.userInfo?["user"] as? User else {
            log("Login notifiaction received but no user data")
            return
        }

        log("📥 RECEIVED: userDidLogin")
        log("   → User: \(user.name)")
        log("   → Email: \(user.email)")

        // ✅ Update UI
        statusLabel.text = "✅ Logged in as:\n\(user.name)\n\(user.email)"
        statusLabel.textColor = .systemGreen
        loginButton.isHidden = true
        logoutButton.isHidden = false
    }

    @objc private func handleUserLogout(_ notification: Notification) {
        log("📥 RECEIVED: userDidLogout")

        // ✅ Update UI
        statusLabel.text = "❌ Not logged in"
        statusLabel.textColor = .systemRed
        loginButton.isHidden = false
        logoutButton.isHidden = true
    }

    private func handleCartUpdate(_ notification: Notification) {
        let itemCount = notification.userInfo?["itemCount"] as? Int ?? 0

        log("📥 RECEIVED: cartDidUpdate")
        log("   → Items: \(itemCount)")

        // ✅ Update UI
        cartBadgeLabel.text = "🛒 Cart: \(itemCount) items"

        if itemCount > 0 {
            cartBadgeLabel.textColor = .systemOrange
        } else {
            cartBadgeLabel.textColor = .label
        }
    }

    // MARK: - Button Actions (Trigger broadcasts)

    @objc private func loginTapped() {
        log("🔘 Login button tapped")
        log("📤 POSTING: userDidLogin notification...")

        // ✅ This will broadcast to ALL listeners
        AuthService.shared.login(name: "John Doe", email: "john@example.com")
    }

    @objc private func logoutTapped() {
        log("🔘 Logout button tapped")
        log("📤 POSTING: userDidLogout notification...")

        AuthService.shared.logout()
    }

    @objc private func addToCartTapped() {
        let items = ["iPhone", "MacBook", "AirPods", "iPad", "Apple Watch"]
        let randomItem = items.randomElement() ?? "Item"

        log("🔘 Add to cart tapped")
        log("📤 POSTING: cartDidUpdate notification...")

        CartService.shared.addItem(randomItem)
    }

    @objc private func clearCartTapped() {
        log("🔘 Clear cart tapped")
        CartService.shared.clearCart()
    }

    private func log(_ message: String) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        logTextView.text += "[\(timestamp)] \(message)\n"

        // Scroll to bottom
        let bottom = NSRange(location: logTextView.text.count - 1, length: 1)
        logTextView.scrollRangeToVisible(bottom)
    }
}
