//
//  StellaSoraSuport.swift
//  PlayTools
//

class StellaSoraSupport: AppSupport {
    override func applyPatch() -> Bool {
        var modified = false
        for encodedName in ["YWNlcnR4", "YW5vcnR4"] {
            guard let frameworkNameBytes = Data(base64Encoded: encodedName) else { continue }
            guard let frameworkName = String(data: frameworkNameBytes, encoding: .utf8) else { continue }
            if isFrameworkPatched(frameworkName) {
                continue
            } else {
                setFrameworkPatched(frameworkName)
            }

            if let patcher = Patcher(filePath: getFrameworkURL(frameworkName).path) {
                // Fix crash issue
                if patcher.patch(dataToFind: Data([0xF3, 0x03, 0x00, 0xAA, 0x16, 0x00, 0x80, 0x52,
                                                   0x14, 0xE2, 0x84, 0x52, 0x35, 0x48, 0x88, 0x52,
                                                   0xF5, 0x01, 0xA0, 0x72, 0xDF, 0x02, 0x14, 0x6B,
                                                   0x60, 0x00, 0x00, 0x54]),
                                 dataToWrite: Data([0x20, 0x00, 0x80, 0xD2, 0xC0, 0x03, 0x5F, 0xD6]),
                                 offset: -28) {
                    patcher.sign()
                    modified = true
                }
                patcher.close()
            }
        }
        return modified
    }
}
