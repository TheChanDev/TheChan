import Foundation

class DvachMarkup: MarkupParser {
    override func parse(node: Node) -> [NSAttributedString.Key: Any]? {
        if node.name == "strong" {
            return bold()
        }

        if node.name == "em" {
            return italic()
        }

        let nodeClass = node["class"]

        if nodeClass == "s" {
            return strikethrough()
        }

        if nodeClass == "spoiler" {
            return spoiler()
        }

        if nodeClass == "unkfunc" {
            return quote()
        }

        if nodeClass == "u" {
            return underline()
        }

        if node.name == "sub" {
            return lowerIndex()
        }

        if node.name == "sup" {
            return upperIndex()
        }

        if let link = node.flags.innerLink {
            return innerLink(link)
        }

        if let url = getURL(from: node) {
            return link(for: url)
        }

        return nil
    }
}
