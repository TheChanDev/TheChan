import MobileVLCKit

final class GalleryVideoCollectionViewCell: UICollectionViewCell {
    // MARK: Lifecycle

    override init(frame: CGRect) {
        super.init(frame: frame)
        player.delegate = self
        player.drawable = videoView
        setupLayout()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    static let identifier = "GalleryVideoCollectionViewCell"

    func configure(with url: URL, delegate: GalleryCollectionViewCellDelegate) {
        backgroundColor = .black
        self.delegate = delegate
        controlsView.duration = 0
        controlsView.position = 0
        player.stop()
        player.media = VLCMedia(url: url)
    }

    func startPlayback() {
        player.play()
    }

    func pausePlaypack() {
        player.pause()
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        hideUITimer?.invalidate()
    }

    // MARK: Gestures

    @objc func handlePanning(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: contentView)
        videoView.transform = CGAffineTransform(translationX: 0, y: translation.y)
        let percentage = translation.y / (panAmountRequiredToClose * 1.2)
        backgroundColor = UIColor.black.withAlphaComponent(1 - min(1, percentage))

        if sender.state == .began {
            hideUI()
        }

        guard sender.state == .ended else { return }
        if translation.y >= panAmountRequiredToClose || sender.velocity(in: contentView)
            .y >= panVelocityRequiredToClose
        {
            delegate?.cellWillClose()
            UIView.animate(withDuration: 0.15, animations: {
                self.backgroundColor = .clear
                self.videoView.transform = CGAffineTransform(
                    translationX: 0,
                    y: self.videoView.bounds.height
                )
            }, completion: { _ in
                self.delegate?.cellClosed()
            })
        } else {
            showUI()
            UIView.animate(withDuration: 0.25, animations: {
                self.backgroundColor = .black
                self.videoView.transform = .identity
            })
        }
    }

    // MARK: Private

    private let player = VLCMediaPlayer()
    private let videoView = UIView()
    private let controlsView = VideoControlsView()
    private var hideUITimer: Timer?
    private weak var delegate: GalleryCollectionViewCellDelegate?

    private func setupLayout() {
        contentView.addSubview(videoView)
        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(videoView.pinningEdges(to: contentView))

        contentView.addSubview(controlsView)
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.delegate = self
        NSLayoutConstraint.activate([
            controlsView.leadingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.leadingAnchor,
                constant: 12
            ),
            controlsView.trailingAnchor.constraint(
                equalTo: contentView.safeAreaLayoutGuide.trailingAnchor,
                constant: -12
            ),
            controlsView.heightAnchor.constraint(equalToConstant: 48),
            controlsView.bottomAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanning(_:)))
        panRecognizer.delegate = self
        contentView.addGestureRecognizer(panRecognizer)

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
        doubleTapRecognizer.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTapRecognizer)

        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleUI))
        singleTapGestureRecognizer.require(toFail: doubleTapRecognizer)
        videoView.addGestureRecognizer(singleTapGestureRecognizer)
    }

    @objc private func togglePlayPause() {
        if player.isPlaying {
            player.pause()
        } else if player.time == player.media.length {
            player.stop()
            player.play()
        } else if player.state == .stopped {
            let media = player.media
            player.media = nil
            player.media = media
            player.play()
        } else {
            player.play()
        }
    }

    @objc private func toggleUI() {
        if controlsView.alpha == 1 {
            hideUI()
        } else {
            showUI()
        }
    }

    private func showUI() {
        hideUITimer?.invalidate()
        delegate?.showPreviews()
        UIView.animate(withDuration: 0.25) {
            self.controlsView.alpha = 1
        }

        launchHideUITimer()
    }

    private func hideUI() {
        guard !controlsView.isBeingInteractedWidth else {
            hideUITimer?.invalidate()
            return
        }

        delegate?.hidePreviews()
        UIView.animate(withDuration: 0.25) {
            self.controlsView.alpha = 0
        }
    }

    private func launchHideUITimer() {
        let timer = Timer(timeInterval: 3, repeats: false, block: { [weak self] _ in
            guard let self = self, self.player.isPlaying else { return }
            self.hideUI()
        })

        RunLoop.main.add(timer, forMode: .default)
        hideUITimer = timer
    }
}

extension GalleryVideoCollectionViewCell: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let panRecognizer = gestureRecognizer as? UIPanGestureRecognizer else { return true }
        let velocity = panRecognizer.velocity(in: contentView)
        return abs(velocity.y) > abs(velocity.x) && velocity.y > 0
    }
}

extension GalleryVideoCollectionViewCell: VLCMediaPlayerDelegate {
    func mediaPlayerStateChanged(_ aNotification: Notification!) {
        controlsView.duration = player.media.length.intValue
        controlsView.position = player.time.intValue
        controlsView.isPlaying = player.isPlaying
        if player.isPlaying {
            launchHideUITimer()
        } else {
            showUI()
            hideUITimer?.invalidate()
        }
    }

    func mediaPlayerTimeChanged(_ aNotification: Notification!) {
        controlsView.position = player.time.intValue
    }
}

extension GalleryVideoCollectionViewCell: VideoControlsViewDelegate {
    func videoControlsViewDidTogglePlayPause() {
        togglePlayPause()
    }

    func videoControlsView(_ view: VideoControlsView, didSetPlaybackPositionTo relativePosition: Float) {
        hideUITimer?.invalidate()
        player.position = relativePosition
    }
}

private let panAmountRequiredToClose: CGFloat = 200
private let panVelocityRequiredToClose: CGFloat = 500
