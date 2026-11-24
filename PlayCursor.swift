//
//  PlayCursor.swift
//  PlayTools
//

import AppKit

// Add a lightweight struct so we can decode only the flag we care about
private struct AKCursorSettingsData: Codable {
    var enableCustomCursor: Bool?
    var customCursorWidth: Int?
    var customCursorHeight: Int?
    var customCursorHotSpotX: Int?
    var customCursorHotSpotY: Int?
}

class PlayCursor {
    public static let shared = PlayCursor()

    private static var cursorSettingsData: AKCursorSettingsData? = {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let settingsURL = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
            .appendingPathComponent("App Settings")
            .appendingPathComponent("\(bundleIdentifier).extra.plist")
        guard let data = try? Data(contentsOf: settingsURL),
              let decoded = try? PropertyListDecoder().decode(AKCursorSettingsData.self, from: data) else {
            return nil
        }
        return decoded
    }()

    private var cursor: NSCursor?
    private weak var window: NSWindow?
    private var timer: DispatchSourceTimer?

    func initialize() {
        if !(Self.cursorSettingsData?.enableCustomCursor ?? false) {
            return
        }

        let bundleIdentifier = Bundle.main.bundleIdentifier ?? ""
        let imageURL = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
            .appendingPathComponent("Cursors")
            .appendingPathComponent("\(bundleIdentifier).png")
        if !FileManager.default.fileExists(atPath: imageURL.path) {
            return
        }

        let size = CGSize(width: Self.cursorSettingsData?.customCursorWidth ?? 32,
                          height: Self.cursorSettingsData?.customCursorHeight ?? 32)
        let hotSpot = CGPoint(x: Self.cursorSettingsData?.customCursorHotSpotX ?? 0,
                              y: Self.cursorSettingsData?.customCursorHotSpotY ?? 0)
        self.cursor = createCursor(imageURL: imageURL, size: size, hotSpot: hotSpot)

        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else {
                return
            }
            if self.window == nil {
                self.window = window
            }
            if window == self.window {
                self.startPolling()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSWindow.didResignKeyNotification,
            object: nil,
            queue: .main
        ) { note in
            guard let window = note.object as? NSWindow else {
                return
            }
            if window == self.window {
                self.stopPolling()
            }
        }
    }

    private func createCursor(imageURL: URL, size: CGSize, hotSpot: CGPoint) -> NSCursor? {
        guard let rawImage = NSImage(contentsOf: imageURL) else { return nil }

        let scaledImage = scaleImage(rawImage, to: size)

        return NSCursor(image: scaledImage, hotSpot: hotSpot)
    }

    private func scaleImage(_ image: NSImage, to size: NSSize) -> NSImage {
        let newImage = NSImage(size: size)
        newImage.lockFocus()
        let srcRect = NSRect(origin: .zero, size: image.size)
        let dstRect = NSRect(origin: .zero, size: size)
        image.draw(in: dstRect, from: srcRect, operation: .sourceOver, fraction: 1.0)
        newImage.unlockFocus()
        return newImage
    }

    func startPolling() {
        if let timer = self.timer {
            timer.cancel()
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now(), repeating: .seconds(1))
        timer.setEventHandler { [weak self] in
           self?.refreshCursor()
        }
        timer.resume()
        self.timer = timer
    }

    func stopPolling() {
        self.timer?.cancel()
        self.timer = nil
    }

    func refreshCursor() {
        guard let window = self.window else { return }
        let mouseLocation = NSEvent.mouseLocation
        let contentRect = window.contentRect(forFrameRect: window.frame)
        if contentRect.contains(mouseLocation) {
            cursor?.set()
        }
    }
}
