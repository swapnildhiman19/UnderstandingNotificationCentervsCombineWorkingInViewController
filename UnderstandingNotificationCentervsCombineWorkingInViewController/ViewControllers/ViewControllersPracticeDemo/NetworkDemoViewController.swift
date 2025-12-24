////
////  NetworkDemoViewController.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 27/11/25.
////
//
//// MARK: - Complete Network Layer
//import UIKit
//
//final class APIClient {
//    static let shared = APIClient()
////    private init() {}
//
//    private let baseURL = "https://jsonplaceholder.typicode.com"
//    private let session: URLSession
//
//    init(configuration: URLSessionConfiguration = .default) {
//        // Configure session
//        configuration.timeoutIntervalForRequest = 30
//        configuration.timeoutIntervalForResource = 300
//        configuration.waitsForConnectivity = true
//
//        self.session = URLSession(configuration: configuration)
//    }
//
//    // Generic request method
//    func request<T: Decodable>(
//        _ endpoint: Endpoint,
//        method: HTTPMethod = .get,
//        parameters: [String: Any]? = nil,
//        body: Encodable? = nil
//    ) async throws -> T {
//        // Build URL
//        var urlComponents = URLComponents(string: baseURL + endpoint.path)!
//
//        // Add query parameters
//        if let parameters = parameters {
//            urlComponents.queryItems = parameters.map { URLQueryItem(name: $0.key, value: "\($0.value)") }
//        }
//
//        guard let url = urlComponents.url else {
//            throw NetworkError.invalidURL
//        }
//
//        // Create request
//        var request = URLRequest(url: url)
//        request.httpMethod = method.rawValue
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//        request.setValue("application/json", forHTTPHeaderField: "Accept")
//
//        // Add body
//        if let body = body {
//            request.httpBody = try JSONEncoder().encode(body)
//        }
//
//        // Log request
//        print("🌐 \(method.rawValue) \(url.absoluteString)")
//
//        // Execute request
//        let (data, response) = try await session.data(for: request)
//
//        // Validate response
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw NetworkError.invalidResponse
//        }
//
//        print("📡 Status: \(httpResponse.statusCode)")
//
//        guard (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkError.httpError(statusCode: httpResponse.statusCode)
//        }
//
//        // Log response
//        if let jsonString = String(data: data, encoding: .utf8) {
//            print("📥 Response: \(jsonString.prefix(200))...")
//        }
//
//        // Decode
//        let decoder = JSONDecoder()
//        decoder.keyDecodingStrategy = .convertFromSnakeCase
//
//        return try decoder.decode(T.self, from: data)
//    }
//}
//
//// MARK: - Endpoints
//
//enum Endpoint {
//    case users
//    case user(id: Int)
//    case posts
//    case post(id: Int)
//    case userPosts(userId: Int)
//
//    var path: String {
//        switch self {
//        case .users:
//            return "/users"
//        case .user(let id):
//            return "/users/\(id)"
//        case .posts:
//            return "/posts"
//        case .post(let id):
//            return "/posts/\(id)"
//        case .userPosts(let userId):
//            return "/posts?userId=\(userId)"
//        }
//    }
//}
//
//// MARK: - Post Model
//
//struct Post: Codable, Identifiable {
//    let userId: Int
//    let id: Int
//    let title: String
//    let body: String
//}
//
//// MARK: - Complete ViewController Example
//
//class NetworkDemoViewController: UIViewController {
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        Task {
//            await runAllExamples()
//        }
//    }
//
//    func runAllExamples() async {
//        print("\n🚀 Starting Network Examples...\n")
//
//        // 1. Fetch all users
//        await example1_fetchUsers()
//
//        // 2. Fetch single user
//        await example2_fetchUser()
//
//        // 3. Fetch user's posts
//        await example3_fetchUserPosts()
//
//        // 4. Create new post
//        await example4_createPost()
//
//        print("\n✅ All examples completed!\n")
//    }
//
//    func example1_fetchUsers() async {
//        print("📌 Example 1: Fetch All Users")
//
//        do {
//            let users: [User] = try await APIClient.shared.request(.users)
//            print("✅ Fetched \(users.count) users")
//
//            // Print first 3
//            for user in users.prefix(3) {
//                print("   • \(user.name) (\(user.email))")
//            }
//        } catch {
//            print("❌ Error: \(error)")
//        }
//
//        print()
//    }
//
//    func example2_fetchUser() async {
//        print("📌 Example 2: Fetch Single User")
//
//        do {
//            let user: User = try await APIClient.shared.request(.user(id: 1))
//            print("✅ Got user: \(user.name)")
//            print("   Email: \(user.email)")
//            print("   Phone: \(user.phone ?? "N/A")")
//            if let city = user.address?.city {
//                print("   City: \(city)")
//            }
//        } catch {
//            print("❌ Error: \(error)")
//        }
//
//        print()
//    }
//
//    func example3_fetchUserPosts() async {
//        print("📌 Example 3: Fetch User's Posts")
//
//        do {
//            let posts: [Post] = try await APIClient.shared.request(.userPosts(userId: 1))
//            print("✅ User has \(posts.count) posts")
//
//            // Print first post
//            if let first = posts.first {
//                print("   First post: \(first.title)")
//            }
//        } catch {
//            print("❌ Error: \(error)")
//        }
//
//        print()
//    }
//
//    func example4_createPost() async {
//        print("📌 Example 4: Create New Post")
//
//        let newPost = Post(userId: 1, id: 0, title: "My New Post", body: "This is the content")
//
//        do {
//            let created: Post = try await APIClient.shared.request(
//                .posts,
//                method: .post,
//                body: newPost
//            )
//            print("✅ Created post with ID: \(created.id)")
//            print("   Title: \(created.title)")
//        } catch {
//            print("❌ Error: \(error)")
//        }
//
//        print()
//    }
//}
