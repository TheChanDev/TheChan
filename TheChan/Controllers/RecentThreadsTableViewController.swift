import RealmSwift
import UIKit

class RecentThreadsTableViewController: UITableViewController {
    // MARK: Lifecycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        navigationController?.tabBarItem.image = .init(
            systemName: "clock",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        navigationController?.tabBarItem.selectedImage = .init(
            systemName: "clock.fill",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )
    }

    deinit {
        notificationToken?.invalidate()
    }

    // MARK: Internal

    @IBOutlet var eraseButton: UIBarButtonItem!

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
        eraseButton.image = .init(
            systemName: "trash",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        uiRealm = RealmInstance.ui

        setupNotifications()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(currentChanChanged),
            name: ChanManager.currentChanChangedNotificationName,
            object: nil
        )
    }

    @objc func currentChanChanged() {
        setupNotifications()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "RecentThreadTableViewCell",
            for: indexPath
        ) as! RecentThreadTableViewCell
        guard let theme = theme else { fatalError("theme is nil") }
        let item = items[indexPath.row]

        cell.theme = theme
        cell.boardIdLabel.text = item.board
        cell.threadNameLabel.text = item.name
        cell.threadNameLabel.textColor = theme.textColor
        cell.boardIdLabel.textColor = chanManager.currentChan.tintColor(
            for: theme,
            userInterfaceStyle: traitCollection.userInterfaceStyle
        )

        return cell
    }

    @IBAction func eraseButtonTapped(_ sender: UIBarButtonItem) {
        guard let realm = uiRealm else { return }
        let alert = UIAlertController(
            title: String(key: "ERASE_HISTORY_TITLE"),
            message: String(key: "ERASE_HISTORY"),
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: String(key: "NO"), style: .default, handler: nil))
        alert.addAction(UIAlertAction(title: String(key: "YES"), style: .destructive, handler: { _ in
            try? realm.write {
                realm.delete(self.getItems())
            }
        }))

        present(alert, animated: true, completion: nil)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "OpenThread",
           let controller = segue.destination as? ThreadTableViewController,
           let index = tableView.indexPathForSelectedRow
        {
            let item = getItems()[index.row]
            controller.chan = ChanManager.shared.currentChan
            controller.navigationInfo = ThreadNavigationInfo(boardId: item.board, threadNumber: item.number)
        }
    }

    // MARK: Private

    private var uiRealm: Realm!
    private var notificationToken: NotificationToken?
    private var items = [HistoryItem]()
    private let chanManager = ChanManager.shared
    private var theme: Theme?

    private func getItems() -> Results<HistoryItem> {
        uiRealm.objects(HistoryItem.self).filter("chanId = %@", chanManager.currentChan.id)
            .sorted(byKeyPath: "lastVisit", ascending: false)
    }

    private func setupNotifications() {
        guard let tableView = tableView else { return }

        notificationToken?.invalidate()
        notificationToken = getItems().observe { changes in
            self.items = Array(self.getItems())
            switch changes {
            case .initial:
                tableView.reloadData()
            case .update(_, let deletions, let insertions, let modifications):
                tableView.beginUpdates()
                tableView.insertRows(at: insertions.map { IndexPath(row: $0, section: 0) }, with: .none)
                tableView.deleteRows(at: deletions.map { IndexPath(row: $0, section: 0) }, with: .none)
                tableView.reloadRows(at: modifications.map { IndexPath(row: $0, section: 0) }, with: .none)
                tableView.endUpdates()
            case .error(let error):
                fatalError("\(error)")
            }
        }
    }
}

extension RecentThreadsTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        navigationController?.navigationBar.standardAppearance = .fromTheme(theme)
        navigationController?.view.backgroundColor = theme.backgroundColor
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}
