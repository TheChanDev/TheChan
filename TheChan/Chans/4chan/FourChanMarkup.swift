import Foundation

class FourChanMarkup: MarkupParser {
    override func parse(node: Node) -> [NSAttributedString.Key: Any]? {
        if node.name == "b" {
            return bold()
        }

        if node.name == "em" {
            return italic()
        }

        if node.name == "spoiler" {
            return spoiler()
        }

        let nodeClass = node["class"]

        if nodeClass == "s" {
            return strikethrough()
        }

        if nodeClass == "quote" {
            return quote()
        }

        if node.name == "sub" {
            return lowerIndex()
        }

        if node.name == "sup" {
            return upperIndex()
        }

        if node.name == "u" {
            return underline()
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
