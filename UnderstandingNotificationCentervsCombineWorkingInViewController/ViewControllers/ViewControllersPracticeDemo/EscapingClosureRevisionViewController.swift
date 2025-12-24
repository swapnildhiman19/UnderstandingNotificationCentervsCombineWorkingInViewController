//
//  EscapingClosureRevisionViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 16/12/25.
//

import Foundation
import UIKit

struct UserEscaping : Codable, Identifiable {
    let id : Int
    let name : String
    let email : String
}

enum UserEscapingNetworkError : Error {
    case invalidURL
    case noData
    case invalidResponse
    case decodingDataError(error: Error)
    case encodingDataError(error: Error)
    case serverError(String)
}

final class UserEscapingService {

    static let shared = UserEscapingService()

    private let baseURL = "https://jsonplaceholder.typicode.com"

    func fetchUser(
        id: Int,
        completionHandler: @escaping (
            (Result<UserEscaping,UserEscapingNetworkError>) -> Void?
        )
    ){
        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
            completionHandler(.failure(UserEscapingNetworkError.invalidURL))
            return
        }

        let task = URLSession.shared.dataTask(with: url) {
            data,
            response,
            error in
            if let error = error {
                completionHandler(
                    .failure(.serverError(error.localizedDescription))
                )
                return
            }

            guard let httpsResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpsResponse.statusCode) else {
                completionHandler(.failure(.invalidResponse))
                return
            }

            guard let data = data else {
                completionHandler(.failure(.noData))
                return
            }

            do {
                let user = try JSONDecoder().decode(
                    UserEscaping.self,
                    from: data
                )
                completionHandler(.success(user))
            } catch {
                completionHandler(.failure(.decodingDataError(error: error)))
            }
        }

        task.resume()
    }
}

class UserEscapingViewController : UIViewController {
    let userEscapingService = UserEscapingService.shared
    let nameLabel = UILabel()
    let emailLabel = UILabel()
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        loadUser()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        let stack = UIStackView(arrangedSubviews: [nameLabel,emailLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stack.centerYAnchor
                .constraint(equalTo: view.centerYAnchor)
        ])
    }
    
    private func loadUser() {
        userEscapingService.fetchUser(id: 1) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let user):
                    self?.nameLabel.text = user.name
                    self?.emailLabel.text = user.email
                case .failure(let error):
                    self?.nameLabel.text = "error"
                    self?.emailLabel.text = error.localizedDescription
                }
            }
        }
    }
}
