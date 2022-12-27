import Foundation

extension String {
    init(localizedFormat: String, argument: Any) {
        self = NSString.localizedStringWithFormat(
            NSLocalizedString(localizedFormat, comment: "") as NSString,
            argument as! CVarArg
        ) as String
    }

    init(key: String) {
        self = NSLocalizedString(key, comment: "") as String
    }

    func truncate(to length: Int, trailing: String = "…") -> String {
        if count > length {
            return prefix(length) + trailing
        } else {
            return self
        }
    }

    static func += (left: inout String?, right: String) {
        left = (left ?? "") + right
    }

    var withoutCrashingSymbols: String {
        replacingOccurrences(of: "\u{0C1C}\u{0C4D}\u{0C1E}\u{200C}\u{0C3E}", with: "")
            .replacingOccurrences(of: "\u{09B8}\u{09CD}\u{09B0}\u{200C}\u{09C1}", with: "")
            .replacingOccurrences(of: "\u{0C1C}\u{0C4D}\u{0C1E}\u{0C3E}", with: "")
    }
}
