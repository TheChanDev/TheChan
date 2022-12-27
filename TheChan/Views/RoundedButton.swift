import UIKit

class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()

        layer.cornerRadius = 7
        contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        titleLabel?.font = UIFont.systemFont(ofSize: 17, weight: .medium)
    }
}
