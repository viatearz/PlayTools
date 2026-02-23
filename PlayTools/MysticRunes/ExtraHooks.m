//
//  ExtraHooks.m
//  PlayTools
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <PlayTools/PlayTools-Swift.h>
#import "ExtraHooks.h"

__attribute__((visibility("hidden")))
@interface ExtraHooksLoader : NSObject
@end

@implementation NSObject (ExtraHooks)

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
                        method_getTypeEncoding(swizzledMethod))) {
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

- (NSUInteger) hook_applicationShouldTerminate:(id)sender {
    [self hook_applicationShouldTerminate:sender];
    return 1; // NSTerminateNow
}

- (bool) hook_UE4_FIOSView_CreateFramebuffer:(bool)bIsForOnDevice {
    bool ret = [self hook_UE4_FIOSView_CreateFramebuffer:bIsForOnDevice];

    UIView *view = (UIView *)self;
    view.contentScaleFactor = [[PlaySettings shared] customScaler];
    CAMetalLayer* MetalLayer = (CAMetalLayer *)view.layer;
    CGSize DrawableSize = view.bounds.size;
    DrawableSize.width *= view.contentScaleFactor;
    DrawableSize.height *= view.contentScaleFactor;
    MetalLayer.drawableSize = DrawableSize;

    return ret;
}

- (float) hook_UE5_IOSAppDelegate_MobileContentScaleFactor {
    return 0;
}

- (NSArray*) hook_UnityView_keyCommands {
    NSArray *keyCommands = [self hook_UnityView_keyCommands];
    if (keyCommands) {
        if (![[UnityEngineKeyboardSupport shared] isIntialized]) {
            [[UnityEngineKeyboardSupport shared] initialize:(UIView *)self];
        }
        if ([[UnityEngineKeyboardSupport shared] isActive]) {
            return nil;
        }
    }
    return keyCommands;
}

+ (BOOL) hook_swizzlingOriginalClass:(Class)arg1 swizzledClass:(Class)arg2
                         originalSEL:(SEL)arg3 swizzledSEL:(SEL)arg4 {
    return false;
}

@end

@implementation ExtraHooksLoader
+ (void)load {
    if ([[PlaySettings shared] forceQuitAppOnClose]) {
        [objc_getClass("UINSApplicationDelegate") swizzleInstanceMethod:NSSelectorFromString(@"applicationShouldTerminate:") withMethod:@selector(hook_applicationShouldTerminate:)];
    }

    if ([[PlaySettings shared] unrealEngineSetScaleFactor]) {
        [objc_getClass("FIOSView") swizzleInstanceMethod:NSSelectorFromString(@"CreateFramebuffer:") withMethod:@selector(hook_UE4_FIOSView_CreateFramebuffer:)];
        [objc_getClass("IOSAppDelegate") swizzleInstanceMethod:NSSelectorFromString(@"MobileContentScaleFactor") withMethod:@selector(hook_UE5_IOSAppDelegate_MobileContentScaleFactor)];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([[PlaySettings shared] unityEngineFixKeyboardInput]) {
            [objc_getClass("UnityView") swizzleInstanceMethod:NSSelectorFromString(@"keyCommands") withMethod:@selector(hook_UnityView_keyCommands)];
        }

        if ([[PlaySettings shared] disableINTLUtilsSwizzling]) {
            [objc_getClass("INTLUtilsIOS") swizzleClassMethod:NSSelectorFromString(@"swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:") withMethod:@selector(hook_swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:)];
        }
    });
}
@end
