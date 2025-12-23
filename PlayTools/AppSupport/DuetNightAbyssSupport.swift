//
//  DuetNightAbyssSupport.swift
//  PlayTools
//

class DuetNightAbyssSupport: AppSupport {
    required init() {
        // Prevent the beep sound when pressing keys
        PlaySettings.shared.consumeAllKeyEvents = true
    }
}
