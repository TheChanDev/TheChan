import AsyncDisplayKit
import Foundation

class CatalogCellNode: ASCellNode {
    // MARK: Lifecycle

    init(
        theme: Theme,
        subject: String,
        showSubject: Bool,
        content: NSAttributedString,
        omittedFiles: Int,
        omittedPosts: Int,
        imageURL: URL?
    ) {
        super.init()

        self.showSubject = showSubject
        if showSubject {
            addSubnode(subjectNode)
            subjectNode.attributedText = NSAttributedString(
                string: subject,
                attributes: [
                    .font: UIFont.systemFont(ofSize: CGFloat(UserSettings.shared.fontSize), weight: .bold),
                    .foregroundColor: theme.textColor,
                ]
            )
        }

        addSubnode(contentNode)
        contentNode.attributedText = content

        addSubnode(imageNode)
        if let url = imageURL {
            imageNode.setImage(from: url)
        }

        addSubnode(footerNode)
        footerNode.attributedText = NSAttributedString(
            string: "\(omittedPosts)P | \(omittedFiles)F",
            attributes: [
                .foregroundColor: theme.textColor,
                .font: UIFont.systemFont(ofSize: CGFloat(UserSettings.shared.fontSize) - 2, weight: .bold),
            ]
        )

        backgroundColor = theme.threadBackgroundColor
        cornerRadius = 12
    }

    // MARK: Internal

    let imageNode: ASImageNode = {
        let node = ASImageNode()
        node.contentMode = .scaleAspectFill
        return node
    }()

    let subjectNode: ASTextNode = {
        let node = ASTextNode()
        node.maximumNumberOfLines = 1
        node.truncationMode = .byTruncatingTail
        return node
    }()

    let contentNode: ASTextNode = {
        let node = ASTextNode()
        node.maximumNumberOfLines = 0
        node.style.flexShrink = 1
        node.style.flexGrow = 1
        node.truncationMode = .byTruncatingTail
        return node
    }()

    let footerNode: ASTextNode = {
        let node = ASTextNode()
        node.maximumNumberOfLines = 1
        node.style.alignSelf = .center
        node.truncationMode = .byTruncatingTail
        return node
    }()

    var showSubject = true

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        let imageHeight: CGFloat = constrainedSize.max.width > 150 ? 100 : 85
        imageNode.style.height = ASDimensionMake(imageHeight)

        var items = [ASLayoutElement]()
        if showSubject {
            items.append(subjectNode)
        }

        items.append(contentNode)
        items.append(footerNode)

        let innerStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 4,
            justifyContent: .start,
            alignItems: .stretch,
            children: items
        )

        let inset = ASInsetLayoutSpec(insets: .init(top: 8, left: 8, bottom: 8, right: 8), child: innerStack)
        inset.style.flexShrink = 1
        inset.style.flexGrow = 1

        return ASStackLayoutSpec(
            direction: .vertical,
            spacing: 0,
            justifyContent: .start,
            alignItems: .stretch,
            children: [imageNode, inset]
        )
    }
}
