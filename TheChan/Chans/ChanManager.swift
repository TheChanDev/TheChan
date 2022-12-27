import Foundation

class ChanManager {
    // MARK: Lifecycle

    private init() {
        let ids = UserSettings.shared.enabledChansIds

        for id in ids {
            guard let chan = allChans.first(where: { $0.id == id }) else { continue }
            _enabledChans.append(chan)
        }

        currentChan = _enabledChans[0]
    }

    // MARK: Public

    public static let shared = ChanManager()

    public let allChans: [Chan] = [Dvach(), FourChan()]

    public var currentChan: Chan {
        didSet {
            currentChan.settings = UserSettings.shared.getChanSettings(id: currentChan.id)
            NotificationCenter.default.post(name: ChanManager.currentChanChangedNotificationName, object: currentChan)
        }
    }

    public var enabledChans: [Chan] {
        _enabledChans
    }

    public func moveChan(atIndex source: Int, to destination: Int) {
        let chan = _enabledChans.remove(at: source)
        _enabledChans.insert(chan, at: destination)
        updateEnabledChans()
    }

    public func isChanEnabled(_ chan: Chan) -> Bool {
        enabledChans.contains(where: { $0.id == chan.id })
    }

    public func enableChan(_ chan: Chan) {
        guard !isChanEnabled(chan) else { return }
        _enabledChans.append(chan)
        updateEnabledChans()
        NotificationCenter.default.post(
            name: ChanManager.chanStateChangedNotificationName,
            object: chan,
            userInfo: [
                "isEnabled": true,
            ]
        )
    }

    public func disableChan(_ chan: Chan) {
        guard let index = enabledChans.firstIndex(where: { $0.id == chan.id }) else { return }
        _enabledChans.remove(at: index)
        updateEnabledChans()
        NotificationCenter.default.post(
            name: ChanManager.chanStateChangedNotificationName,
            object: chan,
            userInfo: [
                "isEnabled": false,
                "index": index,
            ]
        )
    }

    // MARK: Internal

    static let currentChanChangedNotificationName = Notification.Name("THECHAN_CURRENT_CHAN_CHANGED")
    static let chanStateChangedNotificationName = Notification.Name("THECHAN_CHAN_STATE_CHANGED")

    // MARK: Private

    private var _enabledChans = [Chan]()

    private func updateEnabledChans() {
        UserSettings.shared.enabledChansIds = enabledChans.map(\.id)
    }
}
