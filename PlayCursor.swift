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

        // Add tracking area when the window is created,
        // and refresh the cursor when switching back from another app.
        NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification,
            object: nil,
            queue: .main
        ) { _ in
            DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(100)) {
                self.addTrackingArea()
                self.updateCursorIfNeeded()
            }
        }

        // Refresh the cursor when the system menu bar appears in fullscreen.
        // The menu bar triggers an occlusion state change on _NSFullScreenTransitionOverlayWindow.
        NotificationCenter.default.addObserver(
            forName: NSWindow.didChangeOcclusionStateNotification,
            object: nil,
            queue: .main
        ) { _ in
            guard NSApplication.shared.windows.first!.styleMask.contains(.fullScreen) else {
                return
            }
            self.updateCursorIfNeeded()
        }

        // Refresh the cursor when screen recording starts.
        NotificationCenter.default.addObserver(
            forName: Notification.Name("UIScreenCapturedDidChangeNotification"),
            object: nil,
            queue: .main
        ) { _ in
            self.updateCursorIfNeeded()
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

    private func addTrackingArea() {
        guard let contentView = NSApplication.shared.keyWindow?.contentView else {
            return
        }

        let exists = contentView.subviews.contains { $0 is PlayCursorTrackingView }
        if exists {
            return
        }

        // Previously we used a single tracking area. If the custom cursor unexpectedly disappeared,
        // the user had to move the cursor out of the window and back in to force a refresh.
        // Now we split the tracking area into four regions. If the cursor becomes incorrect,
        // moving between regions (e.g. top to bottom) triggers a refresh, so leaving the window
        // is no longer required.

        let topLeft = PlayCursorTrackingView(cursor: cursor)
        let topRight = PlayCursorTrackingView(cursor: cursor)
        let bottomLeft = PlayCursorTrackingView(cursor: cursor)
        let bottomRight = PlayCursorTrackingView(cursor: cursor)

        [topLeft, topRight, bottomLeft, bottomRight].forEach {
            contentView.addSubview($0)
        }

        NSLayoutConstraint.activate([

            // topLeft
            topLeft.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            topLeft.topAnchor.constraint(equalTo: contentView.topAnchor),
            topLeft.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            topLeft.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),

            // topRight
            topRight.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            topRight.topAnchor.constraint(equalTo: contentView.topAnchor),
            topRight.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            topRight.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),

            // bottomLeft
            bottomLeft.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            bottomLeft.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomLeft.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            bottomLeft.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5),

            // bottomRight
            bottomRight.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            bottomRight.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            bottomRight.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.5),
            bottomRight.heightAnchor.constraint(equalTo: contentView.heightAnchor, multiplier: 0.5)

        ])
    }

    func updateCursorIfNeeded() {
        guard let window = NSApplication.shared.keyWindow else {
            return
        }

        let mouseLocation = NSEvent.mouseLocation
        let contentRect = window.contentRect(forFrameRect: window.frame)
        if contentRect.contains(mouseLocation) {
            cursor?.set()
        }
    }
}

class PlayCursorTrackingView: NSView {
    private var trackingArea: NSTrackingArea?
    private var cursor: NSCursor?

    init(cursor: NSCursor?) {
        super.init(frame: .zero)
        self.cursor = cursor
        self.translatesAutoresizingMaskIntoConstraints = false
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = self.trackingArea {
            removeTrackingArea(trackingArea)
        }

        let newTrackingArea = NSTrackingArea(
            rect: bounds,
            options: [.activeInKeyWindow, .cursorUpdate],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(newTrackingArea)
        self.trackingArea = newTrackingArea
    }

    override func cursorUpdate(with event: NSEvent) {
        cursor?.set()
    }
}
