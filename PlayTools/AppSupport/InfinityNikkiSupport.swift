//
//  InfinityNikkiSupport.swift
//  PlayTools
//

class InfinityNikkiSupport: AppSupport {
    override func postLaunch() {
        guard let bundleID = Bundle.main.bundleIdentifier else {
            return
        }
        guard let libraryURL = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first else {
            return
        }

        // Delete corrupted version file (file size smaller than 1 KB)
        let versionFileURL = libraryURL.appendingPathComponent("X6Game")
            .appendingPathComponent("Saved")
            .appendingPathComponent("HotUpdate")
            .appendingPathComponent("paperhotupdateprofile.json")
        if let fileSize = FileUtils.getFileSize(versionFileURL), fileSize < 1024 {
            FileUtils.removeFile(versionFileURL)
        }

        // Prevent login crash in global versions: make Measurement directory read-only
        if bundleID.hasSuffix(".infinitynikkien") || bundleID.hasSuffix(".infinitynikkias") {
            let measurementURL = libraryURL
                .appendingPathComponent("Application Support")
                .appendingPathComponent("Google")
                .appendingPathComponent("Measurement")
            if FileUtils.directoryExists(at: measurementURL) {
                FileUtils.clearAllFiles(at: measurementURL)
            } else {
                FileUtils.createDirectory(at: measurementURL)
            }
            FileUtils.setReadOnly(measurementURL)
        }
    }
}
