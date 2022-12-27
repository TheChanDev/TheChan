import UIKit

class MediaPreferencesViewController: UITableViewController {
    // MARK: Internal

    @IBOutlet var enableMediaSwitch: UISwitch!
    @IBOutlet var enableMiniGallerySwitch: UISwitch!
    @IBOutlet var showVideosInGallerySwitch: UISwitch!
    @IBOutlet var scrollThreadWithGallerySwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
        updateSwitches(addTarget: true)

        enableMediaSwitch.isOn = settings.isMediaEnabled
    }

    @IBAction func enableMediaSwitchValueChanged(_ sender: UISwitch) {
        if settings.hasUserEnabledMediaBefore || !sender.isOn {
            settings.isMediaEnabled = sender.isOn
            updateSwitches()
            return
        }

        let alert = UIAlertController(
            title: String(key: "MEDIA_ALERT_TITLE"),
            message: String(key: "MEDIA_ALERT"),
            preferredStyle: .alert
        )

        let cancelAction = UIAlertAction(
            title: String(key: "CANCEL"),
            style: .cancel,
            handler: { _ in
                sender.setOn(false, animated: true)
                self.updateSwitches()
            }
        )

        let enableAction = UIAlertAction(
            title: String(key: "ENABLE_MEDIA"),
            style: .destructive,
            handler: { [unowned self] _ in
                self.settings.isMediaEnabled = true
                self.settings.hasUserEnabledMediaBefore = true
                self.updateSwitches()
            }
        )

        alert.addAction(cancelAction)
        alert.addAction(enableAction)
        present(alert, animated: true, completion: nil)
    }

    @objc func switchValueChanged(_ sender: UISwitch) {
        switch sender {
        case enableMiniGallerySwitch:
            settings.isMiniGalleryEnabled = sender.isOn
        case showVideosInGallerySwitch:
            settings.showVideosInGallery = sender.isOn
        case scrollThreadWithGallerySwitch:
            settings.scrollThreadWithGallery = sender.isOn
        default:
            break
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let theme = theme,
              let cell = super.tableView(tableView, cellForRowAt: indexPath) as? LabelTableViewCell
        else { fatalError() }

        cell.theme = theme
        return cell
    }

    // MARK: Private

    private let settings = UserSettings.shared
    private var theme: Theme?

    private func updateSwitches(addTarget: Bool = false) {
        let switches = [
            enableMediaSwitch,
            enableMiniGallerySwitch,
            showVideosInGallerySwitch,
            scrollThreadWithGallerySwitch,
        ]
        for switchItem in switches {
            guard let item = switchItem else { continue }

            guard item != enableMediaSwitch else { continue }

            item.isEnabled = settings.isMediaEnabled
            if addTarget {
                item.addTarget(self, action: #selector(switchValueChanged(_:)), for: .valueChanged)
            }
        }

        enableMiniGallerySwitch.setOn(settings.isMiniGalleryEnabled && settings.isMediaEnabled, animated: true)
        showVideosInGallerySwitch.setOn(settings.showVideosInGallery && settings.isMediaEnabled, animated: true)
        scrollThreadWithGallerySwitch.setOn(settings.scrollThreadWithGallery && settings.isMediaEnabled, animated: true)
    }
}

extension MediaPreferencesViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        [enableMediaSwitch, enableMiniGallerySwitch, showVideosInGallerySwitch, scrollThreadWithGallerySwitch].forEach {
            $0?.tintColor = theme.separatorColor
        }

        tableView.separatorColor = theme.separatorColor
        view.backgroundColor = theme.altBackgroundColor
        tableView.reloadData()
    }
}
