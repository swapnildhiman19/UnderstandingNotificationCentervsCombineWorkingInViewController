//////
//////  URLSessionSharedDataTaskViewController.swift
//////  UnderstandingNotificationCentervsCombineWorkingInViewController
//////
//////  Created by Swapnil Dhiman on 21/11/25.
//////
////
////import Foundation
////import UIKit
////
////// MARK: - Model (Codable for automatic JSON parsing)
////
////struct User: Codable, Identifiable {
////    let id: Int
////    let name: String
////    let username: String
////    let email: String
////    let phone: String?
////    let website: String?
////
////    // Nested objects
////    let address: Address?
////    let company: Company?
////
////    struct Address: Codable {
////        let street: String
////        let suite: String
////        let city: String
////        let zipcode: String
////    }
////
////    struct Company: Codable {
////        let name: String
////        let catchPhrase: String?
////    }
////}
////
////// MARK: - Network Manager (Completion Handler Style)
////
////class NetworkManagerOld {
////
////    // ✅ Singleton pattern
////    static let shared = NetworkManagerOld()
////    private init() {}
////
////    // Base URL
////    private let baseURL = "https://jsonplaceholder.typicode.com"
////
////    /// Fetch all users using completion handler
////    /// - Parameter completion: Called with Result containing [User] or Error
////    func fetchUsers(completion: @escaping (Result<[User], Error>) -> Void) {
////        // 1️⃣ Create URL
////        guard let url = URL(string: "\(baseURL)/users") else {
////            completion(.failure(NetworkError.invalidURL))
////            return
////        }
////
////        // 2️⃣ Create URLSession data task
////        // ✅ URLSession.shared - shared singleton instance
////        let task = URLSession.shared.dataTask(with: url) { data, response, error in
////            // 3️⃣ Handle response on background thread
////
////            // Check for network errors
////            if let error = error {
////                completion(.failure(error))
////                return
////            }
////
////            // Check HTTP response status
////            guard let httpResponse = response as? HTTPURLResponse else {
////                completion(.failure(NetworkError.invalidResponse))
////                return
////            }
////
////            // Check status code (200-299 = success)
////            guard (200...299).contains(httpResponse.statusCode) else {
////                completion(.failure(NetworkError.httpError(statusCode: httpResponse.statusCode)))
////                return
////            }
////
////            // Check data exists
////            guard let data = data else {
////                completion(.failure(NetworkError.noData))
////                return
////            }
////
////            // 4️⃣ Parse JSON using Codable
////            do {
////                let decoder = JSONDecoder()
////                let users = try decoder.decode([User].self, from: data)
////
////                // ✅ Success! Return parsed data
////                completion(.success(users))
////            } catch {
////                // ❌ JSON parsing failed
////                completion(.failure(NetworkError.decodingError(error)))
////            }
////        }
////
////        // 5️⃣ Start the task (important!)
////        task.resume()
////    }
////
////    /// Fetch single user by ID
////    func fetchUser(id: Int, completion: @escaping (Result<User, Error>) -> Void) {
////        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
////            completion(.failure(NetworkError.invalidURL))
////            return
////        }
////
////        URLSession.shared.dataTask(with: url) { data, response, error in
////            if let error = error {
////                completion(.failure(error))
////                return
////            }
////
////            guard let httpResponse = response as? HTTPURLResponse,
////                  (200...299).contains(httpResponse.statusCode) else {
////                completion(.failure(NetworkError.invalidResponse))
////                return
////            }
////
////            guard let data = data else {
////                completion(.failure(NetworkError.noData))
////                return
////            }
////
////            do {
////                let user = try JSONDecoder().decode(User.self, from: data)
////                completion(.success(user))
////            } catch {
////                completion(.failure(NetworkError.decodingError(error)))
////            }
////        }.resume()
////    }
////
////    /// POST - Create new user
////    func createUser(_ user: User, completion: @escaping (Result<User, Error>) -> Void) {
////        guard let url = URL(string: "\(baseURL)/users") else {
////            completion(.failure(NetworkError.invalidURL))
////            return
////        }
////
////        // 1️⃣ Create request with POST method
////        var request = URLRequest(url: url)
////        request.httpMethod = "POST"
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////
////        // 2️⃣ Encode user to JSON
////        do {
////            let encoder = JSONEncoder()
////            request.httpBody = try encoder.encode(user)
////        } catch {
////            completion(.failure(NetworkError.encodingError(error)))
////            return
////        }
////
////        // 3️⃣ Send request
////        URLSession.shared.dataTask(with: request) { data, response, error in
////            if let error = error {
////                completion(.failure(error))
////                return
////            }
////
////            guard let httpResponse = response as? HTTPURLResponse,
////                  (200...299).contains(httpResponse.statusCode) else {
////                completion(.failure(NetworkError.invalidResponse))
////                return
////            }
////
////            guard let data = data else {
////                completion(.failure(NetworkError.noData))
////                return
////            }
////
////            do {
////                let createdUser = try JSONDecoder().decode(User.self, from: data)
////                completion(.success(createdUser))
////            } catch {
////                completion(.failure(NetworkError.decodingError(error)))
////            }
////        }.resume()
////    }
////}
////
////// MARK: - Custom Network Errors
////
////enum NetworkError: LocalizedError {
////    case invalidURL
////    case invalidResponse
////    case noData
////    case httpError(statusCode: Int)
////    case decodingError(Error)
////    case encodingError(Error)
////
////    var errorDescription: String? {
////        switch self {
////        case .invalidURL:
////            return "Invalid URL"
////        case .invalidResponse:
////            return "Invalid server response"
////        case .noData:
////            return "No data received from server"
////        case .httpError(let code):
////            return "HTTP Error: \(code)"
////        case .decodingError(let error):
////            return "Failed to decode JSON: \(error.localizedDescription)"
////        case .encodingError(let error):
////            return "Failed to encode JSON: \(error.localizedDescription)"
////        }
////    }
////}
////
////// MARK: - Usage Example
////
////class URLSessionSharedDataTaskViewController: UIViewController {
////
////    override func viewDidLoad() {
////        super.viewDidLoad()
////
////        // ✅ Call API with completion handler
////        NetworkManagerOld.shared.fetchUsers { result in
////            // ⚠️ This closure runs on BACKGROUND thread!
////
////            switch result {
////            case .success(let users):
////                print("✅ Fetched \(users.count) users")
////
////                // Print first user
////                if let firstUser = users.first {
////                    print("First user: \(firstUser.name)")
////                    print("Email: \(firstUser.email)")
////                }
////
////                // ✅ Update UI on MAIN thread
////                DispatchQueue.main.async {
////                    // Update your tableView, labels, etc.
////                    // self.tableView.reloadData()
////                }
////
////            case .failure(let error):
////                print("❌ Error: \(error.localizedDescription)")
////
////                // Show alert on main thread
////                DispatchQueue.main.async {
////                    // self.showErrorAlert(error)
////                }
////            }
////        }
////    }
////}
//
//import Foundation
//import UIKit
//
//nonisolated struct User : Identifiable, Codable {
//    let id: Int
//    let name: String
//    let username: String
//    let email: String
//    let phone: String?
//    let website: String?
//
//    // Nested objects
//    let address: Address?
//    let company: Company?
//
//    struct Address: Codable {
//        let street: String
//        let suite: String
//        let city: String
//        let zipcode: String
//    }
//
//    struct Company: Codable {
//        let name: String
//        let catchPhrase: String?
//    }
//}
//
//enum NetworkManagerError:LocalizedError {
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
//class NetworkManagerOld {
//    static let shared = NetworkManagerOld()
//
//    private let baseURL = "https://jsonplaceholder.typicode.com"
//
//    func fetchUsers(completionHandler: @escaping (Result<[User],Error>)->Void ) {
//        let urlString = "\(baseURL)/users"
//        guard let url = URL(string: urlString) else {
//            completionHandler(.failure(NetworkManagerError.invalidURL))
//            return
//        }
//
//        let task = URLSession.shared.dataTask(with: url) {
//            data,
//            response,
//            error in
//            if let error = error {
//                completionHandler(.failure(error))
//                return
//            }
//
//            guard let httpResponse  = response as? HTTPURLResponse else {
//                completionHandler(.failure(NetworkManagerError.invalidResponse))
//                return
//            }
//
//            guard (200...209).contains(httpResponse.statusCode) else {
//                completionHandler(
//                    .failure(
//                        NetworkManagerError
//                            .httpError(statusCode: httpResponse.statusCode)
//                    )
//                )
//                return
//            }
//
//            guard let data = data else {
//                completionHandler(.failure(NetworkManagerError.noData))
//                return
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let users = try decoder.decode([User].self, from: data)
//                completionHandler(.success(users))
//            } catch {
//                completionHandler(
//                    .failure(NetworkManagerError.decodingError(error: error))
//                )
//            }
//        }
//
//        task.resume()
//    }
//
//    func fetchUser(id: Int, completionHandler: @escaping (Result<User,Error>)->Void) {
//        let urlString = "\(baseURL)/users\(id)"
//        guard let url = URL(string: urlString) else {
//            completionHandler(.failure(NetworkManagerError.invalidURL))
//            return
//        }
//
//        let task = URLSession.shared.dataTask(with: url) {
//            data,
//            response,
//            error in
//            if let error = error {
//                completionHandler(.failure(error))
//                return
//            }
//
//            guard let httpResponse  = response as? HTTPURLResponse else {
//                completionHandler(.failure(NetworkManagerError.invalidResponse))
//                return
//            }
//
//            guard (200...209).contains(httpResponse.statusCode) else {
//                completionHandler(
//                    .failure(
//                        NetworkManagerError
//                            .httpError(statusCode: httpResponse.statusCode)
//                    )
//                )
//                return
//            }
//
//            guard let data = data else {
//                completionHandler(.failure(NetworkManagerError.noData))
//                return
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let user = try decoder.decode(User.self, from: data)
//                completionHandler(.success(user))
//            } catch {
//                completionHandler(.failure(NetworkManagerError.decodingError(error: error)))
//            }
//        }
//        task.resume()
//    }
//
//    /*
//     // Example of what you might send:
//     {
//     "name": "John Doe",
//     "email": "john@example.com",
//     "age": 30
//     }
//     // Example of what the server might return:
//     {
//     "id": "a1b2c3d4e5f6",        // <-- New, server-generated unique ID
//     "name": "John Doe",
//     "email": "john@example.com",
//     "age": 30,
//     "createdAt": "2025-11-22T17:13:00Z" // <-- New, server-generated timestamp
//     }
//     */
//    func createUser(user: User, completionHandler: @escaping (Result<User,Error>)->Void) {
//        let urlString = "\(baseURL)/users"
//        guard let url = URL(string: urlString) else {
//            completionHandler(.failure(NetworkManagerError.invalidURL))
//            return
//        }
//
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        /*
//         HTTP headers provide metadata about the request itself.
//         Content-Type: This specific header tells the server the format of the data you are sending in the request's body.
//         "application/json": This value explicitly informs the server that the data you are about to send (e.g., the JSON-encoded User object) is in JSON format.
//
//         */
//
//        //Encoding the data
//        do {
//            let encoder = JSONEncoder()
//            urlRequest.httpBody = try encoder.encode(user)
//        } catch {
//            completionHandler(.failure(
//                NetworkManagerError.encodingError(error: error))
//            )
//            return
//        }
//
//        let task = URLSession.shared.dataTask(with: urlRequest) {
//            data,
//            response,
//            error in
//            if let error = error {
//                completionHandler(.failure(error))
//                return
//            }
//
//            guard let httpResponse  = response as? HTTPURLResponse else {
//                completionHandler(.failure(NetworkManagerError.invalidResponse))
//                return
//            }
//
//            guard (200...209).contains(httpResponse.statusCode) else {
//                completionHandler(
//                    .failure(
//                        NetworkManagerError
//                            .httpError(statusCode: httpResponse.statusCode)
//                    )
//                )
//                return
//            }
//
//            guard let data = data else {
//                completionHandler(.failure(NetworkManagerError.noData))
//                return
//            }
//
//            do {
//                let decoder = JSONDecoder()
//                let user = try decoder.decode(User.self, from: data)
//                completionHandler(.success(user))
//            } catch {
//                completionHandler(.failure(NetworkManagerError.decodingError(error: error)))
//            }
//        }
//        task.resume()
//    }
//}
//
////// MARK: - Modern Network Manager (Async/Await)
////
////class NetworkManager {
////
////    static let shared = NetworkManager()
////    private init() {}
////
////    private let baseURL = "https://jsonplaceholder.typicode.com"
////
////    /// Fetch all users using async/await
////    /// - Returns: Array of users
////    /// - Throws: Network or decoding errors
////    func fetchUsers() async throws -> [User] {
////        // 1️⃣ Create URL
////        guard let url = URL(string: "\(baseURL)/users") else {
////            throw NetworkError.invalidURL
////        }
////
////        // 2️⃣ Fetch data with async/await (iOS 15+)
////        // ✅ No completion handlers! Much cleaner!
////        let (data, response) = try await URLSession.shared.data(from: url)
////
////        // 3️⃣ Validate response
////        guard let httpResponse = response as? HTTPURLResponse,
////              (200...299).contains(httpResponse.statusCode) else {
////            throw NetworkError.invalidResponse
////        }
////
////        // 4️⃣ Decode JSON
////        let decoder = JSONDecoder()
////        let users = try decoder.decode([User].self, from: data)
////
////        return users
////    }
////
////    /// Fetch single user
////    func fetchUser(id: Int) async throws -> User {
////        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
////            throw NetworkError.invalidURL
////        }
////
////        let (data, response) = try await URLSession.shared.data(from: url)
////
////        guard let httpResponse = response as? HTTPURLResponse,
////              (200...299).contains(httpResponse.statusCode) else {
////            throw NetworkError.invalidResponse
////        }
////
////        return try JSONDecoder().decode(User.self, from: data)
////    }
////
////    /// POST - Create user
////    func createUser(_ user: User) async throws -> User {
////        guard let url = URL(string: "\(baseURL)/users") else {
////            throw NetworkError.invalidURL
////        }
////
////        // 1️⃣ Create POST request
////        var request = URLRequest(url: url)
////        request.httpMethod = "POST"
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////
////        // 2️⃣ Encode body
////        request.httpBody = try JSONEncoder().encode(user)
////
////        // 3️⃣ Send request
////        let (data, response) = try await URLSession.shared.data(for: request)
////
////        guard let httpResponse = response as? HTTPURLResponse,
////              (200...299).contains(httpResponse.statusCode) else {
////            throw NetworkError.invalidResponse
////        }
////
////        return try JSONDecoder().decode(User.self, from: data)
////    }
////
////    /// PUT - Update user
////    func updateUser(_ user: User) async throws -> User {
////        guard let url = URL(string: "\(baseURL)/users/\(user.id)") else {
////            throw NetworkError.invalidURL
////        }
////
////        var request = URLRequest(url: url)
////        request.httpMethod = "PUT"
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////        request.httpBody = try JSONEncoder().encode(user)
////
////        let (data, response) = try await URLSession.shared.data(for: request)
////
////        guard let httpResponse = response as? HTTPURLResponse,
////              (200...299).contains(httpResponse.statusCode) else {
////            throw NetworkError.invalidResponse
////        }
////
////        return try JSONDecoder().decode(User.self, from: data)
////    }
////
////    /// DELETE - Delete user
////    func deleteUser(id: Int) async throws {
////        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
////            throw NetworkError.invalidURL
////        }
////
////        var request = URLRequest(url: url)
////        request.httpMethod = "DELETE"
////
////        let (_, response) = try await URLSession.shared.data(for: request)
////
////        guard let httpResponse = response as? HTTPURLResponse,
////              (200...299).contains(httpResponse.statusCode) else {
////            throw NetworkError.invalidResponse
////        }
////    }
////
////    /// Generic request method (reusable!)
////    func request<T: Decodable>(
////        endpoint: String,
////        method: HTTPMethod = .get,
////        body: Encodable? = nil
////    ) async throws -> T {
////        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
////            throw NetworkError.invalidURL
////        }
////
////        var request = URLRequest(url: url)
////        request.httpMethod = method.rawValue
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////
////        if let body = body {
////            request.httpBody = try JSONEncoder().encode(body)
////        }
////
////        let (data, response) = try await URLSession.shared.data(for: request)
////
////        guard let httpResponse = response as? HTTPURLResponse,
////              (200...299).contains(httpResponse.statusCode) else {
////            throw NetworkError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
////        }
////
////        return try JSONDecoder().decode(T.self, from: data)
////    }
////}
////
////
////// MARK: - Usage with Async/Await
////
////class URLSessionSharedDataTaskViewController: UIViewController {
////
////    override func viewDidLoad() {
////        super.viewDidLoad()
////
////        // ✅ Call async function from sync context
////        Task {
////            await loadUsers()
////            await createNewUser()
////            await fetchUserGeneric()
////        }
////    }
////
////    func loadUsers() async {
////        do {
////            // ✅ Clean, linear code - no nested closures!
////            let users = try await NetworkManager.shared.fetchUsers()
////
////            print("✅ Fetched \(users.count) users")
////
////            // Print details
////            for user in users.prefix(3) {
////                print("---")
////                print("Name: \(user.name)")
////                print("Email: \(user.email)")
////                if let city = user.address?.city {
////                    print("City: \(city)")
////                }
////            }
////
////            // ✅ Already on main actor if ViewController is @MainActor
////            // Update UI directly
////            // self.tableView.reloadData()
////
////        } catch {
////            print("❌ Error: \(error.localizedDescription)")
////            // Show error alert
////        }
////    }
////
////    func createNewUser() async {
////        let newUser = User(
////            id: 0, // Server will assign ID
////            name: "John Appleseed",
////            username: "japple",
////            email: "john@apple.com",
////            phone: "555-1234",
////            website: "apple.com",
////            address: nil,
////            company: nil
////        )
////
////        do {
////            let createdUser = try await NetworkManager.shared.createUser(newUser)
////            print("✅ Created user with ID: \(createdUser.id)")
////        } catch {
////            print("❌ Failed to create user: \(error)")
////        }
////    }
////
////    // ✅ Use generic request method
////    func fetchUserGeneric() async {
////        do {
////            let user: User = try await NetworkManager.shared.request(endpoint: "/users/1")
////            print("✅ Got user: \(user.name)")
////        } catch {
////            print("❌ Error: \(error)")
////        }
////    }
////}
//
//class NetworkManager {
//    static let shared = NetworkManager()
//
//    private let baseURL = "https://jsonplaceholder.typicode.com"
//
//    func fetchUsers() async throws -> [User] {
//        guard let url = URL(string: "\(baseURL)/users") else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        let (data,response) = try await URLSession.shared.data(from: url)
//
//        guard let response = response as? HTTPURLResponse,
//              (200...299).contains(response.statusCode) else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        guard !data.isEmpty else {
//            throw NetworkManagerError.noData
//        }
//
//        return try JSONDecoder().decode([User].self, from: data)
//    }
//
//    func fetchUser(id: Int) async throws -> User {
//        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        let (data,response) = try await URLSession.shared.data(from: url)
//
//        guard let response = response as? HTTPURLResponse,
//              (200...299).contains(response.statusCode) else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        guard !data.isEmpty else {
//            throw NetworkManagerError.noData
//        }
//
//        return try JSONDecoder().decode(User.self, from: data)
//    }
//
//    func createUser(_ user: User) async throws -> User {
//        guard let url = URL(string: "\(baseURL)/users") else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
//        do {
//            urlRequest.httpBody = try JSONEncoder().encode(user)
//        } catch {
//            throw NetworkManagerError
//                .encodingError(error: error)
//        }
//
//        let (data,response) = try await URLSession.shared.data(for: urlRequest)
//
//        guard let response = response as? HTTPURLResponse,
//              (200...299).contains(response.statusCode) else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        guard !data.isEmpty else {
//            throw NetworkManagerError.noData
//        }
//
//        return try JSONDecoder().decode(User.self, from: data)
//    }
//
//    func updateUser(_ user: User) async throws -> User {
//        guard let url = URL(string: "\(baseURL)/users/\(user.id)") else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "PUT"
//        urlRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
//
//        do {
//            urlRequest.httpBody = try JSONEncoder().encode(user)
//        } catch {
//            throw NetworkManagerError
//                .encodingError(error: error)
//        }
//
//        let (data,response) = try await URLSession.shared.data(for: urlRequest)
//
//        guard let response = response as? HTTPURLResponse,
//              (200...299).contains(response.statusCode) else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        guard !data.isEmpty else {
//            throw NetworkManagerError.noData
//        }
//
//        return try JSONDecoder().decode(User.self, from: data)
//    }
//
//    func deleteUser(id : Int) async throws {
//        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "DELETE"
//
//        let (_, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        print("User with id: \(id) DELETED")
//    }
//}
//
//
//class URLSessionSharedDataTaskViewControllerOld : UIViewController {
//
//    override func viewDidLoad(){
//        super.viewDidLoad()
//        //        NetworkManagerOld.shared.fetchUsers { results in
//        //            switch results {
//        //            case .success(let users):
//        //                print("Users count: \(users.count)")
//        //                for user in users {
//        //                    print(user.name)
//        //                }
//        //            case .failure(let error):
//        //                print("Error: \(error.localizedDescription)")
//        //            }
//        //        }
//        Task {
//            await loadUsers()
//            await loadASpecificUser(id: 1)
//            await createNewUser()
//            await deleteUser()
//        }
//
//        func loadUsers() async {
//            do {
//                let users = try await NetworkManager.shared.fetchUsers()
//                print("Users count: \(users.count)")
//                for user in users {
//                    print("----------")
//                    print(user.name)
//                    print(user.email)
//                }
//            } catch {
//                print(
//                    "Error fetching all the users. Error:\(error.localizedDescription) "
//                )
//            }
//        }
//
//        func loadASpecificUser(id: Int) async {
//            do {
//                let user = try await NetworkManager.shared.fetchUser(id: id)
//                print("--------")
//                print("Specific User asked, it's name is : \(user.name) ")
//            } catch {
//                print(
//                    "Error fetching the specific user. Error:\(error.localizedDescription) "
//                )
//            }
//        }
//
//        func createNewUser() async {
//            let user = User(
//                id: 08,
//                name: "Swapnil Dhiman",
//                username: "s0d0bla",
//                email: "swapnildhiman199@gmail.com",
//                phone: "8824348105",
//                website: "leetcode.com/swapnildhiman19",
//                address: nil,
//                company: User.Company(name: "Walmart", catchPhrase: "IDK")
//            )
//
//            do {
//                let decodedUser = try await NetworkManager.shared.createUser(user)
//                print("--------------")
//                print("User has been created successfully")
//                print(decodedUser.name)
//            } catch {
//                print(
//                    "Error creating a new user: \(error.localizedDescription)"
//                )
//            }
//        }
//
//        func deleteUser() async {
//            do {
//                try await NetworkManager.shared.deleteUser(id: 1)
//            } catch {
//                print("Error Deleting User : \(error.localizedDescription)")
//            }
//        }
//    }
//}
//
//import Combine
//
//// MARK: - Combine Network Manager
//
////class CombineNetworkManager {
////
////    static let shared = CombineNetworkManager()
////    private init() {}
////
////    private let baseURL = "https://jsonplaceholder.typicode.com"
////
////    /// Fetch users using Combine publisher
////    /// - Returns: Publisher that emits [User] or Error
////    func fetchUsers() -> AnyPublisher<[User], Error> {
////        guard let url = URL(string: "\(baseURL)/users") else {
////            return Fail(error: NetworkManagerError.invalidURL)
////                .eraseToAnyPublisher()
////        }
////
////        return URLSession.shared.dataTaskPublisher(for: url)
////            // ✅ Switch to background thread
////            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
////            // ✅ Validate response
////            .tryMap { data, response in
////                guard let httpResponse = response as? HTTPURLResponse,
////                      (200...299).contains(httpResponse.statusCode) else {
////                    throw NetworkManagerError.invalidResponse
////                }
////                return data
////            }
////            // ✅ Decode JSON
////            .decode(type: [User].self, decoder: JSONDecoder())
////            // ✅ Receive on main thread (for UI updates)
////            .receive(on: DispatchQueue.main)
////            // ✅ Type erase to AnyPublisher
////            .eraseToAnyPublisher()
////    }
////
////    /// Fetch single user
////    func fetchUser(id: Int) -> AnyPublisher<User, Error> {
////        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
////            return Fail(error: NetworkManagerError.invalidURL)
////                .eraseToAnyPublisher()
////        }
////
////        return URLSession.shared.dataTaskPublisher(for: url)
////            .tryMap { data, response in
////                guard let httpResponse = response as? HTTPURLResponse,
////                      (200...299).contains(httpResponse.statusCode) else {
////                    throw NetworkManagerError.invalidResponse
////                }
////                return data
////            }
////            .decode(type: User.self, decoder: JSONDecoder())
////            .receive(on: DispatchQueue.main)
////            .eraseToAnyPublisher()
////    }
////
////    /// Generic request with Combine
////    func request<T: Decodable>(
////        endpoint: String,
////        method: HTTPMethod = .get,
////        body: Encodable? = nil
////    ) -> AnyPublisher<T, Error> {
////        guard let url = URL(string: "\(baseURL)\(endpoint)") else {
////            return Fail(error: NetworkManagerError.invalidURL)
////                .eraseToAnyPublisher()
////        }
////
////        var request = URLRequest(url: url)
////        request.httpMethod = method.rawValue
////        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
////
////        if let body = body {
////            do {
////                request.httpBody = try JSONEncoder().encode(body)
////            } catch {
////                return Fail(error: error).eraseToAnyPublisher()
////            }
////        }
////
////        return URLSession.shared.dataTaskPublisher(for: request)
////            .tryMap { data, response in
////                guard let httpResponse = response as? HTTPURLResponse,
////                      (200...299).contains(httpResponse.statusCode) else {
////                    throw NetworkManagerError.invalidResponse
////                }
////                return data
////            }
////            .decode(type: T.self, decoder: JSONDecoder())
////            .receive(on: DispatchQueue.main)
////            .eraseToAnyPublisher()
////    }
////}
//
//class CombineNetworkManager {
//    static let shared = CombineNetworkManager()
//
//    let baseURL = "https://jsonplaceholder.typicode.com"
//
//    func fetchUsers() -> AnyPublisher<[User],Error> {
//        guard let url = URL(string: "\(baseURL)/users") else {
//            return Fail(error: NetworkManagerError.invalidURL)
//                .eraseToAnyPublisher()
//        }
//        return URLSession.shared.dataTaskPublisher(for: url)
//        //listening on background thread
//            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
//            .tryMap { data,response in
//                guard let httpResponse = response as? HTTPURLResponse,
//                      (200...299).contains(httpResponse.statusCode) else {
//                    throw NetworkManagerError.invalidResponse
//                }
//                return data
//            }
//            .decode(type: [User].self, decoder: JSONDecoder())
//            .receive(on: DispatchQueue.main)
//            .eraseToAnyPublisher()
//    }
//
//    func fetchSpecificUser(id: Int) -> AnyPublisher<User, Error> {
//        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
//            return Fail(error: NetworkManagerError.invalidURL)
//                .eraseToAnyPublisher()
//        }
//        return URLSession.shared.dataTaskPublisher(for: url)
//            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
//            .tryMap { data,response in
//                guard let httpResponse = response as? HTTPURLResponse,
//                      (200...299).contains(httpResponse.statusCode) else {
//                    throw NetworkManagerError.invalidResponse
//                }
//                return data
//            }
//            .receive(on: DispatchQueue.main)
//            .decode(type: User.self, decoder: JSONDecoder())
//            .eraseToAnyPublisher()
//    }
//
//    func createNewUser(_ user : User) -> AnyPublisher<User,Error> {
//        guard let url = URL(string:"\(baseURL)/users") else {
//            return Fail(error: NetworkManagerError.invalidURL)
//                .eraseToAnyPublisher()
//        }
//
//        var urlRequest = URLRequest(url: url)
//        urlRequest.httpMethod = "POST"
//        urlRequest.setValue("application/JSON", forHTTPHeaderField: "Content-Type")
//        do {
//            urlRequest.httpBody = try JSONEncoder().encode(user)
//        } catch {
//            return Fail(error: NetworkManagerError.encodingError(error: error))
//                .eraseToAnyPublisher()
//        }
//        return URLSession.shared.dataTaskPublisher(for: urlRequest)
//            .subscribe(on: DispatchQueue.global(qos: .userInitiated))
//            .tryMap { data, response in
//                guard let httpResponse = response as? HTTPURLResponse,
//                      (200...299).contains(httpResponse.statusCode)
//                else {
//                    throw NetworkManagerError.invalidURL
//                }
//                return data
//            }
//            .receive(on: DispatchQueue.main)
//            .decode(type: User.self, decoder: JSONDecoder())
//            .eraseToAnyPublisher()
//    }
//}
//enum HTTPMethod: String {
//    case get = "GET"
//    case post = "POST"
//    case put = "PUT"
//    case delete = "DELETE"
//    case patch = "PATCH"
//}
//
//// MARK: - Usage with Combine
//
////class URLSessionSharedDataTaskViewController: UIViewController {
////
////    // ✅ Store subscriptions (prevents deallocation)
////    private var cancellables = Set<AnyCancellable>()
////
////    private let searchTextField: UITextField = {
////        let textField = UITextField()
////        textField.placeholder = "Search users..."
////        textField.borderStyle = .roundedRect
////        textField.translatesAutoresizingMaskIntoConstraints = false
////        return textField
////    }()
////
////    override func viewDidLoad() {
////        super.viewDidLoad()
////
////        setupUI()
////
////        loadUsers()
////
////
////        // --- CHANGES START HERE ---
////        // 1. Pass the retained searchTextField instance
////        setupSearch(searchTextField: searchTextField)
////    }
////
////    private func setupUI() {
////        view.backgroundColor = .white
////        view.addSubview(searchTextField)
////
////        NSLayoutConstraint.activate([
////            searchTextField.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
////            searchTextField.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
////            searchTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
////            searchTextField.heightAnchor.constraint(equalToConstant: 40)
////        ])
////    }
////
////    func loadUsers() {
////        CombineNetworkManager.shared.fetchUsers()
////            .sink(
////                receiveCompletion: { completion in
////                    // ✅ Handle completion (success or failure)
////                    switch completion {
////                    case .finished:
////                        print("✅ Request completed successfully")
////                    case .failure(let error):
////                        print("❌ Error: \(error.localizedDescription)")
////                    }
////                },
////                receiveValue: { users in
////                    // ✅ Handle received data
////                    print("📥 Received \(users.count) users")
////
////                    // Already on main thread - safe to update UI
////                    // self.tableView.reloadData()
////                }
////            )
////            .store(in: &cancellables) // ✅ Keep subscription alive
////    }
////
////    // ✅ Chain multiple requests
////    func loadUserDetails() {
////        CombineNetworkManager.shared.fetchUsers()
////            // Get first user
////            .compactMap { $0.first }
////            // Fetch full details for that user
////            .flatMap { user in
////                CombineNetworkManager.shared.fetchUser(id: user.id)
////            }
////            .sink(
////                receiveCompletion: { _ in },
////                receiveValue: { user in
////                    print("✅ Got detailed user: \(user.name)")
////                }
////            )
////            .store(in: &cancellables)
////    }
////
////    // ✅ Search with debounce (wait for typing to stop)
////    func setupSearch(searchTextField: UITextField) {
////        NotificationCenter.default.publisher(for: UITextField.textDidChangeNotification, object: searchTextField)
////            .compactMap { ($0.object as? UITextField)?.text }
////            .debounce(for: .milliseconds(300), scheduler: DispatchQueue.main)
////            .removeDuplicates()
////            .flatMap { query -> AnyPublisher<[User], Error> in
////                guard !query.isEmpty else {
////                    return Just([])
////                        .setFailureType(to: Error.self)
////                        .eraseToAnyPublisher()
////                }
////                return CombineNetworkManager.shared.fetchUsers()
////                    .map { users in
////                        users.filter { $0.name.localizedCaseInsensitiveContains(query) }
////                    }
////                    .eraseToAnyPublisher()
////            }
////            .sink(
////                receiveCompletion: { _ in },
////                receiveValue: { filteredUsers in
////                    print("🔍 Found \(filteredUsers.count) users")
////                    // Update UI with filtered results
////                }
////            )
////            .store(in: &cancellables)
////    }
////}
//
//class URLSessionSharedDataTaskViewController: UIViewController {
//
//    var cancellable = Set<AnyCancellable>()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        fetchUsersUsingCombine()
//        fetchSpecificUserUsingCombine(id: 02)
//        createUser()
//    }
//
//    private func fetchUsersUsingCombine(){
//        CombineNetworkManager.shared.fetchUsers()
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .finished:
//                        print("Request has successfully been finished")
//                    case .failure(let error):
//                        print(
//                            "Failed with the error : \(error.localizedDescription)"
//                        )
//                    }
//                },
//                receiveValue: { users in
//                    for user in users {
//                        print("======")
//                        print(user.name)
//                    }
//                }
//            )
//            .store(in: &cancellable)
//    }
//
//    private func fetchSpecificUserUsingCombine(id: Int) {
//        CombineNetworkManager.shared.fetchSpecificUser(id: id)
//            .sink(
//                receiveCompletion: { completion in
//                    switch completion {
//                    case .failure(let error):
//                        print("Failed to fetch information of user id \(id), because of \(error.localizedDescription) " )
//                    case .finished:
//                        print("Successfully fetched information of user id \(id)")
//                    }
//                }, receiveValue: { data in
//                    print("========Enquiry about user \(id)==========")
//                    print(data)
//                })
//            .store(in: &cancellable)
//    }
//
//    private func createUser() {
//        let newUser = User(
//            id: 0, // Server will assign ID
//            name: "John Appleseed",
//            username: "japple",
//            email: "john@apple.com",
//            phone: "555-12341231",
//            website: "apple.com",
//            address: nil,
//            company: nil
//        )
//
//        CombineNetworkManager.shared.createNewUser(newUser)
//            .sink(
//                receiveCompletion: {
//                    completion in
//                    switch completion {
//                    case .finished:
//                        print("\(newUser.name) has successfully been created")
//                    case .failure(let error):
//                        print(
//                            "Failed to create \(newUser.name), with the error : \(error.localizedDescription)"
//                        )
//                    }
//                },
//                receiveValue: { data in
//                    print("Newly user created data")
//                    print(data)
//                }
//            )
//            .store(in: &cancellable)
//    }
//}
//
//class DownloadManager {
//    static let shared = DownloadManager()
//    private init() {}
//
//    func downloadFile(
//        from urlString: String,
//        completionHandler: @escaping (Result<URL,Error>)->Void
//    ) {
//        guard let url = URL(string: urlString) else {
//            completionHandler(.failure(NetworkManagerError.invalidURL))
//            return
//        }
//        let task = URLSession.shared.downloadTask(
//            with: URLRequest(url: url)) {
//                localUrl,
//                response,
//                error in
//                if let error = error {
//                    completionHandler(.failure(error))
//                    return
//                }
//                guard let httpResponse = response as? HTTPURLResponse,
//                      (200...299).contains(httpResponse.statusCode) else {
//                    completionHandler(
//                        .failure(NetworkManagerError.invalidResponse)
//                    )
//                    return
//                }
//
//                guard let localUrl = localUrl else {
//                    completionHandler(.failure(NetworkManagerError.noData))
//                    return
//                }
//
//                //Move the localURL to permanent location from where we can download this file
//                let documentsPath = FileManager.default.urls(
//                    for: .documentDirectory,
//                    in: .userDomainMask
//                )[0]
//                let destinationPath = documentsPath.appendingPathComponent(
//                    url.lastPathComponent
//                )
//
//                do {
//                    if FileManager.default
//                        .fileExists(atPath: destinationPath.path()){
//                        try FileManager.default.removeItem(at: destinationPath)
//                    }
//                    try FileManager.default
//                        .moveItem(at: localUrl, to: destinationPath)
//                    completionHandler(.success(destinationPath))
//                } catch {
//                    completionHandler(.failure(error))
//                }
//            }.resume()
//    }
//
//    func downloadFile(from urlString: String) async throws -> URL {
//        guard let url = URL(string: urlString) else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        let (localUrl, response) = try await URLSession.shared.download(
//            from: url
//        )
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkManagerError
//                .httpError(
//                    statusCode: (response as? HTTPURLResponse)?.statusCode
//                    ?? 0)
//        }
//
//        let documentPath = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask
//        )[0]
//
//        let destinationURL = documentPath.appendingPathComponent(
//            url.lastPathComponent
//        )
//
//        do {
//            if FileManager.default.fileExists(atPath: destinationURL.path()) {
//                try FileManager.default.removeItem(at: destinationURL)
//            }
//            try FileManager.default.moveItem(at: localUrl, to: destinationURL)
//        } catch {
//            throw error
//        }
//        return destinationURL
//    }
//
//    func downloadWithProgress(
//        from urlString: String,
//        progressHandler: @escaping (Double)->Void,
//        completionHandler: @escaping (Result<URL,Error>)->Void
//    ) {
//        guard let url = URL(string: urlString) else {
//            completionHandler(.failure(NetworkManagerError.invalidURL))
//            return
//        }
//
//        let configuration = URLSessionConfiguration.default
//        let session = URLSession(
//            configuration: configuration,
//            delegate: DownloadDelegate(
//                progressHandler: progressHandler,
//                completion: completionHandler
//            ),
//            delegateQueue: nil
//        )
//        let task = session.downloadTask(with: url)
//        task.resume()
//    }
//}
//
//class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
//
//    let progressHandler: (Double)->Void
//    let completionHandler : (Result<URL,Error>)->Void
//
//    init(progressHandler: @escaping (Double) -> Void, completion: @escaping (Result<URL, Error>) -> Void) {
//        self.progressHandler = progressHandler
//        self.completionHandler = completion
//    }
//
//    func urlSession(
//        _ session: URLSession,
//        downloadTask: URLSessionDownloadTask,
//        didFinishDownloadingTo location: URL
//    ) {
//
//        let documentsPath = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask
//        )[0]
//
//        let destinationURL = documentsPath.appendingPathComponent(
//            downloadTask.originalRequest?.url?.lastPathComponent ?? "download"
//        )
//
//        do {
//            if FileManager.default.fileExists(atPath: destinationURL.path) {
//                try FileManager.default.removeItem(at: destinationURL)
//            }
//            try FileManager.default.moveItem(at: location, to: destinationURL)
//
//            DispatchQueue.main.async {
//                self.completionHandler(.success(destinationURL))
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.completionHandler(.failure(error))
//            }
//        }
//    }
//
//    // ✅ Handle errors
//    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
//        if let error = error {
//            DispatchQueue.main.async {
//                self.completionHandler(.failure(error))
//            }
//        }
//    }
//
//    //For progress
//    func urlSession(
//        _ session: URLSession,
//        downloadTask: URLSessionDownloadTask,
//        didWriteData bytesWritten: Int64,
//        totalBytesWritten: Int64,
//        totalBytesExpectedToWrite: Int64
//    ) {
//        let progress = Double(totalBytesWritten)/Double(totalBytesExpectedToWrite)
//        DispatchQueue.main.async {
//            self.progressHandler(progress)
//        }
//    }
//}
//
//// MARK: - Auth Manager
//
//class AuthManager {
//    static let shared = AuthManager()
//    private init() {}
//
//    // Store tokens securely in Keychain (production)
//    private var accessToken: String?
//    private var refreshToken: String?
//
//    // 1️⃣ Basic Authentication (Username/Password)
//    func login(username: String, password: String) async throws -> AuthResponse {
//        let endpoint = "https://your-api.com/auth/login"
//        guard let url = URL(string: endpoint) else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let credentials = LoginRequest(username: username, password: password)
//        request.httpBody = try JSONEncoder().encode(credentials)
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
//
//        // ✅ Store tokens
//        self.accessToken = authResponse.accessToken
//        self.refreshToken = authResponse.refreshToken
//
//        return authResponse
//    }
//
//    // 2️⃣ Authenticated Request (with Bearer token)
//    func authenticatedRequest<T: Decodable>(
//        endpoint: String,
//        method: HTTPMethod = .get
//    ) async throws -> T {
//        guard let token = accessToken else {
//            throw AuthError.notAuthenticated
//        }
//
//        guard let url = URL(string: endpoint) else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = method.rawValue
//
//        // ✅ Add Bearer token
//        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse else {
//            throw NetworkManagerError.invalidResponse
//        }
//
//        // ✅ Handle 401 Unauthorized - refresh token
//        if httpResponse.statusCode == 401 {
//            try await refreshAccessToken()
//            // Retry request with new token
//            return try await authenticatedRequest(endpoint: endpoint, method: method)
//        }
//
//        guard (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkManagerError.httpError(statusCode: httpResponse.statusCode)
//        }
//
//        return try JSONDecoder().decode(T.self, from: data)
//    }
//
//    // 3️⃣ Refresh Token
//    private func refreshAccessToken() async throws {
//        guard let refreshToken = refreshToken else {
//            throw AuthError.noRefreshToken
//        }
//
//        let endpoint = "https://your-api.com/auth/refresh"
//        guard let url = URL(string: endpoint) else {
//            throw NetworkManagerError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        let refreshRequest = RefreshTokenRequest(refreshToken: refreshToken)
//        request.httpBody = try JSONEncoder().encode(refreshRequest)
//
//        let (data, response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw AuthError.refreshFailed
//        }
//
//        let authResponse = try JSONDecoder().decode(AuthResponse.self, from: data)
//
//        // ✅ Update tokens
//        self.accessToken = authResponse.accessToken
//        if let newRefreshToken = authResponse.refreshToken {
//            self.refreshToken = newRefreshToken
//        }
//    }
//
//    // 4️⃣ Logout
//    func logout() {
//        accessToken = nil
//        refreshToken = nil
//        // Clear keychain in production
//    }
//}
//
//// MARK: - Auth Models
//
//struct LoginRequest: Encodable {
//    let username: String
//    let password: String
//}
//
//struct AuthResponse: Decodable {
//    let accessToken: String
//    let refreshToken: String?
//    let expiresIn: Int?
//    let tokenType: String?
//}
//
//struct RefreshTokenRequest: Encodable {
//    let refreshToken: String
//}
//
//enum AuthError: LocalizedError {
//    case notAuthenticated
//    case noRefreshToken
//    case refreshFailed
//
//    var errorDescription: String? {
//        switch self {
//        case .notAuthenticated:
//            return "User not authenticated"
//        case .noRefreshToken:
//            return "No refresh token available"
//        case .refreshFailed:
//            return "Failed to refresh access token"
//        }
//    }
//}
