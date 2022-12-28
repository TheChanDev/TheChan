import WebKit

protocol AuthorizationViewControllerDelegate: AnyObject {
    func authorizationViewControllerDelegateDidCompleteAuthorization(_ controller: AuthorizationViewController)
}

final class AuthorizationViewController: UIViewController {
    // MARK: Lifecycle

    init(url: URL) {
        self.url = url
        super.init(nibName: nil, bundle: nil)
        title = String(key: "AUTHORIZATION")
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: .init(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)),
            style: .plain,
            target: self,
            action: #selector(close)
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Internal

    weak var delegate: AuthorizationViewControllerDelegate?

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
        webView.navigationDelegate = self
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(webView)
        NSLayoutConstraint.activate(webView.pinningEdges(to: view))
        webView.load(.init(url: url))
    }

    // MARK: Private

    private let url: URL
    private lazy var webView = WKWebView()

    @objc private func close() {
        dismiss(animated: true)
    }
}

extension AuthorizationViewController: Themable {
    func applyTheme(_ theme: Theme) {
        navigationController?.view.backgroundColor = theme.backgroundColor
        view.backgroundColor = theme.backgroundColor
        webView.backgroundColor = theme.backgroundColor
    }
}

extension AuthorizationViewController: WKNavigationDelegate {
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        guard let response = navigationResponse.response as? HTTPURLResponse,
              response.statusCode == 200,
              response.url == url
        else {
            decisionHandler(.allow)
            return
        }

        webView.configuration.websiteDataStore.httpCookieStore.getAllCookies { [weak self] cookies in
            guard let self = self else { return }
            HTTPCookieStorage.shared.cookies(for: self.url)?.forEach(HTTPCookieStorage.shared.deleteCookie(_:))
            cookies.forEach(HTTPCookieStorage.shared.setCookie(_:))
            self.delegate?.authorizationViewControllerDelegateDidCompleteAuthorization(self)
            decisionHandler(.allow)
        }
    }
}
