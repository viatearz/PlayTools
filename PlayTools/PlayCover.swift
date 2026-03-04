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

        if PlaySettings.shared.racingMasterFixFilePath {
            racingMasterFixFilePath()
        }
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

    static func delay(_ delay: Double, closure: @escaping () -> Void) {
        let when = DispatchTime.now() + delay
        DispatchQueue.main.asyncAfter(deadline: when, execute: closure)
    }

    static func createSymbolicLink(source: URL, dest: URL) {
        do {
            if FileManager.default.fileExists(atPath: source.path) {
                let attributes = try FileManager.default.attributesOfItem(atPath: source.path)
                if let type = attributes[.type] as? FileAttributeType,
                   type == .typeSymbolicLink {
                    // Symlink already exists, skip
                    return
                } else {
                    // Delete the non-symlink item
                    try FileManager.default.removeItem(atPath: source.path)
                }
            }

            try FileManager.default.createDirectory(at: source.deletingLastPathComponent(),
                                                    withIntermediateDirectories: true)
            try FileManager.default.createSymbolicLink(at: source,
                                                       withDestinationURL: dest)
        } catch {
            print(error)
        }
    }

    static func racingMasterFixFilePath() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        let userName = NSUserName()

        let srcPaths = [
            "/Users/\(userName)/Library/Containers/\(bundleID)/Data/Library" +
            "/Users/\(userName)/Library/Containers/\(bundleID)/Data",
            "/Users/\(userName)/Library/Containers/\(bundleID)/Data/Library" +
            "/Users/\(userName)/Documents/Containers/\(bundleID)/Data"
        ]

        let destPath = "/Users/\(userName)/Library/Containers/\(bundleID)/Data"

        for srcPath in srcPaths {
            createSymbolicLink(source: URL(fileURLWithPath: srcPath),
                               dest: URL(fileURLWithPath: destPath))
        }
    }
}
