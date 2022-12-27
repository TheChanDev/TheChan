import Foundation
import RealmSwift

class HistoryItem: Object {
    @objc dynamic var chanId = ""
    @objc dynamic var board = ""
    @objc dynamic var number = 0
    @objc dynamic var name = ""
    @objc dynamic var position = 0
    @objc dynamic var lastVisit = Date()
}
