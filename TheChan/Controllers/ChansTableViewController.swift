import UIKit

class ChansTableViewController: UITableViewController {
    let manager = ChanManager.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        manager.allChans.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(
            withIdentifier: "ChanTableViewCell",
            for: indexPath
        ) as! ChanTableViewCell
        let chan = manager.allChans[indexPath.row]

        cell.nameLabel.text = chan.id
        cell.iconView.image = chan.icon
        cell.backgroundColor = chan.lightColor
        cell.selectedBackgroundColor = chan.darkColor
        cell.accessoryType = manager.enabledChans.contains { $0.id == chan.id } ? .checkmark : .none
        cell.tintColor = .white

        return cell
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        let chan = manager.allChans[indexPath.row]
        return !manager.isChanEnabled(chan) || manager.enabledChans.count > 1
    }

    override func tableView(
        _ tableView: UITableView,
        editActionsForRowAt indexPath: IndexPath
    ) -> [UITableViewRowAction]? {
        let chan = manager.allChans[indexPath.row]
        if manager.isChanEnabled(chan) {
            let action = UITableViewRowAction(
                style: .destructive,
                title: String(key: "DISABLE"),
                handler: { [unowned self] _, _ in
                    self.manager.disableChan(chan)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            )

            return [action]
        } else {
            let action = UITableViewRowAction(
                style: .default,
                title: String(key: "ENABLE"),
                handler: { [unowned self] _, _ in
                    self.manager.enableChan(chan)
                    self.tableView.reloadRows(at: [indexPath], with: .automatic)
                }
            )

            action.backgroundColor = .orange

            return [action]
        }
    }
}

extension ChansTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
    }
}
