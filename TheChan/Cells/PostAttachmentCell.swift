import UIKit

class PostAttachmentCell: UICollectionViewCell {
    @IBOutlet var previewImage: UIImageView!
    @IBOutlet var videoIcon: UIImageView!

    override func awakeFromNib() {
        layer.cornerRadius = 10
    }
}
