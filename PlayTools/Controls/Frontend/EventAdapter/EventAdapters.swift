//
//  EventAdapters.swift
//  PlayTools
//
//  Created by 许沂聪 on 2023/9/15.
//

import Foundation

// This is a builder class for event adapters

public class EventAdapters {

    static func keyboard(controlMode: ControlModeLiteral) -> KeyboardEventAdapter {
        switch controlMode {
        case .gamepadToKeyEditor:
            return TransparentKeyboardEventAdapter()
        case  .off, .textInput:
            return TransparentKeyboardEventAdapter()
        case .cameraRotate, .arbitraryClick:
            return TouchscreenKeyboardEventAdapter()
        case .editor:
            return EditorKeyboardEventAdapter()
        }
    }

    static func mouse(controlMode: ControlModeLiteral) -> MouseEventAdapter {
        switch controlMode {
        case .gamepadToKeyEditor:
            return GamepadToKeyMouseEventAdapter()
        case .off, .textInput:
            return TransparentMouseEventAdapter()
        case .cameraRotate:
            return CameraControlMouseEventAdapter()
        case .arbitraryClick:
            return TouchscreenMouseEventAdapter()
        case .editor:
            return EditorMouseEventAdapter()
        }
    }

    static func controller(controlMode: ControlModeLiteral) -> ControllerEventAdapter {
        switch controlMode {
        case .gamepadToKeyEditor:
            return GamepadToKeyControllerEventAdapter()
        case .off:
            return TransparentControllerEventAdapter()
        case .textInput, .cameraRotate, .arbitraryClick:
            return TouchscreenControllerEventAdapter()
        case .editor:
            return EditorControllerEventAdapter()
        }
    }
}
