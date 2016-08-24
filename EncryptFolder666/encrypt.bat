@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"

REM 程序配置
:: 文件夹深度
set "dirLevel=50"
set "rootDir=encrypt"

REM 程序初始化
set "encryptString="
if not exist "%rootDir%" md "%rootDir%"

set "localLevel=0"

REM 目录生成
for /l %%a in (1,1,%dirLevel%) do (
	call:random encryptString
	echo=!encryptString!
	call:createDir %rootDir%\!encryptString! %dirLevel%
)


goto end

:random
:: call:random var
:: 生成随机字符到var
set "%1=!random!!random!!random!!random!!random!!random!!random!!random!"
exit/b

:createDir
:: call:createDir dir dirLevel
:: 创建层级目录
for /l %%A in (1,1,%~2) do (
	call:random encryptString
	echo=	!encryptString!
	md "%~1\!encryptString!"
	echo=%~1\!encryptString!>"%~1\!encryptString!\!encryptString!"
)
exit/b

:end