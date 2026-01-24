//
//  IdentityVSupport.swift
//  PlayTools
//

class IdentityVSupport: AppSupport {
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
            // This NeoX engine will access the wrong paths like /private/Users/$USER/Library/Containers.
            // The following patch replaces the constant string '/private' with '/'.
            if patcher.patch(dataToFind: Data([0x00, 0x2F, 0x70, 0x72, 0x69, 0x76, 0x61, 0x74, 0x65, 0x00]),
                             dataToWrite: Data([0x00, 0x2F, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00])) {
                modified = true
            }
            if patcher.patch(dataToFind: Data([0xF4, 0x05, 0x8E, 0xD2, 0x54, 0x2E, 0xAD, 0xF2,
                                               0xD4, 0x2E, 0xCC, 0xF2, 0x94, 0xAE, 0xEC, 0xF2]),
                             dataToWrite: Data([0x08, 0x00, 0x80, 0xD2]),
                             offset: 48) {
                modified = true
            }
            patcher.close()
        }
        return modified
    }
}
