//
//  StellaSoraSuport.swift
//  PlayTools
//

class StellaSoraSupport: AppSupport {
    required init() {
        // Fix crash issue
        PlaySettings.shared.blockSleepSpamming = true
    }
}
