//
//  Utility.h
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Utility : NSObject

//获取设备当前网络IP地址
+ (NSString *)getIPAddress:(BOOL)preferIPv4;

//获取所有相关IP信息
+ (NSDictionary *)getIPAddresses;

@end

NS_ASSUME_NONNULL_END
