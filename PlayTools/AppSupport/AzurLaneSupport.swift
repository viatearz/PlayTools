//
//  AzurLaneSupport.swift
//  PlayTools
//

class AzurLaneSupport: AppSupport {
    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            self.swizzleInstanceMethod(
                cls: NSClassFromString("ARCoachingOverlayView"),
                origSelector: NSSelectorFromString("initWithFrame:"),
                newSelector: #selector(UIView.hook_AzurLane_AROverlay_initWithFrame(_:)))
        }
    }
}

extension UIView {
    @objc func hook_AzurLane_AROverlay_initWithFrame(_ frame: CGRect) -> UIView {
        let instance = self.hook_AzurLane_AROverlay_initWithFrame(frame)
        instance.isUserInteractionEnabled = false
        return instance
    }
}
