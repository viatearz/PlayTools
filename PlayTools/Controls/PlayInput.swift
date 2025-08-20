import Foundation
import UIKit
import GameController

// This class is a coordinator (and module entrance), coordinating other concrete classes

@objc class PlayInput: NSObject {
    @objc static let shared = PlayInput()

    static var touchQueue = DispatchQueue.init(label: "playcover.toucher",
                                               qos: .userInteractive,
                                               autoreleaseFrequency: .workItem)

    @objc func drainMainDispatchQueue() {
        _dispatch_main_queue_callback_4CF(nil)
    }

    func initialize() {
        // drain the dispatch queue every frame for responding to GCController events
        let displaylink = CADisplayLink(target: self, selector: #selector(drainMainDispatchQueue))
        displaylink.add(to: .main, forMode: .common)

        if !PlaySettings.shared.keymapping {
            return
        }

        let centre = NotificationCenter.default
        let main = OperationQueue.main

        centre.addObserver(forName: NSNotification.Name(rawValue: "NSWindowDidBecomeKeyNotification"), object: nil,
            queue: main) { _ in
            if mode.cursorHidden() {
                AKInterface.shared!.warpCursor()
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

    func disableBuiltinMouse() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.GCMouseDidConnect,
            object: nil,
            queue: .main
        ) { nofitication in
            guard let mouse = nofitication.object as? GCMouse else {
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                NotificationCenter.default.post(name: NSNotification.Name.GCMouseDidDisconnect, object: mouse)
                mouse.mouseInput?.leftButton.pressedChangedHandler = nil
                mouse.mouseInput?.middleButton?.pressedChangedHandler = nil
                mouse.mouseInput?.rightButton?.pressedChangedHandler = nil
                mouse.mouseInput?.mouseMovedHandler = nil
                mouse.mouseInput?.scroll.valueChangedHandler = nil
                mouse.mouseInput?.auxiliaryButtons?.forEach { button in
                    button.pressedChangedHandler = nil
                }
            }
        }
    }

    private var unityView: UIView?
    private var unityViewInitialized = false

    @objc func shouldDisableUnityKeyCommands(_ view: UIView) -> Bool {
        if !self.unityViewInitialized {
            self.unityViewInitialized = true
            if view.responds(to: NSSelectorFromString("handleCommand:")) {
                self.unityView = view
            } else {
                self.unityView = nil
            }
        }
        return self.unityView != nil
    }

    func sendKeyEventToUnity(key: String, pressed: Bool) -> Bool {
        guard let unityView = self.unityView else {
            return false
        }
        guard let keyCommand = buildUIKeyCommand(key: key) else {
            return false
        }

        // The following code is tightly related to UnityView+Keyboard.mm.
        // It's an ugly workaround, but the only way to fix the keyboard lag issue.
        if pressed {
            // Force Unity to remember the press time as (RealTime + 100000000),
            // so [UnityView processKeyboard] will not fire the KeyUp event
            settimedelta(100000000)
            unityView.perform(NSSelectorFromString("handleCommand:"), with: keyCommand)
            settimedelta(0)
        } else {
            // Force Unity to update the press time to (RealTime - 1),
            // then [UnityView processKeyboard] will fire the KeyUp event immediately (elapsed > 0.5s)
            settimedelta(-1)
            unityView.perform(NSSelectorFromString("handleCommand:"), with: keyCommand)
            settimedelta(0)
        }
        return true
    }

    private func buildUIKeyCommand(key: String) -> UIKeyCommand? {
        if key == "Btn" {
            return nil
        }

        if let modifierFlags = PlayInput.keyToModifierFlags[key] {
            return UIKeyCommand(input: "", modifierFlags: modifierFlags, action: #selector(doNothing))
        }

        let input = PlayInput.keyToCommandInput[key] ?? key.lowercased()
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
