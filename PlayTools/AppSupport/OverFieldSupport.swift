//
//  OverFieldSupport.swift
//  PlayTools
//

class OverFieldSupport: AppSupport {
    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Bypass some detections
            self.swizzleInstanceMethod(
                cls: NSClassFromString("o0_ooo0o0"),
                origSelector: NSSelectorFromString("o0_oaoao0"),
                newSelector: #selector(NSObject.hook_OverField_o0_oaoao0)
            )
        }
    }
}

extension NSObject {
    @objc func hook_OverField_o0_oaoao0() {
        // Do nothing
    }
}
