/*
// ============================================================================
// MEESHO INTERVIEW PREP: Server-Driven UI (SDUI) Architecture
// ============================================================================
// Day 6: Server-Driven UI and Widget Framework
//
// The interviewer "Architected a scalable Server-Driven UI platform using SwiftUI,
// unlocking rapid UI experimentation and modular delivery."
// NOTE: Implementing with UIKit as per your request.
// ============================================================================

import Foundation
import UIKit

// ============================================================================
// SECTION 1: WHAT IS SERVER-DRIVEN UI? (Layman's Explanation)
// ============================================================================
/*
 🎯 SIMPLE ANALOGY:
 
 Think of SDUI like a TV that shows whatever the broadcast station sends:
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                    TRADITIONAL APP vs SERVER-DRIVEN UI                      │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 TRADITIONAL (Hardcoded UI):
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                                                                             │
 │  SERVER                          APP                                        │
 │  ┌─────────┐                    ┌─────────────────────────────┐            │
 │  │  Data   │ ─── JSON ───────▶ │  Fixed UI Layout            │            │
 │  │ {name,  │    (only data)    │  ┌───────────────────────┐  │            │
 │  │  price} │                   │  │ [Image] Title    $$$  │  │            │
 │  └─────────┘                   │  └───────────────────────┘  │            │
 │                                 │  (Layout is HARDCODED)     │            │
 │                                 └─────────────────────────────┘            │
 │                                                                             │
 │  Want to change layout? → New app release (1-2 weeks App Store review!)    │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 SERVER-DRIVEN UI:
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                                                                             │
 │  SERVER                          APP                                        │
 │  ┌─────────┐                    ┌─────────────────────────────┐            │
 │  │ UI +    │ ─── JSON ───────▶ │  Dynamic Renderer           │            │
 │  │ Data    │  (layout + data)  │  ┌───────────────────────┐  │            │
 │  │ {type:  │                   │  │ Whatever server says! │  │            │
 │  │ banner, │                   │  └───────────────────────┘  │            │
 │  │ img...} │                   │  (Layout from SERVER)       │            │
 │  └─────────┘                   └─────────────────────────────┘            │
 │                                                                             │
 │  Want to change layout? → Update server! (Instant, no app release!)        │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 WHY MEESHO USES SDUI:
 1. Rapid experimentation (A/B test different layouts instantly)
 2. No App Store review wait (update UI in minutes, not weeks)
 3. Personalization (show different UI to different users)
 4. Sales & promotions (change home page for flash sales instantly)
 5. Fix bugs without app update (change problematic component from server)
*/

// ============================================================================
// SECTION 2: SDUI ARCHITECTURE
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         SDUI ARCHITECTURE                                   │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌───────────────┐         ┌───────────────┐         ┌───────────────┐
 │    Server     │         │   JSON Spec   │         │   iOS App     │
 │   (Backend)   │ ─────▶  │   Response    │ ─────▶  │   (Client)    │
 └───────────────┘         └───────────────┘         └───────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────────────────────────┐
                    │                                               │
                    │  {                                            │
                    │    "components": [                            │
                    │      {                                        │
                    │        "type": "banner",                      │
                    │        "imageUrl": "...",                     │
                    │        "title": "Flash Sale!"                 │
                    │      },                                       │
                    │      {                                        │
                    │        "type": "productGrid",                 │
                    │        "columns": 2,                          │
                    │        "products": [...]                      │
                    │      }                                        │
                    │    ]                                          │
                    │  }                                            │
                    │                                               │
                    └───────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────────────────────────┐
                    │              Component Registry               │
                    │  ┌─────────────────────────────────────────┐  │
                    │  │ "banner" → BannerComponent              │  │
                    │  │ "productGrid" → ProductGridComponent    │  │
                    │  │ "carousel" → CarouselComponent          │  │
                    │  │ "text" → TextComponent                  │  │
                    │  └─────────────────────────────────────────┘  │
                    └───────────────────────────────────────────────┘
                                  │
                                  ▼
                    ┌───────────────────────────────────────────────┐
                    │              Rendered UI                      │
                    │  ┌─────────────────────────────────────────┐  │
                    │  │  ┌───────────────────────────────────┐  │  │
                    │  │  │         Flash Sale Banner         │  │  │
                    │  │  └───────────────────────────────────┘  │  │
                    │  │  ┌─────────┐ ┌─────────┐               │  │
                    │  │  │ Product │ │ Product │               │  │
                    │  │  └─────────┘ └─────────┘               │  │
                    │  └─────────────────────────────────────────┘  │
                    └───────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 3: COMPONENT PROTOCOL & REGISTRY
// ============================================================================

/// Protocol that all SDUI components must conform to
protocol SDUIComponent {
    /// Unique type identifier matching server's "type" field
    static var typeName: String { get }
    
    /// Initialize from JSON data
    init?(json: [String: Any])
    
    /// Create the UIView for this component
    func createView() -> UIView
}

/// Registry that maps type names to component factories
final class SDUIComponentRegistry {
    
    // MARK: - Singleton
    static let shared = SDUIComponentRegistry()
    
    // MARK: - Types
    
    /// Factory closure that creates a component from JSON
    typealias ComponentFactory = ([String: Any]) -> SDUIComponent?
    
    // MARK: - Storage
    
    private var factories: [String: ComponentFactory] = [:]
    
    // MARK: - Initialization
    
    private init() {
        registerBuiltInComponents()
    }
    
    // MARK: - Registration
    
    /// Register a component type
    func register<T: SDUIComponent>(_ componentType: T.Type) {
        factories[T.typeName] = { json in
            return T(json: json)
        }
    }
    
    /// Create component from JSON
    func createComponent(from json: [String: Any]) -> SDUIComponent? {
        guard let type = json["type"] as? String else {
            print("⚠️ SDUI: Missing 'type' field in component JSON")
            return nil
        }
        
        guard let factory = factories[type] else {
            print("⚠️ SDUI: Unknown component type '\(type)'")
            return nil
        }
        
        return factory(json)
    }
    
    // MARK: - Built-in Components
    
    private func registerBuiltInComponents() {
        register(BannerComponent.self)
        register(ProductGridComponent.self)
        register(TextComponent.self)
        register(SpacerComponent.self)
        register(CarouselComponent.self)
    }
}

// ============================================================================
// SECTION 4: BUILT-IN COMPONENTS
// ============================================================================

// MARK: - Banner Component

/// Full-width image banner with optional title and action
struct BannerComponent: SDUIComponent {
    
    static var typeName: String { "banner" }
    
    let imageUrl: URL
    let title: String?
    let action: SDUIAction?
    
    init?(json: [String: Any]) {
        guard let urlString = json["imageUrl"] as? String,
              let url = URL(string: urlString) else {
            return nil
        }
        
        self.imageUrl = url
        self.title = json["title"] as? String
        self.action = SDUIAction(json: json["action"] as? [String: Any] ?? [:])
    }
    
    func createView() -> UIView {
        let bannerView = BannerView()
        bannerView.configure(imageUrl: imageUrl, title: title, action: action)
        return bannerView
    }
}

// MARK: - Product Grid Component

/// Grid of products with configurable columns
struct ProductGridComponent: SDUIComponent {
    
    static var typeName: String { "productGrid" }
    
    let columns: Int
    let products: [[String: Any]]
    let title: String?
    
    init?(json: [String: Any]) {
        self.columns = json["columns"] as? Int ?? 2
        self.products = json["products"] as? [[String: Any]] ?? []
        self.title = json["title"] as? String
    }
    
    func createView() -> UIView {
        let gridView = ProductGridView()
        gridView.configure(columns: columns, products: products, title: title)
        return gridView
    }
}

// MARK: - Text Component

/// Simple text display
struct TextComponent: SDUIComponent {
    
    static var typeName: String { "text" }
    
    let text: String
    let style: TextStyle
    
    enum TextStyle: String {
        case title, subtitle, body, caption
    }
    
    init?(json: [String: Any]) {
        guard let text = json["text"] as? String else {
            return nil
        }
        
        self.text = text
        self.style = TextStyle(rawValue: json["style"] as? String ?? "body") ?? .body
    }
    
    func createView() -> UIView {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0
        
        switch style {
        case .title:
            label.font = .boldSystemFont(ofSize: 24)
        case .subtitle:
            label.font = .systemFont(ofSize: 18)
        case .body:
            label.font = .systemFont(ofSize: 16)
        case .caption:
            label.font = .systemFont(ofSize: 12)
            label.textColor = .gray
        }
        
        return label
    }
}

// MARK: - Spacer Component

/// Adds vertical spacing
struct SpacerComponent: SDUIComponent {
    
    static var typeName: String { "spacer" }
    
    let height: CGFloat
    
    init?(json: [String: Any]) {
        self.height = CGFloat(json["height"] as? Double ?? 16.0)
    }
    
    func createView() -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }
}

// MARK: - Carousel Component

/// Horizontal scrolling carousel
struct CarouselComponent: SDUIComponent {
    
    static var typeName: String { "carousel" }
    
    let items: [[String: Any]]
    let autoScroll: Bool
    
    init?(json: [String: Any]) {
        self.items = json["items"] as? [[String: Any]] ?? []
        self.autoScroll = json["autoScroll"] as? Bool ?? false
    }
    
    func createView() -> UIView {
        let carouselView = CarouselView()
        carouselView.configure(items: items, autoScroll: autoScroll)
        return carouselView
    }
}

// ============================================================================
// SECTION 5: ACTION SYSTEM
// ============================================================================

/// Represents a user interaction action from SDUI
struct SDUIAction {
    
    enum ActionType: String {
        case deeplink
        case navigate
        case apiCall = "api_call"
        case openUrl = "open_url"
        case dismiss
    }
    
    let type: ActionType
    let value: String
    let params: [String: Any]
    
    init?(json: [String: Any]) {
        guard let typeString = json["type"] as? String,
              let type = ActionType(rawValue: typeString) else {
            return nil
        }
        
        self.type = type
        self.value = json["value"] as? String ?? ""
        self.params = json["params"] as? [String: Any] ?? [:]
    }
}

/// Handles SDUI actions
final class SDUIActionHandler {
    
    static let shared = SDUIActionHandler()
    
    func handle(_ action: SDUIAction) {
        switch action.type {
        case .deeplink:
            handleDeeplink(action.value)
            
        case .navigate:
            handleNavigation(action.value, params: action.params)
            
        case .apiCall:
            handleAPICall(action.value, params: action.params)
            
        case .openUrl:
            handleOpenURL(action.value)
            
        case .dismiss:
            handleDismiss()
        }
    }
    
    private func handleDeeplink(_ url: String) {
        guard let url = URL(string: url) else { return }
        // Use your app's deeplink router
        print("🔗 Handling deeplink: \(url)")
    }
    
    private func handleNavigation(_ screen: String, params: [String: Any]) {
        // Navigate to screen
        print("🧭 Navigating to: \(screen) with params: \(params)")
    }
    
    private func handleAPICall(_ endpoint: String, params: [String: Any]) {
        // Make API call
        print("📡 API call to: \(endpoint)")
    }
    
    private func handleOpenURL(_ url: String) {
        guard let url = URL(string: url) else { return }
        UIApplication.shared.open(url)
    }
    
    private func handleDismiss() {
        // Dismiss current screen
        print("👋 Dismissing")
    }
}

// ============================================================================
// SECTION 6: PAGE RENDERER
// ============================================================================

/// Renders an entire SDUI page
final class SDUIPageRenderer {
    
    private let registry: SDUIComponentRegistry
    
    init(registry: SDUIComponentRegistry = .shared) {
        self.registry = registry
    }
    
    /// Render page from JSON response
    func render(pageJSON: [String: Any]) -> UIView {
        let containerView = UIStackView()
        containerView.axis = .vertical
        containerView.spacing = 0
        
        guard let components = pageJSON["components"] as? [[String: Any]] else {
            return createErrorView(message: "Invalid page structure")
        }
        
        for componentJSON in components {
            if let component = registry.createComponent(from: componentJSON) {
                let view = component.createView()
                containerView.addArrangedSubview(view)
            } else {
                // Unknown component - render fallback
                let fallbackView = createFallbackView(for: componentJSON)
                containerView.addArrangedSubview(fallbackView)
            }
        }
        
        return containerView
    }
    
    private func createErrorView(message: String) -> UIView {
        let label = UILabel()
        label.text = message
        label.textColor = .red
        label.textAlignment = .center
        return label
    }
    
    private func createFallbackView(for json: [String: Any]) -> UIView {
        // Return empty view for unknown components
        // This allows forward compatibility
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 0).isActive = true
        return view
    }
}

// ============================================================================
// SECTION 7: VIEW CONTROLLER INTEGRATION
// ============================================================================

/// View controller that renders SDUI content
class SDUIViewController: UIViewController {
    
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let renderer = SDUIPageRenderer()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    private let pageEndpoint: String
    
    init(pageEndpoint: String) {
        self.pageEndpoint = pageEndpoint
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadPage()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        view.addSubview(loadingIndicator)
        
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        loadingIndicator.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
            
            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        loadingIndicator.startAnimating()
    }
    
    private func loadPage() {
        // Fetch page configuration from server
        SDUIAPIService.shared.fetchPage(endpoint: pageEndpoint) { [weak self] result in
            DispatchQueue.main.async {
                self?.loadingIndicator.stopAnimating()
                
                switch result {
                case .success(let pageJSON):
                    self?.renderPage(pageJSON)
                case .failure(let error):
                    self?.showError(error)
                }
            }
        }
    }
    
    private func renderPage(_ pageJSON: [String: Any]) {
        let renderedView = renderer.render(pageJSON: pageJSON)
        
        contentView.addSubview(renderedView)
        renderedView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            renderedView.topAnchor.constraint(equalTo: contentView.topAnchor),
            renderedView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            renderedView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            renderedView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])
    }
    
    private func showError(_ error: Error) {
        let alert = UIAlertController(
            title: "Error",
            message: error.localizedDescription,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Retry", style: .default) { [weak self] _ in
            self?.loadPage()
        })
        present(alert, animated: true)
    }
}

// ============================================================================
// SECTION 8: PLACEHOLDER VIEW IMPLEMENTATIONS
// ============================================================================

class BannerView: UIView {
    func configure(imageUrl: URL, title: String?, action: SDUIAction?) {
        // Implementation
    }
}

class ProductGridView: UIView {
    func configure(columns: Int, products: [[String: Any]], title: String?) {
        // Implementation
    }
}

class CarouselView: UIView {
    func configure(items: [[String: Any]], autoScroll: Bool) {
        // Implementation
    }
}

enum SDUIAPIService {
    static let shared = SDUIAPIService.self
    
    static func fetchPage(endpoint: String, completion: @escaping (Result<[String: Any], Error>) -> Void) {
        // Implementation
    }
}

// ============================================================================
// SECTION 9: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "Design a Server-Driven UI system"                                     │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  CORE COMPONENTS:                                                           │
 │                                                                             │
 │  1. COMPONENT PROTOCOL:                                                     │
 │     - typeName: String (matches server's "type")                            │
 │     - init(json:): Parse from server JSON                                   │
 │     - createView(): Return UIView                                           │
 │                                                                             │
 │  2. COMPONENT REGISTRY:                                                     │
 │     - Maps type names to component classes                                  │
 │     - Factory pattern to create components                                  │
 │     - Allows registering custom components                                  │
 │                                                                             │
 │  3. PAGE RENDERER:                                                          │
 │     - Parses page JSON                                                      │
 │     - Creates components from registry                                      │
 │     - Handles unknown components gracefully                                 │
 │                                                                             │
 │  4. ACTION SYSTEM:                                                          │
 │     - Parse action from component JSON                                      │
 │     - Handle deeplinks, navigation, API calls                               │
 │                                                                             │
 │  VERSIONING:                                                                │
 │  - Include SDK version in requests                                          │
 │  - Server returns components compatible with that version                   │
 │  - Unknown components → fallback/empty view                                 │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "How do you handle backward compatibility in SDUI?"                    │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  1. VERSION NEGOTIATION:                                                    │
 │     - App sends: GET /page?sdui_version=2.1                                │
 │     - Server returns components for that version                            │
 │                                                                             │
 │  2. GRACEFUL FALLBACK:                                                      │
 │     - Unknown component type → render empty/fallback view                   │
 │     - Missing optional fields → use defaults                                │
 │     - Invalid data → skip component, continue rendering                     │
 │                                                                             │
 │  3. FEATURE FLAGS:                                                          │
 │     - Server checks if app version supports feature                         │
 │     - Only sends components app can render                                  │
 │                                                                             │
 │  4. A/B TESTING:                                                            │
 │     - Server can send different layouts to different users                  │
 │     - Test new components with small % before rollout                       │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/
*/
