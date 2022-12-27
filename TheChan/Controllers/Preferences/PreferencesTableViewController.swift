import UIKit

class PreferencesTableViewController: UITableViewController {
    // MARK: Lifecycle

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        navigationController?.tabBarItem.image = .init(
            systemName: "gearshape.2",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )

        navigationController?.tabBarItem.selectedImage = .init(
            systemName: "gearshape.2.fill",
            withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
        )
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)

        guard let theme = theme else { return cell }

        cell.backgroundColor = theme.backgroundColor
        cell.selectedBackgroundColor = theme.altBackgroundColor
        if let label = cell.contentView.subviews.first(where: { $0 is UILabel }) as? UILabel {
            label.textColor = theme.textColor
        }

        return cell
    }

    // MARK: Private

    private var theme: Theme?
}

extension PreferencesTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        navigationController?.navigationBar.standardAppearance = .fromTheme(theme)
        navigationController?.view.backgroundColor = theme.backgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}
