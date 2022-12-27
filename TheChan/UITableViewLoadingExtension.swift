import UIKit

extension UITableView {
    func startLoading(indicator activityIndicator: UIActivityIndicatorView) {
        activityIndicator.startAnimating()
        let footer = tableFooterView!
        let frame = CGRect(
            x: footer.frame.origin.x,
            y: footer.frame.origin.y,
            width: footer.frame.size.width,
            height: 60
        )
        footer.frame = frame
        tableFooterView?.isHidden = false
    }

    func stopLoading(indicator activityIndicator: UIActivityIndicatorView, hideFooter: Bool = true) {
        activityIndicator.stopAnimating()
        if !hideFooter {
            return
        }

        let footer = tableFooterView!
        let frame = CGRect(
            x: footer.frame.origin.x,
            y: footer.frame.origin.y,
            width: footer.frame.size.width,
            height: 0
        )
        footer.frame = frame
        tableFooterView?.isHidden = true
    }
}
