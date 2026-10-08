#if !os(watchOS)

import UIKit

/// Publicly exposes the current frame provider for consumers
/// that need to calculate their own content insets.
public protocol KeyboardCurrentFrameProvider {

    func currentFrame(in view: UIView) -> KeyboardFrame?
}

public enum KeyboardFrame: Equatable {

    /// The current frame does not overlap the current view at all.
    case nonOverlapping

    /// The current frame does overlap the view, by the provided rect, in the view's coordinate space.
    /// To calculate the exact overlap of the view, use `view.bounds.intersection(frame)`.
    case overlapping(frame: CGRect)
}

extension KeyboardObserver: KeyboardCurrentFrameProvider {}

public protocol KeyboardObserverDelegate: AnyObject {

    func keyboardFrameWillChange(
        for observer: KeyboardObserver,
        animationDuration: Double,
        animationCurve: UIView.AnimationCurve
    )
}

/// Encapsulates listening for system keyboard updates, plus transforming the visible frame of the keyboard into the coordinates of a requested view.
///
/// You use this class by providing a delegate, which receives callbacks when changes to the keyboard frame occur. You would usually implement
/// the delegate somewhat like this:
///
/// ```
/// func keyboardFrameWillChange(
///    for observer: KeyboardObserver,
///    animationDuration: Double,
///    animationCurve: UIView.AnimationCurve
/// ) {
///    let animator = UIViewPropertyAnimator(duration: animationDuration, curve: animationCurve) {
///        // Use the frame from the keyboardObserver to update insets or sizing where relevant.
///    }
///    animator.startAnimation()
/// }
/// ```
///
/// Notes
/// -----
/// iOS Docs for keyboard management:
/// https://developer.apple.com/library/archive/documentation/StringsTextFonts/Conceptual/TextAndWebiPhoneOS/KeyboardManagement/KeyboardManagement.html
///
public final class KeyboardObserver {

    /// The global shared keyboard observer. Why is it a global shared instance?
    /// We can only know the keyboard position via the keyboard frame notifications.
    ///
    /// If a keyboard observing view is created while a keyboard is already on-screen, we'd have no way to determine the
    /// keyboard frame, and thus couldn't provide the correct content insets to avoid the visible keyboard.
    ///
    /// Thus, the `shared` observer is set up on app startup
    /// (via ``configure(with:)``) to avoid this problem.
    public static let shared: KeyboardObserver = KeyboardObserver(center: .default)

    /// Allow logging to the console if app startup-timed shared instance startup did not
    /// occur; this could cause bugs for the reasons outlined above.
    fileprivate static var didSetupSharedInstanceDuringAppStartup = false

    private let center: NotificationCenter

    private(set) var delegates: [Delegate] = []

    struct Delegate {
        private(set) weak var value: KeyboardObserverDelegate?
    }

    //
    // MARK: Initialization
    //

    public init(center: NotificationCenter) {

        self.center = center

        /// We need to listen to both `will` and `keyboardDidChangeFrame` notifications. Why?
        ///
        /// When dealing with an undocked or floating keyboard, historically, moving the keyboard
        /// around the screen did NOT call `willChangeFrame`; only `didChangeFrame`. In recent
        /// iOS versions, moving the undocked or floating keyboard around the screen calls
        /// `willChangeFrame` with a `zero` frame, then it follows with `didChangeFrame` when
        /// the keyboard is done moving. Both delegates will cover all cases.
        ///
        /// Before calling the delegate, we compare positions in fixed screen coordinates,
        /// which prevents duplicate calls without conflating equal rectangles from different orientations.

        self.center.addObserver(
            self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIWindow.keyboardWillChangeFrameNotification,
            object: nil
        )
        self.center.addObserver(
            self,
            selector: #selector(keyboardFrameChanged(_:)),
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: nil
        )
    }

    private var latestNotification: NotificationInfo?

    //
    // MARK: Delegates
    //

    public func add(delegate: KeyboardObserverDelegate) {

        if delegates.contains(where: { $0.value === delegate }) {
            return
        }

        delegates.append(Delegate(value: delegate))

        removeDeallocatedDelegates()
    }

    public func remove(delegate: KeyboardObserverDelegate) {
        delegates.removeAll {
            $0.value === delegate
        }

        removeDeallocatedDelegates()
    }

    private func removeDeallocatedDelegates() {
        delegates.removeAll {
            $0.value == nil
        }
    }

    //
    // MARK: Handling Changes
    //

    /// How the keyboard overlaps the view provided. If the view is not on screen (eg, no window),
    /// or the observer has not yet learned about the keyboard's position, this method returns nil.
    /// Notifications that omit their screen are assumed to describe the main display.
    /// A keyboard that was offscreen when reported remains nonoverlapping until another notification arrives.
    public func currentFrame(in view: UIView) -> KeyboardFrame? {

        guard let window = view.window else {
            return nil
        }

        guard let notification = latestNotification else {
            return nil
        }

        guard notification.frameScreen == window.screen else {
            return .nonOverlapping
        }

        guard notification.isOnScreen else {
            return .nonOverlapping
        }

        let frame = notification.frameScreen.fixedCoordinateSpace.convert(
            notification.frameInFixedCoordinateSpace,
            to: view
        )

        let intersection = view.bounds.intersection(frame)
        // Ignore trivial overlap that can result from fractional view sizes.
        if intersection.width >= 1 && intersection.height >= 1 {
            return .overlapping(frame: frame)
        } else {
            return .nonOverlapping
        }
    }

    /// This returns true if the on-screen keyboard is a floating iPad keyboard. This is done by
    /// comparing the keyboard frame against the bounds of the screen.
    /// Classification uses the screen bounds at notification time, so later rotation cannot
    /// turn a cached docked keyboard into a floating one (or vice versa).
    /// - Parameter view: Used to establish that a view is on screen when the notification has no screen.
    /// - Returns: `true` if the keyboard is floating.
    public func isKeyboardFloating(using view: UIView) -> Bool {

        guard let notification = latestNotification else {
            return false
        }

        guard notification.isOnScreen else {
            return false
        }

        guard notification.screen != nil || view.window != nil else {
            return false
        }

        if let window = view.window, notification.frameScreen != window.screen {
            return false
        }

        return notification.isKeyboardFloating
    }

    //
    // MARK: Receiving Updates
    //

    private func receivedUpdatedKeyboardInfo(_ new: NotificationInfo) {

        let old = latestNotification

        latestNotification = new

        /// Only communicate a frame change to the delegate if the frame actually changed.

        if let old,
           old.endingFrame == new.endingFrame,
           old.frameScreen == new.frameScreen,
           old.frameInFixedCoordinateSpace == new.frameInFixedCoordinateSpace,
           old.isOnScreen == new.isOnScreen,
           old.isKeyboardFloating == new.isKeyboardFloating
        {
            return
        }

        delegates.forEach {
            $0.value?.keyboardFrameWillChange(
                for: self,
                animationDuration: new.animationDuration,
                animationCurve: new.animationCurve
            )
        }
    }

    //
    // MARK: Notification Listeners
    //

    @objc private func keyboardFrameChanged(_ notification: Notification) {

        do {
            let info = try NotificationInfo(with: notification)
            receivedUpdatedKeyboardInfo(info)
        } catch {
            assertionFailure("Could not read system keyboard notification: \(error)")
        }
    }
}

extension KeyboardObserver {
    struct NotificationInfo: Equatable {

        var endingFrame: CGRect = .zero

        var animationDuration: Double = 0.0
        var animationCurve: UIView.AnimationCurve = .easeInOut

        /// The `UIScreen` that the keyboard appears on.
        ///
        /// This may influence the `KeyboardFrame` calculation when the app is not in full screen,
        /// such as in Split View, Slide Over, and Stage Manager.
        ///
        /// - note: In iOS 16.1 and later, every `keyboardWillChangeFrameNotification` and
        /// `keyboardDidChangeFrameNotification` is _supposed_ to include a `UIScreen`
        /// in a the notification, however we've had reports that this isn't always the case (at least when
        /// using the iOS 16.1 simulator runtime). If a screen is _not_ included in an iOS 16.1+ notification,
        /// we do not throw a `ParseError` as it would cause the entire notification to be discarded.
        ///
        /// [Apple Documentation](https://developer.apple.com/documentation/uikit/uiresponder/1621623-keyboardwillchangeframenotificat)
        var screen: UIScreen?

        var frameScreen: UIScreen
        var frameInFixedCoordinateSpace: CGRect
        /// Preserve visibility at notification time; rotation can move a cached offscreen frame into a view.
        var isOnScreen: Bool
        var isKeyboardFloating: Bool

        init(with notification: Notification) throws {

            guard let userInfo = notification.userInfo else {
                throw ParseError.missingUserInfo
            }

            guard let endingFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else {
                throw ParseError.missingEndingFrame
            }

            self.endingFrame = endingFrame

            guard let animationDuration = (userInfo[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue else {
                throw ParseError.missingAnimationDuration
            }

            self.animationDuration = animationDuration

            guard let curveValue = (userInfo[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.intValue,
                  let animationCurve = UIView.AnimationCurve(rawValue: curveValue)
            else {
                throw ParseError.missingAnimationCurve
            }

            self.animationCurve = animationCurve

            screen = notification.object as? UIScreen

            // Keyboard rectangles use the screen's orientation at delivery. That coordinate space
            // can rotate before a later query, so retain the position in orientation-independent coordinates.
            // https://developer.apple.com/documentation/uikit/uiscreen/fixedcoordinatespace
            frameScreen = screen ?? .main
            isOnScreen = endingFrame.intersects(frameScreen.bounds)
            frameInFixedCoordinateSpace = frameScreen.coordinateSpace.convert(
                endingFrame,
                to: frameScreen.fixedCoordinateSpace
            )
            isKeyboardFloating = endingFrame.maxY < frameScreen.bounds.maxY
                && endingFrame.width < frameScreen.bounds.width / 2
        }

        enum ParseError: Error, Equatable {

            case missingUserInfo
            case missingEndingFrame
            case missingAnimationDuration
            case missingAnimationCurve
        }
    }
}


extension KeyboardObserver {
    private static let isExtensionContext: Bool = // This is our best guess for "is this executable an extension?"
        if let _ = Bundle.main.infoDictionary?["NSExtension"] {
            true
        } else if Bundle.main.bundlePath.hasSuffix(".appex") {
            true
        } else {
            false
        }

    /// This should be called by a keyboard-observing view on setup, to warn developers if something has gone wrong with
    /// keyboard setup.
    public static func logKeyboardSetupWarningIfNeeded() {
        guard !isExtensionContext else {
            return
        }

        if KeyboardObserver.didSetupSharedInstanceDuringAppStartup {
            return
        }

        print(
            """
            WARNING: The shared instance of the `KeyboardObserver` was not instantiated
            during app startup. While not fatal, this could result in a view being created that
            does not properly position itself to account for the keyboard, if the view is created
            while the keyboard is already visible.
            """
        )
    }
}

extension KeyboardObserver {

    /// This should be called in `UIApplicationDelegate.application(_:, didFinishLaunchingWithOptions:)`
    /// It ensures that the initial keyboard presentation is detected. Calling this while a keyboard is
    /// already on screen will cause `KeyboardObserver` to miss the initial keyboard frame.
    @available(iOSApplicationExtension, unavailable, message: "This cannot be used in application extensions")
    @objc(configureWithApplication:)
    public static func configure(with application: UIApplication) {
        _ = KeyboardObserver.shared
        KeyboardObserver.didSetupSharedInstanceDuringAppStartup = true
    }
}

#endif
