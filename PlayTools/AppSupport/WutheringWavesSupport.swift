//
//  WutheringWavesSupport.swift
//  PlayTools
//

class WutheringWavesSupport: AppSupport {
    override func applyPatch() -> Bool {
        if isPatched() {
            return false
        } else {
            setPatched()
        }

        var modified = false
        if let patcher = Patcher(filePath: Bundle.main.executablePath) {
            // os_proc_available_memory() always return 0 in Mac Catalyst.
            // Patch it to constantly return 4GB.
            if let addr = try? patcher.getCFuncStubAddr("_os_proc_available_memory") {
                if patcher.patch(dataToWrite: Data([0x20, 0x00, 0xC0, 0xD2, 0xC0, 0x03, 0x5F, 0xD6]),
                                 addr: Int(addr)) {
                    modified = true
                }
            }
            patcher.close()
        }
        return modified
    }
}
