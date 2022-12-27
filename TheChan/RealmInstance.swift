import RealmSwift

class RealmInstance {
    // MARK: Internal

    private(set) static var ui: Realm!

    static func initialize() -> Bool {
        do {
            configure()
            let realm = try Realm()
            ui = realm
        } catch {
            return false
        }

        return true
    }

    // MARK: Private

    private static func configure() {
        let config = Realm.Configuration(
            schemaVersion: 6,
            migrationBlock: { migration, version in

                if version < 2 {
                    migration.enumerateObjects(ofType: FavoriteThread.className()) { _, new in
                        new!["chanId"] = "2ch"
                    }
                }

                if version < 3 {
                    migration.enumerateObjects(ofType: HistoryItem.className()) { _, new in
                        new!["chanId"] = "2ch"
                    }
                }

                if version < 5 {
                    migration.enumerateObjects(ofType: HistoryItem.className()) { old, new in
                        new!["position"] = old!["number"]
                    }
                }

                if version < 6 {
                    migration.enumerateObjects(ofType: FavoriteThread.className()) { _, newObject in
                        newObject!["lastReadPost"] = -1
                    }
                }
            }
        )

        Realm.Configuration.defaultConfiguration = config
    }
}
