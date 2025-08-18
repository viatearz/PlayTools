//
//  AppSupport.swift
//  PlayTools
//

@objc class AppSupport: NSObject {
    required override init() { }

    func postLaunch() { }

    @objc func applyPatch() -> Bool { return false }

    @objc func applyHooks() { }

    func isPatched() -> Bool {
        return Bundle.main.infoDictionary?["__PATCHED__"] != nil
    }

    func setPatched() {
        if let infoPlistPath = Bundle.main.path(forResource: "Info", ofType: "plist"),
           let dict = NSMutableDictionary(contentsOfFile: infoPlistPath) {
            dict["__PATCHED__"] = true
            dict.write(toFile: infoPlistPath, atomically: true)
        }
    }
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

extension AppSupport {
    @objc func swizzleInstanceMethod(cls: AnyClass?, origSelector: Selector, newSelector: Selector) {
        guard let originalMethod = class_getInstanceMethod(cls, origSelector),
              let swizzledMethod = class_getInstanceMethod(cls, newSelector) else {
            return
        }

        if class_addMethod(cls,
                           origSelector,
                           method_getImplementation(swizzledMethod),
                           method_getTypeEncoding(swizzledMethod)) {
            class_replaceMethod(cls,
                                newSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod))

        } else {
            if let imp = class_replaceMethod(cls,
                                             origSelector,
                                             method_getImplementation(swizzledMethod),
                                             method_getTypeEncoding(swizzledMethod)) {
                class_replaceMethod(cls,
                                    newSelector,
                                    imp,
                                    method_getTypeEncoding(originalMethod))
            }
        }
    }

    @objc func swizzleClassMethod(cls: AnyClass?,
                                  origSelector: Selector,
                                  newSelector: Selector) {
        guard let originalMethod = class_getClassMethod(cls, origSelector),
              let swizzledMethod = class_getClassMethod(cls, newSelector) else {
            return
        }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }
}
