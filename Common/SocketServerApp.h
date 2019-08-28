//
//  SocketServerApp.h
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SocketServerAppDelegate <NSObject>

- (void)connectedClientsChanged;

- (void)didReceivedMessage:(NSString *)message fromHost:(NSString *)host port:(int)port;

- (void)didStopListening;

@end

@interface SocketServerApp : NSObject

@property (nonatomic, assign) BOOL listening;

@property (nonatomic, strong) NSMutableDictionary<NSString *, NSString *> *connectedClientsDic;

+ (instancetype)shareInstance;

// 开始监听
- (void)startListenOnPort:(int)port;

// 停止监听
- (void)stopListen;

// 群发信息
- (void)sendMessage:(NSString *)message;

// 设置代理
- (void)setServerDelegate:(id<SocketServerAppDelegate>)delegate;

@end

NS_ASSUME_NONNULL_END
