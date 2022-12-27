import UIKit

class AttachmentCollectionViewCell: UICollectionViewCell {
    @IBOutlet var previewImageView: UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()

        previewImageView.layer.minificationFilter = .trilinear
        previewImageView.layer.cornerCurve = .continuous
    }
}
