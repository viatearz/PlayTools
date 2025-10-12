//
//  AppSupport.swift
//  PlayTools
//

@objc class AppSupport: NSObject {
    required override init() { }

    func postLaunch() { }

    @objc func applyPatch() -> Bool { return false }

    @objc func applyHooks() { }
}

extension AppSupport {
    @objc static var instance: AppSupport = {
        if let id = Bundle.main.bundleIdentifier,
           let cls = AppSupportRegistry.lookup[id] {
            return cls.init()
        }
        return AppSupport()
    }()
}
