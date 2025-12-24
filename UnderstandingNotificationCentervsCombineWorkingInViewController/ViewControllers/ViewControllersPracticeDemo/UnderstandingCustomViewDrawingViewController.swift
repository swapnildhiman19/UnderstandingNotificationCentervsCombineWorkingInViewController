import UIKit

//Using layers
class BorderedImageView: UIImageView {
    var borderColor: UIColor = .white {
        didSet {
            updateBorder()
        }
    }

    var borderWidth: CGFloat = 2 {
        didSet {
            updateBorder()
        }
    }

    var isCircular : Bool = true {
        didSet {
            setNeedsLayout()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    private func setupView(){
        clipsToBounds = true
        contentMode = .scaleAspectFill
        updateBorder()
    }

    private func updateBorder(){
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if isCircular {
            layer.cornerRadius = bounds.width/2
        } else {
            layer.cornerRadius = 10 //Rounded Rectangle
        }
    }
}

class CircleView : UIView {
    var fillColor : UIColor = .systemBlue {
        didSet {
            setNeedsDisplay()
        }
    }

    var strokeColor : UIColor = .systemRed {
        didSet {
            setNeedsDisplay()
        }
    }

    var strokeWidth : CGFloat = 4 {
        didSet {
            setNeedsDisplay()
        }
    }

    convenience init() {
        self.init(frame: .zero)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }

    required init?(coder:NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else {
            print("No graphics context exist")
            return
        }

        let inset = strokeWidth/2
        let circleRect = rect.insetBy(dx: inset, dy: inset)

        context.setFillColor(fillColor.cgColor)
        context.fillEllipse(in: circleRect)

        context.setStrokeColor(strokeColor.cgColor)
        context.setLineWidth(strokeWidth)
        context.strokeEllipse(in: circleRect)
    }
}

class DrawingDemoViewController : UIViewController {
    let borderedImageView = BorderedImageView()

    let circleView = CircleView()

    override func viewDidLoad(){
        super.viewDidLoad()
        title = "Drawing Demo"
        setupView()
    }

    private func setupView(){
        view.backgroundColor = .systemBackground

        borderedImageView.image = UIImage(systemName: "person.circle.fill")
        borderedImageView.borderWidth = 3
        borderedImageView.borderColor = .brown
        borderedImageView.isCircular = true
        borderedImageView.tintColor = .systemGray

        circleView.fillColor = .systemBlue
        circleView.strokeColor = .systemOrange
        circleView.strokeWidth = 6

        view.addSubview(borderedImageView)
        view.addSubview(circleView)

        setupLayoutConstraints()
    }

    private func setupLayoutConstraints(){
        borderedImageView.translatesAutoresizingMaskIntoConstraints = false
        circleView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            // Bordered Image View
            borderedImageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            borderedImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            borderedImageView.widthAnchor.constraint(equalToConstant: 120),
            borderedImageView.heightAnchor.constraint(equalToConstant: 120),

            // Circle View
            circleView.topAnchor.constraint(equalTo: borderedImageView.bottomAnchor, constant: 40),
            circleView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            circleView.widthAnchor.constraint(equalToConstant: 120),
            circleView.heightAnchor.constraint(equalToConstant: 120),

        ])
    }
}
