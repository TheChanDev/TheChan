import Foundation

class UserSettings {
    // MARK: Lifecycle

    init() {
        let preferredLanguage = NSLocale.preferredLanguages.first ?? "en"
        let chans = preferredLanguage.hasPrefix("ru") ? ["2ch", "4chan"] : ["4chan", "2ch"]

        defaults.register(defaults: [
            "FONT_SIZE": UIFont.systemFontSize,
            "ENABLED_CHANS": chans,
            "ENABLE_MEDIA": true,
            "SHOW_VIDEOS_IN_GALLERY": true,
            "ENABLE_MINI_GALLERY": true,
            "USE_SYSTEM_DARK_MODE": true,
            "TOOLBAR_ITEMS": [
                ToolbarItem.replyButton.rawValue,
                ToolbarItem.refreshButton.rawValue,
                ToolbarItem.info.rawValue,
                ToolbarItem.goDownButton.rawValue,
                ToolbarItem.favoriteButton.rawValue],
        ])
    }

    // MARK: Public

    public static let shared = UserSettings()

    // MARK: Internal

    var fontSize: Int {
        get {
            defaults.integer(forKey: "FONT_SIZE")
        }

        set {
            defaults.set(newValue, forKey: "FONT_SIZE")
        }
    }

    var useMonospacedFontInPostInfo: Bool {
        get {
            defaults.bool(forKey: "USE_MONOSPACED_FONT_IN_POST_INFO")
        }

        set {
            defaults.set(newValue, forKey: "USE_MONOSPACED_FONT_IN_POST_INFO")
        }
    }

    var isMediaEnabled: Bool {
        get {
            defaults.bool(forKey: "ENABLE_MEDIA")
        }

        set {
            defaults.set(newValue, forKey: "ENABLE_MEDIA")
        }
    }

    var hasUserEnabledMediaBefore: Bool {
        get {
            defaults.bool(forKey: "HAS_USER_ENABLED_MEDIA_BEFORE")
        }

        set {
            defaults.set(newValue, forKey: "HAS_USER_ENABLED_MEDIA_BEFORE")
        }
    }

    var enabledChansIds: [String] {
        get {
            defaults.object(forKey: "ENABLED_CHANS") as? [String] ?? []
        }

        set {
            defaults.set(newValue, forKey: "ENABLED_CHANS")
        }
    }

    var useSystemDarkMode: Bool {
        get { defaults.bool(forKey: "USE_SYSTEM_DARK_MODE") }
        set { defaults.set(newValue, forKey: "USE_SYSTEM_DARK_MODE") }
    }

    var currentTheme: Theme {
        get { defaults.string(forKey: "CURRENT_THEME").flatMap(Theme.named) ?? .light }
        set { defaults.set(newValue.name, forKey: "CURRENT_THEME") }
    }

    var lightTheme: Theme {
        get { defaults.string(forKey: "LIGHT_THEME").flatMap(Theme.named) ?? .light }
        set { defaults.set(newValue.name, forKey: "LIGHT_THEME") }
    }

    var darkTheme: Theme {
        get { defaults.string(forKey: "DARK_THEME").flatMap(Theme.named) ?? .dark }
        set { defaults.set(newValue.name, forKey: "DARK_THEME") }
    }

    var isMiniGalleryEnabled: Bool {
        get {
            defaults.bool(forKey: "ENABLE_MINI_GALLERY")
        }

        set {
            defaults.set(newValue, forKey: "ENABLE_MINI_GALLERY")
        }
    }

    var showVideosInGallery: Bool {
        get {
            defaults.bool(forKey: "SHOW_VIDEOS_IN_GALLERY")
        }

        set {
            defaults.set(newValue, forKey: "SHOW_VIDEOS_IN_GALLERY")
        }
    }

    var scrollThreadWithGallery: Bool {
        get {
            defaults.bool(forKey: "SCROLL_THREAD_WITH_GALLERY")
        }

        set {
            defaults.set(newValue, forKey: "SCROLL_THREAD_WITH_GALLERY")
        }
    }

    var toolbarItems: [ToolbarItem] {
        get {
            (defaults.array(forKey: "TOOLBAR_ITEMS") as? [Int] ?? [])
                .map { ToolbarItem(rawValue: $0) ?? .refreshButton }
        }

        set {
            defaults.set(newValue.map(\.rawValue), forKey: "TOOLBAR_ITEMS")
        }
    }

    var completedTutorials: CompletedTutorials {
        get {
            let raw = defaults.integer(forKey: "COMPLETED_TUTORIALS")
            return CompletedTutorials(rawValue: raw)
        }

        set {
            defaults.set(newValue.rawValue, forKey: "COMPLETED_TUTORIALS")
        }
    }

    var userLanguage: String {
        get {
            defaults.array(forKey: "AppleLanguages")?.first as? String ?? Locale.current.identifier
        }

        set {
            defaults.set([newValue], forKey: "AppleLanguages")
        }
    }

    var lastCacheCleanTime: Date {
        get {
            let timestamp = defaults.double(forKey: "LAST_CACHE_CLEAN_TIME")
            return Date(timeIntervalSince1970: timestamp)
        }

        set {
            defaults.set(newValue.timeIntervalSince1970, forKey: "LAST_CACHE_CLEAN_TIME")
        }
    }

    var username: String? {
        get {
            defaults.string(forKey: "ACCOUNT_USERNAME")
        }

        set {
            defaults.set(newValue, forKey: "ACCOUNT_USERNAME")
        }
    }

    var sessionToken: String? {
        get {
            defaults.string(forKey: "ACCOUNT_TOKEN")
        }

        set {
            defaults.set(newValue, forKey: "ACCOUNT_TOKEN")
        }
    }

    var userID: String? {
        get {
            defaults.string(forKey: "ACCOUNT_USER_ID")
        }

        set {
            defaults.set(newValue, forKey: "ACCOUNT_USER_ID")
        }
    }

    func getChanSettings(id: String) -> ChanSettings {
        let rootDictionary = getChansRootDictionary()
        guard let settingsData = rootDictionary[id] as? Data else { return ChanSettings() }
        let settings = NSKeyedUnarchiver.unarchiveObject(with: settingsData) as? ChanSettings
        return settings ?? ChanSettings()
    }

    func updateChanSettings(id: String, with settings: ChanSettings) {
        var rootDictionary = getChansRootDictionary()
        rootDictionary[id] = NSKeyedArchiver.archivedData(withRootObject: settings)
        defaults.set(rootDictionary, forKey: "CHAN_SETTINGS")
    }

    func applySettings(from user: User) {
        let settings = user.settings
        isMediaEnabled = settings.isMediaEnabled
    }

    // MARK: Private

    private let defaults = UserDefaults.standard

    private func getChansRootDictionary() -> [String: Any] {
        defaults.dictionary(forKey: "CHAN_SETTINGS") ?? [:]
    }
}
