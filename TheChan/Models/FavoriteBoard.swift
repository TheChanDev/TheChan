import Foundation
import RealmSwift

class FavoriteBoard: Object {
    @objc dynamic var chanId = ""
    @objc dynamic var boardId = ""
    @objc dynamic var name = ""

    static func create(from board: Board, chan: Chan) -> FavoriteBoard {
        let result = FavoriteBoard()
        result.boardId = board.id
        result.name = board.name
        result.chanId = chan.id
        return result
    }
}
