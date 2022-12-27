import Foundation

class HeaderBuilder {
    // MARK: Lifecycle

    init(fontSize: Int, theme: Theme, useMonospacedFont: Bool = false) {
        self.fontSize = CGFloat(fontSize)
        self.theme = theme
        self.useMonospacedFont = useMonospacedFont
    }

    // MARK: Internal

    typealias HeaderItem = (String, [NSAttributedString.Key: Any]?)

    static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    let separator = "•"
    var useMonospacedFont = false
    let fontSize: CGFloat
    let theme: Theme

    func getItems(for markers: PostMarkers) -> [HeaderItem] {
        var items = [HeaderItem]()
        for (marker, color) in markerColors {
            if markers.contains(marker) {
                items.append((marker.stringValue(), [
                    .foregroundColor: color,
                    .font: getFont(ofWeight: .bold),
                ]))
            }
        }

        return items
    }

    func makeAttributedString(
        for items: [HeaderItem],
        customAttributes: [NSAttributedString.Key: Any] = [:]
    ) -> NSAttributedString {
        var offset = 0
        var resultString = ""
        var resultAttributes = [(NSRange, [NSAttributedString.Key: Any]?)]()
        for (string, attributes) in items {
            let length = string.count
            let range = NSRange(location: offset, length: length)

            if offset != 0 {
                resultString += " "
            }

            resultString += string
            offset += length + 1
            resultAttributes.append((range, attributes))
        }

        var attributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: theme.postMetaTextColor,
            .font: getFont(),
        ]

        for (attribute, value) in customAttributes {
            attributes[attribute] = value
        }

        let string = NSMutableAttributedString(string: resultString, attributes: attributes)

        for (range, attributes) in resultAttributes {
            guard let attributes = attributes else { continue }
            string.addAttributes(attributes, range: range)
        }

        return string
    }

    func getFont(ofWeight weight: UIFont.Weight = .regular) -> UIFont {
        useMonospacedFont
            ? UIFont.monospacedSystemFont(ofSize: fontSize, weight: weight)
            : UIFont.systemFont(ofSize: fontSize, weight: weight)
    }

    // MARK: Private

    private lazy var markerColors: [(PostMarkers, UIColor)] = [
        (PostMarkers.userPost, theme.userPostMarkerColor),
        (PostMarkers.op, theme.opMarkerColor),
        (PostMarkers.pinned, theme.pinnedMarkerColor),
        (PostMarkers.banned, theme.bannedMarkerColor),
        (PostMarkers.closed, theme.closedMarkerColor),
    ]
}
