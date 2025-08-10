//
//  JinChanChanSupport.swift
//  PlayTools
//

class JinChanChanSupport: AppSupport {
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
