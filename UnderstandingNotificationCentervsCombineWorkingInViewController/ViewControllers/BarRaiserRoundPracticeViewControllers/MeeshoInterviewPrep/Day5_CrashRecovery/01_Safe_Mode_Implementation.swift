// ============================================================================
// MEESHO INTERVIEW PREP: Safe Mode & Crash Loop Recovery
// ============================================================================
// Day 5: Crash Recovery and Safe Mode
//
// The interviewer implemented "Safe Mode recovery to auto-detect crash loops
// and restore app stability without user friction."
// ============================================================================

import Foundation
import UIKit

// ============================================================================
// SECTION 1: WHAT IS SAFE MODE? (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of Safe Mode like a "lifeboat" for your app:
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         NORMAL APP vs SAFE MODE                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 SCENARIO: User opens Meesho, app crashes. Opens again, crashes. Again, crashes.
 User is now frustrated and might uninstall! 😢
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  WITHOUT SAFE MODE:                                                         │
 │                                                                             │
 │  Launch 1 → 💥 Crash                                                       │
 │  Launch 2 → 💥 Crash                                                       │
 │  Launch 3 → 💥 Crash                                                       │
 │  User → 🗑️ Uninstalls app!                                                 │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  WITH SAFE MODE:                                                            │
 │                                                                             │
 │  Launch 1 → 💥 Crash (recorded)                                            │
 │  Launch 2 → 💥 Crash (recorded)                                            │
 │  Launch 3 → 🛡️ Safe Mode activated!                                        │
 │             - Clears corrupted caches                                       │
 │             - Disables experimental features                                │
 │             - Disables third-party SDKs                                     │
 │             - Shows minimal stable UI                                       │
 │  User can now use basic features! 🎉                                       │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 WHY THIS MATTERS FOR E-COMMERCE:
 - Crash loops can happen due to:
   • Corrupted local data
   • Bad server response cached locally
   • New feature bug
   • Third-party SDK crash
 
 - With Safe Mode, users can still:
   • Browse products
   • Add to cart
   • Complete purchases
 
 BUSINESS IMPACT:
 - Prevents uninstalls
 - Maintains user trust
 - Allows graceful degradation
 - Gives engineers time to fix issue
*/

// ============================================================================
// SECTION 2: CRASH LOOP DETECTION
// ============================================================================

/// Detects crash loops by tracking app launches and crashes
final class CrashLoopDetector {
    
    // MARK: - Configuration
    
    struct Configuration {
        /// Number of crashes in time window to trigger safe mode
        let crashThreshold: Int
        
        /// Time window to count crashes (in seconds)
        let timeWindowSeconds: TimeInterval
        
        /// How long to stay in safe mode before trying normal mode
        let safeModeDurationSeconds: TimeInterval
        
        static let `default` = Configuration(
            crashThreshold: 3,
            timeWindowSeconds: 300, // 5 minutes
            safeModeDurationSeconds: 3600 // 1 hour
        )
    }
    
    // MARK: - Singleton
    static let shared = CrashLoopDetector()
    
    // MARK: - Storage Keys
    private enum Keys {
        static let crashTimestamps = "crash_loop_timestamps"
        static let safeModeActivatedAt = "safe_mode_activated_at"
        static let sessionStarted = "session_started_flag"
        static let lastSuccessfulLaunch = "last_successful_launch"
    }
    
    // MARK: - Properties
    private let defaults: UserDefaults
    private let config: Configuration
    private(set) var isInSafeMode: Bool = false
    
    // MARK: - Initialization
    
    private init(
        defaults: UserDefaults = .standard,
        config: Configuration = .default
    ) {
        self.defaults = defaults
        self.config = config
    }
    
    // MARK: - Public API
    
    /// Call at the VERY START of app launch (before any other initialization)
    /// Returns true if app should run in safe mode
    func checkOnLaunch() -> Bool {
        // Step 1: Check if previous session crashed
        let previousSessionCrashed = !defaults.bool(forKey: Keys.sessionStarted) == false
        
        if !defaults.bool(forKey: Keys.sessionStarted) {
            // First launch ever, or clean launch
        } else {
            // Previous session didn't end cleanly - record as crash
            recordCrash()
        }
        
        // Step 2: Check if we should be in safe mode
        isInSafeMode = shouldActivateSafeMode()
        
        // Step 3: Mark session as started (will be cleared on clean exit)
        defaults.set(true, forKey: Keys.sessionStarted)
        
        if isInSafeMode {
            print("🛡️ SAFE MODE ACTIVATED - \(getCrashCount()) crashes detected")
        }
        
        return isInSafeMode
    }
    
    /// Call when app terminates cleanly (applicationWillTerminate)
    func markCleanShutdown() {
        defaults.set(false, forKey: Keys.sessionStarted)
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastSuccessfulLaunch)
    }
    
    /// Call when app enters background
    func markEnteringBackground() {
        // Save state in case app is killed in background
        defaults.set(false, forKey: Keys.sessionStarted)
    }
    
    /// Call when app becomes active
    func markBecomingActive() {
        defaults.set(true, forKey: Keys.sessionStarted)
    }
    
    // MARK: - Private Methods
    
    private func recordCrash() {
        var timestamps = getCrashTimestamps()
        timestamps.append(Date().timeIntervalSince1970)
        
        // Keep only recent crashes (within time window)
        let cutoff = Date().timeIntervalSince1970 - config.timeWindowSeconds
        timestamps = timestamps.filter { $0 > cutoff }
        
        defaults.set(timestamps, forKey: Keys.crashTimestamps)
        print("💥 Crash recorded. Total recent crashes: \(timestamps.count)")
    }
    
    private func getCrashTimestamps() -> [TimeInterval] {
        return defaults.array(forKey: Keys.crashTimestamps) as? [TimeInterval] ?? []
    }
    
    private func getCrashCount() -> Int {
        let cutoff = Date().timeIntervalSince1970 - config.timeWindowSeconds
        return getCrashTimestamps().filter { $0 > cutoff }.count
    }
    
    private func shouldActivateSafeMode() -> Bool {
        // Check if already in safe mode and duration hasn't expired
        if let activatedAt = defaults.object(forKey: Keys.safeModeActivatedAt) as? TimeInterval {
            let elapsed = Date().timeIntervalSince1970 - activatedAt
            if elapsed < config.safeModeDurationSeconds {
                return true
            } else {
                // Safe mode expired, try normal mode
                defaults.removeObject(forKey: Keys.safeModeActivatedAt)
                clearCrashHistory()
                return false
            }
        }
        
        // Check if crash threshold exceeded
        if getCrashCount() >= config.crashThreshold {
            defaults.set(Date().timeIntervalSince1970, forKey: Keys.safeModeActivatedAt)
            return true
        }
        
        return false
    }
    
    private func clearCrashHistory() {
        defaults.removeObject(forKey: Keys.crashTimestamps)
    }
}

// ============================================================================
// SECTION 3: SAFE MODE MANAGER
// ============================================================================

/// Manages Safe Mode behavior - what to disable, what to enable
final class SafeModeManager {
    
    // MARK: - Singleton
    static let shared = SafeModeManager()
    
    // MARK: - Properties
    
    var isInSafeMode: Bool {
        return CrashLoopDetector.shared.isInSafeMode
    }
    
    // Features to disable in safe mode
    private var disabledFeatures: Set<SafeModeFeature> = []
    
    // MARK: - Feature Flags
    
    enum SafeModeFeature: String, CaseIterable {
        case experimentalUI
        case thirdPartyAnalytics
        case videoPlayback
        case animatedBanners
        case webViews
        case pushNotifications
        case backgroundSync
        case serverDrivenUI
    }
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public API
    
    /// Activate safe mode - call after detecting crash loop
    func activateSafeMode() {
        print("🛡️ Activating Safe Mode...")
        
        // 1. Clear potentially corrupted caches
        clearCaches()
        
        // 2. Disable risky features
        disableRiskyFeatures()
        
        // 3. Notify analytics
        logSafeModeActivation()
        
        // 4. Post notification for UI to update
        NotificationCenter.default.post(name: .safeModeActivated, object: nil)
    }
    
    /// Check if a feature should be enabled
    func isFeatureEnabled(_ feature: SafeModeFeature) -> Bool {
        if isInSafeMode {
            return !disabledFeatures.contains(feature)
        }
        return true
    }
    
    /// Exit safe mode (e.g., after successful session)
    func exitSafeMode() {
        disabledFeatures.removeAll()
        NotificationCenter.default.post(name: .safeModeDeactivated, object: nil)
    }
    
    // MARK: - Private Methods
    
    private func clearCaches() {
        // Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // Clear image cache
        ImageCacheManager.shared.clearAll()
        
        // Clear potentially corrupted data
        clearCorruptedData()
        
        print("✅ Caches cleared")
    }
    
    private func clearCorruptedData() {
        // Clear cached API responses
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let apiCacheDir = cacheDir.appendingPathComponent("APICache")
        try? FileManager.default.removeItem(at: apiCacheDir)
        
        // Clear potentially corrupted preferences
        // (Be careful - don't clear auth tokens!)
        UserDefaults.standard.removeObject(forKey: "cached_home_feed")
        UserDefaults.standard.removeObject(forKey: "cached_banners")
    }
    
    private func disableRiskyFeatures() {
        // Disable features that might cause crashes
        disabledFeatures = [
            .experimentalUI,
            .thirdPartyAnalytics,
            .videoPlayback,
            .animatedBanners,
            .serverDrivenUI // SDUI might have bad config
        ]
        
        print("✅ Disabled features: \(disabledFeatures.map { $0.rawValue })")
    }
    
    private func logSafeModeActivation() {
        // Log to your analytics (use minimal, safe logging)
        print("📊 Logging safe mode activation")
    }
}

// MARK: - Notifications

extension Notification.Name {
    static let safeModeActivated = Notification.Name("SafeModeActivated")
    static let safeModeDeactivated = Notification.Name("SafeModeDeactivated")
}

// ============================================================================
// SECTION 4: INTEGRATION IN APP DELEGATE
// ============================================================================

/*
 HOW TO INTEGRATE:
 
 ```swift
 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {
     
     func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
         
         // STEP 1: Check for crash loop FIRST (before any other initialization)
         let shouldUseSafeMode = CrashLoopDetector.shared.checkOnLaunch()
         
         if shouldUseSafeMode {
             // STEP 2: Activate safe mode
             SafeModeManager.shared.activateSafeMode()
             
             // STEP 3: Show safe mode UI
             // Use minimal, stable UI components
             setupSafeModeUI()
         } else {
             // Normal initialization
             setupNormalApp()
         }
         
         return true
     }
     
     func applicationDidEnterBackground(_ application: UIApplication) {
         CrashLoopDetector.shared.markEnteringBackground()
     }
     
     func applicationWillEnterForeground(_ application: UIApplication) {
         CrashLoopDetector.shared.markBecomingActive()
     }
     
     func applicationWillTerminate(_ application: UIApplication) {
         CrashLoopDetector.shared.markCleanShutdown()
     }
 }
 ```
*/

// ============================================================================
// SECTION 5: SAFE MODE UI EXAMPLE
// ============================================================================

/// Safe Mode Banner to show users
class SafeModeBannerView: UIView {
    
    private let messageLabel: UILabel = {
        let label = UILabel()
        label.text = "We're experiencing issues. Some features may be limited."
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        backgroundColor = UIColor.orange
        
        addSubview(messageLabel)
        messageLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            messageLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            messageLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            messageLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            messageLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
}

/// View Controller that adapts to Safe Mode
class SafeModeAwareViewController: UIViewController {
    
    private var safeModeObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Observe safe mode changes
        safeModeObserver = NotificationCenter.default.addObserver(
            forName: .safeModeActivated,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleSafeModeActivation()
        }
        
        // Check current state
        if SafeModeManager.shared.isInSafeMode {
            handleSafeModeActivation()
        }
    }
    
    private func handleSafeModeActivation() {
        // Show safe mode banner
        let banner = SafeModeBannerView()
        view.addSubview(banner)
        banner.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            banner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            banner.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            banner.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor)
        ])
        
        // Disable unsafe features
        disableUnsafeFeatures()
    }
    
    private func disableUnsafeFeatures() {
        // Disable features based on SafeModeManager
        if !SafeModeManager.shared.isFeatureEnabled(.videoPlayback) {
            // Hide video players
        }
        
        if !SafeModeManager.shared.isFeatureEnabled(.animatedBanners) {
            // Stop animations
        }
    }
}

// ============================================================================
// SECTION 6: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "Design a crash loop detection system"                                 │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  ALGORITHM:                                                                 │
 │  1. On app launch, set a flag "sessionStarted = true"                       │
 │  2. On clean exit (willTerminate, background), set flag to false            │
 │  3. On next launch, if flag is still true → previous session crashed        │
 │  4. Record crash timestamp in array                                         │
 │  5. If N crashes in T minutes → activate safe mode                          │
 │                                                                             │
 │  CONFIGURATION:                                                             │
 │  - crashThreshold: 3 (number of crashes to trigger)                         │
 │  - timeWindow: 5 minutes (how far back to look)                             │
 │  - safeModeDuration: 1 hour (how long to stay in safe mode)                 │
 │                                                                             │
 │  EDGE CASES:                                                                │
 │  - Background kills (not a crash, don't count)                              │
 │  - Force quit (not a crash, but flag won't be cleared - accept false positive)│
 │  - First launch (no previous session, skip check)                           │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "What features would you disable in safe mode?"                        │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  DISABLE (risky features):                                                  │
 │  - Server-Driven UI (might have bad config)                                 │
 │  - Experimental features (A/B tests)                                        │
 │  - Third-party SDKs (analytics, crash reporters - ironic but safe)          │
 │  - Video playback (memory intensive)                                        │
 │  - WebViews (unpredictable content)                                         │
 │  - Complex animations                                                       │
 │  - Background sync                                                          │
 │                                                                             │
 │  KEEP ENABLED (core features):                                              │
 │  - Product browsing (static list, no SDUI)                                  │
 │  - Cart functionality                                                       │
 │  - Checkout flow                                                            │
 │  - User authentication                                                      │
 │  - Basic search                                                             │
 │                                                                             │
 │  ALSO DO:                                                                   │
 │  - Clear caches (corrupted data might be the cause)                         │
 │  - Show user-friendly message                                               │
 │  - Log to analytics for debugging                                           │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "How do you exit safe mode?"                                           │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  STRATEGIES:                                                                │
 │                                                                             │
 │  1. TIME-BASED:                                                             │
 │     - After 1 hour, try normal mode                                         │
 │     - If crashes again, extend safe mode duration                           │
 │                                                                             │
 │  2. SUCCESS-BASED:                                                          │
 │     - After N successful sessions, exit safe mode                           │
 │     - More reliable than time-based                                         │
 │                                                                             │
 │  3. APP UPDATE:                                                             │
 │     - New app version might fix the bug                                     │
 │     - Check version on launch, clear safe mode if updated                   │
 │                                                                             │
 │  4. REMOTE CONFIG:                                                          │
 │     - Server can tell app to exit safe mode                                 │
 │     - Useful when you've fixed the issue server-side                        │
 │                                                                             │
 │  IMPLEMENTATION:                                                            │
 │  - On safe mode exit, clear crash history                                   │
 │  - Gradually re-enable features one by one                                  │
 │  - Monitor for crashes as features are restored                             │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 7: WHITEBOARD DIAGRAM
// ============================================================================

/*
 CRASH LOOP DETECTION FLOW (Draw this):
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                          APP LAUNCH FLOW                                    │
 └─────────────────────────────────────────────────────────────────────────────┘
 
                            ┌──────────────┐
                            │  App Launch  │
                            └──────┬───────┘
                                   │
                                   ▼
                    ┌──────────────────────────────┐
                    │ Was 'sessionStarted' = true? │
                    │ (Previous session crashed)   │
                    └──────────────┬───────────────┘
                                   │
                  ┌────────────────┴────────────────┐
                  │                                 │
                 YES                               NO
            (Crashed!)                    (Clean or first)
                  │                                 │
                  ▼                                 │
        ┌─────────────────┐                        │
        │ Record crash    │                        │
        │ timestamp       │                        │
        └────────┬────────┘                        │
                 │                                 │
                 └──────────────┬──────────────────┘
                                │
                                ▼
                    ┌──────────────────────────┐
                    │ Count crashes in last    │
                    │ 5 minutes               │
                    └──────────────┬───────────┘
                                   │
                  ┌────────────────┴────────────────┐
                  │                                 │
              >= 3 crashes                    < 3 crashes
                  │                                 │
                  ▼                                 ▼
        ┌─────────────────┐              ┌─────────────────┐
        │  🛡️ SAFE MODE   │              │  Normal Mode    │
        │  - Clear caches │              │  - Full features│
        │  - Disable risk │              │                 │
        └─────────────────┘              └─────────────────┘
 
 
 SESSION LIFECYCLE:
 
     Launch                Background              Terminate
        │                      │                      │
        ▼                      ▼                      ▼
 ┌──────────────┐       ┌──────────────┐       ┌──────────────┐
 │ sessionStart │       │ sessionStart │       │ sessionStart │
 │   = true     │       │   = false    │       │   = false    │
 └──────────────┘       └──────────────┘       └──────────────┘
 
 If app crashes:
 - sessionStart stays true
 - Next launch detects this as crash
 
 If app exits cleanly:
 - sessionStart set to false
 - Next launch sees clean exit
*/

