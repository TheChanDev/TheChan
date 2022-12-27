import Kingfisher
import MobileCoreServices
import Photos
import RealmSwift
import StoreKit
import UIKit

enum PostingMode {
    case reply(threadNumber: Int)
    case newThread

    // MARK: Internal

    var threadNumber: Int? {
        if case .reply(let threadNumber) = self {
            return threadNumber
        }

        return nil
    }
}

private enum PostAttachment {
    case image(UIImage)
    case video(url: String, preview: UIImage)
}

class PostingViewController:
    UIViewController, UITextFieldDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate,
    UICollectionViewDataSource, FormattingDelegate, UICollectionViewDelegate, CaptchaViewControllerDelegate,
    Themable
{
    // MARK: Internal

    @IBOutlet var sendButton: UIBarButtonItem!
    @IBOutlet var buttonsView: UIView!
    @IBOutlet var postTextView: UITextView!
    @IBOutlet var subjectField: UITextField!
    @IBOutlet var nameField: UITextField!
    @IBOutlet var emailField: UITextField!
    @IBOutlet var captchaField: UITextField!
    @IBOutlet var opSwitch: UISwitch!
    @IBOutlet var sageSwitch: UISwitch!
    @IBOutlet var captchaView: UIView!
    @IBOutlet var captchaActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var captchaImageView: UIImageView!
    @IBOutlet var attachButton: UIButton!
    @IBOutlet var attachmentsCollectionView: UICollectionView!
    @IBOutlet var sendingActivityIndicator: UIActivityIndicatorView!
    @IBOutlet var opLabel: UILabel!
    @IBOutlet var sageLabel: UILabel!
    @IBOutlet var captchaErrorLabel: UILabel!
    @IBOutlet var captchaErrorView: UIView!

    var chan: Chan!
    var boardId: String = ""
    var captcha: Captcha?
    var mode: PostingMode = .newThread

    func applyTheme(_ theme: Theme) {
        let tintColor = chan.tintColor(for: theme, userInterfaceStyle: traitCollection.userInterfaceStyle)
        view.backgroundColor = theme.backgroundColor
        postTextView.textColor = theme.textColor
        buttonsView.backgroundColor = theme.backgroundColor
        attachmentsCollectionView.backgroundColor = theme.backgroundColor
        captchaImageView.backgroundColor = theme.altBackgroundColor
        sageSwitch.tintColor = theme.separatorColor
        opSwitch.tintColor = theme.separatorColor
        sageLabel.textColor = theme.altTextColor
        opLabel.textColor = theme.altTextColor
        captchaErrorLabel.textColor = theme.altTextColor
        opSwitch.onTintColor = tintColor
        sageSwitch.tintColor = tintColor
        attachButton.layer.cornerRadius = 12
        attachButton.layer.cornerCurve = .continuous

        let fields: [UITextField] = [subjectField, nameField, emailField, captchaField]
        for field in fields {
            field.layer.borderWidth = 1.0
            field.layer.borderColor = theme.separatorColor.cgColor
            field.layer.cornerRadius = 5.0
            field.attributedPlaceholder = NSAttributedString(string: field.placeholder ?? "", attributes: [
                .foregroundColor: theme.altTextColor,
            ])
            field.textColor = theme.textColor
            field.backgroundColor = theme.backgroundColor
            field.delegate = self
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subscribeForThemeChanges()
        setupTitle()
        setupFormattingButtons()
        attachmentsCollectionView.dataSource = self
        attachmentsCollectionView.delegate = self
        attachmentsCollectionView.reloadData()
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: .init(
                systemName: "paperplane",
                withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)
            ),
            style: .plain,
            target: self,
            action: #selector(sendButtonTapped)
        )

        postTextView.font = UIFont.systemFont(ofSize: CGFloat(UserSettings.shared.fontSize))
        attachButton.setImage(
            .init(systemName: "plus.circle", withConfiguration: UIImage.SymbolConfiguration(weight: .semibold)),
            for: .normal
        )

        onLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        subscribeForThemeChanges()

        navigationController?.isNavigationBarHidden = false
    }

    override func viewDidAppear(_ animated: Bool) {
        setupCaptcha()

        postTextView.becomeFirstResponder()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        view.endEditing(true)
    }

    func setupFormattingButtons() {
        guard let controller = children[0] as? FormattingButtonsViewController else { return }
        controller.formatter = chan.postFormatter
        controller.delegate = self
    }

    func setupTitle() {
        switch mode {
        case .reply:
            title = NSLocalizedString("POSTING_REPLY_MODE_TITLE", comment: "Reply")
        case .newThread:
            title = NSLocalizedString("POSTING_NEW_THREAD_MODE_TITLE", comment: "New thread")
        }
    }

    func setupCaptcha() {
        captchaImageView.kf.indicatorType = .activity
        captchaImageView.isUserInteractionEnabled = true

        if chan.settings.isPostingWithoutCaptchaEnabled {
            checkIfCaptchaIsEnabled()
        } else {
            loadCaptcha()
        }
    }

    func checkIfCaptchaIsEnabled() {
        chan.isCaptchaEnabled(in: boardId, forCreatingThread: isNewThread()) { isCaptchaEnabled in
            self.captchaActivityIndicator.stopAnimating()
            if isCaptchaEnabled {
                self.loadCaptcha()
            } else {
                self.isCaptchaHidden = true
            }
        }
    }

    func loadCaptcha(completion: ((Captcha?, CaptchaError?) -> Void)? = nil) {
        chan.getCaptcha(boardId: boardId, threadNumber: mode.threadNumber) { [weak self] captcha, error in
            completion?(captcha, error)
            self?.applyCaptcha(captcha, error: error)
        }
    }

    func isNewThread() -> Bool {
        if case .newThread = mode {
            return true
        }

        return false
    }

    @IBAction func captchaTapped(_ sender: UITapGestureRecognizer) {
        setupCaptcha()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @IBAction func retryLoadingCaptcha() {
        isCapchaErrorHidden = true
        isCaptchaHidden = true
        captchaActivityIndicator.startAnimating()
        loadCaptcha()
    }

    @IBAction func emailChanged(_ sender: UITextField) {
        sageSwitch.setOn(sender.text?.lowercased() == "sage", animated: true)
    }

    @IBAction func sageSwitchValueChanged(_ sender: UISwitch) {
        emailField.text = sender.isOn ? "sage" : nil
    }

    @IBAction func sendButtonTapped(_ sender: UIBarButtonItem) {
        if captcha is ReCaptcha || captcha is SliderCaptcha {
            showCaptchaViewController()
            return
        }

        sendPost(withCaptchaResult: nil)
    }

    func didCompleteCaptcha(_ sender: CaptchaViewController, withResult result: CaptchaResult) {
        sendPost(withCaptchaResult: result)
    }

    func showCaptchaViewController() {
        guard let captcha = captcha else { return }
        if captcha is ReCaptcha || captcha is SliderCaptcha {
            guard let vc = storyboard?
                .instantiateViewController(withIdentifier: "CaptchaVC") as? WebViewCaptchaViewController else { return }
            vc.setCaptcha(captcha)
            vc.delegate = self
            vc.chan = chan
            let nav = UINavigationController(rootViewController: vc)
            nav.modalPresentationStyle = .popover
            present(nav, animated: true, completion: nil)
        }
    }

    func sendPost(withCaptchaResult captchaResult: CaptchaResult? = nil) {
        sendButton.isEnabled = false
        postTextView.resignFirstResponder()

        let postingData = getPostingData()
        if captchaResult != nil {
            postingData.captchaResult = captchaResult
        }

        UIView.transition(
            with: sendingActivityIndicator,
            duration: 0.25,
            options: .transitionCrossDissolve,
            animations: {
                self.sendingActivityIndicator.startAnimating()
            }
        )

        chan.send(post: postingData) { isSuccessful, error, postNumber in
            UIView.transition(
                with: self.sendingActivityIndicator,
                duration: 0.25,
                options: .transitionCrossDissolve,
                animations: {
                    self.sendingActivityIndicator.stopAnimating()
                }
            )

            self.sendButton.isEnabled = true
            if !isSuccessful {
                let error = error ?? NSLocalizedString("UNKNOWN_ERROR", comment: "Unknown error")
                let alert = UIAlertController(title: String(key: "ERROR"), message: error, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
            } else if case .reply = self.mode {
                self.performSegue(withIdentifier: "UnwindToThread", sender: self)
                self.cleanUp()
            } else if case .newThread = self.mode {
                self.navigateToThread(by: postNumber ?? 0)
            }

            if let number = postNumber {
                self.addUserPost(number: number)
            }
        }
    }

    func getPostingData() -> PostingData {
        let postingData = PostingData()
        postingData.text = postTextView.text
        postingData.boardId = boardId
        postingData.subject = subjectField.text ?? ""
        postingData.email = emailField.text ?? ""
        postingData.name = nameField.text ?? ""
        postingData.isOp = opSwitch.isOn
        for attachment in attachments {
            switch attachment {
            case .image(let image):
                guard let data = image.jpegData(compressionQuality: 1.0) else { continue }
                let postingAttachment = PostingAttachment()
                postingAttachment.data = data
                postingAttachment.mimeType = "image/jpeg"
                postingAttachment.name = "image.jpeg"
                postingData.attachments.append(postingAttachment)
            case .video:
                break
            }
        }

        if let imageCaptcha = captcha as? ImageCaptcha {
            postingData.captchaResult = CaptchaResult(captcha: imageCaptcha, input: captchaField.text ?? "")
        }

        if case .reply(let threadNumber) = mode {
            postingData.boardId = boardId
            postingData.threadNumber = threadNumber
        }

        return postingData
    }

    func navigateToThread(by number: Int) {
        guard var viewControllers = navigationController?.viewControllers else { return }
        guard let threadController = storyboard?
            .instantiateViewController(withIdentifier: "ThreadVC") as? ThreadTableViewController else { return }
        threadController.chan = chan
        threadController.navigationInfo = ThreadNavigationInfo(boardId: boardId, threadNumber: number)
        viewControllers.removeLast()
        viewControllers.append(threadController)
        navigationController?.setViewControllers(viewControllers, animated: true)
    }

    @IBAction func attachButtonTapped(_ sender: UIButton) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.sourceType = .photoLibrary
        var types: [String] = [kUTTypeImage as String]
        if chan.id == "2ch" {
            types.append(kUTTypeMovie as String)
        }
        imagePickerController.mediaTypes = types
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        attachments.append(.image(image))
        updateAttachButton()
        attachmentsCollectionView.reloadData()
        dismiss(animated: true, completion: nil)
    }

    // MARK: - UICollectionViewDataSource for attachments

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        attachments.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "AttachmentCollectionViewCell",
            for: indexPath
        ) as! AttachmentCollectionViewCell
        let attachment = attachments[indexPath.item]
        switch attachment {
        case .image(let image):
            cell.previewImageView.image = image
        case .video(_, let preview):
            cell.previewImageView.image = preview
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let index = indexPath.item
        attachments.remove(at: index)
        updateAttachButton()
        collectionView.reloadData()
    }

    func reply(to post: Int, with text: String) {
        let replyAction = { [unowned self] () in
            var quote = text.components(separatedBy: "\n").map {
                $0.trimmingCharacters(in: CharacterSet.whitespaces).isEmpty ? $0 : self.getPrefixedLine(source: $0)
            }.joined(separator: "\n").trimmingCharacters(in: CharacterSet.newlines)

            if !quote.isEmpty {
                quote += "\n"
            }

            let resultText = post == self.lastQuotedPost && !quote.isEmpty ? quote : ">>\(post)\n\(quote)"
            self.lastQuotedPost = post
            self.insertReply(resultText)
        }

        if isViewLoaded {
            replyAction()
        } else {
            onLoad = replyAction
        }
    }

    func insertReply(_ replyText: String) {
        guard let selection = Range(postTextView.selectedRange) else { return }
        var text = postTextView.text ?? ""
        let selectionStartIndex = text.index(text.startIndex, offsetBy: selection.lowerBound)
        let textBeforeSelection = String(text[..<selectionStartIndex])
        let finalReplyText = getPrefixFor(textBeforeSelection: textBeforeSelection) + replyText
        text.insert(contentsOf: finalReplyText, at: selectionStartIndex)
        postTextView.text = text
        postTextView.selectedRange =
            NSMakeRange(
                textBeforeSelection.count + finalReplyText.count,
                0
            )
    }

    func getPrefixFor(textBeforeSelection: String) -> String {
        if textBeforeSelection.hasSuffix("\n\n") || textBeforeSelection.isEmpty {
            return ""
        }

        if textBeforeSelection.hasSuffix("\n") {
            return "\n"
        }

        return "\n\n"
    }

    func getPrefixedLine(source: String) -> String {
        chan.postFormatter.getPrefix(for: .quote) + source
    }

    // MARK: - FormatterDelegate

    func wrapIn(left: String, right: String) {
        guard let selection = Range(postTextView.selectedRange) else { return }
        var text = postTextView.text ?? ""
        text.insert(contentsOf: right, at: text.index(text.startIndex, offsetBy: selection.upperBound))
        text.insert(contentsOf: left, at: text.index(text.startIndex, offsetBy: selection.lowerBound))
        postTextView.text = text

        let cursorPosition = selection.upperBound + left.count
        postTextView.selectedRange = NSMakeRange(cursorPosition, 0)
    }

    func prefixWith(text: String) {
        guard let selection = Range(postTextView.selectedRange) else { return }
        var postText = postTextView.text ?? ""
        postText.insert(contentsOf: text, at: postText.index(postText.startIndex, offsetBy: selection.lowerBound))
        postTextView.text = postText

        let cursorPosition = selection.upperBound + text.count
        postTextView.selectedRange = NSMakeRange(cursorPosition, 0)
    }

    // MARK: Private

    private var attachments = [PostAttachment]()
    private var lastQuotedPost = -1
    private var onLoad: () -> Void = {}

    private var isCaptchaHidden: Bool = true {
        didSet {
            guard oldValue != isCaptchaHidden else { return }
            UIView.transition(with: captchaView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.captchaView.isHidden = self.isCaptchaHidden
            }, completion: nil)
        }
    }

    private var isCapchaErrorHidden: Bool = true {
        didSet {
            guard oldValue != isCapchaErrorHidden else { return }
            UIView.transition(with: captchaView, duration: 0.25, options: .transitionCrossDissolve, animations: {
                self.captchaErrorView.isHidden = self.isCapchaErrorHidden
            }, completion: nil)
        }
    }

    private func applyCaptcha(_ captcha: Captcha?, error: CaptchaError?) {
        self.captcha = captcha
        captchaActivityIndicator.stopAnimating()
        if let error {
            isCaptchaHidden = true
            isCapchaErrorHidden = false
            if let helpText = error.helpMessage {
                captchaErrorLabel.text = String(
                    format: String(key: "CAPTCHA_LOAD_ERROR_WITH_HELP_MESSAGE"),
                    helpText
                )
            } else {
                captchaErrorLabel.text = String(key: "CAPTCHA_LOAD_ERROR")
            }
            return
        }

        isCapchaErrorHidden = true
        guard let imageCaptcha = captcha as? ImageCaptcha else {
            isCaptchaHidden = true
            return
        }

        guard let url = imageCaptcha.imageURL else { return }
        captchaField.text = ""
        isCaptchaHidden = false
        captchaImageView.kf.setImage(with: url)
    }

    private func addUserPost(number: Int) {
        let post = UserPost()
        post.chanId = chan.id
        post.boardId = boardId
        post.number = number
        let realm: Realm = RealmInstance.ui
        try! realm.write {
            realm.add(post)
        }
    }

    private func cleanUp() {
        attachments.removeAll()
        attachmentsCollectionView.reloadData()
        updateAttachButton()
        postTextView.text = nil
        subjectField.text = nil
        captcha = nil
        captchaField.text = nil
        lastQuotedPost = -1
    }

    private func updateAttachButton() {
        if attachments.count >= chan.maxAttachments {
            attachButton.isEnabled = false
        } else {
            attachButton.isEnabled = true
        }
    }
}
