import Foundation

class Board {
    // MARK: Lifecycle

    init(id: String, name: String, isAdult: Bool = false) {
        self.name = name
        self.id = id
        self.isAdult = isAdult
    }

    // MARK: Internal

    var id: String
    var name: String
    var isAdult: Bool

    var description: String {
        "Board(\(id), '\(name)')"
    }
}
