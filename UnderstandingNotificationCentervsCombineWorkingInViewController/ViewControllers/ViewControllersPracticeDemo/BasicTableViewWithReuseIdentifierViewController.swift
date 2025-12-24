//
//  BasicTableViewWithReuseIdentifierViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 18/11/25.
//

import Foundation
import UIKit

class BasicTableViewWithReuseIdentifierCell : UITableViewCell {
    static let reuseIdentifier = "BasicTableViewWithReuseIdentifierCell"

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        textLabel?.text = nil
        imageView?.image = nil
    }

    func configure(with text: String) {
        textLabel?.text = text
    }
}


class BasicTableViewWithReuseIdentifierViewController : UITableViewController {
    let tasks : [String] = ["Task 1", "Task 2", "Task 3", "Task 4", "Task 5", "Task 6", "Task 7", "Task 8", "Task 9", "Task 10"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(BasicTableViewWithReuseIdentifierCell.self, forCellReuseIdentifier: BasicTableViewWithReuseIdentifierCell.reuseIdentifier)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tasks.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: BasicTableViewWithReuseIdentifierCell.reuseIdentifier, for: indexPath) as? BasicTableViewWithReuseIdentifierCell {
            cell.textLabel?.text = tasks[indexPath.row]
            return cell
        }
        return UITableViewCell()
    }
}
