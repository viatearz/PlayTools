//
//  GakuenIdolmasterSupport.swift
//  PlayTools
//

class GakuenIdolmasterSupport: AppSupport {
    required init() {
        PlaySettings.shared.resizableWindow = true
        PlaySettings.shared.supportAutoRotate = true
    }
}
