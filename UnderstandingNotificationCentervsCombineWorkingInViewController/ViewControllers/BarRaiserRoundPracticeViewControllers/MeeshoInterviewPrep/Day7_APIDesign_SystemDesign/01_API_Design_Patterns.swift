// ============================================================================
// MEESHO INTERVIEW PREP: API Design Patterns for iOS
// ============================================================================
// Day 7: API Design and Full System Design Practice
//
// This covers API-level design patterns the interviewer mentioned:
// "API level discussion + designing and integrating and using in iOS"
// ============================================================================

import Foundation

// ============================================================================
// SECTION 1: REPOSITORY PATTERN
// ============================================================================
/*
 🎯 WHAT IS REPOSITORY PATTERN?
 
 The Repository pattern abstracts data access logic:
 - ViewController/ViewModel doesn't know WHERE data comes from
 - Could be network, cache, database - doesn't matter!
 - Easy to test (mock the repository)
 - Easy to change data source later
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         WITHOUT REPOSITORY                                  │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
 │  ViewModel   │ ─────▶ │  URLSession  │ ─────▶ │   Server     │
 │              │        │  (directly)  │        │              │
 └──────────────┘        └──────────────┘        └──────────────┘
 
 Problems:
 - Hard to test (need real network)
 - Hard to add caching
 - ViewModel knows too much about networking
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         WITH REPOSITORY                                     │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌──────────────┐        ┌──────────────┐        ┌──────────────┐
 │  ViewModel   │ ─────▶ │  Repository  │ ─────▶ │  Network /   │
 │              │        │  (Protocol)  │        │  Cache / DB  │
 └──────────────┘        └──────────────┘        └──────────────┘
 
 Benefits:
 - Easy to test (mock repository)
 - Repository handles caching logic
 - ViewModel is clean
*/

// MARK: - Repository Protocol

/// Defines data access operations for products
protocol ProductRepositoryProtocol {
    /// Fetch products with pagination
    func fetchProducts(page: Int, limit: Int) async throws -> ProductListResponse
    
    /// Fetch single product details
    func fetchProductDetails(id: String) async throws -> Product
    
    /// Search products
    func searchProducts(query: String, page: Int) async throws -> ProductListResponse
    
    /// Add product to favorites
    func addToFavorites(productId: String) async throws
}

// MARK: - Data Models

struct Product: Codable {
    let id: String
    let name: String
    let price: Double
    let imageUrl: String
    let description: String
    let category: String
    let rating: Double
    let reviewCount: Int
}

struct ProductListResponse: Codable {
    let products: [Product]
    let pagination: Pagination
}

struct Pagination: Codable {
    let currentPage: Int
    let totalPages: Int
    let hasMore: Bool
}

// MARK: - Repository Implementation

/// Production repository with caching
final class ProductRepository: ProductRepositoryProtocol {
    
    private let networkClient: NetworkClientProtocol
    private let cache: ProductCacheProtocol
    
    init(
        networkClient: NetworkClientProtocol = NetworkClient.shared,
        cache: ProductCacheProtocol = ProductCache.shared
    ) {
        self.networkClient = networkClient
        self.cache = cache
    }
    
    func fetchProducts(page: Int, limit: Int) async throws -> ProductListResponse {
        // Check cache first (only for first page)
        if page == 1, let cached = cache.getCachedProducts() {
            return cached
        }
        
        // Fetch from network
        let request = APIRequest<ProductListResponse>(
            endpoint: "/products",
            method: .get,
            queryParams: ["page": "\(page)", "limit": "\(limit)"]
        )
        
        let response = try await networkClient.execute(request)
        
        // Cache first page
        if page == 1 {
            cache.cacheProducts(response)
        }
        
        return response
    }
    
    func fetchProductDetails(id: String) async throws -> Product {
        // Check cache
        if let cached = cache.getCachedProduct(id: id) {
            return cached
        }
        
        // Fetch from network
        let request = APIRequest<Product>(
            endpoint: "/products/\(id)",
            method: .get
        )
        
        let product = try await networkClient.execute(request)
        cache.cacheProduct(product)
        
        return product
    }
    
    func searchProducts(query: String, page: Int) async throws -> ProductListResponse {
        // Search always hits network (no caching for search)
        let request = APIRequest<ProductListResponse>(
            endpoint: "/products/search",
            method: .get,
            queryParams: ["q": query, "page": "\(page)"]
        )
        
        return try await networkClient.execute(request)
    }
    
    func addToFavorites(productId: String) async throws {
        let request = APIRequest<EmptyResponse>(
            endpoint: "/favorites",
            method: .post,
            body: ["productId": productId]
        )
        
        _ = try await networkClient.execute(request)
    }
}

// MARK: - Mock Repository for Testing

final class MockProductRepository: ProductRepositoryProtocol {
    
    var mockProducts: [Product] = []
    var shouldThrowError = false
    
    func fetchProducts(page: Int, limit: Int) async throws -> ProductListResponse {
        if shouldThrowError {
            throw NSError(domain: "MockError", code: 500)
        }
        
        return ProductListResponse(
            products: mockProducts,
            pagination: Pagination(currentPage: page, totalPages: 1, hasMore: false)
        )
    }
    
    func fetchProductDetails(id: String) async throws -> Product {
        guard let product = mockProducts.first(where: { $0.id == id }) else {
            throw NSError(domain: "NotFound", code: 404)
        }
        return product
    }
    
    func searchProducts(query: String, page: Int) async throws -> ProductListResponse {
        let filtered = mockProducts.filter { $0.name.contains(query) }
        return ProductListResponse(
            products: filtered,
            pagination: Pagination(currentPage: page, totalPages: 1, hasMore: false)
        )
    }
    
    func addToFavorites(productId: String) async throws {
        // No-op for mock
    }
}

// ============================================================================
// SECTION 2: NETWORK LAYER DESIGN
// ============================================================================

/// HTTP methods
enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

/// Generic API request
struct APIRequest<Response: Decodable> {
    let endpoint: String
    let method: HTTPMethod
    var headers: [String: String] = [:]
    var queryParams: [String: String] = [:]
    var body: [String: Any]? = nil
    var timeoutInterval: TimeInterval = 30
}

/// Empty response for endpoints that don't return data
struct EmptyResponse: Decodable {}

/// Network client protocol
protocol NetworkClientProtocol {
    func execute<T: Decodable>(_ request: APIRequest<T>) async throws -> T
}

/// Production network client
final class NetworkClient: NetworkClientProtocol {
    
    static let shared = NetworkClient()
    
    private let session: URLSession
    private let baseURL = "https://api.meesho.com/v1"
    private let decoder: JSONDecoder
    
    init(session: URLSession = .shared) {
        self.session = session
        self.decoder = JSONDecoder()
        self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    }
    
    func execute<T: Decodable>(_ request: APIRequest<T>) async throws -> T {
        let urlRequest = try buildURLRequest(from: request)
        
        let (data, response) = try await session.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode, data)
        }
        
        // Handle empty response
        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        
        return try decoder.decode(T.self, from: data)
    }
    
    private func buildURLRequest<T>(from request: APIRequest<T>) throws -> URLRequest {
        var components = URLComponents(string: baseURL + request.endpoint)!
        
        if !request.queryParams.isEmpty {
            components.queryItems = request.queryParams.map {
                URLQueryItem(name: $0.key, value: $0.value)
            }
        }
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = request.method.rawValue
        urlRequest.timeoutInterval = request.timeoutInterval
        
        // Add headers
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }
        
        // Add auth token
        if let token = AuthManager.shared.accessToken {
            urlRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Add body
        if let body = request.body {
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return urlRequest
    }
}

enum NetworkError: Error {
    case invalidURL
    case invalidResponse
    case serverError(Int, Data)
    case noData
}

// ============================================================================
// SECTION 3: ERROR HANDLING & RETRY
// ============================================================================

/// Retry configuration
struct RetryConfiguration {
    let maxAttempts: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    
    static let `default` = RetryConfiguration(
        maxAttempts: 3,
        baseDelay: 1.0,
        maxDelay: 30.0
    )
}

/// Network client with retry logic
extension NetworkClient {
    
    func executeWithRetry<T: Decodable>(
        _ request: APIRequest<T>,
        config: RetryConfiguration = .default
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...config.maxAttempts {
            do {
                return try await execute(request)
            } catch {
                lastError = error
                
                // Don't retry client errors (4xx)
                if case NetworkError.serverError(let code, _) = error,
                   (400..<500).contains(code) {
                    throw error
                }
                
                // Calculate delay with exponential backoff
                if attempt < config.maxAttempts {
                    let delay = min(
                        config.baseDelay * pow(2, Double(attempt - 1)),
                        config.maxDelay
                    )
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? NetworkError.invalidResponse
    }
}

// ============================================================================
// SECTION 4: PAGINATION PATTERNS
// ============================================================================
/*
 TWO MAIN PAGINATION PATTERNS:
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         OFFSET-BASED PAGINATION                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Request: GET /products?page=2&limit=20
 
 ┌────────────────────────────────────────────────────────────────────────────┐
 │  Page 1: Items 1-20                                                        │
 │  Page 2: Items 21-40   ← Current                                          │
 │  Page 3: Items 41-60                                                       │
 └────────────────────────────────────────────────────────────────────────────┘
 
 Pros:
 ✓ Simple to implement
 ✓ Can jump to any page
 
 Cons:
 ✗ Can skip or duplicate items if list changes
 ✗ Slow for large offsets (DB has to count)
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │                         CURSOR-BASED PAGINATION                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 Request: GET /products?cursor=eyJpZCI6MTAwfQ&limit=20
 
 ┌────────────────────────────────────────────────────────────────────────────┐
 │  First request: no cursor                                                  │
 │  Response includes: nextCursor = "eyJpZCI6MTAwfQ"                         │
 │                                                                            │
 │  Next request: cursor = "eyJpZCI6MTAwfQ"                                  │
 │  Response: next 20 items after item 100                                    │
 └────────────────────────────────────────────────────────────────────────────┘
 
 Pros:
 ✓ Consistent results even if list changes
 ✓ Better performance for large datasets
 
 Cons:
 ✗ Can't jump to arbitrary page
 ✗ More complex to implement
*/

/// Cursor-based pagination manager
final class PaginatedLoader<T: Decodable> {
    
    private var nextCursor: String?
    private var isLoading = false
    private(set) var hasMore = true
    private(set) var items: [T] = []
    
    private let fetchPage: (String?) async throws -> CursorResponse<T>
    
    init(fetchPage: @escaping (String?) async throws -> CursorResponse<T>) {
        self.fetchPage = fetchPage
    }
    
    func loadNextPage() async throws -> [T] {
        guard !isLoading, hasMore else { return [] }
        
        isLoading = true
        defer { isLoading = false }
        
        let response = try await fetchPage(nextCursor)
        
        items.append(contentsOf: response.items)
        nextCursor = response.nextCursor
        hasMore = response.nextCursor != nil
        
        return response.items
    }
    
    func reset() {
        items.removeAll()
        nextCursor = nil
        hasMore = true
        isLoading = false
    }
}

struct CursorResponse<T: Decodable>: Decodable {
    let items: [T]
    let nextCursor: String?
}

// ============================================================================
// SECTION 5: PLACEHOLDER TYPES
// ============================================================================

protocol ProductCacheProtocol {
    func getCachedProducts() -> ProductListResponse?
    func cacheProducts(_ response: ProductListResponse)
    func getCachedProduct(id: String) -> Product?
    func cacheProduct(_ product: Product)
}

enum ProductCache {
    static let shared: ProductCacheProtocol = ProductCacheImpl()
}

class ProductCacheImpl: ProductCacheProtocol {
    func getCachedProducts() -> ProductListResponse? { nil }
    func cacheProducts(_ response: ProductListResponse) {}
    func getCachedProduct(id: String) -> Product? { nil }
    func cacheProduct(_ product: Product) {}
}

enum AuthManager {
    static let shared = AuthManager.self
    static var accessToken: String? { nil }
}

// ============================================================================
// SECTION 6: INTERVIEW QUESTIONS & ANSWERS
// ============================================================================

/*
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q1: "Explain the Repository pattern"                                       │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  Repository pattern abstracts data access from business logic:              │
 │                                                                             │
 │  1. DEFINE PROTOCOL:                                                        │
 │     protocol ProductRepository {                                            │
 │         func fetchProducts() async throws -> [Product]                      │
 │     }                                                                       │
 │                                                                             │
 │  2. IMPLEMENT FOR PRODUCTION:                                               │
 │     class ProductRepositoryImpl: ProductRepository {                        │
 │         // Uses network + cache                                             │
 │     }                                                                       │
 │                                                                             │
 │  3. IMPLEMENT FOR TESTING:                                                  │
 │     class MockProductRepository: ProductRepository {                        │
 │         // Returns fake data                                                │
 │     }                                                                       │
 │                                                                             │
 │  BENEFITS:                                                                  │
 │  - Testability: Inject mock for unit tests                                  │
 │  - Flexibility: Change data source without changing consumers               │
 │  - Clean architecture: Separation of concerns                               │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
 
 ┌─────────────────────────────────────────────────────────────────────────────┐
 │  Q2: "Offset vs Cursor pagination - when to use which?"                     │
 ├─────────────────────────────────────────────────────────────────────────────┤
 │  ANSWER:                                                                    │
 │                                                                             │
 │  OFFSET (page=2&limit=20):                                                  │
 │  Use when:                                                                  │
 │  - User needs to jump to specific page                                      │
 │  - Dataset is relatively static                                             │
 │  - Dataset is small                                                         │
 │  Example: Blog posts, documentation                                         │
 │                                                                             │
 │  CURSOR (cursor=abc123&limit=20):                                          │
 │  Use when:                                                                  │
 │  - Realtime feeds (items being added/removed)                               │
 │  - Large datasets (offset causes performance issues)                        │
 │  - Infinite scroll UI                                                       │
 │  Example: Social media feed, product catalog                                │
 │                                                                             │
 │  FOR MEESHO (E-commerce):                                                   │
 │  Cursor is preferred because:                                               │
 │  - Product availability changes frequently                                  │
 │  - Millions of products (offset would be slow)                              │
 │  - Users scroll infinitely                                                  │
 │                                                                             │
 └─────────────────────────────────────────────────────────────────────────────┘
*/

