@objc protocol Themable: UITraitEnvironment {
    func applyTheme(_ theme: Theme)
}

extension Themable {
    func subscribeForThemeChanges() {
        ThemeManager.shared.attach(self)
    }
}

final class ThemeManager {
    // MARK: Lifecycle

    private init() {
        let settings = UserSettings.shared
        darkTheme = settings.darkTheme
        lightTheme = settings.lightTheme
        systemIndependentTheme = settings.currentTheme
        useSystemDarkMode = settings.useSystemDarkMode
    }

    // MARK: Internal

    static let shared = ThemeManager()

    func attach(_ subscriber: Themable) {
        observers.insert(subscriber)
        applyCurrentTheme(to: subscriber)
    }

    func updateTheme() {
        let settings = UserSettings.shared
        darkTheme = settings.darkTheme
        lightTheme = settings.lightTheme
        systemIndependentTheme = settings.currentTheme
        useSystemDarkMode = settings.useSystemDarkMode
        for observer in observers {
            applyCurrentTheme(to: observer)
        }
    }

    // MARK: Private

    private let observers: WeakSet<Themable> = []
    private var darkTheme: Theme
    private var lightTheme: Theme
    private var systemIndependentTheme: Theme
    private var useSystemDarkMode: Bool

    private func applyCurrentTheme(to subscriber: Themable) {
        let theme: Theme
        if useSystemDarkMode {
            switch subscriber.traitCollection.userInterfaceStyle {
            case .light, .unspecified:
                theme = lightTheme
            case .dark:
                theme = darkTheme
            @unknown default:
                theme = lightTheme
            }
        } else {
            theme = systemIndependentTheme
        }

        subscriber.applyTheme(theme)
    }
}

private class AnyThemable: NSObject, Themable, UITraitEnvironment {
    // MARK: Lifecycle

    init(_ value: Themable) {
        self.value = value
    }

    // MARK: Internal

    var traitCollection: UITraitCollection { value?.traitCollection ?? .init() }

    func applyTheme(_ theme: Theme) {
        value?.applyTheme(theme)
    }

    func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {}

    // MARK: Private

    private weak var value: Themable?
}
