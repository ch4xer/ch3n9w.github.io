---
title: 流量分析
author: ch3n9w
date: 2019-04-22 04:16:47
categories: CTF
typora-root-url: ../
---


> bugku 中的部分misc题目

<!--more-->

### 中国菜刀

下载流量包之后追踪tcp流量或者http流量可以在目录中看见flag.tar.gz字段

思路1：binwalk

先把数据包文件拖进kali子系统中

```
chmod 777 caidao/
cd caidao/
chmod 777 caidao.pcapng
binwalk -e caidao.pcapng
cd _caidao.pcapng.extracted/
cat 1E43
```
思路2：wireshark数据包追踪，把一串base64拎出来

```sql
@ini_set("display_errors","0");
@set_time_limit(0);
if(PHP_VERSION<'5.3.0')
{@set_magic_quotes_runtime(0);};
echo("X@Y");
$D='C:\\wwwroot\\';
$F=@opendir($D);
if($F==NULL){echo("ERROR:// Path Not Found Or No Permission!");}
else{$M=NULL;$L=NULL;
while($N=@readdir($F)){$P=$D.'/'.$N;$T=@date("Y-m-d H:i:s",@filemtime($P));@$E=substr(base_convert(@fileperms($P),10,8),-4);$R="\t".$T."\t".@filesize($P)."\t".$E."\n";if(@is_dir($P))$M.=$N."/".$R;else $L.=$N.$R;}
echo $M.$L;@closedir($F);};echo("X@Y");die();
```

当然这没啥用。。

数据包的数据都是在line-based text data里面的

点击line-based text data,右击，点击显示show packet bytes
额。。。把像\301\213\341这样的编码处理一下，之所以start设置为3，是因为前面的开头是x@y，不是base64的东西。。。设置为处理模式为压缩

### 这么多数据包

分析，据说如果是挂木马的话tcp流中会有“command”字段,于是设定过滤规则为：

```
tcp contains "command"
```
找出一些tcp包来，然后follow，注意如果是乱码的话可以尝试点一点stream长度，说不定就好了
然后就找到了flag的base64码

### 手机热点

蓝牙协议的名字叫做obex，所以在wireshark中搜索一下挑出几个包，然后有一个包写着“secret.rar”
导出来，解压得到flag

### 抓到一只苍蝇

http过滤一下，在第一个数据包中的内容如下：

```
{
    "path":"fly.rar",
    "appid":"",
    "size":525701,
    "md5":"e023afa4f6579db5becda8fe7861c2d3",
    "sha":"ecccba7aea1d482684374b22e2e7abad2ba86749",
    "sha3":""
}
```

发现了要传输的文件名字、文件的md5码、文件大小，
```
http && http.request.method==POST
```
过滤出来的接下来的5个分片数据包
总长度加起来超过了原文件的数据包大小，原因是附加的文件头。
将这些数据包一个一个导出
然后使用命令：


```
dd if=1 bs=1 skip=364 of=1.1
#dd命令用于读取、转换、输出数据
cat *.1 > fly.rar
#将这些文件碎片都拼成原始的压缩文件
md5sum fly.rar | grep e023afa4f6579db5becda8fe7861c2d3
#检查MD5码是否匹配
```
然后用bless打开rar文件，检查加密位，发现是伪加密，因为第一行的73后面的标记位是0000，如果加密就是8000
rar文件头格式介绍：https://wenku.baidu.com/view/b7889b64783e0912a2162aa4.html

把第二行74后面的84改成80就可以了，因为看论文可以知道，这两个字节的值类似于linux中chmod的1、2、4代表三种权限，
最终将所需权限的值相加在一起得到最终的标志位内容

改完之后，解压，打开，发现乱码，改后缀为exe，执行，发现一大堆苍蝇

```
binwalk flag.txt
#发现很多png图片，尝试使用foremost工具进行文件修复
foremost -v -i flag.txt -o outputfile
#-v 将所有信息输出到屏幕上，-i表示输入文件,-o表示输出目标
```
打开后有二维码，里头有flag
### 日志审计

sqlmap二分搜索

观察下面这个
```
172.17.0.1 - - [03/Nov/2018:02:50:57 +0000] "GET /vulnerabilities/sqli_blind/?id=2' AND ORD(MID((SELECT IFNULL(CAST(flag AS CHAR),0x20) FROM dvwa.flag_is_here ORDER BY flag LIMIT 0,1),24,1))>124 AND 'RCKM'='RCKM&Submit=Submit HTTP/1.1" 200 1765 "http://127.0.0.1:8001/vulnerabilities/sqli_blind/?id=1&Submit=Submit" "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/69.0.3497.100 Safari/537.36"
```
特征有200响应成功，而且对于每一位来说，最后一次得到200响应匹配的ascii码加上一就是真实的ascii码，
```python
1 import urllib
2 import re
3
4 ffile=open('/home/access.log','r')
5 datas=ffile.readlines()
6 avalid=[]
7 for data in datas:
8     tmp=urllib.unquote(data)
9     if 'flag' in tmp and 'COUNT' not in tmp and '200' in tmp:
10         avalid.append(tmp)
11
12 flag_ascii={}
13 for segment in avalid:
14     checkout=re.search(r'LIMIT 0,1\),(.*?),1\)\)>(.*?) AND',segment)
      #这里(.*?)后面要加AND否则大于号之后的所有内容都被包括进(.*?)中去了
15     if checkout:
16         key=int(checkout.group(1))
17         print key
18         print checkout.group(2)
19         print int(checkout.group(2))
20         value=int(checkout.group(2))+1
21         flag_ascii[key]=value  #同一个key，value在变化直到最后一个
23 flag=''
   for value in flag_ascii.values():
           flag+=chr(value)
   print flag
```

### weblogic

说是要找到被攻击主机的名字。过滤条件
```
tcp contains "hostname"
```
然后找一找就行了。。。

### 信息提取

这道题真的很懵圈。
将wireshark中涉及到盲注的数据包都导出到txt文件中来。
然后python脚本：

```python

import urllib
import re

f=open('/root/kkk.txt','r')
lines=f.readlines()
datas=[]
for line in lines:
  tmp=urllib.unquote(line)
  datas.append(tmp)

flag_ascii={}
for data in datas:
  checkout=re.search(r'LIMIT 0,1),(.*?),1\)\)>(.*?) HTTP',data)
  if checkout:
    key=int(checkout.group(1))
    value=int(checkout.group(2))
    flag_ascii[key]=value

flag=''
for value in flag_ascii.values():
  flag+=chr(value)

print flag
```
但是不知道为什么flag中有的字符是对的有的是错的。
