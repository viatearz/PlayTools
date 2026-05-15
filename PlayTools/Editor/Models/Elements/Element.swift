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
    case thumbstickFixedRadius = 1000
    case thumbstickFreeRadius = 1001
    case thumbstickTypeMax

    var isMouseType: Bool {
        self.rawValue >= DraggableMode.mouseCursorHidden.rawValue &&
        self.rawValue < DraggableMode.mouseTypeMax.rawValue
    }

    var isThumbstickType: Bool {
        self.rawValue >= DraggableMode.thumbstickFixedRadius.rawValue &&
        self.rawValue < DraggableMode.thumbstickTypeMax.rawValue
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
        var decodedKeyCode = try container.decode(Int.self, forKey: .keyCode)
        var decodedKeyName = try container.decode(String.self, forKey: .keyName)
        (decodedKeyCode, decodedKeyName) = Self.migrateLegacyConfig(keyCode: decodedKeyCode,
                                                                    keyName: decodedKeyName)
        self.transform = try container.decode(KeyModelTransform.self, forKey: .transform)

        let parts = decodedKeyName.split(separator: "$")
        if parts.count == 1 {
            self.keyCode = decodedKeyCode
            self.keyName = KeyCodeNames.keyCodes[keyCode] ?? "Btn"
            self.movementKeyName = decodedKeyName
            self.mode = .mouseCursorHidden
        } else {
            self.keyCode = decodedKeyCode
            self.keyName = String(parts[1])
            self.movementKeyName = String(parts[0])
            self.mode = Self.parseMode(from: String(parts[2]))
        }
    }

    func encode(to encoder: Encoder) throws {
        var serializedKeyName = ""
        if mode == .mouseCursorHidden && !KeyCodeNames.isMouseButton(keyName) {
            // When using the default mode, ensure compatibility with the official version
            serializedKeyName = movementKeyName
        } else {
            serializedKeyName = "\(movementKeyName)$\(keyName)$\(mode.rawValue)"
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(keyCode, forKey: .keyCode)
        try container.encode(serializedKeyName, forKey: .keyName)
        try container.encode(transform, forKey: .transform)
    }

    private static func migrateLegacyConfig(keyCode: Int, keyName: String) -> (Int, String) {
        switch keyCode {
        case -2:
            return (
                KeyCodeNames.defaultCode,
                "\(keyName)$\(KeyCodeNames.rightMouseButton)$\(DraggableMode.mouseCursorHidden.rawValue)"
            )
        case -3:
            return (
                KeyCodeNames.defaultCode,
                "\(keyName)$\(KeyCodeNames.middleMouseButton)$\(DraggableMode.mouseCursorHidden.rawValue)"
            )
        default:
            return (keyCode, keyName)
        }
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
