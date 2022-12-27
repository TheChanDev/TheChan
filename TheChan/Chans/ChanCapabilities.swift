import Foundation

struct ChanCapabiliies: OptionSet {
    // MARK: Internal

    static let captchaBypass = value(0)
    static let catalog = value(1)

    let rawValue: Int

    // MARK: Private

    private static func value(_ offset: Int) -> ChanCapabiliies {
        ChanCapabiliies(rawValue: 1 << offset)
    }
}
