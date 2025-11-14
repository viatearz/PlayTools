//
//  DestinyRisingSupport.swift
//  PlayTools
//

import GameController

class DestinyRisingSupport: AppSupport {
    public static var pointerLocked = false

    required init() {
        PlaySettings.shared.keymapping = false
    }

    override func applyHooks() {
        self.swizzleInstanceMethod(
            cls: NSClassFromString("IOSViewController"),
            origSelector: NSSelectorFromString("setPointerLockState:"),
            newSelector: #selector(NSObject.hook_DestinyRising_setPointerLockState(_:)))
    }
}

extension NSObject {
    @objc func hook_DestinyRising_setPointerLockState(_ locked: Bool) {
        if DestinyRisingSupport.pointerLocked != locked {
            DestinyRisingSupport.pointerLocked = locked
            if locked {
                AKInterface.shared?.hideCursor()
            } else {
                AKInterface.shared?.unhideCursor()
            }
        }
    }
}
