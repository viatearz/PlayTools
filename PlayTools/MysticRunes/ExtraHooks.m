//
//  ExtraHooks.m
//  PlayTools
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <PlayTools/PlayTools-Swift.h>
#import "ExtraHooks.h"
#import <WebKit/WebKit.h>

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

- (UIViewController *) hook_UnityAppController_createRootViewController {
    SEL selector = NSSelectorFromString(@"createUnityViewControllerForOrientation:");
    if ([self respondsToSelector:selector]) {
        IMP imp = [self methodForSelector:selector];
        if (imp) {
            typedef UIViewController *(*Function)(id, SEL, UIInterfaceOrientation);
            Function function = (Function)imp;
            return function(self, selector, UIInterfaceOrientationLandscapeLeft);
        }
    }
    return [self hook_UnityAppController_createRootViewController];
}

- (void) hook_UnityAppController_checkOrientationRequest {
    // do nothing
}

- (BOOL) hook_UE_FIOSView_becomeFirstResponder {
    BOOL ret = [self hook_UE_FIOSView_becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification
                                                        object:nil];
    return ret;
}

- (BOOL) hook_UE_FIOSView_resignFirstResponder {
    BOOL ret = [self hook_UE_FIOSView_resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification
                                                        object:nil];
    return ret;
}

- (BOOL) hook_WKContentView_becomeFirstResponder {
    BOOL ret = [self hook_WKContentView_becomeFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidBeginEditingNotification
                                                        object:nil];
    return ret;
}

- (BOOL) hook_WKContentView_resignFirstResponder {
    BOOL ret = [self hook_WKContentView_resignFirstResponder];
    [[NSNotificationCenter defaultCenter] postNotificationName:UITextFieldTextDidEndEditingNotification
                                                        object:nil];
    return ret;
}

+ (void) hook_Unity_KeyboardDelegate_Initialize {
    @try {
        [self hook_Unity_KeyboardDelegate_Initialize];
    }
    @catch (NSException *exception) {
        NSLog(@"Caught exception: %@, reason: %@", exception.name, exception.reason);
    }
}

- (void) hook_GKLocalPlayer_setAuthenticateHandler:(void (^)(UIViewController *, NSError *))handler {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        NSError *error = [NSError errorWithDomain:@"GKErrorDomain"
                                             code:2 // GKErrorCancelled
                                         userInfo:@{
            NSLocalizedDescriptionKey: @"The requested operation has been cancelled or disabled by the user."
        }];
        if (handler != nil) {
            handler(nil, error);
        }
    });
}

- (instancetype) hook_ARCoachingOverlayView_initWithFrame:(CGRect)frame {
    UIView *view = (UIView *)[self hook_ARCoachingOverlayView_initWithFrame:frame];
    view.userInteractionEnabled = false;
    return view;
}

- (WKWebView *) hook_WKWebView_initWithFrame:(CGRect) frame
                               configuration:(WKWebViewConfiguration *) config {
    WKWebView *webView = [self hook_WKWebView_initWithFrame:frame configuration:config];
    webView.configuration.defaultWebpagePreferences.preferredContentMode = WKContentModeMobile;
    return webView;
}

- (void) hook_o0_ooo0o0_o0_oaoao0 {
    // do nothing
}

- (UIInterfaceOrientationMask) hook_UIViewController_supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeLeft;
}

- (void) hook_LoveAndDeepspace_PSDKLogin_viewWillAppear:(BOOL) animated {
    [self hook_LoveAndDeepspace_PSDKLogin_viewWillAppear:animated];
    [[PlayInput shared] setShouldProcessMouseClick:NO];
}

- (void) hook_LoveAndDeepspace_PSDKLogin_viewWillDisappear:(BOOL) animated {
    [self hook_LoveAndDeepspace_PSDKLogin_viewWillDisappear:animated];
    [[PlayInput shared] setShouldProcessMouseClick:YES];
}

- (void) hook_UnityAppController_didTransitionToViewController:(UIViewController*)toController fromViewController:(UIViewController*)fromController {
    [self hook_UnityAppController_didTransitionToViewController:toController fromViewController:fromController];

    UIInterfaceOrientation newOrientation = UIInterfaceOrientationLandscapeLeft;
    UIInterfaceOrientationMask mask = toController.supportedInterfaceOrientations;
    if (mask & UIInterfaceOrientationMaskLandscapeLeft) {
        newOrientation = UIInterfaceOrientationLandscapeLeft;
    } else if (mask & UIInterfaceOrientationMaskLandscapeRight) {
        newOrientation = UIInterfaceOrientationLandscapeRight;
    } else if (mask & UIInterfaceOrientationMaskPortrait) {
        newOrientation = UIInterfaceOrientationPortrait;
    } else if (mask & UIInterfaceOrientationMaskPortraitUpsideDown) {
        newOrientation = UIInterfaceOrientationPortraitUpsideDown;
    }
    [self setValue:@(newOrientation) forKey:@"_curOrientation"];
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

    if ([[PlaySettings shared] noKMOnInput] &&
        [[PlaySettings shared] unrealEngineSmartTextInput]) {
        [objc_getClass("FIOSView") swizzleInstanceMethod:@selector(becomeFirstResponder) withMethod:@selector(hook_UE_FIOSView_becomeFirstResponder)];
        [objc_getClass("FIOSView") swizzleInstanceMethod:@selector(resignFirstResponder) withMethod:@selector(hook_UE_FIOSView_resignFirstResponder)];
    }
    
    if ([[PlaySettings shared] noKMOnInput] &&
        [[PlaySettings shared] webViewSmartTextInput]) {
        [objc_getClass("WKContentView") swizzleInstanceMethod:@selector(becomeFirstResponder) withMethod:@selector(hook_WKContentView_becomeFirstResponder)];
        [objc_getClass("WKContentView") swizzleInstanceMethod:@selector(resignFirstResponder) withMethod:@selector(hook_WKContentView_resignFirstResponder)];
    }

    if ([[PlaySettings shared] skipGameCenterLogin]) {
        [objc_getClass("GKLocalPlayer") swizzleInstanceMethod:NSSelectorFromString(@"setAuthenticateHandler:") withMethod:@selector(hook_GKLocalPlayer_setAuthenticateHandler:)];
    }

    if ([[PlaySettings shared] forceWebViewUseMobileContentMode]) {
        [objc_getClass("WKWebView") swizzleInstanceMethod:NSSelectorFromString(@"initWithFrame:configuration:") withMethod:@selector(hook_WKWebView_initWithFrame:configuration:)];
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if ([[PlaySettings shared] unityEngineFixKeyboardInput]) {
            [objc_getClass("UnityView") swizzleInstanceMethod:NSSelectorFromString(@"keyCommands") withMethod:@selector(hook_UnityView_keyCommands)];
        }

        if ([[PlaySettings shared] unityEngineForceLandscape]) {
            [objc_getClass("UnityAppController") swizzleInstanceMethod:NSSelectorFromString(@"createRootViewController") withMethod:@selector(hook_UnityAppController_createRootViewController)];
        }

        if ([[PlaySettings shared] unityEngineDisableOrientationCheck]) {
            [objc_getClass("UnityAppController") swizzleInstanceMethod:NSSelectorFromString(@"checkOrientationRequest") withMethod:@selector(hook_UnityAppController_checkOrientationRequest)];
        }

        if ([[PlaySettings shared] unityEngineIgnoreKeyboardDelegateCrash]) {
            [objc_getClass("KeyboardDelegate") swizzleClassMethod:NSSelectorFromString(@"Initialize") withMethod:@selector(hook_Unity_KeyboardDelegate_Initialize)];
        }

        if ([[PlaySettings shared] disableINTLUtilsSwizzling]) {
            [objc_getClass("INTLUtilsIOS") swizzleClassMethod:NSSelectorFromString(@"swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:") withMethod:@selector(hook_swizzlingOriginalClass:swizzledClass:originalSEL:swizzledSEL:)];
        }

        if ([[PlaySettings shared] unityEngineDisableAROverlayTouches]) {
            [objc_getClass("ARCoachingOverlayView") swizzleInstanceMethod:NSSelectorFromString(@"initWithFrame:") withMethod:@selector(hook_ARCoachingOverlayView_initWithFrame:)];
        }

        if ([[PlaySettings shared] bypassUnknownDetectionA]) {
            [objc_getClass("o0_ooo0o0") swizzleInstanceMethod:NSSelectorFromString(@"o0_oaoao0") withMethod:@selector(hook_o0_ooo0o0_o0_oaoao0)];
        }

        if ([[PlaySettings shared] forceUIViewLandscape]) {
            for (NSString *UIViewControllerName in [[PlaySettings shared] forceUIViewLandscapeArgs]) {
                [NSClassFromString(UIViewControllerName) swizzleInstanceMethod:NSSelectorFromString(@"supportedInterfaceOrientations") withMethod:@selector(hook_UIViewController_supportedInterfaceOrientations)];
            }
        }

        if ([[PlaySettings shared] loveAndDeepspaceFixLoginTextInput]) {
            NSArray *UIViewControllerNames = @[
                @"PSDKLogin.PSLoginPhoneSigninViewController",
                @"PSDKLogin.PSLoginSigninViewController",
                @"PSDKLogin.PSLoginGetBackPasswordInputAccountViewController"
            ];
            for (NSString *UIViewControllerName in UIViewControllerNames) {
                [NSClassFromString(UIViewControllerName) swizzleInstanceMethod:NSSelectorFromString(@"viewWillAppear:") withMethod:@selector(hook_LoveAndDeepspace_PSDKLogin_viewWillAppear:)];
                [NSClassFromString(UIViewControllerName) swizzleInstanceMethod:NSSelectorFromString(@"viewWillDisappear:") withMethod:@selector(hook_LoveAndDeepspace_PSDKLogin_viewWillDisappear:)];
            }
        }

        if ([[PlaySettings shared] unityEngineFixAutoRotate]) {
            [objc_getClass("UnityAppController") swizzleInstanceMethod:NSSelectorFromString(@"didTransitionToViewController:fromViewController:") withMethod:@selector(hook_UnityAppController_didTransitionToViewController:fromViewController:)];
        }
    });
}
@end
