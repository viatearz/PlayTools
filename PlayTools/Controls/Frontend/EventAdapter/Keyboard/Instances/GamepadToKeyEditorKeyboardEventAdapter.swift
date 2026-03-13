//
//  GamepadToKeyEditorKeyboardEventAdapter.swift
//  PlayTools
//

import GameController

public class GamepadToKeyEditorKeyboardEventAdapter: KeyboardEventAdapter {
    public func handleKey(keycode: UInt16, pressed: Bool, isRepeat: Bool, ctrlModified: Bool) -> Bool {
        if !pressed || isRepeat {
            return false
        }
        if let name = KeyCodeNames.virtualCodes[keycode] {
            GamepadToKeyEditorController.shared.setTargetKey(name)
            return true
        }
        return false
    }
}
