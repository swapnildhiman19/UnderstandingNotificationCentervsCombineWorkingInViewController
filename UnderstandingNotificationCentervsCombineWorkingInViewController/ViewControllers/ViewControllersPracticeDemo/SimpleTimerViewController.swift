//
//  SimpleTimerViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

class SimpleTimerViewController: UIViewController {

    // MARK: - Properties

    private var timer: Timer?
    private var progress: Float = 0.0
    private let totalSeconds: Float = 10.0  // 10 second timer

    // MARK: - UI Elements

    private let progressView = UIProgressView(progressViewStyle: .default)
    private let percentLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - Timer Control

    @objc private func startTimer() {
        // Don't start if already running
        guard timer == nil else {
            print("⚠️ Timer already running!")
            return
        }

        print("▶️ Timer started!")
        startButton.isEnabled = false

        // Create timer that fires every 0.1 seconds
        timer = Timer.scheduledTimer(
            timeInterval: 0.1,          // Fire every 0.1 seconds
            target: self,
            selector: #selector(updateProgress),
            userInfo: nil,
            repeats: true               // Keep firing until invalidated
        )
    }

    @objc private func updateProgress() {
        // Increase progress
        progress += 0.1 / totalSeconds  // 0.1 second / 10 seconds = 0.01

        // Update UI
        progressView.setProgress(progress, animated: true)
        percentLabel.text = "\(Int(progress * 100))%"

        print("📊 Progress: \(Int(progress * 100))%")

        // Check if complete
        if progress >= 1.0 {
            stopTimer()
            print("✅ Complete!")
            showAlert(title: "Done!", message: "Timer finished")
        }
    }

    private func stopTimer() {
        timer?.invalidate()  // Stop the timer
        timer = nil          // Release it
        startButton.isEnabled = true
    }

    @objc private func resetTimer() {
        stopTimer()
        progress = 0.0
        progressView.setProgress(0, animated: true)
        percentLabel.text = "0%"
        print("🔄 Reset!")
    }

    // MARK: - UI Setup

    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Simple Timer"

        // Progress View
        progressView.progressTintColor = .systemBlue
        progressView.trackTintColor = .systemGray5
        progressView.layer.cornerRadius = 4
        progressView.clipsToBounds = true
        progressView.transform = CGAffineTransform(scaleX: 1, y: 3)  // Thicker

        // Percent Label
        percentLabel.text = "0%"
        percentLabel.font = .systemFont(ofSize: 48, weight: .bold)
        percentLabel.textAlignment = .center

        // Start Button
        startButton.setTitle("Start Timer", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        startButton.backgroundColor = .systemGreen
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.addTarget(self, action: #selector(startTimer), for: .touchUpInside)

        // Reset Button
        resetButton.setTitle("Reset", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .semibold)
        resetButton.backgroundColor = .systemRed
        resetButton.setTitleColor(.white, for: .normal)
        resetButton.layer.cornerRadius = 10
        resetButton.addTarget(self, action: #selector(resetTimer), for: .touchUpInside)

        // Layout
        let stackView = UIStackView(arrangedSubviews: [
            percentLabel, progressView, startButton, resetButton
        ])
        stackView.axis = .vertical
        stackView.spacing = 30
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 40),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -40),
            startButton.heightAnchor.constraint(equalToConstant: 50),
            resetButton.heightAnchor.constraint(equalToConstant: 50)
        ])
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    // MARK: - Cleanup (Important!)

    deinit {
        timer?.invalidate()
        print("🗑️ ViewController deallocated, timer invalidated")
    }
}
