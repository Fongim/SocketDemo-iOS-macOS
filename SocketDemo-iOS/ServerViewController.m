//
//  ServerViewController.m
//  liveroom-test
//
//  Created by Paaatrick on 2019/8/28.
//  Copyright © 2019 Zego. All rights reserved.
//

#import "ServerViewController.h"
#import "SocketServerApp.h"
#import "Utility.h"

@interface ServerViewController () <SocketServerAppDelegate>
@property (weak, nonatomic) IBOutlet UILabel *localAddressLabel;
@property (weak, nonatomic) IBOutlet UIButton *listenButton;
@property (weak, nonatomic) IBOutlet UIButton *sendMessageButton;
@property (weak, nonatomic) IBOutlet UITextView *connectedClientDetail;
@property (weak, nonatomic) IBOutlet UITextField *listenPortTextField;
@property (weak, nonatomic) IBOutlet UITextField *sendMessageTextField;
@property (weak, nonatomic) IBOutlet UITextView *receivedMessageView;

@end

@implementation ServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [[SocketServerApp shareInstance] setServerDelegate:self];
}

- (void)setupUI {
    [self setTitle:@"Server"];
    [self.listenButton setTitle:@"开始监听" forState:UIControlStateNormal];
    [self.listenButton setTitle:@"停止监听" forState:UIControlStateSelected];
    self.listenPortTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"ServerPort"];
    self.localAddressLabel.text = [NSString stringWithFormat:@"本机IP地址：%@", [Utility getIPAddress:YES]];
}

- (IBAction)listen:(UIButton *)sender {
    BOOL listening = [SocketServerApp shareInstance].listening;
    if (listening) {
        [[SocketServerApp shareInstance] stopListen];
        sender.selected = NO;
    } else {
        NSString *port = self.listenPortTextField.text;
        if (port.length == 0) {
            NSLog(@"未输入Port");
            return;
        }
        
        [[SocketServerApp shareInstance] startListenOnPort:port.intValue];
        sender.selected = YES;
        [[NSUserDefaults standardUserDefaults] setObject:port forKey:@"ServerPort"];
    }
}

- (IBAction)sendMessage:(UIButton *)sender {
    if (![SocketServerApp shareInstance].listening) {
        NSLog(@"未在监听");
        return;
    }
    
    if (self.sendMessageTextField.text.length == 0) {
        NSLog(@"没有要发送的信息");
        return;
    }
    
    [[SocketServerApp shareInstance] sendMessage:self.sendMessageTextField.text];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

#pragma mark - delegate

- (void)connectedClientsChanged {
    NSString *detail = [NSString stringWithFormat:@"当前已连接："];
    NSDictionary *dic = [SocketServerApp shareInstance].connectedClientsDic;
    for (NSString *host in dic) {
        detail = [detail stringByAppendingString:[NSString stringWithFormat:@"\n%@:%@", host, dic[host]]];
    }
    
    self.connectedClientDetail.text = detail;
}

- (void)didReceivedMessage:(NSString *)message fromHost:(NSString *)host port:(int)port {
    NSString *oldText = self.receivedMessageView.text ? self.receivedMessageView.text : @"";
    self.receivedMessageView.text = [oldText stringByAppendingString:[NSString stringWithFormat:@"来自 %@:%d 的消息：\n%@\n\n", host, port, message]];
}

- (void)didStopListening {
    self.listenButton.selected = NO;
    self.connectedClientDetail.text = @"";
    self.receivedMessageView.text = @"";
}

@end
