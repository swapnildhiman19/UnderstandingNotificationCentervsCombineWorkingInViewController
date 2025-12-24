import Foundation
import UIKit

class PhotoCollectionViewController: UIViewController {
    var collectionView: UICollectionView!
    var photos: [URL] = []  // URLs to images
    let imageCache = NSCache<NSURL, UIImage>()  // Cache downloaded images

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()

        // ✅ CRITICAL: Add some photos to display!
        loadPhotos()

        // ✅ Enable prefetching
        collectionView.prefetchDataSource = self
    }

    // ✅ NEW: Populate the photos array
    func loadPhotos() {
        // Using placeholder image service (you can replace with your own URLs)
        photos = (1...50).map { index in
            URL(string: "https://picsum.photos/200/200?random=\(index)")!
        }

        // ⚠️ IMPORTANT: Tell collection view to reload after adding data
        collectionView.reloadData()
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: 100, height: 100)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)

        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        collectionView.backgroundColor = .white  // ✅ Set background color
        collectionView.dataSource = self
        collectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        view.addSubview(collectionView)
    }
}

extension PhotoCollectionViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count  // Now returns 50 instead of 0!
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell

        // Check cache first
        if let cachedImage = imageCache.object(forKey: photos[indexPath.row] as NSURL) {
            cell.imageView.image = cachedImage
        } else {
            // ✅ Show a placeholder while loading
            cell.imageView.backgroundColor = .lightGray
            cell.imageView.image = nil

            // If not cached and not being prefetched, download now
            downloadImage(from: photos[indexPath.row]) { [weak self] image in
                if let image = image {
                    self?.imageCache.setObject(image, forKey: self?.photos[indexPath.row] as! NSURL)
                    DispatchQueue.main.async {
                        // Only reload if this cell is still visible
                        if collectionView.indexPathsForVisibleItems.contains(indexPath) {
                            collectionView.reloadItems(at: [indexPath])
                        }
                    }
                }
            }
        }

        return cell
    }
}

// ✅ PREFETCHING: Download images BEFORE they're visible!
extension PhotoCollectionViewController: UICollectionViewDataSourcePrefetching {
    // Called when cells are ABOUT TO become visible
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        print("📥 Prefetching items at: \(indexPaths.map { $0.row })")

        for indexPath in indexPaths {
            let url = photos[indexPath.row]

            // Skip if already cached
            guard imageCache.object(forKey: url as NSURL) == nil else { continue }

            // Download image in background
            downloadImage(from: url) { [weak self] image in
                if let image = image {
                    self?.imageCache.setObject(image, forKey: url as NSURL)
                    // Reload the cell if it's visible
                    DispatchQueue.main.async {
                        if collectionView.indexPathsForVisibleItems.contains(indexPath) {
                            collectionView.reloadItems(at: [indexPath])
                        }
                    }
                }
            }
        }
    }

    // Called when prefetching is no longer needed (user scrolled away)
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        print("❌ Cancelling prefetch for: \(indexPaths.map { $0.row })")
        // In production, you'd cancel URLSessionDataTask here
    }

    func downloadImage(from url: URL, completion: @escaping (UIImage?) -> Void) {
        // Simplified download logic
        URLSession.shared.dataTask(with: url) { data, _, _ in
            let image = data.flatMap { UIImage(data: $0) }
            completion(image)
        }.resume()
    }
}

class PhotoCell: UICollectionViewCell {
    let imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.frame = contentView.bounds
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.backgroundColor = .lightGray  // ✅ Placeholder color
        contentView.addSubview(imageView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
