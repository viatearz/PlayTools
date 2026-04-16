import GameController

// Data structure definition should match those in
// https://github.com/PlayCover/PlayCover/blob/develop/PlayCover/Model/Keymapping.swift
struct KeyModelTransform: Codable {
    var size: CGFloat
    var xCoord: CGFloat
    var yCoord: CGFloat
}

protocol BaseElement: Codable {
    var keyName: String { get set }
    var transform: KeyModelTransform { get set }
}

// controller buttons are indexed with names
struct Button: BaseElement {
    var keyCode: Int
    var keyName: String
    var transform: KeyModelTransform
}

enum DraggableMode: Int, CaseIterable {
    case mouseCursorHidden = 1
    case mouseCursorVisible = 2
    case mouseTypeMax
    case thumbstick = 1000

    var isMouseType: Bool {
        self.rawValue >= DraggableMode.mouseCursorHidden.rawValue &&
        self.rawValue < DraggableMode.mouseTypeMax.rawValue
    }

    var isThumbstickType: Bool {
        self == .thumbstick
    }
}

struct DraggableButton: BaseElement {
    var keyCode: Int
    var keyName: String
    var transform: KeyModelTransform
    var movementKeyName: String
    var mode: DraggableMode

    enum CodingKeys: String, CodingKey {
        case keyCode
        case keyName
        case transform
    }

    init(keyCode: Int, keyName: String, transform: KeyModelTransform,
         movementKeyName: String, mode: DraggableMode) {
        self.keyCode = keyCode
        self.keyName = keyName
        self.transform = transform
        self.movementKeyName = movementKeyName
        self.mode = mode
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.keyCode = try container.decode(Int.self, forKey: .keyCode)
        let serializedString = try container.decode(String.self, forKey: .keyName)
        self.transform = try container.decode(KeyModelTransform.self, forKey: .transform)

        let parts = serializedString.split(separator: "$")
        if parts.count == 1 {
            if keyCode == -2 {
                self.keyCode = KeyCodeNames.defaultCode
                self.keyName = KeyCodeNames.rightMouseButton
            } else if keyCode == -3 {
                self.keyCode = KeyCodeNames.defaultCode
                self.keyName = KeyCodeNames.middleMouseButton
            } else {
                self.keyName = KeyCodeNames.keyCodes[keyCode] ?? "Btn"
            }
            self.movementKeyName = String(parts[0])
            self.mode = .mouseCursorHidden
        } else {
            self.keyName = String(parts[1])
            self.movementKeyName = String(parts[0])
            self.mode = DraggableButton.parseMode(from: String(parts[2]))
        }
    }

    func encode(to encoder: Encoder) throws {
        var keyCode = keyCode
        var serializedString = ""
        if mode == .mouseCursorHidden {
            if keyName == KeyCodeNames.rightMouseButton {
                keyCode = -2
            } else if keyName == KeyCodeNames.middleMouseButton {
                keyCode = -3
            }
            serializedString = movementKeyName
        } else {
            serializedString = "\(movementKeyName)$\(keyName)$\(mode.rawValue)"
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(serializedString, forKey: .keyName)
        try container.encode(transform, forKey: .transform)
    }

    private static func parseMode(from str: String) -> DraggableMode {
        if let value = Int(str),
           let mode = DraggableMode(rawValue: value) {
            return mode
        }
        return .mouseCursorHidden
    }
}

enum JoystickMode: Int, Codable {
    case FIXED
    case FLOATING
}

struct Joystick: BaseElement {
    static let defaultMode = JoystickMode.FIXED
    var upKeyCode: Int
    var rightKeyCode: Int
    var downKeyCode: Int
    var leftKeyCode: Int
    var keyName: String = "Keyboard"
    var transform: KeyModelTransform
    var mode: JoystickMode?
}

struct MouseArea: BaseElement {
    var keyName: String
    var transform: KeyModelTransform
    init(transform: KeyModelTransform) {
        self.transform = transform
        self.keyName = "Mouse"
    }
    init(keyName: String, transform: KeyModelTransform) {
        self.transform = transform
        self.keyName = keyName
    }
}

// This is currently not stored
// Prepare to add swipe mapping
// Swipe mapping starts from a user-defined pos,
// and move to a user-defined pos (polar coordinate system defined by size and angle)
// and end.
struct Swipe: BaseElement {
    var keyName: String
    var transform: KeyModelTransform
    // [0, 2 * PI)
    var angle: CGFloat
}

struct GamepadToKey: Codable {
    var keyName: String
    var targetKeyName: String

    var thumbstickName: String? {
        if let range = keyName.range(of: "Thumbstick") {
            if !keyName.hasSuffix("Button") {
                return String(keyName[..<range.upperBound])
            }
        }
        return nil
    }
}
