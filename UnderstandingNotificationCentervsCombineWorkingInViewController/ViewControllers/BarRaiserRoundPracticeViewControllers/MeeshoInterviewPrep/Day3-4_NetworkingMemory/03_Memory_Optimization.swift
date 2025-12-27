// ============================================================================
// MEESHO INTERVIEW PREP: Memory Optimization Techniques
// ============================================================================
// Day 3-4: Networking and Memory Optimization
//
// The interviewer reduced peak memory usage and OOMs by ~50%.
// This file covers all memory optimization techniques.
// ============================================================================
/*
import Foundation
import UIKit

// ============================================================================
// SECTION 1: COMMON MEMORY ISSUES
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                    TOP 5 MEMORY ISSUES IN iOS                               │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 1. RETAIN CYCLES (Memory Leaks)
    - Objects reference each other strongly
    - Neither can be deallocated
    - Memory grows forever!
 
 2. LARGE IMAGES IN MEMORY
    - Full resolution images decoded
    - 4000x3000 image = 48MB!
    - Solution: Downsampling
 
 3. UNBOUNDED CACHES
    - Cache grows without limits
    - No eviction policy
    - Solution: Use NSCache with limits
 
 4. BACKGROUND TASKS HOLDING DATA
    - Closures capturing large objects
    - Data loaded but never released
    - Solution: [weak self], cancel tasks
 
 5. VIEW CONTROLLER LEAKS
    - VCs not deallocated after dismiss
    - Usually due to closures or delegates
    - Solution: Proper delegate/closure handling
*/

// ============================================================================
// SECTION 2: RETAIN CYCLES - DETECTION AND FIX
// ============================================================================

/// EXAMPLE 1: Retain Cycle in Closures
class RetainCycleExamples {
    
    // ❌ BAD - Creates retain cycle
    class BadExample {
        var closure: (() -> Void)?
        var name = "BadExample"
        
        func setupBadClosure() {
            // 'self' is captured strongly by the closure
            // 'self' holds 'closure', 'closure' holds 'self' = LEAK!
            closure = {
                print(self.name) // Strong reference to self
            }
        }
        
        deinit { print("BadExample deallocated") } // Never called!
    }
    
    // ✅ GOOD - Using [weak self]
    class GoodExample {
        var closure: (() -> Void)?
        var name = "GoodExample"
        
        func setupGoodClosure() {
            // [weak self] breaks the retain cycle
            closure = { [weak self] in
                guard let self = self else { return }
                print(self.name)
            }
        }
        
        deinit { print("GoodExample deallocated") } // Called properly!
    }
}

/// EXAMPLE 2: Delegate Retain Cycle
protocol DataLoaderDelegate: AnyObject {
    func didLoadData(_ data: Data)
}

class DataLoader {
    // ✅ CORRECT: Delegate is weak to avoid retain cycle
    weak var delegate: DataLoaderDelegate?
    
    // ❌ WRONG would be: var delegate: DataLoaderDelegate?
    // This would create: VC -> DataLoader -> VC (cycle!)
}

class ViewController: UIViewController, DataLoaderDelegate {
    let loader = DataLoader() // VC holds loader strongly
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loader.delegate = self // Loader holds VC weakly
    }
    
    func didLoadData(_ data: Data) {
        // Handle data
    }
}

// ============================================================================
// SECTION 3: RUNTIME LEAK DETECTION
// ============================================================================

/// Helper class to detect memory leaks at runtime
final class LeakDetector {
    
    /// Call this in viewDidDisappear to check if VC deallocates
    static func checkForLeak(
        _ object: AnyObject,
        description: String = "",
        file: String = #file,
        line: Int = #line
    ) {
        #if DEBUG
        // Store weak reference
        weak var weakObject = object
        let objectType = String(describing: type(of: object))
        
        // Check after delay if object still exists
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if weakObject != nil {
                let location = "\(file):\(line)"
                print("""
                    ⚠️ POTENTIAL MEMORY LEAK DETECTED!
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

// Usage in View Controller
class LeakCheckingViewController: UIViewController {
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isBeingDismissed || isMovingFromParent {
            LeakDetector.checkForLeak(self, description: "ProductDetailVC")
        }
    }
}

// ============================================================================
// SECTION 4: MEMORY-EFFICIENT COLLECTIONS
// ============================================================================

/// Collection view cell that properly manages memory
class MemoryEfficientCell: UICollectionViewCell {
    
    private let imageView = UIImageView()
    private var currentImageURL: URL?
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        // CRITICAL: Clear image on reuse
        // Without this, old image stays in memory until new one loads
        imageView.image = nil
        currentImageURL = nil
    }
    
    func configure(with imageURL: URL) {
        currentImageURL = imageURL
        
        // Use downsampled image
        ImageCacheManager.shared.loadImage(
            from: imageURL,
            targetSize: contentView.bounds.size
        ) { [weak self] image in
            // Check URL matches (cell might have been reused)
            guard self?.currentImageURL == imageURL else { return }
            self?.imageView.image = image
        }
    }
}

// ============================================================================
// SECTION 5: MEMORY WARNING HANDLER
// ============================================================================

/// Centralized memory warning handler
final class MemoryWarningHandler {
    
    static let shared = MemoryWarningHandler()
    
    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning received!")
        
        // 1. Clear all image caches
        ImageCacheManager.shared.clearAll()
        
        // 2. Clear URL cache
        URLCache.shared.removeAllCachedResponses()
        
        // 3. Notify observers to release their caches
        NotificationCenter.default.post(
            name: .appDidReceiveMemoryWarning,
            object: nil
        )
        
        // 4. Log for analytics
        print("✅ Memory cleanup complete")
    }
}

extension Notification.Name {
    static let appDidReceiveMemoryWarning = Notification.Name("appDidReceiveMemoryWarning")
}

// ============================================================================
// SECTION 6: AUTORELEASE POOL OPTIMIZATION
// ============================================================================

/// Use autorelease pools when processing large amounts of data
class BatchProcessor {
    
    func processLargeDataset(items: [Data]) {
        /*
         WHY AUTORELEASE POOL?
         
         In a loop, temporary objects accumulate until the pool drains.
         For 10,000 items, memory spikes as all temporaries stay alive.
         
         By creating an inner pool per iteration (or every N items),
         we release temporaries immediately.
        */
        
        for (index, item) in items.enumerated() {
            // Create pool every 100 items
            if index % 100 == 0 {
                autoreleasepool {
                    processItem(item)
                }
            } else {
                processItem(item)
            }
        }
    }
    
    private func processItem(_ data: Data) {
        // Processing creates temporary objects
        _ = UIImage(data: data)
    }
}

// ============================================================================
// SECTION 7: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "How would you reduce memory usage by 50% in an e-commerce app?"       │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  1. IMAGE DOWNSAMPLING (biggest impact):                                    │
 │     - Decode images to display size only                                    │
 │     - 4000x3000 → 400x300 = 100x reduction                                 │
 │                                                                             │
 │  2. CACHE MANAGEMENT:                                                       │
 │     - Use NSCache with countLimit and costLimit                             │
 │     - Clear caches on memory warning                                        │
 │                                                                             │
 │  3. FIX RETAIN CYCLES:                                                      │
 │     - Audit closures for [weak self]                                        │
 │     - Ensure delegates are weak                                             │
 │     - Use Instruments Leaks profiler                                        │
 │                                                                             │
 │  4. CELL PREPARATION:                                                       │
 │     - Clear images in prepareForReuse()                                     │
 │     - Cancel pending image loads                                            │
 │                                                                             │
 │  5. PROACTIVE MONITORING:                                                   │
 │     - Track memory usage in real-time                                       │
 │     - Degrade features before hitting limits                                │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "What is a retain cycle and how do you fix it?"                        │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  WHAT: Two objects hold strong references to each other.                    │
 │  Neither can be deallocated because each is keeping the other alive.        │
 │                                                                             │
 │  COMMON CAUSES:                                                             │
 │  1. Closures capturing 'self' strongly                                      │
 │  2. Delegate properties not marked 'weak'                                   │
 │  3. Timer callbacks without weak references                                 │
 │                                                                             │
 │  FIXES:                                                                     │
 │  1. Use [weak self] or [unowned self] in closures                          │
 │  2. Mark delegate properties as 'weak'                                      │
 │  3. Invalidate timers in deinit                                             │
 │                                                                             │
 │  DETECTION:                                                                 │
 │  - Instruments → Leaks tool                                                 │
 │  - Debug → Memory Graph in Xcode                                            │
 │  - Runtime detection (check deinit called)                                  │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "Explain weak vs unowned references"                                   │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  WEAK:                                                                      │
 │  - Can be nil (Optional type)                                               │
 │  - Automatically becomes nil when referenced object is deallocated          │
 │  - Safe: check for nil before use                                           │
 │  - Use when: Referenced object might be deallocated before you use it       │
 │                                                                             │
 │  UNOWNED:                                                                   │
 │  - Never nil (non-optional)                                                 │
 │  - CRASH if you access after object is deallocated                          │
 │  - Slightly more performant (no optional unwrap)                            │
 │  - Use when: You KNOW the referenced object will outlive you                │
 │                                                                             │
 │  RULE OF THUMB:                                                             │
 │  - Default to [weak self] for closures                                      │
 │  - Use [unowned self] only when you're 100% sure about lifetimes            │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/
*/
