---
title: "DOS下.bat批处理脚本编程学习笔记"
date: "2008-01-04"
tags: ["Windows"]
categories: ["DevOps","Programming"]
---

**需要理解的一些概念：**

1. 什么是脚本？

<!--more-->

脚本可以理解为是一种简单的程序（它的语法相对简单，不需要编译，是解释执行的）。

这一点和Linux下的Shell是类似的，并且像PHP,Python这样流行的语言也属于脚本语言。

他们共同的特点是，不需要像C,Java那样需要经过编译成二进制文件后才可以运行，它们需要的，仅仅是一个专属的解释器。

2. 什么是批处理？

我们可以理解为“批量处理”，将一些命令保存到一个文件中，然后一条条一次运行。当然，批处理的功能并不局限于此。

3. 如何建立批处理程序？

新建一个文本文档，将代码写入后更改其扩展名为bat或cmd(NT中的另一种批处理文件)即可。

4. 如何运行批处理程序？

无需编译等操作，直接在Windows下双击或DOS下输入批处理文件名即可运行。

5. 批处理都有那些命令？

我们可以这样想，除了批处理专属的命令外，任何可以在DOS下使用的命令批处理都是可以使用的。

**学习一门语言的最好的方法是：**

1. 有一本系统的、全面的、实用的、循序渐进的阶段性教程来进行指导：《批处理阶段教程[英雄出品]》

2. 有大量的源代码可供参考，通过对这些代码的分析、修改与借鉴来编写出属于自己的程序：《70个批处理实用程序源码》

3. 有一本相当实用的参考手册，可以在实际的代码编写中快速查阅所有命令的参数和实用方法等：《DOS命令全集(中英文对照)》

还有，大家始终要记得批处理脚本的能力真的很有限，我们只需要用它来方便我们处理一些简单的问题就好了！

例如：以下代码便是我根据日常工作需要编写的一个网速检测的脚本

Windows XP版本

```powershell
@echo off
@echo 该程序用于对ping的返回结果进行分析判断
@echo 测试发送包大小为默认的32bytes
@echo ......................................
set /p SITE=请自定义测试网站地址(如www.baidu.com)：
set /p TIMES=请自定义ping的次数(如10)：
set /p MAX=请自定义可接受的最大延迟数，默认单位ms(如200)：
set /p TIMEOUTMAX=请自定义可接受的最大掉包次数(小于%TIMES%)：
@echo ......................................

goto FLUX

:FLUX ::定义模块，用于计算出当前电脑ping结果的最小值与掉包次数
ping -n %TIMES% %SITE% >ping.txt
find "Minimum" ping.txt >pingmin.txt
find "Lost" ping.txt >pingtimeout.txt
for /f "skip=2 tokens=3" %%M in (pingmin.txt) do set PING=%%M
echo %PING% >pingminnum.txt
for /f "tokens=1 delims=m" %%I in (pingminnum.txt) do set NUM=%%I
for /f "skip=2 tokens=10" %%J in (pingtimeout.txt) do set TIMEOUT=%%J
echo 最短:%NUM%ms 丢失:%TIMEOUT%/%TIMES%
if %TIMEOUT% GEQ %TIMEOUTMAX% (goto WARNING) 
if %NUM% GEQ %MAX% (goto WARNING) else goto CONTINUE

:WARNING
mshta vbscript:msgbox("网络已经差于预设值！请立刻采取相应措施！",64,"警告窗口")(window.close)
goto CONTINUE

:CONTINUE
goto FLUX ::从这里开始再次回到FLUX模块进行循环
```

Windows 7版本

```powershell
@echo off
@echo 该程序用于对ping的返回结果进行分析判断
@echo 测试发送包大小为默认的32bytes
@echo ......................................
set /p SITE=请自定义测试网站地址(如www.baidu.com)：
set /p TIMES=请自定义ping的次数(如10)：
set /p MAX=请自定义可接受的最大延迟数，默认单位ms(如200)：
set /p TIMEOUTMAX=请自定义可接受的最大掉包次数(小于%TIMES%)：
@echo ......................................

goto FLUX

:FLUX ::定义模块，用于计算出当前电脑ping结果的最小值与掉包次数
ping -n %TIMES% %SITE% >ping.txt
find "最短" ping.txt >pingmin.txt
find "丢失" ping.txt >pingtimeout.txt
for /f "skip=2 tokens=3" %%M in (pingmin.txt) do set PING=%%M
echo %PING% >pingminnum.txt
for /f "tokens=1 delims=m" %%I in (pingminnum.txt) do set NUM=%%I
for /f "skip=2 tokens=8" %%J in (pingtimeout.txt) do set TIMEOUT=%%J
echo 最短:%NUM%ms 丢失:%TIMEOUT%/%TIMES%
if %TIMEOUT% GEQ %TIMEOUTMAX% (goto WARNING) 
if %NUM% GEQ %MAX% (goto WARNING) else goto CONTINUE

:WARNING
mshta vbscript:msgbox("网络已经差于预设值！请立刻采取相应措施！",64,"警告窗口")(window.close)
goto CONTINUE

:CONTINUE
goto FLUX ::从这里开始再次回到FLUX模块进行循环
```

