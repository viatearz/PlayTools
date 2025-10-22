//
//  SevenDeadlySinsSupport.swift
//  PlayTools
//

class SevenDeadlySinsSuport: AppSupport {
    required init() {
        if PlaySettings.shared.adaptiveDisplay || PlaySettings.shared.windowFixMethod != 1 {
            PlaySettings.shared.resizableWindow = true
        }

        PlaySettings.shared.useFloatingJoystick = true
    }

    override func applyHooks() {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Fix endless loading issue by skipping Game Center Login
            self.swizzleInstanceMethod(
                cls: NSClassFromString("GKLocalPlayer"),
                origSelector: NSSelectorFromString("setAuthenticateHandler:"),
                newSelector: #selector(NSObject.hook_SevenDeadlySins_setAuthenticateHandler(_:)))
        }
    }
}

extension NSObject {
    @objc func hook_SevenDeadlySins_setAuthenticateHandler(_ handler: ((UIViewController?, Error?) -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(1)) {
            // Simulate a "user canceled" result
            if let handler = handler {
                let userInfo = [
                    NSLocalizedDescriptionKey: "The requested operation has been cancelled or disabled by the user."
                ]
                let error = NSError(domain: "GKErrorDomain", code: 2, userInfo: userInfo)
                handler(nil, error)
            }
        }
    }
}
