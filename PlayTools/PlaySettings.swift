import Foundation
import UIKit

let settings = PlaySettings.shared

@objc public final class PlaySettings: NSObject {
    @objc public static let shared = PlaySettings()

    let bundleIdentifier = Bundle.main.infoDictionary?["CFBundleIdentifier"] as? String ?? ""
    let settingsUrl: URL
    var settingsData: AppSettingsData
    let extraSettingsUrl: URL
    var extraSettingsData: ExtraAppSettingsData

    override init() {
        settingsUrl = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
            .appendingPathComponent("App Settings")
            .appendingPathComponent("\(bundleIdentifier).plist")
        do {
            let data = try Data(contentsOf: settingsUrl)
            settingsData = try PropertyListDecoder().decode(AppSettingsData.self, from: data)
        } catch {
            settingsData = AppSettingsData()
            print("[PlayTools] PlaySettings decode failed.\n%@")
        }

        extraSettingsUrl = URL(fileURLWithPath: "/Users/\(NSUserName())/Library/Containers/io.playcover.PlayCover")
           .appendingPathComponent("App Settings")
           .appendingPathComponent("\(bundleIdentifier).extra.plist")
        do {
           let data = try Data(contentsOf: extraSettingsUrl)
           extraSettingsData = try PropertyListDecoder().decode(ExtraAppSettingsData.self, from: data)
        } catch {
           extraSettingsData = ExtraAppSettingsData()
           print("[PlayTools] Extra PlaySettings decode failed.\n%@")
        }

        if extraSettingsData.enhanceBuiltinMouse {
            settingsData.disableBuiltinMouse = false
        }
    }

    @objc lazy var forceQuitAppOnClose = extraSettingsData.forceQuitAppOnClose

    @objc lazy var unrealEngineSetScaleFactor = extraSettingsData.unrealEngineSetScaleFactor

    @objc lazy var ignoreClicksWhenNotFocused = extraSettingsData.ignoreClicksWhenNotFocused

    @objc lazy var enhanceBuiltinMouse = extraSettingsData.enhanceBuiltinMouse

    @objc lazy var preventKeyboardBeepSound = extraSettingsData.preventKeyboardBeepSound

    @objc lazy var fixPlayChainMatchLimit = extraSettingsData.fixPlayChainMatchLimit

    @objc lazy var unityEngineFixKeyboardInput = extraSettingsData.unityEngineFixKeyboardInput

    @objc lazy var disableINTLUtilsSwizzling = extraSettingsData.disableINTLUtilsSwizzling

    @objc lazy var unityEngineForceLandscape = extraSettingsData.unityEngineForceLandscape

    @objc lazy var unrealEngineSmartTextInput = extraSettingsData.unrealEngineSmartTextInput

    @objc lazy var webViewSmartTextInput = extraSettingsData.webViewSmartTextInput

    @objc lazy var unityEngineIgnoreKeyboardDelegateCrash = extraSettingsData.unityEngineIgnoreKeyboardDelegateCrash

    @objc lazy var preloadAppTrackingFramework = extraSettingsData.preloadAppTrackingFramework

    @objc lazy var skipGameCenterLogin = extraSettingsData.skipGameCenterLogin

    @objc lazy var unityEngineDisableOrientationCheck = extraSettingsData.unityEngineDisableOrientationCheck

    @objc lazy var unityEngineDisableAROverlayTouches = extraSettingsData.unityEngineDisableAROverlayTouches

    @objc lazy var forceWebViewUseMobileContentMode = extraSettingsData.forceWebViewUseMobileContentMode

    @objc lazy var bypassUnknownDetectionA = extraSettingsData.bypassUnknownDetectionA

    @objc lazy var enableAutoRotate = extraSettingsData.enableAutoRotate

    @objc lazy var forceUIViewLandscape = extraSettingsData.forceUIViewLandscape

    @objc lazy var forceUIViewLandscapeArgs = extraSettingsData.forceUIViewLandscapeArgs

    @objc lazy var useBuiltinPointerLock = extraSettingsData.useBuiltinPointerLock

    @objc lazy var clearLastTouchesWhenEnterTextInput = extraSettingsData.clearLastTouchesWhenEnterTextInput

    @objc lazy var disableAllAlertDialogs = extraSettingsData.disableAllAlertDialogs

    @objc lazy var dontInterceptClicksInUIViews = extraSettingsData.dontInterceptClicksInUIViews

    @objc lazy var dontInterceptClicksInUIViewsArgs = extraSettingsData.dontInterceptClicksInUIViewsArgs

    @objc lazy var unityEngineFixAutoRotate = extraSettingsData.unityEngineFixAutoRotate

    @objc lazy var useNewHitTestMethodWhenNilWindow = extraSettingsData.useNewHitTestMethodWhenNilWindow

    @objc lazy var useNewHitTestMethodAlways = extraSettingsData.useNewHitTestMethodAlways

    @objc lazy var racingMasterFixFilePath = extraSettingsData.racingMasterFixFilePath

    @objc lazy var fortniteFixNonMainThreadCrash = extraSettingsData.fortniteFixNonMainThreadCrash

    @objc lazy var fortniteDisableOptionKey = extraSettingsData.fortniteDisableOptionKey

    @objc lazy var fixPlayChainAccessGroup = extraSettingsData.fixPlayChainAccessGroup

    @objc lazy var supportMultipleMice = extraSettingsData.supportMultipleMice

    @objc lazy var bypassOnDemandResources = extraSettingsData.bypassOnDemandResources

    @objc lazy var disableBuiltinKeyboard = extraSettingsData.disableBuiltinKeyboard

    @objc lazy var disableBuiltinGamepad = extraSettingsData.disableBuiltinGamepad

    @objc lazy var nikkeTTSMiniGameRemapRightShift = extraSettingsData.nikkeTTSMiniGameRemapRightShift

    lazy var discordActivity = settingsData.discordActivity

    lazy var keymapping = settingsData.keymapping

    lazy var notch = settingsData.notch

    lazy var sensitivity = settingsData.sensitivity / 100

    @objc lazy var bypass = settingsData.bypass

    @objc lazy var windowSizeHeight = CGFloat(settingsData.windowHeight)

    @objc lazy var windowSizeWidth = CGFloat(settingsData.windowWidth)

    @objc lazy var inverseScreenValues = settingsData.inverseScreenValues

    @objc lazy var adaptiveDisplay = settingsData.resolution == 0 ? false : true

    @objc lazy var resizableWindow = settingsData.resolution == 6 ? true : false

    @objc lazy var deviceModel = settingsData.iosDeviceModel as NSString

    @objc lazy var oemID: NSString = {
        switch settingsData.iosDeviceModel {
        case "iPad6,7":
            return "J98aAP"
        case "iPad8,6":
            return "J320xAP"
        case "iPad13,8":
            return "J522AP"
        case "iPad14,5":
            return "A2436"
        case "iPad16,6":
            return "A2925"
        case "iPad17,4":
            return "J821AP"
        case "iPhone14,3":
            return "A2645"
        case "iPhone15,3":
            return "A2896"
        case "iPhone16,2":
            return "A2849"
        case "iPhone17,2":
            return "A3084"
        default:
            return "J320xAP"
        }
    }()

    @objc lazy var playChain = settingsData.playChain

    @objc lazy var playChainDebugging = settingsData.playChainDebugging

    @objc lazy var windowFixMethod = settingsData.windowFixMethod

    @objc lazy var customScaler = settingsData.customScaler

    @objc lazy var rootWorkDir = settingsData.rootWorkDir

    @objc lazy var noKMOnInput = settingsData.noKMOnInput

    @objc lazy var enableScrollWheel = settingsData.enableScrollWheel

    @objc lazy var hideTitleBar = settingsData.hideTitleBar

    @objc lazy var floatingWindow = settingsData.floatingWindow

    @objc lazy var displayRotation = settingsData.displayRotation

    @objc lazy var checkMicPermissionSync = settingsData.checkMicPermissionSync

    @objc lazy var limitMotionUpdateFrequency = settingsData.limitMotionUpdateFrequency

    @objc lazy var disableBuiltinMouse = settingsData.disableBuiltinMouse

    @objc lazy var blockSleepSpamming = settingsData.blockSleepSpamming
}

struct AppSettingsData: Codable {
    var keymapping = true
    var sensitivity: Float = 50

    var disableTimeout = false
    var iosDeviceModel = "iPad13,8"
    var windowWidth = 1920
    var windowHeight = 1080
    var customScaler = 2.0
    var resolution = 2
    var aspectRatio = 1
    var displayRotation = 0
    var notch = false
    var bypass = false
    var discordActivity = DiscordActivity()
    var version = "2.0.0"
    var playChain = false
    var playChainDebugging = false
    var inverseScreenValues = false
    var windowFixMethod = 0
    var rootWorkDir = true
    var noKMOnInput = false
    var enableScrollWheel = true
    var hideTitleBar = false
    var floatingWindow = false
    var checkMicPermissionSync = false
    var limitMotionUpdateFrequency = false
    var disableBuiltinMouse = false
    var resizableAspectRatioType = 0
    var resizableAspectRatioWidth = 0
    var resizableAspectRatioHeight = 0
    var blockSleepSpamming = false
}

struct ExtraAppSettingsData: Codable {
    var forceQuitAppOnClose = false
    var unrealEngineSetScaleFactor = false
    var enableCustomCursor = false
    var customCursorWidth = 32
    var customCursorHeight = 32
    var customCursorHotSpotX = 0
    var customCursorHotSpotY = 0
    var ignoreClicksWhenNotFocused = true
    var enhanceBuiltinMouse = false
    var preventKeyboardBeepSound = false
    var fixPlayChainMatchLimit = true
    var unityEngineFixKeyboardInput = false
    var disableINTLUtilsSwizzling = false
    var unityEngineForceLandscape = false
    var unrealEngineSmartTextInput = false
    var webViewSmartTextInput = true
    var unityEngineIgnoreKeyboardDelegateCrash = false
    var preloadAppTrackingFramework = false
    var skipGameCenterLogin = false
    var unityEngineDisableOrientationCheck = false
    var unityEngineDisableAROverlayTouches = false
    var forceWebViewUseMobileContentMode = false
    var bypassUnknownDetectionA = false
    var enableAutoRotate = false
    var forceUIViewLandscape = false
    var forceUIViewLandscapeArgs: [String] = []
    var useBuiltinPointerLock = false
    var clearLastTouchesWhenEnterTextInput = false
    var disableAllAlertDialogs = false
    var dontInterceptClicksInUIViews = false
    var dontInterceptClicksInUIViewsArgs: [String] = []
    var unityEngineFixAutoRotate = false
    var useNewHitTestMethodWhenNilWindow = true
    var useNewHitTestMethodAlways = false
    var racingMasterFixFilePath = false
    var fortniteFixNonMainThreadCrash = false
    var fortniteDisableOptionKey = false
    var fixPlayChainAccessGroup = false
    var supportMultipleMice = false
    var bypassOnDemandResources = false
    var disableBuiltinKeyboard = false
    var disableBuiltinGamepad = false
    var nikkeTTSMiniGameRemapRightShift = false
}
