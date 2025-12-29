//
//  SDUIImplementation.swift
//  Authentication
//
//  Created by Swapnil Dhiman on 29/12/25.
//  Copyright © 2025 Walmart. All rights reserved.
//

/*
 let mockSDUIResponse: [String: Any] = [
 "components": [
 // 1. Banner Component with Action
 [
 "type": "banner",
 "imageUrl": "https://via.placeholder.com/400x200/FF6B6B/FFFFFF?text=🔥+FLASH+SALE+50%25+OFF",
 "title": "Flash Sale - Tap to Shop!",
 "action": [
 "type": "navigate",
 "value": "product_list",
 "params": ["category": "sale", "discount": "50"]
 ]
 ],

 // 2. Spacer
 [
 "type": "spacer",
 "height": 16
 ],

 // 3. Text Component
 [
 "type": "text",
 "text": "Today's Best Deals",
 "style": "title"
 ],

 // 4. Another Spacer
 [
 "type": "spacer",
 "height": 8
 ],

 // 5. Product Grid
 [
 "type": "productGrid",
 "title": "Trending Products",
 "columns": 2,
 "products": [
 ["name": "T-Shirt", "price": "₹299", "image": "👕"],
 ["name": "Jeans", "price": "₹599", "image": "👖"],
 ["name": "Shoes", "price": "₹899", "image": "👟"],
 ["name": "Watch", "price": "₹1299", "image": "⌚"]
 ]
 ],

 // 6. Text with action
 [
 "type": "text",
 "text": "Free shipping on orders above ₹199!",
 "style": "caption"
 ]
 ]
 ]

 */

import Foundation
import UIKit

protocol SDUIComponent {
    static var typeName: String {get}
    init?(json:[String:Any])
    func createView() -> UIView
}

final class SDUIComponentRegistry {
    static let shared = SDUIComponentRegistry()

    typealias ComponentFactory = ([String:Any]) -> SDUIComponent?

    private var factories : [String: ComponentFactory] = [:]

    private init(){
        registerBuiltInComponents()
    }

    func register<T:SDUIComponent>(_ componentType: T.Type) {
        factories[T.typeName] = {
            json in
            return T(json: json)
        }
    }

    private func registerBuiltInComponents() {
        register(BannerComponent.self)
        register(ProductGridComponent.self)
        register(TextComponent.self)
        register(SpacerComponent.self)
        register(CarouselComponent.self)
    }

    func createComponent(from json: [String:Any]) -> SDUIComponent? {
        guard let type = json["type"] as? String else {
            print("SDUI: Missing 'type' field in component JSON")
            return nil
        }

        guard let factory = factories[type] else {
            print("SDUI: Unknown component type: \(type)")
            return nil
        }

        return factory(json)
    }
}

struct BannerComponent: SDUIComponent {
    static var typeName : String {"banner"}

    let imageUrl : URL
    let title : String?
    let action: SDUIAction?

    init?(json: [String:Any]) {
        guard let urlString = json["imageUrl"] as? String,
              let url = URL(string: urlString) else {
            return nil
        }

        // Assign required property first
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

final class BannerView : UIView {
    func configure(imageUrl : URL, title: String?, action: SDUIAction?) {

    }
}

struct ProductGridComponent: SDUIComponent {
    static var typeName: String {"productGrid"}

    let columns : Int
    let products : [[String:Any]]
    let title : String?

    init?(json: [String : Any]) {
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

final class ProductGridView: UIView {
    func configure(columns: Int, products: [[String: Any]], title : String?){

    }
}

struct TextComponent: SDUIComponent {
    static var typeName: String {"text"}

    let text : String
    let style : TextStyle

    enum TextStyle : String {
        case title, subtitle, body, caption
    }

    init?(json: [String : Any]) {
        guard let text = json["text"] as? String else {
            return nil
        }
        self.text = text
        self.style = TextStyle(
            rawValue: json["style"] as? String ?? "body"
        ) ?? .body
    }

    func createView() -> UIView {
        let label = UILabel()
        label.text = text
        label.numberOfLines = 0

        switch style {
        case .title :
            label.font = .boldSystemFont(ofSize: 24)
        case .subtitle :
            label.font = .systemFont(ofSize: 18)
        case .body:
            label.font = .systemFont(ofSize: 14)
        case .caption:
            label.font = .systemFont(ofSize: 12)
            label.textColor = .gray
        }

        return label
    }
}

struct SpacerComponent: SDUIComponent {
    static var typeName: String {"spacer"}

    let height : CGFloat

    init?(json: [String : Any]) {
        self.height = CGFloat(json["height"] as? Double ?? 16.0)
    }

    func createView() -> UIView {
        let spacerView = UIView()
        spacerView.heightAnchor.constraint(equalToConstant: height).isActive = true
        return spacerView
    }
}

struct CarouselComponent : SDUIComponent {
    static var typeName: String {"carousel"}

    let items : [[String: Any]]
    let autoScroll : Bool

    init?(json: [String : Any]) {
        self.items = json["items"] as? [[String:Any]]  ?? []
        self.autoScroll = json["autoScroll"] as? Bool ?? false
    }

    func createView() -> UIView {
        let carouselView = CarouselView()
        carouselView.configure(items: items, autoScroll: autoScroll)
        return carouselView
    }
}

final class CarouselView : UIView {
    func configure(items:[[String:Any]], autoScroll: Bool){

    }
}


struct SDUIAction {
    enum ActionType: String {
        case navigate
        case openUrl = "open_url"
        case apiCall = "api_call"
        case dismiss
        case deeplink
    }

    let type : ActionType
    let value : String
    let params : [String:Any]

    init?(json: [String:Any]){
        guard let typeString = json["type"] as? String,
              let type = ActionType(rawValue: typeString) else {
            return nil
        }
        self.type = type
        self.value = json["value"] as? String ?? ""
        self.params = json["params"] as? [String:Any] ?? [:]
    }
}

final class SDUIActionHandler {
    static let shared = SDUIActionHandler()

    func handle(_ action: SDUIAction){
        switch action.type {
        case .deeplink:
            handleDeepLink(action.value)
        case .apiCall:
            handleAPICall(action.value, params: action.params)
        case .openUrl:
            handleOpenURL(action.value)
        case .dismiss:
            handleDismiss()
        case .navigate:
            handleNavigation(action.value, params: action.params)
        }
    }

    func handleDeepLink(_ url : String) {
        guard let url = URL(string: url) else { return }
        print("Handling deeplink: \(url)")
    }

    func handleNavigation(_ screen: String, params: [String:Any]) {
        print("Navigating to: \(screen) with params: \(params)")
    }

    func handleOpenURL(_ url : String){
        guard let url = URL(string: url) else {
            return
        }
        UIApplication.shared.open(url)
    }

    func handleAPICall(_ endPoint: String, params: [String:Any]){
        print("API call to :\(endPoint)")
    }

    func handleDismiss(){
        print("Dismissing")
    }

}

final class SDUIPageRenderer {
    private let registry : SDUIComponentRegistry

    init(registry: SDUIComponentRegistry = .shared){
        self.registry = registry
    }

    func render(pageJSON: [String:Any]) -> UIView {
        let containerView = UIStackView()
        containerView.axis = .vertical
        containerView.spacing = 0

        guard let components = pageJSON["components"] as? [[String:Any]] else {
            return createErrorView(message:"Invalid Page Structure")
        }

        for componentJSON in components {
            if let component = registry.createComponent(from: componentJSON) {
                let view = component.createView()
                containerView.addArrangedSubview(view)
            } else {
                let fallBackView = createFallbackView(for: componentJSON)
                containerView.addArrangedSubview(fallBackView)
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

    private func createFallbackView(for json: [String:Any]) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 0).isActive = true
        return view
    }
}

class SDUIViewController : UIViewController {
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    private let renderer = SDUIPageRenderer()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)

    private let pageEndPoint : String

    init(pageEndPoint: String){
        self.pageEndPoint = pageEndPoint
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder:NSCoder){
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad(){
        super.viewDidLoad()
        setupUI()
        loadPage()
    }

    private func setupUI(){
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

    private func loadPage(){
        /*
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
         */
    }

    private func renderPage(_ pageJSON: [String:Any]) {
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

    private func showError(_ error : Error) {
        let alert = UIAlertController(
            title: "Error", message: error.localizedDescription, preferredStyle: .alert
        )
        alert
            .addAction(
                UIAlertAction(title: "Retry", style: .default, handler: { [weak self] _ in
                    self?.loadPage()
                })
            )
        present(alert,animated: true)
    }
}

enum SDUIAPIService {
    static let shared = SDUIAPIService.self

    static func fetchPage(endpoint: String, completion: @escaping (Result<[String:Any], Error>) -> Void){

    }
}



let mockSDUIResponse: [String: Any] = [
    "components": [
        // 1. Banner Component with Action
        [
            "type": "banner",
            "imageUrl": "https://via.placeholder.com/400x200/FF6B6B/FFFFFF?text=🔥+FLASH+SALE+50%25+OFF",
            "title": "Flash Sale - Tap to Shop!",
            "action": [
                "type": "navigate",
                "value": "product_list",
                "params": ["category": "sale", "discount": "50"]
            ]
        ],

        // 2. Spacer
        [
            "type": "spacer",
            "height": 16
        ],

        // 3. Text Component
        [
            "type": "text",
            "text": "Today's Best Deals",
            "style": "title"
        ],

        // 4. Another Spacer
        [
            "type": "spacer",
            "height": 8
        ],

        // 5. Product Grid
        [
            "type": "productGrid",
            "title": "Trending Products",
            "columns": 2,
            "products": [
                ["name": "T-Shirt", "price": "₹299", "image": "👕"],
                ["name": "Jeans", "price": "₹599", "image": "👖"],
                ["name": "Shoes", "price": "₹899", "image": "👟"],
                ["name": "Watch", "price": "₹1299", "image": "⌚"]
            ]
        ],

        // 6. Text with action
        [
            "type": "text",
            "text": "Free shipping on orders above ₹199!",
            "style": "caption"
        ]
    ]
]

class BannerViewComplete: UIView {
    private let imageView : UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = UIColor(red: 1.0, green: 0.6, blue: 0.42, alpha: 1.0)
        return iv
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font  = .boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private let overlayView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        return view
    }()

    private var action: SDUIAction?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI(){
        addSubview(imageView)
        addSubview(overlayView)
        addSubview(titleLabel)

        imageView.translatesAutoresizingMaskIntoConstraints = false
        overlayView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Image fills the banner
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: trailingAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 150),

            // Overlay on top of image
            overlayView.topAnchor.constraint(equalTo: imageView.topAnchor),
            overlayView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            overlayView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            overlayView.bottomAnchor.constraint(equalTo: imageView.bottomAnchor),

            // Title centered
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
            titleLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16)
        ])

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    func configure(imageURL: URL, title: String?, action: SDUIAction?){
        self.action = action
        titleLabel.text = title ?? "FLASH SALE"

        URLSession.shared.dataTask(with: imageURL) { [weak self] data,_,_ in
            if let data = data, let image = UIImage(data: data) {
                DispatchQueue.main.async {
                    self?.imageView.image = image
                }
            }
        }.resume()
    }

    @objc private func handleTap(){
        UIView.animate(withDuration: 0.7) {
            self.alpha = 0.7
        } completion: { _ in
            UIView.animate(withDuration: 0.1) {
                self.alpha = 1.0
            }
        }

        if let action = action {
            print("ACTION TRIGGERED")
            print("   Type: \(action.type)")
            print("   Value: \(action.value)")
            print("   Params: \(action.params)")
            SDUIActionHandler.shared.handle(action)
        }
    }
}

class ProductGridViewComplete: UIView {

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 18)
        label.textColor = .label
        return label
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 12
        sv.distribution = .fillEqually
        return sv
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        addSubview(titleLabel)
        addSubview(stackView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),

            stackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }

    func configure(columns: Int, products: [[String: Any]], title: String?) {
        titleLabel.text = title

        // Clear existing
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        // Create rows
        var currentRow: UIStackView?
        for (index, product) in products.enumerated() {
            if index % columns == 0 {
                currentRow = UIStackView()
                currentRow?.axis = .horizontal
                currentRow?.spacing = 12
                currentRow?.distribution = .fillEqually
                stackView.addArrangedSubview(currentRow!)
            }

            let productView = createProductCard(product)
            currentRow?.addArrangedSubview(productView)
        }
    }

    private func createProductCard(_ product: [String: Any]) -> UIView {
        let card = UIView()
        card.backgroundColor = .systemGray6
        card.layer.cornerRadius = 12

        let emoji = UILabel()
        emoji.text = product["image"] as? String ?? "📦"
        emoji.font = .systemFont(ofSize: 40)
        emoji.textAlignment = .center

        let name = UILabel()
        name.text = product["name"] as? String ?? "Product"
        name.font = .systemFont(ofSize: 14)
        name.textAlignment = .center

        let price = UILabel()
        price.text = product["price"] as? String ?? "₹0"
        price.font = .boldSystemFont(ofSize: 16)
        price.textColor = .systemGreen
        price.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [emoji, name, price])
        stack.axis = .vertical
        stack.spacing = 4
        stack.alignment = .center

        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 8),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -8),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -12),
            card.heightAnchor.constraint(equalToConstant: 120)
        ])

        return card
    }
}


struct DemoBannerComponent: SDUIComponent {

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
        let bannerView = BannerViewComplete()
        bannerView.configure(imageURL: imageUrl, title: title, action: action)
        return bannerView
    }
}

struct DemoProductGridComponent: SDUIComponent {

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
        let gridView = ProductGridViewComplete()
        gridView.configure(columns: columns, products: products, title: title)
        return gridView
    }
}

class SDUIDemoViewController : UIViewController {
    private let scrollView = UIScrollView()

    private let contentStackView : UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 0
        return sv
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "SDUI Demo"
        view.backgroundColor = .systemBackground

        setupUI()
        registerDemoComponents()
        renderMockData()
    }

    private func setupUI(){
        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentStackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
    }

    private func registerDemoComponents(){
        SDUIComponentRegistry.shared.register(DemoBannerComponent.self)
        SDUIComponentRegistry.shared.register(DemoProductGridComponent.self)
    }

    private func renderMockData(){
        print("SDUI rendering with Mock data")
        guard let components = mockSDUIResponse["components"] as? [[String:Any]] else {
            print("Invalid Mock Data")
            return
        }

        for (index, componentJSON) in components.enumerated() {
            let type = componentJSON["type"] as? String ?? "unknown"
            print("\(index+1). Creating component: \(type)")

            if let component = SDUIComponentRegistry.shared.createComponent(
                from: componentJSON
            ) {
                let view = component.createView()
                contentStackView.addArrangedSubview(view)
            } else {
                print("could not create component: \(type)")
            }
        }

        print("SDUI Rendering complete")
    }
}
