//
//  SimpleUIColectionViewController.swift
//  UnderstandingNotificationCentervsCombineWorkingInViewController
//
//  Created by Swapnil Dhiman on 18/11/25.
//

import UIKit

// Step 1: Create a simple cell that shows a number
//class NumberCell: UICollectionViewCell {
//    let label = UILabel()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//
//        // Setup the label
//        label.frame = contentView.bounds
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 30, weight: .bold)
//        label.textColor = .white
//        contentView.addSubview(label)
//
//        // Give the cell a nice background
//        contentView.backgroundColor = .systemBlue
//        contentView.layer.cornerRadius = 8
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//}
//
//// Step 2: Create the View Controller with Collection View
//class SimpleCollectionViewController: UIViewController {
//
//    var collectionView: UICollectionView!
//    var numbers: [Int] = []  // Our data: just numbers from 1 to 20
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//
//        // ✅ STEP A: Add some data to display
//        numbers = Array(1...20)  // Creates [1, 2, 3, 4, ... 20]
//
//        // ✅ STEP B: Setup the collection view
//        setupCollectionView()
//    }
//
//    func setupCollectionView() {
//        // Create a layout (decides how items are arranged)
//        let layout = UICollectionViewFlowLayout()
//        layout.itemSize = CGSize(width: 80, height: 80)  // Each cell is 80x80
//        layout.minimumInteritemSpacing = 10  // Space between items horizontally
//        layout.minimumLineSpacing = 10       // Space between rows
//        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
//        layout.scrollDirection = .horizontal
//
//        // Create the collection view
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.backgroundColor = .systemGray6
//
//        // ⚠️ CRITICAL: Set the data source (who provides the data?)
//        collectionView.dataSource = self
//
//        // Register our cell type
//        collectionView.register(NumberCell.self, forCellWithReuseIdentifier: "NumberCell")
//
//        // Add it to the view
//        view.addSubview(collectionView)
//    }
//}
//
//// Step 3: Implement the Data Source (answer the collection view's questions)
//extension SimpleCollectionViewController: UICollectionViewDataSource {
//
//    // Question 1: "How many items should I show?"
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return numbers.count  // Answer: 20 items
//    }
//
//    // Question 2: "What should I display in each cell?"
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        // Get a reusable cell
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCell", for: indexPath) as! NumberCell
//
//        // Configure it with data
//        let number = numbers[indexPath.row]
//        cell.label.text = "\(number)"
//
//        // Alternate colors for fun
//        if number % 2 == 0 {
//            cell.contentView.backgroundColor = .systemBlue
//        } else {
//            cell.contentView.backgroundColor = .systemGreen
//        }
//
//        return cell
//    }
//}

//
//class ThreeColumnViewController: UIViewController {
//
//    var collectionView: UICollectionView!
//    let numbers = Array(1...30)
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        title = "3 Columns"
//
//        setupCollectionView()
//    }
//
//    func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//
//        // 📐 SCROLL DIRECTION
//        layout.scrollDirection = .vertical  // Scrolls up/down
//
//        // 📏 NUMBER OF COLUMNS (3 columns)
//        let screenWidth = view.bounds.width
//        let spacing: CGFloat = 10
//        let padding: CGFloat = 20
//
//        // Calculate for exactly 3 columns
//        let totalSpacing = (spacing * 2) + (padding * 2)  // 2 gaps + 2 edges
//        let itemWidth = (screenWidth - totalSpacing) / 3
//
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//
//        // 📊 SPACING
//        layout.minimumInteritemSpacing = spacing  // Horizontal space between items
//        layout.minimumLineSpacing = spacing       // Vertical space between rows
//        layout.sectionInset = UIEdgeInsets(top: padding, left: padding,
//                                          bottom: padding, right: padding)
//
//        // Create collection view with this layout
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.backgroundColor = .systemGray6
//        collectionView.dataSource = self
//        collectionView.register(NumberCell.self, forCellWithReuseIdentifier: "NumberCell")
//
//        view.addSubview(collectionView)
//    }
//}
//
//extension ThreeColumnViewController: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return numbers.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "NumberCell", for: indexPath) as! NumberCell
//        cell.label.text = "\(numbers[indexPath.row])"
//        cell.contentView.backgroundColor = .systemBlue
//        return cell
//    }
//}
//
//class NumberCell: UICollectionViewCell {
//    let label = UILabel()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        label.frame = contentView.bounds
//        label.textAlignment = .center
//        label.font = .systemFont(ofSize: 24, weight: .bold)
//        label.textColor = .white
//        contentView.addSubview(label)
//        contentView.layer.cornerRadius = 8
//    }
//
//    required init?(coder: NSCoder) { fatalError() }
//}

class HorizontalScrollViewController: UIViewController {

    var collectionView: UICollectionView!
    let movies = ["🎬 Movie 1", "🎬 Movie 2", "🎬 Movie 3", "🎬 Movie 4",
                  "🎬 Movie 5", "🎬 Movie 6", "🎬 Movie 7", "🎬 Movie 8"]

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = "Netflix Style"

        setupCollectionView()
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()

        // 🔄 HORIZONTAL SCROLLING
        layout.scrollDirection = .horizontal  // ← THIS MAKES IT HORIZONTAL!

        // 📏 SIZE (wider rectangles for movie posters)
        layout.itemSize = CGSize(width: 150, height: 200)

        // 📊 SPACING
        layout.minimumInteritemSpacing = 15
        layout.minimumLineSpacing = 15
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        collectionView = UICollectionView(frame: CGRect(x: 0, y: 100, width: view.bounds.width, height: 240),
                                         collectionViewLayout: layout)
        collectionView.backgroundColor = .darkGray
        collectionView.dataSource = self
        collectionView.register(MovieCell.self, forCellWithReuseIdentifier: "MovieCell")

        // 📱 DISABLE vertical scrolling indicator (since we scroll horizontally)
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = true

        view.addSubview(collectionView)
    }
}

extension HorizontalScrollViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return movies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "MovieCell", for: indexPath) as! MovieCell
        cell.label.text = movies[indexPath.row]
        return cell
    }
}

class MovieCell: UICollectionViewCell {
    let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        label.frame = contentView.bounds
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 16, weight: .semibold)
        label.textColor = .white
        label.numberOfLines = 0
        contentView.addSubview(label)
        contentView.backgroundColor = .systemRed
        contentView.layer.cornerRadius = 12
    }

    required init?(coder: NSCoder) { fatalError() }
}

//class DynamicColumnsViewController: UIViewController {
//
//    var collectionView: UICollectionView!
//    let colors: [UIColor] = [.systemRed, .systemBlue, .systemGreen, .systemOrange,
//                            .systemPurple, .systemPink, .systemTeal, .systemIndigo]
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        view.backgroundColor = .white
//        title = "Dynamic Columns"
//
//        setupCollectionView()
//    }
//
//    func setupCollectionView() {
//        let layout = UICollectionViewFlowLayout()
//        layout.scrollDirection = .vertical
//
//        // 🎯 SMART COLUMN CALCULATION
//        // Automatically adjusts: 4 columns on iPad, 3 on iPhone Plus, 2 on small iPhones
//        let numberOfColumns: CGFloat = {
//            let width = view.bounds.width
//            if width > 768 { return 4 }      // iPad
//            else if width > 414 { return 3 } // Large iPhone
//            else { return 2 }                // Standard iPhone
//        }()
//
//        let spacing: CGFloat = 10
//        let padding: CGFloat = 10
//
//        let totalSpacing = (spacing * (numberOfColumns - 1)) + (padding * 2)
//        let itemWidth = (view.bounds.width - totalSpacing) / numberOfColumns
//
//        layout.itemSize = CGSize(width: itemWidth, height: itemWidth)
//        layout.minimumInteritemSpacing = spacing
//        layout.minimumLineSpacing = spacing
//        layout.sectionInset = UIEdgeInsets(top: padding, left: padding,
//                                          bottom: padding, right: padding)
//
//        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
//        collectionView.backgroundColor = .systemGray6
//        collectionView.dataSource = self
//        collectionView.register(ColorCell.self, forCellWithReuseIdentifier: "ColorCell")
//
//        view.addSubview(collectionView)
//    }
//}
//
//extension DynamicColumnsViewController: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        return colors.count
//    }
//
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorCell", for: indexPath) as! ColorCell
//        cell.contentView.backgroundColor = colors[indexPath.row]
//        return cell
//    }
//}
//
//class ColorCell: UICollectionViewCell {
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        contentView.layer.cornerRadius = 12
//    }
//
//    required init?(coder: NSCoder) { fatalError() }
//}
