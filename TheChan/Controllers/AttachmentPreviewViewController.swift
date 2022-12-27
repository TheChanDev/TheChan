import Foundation

class AttachmentPreviewViewController: UIViewController {
    // MARK: Internal

    var attachment: Attachment?

    static func calculateFittingSize(bounds: CGSize, image: CGSize) -> CGSize {
        let boundsRatio = bounds.width / bounds.height
        let imageRatio = image.width / image.height
        let scaleFactor = boundsRatio > imageRatio ? bounds.height / image.height : bounds.width / image.width

        return CGSize(width: image.width * scaleFactor, height: image.height * scaleFactor)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let attachment = attachment else { return }
        switch attachment.type {
        case .image:
            setupImage()
        default:
            setupVideo()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        imageView.frame = view.frame
    }

    // MARK: Private

    private let imageView = UIImageView()

    private func setupImage() {
        guard let attachment = attachment else { return }
        imageView.contentMode = .scaleToFill
        imageView.kf.setImage(
            with: attachment.url,
            placeholder: nil,
            options: nil,
            progressBlock: nil,
            completionHandler: nil
        )
        view.addSubview(imageView)
    }

    private func setupVideo() {}
}
