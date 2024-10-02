---
title: 特殊网络环境下的微信代理
author: ch3n9w
date: 2024-10-02T09:33:06+08:00
categories: 技术
---

目前单位实施了微信封锁,本文旨在记录绕过封锁的过程.

## 阶段一: 抓域名

使用了`tcpdump`抓取各个dns请求, 来获取需要代理的域名列表

```sh
sudo tcpdump -i any -n -s 0 port 53
```

但是抓到域名后加入daed的代理列表中还是无法登陆,怀疑是没抓全.

## 阶段二: 进程代理

既然抓不全, 那么就对整个微信的进程进行流量代理吧, 在daed中添加规则:

```
pname(WeChatAppEx) -> proxy
pname(wechat) -> proxy
```

这下登陆和发文字消息都正常了, 但是图片的发送和接收有极其严重的延迟, 应该是走了代理导致的.

## 阶段三: 仅代理登陆相关域名

经过几次实验, 发送单位对微信的封禁主要有两方面:

1. 登陆相关的流量封禁
2. 微信公众号图片相关的流量封禁

那么在搜索到[相关域名列表](https://www.fdeer.com/4817.html)之后,将对应的域名添加到daed规则中,其他的流量不作处理使用直连.

```
domain(keyword:login.weixin,keyword:open.weixin,keyword:mp.weixin,keyword:qpic) -> proxy
```

重新加载规则, 一切正常.
