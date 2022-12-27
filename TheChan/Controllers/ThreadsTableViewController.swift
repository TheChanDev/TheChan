import AsyncDisplayKit
import Kingfisher
import RealmSwift
import UIKit

class ThreadsTableViewController:
    UIViewController, ASCollectionDelegate, ASCollectionDataSource, LoadableWithError, Themable
{
    // MARK: Internal

    var chan: Chan!
    var activityIndicator: UIActivityIndicatorView!
    var errorLabel: UILabel?
    var tryAgainButton: UIButton?
    var loadingView = UIView()

    var board: Board = .init(id: "board", name: "Undefined board") {
        didSet {
            title = board.name.isEmpty
                ? "/\(board.id)/"
                : "/\(board.id)/ - \(board.name)"
        }
    }

    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        collectionNode.backgroundColor = view.backgroundColor
        errorLabel?.textColor = theme.altTextColor
        parseMarkup(in: threads, userInterfaceStyle: traitCollection.userInterfaceStyle)
        collectionNode.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubnode(collectionNode)

        if #available(iOS 10.0, *) {
            collectionNode.view.refreshControl = refreshControl
        } else {
            collectionNode.view.addSubview(refreshControl)
        }

        refreshControl.addTarget(self, action: #selector(refresh(refreshControl:)), for: .valueChanged)

        activityIndicator = UIActivityIndicatorView()
        loadingView = makeFooter(progressIndicator: &activityIndicator!)
        setupLoadable(
            buttonImage: .init(
                systemName: "arrow.clockwise",
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            )!,
            selector: #selector(onTriedAgain)
        )

        activityIndicator.hidesWhenStopped = true
        view.addSubview(loadingView)
        subscribeForThemeChanges()

        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.view.contentInsetAdjustmentBehavior = .always

        loadHiddenThreads()
    }

    @objc func onTriedAgain() {
        errorLabel?.isHidden = true
        tryAgainButton?.isHidden = true
        currentPage = -1
        wasLastLoadingSuccessful = true
        threads.removeAll()
        collectionNode.reloadData()
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        collectionNode.frame = view.bounds
        loadingView.frame = CGRect(x: 0, y: view.safeInsets.top, width: view.bounds.width, height: 60)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let selection = collectionNode.indexPathsForSelectedItems?.first {
            collectionNode.deselectItem(at: selection, animated: true)
            transitionCoordinator?.notifyWhenInteractionChanges { [weak self] context in
                if context.isCancelled {
                    self?.collectionNode.selectItem(at: selection, animated: false, scrollPosition: [])
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        navigationItem.hidesBackButton = false
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
    }

    @objc func refresh(refreshControl: UIRefreshControl) {
        if isLoading { return }

        wasLastLoadingSuccessful = true
        threads.removeAll()
        collectionNode.reloadData()
        currentPage = -1
        refreshControl.endRefreshing()
    }

    func getHiddenThread(withNumber number: Int) -> HiddenPost? {
        uiRealm.objects(HiddenPost.self).first {
            $0.chanId == chan.id && $0.boardId == board.id && $0.post == $0.thread && $0.thread == number
        }
    }

    // MARK: - ASCollectionDataSource

    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        1
    }

    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        threads.count
    }

    func shouldBatchFetch(for collectionNode: ASCollectionNode) -> Bool {
        !isLoading && wasLastLoadingSuccessful
    }

    func collectionNode(_ collectionNode: ASCollectionNode, willBeginBatchFetchWith context: ASBatchContext) {
        isLoading = true

        DispatchQueue.main.async { [weak self] in
            if self?.currentPage == -1 {
                self?.loadingView.isHidden = false
                self?.activityIndicator.startAnimating()
                self?.tryAgainButton?.isHidden = true
                self?.errorLabel?.isHidden = true
            }
        }

        chan.loadThreads(boardId: board.id, page: currentPage + 1) { [weak self] threads, error in

            guard let self = self else { return }

            self.activityIndicator.stopAnimating()
            if let threads = threads {
                self.loadingView.isHidden = true
                let userInterfaceStyle = self.traitCollection.userInterfaceStyle
                self.backgroundQueue.async({
                    self.parseMarkup(in: threads, userInterfaceStyle: userInterfaceStyle)
                }) {
                    self.updateThreads(threads)
                    self.wasLastLoadingSuccessful = true
                }
            } else if let error = error, self.currentPage == -1 {
                self.showError(error: error)
                self.wasLastLoadingSuccessful = false
            } else {
                self.wasLastLoadingSuccessful = false
            }

            self.currentPage += 1
            self.isLoading = false
            context.completeBatchFetching(true)
        }
    }

    func collectionNode(
        _ collectionNode: ASCollectionNode,
        nodeBlockForItemAt indexPath: IndexPath
    ) -> ASCellNodeBlock {
        guard let theme = theme else { fatalError("theme is nil") }
        let thread = threads[indexPath.item]
        let builder = Thread.HeaderBuilder(fontSize: UserSettings.shared.fontSize - 1, theme: theme)
        let tintColor = chan.tintColor(for: theme, userInterfaceStyle: traitCollection.userInterfaceStyle)
        return {
            thread.opPost.header = builder.makeHeader(
                for: thread,
                showName: thread.opPost.name != self.chan.defaultName && !thread.opPost.name.isEmpty,
                tintColor: tintColor
            )

            let node = ThreadTableCellNode(
                theme: theme,
                subject: thread.opPost.subject,
                header: thread.opPost.header,
                imageUrl: thread.opPost.attachments[safe: 0]?.thumbnailUrl,
                color: tintColor,
                omittedPosts: thread.omittedPosts,
                omittedFiles: thread.omittedFiles
            )
            node.showName = thread.opPost.name != self.chan.defaultName && !thread.opPost.name.isEmpty
            node.showSubject = !thread.opPost.subject.isEmpty && !thread.opPost.isSubjectRedundant
            node.textNode.attributedText = thread.opPost.attributedString
            node.showImage = thread.opPost.attachments.count > 0 && UserSettings.shared.isMediaEnabled
            node.isThreadHidden = self.hiddenThreads.contains(thread.opPost.number)

            let holdRecognizer = UILongPressGestureRecognizer()
            node.addGestureRecognizer(holdRecognizer, callback: { [weak self] node in
                self?.threadLongPressHandler(holdRecognizer, node: node)
            })

            return node
        }
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        guard let viewController = storyboard?
            .instantiateViewController(withIdentifier: "ThreadVC") as? ThreadTableViewController else { return }
        let thread = threads[indexPath.item]
        viewController.chan = chan
        viewController.navigationInfo = ThreadNavigationInfo(boardId: board.id, threadNumber: thread.opPost.number)
        navigationController?.pushViewController(viewController, animated: true)
    }

    func collectionNode(
        _ collectionNode: ASCollectionNode,
        constrainedSizeForItemAt indexPath: IndexPath
    ) -> ASSizeRange {
        let width = view.bounds.width - 8 * 2 - view.safeAreaInsets.left - view.safeAreaInsets.right
        return ASSizeRangeMake(
            CGSize(width: width, height: 0),
            CGSize(width: width, height: CGFloat.greatestFiniteMagnitude)
        )
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "NewThread" {
            let postingController = segue.destination as! PostingViewController
            postingController.mode = .newThread
            postingController.boardId = board.id
            postingController.chan = chan
        }
    }

    @IBAction func catalogButtonTapped(_ sender: Any) {
        let catalog = CatalogViewController(chan: chan, boardId: board.id)
        navigationController?.pushViewController(catalog, animated: true)
    }

    // MARK: Private

    private let collectionNode: ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        return ASCollectionNode(collectionViewLayout: layout)
    }()

    private var threads = [Thread]()
    private var currentPage = -1
    private var isLoading = false
    private var wasLastLoadingSuccessful = true
    private var hiddenThreads = [Int]()
    private let uiRealm: Realm = RealmInstance.ui
    private var theme: Theme?
    private let refreshControl = UIRefreshControl()
    private let backgroundQueue = DispatchQueue(label: "com.acedened.TheChan.ThreadsBackgroundQueue")

    private func loadHiddenThreads() {
        let hiddenPosts = uiRealm.objects(HiddenPost.self).filter(
            "chanId = %@ AND boardId = %@ AND thread = post", chan.id, board.id
        )

        for hiddenThread in hiddenPosts {
            hiddenThreads.append(hiddenThread.thread)
        }
    }

    private func updateThreads(_ threads: [Thread]) {
        var affectedThreadsPositions = [Int]()
        var newThreads = [Thread]()
        for thread in threads {
            if let index = self.threads.firstIndex(where: { $0.opPost.number == thread.opPost.number }) {
                let existingThread = self.threads[index]
                existingThread.omittedPosts = thread.omittedPosts
                existingThread.omittedFiles = thread.omittedFiles
                affectedThreadsPositions.append(index)
            } else {
                newThreads.append(thread)
            }
        }

        let updatedIndexPaths = affectedThreadsPositions.map { IndexPath(row: $0, section: 0) }

        let position = self.threads.count
        let insertedIndexPaths = (position ..< (position + newThreads.count)).map { IndexPath(row: $0, section: 0) }

        self.threads += newThreads

        collectionNode.performBatchUpdates({
            collectionNode.reloadItems(at: updatedIndexPaths)
            collectionNode.insertItems(at: insertedIndexPaths)
        })
    }

    private func parseMarkup(in threads: [Thread], userInterfaceStyle: UIUserInterfaceStyle) {
        guard let theme = theme else { fatalError("theme is nil") }

        for thread in threads {
            if let parser = chan.getMarkupParser(
                for: thread.opPost.content,
                theme: theme,
                userInterfaceStyle: userInterfaceStyle
            ) {
                thread.opPost.attributedString = parser.parse()
            }
        }
    }

    private func threadLongPressHandler(_ sender: UILongPressGestureRecognizer, node: ThreadTableCellNode) {
        guard sender.state == .began else { return }
        guard let indexPath = collectionNode.indexPath(for: node) else { return }
        guard let thread = threads[safe: indexPath.row] else { return }

        let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        controller.popoverPresentationController?.sourceView = node.view
        controller.popoverPresentationController?.sourceRect = node.bounds

        let hideShowActionTitleKey = hiddenThreads.contains(thread.opPost.number) ? "SHOW" : "HIDE"
        let hideShowAction = UIAlertAction(title: String(key: hideShowActionTitleKey), style: .default, handler: { _ in
            self.hideThread(withNumber: thread.opPost.number, at: indexPath)
        })

        let cancel = UIAlertAction(title: String(key: "CANCEL"), style: .cancel, handler: nil)

        controller.addAction(hideShowAction)
        controller.addAction(cancel)
        present(controller, animated: true)
    }

    private func hideThread(withNumber number: Int, at indexPath: IndexPath) {
        if let index = hiddenThreads.firstIndex(of: number) {
            hiddenThreads.remove(at: index)
            if let hiddenThread = getHiddenThread(withNumber: number) {
                try? uiRealm.write {
                    uiRealm.delete(hiddenThread)
                }
            }
        } else {
            hiddenThreads.append(number)

            let hiddenThread = HiddenPost()
            hiddenThread.chanId = chan.id
            hiddenThread.boardId = board.id
            hiddenThread.thread = number
            hiddenThread.post = number
            hiddenThread.hidingDate = Date()

            try? uiRealm.write {
                uiRealm.add(hiddenThread)
            }
        }

        collectionNode.reloadItems(at: [indexPath])
    }
}
