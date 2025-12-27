//
//  Untitled.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by EasyAiWithSwapnil on 27/12/25.
//

import Foundation
import UIKit

final class ImageCacheManager {
    
    static let shared = ImageCacheManager()
    
    private let memoryCache : NSCache<NSString,UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 50 * 1024 * 1024 //50MB
        cache.countLimit = 100
        return cache
    }()
    
    //DiskCache Directory - can be cleared by iOS
    private let diskCacheURL : URL = {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        let imageCacheDir = cacheDir.appendingPathComponent("ImageCache", isDirectory: true)
        try? FileManager.default.createDirectory(at: imageCacheDir, withIntermediateDirectories: true)
        return imageCacheDir
    }()
    
    private let diskCacheSizeLimit : UInt64 = 200 * 1024 * 1024 //200 MB
    private let diskQueue = DispatchQueue(label: "com.meesho.imagecache.disk", qos: .utility)
    
    private init(){
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
        
        scheduleDiskCleanUp()
    }
    
    @objc private func handleMemoryWarning() {
        print("Swapnil Memory Warning - clearing all image cache")
        memoryCache.removeAllObjects()
    }
    
    private func scheduleDiskCleanUp(){
        //Run this periodically
        DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + 60) {
            [weak self] in
            self?.performDiskCacheCleanUp()
            self?.scheduleDiskCleanUp()
        }
    }
    
    private func performDiskCacheCleanUp(){
        diskQueue.async {
            [weak self] in
            guard let self = self else { return }
            let fileManager = FileManager.default
            guard let files = try? fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.contentModificationDateKey,.fileSizeKey], options: []) else {
                return
            }
            
            var totalSize : UInt64 = 0
            var fileInfos: [(url: URL, date: Date, size: UInt64)] = []
            
            for fileURL in files {
                guard let attributes = try? fileURL.resourceValues(forKeys: [.contentModificationDateKey,.fileSizeKey]),
                      let date = attributes.contentModificationDate,
                      let size = attributes.fileSize else { continue }
                totalSize += UInt64(size)
                fileInfos.append((fileURL, date, UInt64(size)))
            }
            
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
    
    func loadImage(
        url : URL,
        targetSize: CGSize? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        let cacheKey = cacheKey(for: url, targetSize: targetSize)
        
        //Check memory cache
        if let cachedImage = memoryCache.object(forKey: cacheKey as NSString){
            print("Swapnil Memory Cache Hit :\(url.lastPathComponent)")
            completion(cachedImage)
            return
        }
        
        //Check disk cache : This is slow process
        diskQueue.async { [weak self] in
            if let diskImage = self?.loadFromDiskCache(key: cacheKey, targetSize: targetSize) {
                //store in memory cache
                self?.memoryCache.setObject(diskImage, forKey: cacheKey as NSString)
                
                DispatchQueue.main.async {
                    print("Swapnil Disk cache hit: \(url.lastPathComponent)")
                    completion(diskImage)
                }
                return
            }
            
            //Fetch from network
            self?.fetchFromNetwork(url: url, cacheKey: cacheKey, targetSize: targetSize, completion: completion)
        }
    }
    
    //MARK: Generating cache key
    func cacheKey(for url: URL, targetSize: CGSize?) -> String {
        var key = url.absoluteString
        if let size = targetSize {
            key += "_\(Int(size.width))x\(Int(size.height))"
        }
        //creating a hash for file system safety
        return key.data(using: .utf8)?.base64EncodedString() ?? key
    }
    
    //MARK: Disk Cache Operations
    private func loadFromDiskCache(
        key: String,
        targetSize: CGSize? = nil
    ) -> UIImage? {
        let path = diskCachePath(for: key)
        
        guard FileManager.default.fileExists(atPath: path.path),
              let data = try? Data(contentsOf: path) else {
            return nil
        }
        
        //Downsample if targetsize exists - it is storing compressed form of data
        if let targetSize = targetSize {
            return downsampledImage(from: data, for: targetSize)
        } else {
            return UIImage(data: data)
        }
    }
    
    private func downsampledImage(from data: Data, for targetSize: CGSize) -> UIImage? {
        let options : [CFString: Any] = [
            kCGImageSourceShouldCache : false //Don't cache the full size
        ]
        
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, options as CFDictionary) else { return nil }
        
        let scale = UIScreen.main.scale
        let maxDimension = max(targetSize.width, targetSize.height) * scale
        
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways : true,
            kCGImageSourceShouldCacheImmediately : true,
            kCGImageSourceCreateThumbnailWithTransform : true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]
        
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        
        return UIImage(cgImage: downsampledImage)
    }
    
    private func diskCachePath(for key: String) -> URL {
        return diskCacheURL.appendingPathComponent(key)
    }
    
    private func saveToDiskCache(data: Data, key: String) {
        let path = diskCachePath(for: key)
        try? data.write(to: path)
    }
    
    private func fetchFromNetwork(
        url: URL,
        cacheKey: String,
        targetSize: CGSize? = nil,
        completion: @escaping (UIImage?) -> Void
    ) {
        let task =  URLSession.shared.dataTask(with: url) {
            [weak self] data, response, error in
            guard let self = self , let data = data, error == nil else {
                DispatchQueue.main.async {completion(nil)}
                return
            }
            
            //save to original disk
            self.diskQueue.async {
                self.saveToDiskCache(data: data, key: cacheKey)
            }
            
            let image: UIImage?
            if let targetSize = targetSize {
                image = self.downsampledImage(from: data, for: targetSize)
            } else {
                image = UIImage(data: data)
            }
            
            if let image = image {
                self.memoryCache.setObject(image, forKey: cacheKey as NSString)
            }
            
            DispatchQueue.main.async {
                print("Swapnil network loaded \(url.lastPathComponent)")
                completion(image)
            }
        }
        task.resume()
    }
    
    func prefetch(urls: [URL], targetSize: CGSize? = nil) {
        for url in urls {
            let cachedKey = self.cacheKey(for: url, targetSize: targetSize)
            
            if memoryCache.object(forKey: cachedKey as NSString) != nil {
                continue
            }
            
            loadImage(url: url, targetSize: targetSize) { _ in
            
            }
        }
    }
    
    func cancelPrefetch(urls:[URL]){
        print("Cancelling prefetch for \(urls.count) URLs")
    }
    
    func clearAll() {
        memoryCache.removeAllObjects()
        
        diskQueue.async {
            [weak self] in
            guard let self = self else {return}
            try? FileManager.default.removeItem(at: diskCacheURL)
            try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        }
    }
}

extension UIImageView {
    func setImage(
        from url: URL,
        placeholder: UIImage? = nil,
        targetSize: CGSize? = nil
    ) {
        self.image = placeholder
        let size = targetSize ?? self.bounds.size
        
        let urlKey = UnsafeRawPointer(bitPattern: "imageURL".hashValue)!
        objc_setAssociatedObject(self, urlKey, url, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        
        ImageCacheManager.shared.loadImage(url: url, targetSize: targetSize) { [weak self] image in
            guard let self = self else { return }
            let currentURL = objc_getAssociatedObject(self, urlKey) as? URL
            guard currentURL == url else { return }
            self.image = image ?? placeholder
        }
    }
}

class ImagePrefetchingDataSource: NSObject, UICollectionViewDataSourcePrefetching {
    
    var imageURLProvider: ((IndexPath) -> URL?)?
    var targetImageSize : CGSize = CGSize(width: 150, height: 150)
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap {imageURLProvider?($0)}
        ImageCacheManager.shared.prefetch(urls: urls, targetSize: targetImageSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        let urls = indexPaths.compactMap { imageURLProvider?($0) }
        ImageCacheManager.shared.cancelPrefetch(urls: urls)
    }
    
}
