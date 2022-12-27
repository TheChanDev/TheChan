import UIKit

class SwitchTableViewCell: LabelTableViewCell {
    @IBOutlet var theSwitch: UISwitch!

    override var theme: Theme? {
        didSet {
            theSwitch.tintColor = theme?.separatorColor
        }
    }
}
