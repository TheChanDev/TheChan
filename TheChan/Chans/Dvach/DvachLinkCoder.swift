import Foundation

class DvachLinkCoder: LinkCoder {
    func getURL(for link: Link) -> String {
        var url = "https://2ch.hk/"

        guard let board = link as? BoardLink else { return url }
        url += "\(board.boardId)/"

        guard let thread = link as? ThreadLink else { return url }
        url += "res/\(thread.threadNumber).html"

        guard let post = link as? PostLink else { return url }
        url += "#\(post.postNumber)"

        return url
    }

    func parseURL(_ url: String) -> Link? {
        let pattern = "^\\/(\\w+)(\\/res\\/(\\d+).html(#(\\d+))?)?"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) else { return nil }
        guard let match = regex.firstMatch(in: url, options: [], range: NSMakeRange(0, url.count)) else { return nil }

        let boardIdRange = match.range(at: 1)
        let threadNumberRange = match.range(at: 3)
        let postNumberRange = match.range(at: 5)

        let str = url as NSString
        if postNumberRange.length != 0 {
            let postNumber = Int(str.substring(with: postNumberRange))
            let threadNumber = Int(str.substring(with: threadNumberRange))
            let boardId = str.substring(with: boardIdRange)
            return PostLink(boardId: boardId, threadNumber: threadNumber!, number: postNumber!)
        }

        if threadNumberRange.length != 0 {
            let threadNumber = Int(str.substring(with: threadNumberRange))
            let boardId = str.substring(with: boardIdRange)
            return ThreadLink(boardId: boardId, number: threadNumber!)
        }

        if boardIdRange.length != 0 {
            return BoardLink(id: str.substring(with: boardIdRange))
        }

        return nil
    }
}
