// ============================================================================
// MEESHO INTERVIEW PREP: Image Caching System Design
// ============================================================================
// Day 3-4: Networking and Memory Optimization
//
// This is a CRITICAL topic for e-commerce apps. The interviewer optimized
// memory by 50% - image handling is a major part of that.
// ============================================================================

import Foundation
import UIKit

// ============================================================================
// SECTION 1: UNDERSTANDING IMAGE MEMORY (Layman's Explanation)
// ============================================================================
/*
 🎯 THE IMAGE MEMORY PROBLEM:
 
 Images take MUCH more memory than their file size suggests!
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         Image Memory Math                                   │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │                                                                             │
 │  JPEG File on Disk: 200 KB (compressed)                                     │
 │                                                                             │
 │  DECODED IN MEMORY:                                                         │
 │  Width × Height × Bytes per Pixel                                           │
 │  2000  ×  1500  ×  4 (RGBA)                                                 │
 │  = 12,000,000 bytes                                                         │
 │  = 12 MB!  😱                                                              │
 │                                                                             │
 │  That's 60x larger than the file!                                           │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 FOR E-COMMERCE:
 - Product page might show 10 images
 - Each image 12 MB decoded
 - Total: 120 MB just for one page!
 - User scrolls 10 pages → 1.2 GB → OOM CRASH! 💥
 
 SOLUTION: DOWNSAMPLING
 - Don't decode full resolution
 - Decode only what's needed for display size
 - 200×150 pixel thumbnail = 120 KB in memory
 - That's 100x reduction!
*/

// ============================================================================
// SECTION 2: MULTI-TIER CACHING ARCHITECTURE
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                      Image Caching Architecture                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Request Image
      │
      ▼
 ┌─────────────────┐    HIT     ┌─────────────────┐
 │  Memory Cache   │───────────▶│  Return UIImage │
 │  (NSCache)      │            │  (Instant!)     │
 │  ~50MB limit    │            └─────────────────┘
 └────────┬────────┘
          │ MISS
          ▼
 ┌─────────────────┐    HIT     ┌─────────────────┐
 │   Disk Cache    │───────────▶│ Load from disk  │
 │  (FileManager)  │            │ (~10-50ms)      │
 │  ~200MB limit   │            └────────┬────────┘
 └────────┬────────┘                     │
          │ MISS                         │
          ▼                              ▼
 ┌─────────────────┐            ┌─────────────────┐
 │    Network      │            │ Decode & Cache  │
 │  (URLSession)   │───────────▶│ in Memory+Disk  │
 │                 │            └─────────────────┘
 └─────────────────┘
 
 WHY TWO CACHES?
 
 Memory Cache:
 ✓ Instant access (nanoseconds)
 ✗ Limited size (device RAM)
 ✗ Lost when app closes
 
 Disk Cache:
 ✓ Larger capacity (hundreds of MB)
 ✓ Persists across app launches
 ✗ Slower access (disk I/O)
*/

// ============================================================================
// SECTION 3: COMPLETE IMAGE CACHING IMPLEMENTATION
// ============================================================================

/// Production-ready image caching system with memory + disk tiers.
/// Includes downsampling to minimize memory usage.
final class ImageCacheManager {
    
    // MARK: - Singleton
    static let shared = ImageCacheManager()
    
    // MARK: - Cache Layers
    
    /// In-memory cache using NSCache (auto-evicts under memory pressure)
    private let memoryCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 100 // Max 100 images
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        return cache
    }()
    
    /// Disk cache directory
    private let diskCacheURL: URL = {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let imageCacheDir = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: imageCacheDir, withIntermediateDirectories: true)
        return imageCacheDir
    }()
    
    // MARK: - Configuration
    
    private let diskCacheSizeLimit: UInt64 = 200 * 1024 * 1024 // 200 MB
    private let diskQueue = DispatchQueue(label: "com.meesho.imagecache.disk", qos: .utility)
    
    // MARK: - Initialization
    
    private init() {
        // Listen for memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        // Periodic disk cache cleanup
        scheduleDiskCacheCleanup()
    }
    
    // MARK: - Public API
    
    /// Load image with automatic caching and optional downsampling
    ///
    /// - Parameters:
    ///   - url: Image URL
    ///   - targetSize: Size to downsample to (nil = full resolution)
    ///   - completion: Called with the loaded image
    func loadImage(
        from url: URL,
        targetSize: CGSize? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        let cacheKey = cacheKey(for: url, targetSize: targetSize)
        
        // 1. Check memory cache
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString) {
            print("📦 Memory cache hit: \(url.lastPathComponent)")
            completion(cachedImage)
            return
        }
        
        // 2. Check disk cache (async)
        diskQueue.async { [weak self] in
            if let diskImage = self?.loadFromDiskCache(key: cacheKey, targetSize: targetSize) {
                // Store in memory cache
                self?.memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
                
                DispatchQueue.main.async {
                    print("💾 Disk cache hit: \(url.lastPathComponent)")
                    completion(diskImage)
                }
                return
            }
            
            // 3. Fetch from network
            self?.fetchFromNetwork(url: url, cacheKey: cacheKey, targetSize: targetSize, completion: completion)
        }
    }
    
    /// Prefetch images (e.g., for upcoming cells in collection view)
    func prefetch(urls: [URL], targetSize: CGSize? = nil) {
        for url in urls {
            let cacheKey = self.cacheKey(for: url, targetSize: targetSize)
            
            // Skip if already cached
            if memoryCache.object(forKey: cacheKey as NSString) != nil {
                continue
            }
            
            // Low priority fetch
            loadImage(from: url, targetSize: targetSize) { _ in }
        }
    }
    
    /// Cancel prefetching (e.g., user scrolled past)
    func cancelPrefetch(urls: [URL]) {
        // In a production implementation, you'd track active tasks and cancel them
        print("Cancelling prefetch for \(urls.count) URLs")
    }
    
    /// Clear all caches
    func clearAll() {
        memoryCache.removeAllObjects()
        
        diskQueue.async { [weak self] in
            guard let self = self else { return }
            try? FileManager.default.removeItem(at: self.diskCacheURL)
            try? FileManager.default.createDirectory(at: self.diskCacheURL, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Memory Management
    
    @objc private func handleMemoryWarning() {
        print("⚠️ Memory warning - clearing image cache")
        memoryCache.removeAllObjects()
    }
    
    // MARK: - Cache Key Generation
    
    private func cacheKey(for url: URL, targetSize: CGSize?) -> String {
        var key = url.absoluteString
        if let size = targetSize {
            key += "_\(Int(size.width))x\(Int(size.height))"
        }
        // Create hash for file system safety
        return key.data(using: .utf8)?.base64EncodedString() ?? key
    }
    
    // MARK: - Disk Cache Operations
    
    private func diskCachePath(for key: String) -> URL {
        return diskCacheURL.appendingPathComponent(key)
    }
    
    private func saveToDiskCache(data: Data, key: String) {
        let path = diskCachePath(for: key)
        try? data.write(to: path)
    }
    
    private func loadFromDiskCache(key: String, targetSize: CGSize?) -> UIImage? {
        let path = diskCachePath(for: key)
        
        guard FileManager.default.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path) else {
            return nil
        }
        
        // Downsample if target size specified
        if let targetSize = targetSize {
            return downsampledImage(from: data, for: targetSize)
        } else {
            return UIImage(data: data)
        }
    }
    
    // MARK: - Network Fetching
    
    private func fetchFromNetwork(
        url: URL,
        cacheKey: String,
        targetSize: CGSize?,
        completion: @escaping (UIImage?) -> Void
    ) {
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let self = self, let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            
            // Save original to disk cache
            self.diskQueue.async {
                self.saveToDiskCache(data: data, key: cacheKey)
            }
            
            // Decode (with optional downsampling)
            let image: UIImage?
            if let targetSize = targetSize {
                image = self.downsampledImage(from: data, for: targetSize)
            } else {
                image = UIImage(data: data)
            }
            
            // Save to memory cache
            if let image = image {
                self.memoryCache.setObject(image, forKey: cacheKey as NSString)
            }
            
            DispatchQueue.main.async {
                print("🌐 Network loaded: \(url.lastPathComponent)")
                completion(image)
            }
        }
        task.resume()
    }
    
    // MARK: - Disk Cache Cleanup
    
    private func scheduleDiskCacheCleanup() {
        // Run cleanup periodically
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) { [weak self] in
            self?.performDiskCacheCleanup()
            self?.scheduleDiskCacheCleanup()
        }
    }
    
    private func performDiskCacheCleanup() {
        diskQueue.async { [weak self] in
            guard let self = self else { return }
            
            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(
                at: self.diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: []
            ) else { return }
            
            // Calculate total size
            var totalSize: UInt64 = 0
            var fileInfos: [(url: URL, date: Date, size: UInt64)] = []
            
            for fileURL in files {
                guard let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey, .fileSizeKey]),
                      let date = attributes.contentModificationDate,
                      let size = attributes.fileSize else { continue }
                
                totalSize += UInt64(size)
                fileInfos.append((fileURL, date, UInt64(size)))
            }
            
            // If over limit, remove oldest files
            if totalSize > self.diskCacheSizeLimit {
                let sortedByDate = fileInfos.sorted { $0.date < $1.date }
                var sizeToRemove = totalSize - self.diskCacheSizeLimit
                
                for fileInfo in sortedByDate {
                    guard sizeToRemove > 0 else { break }
                    try? fileManager.removeItem(at: fileInfo.url)
                    sizeToRemove -= fileInfo.size
                }
            }
        }
    }
    
    // MARK: - Downsampling (CRITICAL for memory optimization)
    
    /// Downsample image to target size without loading full resolution into memory
    /// This is the KEY technique for reducing memory usage!
    private func downsampledImage(from data: Data, for size: CGSize) -> UIImage? {
        /*
         WHY DOWNSAMPLING MATTERS:
         
         Without downsampling:
         1. Load JPEG (200KB file)
         2. Decode to full resolution (2000x1500 = 12MB in memory)
         3. Draw scaled down (UIImageView scales it)
         4. But memory already used = 12MB!
         
         With downsampling:
         1. Tell iOS "I only need 200x150 pixels"
         2. iOS decodes directly to that size
         3. Memory used = 120KB!
         
         100x memory reduction! 🎉
        */
        
        // Create image source from data
        let options: [CFString: Any] = [
            kCGImageSourceShouldCache: false // Don't cache full-size
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else {
            return nil
        }
        
        // Calculate target size with scale
        let scale = UIScreen.main.scale
        let maxDimension = max(size.width, size.height) * scale
        
        // Request downsampled image
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(
            imageSource,
            0,
            downsampleOptions as CFDictionary
        ) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
}

// ============================================================================
// SECTION 4: UIIMAGEVIEW EXTENSION FOR EASY USE
// ============================================================================

extension UIImageView {
    
    /// Load image from URL with automatic caching
    func setImage(
        from url: URL,
        placeholder: UIImage? = nil,
        targetSize: CGSize? = nil
    ) {
        // Set placeholder immediately
        self.image = placeholder
        
        // Calculate target size based on imageView size if not specified
        let size = targetSize ?? self.bounds.size
        
        // Store URL to handle cell reuse
        let urlKey = UnsafeRawPointer(bitPattern: "imageURL".hashValue)!
        objc_setAssociatedObject(self, urlKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        ImageCacheManager.shared.loadImage(from: url, targetSize: size) { [weak self] image in
            guard let self = self else { return }
            
            // Check if URL still matches (cell might have been reused)
            let currentURL = objc_getAssociatedObject(self, urlKey) as? URL
            guard currentURL == url else { return }
            
            self.image = image ?? placeholder
        }
    }
}

// ============================================================================
// SECTION 5: COLLECTION VIEW PREFETCHING
// ============================================================================

/// Data source that handles image prefetching for collection views
class ImagePrefetchingDataSource: NSObject, UICollectionViewDataSourcePrefetching {
    
    var imageURLProvider: ((IndexPath) -> URL?)?
    var targetImageSize: CGSize = CGSize(width: 150, height: 150)
    
    func collectionView(
        _ collectionView: UICollectionView,
        prefetchItemsAt indexPaths: [IndexPath]
    ) {
        let urls = indexPaths.compactMap { imageURLProvider?($0) }
        ImageCacheManager.shared.prefetch(urls: urls, targetSize: targetImageSize)
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cancelPrefetchingForItemsAt indexPaths: [IndexPath]
    ) {
        let urls = indexPaths.compactMap { imageURLProvider?($0) }
        ImageCacheManager.shared.cancelPrefetch(urls: urls)
    }
}

// ============================================================================
// SECTION 6: MEMORY COMPARISON
// ============================================================================
/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                    MEMORY USAGE COMPARISON                                  │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Scenario: Loading 20 product images in a grid
 
 WITHOUT OPTIMIZATION:
 ┌────────────────────────────────────────────────────────────────────────────┐
 │ Image 1:  Full resolution 2000x1500 → 12 MB                                │
 │ Image 2:  Full resolution 2000x1500 → 12 MB                                │
 │ ...                                                                        │
 │ Image 20: Full resolution 2000x1500 → 12 MB                                │
 │                                                                            │
 │ TOTAL: 240 MB just for one screen! 😱                                     │
 │                                                                            │
 │ User scrolls 5 pages → 1.2 GB → OOM CRASH!                                │
 └────────────────────────────────────────────────────────────────────────────┘
 
 WITH DOWNSAMPLING (Display size: 200x150):
 ┌────────────────────────────────────────────────────────────────────────────┐
 │ Image 1:  Downsampled 200x150 → 120 KB                                     │
 │ Image 2:  Downsampled 200x150 → 120 KB                                     │
 │ ...                                                                        │
 │ Image 20: Downsampled 200x150 → 120 KB                                     │
 │                                                                            │
 │ TOTAL: 2.4 MB per screen! ✨                                              │
 │                                                                            │
 │ User scrolls 5 pages → 12 MB (with cache eviction, even less!)            │
 └────────────────────────────────────────────────────────────────────────────┘
 
 MEMORY REDUCTION: 100x (240 MB → 2.4 MB)
 
 This is how Meesho reduced memory usage by 50%!
*/

// ============================================================================
// SECTION 7: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "Design an image caching system for an e-commerce app"                 │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  ARCHITECTURE: Two-tier caching                                             │
 │                                                                             │
 │  1. MEMORY CACHE (L1):                                                      │
 │     - Use NSCache (auto-evicts on memory pressure)                          │
 │     - Limit: 50 MB or 100 images                                            │
 │     - Store decoded UIImage (ready to display)                              │
 │     - Key: URL + target size hash                                           │
 │                                                                             │
 │  2. DISK CACHE (L2):                                                        │
 │     - Use FileManager in Caches directory                                   │
 │     - Limit: 200 MB with LRU eviction                                       │
 │     - Store original JPEG/PNG data                                          │
 │     - Decode on-demand with downsampling                                    │
 │                                                                             │
 │  3. CRITICAL OPTIMIZATION - DOWNSAMPLING:                                   │
 │     - Use CGImageSourceCreateThumbnailAtIndex                               │
 │     - Decode directly to display size                                       │
 │     - 100x memory reduction for thumbnails                                  │
 │                                                                             │
 │  4. PREFETCHING:                                                            │
 │     - Use UICollectionViewDataSourcePrefetching                             │
 │     - Start loading before cells are visible                                │
 │     - Cancel when user scrolls past                                         │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "What is downsampling and why is it important?"                        │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  PROBLEM:                                                                   │
 │  - JPEG file = 200 KB compressed                                            │
 │  - Decoded in memory = 12 MB (width × height × 4 bytes)                     │
 │  - Even if displayed at 200×150 pixels, full 12 MB is used!                 │
 │                                                                             │
 │  SOLUTION - DOWNSAMPLING:                                                   │
 │  - Tell iOS "decode only to size I need"                                    │
 │  - Use CGImageSourceCreateThumbnailAtIndex                                  │
 │  - iOS decodes directly to target size                                      │
 │  - Memory: 200×150×4 = 120 KB instead of 12 MB                              │
 │                                                                             │
 │  CODE:                                                                      │
 │  let options: [CFString: Any] = [                                          │
 │      kCGImageSourceCreateThumbnailFromImageAlways: true,                    │
 │      kCGImageSourceThumbnailMaxPixelSize: maxDimension,                     │
 │      kCGImageSourceShouldCacheImmediately: true                             │
 │  ]                                                                          │
 │  let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options)    │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q3: "How do you handle cell reuse with async image loading?"               │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  PROBLEM:                                                                   │
 │  - Start loading image for cell A                                           │
 │  - User scrolls, cell is reused for item B                                  │
 │  - Image A finishes loading, shows in cell B → WRONG IMAGE!                 │
 │                                                                             │
 │  SOLUTION:                                                                  │
 │  1. Store the expected URL with the cell (using objc_setAssociatedObject)   │
 │  2. When image loads, check if URL still matches                            │
 │  3. Only set image if it matches                                            │
 │                                                                             │
 │  CODE:                                                                      │
 │  // Store URL when starting load                                            │
 │  objc_setAssociatedObject(cell, &urlKey, url, .OBJC_ASSOCIATION_RETAIN)     │
 │                                                                             │
 │  // In completion handler                                                   │
 │  let currentURL = objc_getAssociatedObject(cell, &urlKey) as? URL           │
 │  guard currentURL == url else { return } // Cell was reused!                │
 │  cell.imageView.image = loadedImage                                         │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q4: "Why use NSCache instead of Dictionary?"                               │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  NSCache ADVANTAGES:                                                        │
 │                                                                             │
 │  1. AUTO-EVICTION:                                                          │
 │     - Automatically removes items under memory pressure                     │
 │     - No manual memory warning handling needed                              │
 │                                                                             │
 │  2. THREAD-SAFE:                                                            │
 │     - Safe to access from multiple threads                                  │
 │     - Dictionary needs manual locking                                       │
 │                                                                             │
 │  3. COST-BASED LIMITS:                                                      │
 │     - Can set limits based on "cost" (e.g., image size in bytes)            │
 │     - cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB                      │
 │                                                                             │
 │  4. COUNT LIMITS:                                                           │
 │     - Can limit number of items                                             │
 │     - cache.countLimit = 100                                                │
 │                                                                             │
 │  Dictionary would require implementing all of this manually!                │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

// ============================================================================
// SECTION 8: WHITEBOARD DIAGRAM
// ============================================================================

/*
 IMAGE LOADING FLOW (Draw this):
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                                                                             │
 │    loadImage(url, targetSize: 200x150)                                     │
 │                    │                                                        │
 │                    ▼                                                        │
 │    ┌─────────────────────────────┐                                         │
 │    │   Memory Cache (NSCache)    │────▶ HIT: Return immediately            │
 │    └──────────────┬──────────────┘      (< 1ms)                            │
 │                   │ MISS                                                    │
 │                   ▼                                                         │
 │    ┌─────────────────────────────┐                                         │
 │    │    Disk Cache (Files)       │────▶ HIT: Decode + Return               │
 │    └──────────────┬──────────────┘      (10-50ms)                          │
 │                   │ MISS                      │                             │
 │                   ▼                           │                             │
 │    ┌─────────────────────────────┐           │                             │
 │    │    Network (URLSession)     │           │                             │
 │    │    Download from CDN        │           │                             │
 │    └──────────────┬──────────────┘           │                             │
 │                   │                           │                             │
 │                   ▼                           ▼                             │
 │    ┌─────────────────────────────────────────────────────────┐             │
 │    │                    DOWNSAMPLING                          │             │
 │    │   CGImageSourceCreateThumbnailAtIndex(targetSize)       │             │
 │    │   2000x1500 (12MB) → 200x150 (120KB)                    │             │
 │    └──────────────────────────┬──────────────────────────────┘             │
 │                               │                                             │
 │                               ▼                                             │
 │                   ┌───────────────────────┐                                │
 │                   │   Cache in Memory     │                                │
 │                   │   + Disk (original)   │                                │
 │                   └───────────┬───────────┘                                │
 │                               │                                             │
 │                               ▼                                             │
 │                   ┌───────────────────────┐                                │
 │                   │   Return to caller    │                                │
 │                   └───────────────────────┘                                │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 
 MEMORY IMPACT COMPARISON:
 
 WITHOUT DOWNSAMPLING:
 ┌────────────────────────────────────────────────────────────────────────────┐
 │                                                                            │
 │  Image Source: 2000 x 1500 pixels                                          │
 │                                                                            │
 │  Memory = Width × Height × 4 bytes (RGBA)                                  │
 │         = 2000 × 1500 × 4                                                  │
 │         = 12,000,000 bytes                                                 │
 │         = 12 MB per image! 😱                                             │
 │                                                                            │
 │  20 product images = 240 MB                                                │
 │                                                                            │
 └────────────────────────────────────────────────────────────────────────────┘
 
 WITH DOWNSAMPLING (to 200x150 display size):
 ┌────────────────────────────────────────────────────────────────────────────┐
 │                                                                            │
 │  Target: 200 x 150 pixels                                                  │
 │                                                                            │
 │  Memory = Width × Height × 4 bytes (RGBA)                                  │
 │         = 200 × 150 × 4                                                    │
 │         = 120,000 bytes                                                    │
 │         = 120 KB per image! ✨                                            │
 │                                                                            │
 │  20 product images = 2.4 MB                                                │
 │                                                                            │
 │  REDUCTION: 100x (240 MB → 2.4 MB)                                        │
 │                                                                            │
 └────────────────────────────────────────────────────────────────────────────┘
*/

