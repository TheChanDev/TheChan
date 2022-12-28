import Alamofire
import Foundation

protocol Chan: AnyObject {
    var id: String { get }
    var defaultName: String { get }
    var maxAttachments: Int { get }
    var capabilities: ChanCapabiliies { get }
    var lightColor: UIColor { get }
    var darkColor: UIColor { get }
    var icon: UIImage { get }
    var postFormatter: PostFormatter { get }
    var settings: ChanSettings { get set }
    var linkCoder: LinkCoder { get }

    func loadBoards(onComplete: @escaping ([BoardsGroup]?, String?) -> Void)
    func loadThreads(boardId: String, page: Int, onComplete: @escaping ([Thread]?, String?) -> Void)
    func loadCatalog(boardId: String, onComplete: @escaping ([Thread]?, String?) -> Void)
    func loadThread(boardId: String, number: Int, from: Int?, onComplete: @escaping ([Post]?, String?) -> Void)
    func isCaptchaEnabled(in board: String, forCreatingThread: Bool, onComplete: @escaping (Bool) -> Void)
    func getCaptcha(boardId: String, threadNumber: Int?, onComplete: @escaping (Captcha?, CaptchaError?) -> Void)
    func send(post: PostingData, onComplete: @escaping (Bool, PostingError?, Int?) -> Void)

    func getMarkupParser(for html: String, theme: Theme, userInterfaceStyle: UIUserInterfaceStyle) -> MarkupParser?
}

extension Chan {
    var capabilities: ChanCapabiliies {
        []
    }

    private func get(_ url: String, onComplete: @escaping (Any?, String?) -> Void) {
        AlamofireManager.instance.request(url).responseJSON { response in
            switch response.result {
            case .success(let value):
                onComplete(value, nil)
            case .failure(let error):
                let code = response.response?.statusCode ?? 0
                let message = code > 0 ? "HTTP \(code)" : error.localizedDescription
                onComplete(nil, message)
            }
        }
    }

    func getAndMapDictionary<T>(
        _ url: String,
        mapping: @escaping ([String: AnyObject]) -> T?,
        onComplete: @escaping (T?, String?) -> Void
    ) {
        get(url) { result, error in
            if error != nil {
                onComplete(nil, error)
            } else if let dictionary = result as? [String: AnyObject] {
                onComplete(mapping(dictionary), nil)
            } else {
                onComplete(nil, "Invalid JSON")
            }
        }
    }

    func getAndMapDictionary<T, E>(
        _ url: String,
        headers: HTTPHeaders? = nil,
        mapping: @escaping ([String: Any]) -> T?,
        errorMapping: @escaping ([String: Any]?, Int) -> E?,
        onComplete: @escaping (T?, E?) -> Void
    ) {
        AlamofireManager.instance.request(url, headers: headers).responseJSON { response in
            let code = response.response?.statusCode ?? -1
            switch response.result {
            case .success(let value):
                guard let dictionary = value as? [String: Any] else {
                    onComplete(nil, errorMapping(nil, code))
                    return
                }

                if let result = mapping(dictionary) {
                    onComplete(result, nil)
                } else {
                    onComplete(nil, errorMapping(dictionary, code))
                }
            case .failure:
                onComplete(nil, errorMapping(nil, code))
            }
        }
    }

    func getAndMapList<T, RawListType>(
        _ url: String,
        mapping: @escaping ([RawListType]) -> T?,
        errorMapping: @escaping ([String: Any]) -> String?,
        onComplete: @escaping (T?, String?) -> Void
    ) {
        get(url) { result, error in
            if error != nil {
                onComplete(nil, error)
            } else if let list = result as? [RawListType] {
                onComplete(mapping(list), nil)
            } else if let data = result as? [String: Any], let error = errorMapping(data) {
                onComplete(nil, error)
            } else {
                onComplete(nil, "Invalid JSON")
            }
        }
    }
}

enum CaptchaError {
    case authorizationRequired(URL)
    case invalidResponse
    case cooldown(seconds: Int)
    case other(String)

    // MARK: Internal

    var helpMessage: String? {
        switch self {
        case .cooldown(let seconds):
            return String(format: String(key: "POSTING_ERROR_COOLDOWN"), String(seconds))
        case .other, .invalidResponse, .authorizationRequired:
            return nil
        }
    }
}

enum PostingError {
    case authorizationRequired(URL)
    case http(Int)
    case other(String)
    case unknown
}

class AlamofireManager: SessionManager {
    // MARK: Lifecycle

    init() {
        configuration.timeoutIntervalForRequest = 30
        configuration.httpCookieStorage = HTTPCookieStorage.shared
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        super.init(configuration: configuration)
    }

    // MARK: Internal

    static let instance = AlamofireManager()

    override func request(
        _ url: URLConvertible,
        method: HTTPMethod = .get,
        parameters: Parameters? = nil,
        encoding: ParameterEncoding = URLEncoding.default,
        headers: HTTPHeaders? = nil
    ) -> DataRequest {
        super.request(
            url,
            method: method,
            parameters: parameters,
            encoding: encoding,
            headers: self.headers(for: url).merging(headers ?? [:], uniquingKeysWith: { h, _ in h })
        )
    }

    override func upload(
        multipartFormData: @escaping (MultipartFormData) -> Void,
        usingThreshold encodingMemoryThreshold: UInt64 = SessionManager.multipartFormDataEncodingMemoryThreshold,
        to url: URLConvertible,
        method: HTTPMethod = .post,
        headers: HTTPHeaders? = nil,
        queue: DispatchQueue? = nil,
        encodingCompletion: ((SessionManager.MultipartFormDataEncodingResult) -> Void)?
    ) {
        super.upload(
            multipartFormData: multipartFormData,
            usingThreshold: encodingMemoryThreshold,
            to: url,
            method: method,
            headers: self.headers(for: url).merging(headers ?? [:], uniquingKeysWith: { h, _ in h }),
            queue: queue,
            encodingCompletion: encodingCompletion
        )
    }

    func headers(for url: URLConvertible) -> HTTPHeaders {
        var resultHeaders = [
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "User-Agent": "Mozilla/5.0 (iPhone; CPU iPhone OS 16_1 like Mac OS X)" +
                " AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148",
        ]

        guard let url = try? url.asURL(),
              let cookies = HTTPCookieStorage.shared.cookies(for: url)
        else { return resultHeaders }

        HTTPCookie.requestHeaderFields(with: cookies).forEach { name, value in
            resultHeaders[name] = value
        }

        return resultHeaders
    }

    // MARK: Private

    private let configuration = URLSessionConfiguration.default
}
