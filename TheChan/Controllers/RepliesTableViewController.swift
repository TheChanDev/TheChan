import AsyncDisplayKit
import UIKit

class RepliesTableViewController: UIViewController, PostDelegate, UITableViewDataSource, UITableViewDelegate,
    UIGestureRecognizerDelegate
{
    // MARK: Internal

    weak var delegate: RepliesTableViewControllerDelegate?
    var postsStack = [[Post]]()
    var postDelegate: PostDelegate?
    var chan: Chan!

    override var prefersStatusBarHidden: Bool {
        !showStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .slide
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostCell")
        tableView.separatorInset = .zero
        tableView.backgroundColor = UIColor.clear
        tableView.dataSource = self
        tableView.delegate = self
        tableView.allowsSelection = false
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
//        tableView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tableView.layoutMargins = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
        tableView.addObserver(self, forKeyPath: "contentSize", options: [.new, .old], context: nil)
//        tableView.layer.cornerRadius = 24
//        tableView.layer.cornerCurve = .continuous

        let blurEffect = UIBlurEffect(style: .systemThinMaterial)
        backgroundView = UIVisualEffectView(effect: blurEffect)
        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(onBackgroundViewPan(_:)))
        panRecognizer.delegate = self
        backgroundView.isUserInteractionEnabled = true
        backgroundView.addGestureRecognizer(panRecognizer)
        (backgroundView as! UIVisualEffectView).contentView.addSubview(tableView)
        view.addSubview(backgroundView)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        tableView.addGestureRecognizer(longPressRecognizer)

        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRecognizer.direction = .down
        swipeRecognizer.require(toFail: panRecognizer)
        backgroundView.addGestureRecognizer(swipeRecognizer)
        subscribeForThemeChanges()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)

        tableView.removeObserver(self, forKeyPath: "contentSize")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        backgroundView.frame = view.bounds
        centerTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        showStatusBar = false
        UIView.animate(withDuration: 0.25) {
            self.setNeedsStatusBarAppearanceUpdate()
        }
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if let obj = object as? UITableView,
           obj == tableView, keyPath == "contentSize",
           let newSize = change?[NSKeyValueChangeKey.newKey] as? CGSize,
           let oldSize = change?[NSKeyValueChangeKey.oldKey] as? CGSize,
           oldSize.height != newSize.height
        {
            centerTableView()
        }
    }

    // MARK: - Data source & delegate

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        postsStack.last?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let theme = theme else { fatalError("theme is nil") }
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostTableViewCell
        cell.backgroundColor = theme.backgroundColor

        guard let post = postsStack.last?[indexPath.row] else { return cell }
        let repliesCount = delegate?.getReplies(for: post).count ?? 0
        let isHidden = delegate?.isPostHidden(post) ?? false
        cell.theme = theme
        cell.configure(
            from: post,
            tintColor: chan.tintColor(for: theme, userInterfaceStyle: traitCollection.userInterfaceStyle),
            repliesCount: repliesCount,
            delegate: self,
            isHidden: isHidden
        )
        cell.layoutSubviews()
        cell.postContent._update()
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let post = postsStack.last?[indexPath.row] else { return 0 }
        let width = tableView.bounds.width - cellPadding * 2
            - tableView.layoutMargins.left - tableView.layoutMargins.right
        let showAttachments = post.attachments.count > 0 && UserSettings.shared.isMediaEnabled
        let height = PostTableViewCell.calculateHeight(
            width: width,
            hasAttachments: showAttachments,
            hasReplies: (delegate?.getReplies(for: post).count ?? 0) > 0,
            header: post.header,
            postContent: post.attributedString,
            isHidden: delegate?.isPostHidden(post) ?? false,
            showHeaderAlongsideOfAttachments: showAttachments && post.attachments.count == 1
        )

        return height
    }

    func reload(reversed: Bool = false) {
        guard let snapshot = tableView.snapshotView(afterScreenUpdates: true) else {
            tableView.reloadData()
            return
        }

        let tableView = tableView
        snapshot.frame = tableView.frame
        tableView.transform = CGAffineTransform(translationX: 0, y: tableView.frame.height / 2 * (reversed ? -1 : 1))
        tableView.alpha = 0
        tableView.reloadData()
        centerTableView()
        view.addSubview(snapshot)
        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: .allowUserInteraction,
            animations: {
                tableView.transform = .identity
                tableView.alpha = 1
                snapshot.alpha = 0
                snapshot.transform = CGAffineTransform(
                    translationX: 0,
                    y: snapshot.frame.height / 2 * (reversed ? 1 : -1)
                )
            },
            completion: { _ in
                snapshot.removeFromSuperview()
            }
        )
    }

    // MARK: - Post Delegate

    func showReplies(toPostAtCell cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let post = postsStack.last?[indexPath.row] else { return }
        guard let replies = delegate?.getReplies(for: post) else { return }
        postsStack.append(replies)
        sourcePostsIndexPathsStack.append(indexPath)
        // collectionNode.reloadData()
        reload()
    }

    func navigateBy(_ sender: PostTableViewCell, board: String, thread: Int?, post: Int?, type: PostPreviewType) {
        guard let item = delegate?.getPost(withNumber: post ?? -1) else {
            dismiss(animated: true, completion: nil)
            postDelegate?.navigateBy(sender, board: board, thread: thread, post: post, type: type)
            return
        }

        guard let senderIndexPath = tableView.indexPath(for: sender) else { return }
        postsStack.append([item])
        sourcePostsIndexPathsStack.append(senderIndexPath)
        reload()
    }

    func show(_ sender: PostTableViewCell, attachment: Attachment) {
        postDelegate?.show(sender, attachment: attachment)
    }

    // MARK: - Pan gesture & animations

    @objc func onBackgroundViewPan(_ sender: UIPanGestureRecognizer) {
        let point = sender.location(in: tableView)
        if sender.state == .began,
           let indexPath = tableView.indexPathForRow(at: point),
           let cell = tableView.cellForRow(at: indexPath) as? PostTableViewCell
        {
            interactedCell = cell
        } else if sender.state == .ended {
            interactedCell = nil
        }

        handlePanGesture(sender: sender, cell: interactedCell)
    }

    func handleMovementOrReturning(rows: [Int], sourceRow: Int, translation: CGFloat, hasEnded: Bool) {
        for row in rows {
            guard let cell = tableView.cellForRow(at: IndexPath(item: row, section: 0)) else { continue }
            if hasEnded {
                animateReturning(view: cell)
            } else {
                let distance = CGFloat(abs(sourceRow - row))
                calculateOffsetFor(view: cell, distance: distance, translation: translation)
            }
        }
    }

    func handleMovementOrReturning(rows: [Int], translation: CGFloat, hasEnded: Bool) {
        for row in rows {
            guard let cell = tableView.cellForRow(at: IndexPath(item: row, section: 0)) else { continue }
            if hasEnded {
                animateReturning(view: cell)
            } else {
                calculateOffsetFor(view: cell, distance: 0, translation: translation)
            }
        }
    }

    func calculateOffsetFor(view: UIView, distance: CGFloat, translation: CGFloat) {
        let movingThreshold = distance * 50
        let offsetModification = abs(translation) < movingThreshold ? -abs(translation) : -movingThreshold
        let offset = translation > 0 ? translation + offsetModification : translation - offsetModification
        let alpha = calculateAlpha(value: abs(translation) * (distance + 1), fullyTransparentValue: 300, minimum: 0.1)
        view.frame.origin.x = offset
        view.alpha = alpha
    }

    func calculateAlpha(value: CGFloat, fullyTransparentValue: CGFloat, minimum: CGFloat) -> CGFloat {
        max(0, 1 - (value / fullyTransparentValue)) + minimum
    }

    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let pan = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = pan.velocity(in: view)
            return abs(velocity.y) < abs(velocity.x)
        }

        return true
    }

    func animateReturning(view: UIView) {
        UIView.animate(withDuration: 0.25) {
            view.frame.origin.x = 0
            view.alpha = 1
        }
    }

    func animateClosing(rows: [Int], velocity: CGFloat) {
        if willClose() {
            showStatusBar = true
        }

        UIView.animate(withDuration: 0.25, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
            for row in rows {
                guard let cell = self.tableView.cellForRow(at: IndexPath(item: row, section: 0)) else { continue }
                cell.frame.origin.x = velocity >= 0 ? cell.frame.width : -cell.frame.width
            }
        }, completion: { isFinished in
            if isFinished {
                self.goBack()
            }
        })
    }

    func goBack() {
        guard postsStack.count > 0 else {
            close()
            return
        }

        postsStack.removeLast()
        if postsStack.count > 0 {
            let indexPath = sourcePostsIndexPathsStack.removeLast()
            reload(reversed: true)
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        } else {
            close()
        }
    }

    func close() {
        dismiss(animated: true, completion: nil)
    }

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return }
        guard let post = postsStack.last?[indexPath.row] else { return }
        dismiss(animated: true, completion: {
            self.delegate?.scrollToPost(withNumber: post.number)
        })
    }

    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        close()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y <= -100 {
            close()
        }
    }

    // MARK: Private

    private var sourcePostsIndexPathsStack = [IndexPath]() // Used for restoring scroll position

    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var backgroundView = UIView()
    private var visibleRows = [Int]()
    private var interactedCell: PostTableViewCell?
    private var theme: Theme?

    private var showStatusBar = true

    private func centerTableView() {
        tableView.layoutIfNeeded()
        let width = view.frame.width
        let height = view.frame.height
        let tableHeight = min(tableView.contentSize.height, height)
        tableView.isScrollEnabled = tableView.contentSize.height >= height
        tableView.frame = CGRect(x: 0, y: (height - tableHeight) / 2, width: width, height: tableHeight)
    }

    private func handlePanGesture(sender: UIPanGestureRecognizer, cell: PostTableViewCell?) {
        let visibleRows = getVisibleRows()
        let translation = sender.translation(in: sender.view).x
        let xVelocity = sender.velocity(in: sender.view).x

        let minimumOffset = CGFloat(150.0)
        let minimumVelocity = CGFloat(500.0)

        let hasExceededMinimumOffset = abs(translation) > minimumOffset
        let hasExceededMinimumVelocity = abs(xVelocity) > minimumVelocity

        if sender.state == .ended, hasExceededMinimumOffset || hasExceededMinimumVelocity {
            animateClosing(rows: visibleRows, velocity: xVelocity)
        } else if let cell = cell {
            guard let sourceRow = tableView.indexPath(for: cell)?.item else { return }
            handleMovementOrReturning(
                rows: visibleRows,
                sourceRow: sourceRow,
                translation: translation,
                hasEnded: sender.state == .ended
            )

        } else {
            handleMovementOrReturning(
                rows: visibleRows,
                translation: translation,
                hasEnded: sender.state == .ended
            )
        }

        if sender.state == .ended {
            self.visibleRows.removeAll()
        }
    }

    private func getVisibleRows() -> [Int] {
        if visibleRows.isEmpty {
            visibleRows = tableView.indexPathsForVisibleRows?.map(\.item) ?? []
        }

        return visibleRows
    }

    private func willClose() -> Bool {
        postsStack.count < 2
    }
}

extension RepliesTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}

protocol RepliesTableViewControllerDelegate: AnyObject {
    func getPost(withNumber number: Int) -> Post?
    func getReplies(for post: Post) -> [Post]
    func scrollToPost(withNumber number: Int)
    func isPostHidden(_ post: Post) -> Bool
}
