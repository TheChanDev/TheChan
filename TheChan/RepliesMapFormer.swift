import Foundation

class RepliesMapFormer {
    // MARK: Internal

    var affectedPosts = [Int]()

    func createMapFrom(newPosts: [Post], existingMap: [Int: [Post]]) -> [Int: [Post]] {
        affectedPosts.removeAll()
        let quotedPosts = findQuotedPostsIn(posts: newPosts) // [PostNumber: Replies]
        var repliesMap = existingMap
        for (number, replies) in quotedPosts {
            if repliesMap[number] != nil { // If we have some replies to this post
                repliesMap[number]! += replies // Just add new replies
            } else {
                repliesMap[number] = replies
            }

            affectedPosts.append(number)
        }

        return repliesMap
    }

    // MARK: Private

    private func findQuotedPostsIn(posts: [Post]) -> [Int: [Post]] {
        guard let regex = try? NSRegularExpression(pattern: ">>(\\d+)", options: .caseInsensitive) else { return [:] }
        var map = [Int: [Post]]()
        for post in posts {
            let text = post.attributedString.string as NSString
            let matches = regex.matches(
                in: post.attributedString.string,
                options: [],
                range: NSMakeRange(0, text.length)
            )
            let uniqueMatches = Set(matches.map { Int(text.substring(with: $0.range(at: 1))) ?? 0 })
            for number in uniqueMatches {
                if map[number] != nil {
                    map[number]!.append(post)
                } else {
                    map[number] = [post]
                }
            }
        }

        return map
    }
}
