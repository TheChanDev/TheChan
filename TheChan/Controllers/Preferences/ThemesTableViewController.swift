import UIKit

class ThemesTableViewController: UITableViewController {
    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0: return 1
        case 1 where useSystemDarkMode: return darkThemes.count
        case 1: return allThemes.count
        default: return 0
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let theme = theme else { fatalError("theme is nil") }
        switch indexPath.section {
        case 0:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "SwitchTableViewCell",
                for: indexPath
            ) as? SwitchTableViewCell else { fatalError() }

            cell.theme = theme
            cell.selectionStyle = .none
            cell.accessoryType = .none
            cell.theSwitch.isOn = useSystemDarkMode
            cell.theSwitch.addTarget(self, action: #selector(toggleSystemDarkMode), for: .valueChanged)
            return cell
        case 1:
            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "ThemeTableViewCell",
                for: indexPath
            ) as? LabelTableViewCell else { fatalError() }

            cell.theme = theme
            if useSystemDarkMode {
                let theme = darkThemes[indexPath.row]
                cell.accessoryType = UserSettings.shared.darkTheme == theme ? .checkmark : .none
                cell.label.text = String(key: theme.name)
            } else {
                let theme = allThemes[indexPath.row]
                cell.accessoryType = UserSettings.shared.currentTheme == theme ? .checkmark : .none
                cell.label.text = String(key: theme.name)
            }

            return cell
        default:
            fatalError()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 1 else { return }
        if useSystemDarkMode {
            let theme = darkThemes[indexPath.row]
            let oldTheme = UserSettings.shared.darkTheme
            guard theme != oldTheme else { return }
            UserSettings.shared.darkTheme = theme
            ThemeManager.shared.updateTheme()
        } else {
            let theme = allThemes[indexPath.row]
            let oldTheme = UserSettings.shared.currentTheme
            guard theme != oldTheme else { return }
            UserSettings.shared.currentTheme = theme
            ThemeManager.shared.updateTheme()
        }

        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }

    // MARK: Private

    private let allThemes: [Theme] = [
        .light,
        .dark,
        .black,
        .tomorrow,
        .candy,
    ]

    private let darkThemes: [Theme] = [
        .dark,
        .black,
        .tomorrow,
        .candy,
    ]

    private var useSystemDarkMode = UserSettings.shared.useSystemDarkMode
    private var theme: Theme?

    @objc
    private func toggleSystemDarkMode(_ sender: UISwitch) {
        useSystemDarkMode = sender.isOn
        UserSettings.shared.useSystemDarkMode = sender.isOn
        ThemeManager.shared.updateTheme()
        tableView.reloadSections(IndexSet(integer: 1), with: .automatic)
    }
}

extension ThemesTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}
