import Foundation

class DvachFormatter: PostFormatter {
    let supportedTypes: [PostFormattingType] = [
        .bold, .underline, .spoiler, .italic, .strikethrough, .sub, .sup, .quote,
    ]

    func getPrefix(for type: PostFormattingType) -> String {
        if type == .quote {
            return "> "
        }

        return ""
    }

    func getWrappingParts(for type: PostFormattingType) -> (left: String, right: String) {
        switch type {
        case .bold:
            return ("[b]", "[/b]")
        case .italic:
            return ("[i]", "[/i]")
        case .spoiler:
            return ("[spoiler]", "[/spoiler]")
        case .underline:
            return ("[u]", "[/u]")
        case .strikethrough:
            return ("[s]", "[/s]")
        case .sub:
            return ("[sub]", "[/sub]")
        case .sup:
            return ("[sup]", "[/sup]")
        default:
            return ("", "")
        }
    }
}
