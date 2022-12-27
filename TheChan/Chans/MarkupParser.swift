import Foundation
import Fuzi
import YYText

struct Node {
    // MARK: Lifecycle

    init(name: String, range: CountableRange<Int>, rawNode: XMLElement, flags: NodeFlags, addition: String? = nil) {
        self.range = range
        self.name = name
        self.rawNode = rawNode
        self.flags = flags
        self.addition = addition
    }

    // MARK: Internal

    let range: CountableRange<Int>
    let name: String
    let rawNode: XMLElement
    let flags: NodeFlags
    let addition: String?

    subscript(attribute: String) -> String? {
        rawNode[attribute]
    }
}

class MarkupParser {
    // MARK: Lifecycle

    init?(from html: String, linkCoder: LinkCoder, theme: Theme, tintColor: UIColor) {
        self.html = html
            .replacingOccurrences(of: "<br>|\\\\r\\\\n|\\\r\\\n", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: "\\t", with: "\t")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        guard let document = try? HTMLDocument(string: self.html) else { return nil }
        self.document = document
        self.linkCoder = linkCoder
        self.theme = theme
        self.tintColor = tintColor
    }

    // MARK: Internal

    let linkCoder: LinkCoder
    let fontSize = CGFloat(UserSettings.shared.fontSize)
    var userPosts = [Int]()
    var opPost = 0

    func getFlags(for element: XMLElement) -> NodeFlags {
        var flags = NodeFlags()
        if let url = element["href"], let link = linkCoder.parseURL(removeDomain(from: url)) {
            flags.append(.innerLink(link: link))
        }

        return flags
    }

    func getContents(for element: XMLElement, flags: NodeFlags) -> (String?, String?) {
        let href = element["href"]
        let contents = element.stringValue
        if let link = flags.innerLink, contents.hasPrefix(">>") || contents == href {
            var text = ">>"
            var addition: String?

            if let post = link as? PostLink, post.threadNumber != post.postNumber, post.postNumber != opPost {
                text += "\(post.postNumber)"
            } else if let thread = link as? ThreadLink {
                let number = thread.threadNumber == 0 ? opPost : thread.threadNumber
                text += "\(number)"
                addition = " OP"
            } else if let board = link as? BoardLink {
                text += "\(board.boardId)/"
            }

            if let number = (link as? PostLink)?.postNumber ?? (link as? ThreadLink)?.threadNumber,
               userPosts.contains(number)
            {
                addition += " YOU"
            }

            return (text, addition)
        }

        return (nil, nil)
    }

    func parse(node: Node) -> [NSAttributedString.Key: Any]? {
        nil
    }

    func bold() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.boldSystemFont(ofSize: fontSize)]
    }

    func italic() -> [NSAttributedString.Key: Any] {
        [.font: UIFont.italicSystemFont(ofSize: fontSize)]
    }

    func strikethrough() -> [NSAttributedString.Key: Any] {
        [
            NSAttributedString.Key(rawValue: YYTextStrikethroughAttributeName): YYTextDecoration(
                style: .single,
                width: 1,
                color: theme.textColor
            ),

            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .strikethroughColor: theme.textColor,
        ]
    }

    func spoiler() -> [NSAttributedString.Key: Any] {
        [
            .backgroundColor: theme.spoilerBackgroundColor,
            .foregroundColor: theme.spoilerTextColor,
        ]
    }

    func quote() -> [NSAttributedString.Key: Any] {
        [.foregroundColor: theme.quoteColor]
    }

    func lowerIndex() -> [NSAttributedString.Key: Any] {
        [
            .baselineOffset: CGFloat(-2),
            .font: UIFont.systemFont(ofSize: fontSize - 5),
        ]
    }

    func upperIndex() -> [NSAttributedString.Key: Any] {
        [
            .baselineOffset: CGFloat(5),
            .font: UIFont.systemFont(ofSize: fontSize - 5),
        ]
    }

    func innerLink(_ link: Link) -> [NSAttributedString.Key: Any] {
        [
            .link: link.internalURL(),
            .font: UIFont.boldSystemFont(ofSize: fontSize),
            .underlineStyle: NSUnderlineStyle().rawValue,
            .underlineColor: UIColor.clear,
            .foregroundColor: tintColor,
        ]
    }

    func link(for url: String) -> [NSAttributedString.Key: Any] {
        [
            .link: url,
            .font: UIFont.systemFont(ofSize: fontSize),
            .underlineStyle: NSUnderlineStyle().rawValue,
            .underlineColor: UIColor.clear,
            .foregroundColor: tintColor,
        ]
    }

    func underline() -> [NSAttributedString.Key: Any] {
        [
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .underlineColor: theme.textColor,
        ]
    }

    func getURL(from node: Node) -> String? {
        if node.name != "a" {
            return nil
        }

        guard let link = node["href"]?.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        else { return nil }
        guard let url = URL(string: link) else { return nil }
        if url.scheme != nil, url.host != nil {
            return link
        }

        return nil
    }

    func parse() -> NSAttributedString {
        guard let body = document.body else { return NSAttributedString(string: "") }
        let text = enumerate(body.childNodes(ofTypes: [.Element, .Text]), 0)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 2
        let resultAttributedString = NSMutableAttributedString(string: text, attributes: [
            .font: UIFont.systemFont(ofSize: fontSize),
            .foregroundColor: theme.textColor,
            .paragraphStyle: paragraphStyle,
        ])

        render(nodes: nodes, to: resultAttributedString)
        return resultAttributedString
    }

    // MARK: Private

    private let html: String
    private let document: HTMLDocument
    private var nodes = [Node]()
    private let theme: Theme
    private let tintColor: UIColor

    private func enumerate(_ nodes: [XMLNode], _ parentOffset: Int) -> String {
        var offset = 0
        var text = ""
        for node in nodes {
            let length = node.stringValue.count
            if let elem = node.toElement() {
                let totalOffset = parentOffset + offset
                if elem.children.count > 0 {
                    let children = elem.childNodes(ofTypes: [.Text, .Element])
                    let newText = enumerate(children, totalOffset)
                    let range = totalOffset ..< totalOffset + newText.count
                    text += newText
                    offset += newText.count
                    self.nodes.append(Node(name: elem.tag!, range: range, rawNode: elem, flags: []))
                } else {
                    let flags = getFlags(for: elem)
                    let (contents, addition) = getContents(for: elem, flags: flags)
                    let newText = contents ?? elem.stringValue
                    let range = totalOffset ..< totalOffset + newText.count
                    text += newText
                    offset += newText.count
                    if let addition = addition {
                        text += addition
                        offset += addition.count
                    }

                    self.nodes
                        .append(Node(name: elem.tag!, range: range, rawNode: elem, flags: flags, addition: addition))
                }
            } else {
                text += node.stringValue
                offset += length
            }
        }

        return text
    }

    private func removeDomain(from url: String) -> String {
        let domain = "https://2ch.hk"
        if url.hasPrefix(domain) {
            return String(url.dropFirst(domain.count))
        }

        return url
    }

    private func addition() -> [NSAttributedString.Key: Any] {
        [
            .font: UIFont.italicSystemFont(ofSize: fontSize),
            .foregroundColor: tintColor,
        ]
    }

    private func addAdditionAttribute(from node: Node, to attributedString: NSMutableAttributedString) {
        guard let addition = node.addition else { return }
        let range = NSRange(location: node.range.upperBound, length: addition.count)
        let attributes = self.addition()
        attributedString.addAttributes(attributes, range: range)
    }

    private func render(nodes: [Node], to attributedString: NSMutableAttributedString) {
        for node in nodes {
            guard let attributes = parse(node: node) else { continue }
            let range = NSRange(location: node.range.lowerBound, length: node.range.count)
            if let linkAttribute = attributes[.link] as? String {
                let highlight = YYTextHighlight()
                highlight.userInfo = ["url": linkAttribute]
                attributedString.yy_setTextHighlight(highlight, range: range)
            }

            if let background = attributes[.backgroundColor] as? UIColor,
               let textColor = attributes[.foregroundColor] as? UIColor
            {
                attributedString.removeAttribute(.foregroundColor, range: range)
                let border = YYTextBorder(fill: background, cornerRadius: 0)
                attributedString.yy_setTextBackgroundBorder(border, range: range)
                attributedString.yy_setColor(textColor, range: range)
            }

            attributedString.addAttributes(attributes, range: range)
            addAdditionAttribute(from: node, to: attributedString)
        }
    }
}
