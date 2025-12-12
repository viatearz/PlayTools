//
//  Patcher.swift
//  PlayTools
//  

class Patcher {
    private let filePath: String
    private let fileHandle: FileHandle
    private let fileData: Data

    init?(filePath: String?) {
        guard let path = filePath else {
            return nil
        }
        guard let fileHandle = FileHandle(forUpdatingAtPath: path) else {
            return nil
        }
        guard let data = try? fileHandle.readToEnd() else {
            try? fileHandle.close()
            return nil
        }
        self.filePath = path
        self.fileHandle = fileHandle
        self.fileData = data
    }

    func patch(dataToFind: Data, dataToWrite: Data, offset: Int = 0) -> Bool {
        guard let range = fileData.range(of: dataToFind) else {
            return false
        }
        let seekPos = range.lowerBound + offset
        guard seekPos >= 0 && seekPos + dataToWrite.count < fileData.count else {
            return false
        }
        do {
            try fileHandle.seek(toOffset: UInt64(seekPos))
            fileHandle.write(dataToWrite)
            return true
        } catch {
            return false
        }
    }

    func sign() {
        guard let cls: AnyClass = NSClassFromString("NSTask") else {
            return
        }
        let task = cls.alloc() as AnyObject
        task.setValue("/usr/bin/codesign", forKey: "launchPath")
        task.setValue(["-fs-", filePath], forKey: "arguments")
        if task.responds(to: NSSelectorFromString("launch")) {
            _ = task.perform(NSSelectorFromString("launch"))
        } else {
            print("[PlayTools] Patcher sign failed: \(filePath)")
        }
    }

    func close() {
        try? fileHandle.close()
    }
}
