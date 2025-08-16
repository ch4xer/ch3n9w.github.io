---
title: ext4到btrfs转换记录
author: ch4ser
typora-root-url: ../
date: 2023-01-16 05:28:51
categories:
  - 技术
cover:
  image: btrfs.jpeg
---

这篇文章是对我从ext4文件系统转换到btrfs过程中的一些操作记录, 便于日后参考. 

## 前置准备

1. 制作arch linux 启动盘, 版本越新越好.
2. 备份重要文件
3. 我个人在转换前会把大文件(例如虚拟机文件)转移到移动硬盘里, 让转换过程更快一些

## 转换

进入LiveCD 系统, 对主分区进行转换

```bash
btrfs-convert /dev/nvme0n1p2
```

等待一段时间之后, 显示`conversion complete`就表示没有问题, 接下来还需要做三件事情才可以进入系统

### 修改fstab

首先将转换成功后的分区挂载到`/mnt`下

```bash
mount /dev/nvme0n1p2 /mnt
```

使用`lsblk -f`命令查看分区的UUID号, 拍个照片记一下

编辑`/mnt/etc/fstab`, 修改这个分区类型为btrfs, 将最后的两列数字都改成0, 保存退出

### 重建内存盘

先挂载, 然后进入chroot环境

```bash
mount -t proc none /mnt/proc
mount -t sysfs none /mnt/sys
mount -o bind /dev /mnt/dev
chroot /mnt bash
```

然后执行下列命令来为所有内核重建内存盘

```bash
mkinitcpio -P
```

最后重建grub引导, 按照道理应该要把引导分区`/dev/nvme0n1p1`挂载到`/mnt/boot`之后才可以, 但是我记得自己执行的时候没有挂载?

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

### 重建grub引导

在上一步的chroot环境中, 执行下列命令, 记得把引导分区挂载到`/mnt/boot` 

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```



大功告成, 退出chroot, 重启电脑就可以进入你的系统了, 唯一的不同是它已经是btrfs了.

---



## 子卷建立

经过上述操作后, 你会得到一个没有子卷的根文件系统, 这点可以通过命令验证

```bash
sudo btrfs subvol list /
```

没有子卷就没有快照, 为了利用好btrfs的特性, 有必要新建快照,  并将数据迁移到里面. 同样, 我们需要进入 LiveCD 系统

首先将btrfs分区挂载到`/mnt`下

```bash
mount -o subvol=/ /dev/nvme0n1p2 /mnt
```

接下来就要开始新建子卷了, 我新建的子卷有两个, 一个叫做`@`, 一个叫做`@home`, 分别挂载根目录和家目录. 这样新建的原因是`timeshift`在使用btrfs进行备份的时候规定这样的命名.

那么首先, 使用btrfs的快照功能新建`@`子卷

```bash
btrfs subvol snapshot /mnt /mnt/@
```

然后建立`@home`子卷, 再将`@`子卷中`/home`的内容迁移过去

```bash
btrfs subvol create /mnt/@home
mv -v /mnt/@/home/* /mnt/@home
```

好了, 子卷新建完毕, 接下来要让系统在启动的时候挂载子卷

首先, 挂载btrfs分区到`/mnt`

```bash
# 这一步在上面如果执行过了就不需要执行了
mount -o subvol=/ /dev/nvme0n1p2 /mnt
# 这些需要挂载
mount -o bind /dev /mnt/dev                        
mount -o bind /proc /mnt/proc                      
mount -o bind /sys /mnt/sys
mount -o bind /boot /mnt/boot
# 进入chroot环境
chroot /mnt
```

然后新建内存初始盘

```bash
mkinitcpio -P
```

然后更新fstab, 我的如下, 里面重要的是`subvol`一项, 其他的参数中, `autodefrag`是btrfs用于应对碎片化的挂载选项, `compress=lzo`启动透明压缩

```
# /dev/nvme0n1p2
UUID=6dd702be-7727-447e-98ec-a79205f18df7	/         	btrfs      	defaults,noatime,autodefrag,subvol=@,compress=lzo,	0 0
UUID=6dd702be-7727-447e-98ec-a79205f18df7	/home         	btrfs      	defaults,noatime,autodefrag,subvol=@home,compress=lzo	0 0

# /dev/nvme0n1p1
UUID=8D41-41B9      	/boot     	vfat      	rw,relatime,fmask=0022,dmask=0022,codepage=437,iocharset=ascii,shortname=mixed,utf8,errors=remount-ro	0 2
```

最后顺手更新一下grub (似乎没必要?)

```bash
grub-mkconfig -o /boot/grub/grub.cfg
```

重启进入系统就可以了. 接下来可以安装`timeshift`来对系统进行定时备份

在一切都没有问题后, 就可以重新进入LiveCD环境, 清理掉原来的那些文件了

```bash
mount -o subvol=/ /dev/nvme0n1p2 /mnt
cd /mnt
rm -r var usr .......(除了子卷外都删掉)
```

最后剩下这些

![image-20230116063914754](image-20230116063914754.png)

清理完毕, 收工

## 其他

去除已有文件的碎片化

```bash
sudo btrfs filesystem defragment -r /
```

回收分配但未使用的数据, 对节约空间有帮助

```bash
sudo btrfs balance start /
sudo btrfs balance status /
```



## 参考

https://coda.world/btrfs-move-to-subvolume/

https://blog.samchu.cn/posts/linux-ext4-to-btrfs/

https://www.jwillikers.com/btrfs-mount-options
