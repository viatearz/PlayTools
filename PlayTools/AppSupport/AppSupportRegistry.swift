//
//  AppSupportRegistry.swift
//  PlayTools
//

class AppSupportRegistry {
    static var lookup: [String: AppSupport.Type] = [
        "com.proximabeta.nikke": NIKKESupport.self,
        "com.gamamobi.nikke": NIKKESupport.self,
        "com.tencent.nikke": NIKKESupport.self,
        "com.papegames.infinitynikki": InfinityNikkiSupport.self,
        "com.infoldgames.infinitynikkien": InfinityNikkiSupport.self,
        "com.infoldgames.infinitynikkias": InfinityNikkiSupport.self,
        "com.tencent.jkchess": JinChanChanSupport.self
    ]
}
