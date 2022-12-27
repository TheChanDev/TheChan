import UIKit

class BottomBarSettingsTableViewController: UITableViewController {
    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.isEditing = true
        tableView.bounces = false
        subscribeForThemeChanges()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {
        guard fromIndexPath.section == to.section else { return }

        let source = fromIndexPath.row
        let destination = to.row

        let item = items.remove(at: source)
        items.insert(item, at: destination)
        UserSettings.shared.toolbarItems = items
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell
        .EditingStyle
    {
        .none
    }

    override func tableView(_ tableView: UITableView, shouldIndentWhileEditingRowAt indexPath: IndexPath) -> Bool {
        false
    }

    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        true
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ButtonCell", for: indexPath) as! LabelTableViewCell
        cell.label.text = String(key: localizationStrings[items[indexPath.row]] ?? localizationStrings.first!.value)
        cell.theme = theme
        return cell
    }

    // MARK: Private

    private var theme: Theme?
    private var items = UserSettings.shared.toolbarItems
    private let localizationStrings: [ToolbarItem: String] = [
        .favoriteButton: "TOOLBAR_FAVORITE_BUTTON",
        .refreshButton: "TOOLBAR_REFRESH_BUTTON",
        .goDownButton: "TOOLBAR_GO_DOWN_BUTTON",
        .replyButton: "TOOLBAR_REPLY_BUTTON",
        .info: "TOOLBAR_INDICATOR",
    ]
}

extension BottomBarSettingsTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}
