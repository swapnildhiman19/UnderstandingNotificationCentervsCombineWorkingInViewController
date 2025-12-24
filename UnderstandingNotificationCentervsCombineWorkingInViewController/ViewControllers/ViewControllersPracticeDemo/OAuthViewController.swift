//
//  OAuthViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 26/11/25.
//

import UIKit
import AuthenticationServices

//// MARK: - Errors
//
//enum OAuthError: LocalizedError {
//    case invalidURL
//    case noCallbackURL
//    case noAuthorizationCode
//    case noData
//
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL"
//        case .noCallbackURL:
//            return "No callback URL received"
//        case .noAuthorizationCode:
//            return "No authorization code in callback"
//        case .noData:
//            return "No data received"
//        }
//    }
//}
//
//// MARK: - OAuth Configuration
//
//struct OAuthConfig {
//    // 🔧 REPLACE THESE WITH YOUR VALUES FROM GITHUB
//    static let clientID = "Ov23lip9lcjBeLCaCs3w"
//    static let clientSecret = "7af4f6eb742ac1f025ed143a5ca07f9d5b286ecd"
//    static let callbackScheme = "myapp"  // Must match your URL scheme
//    static let redirectURI = "myapp://callback"
//
//    // GitHub OAuth URLs
//    static let authorizeURL = "https://github.com/login/oauth/authorize"
//    static let tokenURL = "https://github.com/login/oauth/access_token"
//    static let userAPI = "https://api.github.com/user"
//}
//
//// MARK: - Models
//
//struct OAuthToken: Codable {
//    let accessToken: String
//    let tokenType: String
//    let scope: String
//
//    enum CodingKeys: String, CodingKey {
//        case accessToken = "access_token"
//        case tokenType = "token_type"
//        case scope
//    }
//}
//
//struct GitHubUser: Codable {
//    let login: String
//    let name: String?
//    let avatarUrl: String
//    let bio: String?
//
//    enum CodingKeys: String, CodingKey {
//        case login, name, bio
//        case avatarUrl = "avatar_url"
//    }
//}
//
//// MARK: - OAuth Manager
//
//class SimpleOAuthManager: NSObject {
//
//    static let shared = SimpleOAuthManager()
//
//    private var authSession: ASWebAuthenticationSession?
//    private var completion: ((Result<GitHubUser, Error>) -> Void)?
//
//    private override init() {
//        super.init()
//    }
//
//    // MARK: - Step 1: Start OAuth Flow
//
//    func signInWithGitHub(
//        from viewController: UIViewController,
//        completion: @escaping (Result<GitHubUser, Error>) -> Void
//    ) {
//        self.completion = completion
//
//        // 1️⃣ Build authorization URL
//        guard let authURL = buildAuthorizationURL() else {
//            completion(.failure(OAuthError.invalidURL))
//            return
//        }
//
//        print("🔵 Step 1: Opening GitHub login page...")
//        print("   URL: \(authURL.absoluteString)")
//
//        // 2️⃣ Create authentication session
//        authSession = ASWebAuthenticationSession(
//            url: authURL,
//            callbackURLScheme: OAuthConfig.callbackScheme
//        ) { [weak self] callbackURL, error in
//            self?.handleCallback(url: callbackURL, error: error)
//        }
//
//        // 3️⃣ Set presentation context (required)
//        authSession?.presentationContextProvider = self
//
//        // 4️⃣ Start the session
//        authSession?.start()
//    }
//
//    // MARK: - Step 2: Build Authorization URL
//
//    private func buildAuthorizationURL() -> URL? {
//        var components = URLComponents(string: OAuthConfig.authorizeURL)
//        components?.queryItems = [
//            URLQueryItem(name: "client_id", value: OAuthConfig.clientID),
//            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
//            URLQueryItem(name: "scope", value: "read:user user:email")
//        ]
//        return components?.url
//    }
//
//    // MARK: - Step 3: Handle Callback
//
//    private func handleCallback(url: URL?, error: Error?) {
//        // Check for errors
//        if let error = error {
//            print("❌ OAuth Error: \(error.localizedDescription)")
//            completion?(.failure(error))
//            return
//        }
//
//        guard let callbackURL = url else {
//            print("❌ No callback URL received")
//            completion?(.failure(OAuthError.noCallbackURL))
//            return
//        }
//
//        print("🔵 Step 2: Received callback URL")
//        print("   URL: \(callbackURL.absoluteString)")
//
//        // Extract authorization code from URL
//        guard let code = extractCode(from: callbackURL) else {
//            print("❌ Failed to extract authorization code")
//            completion?(.failure(OAuthError.noAuthorizationCode))
//            return
//        }
//
//        print("🔵 Step 3: Extracted authorization code")
//        print("   Code: \(code)")
//
//        // Exchange code for access token
//        exchangeCodeForToken(code: code)
//    }
//
//    // MARK: - Step 4: Extract Code from URL
//
//    private func extractCode(from url: URL) -> String? {
//        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
//              let queryItems = components.queryItems else {
//            return nil
//        }
//
//        return queryItems.first(where: { $0.name == "code" })?.value
//    }
//
//    // MARK: - Step 5: Exchange Code for Token
//
//    private func exchangeCodeForToken(code: String) {
//        print("🔵 Step 4: Exchanging code for access token...")
//
//        guard let url = URL(string: OAuthConfig.tokenURL) else {
//            completion?(.failure(OAuthError.invalidURL))
//            return
//        }
//
//        // Build request
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        // Request body
//        let body: [String: String] = [
//            "client_id": OAuthConfig.clientID,
//            "client_secret": OAuthConfig.clientSecret,
//            "code": code,
//            "redirect_uri": OAuthConfig.redirectURI
//        ]
//
//        request.httpBody = try? JSONEncoder().encode(body)
//
//        // Make request
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            if let error = error {
//                print("❌ Token exchange failed: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    self?.completion?(.failure(error))
//                }
//                return
//            }
//
//            guard let data = data else {
//                print("❌ No data received from token exchange")
//                DispatchQueue.main.async {
//                    self?.completion?(.failure(OAuthError.noData))
//                }
//                return
//            }
//
//            // Parse token response
//            do {
//                let token = try JSONDecoder().decode(OAuthToken.self, from: data)
//                print("✅ Step 5: Received access token")
//                print("   Token: \(token.accessToken.prefix(10))...")
//
//                // Fetch user info
//                self?.fetchUserInfo(accessToken: token.accessToken)
//            } catch {
//                print("❌ Failed to decode token: \(error)")
//                DispatchQueue.main.async {
//                    self?.completion?(.failure(error))
//                }
//            }
//        }.resume()
//    }
//
//    // MARK: - Step 6: Fetch User Info
//
//    private func fetchUserInfo(accessToken: String) {
//        print("🔵 Step 6: Fetching user information...")
//
//        guard let url = URL(string: OAuthConfig.userAPI) else {
//            completion?(.failure(OAuthError.invalidURL))
//            return
//        }
//
//        var request = URLRequest(url: url)
//        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//
//        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
//            if let error = error {
//                print("❌ User info fetch failed: \(error.localizedDescription)")
//                DispatchQueue.main.async {
//                    self?.completion?(.failure(error))
//                }
//                return
//            }
//
//            guard let data = data else {
//                print("❌ No user data received")
//                DispatchQueue.main.async {
//                    self?.completion?(.failure(OAuthError.noData))
//                }
//                return
//            }
//
//            do {
//                let user = try JSONDecoder().decode(GitHubUser.self, from: data)
//                print("✅ Step 7: Successfully fetched user info!")
//                print("   User: \(user.login)")
//
//                DispatchQueue.main.async {
//                    self?.completion?(.success(user))
//                }
//            } catch {
//                print("❌ Failed to decode user: \(error)")
//                DispatchQueue.main.async {
//                    self?.completion?(.failure(error))
//                }
//            }
//        }.resume()
//    }
//}
//
//// MARK: - ASWebAuthenticationPresentationContextProviding
//
//extension SimpleOAuthManager: ASWebAuthenticationPresentationContextProviding {
//    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
//        // Return the key window
//        return UIApplication.shared.windows.first { $0.isKeyWindow } ?? ASPresentationAnchor()
//    }
//}
//
//
//
//import UIKit
//
//class OAuthViewController: UIViewController {
//
//    // MARK: - UI Elements
//
//    private let scrollView: UIScrollView = {
//        let scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        return scrollView
//    }()
//
//    private let contentStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 24
//        stackView.alignment = .center
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.layoutMargins = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
//        stackView.isLayoutMarginsRelativeArrangement = true
//        return stackView
//    }()
//
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "🔐 OAuth Demo"
//        label.font = .systemFont(ofSize: 32, weight: .bold)
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let descriptionLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Learn how OAuth 2.0 works with a real example"
//        label.font = .systemFont(ofSize: 16)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    private let signInButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("🐙 Sign in with GitHub", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
//        button.backgroundColor = .black
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 12
//        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//
//    private let statusLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Not signed in"
//        label.font = .systemFont(ofSize: 14)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    private let activityIndicator: UIActivityIndicatorView = {
//        let indicator = UIActivityIndicatorView(style: .large)
//        indicator.hidesWhenStopped = true
//        return indicator
//    }()
//
//    private let userInfoView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .systemBackground
//        view.layer.cornerRadius = 16
//        view.layer.borderWidth = 1
//        view.layer.borderColor = UIColor.separator.cgColor
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.isHidden = true
//        return view
//    }()
//
//    private let avatarImageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFill
//        imageView.layer.cornerRadius = 50
//        imageView.clipsToBounds = true
//        imageView.backgroundColor = .systemGray5
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//
//    private let usernameLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 24, weight: .bold)
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 16)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let bioLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    private let signOutButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Sign Out", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
//        button.setTitleColor(.systemRed, for: .normal)
//        return button
//    }()
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupActions()
//    }
//
//    // MARK: - Setup
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentStackView)
//
//        // Add elements to stack
//        contentStackView.addArrangedSubview(titleLabel)
//        contentStackView.addArrangedSubview(descriptionLabel)
//        contentStackView.addArrangedSubview(signInButton)
//        contentStackView.addArrangedSubview(activityIndicator)
//        contentStackView.addArrangedSubview(statusLabel)
//        contentStackView.addArrangedSubview(userInfoView)
//
//        // Setup user info view
//        setupUserInfoView()
//
//        // Constraints
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//
//            signInButton.widthAnchor.constraint(equalToConstant: 250),
//
//            userInfoView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor, constant: -40)
//        ])
//    }
//
//    private func setupUserInfoView() {
//        let stackView = UIStackView(arrangedSubviews: [
//            avatarImageView,
//            usernameLabel,
//            nameLabel,
//            bioLabel,
//            signOutButton
//        ])
//        stackView.axis = .vertical
//        stackView.spacing = 12
//        stackView.alignment = .center
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//
//        userInfoView.addSubview(stackView)
//
//        NSLayoutConstraint.activate([
//            stackView.topAnchor.constraint(equalTo: userInfoView.topAnchor, constant: 24),
//            stackView.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
//            stackView.trailingAnchor.constraint(equalTo: userInfoView.trailingAnchor, constant: -20),
//            stackView.bottomAnchor.constraint(equalTo: userInfoView.bottomAnchor, constant: -24),
//
//            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
//            avatarImageView.heightAnchor.constraint(equalToConstant: 100)
//        ])
//    }
//
//    private func setupActions() {
//        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
//        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
//    }
//
//    // MARK: - Actions
//
//    @objc private func signInTapped() {
//        print("\n==========================================")
//        print("🚀 Starting OAuth Flow")
//        print("==========================================\n")
//
//        signInButton.isEnabled = false
//        activityIndicator.startAnimating()
//        statusLabel.text = "Opening GitHub login..."
//        statusLabel.textColor = .systemBlue
//
//        SimpleOAuthManager.shared.signInWithGitHub(from: self) { [weak self] result in
//            guard let self = self else { return }
//
//            self.activityIndicator.stopAnimating()
//            self.signInButton.isEnabled = true
//
//            switch result {
//            case .success(let user):
//                print("\n==========================================")
//                print("✅ OAuth Flow Complete!")
//                print("==========================================\n")
//
//                self.showUserInfo(user)
//
//            case .failure(let error):
//                print("\n==========================================")
//                print("❌ OAuth Flow Failed!")
//                print("==========================================\n")
//
//                self.showError(error)
//            }
//        }
//    }
//
//    @objc private func signOutTapped() {
//        userInfoView.isHidden = true
//        signInButton.isHidden = false
//        statusLabel.text = "Not signed in"
//        statusLabel.textColor = .secondaryLabel
//
//        print("\n👋 Signed out\n")
//    }
//
//    // MARK: - Display User Info
//
//    private func showUserInfo(_ user: GitHubUser) {
//        usernameLabel.text = "@\(user.login)"
//        nameLabel.text = user.name ?? "No name"
//        bioLabel.text = user.bio ?? "No bio"
//
//        // Load avatar
//        if let url = URL(string: user.avatarUrl) {
//            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
//                if let data = data, let image = UIImage(data: data) {
//                    DispatchQueue.main.async {
//                        self?.avatarImageView.image = image
//                    }
//                }
//            }.resume()
//        }
//
//        signInButton.isHidden = true
//        userInfoView.isHidden = false
//        statusLabel.text = "✅ Successfully signed in!"
//        statusLabel.textColor = .systemGreen
//    }
//
//    private func showError(_ error: Error) {
//        let alert = UIAlertController(
//            title: "Authentication Failed",
//            message: error.localizedDescription,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//
//        statusLabel.text = "❌ Authentication failed"
//        statusLabel.textColor = .systemRed
//    }
//}

/*
 ┌─────────────┐                                    ┌─────────────┐
 │             │   1. "Sign in with Google"         │             │
 │  Your App   │───────────────────────────────────>│    User     │
 │             │                                    │             │
 └─────────────┘                                    └─────────────┘
       │                                                   │
       │ 2. Redirect to Google login                       │
       │────────────────────────────────────────────────>  │
       │                                                   │
       │                                    ┌──────────────▼──────────┐
       │                                    │   Google Login Page     │
       │                                    │  (Enter email/password) │
       │                                    └──────────────┬──────────┘
       │                                                   │
       │ 3. Authorization Code                             │
       │ <──────────────────────────────────────────────── ┘
       │    (callback://success?code=ABC123)
       │
       │ 4. Exchange code for tokens
       │────────────────────────────────────────>┌─────────────────┐
       │                                         │  Google Server  │
       │ 5. Access Token + Refresh Token         │                 │
       │ <───────────────────────────────────────│                 │
       │                                         └─────────────────┘
       │
       │ 6. Use Access Token to get user info
       │────────────────────────────────────────>│-----------------|
       │                                         │  Google API     │
       │ 7. User Profile Data                    │                 │
       │ <───────────────────────────────────────│                 │
       │                                         └─────────────────┘
       ▼
   ✅ User is logged in!
 */

enum OAuthError : Error, LocalizedError {
    case invalidURL
    case noAuthorizationCode
    case noCallbackURL
    case noData

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noCallbackURL:
            return "No callback URL received"
        case .noAuthorizationCode:
            return "No authorization code in callback"
        case .noData:
            return "No data received"
        }
    }
}

struct OAuthConfig {
    static let clientID = "Ov23lip9lcjBeLCaCs3w"
    static let clientSecret = "7af4f6eb742ac1f025ed143a5ca07f9d5b286ecd"
    static let callbackScheme = "myapp"  // Must match your URL scheme
    static let redirectURI = "myapp://callback"

    // GitHub OAuth URLs
    static let authorizeURL = "https://github.com/login/oauth/authorize"
    static let tokenURL = "https://github.com/login/oauth/access_token"
    static let userAPI = "https://api.github.com/user"
}

struct OAuthToken: Codable {
    let accessToken: String
    let tokenType: String
    let scope : String
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
    }
}

struct GithubUser : Codable {
    let login : String
    let name : String?
    let avatarURL : String
    let bio : String?
    enum CodingKeys : String, CodingKey {
        case login, name, bio
        case avatarURL = "avatar_url"
    }
}


class SimpleOAuthManager : NSObject {
    static let shared = SimpleOAuthManager()

    private var authSession : ASWebAuthenticationSession?
    private var completion: ((Result<GithubUser,Error>)->Void)?
    //1. Open the github login page
    func signInWithGithub(
        from viewController : UIViewController,
        completion : @escaping (Result<GithubUser,Error>)->Void
    ){
        self.completion = completion

        //Building the authorization URL
        guard let authorizeURL = buildAuthorizationURL() else {
            completion(.failure(OAuthError.invalidURL))
            return
        }

        print("Opening Github Login Web Page...")
        print("url: \(authorizeURL.absoluteString)")

        authSession = ASWebAuthenticationSession(
            url: authorizeURL,
            callbackURLScheme: OAuthConfig.callbackScheme,
            completionHandler: { [weak self] callbackURL, error in
                self?.handleCallback(url: callbackURL, error: error)
            }
        )

        authSession?.presentationContextProvider = self
        authSession?.start()
    }

    //2. Build the authorizeURL by passing client
    private func buildAuthorizationURL() -> URL? {
        var components = URLComponents(string: OAuthConfig.authorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: OAuthConfig.clientID),
            URLQueryItem(name: "redirect_uri", value: OAuthConfig.redirectURI),
            URLQueryItem(name: "scope", value: "read:user user:email")
        ]
        return components?.url
    }

    //3. Extract the call authorization code from the callback URL
    private func handleCallback(url: URL?, error: Error?) {

        if let error = error {
            print("OAuth Error: \(error.localizedDescription)")
            completion?(.failure(error))
            return
        }

        guard let callbackURL = url else {
            print("Not getting callbackURL to extract the authorization code")
            completion?(.failure(OAuthError.noCallbackURL))
            return
        }

        guard let extractedCode = extractCode(from: callbackURL) else {
            print("Failed to extract the authorization code")
            completion?(.failure(OAuthError.noAuthorizationCode))
            return
        }

        print("Extracted authorization/access code")
        print("Code: \(extractedCode)")

        //asking for token from this extractedCode
        exchangeCodeForToken(authorizationCode: extractedCode)
    }

    //4. Extracting the access code
    private func extractCode(from url : URL) -> String? {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        return components?.queryItems?
            .first(where: { $0.name == "code" })?.value
    }

    //5. Exchanging token for extracted code
    private func exchangeCodeForToken(authorizationCode: String){
        print("Exchanging token for authorization code")

        guard let tokenURL = URL(string: OAuthConfig.tokenURL) else {
            completion?(.failure(OAuthError.invalidURL))
            return
        }

        var httpRequest = URLRequest(url: tokenURL)
        httpRequest.httpMethod = "POST"
        httpRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        httpRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        let body : [String:String] = [
            "client-id":OAuthConfig.clientID,
            "client-secret":OAuthConfig.clientSecret,
            "code": authorizationCode,
            "redirect-uri": OAuthConfig.redirectURI
        ]

        httpRequest.httpBody = try? JSONEncoder().encode(body)

        URLSession.shared.dataTask(
            with: httpRequest) {[weak self] data, response, error in
                if let error = error {
                    DispatchQueue.main.async {
                        self?.completion?(.failure(error))
                    }
                    return
                }

                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    return
                }

                guard let data = data else {
                    print("❌ No data received from token exchange")
                    DispatchQueue.main.async {
                        self?.completion?(.failure(OAuthError.noData))
                    }
                    return
                }

                do {
                    let token = try JSONDecoder().decode(OAuthToken.self, from: data)
                    print("✅ Step 5: Received access token")
                    print("   Token: \(token.accessToken.prefix(10))...")

                    // Fetch user info
                    self?.fetchUserInfo(accessToken: token.accessToken)
                } catch {
                    print("❌ Failed to decode token: \(error)")
                    DispatchQueue.main.async {
                        self?.completion?(.failure(error))
                    }
            }
        }.resume()
    }

    //6 Fetch the user details
    private func fetchUserInfo(accessToken: String) {
        print("🔵 Step 6: Fetching user information...")

        guard let url = URL(string: OAuthConfig.userAPI) else {
            completion?(.failure(OAuthError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            if let error = error {
                print("❌ User info fetch failed: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self?.completion?(.failure(error))
                }
                return
            }

            guard let data = data else {
                print("❌ No user data received")
                DispatchQueue.main.async {
                    self?.completion?(.failure(OAuthError.noData))
                }
                return
            }

            do {
                let user = try JSONDecoder().decode(GithubUser.self, from: data)
                print("✅ Step 7: Successfully fetched user info!")
                print("   User: \(user.login)")

                DispatchQueue.main.async {
                    self?.completion?(.success(user))
                }
            } catch {
                print("❌ Failed to decode user: \(error)")
                DispatchQueue.main.async {
                    self?.completion?(.failure(error))
                }
            }
        }.resume()
    }
}

extension SimpleOAuthManager: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.windows
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}


class OAuthViewController: UIViewController {

    // MARK: - UI Elements

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 24
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.layoutMargins = UIEdgeInsets(top: 40, left: 20, bottom: 40, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
        return stackView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "🔐 OAuth Demo"
        label.font = .systemFont(ofSize: 32, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "Learn how OAuth 2.0 works with a real example"
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let signInButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("🐙 Sign in with GitHub", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = .black
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 32, bottom: 16, right: 32)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Not signed in"
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let userInfoView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.separator.cgColor
        view.translatesAutoresizingMaskIntoConstraints = false
        view.isHidden = true
        return view
    }()

    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 50
        imageView.clipsToBounds = true
        imageView.backgroundColor = .systemGray5
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        return label
    }()

    private let bioLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let signOutButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Sign Out", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        button.setTitleColor(.systemRed, for: .normal)
        return button
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        // Add elements to stack
        contentStackView.addArrangedSubview(titleLabel)
        contentStackView.addArrangedSubview(descriptionLabel)
        contentStackView.addArrangedSubview(signInButton)
        contentStackView.addArrangedSubview(activityIndicator)
        contentStackView.addArrangedSubview(statusLabel)
        contentStackView.addArrangedSubview(userInfoView)

        // Setup user info view
        setupUserInfoView()

        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            signInButton.widthAnchor.constraint(equalToConstant: 250),

            userInfoView.widthAnchor.constraint(equalTo: contentStackView.widthAnchor, constant: -40)
        ])
    }

    private func setupUserInfoView() {
        let stackView = UIStackView(arrangedSubviews: [
            avatarImageView,
            usernameLabel,
            nameLabel,
            bioLabel,
            signOutButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false

        userInfoView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: userInfoView.topAnchor, constant: 24),
            stackView.leadingAnchor.constraint(equalTo: userInfoView.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: userInfoView.trailingAnchor, constant: -20),
            stackView.bottomAnchor.constraint(equalTo: userInfoView.bottomAnchor, constant: -24),

            avatarImageView.widthAnchor.constraint(equalToConstant: 100),
            avatarImageView.heightAnchor.constraint(equalToConstant: 100)
        ])
    }

    private func setupActions() {
        signInButton.addTarget(self, action: #selector(signInTapped), for: .touchUpInside)
        signOutButton.addTarget(self, action: #selector(signOutTapped), for: .touchUpInside)
    }

    // MARK: - Actions

    @objc private func signInTapped() {
        print("\n==========================================")
        print("🚀 Starting OAuth Flow")
        print("==========================================\n")

        signInButton.isEnabled = false
        activityIndicator.startAnimating()
        statusLabel.text = "Opening GitHub login..."
        statusLabel.textColor = .systemBlue

        SimpleOAuthManager.shared.signInWithGithub(from: self) { [weak self] result in
            guard let self = self else { return }

            self.activityIndicator.stopAnimating()
            self.signInButton.isEnabled = true

            switch result {
            case .success(let user):
                print("\n==========================================")
                print("✅ OAuth Flow Complete!")
                print("==========================================\n")

                self.showUserInfo(user)

            case .failure(let error):
                print("\n==========================================")
                print("❌ OAuth Flow Failed!")
                print("==========================================\n")

                self.showError(error)
            }
        }
    }

    @objc private func signOutTapped() {
        userInfoView.isHidden = true
        signInButton.isHidden = false
        statusLabel.text = "Not signed in"
        statusLabel.textColor = .secondaryLabel

        print("\n👋 Signed out\n")
    }

    // MARK: - Display User Info



    private func showUserInfo(_ user: GithubUser) {
        usernameLabel.text = "@\(user.login)"
        nameLabel.text = user.name ?? "No name"
        bioLabel.text = user.bio ?? "No bio"

        // Load avatar
        if let url = URL(string: user.avatarURL) {
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                if let data = data, let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.avatarImageView.image = image
                    }
                }
            }.resume()
        }

        signInButton.isHidden = true
        userInfoView.isHidden = false
        statusLabel.text = "✅ Successfully signed in!"
        statusLabel.textColor = .systemGreen
    }

    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Authentication Failed",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)

        statusLabel.text = "❌ Authentication failed"
        statusLabel.textColor = .systemRed
    }
}
