@objc final class Theme: NSObject {
    // MARK: Lifecycle

    init(
        name: String,
        backgroundColor: UIColor,
        altBackgroundColor: UIColor,
        textColor: UIColor,
        altTextColor: UIColor,
        separatorColor: UIColor,
        spoilerBackgroundColor: UIColor,
        spoilerTextColor: UIColor,
        quoteColor: UIColor,
        postMetaTextColor: UIColor,
        postMetaCountryColor: UIColor,
        postMetaTripColor: UIColor,
        opMarkerColor: UIColor,
        bannedMarkerColor: UIColor,
        pinnedMarkerColor: UIColor,
        closedMarkerColor: UIColor,
        userPostMarkerColor: UIColor,
        threadBackgroundColor: UIColor,
        postsIndicatorInactiveBackgroundColor: UIColor,
        postsIndicatorInactiveForegroundColor: UIColor,
        postsIndicatorErrorBackgroundColor: UIColor,
        postsIndicatorErrorForegroundColor: UIColor,
        tintColorOverride: UIColor? = nil,
        barBackgroundColorOverride: UIColor? = nil,
        barTintColorOverride: UIColor? = nil,
        barShadowColorOverride: UIColor? = nil
    ) {
        self.name = name
        self.backgroundColor = backgroundColor
        self.altBackgroundColor = altBackgroundColor
        self.textColor = textColor
        self.altTextColor = altTextColor
        self.separatorColor = separatorColor
        self.spoilerBackgroundColor = spoilerBackgroundColor
        self.spoilerTextColor = spoilerTextColor
        self.quoteColor = quoteColor
        self.postMetaTextColor = postMetaTextColor
        self.postMetaCountryColor = postMetaCountryColor
        self.postMetaTripColor = postMetaTripColor
        self.opMarkerColor = opMarkerColor
        self.bannedMarkerColor = bannedMarkerColor
        self.pinnedMarkerColor = pinnedMarkerColor
        self.closedMarkerColor = closedMarkerColor
        self.userPostMarkerColor = userPostMarkerColor
        self.threadBackgroundColor = threadBackgroundColor
        self.postsIndicatorInactiveBackgroundColor = postsIndicatorInactiveBackgroundColor
        self.postsIndicatorInactiveForegroundColor = postsIndicatorInactiveForegroundColor
        self.postsIndicatorErrorBackgroundColor = postsIndicatorErrorBackgroundColor
        self.postsIndicatorErrorForegroundColor = postsIndicatorErrorForegroundColor
        self.tintColorOverride = tintColorOverride
        self.barBackgroundColorOverride = barBackgroundColorOverride
        self.barTintColorOverride = barTintColorOverride
        self.barShadowColorOverride = barShadowColorOverride
    }

    // MARK: Internal

    let name: String
    let backgroundColor: UIColor
    let altBackgroundColor: UIColor
    let textColor: UIColor
    let altTextColor: UIColor
    let separatorColor: UIColor
    let spoilerBackgroundColor: UIColor
    let spoilerTextColor: UIColor
    let quoteColor: UIColor
    let postMetaTextColor: UIColor
    let postMetaCountryColor: UIColor
    let postMetaTripColor: UIColor
    let opMarkerColor: UIColor
    let bannedMarkerColor: UIColor
    let pinnedMarkerColor: UIColor
    let closedMarkerColor: UIColor
    let userPostMarkerColor: UIColor
    let threadBackgroundColor: UIColor
    let postsIndicatorInactiveBackgroundColor: UIColor
    let postsIndicatorInactiveForegroundColor: UIColor
    let postsIndicatorErrorBackgroundColor: UIColor
    let postsIndicatorErrorForegroundColor: UIColor
    let tintColorOverride: UIColor?
    let barBackgroundColorOverride: UIColor?
    let barTintColorOverride: UIColor?
    let barShadowColorOverride: UIColor?

    override var hash: Int {
        name.hashValue
    }

    static func == (lhs: Theme, rhs: Theme) -> Bool {
        lhs.name == rhs.name
    }
}
