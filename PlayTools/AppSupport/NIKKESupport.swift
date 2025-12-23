//
//  NIKKESupport.swift
//  PlayTools
//

class NIKKESupport: AppSupport {
    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Fix hang issue
            self.swizzleClassMethod(
                cls: NSClassFromString("INTLUtilsIOS"),
                origSelector: NSSelectorFromString("swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:"),
                newSelector: #selector(NSObject.hook_INTLUtilsIOS_swizzling(
                    originalClass:swizzledClass:originalSEL:swizzledSEL:))
            )

            // Fix window orientation issue
            if PlaySettings.shared.adaptiveDisplay {
                self.swizzleInstanceMethod(
                    cls: NSClassFromString("UnityAppController"),
                    origSelector: NSSelectorFromString("createRootViewController"),
                    newSelector: #selector(NSObject.hook_NIKKE_createRootViewController)
                )

                self.swizzleInstanceMethod(
                    cls: NSClassFromString("UnityAppController"),
                    origSelector: NSSelectorFromString("checkOrientationRequest"),
                    newSelector: #selector(NSObject.hook_NIKKE_checkOrientationRequest)
                )
            }
        }
    }
}

extension NSObject {
    @objc static func hook_INTLUtilsIOS_swizzling(originalClass: AnyClass,
                                                  swizzledClass: AnyClass,
                                                  originalSEL: Selector,
                                                  swizzledSEL: Selector) -> Bool {
        // Do nothing
        return false
    }

    @objc func hook_NIKKE_createRootViewController() -> UIViewController {
        // Calling [UnityAppController createRootViewControllerForOrientation:UIInterfaceOrientationLandscapeLeft]
        let selector = NSSelectorFromString("createRootViewControllerForOrientation:")
        if self.responds(to: selector) {
            if let imp = self.method(for: selector) {
                typealias Function = @convention(c) (AnyObject, Selector, UIInterfaceOrientation) -> UIViewController
                let function = unsafeBitCast(imp, to: Function.self)
                return function(self, selector, .landscapeLeft)
            }
        }
        // If it fails, fall back to the original implementation
        return self.hook_NIKKE_createRootViewController()
    }

    @objc func hook_NIKKE_checkOrientationRequest() {
        // Unity calls this every frame, disable it to prevent restoring to portrait
    }
}
