//
//  SocketClientApp.h
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SocketClientAppDelegate <NSObject>

- (void)didReceivedMessage:(NSString *)message;

- (void)didDisconnect;

@end

@interface SocketClientApp : NSObject

@property (nonatomic, assign) BOOL connected;

+ (instancetype)shareInstance;

// 建立连接
- (void)connectToHost:(NSString *)host port:(int)port;

// 关闭连接
- (void)disconnect;

// 发送信息
- (void)sendMessage:(NSString *)message;

// 设置代理
- (void)setClientDelegate:(id<SocketClientAppDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
