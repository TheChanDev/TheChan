import Kingfisher
import UIKit

private let panAmountRequiredToClose: CGFloat = 200
private let panVelocityRequiredToClose: CGFloat = 500

class GalleryCollectionViewCell: UICollectionViewCell, UIScrollViewDelegate, UIGestureRecognizerDelegate {
    // MARK: Internal

    @IBOutlet var activityIndicatorBackgroundView: UIView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    @IBOutlet var errorIcon: UIImageView!
    @IBOutlet var imageView: AnimatedImageView!
    @IBOutlet var scrollView: UIScrollView!
    weak var delegate: GalleryCollectionViewCellDelegate?
    @IBOutlet var fileInfoView: UIView!
    @IBOutlet var fileInfoViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var sizeLabel: UILabel!
    @IBOutlet var resolutionLabel: UILabel!

    @IBOutlet var shareButton: UIButton!
    @IBOutlet var searchButton: UIButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        scrollView.delegate = self

        fileInfoView.alpha = 0

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapRecognizer.numberOfTapsRequired = 2
        scrollView.addGestureRecognizer(doubleTapRecognizer)

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanning(_:)))
        panRecognizer.delegate = self
        contentView.addGestureRecognizer(panRecognizer)

        let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRecognizer.direction = .up
        swipeRecognizer.delegate = self
        contentView.addGestureRecognizer(swipeRecognizer)

        let swipeDownRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleFileInfoSwipe(_:)))
        swipeDownRecognizer.direction = .down
        contentView.addGestureRecognizer(swipeDownRecognizer)

        let singleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        scrollView.addGestureRecognizer(singleTapRecognizer)

        imageView.autoPlayAnimatedImage = true
        imageView.framePreloadCount = 1
    }

    override func updateConstraints() {
        super.updateConstraints()
        fileInfoViewBottomConstraint.constant = -fileInfoView.bounds.height
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        imageView.frame = bounds
        scrollView.contentSize = imageView.frame.size
    }

    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX: CGFloat = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY: CGFloat = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        imageView.center = CGPoint(
            x: scrollView.contentSize.width * 0.5 + offsetX,
            y: scrollView.contentSize.height * 0.5 + offsetY
        )
    }

    func reset() {
        scrollView.zoomScale = 1
    }

    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        if scrollView.zoomScale == 1 {
            let center = sender.location(in: sender.view)
            let rect = zoomRectForScale(scale: scrollView.maximumZoomScale, center: center)
            scrollView.zoom(to: rect, animated: true)
        } else {
            scrollView.setZoomScale(1, animated: true)
        }
    }

    func zoomRectForScale(scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.height = imageView.frame.size.height / scale
        zoomRect.size.width = imageView.frame.size.width / scale
        let newCenter = imageView.convert(center, from: scrollView)
        zoomRect.origin.x = newCenter.x - (zoomRect.size.width / 2.0)
        zoomRect.origin.y = newCenter.y - (zoomRect.size.height / 2.0)
        return zoomRect
    }

    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = panRecognizer.velocity(in: scrollView)
            return scrollView.zoomScale == 1 && abs(velocity.y) > abs(velocity.x) && velocity
                .y > 0 && !isFileInfoVisible
        }

        return scrollView.zoomScale == 1
    }

    @objc func handlePanning(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: contentView)
        imageView.frame.origin.y = translation.y
        let percentage = translation.y / (panAmountRequiredToClose * 1.2)
        backgroundColor = UIColor.black.withAlphaComponent(1 - min(1, percentage))

        if sender.state == .began {
            delegate?.hidePreviews()
        }

        guard sender.state == .ended else { return }
        if translation.y >= panAmountRequiredToClose || sender.velocity(in: contentView)
            .y >= panVelocityRequiredToClose
        {
            delegate?.cellWillClose()
            UIView.animate(withDuration: 0.15, animations: {
                self.backgroundColor = .clear
                self.imageView.frame.origin.y = self.bounds.height
            }, completion: { _ in
                self.delegate?.cellClosed()
            })
        } else {
            delegate?.showPreviews()
            UIView.animate(withDuration: 0.25, animations: {
                self.backgroundColor = .black
                self.imageView.frame.origin.y = 0
            })
        }
    }

    /// Show file info
    @objc func handleSwipe(_ sender: UISwipeGestureRecognizer) {
        guard !isFileInfoVisible else {
            return
        }
        contentView.layoutIfNeeded()
        fileInfoViewBottomConstraint.constant = 0
        UIView.animate(withDuration: 0.25, animations: {
            self.contentView.layoutIfNeeded()
            self.imageView.frame.origin.y = -self.fileInfoView.bounds.height
            self.fileInfoView.alpha = 1
            self.delegate?.hidePreviews()
        }, completion: { _ in
            self.isFileInfoVisible = true
        })
    }

    /// Hide file info
    @objc func handleFileInfoSwipe(_ sender: UISwipeGestureRecognizer) {
        guard isFileInfoVisible else {
            return
        }

        delegate?.showPreviews()
        contentView.layoutIfNeeded()
        fileInfoViewBottomConstraint.constant = -fileInfoView.bounds.height
        UIView.animate(withDuration: 0.25, animations: {
            self.imageView.frame.origin.y = 0
            self.contentView.layoutIfNeeded()
            self.fileInfoView.alpha = 0
        }, completion: { _ in
            self.isFileInfoVisible = false
        })
    }

    @objc func handleTap(_ sender: UITapGestureRecognizer) {
        delegate?.togglePreviews()
    }

    @IBAction func shareButtonTapped(_ sender: UIButton) {
        delegate?.sharingRequested(self)
    }

    @IBAction func searchButtonTapped(_ sender: UIButton) {
        delegate?.searchRequested(self)
    }

    // MARK: Private

    private var isFileInfoVisible = false
}

protocol GalleryCollectionViewCellDelegate: AnyObject {
    func cellClosed()
    func cellWillClose()
    func showPreviews()
    func hidePreviews()
    func togglePreviews()
    func sharingRequested(_ sender: UICollectionViewCell)
    func searchRequested(_ sender: UICollectionViewCell)
}

extension GalleryCollectionViewCellDelegate {
    func cellWillClose() {}
}
