import UIKit

public extension UIView {
    var safeInsets: UIEdgeInsets {
        if #available(iOS 11, *) {
            return safeAreaInsets
        }

        return .zero
    }

    func pinningEdges(to container: UIView) -> [NSLayoutConstraint] {
        [
            leadingAnchor.constraint(equalTo: container.leadingAnchor),
            trailingAnchor.constraint(equalTo: container.trailingAnchor),
            topAnchor.constraint(equalTo: container.topAnchor),
            bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ]
    }

    func pinningEdges(to guide: UILayoutGuide) -> [NSLayoutConstraint] {
        [
            leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            trailingAnchor.constraint(equalTo: guide.trailingAnchor),
            topAnchor.constraint(equalTo: guide.topAnchor),
            bottomAnchor.constraint(equalTo: guide.bottomAnchor),
        ]
    }
}
