import Foundation

enum AttachmentType {
    case image, video
}

class Attachment: Equatable {
    // MARK: Lifecycle

    init(url: String, thumbUrl: String, size: (Int, Int), thumbSize: (Int, Int), type: AttachmentType) {
        self.url = URL(string: url)!
        thumbnailUrl = URL(string: thumbUrl)!
        self.size = size
        thumbnailSize = thumbSize
        self.type = type
    }

    // MARK: Internal

    var url: URL
    var thumbnailUrl: URL
    var size: (Int, Int)
    var thumbnailSize: (Int, Int)
    var type: AttachmentType
    var name = ""
    var fileSize = 0

    static func == (left: Attachment, right: Attachment) -> Bool {
        left.url == right.url
    }
}
