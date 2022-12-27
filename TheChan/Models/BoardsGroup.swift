import Foundation

class BoardsGroup {
    // MARK: Lifecycle

    init(name: String, boards: [Board] = []) {
        self.name = name
        self.boards = boards
    }

    // MARK: Internal

    var name: String
    var boards: [Board]
}
