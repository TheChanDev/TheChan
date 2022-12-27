import IQKeyboardManagerSwift
import Kingfisher
import UIKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let keyboardManager = IQKeyboardManager.shared
        keyboardManager.enable = true
        keyboardManager.disabledToolbarClasses = [AddCustomBoardViewController.self]

        let _ = RealmInstance.initialize()
        debugPrint("Realm database path: \(RealmInstance.ui.configuration.fileURL?.absoluteString ?? "unknown")")

        let sessionConfiguration = KingfisherManager.shared.downloader.sessionConfiguration
        sessionConfiguration.httpCookieStorage = HTTPCookieStorage.shared
        sessionConfiguration.httpShouldSetCookies = true
        KingfisherManager.shared.downloader.sessionConfiguration = sessionConfiguration

        let lastCacheCleanTime = UserSettings.shared.lastCacheCleanTime
        if Date().timeIntervalSince(lastCacheCleanTime) > 60 * 60 * 24 * 30 { // 30 days
            DispatchQueue.global().async {
                SimpleCacher().clearCache(for: "video")
            }

            KingfisherManager.shared.cache.clearDiskCache()
            UserSettings.shared.lastCacheCleanTime = Date()
        }

        return true
    }

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(
        _ application: UIApplication,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        guard let rootTabBar = window?.rootViewController as? UITabBarController else {
            completionHandler(false)
            return
        }

        switch shortcutItem.type {
        case "io.acedened.thechan.openfavorites":
            guard let navController = rootTabBar.viewControllers?[1] as? UINavigationController else { break }
            navController.popToRootViewController(animated: false)
            rootTabBar.selectedIndex = 1
            completionHandler(true)
        case "io.acedened.thechan.openboard":
            guard let navController = rootTabBar.viewControllers?[0] as? UINavigationController else { break }
            guard let boardController = navController.storyboard?
                .instantiateViewController(withIdentifier: "ThreadsVC") as? ThreadsTableViewController else { break }
            navController.popToRootViewController(animated: false)
            boardController.chan = ChanManager.shared.currentChan
            boardController.board = Board(id: shortcutItem.userInfo!["id"] as! String, name: "")
            rootTabBar.selectedIndex = 0
            navController.pushViewController(boardController, animated: true)
            completionHandler(true)
        default:
            break
        }

        completionHandler(false)
    }

    func closeApplication() {
        exit(0)
    }
}
