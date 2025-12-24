//
//  FrameBoundsViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 15/12/25.
//

import UIKit

class FrameBoundsViewController: UIViewController {

    let parentView = UIView()
    let childView = UIView()
    let grandchildView = UIView()
    let infoLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        printFrameAndBounds()
    }

    func setupViews() {
        view.backgroundColor = .systemBackground

        // Parent View (Blue)
        parentView.frame = CGRect(x: 50, y: 100, width: 300, height: 300)
        parentView.backgroundColor = .systemBlue.withAlphaComponent(0.3)
        parentView.layer.borderWidth = 2
        parentView.layer.borderColor = UIColor.systemBlue.cgColor
        view.addSubview(parentView)

        // Child View (Green)
        childView.frame = CGRect(x: 50, y: 50, width: 150, height: 150)
        childView.backgroundColor = .systemGreen.withAlphaComponent(0.3)
        childView.layer.borderWidth = 2
        childView.layer.borderColor = UIColor.systemGreen.cgColor
        parentView.addSubview(childView)

        // Grandchild View (Red)
        grandchildView.frame = CGRect(x: 25, y: 25, width: 50, height: 50)
        grandchildView.backgroundColor = .systemRed.withAlphaComponent(0.5)
        childView.addSubview(grandchildView)

        // Info Label
        infoLabel.numberOfLines = 0
        infoLabel.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        infoLabel.frame = CGRect(x: 20, y: 450, width: view.bounds.width - 40, height: 300)
        view.addSubview(infoLabel)

        // Add labels
        addLabel(to: parentView, text: "Parent", color: .systemBlue)
        addLabel(to: childView, text: "Child", color: .systemGreen)
        addLabel(to: grandchildView, text: "Grandchild", color: .systemRed)
    }

    func addLabel(to view: UIView, text: String, color: UIColor) {
        let label = UILabel()
        label.text = text
        label.font = .systemFont(ofSize: 10, weight: .bold)
        label.textColor = color
        label.sizeToFit()
        label.frame.origin = CGPoint(x: 5, y: 5)
        view.addSubview(label)
    }

    func printFrameAndBounds() {
        var info = ""

        info += "📦 PARENT VIEW:\n"
        info += "   Frame:  \(parentView.frame)\n"
        info += "   Bounds: \(parentView.bounds)\n\n"

        info += "📦 CHILD VIEW:\n"
        info += "   Frame:  \(childView.frame)\n"
        info += "   Bounds: \(childView.bounds)\n\n"

        info += "📦 GRANDCHILD VIEW:\n"
        info += "   Frame:  \(grandchildView.frame)\n"
        info += "   Bounds: \(grandchildView.bounds)\n"

        infoLabel.text = info
        print(info)
    }
}

// Output:
// 📦 PARENT VIEW:
//    Frame:  (50.0, 100.0, 300.0, 300.0)  ← Position in main view
//    Bounds: (0.0, 0.0, 300.0, 300.0)     ← Own coordinate system
//
// 📦 CHILD VIEW:
//    Frame:  (50.0, 50.0, 150.0, 150.0)   ← Position in PARENT
//    Bounds: (0.0, 0.0, 150.0, 150.0)     ← Own coordinate system
//
// 📦 GRANDCHILD VIEW:
//    Frame:  (25.0, 25.0, 50.0, 50.0)     ← Position in CHILD
//    Bounds: (0.0, 0.0, 50.0, 50.0)       ← Own coordinate system
