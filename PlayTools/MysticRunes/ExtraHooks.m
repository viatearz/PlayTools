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

- (NSUInteger) hook_applicationShouldTerminate:(id)sender {
    [self hook_applicationShouldTerminate:sender];
    return 1; // NSTerminateNow
}

@end

@implementation ExtraHooksLoader
+ (void)load {
    if ([[PlaySettings shared] forceQuitAppOnClose]) {
        [objc_getClass("UINSApplicationDelegate") swizzleInstanceMethod:NSSelectorFromString(@"applicationShouldTerminate:") withMethod:@selector(hook_applicationShouldTerminate:)];
    }
}
@end
