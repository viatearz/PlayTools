//
//  FortniteSupport.swift
//  PlayTools
//

class FortniteSupport: AppSupport {
    required init() {
        should_fix_available_memory = true
    }

    override func applyPatch() -> Bool {
        if isPatched() {
            return false
        } else {
            setPatched()
        }

        var modified = false
        if let patcher = Patcher(filePath: Bundle.main.executablePath) {
            if applyEntitlementPatch(patcher) {
                modified = true
            }
            if applyAvailableMemoryPatch(patcher) {
                modified = true
            }
            patcher.close()
        }
        return modified
    }

    // The following patch forces FIOSPlatformMisc::IsEntitlementEnabled() to return true.
    // On macOS, entitlements are not required to allocate large amounts of memory.
    private func applyEntitlementPatch(_ patcher: Patcher) -> Bool {
        var modified = false
        let pattern = Data([0xF4, 0x03, 0x00, 0xAA, 0xE2, 0x03, 0x00, 0x2A, 0xE0, 0x03, 0x00, 0x91,
                            0xE1, 0x03, 0x13, 0xAA, 0x03, 0x00, 0x80, 0x52, 0x04, 0x00, 0x80, 0x52])
        // MOV W0, #0
        if patcher.patch(dataToFind: pattern,
                         dataToWrite: Data([0x00, 0x00, 0x80, 0x52]),
                         offset: pattern.count) {
            modified = true
        }
        // MOV X0, #1
        if patcher.patch(dataToFind: pattern,
                         dataToWrite: Data([0x20, 0x00, 0x80, 0xD2]),
                         offset: pattern.count + 4 * 16) {
            modified = true
        }
        return modified
    }

    // os_proc_available_memory() always return zero in FApplePlatformMemory::GetConstants().
    // The following patch assigns the correct value to MemoryConstants.TotalPhysical.
    // And FApplePlatformMemory::GetConstants() is called too early,
    // we have no chance to fix this issue by DYLD_INTERPOSE(os_proc_available_memory).
    private func applyAvailableMemoryPatch(_ patcher: Patcher) -> Bool {

        // MOV X0, #0x100000000 * imm16
        let imm16 = UInt16(ProcessInfo.processInfo.physicalMemory / (1 << 32))
        let instruction = UInt32(0xD2C00000) | (UInt32(imm16) << 5)
        var patch = [UInt8](repeating: 0, count: 4)
        for idx in 0..<4 {
            patch[idx] = UInt8((instruction >> (8 * idx)) & 0xFF)
        }

        if patcher.patch(dataToFind: Data([0xF3, 0x03, 0x00, 0xAA, 0xE8, 0x01, 0x80, 0x52,
                                           0xA8, 0xC3, 0x1E, 0xB8, 0xBF, 0x03, 0x1E, 0xF8,
                                           0xA1, 0x83, 0x00, 0xD1]),
                         dataToWrite: Data(patch),
                         offset: 4 * -23) {
            return true
        }
        return false
    }
}
