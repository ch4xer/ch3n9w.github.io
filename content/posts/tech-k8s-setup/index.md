---
title: virtualbox中搭建kubernetes集群
author: ch4ser
typora-root-url: ../
date: 2022-12-12 12:17:49
categories:
  - 技术
---

环境问题, 一生之敌.

<!--more-->

## 准备

### 网络问题

这是最重要的问题, 国内的那些借助于镜像源的扭曲解决方案在我这里不好使. 推荐在路由器上安装clash

### virtualbox安装ubuntu18.04

~~这步没什么好讲的, **要注意的是使用桥接网络模式**, 为什么? 因为集群内通信, 如果不使用桥接模式, 那就只能使用 NAT network来进行node之间通信+Host Only让宿主机能够连接+NAT让虚拟机可以连接到外网去, 在这种情况下, 环境就会变得很复杂, 所以还是选择桥接模式比较好.~~

~~那桥接模式有什么不好的地方吗? 有, 如果你的宿主机开着代理, 桥接模式是走不了你宿主机的代理的, 即便开启了Allow LAN也无济于事, 除非你桥接到了代理软件的虚拟网卡上, 但是这条路我没走通, 所以最后选择了在路由器上安装clash~~

网卡类型使用NAT+Host Only就可以了, Host Only那里最好新建一张网卡, NAT用于集群的对外网络请求(下载之类的), 宿主机上使用clash tun或者dae或者v2raya都可以开启透明代理来让虚拟机可以连接外网.

然后在netplan中启用第二张网卡并设置静态ip, 例如

```yaml
network:
  ethernets:
    enp0s3:
      dhcp4: true
    enp0s8:
      dhcp4: no
      addresses: [192.168.59.125/24]
  version: 2
```



### 关闭swap

```bash
swayoff -a # 临时禁用
```

如果永久禁用, 修改`/etc/fstab`

## 安装依赖

### docker

```bash
apt-get update && apt-get install -y \
  apt-transport-https ca-certificates curl software-properties-common gnupg2

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

apt-get update && apt-get install -y \
  containerd.io=1.2.13-1 \
  docker-ce=5:19.03.8~3-0~ubuntu-$(lsb_release -cs) \
  docker-ce-cli=5:19.03.8~3-0~ubuntu-$(lsb_release -cs)


cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl daemon-reload; systemctl restart docker

```

### kubernetes

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https curl
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

cat <<EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt-get update; apt-get install -y kubelet=1.25.3-00 kubeadm=1.25.3-00 kubectl=1.25.3-00; apt-mark hold kubelet kubeadm kubectl

echo 'alias k=kubectl' >> ~/.bashrc ; source ~/.bashrc

```

### 清理

```bash
kubeadm reset
rm -r ~/.kube /etc/containerd/config.toml /etc/cni/net.d
systemctl restart containerd
```

## 集群安装

### master setup

```bash
kubeadm init --pod-network-cidr=10.244.0.0/16 --service-cidr=10.96.0.0/12 --apiserver-advertise-address=192.168.59.126
mkdir -p $HOME/.kube;sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config;sudo chown $(id -u):$(id -g) $HOME/.kube/config



```

然后安装flannel, 下载 https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml , 然后往其中添加网卡的名称

```yaml
...      
      containers:
        - name: kube-flannel
          image: docker.io/flannel/flannel:v0.21.4
          #image: docker.io/rancher/mirrored-flannelcni-flannel:v0.21.4
          command:
            - /opt/bin/flanneld
          args:
            - --ip-masq
            - --kube-subnet-mgr
            - --iface=enp0s8 <-- 添加
...
```

然后执行`kubectl apply -f kube-flannel.yml`就行

### worker setup

```bash
rm /etc/containerd/config.toml
systemctl restart containerd docker kubelet
kubeadm join 10.0.2.15:6443 --token am85zn.iymt1qn11oel8ktn \
	--discovery-token-ca-cert-hash sha256:ede03b0defa4929ccfcbf6a21ae924cdd6947c5fe6a0090144c3ccea00475344
```

然后修改`10-kubeadm.conf`添加静态ip地址就完成了.

## 部署应用

来装个简单的应用

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  # 部署名字
  name: test-k8s
spec:
  replicas: 2
  # 用来查找关联的 Pod，所有标签都匹配才行
  selector:
    matchLabels:
      app: test-k8s
  # 定义 Pod 相关数据
  template:
    metadata:
      labels:
        app: test-k8s
    spec:
      # 定义容器，可以多个
      containers:
      - name: test-k8s # 容器名字
        image: ccr.ccs.tencentyun.com/k8s-tutorial/test-k8s:v1 # 镜像
```

然后部署service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: test-k8s
spec:
  selector:
    app: test-k8s
  type: NodePort
  ports:
    - port: 8080        # 本 Service 的端口
      targetPort: 8080  # 容器端口
      nodePort: 31000   # 节点端口，范围固定 30000 ~ 32767, 虚拟机外的机器可以通过该端口访问内部服务
```

来访问一下, 顺利就好
