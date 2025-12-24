//
//  GestureViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 18/11/25.
//


import UIKit

class GestureViewController: UIViewController {
    let tapBox = UIView()
    let swipeBox = UIView()
    let pinchBox = UIView()
    let longPressBox = UIView()
    let panBox = UIView()
    
    let statusLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        setupViews()
        setupGestures()
    }
    
    func setupViews() {
        // Create colored boxes
        tapBox.backgroundColor = .systemBlue
        swipeBox.backgroundColor = .systemGreen
        pinchBox.backgroundColor = .systemOrange
        longPressBox.backgroundColor = .systemPurple
        panBox.backgroundColor = .systemPink
        
        let boxes = [tapBox, swipeBox, pinchBox, longPressBox, panBox]
        let labels = ["TAP", "SWIPE", "PINCH", "LONG PRESS", "PAN"]
        
        for (index, box) in boxes.enumerated() {
            box.frame = CGRect(x: 50, y: 150 + (index * 100), width: 300, height: 80)
            box.layer.cornerRadius = 12
            
            let label = UILabel(frame: box.bounds)
            label.text = labels[index]
            label.textAlignment = .center
            label.textColor = .white
            label.font = .boldSystemFont(ofSize: 18)
            box.addSubview(label)
            
            view.addSubview(box)
        }
        
        statusLabel.frame = CGRect(x: 20, y: 80, width: view.bounds.width - 40, height: 40)
        statusLabel.textAlignment = .center
        statusLabel.font = .systemFont(ofSize: 16, weight: .medium)
        view.addSubview(statusLabel)
    }
    
    func setupGestures() {
        // 1️⃣ TAP GESTURE
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1  // Single tap
        tapGesture.numberOfTouchesRequired = 1  // One finger
        tapBox.addGestureRecognizer(tapGesture)
        
        // ⚠️ Must enable user interaction!
        tapBox.isUserInteractionEnabled = true
        
        // 2️⃣ SWIPE GESTURE
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeGesture.direction = .right  // Swipe right
        swipeBox.addGestureRecognizer(swipeGesture)
        swipeBox.isUserInteractionEnabled = true
        
        // You can add multiple swipe gestures for different directions
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        swipeBox.addGestureRecognizer(swipeLeft)
        
        // 3️⃣ PINCH GESTURE
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchBox.addGestureRecognizer(pinchGesture)
        pinchBox.isUserInteractionEnabled = true
        
        // 4️⃣ LONG PRESS GESTURE
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0  // 1 second
        longPressBox.addGestureRecognizer(longPressGesture)
        longPressBox.isUserInteractionEnabled = true
        
        // 5️⃣ PAN GESTURE (drag)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panBox.addGestureRecognizer(panGesture)
        panBox.isUserInteractionEnabled = true
    }
    
    // GESTURE HANDLERS
    
    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        statusLabel.text = "👆 Tapped!"
        
        // Animate the box
        UIView.animate(withDuration: 0.1, animations: {
            sender.view?.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                sender.view?.transform = .identity
            }
        }
    }
    
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        statusLabel.text = "👉 Swiped \(sender.direction == .right ? "Right" : "Left")!"
        
        // Animate slide
        UIView.animate(withDuration: 0.3) {
            let offset: CGFloat = sender.direction == .right ? 50 : -50
            sender.view?.transform = CGAffineTransform(translationX: offset, y: 0)
        } completion: { _ in
            UIView.animate(withDuration: 0.3) {
                sender.view?.transform = .identity
            }
        }
    }
    
    @objc func handlePinch(_ sender: UIPinchGestureRecognizer) {
        guard let view = sender.view else { return }
        
        switch sender.state {
        case .began, .changed:
            statusLabel.text = "🤏 Pinching: \(String(format: "%.2f", sender.scale))x"
            // Scale the view
            view.transform = CGAffineTransform(scaleX: sender.scale, y: sender.scale)
            
        case .ended:
            statusLabel.text = "🤏 Pinch ended"
            // Reset
            UIView.animate(withDuration: 0.3) {
                view.transform = .identity
            }
            
        default:
            break
        }
    }
    
    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        switch sender.state {
        case .began:
            statusLabel.text = "⏱️ Long Press Started!"
            UIView.animate(withDuration: 0.2) {
                sender.view?.backgroundColor = .systemRed
            }
            
        case .ended:
            statusLabel.text = "⏱️ Long Press Ended!"
            UIView.animate(withDuration: 0.2) {
                sender.view?.backgroundColor = .systemPurple
            }
            
        default:
            break
        }
    }
    
    @objc func handlePan(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        
        // Get translation (how much finger moved)
        let translation = sender.translation(in: self.view)
        
        switch sender.state {
        case .began:
            statusLabel.text = "✋ Pan Started"
            
        case .changed:
            // Move the view
            view.center = CGPoint(
                x: view.center.x + translation.x,
                y: view.center.y + translation.y
            )
            // Reset translation (so it doesn't accumulate)
            sender.setTranslation(.zero, in: self.view)
            
            statusLabel.text = "✋ Panning..."
            
        case .ended:
            // Get velocity (speed of drag)
            let velocity = sender.velocity(in: self.view)
            statusLabel.text = "✋ Pan Ended (velocity: \(Int(velocity.x)))"
            
        default:
            break
        }
    }
}


class BindableTapGestureRecognizer: UITapGestureRecognizer {
    private var action: () -> Void

    init(action: @escaping () -> Void) {
        self.action = action
        super.init(target: nil, action: nil)
        addTarget(self, action: #selector(handleTap))
    }

    @objc func handleTap() {
        guard state == .ended else { return }
        action()
    }
}

// USAGE:
//let box = UIView()
//let tap = BindableTapGestureRecognizer { [weak self] in
//    print("Box tapped!")
//    self?.handleBoxTap()
//}
//box.addGestureRecognizer(tap)
