import UIKit

class BoardTableViewCell: UITableViewCell {
    @IBOutlet var idLabel: UILabel!
    @IBOutlet var nameLabel: UILabel!

    var theme: Theme? {
        didSet {
            guard let theme = theme else { return }
            backgroundColor = theme.backgroundColor
            nameLabel.textColor = theme.textColor
        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        backgroundColor = highlighted ? theme?.altBackgroundColor : theme?.backgroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        backgroundColor = selected ? theme?.altBackgroundColor : theme?.backgroundColor
    }
}
