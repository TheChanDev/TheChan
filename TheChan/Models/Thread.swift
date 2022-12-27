import Foundation

class Thread {
    class HeaderBuilder: TheChan.HeaderBuilder {
        func makeHeader(for thread: Thread, showName: Bool, tintColor: UIColor) -> NSAttributedString {
            let post = thread.opPost
            var items: [HeaderItem] = getItems(for: post.markers)
            if !items.isEmpty {
                items.append((separator, nil))
            }

            if showName && post.trip.isEmpty {
                items.append((post.name.truncate(to: 15), [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                ]))
            }

            if !post.trip.isEmpty {
                items.append((post.trip, [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                    .foregroundColor: theme.postMetaTripColor,
                ]))
            }

            if showName || !post.trip.isEmpty {
                items.append((separator, nil))
            }

            if !post.countryCode.isEmpty {
                items.append((post.countryCode, [
                    .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
                    .foregroundColor: theme.postMetaCountryColor,
                ]))

                items.append((separator, nil))
            }

            items.append(("#\(post.number)", [
                .foregroundColor: tintColor,
            ]))

            let date = HeaderBuilder.dateFormatter.string(from: post.date)
            items.append(("\n\(date)", nil))

            items.append((separator, nil))
            items.append(("\(thread.omittedPosts)P | \(thread.omittedFiles)F", [
                .font: UIFont.systemFont(ofSize: fontSize, weight: .bold),
            ]))

            let attachmentsString = String(localizedFormat: "%d attachments", argument: post.attachments.count)
            items.append(("\n\(attachmentsString)", nil))

            let paragraph = NSMutableParagraphStyle()
            paragraph.lineSpacing = 6

            return makeAttributedString(for: items, customAttributes: [
                .paragraphStyle: paragraph,
            ])
        }
    }

    var opPost = Post()
    var omittedPosts = 0
    var omittedFiles = 0
}
