//
//  ViewController.m
//  CFNetWorkingDemo
//
//  Created by vd on 2016/12/11.
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
    
    [self socketServer];
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)socketServer
{
    int err;
    // 1. 创建socket套接字
    // 原型：int socket(int domain, int type, int protocol);
    // domain：协议族 type：socket类型 protocol：协议
    int fd = socket(AF_INET, SOCK_STREAM, IPPROTO_IP);
    BOOL success = (fd != -1);
    if (success) {
        NSLog(@"Socket 创建成功");
        // 地址结构体
        struct sockaddr_in addr;
        // 内存清空
        memset(&addr, 0, sizeof(addr));
        // 内存大小
        addr.sin_len=sizeof(addr);
        // 地址族，在socket编程中只能是AF_INET
        addr.sin_family=AF_INET;
        // 端口号
        addr.sin_port=htons(1024);
        // 按照网络字节顺序存储IP地址
        addr.sin_addr.s_addr=INADDR_ANY;
        
        // 2. 建立地址和套接字的联系（绑定）
        // 原型：bind(sockid, local addr, addrlen)
        err=bind(fd, (const struct sockaddr *)&addr, sizeof(addr));
        success=(err==0);
    }
    
    // 3. 服务器端侦听客户端的请求
    if (success) {
        NSLog(@"绑定成功");
        // listen( Sockid ,quenlen) quenlen 并发队列
        err=listen(fd, 5);//开始监听
        success=(err==0);
    }
    if (success) {
        NSLog(@"监听成功");
        // 4. 一直阻塞等到客户端的连接
        while (true) {
            struct sockaddr_in peeraddr;
            int peerfd;
            socklen_t addrLen;
            addrLen = sizeof(peeraddr);
            NSLog(@"等待客户端的连接请求");
            // 5. 服务器端等待从编号为Sockid的Socket上接收客户端连接请求
            // 原型：newsockid=accept(Sockid，Clientaddr, paddrlen)
            peerfd = accept(fd, (struct sockaddr *)&peeraddr, &addrLen);
            success=(peerfd!=-1);
            // 接收客户端请求成功
            if (success) {
                NSLog(@"接收客户端请求成功，客户端地址：%s, 端口号：%d",inet_ntoa(peeraddr.sin_addr), ntohs(peeraddr.sin_port));
                send(peerfd, "欢迎进入Socket聊天室", 1024, 0);
                // 6. 创建新线程接收客户端发送的消息
                [NSThread detachNewThreadSelector:@selector(reciveMessage:) toTarget:self withObject:@(peerfd)];
            }
        }
    }
}
- (void)reciveMessage:(id) peerfd
{
    int fd = [peerfd intValue];
    char buf[1024];
    ssize_t bufLen;
    size_t len=sizeof(buf);
    
    // 循环阻塞接收客户端发送的消息
    do {
        bufLen = recv(fd, buf, len, 0);
        // 当返回值小于等于零时，表示socket异常或者socket关闭，退出循环阻塞接收消息
        if (bufLen <= 0) {
            break;
        }
        // 接收到的信息
        NSString* msg = [NSString stringWithCString:buf encoding:NSUTF8StringEncoding];
        NSLog(@"来自客户端，消息内容：%@", msg);
        memset(buf, 0, sizeof(buf));
    } while (true);
    // 7. 关闭
    close(fd);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
