import UIKit

private let indicatorHeight: CGFloat = 26

class PostsIndicatorView: UIView {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(backgroundView)
        backgroundView.addSubview(label)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override class var requiresConstraintBasedLayout: Bool {
        true
    }

    lazy var backgroundView: UIView = {
        let view = UIView()

        view.layer.cornerRadius = indicatorHeight / 2
        view.translatesAutoresizingMaskIntoConstraints = false

        return view
    }()

    lazy var label: UILabel = {
        let l = UILabel()

        l.font = UIFont.systemFont(ofSize: UIFont.systemFontSize, weight: .semibold)
        l.text = "42"
        l.textColor = .black
        l.translatesAutoresizingMaskIntoConstraints = false

        return l
    }()

    override func updateConstraints() {
        super.updateConstraints()

        widthAnchor.constraint(equalTo: backgroundView.widthAnchor).isActive = true
        heightAnchor.constraint(equalTo: backgroundView.heightAnchor).isActive = true
        backgroundView.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
        backgroundView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        backgroundView.widthAnchor.constraint(greaterThanOrEqualToConstant: indicatorHeight).isActive = true
        backgroundView.heightAnchor.constraint(equalToConstant: indicatorHeight).isActive = true

        label.centerXAnchor.constraint(equalTo: backgroundView.centerXAnchor).isActive = true
        label.centerYAnchor.constraint(equalTo: backgroundView.centerYAnchor).isActive = true
        label.leadingAnchor.constraint(greaterThanOrEqualTo: backgroundView.leadingAnchor, constant: 8).isActive = true
        label.trailingAnchor.constraint(lessThanOrEqualTo: backgroundView.trailingAnchor, constant: -8).isActive = true
    }
}
