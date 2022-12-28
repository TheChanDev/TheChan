import Foundation

class DvachMapper {
    // MARK: Lifecycle

    init(linkCoder: LinkCoder) {
        self.linkCoder = linkCoder
    }

    // MARK: Internal

    let linkCoder: LinkCoder
    let countryCodeRegex = try! NSRegularExpression(
        pattern: "<img.*src=\"\\/flags\\/(\\w+).*\"",
        options: .caseInsensitive
    )

    func map(boards: [[String: AnyObject]]) -> [BoardsGroup] {
        Dictionary(grouping: boards, by: { $0["category"] as? String ?? "" }).map { name, boards in
            BoardsGroup(name: name, boards: boards.map(map(board:)))
        }.sorted(by: { $0.name < $1.name })
    }

    func map(board: [String: AnyObject]) -> Board {
        let id = board["id"] as? String ?? ""
        return Board(
            id: id,
            name: board["name"] as? String ?? "",
            isAdult: id == "b" || board["category"] as? String == "Взрослым"
        )
    }

    func map(threads: [[String: AnyObject]]) -> [Thread] {
        threads.map { thread in
            let result = Thread()
            result.omittedPosts = thread["posts_count"] as? Int ?? 0
            result.omittedFiles = thread["files_count"] as? Int ?? 0
            var posts = (thread["posts"] as? [[String: AnyObject]] ?? []).map { post in map(post: post) }
            if posts.count > 0 {
                result.opPost = posts[0]
                posts.remove(at: 0)
                result.omittedPosts += posts.count
                result.omittedFiles += posts.reduce(0) { count, post in count + post.attachments.count }
            }

            return result
        }
    }

    func map(catalogThreads: [[String: AnyObject]]) -> [Thread] {
        catalogThreads.map { thread in
            let result = Thread()
            result.omittedPosts = thread["posts_count"] as? Int ?? 0
            result.omittedFiles = thread["files_count"] as? Int ?? 0
            result.opPost = map(post: thread)
            return result
        }
    }

    func map(post raw: [String: Any]) -> Post {
        let post = Post()

        let html = raw["comment"] as? String ?? ""
        post.content = html

        // Fields
        post.subject = String(htmlEncodedString: raw["subject"] as? String ?? "")
        post.name = String(htmlEncodedString: raw["name"] as? String ?? "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        if post.name == "Anonymous" {
            post.name = "Аноним"
        }

        post.number = raw["num"] as? Int ?? 0
        post.trip = raw["trip"] as? String ?? ""

        post.email = raw["email"] as? String ?? ""
        if post.email.hasPrefix("mailto:") {
            post.email.removeSubrange(post.email.startIndex ..< "mailto:".endIndex)
        }

        if let flag = raw["icon"] as? NSString,
           let match = countryCodeRegex.firstMatch(
               in: flag as String,
               options: [],
               range: NSRange(location: 0, length: flag.length)
           )
        {
            post.countryCode = flag.substring(with: match.range(at: 1)) as String
        }

        // Files
        if let files = raw["files"] as? [[String: AnyObject]] {
            post.attachments = files.map { file in map(attachment: file) }
        }

        // Date
        let timestamp = (raw["timestamp"] as? NSNumber)?.int64Value ?? 0
        post.date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        let boolMarkers = ["op": PostMarkers.op, "closed": .closed, "banned": .banned]

        for (field, marker) in boolMarkers {
            if raw[field] as? Bool == true {
                post.markers.insert(marker)
            }
        }

        if raw["sticky"] as? Int ?? 0 != 0 {
            post.markers.insert(.pinned)
        }

        return post
    }

    func map(attachment raw: [String: AnyObject]) -> Attachment {
        let url = "https://2ch.hk\(raw["path"] as? String ?? "")"
        let thumbUrl = "https://2ch.hk\(raw["thumbnail"] as? String ?? "")"
        let size = (
            raw["width"] as? Int ?? 0,
            raw["height"] as? Int ?? 0
        )

        let thSize = (
            raw["th_width"] as? Int ?? 0,
            raw["th_height"] as? Int ?? 0
        )

        let fileExt = url.components(separatedBy: ".").last ?? "png"
        var type = AttachmentType.image
        if fileExt == "webm" || fileExt == "mp4" {
            type = .video
        }

        let attachment = Attachment(url: url, thumbUrl: thumbUrl, size: size, thumbSize: thSize, type: type)
        attachment.fileSize = raw["size"] as? Int ?? 0
        attachment.name = raw["fullname"] as? String ?? raw["name"] as? String ?? "unknown"

        return attachment
    }

    func map(postingData post: PostingData) -> [String: String] {
        var dict: [String: String] = [
            "board": post.boardId,
            "thread": String(post.threadNumber),
            "comment": post.text,
            "op_mark": post.isOp ? "1" : "0",
            "subject": post.subject,
            "email": post.email,
            "name": post.name,
        ]

        if let capthaResult = post.captchaResult {
            if capthaResult.captcha is ImageCaptcha {
                dict["captcha_type"] = "2chcaptcha"
                dict["2chcaptcha_id"] = capthaResult.captcha.key
                dict["2chcaptcha_value"] = capthaResult.input
            } else if capthaResult.captcha is ReCaptcha {
                dict["captcha_type"] = "recaptcha"
                dict["g-recaptcha-response"] = capthaResult.input
            }
        }

        return dict
    }

    func getError(from data: [String: Any]?) -> String? {
        guard let data = data else { return nil }
        return data["Error"] as? String ?? (data["error"] as? [String: Any])?["message"] as? String
    }
}
