// ============================================================================
// MEESHO INTERVIEW PREP: OOM Detection Complete Guide
// ============================================================================
// Day 1-2: App Observability and Performance Monitoring
//
// The interviewer reduced OOMs by 50% at Meesho. This is a critical topic!
// OOM = Out Of Memory - when iOS kills your app due to excessive memory usage.
// ============================================================================

import Foundation
import UIKit

// ============================================================================
// SECTION 1: UNDERSTANDING OOM (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of your iPhone's RAM like a hotel with limited rooms:
 
 ┌─────────────────────────────────────────────────────────────────┐
 │                     iPhone RAM (Hotel)                          │
 ├─────────────────────────────────────────────────────────────────┤
 │  Room 1: iOS System (always reserved, can't be kicked out)      │
 │  Room 2: Phone App (high priority, rarely kicked out)           │
 │  Room 3: Messages (medium priority)                             │
 │  Room 4: Meesho App (YOUR app - can be kicked out!)             │
 │  Room 5: Safari (was kicked out to make room)                   │
 │  Room 6: Empty (available)                                      │
 └─────────────────────────────────────────────────────────────────┘
 
 When all rooms are full and a new guest (app) needs a room:
 1. iOS looks for apps using too much space (memory)
 2. iOS kicks out (KILLS) those apps without warning
 3. This is an OOM (Out Of Memory) crash
 
 THE PROBLEM:
 - OOM crashes are SILENT - no crash log is generated
 - From user's perspective: app just "disappears"
 - MetricKit doesn't directly report OOMs
 - You must INFER that an OOM happened
 
 WHY THIS MATTERS FOR E-COMMERCE:
 - Product images use LOTS of memory
 - Users browse many products (loading more images)
 - Memory builds up → OOM → user was about to checkout → LOST SALE!
*/

// ============================================================================
// SECTION 2: THE OOM DETECTION ALGORITHM
// ============================================================================
/*
 HOW TO DETECT AN OOM:
 
 If an app terminates and it was NOT due to:
 - User force-quit
 - System upgrade
 - App update
 - Normal app termination
 - Crash (we'd have a crash log)
 - Watchdog kill (too long in background)
 
 Then it was likely an OOM!
 
 DETECTION FLOW:
 
 App Launches
      │
      ▼
 ┌─────────────────────────────────────┐
 │ Check: Did last session end cleanly?│
 │ (didTerminateCleanly flag in storage)│
 └─────────────────────┬───────────────┘
                       │
           ┌───────────┴───────────┐
           │                       │
        YES (Clean)             NO (Dirty)
           │                       │
           ▼                       ▼
    Normal startup         ┌──────────────────┐
                          │ Check other causes:│
                          │ - Was there a crash?│
                          │ - Was app updated?  │
                          │ - Was memory high?  │
                          └─────────┬──────────┘
                                    │
                         ┌──────────┴──────────┐
                         │                     │
                      Other cause           No other cause
                         │                     │
                         ▼                     ▼
                   Handle that cause    ⚠️ LIKELY OOM!
                                              │
                                              ▼
                                    Report to analytics
*/

// ============================================================================
// SECTION 3: OOM DETECTOR IMPLEMENTATION
// ============================================================================

/// Comprehensive OOM (Out Of Memory) detector.
/// This class tracks app termination state to infer OOM crashes.
///
/// INTERVIEW TIP: Explain that this uses a "flag-based" detection approach.
/// We set a flag when app launches, and clear it on clean exit.
/// If the flag is still set on next launch, the previous session crashed.
final class OOMDetector {
    
    // MARK: - Singleton
    static let shared = OOMDetector()
    
    // MARK: - Constants (UserDefaults Keys)
    private enum Keys {
        static let didTerminateCleanly = "oom_detector_did_terminate_cleanly"
        static let lastKnownMemoryMB = "oom_detector_last_memory_mb"
        static let lastAppVersion = "oom_detector_last_app_version"
        static let wasInBackground = "oom_detector_was_in_background"
        static let lastSessionStartTime = "oom_detector_session_start"
    }
    
    // MARK: - Configuration
    
    /// Memory threshold above which we suspect OOM (in MB)
    /// If app was using more than this when it died, likely OOM
    private let highMemoryThresholdMB: Double = 500
    
    /// How often to sample memory usage (in seconds)
    private let memorySamplingInterval: TimeInterval = 30
    
    // MARK: - Dependencies
    private let defaults: UserDefaults
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - State
    private var memorySamplingTimer: Timer?
    private var currentSessionStartTime: Date?
    
    // MARK: - Initialization
    
    private init() {
        self.defaults = UserDefaults.standard
        self.analyticsService = AnalyticsService.shared
    }
    
    /// Testable initializer
    init(defaults: UserDefaults, analyticsService: AnalyticsServiceProtocol) {
        self.defaults = defaults
        self.analyticsService = analyticsService
    }
    
    // MARK: - Public API
    
    /// Call this FIRST thing in AppDelegate's didFinishLaunchingWithOptions.
    /// This checks if the previous session ended with an OOM.
    func applicationDidLaunch() {
        // Step 1: Check previous session
        checkForPreviousOOM()
        
        // Step 2: Mark this session as "in progress" (not clean)
        markSessionStarted()
        
        // Step 3: Start memory monitoring
        startMemorySampling()
    }
    
    /// Call this when app enters background (applicationDidEnterBackground)
    func applicationDidEnterBackground() {
        defaults.set(true, forKey: Keys.wasInBackground)
        // Take final memory reading
        recordCurrentMemory()
    }
    
    /// Call this when app will terminate cleanly (applicationWillTerminate)
    func applicationWillTerminate() {
        markCleanTermination()
    }
    
    /// Call this when app enters foreground (applicationWillEnterForeground)
    func applicationWillEnterForeground() {
        defaults.set(false, forKey: Keys.wasInBackground)
    }
    
    // MARK: - Detection Logic
    
    private func checkForPreviousOOM() {
        // Was the previous termination clean?
        let didTerminateCleanly = defaults.bool(forKey: Keys.didTerminateCleanly)
        
        // If it was clean, nothing to check
        if didTerminateCleanly {
            print("✅ Previous session ended cleanly")
            return
        }
        
        // Previous session was NOT clean - investigate
        print("⚠️ Previous session did NOT end cleanly - investigating...")
        
        // Gather evidence
        let evidence = gatherOOMEvidence()
        
        // Analyze and report
        if evidence.isLikelyOOM {
            reportPotentialOOM(evidence: evidence)
        } else {
            // Might be a crash that wasn't detected yet, or background kill
            reportUnclearTermination(evidence: evidence)
        }
    }
    
    /// Gather evidence about the previous termination
    private func gatherOOMEvidence() -> OOMEvidence {
        let lastMemoryMB = defaults.double(forKey: Keys.lastKnownMemoryMB)
        let lastAppVersion = defaults.string(forKey: Keys.lastAppVersion)
        let currentAppVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        let wasInBackground = defaults.bool(forKey: Keys.wasInBackground)
        let sessionStartTime = defaults.double(forKey: Keys.lastSessionStartTime)
        
        return OOMEvidence(
            lastMemoryMB: lastMemoryMB,
            wasMemoryHigh: lastMemoryMB > highMemoryThresholdMB,
            wasAppUpdated: lastAppVersion != currentAppVersion,
            wasInBackground: wasInBackground,
            sessionDurationSeconds: sessionStartTime > 0 
                ? Date().timeIntervalSince1970 - sessionStartTime 
                : 0
        )
    }
    
    private func reportPotentialOOM(evidence: OOMEvidence) {
        print("🚨 POTENTIAL OOM DETECTED!")
        print("   Last memory: \(evidence.lastMemoryMB)MB")
        print("   Was in background: \(evidence.wasInBackground)")
        
        analyticsService.log(
            event: "potential_oom",
            params: [
                "last_memory_mb": evidence.lastMemoryMB,
                "was_in_background": evidence.wasInBackground,
                "session_duration_seconds": evidence.sessionDurationSeconds
            ]
        )
        
        // Also send to crash reporting service
        CrashReporter.shared.report(
            type: .oom,
            info: [
                "last_memory_mb": evidence.lastMemoryMB,
                "was_in_background": evidence.wasInBackground
            ],
            callStack: nil // OOMs don't have call stacks
        )
    }
    
    private func reportUnclearTermination(evidence: OOMEvidence) {
        analyticsService.log(
            event: "unclear_termination",
            params: [
                "last_memory_mb": evidence.lastMemoryMB,
                "was_in_background": evidence.wasInBackground,
                "was_app_updated": evidence.wasAppUpdated
            ]
        )
    }
    
    // MARK: - Session Management
    
    private func markSessionStarted() {
        // Mark as "dirty" - if we crash, this will still be false
        defaults.set(false, forKey: Keys.didTerminateCleanly)
        
        // Record current app version
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
        defaults.set(currentVersion, forKey: Keys.lastAppVersion)
        
        // Record session start time
        currentSessionStartTime = Date()
        defaults.set(Date().timeIntervalSince1970, forKey: Keys.lastSessionStartTime)
        
        // Reset background flag
        defaults.set(false, forKey: Keys.wasInBackground)
    }
    
    private func markCleanTermination() {
        defaults.set(true, forKey: Keys.didTerminateCleanly)
        stopMemorySampling()
    }
    
    // MARK: - Memory Sampling
    
    private func startMemorySampling() {
        // Take initial reading
        recordCurrentMemory()
        
        // Set up periodic sampling
        memorySamplingTimer = Timer.scheduledTimer(
            withTimeInterval: memorySamplingInterval,
            repeats: true
        ) { [weak self] _ in
            self?.recordCurrentMemory()
        }
    }
    
    private func stopMemorySampling() {
        memorySamplingTimer?.invalidate()
        memorySamplingTimer = nil
    }
    
    private func recordCurrentMemory() {
        let memoryMB = getCurrentMemoryUsage()
        defaults.set(memoryMB, forKey: Keys.lastKnownMemoryMB)
        
        // Log high memory warnings
        if memoryMB > highMemoryThresholdMB {
            print("⚠️ High memory usage: \(memoryMB)MB")
            analyticsService.log(
                event: "high_memory_warning",
                params: ["memory_mb": memoryMB]
            )
        }
    }
    
    /// Get current app memory usage in megabytes
    private func getCurrentMemoryUsage() -> Double {
        /*
         TECHNICAL EXPLANATION:
         
         We use mach_task_basic_info to get the "resident size" of our process.
         
         Resident Size = Physical RAM currently used by our app
         
         This includes:
         - Heap allocations (objects we create)
         - Stack memory
         - Mapped files (images loaded into memory)
         - Framework memory
         
         This is what iOS uses to decide when to kill our app!
        */
        
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size
        )
        
        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    intPtr,
                    &count
                )
            }
        }
        
        guard result == KERN_SUCCESS else {
            return 0
        }
        
        // Convert bytes to megabytes
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
}

// MARK: - Evidence Model

/// Holds evidence about a potential OOM
struct OOMEvidence {
    let lastMemoryMB: Double
    let wasMemoryHigh: Bool
    let wasAppUpdated: Bool
    let wasInBackground: Bool
    let sessionDurationSeconds: TimeInterval
    
    /// Heuristic to determine if this was likely an OOM
    var isLikelyOOM: Bool {
        // If memory was high and app wasn't updated, likely OOM
        if wasMemoryHigh && !wasAppUpdated {
            return true
        }
        
        // If app was in foreground (not background killed) and high memory
        if !wasInBackground && wasMemoryHigh {
            return true
        }
        
        // If session was very short (< 5 seconds), might be crash, not OOM
        if sessionDurationSeconds < 5 {
            return false
        }
        
        return wasMemoryHigh
    }
}

// ============================================================================
// SECTION 4: ADVANCED OOM PREVENTION
// ============================================================================

/// Manager for preventing OOMs through proactive memory management
final class OOMPreventionManager {
    
    static let shared = OOMPreventionManager()
    
    // Memory thresholds in MB
    private let warningThreshold: Double = 400
    private let criticalThreshold: Double = 600
    private let emergencyThreshold: Double = 800
    
    /// Called periodically or on memory warning
    func evaluateMemoryPressure() {
        let currentMemory = OOMDetector.shared.currentMemoryMB
        
        switch currentMemory {
        case ..<warningThreshold:
            // Normal operation
            break
            
        case warningThreshold..<criticalThreshold:
            handleWarningLevel()
            
        case criticalThreshold..<emergencyThreshold:
            handleCriticalLevel()
            
        default:
            handleEmergencyLevel()
        }
    }
    
    private func handleWarningLevel() {
        print("⚠️ Memory Warning Level - Clearing optional caches")
        
        // Clear non-essential caches
        URLCache.shared.removeAllCachedResponses()
        
        // Notify interested components
        NotificationCenter.default.post(
            name: .memoryWarningLevel,
            object: nil
        )
    }
    
    private func handleCriticalLevel() {
        print("🔴 Memory Critical Level - Aggressive cleanup")
        
        // Clear all image caches
        ImageCache.shared.clearAll()
        
        // Release any pre-loaded content
        PreloadManager.shared.releaseAll()
        
        NotificationCenter.default.post(
            name: .memoryCriticalLevel,
            object: nil
        )
    }
    
    private func handleEmergencyLevel() {
        print("🚨 Memory Emergency Level - Survival mode")
        
        // Clear everything possible
        handleCriticalLevel()
        
        // Disable features that use memory
        FeatureFlags.disableMemoryIntensiveFeatures()
        
        // Show user a message if in foreground
        if UIApplication.shared.applicationState == .active {
            showMemoryWarningToUser()
        }
        
        NotificationCenter.default.post(
            name: .memoryEmergencyLevel,
            object: nil
        )
    }
    
    private func showMemoryWarningToUser() {
        // In production, show a subtle banner, not an alert
        print("Would show: 'Low memory - some features temporarily disabled'")
    }
}

// MARK: - Extension for OOMDetector

extension OOMDetector {
    var currentMemoryMB: Double {
        return getCurrentMemoryUsagePublic()
    }
    
    private func getCurrentMemoryUsagePublic() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size / MemoryLayout<integer_t>.size
        )
        
        let result = withUnsafeMutablePointer(to: &info) { infoPtr in
            infoPtr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), intPtr, &count)
            }
        }
        
        guard result == KERN_SUCCESS else { return 0 }
        return Double(info.resident_size) / 1024.0 / 1024.0
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let memoryWarningLevel = Notification.Name("OOM_MemoryWarningLevel")
    static let memoryCriticalLevel = Notification.Name("OOM_MemoryCriticalLevel")
    static let memoryEmergencyLevel = Notification.Name("OOM_MemoryEmergencyLevel")
}

// MARK: - Placeholder Types

enum FeatureFlags {
    static func disableMemoryIntensiveFeatures() {
        // Disable video autoplay, high-res images, etc.
    }
}

enum ImageCache {
    static let shared = ImageCache.self
    static func clearAll() {}
}

enum PreloadManager {
    static let shared = PreloadManager.self
    static func releaseAll() {}
}

// ============================================================================
// SECTION 5: INTEGRATION EXAMPLE
// ============================================================================

/*
 COMPLETE APPDELEGATE INTEGRATION:
 
 ```swift
 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {
     
     func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
         
         // IMPORTANT: Call OOM detector FIRST
         // This checks if previous session had an OOM
         OOMDetector.shared.applicationDidLaunch()
         
         // Then MetricKit
         MetricKitManager.shared.startMonitoring()
         
         // ... other setup
         
         return true
     }
     
     func applicationDidEnterBackground(_ application: UIApplication) {
         OOMDetector.shared.applicationDidEnterBackground()
     }
     
     func applicationWillEnterForeground(_ application: UIApplication) {
         OOMDetector.shared.applicationWillEnterForeground()
     }
     
     func applicationWillTerminate(_ application: UIApplication) {
         OOMDetector.shared.applicationWillTerminate()
     }
     
     func applicationDidReceiveMemoryWarning(_ application: UIApplication) {
         // iOS is telling us memory is low
         OOMPreventionManager.shared.evaluateMemoryPressure()
     }
 }
 ```
*/

// ============================================================================
// SECTION 6: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "How do you detect OOMs if there's no crash log?"                      │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │  We use a "flag-based" detection approach:                                  │
 │                                                                             │
 │  1. On app launch, we set a flag "didTerminateCleanly = false"              │
 │  2. We periodically record current memory usage                             │
 │  3. On clean termination (user closed app), we set flag to true             │
 │  4. On next launch, if flag is still false AND memory was high,             │
 │     AND there was no crash log → likely an OOM                              │
 │                                                                             │
 │  We also filter out other causes:                                           │
 │  - App updates (version changed)                                            │
 │  - System updates                                                           │
 │  - Watchdog kills (app in background too long)                              │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "How would you reduce OOMs by 50% like Meesho did?"                    │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │  Multiple strategies working together:                                       │
 │                                                                             │
 │  1. IMAGE OPTIMIZATION (biggest impact for e-commerce):                     │
 │     - Downsample images to display size, not full resolution                │
 │     - A 4000x3000 image uses 48MB, downsampled to 400x300 uses 0.5MB        │
 │                                                                             │
 │  2. CACHE MANAGEMENT:                                                       │
 │     - Set memory limits on NSCache                                          │
 │     - Implement tiered caching (memory → disk)                              │
 │     - Clear caches on memory warnings                                       │
 │                                                                             │
 │  3. FIX RETAIN CYCLES:                                                      │
 │     - Audit all closures for [weak self]                                    │
 │     - Use Instruments to find leaks                                         │
 │                                                                             │
 │  4. PROACTIVE MONITORING:                                                   │
 │     - Track memory in real-time                                             │
 │     - Degrade features before hitting limits                                │
 │     - Pre-emptively clear caches at warning thresholds                      │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "What memory limits should you design for?"                            │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │  iOS doesn't publish exact limits, but from experience:                     │
 │                                                                             │
 │  Device            │ Typical Safe Limit  │ Danger Zone                     │
 │  ─────────────────┼────────────────────┼───────────────                    │
 │  iPhone 15 Pro     │ 1.2-1.5 GB         │ > 1.8 GB                         │
 │  iPhone 12         │ 800MB - 1 GB       │ > 1.2 GB                         │
 │  iPhone SE         │ 500-700 MB         │ > 900 MB                         │
 │                                                                             │
 │  DESIGN PRINCIPLE:                                                          │
 │  Target the OLDEST supported device. If you support iPhone SE,              │
 │  design for 500MB peak memory even on iPhone 15 Pro.                        │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 7: WHITEBOARD DIAGRAM TO PRACTICE
// ============================================================================

/*
 OOM DETECTION FLOW (Draw this on whiteboard):
 
                           ┌──────────────┐
                           │  App Launch  │
                           └──────┬───────┘
                                  │
                                  ▼
                      ┌─────────────────────────┐
                      │ Check: didTerminateCleanly │
                      │ flag from last session    │
                      └───────────┬───────────────┘
                                  │
                  ┌───────────────┴───────────────┐
                  │                               │
               TRUE                            FALSE
                  │                               │
                  ▼                               ▼
         ┌─────────────────┐            ┌─────────────────────┐
         │ Normal startup  │            │ Investigate cause:  │
         │ Last session OK │            │ - Check last memory │
         └─────────────────┘            │ - Check for crash   │
                                        │ - Check app version │
                                        └──────────┬──────────┘
                                                   │
                                    ┌──────────────┴──────────────┐
                                    │                             │
                              Memory High                    Memory Low
                              + No Crash                     or Crash Found
                                    │                             │
                                    ▼                             ▼
                           ┌─────────────────┐          ┌─────────────────┐
                           │   OOM LIKELY!   │          │ Other cause     │
                           │   Report it     │          │ (crash, etc.)   │
                           └─────────────────┘          └─────────────────┘
 
 
 MEMORY MONITORING LOOP:
 
              ┌───────────────────────────────────────────────┐
              │                                               │
              │    Every 30 seconds:                          │
              │                                               │
              │    ┌───────────────────┐                     │
              │    │ Read current      │                     │
              │    │ memory usage      │                     │
              │    └─────────┬─────────┘                     │
              │              │                               │
              │              ▼                               │
              │    ┌───────────────────┐                     │
              │    │ Save to           │                     │
              │    │ UserDefaults      │                     │
              │    └─────────┬─────────┘                     │
              │              │                               │
              │    ┌─────────┴─────────┐                     │
              │    │                   │                     │
              │    ▼                   ▼                     │
              │ < 500MB            >= 500MB                  │
              │    │                   │                     │
              │    ▼                   ▼                     │
              │ Continue           Log warning               │
              │                    + start cleanup           │
              │                                               │
              └───────────────────────────────────────────────┘
*/

