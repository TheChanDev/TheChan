import Foundation

extension DispatchQueue {
    func async(_ execute: @escaping () -> Void, completion: @escaping () -> Void) {
        async {
            execute()

            DispatchQueue.main.sync {
                completion()
            }
        }
    }
}
