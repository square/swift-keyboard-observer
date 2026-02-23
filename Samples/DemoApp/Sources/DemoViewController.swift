import KeyboardObserver
import UIKit

final class DemoViewController: UIViewController, KeyboardObserverDelegate {

    let overlapBoxBorderRadius: CGFloat = 4

    private let textField = UITextField()
    private let frameLabel = UILabel()
    private let overlapBox = UIView()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "KeyboardObserver Demo"
        view.backgroundColor = .systemBackground

        frameLabel.text = "Tap the text field to show the keyboard."
        frameLabel.font = .preferredFont(forTextStyle: .body)
        frameLabel.textColor = .secondaryLabel
        frameLabel.numberOfLines = 0
        frameLabel.textAlignment = .center

        textField.placeholder = "Tap here to type..."
        textField.borderStyle = .roundedRect
        textField.returnKeyType = .done
        textField.delegate = self

        let stackView = UIStackView(arrangedSubviews: [frameLabel, textField])
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false

        overlapBox.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
        overlapBox.layer.borderColor = UIColor.systemBlue.cgColor
        overlapBox.layer.borderWidth = overlapBoxBorderRadius
        overlapBox.isHidden = true

        view.addSubview(overlapBox)
        view.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -24),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
        ])

        KeyboardObserver.shared.add(delegate: self)
    }

    // MARK: KeyboardObserverDelegate

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
    ) {
        let targetFrame: CGRect
        let targetHidden: Bool
        switch observer.currentFrame(in: view) {
        case .overlapping(let keyboardFrame):
            let overlap = view.bounds.maxY - keyboardFrame.minY
            frameLabel.text = "Keyboard overlapping by \(Int(overlap))pt"
            if keyboardFrame == .zero {
                // A zero frame indicates that the floating keyboard is actively being dragged.
                targetFrame = overlapBox.frame
                targetHidden = true
            } else {
                targetFrame = keyboardFrame
                targetHidden = false
            }

        case .nonOverlapping:
            frameLabel.text = "Keyboard is not overlapping."
            targetFrame = CGRect(x: 0, y: view.bounds.maxY, width: view.bounds.width, height: 0)
            targetHidden = true

        case .none:
            frameLabel.text = "No keyboard frame available."
            targetFrame = CGRect(x: 0, y: view.bounds.maxY, width: view.bounds.width, height: 0)
            targetHidden = true
        }

        let animator = UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
            self.overlapBox.frame = targetFrame.insetBy(
                dx: -self.overlapBoxBorderRadius,
                dy: -self.overlapBoxBorderRadius
            )
            self.view.layoutIfNeeded()
        }
        animator.addCompletion { _ in
            self.overlapBox.isHidden = targetHidden
        }
        animator.startAnimation()
    }
}

extension DemoViewController: UITextFieldDelegate {

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
