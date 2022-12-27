import UIKit

class Post: Hashable {
    class HeaderBuilder: TheChan.HeaderBuilder {
        func makeSingleLineHeader(for post: Post, showName: Bool, position: Int? = nil) -> NSAttributedString {
            var items: [HeaderItem] = []

            if let position = position {
                items.append(("\(position)", nil))
            }

            items.append(("#\(post.number)", [
                .font: getFont(ofWeight: .bold),
            ]))

            items += getItems(for: post.markers)

            if !post.trip.isEmpty {
                items.append((post.trip, [
                    .foregroundColor: theme.postMetaTripColor,
                    .font: getFont(ofWeight: .bold),
                ]))
            }

            if showName {
                items.append((post.name, nil))
            }

            if !post.countryCode.isEmpty {
                items.append((post.countryCode, [
                    .font: getFont(ofWeight: .bold),
                    .foregroundColor: theme.postMetaCountryColor,
                ]))
            }

            if !post.email.isEmpty {
                items.append((post.email, nil))
            }

            items.append((
                HeaderBuilder
                    .dateFormatter
                    .string(from: post.date)
                    .replacingOccurrences(of: ", ", with: " "),
                nil
            ))

            return makeAttributedString(for: items)
        }

        func makeMultiLineHeader(for post: Post, showName: Bool, position: Int? = nil) -> NSAttributedString {
            var items: [HeaderItem] = []

            if let position = position {
                items.append(("\(position)", nil))
            }

            items += getItems(for: post.markers)

            items.append(("#\(post.number)", [
                .font: getFont(ofWeight: .bold),
            ]))

            if !post.trip.isEmpty {
                items.append(("\n\(post.trip)", [
                    .font: getFont(ofWeight: .bold),
                    .foregroundColor: theme.postMetaTripColor,
                ]))
            }

            if showName {
                items.append(("\(post.name.truncate(to: 15))", [
                    .font: getFont(ofWeight: .bold),
                ]))
            }

            if !post.countryCode.isEmpty {
                items.append((post.countryCode, [
                    .font: getFont(ofWeight: .bold),
                    .foregroundColor: theme.postMetaCountryColor,
                ]))
            }

            if !post.email.isEmpty {
                items.append(("\n\(post.email)", nil))
            }

            let date = HeaderBuilder.dateFormatter.string(from: post.date)
            items.append(("\n\(date)", nil))

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 6

            var separatedItems = [HeaderItem]()
            for (index, item) in items.enumerated() {
                separatedItems.append(item)
                if index != items.count - 1, !items[index + 1].0.hasPrefix("\n") {
                    separatedItems.append((separator, nil))
                }
            }

            return makeAttributedString(for: separatedItems, customAttributes: [
                .paragraphStyle: paragraph,
            ])
        }
    }

    var name = ""
    var subject = ""
    var number = 0
    var parent = 0
    var trip = ""
    var date = Date()
    var content = ""
    var email = ""
    var countryCode = ""
    var header = NSAttributedString()
    var attributedString = NSAttributedString()
    var attachments = [Attachment]()
    var markers: PostMarkers = []

    var text: String {
        attributedString.string
    }

    var isSubjectRedundant: Bool {
        let text = text.replacingOccurrences(of: "\n", with: " ")
        return text.hasPrefix(subject.trimmingCharacters(in: .whitespaces))
    }

    static func == (_ lhs: Post, _ rhs: Post) -> Bool {
        lhs.number == rhs.number
    }

    func getTitle() -> String {
        if !subject.isEmpty {
            return subject
        } else if !text.isEmpty {
            let offset = text.count >= 50 ? 50 : text.count
            let subject = text[..<text.index(text.startIndex, offsetBy: offset)]
            return String(subject)
        } else {
            return "\(number)"
        }
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(number)
    }
}
