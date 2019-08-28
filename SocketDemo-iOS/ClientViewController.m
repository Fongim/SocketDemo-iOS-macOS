//
//  ClientViewController.m
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/27.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ClientViewController.h"
#import "SocketClientApp.h"

@interface ClientViewController () <SocketClientAppDelegate>
@property (weak, nonatomic) IBOutlet UITextField *hostTextField;
@property (weak, nonatomic) IBOutlet UITextField *portTextField;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UIButton *connectButton;
@property (weak, nonatomic) IBOutlet UITextField *sendMessageTextField;
@property (weak, nonatomic) IBOutlet UITextView *receivedMessageTextView;

@end

@implementation ClientViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [[SocketClientApp shareInstance] setClientDelegate:self];
}

- (void)setupUI {
    [self setTitle:@"Client"];
    [self.connectButton setTitle:@"连接" forState:UIControlStateNormal];
    [self.connectButton setTitle:@"断开" forState:UIControlStateSelected];
    self.hostTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ClientHost"];
    self.portTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ClientPort"];
}

- (IBAction)connectHost:(UIButton *)sender {
    BOOL connected = [SocketClientApp shareInstance].connected;
    if (connected) {
        [[SocketClientApp shareInstance] disconnect];
        sender.selected = NO;
    } else {
        NSString *host = self.hostTextField.text;
        NSString *port = self.portTextField.text;
        if (host.length == 0 || port.length == 0) {
            NSLog(@"未输入host或port");
            return;
        }
        
        [[SocketClientApp shareInstance] connectToHost:host port:port.intValue];
        sender.selected = YES;
        [[NSUserDefaults standardUserDefaults] setObject:host forKey:@"ClientHost"];
        [[NSUserDefaults standardUserDefaults] setObject:port forKey:@"ClientPort"];
    }
}

- (IBAction)sendMessage:(UIButton *)sender {
    if (![SocketClientApp shareInstance].connected) {
        NSLog(@"未连接 Host");
        return;
    }
    
    if (self.sendMessageTextField.text.length == 0) {
        NSLog(@"没有要发送的信息");
        return;
    }
    
    [[SocketClientApp shareInstance] sendMessage:self.sendMessageTextField.text];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - delegate

- (void)didReceivedMessage:(NSString *)message {
    NSString *oldText = self.receivedMessageTextView.text ? self.receivedMessageTextView.text : @"";
    self.receivedMessageTextView.text = [oldText stringByAppendingString:[NSString stringWithFormat:@"%@\n", message]];
}

- (void)didDisconnect {
    self.connectButton.selected = NO;
    self.receivedMessageTextView.text = @"";
}

@end
