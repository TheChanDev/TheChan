import Foundation

enum PostFormattingType {
    case spoiler, bold, italic, underline, strikethrough, sub, sup, quote
}

protocol PostFormatter {
    var supportedTypes: [PostFormattingType] { get }
    func getPrefix(for type: PostFormattingType) -> String
    func getWrappingParts(for type: PostFormattingType) -> (left: String, right: String)
}
