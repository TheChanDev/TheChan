import Fuzi
import UIKit

extension String {
    init(htmlEncodedString: String) {
        self.init()
        let document = try! HTMLDocument(
            string: htmlEncodedString.replacingOccurrences(of: "<br>", with: "\n"),
            encoding: .utf8
        )
        let text = document.body?.stringValue ?? htmlEncodedString
        self = text
    }
}
