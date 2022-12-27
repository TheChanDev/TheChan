import RealmSwift
import TUSafariActivity
import UIKit

let cellPadding: CGFloat = 12

struct ThreadNavigationInfo {
    // MARK: Lifecycle

    init(boardId: String, threadNumber: Int) {
        self.boardId = boardId
        self.threadNumber = threadNumber
        postNumber = nil
    }

    init(boardId: String, threadNumber: Int, postNumber: Int?) {
        self.boardId = boardId
        self.threadNumber = threadNumber
        self.postNumber = postNumber
    }

    // MARK: Internal

    static let empty = ThreadNavigationInfo(boardId: "", threadNumber: 0)

    let boardId: String
    let threadNumber: Int
    let postNumber: Int?
}

class ThreadTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,
    UIGestureRecognizerDelegate, PostDelegate, LoadableWithError, UIViewControllerPreviewingDelegate,
    ThreadToolbarItemsFactoryDelegate, RepliesTableViewControllerDelegate, GalleryDelegate, PostQuotingDelegate
{
    // MARK: Lifecycle

    deinit {
        userPostsNotificationToken?.invalidate()
    }

    // MARK: Public

    public func previewingContext(
        _ previewingContext: UIViewControllerPreviewing,
        commit viewControllerToCommit: UIViewController
    ) {
        guard let previewViewController = viewControllerToCommit as? AttachmentPreviewViewController else { return }
        guard let attachment = previewViewController.attachment else { return }
        openAttachment(attachment)
    }

    // MARK: Internal

    var favoriteButton: UIBarButtonItem!
    var errorLabel: UILabel?
    var tryAgainButton: UIButton?

    var navigationInfo: ThreadNavigationInfo = .empty
    var posts = [Post]()
    let dateFormatter = DateFormatter()
    lazy var chan: Chan! = nil
    @IBOutlet var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        setupFooter()
        tableView.separatorInset = UIEdgeInsets(top: 0, left: cellPadding, bottom: 0, right: cellPadding)
        tableView.cellLayoutMarginsFollowReadableWidth = false
        tableView.register(PostTableViewCell.self, forCellReuseIdentifier: "PostCell")
        tableView.delegate = self
        tableView.dataSource = self
        tableView.autoresizingMask = []

        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        tableView.allowsSelection = true

        setupLoadable(
            buttonImage: .init(
                systemName: "arrow.clockwise",
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            )!,
            selector: #selector(onTriedAgain)
        )

        let holdRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        holdRecognizer.minimumPressDuration = 0.5
        tableView.addGestureRecognizer(holdRecognizer)

        registerForPreviewing(with: self, sourceView: tableView)

        subscribeForThemeChanges()
        configureStateController()
        configureFavoritesState()

        title = getTitleFrom(boardId: navigationInfo.boardId, threadNumber: navigationInfo.threadNumber)
        loadHiddenPosts()
        setupUserPostsNotifications()
        loadThread()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        heightCache.removeAll(keepingCapacity: true)
        guard let visibleRow = getIndexPathForFirstActuallyVisibleRow() else { return }
        coordinator.animate(alongsideTransition: { _ in }, completion: { [weak self] _ in
            self?.tableView.scrollToRow(at: visibleRow, at: .top, animated: false)
        })
    }

    func loadThread() {
        tableView.startLoading(indicator: progressIndicator)
        isLoading = true
        chan
            .loadThread(
                boardId: navigationInfo.boardId,
                number: navigationInfo.threadNumber,
                from: nil
            ) { [weak self] posts, error in
                guard let self = self else { return }
                if let posts = posts {
                    self.loadPostsIntoTable(posts)
                } else if let error = error {
                    self.showError(error: error)
                    self.tableView.stopLoading(indicator: self.progressIndicator, hideFooter: false)
                }

                self.isLoading = false
            }
    }

    func performScrolling() {
        guard tableView.numberOfRows(inSection: 0) > 0 else { return }

        if let postNumber = navigationInfo.postNumber,
           let index = posts.firstIndex(where: { $0.number == postNumber })
        {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        } else if historyItem.position != 0,
                  let index = posts.firstIndex(where: { $0.number == historyItem.position })
        {
            let indexPath = IndexPath(row: index, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: false)
        } else if unreadPosts != 0 {
            let lastReadedPostPosition = posts.count - unreadPosts
            let indexPath = IndexPath(row: lastReadedPostPosition, section: 0)
            tableView.scrollToRow(at: indexPath, at: .top, animated: true)
            updateUnreadPostsCount()
        }
    }

    @objc func onTriedAgain() {
        tryAgainButton?.isHidden = true
        errorLabel?.isHidden = true
        loadThread()
    }

    func setupActivity() {
        let link = ThreadLink(boardId: navigationInfo.boardId, number: navigationInfo.threadNumber)
        let url = URL(string: chan.linkCoder.getURL(for: link))

        activity.webpageURL = url
        activity.isEligibleForHandoff = true
        activity.isEligibleForSearch = true
        userActivity = activity
    }

    func updateHistoryItem() {
        let existingItem = uiRealm.objects(HistoryItem.self).first { item in
            item.board == navigationInfo.boardId && item.number == navigationInfo.threadNumber && item.chanId == chan.id
        }

        try? uiRealm.write {
            if let item = existingItem {
                self.historyItem = item
                item.lastVisit = Date()
            } else {
                let newItem = HistoryItem()
                newItem.chanId = chan.id
                newItem.board = navigationInfo.boardId
                newItem.name = posts[0].getTitle()
                newItem.number = navigationInfo.threadNumber
                newItem.position = 0
                newItem.lastVisit = Date()
                uiRealm.add(newItem)
                self.historyItem = newItem
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tableView.bottomRefreshControl = nil
        let bottomRefreshControl = UIRefreshControl()
        bottomRefreshControl.triggerVerticalOffset = 120
        tableView.bottomRefreshControl = bottomRefreshControl
        bottomRefreshControl.addTarget(self, action: #selector(refreshControlTriggered(_:)), for: .valueChanged)

        tableView.scrollsToTop = true

        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(threadStateTapped))
        stateController.view?.isUserInteractionEnabled = true
        stateController.view?.addGestureRecognizer(gestureRecognizer)

        stateController.beginAppearanceTransition(true, animated: animated)
        navigationController?.setToolbarHidden(false, animated: animated)
        stateController.endAppearanceTransition()

        setupActivity()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        activity.invalidate()
        savePosition()

        guard let viewControllers = navigationController?.viewControllers else { return }
        if viewControllers.isEmpty || !(viewControllers.last! is ThreadTableViewController) {
            navigationController?.setToolbarHidden(true, animated: true)
        }
    }

    func configureStateController() {
        toolbarFactory = ThreadToolbarItemsFactory(items: settings.toolbarItems)
        toolbarFactory.delegate = self
        let items = toolbarFactory.makeBarItems(withStateController: stateController)
        favoriteButton = toolbarFactory.getBarItem(for: .favoriteButton)

        setToolbarItems(items, animated: false)
    }

    func itemTapped(_ sender: ThreadToolbarItemsFactory, item: ToolbarItem, barItem: UIBarButtonItem) {
        switch item {
        case .favoriteButton:
            favoriteButtonTapped(barItem)
        case .goDownButton:
            goDownButtonTapped(barItem)
        case .replyButton:
            if shouldPerformSegue(withIdentifier: "Reply", sender: self) {
                performSegue(withIdentifier: "Reply", sender: self)
            }
        case .refreshButton:
            refreshButtonTapped(barItem)
        default:
            break
        }
    }

    @objc func threadStateTapped() {
        if lastRefreshError.isEmpty, unreadPosts > 0 {
            let position = posts.count - unreadPosts
            tableView.scrollToRow(at: IndexPath(row: position, section: 0), at: .top, animated: true)
        } else if !lastRefreshError.isEmpty {
            let alert = UIAlertController(
                title: String(key: "ERROR"),
                message: lastRefreshError,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: String(key: "OK"), style: .default))
            present(alert, animated: true, completion: nil)
        }
    }

    func configureFavoritesState() {
        let favoriteThread = uiRealm
            .objects(FavoriteThread.self)
            .filter(
                "board = %@ AND number = %@ AND chanId = %@",
                navigationInfo.boardId,
                navigationInfo.threadNumber,
                chan.id
            )
            .first
        if favoriteThread != nil {
            self.favoriteThread = favoriteThread
        }

        isInFavorites = favoriteThread != nil
    }

    func updateFavoriteState(initialLoad: Bool) {
        guard let thread = favoriteThread else { return }
        guard posts.count > 0 else { return }

        if thread.isInvalidated {
            favoriteThread = nil
            configureFavoritesState()
            updateFavoriteState(initialLoad: false)
        }

        let lastReadPost = thread.lastReadPost
        if initialLoad {
            if lastReadPost != -1 {
                unreadPosts = posts.lazy.reversed().prefix { $0.number > lastReadPost }.count
                self.lastReadPost = lastReadPost
            } else if thread.lastLoadedPost < posts[0].number, thread.lastLoadedPost <= posts.count {
                unreadPosts = posts.count - thread.lastLoadedPost
                self.lastReadPost = thread.lastReadPost
            } else {
                unreadPosts = 0
                self.lastReadPost = posts.last!.number
            }
        }

        let newLastReadPost = max(self.lastReadPost, lastReadPost)

        do {
            try uiRealm.write {
                thread.unreadPosts = unreadPosts
                thread.lastLoadedPost = posts.last!.number
                thread.lastReadPost = newLastReadPost
            }
        } catch {}
    }

    func getTitleFrom(boardId: String, threadNumber: Int) -> String {
        "/\(boardId)/ - \(threadNumber)"
    }

    func loadPosts(from: Int?, onComplete: @escaping ([Post]?, String?) -> Void) {
        chan
            .loadThread(
                boardId: navigationInfo.boardId,
                number: navigationInfo.threadNumber,
                from: from
            ) { posts, error in
                onComplete(posts, error)
            }
    }

    @objc func refreshControlTriggered(_ sender: UIRefreshControl) {
        stateController.state = .refreshing
        refresh()
        sender.endRefreshing()
    }

    func refresh() {
        guard !isLoading, !isRefreshing else { return }

        isRefreshing = true
        loadPosts(from: posts.last?.number) { [weak self] newPosts, error in
            guard let self = self else { return }
            self.lastRefreshError = error ?? ""
            self.finishRefreshing(with: newPosts)
            self.isRefreshing = false
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        posts.count
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let cachedValue = heightCache[indexPath.row] {
            return cachedValue
        }

        let post = posts[indexPath.row]
        let width = view.bounds.width - cellPadding * 2
        let showAttachments = !post.attachments.isEmpty && settings.isMediaEnabled
        let height = PostTableViewCell.calculateHeight(
            width: width,
            hasAttachments: showAttachments,
            hasReplies: (replies[post.number]?.count ?? 0) > 0,
            header: post.header,
            postContent: post.attributedString,
            isHidden: isPostHidden(post),
            showHeaderAlongsideOfAttachments: showAttachments && post.attachments.count == 1
        )
        heightCache[indexPath.row] = height

        return height
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let theme = theme else { fatalError("theme is nil") }
        let cell = tableView.dequeueReusableCell(withIdentifier: "PostCell", for: indexPath) as! PostTableViewCell
        let post = posts[indexPath.row]
        let repliesCount = replies[post.number]?.count ?? 0
        cell.theme = theme
        cell.configure(
            from: post,
            tintColor: chan.tintColor(for: theme, userInterfaceStyle: traitCollection.userInterfaceStyle),
            repliesCount: repliesCount,
            delegate: self,
            isHidden: isPostHidden(post)
        )
        return cell
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let theme = theme else { fatalError("theme is nil") }
        if indexPath.row >= posts.count {
            let baseColor = view.tintColor!
            cell.backgroundColor = baseColor.withAlphaComponent(0.1)

            UIView.animate(
                withDuration: 1,
                delay: 2,
                options: [.allowUserInteraction],
                animations: {
                    cell.backgroundColor = theme.backgroundColor
                },
                completion: nil
            )
        }
    }

    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {
        if #available(iOS 10.0, *) {
            let generator = UISelectionFeedbackGenerator()
            self.selectionFeedbackGenerator = generator
            generator.prepare()
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            updateFavoriteState(initialLoad: false)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        updateFavoriteState(initialLoad: false)
    }

    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        updateFavoriteState(initialLoad: false)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateUnreadPostsCount()
    }

    func updateUnreadPostsCount() {
        guard let lastPost = lastVisiblePost() else { return }
        lastReadPost = max(lastReadPost, lastPost.number)
        unreadPosts = posts.lazy.reversed().prefix { $0.number > self.lastReadPost }.count
        stateController.state = .success(unreadPosts: unreadPosts)
    }

    func showRepliesViewController(_ viewController: RepliesTableViewController) {
        viewController.modalTransitionStyle = .coverVertical
        viewController.modalPresentationStyle = .overCurrentContext
        viewController.modalPresentationCapturesStatusBarAppearance = true
        viewController.delegate = self
        viewController.chan = chan
        viewController.postDelegate = self
        present(viewController, animated: true, completion: nil)
    }

    func getReplies(for post: Post) -> [Post] {
        replies[post.number] ?? []
    }

    func getPost(withNumber number: Int) -> Post? {
        posts.first { $0.number == number }
    }

    func scrollToPost(withNumber number: Int) {
        guard let index = posts.firstIndex(where: { $0.number == number }) else { return }
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .top, animated: true)
    }

    func isPostHidden(_ post: Post) -> Bool {
        hiddenPosts.contains(post.number)
    }

    func navigateToBoard(id: String) {
        guard let vc = storyboard?
            .instantiateViewController(withIdentifier: "ThreadsVC") as? ThreadsTableViewController else { return }
        vc.board = Board(id: id, name: "")
        vc.chan = chan
        navigationController?.pushViewController(vc, animated: true)
    }

    func navigateToThread(boardId: String, number: Int, postNumber: Int? = nil) {
        guard let vc = storyboard?.instantiateViewController(withIdentifier: "ThreadVC") as? ThreadTableViewController
        else { return }
        vc.navigationInfo = ThreadNavigationInfo(boardId: boardId, threadNumber: number, postNumber: postNumber)
        vc.chan = chan
        navigationController?.pushViewController(vc, animated: true)
    }

    func previewPost(number: Int) -> Bool {
        guard let post = posts.first(where: { $0.number == number }) else { return false }
        let viewController = RepliesTableViewController()
        viewController.postsStack.append([post])
        showRepliesViewController(viewController)

        return true
    }

    func initPostingController() {
        if postingController == nil {
            performSegue(withIdentifier: "Reply", sender: self)
        } else {
            navigationController?.pushViewController(postingController!, animated: true)
        }
    }

    func reply(to number: Int) {
        initPostingController()
        postingController?.reply(to: number, with: "")
    }

    func quote(_ post: Post) {
        performSegue(withIdentifier: "Quote", sender: post)
    }

    func didQuote(post: Post, withText text: String) {
        navigationController?.popViewController(animated: false)
        initPostingController()
        postingController?.reply(to: post.number, with: text)
    }

    // MARK: Post Delegate

    func showReplies(toPostAtCell cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let post = posts[indexPath.row]
        let viewController = RepliesTableViewController()
        viewController.postsStack.append(replies[post.number]!)
        showRepliesViewController(viewController)
    }

    func show(_ sender: PostTableViewCell, attachment: Attachment) {
        openAttachment(attachment)
    }

    func navigateBy(_ sender: PostTableViewCell, board: String, thread: Int?, post: Int?, type: PostPreviewType) {
        if let postNumber = post {
            if !previewPost(number: postNumber), let threadNumber = thread {
                navigateToThread(boardId: board, number: threadNumber, postNumber: postNumber)
            }
        } else if let threadNumber = thread {
            navigateToThread(boardId: board, number: threadNumber)
        } else if !board.isEmpty {
            navigateToBoard(id: board)
        }
    }

    // - MARK: Gallery delegate

    func galleryDidClose(_ gallery: GalleryViewController) {
        guard settings.scrollThreadWithGallery, presentedViewController == nil else { return }
        let attachment = allAttachments[gallery.activeItem]
        guard let index = posts.firstIndex(where: { $0.attachments.contains(attachment) }) else { return }
        tableView.scrollToRow(at: IndexPath(row: index, section: 0), at: .none, animated: true)
    }

    // MARK: - Navigation

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if let controller = postingController, identifier == "Reply" {
            navigationController?.pushViewController(controller, animated: true)
            return false
        }

        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Reply" {
            guard let controller = segue.destination as? PostingViewController else { return }
            controller.boardId = navigationInfo.boardId
            controller.chan = chan
            controller.mode = .reply(threadNumber: navigationInfo.threadNumber)
            postingController = controller
        } else if segue.identifier == "Quote" {
            guard
                let controller = segue.destination as? PostQuotingViewController,
                let post = sender as? Post else { return }
            controller.sourcePost = post
            controller.delegate = self
        }
    }

    func scrollToBottom() {
        let fullHeight = tableView.bounds.height - (tableView.contentInset.bottom + view.safeInsets.bottom)
        let y = max(0, tableView.contentSize.height - fullHeight)
        tableView.setContentOffset(CGPoint(x: 0, y: y), animated: true)
    }

    @IBAction func goDownButtonTapped(_ sender: UIBarButtonItem) {
        scrollToBottom()
    }

    @IBAction func favoriteButtonTapped(_ sender: UIBarButtonItem) {
        try? uiRealm.write {
            if isInFavorites {
                uiRealm.delete(uiRealm.objects(FavoriteThread.self).filter(
                    "chanId = %@ AND board = %@ AND number = %@",
                    chan.id,
                    navigationInfo.boardId,
                    navigationInfo.threadNumber
                ))
                favoriteThread = nil
            } else if posts.count > 0 {
                favoriteThread = FavoriteThread.create(
                    chan: chan,
                    boardId: navigationInfo.boardId,
                    threadNumber: navigationInfo.threadNumber,
                    opPost: posts.first!,
                    lastLoadedPost: posts.last!.number,
                    lastReadPost: lastReadPost,
                    unreadPosts: unreadPosts
                )
                uiRealm.add(favoriteThread!)
            }

            isInFavorites = !isInFavorites
        }
    }

    @IBAction func shareButtonTapped(_ sender: UIBarButtonItem) {
        let link = ThreadLink(boardId: navigationInfo.boardId, number: navigationInfo.threadNumber)
        guard let url = URL(string: chan.linkCoder.getURL(for: link)) else { return }

        let activities: [UIActivity] = [TUSafariActivity()]
        let controller = UIActivityViewController(activityItems: [url], applicationActivities: activities)
        controller.popoverPresentationController?.barButtonItem = sender
        present(controller, animated: true)
    }

    @IBAction func unwindToThread(segue: UIStoryboardSegue) {
        dismiss(animated: false, completion: nil)
        if segue.source is PostingViewController {
            refresh()
        }
    }

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        guard sender.state == .began else { return }
        let position = sender.location(in: tableView)

        guard
            let indexPath = tableView.indexPathForRow(at: position),
            let cell = tableView.cellForRow(at: indexPath) as? PostTableViewCell,
            cell.isHandlingGesture == false
        else { return }

        let post = posts[indexPath.row]

        if let (indexPath, _) = getAttachmentContext(for: cell, at: position),
           let attachmentCell = cell.attachmentsView.cellForItem(at: indexPath)
        {
            let attachment = post.attachments[indexPath.item]
            showAlertController(for: attachment, in: attachmentCell)
        } else {
            showAlertController(for: post, in: cell)
        }
    }

    func shareLink(cell: PostTableViewCell, url: URL, rect: CGRect, completion: @escaping () -> Void) {
        let activityController = UIActivityViewController(
            activityItems: [url],
            applicationActivities: [TUSafariActivity()]
        )
        activityController.popoverPresentationController?.sourceView = cell.postContent
        activityController.popoverPresentationController?.sourceRect = rect
        activityController.completionWithItemsHandler = { _, _, _, _ in
            completion()
        }

        present(activityController, animated: true)
    }

    func previewingContext(
        _ previewingContext: UIViewControllerPreviewing,
        viewControllerForLocation location: CGPoint
    ) -> UIViewController? {
        guard let postIndexPath = tableView.indexPathForRow(at: location) else { return nil }
        guard let postCell = tableView.cellForRow(at: postIndexPath) as? PostTableViewCell else { return nil }
        let relativePoint = tableView.convert(location, to: postCell.attachmentsView)
        guard let attachmentIndexPath = postCell.attachmentsView.indexPathForItem(at: relativePoint) else { return nil }
        guard let attributes = postCell.attachmentsView.layoutAttributesForItem(at: attachmentIndexPath)
        else { return nil }
        previewingContext.sourceRect = tableView.convert(attributes.frame, from: postCell.attachmentsView)

        let attachment = posts[postIndexPath.row].attachments[attachmentIndexPath.item]

        let vc = AttachmentPreviewViewController()
        let imageSize = CGSize(width: attachment.size.0, height: attachment.size.1)
        let boundsSize = CGSize(width: view.frame.width - 50, height: view.frame.height - 100)
        let resultSize = AttachmentPreviewViewController.calculateFittingSize(bounds: boundsSize, image: imageSize)
        vc.preferredContentSize = resultSize
        vc.attachment = attachment
        return vc
    }

    // MARK: Private

    private enum ThreadRefreshingResult {
        case success, failure
    }

    private var progressIndicator: UIActivityIndicatorView!
    private var toolbarFactory = ThreadToolbarItemsFactory(items: [.info])

    private var unreadPosts = 0
    private var lastReadPost = 0
    private var allAttachments = [Attachment]()
    private let stateController = ThreadStateViewController()
    private let uiRealm: Realm = RealmInstance.ui
    private var favoriteThread: FavoriteThread?
    private var lastRefreshError = ""
    private var isLoading = false
    private let repliesMapFormer = RepliesMapFormer()
    private var replies: [Int: [Post]] = [:]
    private var hiddenPosts = [Int]()
    private var heightCache = [Int: CGFloat]()
    private let backgroundQueue = DispatchQueue(label: "com.acedened.TheChan.ThreadBackgroundQueue")
    private let activity = NSUserActivity(activityType: "com.acedened.TheChan.OpenThreadPage")
    private var isRefreshing = false
    private var userPosts = [Int]()
    private var userPostsNotificationToken: NotificationToken?
    private let settings = UserSettings.shared
    private var historyItem = HistoryItem()
    private var selectionFeedbackGenerator: Any?
    private var theme: Theme?

    private var postingController: PostingViewController?

    private var isInFavorites = false {
        didSet {
            let imageName = isInFavorites ? "star.fill" : "star"
            favoriteButton.image = .init(
                systemName: imageName,
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            )
        }
    }

    private func setupFooter() {
        progressIndicator = UIActivityIndicatorView()
        errorLabel = UILabel()
        errorLabel?.textColor = .lightText
        errorLabel?.textAlignment = .center
        errorLabel?.font = UIFont.systemFont(ofSize: 15)
        tryAgainButton = UIButton()

        let stackView = UIStackView(arrangedSubviews: [progressIndicator, errorLabel!, tryAgainButton!])
        stackView.axis = .vertical

        tableView.tableFooterView = stackView
    }

    private func setupUserPostsNotifications() {
        let query = uiRealm.objects(UserPost.self)
            .filter("chanId = %@ AND boardId = %@", chan.id, navigationInfo.boardId)
        userPostsNotificationToken = query.observe { [weak self] _ in
            self?.userPosts = query.map(\.number)
        }
    }

    private func loadHiddenPosts() {
        let hiddenPosts = uiRealm.objects(HiddenPost.self).filter(
            "chanId = %@ AND boardId = %@ AND thread = %@", chan.id, navigationInfo.boardId, navigationInfo.threadNumber
        )

        for hiddenPost in hiddenPosts {
            self.hiddenPosts.append(hiddenPost.post)
        }
    }

    private func loadPostsIntoTable(_ posts: [Post]) {
        self.posts += posts

        let userInterfaceStyle = traitCollection.userInterfaceStyle
        backgroundQueue.async({ [weak self] in
            guard let self = self else { return }

            self.parseMarkupAndMakeHeaders(
                in: posts,
                userInterfaceStyle: userInterfaceStyle
            )

            self.replies = self.repliesMapFormer.createMapFrom(
                newPosts: posts,
                existingMap: self.replies
            )
        }) { [weak self] in
            guard let self = self else { return }

            self.title = posts.first!.getTitle()

            self.updateFavoriteState(initialLoad: true)
            self.updateThreadState(refreshingResult: .success)
            self.updateHistoryItem()
            self.tableView.stopLoading(indicator: self.progressIndicator)

            self.tableView.reloadData()
            self.performScrolling()
        }
    }

    private func parseMarkupAndMakeHeaders(
        in posts: [Post],
        userInterfaceStyle: UIUserInterfaceStyle,
        positionOffset: Int = 0
    ) {
        guard let opPost = self.posts.first, let theme = theme else { return }
        let builder = Post.HeaderBuilder(
            fontSize: settings.fontSize - 2,
            theme: theme,
            useMonospacedFont: settings.useMonospacedFontInPostInfo
        )
        for (index, post) in posts.enumerated() {
            post.markers.remove(.userPost)
            if userPosts.contains(post.number) {
                post.markers.insert(.userPost)
            }

            let showName = post.name != chan.defaultName && !post.name.isEmpty
            let position = positionOffset + index + 1

            post.header = post.attachments.count == 1
                ? builder.makeMultiLineHeader(for: post, showName: showName, position: position)
                : builder.makeSingleLineHeader(for: post, showName: showName, position: position)

            if let parser = chan.getMarkupParser(
                for: post.content,
                theme: theme,
                userInterfaceStyle: userInterfaceStyle
            ) {
                parser.opPost = opPost.number
                parser.userPosts = userPosts
                post.attributedString = parser.parse()
            }
        }
    }

    private func getIndexPathForFirstActuallyVisibleRow() -> IndexPath? {
        guard let navigationBar = navigationController?.navigationBar else { return nil }
        let localFrame = tableView.convert(navigationBar.bounds, from: navigationBar)
        let point = CGPoint(x: 0, y: localFrame.origin.y + localFrame.size.height + 1)
        return tableView.indexPathForRow(at: point)
    }

    private func savePosition() {
        guard let firstVisibleIndexPath = getIndexPathForFirstActuallyVisibleRow() else { return }
        let post = posts[firstVisibleIndexPath.row]

        try! uiRealm.write {
            historyItem.position = post.number
        }
    }

    private func finishRefreshing(with posts: [Post]?) {
        if let posts = posts {
            self.posts += posts
            unreadPosts += posts.count
            updateFavoriteState(initialLoad: false)
            let userInterfaceStyle = traitCollection.userInterfaceStyle

            backgroundQueue.async({ [weak self] in
                guard let self = self else { return }

                self.parseMarkupAndMakeHeaders(
                    in: self.posts,
                    userInterfaceStyle: userInterfaceStyle
                )
                self.replies = self.repliesMapFormer.createMapFrom(
                    newPosts: posts,
                    existingMap: self.replies
                )
            }, completion: { [weak self] in
                guard let self = self else { return }

                self.updateThreadState(refreshingResult: .success)

                for indexPath in self.getIndexPathsForAffectedRows() {
                    self.heightCache.removeValue(forKey: indexPath.row)
                }

                self.tableView.reloadData()
            })
        } else {
            updateThreadState(refreshingResult: .failure)
        }

        if #available(iOS 10, *) {
            let feedbackGenerator = UINotificationFeedbackGenerator()
            let type: UINotificationFeedbackGenerator.FeedbackType = posts != nil ? .success : .error
            feedbackGenerator.notificationOccurred(type)
        }
    }

    private func getIndexPathsForAffectedRows() -> [IndexPath] {
        // TODO: This implementation is retarded
        var indexPaths = [IndexPath]()
        let affectedPosts = repliesMapFormer.affectedPosts
        for number in affectedPosts {
            guard let index = posts.firstIndex(where: { $0.number == number }) else { continue }
            indexPaths.append(IndexPath(row: index, section: 0))
        }

        return indexPaths
    }

    @IBAction private func refreshButtonTapped(_ sender: UIBarButtonItem) {
        stateController.state = .refreshing
        refresh()
    }

    private func updateThreadState(refreshingResult: ThreadRefreshingResult) {
        switch refreshingResult {
        case .failure:
            stateController.state = .error(message: lastRefreshError)
        default:
            stateController.state = .success(unreadPosts: unreadPosts)
        }
    }

    private func hidePost(at cell: PostTableViewCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        heightCache.removeValue(forKey: indexPath.row)
        let post = posts[indexPath.row]

        if let index = hiddenPosts.firstIndex(of: post.number) {
            hiddenPosts.remove(at: index)
            if let hiddenPost = getHiddenPost(withNumber: post.number) {
                try? uiRealm.write {
                    uiRealm.delete(hiddenPost)
                }
            }
        } else {
            hiddenPosts.append(post.number)

            let hiddenPostItem = HiddenPost()
            hiddenPostItem.chanId = chan.id
            hiddenPostItem.boardId = navigationInfo.boardId
            hiddenPostItem.thread = navigationInfo.threadNumber
            hiddenPostItem.post = post.number
            hiddenPostItem.hidingDate = Date()
            try? uiRealm.write {
                uiRealm.add(hiddenPostItem)
            }
        }

        tableView.reloadRows(at: [indexPath], with: .fade)
    }

    private func getHiddenPost(withNumber number: Int) -> HiddenPost? {
        uiRealm.objects(HiddenPost.self).first {
            $0.chanId == chan.id && $0.boardId == navigationInfo.boardId && $0.thread == navigationInfo
                .threadNumber && $0.post == number
        }
    }

    private func openAttachment(_ attachment: Attachment) {
        let showVideosInGallery = settings.showVideosInGallery
        if attachment.type == .video, !showVideosInGallery {
            let videoController = VideoViewController(url: attachment.url)

            dismiss(animated: false, completion: nil)
            navigationController?.pushViewController(videoController, animated: true)
            return
        }

        allAttachments = posts.flatMap { post in post.attachments }.filter { showVideosInGallery || $0.type != .video }
        let gallery = GalleryViewController(nibName: "GalleryViewController", bundle: .main)
        gallery.attachments = allAttachments
        gallery.activeItem = allAttachments.firstIndex(of: attachment) ?? 0
        gallery.delegate = self
        gallery.modalPresentationStyle = .overCurrentContext
        gallery.modalPresentationCapturesStatusBarAppearance = true

        if let presentedVc = presentedViewController {
            presentedVc.present(gallery, animated: true, completion: nil)
        } else {
            present(gallery, animated: true)
        }
    }

    private func getAttachmentContext(
        for cell: PostTableViewCell,
        at position: CGPoint
    ) -> (indexPath: IndexPath, frame: CGRect)? {
        let relativePoint = tableView.convert(position, to: cell.attachmentsView)
        guard let attachmentIndexPath = cell.attachmentsView.indexPathForItem(at: relativePoint) else { return nil }
        guard let attributes = cell.attachmentsView.layoutAttributesForItem(at: attachmentIndexPath) else { return nil }
        return (attachmentIndexPath, attributes.frame)
    }

    private func showAlertController(for post: Post, in cell: PostTableViewCell) {
        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = cell
        controller.popoverPresentationController?.sourceRect = cell.bounds
        controller.addAction(UIAlertAction(title: String(key: "REPLY"), style: .default, handler: { _ in
            self.reply(to: post.number)
        }))
        controller.addAction(UIAlertAction(title: String(key: "QUOTE"), style: .default, handler: { _ in
            self.quote(post)
        }))
        controller.addAction(UIAlertAction(title: String(key: "SHARE"), style: .default, handler: { _ in
            let text = post.text
            var items: [Any] = [text]
            let link = PostLink(
                boardId: self.navigationInfo.boardId,
                threadNumber: self.navigationInfo.threadNumber,
                number: post.number
            )
            let url = URL(string: self.chan.linkCoder.getURL(for: link))
            if let url = url {
                items.append(url)
            }

            let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
            controller.popoverPresentationController?.sourceView = cell
            controller.popoverPresentationController?.sourceRect = cell.bounds
            self.present(controller, animated: true)
        }))

        let hideTitleKey = hiddenPosts.contains(post.number) ? "SHOW" : "HIDE"
        controller.addAction(UIAlertAction(title: String(key: hideTitleKey), style: .default, handler: { _ in
            self.hidePost(at: cell)
        }))

        let markTitleKey = userPosts.contains(post.number) ? "UNMARK_MY_POST" : "MARK_MY_POST"
        controller.addAction(UIAlertAction(title: String(key: markTitleKey), style: .default, handler: { _ in
            self.markUserPost(number: post.number)
        }))

        controller.addAction(UIAlertAction(title: String(key: "CANCEL"), style: .cancel, handler: nil))

        if #available(iOS 10, *), let generator = selectionFeedbackGenerator as? UISelectionFeedbackGenerator {
            generator.selectionChanged()
        }

        present(controller, animated: true)
    }

    private func markUserPost(number: Int) {
        if let post = uiRealm.objects(UserPost.self)
            .filter("chanId = %@ AND number = %@ AND boardId = %@", chan.id, number, navigationInfo.boardId).first
        {
            try! uiRealm.write {
                uiRealm.delete(post)
            }
        } else {
            let post = UserPost()
            post.chanId = chan.id
            post.number = number
            post.boardId = navigationInfo.boardId
            try! uiRealm.write {
                uiRealm.add(post)
            }
        }

        let userInterfaceStyle = traitCollection.userInterfaceStyle
        backgroundQueue.async({ [weak self] in
            self?.parseMarkupAndMakeHeaders(in: self?.posts ?? [], userInterfaceStyle: userInterfaceStyle)
        }) { [weak self] in
            self?.tableView.reloadData()
        }
    }

    private func showAlertController(for attachment: Attachment, in view: UIView) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        alertController.popoverPresentationController?.sourceRect = view.bounds
        alertController.popoverPresentationController?.sourceView = view
        let shareAction = UIAlertAction(title: String(key: "SHARE"), style: .default, handler: { _ in
            let activityViewController = UIActivityViewController(
                activityItems: [attachment.url],
                applicationActivities: nil
            )
            activityViewController.popoverPresentationController?.sourceView = view
            activityViewController.popoverPresentationController?.sourceRect = view.bounds
            self.present(activityViewController, animated: true)
        })

        let cancelAction = UIAlertAction(title: String(key: "CANCEL"), style: .cancel, handler: nil)

        alertController.addAction(shareAction)
        alertController.addAction(cancelAction)
        present(alertController, animated: true)
    }

    private func lastVisiblePost() -> Post? {
        let point = view.convert(CGPoint(x: 0, y: view.safeAreaLayoutGuide.layoutFrame.maxY), to: tableView)
        guard let indexPath = tableView.indexPathForRow(at: point) else { return posts.last }
        let rect = tableView.rectForRow(at: indexPath)
        let postIndex = rect.maxY - point.y < 10 ? indexPath.row : indexPath.row - 1
        return posts.isEmpty ? nil : posts[max(0, postIndex)]
    }
}

extension PostTableViewCell {
    func configure(from post: Post, tintColor: UIColor, repliesCount: Int, delegate: PostDelegate, isHidden: Bool) {
        setTextTintColor(tintColor)
        postContent.attributedText = post.attributedString

        header.attributedText = post.header
        attachments = post.attachments
        showAttachments = !post.attachments.isEmpty && UserSettings.shared.isMediaEnabled
        showHeaderAlongsideOfAttachments = showAttachments && attachments.count == 1
        attachmentsView.reloadData()

        isPostHidden = isHidden

        self.delegate = delegate

        showReplies = repliesCount > 0
        replies.setTitle(String(localizedFormat: "%d replies", argument: repliesCount), for: .normal)
    }
}

extension ThreadTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        tableView.backgroundColor = view.backgroundColor
        tableView.separatorColor = theme.separatorColor
        errorLabel?.textColor = theme.altTextColor
        navigationController?.toolbar.standardAppearance = .fromTheme(theme)
        if #available(iOS 15.0, *) {
            navigationController?.toolbar.scrollEdgeAppearance = .fromTheme(theme)
        }

        stateController.indicatorTint = theme.tintColorOverride ?? chan.darkColor
        parseMarkupAndMakeHeaders(in: posts, userInterfaceStyle: traitCollection.userInterfaceStyle)
        tableView.reloadData()
    }
}
