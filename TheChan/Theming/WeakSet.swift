import Foundation

final class WeakSet<T: AnyObject>: Sequence, ExpressibleByArrayLiteral {
    // MARK: Lifecycle

    public init(_ objects: [T]) {
        for object in objects {
            insert(object)
        }
    }

    public required convenience init(arrayLiteral elements: T...) {
        self.init(elements)
    }

    // MARK: Public

    public var allObjects: [T] {
        objects.allObjects
    }

    public var count: Int {
        objects.count
    }

    public func contains(_ object: T) -> Bool {
        objects.contains(object)
    }

    public func insert(_ object: T) {
        objects.add(object)
    }

    public func remove(_ object: T) {
        objects.remove(object)
    }

    public func makeIterator() -> AnyIterator<T> {
        let iterator = objects.objectEnumerator()
        return AnyIterator {
            iterator.nextObject() as? T
        }
    }

    // MARK: Private

    private var objects = NSHashTable<T>.weakObjects()
}
