import EasyTipView
import RealmSwift
import UIKit

class BoardsTableViewController: UITableViewController, LoadableWithError, UISearchResultsUpdating, UISearchBarDelegate,
    UICollectionViewDataSource, UICollectionViewDelegate, CustomBoardDialogDelegate, EasyTipViewDelegate
{
    // MARK: Lifecycle

    deinit {
        notificationToken?.invalidate()
    }

    // MARK: Internal

    var groups = [BoardsGroup]()

    var searchResults = [BoardsGroup]()
    @IBOutlet var activityView: UIActivityIndicatorView!
    @IBOutlet var errorLabel: UILabel?
    @IBOutlet var tryAgainButton: UIButton?
    @IBOutlet var addBoardBarItem: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearch()
        setupChansCollection()
        subscribeForThemeChanges()
        clearsSelectionOnViewWillAppear = false // this is done manually
        setupLoadable(
            buttonImage: .init(
                systemName: "arrow.clockwise",
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            )!,
            selector: #selector(onTriedAgain)
        )
        loadBoards()
        setupFavorites()
        setupHeader()
        fetchUserSettings()

        addBoardBarItem.image = .init(
            systemName: "plus",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        navigationController?.tabBarItem.image = .init(
            systemName: "list.bullet",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(chanStateChanged(_:)),
            name: ChanManager.chanStateChangedNotificationName,
            object: nil
        )
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let currentChan = chanManager.currentChan
        guard let selectedChanIndex = chanManager.enabledChans.firstIndex(where: { $0.id == currentChan.id })
        else { return }
        chansCollectionView.selectItem(
            at: IndexPath(item: selectedChanIndex, section: 0),
            animated: false,
            scrollPosition: .left
        )

        if !UserSettings.shared.completedTutorials.contains(.customBoards) {
            showTooltip()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        boardsTip?.dismiss {}
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        let showChans = chanManager.enabledChans.count > 1
        let height = showChans ? 44.0 : 0

        tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: height)
        chansCollectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 44)
    }

    func easyTipViewDidTap(_ tipView: EasyTipView) {}

    func easyTipViewDidDismiss(_ tipView: EasyTipView) {
        var tutorials = UserSettings.shared.completedTutorials
        tutorials.insert(.customBoards)
        UserSettings.shared.completedTutorials = tutorials
    }

    func loadBoards() {
        groups.removeAll()
        tableView.reloadData()
        tableView.startLoading(indicator: activityView)
        chanManager.currentChan.loadBoards { groups, error in
            if let groups = groups {
                self.tableView.stopLoading(indicator: self.activityView)
                self.updateGroups(from: groups)
                self.tableView.reloadData()
            } else if let error = error {
                self.tableView.stopLoading(indicator: self.activityView, hideFooter: false)
                self.showError(error: error)
            }
        }
    }

    func updateGroups(from groups: [BoardsGroup]) {
        self.groups.removeAll()
        adultBoards.removeAll()
        for group in groups {
            var boards = [Board]()
            for board in group.boards {
                if board.isAdult {
                    adultBoards.append(board)
                } else {
                    boards.append(board)
                }
            }

            guard !boards.isEmpty else { continue }
            self.groups.append(BoardsGroup(name: group.name, boards: boards))
        }
    }

    @objc func onTriedAgain() {
        tryAgainButton?.isHidden = true
        errorLabel?.isHidden = true
        loadBoards()
    }

    func fetchUserSettings() {
        guard let token = UserSettings.shared.sessionToken else { return }
        API.shared.fetchCurrentUser(withSessionToken: token) { user, error in
            if let user = user {
                UserSettings.shared.applySettings(from: user)
            } else if error?.isOfKind(.invalidSession) == true {
                UserSettings.shared.sessionToken = nil
            }
        }
    }

    func setupChansCollection() {
        let layout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 72, height: 36)
        layout.minimumLineSpacing = 4

        chansCollectionView = UICollectionView(frame: CGRect(), collectionViewLayout: layout)
        chansCollectionView.register(ChanCollectionViewCell.self, forCellWithReuseIdentifier: "ChanCell")
        chansCollectionView.clipsToBounds = false
        chansCollectionView.dataSource = self
        chansCollectionView.delegate = self
        chansCollectionView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)

        let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        chansCollectionView.addGestureRecognizer(longPressRecognizer)
    }

    func setupHeader() {
        let showChans = chanManager.enabledChans.count > 1
        let height: CGFloat = showChans ? 44 : 0
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: height))
        headerView.backgroundColor = view.backgroundColor
        headerView.clipsToBounds = false

        if showChans {
            headerView.addSubview(chansCollectionView)
        }

        chansCollectionView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: height)

        tableView.tableHeaderView = headerView
    }

    func setupFavorites() {
        uiRealm = RealmInstance.ui
        guard let realm = uiRealm else { return }
        guard let table = tableView else { return }

        notificationToken?.invalidate()
        notificationToken = realm.objects(FavoriteBoard.self).filter("chanId = %@", chanManager.currentChan.id)
            .observe { changes in
                self
                    .favorites = [FavoriteBoard](
                        realm.objects(FavoriteBoard.self)
                            .filter("chanId = %@", self.chanManager.currentChan.id)
                    )
                table.setEditing(false, animated: true)
                if self.isSearching() {
                    return
                }

                self.updateQuickActions()
                switch changes {
                case .initial:
                    table.reloadSections(IndexSet(integer: 0), with: .none)
                case .update(_, let deletions, let insertions, let modifications):
                    table.beginUpdates()
                    table.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    table.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    table.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .automatic)
                    table.endUpdates()
                    table.reloadSections(IndexSet(integer: 0), with: .none)
                case .error(let error):
                    fatalError("\(error)")
                }
            }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let selection = tableView.indexPathForSelectedRow
        if selection != nil {
            tableView.deselectRow(at: selection!, animated: true)
            transitionCoordinator?.notifyWhenInteractionChanges { context in
                if context.isCancelled {
                    self.tableView.selectRow(at: selection, animated: false, scrollPosition: .none)
                }
            }
        }
    }

    @objc func chanStateChanged(_ notification: Notification) {
        guard let chan = notification.object as? Chan else { return }
        guard let info = notification.userInfo else { return }
        guard let isEnabled = info["isEnabled"] as? Bool else { return }

        chansCollectionView.reloadData()
        setupHeader()

        if !isEnabled {
            guard let index = info["index"] as? Int else { return }
            guard chan.id == chanManager.currentChan.id else { return }
            let newIndex =
                index == chanManager.enabledChans.count ? index - 1 : index

            chansCollectionView.selectItem(
                at: IndexPath(item: newIndex, section: 0),
                animated: true,
                scrollPosition: .left
            )
            updateChan()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if isSearching() {
            return searchResults.count
        }

        return groups.count + 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if isSearching() {
            return searchResults[section].name
        }

        if section == 0 {
            return favorites.isEmpty ? nil : String(key: "FAVORITES")
        }

        let name = groups[section - 1].name
        return name.isEmpty ? String(key: "ALL_BOARDS") : name
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if isSearching() {
            return 32
        }

        return section == 0 && favorites.isEmpty ? CGFloat.leastNonzeroMagnitude : 48
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isSearching() {
            return searchResults[section].boards.count
        }

        if section == 0 {
            return favorites.count
        }

        return (section - 1) < groups.count ? groups[section - 1].boards.count : 0
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "BoardTableViewCell",
            for: indexPath
        ) as! BoardTableViewCell
        guard let theme = theme else { fatalError("theme is nil") }
        cell.theme = theme

        if indexPath.section == 0, !isSearching() {
            let board = favorites[indexPath.row]
            cell.idLabel.text = board.boardId
            cell.nameLabel.text = board.name
        } else {
            let board = getBoard(for: indexPath)
            cell.idLabel.text = board.id
            cell.nameLabel.text = board.name
        }

        cell.idLabel.textColor = chanManager.currentChan.tintColor(
            for: theme,
            userInterfaceStyle: traitCollection.userInterfaceStyle
        )

        return cell
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let isSearching = isSearching()

        if indexPath.section == 0, !isSearching {
            return true
        }

        let board = getBoard(for: indexPath)
        return !favorites.contains(where: { $0.boardId == board.id })
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        let board = favorites[indexPath.row]
        try? uiRealm.write {
            self.uiRealm.delete(board)
        }
    }

    override func tableView(
        _ tableView: UITableView,
        editActionsForRowAt indexPath: IndexPath
    ) -> [UITableViewRowAction]? {
        if indexPath.section == 0, !isSearching() {
            return nil
        }

        let addToFavoritesAction = UITableViewRowAction(
            style: .default,
            title: String(key: "FAVORITE")
        ) { _, indexPath in
            let board = self.getBoard(for: indexPath)

            let favoriteBoard = FavoriteBoard.create(from: board, chan: self.chanManager.currentChan)
            try? self.uiRealm.write {
                self.uiRealm.add(favoriteBoard)
            }
        }

        addToFavoritesAction.backgroundColor = UIColor.orange

        return [addToFavoritesAction]
    }

    func updateQuickActions() {
        let boards = uiRealm.objects(FavoriteBoard.self).dropLast(max(0, favorites.count - 3)).map { board in
            UIApplicationShortcutItem(
                type: "io.acedened.thechan.openboard",
                localizedTitle: board.boardId,
                localizedSubtitle: board.name,
                icon: nil,
                userInfo: ["chan": NSString(string: board.chanId), "id": NSString(string: board.boardId)]
            )
        }

        UIApplication.shared.shortcutItems = Array(boards)
    }

    func getBoard(for indexPath: IndexPath) -> Board {
        isSearching()
            ? searchResults[indexPath.section].boards[indexPath.row]
            : groups[indexPath.section - 1].boards[indexPath.row]
    }

    override func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        dismiss(animated: true)
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard let text = searchController.searchBar.text else { return }
        filterBoards(text: text)
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let text = searchBar.text ?? ""
        searchBar.text = ""
        navigateToBoardById(text)
    }

    func navigateToBoardById(_ id: String) {
        if id == "7876711" {
            let alertController = UIAlertController(
                title: nil,
                message: "m5s f6k\ns5e t4t\nd5p u9n",
                preferredStyle: .alert
            )
            alertController.addAction(UIAlertAction(title: "OK", style: .default))
            present(alertController, animated: true)
            return
        }

        let board = Board(id: id, name: "")
        let vc = storyboard?.instantiateViewController(withIdentifier: "ThreadsVC") as! ThreadsTableViewController
        vc.board = board
        vc.chan = chanManager.currentChan
        navigationController?.pushViewController(vc, animated: true)
        searchController.dismiss(animated: true, completion: nil)
        searchController.isActive = false
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenBoard" {
            let threadsTableViewController = segue.destination as! ThreadsTableViewController
            let selectedBoardPath = tableView.indexPathForSelectedRow!
            if selectedBoardPath.section == 0, !isSearching() {
                let board = favorites[selectedBoardPath.row]
                threadsTableViewController.board = Board(id: board.boardId, name: board.name)
            } else {
                let board = getBoard(for: selectedBoardPath)
                threadsTableViewController.board = board
            }

            threadsTableViewController.chan = chanManager.currentChan
        } else if segue.identifier == "AddCustomBoard" {
            boardsTip?.dismiss()
            let nc = segue.destination as! UINavigationController
            let vc = nc.visibleViewController as! AddCustomBoardViewController
            vc.delegate = self
        }
    }

    // MARK: - UICollectionViewDataSource, Delegate

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        chanManager.enabledChans.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ChanCell",
            for: indexPath
        ) as! ChanCollectionViewCell
        let chan = chanManager.enabledChans[indexPath.item]
        cell.setIcon(chan.icon)
        cell.setGradientColors(chan.darkColor, chan.lightColor)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        updateChan()
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        true
    }

    func collectionView(
        _ collectionView: UICollectionView,
        moveItemAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        chanManager.moveChan(atIndex: sourceIndexPath.item, to: destinationIndexPath.row)
    }

    @objc func handleLongPress(_ sender: UILongPressGestureRecognizer) {
        guard let view = sender.view else { return }
        switch sender.state {
        case .began:
            let location = sender.location(in: chansCollectionView)
            guard let selectedIndexPath = chansCollectionView.indexPathForItem(at: location) else { break }
            chansCollectionView.beginInteractiveMovementForItem(at: selectedIndexPath)
        case .changed:
            chansCollectionView.updateInteractiveMovementTargetPosition(sender.location(in: view))
        case .ended:
            chansCollectionView.endInteractiveMovement()
        default:
            chansCollectionView.cancelInteractiveMovement()
        }
    }

    // MARK: - CustomBoardDialogDelegate

    func getNameForBoard(withId id: String) -> String? {
        adultBoards.first(where: { $0.id == id })?.name
            ?? groups.flatMap(\.boards).first(where: { $0.id == id })?.name
    }

    func didCreateCustomBoard(id: String, name: String) {
        if favorites.contains(where: { $0.boardId == id }) {
            return
        }

        let board = FavoriteBoard()
        board.chanId = chanManager.currentChan.id
        board.boardId = id
        board.name = name
        try? uiRealm.write {
            uiRealm?.add(board)
        }
    }

    // MARK: Private

    private var favorites = [FavoriteBoard]()
    private var adultBoards = [Board]()
    private let chanManager = ChanManager.shared
    private var chansCollectionView = UICollectionView(
        frame: CGRect(),
        collectionViewLayout: UICollectionViewFlowLayout()
    )
    private var notificationToken: NotificationToken?
    private var uiRealm: Realm!
    private var boardsTip: EasyTipView?
    private var theme: Theme?

    private var searchController = UISearchController()

    private func showTooltip() {
        var prefs = EasyTipView.Preferences()
        prefs.drawing.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        prefs.drawing.foregroundColor = .white
        prefs.drawing.backgroundColor = chanManager.currentChan.darkColor
        prefs.drawing.arrowPosition = .top

        boardsTip = EasyTipView(text: String(key: "CUSTOM_BOARDS_TIP"), preferences: prefs, delegate: self)
        boardsTip?.show(animated: true, forItem: addBoardBarItem, withinSuperView: nil)
    }

    // MARK: - Search

    private func setupSearch() {
        searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.returnKeyType = .go
        searchController.searchBar.autocapitalizationType = .none
        searchController.searchBar.enablesReturnKeyAutomatically = true
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = String(key: "BOARDS_SEARCH_BAR_PLACEHOLDER")
        searchController.hidesNavigationBarDuringPresentation = false
        navigationItem.searchController = searchController
        tableView.backgroundView = UIView()
    }

    private func filterBoards(text: String) {
        let text = text.uppercased()
        searchResults = groups.map { group in
            let boards = group.boards.filter { board in
                board.id.uppercased().contains(text)
                    || board.name.uppercased().contains(text)
            }

            return BoardsGroup(name: group.name, boards: boards)
        }.filter { !$0.boards.isEmpty }

        tableView.reloadData()
    }

    private func isSearching() -> Bool {
        searchController.isActive && searchController.searchBar.text != ""
    }

    private func updateChan() {
        guard let indexPath = chansCollectionView.indexPathsForSelectedItems?.first else { return }
        let chan = chanManager.enabledChans[indexPath.item]
        chanManager.currentChan = chan
        loadBoards()
        setupFavorites()
    }
}

extension BoardsTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme

        view.backgroundColor = theme.altBackgroundColor
        chansCollectionView.backgroundColor = view.backgroundColor
        tableView.tableHeaderView?.backgroundColor = view.backgroundColor
        tableView.tableFooterView?.backgroundColor = view.backgroundColor
        errorLabel?.textColor = theme.altTextColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
        tabBarController?.tabBar.standardAppearance = .fromTheme(theme)

        guard let nc = navigationController else { return }

        nc.view.backgroundColor = theme.backgroundColor
        nc.navigationBar.standardAppearance = .fromTheme(theme)
    }
}
