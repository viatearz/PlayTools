//
//  RacingMasterSupport.swift
//  PlayTools
//

class RacingMasterSupport: AppSupport {
    required init() {
        should_fix_available_memory = true
    }

    override func applyHooks() {
        // Fix login issue by skipping Game Center Login
        self.swizzleInstanceMethod(
            cls: NSClassFromString("GKLocalPlayer"),
            origSelector: NSSelectorFromString("setAuthenticateHandler:"),
            newSelector: #selector(NSObject.hook_RacingMaster_setAuthenticateHandler(_:)))
    }

    override func postLaunch() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        let userName = NSUserName()

        let srcPath = "/Users/\(userName)/Library/Containers/\(bundleID)/Data/Library" +
            "/Users/\(userName)/Documents/Containers/\(bundleID)/Data"

        let destPath = "/Users/\(userName)/Library/Containers/\(bundleID)/Data"

        PlayCover.createSymbolicLink(source: URL(fileURLWithPath: srcPath),
                                     destination: URL(fileURLWithPath: destPath))
    }
}

extension NSObject {
    @objc func hook_RacingMaster_setAuthenticateHandler(_ handler: ((UIViewController?, Error?) -> Void)?) {
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
