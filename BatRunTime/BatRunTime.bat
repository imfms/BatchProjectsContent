@echo off&Setlocal enabledelayedexpansion
REM 功能：测试命令运行时间
REM 版本：20160107
title BatRunTime - 计算命令运行时间 F_Ms ^| 博客：f-ms.cn
if "%~1"=="/?" goto help
if not "%~1"=="" (
	set batruntimekz=
	call:localtime
	echo=#计时开始
	for /f "tokens=1,* delims= " %%a in ("%*") do set batruntimekz=%%b
)

::测试命令插入处
:command
if defined user set user=
if "%~1"=="" (
	set /p user=#请输入被计时命令：
	if defined user (
		call:localtime
		start /wait "BatRunTime计时中...  !user!" cmd /c !user!
	) else goto command
) else (
	start /wait "BatRunTime计时中...  %~1 %batruntimekz%" cmd /c "%~1" %batruntimekz%
)
::测试命令结束处
call:localtime %localtime%
if "%localtime:~2,1%"=="" (set localtime=0.%localtime%) else set localtime=%localtime:~0,-2%.%localtime:~-2%
echo=#计时结束 %localtime%秒
goto end


REM 帮助
:help
echo=	------------------------
echo=               %~n0
echo=
echo=        计算命令运行的时间可用于
echo=        判断多个命令间的效率比对
echo=
echo=	%~n0
echo=	    请输入命令：Command
echo=
echo=	%~n0 file
echo=	    call file %%2
echo=
echo=	%~n0 command
echo=	    cmd /c command %%2 ...
echo=
echo=	------------------------
echo=                           F_Ms
goto end

:localtime
for %%a in (localtime timeh timem times timems) do set %%a=
for /f "tokens=1,2,3,4 delims=:." %%1 in ("%time%") do set timeh=%%1&set timem=%%2&set times=%%3&set timems=%%4
set /a timeh=timeh*3600*100,timem=timem*60*100,times=times*100
set /a localtime=timeh+timem+times+timems
if not "%1"=="" set /a localtime=localtime-%1
goto :eof

:end
pause>nul 2>nul
exit /b