//
//  AppSupportRegistry.swift
//  PlayTools
//

class AppSupportRegistry {
    static var lookup: [String: AppSupport.Type] = [
        "com.proximabeta.nikke": NIKKESupport.self
    ]
}
