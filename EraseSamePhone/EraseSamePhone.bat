@echo off
setlocal ENABLEDELAYEDEXPANSION

title 文本文档电话去除重复工具 ^| F_Ms ^| f-ms.cn ^| 20160303

REM 判断运行环境
if "%~1"=="" (
	echo=#使用方法：
	echo=	将要去重的文本文件拖到本程序文件
	pause
	exit/b
) else if exist "%~1" (
	if /i not "%~x1"==".txt" if not exist "%~1\" (
		echo=#注意：
		echo=	抱歉，只支持文本文件^(扩展名为.txt的文件^)或文件夹
		echo=	请先将文档转换为文本文件^(或文件夹^)再拖到本程序文件上^(非本窗口^)
		pause
		exit/b
	) 
) else (
	echo=#警告：
	echo=	抱歉，文件不存在
	pause
	exit/b
)


set fileName=%~1
set filePath=%~dp1
if exist "%~1\" set filePath=%~1\
set fileNewName=%~dp1%~n1_去除重复后%~x1
if exist "%~1\" set fileNewName=%~1_去除重复后\
set QQCF_Count=0


if exist "%fileNewName%" (
	echo=#警告：
	if exist "%fileName%\" (
		if exist "%fileNewName%" (
			echo=	目录 "%fileNewName%" 已存在
			echo=	请检查后重试
			pause>nul
			exit/b
		)
	) else echo=	文件 "%~nx1" 已存在
	echo=	按任意键覆盖，关闭窗口则取消
	pause>nul
	(if a==b echo=a)>"%fileNewName%"
)
cls

echo=_______________________________________________
echo=
echo=#正在查找重复

if exist "%fileName%\" (
	echo=	以下是文件夹内文件的去重顺序，请务必检查有无问题
	echo=	有问题请关闭本窗口后重新命名文件夹内文件
	echo=
	for %%I in ("%filePath%*.txt") do echo=	%%I
	pause
	md "%fileNewName%"
	for %%I in ("%filePath%*.txt") do for /f "usebackq tokens=1,* delims=	 " %%a in (`type "%%~I"`) do if "%%~b"=="" (call:One "%fileNewName%%%~nxI" %%~a %%~b) else call:Two "%fileNewName%%%~nxI" %%~a %%~b
) else for /f "usebackq tokens=1,* delims=	 " %%a in (`type "%fileName%"`) do if "%%~b"=="" (call:One "%fileNewName%" %%~a %%~b) else call:Two "%fileNewName%" %%~a %%~b
echo=
echo=_______________________________________________
echo=
echo= 查找重复结束，已筛选出 %QQCF_Count% 条重复数据
echo= 去除重复数据后文件(夹)为：%~n1_去除重复后%~x1
echo=                                         F_Ms
echo=_______________________________________________
echo=
pause
goto end

:子程序开始

REM 单个号码判断
:One
set QCCF_-Temp=%~2
REM if "%QCCF_-Temp:~0,1%"=="-" set QCCF_-Temp=%QCCF_-Temp:~1%
if defined QCCF-%QCCF_-Temp% (
	set /a QQCF_Count+=1
	echo=	发现重复：%QCCF_-Temp%
) else (
	echo=%QCCF_-Temp%>>"%~1"
	set QCCF-%QCCF_-Temp%=0
)
exit/b


REM 多个号码判断
:Two
set tempTwoVar=
:Two2
set QCCF_-Temp=%~2
REM if "%QCCF_-Temp:~0,1%"=="-" set QCCF_-Temp=%QCCF_-Temp:~1%
if defined QCCF-%QCCF_-Temp% (
	set /a QQCF_Count+=1
	echo=	发现重复：%QCCF_-Temp%
) else (
	set tempTwoVar=!tempTwoVar!	%QCCF_-Temp%
	set QCCF-%QCCF_-Temp%=0
)

if not "%~3"=="" (
	shift/2
	goto Two2
)
set tempTwoVar2=
if defined tempTwoVar (
	set tempTwoVar2=!tempTwoVar: =!
	set tempTwoVar2=!tempTwoVar2:	=!
)
if defined tempTwoVar2 echo=!tempTwoVar:~1!>>"%~1"
exit/b


:子程序结束
:end