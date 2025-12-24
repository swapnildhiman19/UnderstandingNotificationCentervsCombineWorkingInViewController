// ============================================================================
// MEESHO INTERVIEW PREP: Auto-Login & Keychain Storage
// ============================================================================
// Day 7: Additional Topic
//
// The interviewer built "frictionless auto-login post reinstall".
// This covers Keychain persistence for seamless re-authentication.
// ============================================================================

import Foundation
import Security

// ============================================================================
// SECTION 1: WHY KEYCHAIN? (Layman's Explanation)
// ============================================================================
/*
 🎯 THE PROBLEM:
 
 User installs Meesho → Logs in → Uses app → Uninstalls
 User reinstalls Meesho → Has to log in AGAIN! 😤
 
 WHY? Because UserDefaults and files are DELETED on uninstall.
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                    STORAGE PERSISTENCE COMPARISON                           │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────┬───────────────────┬───────────────────────────────────────┐
 │   Storage       │ On App Uninstall  │ Use Case                              │
 ├─────────────────┼───────────────────┼───────────────────────────────────────┤
 │ UserDefaults    │ ❌ DELETED        │ App settings, preferences             │
 │ Files           │ ❌ DELETED        │ Downloaded content, cache             │
 │ CoreData        │ ❌ DELETED        │ Local database                        │
 │ KEYCHAIN        │ ✅ PERSISTS!      │ Credentials, tokens, secrets          │
 └─────────────────┴───────────────────┴───────────────────────────────────────┘
 
 KEYCHAIN is the ONLY storage that survives app uninstall/reinstall!
 (Unless user explicitly clears it or resets device)
 
 SOLUTION:
 1. User logs in → Store auth token in Keychain
 2. User uninstalls → Token stays in Keychain
 3. User reinstalls → Check Keychain → Token found! → Auto-login!
*/

// ============================================================================
// SECTION 2: KEYCHAIN MANAGER IMPLEMENTATION
// ============================================================================

/// Secure storage for authentication credentials using iOS Keychain
final class KeychainManager {
    
    // MARK: - Singleton
    static let shared = KeychainManager()
    
    // MARK: - Configuration
    
    /// Service identifier for your app's keychain items
    private let service: String
    
    /// Access group for sharing keychain between app and extensions
    private let accessGroup: String?
    
    // MARK: - Keys
    
    private enum KeychainKey: String {
        case accessToken = "auth_access_token"
        case refreshToken = "auth_refresh_token"
        case userId = "auth_user_id"
        case deviceId = "device_identifier"
    }
    
    // MARK: - Initialization
    
    private init(
        service: String = "com.meesho.app",
        accessGroup: String? = nil
    ) {
        self.service = service
        self.accessGroup = accessGroup
    }
    
    // MARK: - Public API: Tokens
    
    /// Save access token securely
    func saveAccessToken(_ token: String) -> Bool {
        return save(value: token, for: .accessToken)
    }
    
    /// Get access token
    func getAccessToken() -> String? {
        return getString(for: .accessToken)
    }
    
    /// Save refresh token securely
    func saveRefreshToken(_ token: String) -> Bool {
        return save(value: token, for: .refreshToken)
    }
    
    /// Get refresh token
    func getRefreshToken() -> String? {
        return getString(for: .refreshToken)
    }
    
    /// Save user ID
    func saveUserId(_ userId: String) -> Bool {
        return save(value: userId, for: .userId)
    }
    
    /// Get user ID
    func getUserId() -> String? {
        return getString(for: .userId)
    }
    
    // MARK: - Public API: Auth State
    
    /// Check if valid authentication exists
    var hasStoredCredentials: Bool {
        return getAccessToken() != nil && getUserId() != nil
    }
    
    /// Clear all authentication data (on logout)
    func clearAllCredentials() {
        delete(key: .accessToken)
        delete(key: .refreshToken)
        delete(key: .userId)
    }
    
    // MARK: - Private: Core Keychain Operations
    
    private func save(value: String, for key: KeychainKey) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }
        
        // Delete existing item first
        delete(key: key)
        
        // Build query
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            // Allow access after first unlock (persists across reinstalls)
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        
        // Add access group if specified (for app extensions)
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        // Add item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            print("⚠️ Keychain save failed for \(key.rawValue): \(status)")
        }
        
        return status == errSecSuccess
    }
    
    private func getString(for key: KeychainKey) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func delete(key: KeychainKey) {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key.rawValue
        ]
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        SecItemDelete(query as CFDictionary)
    }
}

// ============================================================================
// SECTION 3: AUTO-LOGIN MANAGER
// ============================================================================

/// Handles automatic login on app launch
final class AutoLoginManager {
    
    static let shared = AutoLoginManager()
    
    private let keychainManager = KeychainManager.shared
    private let authService: AuthServiceProtocol
    
    init(authService: AuthServiceProtocol = AuthService.shared) {
        self.authService = authService
    }
    
    /// Attempt auto-login on app launch
    /// Call this in didFinishLaunchingWithOptions
    func attemptAutoLogin(completion: @escaping (AutoLoginResult) -> Void) {
        // Check if we have stored credentials
        guard keychainManager.hasStoredCredentials,
              let accessToken = keychainManager.getAccessToken(),
              let userId = keychainManager.getUserId() else {
            completion(.noCredentials)
            return
        }
        
        // Validate token with server
        authService.validateToken(accessToken, userId: userId) { [weak self] result in
            switch result {
            case .success(let validationResult):
                if validationResult.isValid {
                    // Token is valid - proceed with login
                    completion(.success(userId: userId))
                } else if let newToken = validationResult.refreshedToken {
                    // Token was refreshed - save new token
                    self?.keychainManager.saveAccessToken(newToken)
                    completion(.success(userId: userId))
                } else {
                    // Token invalid and can't refresh
                    self?.keychainManager.clearAllCredentials()
                    completion(.tokenExpired)
                }
                
            case .failure:
                // Network error - allow offline access with cached token
                completion(.offlineMode(userId: userId))
            }
        }
    }
    
    /// Save credentials after successful login
    func saveLoginCredentials(accessToken: String, refreshToken: String?, userId: String) {
        _ = keychainManager.saveAccessToken(accessToken)
        if let refreshToken = refreshToken {
            _ = keychainManager.saveRefreshToken(refreshToken)
        }
        _ = keychainManager.saveUserId(userId)
    }
    
    /// Clear credentials on logout
    func logout() {
        keychainManager.clearAllCredentials()
    }
}

// MARK: - Result Types

enum AutoLoginResult {
    case success(userId: String)       // Token valid, proceed
    case noCredentials                  // First launch or logged out
    case tokenExpired                   // Need fresh login
    case offlineMode(userId: String)   // Network unavailable, use cached
}

struct TokenValidationResult {
    let isValid: Bool
    let refreshedToken: String?
}

// MARK: - Protocols

protocol AuthServiceProtocol {
    func validateToken(
        _ token: String,
        userId: String,
        completion: @escaping (Result<TokenValidationResult, Error>) -> Void
    )
}

enum AuthService {
    static let shared: AuthServiceProtocol = AuthServiceImpl()
}

class AuthServiceImpl: AuthServiceProtocol {
    func validateToken(
        _ token: String,
        userId: String,
        completion: @escaping (Result<TokenValidationResult, Error>) -> Void
    ) {
        // Implementation would make API call to validate token
    }
}

// ============================================================================
// SECTION 4: INTEGRATION
// ============================================================================

/*
 INTEGRATION IN APPDELEGATE:
 
 ```swift
 func application(
     _ application: UIApplication,
     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
 ) -> Bool {
     
     // Check for auto-login
     AutoLoginManager.shared.attemptAutoLogin { [weak self] result in
         DispatchQueue.main.async {
             switch result {
             case .success(let userId):
                 print("✅ Auto-login successful for user: \(userId)")
                 self?.showMainApp()
                 
             case .noCredentials:
                 print("📝 No stored credentials, show login")
                 self?.showLoginScreen()
                 
             case .tokenExpired:
                 print("⏰ Token expired, need fresh login")
                 self?.showLoginScreen()
                 
             case .offlineMode(let userId):
                 print("📴 Offline mode for user: \(userId)")
                 self?.showMainApp(offline: true)
             }
         }
     }
     
     return true
 }
 ```
 
 AFTER SUCCESSFUL LOGIN:
 
 ```swift
 func handleLoginSuccess(response: LoginResponse) {
     AutoLoginManager.shared.saveLoginCredentials(
         accessToken: response.accessToken,
         refreshToken: response.refreshToken,
         userId: response.userId
     )
     
     showMainApp()
 }
 ```
 
 ON LOGOUT:
 
 ```swift
 func handleLogout() {
     AutoLoginManager.shared.logout()
     showLoginScreen()
 }
 ```
*/

// ============================================================================
// SECTION 5: INTERVIEW QUESTIONS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "How do you implement auto-login that survives app reinstall?"         │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  Use iOS KEYCHAIN - it's the only storage that persists after uninstall.   │
 │                                                                             │
 │  FLOW:                                                                      │
 │  1. User logs in → Save auth token + user ID in Keychain                   │
 │  2. User uninstalls → Keychain data remains                                │
 │  3. User reinstalls → Check Keychain for credentials                       │
 │  4. If found → Validate token with server                                  │
 │  5. If valid → Auto-login, proceed to main app                             │
 │  6. If invalid → Clear Keychain, show login screen                         │
 │                                                                             │
 │  KEY CONFIGURATION:                                                         │
 │  - Use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly                    │
 │  - This ensures data persists but is device-specific                       │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "What's the difference between Keychain accessibility options?"        │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  kSecAttrAccessibleWhenUnlocked:                                           │
 │  - Accessible only when device is unlocked                                  │
 │  - Most secure, but can't access in background                             │
 │                                                                             │
 │  kSecAttrAccessibleAfterFirstUnlock:                                       │
 │  - Accessible after first unlock after reboot                              │
 │  - Good for background operations                                           │
 │  - Data can be restored to new device via backup                           │
 │                                                                             │
 │  kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly:                         │
 │  - Same as above, but NOT transferred to new device                        │
 │  - Best for auth tokens (device-specific)                                  │
 │                                                                             │
 │  FOR AUTO-LOGIN:                                                            │
 │  Use kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly because:             │
 │  - Survives app reinstall on same device ✓                                 │
 │  - Accessible in background for token refresh ✓                            │
 │  - Not transferred to new device (security) ✓                              │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

