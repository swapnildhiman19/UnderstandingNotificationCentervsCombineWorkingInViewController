//
//  MemoryOptimization.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 27/12/25.
//
import Foundation
import UIKit

class RetainCycleExamples {
    class BadExample {
        var closure : (()->Void)?
        var name : String = "Bad Example"
        
        func setupBadClosure() {
            closure = {
                print(self.name)
            }
        }
        
        deinit {
            print("Bad Example deallocated")
        }
    }
    
    class GoodExample {
        var closure : (()->Void)?
        var name : String = "Good Example"
        
        func setupBadClosure() {
            closure = { [weak self] in
                guard let self = self else {return}
                print(self.name)
            }
        }
        
        deinit {
            print("Good Example deallocated")
        }
    }
}

protocol DataLoaderDelegate: AnyObject {
    func didLoadData(_ data: Data)
}

class DataLoader {
    weak var delegate : DataLoaderDelegate?
    
    //WRONG: var delegate: DataLoaderDelegate?
}

class GoodViewController : UIViewController, DataLoaderDelegate {
    let loader = DataLoader() //VC holds strongly
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.delegate = self
    }
    
    func didLoadData(_ data: Data) {
        //
    }
}

final class LeakDetector {
    static func checkForLeak (
        _ object: AnyObject,
        description: String = "",
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        weak var weakObject = object
        let objectType = String(describing: type(of: object))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if weakObject != nil {
                let location = "\(file)_\(line)"
                print("""
                Swapnil Potential memory leak detected!
                Object: \(objectType)
                Description: \(description)
                Location: \(location)
                The object was not deallocated after 2 seconds.
                """)
            }
        }
        #endif
    }
}

class LeakCheckingViewController : UIViewController {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed || isMovingFromParent {
            LeakDetector.checkForLeak(self, description: "Product Details VC")
        }
    }
}

class MemoryEfficientCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private var currentImageURL : URL?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        currentImageURL = nil
    }
    
    func configure(with imageURL: URL) {
        currentImageURL = imageURL
        
        //Use downsampled image
        ImageCacheManager.shared.loadImage(url: imageURL, targetSize: contentView.bounds.size) { [weak self] image in
            guard self?.currentImageURL == imageURL else { return }
            self?.imageView.image = image
        }
    }
}

final class MemoryWarningHandler {
    static let shared = MemoryWarningHandler()
    
    private init(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("Swapnil Memory Warning Received")
        
        ImageCacheManager.shared.clearAll()
        
        URLCache.shared.removeAllCachedResponses()
        
        NotificationCenter.default.post(
            name: .appDidReceiveMemoryWarning,
            object: nil
        )
        
        print("Swapnil Memory cleanup complete")
    }
}

extension Notification.Name {
    static let appDidReceiveMemoryWarning = Notification.Name("appDidRecieveMemoryWarning")
}

class BatchProcessor {
    func processLargeDataset(items:[Data]) {
        for (index,item) in items.enumerated() {
            if index % 100 == 0 {
                autoreleasepool {
                    processItem(item)
                }
            } else {
               processItem(item)
            }
        }
    }
    
    private func processItem(_  item: Data) {
        _ = UIImage(data: item)
    }
}
