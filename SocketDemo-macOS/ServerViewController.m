//
//  ServerViewController.m
//  SimpleSocketDemo-macOS
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ServerViewController.h"
#import "SocketServerApp.h"
#import "Utility.h"

@interface ServerViewController () <SocketServerAppDelegate>

@property (weak) IBOutlet NSTextField *localAddressLabel;
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSTextField *sendMessageTextField;
@property (weak) IBOutlet NSButton *listenButton;
@property (weak) IBOutlet NSButton *sendButton;
@property (weak) IBOutlet NSTextField *connectedClientDetailView;
@property (weak) IBOutlet NSTextField *receivedMessageView;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [[SocketServerApp shareInstance] setServerDelegate:self];
}

- (void)setupUI {
    NSString *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"ServerPort"];
    self.portTextField.stringValue = port ? port : @"";
    self.localAddressLabel.stringValue = [NSString stringWithFormat:@"本机IP地址：%@", [Utility getIPAddress:YES]];
}

- (IBAction)startListen:(NSButton *)sender {
    BOOL listening = [SocketServerApp shareInstance].listening;
    if (listening) {
        [[SocketServerApp shareInstance] stopListen];
        sender.state = NSControlStateValueOff;
    } else {
        NSString *port = self.portTextField.stringValue;
        if (port.length == 0) {
            NSLog(@"未输入Port");
            return;
        }
        
        [[SocketServerApp shareInstance] startListenOnPort:port.intValue];
        sender.state = NSControlStateValueOn;
        [[NSUserDefaults standardUserDefaults] setObject:port forKey:@"ServerPort"];
    }
}

- (IBAction)sendMessage:(NSButton *)sender {
    if (![SocketServerApp shareInstance].listening) {
        NSLog(@"未在监听");
        return;
    }
    
    if (self.sendMessageTextField.stringValue.length == 0) {
        NSLog(@"没有要发送的信息");
        return;
    }
    
    [[SocketServerApp shareInstance] sendMessage:self.sendMessageTextField.stringValue];
}

#pragma mark - delegate

- (void)connectedClientsChanged {
    NSString *detail = [NSString stringWithFormat:@"当前已连接："];
    NSDictionary *dic = [SocketServerApp shareInstance].connectedClientsDic;
    for (NSString *host in dic) {
        detail = [detail stringByAppendingString:[NSString stringWithFormat:@"\n%@:%@", host, dic[host]]];
    }
    
    self.connectedClientDetailView.stringValue = detail;
}

- (void)didReceivedMessage:(NSString *)message fromHost:(NSString *)host port:(int)port {
    NSString *oldText = self.receivedMessageView ? self.receivedMessageView.stringValue : @"";
    self.receivedMessageView.stringValue = [oldText stringByAppendingString:[NSString stringWithFormat:@"来自 %@:%d 的消息：\n%@\n\n", host, port, message]];
}

- (void)didStopListening {
    self.listenButton.state = NSControlStateValueOff;
    self.connectedClientDetailView.stringValue = @"";
    self.receivedMessageView.stringValue = @"";
}


@end
