import Foundation
import UIKit
import GameController

// This class is a coordinator (and module entrance), coordinating other concrete classes

@objc class PlayInput: NSObject {
    @objc static let shared = PlayInput()

    static var touchQueue = DispatchQueue.init(label: "playcover.toucher",
                                               qos: .userInteractive,
                                               autoreleaseFrequency: .workItem)

    var shouldProcessMouseClick: Bool {
        !disbleMouseClickWhenNotFocused && !disableMouseClickInCertainViews
    }

    private var disbleMouseClickWhenNotFocused = false

    @objc var disableMouseClickInCertainViews = false

    @objc func drainMainDispatchQueue() {
        _dispatch_main_queue_callback_4CF(nil)
    }

    func initialize() {
        // drain the dispatch queue every frame for responding to GCController events
        let displaylink = CADisplayLink(target: self, selector: #selector(drainMainDispatchQueue))
        displaylink.add(to: .main, forMode: .common)

        if PlaySettings.shared.disableBuiltinMouse {
            simulateGCMouseDisconnect()
        }

        if PlaySettings.shared.disableBuiltinKeyboard {
            disableBuiltinKeyboard()
        }

        if PlaySettings.shared.enhanceBuiltinMouse {
            EnhancedBuiltinMouseSupport.shared.initialize()
        }

        if PlaySettings.shared.supportMultipleMice {
            MultipleMiceSupport.shared.initialize()
        }

        if !PlaySettings.shared.keymapping {
            return
        }

        let centre = NotificationCenter.default
        let main = OperationQueue.main

        centre.addObserver(forName: NSNotification.Name(rawValue: "NSWindowDidBecomeKeyNotification"), object: nil,
            queue: main) { _ in
            if PlaySettings.shared.ignoreClicksWhenNotFocused {
                self.disbleMouseClickWhenNotFocused = false
            }
            if mode.cursorHidden() {
                AKInterface.shared!.warpCursor()
            }
        }

        centre.addObserver(forName: NSNotification.Name(rawValue: "NSWindowDidResignKeyNotification"), object: nil,
            queue: main) { _ in
            if PlaySettings.shared.ignoreClicksWhenNotFocused {
                self.disbleMouseClickWhenNotFocused = true
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 5, qos: .utility) {
            if mode.cursorHidden() || !ActionDispatcher.cursorHideNecessary {
                return
            }
            Toast.initialize()
        }
        mode.initialize()
    }

    private func disableBuiltinKeyboard() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = nil
        }

        NotificationCenter.default.addObserver(
            forName: .GCKeyboardDidConnect,
            object: nil,
            queue: .main
        ) { nofitication in
            guard let keyboard = nofitication.object as? GCKeyboard else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                keyboard.keyboardInput?.keyChangedHandler = nil
            }
        }
    }

    private func simulateGCMouseDisconnect() {
        NotificationCenter.default.addObserver(
            forName: .GCMouseDidConnect,
            object: nil,
            queue: .main
        ) { nofitication in
            guard let mouse = nofitication.object as? GCMouse else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                NotificationCenter.default.post(name: .GCMouseDidDisconnect, object: mouse)
                mouse.mouseInput?.leftButton.pressedChangedHandler = nil
                mouse.mouseInput?.leftButton.valueChangedHandler = nil
                mouse.mouseInput?.rightButton?.pressedChangedHandler = nil
                mouse.mouseInput?.rightButton?.valueChangedHandler = nil
                mouse.mouseInput?.middleButton?.pressedChangedHandler = nil
                mouse.mouseInput?.middleButton?.valueChangedHandler = nil
                mouse.mouseInput?.auxiliaryButtons?.forEach { button in
                    button.pressedChangedHandler = nil
                    button.valueChangedHandler = nil
                }
                mouse.mouseInput?.scroll.valueChangedHandler = nil
                mouse.mouseInput?.mouseMovedHandler = nil
            }
        }
    }
}

class EnhancedBuiltinMouseSupport {
    static let shared = EnhancedBuiltinMouseSupport()
    private var timer: DispatchSourceTimer?

    func initialize() {
        // Always use the Option key to hide the cursor
        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: 0.1)
        timer.setEventHandler {
            ActionDispatcher.cursorHideNecessary = true
        }
        timer.resume()
        self.timer = timer

        // Forward mouse events to the app only when the cursor is hidden
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            if let mouse = GCMouse.current {
                self.wrapMouseEventHandlers(mouse)
            }

            NotificationCenter.default.addObserver(
                forName: .GCMouseDidConnect,
                object: nil,
                queue: .main
            ) { nofitication in
                if let mouse = nofitication.object as? GCMouse {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                        self.wrapMouseEventHandlers(mouse)
                    }
                }
            }
        }
    }

    private func wrapMouseEventHandlers(_ currentMouse: GCMouse) {
        let leftButtonHandler = currentMouse.mouseInput?.leftButton.pressedChangedHandler
        let rightButtonHandler = currentMouse.mouseInput?.rightButton?.pressedChangedHandler
        let middleButtonHandler = currentMouse.mouseInput?.middleButton?.pressedChangedHandler
        let mouseMovedHandler = currentMouse.mouseInput?.mouseMovedHandler
        let scrollWheelHandler = currentMouse.mouseInput?.scroll.valueChangedHandler

        for mouse in GCMouse.mice() {
            mouse.mouseInput?.leftButton.pressedChangedHandler = { button, value, pressed in
                if ControlMode.mode.cursorHidden() {
                    leftButtonHandler?(button, value, pressed)
                }
            }

            mouse.mouseInput?.rightButton?.pressedChangedHandler = { button, value, pressed in
                if ControlMode.mode.cursorHidden() {
                    rightButtonHandler?(button, value, pressed)
                }
            }

            mouse.mouseInput?.middleButton?.pressedChangedHandler = { button, value, pressed in
                if ControlMode.mode.cursorHidden() {
                    middleButtonHandler?(button, value, pressed)
                }
            }

            mouse.mouseInput?.mouseMovedHandler = { mouse, deltaX, deltaY in
                if ControlMode.mode.cursorHidden() {
                    mouseMovedHandler?(mouse, deltaX, deltaY)
                }
            }

            mouse.mouseInput?.scroll.valueChangedHandler = scrollWheelHandler
        }
    }
}

class MultipleMiceSupport {
    static let shared = MultipleMiceSupport()

    func initialize() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5)) {
            if let mouse = GCMouse.current {
                self.wrapMouseEventHandlers(mouse)
            }

            NotificationCenter.default.addObserver(
                forName: .GCMouseDidConnect,
                object: nil,
                queue: .main
            ) { nofitication in
                if let mouse = nofitication.object as? GCMouse {
                    DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                        self.wrapMouseEventHandlers(mouse)
                    }
                }
            }
        }
    }

    private func wrapMouseEventHandlers(_ currentMouse: GCMouse) {
        let leftButtonHandler = currentMouse.mouseInput?.leftButton.pressedChangedHandler
        let rightButtonHandler = currentMouse.mouseInput?.rightButton?.pressedChangedHandler
        let middleButtonHandler = currentMouse.mouseInput?.middleButton?.pressedChangedHandler
        let mouseMovedHandler = currentMouse.mouseInput?.mouseMovedHandler
        let scrollWheelHandler = currentMouse.mouseInput?.scroll.valueChangedHandler

        for mouse in GCMouse.mice() {
            mouse.mouseInput?.leftButton.pressedChangedHandler = { button, value, pressed in
                leftButtonHandler?(button, value, pressed)
            }

            mouse.mouseInput?.rightButton?.pressedChangedHandler = { button, value, pressed in
                rightButtonHandler?(button, value, pressed)
            }

            mouse.mouseInput?.middleButton?.pressedChangedHandler = { button, value, pressed in
                middleButtonHandler?(button, value, pressed)
            }

            mouse.mouseInput?.mouseMovedHandler = { mouse, deltaX, deltaY in
                mouseMovedHandler?(mouse, deltaX, deltaY)
            }

            mouse.mouseInput?.scroll.valueChangedHandler = scrollWheelHandler
        }
    }
}

@objc class UnityEngineKeyboardSupport: NSObject {
    @objc static let shared = UnityEngineKeyboardSupport()
    private var unityView: UIView?
    @objc var isIntialized = false
    @objc var isActive = false

    @objc func initialize(_ unityView: UIView) {
        self.isIntialized = true

        if !PlaySettings.shared.keymapping {
            return
        }

        if unityView.responds(to: NSSelectorFromString("handleCommand:")) {
            self.unityView = unityView
            self.isActive = true
        }
    }

    func sendEvent(key: String, pressed: Bool) -> Bool {
        guard self.isActive else {
            return false
        }
        guard let unityView = self.unityView else {
            return false
        }
        guard let keyCommand = buildUIKeyCommand(key: key) else {
            return false
        }

        // The following code is tightly related to UnityView+Keyboard.mm.
        // It's an ugly workaround, but the only way to fix the keyboard lag issue.
        if pressed {
            // Force Unity to remeber the press time as (RealTime + 100000000),
            // so [UnityView processKeyboard] will not fire the KeyUp event
            pt_set_time_delta(100000000)
            unityView.perform(NSSelectorFromString("handleCommand:"), with: keyCommand)
            pt_set_time_delta(0)
        } else {
            // Force Unity to update the press time to (RealTime - 1),
            // then [UnityView processKeyboard] will fire the KeyUp event immediately (elapsed > 0.5s)
            pt_set_time_delta(-1)
            unityView.perform(NSSelectorFromString("handleCommand:"), with: keyCommand)
            pt_set_time_delta(0)
        }
        return true
    }

    private func buildUIKeyCommand(key: String) -> UIKeyCommand? {
        if key == "Btn" {
            return nil
        }

        if let modifierFlags = UnityEngineKeyboardSupport.keyToModifierFlags[key] {
            return UIKeyCommand(input: "", modifierFlags: modifierFlags, action: #selector(doNothing))
        }

        let input = UnityEngineKeyboardSupport.keyToCommandInput[key] ?? key.lowercased()
        return UIKeyCommand(input: input, modifierFlags: UIKeyModifierFlags(rawValue: 0), action: #selector(doNothing))
    }

    @objc private func doNothing() {}

    private static let keyToCommandInput: [String: String] = [
        "Spc": " ",
        "Tab": "\t",
        "Enter": "\r",
        "Del": UIKeyCommand.inputDelete,
        "Page Up": UIKeyCommand.inputPageUp,
        "Page Down": UIKeyCommand.inputPageDown,
        "Up": UIKeyCommand.inputUpArrow,
        "Down": UIKeyCommand.inputDownArrow,
        "Left": UIKeyCommand.inputLeftArrow,
        "Right": UIKeyCommand.inputRightArrow,
        "Esc": UIKeyCommand.inputEscape,
        "Home": UIKeyCommand.inputHome,
        "End": UIKeyCommand.inputEnd,
        "F1": UIKeyCommand.f1,
        "F2": UIKeyCommand.f2,
        "F3": UIKeyCommand.f3,
        "F4": UIKeyCommand.f4,
        "F5": UIKeyCommand.f5,
        "F6": UIKeyCommand.f6,
        "F7": UIKeyCommand.f7,
        "F8": UIKeyCommand.f8,
        "F9": UIKeyCommand.f9,
        "F10": UIKeyCommand.f10,
        "F11": UIKeyCommand.f11,
        "F12": UIKeyCommand.f12
    ]

    private static let keyToModifierFlags: [String: UIKeyModifierFlags] = [
        "Caps": .alphaShift,
        "Lshft": .shift,
        "Rshft": .shift,
        "LCtrl": .control,
        "RCtrl": .control,
        "LOpt": .alternate,
        "ROpt": .alternate,
        "LCmd": .command,
        "RCmd": .command
    ]
}

extension UIResponder {
    private static weak var _currentFirstResponder: UIResponder?

    @objc private func _captureFirstResponder(_ sender: Any?) {
        UIResponder._currentFirstResponder = self
    }

    static func currentFirstResponder() -> UIResponder? {
        UIResponder._currentFirstResponder = nil

        UIApplication.shared.sendAction(
            #selector(_captureFirstResponder(_:)),
            to: nil,
            from: nil,
            for: nil
        )

        return UIResponder._currentFirstResponder
    }
}

extension UIView {
    func findKeyInput() -> UIKeyInput? {
        if let input = self as? UIKeyInput {
            return input
        }
        for subview in subviews {
            if let found = subview.findKeyInput() {
                return found
            }
        }
        return nil
    }
}
