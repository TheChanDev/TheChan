import Foundation

@objc(ChanSettings)
class ChanSettings: NSObject, NSCoding {
    // MARK: Lifecycle

    override init() {
        coder = NSCoder()
    }

    required init(coder: NSCoder) {
        self.coder = coder
        super.init()
        isPostingWithoutCaptchaEnabled =
            coder.containsValue(forKey: Keys.postingWithoutCaptcha)
                ? coder.decodeBool(forKey: Keys.postingWithoutCaptcha)
                : true
    }

    // MARK: Internal

    let coder: NSCoder
    var isPostingWithoutCaptchaEnabled = true

    func encode(with coder: NSCoder) {
        coder.encode(isPostingWithoutCaptchaEnabled, forKey: Keys.postingWithoutCaptcha)
    }

    // MARK: Private

    private enum Keys {
        static let postingWithoutCaptcha = "POSTING_WITHOUT_CAPTCHA"
    }
}
