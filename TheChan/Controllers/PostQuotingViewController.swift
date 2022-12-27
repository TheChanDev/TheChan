import UIKit

class PostQuotingViewController: UIViewController {
    @IBOutlet var textView: UITextView!
    weak var delegate: PostQuotingDelegate?
    var sourcePost = Post()

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
        textView.backgroundColor = .clear

        textView.attributedText = sourcePost.attributedString
        title = String(key: "QUOTE")
    }

    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        guard
            let range = textView.selectedTextRange,
            let text = textView.text(in: range) else { return }

        delegate?.didQuote(post: sourcePost, withText: text)
    }
}

extension PostQuotingViewController: Themable {
    func applyTheme(_ theme: Theme) {
        view.backgroundColor = theme.backgroundColor
    }
}

protocol PostQuotingDelegate: AnyObject {
    func didQuote(post: Post, withText text: String)
}
