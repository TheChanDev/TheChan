import Foundation

class FourChanMapper {
    // MARK: Lifecycle

    init(linkCoder: LinkCoder) {
        self.linkCoder = linkCoder
    }

    // MARK: Internal

    func map(boards: [[String: AnyObject]]) -> [Board] {
        boards.map { board in
            Board(
                id: board["board"] as? String ?? "",
                name: board["title"] as? String ?? "",
                isAdult: (board["ws_board"] as? Int ?? 1) == 0
            )
        }
    }

    func map(catalog: [[String: Any]], board: String) -> [Thread] {
        catalog.flatMap { (page: [String: Any]) -> [Thread] in
            if let threads = page["threads"] as? [[String: AnyObject]] {
                return threads.map { map(catalogThread: $0, board: board) }
            }

            return []
        }
    }

    func map(catalogThread: [String: AnyObject], board: String) -> Thread {
        let thread = Thread()
        thread.opPost = map(post: catalogThread, board: board)
        thread.omittedPosts = catalogThread["omitted_posts"] as? Int ?? 0
        thread.omittedFiles = catalogThread["omitted_images"] as? Int ?? 0
        return thread
    }

    func map(threads: [[String: AnyObject]], board: String) -> [Thread] {
        threads.map { map(thread: $0, board: board) }
    }

    func map(thread raw: [String: AnyObject], board: String) -> Thread {
        let thread = Thread()
        guard let posts = raw["posts"] as? [[String: AnyObject]] else { return thread }
        let rawOpPost = posts[0]
        thread.opPost = map(post: rawOpPost, board: board)
        thread.omittedFiles = rawOpPost["images"] as? Int ?? 0
        thread.omittedPosts = rawOpPost["replies"] as? Int ?? 0

        return thread
    }

    func map(posts: [[String: AnyObject]], board: String) -> [Post] {
        posts.map { map(post: $0, board: board) }
    }

    func map(post raw: [String: AnyObject], board: String) -> Post {
        let post = Post()
        post.number = raw["no"] as? Int ?? 0
        post.name = String(htmlEncodedString: raw["name"] as? String ?? "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        post.subject = String(htmlEncodedString: raw["sub"] as? String ?? "")
        post.countryCode = raw["country"] as? String ?? ""
        post.trip =
            raw["id"] as? String ??
            raw["trip"] as? String ??
            (raw["capcode"] as? String ?? "").capitalized

        let comment = raw["com"] as? String ?? ""
        post.content = comment

        post.parent = raw["resto"] as? Int ?? 0
        if let time = (raw["tim"] as? NSNumber)?.int64Value {
            let ext = raw["ext"] as? String ?? ""
            let url = "https://i.4cdn.org/\(board)/\(time)\(ext)"
            let tnUrl = "https://i.4cdn.org/\(board)/\(time)s.jpg"
            let width = raw["w"] as? Int ?? 0
            let height = raw["h"] as? Int ?? 0
            let tnWidth = raw["tn_w"] as? Int ?? 0
            let tnHeight = raw["tn_h"] as? Int ?? 0
            let type = ext == ".webm" ? AttachmentType.video : .image
            let attachment = Attachment(
                url: url,
                thumbUrl: tnUrl,
                size: (width, height),
                thumbSize: (tnWidth, tnHeight),
                type: type
            )

            attachment.name = "\(raw["filename"] as? String ?? "")\(ext)"
            attachment.fileSize = Int(round(Double(raw["fsize"] as? Int ?? 0) / 1024))

            post.attachments.append(attachment)
        }

        let boolMarkers = ["closed": PostMarkers.closed, "sticky": .pinned]

        for (field, marker) in boolMarkers {
            if raw[field] as? Bool == true {
                post.markers.insert(marker)
            }
        }

        let timestamp = (raw["time"] as? NSNumber)?.int64Value ?? 0
        post.date = Date(timeIntervalSince1970: TimeInterval(timestamp))

        return post
    }

//    func map(sliderCaptcha raw: [String: Any]) -> SliderCaptcha? {
//        let key = SliderCaptcha.CodingKeys.self
//        guard
//            let challenge = raw[key.key.rawValue] as? String,
//            let fg = (raw[key.foregroundImage.rawValue] as? String).flatMap({
//                $0.data(using: .utf8)
//            }).flatMap({ Data(base64Encoded: $0) }),
//            let bg = (raw[key.backgroundImage.rawValue] as? String).flatMap({
//                $0.data(using: .utf8)
//            }).flatMap({ Data(base64Encoded: $0) })
//        else { return nil }
//
//        return SliderCaptcha(
//            key: challenge,
//            foregroundImage: fg,
//            backgroundImage: bg
//        )
//    }

    func map(postingData data: PostingData) -> [String: String] {
        var dict: [String: String] = [
            "mode": "regist",
            "resto": String(data.threadNumber),
            "com": data.text,
            "sub": data.subject,
            "name": data.name,
            "email": data.email,
        ]

        if let captchaResullt = data.captchaResult, captchaResullt.captcha is ReCaptcha {
            dict["g-recaptcha-response"] = captchaResullt.input
        } else if let captchaResullt = data.captchaResult, captchaResullt.captcha is SliderCaptcha {
            dict["t-challenge"] = captchaResullt.captcha.key
            dict["t-response"] = captchaResullt.input
        }

        return dict
    }

    func map(postingResult result: String) -> (Bool, String?, Int?) {
        let string = result as NSString
        let range = NSMakeRange(0, string.length)
        if let errorMatch = errorRegex.firstMatch(in: result, options: [], range: range) {
            let messageRange = errorMatch.range(at: 1)
            let message = string.substring(with: messageRange)
            return (false, message, nil)
        } else if let successMatch = successRegex.firstMatch(in: result, options: [], range: range) {
            let numberRange = successMatch.range(at: 2)
            let number = string.substring(with: numberRange)
            if let intNumber = Int(number) {
                return (true, nil, intNumber)
            }
        }

        return (false, "Unable to parse response", nil)
    }

    // MARK: Private

    private let linkCoder: LinkCoder

    private let errorRegex = try! NSRegularExpression(pattern: "\"errmsg\"[^>]*>(.*?)<\\/span", options: [])
    private let successRegex = try! NSRegularExpression(pattern: "<!-- thread:([0-9]+),no:([0-9]+) -->", options: [])
}
