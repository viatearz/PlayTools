//
//  MoonlightBladeSupport.swift
//  PlayTools
//

class MoonlightBladeSupport: AppSupport {
    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Fix window orientation issue
            self.swizzleInstanceMethod(
                cls: NSClassFromString("UnityAppController"),
                origSelector: NSSelectorFromString("createRootViewController"),
                newSelector: #selector(NSObject.hook_MoonlightBlade_createRootViewController)
            )
        }
    }
}

extension NSObject {
    @objc func hook_MoonlightBlade_createRootViewController() -> UIViewController {
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
        return self.hook_MoonlightBlade_createRootViewController()
    }
}
