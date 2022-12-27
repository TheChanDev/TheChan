import AsyncDisplayKit
import Foundation

class ThreadTableCellNode: ASCellNode {
    // MARK: Lifecycle

    init(
        theme: Theme,
        subject: String,
        header: NSAttributedString,
        imageUrl: URL?,
        color: UIColor,
        omittedPosts: Int,
        omittedFiles: Int
    ) {
        self.theme = theme
        super.init()

        subjectNode.maximumNumberOfLines = 3
        subjectNode.truncationMode = .byTruncatingTail

        self.subject = subject
        subjectNode.attributedText = getAttributedString(forSubject: subject)
        addSubnode(subjectNode)

        headerNode.maximumNumberOfLines = 0
        headerNode.attributedText = header
        headerNode.truncationMode = .byTruncatingTail
        headerNode.style.flexShrink = 1
        addSubnode(headerNode)

        imageNode.contentMode = .scaleAspectFill
        let size: CGFloat = Device.isPad() ? 100 : 75
        imageNode.style.width = ASDimensionMake(size)
        imageNode.style.height = ASDimensionMake(size)
        imageNode.cornerRadius = 10
        imageNode.clipsToBounds = true
        addSubnode(imageNode)
        if let url = imageUrl {
            imageNode.setImage(from: url)
        }

        textNode.maximumNumberOfLines = 7
        textNode.tintColor = color
        textNode.style.flexShrink = 1
        textNode.truncationMode = .byTruncatingTail
        addSubnode(textNode)

        backgroundColor = theme.threadBackgroundColor
        cornerRadius = 10
    }

    // MARK: Internal

    let textNode = ASTextNode()
    var showImage = true
    var showSubject = true
    var showName = true

    var isThreadHidden = false {
        didSet {
            subjectNode.attributedText = getAttributedString(forSubject: subject)
        }
    }

    override func layoutSpecThatFits(_ constrainedSize: ASSizeRange) -> ASLayoutSpec {
        var items = [ASLayoutElement]()

        if showSubject {
            items.append(subjectNode)
        }

        if isThreadHidden {
            textNode.maximumNumberOfLines = 1
            subjectNode.maximumNumberOfLines = 1
            subjectNode.alpha = 0.75
            textNode.alpha = 0.75
        } else {
            textNode.maximumNumberOfLines = 7
            subjectNode.maximumNumberOfLines = 3
            subjectNode.alpha = 1
            textNode.alpha = 1
        }

        var headerChildren = [ASLayoutElement]()
        if showImage {
            headerChildren.append(imageNode)
        }

        headerChildren.append(headerNode)

        let headerStack = ASStackLayoutSpec(
            direction: .horizontal,
            spacing: 12,
            justifyContent: .start,
            alignItems: .center,
            children: headerChildren
        )

        if !isThreadHidden {
            items.append(headerStack)
        }

        if !(isThreadHidden && showSubject) {
            items.append(textNode)
        }

        let mainStack = ASStackLayoutSpec(
            direction: .vertical,
            spacing: 12,
            justifyContent: .start,
            alignItems: .stretch,
            children: items
        )

        return ASInsetLayoutSpec(insets: .init(top: 12, left: 12, bottom: 12, right: 12), child: mainStack)
    }

    func addGestureRecognizer(_ recognizer: UIGestureRecognizer, callback: @escaping (ThreadTableCellNode) -> Void) {
        gestureRecognizerCallback = callback
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.view.addGestureRecognizer(recognizer)
            recognizer.addTarget(self, action: #selector(ThreadTableCellNode.gestureRecognized(_:)))
        }
    }

    @objc func gestureRecognized(_ sender: UIGestureRecognizer) {
        gestureRecognizerCallback?(self)
    }

    // MARK: Private

    private let subjectNode = ASTextNode()
    private let headerNode = ASTextNode()
    private let imageNode = ASImageNode()
    private let theme: Theme
    private var gestureRecognizerCallback: ((ThreadTableCellNode) -> Void)?

    private var subject = ""

    private func getAttributedString(forSubject subject: String) -> NSAttributedString {
        var fontSize = CGFloat(UserSettings.shared.fontSize)
        if !isThreadHidden {
            fontSize += 3
        }

        return NSAttributedString(
            string: subject,
            attributes: [
                .foregroundColor: theme.altTextColor,
                .font: UIFont.systemFont(ofSize: fontSize, weight: .heavy),
            ]
        )
    }
}
