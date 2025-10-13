//
//  ScreenController.swift
//  PlayTools
//
import Foundation
import UIKit

let screen = PlayScreen.shared
let isInvertFixEnabled = PlaySettings.shared.inverseScreenValues && PlaySettings.shared.adaptiveDisplay
let mainScreenWidth =  !isInvertFixEnabled ? PlaySettings.shared.windowSizeWidth : PlaySettings.shared.windowSizeHeight
let mainScreenHeight = !isInvertFixEnabled ? PlaySettings.shared.windowSizeHeight : PlaySettings.shared.windowSizeWidth
let customScaler = PlaySettings.shared.customScaler

extension CGSize {
    func aspectRatio() -> CGFloat {
        if mainScreenWidth > mainScreenHeight {
            return mainScreenWidth / mainScreenHeight
        } else {
            return mainScreenHeight / mainScreenWidth
        }
    }

    func toAspectRatio() -> CGSize {
        if #available(iOS 16.3, *) {
            return CGSize(width: mainScreenWidth, height: mainScreenHeight)
        } else {
            return CGSize(width: mainScreenHeight, height: mainScreenWidth)
        }
    }

    func toAspectRatioInternal() -> CGSize {
        return CGSize(width: mainScreenHeight, height: mainScreenWidth)
    }
    func toAspectRatioDefault() -> CGSize {
        return CGSize(width: mainScreenHeight, height: mainScreenWidth)
    }
    func toAspectRatioInternalDefault() -> CGSize {
        return CGSize(width: mainScreenWidth, height: mainScreenHeight)
    }
}

extension CGRect {
    func aspectRatio() -> CGFloat {
        if mainScreenWidth > mainScreenHeight {
            return mainScreenWidth / mainScreenHeight
        } else {
            return mainScreenHeight / mainScreenWidth
        }
    }

    func toAspectRatio(_ multiplier: CGFloat = 1) -> CGRect {
        return CGRect(x: minX, y: minY, width: mainScreenWidth * multiplier, height: mainScreenHeight * multiplier)
    }

    func toAspectRatioReversed() -> CGRect {
        return CGRect(x: minX, y: minY, width: mainScreenHeight, height: mainScreenWidth)
    }
    func toAspectRatioDefault(_ multiplier: CGFloat = 1) -> CGRect {
        return CGRect(x: minX, y: minY, width: mainScreenWidth * multiplier, height: mainScreenHeight * multiplier)
    }
    func toAspectRatioReversedDefault() -> CGRect {
        return CGRect(x: minX, y: minY, width: mainScreenHeight, height: mainScreenWidth)
    }
}

extension UIScreen {
    static var aspectRatio: CGFloat {
        let count = AKInterface.shared!.screenCount
        if PlaySettings.shared.notch {
            if count == 1 {
                return mainScreenWidth / mainScreenHeight // 1.6 or 1.77777778
            } else {
                if AKInterface.shared!.isMainScreenEqualToFirst {
                    return mainScreenWidth / mainScreenHeight
                }
            }

        }

        let frame = AKInterface.shared!.mainScreenFrame
        return frame.aspectRatio()
    }
}

public class PlayScreen: NSObject {
    @objc public static let shared = PlayScreen()

    func initialize() {
        if resizable {
            // Remove default size restrictions
            NotificationCenter.default.addObserver(forName: UIWindow.didBecomeKeyNotification, object: nil,
                queue: .main) { notification in
                if let window = notification.object as? UIWindow,
                   let windowScene = window.windowScene {
                    windowScene.sizeRestrictions?.minimumSize = CGSize(width: 0, height: 0)
                    windowScene.sizeRestrictions?.maximumSize = CGSize(width: .max, height: .max)
                }
            }
        }

        if PlaySettings.shared.supportAutoRotate {
            ResizableWindowManager.shared.initialize()
        }
    }

    @objc public static func frame(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatioReversed()
    }

    @objc public static func bounds(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatio()
    }

    @objc public static func nativeBounds(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatio(CGFloat((customScaler)))
    }

    @objc public static func width(_ size: Int) -> Int {
        return size
    }

    @objc public static func height(_ size: Int) -> Int {
        return Int(size / Int(UIScreen.aspectRatio))
    }

    @objc public static func sizeAspectRatio(_ size: CGSize) -> CGSize {
        return size.toAspectRatio()
    }

    var fullscreen: Bool {
        return AKInterface.shared!.isFullscreen
    }

    var resizable: Bool {
        return PlaySettings.shared.resizableWindow
    }

    @objc public var screenRect: CGRect {
        return UIScreen.main.bounds
    }

    var width: CGFloat {
        screenRect.width
    }

    var height: CGFloat {
        screenRect.height
    }

    var max: CGFloat {
        Swift.max(width, height)
    }

    var percent: CGFloat {
        max / 100.0
    }

    var keyWindow: UIWindow? {
        return UIApplication
            .shared
            .connectedScenes
            .flatMap { ($0 as? UIWindowScene)?.windows ?? [] }
            .first { $0.isKeyWindow }
    }

    var windowScene: UIWindowScene? {
        window?.windowScene
    }

    var window: UIWindow? {
        return UIApplication.shared.connectedScenes
            .filter({$0.activationState == .foregroundActive})
            .compactMap({$0 as? UIWindowScene})
            .first?.windows
            .filter({$0.isKeyWindow}).first
    }

    var nsWindow: NSObject? {
        window?.nsWindow
    }

    func switchDock(_ visible: Bool) {
        AKInterface.shared!.setMenuBarVisible(visible)
    }

    // Default calculation
    @objc public static func frameReversedDefault(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatioReversedDefault()
    }
    @objc public static func frameDefault(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatioDefault()
    }
    @objc public static func boundsDefault(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatioDefault()
    }

    @objc public static func nativeBoundsDefault(_ rect: CGRect) -> CGRect {
        return rect.toAspectRatioDefault(CGFloat((customScaler)))
    }

    @objc public static func sizeAspectRatioDefault(_ size: CGSize) -> CGSize {
        return size.toAspectRatioDefault()
    }
    @objc public static func frameInternalDefault(_ rect: CGRect) -> CGRect {
            return rect.toAspectRatioDefault()
    }

    private static weak var cachedWindow: UIWindow?
    @objc public static func boundsResizable(_ rect: CGRect) -> CGRect {
        if cachedWindow == nil {
            cachedWindow = PlayScreen.shared.keyWindow
        }
        return cachedWindow?.bounds ?? rect
    }
}

extension CGFloat {
    var relativeY: CGFloat {
        self / screen.height
    }

    var relativeX: CGFloat {
        self / screen.width
    }

    var relativeSize: CGFloat {
        self / screen.percent
    }

    var absoluteSize: CGFloat {
        self * screen.percent
    }

    var absoluteX: CGFloat {
        self * screen.width
    }

    var absoluteY: CGFloat {
        self * screen.height
    }
}

extension UIWindow {
    var nsWindow: NSObject? {
        guard let nsWindows = NSClassFromString("NSApplication")?
            .value(forKeyPath: "sharedApplication.windows") as? [AnyObject] else { return nil }
        for nsWindow in nsWindows {
            let uiWindows = nsWindow.value(forKeyPath: "uiWindows") as? [UIWindow] ?? []
            if uiWindows.contains(self) {
                return nsWindow as? NSObject
            }
        }
        return nil
    }

    var isLandscape: Bool {
        if let orientationMask = self.rootViewController?.supportedInterfaceOrientations {
            return orientationMask.contains(.landscapeLeft) || orientationMask.contains(.landscapeRight)
        }
        return false
    }
}

final class ResizableWindowManager {
    public static let shared = ResizableWindowManager()
    private var nsWindow: AnyObject?
    private var uiWindow: UIWindow?
    private var timer: Timer?
    private var isLandscape = false
    private var autoResize = false
    private var portraitOrigin = CGPoint()
    private var portraitSize = CGSize()
    private var landscapeSize = CGSize()

    func initialize() {
        landscapeSize = CGSize(width: mainScreenWidth, height: mainScreenHeight)

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey(_:)),
            name: Notification.Name("NSWindowDidBecomeKeyNotification"),
            object: nil
        )
    }

    @objc private func windowDidBecomeKey(_ notification: Notification) {
        // Use NSWindow to change window position
        nsWindow = notification.object as? AnyObject
        // Use UIWindow to change window size
        if let uiWindows = nsWindow?.value(forKey: "uiWindows") as? [UIWindow] {
            uiWindow = uiWindows.first(where: { $0.isKeyWindow })
        }
        isLandscape = uiWindow?.isLandscape ?? false
        resetUIWindowSizeRestrictions()

        timer = Timer.scheduledTimer(
            timeInterval: 0.1,
            target: self,
            selector: #selector(self.checkOrientation),
            userInfo: nil,
            repeats: true
        )

        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name("NSWindowDidBecomeKeyNotification"),
            object: nil
        )
    }

    @objc private func checkOrientation() {
        guard let uiWindow = uiWindow else {
            return
        }
        let currentLandscape = uiWindow.isLandscape
        if isLandscape != currentLandscape {
            isLandscape = currentLandscape
            orientationDidChanged()
        }
    }

    private func orientationDidChanged() {
        let isFullScreen = uiWindow?.windowScene?.isFullScreen ?? false

        if isLandscape {
            // portrait -> landscape
            let nsWindowFrame = nsWindow?.value(forKey: "frame") as? CGRect ?? CGRect()
            let uiWindowSize = uiWindow?.bounds.size ?? CGSize()
            if !isFullScreen && uiWindowSize.width < uiWindowSize.height {
                autoResize = true
                portraitSize = uiWindowSize
                portraitOrigin = nsWindowFrame.origin
                setUIWindowSize(landscapeSize)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                    self.resetUIWindowSizeRestrictions()
                    self.setNSWindowCenterPoint(CGPoint(x: nsWindowFrame.midX, y: nsWindowFrame.midY))
                    ActionDispatcher.build()
                }
            } else {
                autoResize = false
            }
        } else {
            // landscape -> portrait
            if !isFullScreen && autoResize {
                setUIWindowSize(portraitSize)
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(50)) {
                    self.resetUIWindowSizeRestrictions()
                    self.setNSWindowOriginPoint(self.portraitOrigin)
                    ActionDispatcher.build()
                }
            }
            autoResize = false
        }
    }

    private func setUIWindowSize(_ size: CGSize) {
        if let windowScene = uiWindow?.windowScene {
            windowScene.sizeRestrictions?.minimumSize = size
            windowScene.sizeRestrictions?.maximumSize = size
        }
    }

    private func resetUIWindowSizeRestrictions() {
        if let windowScene = uiWindow?.windowScene {
            windowScene.sizeRestrictions?.minimumSize = CGSize()
            windowScene.sizeRestrictions?.maximumSize = CGSize(width: 10000, height: 10000)
        }
    }

    private func setNSWindowOriginPoint(_ origin: CGPoint) {
        if let obj = nsWindow {
            let sel = NSSelectorFromString("setFrameOrigin:")
            if obj.responds(to: sel) {
                typealias SetFrameOrigin = @convention(c) (AnyObject, Selector, CGPoint) -> Void
                let imp = obj.method(for: sel)
                let function = unsafeBitCast(imp, to: SetFrameOrigin.self)
                function(obj, sel, origin)
            }
        }
    }

    private func setNSWindowCenterPoint(_ center: CGPoint) {
        var windowFrame = nsWindow?.value(forKey: "frame") as? CGRect ?? CGRect()
        windowFrame.origin = CGPoint(
            x: center.x - windowFrame.size.width / 2,
            y: center.y - windowFrame.size.height / 2
        )

        // Aovid overlapping with dock and notch
        if let screen = nsWindow?.value(forKey: "screen") as? AnyObject,
           let visibleFrame = screen.value(forKey: "visibleFrame") as? CGRect {
            if windowFrame.minX < visibleFrame.minX {
                windowFrame.origin.x = visibleFrame.minX
            }
            if windowFrame.maxX > visibleFrame.maxX {
                windowFrame.origin.x = visibleFrame.maxX - windowFrame.width
            }
            if windowFrame.minY < visibleFrame.minY {
                windowFrame.origin.y = visibleFrame.minY
            }
            if windowFrame.maxY > visibleFrame.maxY {
                windowFrame.origin.y = visibleFrame.maxY - windowFrame.height
            }
        }

        setNSWindowOriginPoint(windowFrame.origin)
    }
}
