---
title: k8s lan party
author: ch3n9w
date: 2024-03-15 07:34:46
categories: CTF
---

为数不多的和K8s相关的CTF, 也很久没有尝试做题了.

<!--more-->

## RECON

简单的服务发现, 首先使用`env`看K8s相关的变量, 得到网段后用dnscan扫描就可以发现服务了.


![recon](recon.png)

This blog is good written [link](https://thegreycorner.com/2023/12/13/kubernetes-internal-service-discovery.html)

## Finding Neighbours

According to the description, the sidecar container of current pod is sending some information (possibly flag) to remote server. So, the first step is digging the remote server like what we do in the first challenge, which leads me to `reporting-service.k8s-lan-party.svc.cluster.local`.

As we all know, all containers within same pod share one network namespace, which means we can sniff the traffic from our current container.

```sh
tcpdump -i any host reporting-service.k8s-lan-party.svc.cluster.local and tcp -w traffic.pcap
```

and the flag was in the `traffic.pcap`

![neighbours](neighbours.png)
