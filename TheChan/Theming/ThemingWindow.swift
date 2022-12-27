final class ThemingWindow: UIWindow, Themable {
    // MARK: Lifecycle

    override init(windowScene: UIWindowScene) {
        super.init(windowScene: windowScene)

        subscribeForThemeChanges()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateTintColor),
            name: ChanManager.currentChanChangedNotificationName,
            object: nil
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        ThemeManager.shared.updateTheme()
    }

    func applyTheme(_ theme: Theme) {
        self.theme = theme
        updateTintColor()
        if !UserSettings.shared.useSystemDarkMode {
            overrideUserInterfaceStyle = theme == .light ? .light : .dark
        } else {
            overrideUserInterfaceStyle = .unspecified
        }
    }

    // MARK: Private

    private var theme: Theme?

    @objc private func updateTintColor() {
        guard let theme = theme else { return }
        tintColor = ChanManager.shared.currentChan.tintColor(
            for: theme,
            userInterfaceStyle: traitCollection.userInterfaceStyle
        )
    }
}
