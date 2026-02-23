import Foundation
import UIKit
import GameController

// This class is a coordinator (and module entrance), coordinating other concrete classes

class PlayInput {
    static let shared = PlayInput()

    static var touchQueue = DispatchQueue.init(label: "playcover.toucher",
                                               qos: .userInteractive,
                                               autoreleaseFrequency: .workItem)

    var shouldProcessMouseClick = true

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

        if PlaySettings.shared.enhanceBuiltinMouse {
            EnhancedBuiltinMouseSupport.shared.initialize()
        }

        if !PlaySettings.shared.keymapping {
            return
        }

        let centre = NotificationCenter.default
        let main = OperationQueue.main

        centre.addObserver(forName: NSNotification.Name(rawValue: "NSWindowDidBecomeKeyNotification"), object: nil,
            queue: main) { _ in
            if PlaySettings.shared.ignoreClicksWhenNotFocused {
                self.shouldProcessMouseClick = true
            }
            if mode.cursorHidden() {
                AKInterface.shared!.warpCursor()
            }
        }

        centre.addObserver(forName: NSNotification.Name(rawValue: "NSWindowDidResignKeyNotification"), object: nil,
            queue: main) { _ in
            if PlaySettings.shared.ignoreClicksWhenNotFocused {
                self.shouldProcessMouseClick = false
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
