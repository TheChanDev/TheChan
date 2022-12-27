import Kingfisher
import UIKit

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,
    UICollectionViewDelegateFlowLayout, GalleryCollectionViewCellDelegate, PreviewsCollectionViewDelegate
{
    // MARK: Internal

    @IBOutlet var galleryCollectionView: UICollectionView!
    @IBOutlet var previewsCollectionView: UICollectionView!

    var attachments = [Attachment]()
    var activeItem = 0
    weak var delegate: GalleryDelegate?

    override var prefersStatusBarHidden: Bool {
        !showStatusBar
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        .slide
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        galleryCollectionView.dataSource = self
        galleryCollectionView.delegate = self
        galleryCollectionView.allowsSelection = false
        if #available(iOS 11.0, *) {
            galleryCollectionView.contentInsetAdjustmentBehavior = .never
        }
        galleryCollectionView.register(
            UINib(nibName: "GalleryCollectionViewCell", bundle: .main),
            forCellWithReuseIdentifier: "GalleryCell"
        )

        galleryCollectionView.register(
            GalleryVideoCollectionViewCell.self,
            forCellWithReuseIdentifier: GalleryVideoCollectionViewCell.identifier
        )

        let isMiniGalleryEnabled = UserSettings.shared.isMiniGalleryEnabled
        if isMiniGalleryEnabled {
            previewsDataSource.delegate = self
            previewsCollectionView.dataSource = previewsDataSource
            previewsCollectionView.delegate = previewsDataSource
            previewsCollectionView.register(
                UINib(nibName: "GalleryPreviewCollectionViewCell", bundle: .main),
                forCellWithReuseIdentifier: "PreviewCell"
            )
        }

        previewsCollectionView.isHidden = true

        let indexPath = IndexPath(item: activeItem, section: 0)
        galleryCollectionView.scrollToItem(
            at: indexPath,
            at: .left,
            animated: false
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        showStatusBar = false
        UIView.animate(withDuration: 0.25, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }

    override func viewDidAppear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = true
        let indexPath = IndexPath(item: activeItem, section: 0)

        if UserSettings.shared.isMiniGalleryEnabled {
            previewsCollectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }

    override func viewDidDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        coordinator.animate(alongsideTransition: { [weak self] _ in
            guard let self = self else { return }
            self.galleryCollectionView.scrollToItem(
                at: IndexPath(item: self.activeItem, section: 0),
                at: .left,
                animated: false
            )
        })

        galleryCollectionView.scrollToItem(at: IndexPath(item: activeItem, section: 0), at: .left, animated: false)
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()

        guard let layout = galleryCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else { return }

        layout.itemSize = view.bounds.size

        layout.invalidateLayout()
        galleryCollectionView.scrollToItem(at: IndexPath(item: activeItem, section: 0), at: .left, animated: false)
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        attachments.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let attachment = attachments[indexPath.row]
        switch attachment.type {
        case .image:
            let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: "GalleryCell",
                for: indexPath
            ) as! GalleryCollectionViewCell

            cell.delegate = self
            cell.nameLabel.text = attachment.name
            cell.resolutionLabel.text = "\(attachment.size.0)x\(attachment.size.1)"
            cell.sizeLabel.text = "\(attachment.fileSize)KB"
            cell.errorIcon.isHidden = true
            cell.activityIndicatorBackgroundView.isHidden = false
            cell.activityIndicator.startAnimating()

            cell.imageView.kf.setImage(
                with: attachment.url,
                options: [.processor(JFIFFixImageProcessor())],
                completionHandler: { result in
                    cell.activityIndicator.stopAnimating()
                    switch result {
                    case .failure:
                        cell.errorIcon.isHidden = false
                    case .success:
                        cell.activityIndicatorBackgroundView.isHidden = true
                    }
                }
            )
            cell.searchButton.isEnabled = true
            return cell
        case .video:
            guard
                let cell = collectionView.dequeueReusableCell(
                    withReuseIdentifier: GalleryVideoCollectionViewCell.identifier,
                    for: indexPath
                ) as? GalleryVideoCollectionViewCell
            else { fatalError() }

            cell.configure(with: attachment.url, delegate: self)
            return cell
//            if attachment.url.pathExtension == "webm" {
//                cell.imageView.image = nil
//                cell.activityIndicator.stopAnimating()
//                cell.activityIndicatorBackgroundView.isHidden = true
//                cell.playerView.sourceURL = attachment.url
//            } else {
//                cell.activityIndicatorBackgroundView.isHidden = false
//                cell.activityIndicator.startAnimating()
//                let cacher = SimpleCacher()
//                cacher.getFile(from: attachment.url, category: "video", completionHandler: { url in
//                    cell.activityIndicator.stopAnimating()
//                    if let url = url {
//                        cell.activityIndicatorBackgroundView.isHidden = true
//                        cell.playerView.sourceURL = url
//                        if collectionView.indexPathsForVisibleItems.contains(indexPath) {
//                            cell.isActive = true
//                            cell.playerView.play()
//                        }
//
//                    } else {
//                        cell.errorIcon.isHidden = false
//                    }
//                })
//            }
//
//            cell.playerView.isHidden = false
//            cell.searchButton.isEnabled = false
        }
    }

    func collectionView(
        _ collectionView: UICollectionView,
        didEndDisplaying cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard let cell = cell as? GalleryVideoCollectionViewCell else { return }
        cell.pausePlaypack()
    }

    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        guard
            indexPath.item == activeItem,
            let cell = cell as? GalleryVideoCollectionViewCell
        else { return }

        cell.startPlayback()
    }

    func cellWillClose() {
        showStatusBar = true
        UIView.animate(withDuration: 0.25, animations: {
            self.setNeedsStatusBarAppearanceUpdate()
        })
    }

    func cellClosed() {
        dismiss(animated: false, completion: {
            self.delegate?.galleryDidClose(self)
        })
    }

    func hidePreviews() {
        guard UserSettings.shared.isMiniGalleryEnabled else { return }
        UIView.transition(with: previewsCollectionView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.previewsCollectionView.isHidden = true
        }, completion: nil)
    }

    func showPreviews() {
        guard UserSettings.shared.isMiniGalleryEnabled else { return }
        UIView.transition(with: previewsCollectionView, duration: 0.25, options: .transitionCrossDissolve, animations: {
            self.previewsCollectionView.isHidden = false
        }, completion: nil)
    }

    func togglePreviews() {
        guard UserSettings.shared.isMiniGalleryEnabled else { return }
        if previewsCollectionView.isHidden {
            showPreviews()
        } else {
            hidePreviews()
        }
    }

    func numberOfAttachments() -> Int {
        attachments.count
    }

    func getAttachment(for indexPath: IndexPath) -> Attachment? {
        attachments[indexPath.item]
    }

    func didSelectAttachment(at indexPath: IndexPath) {
        activeItem = indexPath.item
        galleryCollectionView.scrollToItem(at: indexPath, at: .left, animated: true)
    }

    func sharingRequested(_ sender: UICollectionViewCell) {
        guard let sender = sender as? GalleryCollectionViewCell,
              let indexPath = galleryCollectionView.indexPath(for: sender)
        else { return }
        let attachment = attachments[indexPath.item]
        var items: [Any] = []
        if attachment.type == .image, let image = sender.imageView.image {
            items.append(image)
        } else {
            items.append(attachment.url)
        }

        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.popoverPresentationController?.sourceView = sender
        vc.popoverPresentationController?.sourceRect = sender.convert(
            sender.shareButton.bounds,
            from: sender.shareButton
        )
        present(vc, animated: true, completion: nil)
    }

    func searchRequested(_ sender: UICollectionViewCell) {
        guard let indexPath = galleryCollectionView.indexPath(for: sender) else { return }
        let attachment = attachments[indexPath.item]
        guard attachment.type == .image else { return }

        guard let url = URL(string: "https://images.google.com/searchbyimage?image_url=\(attachment.url)")
        else { return }
        UIApplication.shared.open(url)
    }

    func scrollViewWillEndDragging(
        _ scrollView: UIScrollView,
        withVelocity velocity: CGPoint,
        targetContentOffset: UnsafeMutablePointer<CGPoint>
    ) {
        let offset = targetContentOffset.pointee
        let pageWidth = scrollView.bounds.width
        let page = Int(floor((offset.x - pageWidth / 2) / pageWidth) + 1)
        if page != activeItem {
            activeItem = page
            (galleryCollectionView.cellForItem(
                at: IndexPath(item: page, section: 0)
            ) as? GalleryVideoCollectionViewCell)?.startPlayback()

            if UserSettings.shared.isMiniGalleryEnabled,
               activeItem < previewsCollectionView.numberOfItems(inSection: 0)
            {
                previewsCollectionView.selectItem(
                    at: IndexPath(item: activeItem, section: 0),
                    animated: true,
                    scrollPosition: .centeredHorizontally
                )
            }
        }
    }

    // MARK: Private

    private let previewsDataSource = PreviewsCollectionViewDataSource()

    private var showStatusBar = true
}

protocol GalleryDelegate: AnyObject {
    func galleryDidClose(_ gallery: GalleryViewController)
}

class PreviewsCollectionViewDataSource: NSObject, UICollectionViewDataSource, UICollectionViewDelegate {
    weak var delegate: PreviewsCollectionViewDelegate?

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        delegate?.numberOfAttachments() ?? 0
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "PreviewCell",
            for: indexPath
        ) as! GalleryPreviewCollectionViewCell
        guard let attachment = delegate?.getAttachment(for: indexPath) else { return cell }

        cell.imageView.kf.setImage(with: attachment.thumbnailUrl)

        let isVideo = attachment.type == .video
        let isGif = attachment.url.absoluteString.hasSuffix(".gif")
        cell.typeInfoView.isHidden = !(isVideo || isGif)
        cell.gifTypeInfoView.isHidden = !isGif
        cell.videoTypeInfoView.isHidden = !isVideo

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.didSelectAttachment(at: indexPath)
    }
}

protocol PreviewsCollectionViewDelegate: AnyObject {
    func numberOfAttachments() -> Int
    func getAttachment(for indexPath: IndexPath) -> Attachment?
    func didSelectAttachment(at indexPath: IndexPath)
}
