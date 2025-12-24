//
//  ScrollBoundsViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 15/12/25.
//

import UIKit

class ScrollBoundsViewController: UIViewController {

    let scrollView = UIScrollView()
    let infoLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        setupScrollView()
        setupInfoLabel()
        updateInfo()
    }

    func setupScrollView() {
        // The VISIBLE WINDOW (300 x 400)
        scrollView.frame = CGRect(x: 20, y: 120, width: 300, height: 400)
        scrollView.backgroundColor = .systemGray6
        scrollView.delegate = self
        view.addSubview(scrollView)

        // The TOTAL CONTENT (300 x 1000) - Much taller!
        scrollView.contentSize = CGSize(width: 300, height: 1000)

        // Add visible items
        let colors: [UIColor] = [.systemRed, .systemOrange, .systemYellow,
                                  .systemGreen, .systemBlue, .systemIndigo,
                                  .systemPurple, .systemPink, .systemTeal, .systemBrown]

        for i in 0..<10 {
            let itemView = UIView()
            itemView.frame = CGRect(x: 10, y: i * 100, width: 280, height: 90)
            itemView.backgroundColor = colors[i].withAlphaComponent(0.5)
            itemView.layer.cornerRadius = 10
            scrollView.addSubview(itemView)

            let label = UILabel()
            label.text = "Item \(i + 1) (y: \(i * 100) to \(i * 100 + 90))"
            label.font = .systemFont(ofSize: 16, weight: .medium)
            label.frame = CGRect(x: 15, y: 30, width: 250, height: 30)
            itemView.addSubview(label)
        }
    }

    func setupInfoLabel() {
        infoLabel.frame = CGRect(x: 20, y: 540, width: 300, height: 200)
        infoLabel.numberOfLines = 0
        infoLabel.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        infoLabel.backgroundColor = .systemGray6
        view.addSubview(infoLabel)
    }

    func updateInfo() {
        let frame = scrollView.frame
        let bounds = scrollView.bounds
        let contentOffset = scrollView.contentOffset

        infoLabel.text = """
        📐 FRAME (position on screen):
           \(frame)
        
        👁 BOUNDS (viewport into content):
           \(bounds)
        
        📍 CONTENT OFFSET:
           \(contentOffset)
        
        💡 bounds.origin == contentOffset
           \(bounds.origin == contentOffset ? "✅ TRUE!" : "❌ FALSE")
        
        🎯 Visible range: y=\(Int(bounds.origin.y)) to y=\(Int(bounds.origin.y + bounds.height))
        """
    }
}

extension ScrollBoundsViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateInfo()  // Update info as user scrolls!
    }
}
