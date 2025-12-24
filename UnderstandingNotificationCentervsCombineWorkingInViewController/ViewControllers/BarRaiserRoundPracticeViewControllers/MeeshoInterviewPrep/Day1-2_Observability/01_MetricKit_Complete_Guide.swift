// ============================================================================
// MEESHO INTERVIEW PREP: MetricKit Complete Guide
// ============================================================================
// Day 1-2: App Observability and Performance Monitoring
//
// This file covers everything you need to know about MetricKit for the
// Meesho Bar Raiser interview. The interviewer has integrated MetricKit
// for page-load performance tracking and OOM detection.
// ============================================================================

import Foundation
import MetricKit
import UIKit

// ============================================================================
// SECTION 1: WHAT IS METRICKIT? (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of MetricKit as a "fitness tracker" for your iOS app:
 
 ┌─────────────────────────────────────────────────────────────────┐
 │  Fitness Tracker (for humans)    │   MetricKit (for apps)       │
 ├───────────────────────────────────┼──────────────────────────────┤
 │  Tracks heart rate               │   Tracks app launch time     │
 │  Counts steps                    │   Counts memory usage        │
 │  Records sleep quality           │   Records battery drain      │
 │  Alerts on health issues         │   Alerts on crashes/hangs    │
 │  Daily summary report            │   24-hour aggregated report  │
 └─────────────────────────────────────────────────────────────────┘
 
 KEY INSIGHT: iOS collects metrics SILENTLY in the background.
 Every 24 hours, it delivers a "report card" of your app's health.
 
 WHY THIS MATTERS FOR MEESHO:
 - E-commerce apps need to be FAST (users leave if product images are slow)
 - Crashes = lost revenue (user was about to buy, app crashed)
 - Memory issues = silent app kills (user thinks app is buggy)
*/

// ============================================================================
// SECTION 2: THE TWO TYPES OF METRICKIT DATA
// ============================================================================
/*
 MetricKit delivers two types of payloads:
 
 ┌─────────────────────────────────────────────────────────────────┐
 │                    MXMetricPayload                              │
 │   (Performance Metrics - delivered every ~24 hours)             │
 ├─────────────────────────────────────────────────────────────────┤
 │  • App Launch Time (cold & warm)                                │
 │  • Memory Usage (peak, average)                                 │
 │  • CPU Usage                                                    │
 │  • Disk I/O                                                     │
 │  • Network Transfer                                             │
 │  • Battery Drain (by component)                                 │
 │  • Scroll Hitch Rate (janky scrolling)                          │
 └─────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────┐
 │                   MXDiagnosticPayload                           │
 │   (Diagnostic Reports - delivered when issues occur)            │
 ├─────────────────────────────────────────────────────────────────┤
 │  • Crash Reports (with call stacks)                             │
 │  • Hang Reports (app frozen > 250ms)                            │
 │  • CPU Exceptions (excessive CPU usage)                         │
 │  • Disk Write Exceptions                                        │
 │                                                                 │
 │  NOTE: These are delivered faster than 24h when they occur!     │
 └─────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 3: BASIC METRICKIT SETUP
// ============================================================================

/// The centralized manager for all MetricKit operations.
/// This follows the Singleton pattern for easy access throughout the app.
///
/// INTERVIEW TIP: Mention that you use a dedicated manager class to:
/// 1. Encapsulate all MetricKit logic
/// 2. Make it testable (can mock the manager)
/// 3. Single responsibility principle
final class MetricKitManager: NSObject {
    
    // MARK: - Singleton
    static let shared = MetricKitManager()
    
    // MARK: - Dependencies
    private let analyticsService: AnalyticsServiceProtocol
    private let crashReporter: CrashReporterProtocol
    
    // MARK: - State
    private(set) var isMonitoring = false
    
    // MARK: - Initialization
    
    /// Private init for singleton. In production, you might use dependency injection.
    private override init() {
        self.analyticsService = AnalyticsService.shared
        self.crashReporter = CrashReporter.shared
        super.init()
    }
    
    /// Testable initializer with injected dependencies
    init(analyticsService: AnalyticsServiceProtocol, crashReporter: CrashReporterProtocol) {
        self.analyticsService = analyticsService
        self.crashReporter = crashReporter
        super.init()
    }
    
    // MARK: - Public API
    
    /// Start monitoring. Call this in AppDelegate's didFinishLaunchingWithOptions.
    ///
    /// INTERVIEW TIP: Emphasize that this should be called EARLY in app lifecycle
    /// to capture metrics from the very beginning.
    func startMonitoring() {
        guard !isMonitoring else {
            print("⚠️ MetricKit monitoring already active")
            return
        }
        
        // Subscribe to receive metric payloads
        MXMetricManager.shared.add(self)
        isMonitoring = true
        
        print("📊 MetricKit monitoring started")
    }
    
    /// Stop monitoring. Call this when app is terminating (if needed).
    func stopMonitoring() {
        MXMetricManager.shared.remove(self)
        isMonitoring = false
        print("📊 MetricKit monitoring stopped")
    }
}

// MARK: - MXMetricManagerSubscriber Implementation

extension MetricKitManager: MXMetricManagerSubscriber {
    
    // =========================================================================
    // PERFORMANCE METRICS (Called every ~24 hours)
    // =========================================================================
    
    /// Called by iOS when aggregated performance metrics are available.
    /// This typically happens once per day, containing the last 24 hours of data.
    ///
    /// INTERVIEW TIP: Explain that these are HISTOGRAMS, not single values.
    /// iOS collects many measurements and gives you distribution data.
    func didReceive(_ payloads: [MXMetricPayload]) {
        for payload in payloads {
            processMetricPayload(payload)
        }
    }
    
    // =========================================================================
    // DIAGNOSTIC REPORTS (Called when crashes/hangs occur)
    // =========================================================================
    
    /// Called when crash or hang diagnostics are available.
    /// Available on iOS 14+. This is crucial for root-cause analysis.
    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for payload in payloads {
            processDiagnosticPayload(payload)
        }
    }
    
    // MARK: - Private Processing Methods
    
    private func processMetricPayload(_ payload: MXMetricPayload) {
        // 1. Extract launch metrics (CRITICAL for Meesho - they optimized this)
        if let launchMetrics = payload.applicationLaunchMetrics {
            processLaunchMetrics(launchMetrics)
        }
        
        // 2. Extract memory metrics (CRITICAL - they reduced OOMs by 50%)
        if let memoryMetrics = payload.memoryMetrics {
            processMemoryMetrics(memoryMetrics)
        }
        
        // 3. Extract responsiveness metrics (scroll jank)
        if let responsivenessMetrics = payload.applicationResponsivenessMetrics {
            processResponsivenessMetrics(responsivenessMetrics)
        }
        
        // 4. Send entire payload to backend for detailed analysis
        sendFullPayloadToBackend(payload)
    }
    
    /// Process app launch metrics - INTERVIEW FOCUS AREA
    private func processLaunchMetrics(_ metrics: MXAppLaunchMetric) {
        /*
         UNDERSTANDING LAUNCH TYPES:
         
         ┌─────────────────────────────────────────────────────────────────┐
         │                    Cold Launch                                  │
         ├─────────────────────────────────────────────────────────────────┤
         │  App is NOT in memory. Must load everything from scratch.       │
         │  Happens when:                                                  │
         │  - Fresh app start after device reboot                          │
         │  - App was force-killed                                         │
         │  - iOS removed app from memory due to memory pressure           │
         │                                                                 │
         │  This is the SLOWEST launch type (1-3 seconds typical)          │
         └─────────────────────────────────────────────────────────────────┘
         
         ┌─────────────────────────────────────────────────────────────────┐
         │                    Warm Launch                                  │
         ├─────────────────────────────────────────────────────────────────┤
         │  App is partially in memory. Some resources cached.             │
         │  Happens when:                                                  │
         │  - App was recently suspended (not killed)                      │
         │  - User switches back to app quickly                            │
         │                                                                 │
         │  Faster than cold launch (0.5-1 second typical)                 │
         └─────────────────────────────────────────────────────────────────┘
         
         ┌─────────────────────────────────────────────────────────────────┐
         │                    Resume (Hot Launch)                          │
         ├─────────────────────────────────────────────────────────────────┤
         │  App is fully in memory, just suspended.                        │
         │  Happens when:                                                  │
         │  - App is in background, user taps to bring it back             │
         │                                                                 │
         │  Essentially instant (<100ms)                                   │
         └─────────────────────────────────────────────────────────────────┘
        */
        
        // histogrammedTimeToFirstDraw: Time from launch to first frame rendered
        let coldLaunchHistogram = metrics.histogrammedTimeToFirstDraw
        
        // Extract percentiles for cold launch
        // P50 = median (50% of launches faster than this)
        // P95 = 95th percentile (only 5% of launches slower)
        // P99 = 99th percentile (worst case performance)
        
        let coldLaunchP50 = coldLaunchHistogram.bucketEnumerator
            // Note: In real code, you'd calculate percentiles from buckets
        
        // Log the average (simple approach)
        let averageColdLaunch = coldLaunchHistogram.averageMeasurement
        let coldLaunchMs = averageColdLaunch.converted(to: .milliseconds).value
        
        analyticsService.log(
            event: "metric_cold_launch",
            params: [
                "average_ms": coldLaunchMs,
                "sample_count": coldLaunchHistogram.totalBucketCount
            ]
        )
        
        print("🚀 Cold Launch Average: \(coldLaunchMs)ms")
        
        // INTERVIEW TIP: Mention target thresholds
        // - Good: < 400ms
        // - Acceptable: 400-1000ms
        // - Bad: > 1000ms
        if coldLaunchMs > 1000 {
            analyticsService.log(event: "cold_launch_slow", params: ["ms": coldLaunchMs])
        }
    }
    
    /// Process memory metrics - INTERVIEW FOCUS AREA
    private func processMemoryMetrics(_ metrics: MXMemoryMetric) {
        /*
         MEMORY METRICS EXPLAINED:
         
         Peak Memory Usage:
         - The HIGHEST memory your app used during the reporting period
         - If this exceeds device limits, iOS KILLS your app (OOM)
         - This is what Meesho optimized (reduced by 50%)
         
         Average Suspended Memory:
         - Memory when app is in background
         - High value = iOS more likely to kill app to free memory
         - Keep this low for better app switching experience
        */
        
        let peakMemory = metrics.peakMemoryUsage
        let peakMemoryMB = peakMemory.averageMeasurement.converted(to: .megabytes).value
        
        analyticsService.log(
            event: "metric_peak_memory",
            params: ["mb": peakMemoryMB]
        )
        
        print("💾 Peak Memory: \(peakMemoryMB)MB")
        
        // Memory limits by device (approximate):
        // iPhone 15 Pro: ~1.5-2GB safe limit
        // iPhone 12: ~1-1.2GB safe limit
        // iPhone SE: ~600-800MB safe limit
        
        if peakMemoryMB > 1000 {
            analyticsService.log(event: "high_memory_usage", params: ["mb": peakMemoryMB])
        }
    }
    
    /// Process responsiveness (scroll performance)
    private func processResponsivenessMetrics(_ metrics: MXAppResponsivenessMetric) {
        /*
         SCROLL HITCH:
         A "hitch" is when a frame takes longer than expected to render.
         - 60 FPS = 16.67ms per frame
         - If a frame takes 33ms, that's 1 frame of hitch
         
         For e-commerce:
         - Product grid scrolling must be smooth
         - Users leave if scrolling is janky
        */
        
        let hitchTimeRatio = metrics.histogrammedApplicationHangTime
        let averageHitchMs = hitchTimeRatio.averageMeasurement.converted(to: .milliseconds).value
        
        analyticsService.log(
            event: "metric_hitch_rate",
            params: ["average_ms": averageHitchMs]
        )
    }
    
    /// Process crash and hang diagnostics
    private func processDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        // Process crash diagnostics
        if let crashes = payload.crashDiagnostics {
            for crash in crashes {
                processCrashDiagnostic(crash)
            }
        }
        
        // Process hang diagnostics (app frozen)
        if let hangs = payload.hangDiagnostics {
            for hang in hangs {
                processHangDiagnostic(hang)
            }
        }
        
        // Process CPU exceptions
        if let cpuExceptions = payload.cpuExceptionDiagnostics {
            for exception in cpuExceptions {
                processCPUException(exception)
            }
        }
    }
    
    private func processCrashDiagnostic(_ crash: MXCrashDiagnostic) {
        /*
         CRASH DIAGNOSTIC STRUCTURE:
         
         ┌─────────────────────────────────────────────────────────────────┐
         │  MXCrashDiagnostic                                              │
         ├─────────────────────────────────────────────────────────────────┤
         │  exceptionType: Mach exception type (EXC_BAD_ACCESS, etc.)      │
         │  signal: Unix signal (SIGSEGV, SIGABRT, etc.)                   │
         │  exceptionCode: Specific error code                             │
         │  terminationReason: Why iOS killed the app                      │
         │  callStackTree: Full call stack at crash time                   │
         └─────────────────────────────────────────────────────────────────┘
         
         COMMON CRASH TYPES:
         - EXC_BAD_ACCESS: Accessing invalid memory (null pointer, etc.)
         - EXC_CRASH + SIGABRT: Assertion failure or fatalError()
         - EXC_RESOURCE: Used too much CPU/memory
        */
        
        let crashInfo: [String: Any] = [
            "exception_type": crash.exceptionType?.intValue ?? -1,
            "signal": crash.signal?.intValue ?? -1,
            "exception_code": crash.exceptionCode?.intValue ?? -1,
            "termination_reason": crash.terminationReason ?? "unknown"
        ]
        
        // Get symbolicated call stack for debugging
        if let callStackData = crash.callStackTree.jsonRepresentation() {
            crashReporter.report(
                type: .crash,
                info: crashInfo,
                callStack: callStackData
            )
        }
        
        print("💥 Crash detected: \(crashInfo)")
    }
    
    private func processHangDiagnostic(_ hang: MXHangDiagnostic) {
        /*
         HANG = App frozen for > 250ms
         
         Common causes:
         - Heavy work on main thread
         - Synchronous network calls
         - Large image decoding on main thread
         - Database operations on main thread
        */
        
        let hangDuration = hang.hangDuration.converted(to: .seconds).value
        
        crashReporter.report(
            type: .hang,
            info: ["duration_seconds": hangDuration],
            callStack: hang.callStackTree.jsonRepresentation()
        )
        
        print("🧊 Hang detected: \(hangDuration)s")
    }
    
    private func processCPUException(_ exception: MXCPUExceptionDiagnostic) {
        let cpuTime = exception.totalCPUTime.converted(to: .seconds).value
        let sampledTime = exception.totalSampledTime.converted(to: .seconds).value
        
        crashReporter.report(
            type: .cpuException,
            info: [
                "cpu_time_seconds": cpuTime,
                "sampled_time_seconds": sampledTime
            ],
            callStack: exception.callStackTree.jsonRepresentation()
        )
    }
    
    private func sendFullPayloadToBackend(_ payload: MXMetricPayload) {
        // Get JSON representation for complete backend analysis
        guard let jsonData = payload.jsonRepresentation() else { return }
        
        // Send to your observability backend (e.g., Datadog, Firebase)
        analyticsService.sendRawMetrics(jsonData)
    }
}

// ============================================================================
// SECTION 4: PROTOCOL DEFINITIONS (For Testability)
// ============================================================================

/// Protocol for analytics service - allows mocking in tests
protocol AnalyticsServiceProtocol {
    func log(event: String, params: [String: Any])
    func sendRawMetrics(_ data: Data)
}

/// Protocol for crash reporting - allows mocking in tests
protocol CrashReporterProtocol {
    func report(type: CrashType, info: [String: Any], callStack: Data?)
}

enum CrashType {
    case crash
    case hang
    case cpuException
    case oom
}

// Concrete implementations
final class AnalyticsService: AnalyticsServiceProtocol {
    static let shared = AnalyticsService()
    
    func log(event: String, params: [String: Any]) {
        // In production: Send to Firebase, Amplitude, etc.
        print("📈 Analytics: \(event) - \(params)")
    }
    
    func sendRawMetrics(_ data: Data) {
        // POST to your metrics backend
        print("📤 Sending \(data.count) bytes of metrics to backend")
    }
}

final class CrashReporter: CrashReporterProtocol {
    static let shared = CrashReporter()
    
    func report(type: CrashType, info: [String: Any], callStack: Data?) {
        // In production: Send to Crashlytics, Sentry, etc.
        print("🚨 Crash Report [\(type)]: \(info)")
    }
}

// ============================================================================
// SECTION 5: INTEGRATION IN APP DELEGATE
// ============================================================================

/*
 HOW TO INTEGRATE IN YOUR APP:
 
 ```swift
 // AppDelegate.swift
 
 @main
 class AppDelegate: UIResponder, UIApplicationDelegate {
     
     func application(
         _ application: UIApplication,
         didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
     ) -> Bool {
         
         // Start MetricKit monitoring EARLY
         // This ensures we capture metrics from app start
         MetricKitManager.shared.startMonitoring()
         
         // ... other setup code
         
         return true
     }
 }
 ```
 
 INTERVIEW TIP: Mention that MetricKit should be started very early in the
 app lifecycle, but it doesn't block the main thread since iOS handles
 collection asynchronously.
*/

// ============================================================================
// SECTION 6: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "How does MetricKit help with app observability?"                      │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │  MetricKit provides system-level metrics that we can't easily collect       │
 │  ourselves. It gives us:                                                    │
 │                                                                             │
 │  1. ACCURATE LAUNCH TIME: iOS measures from process start to first frame,  │
 │     which is more accurate than anything we can measure in-app.             │
 │                                                                             │
 │  2. MEMORY FOOTPRINT: Real resident memory, not just our allocations.       │
 │     Includes framework memory, image caches, etc.                           │
 │                                                                             │
 │  3. CRASH DIAGNOSTICS: Symbolicated crash stacks delivered through the app, │
 │     allowing us to track crashes even for users who haven't opted into      │
 │     App Store crash reporting.                                              │
 │                                                                             │
 │  4. HANG DETECTION: Identifies when main thread is blocked > 250ms,         │
 │     crucial for e-commerce where scroll performance matters.                │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "What's the difference between MXMetricPayload and MXDiagnosticPayload?"│
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  MXMetricPayload:                                                           │
 │  - AGGREGATED performance data over 24 hours                                │
 │  - Contains histograms (distributions, not single values)                   │
 │  - Delivered once per day                                                   │
 │  - Examples: launch time, memory usage, battery drain, scroll hitch rate    │
 │                                                                             │
 │  MXDiagnosticPayload:                                                       │
 │  - INDIVIDUAL incident reports                                              │
 │  - Contains call stacks for debugging                                       │
 │  - Delivered closer to when the incident occurred                           │
 │  - Examples: crash reports, hang reports, CPU exceptions                    │
 │                                                                             │
 │  Use MetricPayload for TRENDS (is our launch time getting slower?)          │
 │  Use DiagnosticPayload for ROOT CAUSE (why did this specific crash happen?) │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "How would you design page-load tracking for 50+ screens?"             │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │  MetricKit only gives us overall app metrics. For per-screen tracking,      │
 │  we need custom instrumentation:                                            │
 │                                                                             │
 │  1. Define "page load complete" for each screen type:                       │
 │     - List screen: Data loaded + first visible cell rendered                │
 │     - Detail screen: Primary content + hero image loaded                    │
 │                                                                             │
 │  2. Create a lightweight PageLoadTracker:                                   │
 │     - startTracking(page: String) when viewDidLoad                          │
 │     - endTracking(page: String) when content is visible                     │
 │                                                                             │
 │  3. Batch and upload metrics asynchronously                                 │
 │                                                                             │
 │  4. For high-traffic screens, use sampling (track 10% of loads)             │
 │                                                                             │
 │  (See PageLoadTracker implementation in next file)                          │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 7: WHITEBOARD DIAGRAM TO PRACTICE
// ============================================================================

/*
 Draw this on the whiteboard when discussing MetricKit:
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         MetricKit Architecture                              │
 └─────────────────────────────────────────────────────────────────────────────┘
 
                    ┌─────────────┐
                    │  Your App   │
                    │   Running   │
                    └──────┬──────┘
                           │
          ┌────────────────┴────────────────┐
          │  iOS System (Silent Collection) │
          │                                 │
          │  ┌───────────┐ ┌───────────┐   │
          │  │  Launch   │ │  Memory   │   │
          │  │  Metrics  │ │  Metrics  │   │
          │  └───────────┘ └───────────┘   │
          │  ┌───────────┐ ┌───────────┐   │
          │  │   CPU     │ │  Battery  │   │
          │  │  Metrics  │ │  Metrics  │   │
          │  └───────────┘ └───────────┘   │
          └────────────────┬────────────────┘
                           │
                           │ Every 24 hours
                           ▼
          ┌────────────────────────────────┐
          │    MXMetricManagerSubscriber   │
          │    didReceive(_ payloads:)     │
          └────────────────┬───────────────┘
                           │
          ┌────────────────┴────────────────┐
          │                                 │
          ▼                                 ▼
 ┌─────────────────┐              ┌─────────────────┐
 │  Local Storage  │              │  Backend API    │
 │  (for offline)  │              │  (Analytics)    │
 └─────────────────┘              └─────────────────┘
 
*/

