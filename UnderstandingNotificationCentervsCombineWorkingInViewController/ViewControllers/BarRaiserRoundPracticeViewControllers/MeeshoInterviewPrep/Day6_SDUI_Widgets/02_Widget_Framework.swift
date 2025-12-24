/*
// ============================================================================
// MEESHO INTERVIEW PREP: Centralized Widget Framework
// ============================================================================
// Day 6: Server-Driven UI and Widget Framework
//
// The interviewer "Built a centralised Widget framework enabling seamless
// widget adoption across multiple product teams."
// ============================================================================

import Foundation
import WidgetKit

// ============================================================================
// SECTION 1: WHAT IS A WIDGET FRAMEWORK? (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of a Widget Framework like a "cookie cutter factory":
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         WITHOUT FRAMEWORK                                   │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Team A (Deals):          Team B (Orders):         Team C (Cart):
 ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
 │ Write timeline  │      │ Write timeline  │      │ Write timeline  │
 │ Write data layer│      │ Write data layer│      │ Write data layer│
 │ Write UI code   │      │ Write UI code   │      │ Write UI code   │
 │ Handle refresh  │      │ Handle refresh  │      │ Handle refresh  │
 │ Handle deeplinks│      │ Handle deeplinks│      │ Handle deeplinks│
 └─────────────────┘      └─────────────────┘      └─────────────────┘
        ↓                        ↓                        ↓
   Lots of duplicate code! Different patterns! Inconsistent UX!
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         WITH CENTRALIZED FRAMEWORK                          │
 └─────────────────────────────────────────────────────────────────────────────┘
 
                    ┌─────────────────────────────────┐
                    │      Widget Framework           │
                    │  ┌───────────────────────────┐  │
                    │  │ - Timeline Provider       │  │
                    │  │ - Data Sharing Layer      │  │
                    │  │ - Deeplink Handler        │  │
                    │  │ - Design System Components│  │
                    │  │ - Refresh Logic           │  │
                    │  └───────────────────────────┘  │
                    └─────────────────┬───────────────┘
                                      │
            ┌─────────────────────────┼─────────────────────────┐
            │                         │                         │
            ▼                         ▼                         ▼
 Team A (Deals):          Team B (Orders):         Team C (Cart):
 ┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
 │ Just define:    │      │ Just define:    │      │ Just define:    │
 │ - Widget data   │      │ - Widget data   │      │ - Widget data   │
 │ - Widget UI     │      │ - Widget UI     │      │ - Widget UI     │
 └─────────────────┘      └─────────────────┘      └─────────────────┘
 
 Benefits:
 ✓ Consistent patterns
 ✓ Less code to write
 ✓ Shared infrastructure
 ✓ Easier maintenance
*/

// ============================================================================
// SECTION 2: APP GROUPS FOR DATA SHARING
// ============================================================================
/*
 UNDERSTANDING APP GROUPS:
 
 Your main app and widget extension are SEPARATE processes.
 They cannot directly share data. Solution: App Groups!
 
 ┌────────────────────────────────────────────────────────────────────────────┐
 │                                                                            │
 │   Main App                           Widget Extension                      │
 │   ┌──────────────────┐               ┌──────────────────┐                 │
 │   │ Cannot access    │               │ Cannot access    │                 │
 │   │ widget's sandbox │               │ app's sandbox    │                 │
 │   └────────┬─────────┘               └────────┬─────────┘                 │
 │            │                                   │                          │
 │            └──────────────┬────────────────────┘                          │
 │                           │                                               │
 │                           ▼                                               │
 │            ┌──────────────────────────────┐                               │
 │            │        APP GROUP             │                               │
 │            │   group.com.meesho.shared    │                               │
 │            │                              │                               │
 │            │  ┌────────────────────────┐  │                               │
 │            │  │   Shared Container     │  │                               │
 │            │  │   - UserDefaults       │  │                               │
 │            │  │   - Files              │  │                               │
 │            │  │   - CoreData           │  │                               │
 │            │  └────────────────────────┘  │                               │
 │            │                              │                               │
 │            └──────────────────────────────┘                               │
 │                                                                            │
 └────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 3: SHARED DATA LAYER
// ============================================================================

/// Shared data storage accessible from both main app and widget extension
final class WidgetDataStore {
    
    // MARK: - Singleton
    static let shared = WidgetDataStore()
    
    // MARK: - App Group Identifier
    private let appGroupID = "group.com.meesho.shared"
    
    // MARK: - Storage
    private lazy var sharedDefaults: UserDefaults? = {
        return UserDefaults(suiteName: appGroupID)
    }()
    
    private lazy var sharedContainerURL: URL? = {
        return FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }()
    
    // MARK: - Keys
    private enum Keys {
        static let cartCount = "widget_cart_count"
        static let activeOrders = "widget_active_orders"
        static let flashDeals = "widget_flash_deals"
        static let lastUpdate = "widget_last_update"
    }
    
    // MARK: - Cart Data
    
    var cartCount: Int {
        get { sharedDefaults?.integer(forKey: Keys.cartCount) ?? 0 }
        set {
            sharedDefaults?.set(newValue, forKey: Keys.cartCount)
            notifyWidgetToRefresh()
        }
    }
    
    // MARK: - Orders Data
    
    func saveActiveOrders(_ orders: [WidgetOrder]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(orders) {
            sharedDefaults?.set(data, forKey: Keys.activeOrders)
            notifyWidgetToRefresh()
        }
    }
    
    func getActiveOrders() -> [WidgetOrder] {
        guard let data = sharedDefaults?.data(forKey: Keys.activeOrders),
              let orders = try? JSONDecoder().decode([WidgetOrder].self, from: data) else {
            return []
        }
        return orders
    }
    
    // MARK: - Flash Deals Data
    
    func saveFlashDeals(_ deals: [WidgetDeal]) {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(deals) {
            sharedDefaults?.set(data, forKey: Keys.flashDeals)
            notifyWidgetToRefresh()
        }
    }
    
    func getFlashDeals() -> [WidgetDeal] {
        guard let data = sharedDefaults?.data(forKey: Keys.flashDeals),
              let deals = try? JSONDecoder().decode([WidgetDeal].self, from: data) else {
            return []
        }
        return deals
    }
    
    // MARK: - Widget Refresh
    
    private func notifyWidgetToRefresh() {
        // Tell iOS to refresh widgets
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Call when user opens app to sync fresh data
    func syncFromMainApp() {
        sharedDefaults?.set(Date(), forKey: Keys.lastUpdate)
    }
}

// MARK: - Data Models

struct WidgetOrder: Codable {
    let orderId: String
    let productName: String
    let status: String
    let imageUrl: String
    let estimatedDelivery: Date?
}

struct WidgetDeal: Codable {
    let dealId: String
    let title: String
    let discount: Int
    let imageUrl: String
    let expiresAt: Date
}

// ============================================================================
// SECTION 4: BASE TIMELINE PROVIDER
// ============================================================================

/// Base protocol for widget data providers
protocol WidgetDataProvider {
    associatedtype EntryType: TimelineEntry
    
    /// Fetch current data for widget
    func fetchCurrentEntry() async -> EntryType
    
    /// Calculate next refresh time
    func nextRefreshDate() -> Date
}

/// Generic timeline provider that teams can use
struct GenericTimelineProvider<Provider: WidgetDataProvider>: TimelineProvider {
    
    typealias Entry = Provider.EntryType
    
    let provider: Provider
    
    func placeholder(in context: Context) -> Entry {
        // Return placeholder entry
        // This is shown while widget loads
        fatalError("Subclasses must implement placeholder")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        // For widget gallery preview
        Task {
            let entry = await provider.fetchCurrentEntry()
            completion(entry)
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        Task {
            let entry = await provider.fetchCurrentEntry()
            let nextUpdate = provider.nextRefreshDate()
            
            let timeline = Timeline(
                entries: [entry],
                policy: .after(nextUpdate)
            )
            completion(timeline)
        }
    }
}

// ============================================================================
// SECTION 5: DEEPLINK HANDLER
// ============================================================================

/// Centralized deeplink handling for widgets
final class WidgetDeeplinkHandler {
    
    /// Widget deeplink scheme
    static let scheme = "meeshowidget"
    
    /// Deeplink types
    enum DeeplinkType: String {
        case orderDetails = "order"
        case dealDetails = "deal"
        case cart = "cart"
        case home = "home"
    }
    
    /// Generate deeplink URL for widget actions
    static func generateURL(type: DeeplinkType, params: [String: String] = [:]) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = type.rawValue
        components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        return components.url!
    }
    
    /// Handle incoming deeplink from widget
    static func handle(url: URL) -> Bool {
        guard url.scheme == scheme,
              let host = url.host,
              let type = DeeplinkType(rawValue: host) else {
            return false
        }
        
        let params = extractParams(from: url)
        
        switch type {
        case .orderDetails:
            navigateToOrderDetails(orderId: params["orderId"])
        case .dealDetails:
            navigateToDealDetails(dealId: params["dealId"])
        case .cart:
            navigateToCart()
        case .home:
            navigateToHome()
        }
        
        return true
    }
    
    private static func extractParams(from url: URL) -> [String: String] {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return [:]
        }
        
        var params: [String: String] = [:]
        for item in queryItems {
            params[item.name] = item.value
        }
        return params
    }
    
    private static func navigateToOrderDetails(orderId: String?) {
        // Navigate to order details screen
        print("Navigate to order: \(orderId ?? "unknown")")
    }
    
    private static func navigateToDealDetails(dealId: String?) {
        // Navigate to deal details
        print("Navigate to deal: \(dealId ?? "unknown")")
    }
    
    private static func navigateToCart() {
        // Navigate to cart
        print("Navigate to cart")
    }
    
    private static func navigateToHome() {
        // Navigate to home
        print("Navigate to home")
    }
}

// ============================================================================
// SECTION 6: EXAMPLE WIDGET IMPLEMENTATION
// ============================================================================

/*
 EXAMPLE: Orders Widget using the framework
 
 ```swift
 // OrdersWidgetProvider.swift
 
 struct OrdersEntry: TimelineEntry {
     let date: Date
     let orders: [WidgetOrder]
 }
 
 class OrdersDataProvider: WidgetDataProvider {
     typealias EntryType = OrdersEntry
     
     func fetchCurrentEntry() async -> OrdersEntry {
         let orders = WidgetDataStore.shared.getActiveOrders()
         return OrdersEntry(date: Date(), orders: orders)
     }
     
     func nextRefreshDate() -> Date {
         // Refresh every 15 minutes
         return Date().addingTimeInterval(15 * 60)
     }
 }
 
 // In Widget definition:
 struct OrdersWidget: Widget {
     let kind = "OrdersWidget"
     
     var body: some WidgetConfiguration {
         StaticConfiguration(
             kind: kind,
             provider: GenericTimelineProvider(provider: OrdersDataProvider())
         ) { entry in
             OrdersWidgetView(entry: entry)
         }
         .configurationDisplayName("My Orders")
         .description("Track your active orders")
     }
 }
 ```
*/

// ============================================================================
// SECTION 7: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "Design a widget framework for multiple product teams"                 │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  COMPONENTS:                                                                │
 │                                                                             │
 │  1. SHARED DATA LAYER:                                                      │
 │     - App Groups for data sharing between app and widget                    │
 │     - Centralized WidgetDataStore                                           │
 │     - Codable models for type-safe data transfer                            │
 │                                                                             │
 │  2. BASE TIMELINE PROVIDER:                                                 │
 │     - Generic provider teams can extend                                     │
 │     - Handles refresh logic                                                 │
 │     - Standardizes snapshot/timeline behavior                               │
 │                                                                             │
 │  3. DEEPLINK HANDLER:                                                       │
 │     - Unified URL scheme                                                    │
 │     - Centralized routing logic                                             │
 │     - Consistent action handling                                            │
 │                                                                             │
 │  4. DESIGN SYSTEM COMPONENTS:                                               │
 │     - Reusable UI components matching app design                            │
 │     - Consistent look and feel                                              │
 │                                                                             │
 │  TEAM WORKFLOW:                                                             │
 │  1. Team defines data model conforming to Codable                           │
 │  2. Team creates TimelineEntry with their data                              │
 │  3. Team implements WidgetDataProvider protocol                             │
 │  4. Team creates widget view using design system components                 │
 │  5. Framework handles all infrastructure                                    │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "How do you share data between app and widget?"                        │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  PROBLEM:                                                                   │
 │  - Main app and widget are SEPARATE processes                               │
 │  - Cannot share memory directly                                             │
 │  - Each has its own sandbox                                                 │
 │                                                                             │
 │  SOLUTION: APP GROUPS                                                       │
 │                                                                             │
 │  1. Configure App Group capability in Xcode:                                │
 │     - Main app target: Add "group.com.meesho.shared"                        │
 │     - Widget target: Add same group ID                                      │
 │                                                                             │
 │  2. Access shared storage:                                                  │
 │     - UserDefaults(suiteName: "group.com.meesho.shared")                    │
 │     - FileManager containerURL(forSecurityApplicationGroupIdentifier:)      │
 │                                                                             │
 │  3. Sync pattern:                                                           │
 │     - Main app writes data to shared container                              │
 │     - Call WidgetCenter.shared.reloadAllTimelines()                         │
 │     - Widget reads from shared container in timeline provider               │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/
*/
