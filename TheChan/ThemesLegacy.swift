import Foundation

extension Chan {
    func tintColor(for theme: Theme, userInterfaceStyle: UIUserInterfaceStyle) -> UIColor {
        theme.tintColorOverride ?? (userInterfaceStyle == .dark ? darkColor : lightColor)
    }
}

protocol Bar: AnyObject {
    var barTintColor: UIColor? { get set }
    var tintColor: UIColor! { get set }
    var isTranslucent: Bool { get set }
    var barStyle: UIBarStyle { get set }
}

protocol BarWithShadow: Bar {
    var shadowImage: UIImage? { get set }
    func setBarBackgroundImage(_ image: UIImage?)
}

extension UITabBar: BarWithShadow {
    func setBarBackgroundImage(_ image: UIImage?) {
        backgroundImage = image
    }
}

extension UINavigationBar: BarWithShadow {
    func setBarBackgroundImage(_ image: UIImage?) {
        setBackgroundImage(image, for: .default)
    }
}

extension UIToolbar: BarWithShadow {
    var shadowImage: UIImage? {
        get {
            shadowImage(forToolbarPosition: .any)
        }

        set {
            setShadowImage(newValue, forToolbarPosition: .any)
        }
    }

    func setBarBackgroundImage(_ image: UIImage?) {
        setBackgroundImage(image, forToolbarPosition: .any, barMetrics: .default)
    }
}

extension UISearchBar: Bar {}

extension Bar {
    func setupTheme() {
//        barStyle = UIColor.isDarkTheme ? .black : .default
//        if let background = UIColor.barBackgroundColorOverride {
//            isTranslucent = false
//            barTintColor = background
//
//            if let barWithShadow = self as? BarWithShadow,
//                let shadow = UIColor.barShadowColorOverride {
//                barWithShadow.shadowImage = shadow.as1ptImage()
//                barWithShadow.setBarBackgroundImage(background.as1ptImage())
//            }
//        }
//
//
//
//        if let tint = UIColor.barTintColorOverride {
//            tintColor = tint
//        } else if let bar = self as? UISearchBar {
//            bar.barTintColor = .backgroundColor
//            bar.tintColor = .altBackgroundColor
//            bar.layer.borderWidth = 1
//            bar.layer.borderColor = UIColor.backgroundColor.cgColor
//        }
    }
}

extension UIColor {
    func toHexString() -> String {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)
        let rgb =
            Int(r * 255) << 16 |
            Int(g * 255) << 8 |
            Int(b * 255) << 0

        return NSString(format: "#%06x", rgb) as String
    }

    func as1ptImage() -> UIImage? {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        guard let ctx = UIGraphicsGetCurrentContext() else { return nil }

        setFill()
        ctx.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
