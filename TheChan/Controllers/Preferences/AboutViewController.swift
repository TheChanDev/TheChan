import UIKit

class AboutViewController: UIViewController {
    // MARK: Internal

    @IBOutlet var versionLabel: UILabel!
    @IBOutlet var logoView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        logoView.image = #imageLiteral(resourceName: "Logo").withRenderingMode(.alwaysTemplate)
        subscribeForThemeChanges()
        versionLabel.text = getVersionString()
    }

    // MARK: Private

    private func getVersionString() -> String {
        let versionNumber: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String

        return "v\(versionNumber) (Legacy Edition)"
    }

    private func openURL(_ urlString: String) {
        let url = URL(string: urlString)!
        if #available(iOS 10.0, *) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            UIApplication.shared.openURL(url)
        }
    }
}

extension AboutViewController: Themable {
    func applyTheme(_ theme: Theme) {
        logoView.tintColor = theme.textColor
        versionLabel.textColor = theme.altTextColor
        view.backgroundColor = theme.backgroundColor
    }
}
