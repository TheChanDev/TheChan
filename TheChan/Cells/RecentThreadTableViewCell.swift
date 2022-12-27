import UIKit

class RecentThreadTableViewCell: UITableViewCell {
    @IBOutlet var boardIdLabel: UILabel!
    @IBOutlet var threadNameLabel: UILabel!
    var theme: Theme?

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard let theme = theme else { return }
        backgroundColor = highlighted ? theme.altBackgroundColor : theme.backgroundColor
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        guard let theme = theme else { return }
        backgroundColor = selected ? theme.altBackgroundColor : theme.backgroundColor
    }
}
