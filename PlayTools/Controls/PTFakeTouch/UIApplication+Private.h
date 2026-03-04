//
//  UIApplication+Private.h
//  FakeTouch
//
//  Created by Watanabe Toshinori on 2/6/19.
//  Copyright © 2019 Watanabe Toshinori. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (Private)

- (UIEvent *)_touchesEvent;
- (UIEvent *)_touchesEventForWindow:(UIWindow *)window;

@end
