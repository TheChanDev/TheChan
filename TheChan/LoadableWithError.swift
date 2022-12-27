import UIKit

@objc protocol LoadableWithError {
    var tryAgainButton: UIButton? { get set }
    var errorLabel: UILabel? { get set }
}

extension LoadableWithError {
    func makeFooter(progressIndicator: inout UIActivityIndicatorView) -> UIView {
        progressIndicator = UIActivityIndicatorView(style: .medium)
        progressIndicator.translatesAutoresizingMaskIntoConstraints = false
        errorLabel = UILabel()
        errorLabel?.translatesAutoresizingMaskIntoConstraints = false
        errorLabel?.textAlignment = .center
        errorLabel?.font = UIFont.systemFont(ofSize: 15)
        tryAgainButton = UIButton()
        tryAgainButton?.translatesAutoresizingMaskIntoConstraints = false
        let stackView = UIStackView(arrangedSubviews: [progressIndicator, errorLabel!, tryAgainButton!])
        stackView.axis = .vertical

        return stackView
    }

    func setupLoadable(buttonImage: UIImage, selector: Selector) {
        tryAgainButton?.setImage(buttonImage.withRenderingMode(.alwaysTemplate), for: .normal)
        tryAgainButton?.isHidden = true
        errorLabel?.isHidden = true
        tryAgainButton?.addTarget(self, action: selector, for: .touchUpInside)
    }

    func showError(error: String) {
        errorLabel?.text = error
        tryAgainButton?.isHidden = false
        errorLabel?.isHidden = false
    }
}
