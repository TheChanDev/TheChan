import UIKit

private let iconSize = CGFloat(32)

class ChanCollectionViewCell: UICollectionViewCell {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true

        iconView.alpha = 0.85
        contentView.addSubview(iconView)

        gradientLayer.cornerRadius = 7.5
        contentView.layer.insertSublayer(gradientLayer, at: 0)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    // MARK: Internal

    override var isHighlighted: Bool {
        didSet {
            gradientLayer.colors = [gradientColors.0, isHighlighted ? gradientColors.0 : gradientColors.1]
            iconView.alpha = isHighlighted ? 0.9 : 0.85
        }
    }

    override var isSelected: Bool {
        didSet {
            gradientLayer.colors = [isSelected ? gradientColors.1 : gradientColors.0, gradientColors.1]
            iconView.alpha = isSelected ? 1 : 0.85
        }
    }

    override func layoutSubviews() {
        gradientLayer.frame = contentView.frame
        iconView.frame = contentView.frame
    }

    func setIcon(_ icon: UIImage) {
        iconView.image = icon
        iconView.contentMode = .center
    }

    func setGradientColors(_ first: UIColor, _ second: UIColor) {
        gradientColors = (first.cgColor, second.cgColor)
        gradientLayer.colors = [first.cgColor, second.cgColor]
    }

    // MARK: Private

    private let iconView = UIImageView()
    private let gradientLayer = CAGradientLayer()
    private var gradientColors = (UIColor.black.cgColor, UIColor.black.cgColor)
}
