REM 需求：
	REM 设定超过某个时间点操作删除某个文件(夹)且不可恢复
	REM 以此威胁自己起床或做其他事情

REM 分析：
	REM 需要加入用户输入时间点
	REM 需要判断时间点且进行下一步内容

REM 实现：
	REM 提示用户创建一个时间点
		REM 进行时间点规则判断
		REM 提示用户是否确认
	REM 提示用户给定一个文件或文件夹
		REM 判断时间或文件夹是否存在
		REM 提示用户是否确认

REM 全局初始化
@echo off
setlocal ENABLEDELAYEDEXPANSION
color 0a
set version=20151218
title 文件删除胁迫工具 - F_Ms - %version% ^| imf_ms@yeah.net ^| f-ms.cn

:InputTime
for %%A in (userTime userTimeTemp userTimeCount userTimeMinute userTimeHour tomorrowRun) do set %%A=
cls

REM 提示用户输入执行时间
echo=#文件删除胁迫工具
echo=#时间例子：
echo=	    时 分
echo=	     3 5  (3点5分)
set/p userTime=#胁迫时间点:

REM 判断时间是否符合标准
if not defined userTime goto InputTime
set userTimeTemp=%userTime: =%
if not defined userTimeTemp goto InputTime
call:DefinedNoNumberString "%userTime: =%"
if "%errorlevel%"=="0" goto InputTime
for %%A in (%userTime%) do set /a userTimeCount+=1
if not "%userTimeCount%"=="2" goto InputTime
for /f "tokens=1,2" %%A in ("%userTime%") do (
	set userTimeHour=%%A
	set userTimeMinute=%%B
	if not "!userTimeHour:~2,1!"=="" goto InputTime
	if not "!userTimeMinute:~2,1!"=="" goto InputTime

	if %%A0 lss 0 goto InputTime
	if %%A0 gtr 230 goto InputTime
	if %%B0 lss 0 goto InputTime
	if %%B0 gtr 600 goto InputTime

	if "!userTimeHour:~1,1!"=="" set userTimeHour=0!userTimeHour!
	if "!userTimeMinute:~1,1!"=="" set userTimeMinute=0!userTimeMinute!
	set userTime=!userTimeHour!!userTimeMinute!
)

REM 判定执行时间
call:CurrentTime
if %currentTime% geq %userTime% set tomorrowRun=Yes


REM 提示用户输入被执行删除文件
:InputFile
cls
for %%A in (userFile) do set %%A=
set /p userFile=#请将胁迫文件(夹)拖入此窗口并回车确认:
if not defined userFile goto InputFile
set userFile=%userFile:"=%
if not exist "%userFile%" goto InputFile

echo=#设置成功
ping -n 2 127.1>nul 2>nul

:DisplayMessage
cls
echo=
echo=		%userTimeHour%点%userTimeMinute%分
echo=
echo=	"%userFile%"
echo=
echo=		将被删除
echo=
echo=		   且
echo=
echo=		不可恢复
echo=
echo=	   请在之前，解除命令
echo=
echo=	 作者不对结果负任何责任
echo=

:WaitTime
if not defined tomorrowRun goto WaitTime2
call:CurrentTime
if %userTime%0 geq %CurrentTime%0 goto WaitTime2
ping -n 11 127.1>nul 2>nul
goto WaitTime

:WaitTime2
call:CurrentTime
if %CurrentTime%0 geq %userTime%0 goto DeleteFile
ping -n 11 127.1>nul 2>nul 
goto WaitTime2

REM 防止程序错误
exit

:DeleteFile
cls
echo=
echo=	两分钟后将执行删除命令
echo=
echo=	     这是最后期限
ping -n 121 127.1>nul 2>nul
del /f /q "%userFile%"
if exist "%userFile%" rd /s /q "%userFile%"
cls
echo=
echo=
echo=		抱歉

pause>nul
exit





goto end
:子程序开始:

:CurrentTime
REM 初始化子程序
for %%a in (currentTime) do set %%a=

REM 处理时间
for /f "tokens=1,* delims=:" %%a in ("%time%") do if %%a0 lss 100 (
	set currentTime=0%%a%%b
) else (
	set currentTime=%%a%%b
)
REM 规范时间
set currentTime=%currentTime:.=%
set currentTime=%currentTime::=%
set currentTime=%currentTime: =%
set currentTime=%currentTime:~0,-4%

REM 退出及返回值
exit/b

REM 判断变量中是否含有非数字字符 call:DefinedNoNumberString 被判断字符
REM					返回值0代表有非数字字符，返回值1代表无非数字字符
:DefinedNoNumberString
REM 判断子程序基本需求参数
if "%~1"=="" exit/b 2

REM 初始化子程序需求变量
for %%B in (DefinedNoNumberString) do set %%B=
set DefinedNoNumberString=%~1

REM 子程序开始运行
set DefinedNoNumberString=!DefinedNoNumberString:0=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:1=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:2=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:3=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:4=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:5=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:6=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:7=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:8=!
if not defined DefinedNoNumberString exit/b 1
set DefinedNoNumberString=!DefinedNoNumberString:9=!
if not defined DefinedNoNumberString (exit/b 1) else exit/b 0

:子程序结束
:end