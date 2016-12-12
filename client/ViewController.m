//
//  ViewController.m
//  client
//
//  Created by vd on 2016/12/12.
//  Copyright © 2016年 vd. All rights reserved.
//

#import "ViewController.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <ifaddrs.h>
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self createSocketClient];
    
    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (void)createSocketClient
{
    int err;
    // 创建socket套接字
    int fd =socket(AF_INET, SOCK_STREAM, 0);
    BOOL success=(fd!=-1);
    struct sockaddr_in addr;
    if (success) {
        NSLog(@"Socket创建成功");
        memset(&addr, 0, sizeof(addr));
        addr.sin_len = sizeof(addr);
        addr.sin_family = AF_INET;
        addr.sin_addr.s_addr = INADDR_ANY;
        
        // 建立地址和套接字的联系
        err = bind(fd, (const struct sockaddr *)&addr, sizeof(addr));
        success = (err==0);
    }
    if (success) {
        struct sockaddr_in serveraddr;
        memset(&serveraddr, 0, sizeof(serveraddr));
        serveraddr.sin_len=sizeof(serveraddr);
        serveraddr.sin_family=AF_INET;
        // 服务器端口
        serveraddr.sin_port=htons(1024);
        // 服务器的地址
        serveraddr.sin_addr.s_addr=inet_addr("127.0.0.1");
        socklen_t addrLen;
        addrLen =sizeof(serveraddr);
        NSLog(@"连接服务器中...");
        err=connect(fd, (struct sockaddr *)&serveraddr, addrLen);
        success=(err==0);
        if (success) {
            // getsockname 是对tcp连接而言。套接字socket必须是已连接套接字描述符。
            err =getsockname(fd, (struct sockaddr *)&addr, &addrLen);
            success=(err==0);
            if (success) {
                NSLog(@"连接服务器成功，本地地址：%s，端口：%d",inet_ntoa(addr.sin_addr),ntohs(addr.sin_port));
                [NSThread detachNewThreadSelector:@selector(reciveMessage:) toTarget:self withObject:@(fd)];
            }
        }
        else{
            NSLog(@"connect failed");
        }
    }
}

- (void)reciveMessage:(id) peerfd
{
    int fd = [peerfd intValue];
    char buf[1024];
    ssize_t bufLen;
    size_t len=sizeof(buf);
    
    // 循环阻塞接收消息
    do {
        bufLen = recv(fd, buf, len, 0);
        // 当返回值小于等于零时，表示socket异常或者socket关闭，退出循环阻塞接收消息
        if (bufLen <= 0) {
            break;
        }
        // 接收到的信息
        NSString* msg = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
        
        NSLog(@"来自服务端，消息内容：%@", msg);
    } while (true);
    // 7. 关闭
    close(fd);
}


@end
