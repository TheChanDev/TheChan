import Foundation

extension Collection {
    /// Returns the element at the specified index iff it is within bounds, otherwise nil.
    subscript(safe index: Index) -> Iterator.Element? {
        indices.contains(index) ? self[index] : nil
    }
}
