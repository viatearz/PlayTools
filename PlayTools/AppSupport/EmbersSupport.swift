//
//  EmbersSupport.swift
//  PlayTools
//

class EmbersSupport: AppSupport {
    override func applyPatch() -> Bool {
        guard let frameworkNameBytes = Data(base64Encoded: "YWNlcnQy") else { return false }
        guard let frameworkName = String(data: frameworkNameBytes, encoding: .utf8) else { return false }
        if isFrameworkPatched(frameworkName) {
            return false
        } else {
            setFrameworkPatched(frameworkName)
        }

        var modified = false
        if let patcher = Patcher(filePath: getFrameworkURL(frameworkName).path) {
            // Fix crash issue
            if patcher.patch(dataToFind: Data([0x77, 0x05, 0x00, 0xB4, 0xF4, 0x03, 0x02, 0xAA,
                                               0xF5, 0x03, 0x01, 0xAA, 0xF3, 0x03, 0x00, 0xAA,
                                               0x16, 0x00, 0x80, 0x52, 0x28, 0x00, 0x80, 0x52]),
                             dataToWrite: Data([0x1F, 0x20, 0x03, 0xD5]),
                             offset: 168) {
                patcher.sign()
                modified = true
            }
            patcher.close()
        }
        return modified
    }
}
