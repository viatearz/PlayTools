//
//  PlayCover.swift
//  PlayTools
//

import Foundation
import UIKit

public class PlayCover: NSObject {

    static let shared = PlayCover()
    var menuController: MenuController?

    @objc static public func launch() {
        quitWhenClose()
        AKInterface.initialize()
        PlayScreen.shared.initialize()
        PlayInput.shared.initialize()
        DiscordIPC.shared.initialize()

        if PlaySettings.shared.rootWorkDir {
            // Change the working directory to / just like iOS
            FileManager.default.changeCurrentDirectoryPath("/")
        }

        if PlayInfo.isUnrealEngine {
            setupUnrealEngineEnvironment()
            // Disable built-in mouse to avoid click conflicts
            PlayInput.shared.disableBuiltinMouse()
        }

        AppSupport.instance.postLaunch()
    }

    @objc static public func initMenu(menu: NSObject) {
        guard let menuBuilder = menu as? UIMenuBuilder else { return }
        shared.menuController = MenuController(with: menuBuilder)
    }

    static public func quitWhenClose() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name(rawValue: "NSWindowWillCloseNotification"),
            object: nil,
            queue: OperationQueue.main
        ) { notif in
            if PlayScreen.shared.nsWindow?.isEqual(notif.object) ?? false {
                // Step 1: Resign active
                for scene in UIApplication.shared.connectedScenes {
                    scene.delegate?.sceneWillResignActive?(scene)
                    NotificationCenter.default.post(name: UIScene.willDeactivateNotification,
                                                    object: scene)
                }
                UIApplication.shared.delegate?.applicationWillResignActive?(UIApplication.shared)
                NotificationCenter.default.post(name: UIApplication.willResignActiveNotification,
                                                object: UIApplication.shared)

                // Step 2: Enter background
                for scene in UIApplication.shared.connectedScenes {
                    scene.delegate?.sceneDidEnterBackground?(scene)
                    NotificationCenter.default.post(name: UIScene.didEnterBackgroundNotification,
                                                    object: scene)
                }
                UIApplication.shared.delegate?.applicationDidEnterBackground?(UIApplication.shared)
                NotificationCenter.default.post(name: UIApplication.didEnterBackgroundNotification,
                                                object: UIApplication.shared)

                // Step 2.5: End UIBackgroundTask
                // There is an expiration handler, but idk how to invoke it. Skip for now.

                // Step 3: Terminate
                UIApplication.shared.delegate?.applicationWillTerminate?(UIApplication.shared)
                NotificationCenter.default.post(name: UIApplication.willTerminateNotification,
                                                object: UIApplication.shared)
                DispatchQueue.main.async(execute: AKInterface.shared!.terminateApplication)

                // Step 3.5: End BGTask
                // BGTask typically runs in another process and is tricky to terminate.
                // It may run into infinite loops, end up silently heating the device up.
                // This actually happens for ToF. Hope future developers can solve this.
            }
        }
    }

    static func setupUnrealEngineEnvironment() {
        guard let executableURL = Bundle.main.executableURL else {
            return
        }

        let cookeddataDir = executableURL.deletingLastPathComponent()
            .appendingPathComponent("cookeddata")

        let documentDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

        let libraryDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first!

        let appDataDir = documentDir.deletingLastPathComponent()

        for sourceParentDir in [documentDir, libraryDir] {
            for destDir in [appDataDir, cookeddataDir] {
                let sourceDir = sourceParentDir.appendingPathComponent(destDir.path)
                createSymbolicLink(source: sourceDir, destination: destDir)
            }
        }
    }

    static func createSymbolicLink(source: URL, destination: URL) {
        do {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: source.path, isDirectory: &isDirectory) {
                let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
                if let fileType = attributes[.type] as? FileAttributeType, fileType == .typeSymbolicLink {
                    // Symlink already exists, skip
                    return
                } else {
                    // Delete the non-symlink item
                    try FileManager.default.removeItem(atPath: source.path)
                }
            }

            try FileManager.default.createDirectory(at: source.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try FileManager.default.createSymbolicLink(at: source, withDestinationURL: destination)
        } catch {
            NSLog("[PlayTools] create symlink failed: \(source.path) \(destination.path) \(error)")
        }
    }

    static func delay(_ delay: Double, closure: @escaping () -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }
}

class FileUtils {
    public static func getFileSize(_ url: URL) -> UInt64? {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            return attributes[.size] as? UInt64
        } catch {
            return nil
        }
    }

    public static func removeFile(_ url: URL) {
        do {
            try FileManager.default.removeItem(atPath: url.path)
        } catch {
            print("[PlayTools] Failed to remove file \(url.path): \(error)")
        }
    }

    public static func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
    }

    public static func createDirectory(at url: URL) {
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        } catch {
            print("[PlayTools] Failed to create directory \(url.path): \(error)")
        }
    }

    public static func clearAllFiles(at diretotryURL: URL) {
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: diretotryURL.path)
            for file in contents {
                let fileURL = diretotryURL.appendingPathComponent(file)
                try FileManager.default.removeItem(atPath: fileURL.path)
            }
        } catch {
            print("[PlayTools] Failed to clear files in directory \(diretotryURL.path): \(error)")
        }
    }

    public static func setReadOnly(_ url: URL) {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let currentPermissions = attributes[.posixPermissions] as? NSNumber {
                let currentMode = currentPermissions.uint16Value
                let newMode = currentMode & ~0o222
                try FileManager.default.setAttributes([.posixPermissions: NSNumber(value: newMode)], ofItemAtPath: url.path)
            }
        } catch {
            print("[PlayTools] Failed to set readonly for \(url.path): \(error)")
        }
    }
}
