////
////  MVVMArchitectureUnderstandingViewController.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 14/12/25.
////
//
////Data: // ✅ Model: Plain data structure
//// - No UI logic
//// - No business logic
//// - Just data
//
//import Foundation
//
//struct User : Codable, Identifiable, Equatable {
//    let id : Int
//    let name : String
//    let email : String
//    let phone : String?
//
//    var initials : String {
//        let parts =  name.split(separator: " ")
//        let firstInitial = parts.first?.prefix(1) ?? ""
//        let lastInitial = parts.dropFirst().first?.prefix(1) ?? ""
//        return "\(firstInitial)\(lastInitial)".uppercased()
//    }
//}
//
//enum UserError: LocalizedError {
//    case invalidURL
//    case invalidResponse
//    case httpError(statusCode: Int)
//    case decodingError(error: Error)
//    case encodingError(error: Error)
//    case noData
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
//// Service Layer : Data Source
//// Can be implemented using SingleTon but better to have it implemented using protocol , can easily test it later
//
////Functionalities
//protocol UserServiceProtocol {
//    func fetchUsers() async throws -> [User]
//    func fetchUser(id : Int) async throws -> User
//    func createUser(_ user: User) async throws -> User
//    func deleteUser(id: Int) async throws
//}
//
//final class UserService : UserServiceProtocol {
//   
//    let baseURL = "https://jsonplaceholder.typicode.com"
//
//    func fetchUsers() async throws -> [User] {
//        guard let url = URL(string: "\(baseURL)/users") else {
//            throw UserError.invalidURL
//        }
//        let (data,response) = try await URLSession.shared.data(from: url)
//        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
//            throw UserError.invalidResponse
//        }
//        if data.isEmpty {
//            throw UserError.noData
//        }
//        return try JSONDecoder().decode([User].self, from: data)
//    }
//
//    func fetchUser(id: Int) async throws -> User {
//        guard let url = URL(string: "\(baseURL)/users/\(id)") else {
//            throw UserError.invalidURL
//        }
//
//        let (data,response) = try await URLSession.shared.data(from: url)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode)
//        else {
//            throw UserError.invalidResponse
//        }
//
//        if data.isEmpty {
//            throw UserError.noData
//        }
//
//        return try JSONDecoder().decode(User.self, from: data)
//    }
//
//    func createUser(_ user: User) async throws -> User {
//        // Here we will be using encoder to encode the User into data along with PUT method
//        guard let url = URL(string: "\(baseURL)/users") else {
//            throw UserError.invalidURL
//        }
//
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
//
//        //Encoding
//        request.httpBody = try JSONEncoder().encode(user)
//
//        //Sending the request
//        let (data,response) = try await URLSession.shared.data(for: request)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw UserError.invalidResponse
//        }
//
//        if data.isEmpty {
//            throw UserError.noData
//        }
//
//        return try JSONDecoder().decode(User.self, from: data)
//    }
//
//    func deleteUser(id: Int) async throws {
//        //Implementation can be made here
//    }
//}
//
////Benefit of using Protocol here comes for testing
//
//final class MockUserService : UserServiceProtocol {
//    var usersToReturn : [User] = []
//    var errorToThrow : UserError?
//
//    func fetchUsers() async throws -> [User] {
//        if let error = errorToThrow {
//            throw error
//        }
//        return usersToReturn
//    }
//
//    func fetchUser(id: Int) async throws -> User {
//        if let error = errorToThrow { throw error }
//        guard let user = usersToReturn.first(where: {
//            $0.id == id
//        }) else {
//            throw UserError.noData
//        }
//        return user
//    }
//
//    func createUser(_ user: User) async throws -> User {
//        user
//    }
//
//    func deleteUser(id: Int) async throws {
//        //
//    }
//}
//
////ViewModel Business Logic : Brain  Model/DataSource <-> ViewModel <-> View/ViewController
//import Combine
//final class UserViewModel: ObservableObject {
//
//    @Published private(set) var users: [User] = []
//    @Published private(set) var isLoading: Bool = false
//    @Published private(set) var errorMessage: String?
//    @Published var searchText = ""
//
//    var filteredUsers: [User] {
//        if searchText.isEmpty { return users }
//        return users.filter {
//            $0.name.localizedCaseInsensitiveContains(searchText) ||
//            $0.email.localizedCaseInsensitiveContains(searchText)
//        }
//    }
//
//    var userCount: String {
//        "\(filteredUsers.count) users"
//    }
//
//    private let userService : UserServiceProtocol
//
//    init(userService: UserServiceProtocol = UserService()){
//        self.userService = userService
//    }
//
//    @MainActor
//    func loadUsers() async {
//        isLoading = true
//        errorMessage = nil
//
//        do {
//            users = try await userService.fetchUsers()
//        } catch {
//            errorMessage = (error as? UserError)?.errorDescription ?? "Failed to fetch users"
//        }
//
//        isLoading = false
//    }
//
//    @MainActor
//    func deleteUser(_ user : User) async {
//        do {
//            try await userService.deleteUser(id: user.id)
//            users.removeAll { $0.id == user.id}
//        } catch {
//            errorMessage = "Failed to delete user"
//        }
//    }
//
//    @MainActor
//    func refreshData() async {
//        await loadUsers()
//    }
//
//    func clearError() {
//        errorMessage = nil
//    }
//}
//
////View
//
//import UIKit
//
//final class UserCell: UITableViewCell {
//    static let reuseId = "UserCell"
//
//    //initials, initialContainer, nameLabel, emailLabel, phoneLabel,textStackView
//    private lazy var initialsLabel : UILabel = {
//        //font, textColor, translatesAutoResizingMaskIntoConstraints
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 16, weight: .bold)
//        label.translatesAutoresizingMaskIntoConstraints = false // Use the constraints which I will give to you
//        label.textColor = .white
//        label.textAlignment = .center
//        return label
//    }()
//
//    private lazy var initialsContainer: UIView = {
//        let view = UIView()
//        view.backgroundColor = .systemBlue
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.layer.cornerRadius = 20
//        return view
//    }()
//
//    private lazy var nameLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 16, weight: .semibold)
//        label.translatesAutoresizingMaskIntoConstraints = false // Use the constraints which I will give to you
//        label.textColor = .label
//        return label
//    }()
//
//    private lazy var emailLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 14, weight: .semibold)
//        label.translatesAutoresizingMaskIntoConstraints = false // Use the constraints which I will give to you
//        label.textColor = .secondaryLabel
//        return label
//    }()
//
//    private lazy var phoneLabel: UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 12, weight: .semibold)
//        label.translatesAutoresizingMaskIntoConstraints = false // Use the constraints which I will give to you
//        label.textColor = .tertiaryLabel
//        return label
//    }()
//
//    private lazy var textStackView: UIStackView = {
//        let stack = UIStackView(
//            arrangedSubviews: [nameLabel,emailLabel,phoneLabel]
//        )
//        stack.axis = .vertical
//        stack.spacing = 4
//        stack.translatesAutoresizingMaskIntoConstraints = false
//        return stack
//    }()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        setupUI()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder) has not been implemented")
//    }
//
//    private func setupUI(){
//        contentView.addSubview(initialsContainer)
//        initialsContainer.addSubview(initialsLabel)
//        contentView.addSubview(textStackView)
//
//        NSLayoutConstraint.activate([
//            initialsContainer.leadingAnchor
//                .constraint(equalTo: contentView.leadingAnchor, constant: 16),
//            initialsContainer.centerYAnchor
//                .constraint(equalTo: contentView.centerYAnchor),
//            initialsContainer.widthAnchor.constraint(equalToConstant: 40),
//            initialsContainer.heightAnchor.constraint(equalToConstant: 40),
//
//            initialsLabel.centerXAnchor
//                .constraint(equalTo: initialsContainer.centerXAnchor),
//            initialsLabel.centerYAnchor
//                .constraint(equalTo: initialsContainer.centerYAnchor),
//
//            textStackView.leadingAnchor.constraint(equalTo: initialsContainer.trailingAnchor, constant: 12),
//            textStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
//            textStackView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
//        ])
//    }
//
//    func configure(with user: User) {
//        initialsLabel.text = user.initials
//        nameLabel.text = user.name
//        emailLabel.text = user.email
//        phoneLabel.text = user.phone ?? "No phone"
//
//        let colors : [UIColor] = [.red,.green,.blue,.yellow,.brown]
//        initialsContainer.backgroundColor = colors[user.id % colors.count]
//    }
//}
//
//final class MVVMArchitectureUnderstandingViewController: UIViewController {
//
//    var userViewModel = UserViewModel()
//
//    private var cancellables = Set<AnyCancellable>()
//
//    private lazy var tableView : UITableView = {
//        let tableView = UITableView()
//        tableView
//            .register(UserCell.self, forCellReuseIdentifier: UserCell.reuseId)
//        tableView.dataSource = self
//        tableView.delegate = self
//        tableView.refreshControl = refreshControl
//        tableView.rowHeight = 72
//        tableView.translatesAutoresizingMaskIntoConstraints = false
//        return tableView
//    }()
//
//    private lazy var refreshControl : UIRefreshControl = {
//        let refreshControl = UIRefreshControl()
//        refreshControl
//            .addTarget(
//                self,
//                action: #selector(didPullToRefresh),
//                for: .valueChanged
//            )
//        return refreshControl
//    }()
//
//    private lazy var searchBar : UISearchBar = {
//        let search = UISearchBar()
//        search.delegate = self
//        search.placeholder = "Search users by name or email..."
//        search.searchBarStyle = .minimal
//        return search
//    }()
//
//    private lazy var loadingIndicator: UIActivityIndicatorView = {
//        let indicatorView = UIActivityIndicatorView(style: .large)
//        indicatorView.hidesWhenStopped = true
//        indicatorView.translatesAutoresizingMaskIntoConstraints = false
//        return indicatorView
//    }()
//
//    private lazy var errorView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .systemBackground
//        view.isHidden = true
//        view.translatesAutoresizingMaskIntoConstraints = false
//        return view
//    }()
//
//    private lazy var errorLabel: UILabel = {
//        let label = UILabel()
//        label.textColor = .systemRed
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        label.font = .systemFont(ofSize: 16)
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private lazy var retryButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Retry", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
//        button
//            .addTarget(
//                self,
//                action: #selector(didTapRetry),
//                for: .touchUpInside
//            )
//        button.translatesAutoresizingMaskIntoConstraints = false
//        return button
//    }()
//
//    private lazy var emptyStateLabel: UILabel = {
//        let label = UILabel()
//        label.text = "No users found"
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.isHidden = true
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    private lazy var userCountLabel : UILabel = {
//        let label = UILabel()
//        label.font = .systemFont(ofSize: 12)
//        label.textColor = .secondaryLabel
//        label.translatesAutoresizingMaskIntoConstraints = false
//        return label
//    }()
//
//    override func viewDidLoad(){
//        super.viewDidLoad()
//        setupUI()
//        bindViewModel()
//        loadData()
//    }
//
//    private func setupUI() {
//        title = "Users"
//        view.backgroundColor = .systemBackground
//
//        navigationItem.titleView = searchBar
//        navigationController?.navigationBar.prefersLargeTitles = true
//
//        view.addSubview(tableView)
//        view.addSubview(loadingIndicator)
//        view.addSubview(errorView)
//        view.addSubview(emptyStateLabel)
//        view.addSubview(userCountLabel)
//
//        errorView.addSubview(errorLabel)
//        errorView.addSubview(retryButton)
//
//        setLayoutConstraints()
//    }
//
//    private func setLayoutConstraints(){
//        NSLayoutConstraint.activate([
//            //Table View Constraints
//            tableView.topAnchor
//                .constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            tableView.bottomAnchor
//                .constraint(equalTo: userCountLabel.topAnchor, constant: -10),
//
//            // User Count Label (bottom bar)
//            userCountLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
//            userCountLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
//
//            // Loading Indicator (center)
//            loadingIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            loadingIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//
//            // Error View (center)
//            errorView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            errorView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
//            errorView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
//            errorView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
//
//            errorLabel.topAnchor.constraint(equalTo: errorView.topAnchor),
//            errorLabel.leadingAnchor.constraint(equalTo: errorView.leadingAnchor),
//            errorLabel.trailingAnchor.constraint(equalTo: errorView.trailingAnchor),
//
//            retryButton.topAnchor.constraint(equalTo: errorLabel.bottomAnchor, constant: 16),
//            retryButton.centerXAnchor.constraint(equalTo: errorView.centerXAnchor),
//            retryButton.bottomAnchor.constraint(equalTo: errorView.bottomAnchor),
//
//            // Empty State Label (center)
//            emptyStateLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
//            emptyStateLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
//        ])
//    }
//
//    private func bindViewModel(){
//        userViewModel.$users
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.tableView.reloadData()
//                self?.updateEmptyState()
//            }.store(in: &cancellables)
//
//        userViewModel.$isLoading
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] isLoading in
//                if isLoading {
//                    self?.loadingIndicator.startAnimating()
//                    self?.tableView.isHidden = true
//                    self?.errorView.isHidden = true
//                    self?.emptyStateLabel.isHidden = true
//                } else {
//                    self?.loadingIndicator.stopAnimating()
//                    self?.refreshControl.endRefreshing()
//                    self?.tableView.isHidden = false
//                }
//            }.store(in: &cancellables)
//
//        userViewModel.$errorMessage
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] errorMessage in
//                if let errorMessage = errorMessage {
//                    self?.showError(errorMessage)
//                } else {
//                    self?.errorView.isHidden = true
//                }
//            }.store(in: &cancellables)
//
//        userViewModel.$searchText
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] _ in
//                self?.tableView.reloadData()
//                self?.updateUserCount()
//                self?.updateEmptyState()
//            }.store(in: &cancellables)
//    }
//
//    //Helper Methods
//    private func loadData() {
//        Task {
//            await userViewModel.loadUsers()
//            updateUserCount()
//        }
//    }
//
//    @objc func didTapRetry(){
//        userViewModel.clearError()
//        loadData()
//    }
//
//    @objc func didPullToRefresh() {
//        Task {
//            await userViewModel.refreshData()
//            updateUserCount()
//        }
//    }
//
//    private func updateEmptyState(){
//        let isEmpty = userViewModel.filteredUsers.isEmpty && !userViewModel.isLoading && userViewModel.errorMessage == nil
//        emptyStateLabel.isHidden = !isEmpty
//
//        if !userViewModel.searchText.isEmpty && isEmpty {
//            emptyStateLabel.text = "No users match \(userViewModel.searchText)"
//        } else {
//            emptyStateLabel.text = "No users found"
//        }
//    }
//
//    private func updateUserCount(){
//        userCountLabel.text = userViewModel.userCount
//    }
//
//    private func showError(_ errorMessage: String){
//        errorLabel.text = errorMessage
//        errorView.isHidden = false
//        tableView.isHidden = true
//        emptyStateLabel.isHidden = true
//    }
//}
//
//extension MVVMArchitectureUnderstandingViewController : UISearchBarDelegate {
//    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
//        userViewModel.searchText = searchText
//    }
//
//    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.resignFirstResponder()
//    }
//
//    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
//        searchBar.text = ""
//        userViewModel.searchText = ""
//        searchBar.resignFirstResponder()
//    }
//}
//
//extension MVVMArchitectureUnderstandingViewController: UITableViewDelegate {
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//
//        let user = userViewModel.filteredUsers[indexPath.row]
//        showUserDetail(user)
//    }
//
//    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
////        let user = userViewModel.filteredUsers[indexPath.row]
////
////        // Delete action
////        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
////            self?.confirmDelete(user: user, completion: completion)
////        }
////        deleteAction.image = UIImage(systemName: "trash")
////
////        return UISwipeActionsConfiguration(actions: [deleteAction])
//        let user = userViewModel.filteredUsers[indexPath.row]
//        let deleteAction = UIContextualAction(
//            style: .destructive,
//            title: "Delete") { [weak self] _, _, completion in
//                self?.confirmDelete(user: user, completion: completion)
//            }
//        deleteAction.image = UIImage(systemName: "trash")
//        return UISwipeActionsConfiguration(actions:[deleteAction])
//    }
//
//    private func showUserDetail(_ user: User) {
//        let alert = UIAlertController(
//            title: user.name,
//            message: """
//            📧 Email: \(user.email)
//            📱 Phone: \(user.phone ?? "N/A")
//            🆔 ID: \(user.id)
//            """,
//            preferredStyle: .alert
//        )
//        alert.addAction(UIAlertAction(title: "OK", style: .default))
//        present(alert, animated: true)
//    }
//
//    private func confirmDelete(user: User, completion: @escaping (Bool) -> Void) {
//        let alert = UIAlertController(
//            title: "Delete User",
//            message: "Are you sure you want to delete \(user.name)?",
//            preferredStyle: .alert
//        )
//
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
//            completion(false)
//        })
//
//        alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
//            Task {
//                await self?.userViewModel.deleteUser(user)
//                self?.updateUserCount()
//                completion(true)
//            }
//        })
//
//        present(alert, animated: true)
//    }
//}
//
//extension MVVMArchitectureUnderstandingViewController: UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return userViewModel.filteredUsers.count
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(
//            withIdentifier: UserCell.reuseId,
//            for: indexPath
//        ) as? UserCell else {
//            return UITableViewCell()
//        }
//
//        let user = userViewModel.filteredUsers[indexPath.row]
//        cell.configure(with: user)
//        return cell
//    }
//}
////
////import XCTest
////
////final class UserViewModelTests: XCTestCase {
////    var sut: UserViewModel!
////    var mockService : MockUserService!
////
////    override func setUp(){
////        super.setUp()
////        mockService = MockUserService()
////        sut = UserViewModel(userService: mockService)
////    }
////
////    override func tearDown(){
////        sut = nil
////        mockService = nil
////        super.tearDown()
////    }
////
////    func testLoadUsers_Sucess() async {
////        let expectedUsers = [
////            User(id: 1, name: "Swapnil Dhiman", email: "s0d0bla@walmart.com", phone: "123123"),
////            User(id: 1, name: "Swapniliiiiii Dhiman", email: "s0d0bla@walmart.com", phone: "123123")
////        ]
////        mockService.usersToReturn = expectedUsers
////        await sut.loadUsers()
////
////        XCTAssertEqual(sut.users.count, 2)
////        XCTAssertNil(sut.errorMessage)
////    }
////}
//
//
//
