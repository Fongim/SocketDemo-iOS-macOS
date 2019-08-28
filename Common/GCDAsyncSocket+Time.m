//
//  GCDAsyncSocket+Time.m
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "GCDAsyncSocket+Time.h"
#import <objc/runtime.h>

@implementation GCDAsyncSocket (Time)

- (void)setActiveDate:(NSDate *)activeDate {
    objc_setAssociatedObject(self, _cmd, activeDate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (NSDate *)activeDate {
    return objc_getAssociatedObject(self, @selector(setActiveDate:));
}

@end
