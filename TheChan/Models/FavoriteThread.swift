import Foundation
import RealmSwift

class FavoriteThread: Object {
    @objc dynamic var chanId = ""
    @objc dynamic var board = ""
    @objc dynamic var number = 0
    @objc dynamic var name = ""
    @objc dynamic var unreadPosts = 0
    @objc dynamic var lastLoadedPost = 0
    @objc dynamic var lastReadPost = 0
    @objc dynamic var thumbnailUrl = ""

    static func create(
        chan: Chan,
        boardId: String,
        threadNumber: Int,
        opPost: Post,
        lastLoadedPost: Int,
        lastReadPost: Int,
        unreadPosts: Int
    ) -> FavoriteThread {
        let thread = FavoriteThread()
        thread.chanId = chan.id
        thread.board = boardId
        thread.number = threadNumber
        thread.name = opPost.getTitle()
        thread.lastLoadedPost = lastLoadedPost
        thread.lastReadPost = lastReadPost
        thread.unreadPosts = unreadPosts
        if opPost.attachments.count > 0 {
            thread.thumbnailUrl = opPost.attachments[0].thumbnailUrl.absoluteString
        }

        return thread
    }
}
