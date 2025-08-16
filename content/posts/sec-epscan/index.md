---
title: (论文&代码阅读)EPScan:Automated Detection of Excessive RBAC Permissions in Kubernetes Applications.
author: ch4xer
date: 2025-07-31T16:20:47+08:00
cagetories:
  - 安全研究
draft: true
---

# EPScan:Automated Detection of Excessive RBAC Permissions in Kubernetes Applications.

> 遥想去年开题思考博士研究点的时候，就有分析Kubernetes RBAC过度授权的问题，那个时候刚好就看到了这篇论文，只好含恨想别的。今年复旦的团队总算把源码放出来了，于是就有了这篇阅读笔记。

[Paper](https://ieeexplore.ieee.org/abstract/document/11023379/)
[Source Code](https://github.com/seclab-fudan/EPScan)

## Background

RBAC is a critical component of Kubernetes security, but excessive permissions can lead to vulnerabilities. Currently, there is no work that identify whether the application requires all the permissions granted by the developer or, some of them are excessivly granted. This work aims to automate the detection of excessive RBAC permissions in Kubernetes applications, which can help developers and security teams to identify and mitigate potential security risks.

## Approach

Given a third-party application, EPScan (the tool developed by the authors) determines the permissions required by application pods based on source code analysis and compares them with the permissions granted by the RBAC policies to identify excessive permissions.

Challenges:

- (C1) How to identify source code entry for executables running in the pod, as cloud native applications always consist of multiple pods?
- (C2) How to identify and model resource access behavior in the source code?
- (C3) How to determine the reachable resource access for each program?

[Arichitecture](./architecture.png)

### RBAC-centered Configuration Analysis

This step extracts and formats the RBAC permissions from configuration files.

### LLM-assisted Pod-Program Matching (to solve C1)

1. download the image of the application pod
2. generates a prompt based on the contents of the startup commands and scripts collected from the container image
3. use LLM to identify the executable files in the image (use few-shot learning to format the output from LLM), and extracts them from it.
4. locate the code entry of these executables in source code repository via runtime information within the executable files, such as **the file path of the function's source code**, then identify the `main` function in the code entry.

### RefGraph-based Program Behavior Analysis

1. 

### Excessive permission detection

## Evaluation

## Code
