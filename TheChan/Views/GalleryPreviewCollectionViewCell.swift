import UIKit

class GalleryPreviewCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var typeInfoView: UIView!
    @IBOutlet var gifTypeInfoView: UIView!
    @IBOutlet var videoTypeInfoView: UIView!

    override var isSelected: Bool {
        didSet {
            layer.borderColor = isSelected ? tintColor.cgColor : UIColor.clear.cgColor
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        layer.borderWidth = 2
        layer.borderColor = UIColor.clear.cgColor
    }
}
