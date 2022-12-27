import Alamofire

struct APIError: Codable, Error {
    // MARK: Lifecycle

    private init(of kind: Kind, with message: String) {
        code = kind.rawValue
        error = message
    }

    init(_ kind: Kind) {
        self.init(of: kind, with: APIError.messageKeys[kind] ?? String(key: "ERR_UNKNOWN"))
    }

    init(other error: Error) {
        self.init(of: .other, with: error.localizedDescription)
    }

    // MARK: Internal

    enum Kind: Int {
        case invalidCredentials = 101
        case invalidSession = 209
        case invalidResponse = -1
        case unknown = -2
        case other = -3
    }

    let code: Int
    let error: String

    func isOfKind(_ kind: Kind) -> Bool {
        code == kind.rawValue
    }

    // MARK: Private

    private static let messageKeys: [Kind: String] = [
        .invalidResponse: "ERR_INVALID_RESPONSE",
    ]
}

class API {
    // MARK: Lifecycle

    private init() {}

    // MARK: Internal

    static let shared = API()

    let decoder = JSONDecoder()

    func register(withLogin login: String, password: String, completion: @escaping (User?, APIError?) -> Void) {
        AlamofireManager.instance.request(
            url("users"),
            method: .post,
            parameters: [
                "username": login,
                "password": password,
            ],
            headers: defaultHeaders
        ).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    var user = try self.decoder.decode(User.self, from: data)
                    if user.username == nil {
                        user.username = login
                    }

                    completion(user, nil)
                } catch {
                    completion(nil, self.error(from: data))
                }

            case .failure(let error):
                completion(nil, APIError(other: error))
            }
        }
    }

    func signIn(withLogin login: String, password: String, completion: @escaping (User?, APIError?) -> Void) {
        AlamofireManager.instance.request(
            url("login"),
            parameters: [
                "username": login,
                "password": password,
            ],
            headers: defaultHeaders
        ).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let user = try self.decoder.decode(User.self, from: data)
                    completion(user, nil)
                } catch {
                    completion(nil, self.error(from: data))
                }

            case .failure(let error):
                completion(nil, APIError(other: error))
            }
        }
    }

    func fetchCurrentUser(withSessionToken token: String, completion: @escaping (User?, APIError?) -> Void) {
        AlamofireManager.instance.request(
            url("users/me"),
            method: .get,
            parameters: [:],
            headers: headers(with: header(forSessionToken: token))
        ).responseData { response in
            switch response.result {
            case .success(let data):
                do {
                    let user = try self.decoder.decode(User.self, from: data)
                    completion(user, nil)
                } catch {
                    completion(nil, self.error(from: data))
                }

            case .failure(let error):
                completion(nil, APIError(other: error))
            }
        }
    }

    // MARK: Private

    private let baseURL = URL(string: "https://thechan.app/parse/")
    private let defaultHeaders: HTTPHeaders = [
        "X-Parse-Application-Id": "Pmbyln0Srsg9Rg16sDFihzA3OpqV1qnUUYeql9SA",
    ]

    private func url(_ string: String) -> URL {
        guard let url = baseURL?.appendingPathComponent(string) else {
            fatalError("Invalid URL")
        }

        return url
    }

    private func error(from data: Data) -> APIError {
        let error = try? decoder.decode(APIError.self, from: data)
        return error ?? APIError(.invalidResponse)
    }

    private func headers(with otherHeaders: HTTPHeaders) -> HTTPHeaders {
        defaultHeaders.merging(otherHeaders, uniquingKeysWith: { key, _ in key })
    }

    private func header(forSessionToken token: String) -> HTTPHeaders {
        ["X-Parse-Session-Token": token]
    }
}
