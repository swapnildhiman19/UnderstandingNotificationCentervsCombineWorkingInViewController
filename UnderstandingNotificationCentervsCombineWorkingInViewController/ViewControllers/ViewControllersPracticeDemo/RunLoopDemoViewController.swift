//
//  RunLoopDemoViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

class RunLoopDemoViewController: UIViewController {

    // MARK: - UI
    private let scrollView = UIScrollView()
    private let contentView = UIView()

    // Two progress views - one for each timer type
    private let defaultProgressView = UIProgressView()
    private let commonProgressView = UIProgressView()

    private let defaultLabel = UILabel()
    private let commonLabel = UILabel()
    private let instructionLabel = UILabel()

    // MARK: - Timers
    private var defaultTimer: Timer?
    private var commonTimer: Timer?

    private var defaultProgress: Float = 0.0
    private var commonProgress: Float = 0.0

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "RunLoop Modes Demo"

        setupUI()
        startTimers()
    }

    private func startTimers() {
        // TIMER 1: Default mode (WILL PAUSE during scroll!)
        defaultTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            self?.updateDefaultProgress()
        }
        // ⚠️ This timer uses .default mode (pauses during scroll)


        // TIMER 2: Common mode (WON'T pause during scroll!)
        commonTimer = Timer.scheduledTimer(
            withTimeInterval: 0.1,
            repeats: true
        ) { [weak self] _ in
            self?.updateCommonProgress()
        }
        // ✅ Add to .common runloop mode
        RunLoop.current.add(commonTimer!, forMode: .common)
    }

    private func updateDefaultProgress() {
        defaultProgress += 0.005
        if defaultProgress > 1.0 { defaultProgress = 0.0 }

        defaultProgressView.progress = defaultProgress
        defaultLabel.text = String(format: "Default Timer: %.0f%%", defaultProgress * 100)
    }

    private func updateCommonProgress() {
        commonProgress += 0.005
        if commonProgress > 1.0 { commonProgress = 0.0 }

        commonProgressView.progress = commonProgress
        commonLabel.text = String(format: "Common Timer: %.0f%%", commonProgress * 100)
    }

    // MARK: - UI Setup

    private func setupUI() {
        // Scroll View (to demonstrate the difference)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        // Instructions
        instructionLabel.text = """
        👆 SCROLL THIS VIEW UP AND DOWN!
        
        Watch what happens to each timer:
        • Default Timer will PAUSE
        • Common Timer keeps going!
        """
        instructionLabel.numberOfLines = 0
        instructionLabel.textAlignment = .center
        instructionLabel.font = .systemFont(ofSize: 16)
        instructionLabel.textColor = .secondaryLabel

        // Default Timer UI (Red - will pause)
        defaultLabel.text = "Default Timer: 0%"
        defaultLabel.font = .systemFont(ofSize: 18, weight: .bold)
        defaultLabel.textColor = .systemRed

        defaultProgressView.progressTintColor = .systemRed
        defaultProgressView.trackTintColor = .systemRed.withAlphaComponent(0.2)
        defaultProgressView.transform = CGAffineTransform(scaleX: 1.0, y: 4.0)

        let defaultWarning = UILabel()
        defaultWarning.text = "⚠️ Uses .default mode - PAUSES when scrolling!"
        defaultWarning.font = .systemFont(ofSize: 12)
        defaultWarning.textColor = .systemRed

        // Common Timer UI (Green - won't pause)
        commonLabel.text = "Common Timer: 0%"
        commonLabel.font = .systemFont(ofSize: 18, weight: .bold)
        commonLabel.textColor = .systemGreen

        commonProgressView.progressTintColor = .systemGreen
        commonProgressView.trackTintColor = .systemGreen.withAlphaComponent(0.2)
        commonProgressView.transform = CGAffineTransform(scaleX: 1.0, y: 4.0)

        let commonInfo = UILabel()
        commonInfo.text = "✅ Uses .common mode - KEEPS RUNNING when scrolling!"
        commonInfo.font = .systemFont(ofSize: 12)
        commonInfo.textColor = .systemGreen

        // Scrollable content (to make it scroll)
        var scrollableContent: [UIView] = []
        for i in 1...30 {
            let label = UILabel()
            label.text = "Scroll item #\(i) - Keep scrolling to see the difference!"
            label.textColor = .secondaryLabel
            scrollableContent.append(label)
        }

        // Stack everything
        let mainStack = UIStackView(arrangedSubviews: [
            instructionLabel,
            createSpacer(height: 20),
            defaultLabel,
            defaultProgressView,
            defaultWarning,
            createSpacer(height: 30),
            commonLabel,
            commonProgressView,
            commonInfo,
            createSpacer(height: 40)
        ] + scrollableContent)

        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.alignment = .fill
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(mainStack)

        // Constraints
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),

            mainStack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -20),
            mainStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }

    private func createSpacer(height: CGFloat) -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: height).isActive = true
        return view
    }

    deinit {
        defaultTimer?.invalidate()
        commonTimer?.invalidate()
    }
}
