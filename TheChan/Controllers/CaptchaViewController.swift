protocol CaptchaViewController: UIViewController {
    func setCaptcha(_ captcha: Captcha)
}

protocol CaptchaViewControllerDelegate: AnyObject {
    func didCompleteCaptcha(_ sender: CaptchaViewController, withResult result: CaptchaResult)
}
