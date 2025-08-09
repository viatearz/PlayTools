//
//  AppSupportRegistry.swift
//  PlayTools
//

class AppSupportRegistry {
    static var lookup: [String: AppSupport.Type] = [
        "com.proximabeta.nikke": NIKKESupport.self,
        "com.gamamobi.nikke": NIKKESupport.self,
        "com.tencent.nikke": NIKKESupport.self
    ]
}
