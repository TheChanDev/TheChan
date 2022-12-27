import UIKit

class LabelTableViewCell: UITableViewCell {
    @IBOutlet var label: UILabel!

    var theme: Theme? {
        didSet {
            guard let theme = theme else { return }
            backgroundColor = theme.backgroundColor
            label.textColor = theme.textColor
        }
    }

    override var alpha: CGFloat {
        didSet {
            super.alpha = 1
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        label.font = .systemFont(ofSize: CGFloat(UserSettings.shared.fontSize))
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        backgroundColor = highlighted ? theme?.altBackgroundColor : theme?.backgroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        backgroundColor = selected ? theme?.altBackgroundColor : theme?.backgroundColor
    }
}
