//
//  GamepadToKeyEditorControllerEventAdapter.swift
//  PlayTools
//

import GameController

public class GamepadToKeyEditorControllerEventAdapter: ControllerEventAdapter {
    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        var alias: String?
        if let dpad = element as? GCControllerDirectionPad {
            alias = getDirectionPadAlias(dpad)
        } else {
            alias = element.aliases.first
        }
        if let alias = alias {
            GamepadToKeyEditorController.shared.setGamepadKey(alias)
        }
    }

    private func getDirectionPadAlias(_ dpad: GCControllerDirectionPad) -> String? {
        let deltaX = dpad.xAxis.value
        let deltaY = dpad.yAxis.value
        if abs(deltaX) > 0 || abs(deltaY) > 0 {
            if abs(deltaX) > abs(deltaY) {
                return deltaX < 0 ? dpad.left.aliases.first : dpad.right.aliases.first
            } else {
                return deltaY > 0 ? dpad.up.aliases.first : dpad.down.aliases.first
            }
        }
        return nil
    }
}
