struct User: Codable {
    enum CodingKeys: String, CodingKey {
        case id = "objectId"
        case username
        case settings
        case sessionToken
    }

    struct Settings: Codable {
        let isMediaEnabled: Bool
    }

    let id: String
    var username: String?
    let settings: Settings
    let sessionToken: String
}
