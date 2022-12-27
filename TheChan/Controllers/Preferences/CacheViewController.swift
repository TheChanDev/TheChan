import Kingfisher
import UIKit

class CacheViewController: UITableViewController {
    // MARK: Internal

    @IBOutlet var imagesSizeLabel: UILabel!
    @IBOutlet var videosSizeLabel: UILabel!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    override func viewDidLoad() {
        subscribeForThemeChanges()
        super.viewDidLoad()
        calculateSizes()
    }

    func calculateSizes() {
        KingfisherManager.shared.cache.calculateDiskStorageSize { result in
            switch result {
            case .success(let size):
                self.imagesSizeLabel.text = self.fileSizeDisplay(fromBytes: UInt64(size))
            case .failure:
                self.imagesSizeLabel.text = String(key: "ERROR")
            }
        }

        var videosSize = ""
        DispatchQueue.global().async({
            videosSize = self.fileSizeDisplay(fromBytes: self.cacher.getSizeOfDirectory(for: "video"))
        }) {
            self.videosSizeLabel.text = videosSize
        }
    }

    @IBAction func clearCacheButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        activityIndicator.startAnimating()
        KingfisherManager.shared.cache.clearDiskCache {
            DispatchQueue.global().async({
                self.cacher.clearCache(for: "video")
            }) {
                self.imagesSizeLabel.text = "..."
                self.videosSizeLabel.text = "..."
                self.calculateSizes()
                self.activityIndicator.stopAnimating()
                UserSettings.shared.lastCacheCleanTime = Date()
            }
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        guard let theme = theme else { return cell }

        cell.backgroundColor = theme.backgroundColor

        let labels = cell.contentView.subviews.filter { $0 is UILabel }.map { $0 as! UILabel }
        guard labels.count == 2 else { return cell }

        labels[0].textColor = theme.altTextColor
        labels[1].textColor = theme.textColor

        return cell
    }

    // MARK: Private

    private let cacher = SimpleCacher()
    private var theme: Theme?

    private func fileSizeDisplay(fromBytes: UInt64) -> String {
        let display = ["B", "KB", "MB", "GB", "TB", "PB"]
        var value = Double(fromBytes)
        var type = 0
        while value > 1024 {
            value /= 1024
            type = type + 1
        }

        return "\(String(format: "%.1f", value)) \(display[type])"
    }
}

extension CacheViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.altBackgroundColor
        tableView.separatorColor = theme.separatorColor
        tableView.reloadData()
    }
}
