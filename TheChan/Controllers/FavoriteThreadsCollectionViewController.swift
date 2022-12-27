import DZNEmptyDataSet
import RealmSwift
import UIKit

private let reuseIdentifier = "FavoriteThreadCollectionViewCell"
private let minItemWidth = CGFloat(135.0)

protocol UpdateOperationDelegate: AnyObject {
    func onUpdated(thread: FavoriteThread, posts: [Post]?)
}

private class UpdateOperation: ConcurrentOperation {
    // MARK: Lifecycle

    init(chan: Chan, thread: FavoriteThread, delegate: UpdateOperationDelegate? = nil) {
        self.chan = chan
        self.thread = thread
        self.delegate = delegate
        boardId = thread.board
        threadNumber = thread.number
        loadFrom = thread.lastReadPost == -1 ? nil : thread.lastReadPost
        super.init()
    }

    // MARK: Internal

    let chan: Chan
    let thread: FavoriteThread
    weak var delegate: UpdateOperationDelegate?

    // MARK: Fileprivate

    override fileprivate func main() {
        chan.loadThread(boardId: boardId, number: threadNumber, from: loadFrom) { [weak self] posts, error in
            guard let self = self else { return }
            if error != nil {
                self.chan.loadThread(boardId: self.boardId, number: self.threadNumber, from: nil) { posts, _ in
                    self.delegate?.onUpdated(thread: self.thread, posts: posts)
                    self.completeOperation()
                }
            } else {
                self.delegate?.onUpdated(thread: self.thread, posts: posts)
                self.completeOperation()
            }
        }
    }

    // MARK: Private

    private let boardId: String
    private let threadNumber: Int
    private let loadFrom: Int?
}

class FavoriteThreadsCollectionViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout,
    UpdateOperationDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, Themable
{
    // MARK: Lifecycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        navigationController?.tabBarItem.image = .init(
            systemName: "star",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        navigationController?.tabBarItem.selectedImage = .init(
            systemName: "star.fill",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )
    }

    deinit {
        notificationToken?.invalidate()
    }

    // MARK: Internal

    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var refreshButton: UIBarButtonItem!

    func applyTheme(_ theme: Theme) {
        self.theme = theme
        collectionView?.backgroundColor = theme.altBackgroundColor
        collectionView?.reloadData()
        navigationController?.navigationBar.standardAppearance = .fromTheme(theme)
        navigationController?.view.backgroundColor = theme.backgroundColor
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()

        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh(_:)), for: .valueChanged)
        refreshButton.image = .init(
            systemName: "arrow.clockwise",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        collectionView?.addSubview(refreshControl)
        collectionView?.alwaysBounceVertical = true
        collectionView?.emptyDataSetSource = self
        collectionView?.emptyDataSetDelegate = self

        uiRealm = RealmInstance.ui

        setupNotifications()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currentChanChanged),
            name: ChanManager.currentChanChangedNotificationName,
            object: nil
        )

        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView?.addGestureRecognizer(holdGesture)

        updateFavorites()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView?.reloadSections(.init(integer: 0))
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        collectionView?.reloadEmptyDataSet()
    }

    func setupNotifications() {
        notificationToken?.invalidate()
        notificationToken = uiRealm?.objects(FavoriteThread.self).filter("chanId = %@", chanManager.currentChan.id)
            .observe { _ in
                self.updateFavorites()
            }
    }

    func updateFavorites() {
        favorites.removeAll()
        if let favs = uiRealm?.objects(FavoriteThread.self).filter("chanId = %@", chanManager.currentChan.id) {
            favorites = Array(favs)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @objc func currentChanChanged() {
        updateFavorites()
        setupNotifications()
    }

    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        UIImage(systemName: "star", withConfiguration: UIImage.SymbolConfiguration(pointSize: 48, weight: .semibold))
    }

    func verticalOffset(forEmptyDataSet scrollView: UIScrollView!) -> CGFloat {
        0
    }

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        NSAttributedString(
            string: String(key: "FAVORITES_EMPTY_MESSAGE"),
            attributes: [
                .foregroundColor: theme!.altTextColor,
                .font: UIFont.systemFont(ofSize: 16, weight: .regular),
            ]
        )
    }

    func imageTintColor(forEmptyDataSet scrollView: UIScrollView!) -> UIColor! {
        theme?.altTextColor
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenThread" {
            let chan = chanManager.currentChan
            guard let threadController = segue.destination as? ThreadTableViewController else { return }
            guard let cell = sender as? UICollectionViewCell else { return }
            guard let indexPath = collectionView?.indexPath(for: cell) else { return }
            let thread = favorites[indexPath.item]
            threadController.navigationInfo = ThreadNavigationInfo(boardId: thread.board, threadNumber: thread.number)
            threadController.chan = chan
        }
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        favorites.count
    }

    override func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        guard let theme = theme else { fatalError("theme is nil") }
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: reuseIdentifier,
            for: indexPath
        ) as! FavoriteThreadCollectionViewCell
        let thread = favorites[indexPath.row]

        cell.boardLabel.textColor = chanManager.currentChan.tintColor(
            for: theme,
            userInterfaceStyle: traitCollection.userInterfaceStyle
        )
        cell.theme = theme
        cell.boardLabel.text = thread.board
        cell.threadNameLabel.text = thread.name
        cell.unreadPostsLabel.text = "\(thread.unreadPosts)"
        cell.unreadPostsLabelBackgroundView.backgroundColor =
            thread.unreadPosts > 0 ? theme.tintColorOverride ?? chanManager.currentChan.lightColor : UIColor(
                white: 0,
                alpha: 0.25
            )

        cell.thumbnailImageView.kf.setImage(with: URL(string: thread.thumbnailUrl))

        return cell
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard let layout = collectionViewLayout as? UICollectionViewFlowLayout else { return }
        layout.invalidateLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView?.bringSubviewToFront(activityIndicator)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        let layout = collectionViewLayout as! UICollectionViewFlowLayout
        let availableWidth = collectionView.frame.width - layout.sectionInset.left - layout.sectionInset.right
        let spacing = layout.minimumInteritemSpacing
        let minItemWidthWithSpacing = spacing + minItemWidth
        let numberOfItemsCanFit = floor(availableWidth / minItemWidthWithSpacing)
        let itemWidth = (availableWidth - spacing * (numberOfItemsCanFit - 1)) / numberOfItemsCanFit
        return CGSize(width: itemWidth, height: 105)
    }

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        let point = sender.location(in: collectionView)
        guard let indexPath = collectionView?.indexPathForItem(at: point) else { return }
        guard let cell = collectionView?.cellForItem(at: indexPath) else { return }
        let thread = favorites[indexPath.item]

        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.popoverPresentationController?.sourceView = cell
        sheet.popoverPresentationController?.sourceRect = cell.bounds

        let deleteAction = UIAlertAction(title: String(key: "DELETE"), style: .destructive, handler: { _ in
            guard let realm = self.uiRealm else { return }
            try! realm.write {
                realm.delete(thread)
            }

            self.updateFavorites()
            self.collectionView?.reloadSections(IndexSet(integer: 0))
        })

        let cancelAction = UIAlertAction(title: String(key: "CANCEL"), style: .cancel, handler: nil)

        sheet.addAction(deleteAction)
        sheet.addAction(cancelAction)
        present(sheet, animated: true)
    }

    @objc func refresh(_ sender: UIRefreshControl) {
        refreshButton.isEnabled = false
        updateFavorites {
            self.refreshButton.isEnabled = true
            sender.endRefreshing()
            self.collectionView?.reloadSections(IndexSet(integer: 0))
        }
    }

    @IBAction func refreshButtonTapped(_ sender: UIBarButtonItem) {
        activityIndicator.startAnimating()
        sender.isEnabled = false
        updateFavorites {
            sender.isEnabled = true
            self.activityIndicator.stopAnimating()
            self.collectionView?.reloadSections(IndexSet(integer: 0))
        }
    }

    func updateFavorites(onComplete: @escaping () -> Void) {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1
        let operations = favorites
            .map { UpdateOperation(chan: self.chanManager.currentChan, thread: $0, delegate: self) }
        queue.addOperations(operations, waitUntilFinished: false)
        queue.addOperation {
            DispatchQueue.main.async {
                onComplete()
            }
        }
    }

    func onUpdated(thread: FavoriteThread, posts: [Post]?) {
        guard let posts = posts, let lastPost = posts.last else { return }
        let unreadPosts: Int
        if thread.lastReadPost != -1 {
            unreadPosts = posts.lazy.reversed().prefix(while: { $0.number > thread.lastReadPost }).count
        } else if thread.lastLoadedPost < thread.number {
            unreadPosts = thread.unreadPosts + max(0, posts.count - thread.lastLoadedPost)
        } else {
            unreadPosts = thread.unreadPosts + posts.count
        }

        try! uiRealm?.write {
            thread.lastLoadedPost = lastPost.number
            thread.unreadPosts = unreadPosts
        }
    }

    // MARK: Private

    private var uiRealm: Realm?
    private var notificationToken: NotificationToken?
    private let chanManager = ChanManager.shared
    private var favorites = [FavoriteThread]()
    private var theme: Theme?
}
