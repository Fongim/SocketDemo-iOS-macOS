//
//  SocketClientApp.m
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "SocketClientApp.h"
#import "GCDAsyncSocket.h"

@interface SocketClientApp () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *clientSocket;
@property (nonatomic, strong) NSTimer *connectTimer;
@property (nonatomic, weak) id<SocketClientAppDelegate> delegate;

@end

static SocketClientApp *instance;

@implementation SocketClientApp

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    return instance;
}

- (void)dealloc {
    [self disconnect];
}

#pragma mark - Access

- (GCDAsyncSocket *)clientSocket {
    if (!_clientSocket) {
        _clientSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _clientSocket.delegate = self;
    }
    return _clientSocket;
}

#pragma mark - Public Methods

- (void)connectToHost:(NSString *)host port:(int)port {
    NSError *error = nil;
    self.connected = [self.clientSocket connectToHost:host onPort:port error:&error];
    NSLog(self.connected ? @"连接成功" : @"连接失败");
}

- (void)disconnect {
    [self.clientSocket disconnect];
    NSLog(@"停止连接");
}

- (void)sendMessage:(NSString *)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    long addressNum = [self.clientSocket.connectedHost stringByReplacingOccurrencesOfString:@"." withString:@""].intValue;
    long tag = addressNum * 1000 + arc4random() % 100;
    [self.clientSocket writeData:data withTimeout:-1 tag:tag];// -1 不处理 timeout
    NSLog(@"发送消息 '%@' 到 %@:%d, Tag:%ld", message, self.clientSocket.connectedHost, self.clientSocket.connectedPort, tag);
}

- (void)setClientDelegate:(id<SocketClientAppDelegate>)delegate {
    self.delegate = delegate;
}

#pragma mark - Private Methods

- (void)addTimer {
    if (!_connectTimer) {
        self.connectTimer = [NSTimer scheduledTimerWithTimeInterval:10 target:self selector:@selector(longConnectToSocket) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.connectTimer forMode:NSRunLoopCommonModes];
    }
}

// 心跳连接
- (void)longConnectToSocket {
    NSString *message = [NSString stringWithFormat:@"%@:%d-keepAlive", self.clientSocket.connectedHost, self.clientSocket.connectedPort];
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    [self.clientSocket writeData:data withTimeout:-1 tag:777];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"连接成功: host:%@, port:%d", host, port);
    [self addTimer];
    [self.clientSocket readDataWithTimeout:-1 tag:0];
    self.connected = YES;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if ([self.delegate respondsToSelector:@selector(didReceivedMessage:)]) {
        [self.delegate didReceivedMessage:message];
    }
    NSLog(@"收到消息：%@", message);
    [self.clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    NSLog(@"断开连接");
    self.clientSocket.delegate = nil;
    self.clientSocket = nil;
    self.connected = NO;
    [self.connectTimer invalidate];
    self.connectTimer = nil;
    if ([self.delegate respondsToSelector:@selector(didDisconnect)]) {
        [self.delegate didDisconnect];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == 777) {
        return;
    }
    NSLog(@"发送消息成功回调, tag:%ld", tag);
}

@end
