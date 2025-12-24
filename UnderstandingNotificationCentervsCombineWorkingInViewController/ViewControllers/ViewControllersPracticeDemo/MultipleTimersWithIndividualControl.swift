//
//  MultipleTimersWithIndividualControl.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 17/12/25.
//

import UIKit

class MultipleTimersViewController: UIViewController {

    // MARK: - Timer Data Model

    struct TimerItem {
        var timer: Timer?
        var progress: Float = 0.0
        var isRunning: Bool = false
        let duration: TimeInterval  // Total duration in seconds
        let color: UIColor
        let name: String
    }

    // MARK: - Properties

    private var timers: [TimerItem] = []
    private var timerViews: [TimerRowView] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "Multiple Timers"

        // Create 3 different timers
        timers = [
            TimerItem(duration: 5, color: .systemRed, name: "Fast (5s)"),
            TimerItem(duration: 10, color: .systemBlue, name: "Medium (10s)"),
            TimerItem(duration: 15, color: .systemGreen, name: "Slow (15s)")
        ]

        setupUI()
    }

    // MARK: - Timer Control

    private func startTimer(at index: Int) {
        guard index < timers.count else { return }

        // If already running, do nothing
        if timers[index].isRunning { return }

        // Stop any existing timer (but DON'T reset progress!)
        timers[index].timer?.invalidate()

        // DON'T reset progress here! Keep the current value
        // timers[index].progress = 0.0  // ❌ REMOVED!

        timers[index].isRunning = true

        let duration = timers[index].duration
        let increment = Float(0.1 / duration)  // Progress per tick

        // Create timer - continues from current progress
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] t in
            guard let self = self else { return }

            self.timers[index].progress += increment

            if self.timers[index].progress >= 1.0 {
                self.timers[index].progress = 1.0
                self.timers[index].isRunning = false
                t.invalidate()
                self.timers[index].timer = nil
                print("✅ Timer \(index + 1) completed!")
            }

            // Update UI
            self.timerViews[index].updateProgress(self.timers[index].progress)
        }

        // Add to common mode so it works during scroll
        RunLoop.current.add(timer, forMode: .common)

        timers[index].timer = timer
        timerViews[index].setRunning(true)

        // Log whether starting fresh or resuming
        if timers[index].progress == 0 {
            print("▶️ Timer \(index + 1) started from beginning")
        } else {
            print("▶️ Timer \(index + 1) resumed from \(Int(timers[index].progress * 100))%")
        }
    }

    private func pauseTimer(at index: Int) {
        guard index < timers.count else { return }

        timers[index].timer?.invalidate()
        timers[index].timer = nil
        timers[index].isRunning = false
        timerViews[index].setRunning(false)

        print("⏸️ Timer \(index + 1) paused at \(Int(timers[index].progress * 100))%")
    }

    private func resetTimer(at index: Int) {
        guard index < timers.count else { return }

        timers[index].timer?.invalidate()
        timers[index].timer = nil
        timers[index].progress = 0.0  // ✅ Reset only happens here!
        timers[index].isRunning = false
        timerViews[index].updateProgress(0.0)
        timerViews[index].setRunning(false)

        print("🔄 Timer \(index + 1) reset")
    }

    // MARK: - Start/Stop All

    @objc private func startAll() {
        for i in 0..<timers.count {
            // Only start if not already running
            if !timers[i].isRunning {
                startTimer(at: i)
            }
        }
    }

    @objc private func stopAll() {
        for i in 0..<timers.count {
            pauseTimer(at: i)
        }
    }

    @objc private func resetAll() {
        for i in 0..<timers.count {
            resetTimer(at: i)
        }
    }
    // MARK: - UI Setup

    private func setupUI() {
        // Create timer views
        for (index, item) in timers.enumerated() {
            let timerView = TimerRowView(
                name: item.name,
                color: item.color,
                onStart: { [weak self] in self?.startTimer(at: index) },
                onPause: { [weak self] in self?.pauseTimer(at: index) },
                onReset: { [weak self] in self?.resetTimer(at: index) }
            )
            timerViews.append(timerView)
        }

        // Control all buttons
        let startAllBtn = createButton(title: "▶️ Start All", color: .systemGreen)
        startAllBtn.addTarget(self, action: #selector(startAll), for: .touchUpInside)

        let stopAllBtn = createButton(title: "⏸️ Pause All", color: .systemOrange)
        stopAllBtn.addTarget(self, action: #selector(stopAll), for: .touchUpInside)

        let resetAllBtn = createButton(title: "🔄 Reset All", color: .systemRed)
        resetAllBtn.addTarget(self, action: #selector(resetAll), for: .touchUpInside)

        let controlStack = UIStackView(arrangedSubviews: [startAllBtn, stopAllBtn, resetAllBtn])
        controlStack.distribution = .fillEqually
        controlStack.spacing = 10

        // Main stack
        let mainStack = UIStackView(arrangedSubviews: timerViews + [controlStack])
        mainStack.axis = .vertical
        mainStack.spacing = 20
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func createButton(title: String, color: UIColor) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.backgroundColor = color.withAlphaComponent(0.2)
        button.setTitleColor(color, for: .normal)
        button.layer.cornerRadius = 8
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    deinit {
        for timer in timers {
            timer.timer?.invalidate()
        }
    }
}

// MARK: - Timer Row View

class TimerRowView: UIView {

    private let nameLabel = UILabel()
    private let progressView = UIProgressView()
    private let percentLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let resetButton = UIButton(type: .system)

    private var onStart: (() -> Void)?
    private var onPause: (() -> Void)?
    private var onReset: (() -> Void)?

    private var isRunning = false

    init(name: String, color: UIColor, onStart: @escaping () -> Void, onPause: @escaping () -> Void, onReset: @escaping () -> Void) {
        super.init(frame: .zero)

        self.onStart = onStart
        self.onPause = onPause
        self.onReset = onReset

        // Name
        nameLabel.text = name
        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
        nameLabel.textColor = color

        // Progress
        progressView.progressTintColor = color
        progressView.trackTintColor = color.withAlphaComponent(0.2)
        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 3.0)

        // Percent
        percentLabel.text = "0%"
        percentLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
        percentLabel.textAlignment = .right
        percentLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true

        // Buttons
        startButton.setTitle("▶️", for: .normal)
        startButton.titleLabel?.font = .systemFont(ofSize: 24)
        startButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)

        resetButton.setTitle("🔄", for: .normal)
        resetButton.titleLabel?.font = .systemFont(ofSize: 24)
        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)

        // Layout
        let progressStack = UIStackView(arrangedSubviews: [progressView, percentLabel])
        progressStack.spacing = 10
        progressStack.alignment = .center

        let buttonStack = UIStackView(arrangedSubviews: [startButton, resetButton])
        buttonStack.spacing = 10

        let mainStack = UIStackView(arrangedSubviews: [nameLabel, progressStack, buttonStack])
        mainStack.axis = .vertical
        mainStack.spacing = 8
        mainStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(mainStack)

        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        // Styling
        backgroundColor = color.withAlphaComponent(0.05)
        layer.cornerRadius = 12
        layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func startPauseTapped() {
        if isRunning {
            onPause?()
        } else {
            onStart?()
        }
    }

    @objc private func resetTapped() {
        onReset?()
    }

    func updateProgress(_ progress: Float) {
        progressView.progress = progress
        percentLabel.text = String(format: "%.0f%%", progress * 100)
    }

    func setRunning(_ running: Bool) {
        isRunning = running
        startButton.setTitle(running ? "⏸️" : "▶️", for: .normal)
    }
}

//class MultipleTimersViewController: UIViewController {
//    struct TimerItem {
//        var timer : Timer?
//        var progress : Float = 0.0
//        var isRunning: Bool = false
//        let duration : TimeInterval
//        let color : UIColor
//        let name : String
//    }
//
//    private var timers : [TimerItem] = []
//    private var timerViews : [TimerRowView] = []
//
//    override func viewDidLoad() {
//        title = "Multiple Timers"
//
//        timers = [
//            TimerItem(duration: 5, color: .red, name: "Fast (5s)"),
//            TimerItem(duration: 10, color: .blue, name: "Medium (10s)"),
//            TimerItem(duration: 15, color: .green, name: "Slow (15s)")
//        ]
//
//        setupUI()
//    }
//
//    private func startTimer(at index: Int) {
//        guard index < timers.count else { return }
//
//        timers[index].timer?.invalidate()
//        timers[index].progress = 0.0
//
//        let duration = timers[index].duration
//        let increment = Float(0.1/duration)
//
//        let timer = Timer.scheduledTimer(
//            withTimeInterval: 0.1,
//            repeats: true) { [weak self] t in
//                guard let self = self else { return }
//
//                self.timers[index].progress += increment
//
//                if self.timers[index].progress >= 1.0 {
//                    t.invalidate()
//                    self.timers[index].progress = 1.0
//                    self.timers[index].isRunning = false
//                }
//
//                self.timerViews[index]
//                    .updateProgress(self.timers[index].progress)
//            }
//
//        RunLoop.current.add(timer, forMode: .common)
//
//        self.timers[index].timer = timer
//        self.timerViews[index].setRunning(true)
//    }
//
//    private func pauseTimer(at index: Int) {
//        timers[index].timer?.invalidate()
//        timers[index].timer = nil
//        timers[index].isRunning = false
//        timerViews[index].setRunning(false)
//    }
//
//    private func resetTimer(at index: Int) {
//        timers[index].timer?.invalidate()
//        timers[index].timer = nil
//        timers[index].progress = 0.0
//        timers[index].isRunning = false
//        timerViews[index].setRunning(false)
//        timerViews[index].updateProgress(0.0)
//    }
//
//
//    @objc private func startAll() {
//        for i in 0..<timers.count {
//            startTimer(at: i)
//        }
//    }
//
//    @objc private func stopAll() {
//        for i in 0..<timers.count {
//            pauseTimer(at: i)
//        }
//    }
//
//    @objc private func resetAll() {
//        for i in 0..<timers.count {
//            resetTimer(at: i)
//        }
//    }
//    private func setupUI() {
//
//        for (index,item) in timers.enumerated() {
//            let timerView = TimerRowView(
//                name: item.name,
//                color: item.color,
//                onStart: {
//                    [weak self] in self?.startTimer(at: index)
//                },
//                onPause: {
//                    [weak self] in self?.pauseTimer(at: index)
//                },
//                onReset: {
//                    [weak self] in self?.resetTimer(at: index)
//                }
//            )
//        }
//
//        // Control all buttons
//        let startAllBtn = createButton(title: "▶️ Start All", color: .systemGreen)
//        startAllBtn.addTarget(self, action: #selector(startAll), for: .touchUpInside)
//
//        let stopAllBtn = createButton(title: "⏸️ Pause All", color: .systemOrange)
//        stopAllBtn.addTarget(self, action: #selector(stopAll), for: .touchUpInside)
//
//        let resetAllBtn = createButton(title: "🔄 Reset All", color: .systemRed)
//        resetAllBtn.addTarget(self, action: #selector(resetAll), for: .touchUpInside)
//
//        let controlStack = UIStackView(arrangedSubviews: [startAllBtn, stopAllBtn, resetAllBtn])
//        controlStack.distribution = .fillEqually
//        controlStack.spacing = 10
//
//        // Main stack
//        let mainStack = UIStackView(arrangedSubviews: timerViews + [controlStack])
//        mainStack.axis = .vertical
//        mainStack.spacing = 20
//        mainStack.translatesAutoresizingMaskIntoConstraints = false
//
//        view.addSubview(mainStack)
//
//        NSLayoutConstraint.activate([
//            mainStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
//            mainStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
//            mainStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
//        ])
//    }
//
//
//    private func createButton(title: String, color: UIColor) -> UIButton {
//        let button = UIButton(type: .system)
//        button.setTitle(title, for: .normal)
//        button.backgroundColor = color.withAlphaComponent(0.2)
//        button.setTitleColor(color, for: .normal)
//        button.layer.cornerRadius = 8
//        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
//        return button
//    }
//
//    deinit {
//        for timer in timers {
//            timer.timer?.invalidate()
//        }
//    }
//}
//
//class TimerRowView: UIView {
//
//    private let nameLabel = UILabel()
//    private let progressView = UIProgressView()
//    private let percentLabel = UILabel()
//    private let startButton = UIButton(type: .system)
//    private let resetButton = UIButton(type: .system)
//
//    private var onStart: (() -> Void)?
//    private var onPause: (() -> Void)?
//    private var onReset: (() -> Void)?
//
//    private var isRunning = false
//
//    init(name: String, color: UIColor, onStart: @escaping () -> Void, onPause: @escaping () -> Void, onReset: @escaping () -> Void) {
//        super.init(frame: .zero)
//
//        self.onStart = onStart
//        self.onPause = onPause
//        self.onReset = onReset
//
//        // Name
//        nameLabel.text = name
//        nameLabel.font = .systemFont(ofSize: 18, weight: .bold)
//        nameLabel.textColor = color
//
//        // Progress
//        progressView.progressTintColor = color
//        progressView.trackTintColor = color.withAlphaComponent(0.2)
//        progressView.transform = CGAffineTransform(scaleX: 1.0, y: 3.0)
//
//        // Percent
//        percentLabel.text = "0%"
//        percentLabel.font = .monospacedDigitSystemFont(ofSize: 16, weight: .medium)
//        percentLabel.textAlignment = .right
//        percentLabel.widthAnchor.constraint(equalToConstant: 50).isActive = true
//
//        // Buttons
//        startButton.setTitle("▶️", for: .normal)
//        startButton.titleLabel?.font = .systemFont(ofSize: 24)
//        startButton.addTarget(self, action: #selector(startPauseTapped), for: .touchUpInside)
//
//        resetButton.setTitle("🔄", for: .normal)
//        resetButton.titleLabel?.font = .systemFont(ofSize: 24)
//        resetButton.addTarget(self, action: #selector(resetTapped), for: .touchUpInside)
//
//        // Layout
//        let progressStack = UIStackView(arrangedSubviews: [progressView, percentLabel])
//        progressStack.spacing = 10
//        progressStack.alignment = .center
//
//        let buttonStack = UIStackView(arrangedSubviews: [startButton, resetButton])
//        buttonStack.spacing = 10
//
//        let mainStack = UIStackView(arrangedSubviews: [nameLabel, progressStack, buttonStack])
//        mainStack.axis = .vertical
//        mainStack.spacing = 8
//        mainStack.translatesAutoresizingMaskIntoConstraints = false
//
//        addSubview(mainStack)
//
//        NSLayoutConstraint.activate([
//            mainStack.topAnchor.constraint(equalTo: topAnchor),
//            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
//            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
//            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
//        ])
//
//        // Styling
//        backgroundColor = color.withAlphaComponent(0.05)
//        layer.cornerRadius = 12
//        layoutMargins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    @objc private func startPauseTapped() {
//        if isRunning {
//            onPause?()
//        } else {
//            onStart?()
//        }
//    }
//
//    @objc private func resetTapped() {
//        onReset?()
//    }
//
//    func updateProgress(_ progress: Float) {
//        progressView.progress = progress
//        percentLabel.text = String(format: "%.0f%%", progress * 100)
//    }
//
//    func setRunning(_ running: Bool) {
//        isRunning = running
//        startButton.setTitle(running ? "⏸️" : "▶️", for: .normal)
//    }
//}
