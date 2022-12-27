import Kingfisher
import UIKit
import YYText

private let margins = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
private let repliesHeight = CGFloat(42)
private let headerVerticalSpacing = CGFloat(8)
private let attachmentSize = Device.isPad() ? CGFloat(100) : CGFloat(75)
private let attachmentsVerticalSpacing = CGFloat(6)

class PostTableViewCell: UITableViewCell, UICollectionViewDelegate, UICollectionViewDataSource, YYTextViewDelegate {
    // MARK: Lifecycle

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        let layout = UICollectionViewFlowLayout()
        attachmentsView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        postContent.textContainerInset = .zero
        postContent.backgroundColor = .clear
        postContent.delegate = self
        postContent.dataDetectorTypes = .link
        postContent.isUserInteractionEnabled = true
        postContent.isScrollEnabled = false
        postContent.isEditable = false
        postContent.isSelectable = false
        contentView.addSubview(postContent)

        layout.itemSize = CGSize(width: attachmentSize, height: attachmentSize)
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 6
        layout.minimumInteritemSpacing = 0
        attachmentsView.showsHorizontalScrollIndicator = false
        attachmentsView.dataSource = self
        attachmentsView.delegate = self
        attachmentsView.backgroundColor = .clear
        attachmentsView.scrollsToTop = false
        attachmentsView.register(
            UINib(nibName: "PostAttachmentCell", bundle: .main),
            forCellWithReuseIdentifier: "PostAttachment"
        )
        contentView.addSubview(attachmentsView)

        header.lineBreakMode = .byTruncatingMiddle
        header.numberOfLines = 1
        contentView.addSubview(header)

        let settings = UserSettings.shared
        let fontSize = CGFloat(settings.fontSize - 1)
        let font = settings.useMonospacedFontInPostInfo
            ? UIFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
            : UIFont.systemFont(ofSize: fontSize, weight: .bold)

        replies.titleLabel?.font = font
        replies.titleEdgeInsets = UIEdgeInsets(top: 0, left: margins.left, bottom: 0, right: 0)
        replies.contentHorizontalAlignment = .left
        replies.addTarget(self, action: #selector(repliesTapped), for: .touchUpInside)
        contentView.addSubview(replies)
    }

    required init?(coder aDecoder: NSCoder) {
        nil
    }

    // MARK: Internal

    weak var delegate: PostDelegate?
    var attachments = [Attachment]()

    let postContent = YYTextView(frame: CGRect.zero)
    let header = UILabel(frame: CGRect.zero)
    let attachmentsView: UICollectionView
    let replies = UIButton()
    private(set) var isHandlingGesture = false

    var showAttachments = false {
        didSet {
            attachmentsView.isHidden = !showAttachments
        }
    }

    var showReplies = false {
        didSet {
            replies.isHidden = !showReplies
        }
    }

    var isPostHidden = false {
        didSet {
            postContent.isHidden = isPostHidden
        }
    }

    var showHeaderAlongsideOfAttachments = false {
        didSet {
            header.numberOfLines = showHeaderAlongsideOfAttachments ? 0 : 1
        }
    }

    var theme: Theme? {
        didSet {
            guard let theme = theme else { fatalError("theme is nil") }
            backgroundColor = theme.backgroundColor
            header.textColor = theme.postMetaTextColor
            replies.setTitleColor(theme.altTextColor, for: .normal)
            replies.setTitleColor(theme.altTextColor.withAlphaComponent(0.7), for: .highlighted)
        }
    }

    static func calculateHeight(
        width: CGFloat,
        hasAttachments: Bool,
        hasReplies: Bool,
        header: NSAttributedString,
        postContent: NSAttributedString,
        isHidden: Bool,
        showHeaderAlongsideOfAttachments: Bool
    ) -> CGFloat {
        let contentSize = YYTextLayout(
            containerSize: CGSize(width: width, height: .greatestFiniteMagnitude),
            text: postContent
        )

        let headerHeight: CGFloat = header.boundingRect(
            with: CGSize(width: Double.infinity, height: Double.infinity),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).height

        let contentHeight: CGFloat = contentSize?.textBoundingSize.height ?? 0
        let attachmentsHeight: CGFloat = hasAttachments ? attachmentSize + attachmentsVerticalSpacing : 0
        let repliesFinalHeight: CGFloat = hasReplies ? repliesHeight : margins.bottom
        let heightOfAttachmentsWithHeader: CGFloat = showHeaderAlongsideOfAttachments
            ? max(headerHeight, attachmentSize) + attachmentsVerticalSpacing
            : attachmentsHeight

        var height = contentHeight + margins
            .top + heightOfAttachmentsWithHeader + repliesFinalHeight + headerVerticalSpacing
        if !showHeaderAlongsideOfAttachments {
            height += headerHeight
        }

        return isHidden ? headerHeight + margins.top + margins.bottom : height
    }

    func setTextTintColor(_ color: UIColor) {
//        postContent.linkAttributes = [
//            NSAttributedString.Key.foregroundColor: color
//        ]
//
//        postContent.activeLinkAttributes = [
//            NSAttributedString.Key.foregroundColor: color.withAlphaComponent(0.7)
//        ]
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        var postContentHeight =
            bounds.height - margins.top

        let fullWidth = bounds.width - margins.left - margins.right
        let x = margins.left
        var y = margins.top

        var headerSize = header.sizeThatFits(CGSize(width: fullWidth, height: .greatestFiniteMagnitude))
        headerSize.width = min(fullWidth, headerSize.width)

        var headerOrigin = CGPoint.zero
        if showHeaderAlongsideOfAttachments, !isPostHidden {
            let desiredHeight = max(headerSize.height, attachmentSize)
            let attachmentsY = y + desiredHeight / 2 - attachmentSize / 2
            let headerY = y + desiredHeight / 2 - headerSize.height / 2
            let headerX = x + attachmentSize + margins.left
            headerOrigin = CGPoint(x: headerX, y: headerY)
            y += desiredHeight + attachmentsVerticalSpacing
            postContentHeight -= desiredHeight + attachmentsVerticalSpacing
            attachmentsView.frame = CGRect(x: x, y: attachmentsY, width: attachmentSize, height: attachmentSize)
        } else {
            headerOrigin = CGPoint(x: x, y: y)
            y += headerSize.height + headerVerticalSpacing
            postContentHeight -= headerSize.height + headerVerticalSpacing

            if showAttachments, !isPostHidden {
                attachmentsView.frame = CGRect(x: x, y: y, width: fullWidth, height: attachmentSize)
                let space = attachmentSize + attachmentsVerticalSpacing
                y += space
                postContentHeight -= space
            }
        }

        header.frame = CGRect(origin: headerOrigin, size: headerSize)

        if showReplies, !isPostHidden {
            postContentHeight -= repliesHeight
            replies.frame = CGRect(x: 0, y: y + postContentHeight, width: bounds.width, height: repliesHeight)
        } else {
            postContentHeight -= margins.bottom
        }

        if isPostHidden { return }

        postContent.frame = CGRect(
            x: x, y: y,
            width: fullWidth,
            height: postContentHeight
        )
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        attachments.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PostAttachment",
            for: indexPath
        ) as! PostAttachmentCell
        let attachment = attachments[indexPath.row]

        cell.previewImage.kf.setImage(
            with: attachment.thumbnailUrl,
            options: [
                .backgroundDecode,
                .transition(.fade(0.2)),
            ]
        )

        cell.videoIcon.isHidden = attachment.type != .video

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.show(self, attachment: attachments[indexPath.item])
    }

    func textView(_ textView: YYTextView, shouldTap highlight: YYTextHighlight, in characterRange: NSRange) -> Bool {
        true
    }

    func textView(_ textView: YYTextView, didTap highlight: YYTextHighlight, in characterRange: NSRange, rect: CGRect) {
        guard let url = getURL(from: highlight, text: textView.text, range: characterRange) else { return }

        isHandlingGesture = false

        if url.scheme == "thechan" {
            let components = url.pathComponents
            guard let board = url.host else { return }
            let thread = Int(components[safe: 1] ?? "")
            let post = Int(components[safe: 2] ?? "")
            delegate?.navigateBy(self, board: board, thread: thread, post: post, type: .regular)
        } else if url.scheme == "thechan-post" {
            guard let post = Int(url.host ?? "") else { return }
            delegate?.navigateBy(self, board: "", thread: nil, post: post, type: .regular)
        } else {
            UIApplication.shared.open(url)
        }
    }

    func textView(
        _ textView: YYTextView,
        shouldLongPress highlight: YYTextHighlight,
        in characterRange: NSRange
    ) -> Bool {
        guard
            let url = getURL(from: highlight, text: textView.text, range: characterRange),
            let scheme = url.scheme,
            !scheme.hasPrefix("thechan")
        else { return false }
        isHandlingGesture = true
        return true
    }

    func textView(
        _ textView: YYTextView,
        didLongPress highlight: YYTextHighlight,
        in characterRange: NSRange,
        rect: CGRect
    ) {
        guard
            let url = getURL(from: highlight, text: textView.text, range: characterRange),
            let scheme = url.scheme,
            !scheme.hasPrefix("thechan")
        else { return }
        delegate?.shareLink(cell: self, url: url, rect: rect, completion: { [weak self] in
            self?.isHandlingGesture = false
        })
    }

    override func prepareForReuse() {
        attachments = []
        attachmentsView.reloadData()
        showAttachments = false
        attachmentsView.frame = CGRect.zero
        showReplies = false
        replies.frame = CGRect.zero
        postContent.frame = CGRect.zero
        isHandlingGesture = false
    }

    @objc func repliesTapped() {
        delegate?.showReplies(toPostAtCell: self)
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
//        UIView.animate(withDuration: 0.25) {
//            self.backgroundColor = selected ? theme.altBackgroundColor : theme.backgroundColor
//        }
    }

    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        guard let theme = theme else { return }
        UIView.animate(withDuration: 0.25) {
            self.contentView.backgroundColor = highlighted ? theme.altBackgroundColor : theme.backgroundColor
        }
    }

    // MARK: Private

    private func getURL(from highlight: YYTextHighlight, text: String, range: NSRange) -> URL? {
        var rawUrl = highlight.userInfo?["url"] as? String
            ?? (text as NSString).substring(with: range) as String
        if !rawUrl.hasPrefix("http"), !rawUrl.hasPrefix("thechan") {
            rawUrl = "http://" + rawUrl
        }

        return URL(string: rawUrl.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? rawUrl)
    }
}

enum PostPreviewType {
    case regular
    case peekAndPop
}

protocol PostDelegate: AnyObject {
    func showReplies(toPostAtCell cell: PostTableViewCell)
    func show(_ sender: PostTableViewCell, attachment: Attachment)
    func navigateBy(_ sender: PostTableViewCell, board: String, thread: Int?, post: Int?, type: PostPreviewType)
    func shareLink(cell: PostTableViewCell, url: URL, rect: CGRect, completion: @escaping () -> Void)
}

extension PostDelegate {
    func shareLink(cell: PostTableViewCell, url: URL, rect: CGRect, completion: @escaping () -> Void) {}
}
