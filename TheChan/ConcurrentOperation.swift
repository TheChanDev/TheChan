import Foundation

class ConcurrentOperation: Operation {
    // MARK: Internal

    override var isAsynchronous: Bool {
        true
    }

    override var isExecuting: Bool {
        get {
            _executing
        }
        set {
            if _executing != newValue {
                willChangeValue(forKey: "isExecuting")
                _executing = newValue
                didChangeValue(forKey: "isExecuting")
            }
        }
    }

    override var isFinished: Bool {
        get {
            _finished
        }
        set {
            if _finished != newValue {
                willChangeValue(forKey: "isFinished")
                _finished = newValue
                didChangeValue(forKey: "isFinished")
            }
        }
    }

    /// Complete the operation
    ///
    /// This will result in the appropriate KVN of isFinished and isExecuting

    func completeOperation() {
        isExecuting = false
        isFinished = true
    }

    override func start() {
        if isCancelled {
            isFinished = true
            return
        }

        isExecuting = true

        main()
    }

    // MARK: Private

    private var _executing: Bool = false
    private var _finished: Bool = false
}
