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
        "com.tencent.jkchess": JinChanChanSupport.self,
        "com.Nekootan.kfkj.apple": OverFieldSupport.self,
        "com.netease.party": EggyPartySupport.self,
        "com.epicgames.FortniteGame": FortniteSupport.self,
        "com.tencent.wuxia": MoonlightBladeSupport.self,
        "com.netease.id5": IdentityVSupport.self,
        "com.ProjectMoon.LimbusCompany": LimbusCompanySupport.self,
        "jp.co.bandainamcoent.BNEI0421": GakuenIdolmasterSupport.self,
        "com.papegames.lysk": LoveAndDeepspaceSupport.self,
        "com.papegames.lysk.en": LoveAndDeepspaceSupport.self,
        "com.papegames.lysk.jp": LoveAndDeepspaceSupport.self,
        "com.netease.rc": RacingMasterSupport.self,
        "com.netease.dfjssea": RacingMasterSupport.self,
        "com.netease.dfjsjp": RacingMasterSupport.self,
        "com.netease.g108": DestinyRisingSupport.self,
        "com.netease.g108na": DestinyRisingSupport.self,
        "com.netease.g108hmt": DestinyRisingSupport.self,
        "com.netease.g138": UnVEILTheWorldSupport.self,
        "com.netease.g138na": UnVEILTheWorldSupport.self,
    ]
}
