import Foundation

typealias NodeFlags = [NodeFlag]

enum NodeFlag {
    case innerLink(link: Link)
}

precedencegroup ItemComparisonPrecedence {
    associativity: none
    higherThan: LogicalConjunctionPrecedence
}

infix operator <==: ItemComparisonPrecedence

func <== (lhs: NodeFlag, rhs: NodeFlag) -> Bool {
    switch (lhs, rhs) {
    case (.innerLink(_), .innerLink(_)): return true
        // default: return false
    }
}

extension Collection where Iterator.Element == NodeFlag {
    func firstMatch(with item: Iterator.Element) -> Iterator.Element? {
        first { $0 <== item }
    }
}

extension Collection where Iterator.Element == NodeFlag {
    var innerLink: Link? {
        if let item = firstMatch(with: .innerLink(link: Link())),
           case .innerLink(let link) = item
        {
            return link
        }

        return nil
    }
}
