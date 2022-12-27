protocol VideoControlsViewDelegate: AnyObject {
    func videoControlsViewDidTogglePlayPause()
    func videoControlsView(_ view: VideoControlsView, didSetPlaybackPositionTo relativePosition: Float)
}

final class VideoControlsView: UIView {
    // MARK: Lifecycle

    init() {
        super.init(frame: .zero)
        setupLayout()
        isPlaying = false
        duration = 0
        position = 0

        blurView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(seek)))
        blurView.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(seek)))
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: VideoControlsViewDelegate?

    private(set) var isBeingInteractedWidth: Bool = false

    var isPlaying: Bool = false {
        didSet {
            playPauseButton.setImage(isPlaying ? pauseImage : playImage, for: .normal)
        }
    }

    var duration: Int32 = 0 {
        didSet {
            durationLabel.text = formatTime(duration)
            updatePositionIndicator()
        }
    }

    var position: Int32 = 0 {
        didSet {
            guard !isBeingInteractedWidth else { return }
            positionLabel.text = formatTime(position)
            updatePositionIndicator()
        }
    }

    // MARK: Private

    private let blurView: UIVisualEffectView = {
        let view = UIVisualEffectView(effect: UIBlurEffect(style: .systemThinMaterialDark))
        view.clipsToBounds = true
        view.layer.cornerRadius = 12
        view.layer.cornerCurve = .continuous
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(
        blurEffect: UIBlurEffect(style: .systemThinMaterialDark)
    ))

    private let pauseImage = UIImage(systemName: "pause.fill")
    private let playImage = UIImage(systemName: "play.fill")
    private lazy var playPauseButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.tintColor = .white
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(togglePlayPause), for: .touchUpInside)
        return button
    }()

    private let positionLabel = createLabel()
    private let durationLabel = createLabel()
    private var positionIndicatorWidth: NSLayoutConstraint?
    private let positionIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private static func createLabel() -> UILabel {
        let label = UILabel()
        label.font = .monospacedDigitSystemFont(ofSize: 12, weight: .semibold)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        return label
    }

    private func setupLayout() {
        addSubview(blurView)
        NSLayoutConstraint.activate(blurView.pinningEdges(to: self))

        vibrancyView.translatesAutoresizingMaskIntoConstraints = false
        blurView.contentView.addSubview(vibrancyView)
        NSLayoutConstraint.activate(vibrancyView.pinningEdges(to: blurView.contentView))

        vibrancyView.contentView.addSubview(positionIndicator)
        vibrancyView.contentView.addSubview(playPauseButton)
        vibrancyView.contentView.addSubview(positionLabel)
        vibrancyView.contentView.addSubview(durationLabel)
        durationLabel.textAlignment = .right

        let positionIndicatorWidth = positionIndicator.widthAnchor.constraint(
            equalTo: vibrancyView.contentView.widthAnchor,
            multiplier: 0
        )

        NSLayoutConstraint.activate([
            playPauseButton.leadingAnchor.constraint(equalTo: vibrancyView.contentView.leadingAnchor),
            playPauseButton.topAnchor.constraint(equalTo: vibrancyView.contentView.topAnchor),
            playPauseButton.bottomAnchor.constraint(equalTo: vibrancyView.contentView.bottomAnchor),
            playPauseButton.widthAnchor.constraint(equalToConstant: 48),

            positionLabel.leadingAnchor.constraint(equalTo: playPauseButton.trailingAnchor),
            positionLabel.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor),

            positionIndicator.leadingAnchor.constraint(equalTo: vibrancyView.contentView.leadingAnchor),
            positionIndicator.topAnchor.constraint(equalTo: vibrancyView.contentView.topAnchor),
            positionIndicator.bottomAnchor.constraint(equalTo: vibrancyView.contentView.bottomAnchor),
            positionIndicatorWidth,

            durationLabel.trailingAnchor.constraint(equalTo: vibrancyView.contentView.trailingAnchor, constant: -12),
            durationLabel.centerYAnchor.constraint(equalTo: vibrancyView.contentView.centerYAnchor),
        ])

        self.positionIndicatorWidth = positionIndicatorWidth
    }

    private func updatePositionIndicator() {
        let relativePosition = duration != 0 && position <= duration ? CGFloat(position) / CGFloat(duration) : 0
        setRelativePosition(relativePosition)
    }

    private func setRelativePosition(_ position: CGFloat) {
        positionIndicatorWidth?.isActive = false
        positionIndicatorWidth = positionIndicator.widthAnchor.constraint(
            equalTo: vibrancyView.contentView.widthAnchor,
            multiplier: position
        )

        positionIndicatorWidth?.isActive = true
        layoutIfNeeded()
    }

    private func formatTime(_ time: Int32) -> String {
        let totalSeconds = time / 1000
        let seconds = totalSeconds % 60
        let minutes = totalSeconds / 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    @objc private func togglePlayPause() {
        delegate?.videoControlsViewDidTogglePlayPause()
    }

    @objc private func seek(_ sender: UIGestureRecognizer) {
        isBeingInteractedWidth = true
        let location = sender.location(in: blurView)
        let relativeLocation = location.x / blurView.bounds.width
        positionLabel.text = formatTime(Int32(relativeLocation * CGFloat(duration)))
        setRelativePosition(relativeLocation)
        guard sender.state == .ended else { return }
        delegate?.videoControlsView(self, didSetPlaybackPositionTo: Float(relativeLocation))
        isBeingInteractedWidth = false
    }
}
