//
//  ClientViewController.m
//  SimpleSocketDemo-macOS
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ClientViewController.h"
#import "SocketClientApp.h"

@interface ClientViewController () <SocketClientAppDelegate>
@property (weak) IBOutlet NSTextField *hostTextField;
@property (weak) IBOutlet NSTextField *portTextField;
@property (weak) IBOutlet NSTextField *sendMessageTextField;
@property (weak) IBOutlet NSButton *connectButton;
@property (weak) IBOutlet NSLayoutConstraint *sendMessageButton;
@property (weak) IBOutlet NSTextField *receivedMessageView;

@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [[SocketClientApp shareInstance] setClientDelegate:self];
}

- (void)setupUI {
    NSString *host = [[NSUserDefaults standardUserDefaults] objectForKey:@"ClientHost"];
    NSString *port = [[NSUserDefaults standardUserDefaults] objectForKey:@"ClientPort"];
    self.hostTextField.stringValue = host ? host : @"";
    self.portTextField.stringValue = port ? port : @"";
}

- (IBAction)connectHost:(NSButton *)sender {
    BOOL connected = [SocketClientApp shareInstance].connected;
    if (connected) {
        [[SocketClientApp shareInstance] disconnect];
        sender.state = NSControlStateValueOff;
    } else {
        NSString *host = self.hostTextField.stringValue;
        NSString *port = self.portTextField.stringValue;
        if (host.length == 0 || port.length == 0) {
            NSLog(@"未输入host或port");
            return;
        }
        
        [[SocketClientApp shareInstance] connectToHost:host port:port.intValue];
        sender.state = NSControlStateValueOn;
        [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"ClientHost"];
        [[NSUserDefaults standardUserDefaults] setObject:port forKey:@"ClientPort"];
    }
}

- (IBAction)sendMessage:(NSButton *)sender {
    if (![SocketClientApp shareInstance].connected) {
        NSLog(@"未连接 Host");
        return;
    }
    
    if (self.sendMessageTextField.stringValue.length == 0) {
        NSLog(@"没有要发送的信息");
        return;
    }
    
    [[SocketClientApp shareInstance] sendMessage:self.sendMessageTextField.stringValue];
}

#pragma mark - delegate

- (void)didReceivedMessage:(NSString *)message {
    NSString *oldText = self.receivedMessageView.stringValue ? self.receivedMessageView.stringValue : @"";
    self.receivedMessageView.stringValue = [oldText stringByAppendingString:[NSString stringWithFormat:@"%@\n", message]];
}

- (void)didDisconnect {
    self.connectButton.state = NSControlStateValueOff;
    self.receivedMessageView.stringValue = @"";
}

@end
