//
//  PlayInformation.swift
//  PlayTools
//

import Foundation

class PlayInfo: NSObject {
    static var isLauncherInstalled: Bool {
        return AKInterface.shared!
            .urlForApplicationWithBundleIdentifier("io.playcover.PlayCover") != nil
    }

    @objc static var isUnrealEngine: Bool {
        let appFolder = Bundle.main.bundleURL
        let ueFiles: [URL] = [
            appFolder.appendingPathComponent("ue4commandline.txt"),
            appFolder.appendingPathComponent("uecommandline.txt")
        ]

        for ueFile in ueFiles where FileManager.default.fileExists(atPath: ueFile.path) {
            return true
        }

        let ueCookedData = appFolder.appendingPathComponent("cookeddata")
        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(atPath: ueCookedData.path, isDirectory: &isDirectory), isDirectory.boolValue {
            return true
        }

        return false
    }
}

extension ProcessInfo {
    @objc open var isMacCatalystApp: Bool {
        return false
    }
    @objc open var isiOSAppOnMac: Bool {
        return true
    }
    @objc open var thermalState: ProcessInfo.ThermalState {
        return ProcessInfo.ThermalState.nominal
    }
    @objc open var isLowPowerModeEnabled: Bool {
        return false
    }
}
