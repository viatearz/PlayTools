//
//  PlayCursor.swift
//  PlayTools
//
//  Created by viatearz on 2025/2/4.
//

import AppKit

class PlayCursor {
    public static let shared = PlayCursor()
    private var cursor: NSCursor?

    func setupCustomCursor(imageUrl: URL, size: CGSize, hotSpot: CGPoint) {
        self.cursor = createCursor(imageUrl: imageUrl, size: size, hotSpot: hotSpot)

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

    private func createCursor(imageUrl: URL, size: CGSize, hotSpot: CGPoint) -> NSCursor? {
        guard let rawImage = NSImage(contentsOf: imageUrl) else { return nil }

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

        let trackingView = PlayCursorTrackingView(frame: contentView.bounds, cursor: cursor)
        contentView.addSubview(trackingView)
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

    init(frame frameRect: NSRect, cursor: NSCursor?) {
        super.init(frame: frameRect)
        self.cursor = cursor
        self.autoresizingMask = [.width, .height]
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
