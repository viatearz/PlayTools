//
//  ExtraHooks.h
//  PlayTools
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSObject (ExtraHooks)

- (void)swizzleInstanceMethod:(SEL)origSelector withMethod:(SEL)newSelector;

@end
NS_ASSUME_NONNULL_END
