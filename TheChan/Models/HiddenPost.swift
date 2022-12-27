import Foundation
import RealmSwift

@objc enum HidingMode: Int, RealmEnum {
    case single, tree
}

class HiddenPost: Object {
    @objc dynamic var chanId = ""
    @objc dynamic var boardId = ""
    @objc dynamic var thread = 0
    @objc dynamic var post = 0
    @objc dynamic var mode = HidingMode.single
    @objc dynamic var hidingDate = Date(timeIntervalSince1970: 0)
}
