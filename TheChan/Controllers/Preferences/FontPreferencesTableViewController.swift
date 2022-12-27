import UIKit

class FontPreferencesTableViewController: UITableViewController {
    // MARK: Internal

    let minimumSize = 12
    let maximumSize = 25
    let settings = UserSettings.shared

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 1 ? maximumSize - minimumSize + 1 : 1
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        section == 0 ? nil : String(key: "FONT_SIZE")
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let theme = theme else { fatalError("theme is nil") }
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "UseMonospacedFontCell",
                for: indexPath
            ) as! SwitchTableViewCell
            cell.theme = theme
            cell.selectionStyle = .none
            let s = cell.theSwitch
            s?.isOn = settings.useMonospacedFontInPostInfo
            s?.addTarget(self, action: #selector(useMonospacedFontSwitchValueChanged(_:)), for: .valueChanged)

            return cell
        default:
            let cell = tableView.dequeueReusableCell(
                withIdentifier: "FontSizeCell",
                for: indexPath
            ) as! LabelTableViewCell
            cell.theme = theme
            let size = minimumSize + indexPath.row

            cell.label.text = "\(size)"

            let currentSize = settings.fontSize
            if size == currentSize {
                cell.accessoryType = .checkmark
            } else {
                cell.accessoryType = .none
            }

            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }

        let previousSize = settings.fontSize
        let size = minimumSize + indexPath.row
        settings.fontSize = size
        tableView.beginUpdates()
        tableView.reloadRows(at: [indexPath, IndexPath(row: previousSize - minimumSize, section: 1)], with: .none)
        tableView.endUpdates()
        let _ = navigationController?.popViewController(animated: true)
    }

    @objc func useMonospacedFontSwitchValueChanged(_ sender: UISwitch) {
        settings.useMonospacedFontInPostInfo = sender.isOn
    }

    // MARK: Private

    private var theme: Theme?
}

extension FontPreferencesTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}
