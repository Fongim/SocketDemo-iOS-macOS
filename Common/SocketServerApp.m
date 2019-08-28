//
//  SocketServerApp.m
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "SocketServerApp.h"
#import "GCDAsyncSocket.h"
#import "GCDAsyncSocket+Time.h"

@interface SocketServerApp () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *serverSocket;
@property (nonatomic, strong) NSMutableArray *clientsArray;
@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, weak) id<SocketServerAppDelegate> delegate;

@end

static SocketServerApp *instance;

@implementation SocketServerApp

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[super alloc] init];
    });
    return instance;
}

#pragma mark - Access

- (GCDAsyncSocket *)serverSocket {
    if (!_serverSocket) {
        _serverSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
        _serverSocket.delegate = self;
    }
    return _serverSocket;
}

- (NSMutableArray *)clientsArray {
    if (!_clientsArray) {
        _clientsArray = [NSMutableArray array];
    }
    return _clientsArray;
}

- (NSMutableDictionary<NSString *,NSString *> *)connectedClientsDic {
    if (!_connectedClientsDic) {
        _connectedClientsDic = [NSMutableDictionary dictionary];
    }
    [_connectedClientsDic removeAllObjects];
    for (GCDAsyncSocket *clientSocket in self.clientsArray) {
        NSString *host = clientSocket.connectedHost;
        NSString *port = [NSString stringWithFormat:@"%d", clientSocket.connectedPort];
        [_connectedClientsDic setObject:port forKey:host];
    }
    return _connectedClientsDic;
}

- (void)startListenOnPort:(int)port {
    NSError *error = nil;
    self.listening = [self.serverSocket acceptOnPort:port error:&error];
    [self addTimer];
    NSLog(self.listening ? @"开始监听" : @"开启监听失败");
}

- (void)stopListen {
    [self.serverSocket disconnect];
    NSLog(@"停止监听");
}

- (void)sendMessage:(NSString *)message {
    NSData *data = [message dataUsingEncoding:NSUTF8StringEncoding];
    // 群发消息
    if (self.clientsArray.count > 0) {
        for (GCDAsyncSocket *clientSocket in self.clientsArray) {
            long addressNum = [clientSocket.connectedHost stringByReplacingOccurrencesOfString:@"." withString:@""].intValue;
            long tag = addressNum * 1000 + arc4random() % 100;
            [clientSocket writeData:data withTimeout:-1 tag:tag];
            NSLog(@"发送消息 '%@' 到 %@:%d, Tag:%ld", message, clientSocket.connectedHost, clientSocket.connectedPort, tag);
            
        }
    }
}

- (void)setServerDelegate:(id<SocketServerAppDelegate>)delegate {
    self.delegate = delegate;
}

#pragma mark - Private Methods

- (void)addTimer {
    if (!_checkTimer) {
        self.checkTimer = [NSTimer scheduledTimerWithTimeInterval:20 target:self selector:@selector(checkLongConnect) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.checkTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)checkLongConnect{
//    NSLog(@"检查存活链接");
    NSDate *date = [NSDate date];
    NSMutableArray *newArray = [NSMutableArray array];
    for (GCDAsyncSocket *socket in self.clientsArray ) {
        if ([date timeIntervalSinceDate:socket.activeDate] > 15) {
            continue;
        }
        [newArray addObject:socket];
    }
    self.clientsArray = newArray;
    if ([self.delegate respondsToSelector:@selector(connectedClientsChanged)]) {
        [self.delegate connectedClientsChanged];
    }
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socket:(GCDAsyncSocket *)serverSocket didAcceptNewSocket:(GCDAsyncSocket *)newSocket {
    newSocket.activeDate = [NSDate date];
    [self.clientsArray addObject:newSocket];
    if ([self.delegate respondsToSelector:@selector(connectedClientsChanged)]) {
        [self.delegate connectedClientsChanged];
    }
    NSLog(@"连接新 Clinet, %@:%d", newSocket.connectedHost, newSocket.connectedPort);
    [newSocket readDataWithTimeout:-1 tag:0];
}

- (void)socket:(GCDAsyncSocket *)clientSocket didReadData:(NSData *)data withTag:(long)tag {
    for (GCDAsyncSocket *socket in self.clientsArray) {
        if ([socket isEqual:clientSocket]) {
            socket.activeDate = [NSDate date];
        }
    }
    
    NSString *message = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (![message hasSuffix:@"-keepAlive"]) {
        NSLog(@"收到来自 %@:%d 的消息：%@", clientSocket.connectedHost, clientSocket.connectedPort, message);
        if ([self.delegate respondsToSelector:@selector(didReceivedMessage:fromHost:port:)]) {
            [self.delegate didReceivedMessage:message fromHost:clientSocket.connectedHost port:clientSocket.connectedPort];
        }
    }
    
    [clientSocket readDataWithTimeout:-1 tag:0];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    if ([self.serverSocket isEqual:sock]) {
        self.serverSocket.delegate = nil;
        self.serverSocket = nil;
        self.listening = NO;
        [self.checkTimer invalidate];
        self.checkTimer = nil;
        self.clientsArray = nil;
        if ([self.delegate respondsToSelector:@selector(didStopListening)]) {
            [self.delegate didStopListening];
        }
        NSLog(@"停止监听回调");
        return;
    }
    
    [self.clientsArray enumerateObjectsUsingBlock:^(GCDAsyncSocket * _Nonnull client, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([client isEqual:sock]) {
            NSLog(@"Clinet: %@:%d 断开连接", client.connectedHost, client.connectedPort);
            [self.clientsArray removeObject:client];
            *stop = YES;
        }
    }];
    
    if ([self.delegate respondsToSelector:@selector(connectedClientsChanged)]) {
        [self.delegate connectedClientsChanged];
    }
    
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    NSLog(@"发送消息成功回调, tag:%ld", tag);
}

@end
