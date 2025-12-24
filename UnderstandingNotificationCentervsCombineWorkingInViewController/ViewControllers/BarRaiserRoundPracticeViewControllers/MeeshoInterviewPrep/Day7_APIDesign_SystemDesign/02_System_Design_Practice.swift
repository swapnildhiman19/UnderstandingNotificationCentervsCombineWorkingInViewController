// ============================================================================
// MEESHO INTERVIEW PREP: System Design Practice Problems
// ============================================================================
// Day 7: API Design and Full System Design Practice
//
// Practice problems based on the interviewer's work at Meesho.
// Each problem includes: Requirements, Approach, and Solution outline.
// ============================================================================

import Foundation
import UIKit

// ============================================================================
// PROBLEM 1: PRODUCT LISTING PAGE (CORE E-COMMERCE)
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  PROBLEM: Design the product listing page for Meesho                        │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 REQUIREMENTS:
 1. Display products in a 2-column grid
 2. Infinite scroll with pagination
 3. Pull-to-refresh
 4. Filters (category, price range, rating)
 5. Image loading with placeholders
 6. Offline support (show cached products)
 7. Handle millions of products
 8. Fast and smooth scrolling
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  YOUR ANSWER STRUCTURE (30-40 minutes on whiteboard)                        │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 1. CLARIFY REQUIREMENTS (2-3 minutes)
    - How many products total? → Millions
    - Offline must work? → Yes, cache first page
    - Filter applied server-side? → Yes
 
 2. HIGH-LEVEL ARCHITECTURE (5 minutes)
 
    ┌─────────────────────────────────────────────────────────────────────────┐
    │                                                                         │
    │   ┌───────────────────────────────────────────────────────────────┐    │
    │   │              ProductListViewController                         │    │
    │   │   ┌─────────────────────────────────────────────────────────┐ │    │
    │   │   │  FilterBar (Categories, Sort, Price)                    │ │    │
    │   │   └─────────────────────────────────────────────────────────┘ │    │
    │   │   ┌─────────────────────────────────────────────────────────┐ │    │
    │   │   │  UICollectionView (2-column grid)                       │ │    │
    │   │   │  ┌─────────────┐  ┌─────────────┐                       │ │    │
    │   │   │  │ ProductCell │  │ ProductCell │                       │ │    │
    │   │   │  │ [Image]     │  │ [Image]     │                       │ │    │
    │   │   │  │ Title       │  │ Title       │                       │ │    │
    │   │   │  │ ₹Price      │  │ ₹Price      │                       │ │    │
    │   │   │  └─────────────┘  └─────────────┘                       │ │    │
    │   │   │  ┌─────────────┐  ┌─────────────┐                       │ │    │
    │   │   │  │ ProductCell │  │ ProductCell │                       │ │    │
    │   │   │  └─────────────┘  └─────────────┘                       │ │    │
    │   │   └─────────────────────────────────────────────────────────┘ │    │
    │   └───────────────────────────────────────────────────────────────┘    │
    │                              │                                          │
    │                              ▼                                          │
    │   ┌───────────────────────────────────────────────────────────────┐    │
    │   │              ProductListViewModel                              │    │
    │   │   - products: [Product]                                        │    │
    │   │   - isLoading: Bool                                            │    │
    │   │   - hasMore: Bool                                              │    │
    │   │   - loadNextPage()                                             │    │
    │   │   - refresh()                                                  │    │
    │   │   - applyFilter()                                              │    │
    │   └─────────────────────────────────────────────────────────────────┘   │
    │                              │                                          │
    │                              ▼                                          │
    │   ┌───────────────────────────────────────────────────────────────┐    │
    │   │              ProductRepository                                 │    │
    │   │   - fetchProducts(page, filters)                               │    │
    │   │   - uses NetworkClient + Cache                                 │    │
    │   └─────────────────────────────────────────────────────────────────┘   │
    │                                                                         │
    └─────────────────────────────────────────────────────────────────────────┘
 
 3. KEY COMPONENTS (10 minutes)
 
    a. COLLECTION VIEW:
       - UICollectionViewDiffableDataSource (smooth updates)
       - UICollectionViewFlowLayout (2 columns)
       - Cell prefetching for image loading
 
    b. PAGINATION:
       - Cursor-based (not offset)
       - Load more when scrolled to 80% of content
       - Show loading spinner at bottom
 
    c. IMAGE LOADING:
       - Two-tier cache (Memory + Disk)
       - Downsampling to cell size
       - Prefetching for upcoming cells
       - Cancel prefetch when scrolled past
 
    d. OFFLINE:
       - Cache first page of products
       - Show cache immediately, then fetch fresh
       - Indicate stale data
 
 4. API DESIGN (5 minutes)
 
    GET /products?cursor=xxx&limit=20&category=fashion&sort=price_asc
    
    Response:
    {
      "products": [
        {
          "id": "123",
          "name": "Cotton Kurti",
          "price": 299,
          "imageUrl": "https://cdn.meesho.com/...",
          "rating": 4.5
        }
      ],
      "nextCursor": "eyJpZCI6MTAwfQ",
      "hasMore": true
    }
 
 5. OPTIMIZATIONS (5 minutes)
 
    - Image downsampling (100x memory reduction)
    - Cell reuse properly configured
    - Skeleton loading while data loads
    - Throttle filter changes (don't fetch on every keystroke)
    - HTTP/3 for parallel image downloads
 
 6. EDGE CASES (3 minutes)
 
    - Empty state (no products)
    - Error state (network failure)
    - Filter returns no results
    - Slow network (timeout handling)
    - Rapid scrolling (cancel unnecessary requests)
*/

// ============================================================================
// PROBLEM 2: ORDER TRACKING SYSTEM
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  PROBLEM: Design an order tracking system with real-time updates            │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 REQUIREMENTS:
 1. Show order status (Placed → Shipped → Out for Delivery → Delivered)
 2. Real-time updates when status changes
 3. Push notifications for status updates
 4. Live Activity on lock screen (iOS 16+)
 5. Order history with pagination
 6. Offline viewing of orders
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  ARCHITECTURE                                                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
                          ┌──────────────────┐
                          │     Server       │
                          │   (Order State)  │
                          └────────┬─────────┘
                                   │
               ┌───────────────────┼───────────────────┐
               │                   │                   │
               ▼                   ▼                   ▼
        ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
        │ REST API    │    │   Push      │    │  WebSocket  │
        │ (History)   │    │  (APNS)     │    │ (Realtime)  │
        └──────┬──────┘    └──────┬──────┘    └──────┬──────┘
               │                  │                   │
               └──────────────────┴───────────────────┘
                                  │
                                  ▼
               ┌──────────────────────────────────────┐
               │          iOS App                     │
               │  ┌────────────────────────────────┐  │
               │  │  OrderTrackingManager          │  │
               │  │  - syncOrders()                │  │
               │  │  - handlePushNotification()    │  │
               │  │  - connectWebSocket()          │  │
               │  └────────────────────────────────┘  │
               │                 │                    │
               │      ┌──────────┴──────────┐        │
               │      ▼                     ▼        │
               │  ┌────────────┐     ┌────────────┐  │
               │  │   UI       │     │   Live     │  │
               │  │ (OrderVC)  │     │  Activity  │  │
               │  └────────────┘     └────────────┘  │
               └──────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  STATE MACHINE FOR ORDER STATUS                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
       ┌─────────┐      ┌─────────┐      ┌─────────────┐      ┌───────────┐
       │ Placed  │─────▶│ Shipped │─────▶│Out for      │─────▶│ Delivered │
       │         │      │         │      │Delivery     │      │           │
       └─────────┘      └─────────┘      └─────────────┘      └───────────┘
            │                                                        │
            │                     ┌─────────┐                        │
            └────────────────────▶│Cancelled│◀───────────────────────┘
                                  └─────────┘
 
 KEY DECISIONS:
 
 1. REAL-TIME UPDATES:
    - WebSocket for active screen
    - Fall back to polling if WebSocket fails
    - Push notifications for background updates
 
 2. LIVE ACTIVITY:
    - Start when order is "Out for Delivery"
    - Update via push token updates
    - End when delivered or cancelled
 
 3. OFFLINE:
    - Store orders in local database
    - Sync delta on app open
    - Conflict resolution: server wins
*/

// ============================================================================
// PROBLEM 3: APP LAUNCH OPTIMIZATION
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  PROBLEM: Optimize app launch time (target: < 400ms cold start)             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 CURRENT ISSUES:
 1. Cold launch takes 2-3 seconds
 2. Too much work on main thread
 3. All SDKs initialized at launch
 4. Large splash screen image
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  LAUNCH PHASES                                                              │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                                                                             │
 │  Pre-main (Before main() is called)                                         │
 │  ├── Load dylibs (frameworks)                                              │
 │  ├── Rebase/bind symbols                                                    │
 │  └── Run initializers (+load, __attribute__((constructor)))                │
 │                                                                             │
 │  Post-main (After main(), before UI)                                        │
 │  ├── UIApplicationMain                                                      │
 │  ├── AppDelegate init                                                       │
 │  ├── willFinishLaunchingWithOptions                                        │
 │  ├── didFinishLaunchingWithOptions                                         │
 │  └── applicationDidBecomeActive                                            │
 │                                                                             │
 │  First Frame                                                                │
 │  ├── Load first view controller                                            │
 │  ├── viewDidLoad, viewWillAppear                                           │
 │  └── First render (TTI - Time to Interactive)                              │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  OPTIMIZATION STRATEGIES                                                    │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 1. PRE-MAIN OPTIMIZATION:
    - Reduce number of frameworks (use static linking where possible)
    - Remove unused code (strip dead code)
    - Avoid +load methods (use +initialize instead)
 
 2. LAZY INITIALIZATION:
    - Don't init all SDKs at launch
    - Use dependency injection with lazy properties
    - Initialize on first use, not at app start
    
    ```swift
    // ❌ BAD: Initialize everything at launch
    func didFinishLaunching() {
        Firebase.configure()
        Analytics.start()
        CrashReporter.enable()
        ABTestingSDK.configure()
        // ... 10 more SDKs
    }
    
    // ✅ GOOD: Lazy initialization
    class SDKManager {
        static let shared = SDKManager()
        
        private lazy var analytics: AnalyticsSDK = {
            AnalyticsSDK.configure()
            return AnalyticsSDK.shared
        }()
        
        func trackEvent(_ event: String) {
            analytics.track(event) // Initialized on first use
        }
    }
    ```
 
 3. BACKGROUND INITIALIZATION:
    - Move heavy work off main thread
    - Initialize non-UI stuff in background
    
    ```swift
    func didFinishLaunching() {
        // Only essential on main thread
        setupWindow()
        showSplash()
        
        // Everything else in background
        DispatchQueue.global().async {
            self.setupNonEssentialSDKs()
            self.prefetchData()
        }
    }
    ```
 
 4. WARM DATA:
    - Cache home screen data
    - Show cached data immediately
    - Refresh in background
 
 5. ASSET OPTIMIZATION:
    - Compress splash image
    - Use asset catalogs
    - Lazy load images
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  MEASURING LAUNCH TIME                                                      │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 1. INSTRUMENTS:
    - App Launch template
    - Shows pre-main and post-main breakdown
 
 2. METRICKIT:
    - Real-world launch data
    - histogrammedTimeToFirstDraw
 
 3. CUSTOM LOGGING:
    ```swift
    // In main.swift
    let launchStart = CFAbsoluteTimeGetCurrent()
    
    // In first view controller
    override func viewDidAppear() {
        let launchTime = CFAbsoluteTimeGetCurrent() - AppDelegate.launchStart
        Analytics.log("launch_time", launchTime * 1000) // in ms
    }
    ```
*/

// ============================================================================
// PROBLEM 4: IMAGE LOADING SYSTEM
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  PROBLEM: Design image loading for e-commerce (millions of products)        │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 REQUIREMENTS:
 1. Load product images efficiently
 2. Support thousands of images per session
 3. Minimize memory usage
 4. Work on low-end devices
 5. Fast scrolling performance
 6. Offline caching
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  ARCHITECTURE                                                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
        loadImage(url, targetSize)
                   │
                   ▼
        ┌─────────────────────┐
        │   Memory Cache      │ ──── HIT ────▶ Return immediately
        │   (NSCache, 50MB)   │                (< 1ms)
        └──────────┬──────────┘
                   │ MISS
                   ▼
        ┌─────────────────────┐
        │    Disk Cache       │ ──── HIT ────▶ Decode + return
        │   (Files, 200MB)    │                (10-50ms)
        └──────────┬──────────┘
                   │ MISS
                   ▼
        ┌─────────────────────┐
        │    Network          │ ──────────────▶ Download + save
        │   (URLSession)      │                 (100-2000ms)
        └──────────┬──────────┘
                   │
                   ▼
        ┌─────────────────────┐
        │   DOWNSAMPLING      │ ──────────────▶ Decode to target size
        │   (CGImageSource)   │                 (Massive memory savings!)
        └─────────────────────┘
 
 KEY INSIGHT: DOWNSAMPLING
 
 A 4000x3000 image:
 - File size: 200 KB (compressed)
 - Memory (full): 4000 × 3000 × 4 = 48 MB!
 
 Displayed at 200x150:
 - Memory (downsampled): 200 × 150 × 4 = 120 KB
 - Reduction: 400x!
 
 CODE:
 ```swift
 func downsample(imageAt url: URL, to size: CGSize) -> UIImage? {
     let options = [kCGImageSourceShouldCache: false] as CFDictionary
     guard let source = CGImageSourceCreateWithURL(url as CFURL, options) else {
         return nil
     }
     
     let maxDimension = max(size.width, size.height) * UIScreen.main.scale
     let downsampleOptions = [
         kCGImageSourceCreateThumbnailFromImageAlways: true,
         kCGImageSourceShouldCacheImmediately: true,
         kCGImageSourceThumbnailMaxPixelSize: maxDimension
     ] as CFDictionary
     
     guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, downsampleOptions) else {
         return nil
     }
     
     return UIImage(cgImage: cgImage)
 }
 ```
*/

// ============================================================================
// SECTION: WHITEBOARD TIPS
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                     WHITEBOARD INTERVIEW TIPS                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 1. STRUCTURE YOUR ANSWER:
    - Requirements (2-3 min): Ask clarifying questions
    - High-level design (5 min): Draw boxes and arrows
    - Deep dive (10 min): Detail 2-3 key components
    - API design (5 min): Show request/response
    - Optimizations (5 min): Performance considerations
    - Trade-offs (3 min): What you'd do differently with more time
 
 2. DRAW CLEARLY:
    - Use boxes for components
    - Arrows for data flow
    - Label everything
    - Use different colors if available
 
 3. TALK WHILE DRAWING:
    - Explain your thought process
    - Justify decisions
    - Acknowledge trade-offs
 
 4. SHOW iOS EXPERTISE:
    - Mention specific APIs (UICollectionViewDiffableDataSource, CGImageSource)
    - Reference frameworks (MetricKit, WidgetKit)
    - Discuss memory management
    - Show awareness of main thread
 
 5. CONNECT TO INTERVIEWER'S WORK:
    - "Similar to your HTTP/3 adoption, we'd want..."
    - "Like your Safe Mode implementation, we'd need..."
    - Shows you researched and understood their work
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                     EXAMPLE OPENING STATEMENT                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 "Before I start designing, let me clarify a few requirements:
 
 1. What's the expected scale - how many products/users?
 2. Is offline support critical?
 3. Are there specific performance targets (load time, scroll fps)?
 4. Any existing systems I should integrate with?
 
 Okay, great. Let me start with the high-level architecture..."
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                     EXAMPLE CLOSING STATEMENT                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 "To summarize:
 
 - We have a MVVM architecture with Repository pattern
 - Two-tier caching for performance
 - Cursor-based pagination for scale
 - Image downsampling for memory efficiency
 
 If I had more time, I'd also consider:
 - A/B testing the image cache size
 - Adding prefetching based on scroll velocity
 - Implementing skeleton loading for perceived performance
 
 Do you have any questions about specific parts?"
*/

