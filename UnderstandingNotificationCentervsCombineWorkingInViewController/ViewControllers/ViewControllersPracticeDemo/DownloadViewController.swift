////
////  DownloadViewController.swift
////  UnderstandingNotificationCentervsCombineWorkingInViewController
////
////  Created by Swapnil Dhiman on 25/11/25.
////
//
//import UIKit
//import Foundation
//
//
//// MARK: - Download Manager
//
//class DownloadManager {
//
//    static let shared = DownloadManager()
//
//    private init() {}
//
//    // MARK: - 1️⃣ Download with Completion Handler
//
//    func downloadFile(
//        from urlString: String,
//        completion: @escaping (Result<URL, Error>) -> Void
//    ) {
//        guard let url = URL(string: urlString) else {
//            completion(.failure(NetworkError.invalidURL))
//            return
//        }
//
//        // ✅ downloadTask - better for large files
//        let task = URLSession.shared.downloadTask(with: url) { localURL, response, error in
//            if let error = error {
//                DispatchQueue.main.async {
//                    completion(.failure(error))
//                }
//                return
//            }
//
//            guard let localURL = localURL else {
//                DispatchQueue.main.async {
//                    completion(.failure(NetworkError.noData))
//                }
//                return
//            }
//
//            // Validate response
//            if let httpResponse = response as? HTTPURLResponse,
//               !(200...299).contains(httpResponse.statusCode) {
//                DispatchQueue.main.async {
//                    completion(.failure(NetworkError.invalidResponse))
//                }
//                return
//            }
//
//            // ✅ Move file to permanent location
//            do {
//                let destinationURL = try self.moveToDocuments(from: localURL, filename: url.lastPathComponent)
//                DispatchQueue.main.async {
//                    completion(.success(destinationURL))
//                }
//            } catch {
//                DispatchQueue.main.async {
//                    completion(.failure(error))
//                }
//            }
//        }
//
//        task.resume()
//    }
//
//    // MARK: - 2️⃣ Download with Async/Await
//
//    func downloadFile(from urlString: String) async throws -> URL {
//        guard let url = URL(string: urlString) else {
//            throw NetworkError.invalidURL
//        }
//
//        // ✅ Async download
//        let (localURL, response) = try await URLSession.shared.download(from: url)
//
//        guard let httpResponse = response as? HTTPURLResponse,
//              (200...299).contains(httpResponse.statusCode) else {
//            throw NetworkError.invalidResponse
//        }
//
//        // Move to permanent location
//        return try moveToDocuments(from: localURL, filename: url.lastPathComponent)
//    }
//
//    // MARK: - 3️⃣ Download with Progress Tracking
//
//    func downloadWithProgress(
//        from urlString: String,
//        progressHandler: @escaping (Double) -> Void,
//        completion: @escaping (Result<URL, Error>) -> Void
//    ) -> URLSessionDownloadTask? {
//        guard let url = URL(string: urlString) else {
//            completion(.failure(NetworkError.invalidURL))
//            return nil
//        }
//
//        // ✅ Use custom URLSession with delegate
//        let configuration = URLSessionConfiguration.default
//        let delegate = DownloadDelegate(
//            url: url,
//            progressHandler: progressHandler,
//            completion: completion
//        )
//        let session = URLSession(
//            configuration: configuration,
//            delegate: delegate,
//            delegateQueue: nil
//        )
//
//        let task = session.downloadTask(with: url)
//        task.resume()
//
//        return task
//    }
//
//    // MARK: - Helper Methods
//
//    private func moveToDocuments(from localURL: URL, filename: String) throws -> URL {
//        let documentsPath = FileManager.default.urls(
//            for: .documentDirectory,
//            in: .userDomainMask
//        )[0]
//        let destinationURL = documentsPath.appendingPathComponent(filename)
//
//        // Remove old file if exists
//        if FileManager.default.fileExists(atPath: destinationURL.path) {
//            try FileManager.default.removeItem(at: destinationURL)
//        }
//
//        try FileManager.default.moveItem(at: localURL, to: destinationURL)
//
//        return destinationURL
//    }
//
//    // Get file size
//    func getFileSize(at url: URL) -> String {
//        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
//              let fileSize = attributes[.size] as? Int64 else {
//            return "Unknown size"
//        }
//
//        return ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
//    }
//}
//
//// MARK: - Download Delegate (for progress tracking)
//
//private class DownloadDelegate: NSObject, URLSessionDownloadDelegate {
//    let url: URL
//    let progressHandler: (Double) -> Void
//    let completion: (Result<URL, Error>) -> Void
//
//    init(
//        url: URL,
//        progressHandler: @escaping (Double) -> Void,
//        completion: @escaping (Result<URL, Error>) -> Void
//    ) {
//        self.url = url
//        self.progressHandler = progressHandler
//        self.completion = completion
//    }
//
//    // ✅ Track progress
//    func urlSession(
//        _ session: URLSession,
//        downloadTask: URLSessionDownloadTask,
//        didWriteData bytesWritten: Int64,
//        totalBytesWritten: Int64,
//        totalBytesExpectedToWrite: Int64
//    ) {
//        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
//        DispatchQueue.main.async {
//            self.progressHandler(progress)
//        }
//    }
//
//    // ✅ Download finished
//    func urlSession(
//        _ session: URLSession,
//        downloadTask: URLSessionDownloadTask,
//        didFinishDownloadingTo location: URL
//    ) {
//        do {
//            let destinationURL = try DownloadManager.shared.moveToDocuments(
//                from: location,
//                filename: url.lastPathComponent
//            )
//
//            DispatchQueue.main.async {
//                self.completion(.success(destinationURL))
//            }
//        } catch {
//            DispatchQueue.main.async {
//                self.completion(.failure(error))
//            }
//        }
//    }
//
//    // ✅ Handle errors
//    func urlSession(
//        _ session: URLSession,
//        task: URLSessionTask,
//        didCompleteWithError error: Error?
//    ) {
//        if let error = error {
//            DispatchQueue.main.async {
//                self.completion(.failure(error))
//            }
//        }
//    }
//}
//
//class DownloadViewController: UIViewController {
//
//    // MARK: - UI Elements
//
//    private let scrollView: UIScrollView = {
//        let scrollView = UIScrollView()
//        scrollView.translatesAutoresizingMaskIntoConstraints = false
//        return scrollView
//    }()
//
//    private let contentStackView: UIStackView = {
//        let stackView = UIStackView()
//        stackView.axis = .vertical
//        stackView.spacing = 20
//        stackView.translatesAutoresizingMaskIntoConstraints = false
//        stackView.layoutMargins = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
//        stackView.isLayoutMarginsRelativeArrangement = true
//        return stackView
//    }()
//
//    // Title Label
//    private let titleLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Download Manager Demo"
//        label.font = .systemFont(ofSize: 28, weight: .bold)
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    // MARK: - Simple Download Section
//
//    private let simpleDownloadButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Download Image (Async/Await)", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
//        button.backgroundColor = .systemBlue
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 12
//        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
//        return button
//    }()
//
//    private let imageView: UIImageView = {
//        let imageView = UIImageView()
//        imageView.contentMode = .scaleAspectFit
//        imageView.backgroundColor = .systemGray6
//        imageView.layer.cornerRadius = 12
//        imageView.clipsToBounds = true
//        imageView.translatesAutoresizingMaskIntoConstraints = false
//        return imageView
//    }()
//
//    private let imageStatusLabel: UILabel = {
//        let label = UILabel()
//        label.text = "No image downloaded"
//        label.font = .systemFont(ofSize: 14)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    // MARK: - Progress Download Section
//
//    private let progressDownloadButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Download Video with Progress", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
//        button.backgroundColor = .systemGreen
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 12
//        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
//        return button
//    }()
//
//    private let cancelDownloadButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Cancel Download", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 14, weight: .medium)
//        button.backgroundColor = .systemRed
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 8
//        button.contentEdgeInsets = UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16)
//        button.isEnabled = false
//        button.alpha = 0.5
//        return button
//    }()
//
//    private let progressView: UIProgressView = {
//        let progressView = UIProgressView(progressViewStyle: .default)
//        progressView.progressTintColor = .systemGreen
//        progressView.trackTintColor = .systemGray5
//        progressView.layer.cornerRadius = 4
//        progressView.clipsToBounds = true
//        progressView.translatesAutoresizingMaskIntoConstraints = false
//        return progressView
//    }()
//
//    private let progressLabel: UILabel = {
//        let label = UILabel()
//        label.text = "0%"
//        label.font = .monospacedSystemFont(ofSize: 16, weight: .medium)
//        label.textAlignment = .center
//        return label
//    }()
//
//    private let downloadStatusLabel: UILabel = {
//        let label = UILabel()
//        label.text = "Ready to download"
//        label.font = .systemFont(ofSize: 14)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    // MARK: - Completion Handler Section
//
//    private let completionDownloadButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Download PDF (Completion Handler)", for: .normal)
//        button.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
//        button.backgroundColor = .systemOrange
//        button.setTitleColor(.white, for: .normal)
//        button.layer.cornerRadius = 12
//        button.contentEdgeInsets = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)
//        return button
//    }()
//
//    private let pdfStatusLabel: UILabel = {
//        let label = UILabel()
//        label.text = "No PDF downloaded"
//        label.font = .systemFont(ofSize: 14)
//        label.textColor = .secondaryLabel
//        label.textAlignment = .center
//        label.numberOfLines = 0
//        return label
//    }()
//
//    // MARK: - Properties
//
//    private var downloadTask: URLSessionDownloadTask?
//
//    // MARK: - Lifecycle
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupActions()
//    }
//
//    // MARK: - Setup UI
//
//    private func setupUI() {
//        view.backgroundColor = .systemBackground
//
//        // Add scroll view
//        view.addSubview(scrollView)
//        scrollView.addSubview(contentStackView)
//
//        // Add all elements to stack view
//        contentStackView.addArrangedSubview(titleLabel)
//        contentStackView.addArrangedSubview(createSeparator())
//
//        // Simple download section
//        contentStackView.addArrangedSubview(createSectionLabel("1. Async/Await Download"))
//        contentStackView.addArrangedSubview(simpleDownloadButton)
//        contentStackView.addArrangedSubview(imageView)
//        contentStackView.addArrangedSubview(imageStatusLabel)
//        contentStackView.addArrangedSubview(createSeparator())
//
//        // Progress download section
//        contentStackView.addArrangedSubview(createSectionLabel("2. Progress Tracking"))
//        contentStackView.addArrangedSubview(progressDownloadButton)
//        contentStackView.addArrangedSubview(cancelDownloadButton)
//        contentStackView.addArrangedSubview(progressView)
//        contentStackView.addArrangedSubview(progressLabel)
//        contentStackView.addArrangedSubview(downloadStatusLabel)
//        contentStackView.addArrangedSubview(createSeparator())
//
//        // Completion handler section
//        contentStackView.addArrangedSubview(createSectionLabel("3. Completion Handler"))
//        contentStackView.addArrangedSubview(completionDownloadButton)
//        contentStackView.addArrangedSubview(pdfStatusLabel)
//
//        // Setup constraints
//        NSLayoutConstraint.activate([
//            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
//            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
//            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
//            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
//
//            contentStackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
//            contentStackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
//            contentStackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
//            contentStackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
//            contentStackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor),
//
//            imageView.heightAnchor.constraint(equalToConstant: 200),
//            progressView.heightAnchor.constraint(equalToConstant: 8)
//        ])
//    }
//
//    private func createSectionLabel(_ text: String) -> UILabel {
//        let label = UILabel()
//        label.text = text
//        label.font = .systemFont(ofSize: 18, weight: .semibold)
//        label.textColor = .label
//        return label
//    }
//
//    private func createSeparator() -> UIView {
//        let view = UIView()
//        view.backgroundColor = .separator
//        view.translatesAutoresizingMaskIntoConstraints = false
//        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
//        return view
//    }
//
//    // MARK: - Setup Actions
//
//    private func setupActions() {
//        simpleDownloadButton.addTarget(
//            self,
//            action: #selector(downloadImageTapped),
//            for: .touchUpInside
//        )
//
//        progressDownloadButton.addTarget(
//            self,
//            action: #selector(downloadWithProgressTapped),
//            for: .touchUpInside
//        )
//
//        cancelDownloadButton.addTarget(
//            self,
//            action: #selector(cancelDownloadTapped),
//            for: .touchUpInside
//        )
//
//        completionDownloadButton.addTarget(
//            self,
//            action: #selector(downloadPDFTapped),
//            for: .touchUpInside
//        )
//    }
//
//    // MARK: - Actions
//
//    @objc private func downloadImageTapped() {
//        imageStatusLabel.text = "Downloading..."
//        imageStatusLabel.textColor = .systemBlue
//        simpleDownloadButton.isEnabled = false
//        imageView.image = nil
//
//        Task {
//            do {
//                let imageURL = "https://picsum.photos/800/600"
//                let localURL = try await DownloadManager.shared.downloadFile(from: imageURL)
//
//                // Load and display image
//                if let image = UIImage(contentsOfFile: localURL.path) {
//                    imageView.image = image
//                    let fileSize = DownloadManager.shared.getFileSize(at: localURL)
//                    imageStatusLabel.text = "✅ Downloaded (\(fileSize))\n\(localURL.lastPathComponent)"
//                    imageStatusLabel.textColor = .systemGreen
//                } else {
//                    imageStatusLabel.text = "❌ Failed to load image"
//                    imageStatusLabel.textColor = .systemRed
//                }
//
//            } catch {
//                imageStatusLabel.text = "❌ Error: \(error.localizedDescription)"
//                imageStatusLabel.textColor = .systemRed
//            }
//
//            simpleDownloadButton.isEnabled = true
//        }
//    }
//
//    @objc private func downloadWithProgressTapped() {
//        progressView.progress = 0
//        progressLabel.text = "0%"
//        downloadStatusLabel.text = "Starting download..."
//        downloadStatusLabel.textColor = .systemBlue
//
//        progressDownloadButton.isEnabled = false
//        cancelDownloadButton.isEnabled = true
//        cancelDownloadButton.alpha = 1.0
//
//        // Sample video URL
//        let videoURL = "https://file-examples.com/storage/fe0a8695c9a180c51cf6e1e/2017/04/file_example_MP4_480_1_5MG.mp4"
//
//        downloadTask = DownloadManager.shared.downloadWithProgress(
//            from: videoURL,
//            progressHandler: { [weak self] progress in
//                self?.progressView.progress = Float(progress)
//                self?.progressLabel.text = "\(Int(progress * 100))%"
//                self?.downloadStatusLabel.text = "Downloading... \(Int(progress * 100))%"
//            },
//            completion: { [weak self] result in
//                guard let self = self else { return }
//
//                self.progressDownloadButton.isEnabled = true
//                self.cancelDownloadButton.isEnabled = false
//                self.cancelDownloadButton.alpha = 0.5
//                self.downloadTask = nil
//
//                switch result {
//                case .success(let url):
//                    let fileSize = DownloadManager.shared.getFileSize(at: url)
//                    self.downloadStatusLabel.text = "✅ Download complete (\(fileSize))\n\(url.lastPathComponent)"
//                    self.downloadStatusLabel.textColor = .systemGreen
//                    self.progressLabel.text = "100%"
//                    self.progressView.progress = 1.0
//
//                case .failure(let error):
//                    if (error as NSError).code == NSURLErrorCancelled {
//                        self.downloadStatusLabel.text = "⚠️ Download cancelled"
//                        self.downloadStatusLabel.textColor = .systemOrange
//                    } else {
//                        self.downloadStatusLabel.text = "❌ Error: \(error.localizedDescription)"
//                        self.downloadStatusLabel.textColor = .systemRed
//                    }
//                }
//            }
//        )
//    }
//
//    @objc private func cancelDownloadTapped() {
//        downloadTask?.cancel()
//        downloadTask = nil
//
//        cancelDownloadButton.isEnabled = false
//        cancelDownloadButton.alpha = 0.5
//        progressDownloadButton.isEnabled = true
//
//        downloadStatusLabel.text = "Download cancelled by user"
//        downloadStatusLabel.textColor = .systemOrange
//    }
//
//    @objc private func downloadPDFTapped() {
//        pdfStatusLabel.text = "Downloading..."
//        pdfStatusLabel.textColor = .systemBlue
//        completionDownloadButton.isEnabled = false
//
//        let pdfURL = "https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf"
//
//        DownloadManager.shared.downloadFile(from: pdfURL) { [weak self] result in
//            guard let self = self else { return }
//
//            self.completionDownloadButton.isEnabled = true
//
//            switch result {
//            case .success(let url):
//                let fileSize = DownloadManager.shared.getFileSize(at: url)
//                self.pdfStatusLabel.text = "✅ Downloaded (\(fileSize))\n\(url.lastPathComponent)"
//                self.pdfStatusLabel.textColor = .systemGreen
//
//            case .failure(let error):
//                self.pdfStatusLabel.text = "❌ Error: \(error.localizedDescription)"
//                self.pdfStatusLabel.textColor = .systemRed
//            }
//        }
//    }
//}
