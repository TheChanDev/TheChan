import Alamofire
import Foundation

class Dvach: Chan {
    // MARK: Lifecycle

    init() {
        mapper = DvachMapper(linkCoder: linkCoder)
    }

    // MARK: Internal

    let id = "2ch"
    let defaultName = "Аноним"
    let capabilities: ChanCapabiliies = [.catalog]
    let postFormatter: PostFormatter = DvachFormatter()
    let darkColor = UIColor(red: 255 / 255.0, green: 149 / 255.0, blue: 0.0, alpha: 1.0)
    let lightColor = #colorLiteral(red: 0.9098039216, green: 0.4196078431, blue: 0.03529411765, alpha: 1)
    let icon = #imageLiteral(resourceName: "2ch")
    var settings = ChanSettings()
    let linkCoder: LinkCoder = DvachLinkCoder()

    var maxAttachments: Int { 4 }

    func loadBoards(onComplete: @escaping ([BoardsGroup]?, String?) -> Void) {
        getAndMapList(
            "https://2ch.hk/api/mobile/v2/boards",
            mapping: mapper.map(boards:),
            errorMapping: mapper.getError(from:),
            onComplete: onComplete
        )
    }

    func loadThreads(boardId: String, page: Int, onComplete: @escaping ([Thread]?, String?) -> Void) {
        let pageStr = page == 0 ? "index" : String(page)
        getAndMapDictionary("https://2ch.hk/\(boardId)/\(pageStr).json", mapping: { page -> [Thread]? in
            if let rawThreads = page["threads"] as? [[String: AnyObject]] {
                return self.mapper.map(threads: rawThreads)
            }

            return nil
        }, onComplete: onComplete)
    }

    func loadCatalog(boardId: String, onComplete: @escaping ([Thread]?, String?) -> Void) {
        getAndMapDictionary("https://2ch.hk/\(boardId)/catalog.json", mapping: { page -> [Thread]? in
            if let rawThreads = page["threads"] as? [[String: AnyObject]] {
                return self.mapper.map(catalogThreads: rawThreads)
            }

            return nil
        }, onComplete: onComplete)
    }

    func loadThread(boardId: String, number: Int, from: Int?, onComplete: @escaping ([Post]?, String?) -> Void) {
        if let from, from > number {
            let url = "https://2ch.hk/api/mobile/v2/after/\(boardId)/\(number)/\(from)"
            getAndMapDictionary(url, mapping: { response in
                guard let posts = response["posts"] as? [[String: Any]] else { return nil }
                let result = posts.enumerated().map { index, rawPost in
                    // in pinned thread all posts get marked as pinned, we don't need that
                    let post = self.mapper.map(post: rawPost)
                    if index > 0 || from > 0 {
                        post.markers.remove(.pinned)
                    }

                    return post
                }.drop(while: { $0.number <= from })

                return Array(result)
            }, errorMapping: { r, _ in self.mapper.getError(from: r) }, onComplete: onComplete)
        } else {
            let url = "https://2ch.hk/\(boardId)/res/\(number).json"
            getAndMapDictionary(url, mapping: { response in
                guard let threads = response["threads"] as? [[String: Any]],
                      let thread = threads.first,
                      let posts = thread["posts"] as? [[String: Any]] else { return nil }
                return posts.enumerated().map { index, rawPost in
                    let post = self.mapper.map(post: rawPost)
                    if index > 0 {
                        post.markers.remove(.pinned)
                    }

                    return post
                }
            }, errorMapping: {
                r, c in self.mapper.getError(from: r) ?? "HTTP \(c)"
            }, onComplete: onComplete)
        }
    }

    func isCaptchaEnabled(in board: String, forCreatingThread: Bool, onComplete: @escaping (Bool) -> Void) {
        getAndMapDictionary(
            "https://2ch.hk/api/captcha/settings/\(board)",
            mapping: {
                $0["enabled"] as? Bool
            }
        ) { isEnabled, _ in
            onComplete(isEnabled ?? true)
        }
    }

    func getCaptcha(boardId: String, threadNumber: Int?, onComplete: @escaping (Captcha?, CaptchaError?) -> Void) {
        get2chCaptcha(boardId: boardId, threadNumber: threadNumber, onComplete: onComplete)
    }

    func getReCaptcha(boardId: String, threadNumber: Int?, onComplete: @escaping (Captcha?, CaptchaError?) -> Void) {
        var url = "https://2ch.hk/api/captcha/recaptcha/id?board=\(boardId)"
        if let threadNumber { url += "&thread=\(threadNumber)" }

        getAndMapDictionary(
            url,
            mapping: { result in
                guard let key = result["id"] as? String,
                      let baseURL = URL(string: "https://2ch.hk/\(boardId)")
                else { return nil }
                return ReCaptcha(key: key, baseURL: baseURL)
            }, errorMapping: { r, code in
                code == 503
                    ? .authorizationRequired(URL(string: url)!)
                    : self.mapper.getError(from: r).flatMap(CaptchaError.other)
            },
            onComplete: { captcha, error in onComplete(captcha, error) }
        )
    }

    func get2chCaptcha(boardId: String, threadNumber: Int?, onComplete: @escaping (Captcha?, CaptchaError?) -> Void) {
        var url = "https://2ch.hk/api/captcha/2chcaptcha/id?board=\(boardId)"
        if let threadNumber { url += "&thread=\(threadNumber)" }

        getAndMapDictionary(
            url,
            mapping: { result in
                guard let key = result["id"] as? String,
                      let imageURL = URL(string: "https://2ch.hk/api/captcha/2chcaptcha/show?id=\(key)")
                else { return nil }
                let captcha = ImageCaptcha()
                captcha.key = key
                captcha.imageURL = imageURL

                return captcha
            }, errorMapping: { r, code in
                code == 503
                    ? .authorizationRequired(URL(string: url)!)
                    : self.mapper.getError(from: r).flatMap(CaptchaError.other)
            },
            onComplete: { captcha, error in onComplete(captcha, error) }
        )
    }

    func send(post: PostingData, onComplete: @escaping (Bool, PostingError?, Int?) -> Void) {
        let data = mapper.map(postingData: post)
        send(data: data, post: post, onComplete: onComplete)
    }

    func send(data: [String: String], post: PostingData, onComplete: @escaping (Bool, PostingError?, Int?) -> Void) {
        let url = "https://2ch.hk/user/posting?nc=1"
        AlamofireManager.instance.upload(multipartFormData: { formData in
            for (key, value) in data {
                formData.append(value.data(using: .utf8)!, withName: key)
            }

            for (index, attachment) in post.attachments.enumerated() {
                formData.append(
                    attachment.data,
                    withName: "image\(index)",
                    fileName: attachment.name,
                    mimeType: attachment.mimeType
                )
            }
        }, to: url) { encodingResult in
            switch encodingResult {
            case .success(let request, _, _):
                request.responseJSON { response in
                    if let result = response.result.value as? [String: Any] {
                        let error = result["error"] as? [String: Any]
                        let num = result["num"] as? Int ?? result["thread"] as? Int
                        if let error, let message = error["message"] as? String {
                            onComplete(false, .other(message), nil)
                        } else {
                            onComplete(true, nil, num)
                        }
                    } else {
                        let error: PostingError
                        switch response.response?.statusCode {
                        case 503:
                            error = .authorizationRequired(URL(string: "https://2ch.hk/\(post.boardId)")!)
                        case .some(let code):
                            error = .http(code)
                        case .none:
                            error = .unknown
                        }

                        onComplete(false, error, nil)
                    }
                }
            default:
                onComplete(false, .unknown, nil)
            }
        }
    }

    func getMarkupParser(for html: String, theme: Theme, userInterfaceStyle: UIUserInterfaceStyle) -> MarkupParser? {
        DvachMarkup(
            from: html,
            linkCoder: linkCoder,
            theme: theme,
            tintColor: tintColor(for: theme, userInterfaceStyle: userInterfaceStyle)
        )
    }

    // MARK: Private

    private let mapper: DvachMapper
}
