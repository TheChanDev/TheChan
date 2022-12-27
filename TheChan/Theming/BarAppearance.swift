extension UINavigationBarAppearance {
    static func fromTheme(_ theme: Theme) -> UINavigationBarAppearance {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        if let override = theme.barBackgroundColorOverride {
            appearance.backgroundColor = override
        }

        return appearance
    }
}

extension UITabBarAppearance {
    static func fromTheme(_ theme: Theme) -> UITabBarAppearance {
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        if let override = theme.barBackgroundColorOverride {
            appearance.backgroundColor = override
        }

        return appearance
    }
}

extension UIToolbarAppearance {
    static func fromTheme(_ theme: Theme) -> UIToolbarAppearance {
        let appearance = UIToolbarAppearance()
        appearance.configureWithDefaultBackground()
        if let override = theme.barBackgroundColorOverride {
            appearance.backgroundColor = override
        }

        return appearance
    }
}
