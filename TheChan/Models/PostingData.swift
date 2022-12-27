import Foundation

class PostingData {
    var boardId = ""
    var threadNumber = 0
    var text = ""
    var subject = ""
    var name = ""
    var email = ""
    var isOp = false
    var captchaResult: CaptchaResult?
    var attachments = [PostingAttachment]()
}

class PostingAttachment {
    var name = ""
    var mimeType = ""
    var data = Data()
}

struct CaptchaResult {
    let captcha: Captcha
    let input: String
}
