//
//  LoveAndDeepspaceSupport.swift
//  PlayTools
//

class LoveAndDeepspaceSupport: AppSupport {
    required init() {
        PlaySettings.shared.resizableWindow = true
        PlaySettings.shared.supportAutoRotate = true
    }

    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Fix window not rotating issue
            self.swizzleInstanceMethod(
                cls: NSClassFromString("UnityAppController"),
                origSelector: NSSelectorFromString("didTransitionToViewController:fromViewController:"),
                newSelector: #selector(NSObject.hook_LoveAndDeepspace_didTransition(
                    toViewController:fromViewController:))
            )
        }
    }
}

extension NSObject {
    @objc func hook_LoveAndDeepspace_didTransition(toViewController: UIViewController?,
                                                   fromViewController: UIViewController?) {
        let orientation = self.value(forKey: "_curOrientation") as? Int

        self.hook_LoveAndDeepspace_didTransition(toViewController: toViewController,
                                                 fromViewController: fromViewController)

        // The previous call sets an incorrect orientation, revert it to the original value
        if let value = orientation {
            self.setValue(value, forKey: "_curOrientation")
        }
    }
}
