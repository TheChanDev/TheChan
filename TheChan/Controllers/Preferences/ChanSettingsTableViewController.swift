import UIKit

class ChanSettingsTableViewController: UITableViewController {
    // MARK: Public

    public var chan = ChanManager.shared.currentChan

    // MARK: Internal

    // MARK: - Outlets

    @IBOutlet var postingWithoutCaptchaSwitch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()

        title = chan.id

        chanSettings = settings.getChanSettings(id: chan.id)
        postingWithoutCaptchaSwitch.isOn = chan.capabilities.contains(.captchaBypass) && chanSettings
            .isPostingWithoutCaptchaEnabled
        postingWithoutCaptchaSwitch.isEnabled = chan.capabilities.contains(.captchaBypass)
    }

    @IBAction func postingWithoutCaptchaSettingChanged(_ sender: UISwitch) {
        chanSettings.isPostingWithoutCaptchaEnabled = sender.isOn
        chan.settings = chanSettings
        settings.updateChanSettings(id: chan.id, with: chanSettings)
    }

    // MARK: Private

    private let settings = UserSettings.shared
    private var chanSettings = ChanSettings()
}

extension ChanSettingsTableViewController: Themable {
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
        postingWithoutCaptchaSwitch.tintColor = theme.separatorColor
    }
}
