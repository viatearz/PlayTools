//
//  VirtualCursorControllerEventAdapter.swift
//  PlayTools
//
//  Created by viatearz on 2025/2/10.
//

import Foundation
import GameController
import UIKit

// Controls/Frontend/EventAdapter/Controller/Instances/VirtualCursorControllerEventAdapter.swift
public class VirtualCursorControllerEventAdapter: ControllerEventAdapter {
    let padding = VirtualCursorController.shared.cursorSize / 2
    var speedRate = 1.0

    public func handleValueChanged(_ profile: GCExtendedGamepad, _ element: GCControllerElement) {
        let name: String = element.aliases.first!
        if let buttonElement = element as? GCControllerButtonInput {
            handleButtons(name, buttonElement)
        } else if let dpadElement = element as? GCControllerDirectionPad {
            if name == GCInputDirectionPad {
                handleDirectionPad(dpadElement)
            } else {
                handleThumbsticks(dpadElement)
            }
        }
    }

    private func handleButtons(_ name: String, _ buttonElement: GCControllerButtonInput) {
        if name == GCInputLeftThumbstickButton {
            // quit virtual cursor mode
            if buttonElement.isPressed {
                ModeAutomaton.onPressLeftThumbstick()
            }
            return
        }

        if name == GCInputButtonA || name == GCInputButtonB {
            // simulating mouse click
            VirtualCursorController.shared.handlePress(pressed: buttonElement.isPressed)
            return
        }

        if name == GCInputButtonY {
            // speed up
            speedRate = buttonElement.isPressed ? 2.0 : 1.0
            return
        }

        if name == GCInputButtonX {
            // speed down
            speedRate = buttonElement.isPressed ? 0.3 : 1.0
            return
        }

        if buttonElement.isPressed {
            if name == GCInputLeftShoulder {
                // top left
                VirtualCursorController.shared.setCursorPos(CGPoint(
                    x: screen.screenRect.minX + padding, y: screen.screenRect.minY + padding))
            } else if name == GCInputLeftTrigger {
                // bottom left
                VirtualCursorController.shared.setCursorPos(CGPoint(
                    x: screen.screenRect.minX + padding, y: screen.screenRect.maxY - padding))
            } else if name == GCInputRightShoulder {
                // top right
                VirtualCursorController.shared.setCursorPos(CGPoint(
                    x: screen.screenRect.maxX - padding, y: screen.screenRect.minY + padding))
            } else if name == GCInputRightTrigger {
                // bottom right
                VirtualCursorController.shared.setCursorPos(CGPoint(
                    x: screen.screenRect.maxX - padding, y: screen.screenRect.maxY - padding))
            } else if name == GCInputButtonShare {
                // center
                VirtualCursorController.shared.setCursorPos(CGPoint(
                    x: screen.screenRect.midX, y: screen.screenRect.midY))
            }
        }
    }

    private func handleDirectionPad(_ dpadElement: GCControllerDirectionPad) {
        if dpadElement.xAxis.value < 0 {
            // left
            VirtualCursorController.shared.setCursorPos(CGPoint(
                x: screen.screenRect.minX + padding, y: screen.screenRect.midY))
        } else if dpadElement.xAxis.value > 0 {
            // right
            VirtualCursorController.shared.setCursorPos(CGPoint(
                x: screen.screenRect.maxX - padding, y: screen.screenRect.midY))
        } else if dpadElement.yAxis.value > 0 {
            // top
            VirtualCursorController.shared.setCursorPos(CGPoint(
                x: screen.screenRect.midX, y: screen.screenRect.minY + padding))
        } else if dpadElement.yAxis.value < 0 {
            // bottom
            VirtualCursorController.shared.setCursorPos(CGPoint(
                x: screen.screenRect.midX, y: screen.screenRect.maxY - padding))
        }
    }

    private func handleThumbsticks(_ dpadElement: GCControllerDirectionPad) {
        // move cursor by thumbsticks
        let velocityX = CGFloat(dpadElement.xAxis.value) * speedRate
        let velocityY = CGFloat(dpadElement.yAxis.value) * speedRate
        VirtualCursorController.shared.setVelocity(velocityX: velocityX, velocityY: velocityY)
    }
}

// Controls/Frontend/ModeAutomaton.swift
extension ModeAutomaton {
    static public func onPressLeftThumbstick() -> Bool {
        if !VirtualCursorController.shared.enabled {
            return false
        }
        if mode == .arbitraryClick {
            VirtualCursorController.shared.showCursor()
            mode.set(.virtualCursor)
            return true
        } else if mode == .virtualCursor {
            VirtualCursorController.shared.hideCursor()
            mode.set(.arbitraryClick)
            return true
        }
        return false
    }
}

// Controls/VirtualCursor.swift
class VirtualCursorController {
    // swiftlint:disable line_length
    let imageBase64 = "iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAACXBIWXMAAAsTAAALEwEAmpwYAAAF0WlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgOS4wLWMwMDAgNzkuMTcxYzI3ZmFiLCAyMDIyLzA4LzE2LTIyOjM1OjQxICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOmRjPSJodHRwOi8vcHVybC5vcmcvZGMvZWxlbWVudHMvMS4xLyIgeG1sbnM6cGhvdG9zaG9wPSJodHRwOi8vbnMuYWRvYmUuY29tL3Bob3Rvc2hvcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RFdnQ9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZUV2ZW50IyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgMjQuMCAoTWFjaW50b3NoKSIgeG1wOkNyZWF0ZURhdGU9IjIwMjQtMDktMTNUMjE6MTA6MTArMDg6MDAiIHhtcDpNb2RpZnlEYXRlPSIyMDI0LTA5LTEzVDIxOjE1OjI0KzA4OjAwIiB4bXA6TWV0YWRhdGFEYXRlPSIyMDI0LTA5LTEzVDIxOjE1OjI0KzA4OjAwIiBkYzpmb3JtYXQ9ImltYWdlL3BuZyIgcGhvdG9zaG9wOkNvbG9yTW9kZT0iMyIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDplN2MyOTZiNS05MmZjLTQ5ODktOTI1MS1kNWFkZTQzOGUyNWEiIHhtcE1NOkRvY3VtZW50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"
    // swiftlint:enable line_length

    static let shared = VirtualCursorController()
    let cursorSize = CGFloat(36)
    private var cursorWindow: UIWindow?
    private var cursorView: UIImageView?
    private var moveVelocity = CGVector.zero
    private var movePolling = false
    private var touchId: Int?
    private var touchPolling = false

    var enabled: Bool {
        get {
            return ExtraKeymapping.shared.keymapData.enableVirtualCursor
        }
    }

    func toggleVirtualCursor() {
        let enabled = !ExtraKeymapping.shared.keymapData.enableVirtualCursor
        if !enabled {
            if ControlMode.mode == .virtualCursor {
                ControlMode.mode.set(.arbitraryClick)
            }
        }
        ExtraKeymapping.shared.keymapData.enableVirtualCursor = enabled
    }

    func showCursor() {
        if cursorWindow == nil {
            cursorWindow = UIWindow(windowScene: screen.windowScene!)
            cursorWindow?.windowLevel = .alert + 1
            cursorWindow?.rootViewController = RootViewController()

            var image: UIImage?
            if let imageData = Data(base64Encoded: imageBase64, options: .ignoreUnknownCharacters) {
                image = UIImage(data: imageData)
            } else {
                image = UIImage(systemName: "circle")
            }
            cursorView = UIImageView(image: image)
            cursorView?.setWidth(width: cursorSize)
            cursorView?.setHeight(height: cursorSize)
            cursorView?.setX(xCoord: screen.width / 2)
            cursorView?.setY(yCoord: screen.height / 2)
            cursorWindow?.rootViewController?.view.addSubview(cursorView!)
        }
        cursorWindow?.isHidden = false
    }

    func hideCursor() {
        cursorWindow?.isHidden = true
    }

    func setCursorPos(_ pos: CGPoint) {
        if let cursor = cursorView {
            DispatchQueue.main.async {
                cursor.center = pos
            }
        }
    }

    func setVelocity(velocityX: CGFloat, velocityY: CGFloat) {
        self.moveVelocity.dx = velocityX
        self.moveVelocity.dy = velocityY
        if !movePolling {
            self.movePolling = true
            PlayInput.touchQueue.async(execute: self.movePoll)
        }
    }

    private func movePoll() {
        if !isVectorSignificant(self.moveVelocity) {
            self.movePolling = false
            return
        }
        moveCursor(velocityX: moveVelocity.dx, velocityY: moveVelocity.dy)
        PlayInput.touchQueue.asyncAfter(deadline: DispatchTime.now() + 0.017, execute: self.movePoll)
    }

    private func moveCursor(velocityX: CGFloat, velocityY: CGFloat) {
        if let cursor = cursorView {
            let speed = CGFloat(10)
            let newX = min(max(0, cursor.center.x + velocityX * speed), screen.width)
            let newY = min(max(0, cursor.center.y - velocityY * speed), screen.height)
            DispatchQueue.main.async {
                cursor.center = CGPoint(x: newX, y: newY)
            }
        }
    }

    private func isVectorSignificant(_ vector: CGVector) -> Bool {
        return vector.dx.magnitude + vector.dy.magnitude > 0.2
    }

    func handlePress(pressed: Bool) {
        if let cursor = cursorView {
            let point = cursor.center
            if pressed {
                Toucher.touchcam(point: point, phase: UITouch.Phase.began, tid: &touchId,
                                 actionName: "Button", keyName: "VirtualCursor")
                if !self.touchPolling {
                    self.touchPolling = true
                    PlayInput.touchQueue.async(execute: self.touchPoll)
                }
            } else {
                Toucher.touchcam(point: point, phase: UITouch.Phase.ended, tid: &touchId,
                                 actionName: "Button", keyName: "VirtualCursor")
                self.touchPolling = false
            }
        }
    }

    private func touchPoll() {
        if !self.touchPolling {
            return
        }
        if let point = self.cursorView?.center {
            Toucher.touchcam(point: point, phase: UITouch.Phase.moved, tid: &touchId,
                             actionName: "Button", keyName: "VirtualCursor")
        }
        PlayInput.touchQueue.asyncAfter(deadline: DispatchTime.now() + 0.017, execute: self.touchPoll)
    }

    class RootViewController: UIViewController {
        override func viewDidLoad() {
            super.viewDidLoad()
            view.isUserInteractionEnabled = false
        }
    }
}
