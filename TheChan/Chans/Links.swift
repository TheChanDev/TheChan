import Foundation

class Link {
    func internalURL() -> String {
        "thechan://"
    }
}

class BoardLink: Link {
    // MARK: Lifecycle

    init(id: String) {
        boardId = id
    }

    // MARK: Internal

    let boardId: String

    override func internalURL() -> String {
        super.internalURL() + "\(boardId)/"
    }
}

class ThreadLink: BoardLink {
    // MARK: Lifecycle

    init(boardId: String, number: Int) {
        threadNumber = number
        super.init(id: boardId)
    }

    // MARK: Internal

    let threadNumber: Int

    override func internalURL() -> String {
        super.internalURL() + "\(threadNumber)/"
    }
}

class PostLink: ThreadLink {
    // MARK: Lifecycle

    init(boardId: String, threadNumber: Int, number: Int) {
        postNumber = number
        super.init(boardId: boardId, number: threadNumber)
    }

    // MARK: Internal

    let postNumber: Int
    var isSameThread = false

    override func internalURL() -> String {
        if isSameThread {
            return "thechan-post://\(postNumber)"
        }

        return super.internalURL() + "\(postNumber)"
    }
}
