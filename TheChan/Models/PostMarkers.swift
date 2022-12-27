import Foundation

struct PostMarkers: OptionSet, Hashable {
    // MARK: Internal

    static let op = value(0)
    static let banned = value(1)
    static let pinned = value(3)
    static let closed = value(4)
    static let userPost = value(5)

    let rawValue: Int

    var hashValue: Int {
        rawValue
    }

    func stringValue() -> String {
        switch self {
        case PostMarkers.op:
            return "OP"
        case PostMarkers.banned:
            return "BAN"
        case PostMarkers.pinned:
            return "PIN"
        case PostMarkers.closed:
            return "CLOS"
        case PostMarkers.userPost:
            return "Y"
        default:
            return "UNKNWN"
        }
    }

    // MARK: Private

    private static func value(_ offset: Int) -> PostMarkers {
        PostMarkers(rawValue: 1 << offset)
    }
}
