import UIKit

class FavoriteThreadCollectionViewCell: UICollectionViewCell {
    @IBOutlet var boardLabelBackgroundView: UIView!
    @IBOutlet var boardLabel: UILabel!
    @IBOutlet var threadNameLabel: UILabel!
    @IBOutlet var unreadPostsLabel: UILabel!
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var unreadPostsLabelBackgroundView: UIView!
    @IBOutlet var blurEffectView: UIVisualEffectView!

    var theme: Theme! {
        didSet {
            threadNameLabel.textColor = theme.textColor
            boardLabelBackgroundView.backgroundColor = theme.backgroundColor.withAlphaComponent(0.8)
        }
    }

    override func awakeFromNib() {
        blurEffectView.effect = UIBlurEffect(style: .systemMaterial)

        contentView.layer.cornerRadius = 12
        contentView.layer.cornerCurve = .continuous
        contentView.layer.masksToBounds = true
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let shadowPath = UIBezierPath(rect: bounds)
        layer.shadowPath = shadowPath.cgPath
    }
}
