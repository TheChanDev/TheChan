import UIKit

extension UIFont {
    class func monospacedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight = .regular) -> UIFont {
        let name = "Menlo-" + (weight == .bold ? "Bold" : "Regular")
        return UIFont(name: name, size: size)!
    }
}
