import MobileVLCKit

final class VideoViewController: UIViewController {
    // MARK: Lifecycle

    init(url: URL) {
        media = VLCMedia(url: url)
        super.init(nibName: nil, bundle: nil)
        player.delegate = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        view.addSubview(videoView)

        videoView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(videoView.pinningEdges(to: view))
        player.drawable = videoView

        view.addSubview(controlsView)
        controlsView.translatesAutoresizingMaskIntoConstraints = false
        controlsView.delegate = self
        NSLayoutConstraint.activate([
            controlsView.leadingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.leadingAnchor,
                constant: 12
            ),
            controlsView.trailingAnchor.constraint(
                equalTo: view.safeAreaLayoutGuide.trailingAnchor,
                constant: -12
            ),
            controlsView.heightAnchor.constraint(equalToConstant: 48),
            controlsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])

        let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(togglePlayPause))
        doubleTapRecognizer.numberOfTapsRequired = 2
        videoView.addGestureRecognizer(doubleTapRecognizer)

        let singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(toggleUI))
        singleTapGestureRecognizer.require(toFail: doubleTapRecognizer)
        videoView.addGestureRecognizer(singleTapGestureRecognizer)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if player.media == nil {
            player.media = media
            player.play()
        }
    }

    // MARK: Private

    private let player = VLCMediaPlayer()
    private let media: VLCMedia
    private lazy var videoView = UIView()
    private lazy var controlsView = VideoControlsView()
    private var hideUITimer: Timer?

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

        navigationController?.setNavigationBarHidden(false, animated: true)
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

        navigationController?.setNavigationBarHidden(true, animated: true)
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

extension VideoViewController: VLCMediaPlayerDelegate {
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

extension VideoViewController: VideoControlsViewDelegate {
    func videoControlsViewDidTogglePlayPause() {
        togglePlayPause()
    }

    func videoControlsView(_ view: VideoControlsView, didSetPlaybackPositionTo relativePosition: Float) {
        hideUITimer?.invalidate()
        player.position = relativePosition
    }
}
