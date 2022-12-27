import UIKit

class FormattingButtonsViewController: UIViewController {
    // MARK: Internal

    @IBOutlet var boldButton: UIButton!
    @IBOutlet var italicButton: UIButton!
    @IBOutlet var underlineButton: UIButton!
    @IBOutlet var strikethroughButton: UIButton!
    @IBOutlet var spoilerButton: UIButton!
    @IBOutlet var quoteButton: UIButton!
    @IBOutlet var subButton: UIButton!
    @IBOutlet var supButton: UIButton!

    var delegate: FormattingDelegate?

    var formatter: PostFormatter? {
        didSet {
            guard let formatter = formatter else { return }
            for (button, type) in formattingType {
                button.isHidden = !formatter.supportedTypes.contains(type)
            }
        }
    }

    override func viewDidLoad() {
        wrappingButtons = [
            boldButton, italicButton,
            underlineButton, strikethroughButton,
            subButton, supButton,
            spoilerButton,
        ]

        prefixingButtons = [quoteButton]

        formattingType = [
            boldButton: .bold,
            italicButton: .italic,
            underlineButton: .underline,
            strikethroughButton: .strikethrough,
            quoteButton: .quote,
            subButton: .sub,
            supButton: .sup,
            spoilerButton: .spoiler,
        ]
    }

    @IBAction func buttonTapped(_ sender: UIButton) {
        guard let formatter = formatter else { return }
        guard let type = formattingType[sender] else { return }
        if wrappingButtons.contains(where: { $0 == sender }) {
            let parts = formatter.getWrappingParts(for: type)
            delegate?.wrapIn(left: parts.left, right: parts.right)
        } else {
            delegate?.prefixWith(text: formatter.getPrefix(for: type))
        }
    }

    // MARK: Private

    private var wrappingButtons: [UIButton?] = []
    private var prefixingButtons: [UIButton?] = []
    private var formattingType: [UIButton: PostFormattingType] = [:]
}

protocol FormattingDelegate {
    func wrapIn(left: String, right: String)
    func prefixWith(text: String)
}
