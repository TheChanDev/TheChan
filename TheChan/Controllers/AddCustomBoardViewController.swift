import UIKit

class AddCustomBoardViewController: UIViewController, UITextFieldDelegate {
    // MARK: Internal

    @IBOutlet var idTextField: UITextField!
    @IBOutlet var nameTextField: UITextField!
    var delegate: CustomBoardDialogDelegate?
    @IBOutlet var doneButton: UIBarButtonItem!
    @IBOutlet var verticallyCenter: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribeForThemeChanges()
        preferredContentSize = CGSize(width: 240, height: 120)
        configureField(idTextField)
        configureField(nameTextField)
        idTextField.delegate = self
        nameTextField.delegate = self

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow(_:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide(_:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        idTextField.becomeFirstResponder()
    }

    @objc func keyboardWillShow(_ notification: Notification) {
        guard
            let info = notification.userInfo,
            let keyboardFrame = info[UIResponder.keyboardFrameBeginUserInfoKey] as? CGRect,
            let window = view.window
        else { return }

        let convertedFrame = window.convert(keyboardFrame, to: view)
        verticallyCenter.constant = -convertedFrame.height / 2
        view.layoutIfNeeded()
    }

    @objc func keyboardWillHide(_ notification: Notification) {
        verticallyCenter.constant = 0
        view.layoutIfNeeded()
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard textField.text != nil, textField.text?.isEmpty == false else { return false }

        if textField == idTextField {
            nameTextField.becomeFirstResponder()
            return false
        }

        textField.resignFirstResponder()
        createBoard()
        dismiss(animated: true)
        return true
    }

    @IBAction func idChanged(_ sender: UITextField) {
        doneButton.isEnabled = sender.text != nil && !sender.text!.isEmpty
        guard let id = sender.text else { return }
        guard let name = delegate?.getNameForBoard(withId: id.trimmingCharacters(in: CharacterSet(charactersIn: "/")))
        else { return }

        nameTextField.text = name
    }

    @IBAction func cancelButtonTapped(_ sender: UIBarButtonItem) {
        idTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        dismiss(animated: true)
    }

    @IBAction func doneButtonTapped(_ sender: UIBarButtonItem) {
        idTextField.resignFirstResponder()
        nameTextField.resignFirstResponder()
        createBoard()
        dismiss(animated: true)
    }

    func createBoard() {
        let id = idTextField.text!
        let name = nameTextField.text?.isEmpty == false ? nameTextField.text! : id
        delegate?.didCreateCustomBoard(id: id.trimmingCharacters(in: CharacterSet(charactersIn: "/")), name: name)
    }

    // MARK: Private

    private func configureField(_ field: UITextField) {
        field.layer.borderWidth = 1.0
        field.layer.cornerRadius = 5.0
    }
}

extension AddCustomBoardViewController: Themable {
    func applyTheme(_ theme: Theme) {
        navigationController?.navigationBar.standardAppearance = .fromTheme(theme)
        navigationController?.view.backgroundColor = theme.backgroundColor
        view.backgroundColor = theme.backgroundColor
        [idTextField, nameTextField].forEach {
            $0.attributedPlaceholder = NSAttributedString(
                string: $0.placeholder ?? "",
                attributes: [
                    .foregroundColor: theme.altTextColor,
                ]
            )
            $0.backgroundColor = theme.backgroundColor
            $0.textColor = theme.textColor
            $0.layer.borderColor = theme.separatorColor.cgColor
        }
    }
}

protocol CustomBoardDialogDelegate {
    func getNameForBoard(withId id: String) -> String?
    func didCreateCustomBoard(id: String, name: String)
}
