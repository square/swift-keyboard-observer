import UIKit
import XCTest

@testable import KeyboardObserver


class KeyboardObserverTests: XCTestCase {
    
    var center: NotificationCenter!
    var observer: KeyboardObserver!

    lazy var windowedView: UIView = {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 800))
        let view = UIView(frame: window.bounds)
        window.addSubview(view)
        window.makeKeyAndVisible()
        return view
    }()
    
    override func setUp() {
        super.setUp()
        center = NotificationCenter()
        observer = KeyboardObserver(center: center)
    }

    func test_add() {

        var delegate1: Delegate? = Delegate()
        weak let weakDelegate1 = delegate1

        let delegate2 = Delegate()
        let delegate3 = Delegate()

        // Validate that delegates are only registered once.

        XCTAssertEqual(observer.delegates.count, 0)

        observer.add(delegate: delegate1!)
        XCTAssertEqual(observer.delegates.count, 1)

        observer.add(delegate: delegate1!)
        XCTAssertEqual(observer.delegates.count, 1)

        // Register a second observer

        observer.add(delegate: delegate2)
        XCTAssertEqual(observer.delegates.count, 2)

        // Register a third, but deallocate the first. Should be removed.

        delegate1 = nil

        XCTAssertNil(weakDelegate1)

        observer.add(delegate: delegate3)
        XCTAssertEqual(observer.delegates.count, 2)
    }

    func test_remove() {
        let delegate1: Delegate? = Delegate()

        var delegate2: Delegate? = Delegate()
        weak let weakDelegate2 = delegate2

        let delegate3: Delegate? = Delegate()

        // Register all 3 observers

        observer.add(delegate: delegate1!)
        observer.add(delegate: delegate2!)
        observer.add(delegate: delegate3!)

        XCTAssertEqual(observer.delegates.count, 3)

        // Nil out the second delegate

        delegate2 = nil

        XCTAssertNil(weakDelegate2)

        // Should only have 1 left

        observer.remove(delegate: delegate3!)
        XCTAssertEqual(observer.delegates.count, 1)
    }

    func test_notifications() {
        // Will Change Frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.add(delegate: delegate)

            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: 10.0,
                    y: 10.0,
                    width: 100.0,
                    height: 200.0
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            XCTAssertNil(delegate.lastAnimationDuration)
            XCTAssertNil(delegate.lastAnimationCurve)
            center.post(Notification(
                name: UIWindow.keyboardWillChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
            XCTAssertEqual(delegate.lastAnimationDuration, 2.5)
            XCTAssertEqual(delegate.lastAnimationCurve, UIView.AnimationCurve(rawValue: 123))
        }

        // Did Change Frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.add(delegate: delegate)

            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: 10.0,
                    y: 10.0,
                    width: 100.0,
                    height: 200.0
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
            XCTAssertEqual(delegate.lastAnimationDuration, 2.5)
            XCTAssertEqual(delegate.lastAnimationCurve, UIView.AnimationCurve(rawValue: 123))
        }

        // Only calls delegate for changed frame
        do {
            let observer = KeyboardObserver(center: center)

            let delegate = Delegate()
            observer.add(delegate: delegate)

            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: 10.0,
                    y: 10.0,
                    width: 100.0,
                    height: 200.0
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 0)
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)

            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))
            XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)
        }
    }

    func test_delegate_notifiedForDifferentFrames() {
        let delegate = Delegate()
        observer.add(delegate: delegate)

        let firstUserInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 500, width: 400, height: 300)),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
        ]

        center.post(Notification(
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: UIScreen.main,
            userInfo: firstUserInfo
        ))
        XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 1)

        // Post a different frame — delegate should be notified again.
        let secondUserInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 600, width: 400, height: 200)),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
        ]

        center.post(Notification(
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: UIScreen.main,
            userInfo: secondUserInfo
        ))
        XCTAssertEqual(delegate.keyboardFrameWillChange_callCount, 2)
    }


    func test_isKeyboardFloating() {
        // Did Change Frame with a docked keyboard
        do {
            let observer = KeyboardObserver(center: center)
            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: UIScreen.main.bounds.minX,
                    y: UIScreen.main.bounds.maxY - 500,
                    width: UIScreen.main.bounds.width,
                    height: 500
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))

            // This view has no window, but KeyboardObserver can use
            // the screen provided in the notification.
            XCTAssertFalse(observer.isKeyboardFloating(using: UIView()))
        }

        // Did Change Frame with a floating keyboard
        do {
            let observer = KeyboardObserver(center: center)
            let userInfo: [AnyHashable: Any] = [
                UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                    x: UIScreen.main.bounds.minX,
                    y: UIScreen.main.bounds.maxY - 600,
                    width: 150,
                    height: 500
                )),
                UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
                UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
            ]
            center.post(Notification(
                name: UIWindow.keyboardDidChangeFrameNotification,
                object: UIScreen.main,
                userInfo: userInfo
            ))

            XCTAssertTrue(observer.isKeyboardFloating(using: UIView()))
        }
    }

    func test_isKeyboardFloating_returnsFalse_whenNoNotification() {
        XCTAssertFalse(observer.isKeyboardFloating(using: UIView()))
    }

    func test_currentFrame_returnsNil_whenViewHasNoWindow() {
        // Post a notification so the observer has a frame.
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 500, width: 400, height: 300)),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
        ]
        center.post(Notification(
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: UIScreen.main,
            userInfo: userInfo
        ))

        // A view with no window should return nil.
        let view = UIView()
        XCTAssertNil(view.window)
        XCTAssertNil(observer.currentFrame(in: view))
    }

    func test_currentFrame_returnsNil_whenNoNotificationReceived() {
        // Even with a windowed view, no notification results in a nil KeyboardFrame.
        XCTAssertNil(observer.currentFrame(in: windowedView))
    }

    func test_currentFrame_returnsNonOverlapping_whenKeyboardDoesNotIntersect() {
        // Post a keyboard frame that is entirely below the view.
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(x: 0, y: 900, width: 400, height: 300)),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
        ]
        center.post(Notification(
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: UIScreen.main,
            userInfo: userInfo
        ))

        XCTAssertEqual(observer.currentFrame(in: windowedView), .nonOverlapping)
    }

    func test_currentFrame_returnsOverlapping_whenKeyboardIntersectsView() {
        // Post a keyboard frame that overlaps the view.
        let keyboardFrame = CGRect(x: 0, y: 500, width: 400, height: 300)
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
        ]
        center.post(Notification(
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: UIScreen.main,
            userInfo: userInfo
        ))

        let result = observer.currentFrame(in: windowedView)
        if case .overlapping(let frame) = result {
            XCTAssertEqual(frame, keyboardFrame)
        } else {
            XCTFail("Expected .overlapping, got \(String(describing: result))")
        }
    }

    func test_currentFrame_returnsOverlapping_whenKeyboardPartiallyOverlapsView() {
        // Post a keyboard frame that starts inside the view but extends beyond its bottom edge.
        let keyboardFrame = CGRect(x: 0, y: 500, width: 400, height: 600)
        let userInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: keyboardFrame),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 0.25),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 7),
        ]
        center.post(Notification(
            name: UIWindow.keyboardDidChangeFrameNotification,
            object: UIScreen.main,
            userInfo: userInfo
        ))

        let result = observer.currentFrame(in: windowedView)
        if case .overlapping(let frame) = result {
            XCTAssertEqual(frame, keyboardFrame)
        } else {
            XCTFail("Expected .overlapping, got \(String(describing: result))")
        }
    }

    final class Delegate: KeyboardObserverDelegate {

        var keyboardFrameWillChange_callCount: Int = 0
        var lastAnimationDuration: Double?
        var lastAnimationCurve: UIView.AnimationCurve?

        func keyboardFrameWillChange(
            for observer: KeyboardObserver,
            animationDuration: Double,
            animationCurve: UIView.AnimationCurve
        ) {

            keyboardFrameWillChange_callCount += 1
            lastAnimationDuration = animationDuration
            lastAnimationCurve = animationCurve
        }
    }
}


class KeyboardObserver_NotificationInfo_Tests: XCTestCase {

    func test_init() {

        let defaultUserInfo: [AnyHashable: Any] = [
            UIResponder.keyboardFrameEndUserInfoKey: NSValue(cgRect: CGRect(
                x: 10.0,
                y: 10.0,
                width: 100.0,
                height: 200.0
            )),
            UIResponder.keyboardAnimationDurationUserInfoKey: NSNumber(value: 2.5),
            UIResponder.keyboardAnimationCurveUserInfoKey: NSNumber(value: 123),
        ]

        // Successful Init
        do {
            let info = try! KeyboardObserver.NotificationInfo(
                with: Notification(
                    name: UIResponder.keyboardDidShowNotification,
                    object: UIScreen.main,
                    userInfo: defaultUserInfo
                )
            )

            XCTAssertEqual(info.endingFrame, CGRect(x: 10.0, y: 10.0, width: 100.0, height: 200.0))
            XCTAssertEqual(info.animationDuration, 2.5)
            XCTAssertEqual(info.animationCurve, UIView.AnimationCurve(rawValue: 123)!)
            XCTAssertEqual(info.screen, UIScreen.main)
        }

        // Screen is nil when notification object is not a UIScreen.
        do {
            let info = try! KeyboardObserver.NotificationInfo(
                with: Notification(
                    name: UIResponder.keyboardDidShowNotification,
                    object: nil,
                    userInfo: defaultUserInfo
                )
            )
            XCTAssertNil(info.screen)
        }

        // Failed Inits
        do {
            // No userInfo
            do {
                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: nil
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingUserInfo)
                }
            }

            // No end frame
            do {
                var userInfo = defaultUserInfo
                userInfo.removeValue(forKey: UIResponder.keyboardFrameEndUserInfoKey)

                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: userInfo
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingEndingFrame)
                }
            }

            // No animation duration
            do {
                var userInfo = defaultUserInfo
                userInfo.removeValue(forKey: UIResponder.keyboardAnimationDurationUserInfoKey)

                XCTAssertThrowsError(
                    try _ = KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: userInfo
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingAnimationDuration)
                }
            }

            // No animation curve
            do {
                var userInfo = defaultUserInfo
                userInfo.removeValue(forKey: UIResponder.keyboardAnimationCurveUserInfoKey)

                XCTAssertThrowsError(
                    try KeyboardObserver.NotificationInfo(
                        with: Notification(
                            name: UIResponder.keyboardDidShowNotification,
                            object: UIScreen.main,
                            userInfo: userInfo
                        )
                    )
                ) { error in
                    XCTAssertEqual(error as? KeyboardObserver.NotificationInfo.ParseError, .missingAnimationCurve)
                }
            }
        }
    }
}
