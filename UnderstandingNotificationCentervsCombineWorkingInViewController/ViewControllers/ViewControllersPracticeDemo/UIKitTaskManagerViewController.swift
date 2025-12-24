////
////  UIKitTaskManager.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 18/11/25.
////
//
//// COMPLETE UIKit APP - Task Manager
//
import UIKit

// MARK: - Model
struct Task {
    let id = UUID()
    var title: String
    var isCompleted: Bool
    var priority: Priority

    enum Priority: String, CaseIterable {
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: UIColor {
            switch self {
            case .low: return .systemGreen
            case .medium: return .systemOrange
            case .high: return .systemRed
            }
        }
    }
}

// MARK: - Custom Table View Cell
class TaskCell: UITableViewCell {
    static let reuseIdentifier = "TaskCell"

    let checkmarkButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let priorityView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        // Checkmark button
        checkmarkButton.setImage(UIImage(systemName: "circle"), for: .normal)
        checkmarkButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .selected)
        checkmarkButton.isUserInteractionEnabled = false

        // Title label
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.numberOfLines = 0

        // Priority indicator
        priorityView.layer.cornerRadius = 4

        // Add subviews
        contentView.addSubview(checkmarkButton)
        contentView.addSubview(titleLabel)
        contentView.addSubview(priorityView)

        // Setup constraints
        checkmarkButton.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        priorityView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            checkmarkButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            checkmarkButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            checkmarkButton.widthAnchor.constraint(equalToConstant: 24),
            checkmarkButton.heightAnchor.constraint(equalToConstant: 24),

            titleLabel.leadingAnchor.constraint(equalTo: checkmarkButton.trailingAnchor, constant: 12),
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: priorityView.leadingAnchor, constant: -12),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12),

            priorityView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            priorityView.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            priorityView.widthAnchor.constraint(equalToConstant: 8),
            priorityView.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func configure(with task: Task) {
        titleLabel.text = task.title
        checkmarkButton.isSelected = task.isCompleted
        priorityView.backgroundColor = task.priority.color

        if task.isCompleted {
            titleLabel.textColor = .systemGray
            titleLabel.attributedText = NSAttributedString(
                string: task.title,
                attributes: [.strikethroughStyle: NSUnderlineStyle.single.rawValue]
            )
        } else {
            titleLabel.textColor = .label
            titleLabel.attributedText = NSAttributedString(string: task.title)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        checkmarkButton.isSelected = false
        titleLabel.text = nil
        priorityView.backgroundColor = nil
    }
}

// MARK: - Main View Controller
class TaskListViewController: UITableViewController {

    var tasks: [Task] = [
        Task(title: "Buy groceries", isCompleted: false, priority: .high),
        Task(title: "Walk the dog", isCompleted: true, priority: .medium),
        Task(title: "Finish project", isCompleted: false, priority: .high),
        Task(title: "Call mom", isCompleted: false, priority: .low),
        Task(title: "Read book", isCompleted: true, priority: .low)
    ]

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()
        setupTableView()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Setup
    func setupUI() {
        title = "My Tasks"
        view.backgroundColor = .systemBackground

        // Navigation bar buttons
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addTaskTapped)
        )

        navigationItem.leftBarButtonItem = editButtonItem
    }

    func setupTableView() {
        tableView.register(TaskCell.self, forCellReuseIdentifier: TaskCell.reuseIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    func setupGestures() {
        // Add pull to refresh
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(handleRefresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }

    // MARK: - Actions
    @objc func addTaskTapped() {
        let alertController = UIAlertController(
            title: "New Task",
            message: "Enter task details",
            preferredStyle: .alert
        )

        alertController.addTextField { textField in
            textField.placeholder = "Task title"
        }

        let priorities = Task.Priority.allCases
        let priorityAction = UIAlertAction(title: "Priority: Medium", style: .default) { _ in
            // Would show priority picker
        }

        let addAction = UIAlertAction(title: "Add", style: .default) { [weak self] _ in
            guard let title = alertController.textFields?.first?.text, !title.isEmpty else {
                return
            }

            let newTask = Task(title: title, isCompleted: false, priority: .medium)
            self?.tasks.insert(newTask, at: 0)
            self?.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        }

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)

        alertController.addAction(addAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true)
    }

    @objc func handleRefresh() {
        // Simulate network request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.tableView.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table View Data Source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCell.reuseIdentifier,
            for: indexPath
        ) as! TaskCell

        cell.configure(with: tasks[indexPath.row])
        return cell
    }

    // MARK: - Table View Delegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Toggle completion
        tasks[indexPath.row].isCompleted.toggle()
        tableView.reloadRows(at: [indexPath], with: .automatic)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    override func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let movedTask = tasks.remove(at: sourceIndexPath.row)
        tasks.insert(movedTask, at: destinationIndexPath.row)
    }

    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completionHandler in
            self?.tasks.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }

        let completeAction = UIContextualAction(style: .normal, title: "Complete") { [weak self] _, _, completionHandler in
            self?.tasks[indexPath.row].isCompleted.toggle()
            tableView.reloadRows(at: [indexPath], with: .automatic)
            completionHandler(true)
        }
        completeAction.backgroundColor = .systemGreen

        return UISwipeActionsConfiguration(actions: [deleteAction, completeAction])
    }
}
//
////// MARK: - App Delegate Setup
////@main
////class AppDelegate: UIResponder, UIApplicationDelegate {
////    var window: UIWindow?
////
////    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
////
////        window = UIWindow(frame: UIScreen.main.bounds)
////
////        let taskListVC = TaskListViewController(style: .plain)
////        let navigationController = UINavigationController(rootViewController: taskListVC)
////        navigationController.navigationBar.prefersLargeTitles = true
////
////        window?.rootViewController = navigationController
////        window?.makeKeyAndVisible()
////
////        return true
////    }
////}
