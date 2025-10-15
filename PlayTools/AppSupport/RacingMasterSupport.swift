//
//  RacingMasterSupport.swift
//  PlayTools
//

class RacingMasterSupport: AppSupport {
    required init() {
        should_fix_available_memory = true
    }

    override func postLaunch() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }

        let userName = NSUserName()

        let srcPath = "/Users/\(userName)/Library/Containers/\(bundleID)/Data/Library" +
            "/Users/\(userName)/Documents/Containers/\(bundleID)/Data"

        let destPath = "/Users/\(userName)/Library/Containers/\(bundleID)/Data"

        PlayCover.createSymbolicLink(source: URL(fileURLWithPath: srcPath),
                                     destination: URL(fileURLWithPath: destPath))
    }
}
