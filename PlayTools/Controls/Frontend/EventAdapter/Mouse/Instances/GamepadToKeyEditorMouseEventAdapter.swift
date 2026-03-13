//
//  GamepadToKeyEditorMouseEventAdapter.swift
//  PlayTools
//

public class GamepadToKeyEditorMouseEventAdapter: MouseEventAdapter {
    public func handleOtherButton(id: Int, pressed: Bool) -> Bool {
        if pressed {
            let name = EditorMouseEventAdapter.getMouseButtonName(id)
            // asynced to return quickly. Editor contains UI operation so main queue.
            // main queue is fine. should not be slower than keyboard
            DispatchQueue.main.async(qos: .userInteractive, execute: {
                GamepadToKeyEditorController.shared.setTargetKey(name)
            })
        }
        return true
    }

    public func handleScrollWheel(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleMove(deltaX: CGFloat, deltaY: CGFloat) -> Bool {
        false
    }

    public func handleLeftButton(pressed: Bool) -> Bool {
        // Event flows to EditorController via UIKit
        false
    }

    public func cursorHidden() -> Bool {
        false
    }
}
