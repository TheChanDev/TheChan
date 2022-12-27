import AsyncDisplayKit
import UIKit

protocol HasSelectedBackgroundViewProperty: AnyObject {
    var selectedBackgroundView: UIView? { get set }
}

extension UITableViewCell: HasSelectedBackgroundViewProperty {}

extension HasSelectedBackgroundViewProperty {
    var selectedBackgroundColor: UIColor? {
        get {
            selectedBackgroundView?.backgroundColor
        }

        set {
            let view = UIView()
            view.backgroundColor = newValue
            selectedBackgroundView = view
        }
    }
}
