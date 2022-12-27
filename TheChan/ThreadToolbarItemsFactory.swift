import UIKit

enum ToolbarItem: Int {
    case info, refreshButton, goDownButton, favoriteButton, replyButton
}

@objc class ThreadToolbarItemsFactory: NSObject {
    // MARK: Lifecycle

    init(items: [ToolbarItem]) {
        self.items = items
    }

    // MARK: Internal

    weak var delegate: ThreadToolbarItemsFactoryDelegate?

    func makeBarItems(withStateController stateController: ThreadStateViewController) -> [UIBarButtonItem] {
        var result = [UIBarButtonItem]()
        for (index, item) in items.enumerated() {
            if item == .info {
                let view: UIView = stateController.view
                result.append(UIBarButtonItem(customView: view))
            } else {
                let barItem = createBarItem(for: item)
                barItems[item] = barItem
                result.append(barItem)
            }

            if index != items.count - 1 {
                result.append(UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil))
            }
        }

        return result
    }

    @objc func barItemTapped(_ barItem: UIBarButtonItem) {
        var item = ToolbarItem.info

        for (key, value) in barItems {
            if value == barItem {
                item = key
            }
        }

        delegate?.itemTapped(self, item: item, barItem: barItem)
    }

    func getBarItem(for item: ToolbarItem) -> UIBarButtonItem? {
        barItems[item]
    }

    // MARK: Private

    private static let symbolConfiguration = UIImage.SymbolConfiguration(weight: .semibold)
    private static let icons: [ToolbarItem: UIImage] = [
        .replyButton: .init(systemName: "square.and.pencil", withConfiguration: symbolConfiguration)!,
        .refreshButton: .init(systemName: "arrow.clockwise", withConfiguration: symbolConfiguration)!,
        .goDownButton: .init(systemName: "arrow.down.circle", withConfiguration: symbolConfiguration)!,
        .favoriteButton: .init(systemName: "star", withConfiguration: symbolConfiguration)!,
    ]

    private let items: [ToolbarItem]

    private var barItems: [ToolbarItem: UIBarButtonItem] = [:]

    private func createBarItem(for item: ToolbarItem) -> UIBarButtonItem {
        let icon = ThreadToolbarItemsFactory.icons[item]
        return UIBarButtonItem(image: icon, style: .plain, target: self, action: #selector(barItemTapped(_:)))
    }
}

protocol ThreadToolbarItemsFactoryDelegate: AnyObject {
    func itemTapped(_ sender: ThreadToolbarItemsFactory, item: ToolbarItem, barItem: UIBarButtonItem)
}
