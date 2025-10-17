//
//  ThreeKingdomsTacticsSupport.swift
//  PlayTools
//

class ThreeKingdomsTacticsSupport: AppSupport {
    override func applyPatch() -> Bool {
        if isPatched() {
            return false
        } else {
            setPatched()
        }

        var modified = false
        if let patcher = Patcher(filePath: Bundle.main.executablePath) {
            // Fix hang issue by disabling CRIWARE SonicSYNC
            if patcher.patch(dataToFind: Data([0x00, 0x00, 0xC0, 0x3D, 0x60, 0x02, 0x80, 0x3D,
                                               0x00, 0x84, 0x40, 0xAD, 0x02, 0x8C, 0x41, 0xAD,
                                               0x62, 0x8E, 0x01, 0xAD, 0x60, 0x86, 0x00, 0xAD,
                                               0x00, 0x84, 0x42, 0xAD, 0x02, 0x1C, 0xC0, 0x3D]),
                             dataToWrite: Data([0x1F, 0x00, 0x00, 0xB9]),
                             offset: -4) {
                modified = true
            }
            patcher.close()
        }
        return modified
    }
}
