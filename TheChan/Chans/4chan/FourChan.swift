import Alamofire
import Foundation

class FourChan: Chan {
    // MARK: Lifecycle

    init() {
        mapper = FourChanMapper(linkCoder: linkCoder)
    }

    // MARK: Internal

    let id = "4chan"
    let defaultName = "Anonymous"
    let lightColor = #colorLiteral(red: 0.2896378277, green: 0.6322529841, blue: 0.1062434565, alpha: 1)
    let darkColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
    let icon = #imageLiteral(resourceName: "4chan")
    let maxAttachments = 1
    let postFormatter: PostFormatter = FourChanPostFormatter()
    var settings = ChanSettings()
    var linkCoder: LinkCoder = FourChanLinkCoder()
    var capabilities = ChanCapabiliies.catalog

    func loadBoards(onComplete: @escaping ([BoardsGroup]?, String?) -> Void) {
        getAndMapDictionary("https://a.4cdn.org/boards.json", mapping: { result in
            let boards = self.mapper.map(boards: result["boards"] as? [[String: AnyObject]] ?? [])
            return [BoardsGroup(name: "", boards: boards)]
        }, onComplete: onComplete)
    }

    func loadThreads(boardId: String, page: Int, onComplete: @escaping ([Thread]?, String?) -> Void) {
        let url = "https://a.4cdn.org/\(boardId)/\(page + 1).json"
        getAndMapDictionary(url, mapping: { result in
            let threads = self.mapper.map(threads: result["threads"] as? [[String: AnyObject]] ?? [], board: boardId)
            return threads
        }, onComplete: onComplete)
    }

    func loadCatalog(boardId: String, onComplete: @escaping ([Thread]?, String?) -> Void) {
        let url = "https://a.4cdn.org/\(boardId)/catalog.json"
        getAndMapList(url, mapping: { (catalog: [[String: Any]]) -> [Thread]? in
            self.mapper.map(catalog: catalog, board: boardId)
        }, errorMapping: { _ in nil }, onComplete: onComplete)
    }

    func loadThread(boardId: String, number: Int, from: Int?, onComplete: @escaping ([Post]?, String?) -> Void) {
        let url = "https://a.4cdn.org/\(boardId)/thread/\(number).json"
        getAndMapDictionary(url, mapping: { result in
            let rawPosts = Array(result["posts"] as? [[String: AnyObject]] ?? [])
            let posts = self.mapper.map(posts: rawPosts, board: boardId).drop { post in
                guard let from = from else { return false }

                return post.number <= from
            }
            return Array(posts)
        }, onComplete: onComplete)
    }

    func isCaptchaEnabled(in board: String, forCreatingThread: Bool, onComplete: @escaping (Bool) -> Void) {
        onComplete(true)
    }

    func getCaptcha(boardId: String, threadNumber: Int?, onComplete: @escaping (Captcha?, CaptchaError?) -> Void) {
        onComplete(SliderCaptcha(key: "", board: boardId, threadNumber: threadNumber), nil)
//        var url = "https://sys.4chan.org/captcha?board=\(boardId)"
//        if let threadNumber {
//            url += "&thread_id=\(threadNumber)"
//        }
//
//        let headers: HTTPHeaders = [
//            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
//            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
//            "Referer": url,
//        ]
//
//        getAndMapDictionary(
//            url,
//            headers: headers,
//            mapping: mapper.map(sliderCaptcha:),
//            errorMapping: { response, code in
//                if let cooldown = response?["cd"] as? Int {
//                    return CaptchaError.cooldown(seconds: cooldown)
//                } else if let error = response?["error"] as? String {
//                    return CaptchaError.other(error)
//                } else if code == 503 {
//                    return CaptchaError.authorizationRequired(URL(string: url)!)
//                } else {
//                    return CaptchaError.invalidResponse
//                }
//            },
//            onComplete: onComplete
//        )
    }

    func send(post: PostingData, onComplete: @escaping (Bool, String?, Int?) -> Void) {
        let url = "https://sys.4chan.org/\(post.boardId)/post"
        let data = mapper.map(postingData: post)
        Alamofire.upload(multipartFormData: { formData in
            for (key, value) in data {
                formData.append(value.data(using: .utf8)!, withName: key)
            }

            if let file = post.attachments.first {
                formData.append(file.data, withName: "upfile", fileName: file.name, mimeType: file.mimeType)
            }
        }, to: url) { encodingResult in
            switch encodingResult {
            case .success(let request, _, _):
                request.responseString { response in
                    if let result = response.result.value {
                        let (isSuccess, message, num) = self.mapper.map(postingResult: result)
                        onComplete(isSuccess, message, num)
                    } else {
                        onComplete(false, String(response.response?.statusCode ?? 404), nil)
                    }
                }
            default:
                onComplete(false, nil, nil)
            }
        }
    }

    func getMarkupParser(for html: String, theme: Theme, userInterfaceStyle: UIUserInterfaceStyle) -> MarkupParser? {
        FourChanMarkup(
            from: html,
            linkCoder: linkCoder,
            theme: theme,
            tintColor: tintColor(for: theme, userInterfaceStyle: userInterfaceStyle)
        )
    }

    // MARK: Private

    private let mapper: FourChanMapper
}
