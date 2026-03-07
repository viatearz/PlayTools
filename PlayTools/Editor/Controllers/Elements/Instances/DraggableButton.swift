//
//  DraggableButton.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/12/25.
//

import Foundation

class DraggableButtonModel: ControlModel<DraggableButton>, ParentElement {
    func unfocusChildren() {
        childButton?.focus(false)
    }

    var childButton: ChildButtonModel?

    func save() -> DraggableButton {
        data.keyCode = childButton!.data.keyCode
        data.keyName = childButton!.data.keyName
        return data
    }

    override init(data: DraggableButton) {
        super.init(data: data)
        button = DraggableButtonElement(frame: CGRect(
            x: data.transform.xCoord.absoluteX - data.transform.size.absoluteSize/2,
            y: data.transform.yCoord.absoluteY - data.transform.size.absoluteSize/2,
            width: data.transform.size.absoluteSize,
            height: data.transform.size.absoluteSize
        ))
        button.model = self
        // temporarily, cannot map controller keys to draggable buttons
        // `data.keyName` is the key for the move area, not that of the button key.
        childButton = ChildButtonModel(
            data: Button(keyCode: data.keyCode, keyName: data.keyName, transform: data.transform),
            parent: self
        )
        childButton?.setKey(code: data.keyCode, name: data.keyName)
        setKey(name: data.movementKeyName)
        setMode(mode: data.mode)
        button.update()
    }

    override func setKey(code: Int, name: String) {
        if name == "Mouse" || name == "RMB" {
            // set the parent key
            self.data.movementKeyName = "Mouse"
            button.setTitle(data.movementKeyName, for: UIControl.State.normal)
            if !self.data.mode.isMouseType {
                setMode(mode: .mouseCursorHidden)
            }
        } else if name.hasSuffix("Thumbstick") {
            // set the parent key
            self.data.movementKeyName = name
            button.setTitle(data.movementKeyName, for: UIControl.State.normal)
            if !self.data.mode.isThumbstickType {
                setMode(mode: .thumbstick)
            }
        } else {
            // set the child key
            childButton!.setKey(code: code, name: name)
        }
    }

    override func focus(_ focus: Bool) {
        super.focus(focus)
        if !focus {
            unfocusChildren()
        }
    }

    func setMode(mode: DraggableMode) {
        guard let btn = button as? DraggableButtonElement else {
            Toast.showHint(title: "setDraggableMode error", text: ["View is not DraggableButtonElement"])
            return
        }
        self.data.mode = mode
        btn.setMode(mode: mode)
    }

    func switchToNextMode() {
        let maxValue = DraggableMode.mouseTypeMax.rawValue - 1
        let newValue = data.mode.rawValue % maxValue + 1
        let newMode = DraggableMode(rawValue: newValue)!
        setMode(mode: newMode)
    }
}
