//
//  DuetNightAbyssSupport.swift
//  PlayTools
//

class DuetNightAbyssSupport: AppSupport {
    required init() {
        // Prevent the beep sound when pressing keys
        PlaySettings.shared.consumeAllKeyEvents = true
        // Fix crash or hang issue
        PlaySettings.shared.blockSleepSpamming = true
    }
}
