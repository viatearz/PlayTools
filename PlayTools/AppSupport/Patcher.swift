//
//  Patcher.swift
//  PlayTools
//

import Foundation
import MachO
import Darwin

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

    func patch(dataToWrite: Data, addr: Int = 0) -> Bool {
        guard addr >= 0 && addr + dataToWrite.count < fileData.count else {
            return false
        }
        do {
            try fileHandle.seek(toOffset: UInt64(addr))
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

    // swiftlint:disable:next cyclomatic_complexity function_body_length
    func getCFuncStubAddr(_ targetSymbol: String) throws -> UInt64? {
        let data = self.fileData
        var symtab: symtab_command!
        var dysymtab: dysymtab_command!
        var stubsSection: section_64!

        // --- Mach-O Header ---
        let header = readStruct(data, 0, as: mach_header_64.self)
        precondition(header.magic == MH_MAGIC_64)

        // --- Load Commands ---
        var offset = MemoryLayout<mach_header_64>.size
        for _ in 0..<header.ncmds {
            let cmd = readStruct(data, offset, as: load_command.self)

            if cmd.cmd == LC_SYMTAB {
                symtab = readStruct(data, offset, as: symtab_command.self)
            }

            if cmd.cmd == LC_DYSYMTAB {
                dysymtab = readStruct(data, offset, as: dysymtab_command.self)
            }

            if cmd.cmd == LC_SEGMENT_64 {
                let seg = readStruct(data, offset, as: segment_command_64.self)
                var secOff = offset + MemoryLayout<segment_command_64>.size

                for _ in 0..<seg.nsects {
                    let sec = readStruct(data, secOff, as: section_64.self)
                    if sec.flags & UInt32(SECTION_TYPE) == S_SYMBOL_STUBS {
                        stubsSection = sec
                        break
                    }
                    secOff += MemoryLayout<section_64>.size
                }
            }

            offset += Int(cmd.cmdsize)
        }

        guard symtab != nil, dysymtab != nil, stubsSection != nil else {
            return nil
        }

        // --- Read Symbol Table ---
        var symbols: [nlist_64] = []
        for idx in 0..<symtab.nsyms {
            let off = Int(symtab.symoff) + Int(idx) * MemoryLayout<nlist_64>.size
            symbols.append(readStruct(data, off, as: nlist_64.self))
        }

        // --- Read String Table ---
        let stringBase = Int(symtab.stroff)
        func symbolName(_ index: UInt32) -> String {
            let symbol = symbols[Int(index)]
            return readCString(data, stringBase + Int(symbol.n_un.n_strx))
        }

        // --- Read Indirect Symbol Table ---
        let indirectCount = dysymtab.nindirectsyms
        var indirect: [UInt32] = []
        for idx in 0..<indirectCount {
            let off = Int(dysymtab.indirectsymoff) + Int(idx) * 4
            indirect.append(readStruct(data, off, as: UInt32.self))
        }

        // --- Find Target Symbol ---
        let start = Int(stubsSection.reserved1)
        let stubSize = Int(stubsSection.reserved2)
        let count = Int(stubsSection.size) / stubSize
        for idx in 0..<count {
            let symbolIndex = indirect[start + idx]

            if symbolIndex == INDIRECT_SYMBOL_LOCAL ||
                symbolIndex == INDIRECT_SYMBOL_ABS {
                continue
            }

            if symbolName(symbolIndex) == targetSymbol {
                return UInt64(stubsSection.offset) + UInt64(stubSize * idx)
            }
        }

        return nil
    }

    private func readStruct<T>(_ data: Data, _ offset: Int, as type: T.Type) -> T {
        return data.withUnsafeBytes {
            $0.load(fromByteOffset: offset, as: T.self)
        }
    }

    private func readCString(_ data: Data, _ offset: Int) -> String {
        var end = offset
        while data[end] != 0 { end += 1 }
        return String(bytes: data[offset..<end], encoding: .utf8) ?? ""
    }
}
