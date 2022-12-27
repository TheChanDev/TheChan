import Foundation

class ReCaptcha: Captcha {
    // MARK: Lifecycle

    init() {}

    convenience init(key: String, baseURL: URL? = nil) {
        self.init()
        self.key = key
        self.baseURL = baseURL
    }

    // MARK: Internal

    var key = ""
    var baseURL: URL?

    func makeHTML(darkTheme: Bool, background: UIColor) -> String {
        let html =
            "<head>" +
            "<meta name='viewport' content= 'width=device-width, initial-scale=1.0' >" +
            "<style>" +
            "* { margin: 0; padding: 0; }" +
            "</style>" +
            "<script type='text/javascript'>" +
            "var onloadCallback = function() {" +
            "grecaptcha.render('html_element', {" +
            "'sitekey' : '\(key)'," +
            "'callback' : dataCallback," +
            "'theme' : '\(darkTheme ? "dark" : "light")'," +
            "});" +
            "};" +
            "</script>" +
            "<script type='text/javascript'>" +
            "var dataCallback = function(authResult) {" +
            "window.location.href = 'thechan://captcha-result/' + authResult" +
            "};" +
            "</script>" +
            "<script src='https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit'></script>" +
            "</head>" +
            "<body style='height: 100%; background: \(background.toHexString())'>" +
            "<form name='myform' action='' method='post' style='height: 100%'>" +
            "<div style='display: flex; align-items: center; justify-content: center; height: 100%'>" +
            "<div style='width: 304px; height: 78px;'>" +
            "<div id='html_element'></div>" +
            "</div>" +
            "</div>" +
            "</form>" +
            "</body>"
        return html
    }
}
