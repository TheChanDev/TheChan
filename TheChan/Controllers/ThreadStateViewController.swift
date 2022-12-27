import UIKit

enum ThreadState {
    case refreshing
    case success(unreadPosts: Int)
    case error(message: String)
}

class ThreadStateViewController: UIViewController {
    // MARK: Internal

    var indicatorTint = UIColor.black

    var state = ThreadState.success(unreadPosts: 0) {
        didSet {
            updateStateView(oldValue: oldValue)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view = UIView(frame: CGRect.zero)
        subscribeForThemeChanges()

        postsIndicatorView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(postsIndicatorView)
        view.addSubview(activityIndicatorView)

        view.leadingAnchor.constraint(equalTo: postsIndicatorView.leadingAnchor).isActive = true
        view.trailingAnchor.constraint(equalTo: postsIndicatorView.trailingAnchor).isActive = true
        postsIndicatorView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        postsIndicatorView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        activityIndicatorView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        activityIndicatorView.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true

        updateStateView(oldValue: state)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        subscribeForThemeChanges()
    }

    // MARK: Private

    private var postsIndicatorView = PostsIndicatorView(frame: CGRect.zero)
    private var activityIndicatorView: UIActivityIndicatorView = {
        let i = UIActivityIndicatorView(style: .medium)
        i.translatesAutoresizingMaskIntoConstraints = false
        return i
    }()

    private var theme: Theme?

    private func updateStateView(oldValue: ThreadState) {
        guard let theme = theme else { fatalError("theme is nil") }

        switch state {
        case .refreshing:
            activityIndicatorView.startAnimating()
            UIView.animate(withDuration: 0.2) {
                self.postsIndicatorView.alpha = 0
                self.activityIndicatorView.alpha = 1
            }

        case .success(let unreadPosts):
            postsIndicatorView.label.text = "\(unreadPosts)"
            let background: UIColor = unreadPosts > 0 ? indicatorTint : theme.postsIndicatorInactiveBackgroundColor
            let foreground: UIColor = unreadPosts > 0
                ? theme.backgroundColor
                : theme.postsIndicatorInactiveForegroundColor

            if case .success = oldValue {
                self.animateIndicator(to: background, to: foreground)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                    self.animateIndicator(to: background, to: foreground)
                }
            }
        case .error:
            postsIndicatorView.label.text = "!"
            animateIndicator(to: theme.postsIndicatorErrorBackgroundColor, to: theme.postsIndicatorErrorForegroundColor)
        }
    }

    private func animateIndicator(to background: UIColor, to foreground: UIColor) {
        activityIndicatorView.stopAnimating()
        UIView.animate(withDuration: 0.2) {
            self.activityIndicatorView.alpha = 0
            self.postsIndicatorView.alpha = 1
            self.postsIndicatorView.label.textColor = foreground
            self.postsIndicatorView.backgroundView.backgroundColor = background
            self.postsIndicatorView.backgroundView.setNeedsDisplay()
            self.postsIndicatorView.label.setNeedsDisplay()
            self.postsIndicatorView.layoutIfNeeded()
        }
    }
}

extension ThreadStateViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        updateStateView(oldValue: state)
    }
}
