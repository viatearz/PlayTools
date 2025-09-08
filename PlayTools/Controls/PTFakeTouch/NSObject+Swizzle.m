//
//  NSObject+PrivateSwizzle.m
//  PlayTools
//
//  Created by siri on 06.10.2021.
//

#import "NSObject+Swizzle.h"
#import "PlayLoader.h"
#import <objc/runtime.h>
#import "CoreGraphics/CoreGraphics.h"
#import "UIKit/UIKit.h"
#import <PlayTools/PlayTools-Swift.h>
#import "PTFakeMetaTouch.h"
#import <VideoSubscriberAccount/VideoSubscriberAccount.h>
#import <CoreMotion/CoreMotion.h>
#import <AVFoundation/AVFoundation.h>
#import <GameController/GameController.h>

__attribute__((visibility("hidden")))
@interface PTSwizzleLoader : NSObject
@end

__attribute__((visibility("hidden")))
@interface PTBinaryPatcher : NSObject
+ (BOOL)applyPatch;
@end

@implementation NSObject (Swizzle)

- (void) swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    // If current class doesn't exist selector, then get super
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    // Add selector if it doesn't exist, implement append with method
    if (class_addMethod(cls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        // Replace class instance method, added if selector not exist
        // For class cluster, it always adds new selector here
        class_replaceMethod(cls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
        
    } else {
        // SwizzleMethod maybe belongs to super
        class_replaceMethod(cls,
                            newSelector,
                            class_replaceMethod(cls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

- (void) swizzleExchangeMethod:(SEL)origSelector withMethod:(SEL)newSelector
{
    Class cls = [self class];
    // If current class doesn't exist selector, then get super
    Method originalMethod = class_getInstanceMethod(cls, origSelector);
    Method swizzledMethod = class_getInstanceMethod(cls, newSelector);
    
    method_exchangeImplementations(originalMethod, swizzledMethod);
}

+ (void) swizzleClassMethod:(SEL)origSelector withMethod:(SEL)newSelector {
    Class cls = object_getClass((id)self);
    Method originalMethod = class_getClassMethod(cls, origSelector);
    Method swizzledMethod = class_getClassMethod(cls, newSelector);

    if (class_addMethod(cls,
                        origSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod)) ) {
        class_replaceMethod(cls,
                            newSelector,
                            method_getImplementation(originalMethod),
                            method_getTypeEncoding(originalMethod));
    } else {
        class_replaceMethod(cls,
                            newSelector,
                            class_replaceMethod(cls,
                                                origSelector,
                                                method_getImplementation(swizzledMethod),
                                                method_getTypeEncoding(swizzledMethod)),
                            method_getTypeEncoding(originalMethod));
    }
}

- (BOOL) hook_prefersPointerLocked {
    return false;
}

- (CGRect) hook_frameDefault {
    return [PlayScreen frameDefault:[self hook_frameDefault]];
}

- (CGRect) hook_boundsDefault {
    return [PlayScreen boundsDefault:[self hook_boundsDefault]];
}

- (CGRect) hook_nativeBoundsDefault {
    return [PlayScreen nativeBoundsDefault:[self hook_nativeBoundsDefault]];
}

- (CGSize) hook_sizeDelfault {
    return [PlayScreen sizeAspectRatioDefault:[self hook_sizeDelfault]];
}


- (CGRect) hook_frame {
    return [PlayScreen frame:[self hook_frame]];
}

- (CGRect) hook_bounds {
    return [PlayScreen bounds:[self hook_bounds]];
}

- (CGRect) hook_nativeBounds {
    return [PlayScreen nativeBounds:[self hook_nativeBounds]];
}

- (CGSize) hook_size {
    return [PlayScreen sizeAspectRatio:[self hook_size]];
}



- (long long) hook_orientation {
    return 0;
}

- (double) hook_nativeScale {
    return [[PlaySettings shared] customScaler];
}

- (double) hook_scale {
    // Return rounded value of [[PlaySettings shared] customScaler]
    // Even though it is a double return, this will only accept .0 value or apps will crash
    return round([[PlaySettings shared] customScaler]);
}

- (double) get_default_height {
    return [[UIScreen mainScreen] bounds].size.height;
    
}
- (double) get_default_width {
    return [[UIScreen mainScreen] bounds].size.width;
    
}

- (void) hook_setCurrentSubscription:(VSSubscription *)currentSubscription {
    // do nothing
}

// Hook for UIUserInterfaceIdiom

// - (long long) hook_userInterfaceIdiom {
//     return UIUserInterfaceIdiomPad;
// }

bool menuWasCreated = false;
- (id) initWithRootMenuHook:(id)rootMenu {
    self = [self initWithRootMenuHook:rootMenu];
    if (!menuWasCreated) {
        [PlayCover initMenuWithMenu: self];
        menuWasCreated = TRUE;
    }
    return self;
}

- (instancetype)hook_CMMotionManager_init {
    CMMotionManager* motionManager = (CMMotionManager*)[self hook_CMMotionManager_init];
    // The default update interval is 0, which may lead to high CPU usage
    motionManager.accelerometerUpdateInterval = 0.01;
    motionManager.deviceMotionUpdateInterval = 0.01;
    motionManager.gyroUpdateInterval = 0.01;
    return motionManager;
}

- (NSString *)hook_stringByReplacingOccurrencesOfRegularExpressionPattern:(NSString *)pattern
                                                             withTemplate:(NSString *)template
                                                                  options:(NSRegularExpressionOptions)options
                                                                    range:(NSRange)range {
    // If the string is empty, return immediately to prevent a range out-of-bounds error.
    if ([(NSString*)self isEqualToString:@""]) {
        return @"";
    }
    return [self hook_stringByReplacingOccurrencesOfRegularExpressionPattern:pattern
                                                                withTemplate:template
                                                                     options:options
                                                                       range:range];
}

+ (GCMouse*)hook_GCMouse_current {
    return nil;
}

- (void)hook_requestRecordPermission:(void (^)(BOOL))response {
    BOOL granted = [[AVAudioSession sharedInstance] recordPermission] == AVAudioSessionRecordPermissionGranted;
    if (granted) {
        response(granted);
    } else {
        [self hook_requestRecordPermission:response];
    }
}

+ (void)hook_KeyboardDelegate_Initialize {
    @try {
        [self hook_KeyboardDelegate_Initialize];
    }
    @catch (NSException *exception) {
        NSLog(@"Caught exception: %@, reason: %@", exception.name, exception.reason);
    }
}

- (NSArray*)hook_UnityView_keyCommands {
    NSArray *keyCommands = [self hook_UnityView_keyCommands];
    if (keyCommands) {
        if ([[PlayInput shared] shouldDisableUnityKeyCommands:(UIView *)self]) {
            return nil;
        }
    }
    return keyCommands;
}

+ (BOOL)hook_swizzlingOriginalClass:(Class)originalClass swizzledClass:(Class)swizzledClass originalSEL:(SEL)originalSEL swizzledSEL:(SEL)swizzledSEL {
    // Prevent swizzling [UIApplication setDelegate:] as it will cause NIKKE to hang
    if ([NSStringFromSelector(originalSEL) isEqualToString:@"setDelegate:"] &&
        [NSStringFromSelector(swizzledSEL) isEqualToString:@"webview_setDelegate:"]) {
        return NO;
    }
    return [self hook_swizzlingOriginalClass:originalClass swizzledClass:swizzledClass
                                 originalSEL:originalSEL swizzledSEL:swizzledSEL];
}

- (UIViewController*)hook_UnityAppController_createRootViewController {
    UIViewController* ret = nil;
    // Dynamically call method:
    // [UnityAppController createRootViewControllerForOrientation:UIInterfaceOrientationLandscapeLeft]
    SEL selector = NSSelectorFromString(@"createRootViewControllerForOrientation:");
    if ([self respondsToSelector:selector]) {
        UIViewController* (*func)(id, SEL, UIInterfaceOrientation) = (void *)[self methodForSelector:selector];
        ret = func(self, selector, UIInterfaceOrientationLandscapeLeft);
    }
    // If it fails, fall back to the original implementation
    if (ret == nil) {
        ret = [self hook_UnityAppController_createRootViewController];
    }
    return ret;
}

- (void)hook_UnityAppController_checkOrientationRequest {
    // Unity calls this every frame, disable it to prevent restoring to portrait
}

- (UIInterfaceOrientationMask)hook_jkchess_supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscape;
}

- (void)hook_OverField_o0_ooo0o0 {
    // do nothing
}

@end

/*
 This class only exists to apply swizzles from the +load of a class that won't have any categories/extensions. The reason
 for not doing this in a C module initializer is that obj-c initialization happens before any __attribute__((constructor))
 is called. This way we can guarantee the hooks will be applied before [PlayCover launch] is called (in PlayLoader.m).
 
 Side note:
 While adding method replacements to NSObject does work, I'm not certain this doesn't (or won't) have any side effects. The
 way Apple does method swizzling internally is by creating a category of the swizzled class and adding the replacements there.
 This keeps all those replacements "local" to that class. Example:
 
 '''
 @interface FBSSceneSettings (Swizzle)
 -(CGRect) hook_frame {
    ...
 }
 @end
 
 Somewhere else:
 swizzle(FBSSceneSettings.class, @selector(frame), @selector(hook_frame);
 '''
 
 However, doing this would require generating @interface declarations (either with class-dump or by hand) which would add a lot
 of code and complexity. I'm not sure this trade-off is "worth it", at least at the time of writing.
 */

@implementation PTSwizzleLoader
+ (void)load {
    if ([PTBinaryPatcher applyPatch]) {
        exit(0);
    }

    // This might need refactor soon
    if(@available(iOS 16.3, *)) {
        if ([[PlaySettings shared] adaptiveDisplay]) {
            // This is an experimental fix
            if ([[PlaySettings shared] inverseScreenValues]) {
                // This lines set External Scene settings and other IOS10 Runtime services by swizzling
                // In Sonoma 14.1 betas, frame method seems to be moved to FBSSceneSettingsCore
                if(@available(iOS 17.1, *))
                    [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                else
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_boundsDefault)];
                [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_sizeDelfault)];
                
                // Fixes Apple mess at MacOS 13.2
                [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(orientation) withMethod:@selector(hook_orientation)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeBounds) withMethod:@selector(hook_nativeBoundsDefault)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeScale) withMethod:@selector(hook_nativeScale)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(scale) withMethod:@selector(hook_scale)];
            } else {
                // This acutally runs when adaptiveDisplay is normally triggered
                if(@available(iOS 17.1, *))
                    [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frame)];
                else
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frame)];
                [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_bounds)];
                [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_size)];
                
                [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(orientation) withMethod:@selector(hook_orientation)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeBounds) withMethod:@selector(hook_nativeBounds)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeScale) withMethod:@selector(hook_nativeScale)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(scale) withMethod:@selector(hook_scale)];   
            }
        }
        else {
            if ([[PlaySettings shared] windowFixMethod] == 1) {
                // do nothing:tm:
            }
            else {
                CGFloat newValueW = (CGFloat) [self get_default_width];
                [[PlaySettings shared] setValue:@(newValueW) forKey:@"windowSizeWidth"];
                
                CGFloat newValueH = (CGFloat)[self get_default_height];
                [[PlaySettings shared] setValue:@(newValueH) forKey:@"windowSizeHeight"];
                if (![[PlaySettings shared] inverseScreenValues]) {
                    if(@available(iOS 17.1, *))
                        [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                    else
                        [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frameDefault)];
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_boundsDefault)];
                    [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_sizeDelfault)];
                }
                [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(orientation) withMethod:@selector(hook_orientation)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeBounds) withMethod:@selector(hook_nativeBoundsDefault)];
                
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(nativeScale) withMethod:@selector(hook_nativeScale)];
                [objc_getClass("UIScreen") swizzleInstanceMethod:@selector(scale) withMethod:@selector(hook_scale)];
            }
        }
    } 
    else {
        if ([[PlaySettings shared] adaptiveDisplay]) {
                if(@available(iOS 17.1, *))
                    [objc_getClass("FBSSceneSettingsCore") swizzleExchangeMethod:@selector(frame) withMethod:@selector(hook_frame)];
                else
                    [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(frame) withMethod:@selector(hook_frame)];
                [objc_getClass("FBSSceneSettings") swizzleInstanceMethod:@selector(bounds) withMethod:@selector(hook_bounds)];
                [objc_getClass("FBSDisplayMode") swizzleInstanceMethod:@selector(size) withMethod:@selector(hook_size)];
            }
    }
    
    [objc_getClass("_UIMenuBuilder") swizzleInstanceMethod:sel_getUid("initWithRootMenu:") withMethod:@selector(initWithRootMenuHook:)];
    [objc_getClass("IOSViewController") swizzleInstanceMethod:@selector(prefersPointerLocked) withMethod:@selector(hook_prefersPointerLocked)];
    // Set idiom to iPad
    // [objc_getClass("UIDevice") swizzleInstanceMethod:@selector(userInterfaceIdiom) withMethod:@selector(hook_userInterfaceIdiom)];
    // [objc_getClass("UITraitCollection") swizzleInstanceMethod:@selector(userInterfaceIdiom) withMethod:@selector(hook_userInterfaceIdiom)];

    [objc_getClass("VSSubscriptionRegistrationCenter") swizzleInstanceMethod:@selector(setCurrentSubscription:) withMethod:@selector(hook_setCurrentSubscription:)];

    [objc_getClass("CMMotionManager") swizzleInstanceMethod:@selector(init) withMethod:@selector(hook_CMMotionManager_init)];
    
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];

    if (PlayInfo.isUnrealEngine) {
        // Fix NSRegularExpression crash when system language is set to Chinese
        CFStringEncoding encoding = CFStringGetSystemEncoding();
        if (encoding == kCFStringEncodingMacChineseSimp || encoding == kCFStringEncodingMacChineseTrad) {
            SEL origSelector = NSSelectorFromString(@"_stringByReplacingOccurrencesOfRegularExpressionPattern:withTemplate:options:range:");
            SEL newSelector = @selector(hook_stringByReplacingOccurrencesOfRegularExpressionPattern:withTemplate:options:range:);
            [objc_getClass("NSString") swizzleInstanceMethod:origSelector withMethod:newSelector];
        }

        // Fix click conflicts by disabling built-in mouse
        [objc_getClass("GCMouse") swizzleClassMethod:@selector(current) withMethod:@selector(hook_GCMouse_current)];
    }

    // Wait for UnityFramework.framework to load
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        // Fix Tencent GVoice microphone permission
        if (objc_getClass("GVGCloudVoice") != nil) {
            [objc_getClass("AVAudioSession") swizzleInstanceMethod:@selector(requestRecordPermission:) withMethod:@selector(hook_requestRecordPermission:)];
        }

        if (objc_getClass("UnityAppController") != nil) {
            // Fix Unity KeyboardDelegate crash
            [objc_getClass("KeyboardDelegate") swizzleClassMethod:NSSelectorFromString(@"Initialize") withMethod:@selector(hook_KeyboardDelegate_Initialize)];

            // Fix Unity built-in keyboard lag
            [objc_getClass("UnityView") swizzleInstanceMethod:NSSelectorFromString(@"keyCommands") withMethod:@selector(hook_UnityView_keyCommands)];
        }

        // Specific fixes for NIKKE
        if ([bundleID hasSuffix:@".nikke"]) {
            // Fix hange issue
            [objc_getClass("INTLUtilsIOS") swizzleClassMethod:NSSelectorFromString(@"swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:") withMethod:@selector(hook_swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:)];

            // Fix window orientation issue
            if ([[PlaySettings shared] adaptiveDisplay]) {
                [objc_getClass("UnityAppController") swizzleInstanceMethod:NSSelectorFromString(@"createRootViewController") withMethod:@selector(hook_UnityAppController_createRootViewController)];
                [objc_getClass("UnityAppController") swizzleInstanceMethod:NSSelectorFromString(@"checkOrientationRequest") withMethod:@selector(hook_UnityAppController_checkOrientationRequest)];
            }
        }

        // Specific fixes for 金铲铲之战
        if ([bundleID isEqualToString:@"com.tencent.jkchess"]) {
            // Fix web view orientation issue
            [objc_getClass("MSDKBaseWebViewController") swizzleInstanceMethod:@selector(supportedInterfaceOrientations) withMethod:@selector(hook_jkchess_supportedInterfaceOrientations)];
        }

        // Specific fixes for OverField
        if ([bundleID isEqualToString:@"com.Nekootan.kfkj.apple"]) {
            // Bypass some detections
            [objc_getClass("o0_ooo0o0") swizzleInstanceMethod:NSSelectorFromString(@"o0_oaoao0") withMethod:@selector(hook_OverField_o0_ooo0o0)];
        }

        // Specific fixes for 天涯明月刀
        if ([bundleID isEqualToString:@"com.tencent.wuxia"]) {
            // Fix window orientation issue
            [objc_getClass("UnityAppController") swizzleInstanceMethod:NSSelectorFromString(@"createRootViewController") withMethod:@selector(hook_UnityAppController_createRootViewController)];
        }
    });
}

@end

@implementation PTBinaryPatcher
+ (BOOL)applyPatch {
    NSString* bundleID = [[NSBundle mainBundle] bundleIdentifier];

    if ([bundleID isEqualToString:@"com.tencent.jkchess"]) {
        return [self applyPatch_jkchess];
    }

    if ([bundleID isEqualToString:@"com.netease.party"] ||
        [bundleID isEqualToString:@"com.netease.id5"]) {
        return [self applyPatch_NeoX];
    }

    if ([bundleID isEqualToString:@"com.epicgames.FortniteGame"]) {
        should_fix_available_memory = true;
        return [self applyPatch_Fortnite];
    }

    return NO;
}

// This game calls UnityEngine.Application.HasUserAuthorization().
// However HasUserAuthorization() always return false due to missing #define UNITY_USES_MICROPHONE.
// The following patch forces HasUserAuthorization() to return true.
// (It is better to ask the game developers to remove the HasUserAuthorization() check.)
+ (BOOL)applyPatch_jkchess {
    NSString *infoPlistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *PLIST_KEY_PATCHED = @"__PATCHED__";
    if (plist[PLIST_KEY_PATCHED]) {
        return NO;
    } else {
        plist[PLIST_KEY_PATCHED] = @YES;
        [plist writeToFile:infoPlistPath atomically:YES];
    }

    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:[[NSBundle mainBundle] executablePath]];
    if (file == nil) {
        NSLog(@"[PlayTools] failed to open executable file");
        return NO;
    }
    
    NSData *data = [file readDataToEndOfFile];
    const unsigned char pattern[] = {0x7F,0x0A,0x00,0x71,0x93,0x02,0x88,0x1A,0xE0,0x03,0x13,0xAA};
    NSData *patternData = [NSData dataWithBytes:pattern length:sizeof(pattern)];

    NSRange range = [data rangeOfData:patternData options:0 range:NSMakeRange(0, data.length)];
    if (range.location == NSNotFound) {
        NSLog(@"[PlayTools] cannot find target byte sequence in executable file");
        [file closeFile];
        return NO;
    }

    [file seekToFileOffset:range.location + 8];
    const unsigned char patch[] = {0x20,0x00,0x80,0xD2};
    NSData *patchData = [NSData dataWithBytes:patch length:sizeof(patch)];
    [file writeData:patchData];
    [file closeFile];
    return YES;
}

// This game engine will access the wrong paths like /private/Users/$USER/Library/Containers.
// The following patch replaces the constant string '/private' with '/'.
+ (BOOL)applyPatch_NeoX {
    NSString *infoPlistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *PLIST_KEY_PATCHED = @"__PATCHED__";
    if (plist[PLIST_KEY_PATCHED]) {
        return NO;
    } else {
        plist[PLIST_KEY_PATCHED] = @YES;
        [plist writeToFile:infoPlistPath atomically:YES];
    }

    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:[[NSBundle mainBundle] executablePath]];
    if (file == nil) {
        NSLog(@"[PlayTools] failed to open executable file");
        return NO;
    }

    NSData *data = [file readDataToEndOfFile];
    const unsigned char pattern[] = {0x00,0x2F,0x70,0x72,0x69,0x76,0x61,0x74,0x65,0x00};
    NSData *patternData = [NSData dataWithBytes:pattern length:sizeof(pattern)];

    NSRange range = [data rangeOfData:patternData options:0 range:NSMakeRange(0, data.length)];
    if (range.location == NSNotFound) {
        NSLog(@"[PlayTools] cannot find target byte sequence in executable file");
        [file closeFile];
        return NO;
    }

    [file seekToFileOffset:range.location];
    const unsigned char patch[] = {0x00,0x2F,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00};
    NSData *patchData = [NSData dataWithBytes:patch length:sizeof(patch)];
    [file writeData:patchData];
    [file closeFile];
    return YES;
}

+ (BOOL)applyPatch_Fortnite {
    NSString *infoPlistPath = [[NSBundle mainBundle] pathForResource:@"Info" ofType:@"plist"];
    NSMutableDictionary *plist = [NSMutableDictionary dictionaryWithContentsOfFile:infoPlistPath];
    NSString *PLIST_KEY_PATCHED = @"__PATCHED__";
    if (plist[PLIST_KEY_PATCHED]) {
        return NO;
    } else {
        plist[PLIST_KEY_PATCHED] = @YES;
        [plist writeToFile:infoPlistPath atomically:YES];
    }

    NSFileHandle *file = [NSFileHandle fileHandleForUpdatingAtPath:[[NSBundle mainBundle] executablePath]];
    if (file == nil) {
        NSLog(@"[PlayTools] failed to open executable file");
        return NO;
    }

    BOOL ret = false;
    NSData *data = [file readDataToEndOfFile];
    if ([self applyPatch_Fortnite_Part1_WithFile:file AndData:data]) {
        ret = YES;
    }
    if ([self applyPatch_Fortnite_Part2_WithFile:file AndData:data]) {
        ret = YES;
    }
    [file closeFile];
    return ret;
}

// The following patch forces FIOSPlatformMisc::IsEntitlementEnabled() to return true
// On macOS, entitlements are not required to allocate large amounts of memory.
+ (BOOL)applyPatch_Fortnite_Part1_WithFile:(NSFileHandle *)file AndData:(NSData *)data {
    const uint8_t pattern[] = {0xF4,0x03,0x00,0xAA,0xE2,0x03,0x00,0x2A,0xE0,0x03,0x00,0x91,0xE1,0x03,0x13,0xAA,0x03,0x00,0x80,0x52,0x04,0x00,0x80,0x52};
    NSData *patternData = [NSData dataWithBytes:pattern length:sizeof(pattern)];
    NSRange range = [data rangeOfData:patternData options:0 range:NSMakeRange(0, data.length)];
    if (range.location == NSNotFound) {
        NSLog(@"[PlayTools] cannot find target byte sequence in executable file");
        return NO;
    }

    // MOV W0, #0
    [file seekToFileOffset:range.location + sizeof(pattern)];
    const uint8_t patch[] = {0x00,0x00,0x80,0x52};
    NSData *patchData = [NSData dataWithBytes:patch length:sizeof(patch)];
    [file writeData:patchData];

    // MOV X0, #1
    [file seekToFileOffset:range.location + sizeof(pattern) + 4 * 16];
    const uint8_t patch2[] = {0x20,0x00,0x80,0xD2};
    NSData *patchData2 = [NSData dataWithBytes:patch2 length:sizeof(patch2)];
    [file writeData:patchData2];
    return YES;
}

// os_proc_available_memory() always return zero in FApplePlatformMemory::GetConstants().
// The following patch assigns the correct value to MemoryConstants.TotalPhysical.
// And FApplePlatformMemory::GetConstants() is called too early,
// we have no chance to fix this issue by DYLD_INTERPOSE(os_proc_available_memory).
+ (BOOL)applyPatch_Fortnite_Part2_WithFile:(NSFileHandle *)file AndData:(NSData *)data {
    const uint8_t pattern[] = {0xF3,0x03,0x00,0xAA,0xE8,0x01,0x80,0x52,0xA8,0xC3,0x1E,0xB8,0xBF,0x03,0x1E,0xF8,0xA1,0x83,0x00,0xD1};
    NSData *patternData = [NSData dataWithBytes:pattern length:sizeof(pattern)];
    NSRange range = [data rangeOfData:patternData options:0 range:NSMakeRange(0, data.length)];
    if (range.location == NSNotFound) {
        NSLog(@"[PlayTools] cannot find target byte sequence in executable file (2)");
        return NO;
    }

    // MOV X0, #0x100000000 * imm16
    [file seekToFileOffset:range.location + 4 * -23];
    uint16_t imm16 = [NSProcessInfo processInfo].physicalMemory / (1ull << 32);
    uint32_t instruction = 0xD2C00000 | (imm16 << 5);
    uint8_t patch[4] = {0};
    for (int i = 0; i < 4; i++) {
        patch[i] = (instruction >> (8 * i)) & 0xFF;
    }
    NSData *patchData = [NSData dataWithBytes:patch length:sizeof(patch)];
    [file writeData:patchData];
    return YES;
}
@end
