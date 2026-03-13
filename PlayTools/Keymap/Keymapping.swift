//
//  Keymapping.swift
//  PlayTools
//
//  Created by 이승윤 on 2022/08/29.
//

import Foundation

let keymap = Keymapping.shared

class Keymapping {
    static let shared = Keymapping()

    let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""

    private var keymapIdx: Int
    public var currentKeymap: KeymappingData {
        get {
            getKeymap(path: currentKeymapURL)
        }
        set {
            setKeymap(path: currentKeymapURL, map: newValue)
        }
    }

    private let baseKeymapURL: URL
    private let configURL: URL
    private var keymapOrder: [URL: KeymappingData] = [:]

    public var keymapConfig: KeymapConfig {
        get {
            do {
                let data = try Data(contentsOf: configURL)
                return try PropertyListDecoder().decode(KeymapConfig.self, from: data)
            } catch {
                print("[PlayTools] Failed to decode config url.\n%@")
                return resetConfig()
            }
        }
        set {
            let encoder = PropertyListEncoder()
            encoder.outputFormat = .xml

            do {
                let data = try encoder.encode(newValue)
                try data.write(to: configURL)
            } catch {
                print("[PlayTools] Keymapping encode failed.\n%@")
            }
        }
    }

    public var currentKeymapURL: URL {
        keymapConfig.keymapOrder[keymapIdx]
    }

    public var currentKeymapName: String {
        currentKeymapURL.deletingPathExtension().lastPathComponent
    }

    init() {
        baseKeymapURL = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
            .appendingPathComponent("Keymapping")
            .appendingPathComponent(bundleIdentifier)

        configURL = baseKeymapURL.appendingPathComponent(".config").appendingPathExtension("plist")

        keymapIdx = 0

        loadKeymapData()
    }

    private func constructKeymapPath(name: String) -> URL {
        baseKeymapURL.appendingPathComponent(name).appendingPathExtension("plist")
    }

    private func loadKeymapData() {
        if !FileManager.default.fileExists(atPath: baseKeymapURL.path) {
            do {
                try FileManager.default.createDirectory(
                    atPath: baseKeymapURL.path,
                    withIntermediateDirectories: true,
                    attributes: [:])
            } catch {
                print("[PlayTools] Failed to create Keymapping directory.\n%@")
            }
        }

        keymapOrder.removeAll()

        for keymap in keymapConfig.keymapOrder {
            keymapOrder[keymap] = getKeymap(path: keymap)
        }

        if let defaultKmIdx = keymapOrder.keys.firstIndex(of: keymapConfig.defaultKm) {
            keymapIdx = keymapOrder.distance(from: keymapOrder.startIndex, to: defaultKmIdx)
        } else {
            setKeymap(path: keymapConfig.defaultKm, map: KeymappingData(bundleIdentifier: bundleIdentifier))
            loadKeymapData()
        }
    }

    private func getKeymap(path: URL) -> KeymappingData {
        do {
            let data = try Data(contentsOf: path)
            let map = try PropertyListDecoder().decode(KeymappingData.self, from: data)
            return map
        } catch {
            print("[PlayTools] Keymapping decode failed.\n%@")
        }

        return resetKeymap(path: path)
    }

    private func setKeymap(path: URL, map: KeymappingData) {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml

        do {
            let data = try encoder.encode(map)
            try data.write(to: path)

            if !keymapOrder.keys.contains(path) {
                keymapConfig.keymapOrder.append(path)
                keymapOrder[path] = getKeymap(path: path)
            }
        } catch {
            print("[PlayTools] Keymapping encode failed.\n%@")
        }
    }

    public func nextKeymap() {
        keymapIdx = (keymapIdx + 1) % keymapOrder.count
    }

    public func previousKeymap() {
        keymapIdx = (keymapIdx - 1 + keymapOrder.count) % keymapOrder.count
    }

    @discardableResult
    public func resetKeymap(path: URL) -> KeymappingData {
        setKeymap(path: path, map: KeymappingData(bundleIdentifier: bundleIdentifier))
        return getKeymap(path: path)
    }

    @discardableResult
    private func resetConfig() -> KeymapConfig {
        let defaultURL = constructKeymapPath(name: "default")

        keymapConfig = KeymapConfig(defaultKm: defaultURL, keymapOrder: [defaultURL])

        return keymapConfig
    }

}

struct KeymappingData: Codable {
    var buttonModels: [Button] = []
    var draggableButtonModels: [DraggableButton] = []
    var joystickModel: [Joystick] = []
    var mouseAreaModel: [MouseArea] = []
    var gamepadToKeyModel: [GamepadToKey] = []
    var bundleIdentifier: String
    var version = "2.0.0"

    enum CodingKeys: CodingKey {
        case buttonModels
        case draggableButtonModels
        case joystickModel
        case mouseAreaModel
        case bundleIdentifier
        case version
    }

    init(bundleIdentifier: String) {
        self.bundleIdentifier = bundleIdentifier
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        var buttonModels = try container.decode([Button].self, forKey: .buttonModels)
        self.draggableButtonModels = try container.decode([DraggableButton].self, forKey: .draggableButtonModels)
        self.joystickModel = try container.decode([Joystick].self, forKey: .joystickModel)
        self.mouseAreaModel = try container.decode([MouseArea].self, forKey: .mouseAreaModel)
        self.bundleIdentifier = try container.decode(String.self, forKey: .bundleIdentifier)
        self.version = try container.decode(String.self, forKey: .version)

        var gamepadToKeyModel: [GamepadToKey] = []
        for idx in stride(from: buttonModels.count - 1, through: 0, by: -1) {
            let buttonModel = buttonModels[idx]
            if buttonModel.keyName.starts(with: "GAMEPAD2KEY$") {
                buttonModels.remove(at: idx)
            }
            let parts = buttonModel.keyName.split(separator: "$")
            if parts.count > 2 {
                gamepadToKeyModel.append(GamepadToKey(keyName: String(parts[1]), targetKeyName: String(parts[2])))
            }
        }
        self.buttonModels = buttonModels
        self.gamepadToKeyModel = gamepadToKeyModel
    }

    func encode(to encoder: any Encoder) throws {
        // Store GamepadToKey data in the buttonModels field to ensure compatibility with the official version
        var buttonModels = self.buttonModels
        for gamepadToKey in self.gamepadToKeyModel {
            buttonModels.append(Button(
                keyCode: KeyCodeNames.defaultCode,
                keyName: "GAMEPAD2KEY$\(gamepadToKey.keyName)$\(gamepadToKey.targetKeyName)",
                transform: KeyModelTransform(size: 0, xCoord: -1, yCoord: -1)
            ))
        }

        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(buttonModels, forKey: .buttonModels)
        try container.encode(self.draggableButtonModels, forKey: .draggableButtonModels)
        try container.encode(self.joystickModel, forKey: .joystickModel)
        try container.encode(self.mouseAreaModel, forKey: .mouseAreaModel)
        try container.encode(self.bundleIdentifier, forKey: .bundleIdentifier)
        try container.encode(self.version, forKey: .version)
    }
}

struct KeymapConfig: Codable {
    var defaultKm: URL
    var keymapOrder: [URL]
}
