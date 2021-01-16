---
title: "File Size Limit Exceeded 问题处理"
date: "2008-08-19"
tags: ["Linux"]
categories: ["DevOps"]
---

File Size Limit Exceeded

今天，RoseHA双机软件出现了故障，其中一台上的hasvrd进程挂掉，在双机管理程序中看到这台server的状态都是error。

<!--more-->

而重启了RoseHA服务之后，这一台server上的hasvrd还是不能启动。于是我直接单独运行hasvrd，结果出现了File Size Limit Exceeded 的错误。“文件大小超过限制”，奇怪！因为该程序文件大小还不到300KB！

在网络上借鉴了多位前辈的经验教训之后，我估计应该是该程序启动后会打开RoseHA的日志文件，而该日志的大小已经达到了2G多。于是立刻手动清空该日志文件，再次重启RoseHA，结果hasvrd进程成功启动，双机重新恢复了正常。

最后，为了避免以后再次出现该问题，我在两台双机Server中添加了“每天自动清除一次日志”的计划任务。

```bash
crontab -e
```

```text
30 1 * * * cat /dev/null > /opt/roseha/etc/*.log
```

