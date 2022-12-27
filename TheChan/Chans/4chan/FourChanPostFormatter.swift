import Foundation

class FourChanPostFormatter: PostFormatter {
    let supportedTypes: [PostFormattingType] = [
        .spoiler, .quote,
    ]

    func getPrefix(for type: PostFormattingType) -> String {
        if type == .quote {
            return "> "
        }

        return ""
    }

    func getWrappingParts(for type: PostFormattingType) -> (left: String, right: String) {
        switch type {
        case .spoiler:
            return ("[spoiler]", "[/spoiler]")
        default:
            return ("", "")
        }
    }
}
