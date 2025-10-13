//
//  EggyPartySupport.swift
//  PlayTools
//

class EggyPartySupport: AppSupport {
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
            patcher.close()
        }
        return modified
    }
}
