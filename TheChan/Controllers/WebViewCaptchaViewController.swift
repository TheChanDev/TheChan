import UIKit
import WebKit

class WebViewCaptchaViewController: UIViewController, CaptchaViewController, WKNavigationDelegate {
    // MARK: Internal

    var chan: Chan!
    weak var delegate: CaptchaViewControllerDelegate?

    func setCaptcha(_ captcha: Captcha) {
        self.captcha = captcha
        if captcha is SliderCaptcha {
            navigationItem.rightBarButtonItem = UIBarButtonItem(
                image: .init(
                    systemName: "paperplane",
                    withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
                ),
                style: .plain,
                target: self,
                action: #selector(submitSliderCaptcha)
            )
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = String(key: "CAPTCHA")
        webView.configuration.userContentController.add(self, name: "cloudflare")
        webView.configuration.userContentController.add(self, name: "submit")
        webView.navigationDelegate = self
        subscribeForThemeChanges()

        view.addSubview(webView)
    }

    override func viewWillLayoutSubviews() {
        webView.frame = view.bounds
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        if let url = navigationAction.request.url,
           url.scheme == "thechan", url.host == "captcha-result"
        {
            let response = url.pathComponents[1]
            let result = CaptchaResult(captcha: captcha, input: response)

            decisionHandler(.cancel)
            delegate?.didCompleteCaptcha(self, withResult: result)
            dismiss(animated: true, completion: nil)
        } else {
            decisionHandler(.allow)
        }
    }

    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse,
        decisionHandler: @escaping (WKNavigationResponsePolicy) -> Void
    ) {
        guard let captcha = captcha as? SliderCaptcha,
              let response = navigationResponse.response as? HTTPURLResponse,
              response.statusCode == 200
        else {
            decisionHandler(.allow)
            return
        }

        decisionHandler(.cancel)
        let tintColor = chan.tintColor(for: theme, userInterfaceStyle: traitCollection.userInterfaceStyle)
        webView.loadHTMLString(
            captcha.makeHTML(theme: theme, tintColor: tintColor),
            baseURL: captcha.baseURL
        )
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }

    // MARK: Private

    private let webView = WebView()
    private var captcha: Captcha = ReCaptcha()
    private var theme: Theme!

    @objc private func submitSliderCaptcha() {
        webView.evaluateJavaScript("submitCaptcha()")
    }
}

extension WebViewCaptchaViewController: Themable {
    func applyTheme(_ theme: Theme) {
        self.theme = theme
        view.backgroundColor = theme.backgroundColor
        webView.backgroundColor = theme.backgroundColor
        webView.scrollView.backgroundColor = theme.backgroundColor
        navigationController?.navigationBar.standardAppearance = .fromTheme(theme)
        let tintColor = chan.tintColor(for: theme, userInterfaceStyle: traitCollection.userInterfaceStyle)

        if let recaptcha = captcha as? ReCaptcha {
            webView.loadHTMLString(
                recaptcha.makeHTML(
                    darkTheme: traitCollection.userInterfaceStyle == .dark,
                    background: theme.backgroundColor
                ),
                baseURL: recaptcha.baseURL
            )
        } else if let sliderCaptcha = captcha as? SliderCaptcha {
            webView.loadHTMLString(
                sliderCaptcha.makeHTML(theme: theme, tintColor: tintColor),
                baseURL: sliderCaptcha.baseURL
            )

            webView.scrollView.isScrollEnabled = false
        }
    }
}

extension WebViewCaptchaViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "submit":
            guard let body = message.body as? [String: String],
                  let input = body["input"],
                  let challenge = body["challenge"],
                  let captcha = captcha as? SliderCaptcha
            else { return }

            delegate?.didCompleteCaptcha(self, withResult: .init(
                captcha: SliderCaptcha(key: challenge, board: captcha.board, threadNumber: captcha.threadNumber),
                input: input.uppercased()
            ))

            dismiss(animated: true)
        case "cloudflare":
            guard let html = message.body as? String, let captcha = captcha as? SliderCaptcha else { return }
            webView.loadHTMLString(html, baseURL: captcha.baseURL)
        default:
            break
        }
    }
}

private class WebView: WKWebView {
    override var inputAccessoryView: UIView? { nil }
}
