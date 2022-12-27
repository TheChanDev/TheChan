import AsyncDisplayKit
import UIKit
private let spacing: CGFloat = 8
private let maxItemWidth: CGFloat = 200
class CatalogViewController: UIViewController, ASCollectionDelegate, ASCollectionDataSource,
    UICollectionViewDelegateFlowLayout, UISearchResultsUpdating, LoadableWithError, UISearchBarDelegate
{
    // MARK: Lifecycle

    init(chan: Chan, boardId: String) {
        self.chan = chan
        self.boardId = boardId

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        searchTimer?.invalidate()
    }

    // MARK: Internal

    var footerView = UIView()
    var tryAgainButton: UIButton?
    var errorLabel: UILabel?
    var activityIndicator = UIActivityIndicatorView()

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubnode(collectionNode)
        collectionNode.delegate = self
        collectionNode.dataSource = self
        collectionNode.alwaysBounceVertical = true

        searchController.searchBar.delegate = self
        searchController.searchResultsUpdater = self
        searchController.modalPresentationCapturesStatusBarAppearance = true
        navigationItem.searchController = searchController

        collectionNode.view.contentInsetAdjustmentBehavior = .always
        edgesForExtendedLayout = [.top]
        extendedLayoutIncludesOpaqueBars = true
        definesPresentationContext = true
        title = String(key: "CATALOG_TITLE")
        footerView = makeFooter(progressIndicator: &activityIndicator)
        activityIndicator.hidesWhenStopped = true
        view.addSubview(footerView)
        setupLoadable(
            buttonImage: .init(
                systemName: "arrow.clockwise",
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            )!,
            selector: #selector(loadCatalog)
        )

        subscribeForThemeChanges()

        searchTimer = Timer.scheduledTimer(
            timeInterval: 0.5,
            target: self,
            selector: #selector(searchTimerTriggered(_:)),
            userInfo: nil,
            repeats: true
        )

        loadCatalog()
    }

    override func viewWillDisappear(_ animated: Bool) {
        dismiss(animated: animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionNode.frame = view.bounds
        footerView.frame = CGRect(
            x: 0,
            y: view.safeInsets.top,
            width: view.bounds.width,
            height: 60
        )
    }

    func numberOfSections(in collectionNode: ASCollectionNode) -> Int {
        1
    }

    func collectionNode(_ collectionNode: ASCollectionNode, numberOfItemsInSection section: Int) -> Int {
        isSearching ? searchResults.count : threads.count
    }

    func collectionNode(
        _ collectionNode: ASCollectionNode,
        nodeBlockForItemAt indexPath: IndexPath
    ) -> ASCellNodeBlock {
        guard let theme = theme else { fatalError("Expected to have theme before creating a cell") }
        let thread = isSearching ? searchResults[indexPath.item] : threads[indexPath.item]
        return {
            let cell = CatalogCellNode(
                theme: theme,
                subject: thread.opPost.subject,
                showSubject: !thread.opPost.isSubjectRedundant,
                content: thread.opPost.attributedString,
                omittedFiles: thread.omittedFiles,
                omittedPosts: thread.omittedPosts,
                imageURL: thread.opPost.attachments.first?.thumbnailUrl
            )

            return cell
        }
    }

    func collectionNode(
        _ collectionNode: ASCollectionNode,
        constrainedSizeForItemAt indexPath: IndexPath
    ) -> ASSizeRange {
        let availableWidth = collectionNode.frame.width
        let numberOfItemsCanFit = ceil(availableWidth / maxItemWidth)
        let itemWidth = (availableWidth - spacing * (numberOfItemsCanFit + 1)) / numberOfItemsCanFit

        let height: CGFloat = 200
        return ASSizeRangeMake(CGSize(width: floor(itemWidth), height: height))
    }

    func collectionNode(_ collectionNode: ASCollectionNode, didSelectItemAt indexPath: IndexPath) {
        guard let controller =
            navigationController?.storyboard?.instantiateViewController(withIdentifier: "ThreadVC")
                as? ThreadTableViewController else { return }
        let thread = isSearching ? searchResults[indexPath.item] : threads[indexPath.item]
        controller.chan = chan
        controller.navigationInfo = ThreadNavigationInfo(boardId: boardId, threadNumber: thread.opPost.number)
        searchController.resignFirstResponder()
        searchController.dismiss(animated: false) {
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }

    @objc func searchTimerTriggered(_ timer: Timer) {
        guard lastSearch != currentSearch else { return }
        filterResults(by: currentSearch)
        collectionNode.reloadSections(IndexSet(integer: 0))
        lastSearch = currentSearch
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text?.lowercased() else { return }
        currentSearch = text
    }

    // MARK: Private

    private let chan: Chan
    private let boardId: String
    private var threads = [Thread]()
    private var searchIndex = [String]()
    private var searchResults = [Thread]()
    private var currentSearch = ""
    private var lastSearch = ""
    private var searchTimer: Timer?
    private let searchQueue = DispatchQueue(label: "com.acedened.TheChan.catalogSearch")
    private var theme: Theme?
    private let collectionNode: ASCollectionNode = {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = spacing
        layout.minimumInteritemSpacing = spacing
        return ASCollectionNode(collectionViewLayout: layout)
    }()

    private let searchController: UISearchController = {
        let searchController = UISearchController(searchResultsController: nil)
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .done
        searchController.hidesNavigationBarDuringPresentation = true
        searchController.definesPresentationContext = true
        return searchController
    }()

    private var isSearching: Bool {
        !(searchController.searchBar.text ?? "").isEmpty
    }

    @objc private func loadCatalog() {
        activityIndicator.startAnimating()
        errorLabel?.isHidden = true
        tryAgainButton?.isHidden = true
        chan.loadCatalog(boardId: boardId) { threads, error in
            self.activityIndicator.stopAnimating()
            if let threads = threads {
                self.threads = threads
                self.parseMarkup()
                self.makeSearchIndex()
                self.collectionNode.reloadData()
            } else if let error = error {
                self.showError(error: error)
            }
        }
    }

    private func parseMarkup() {
        guard let theme = theme else { fatalError("theme is nil") }
        threads.forEach { thread in
            let parser = self.chan.getMarkupParser(
                for: thread.opPost.content,
                theme: theme,
                userInterfaceStyle: traitCollection.userInterfaceStyle
            )
            if let content = parser?.parse() {
                thread.opPost.attributedString = content
            }
        }
    }

    private func makeSearchIndex() {
        searchIndex = threads.map { thread in
            let post = thread.opPost
            let text = post.isSubjectRedundant
                ? post.attributedString.string
                : post.subject + post.attributedString.string
            return text.lowercased()
        }
    }

    private func filterResults(by text: String) {
        searchResults = searchIndex.enumerated()
            .filter { _, fullText in
                fullText.contains(text)
            }.map { index, _ in
                self.threads[index]
            }
    }
}

extension CatalogViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        errorLabel?.textColor = theme.altTextColor
        view.backgroundColor = theme.altBackgroundColor
        collectionNode.backgroundColor = view.backgroundColor
        parseMarkup()
        collectionNode.reloadData()
    }
}
