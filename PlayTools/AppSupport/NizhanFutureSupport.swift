//
//  NizhanFutureSupport.swift
//  PlayTools
//

class NizhanFutureSupport: AppSupport {
    required init() {
        PlaySettings.shared.useFloatingJoystick = true
    }

    override func applyPatch() -> Bool {
        if isPatched() {
            return false
        } else {
            setPatched()
        }

        var modified = false
        if let patcher = Patcher(filePath: Bundle.main.executablePath) {
            // Fix Unreal Engine wrong path issue, replace '/var/' with '/User'
            if patcher.patch(dataToFind: Data([0x2F, 0x00, 0x76, 0x00, 0x61, 0x00, 0x72, 0x00,
                                               0x2F, 0x00, 0x00, 0x00]),
                             dataToWrite: Data([0x2F, 0x00, 0x55, 0x00, 0x73, 0x00, 0x65, 0x00,
                                                0x72, 0x00, 0x00, 0x00])) {
                modified = true
            }
            patcher.close()
        }
        return modified
    }
}
