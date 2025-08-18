//
//  Patcher.swift
//  PlayTools
//  

class Patcher {
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

    func close() {
        try? fileHandle.close()
    }
}
