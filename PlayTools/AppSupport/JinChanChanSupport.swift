//
//  JinChanChanSupport.swift
//  PlayTools
//

class JinChanChanSupport: AppSupport {
    override func applyPatch() -> Bool {
        if isPatched() {
            return false
        } else {
            setPatched()
        }

        var modified = false
        if let patcher = Patcher(filePath: Bundle.main.executablePath) {
            // This game calls UnityEngine.Application.HasUserAuthorization().
            // However HasUserAuthorization() always return false due to missing #define UNITY_USES_MICROPHONE.
            // The following patch forces HasUserAuthorization() to return true.
            // (It is better to ask the game developers to remove the HasUserAuthorization() check.)
            if patcher.patch(dataToFind: Data([0x7F, 0x0A, 0x00, 0x71, 0x93, 0x02, 0x88, 0x1A, 0xE0, 0x03, 0x13, 0xAA]),
                             dataToWrite: Data([0x20, 0x00, 0x80, 0xD2]),
                             offset: 8) {
                modified = true
            }
            patcher.close()
        }
        return modified
    }

    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Fix web view orientation issue
            self.swizzleInstanceMethod(
                cls: NSClassFromString("MSDKBaseWebViewController"),
                origSelector: #selector(getter: UIViewController.supportedInterfaceOrientations),
                newSelector: #selector(NSObject.hook_JinChanChan_supportedInterfaceOrientations)
            )
        }
    }
}

extension NSObject {
    @objc func hook_JinChanChan_supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return .landscape
    }
}
