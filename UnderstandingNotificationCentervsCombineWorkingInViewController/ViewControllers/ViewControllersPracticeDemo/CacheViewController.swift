////
////  CacheViewController.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 27/11/25.
////
//
//// MARK: - Cache Manager
//import UIKit
//
//enum NetworkError:LocalizedError {
//    case invalidURL
//    case invalidResponse
//    case httpError(statusCode: Int)
//    case decodingError(error: Error)
//    case encodingError(error: Error)
//    case noData
//
//
//    var errorDescription: String? {
//        switch self {
//        case .invalidURL:
//            return "Invalid URL"
//        case .invalidResponse:
//            return "Invalid server response"
//        case .noData:
//            return "No data received from server"
//        case .httpError(let code):
//            return "HTTP Error: \(code)"
//        case .decodingError(let error):
//            return "Failed to decode JSON: \(error.localizedDescription)"
//        case .encodingError(let error):
//            return "Failed to encode JSON: \(error.localizedDescription)"
//        }
//    }
//}
//
//class MyOwnNetworkCacheManager {
//    static let shared = MyOwnNetworkCacheManager()
//    private init() {}
//
//    private let urlCache : URLCache = {
//        let cachesURL = FileManager.default.urls(
//            for: .cachesDirectory,
//            in: .userDomainMask
//        )[0]
//
//        let diskPath = cachesURL.appendingPathComponent("NetworkCache")
//
//        return URLCache(
//            memoryCapacity: 50 * 1024 * 1024,
//            diskCapacity: 100 * 1024 * 1024,
//            directory: diskPath
//        )
//    }()
//
//    private var memoryCache = NSCache<NSString,AnyObject>()
//
//    func configure() {
//        URLCache.shared = urlCache
//        memoryCache.countLimit = 100
//        memoryCache.totalCostLimit = 50 * 1024 * 1024
//    }
//
//    //Fetch with Cache URL
//    func fetchWithCache<T:Decodable>(
//        from urlString: String,
//        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
//    ) async throws -> T {
//        guard let url = URL(string: urlString) else {
//            throw NetworkError.invalidURL
//        }
//
//        var request = URLRequest(url: url, cachePolicy: cachePolicy)
//
//        //Checking for cache response
//        if let cachedResponse = urlCache.cachedResponse(for: request) {
//            print("cached response available")
//            return try JSONDecoder().decode(T.self, from: cachedResponse.data)
//        }
//
//        let (data,response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkError.invalidResponse
//        }
//
//        //store this response for future use case
//        let cachedResponse = CachedURLResponse(response: httpResponse, data: data)
//        urlCache.storeCachedResponse(cachedResponse, for: request)
//
//        return try JSONDecoder().decode(T.self, from: data)
//    }
//
//    func fetchWithMemoryCache<T : Codable>(
//        key : String,
//        fetchBlock: () async throws ->T
//    ) async throws -> T {
//        let cacheKey = NSString(string: key)
//
//        if let cached = memoryCache.object(forKey: cacheKey) as? T {
//            return cached
//        }
//
//        let results = try await fetchBlock()
//
//        memoryCache.setObject(results as AnyObject, forKey: cacheKey)
//        return results
//    }
//}
//
//
//class NetworkCacheManager {
//    static let shared = NetworkCacheManager()
//    private init() {}
//
//    // ✅ URLCache - built-in HTTP caching
//    private let urlCache: URLCache = {
//        let cachesURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
//        let diskPath = cachesURL.appendingPathComponent("NetworkCache")
//
//        // 50 MB memory, 100 MB disk
//        return URLCache(
//            memoryCapacity: 50 * 1024 * 1024,
//            diskCapacity: 100 * 1024 * 1024,
//            directory: diskPath
//        )
//    }()
//
//    // ✅ Custom cache for models
//    private var memoryCache = NSCache<NSString, AnyObject>()
//
//    func configure() {
//        // Set global URL cache
//        URLCache.shared = urlCache
//
//        // Configure memory cache
//        memoryCache.countLimit = 100 // Max 100 items
//        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
//    }
//
//    // 1️⃣ Fetch with Cache (URLCache)
//    func fetchWithCache<T: Decodable>(
//        from urlString: String,
//        cachePolicy: URLRequest.CachePolicy = .returnCacheDataElseLoad
//    ) async throws -> T {
//        guard let url = URL(string: urlString) else {
//            throw NetworkError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.cachePolicy = cachePolicy
//
//        // ✅ Check if cached response exists
//        if let cachedResponse = urlCache.cachedResponse(for: request) {
//            print("📦 Using cached response")
//            return try JSONDecoder().decode(T.self, from: cachedResponse.data)
//        }
//
//        // ✅ Fetch from network
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkError.invalidResponse
//        }
//
//        // ✅ Cache response
//        let cachedResponse = CachedURLResponse(response: response, data: data)
//        urlCache.storeCachedResponse(cachedResponse, for: request)
//
//        return try JSONDecoder().decode(T.self, from: data)
//    }
//
//    // 2️⃣ Custom Memory Cache
//    func fetchWithMemoryCache<T: Decodable & Encodable>(
//        key: String,
//        fetchBlock: () async throws -> T
//    ) async throws -> T {
//        let cacheKey = NSString(string: key)
//
//        // ✅ Check memory cache
//        if let cached = memoryCache.object(forKey: cacheKey) as? T {
//            print("📦 Using memory cache for: \(key)")
//            return cached
//        }
//
//        // ✅ Fetch from network
//        let result = try await fetchBlock()
//
//        // ✅ Store in cache
//        memoryCache.setObject(result as AnyObject, forKey: cacheKey)
//
//        return result
//    }
//
//    // 3️⃣ Disk Cache (UserDefaults for small data)
//    func fetchWithDiskCache<T: Codable>(
//        key: String,
//        expirationTime: TimeInterval = 3600, // 1 hour default
//        fetchBlock: () async throws -> T
//    ) async throws -> T {
//        let cacheKey = "cache_\(key)"
//        let timestampKey = "timestamp_\(key)"
//
//        // ✅ Check disk cache
//        if let cachedData = UserDefaults.standard.data(forKey: cacheKey),
//           let timestamp = UserDefaults.standard.object(forKey: timestampKey) as? Date {
//
//            // Check if expired
//            let age = Date().timeIntervalSince(timestamp)
//            if age < expirationTime {
//                print("📦 Using disk cache for: \(key)")
//                return try JSONDecoder().decode(T.self, from: cachedData)
//            } else {
//                print("⏰ Cache expired for: \(key)")
//            }
//        }
//
//        // ✅ Fetch from network
//        let result = try await fetchBlock()
//
//        // ✅ Store in disk cache
//        let data = try JSONEncoder().encode(result)
//        UserDefaults.standard.set(data, forKey: cacheKey)
//        UserDefaults.standard.set(Date(), forKey: timestampKey)
//
//        return result
//    }
//
//    // Clear all caches
//    func clearAllCaches() {
//        urlCache.removeAllCachedResponses()
//        memoryCache.removeAllObjects()
//        print("🗑️ All caches cleared")
//    }
//}
//
//// MARK: - Usage
//
//class CacheViewController: UIViewController {
//
//    func loadUsersWithCache() async {
//        do {
//            // ✅ Will use cache if available
//            let users: [User] = try await NetworkCacheManager.shared.fetchWithCache(
//                from: "https://jsonplaceholder.typicode.com/users",
//                cachePolicy: .returnCacheDataElseLoad
//            )
//
//            print("✅ Got \(users.count) users")
//        } catch {
//            print("❌ Error: \(error)")
//        }
//    }
//
//    func loadWithCustomCache() async {
//        do {
//            let users = try await NetworkCacheManager.shared.fetchWithMemoryCache(key: "all_users") {
//                // This block only runs if not cached
//                try await NetworkManager.shared.fetchUsers()
//            }
//
//            print("✅ Got \(users.count) users")
//        } catch {
//            print("❌ Error: \(error)")
//        }
//    }
//}
