// ============================================================================
// MEESHO INTERVIEW PREP: Page Load Performance Tracking
// ============================================================================
// Day 1-2: App Observability and Performance Monitoring
//
// MetricKit gives us overall app metrics, but for per-screen performance,
// we need custom instrumentation. This is what the interviewer implemented
// for "page-load performance tracking" at Meesho.
// ============================================================================

import Foundation
import UIKit

// ============================================================================
// SECTION 1: WHAT IS PAGE LOAD TRACKING? (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of page load tracking like a stopwatch for each screen:
 
 ┌─────────────────────────────────────────────────────────────────┐
 │                         User Journey                            │
 ├─────────────────────────────────────────────────────────────────┤
 │                                                                 │
 │  User taps "View Product"                                       │
 │       │                                                         │
 │       ├──▶ ⏱️ START TIMER                                       │
 │       │                                                         │
 │       │    [Loading Spinner shows]                              │
 │       │    [API call in progress]                               │
 │       │    [Images downloading]                                 │
 │       │                                                         │
 │       ├──▶ ⏱️ STOP TIMER (Product visible to user)              │
 │       │                                                         │
 │       │    Elapsed: 1,247ms                                     │
 │       │                                                         │
 │       └──▶ 📊 Send to Analytics                                 │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
 
 WHY THIS MATTERS:
 - Slow pages = users leave = lost revenue
 - Amazon found: 100ms slower = 1% less revenue
 - For e-commerce, Product Detail Page (PDP) is CRITICAL
 - Need to track EVERY screen to find slow ones
 
 WHAT TO MEASURE:
 
 ┌─────────────────────────────────────────────────────────────────┐
 │  TTI (Time To Interactive)                                      │
 │  ─────────────────────────────────────────────────────────────  │
 │                                                                 │
 │  Navigation ──▶ viewDidLoad ──▶ API Response ──▶ UI Rendered   │
 │       │                │               │               │        │
 │       │◀── T1 ────────▶│               │               │        │
 │       │                │◀──── T2 ─────▶│               │        │
 │       │                │               │◀───── T3 ────▶│        │
 │       │                                                │        │
 │       │◀──────────── TOTAL TTI ───────────────────────▶│        │
 │                                                                 │
 │  T1 = Navigation + View Loading                                 │
 │  T2 = Network Request                                           │
 │  T3 = Data Processing + Rendering                               │
 │                                                                 │
 └─────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 2: PAGE LOAD TRACKER - CORE IMPLEMENTATION
// ============================================================================

/// Centralized page load performance tracker.
/// Tracks time from navigation start to content visible for every screen.
///
/// INTERVIEW TIP: Key design decisions:
/// 1. Thread-safe using a serial queue
/// 2. Automatically handles multiple concurrent page loads
/// 3. Supports nested tracking (e.g., track screen + track image loading)
final class PageLoadTracker {
    
    // MARK: - Singleton
    static let shared = PageLoadTracker()
    
    // MARK: - Types
    
    /// Represents a single page load measurement in progress
    private struct ActiveMeasurement {
        let pageName: String
        let startTime: CFAbsoluteTime
        let metadata: [String: Any]
        var milestones: [Milestone]
        
        struct Milestone {
            let name: String
            let timestamp: CFAbsoluteTime
        }
    }
    
    /// The result of a completed page load measurement
    struct PageLoadResult {
        let pageName: String
        let totalDurationMs: Double
        let milestones: [String: Double] // milestone name -> time since start
        let metadata: [String: Any]
        let timestamp: Date
    }
    
    // MARK: - State
    
    /// Active measurements keyed by unique ID
    private var activeMeasurements: [String: ActiveMeasurement] = [:]
    
    /// Serial queue for thread-safe access
    private let queue = DispatchQueue(label: "com.meesho.pageloadtracker")
    
    // MARK: - Dependencies
    private let analyticsService: AnalyticsServiceProtocol
    
    // MARK: - Configuration
    
    /// Threshold above which a page load is considered "slow"
    private let slowThresholdMs: Double = 2000
    
    /// Sampling rate (1.0 = 100%, 0.1 = 10%)
    /// Use sampling for high-traffic pages to reduce backend load
    private var samplingRate: Double = 1.0
    
    // MARK: - Initialization
    
    private init() {
        self.analyticsService = AnalyticsService.shared
    }
    
    // MARK: - Public API
    
    /// Start tracking a page load.
    /// Returns a unique tracking ID to use for milestones and end tracking.
    ///
    /// - Parameters:
    ///   - pageName: Identifier for the page (e.g., "product_detail", "cart")
    ///   - metadata: Additional context (e.g., ["product_id": "123"])
    /// - Returns: Unique tracking ID
    @discardableResult
    func startTracking(
        pageName: String,
        metadata: [String: Any] = [:]
    ) -> String {
        let trackingId = UUID().uuidString
        let startTime = CFAbsoluteTimeGetCurrent()
        
        queue.sync {
            activeMeasurements[trackingId] = ActiveMeasurement(
                pageName: pageName,
                startTime: startTime,
                metadata: metadata,
                milestones: []
            )
        }
        
        print("⏱️ Started tracking: \(pageName) [\(trackingId)]")
        return trackingId
    }
    
    /// Record a milestone during page load (e.g., "api_complete", "images_loaded")
    ///
    /// - Parameters:
    ///   - name: Milestone identifier
    ///   - trackingId: The ID returned from startTracking
    func recordMilestone(_ name: String, trackingId: String) {
        let timestamp = CFAbsoluteTimeGetCurrent()
        
        queue.sync {
            guard var measurement = activeMeasurements[trackingId] else {
                print("⚠️ No active measurement for tracking ID: \(trackingId)")
                return
            }
            
            let milestone = ActiveMeasurement.Milestone(
                name: name,
                timestamp: timestamp
            )
            measurement.milestones.append(milestone)
            activeMeasurements[trackingId] = measurement
            
            let elapsedMs = (timestamp - measurement.startTime) * 1000
            print("📍 Milestone '\(name)' at \(elapsedMs)ms")
        }
    }
    
    /// End tracking and report the result.
    ///
    /// - Parameter trackingId: The ID returned from startTracking
    /// - Returns: The complete measurement result, or nil if tracking ID not found
    @discardableResult
    func endTracking(trackingId: String) -> PageLoadResult? {
        let endTime = CFAbsoluteTimeGetCurrent()
        
        var result: PageLoadResult?
        
        queue.sync {
            guard let measurement = activeMeasurements.removeValue(forKey: trackingId) else {
                print("⚠️ No active measurement for tracking ID: \(trackingId)")
                return
            }
            
            let totalDurationMs = (endTime - measurement.startTime) * 1000
            
            // Calculate milestone times relative to start
            var milestoneTimings: [String: Double] = [:]
            for milestone in measurement.milestones {
                let milestoneMs = (milestone.timestamp - measurement.startTime) * 1000
                milestoneTimings[milestone.name] = milestoneMs
            }
            
            result = PageLoadResult(
                pageName: measurement.pageName,
                totalDurationMs: totalDurationMs,
                milestones: milestoneTimings,
                metadata: measurement.metadata,
                timestamp: Date()
            )
        }
        
        if let result = result {
            reportResult(result)
        }
        
        return result
    }
    
    /// Cancel tracking without reporting (e.g., user navigated away)
    func cancelTracking(trackingId: String) {
        queue.sync {
            activeMeasurements.removeValue(forKey: trackingId)
        }
        print("❌ Cancelled tracking: \(trackingId)")
    }
    
    // MARK: - Reporting
    
    private func reportResult(_ result: PageLoadResult) {
        // Apply sampling for high-traffic pages
        if Double.random(in: 0...1) > samplingRate {
            return
        }
        
        print("✅ Page Load Complete: \(result.pageName) - \(result.totalDurationMs)ms")
        
        // Build event params
        var params: [String: Any] = [
            "page": result.pageName,
            "duration_ms": result.totalDurationMs,
            "timestamp": result.timestamp.timeIntervalSince1970
        ]
        
        // Add milestone timings
        for (milestone, timing) in result.milestones {
            params["milestone_\(milestone)_ms"] = timing
        }
        
        // Add metadata
        for (key, value) in result.metadata {
            params["meta_\(key)"] = value
        }
        
        // Determine if this is a slow load
        let isSlow = result.totalDurationMs > slowThresholdMs
        params["is_slow"] = isSlow
        
        // Report to analytics
        analyticsService.log(event: "page_load", params: params)
        
        // Additional reporting for slow loads
        if isSlow {
            analyticsService.log(event: "slow_page_load", params: params)
            print("🐢 SLOW PAGE LOAD: \(result.pageName) took \(result.totalDurationMs)ms")
        }
    }
}

// ============================================================================
// SECTION 3: EASY INTEGRATION HELPERS
// ============================================================================

/// Protocol that view controllers can conform to for easy page load tracking
protocol PageLoadTrackable: AnyObject {
    var pageLoadTrackingId: String? { get set }
    var pageLoadPageName: String { get }
    var pageLoadMetadata: [String: Any] { get }
}

extension PageLoadTrackable {
    var pageLoadMetadata: [String: Any] { return [:] }
}

// MARK: - UIViewController Extension

extension UIViewController {
    
    // Associated object key for storing tracking ID
    private static var trackingIdKey: UInt8 = 0
    
    /// The current page load tracking ID (if tracking is active)
    var pageLoadTrackingId: String? {
        get {
            return objc_getAssociatedObject(self, &Self.trackingIdKey) as? String
        }
        set {
            objc_setAssociatedObject(
                self,
                &Self.trackingIdKey,
                newValue,
                .OBJC_ASSOCIATION_RETAIN_NONATOMIC
            )
        }
    }
    
    /// Start tracking page load. Call in viewDidLoad or viewWillAppear.
    func startPageLoadTracking(pageName: String, metadata: [String: Any] = [:]) {
        pageLoadTrackingId = PageLoadTracker.shared.startTracking(
            pageName: pageName,
            metadata: metadata
        )
    }
    
    /// Record a milestone. Call when significant events occur.
    func recordPageLoadMilestone(_ name: String) {
        guard let trackingId = pageLoadTrackingId else { return }
        PageLoadTracker.shared.recordMilestone(name, trackingId: trackingId)
    }
    
    /// End tracking. Call when content is fully visible and interactive.
    func endPageLoadTracking() {
        guard let trackingId = pageLoadTrackingId else { return }
        PageLoadTracker.shared.endTracking(trackingId: trackingId)
        pageLoadTrackingId = nil
    }
    
    /// Cancel tracking. Call if user leaves before content loaded.
    func cancelPageLoadTracking() {
        guard let trackingId = pageLoadTrackingId else { return }
        PageLoadTracker.shared.cancelTracking(trackingId: trackingId)
        pageLoadTrackingId = nil
    }
}

// ============================================================================
// SECTION 4: COMPLETE USAGE EXAMPLE
// ============================================================================

/// Example: Product Detail Page with full page load tracking
class ProductDetailViewController: UIViewController {
    
    // MARK: - Properties
    private let productId: String
    private var product: Product?
    
    // UI Elements
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    // MARK: - Initialization
    
    init(productId: String) {
        self.productId = productId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ⏱️ START TRACKING - Include product ID in metadata
        startPageLoadTracking(
            pageName: "product_detail",
            metadata: ["product_id": productId]
        )
        
        setupUI()
        loadProductData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // ❌ CANCEL if user leaves before loading completes
        if product == nil {
            cancelPageLoadTracking()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        loadingIndicator.center = view.center
        
        // Setup other UI elements...
    }
    
    // MARK: - Data Loading
    
    private func loadProductData() {
        // Simulate API call
        ProductAPI.fetchProduct(id: productId) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let product):
                // 📍 MILESTONE: API data received
                self.recordPageLoadMilestone("api_complete")
                
                self.product = product
                self.populateUI(with: product)
                self.loadProductImage(url: product.imageUrl)
                
            case .failure(let error):
                self.showError(error)
                self.cancelPageLoadTracking()
            }
        }
    }
    
    private func populateUI(with product: Product) {
        DispatchQueue.main.async {
            self.titleLabel.text = product.name
            self.priceLabel.text = "₹\(product.price)"
            self.descriptionLabel.text = product.description
            
            // 📍 MILESTONE: Basic content rendered
            self.recordPageLoadMilestone("content_rendered")
        }
    }
    
    private func loadProductImage(url: URL) {
        ImageLoader.shared.loadImage(from: url) { [weak self] image in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.imageView.image = image
                self.loadingIndicator.stopAnimating()
                
                // 📍 MILESTONE: Image loaded
                self.recordPageLoadMilestone("image_loaded")
                
                // ✅ END TRACKING - Page is now fully visible and interactive
                self.endPageLoadTracking()
            }
        }
    }
    
    private func showError(_ error: Error) {
        // Show error UI
    }
}

// MARK: - Supporting Types for Example

struct Product {
    let id: String
    let name: String
    let price: Double
    let description: String
    let imageUrl: URL
}

enum ProductAPI {
    static func fetchProduct(id: String, completion: @escaping (Result<Product, Error>) -> Void) {
        // Simulated API call
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let product = Product(
                id: id,
                name: "Sample Product",
                price: 499,
                description: "A great product",
                imageUrl: URL(string: "https://example.com/image.jpg")!
            )
            completion(.success(product))
        }
    }
}

enum ImageLoader {
    static let shared = ImageLoader.self
    
    static func loadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Simulated image loading
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            completion(UIImage(systemName: "photo"))
        }
    }
}

// ============================================================================
// SECTION 5: ADVANCED - AUTOMATIC TRACKING WITH SWIZZLING
// ============================================================================

/// Automatic page load tracking using method swizzling.
/// This tracks ALL view controllers without manual instrumentation.
///
/// INTERVIEW TIP: Mention this as an advanced technique, but note
/// that explicit tracking is often preferred for accuracy.
final class AutomaticPageLoadTracker {
    
    static func enable() {
        swizzleViewDidAppear()
        swizzleViewDidDisappear()
    }
    
    private static func swizzleViewDidAppear() {
        let originalSelector = #selector(UIViewController.viewDidAppear(_:))
        let swizzledSelector = #selector(UIViewController.plt_viewDidAppear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
    
    private static func swizzleViewDidDisappear() {
        let originalSelector = #selector(UIViewController.viewDidDisappear(_:))
        let swizzledSelector = #selector(UIViewController.plt_viewDidDisappear(_:))
        
        guard let originalMethod = class_getInstanceMethod(UIViewController.self, originalSelector),
              let swizzledMethod = class_getInstanceMethod(UIViewController.self, swizzledSelector) else {
            return
        }
        
        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}

extension UIViewController {
    
    @objc func plt_viewDidAppear(_ animated: Bool) {
        // Call original implementation (now swapped)
        plt_viewDidAppear(animated)
        
        // Skip system view controllers
        guard !isSystemViewController else { return }
        
        // End tracking when view appears (simple heuristic)
        if pageLoadTrackingId != nil {
            endPageLoadTracking()
        }
    }
    
    @objc func plt_viewDidDisappear(_ animated: Bool) {
        plt_viewDidDisappear(animated)
        
        // Cancel any active tracking
        cancelPageLoadTracking()
    }
    
    private var isSystemViewController: Bool {
        let className = String(describing: type(of: self))
        return className.hasPrefix("UI") || className.hasPrefix("_")
    }
}

// ============================================================================
// SECTION 6: BATCHING FOR HIGH SCALE
// ============================================================================

/// Batches page load events before sending to reduce network calls.
/// Use this for apps with millions of users.
final class BatchedPageLoadReporter {
    
    static let shared = BatchedPageLoadReporter()
    
    private var pendingEvents: [PageLoadTracker.PageLoadResult] = []
    private let queue = DispatchQueue(label: "com.meesho.batchedreporter")
    private var flushTimer: Timer?
    
    // Configuration
    private let maxBatchSize = 20
    private let flushInterval: TimeInterval = 30
    
    private init() {
        startFlushTimer()
    }
    
    func add(_ result: PageLoadTracker.PageLoadResult) {
        queue.async {
            self.pendingEvents.append(result)
            
            if self.pendingEvents.count >= self.maxBatchSize {
                self.flush()
            }
        }
    }
    
    private func startFlushTimer() {
        flushTimer = Timer.scheduledTimer(
            withTimeInterval: flushInterval,
            repeats: true
        ) { [weak self] _ in
            self?.queue.async {
                self?.flush()
            }
        }
    }
    
    private func flush() {
        guard !pendingEvents.isEmpty else { return }
        
        let eventsToSend = pendingEvents
        pendingEvents.removeAll()
        
        // Send batch to backend
        sendBatch(eventsToSend)
    }
    
    private func sendBatch(_ events: [PageLoadTracker.PageLoadResult]) {
        // Convert to JSON and POST to analytics endpoint
        print("📤 Sending batch of \(events.count) page load events")
    }
}

// ============================================================================
// SECTION 7: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "Design page-load tracking for an app with 50+ screens"                │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  ARCHITECTURE:                                                              │
 │  1. Centralized PageLoadTracker (singleton)                                 │
 │     - Thread-safe with serial queue                                         │
 │     - Supports concurrent tracking (multiple screens)                       │
 │     - Unique ID per tracking session                                        │
 │                                                                             │
 │  2. Define "page load complete" per screen type:                            │
 │     - List screen: First 10 items visible                                   │
 │     - Detail screen: Hero content + image loaded                            │
 │     - Search: Results rendered                                              │
 │                                                                             │
 │  3. Instrumentation approach:                                               │
 │     - Explicit: Developers call start/end in view controllers               │
 │     - Automatic: Swizzle viewDidLoad/viewDidAppear                          │
 │     - Hybrid: Auto-start, explicit end (when content ready)                 │
 │                                                                             │
 │  4. Milestones for granularity:                                             │
 │     - "api_start", "api_complete"                                           │
 │     - "parse_complete"                                                      │
 │     - "first_render"                                                        │
 │     - "images_loaded"                                                       │
 │                                                                             │
 │  5. Scale considerations:                                                   │
 │     - Batch events before sending                                           │
 │     - Sample high-traffic pages (10% of events)                             │
 │     - Async reporting (don't block main thread)                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "How do you define 'page load complete' for an e-commerce product list?"│
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  For a product list (like Meesho's home feed), "complete" means:            │
 │                                                                             │
 │  1. ABOVE-THE-FOLD CONTENT VISIBLE:                                         │
 │     - First ~10 products rendered (what user sees without scrolling)        │
 │     - Product images for those items loaded                                 │
 │     - Prices and titles visible                                             │
 │                                                                             │
 │  2. USER CAN INTERACT:                                                      │
 │     - Scrolling works                                                       │
 │     - Tap on product works                                                  │
 │                                                                             │
 │  IMPLEMENTATION:                                                            │
 │  ```swift                                                                   │
 │  func collectionView(_ cv: UICollectionView,                                │
 │                      willDisplay cell: UICollectionViewCell,                │
 │                      forItemAt indexPath: IndexPath) {                      │
 │      // End tracking when 10th cell is displayed                            │
 │      if indexPath.item == 9 && pageLoadTrackingId != nil {                 │
 │          endPageLoadTracking()                                              │
 │      }                                                                      │
 │  }                                                                          │
 │  ```                                                                        │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "How do you handle tracking when user navigates away before load?"     │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  1. CANCEL, DON'T END:                                                      │
 │     - If user leaves before content loads, call cancelTracking()            │
 │     - Don't report partial loads as complete (skews metrics)                │
 │                                                                             │
 │  2. TRACK ABANDONMENT SEPARATELY:                                           │
 │     - Log "page_abandoned" event with how long they waited                  │
 │     - Helps identify pages that are TOO SLOW (users give up)                │
 │                                                                             │
 │  3. IMPLEMENTATION:                                                         │
 │     ```swift                                                                │
 │     override func viewWillDisappear(_ animated: Bool) {                     │
 │         super.viewWillDisappear(animated)                                   │
 │         if isContentLoaded {                                                │
 │             // Normal exit after viewing                                    │
 │         } else {                                                            │
 │             // User left before content loaded                              │
 │             trackAbandonedPageLoad()                                        │
 │             cancelPageLoadTracking()                                        │
 │         }                                                                   │
 │     }                                                                       │
 │     ```                                                                     │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 8: WHITEBOARD DIAGRAM
// ============================================================================

/*
 PAGE LOAD TRACKING FLOW (Draw this):
 
 ┌──────────────────────────────────────────────────────────────────────────────┐
 │                                                                              │
 │   User Action                    App                           Analytics     │
 │   ──────────                    ───                           ─────────      │
 │       │                          │                               │           │
 │       │  Tap "View Product"      │                               │           │
 │       │─────────────────────────▶│                               │           │
 │       │                          │                               │           │
 │       │                          │ ⏱️ startTracking()            │           │
 │       │                          │──────────────────────────┐    │           │
 │       │                          │                          │    │           │
 │       │                          │    viewDidLoad()         │    │           │
 │       │                          │    [show loading]        │    │           │
 │       │                          │                          │    │           │
 │       │                          │    fetchProduct()        │    │           │
 │       │                          │    ─────────────▶        │    │           │
 │       │                          │                 (API)    │    │           │
 │       │                          │    ◀─────────────        │    │           │
 │       │                          │                          │    │           │
 │       │                          │ 📍 milestone("api_done") │    │           │
 │       │                          │──────────────────────────┤    │           │
 │       │                          │                          │    │           │
 │       │                          │    loadImage()           │    │           │
 │       │                          │    ──────────▶           │    │           │
 │       │                          │              (CDN)       │    │           │
 │       │                          │    ◀──────────           │    │           │
 │       │                          │                          │    │           │
 │       │                          │ ✅ endTracking()         │    │           │
 │       │                          │──────────────────────────┘    │           │
 │       │                          │                               │           │
 │       │   [Content Visible]      │                               │           │
 │       │◀─────────────────────────│                               │           │
 │       │                          │                               │           │
 │       │                          │         {"page_load":         │           │
 │       │                          │          "product_detail",    │           │
 │       │                          │          "duration_ms": 847,  │           │
 │       │                          │          "api_done_ms": 412}  │           │
 │       │                          │──────────────────────────────▶│           │
 │       │                          │                               │           │
 └──────────────────────────────────────────────────────────────────────────────┘
*/

