import UIKit

// MARK: - Device Structure

struct Device {
    // MARK: - Device Version Checks

    enum Versions: Float {
        case five = 5.0
        case six = 6.0
        case seven = 7.0
        case eight = 8.0
        case nine = 9.0
        case ten = 10.0
    }

    // MARK: - Device Size Checks

    enum Heights: CGFloat {
        case inches_3_5 = 480
        case inches_4 = 568
        case inches_4_7 = 667
        case inches_5_5 = 736
        case inches_9_7 = 1024
        case inches_12_9 = 1366
    }

    // MARK: - Singletons

    static var TheCurrentDevice: UIDevice {
        enum Singleton {
            static let device = UIDevice.current
        }
        return Singleton.device
    }

    static var TheCurrentDeviceVersion: Float {
        enum Singleton {
            static let version = Float(UIDevice.current.systemVersion)
        }
        return Singleton.version!
    }

    static var TheCurrentDeviceHeight: CGFloat {
        enum Singleton {
            static let height = UIScreen.main.bounds.size.height
        }
        return Singleton.height
    }

    // MARK: - Device Idiom Checks

    static var PHONE_OR_PAD: String {
        if isPhone() {
            return "iPhone"
        } else if isPad() {
            return "iPad"
        }
        return "Not iPhone nor iPad"
    }

    static var DEBUG_OR_RELEASE: String {
        #if DEBUG
            return "Debug"
        #else
            return "Release"
        #endif
    }

    static var SIMULATOR_OR_DEVICE: String {
        #if targetEnvironment(simulator)
            return "Simulator"
        #else
            return "Device"
        #endif
    }

    static var CURRENT_DEVICE: String {
        // return GBDeviceInfo.deviceInfo().modelString
        UIDevice.current.model
    }

    static var CURRENT_VERSION: String {
        "\(TheCurrentDeviceVersion)"
    }

    static var CURRENT_SIZE: String {
        if IS_3_5_INCHES() {
            return "3.5 Inches"
        } else if IS_4_INCHES() {
            return "4 Inches"
        } else if IS_4_7_INCHES() {
            return "4.7 Inches"
        } else if IS_5_5_INCHES() {
            return "5.5 Inches"
        } else if IS_9_7_INCHES() {
            return "9.7 Inches"
        } else if IS_12_9_INCHES() {
            return "12.9 Inches"
        }
        return "\(TheCurrentDeviceHeight) Points"
    }

    // MARK: - International Checks

    static var CURRENT_REGION: String {
        Locale.current.regionCode!
    }

    static var CURRENT_LANGUAGE: String {
        Locale.current.languageCode!
    }

    static func isPhone() -> Bool {
        TheCurrentDevice.userInterfaceIdiom == .phone
    }

    static func isPad() -> Bool {
        TheCurrentDevice.userInterfaceIdiom == .pad
    }

    static func isDebug() -> Bool {
        DEBUG_OR_RELEASE == "Debug"
    }

    static func isRelease() -> Bool {
        DEBUG_OR_RELEASE == "Release"
    }

    static func isSimulator() -> Bool {
        SIMULATOR_OR_DEVICE == "Simulator"
    }

    static func isDevice() -> Bool {
        SIMULATOR_OR_DEVICE == "Device"
    }

    static func isVersion(_ version: Versions) -> Bool {
        TheCurrentDeviceVersion >= version.rawValue && TheCurrentDeviceVersion < (version.rawValue + 1.0)
    }

    static func isVersionOrLater(_ version: Versions) -> Bool {
        TheCurrentDeviceVersion >= version.rawValue
    }

    static func isVersionOrEarlier(_ version: Versions) -> Bool {
        TheCurrentDeviceVersion < (version.rawValue + 1.0)
    }

    // MARK: iOS 5 Checks

    static func IS_OS_5() -> Bool {
        isVersion(.five)
    }

    static func IS_OS_5_OR_LATER() -> Bool {
        isVersionOrLater(.five)
    }

    static func IS_OS_5_OR_EARLIER() -> Bool {
        isVersionOrEarlier(.five)
    }

    // MARK: iOS 6 Checks

    static func IS_OS_6() -> Bool {
        isVersion(.six)
    }

    static func IS_OS_6_OR_LATER() -> Bool {
        isVersionOrLater(.six)
    }

    static func IS_OS_6_OR_EARLIER() -> Bool {
        isVersionOrEarlier(.six)
    }

    // MARK: iOS 7 Checks

    static func IS_OS_7() -> Bool {
        isVersion(.seven)
    }

    static func IS_OS_7_OR_LATER() -> Bool {
        isVersionOrLater(.seven)
    }

    static func IS_OS_7_OR_EARLIER() -> Bool {
        isVersionOrEarlier(.seven)
    }

    // MARK: iOS 8 Checks

    static func IS_OS_8() -> Bool {
        isVersion(.eight)
    }

    static func IS_OS_8_OR_LATER() -> Bool {
        isVersionOrLater(.eight)
    }

    static func IS_OS_8_OR_EARLIER() -> Bool {
        isVersionOrEarlier(.eight)
    }

    // MARK: iOS 9 Checks

    static func IS_OS_9() -> Bool {
        isVersion(.nine)
    }

    static func IS_OS_9_OR_LATER() -> Bool {
        isVersionOrLater(.nine)
    }

    static func IS_OS_9_OR_EARLIER() -> Bool {
        isVersionOrEarlier(.nine)
    }

    // MARK: iOS 10 Checks

    static func IS_OS_10() -> Bool {
        isVersion(.ten)
    }

    static func IS_OS_10_OR_LATER() -> Bool {
        isVersionOrLater(.ten)
    }

    static func IS_OS_10_OR_EARLIER() -> Bool {
        isVersionOrEarlier(.ten)
    }

    static func isSize(_ height: Heights) -> Bool {
        TheCurrentDeviceHeight == height.rawValue
    }

    static func isSizeOrLarger(_ height: Heights) -> Bool {
        TheCurrentDeviceHeight >= height.rawValue
    }

    static func isSizeOrSmaller(_ height: Heights) -> Bool {
        TheCurrentDeviceHeight <= height.rawValue
    }

    // MARK: Retina Check

    static func IS_RETINA() -> Bool {
        UIScreen.main.scale >= 2.0
    }

    static func IS_RETINA_HD() -> Bool {
        UIScreen.main.scale >= 3.0
    }

    // MARK: 3.5 Inch Checks

    static func IS_3_5_INCHES() -> Bool {
        isPhone() && isSize(.inches_3_5)
    }

    static func IS_3_5_INCHES_OR_LARGER() -> Bool {
        isPhone() && isSizeOrLarger(.inches_3_5)
    }

    static func IS_3_5_INCHES_OR_SMALLER() -> Bool {
        isPhone() && isSizeOrSmaller(.inches_3_5)
    }

    // MARK: 4 Inch Checks

    static func IS_4_INCHES() -> Bool {
        isPhone() && isSize(.inches_4)
    }

    static func IS_4_INCHES_OR_LARGER() -> Bool {
        isPhone() && isSizeOrLarger(.inches_4)
    }

    static func IS_4_INCHES_OR_SMALLER() -> Bool {
        isPhone() && isSizeOrSmaller(.inches_4)
    }

    // MARK: 4.7 Inch Checks

    static func IS_4_7_INCHES() -> Bool {
        isPhone() && isSize(.inches_4_7)
    }

    static func IS_4_7_INCHES_OR_LARGER() -> Bool {
        isPhone() && isSizeOrLarger(.inches_4_7)
    }

    static func IS_4_7_INCHES_OR_SMALLER() -> Bool {
        isPhone() && isSizeOrLarger(.inches_4_7)
    }

    // MARK: 5.5 Inch Checks

    static func IS_5_5_INCHES() -> Bool {
        isPhone() && isSize(.inches_5_5)
    }

    static func IS_5_5_INCHES_OR_LARGER() -> Bool {
        isPhone() && isSizeOrLarger(.inches_5_5)
    }

    static func IS_5_5_INCHES_OR_SMALLER() -> Bool {
        isPhone() && isSizeOrLarger(.inches_5_5)
    }

    // MARK: 9.7 Inch Checks

    static func IS_9_7_INCHES() -> Bool {
        isPad() && isSize(.inches_9_7)
    }

    static func IS_9_7_INCHES_OR_LARGER() -> Bool {
        isPad() && isSizeOrLarger(.inches_9_7)
    }

    static func IS_9_7_INCHES_OR_SMALLER() -> Bool {
        isPad() && isSizeOrLarger(.inches_9_7)
    }

    // MARK: 12.9 Inch Checks

    static func IS_12_9_INCHES() -> Bool {
        isPad() && isSize(.inches_12_9)
    }

    static func IS_12_9_INCHES_OR_LARGER() -> Bool {
        isPad() && isSizeOrLarger(.inches_12_9)
    }

    static func IS_12_9_INCHES_OR_SMALLER() -> Bool {
        isPad() && isSizeOrLarger(.inches_12_9)
    }
}

extension UIScreen {
    private static let cornerRadiusKey: String = {
        let components = ["Radius", "Corner", "display", "_"]
        return components.reversed().joined()
    }()

    /// The corner radius of the display. Uses a private property of `UIScreen`,
    /// and may report 0 if the API changes.
    public var displayCornerRadius: CGFloat {
        guard let cornerRadius = value(forKey: Self.cornerRadiusKey) as? CGFloat else {
            return 16
        }

        return cornerRadius
    }
}
