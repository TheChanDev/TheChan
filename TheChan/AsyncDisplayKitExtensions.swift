import AsyncDisplayKit
import Foundation
import Kingfisher

extension ASImageNode {
    func setImage(from url: URL) {
        KingfisherManager.shared.retrieveImage(
            with: url,
            options: [],
            progressBlock: nil
        ) { result in
            self.image = (try? result.get())?.image
        }
    }
}
