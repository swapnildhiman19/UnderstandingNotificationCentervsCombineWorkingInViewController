//
//  PageLoadKit.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 26/12/25.
//
import Foundation
import UIKit

final class PageLoadTracker {
    static let shared = PageLoadTracker()
    
    //Single page load measurement in progress
    private struct ActiveMeasurement {
        let pageName : String
        let startTime : CFAbsoluteTime
        let metadata : [String: Any]
        var milestones : [Milestone]
        
        struct Milestone {
            let name : String
            let timeStamp : CFAbsoluteTime
        }
    }
    
    //Result of completed page load measurement
    struct PageLoadResult {
        let pageName: String
        let totalDurationMs : Double
        let metadata: [String: Any]
        let milestones : [String: Any]
        let timestamp : Date
    }
    
    private var activeMeasurementsDict : [String: ActiveMeasurement] = [:]
    
    //Race condition avoid for activeMeasurementsDict
    private let queue = DispatchQueue(label: "com.meesho.pageloadtracker")
    
    private let analyticsService : AnalyticsServiceProtocol
    
    private let samplingRate : Double = 1.0
    
    private let slowThresholdMs : Double = 2000
    
    private init(){
        self.analyticsService = AnalyticsService.shared
    }
    
    func startTracking(
        pageName: String,
        metadata: [String:Any] = [:]
    ) -> String {
        //Will return tracking id for each page
        let trackingID = UUID().uuidString
        let startTime = CFAbsoluteTimeGetCurrent()
        
        queue.sync {
            activeMeasurementsDict[trackingID] = ActiveMeasurement(pageName: pageName, startTime: startTime, metadata: metadata, milestones: [])
        }
        
        print("Swapnil Started tracking: \(pageName)  [\(trackingID)] trackingID")
        return trackingID
    }
    
    //api_complete, content_rendered, image_downloaded
    func recordMilestone(_ name: String, trackingID: String) {
        let timestamp = CFAbsoluteTimeGetCurrent()
        
        queue.sync {
            guard var measurement = activeMeasurementsDict[trackingID] else {
                print("Swapnil No Active measurement happening for this trackingID : \(trackingID)")
                return
            }
            
            var milestone = ActiveMeasurement.Milestone(name: name, timeStamp: timestamp)
            
            measurement.milestones.append(milestone)
            activeMeasurementsDict[trackingID] = measurement
            
            let elapsedMs = (timestamp - measurement.startTime) * 1000
            print("Swapnil milestone \(name) at \(elapsedMs) ms")
        }
    }
    
    @discardableResult
    func endTracking(trackingId: String) -> PageLoadResult? {
        let endTime = CFAbsoluteTimeGetCurrent()
        var result: PageLoadResult?
        
        queue.sync {
            guard let measurement = activeMeasurementsDict[trackingId] else {
                print("Swapnil No active measurement for tracking ID : \(trackingId)")
                return
            }
            
            let totalDurationMs = (endTime - measurement.startTime) * 1000
            
            var milestoneTimings : [String: Double] = [:]
            for milestone in measurement.milestones {
                let milestoneMs = (milestone.timeStamp - measurement.startTime) * 1000
                milestoneTimings[milestone.name] = milestoneMs //time of the event from the start of pageLoad
            }
            
            result = PageLoadResult(
                pageName: measurement.pageName,
                totalDurationMs: totalDurationMs,
                metadata: measurement.metadata,
                milestones: milestoneTimings,
                timestamp: Date()
            )
        }
        
        if let result = result {
            reportResult(result)
        }
        
        return result
    }
    
    
    //User navigated to someother screen ( cancel tracking without reporting )
    func cancelTracking(trackingId: String) {
        queue.sync {
            activeMeasurementsDict.removeValue(forKey: trackingId)
        }
        print("Swapnil cancelled tracking: \(trackingId)")
    }
    
    private func reportResult(_ result: PageLoadResult){
        if Double.random(in: 0...1) > samplingRate {
            return //high traffic BE, do not overload with all the pageLoad events
        }
        
        print("Swapnil page load has been completed: \(result.pageName) in \(result.totalDurationMs) ms")
        
        var params : [String:Any] = [
            "page": result.pageName,
            "duration_ms": result.totalDurationMs,
            "timestamp": result.timestamp.timeIntervalSince1970
        ]
        
        for (milestone,timing) in result.milestones {
            params["milestone_\(milestone)_ms"] = timing
        }
        
        for (key,value) in result.metadata {
            params["meta_\(key)"] = value
        }
        
        let isSlow = result.totalDurationMs > slowThresholdMs
        params["is_slow"] = isSlow
        
        analyticsService.log(event: "page_load", params: params)
        
        if isSlow {
            analyticsService.log(event: "slow_page_load", params: params)
            print("Swapnil SLOW PAGE LOAD: \(result.pageName) took \(result.totalDurationMs)")
        }
    }
}

protocol PageLoadTrackable: AnyObject {
    var pageLoadPageName : String { get }
    var pageLoadTrackingId : String? { get set }
    var pageLoadMetaData : [String:Any] {get}
}

extension PageLoadTrackable {
    var metaData : [String:Any] { return [:] }
}

extension UIViewController {
    private static var trackingIdKey: UInt8 = 0
    
    var pageLoadTrackingId: String? {
        get {
            return objc_getAssociatedObject(self, &Self.trackingIdKey) as? String
        }
        set {
            objc_setAssociatedObject(self, &Self.trackingIdKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    func startPageLoadTracking(pageName: String, metadata: [String:Any] = [:]) {
        pageLoadTrackingId = PageLoadTracker.shared.startTracking(
            pageName: pageName,
            metadata: metadata
        )
    }
    
    func recordPageLoadMilestone(_ name: String) {
        guard let trackingId = pageLoadTrackingId else {
            return
        }
        PageLoadTracker.shared.recordMilestone(name, trackingID: trackingId)
    }
    
    func endPageLoadTracking() {
        guard let trackingId = pageLoadTrackingId else { return }
        PageLoadTracker.shared.endTracking(trackingId: trackingId)
        pageLoadTrackingId = nil
    }
    
    func cancelPageLoadTracking() {
        guard let trackingId = pageLoadTrackingId else { return }
        PageLoadTracker.shared.cancelTracking(trackingId: trackingId)
        pageLoadTrackingId = nil
    }
}

//MARK: Usage

class ProductDetailViewControllerWithPageLoadTracking: UIViewController {
    
    private let productId: String
    private var product: Product?
    
    private let scrollView = UIScrollView()
    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let priceLabel = UILabel()
    private let descriptionLabel = UILabel()
    private let loadingIndicator = UIActivityIndicatorView(style: .large)
    
    init(productId: String){
        self.productId = productId
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
         super.viewDidLoad()
        
        startPageLoadTracking(
            pageName: "product_detail",
            metadata: ["product_id":productId]
        )
        
        setupUI()
        loadProductData()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(true)
        
        //Cancelling if user leaves before pageloads
        if product == nil {
            cancelPageLoadTracking()
        }
    }
    
    private func setupUI(){
        view.backgroundColor = .systemBackground
        
        loadingIndicator.startAnimating()
        view.addSubview(loadingIndicator)
        loadingIndicator.center = view.center
    }
    
    private func loadProductData() {
        ProductAPI.fetchProduct(id: productId) { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let product):
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
            self.priceLabel.text = "Rs \(product.price)"
            self.descriptionLabel.text = product.description
            
            self.recordPageLoadMilestone("content_rendered")
        }
    }
    
    private func loadProductImage(url: URL) {
        ImageLoader.shared.loadImage(url: url) { [weak self] image in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.imageView.image = image
                self.loadingIndicator.stopAnimating()
                self.recordPageLoadMilestone("image_loaded")
                //all done
                self.endPageLoadTracking()
            }
        }
    }
    
    private func showError(_ error: Error){
        //Show error on the UI
    }
}

struct Product {
    let id : String
    let name : String
    let price : Double
    let description: String
    let imageUrl : URL
}

enum ProductAPI {
    static func fetchProduct(id: String, completion: @escaping (Result<Product,Error>)-> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.5) {
            let product = Product(id: id, name: "Sample Product", price: 499, description: "A great product", imageUrl: URL(string:"https://example.com/image.jpg")!
            )
            completion(.success(product))
        }
    }
}

enum ImageLoader {
    static let shared = ImageLoader.self
    static func loadImage(url: URL, completion: @escaping (UIImage?)->Void){
        DispatchQueue.global().asyncAfter(deadline: .now() + 0.3) {
            completion(UIImage(systemName: "photo"))
        }
    }
}
