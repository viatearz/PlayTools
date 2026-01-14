//
//  ThreeKingdomsTacticsSupport.swift
//  PlayTools
//

import WebKit

class ThreeKingdomsTacticsSupport: AppSupport {
    override func applyPatch() -> Bool {
        if isPatched() {
            return false
        } else {
            setPatched()
        }

        var modified = false
        if let patcher = Patcher(filePath: Bundle.main.executablePath) {
            // Fix hang issue by disabling CRIWARE SonicSYNC
            if patcher.patch(dataToFind: Data([0x00, 0x00, 0xC0, 0x3D, 0x60, 0x02, 0x80, 0x3D,
                                               0x00, 0x84, 0x40, 0xAD, 0x02, 0x8C, 0x41, 0xAD,
                                               0x62, 0x8E, 0x01, 0xAD, 0x60, 0x86, 0x00, 0xAD,
                                               0x00, 0x84, 0x42, 0xAD, 0x02, 0x1C, 0xC0, 0x3D]),
                             dataToWrite: Data([0x1F, 0x00, 0x00, 0xB9]),
                             offset: -4) {
                modified = true
            }
            patcher.close()
        }
        return modified
    }

    override func applyHooks() {
        // Fix captcha not showing issue
        self.swizzleInstanceMethod(
            cls: NSClassFromString("WKWebView"),
            origSelector: NSSelectorFromString("initWithFrame:configuration:"),
            newSelector: #selector(NSObject.hook_ThreeKingdomsTactics_initWKWebView(frame:configuration:)))
    }
}

extension NSObject {
    @objc func hook_ThreeKingdomsTactics_initWKWebView(
        frame: CGRect,
        configuration: WKWebViewConfiguration
    ) -> WKWebView {
        let webView = self.hook_ThreeKingdomsTactics_initWKWebView(frame: frame, configuration: configuration)
        webView.configuration.defaultWebpagePreferences.preferredContentMode = .mobile
        return webView
    }
}
