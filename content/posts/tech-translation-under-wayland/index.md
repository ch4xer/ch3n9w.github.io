---
title: wayland下的划词翻译解决方案
author: ch3n9w
typora-root-url: ../
date: 2023-01-11 04:36:45
categories:
  - 技术
cover:
  image: 1.jpg
---

对于我这种英语不好的人来说, 翻译是离不开的工具, 但是众所周知, Linux的日用软件生态相比较windows和macos来说相差甚远, 别说目前正处于发展阶段的wayland, 就连成熟透了的x11下也没有拿得出手的翻译软件. 作为一个英语不好的Linux爱好者, 缺少翻译软件必定会对日常的使用造成一定的影响, 于是开始思考怎么样解决这个问题.

我的第一个思路, 也就是见到最多的划词翻译软件的样子, 选中文本之后, 在被选中的文本周围的某块区域中绘制一个窗口, 在其中展示翻译结果. 但是问题来了, 要如何绘制这样的窗口呢? 在wayland中, 窗口的位置交给了compositor进行管理, 这种能够自己决定显示位置的能力, 据我所知, 在wayland下仅有fcitx5做到了, 于是我翻阅了一下它的源代码, 并没有看懂, 但是应该没有借助于Qt和GTK来绘制, 而是使用wayland-client. 对我这样一个连Qt GTK开发经历都没有的人来说, 理解wayland编程开发中的那些概念实在有些困难. 于是紧接着又有一个问题出现了:

能否绕开wayland?

就我思考这个问题的时候, linux QQ给我发了一个系统通知, 我的电脑上的系统通知服务原先只是为了让linux qq不崩溃才安装的, 然而这个时候, 它给了我一个新的解决方案: 使用系统通知来呈现翻译结果. 于是搜了一下如何发送系统通知, 发现竟然意外的简单.

```bash
notify-send "title" "content"
```

那么接下来的问题: 如何获取选中文本的内容? 这个问题, 我原本计划通过阅读`wl-clipboard`来学习的, 但是我想先尽快用上翻译, 把优化放到以后再说, 于是决定直接使用`wl-clipboard`来获取选中文本内容, 那么至此思路理清, 大致如下:

1. 使用剪切板获取到选中文本的内容, 可以使用`wl-paste -p`来获取
2. 获取文本之后, 将换行符替换成空格 (这块可以有更好的处理方法, 简单起见就全换掉了), 使用`sed`
3. 文本处理完毕后, 将文本输入进`translate.js`中进行翻译, (这块可以使用别的现成工具)
4. 翻译结果出来之后, 将结果以系统通知的形式呈现出来, 当然, 系统通知必须要有, 可以是`dunst`, `mako`, `swaync`, 以及kde或者gnome的桌面消息通知都可以. 发送翻译结果使用命令`notify-send "标题" "翻译内容"`

以我的划词翻译为案例,  我在`~/.config/sway/config`中加入了这么一行作为划词翻译触发按键

```
bindsym Ctrl+Mod1+z exec ~/.config/sway/bin/translate.sh
```

那么来看看`translate.sh`的内容是怎么样的:

```bash
a=$(wl-paste -p | sed ':a;N;$!ba;s/\n/ /g' | node ~/.config/sway/bin/translate.js)
notify-send "Google" "$a"
```

首先从primary剪切板中获取选中的文本内容, 注意这个剪切板不需要你按ctrl-c, 选中文本的时候, 文本会自动出现在primary剪切板中. 然后使用`sed`命令将`\n`都替换为空格. 再然后执行js脚本, 将要翻译的内容通过管道符输入进去, js脚本调用谷歌翻译. 最后出来的翻译结果通过`notify-send`发送出去了.

`translate.js`文件的内容如下

```js
function TL(a) {
  var k = "";
  var b = 406644;
  var b1 = 3293161072;

  var jd = ".";
  var $b = "+-a^+6";
  var Zb = "+-3^+b+-f";

  for (var e = [], f = 0, g = 0; g < a.length; g++) {
    var m = a.charCodeAt(g);
    128 > m
      ? (e[f++] = m)
      : (2048 > m
          ? (e[f++] = (m >> 6) | 192)
          : (55296 === (m & 64512) &&
            g + 1 < a.length &&
            56320 === (a.charCodeAt(g + 1) & 64512)
              ? ((m = 65536 + ((m & 1023) << 10) + (a.charCodeAt(++g) & 1023)),
                (e[f++] = (m >> 18) | 240),
                (e[f++] = ((m >> 12) & 63) | 128))
              : (e[f++] = (m >> 12) | 224),
            (e[f++] = ((m >> 6) & 63) | 128)),
        (e[f++] = (m & 63) | 128));
  }
  a = b;
  for (f = 0; f < e.length; f++) (a += e[f]), (a = RL(a, $b));
  a = RL(a, Zb);
  a ^= b1 || 0;
  0 > a && (a = (a & 2147483647) + 2147483648);
  a %= 1e6;
  return a.toString() + jd + (a ^ b);
}

function RL(a, b) {
  var t = "a";
  var Yb = "+";
  for (var c = 0; c < b.length - 2; c += 3) {
    var d = b.charAt(c + 2);
    d = d >= t ? d.charCodeAt(0) - 87 : Number(d);
    d = b.charAt(c + 1) === Yb ? a >>> d : a << d;
    a = b.charAt(c) === Yb ? (a + d) & 4294967295 : a ^ d;
  }
  return a;
}

const http = require("http");
const readline = require("readline");
const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
});

rl.question("", function (text) {
  var strip_text = text.replace(/\n/g, "");
  var target_language = "zh-CN";
  const options = {
    hostname: "translate.google.com",
    path: `/translate_a/single?client=webapp&sl=auto&tl=${target_language}&hl=${target_language}&dt=at&dt=bd&dt=ex&dt=ld&dt=md&dt=qca&dt=rw&dt=rm&dt=ss&dt=t&source=bh&ssel=0&tsel=0&kc=1&tk=${TL(
      strip_text,
    )}&q=${encodeURIComponent(strip_text)}`,
    method: "GET",
    headers: { responseType: "json" },
  };
  const req = http
    .request(options, (res) => {
      let data = "";
      res.on("data", (chunk) => {
        data += chunk;
      }); // Ending the response
      res.on("end", () => {
        var result = JSON.parse(data);
        var content_list = result[0];
        var final = "";
        // console.log(content_list)
        for (let index = 0; index < content_list.length; index++) {
          if (content_list[index][0] !== null) {
            final += content_list[index][0];
          } else {
            break;
          }
        }
        console.log(final);
      });
    })
    .on("error", (err) => {
      console.log("Error: ", err);
    })
    .end();
});
```
