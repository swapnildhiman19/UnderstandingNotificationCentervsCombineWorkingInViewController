//
//  BuilderPatternDemoViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 14/12/25.
//

import UIKit

// MARK: - 1️⃣ Alert Builder

class AlertBuilder {

    private var title: String = ""
    private var message: String = ""
    private var style: UIAlertController.Style = .alert
    private var actions: [UIAlertAction] = []
    private var preferredAction: UIAlertAction?
    private var textFields: [(placeholder: String, isSecure: Bool)] = []

    // MARK: - Builder Methods (each returns self for chaining)

    func setTitle(_ title: String) -> AlertBuilder {
        self.title = title
        return self
    }

    func setMessage(_ message: String) -> AlertBuilder {
        self.message = message
        return self
    }

    func setStyle(_ style: UIAlertController.Style) -> AlertBuilder {
        self.style = style
        return self
    }

    func addAction(
        title: String,
        style: UIAlertAction.Style = .default,
        handler: ((UIAlertAction) -> Void)? = nil
    ) -> AlertBuilder {
        let action = UIAlertAction(title: title, style: style, handler: handler)
        actions.append(action)
        return self
    }

    func addCancelAction(title: String = "Cancel", handler: ((UIAlertAction) -> Void)? = nil) -> AlertBuilder {
        return addAction(title: title, style: .cancel, handler: handler)
    }

    func addDestructiveAction(title: String, handler: ((UIAlertAction) -> Void)? = nil) -> AlertBuilder {
        return addAction(title: title, style: .destructive, handler: handler)
    }

    func addTextField(placeholder: String, isSecure: Bool = false) -> AlertBuilder {
        textFields.append((placeholder, isSecure))
        return self
    }

    func setPreferredAction(_ action: UIAlertAction) -> AlertBuilder {
        self.preferredAction = action
        return self
    }

    // MARK: - Build Final Object

    func build() -> UIAlertController {
        let alert = UIAlertController(
            title: title.isEmpty ? nil : title,
            message: message.isEmpty ? nil : message,
            preferredStyle: style
        )

        // Add text fields
        for textField in textFields {
            alert.addTextField { tf in
                tf.placeholder = textField.placeholder
                tf.isSecureTextEntry = textField.isSecure
            }
        }

        // Add actions
        actions.forEach { alert.addAction($0) }

        // Set preferred action
        if let preferred = preferredAction {
            alert.preferredAction = preferred
        }

        return alert
    }
}

// MARK: - 2️⃣ Network Request Builder

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

class RequestBuilder {

    private var url: URL?
    private var method: HTTPMethod = .get
    private var headers: [String: String] = [:]
    private var body: Data?
    private var timeout: TimeInterval = 30
    private var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy

    // MARK: - Builder Methods

    func setURL(_ urlString: String) -> RequestBuilder {
        self.url = URL(string: urlString)
        return self
    }

    func setURL(_ url: URL) -> RequestBuilder {
        self.url = url
        return self
    }

    func setMethod(_ method: HTTPMethod) -> RequestBuilder {
        self.method = method
        return self
    }

    func addHeader(key: String, value: String) -> RequestBuilder {
        headers[key] = value
        return self
    }

    func setContentTypeJSON() -> RequestBuilder {
        headers["Content-Type"] = "application/json"
        return self
    }

    func setAuthorization(token: String) -> RequestBuilder {
        headers["Authorization"] = "Bearer \(token)"
        return self
    }

    func setBody(_ data: Data) -> RequestBuilder {
        self.body = data
        return self
    }

    func setJSONBody<T: Encodable>(_ object: T) -> RequestBuilder {
        self.body = try? JSONEncoder().encode(object)
        return self
    }

    func setTimeout(_ timeout: TimeInterval) -> RequestBuilder {
        self.timeout = timeout
        return self
    }

    func setCachePolicy(_ policy: URLRequest.CachePolicy) -> RequestBuilder {
        self.cachePolicy = policy
        return self
    }

    // MARK: - Build

    func build() -> URLRequest? {
        guard let url = url else {
            print("❌ RequestBuilder: URL is required")
            return nil
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.timeoutInterval = timeout
        request.cachePolicy = cachePolicy

        headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        request.httpBody = body

        return request
    }
}

// MARK: - 3️⃣ Custom View Builder

class CardViewBuilder {

    private var backgroundColor: UIColor = .systemBackground
    private var cornerRadius: CGFloat = 12
    private var shadowEnabled: Bool = false
    private var shadowColor: UIColor = .black
    private var shadowOpacity: Float = 0.1
    private var shadowRadius: CGFloat = 8
    private var shadowOffset: CGSize = CGSize(width: 0, height: 4)
    private var borderWidth: CGFloat = 0
    private var borderColor: UIColor = .clear
    private var padding: UIEdgeInsets = .zero

    // MARK: - Builder Methods

    func setBackgroundColor(_ color: UIColor) -> CardViewBuilder {
        self.backgroundColor = color
        return self
    }

    func setCornerRadius(_ radius: CGFloat) -> CardViewBuilder {
        self.cornerRadius = radius
        return self
    }

    func enableShadow(
        color: UIColor = .black,
        opacity: Float = 0.1,
        radius: CGFloat = 8,
        offset: CGSize = CGSize(width: 0, height: 4)
    ) -> CardViewBuilder {
        self.shadowEnabled = true
        self.shadowColor = color
        self.shadowOpacity = opacity
        self.shadowRadius = radius
        self.shadowOffset = offset
        return self
    }

    func setBorder(width: CGFloat, color: UIColor) -> CardViewBuilder {
        self.borderWidth = width
        self.borderColor = color
        return self
    }

    func setPadding(_ padding: UIEdgeInsets) -> CardViewBuilder {
        self.padding = padding
        return self
    }

    func setPadding(_ value: CGFloat) -> CardViewBuilder {
        self.padding = UIEdgeInsets(top: value, left: value, bottom: value, right: value)
        return self
    }

    // MARK: - Build

    func build() -> UIView {
        let view = UIView()
        view.backgroundColor = backgroundColor
        view.layer.cornerRadius = cornerRadius
        view.translatesAutoresizingMaskIntoConstraints = false

        if shadowEnabled {
            view.layer.shadowColor = shadowColor.cgColor
            view.layer.shadowOpacity = shadowOpacity
            view.layer.shadowRadius = shadowRadius
            view.layer.shadowOffset = shadowOffset
        }

        if borderWidth > 0 {
            view.layer.borderWidth = borderWidth
            view.layer.borderColor = borderColor.cgColor
        }

        view.layoutMargins = padding

        return view
    }
}

// MARK: - 4️⃣ Stack View Builder

class StackViewBuilder {

    private var axis: NSLayoutConstraint.Axis = .vertical
    private var spacing: CGFloat = 8
    private var alignment: UIStackView.Alignment = .fill
    private var distribution: UIStackView.Distribution = .fill
    private var arrangedSubviews: [UIView] = []
    private var layoutMargins: UIEdgeInsets = .zero
    private var isLayoutMarginsRelative: Bool = false

    // MARK: - Builder Methods

    func setAxis(_ axis: NSLayoutConstraint.Axis) -> StackViewBuilder {
        self.axis = axis
        return self
    }

    func vertical() -> StackViewBuilder {
        return setAxis(.vertical)
    }

    func horizontal() -> StackViewBuilder {
        return setAxis(.horizontal)
    }

    func setSpacing(_ spacing: CGFloat) -> StackViewBuilder {
        self.spacing = spacing
        return self
    }

    func setAlignment(_ alignment: UIStackView.Alignment) -> StackViewBuilder {
        self.alignment = alignment
        return self
    }

    func setDistribution(_ distribution: UIStackView.Distribution) -> StackViewBuilder {
        self.distribution = distribution
        return self
    }

    func addArrangedSubview(_ view: UIView) -> StackViewBuilder {
        arrangedSubviews.append(view)
        return self
    }

    func addArrangedSubviews(_ views: [UIView]) -> StackViewBuilder {
        arrangedSubviews.append(contentsOf: views)
        return self
    }

    func setMargins(_ margins: UIEdgeInsets) -> StackViewBuilder {
        self.layoutMargins = margins
        self.isLayoutMarginsRelative = true
        return self
    }

    func setMargins(_ value: CGFloat) -> StackViewBuilder {
        return setMargins(UIEdgeInsets(top: value, left: value, bottom: value, right: value))
    }

    // MARK: - Build

    func build() -> UIStackView {
        let stackView = UIStackView(arrangedSubviews: arrangedSubviews)
        stackView.axis = axis
        stackView.spacing = spacing
        stackView.alignment = alignment
        stackView.distribution = distribution
        stackView.layoutMargins = layoutMargins
        stackView.isLayoutMarginsRelativeArrangement = isLayoutMarginsRelative
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }
}

// MARK: - 5️⃣ Demo ViewController

class BuilderPatternDemoViewController: UIViewController {

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground
        title = "Builder Pattern Demo"

        // ✅ Build buttons
        let alertButton = createButton(title: "Show Alert", color: .systemBlue)
        alertButton.addTarget(self, action: #selector(showAlertExample), for: .touchUpInside)

        let loginButton = createButton(title: "Show Login Alert", color: .systemGreen)
        loginButton.addTarget(self, action: #selector(showLoginAlert), for: .touchUpInside)

        let actionSheetButton = createButton(title: "Show Action Sheet", color: .systemOrange)
        actionSheetButton.addTarget(self, action: #selector(showActionSheet), for: .touchUpInside)

        let requestButton = createButton(title: "Build Network Request", color: .systemPurple)
        requestButton.addTarget(self, action: #selector(showRequestExample), for: .touchUpInside)

        // ✅ Build card view using CardViewBuilder
        let card = CardViewBuilder()
            .setBackgroundColor(.systemBackground)
            .setCornerRadius(16)
            .enableShadow(opacity: 0.15, radius: 10)
            .setPadding(16)
            .build()

        let cardLabel = UILabel()
        cardLabel.text = "This card was built using CardViewBuilder!\n\n• Background color\n• Corner radius\n• Shadow effect\n• Padding"
        cardLabel.numberOfLines = 0
        cardLabel.font = .systemFont(ofSize: 14)
        cardLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(cardLabel)
        NSLayoutConstraint.activate([
            cardLabel.topAnchor.constraint(equalTo: card.layoutMarginsGuide.topAnchor),
            cardLabel.leadingAnchor.constraint(equalTo: card.layoutMarginsGuide.leadingAnchor),
            cardLabel.trailingAnchor.constraint(equalTo: card.layoutMarginsGuide.trailingAnchor),
            cardLabel.bottomAnchor.constraint(equalTo: card.layoutMarginsGuide.bottomAnchor)
        ])

        // ✅ Build stack view using StackViewBuilder
        let mainStack = StackViewBuilder()
            .vertical()
            .setSpacing(16)
            .setMargins(20)
            .addArrangedSubviews([
                createSectionLabel("🔧 Builder Pattern Examples"),
                alertButton,
                loginButton,
                actionSheetButton,
                requestButton,
                createSectionLabel("📦 CardView Built with Builder:"),
                card
            ])
            .build()

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        button.backgroundColor = color
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 10
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        return button
    }

    private func createSectionLabel(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 18, weight: .bold)
        return label
    }

    // MARK: - Actions

    @objc private func showAlertExample() {
        // ✅ Build alert step by step
        let alert = AlertBuilder()
            .setTitle("Delete Item")
            .setMessage("Are you sure you want to delete this item? This action cannot be undone.")
            .addCancelAction()
            .addDestructiveAction(title: "Delete") { _ in
                print("Item deleted!")
            }
            .build()

        present(alert, animated: true)
    }

    @objc private func showLoginAlert() {
        // ✅ Build complex login alert
        let alert = AlertBuilder()
            .setTitle("Login")
            .setMessage("Enter your credentials")
            .addTextField(placeholder: "Email")
            .addTextField(placeholder: "Password", isSecure: true)
            .addCancelAction()
            .addAction(title: "Login", style: .default) { [weak self] _ in
                // Access text fields
                if let alert = self?.presentedViewController as? UIAlertController {
                    let email = alert.textFields?[0].text ?? ""
                    let password = alert.textFields?[1].text ?? ""
                    print("Email: \(email), Password: \(password)")
                }
            }
            .build()

        present(alert, animated: true)
    }

    @objc private func showActionSheet() {
        // ✅ Build action sheet
        let actionSheet = AlertBuilder()
            .setTitle("Share Photo")
            .setMessage("Choose how to share this photo")
            .setStyle(.actionSheet)
            .addAction(title: "📷 Save to Photos") { _ in print("Saved to Photos") }
            .addAction(title: "📤 Share via AirDrop") { _ in print("AirDrop") }
            .addAction(title: "📧 Send via Email") { _ in print("Email") }
            .addAction(title: "💬 Send via Message") { _ in print("Message") }
            .addCancelAction()
            .build()

        // For iPad
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }

        present(actionSheet, animated: true)
    }

    @objc private func showRequestExample() {
        // ✅ Build network request
        struct User: Encodable {
            let name: String
            let email: String
        }

        let user = User(name: "John", email: "john@example.com")

        let request = RequestBuilder()
            .setURL("https://api.example.com/users")
            .setMethod(.post)
            .setContentTypeJSON()
            .setAuthorization(token: "abc123xyz")
            .setJSONBody(user)
            .setTimeout(60)
            .build()

        // Show the built request details
        var message = "Request Built:\n\n"
        message += "URL: \(request?.url?.absoluteString ?? "N/A")\n"
        message += "Method: \(request?.httpMethod ?? "N/A")\n"
        message += "Headers: \(request?.allHTTPHeaderFields ?? [:])\n"
        message += "Timeout: \(request?.timeoutInterval ?? 0)s"

        let alert = AlertBuilder()
            .setTitle("Network Request Built!")
            .setMessage(message)
            .addAction(title: "OK")
            .build()

        present(alert, animated: true)
    }
}
