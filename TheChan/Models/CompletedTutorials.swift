import Foundation

struct CompletedTutorials: OptionSet {
    // MARK: Internal

    static let customBoards = value(0)
    static let review = value(1)

    let rawValue: Int

    // MARK: Private

    private static func value(_ offset: Int) -> CompletedTutorials {
        CompletedTutorials(rawValue: 1 << offset)
    }
}
