//
//  DestinyRisingSupport.swift
//  PlayTools
//

import GameController

class DestinyRisingSupport: AppSupport {
    required init() {
        PlaySettings.shared.keymapping = false
    }

    override func applyHooks() {
        self.swizzleInstanceMethod(
            cls: NSClassFromString("IOSViewController"),
            origSelector: NSSelectorFromString("setPointerLockState:"),
            newSelector: #selector(NSObject.hook_DestinyRising_setPointerLockState(_:)))

        self.swizzleInstanceMethod(
            cls: NSClassFromString("MetalView"),
            origSelector: NSSelectorFromString("HandleTouches:ofType:"),
            newSelector: #selector(NSObject.hook_DestinyRising_HandleTouches(_:ofType:)))

        self.swizzleInstanceMethod(
            cls: NSClassFromString("InputDeviceManagerProxy"),
            origSelector: NSSelectorFromString("registerMouseCallbacks:"),
            newSelector: #selector(NSObject.hook_DestinyRising_registerMouseCallbacks(_:)))

        self.swizzleInstanceMethod(
            cls: NSClassFromString("InputDeviceManagerProxy"),
            origSelector: NSSelectorFromString("onKeyboardConnect:"),
            newSelector: #selector(NSObject.hook_DestinyRising_onKeyboardConnect(_:)))
    }
}

extension NSObject {
    @objc func hook_DestinyRising_setPointerLockState(_ locked: Bool) {
        DestinyRisingController.shared.requestSetPointerLockState(locked)
    }

    @objc func hook_DestinyRising_HandleTouches(_ touches: NSArray, ofType type: Int32) {
        if DestinyRisingController.shared.isTouchMode {
            self.hook_DestinyRising_HandleTouches(touches, ofType: type)
        }
    }

    @objc func hook_DestinyRising_registerMouseCallbacks(_ mouse: GCMouse) {
        self.hook_DestinyRising_registerMouseCallbacks(mouse)
        DestinyRisingController.shared.didRegisterMouseCallbacks(mouse)
    }

    @objc func hook_DestinyRising_onKeyboardConnect(_ arg: AnyObject) {
        self.hook_DestinyRising_onKeyboardConnect(arg)
        DestinyRisingController.shared.didRegisterKeyboardCallbacks()
    }
}

class DestinyRisingController {
    enum InputMode: Int {
        case touch
        case mouse
    }

    public static let shared = DestinyRisingController()
    private var inputMode = InputMode.touch
    private var mouseX: Float = 0
    private var mouseY: Float = 0
    private var lastPressedKey = GCKeyCode.escape
    private var touchId: Int?
    private var cmdPressed = false
    private var originalLeftButtonHandler: GCControllerButtonValueChangedHandler?
    private var originalKeyboardHandler: GCKeyboardValueChangedHandler?

    public var isTouchMode: Bool {
        return inputMode == .touch
    }

    public var isMouseMode: Bool {
        return inputMode == .mouse
    }

    public func requestSetPointerLockState(_ locked: Bool) {
        setInputMode(locked ? .mouse : .touch)
    }

    public func didRegisterMouseCallbacks(_ mouse: GCMouse) {
        if let originalMouseMovedHandler = mouse.mouseInput?.mouseMovedHandler {
            mouse.mouseInput?.mouseMovedHandler = { (mouse, deltaX, deltaY) in
                self.mouseX += deltaX
                self.mouseY -= deltaY
                if self.isMouseMode {
                    originalMouseMovedHandler(mouse, self.mouseX, self.mouseY)
                }
            }
        }
        if let originalLeftButtonHandler = mouse.mouseInput?.leftButton.valueChangedHandler {
            self.originalLeftButtonHandler = originalLeftButtonHandler
            mouse.mouseInput?.leftButton.valueChangedHandler = { (button, value, pressed) in
                if self.isMouseMode {
                    originalLeftButtonHandler(button, value, pressed)
                }
            }
        }
        if let originalRightButtonHandler = mouse.mouseInput?.rightButton?.valueChangedHandler {
            mouse.mouseInput?.rightButton?.valueChangedHandler = { (button, value, pressed) in
                if self.isMouseMode {
                    originalRightButtonHandler(button, value, pressed)
                }
            }
        }
        if let originalMiddleButtonHandler = mouse.mouseInput?.middleButton?.valueChangedHandler {
            mouse.mouseInput?.middleButton?.valueChangedHandler = { (button, value, pressed) in
                if self.isMouseMode {
                    originalMiddleButtonHandler(button, value, pressed)
                }
            }
        }
        if let originalScrollHandler = mouse.mouseInput?.scroll.valueChangedHandler {
            mouse.mouseInput?.scroll.valueChangedHandler = { (dpad, xValue, yValue) in
                if self.isMouseMode {
                    originalScrollHandler(dpad, xValue, yValue)
                }
            }
        }
    }

    public func didRegisterKeyboardCallbacks() {
        if let originalKeyboardHandler = GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler {
            self.originalKeyboardHandler = originalKeyboardHandler
            GCKeyboard.coalesced?.keyboardInput?.keyChangedHandler = { (keyboard, key, keyCode, pressed) in
                if keyCode == .leftGUI || keyCode == .rightGUI {
                    self.cmdPressed = pressed
                }
                if pressed {
                    self.lastPressedKey = keyCode
                    if keyCode == .leftAlt || keyCode == .rightAlt {
                        self.setInputMode(self.isTouchMode ? .mouse : .touch)
                        return
                    }
                    if keyCode == .escape && self.isTouchMode {
                        self.exitTouchModeAndSendEscKey()
                        return
                    }
                }
                originalKeyboardHandler(keyboard, key, keyCode, pressed)
            }
        }
    }

    private func setInputMode(_ newInputMode: InputMode) {
        guard inputMode != newInputMode else {
            return
        }

        inputMode = newInputMode

        if isTouchMode {
            AKInterface.shared?.unhideCursor()
            if !cmdPressed && shouldSimulateTouchEvent() {
                // Simulate a touch event to trigger the game to switch into touchscreen mode
                let point = CGPoint.zero
                Toucher.touchcam(point: point, phase: .began, tid: &self.touchId,
                                 actionName: "FakeTouch", keyName: "FakeTouch")
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
                    Toucher.touchcam(point: point, phase: .ended, tid: &self.touchId,
                                     actionName: "FakeTouch", keyName: "FakeTouch")
                }
            }
        } else {
            AKInterface.shared?.hideCursor()
            if !cmdPressed {
                // Simulate a mouse click event to trigger the game to switch into keyboard-and-mouse mode
                if let button = GCMouse.current?.mouseInput?.leftButton {
                    originalLeftButtonHandler?(button, /*value*/0, /*pressed*/false)
                }
            }
        }
    }

    private func shouldSimulateTouchEvent() -> Bool {
        return lastPressedKey != .four && lastPressedKey != .keyO
    }

    private func exitTouchModeAndSendEscKey() {
        if let button = GCMouse.current?.mouseInput?.leftButton {
            originalLeftButtonHandler?(button, /*value*/0, /*pressed*/false)
        }
        if let keyboardInput = GCKeyboard.coalesced?.keyboardInput,
           let key = keyboardInput.button(forKeyCode: .escape) {
            originalKeyboardHandler?(keyboardInput, key, .escape, /*pressed*/true)
        }
    }
}
