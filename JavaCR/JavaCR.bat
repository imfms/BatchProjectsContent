@echo off&setlocal ENABLEDELAYEDEXPANSION
title JavaCR - 方便Java的编译与运行 - F_Ms ^| imf_ms@yeah.net ^| f-ms.cn ^| 20160106
REM 检查运行环境
if "%~1"=="" (goto help) else if not exist "%~1" goto help

REM 编译
:Compile
title JavaCR - 方便Java的编译与运行 - F_Ms ^| imf_ms@yeah.net ^| f-ms.cn ^| 20160106
cls
set runClass=
echo=#JavaCR
if /i "%~x1"==".java" (
	echo=#正在调用命令javac编译源文件 %~nx1
	pushd "%~dp1"
	javac -d . "%~1"
	popd
	if "!errorlevel!"=="9009" (
		echo=
		echo=	#错误:未发现javac.exe,请检查是否已成功安装JDK或是否已成功配置path路径
		pause>nul
		goto end
	) else if not "!errorlevel!"=="0" (
		echo=#编译发现错误,请检查后重试
		pause
		cls
		goto Compile
	) else (
		echo=#编译成功
	)
) else (
	if /i "%~x1"==".class" (
		goto Run
	) else (
		echo=#文件类型错误,只接受.java与.class
		pause>nul
		goto end
	)
)

:Run
REM 运行
if defined userInput set userInput=
REM 处理带有包的java文件
if defined runClass goto Run2
for /f "usebackq tokens=1,2 delims=p; " %%a in ("%~1") do if "%%a"=="ackage" (
	set runClass=%%b.%~n1
	goto Run2
)
set runClass=%~n1
:Run2
echo=#正在调用java运行类 %runclass%
pushd "%~dp1"
title 正在运行类: %runClass%
cls
java %runClass%
popd
if "!errorlevel!"=="9009" (
		echo=
		echo=	#错误:未发现java.exe,请检查是否已成功安装JDK或是否已成功配置path路径
		pause>nul
		goto end
) else if not "%errorlevel%"=="0" (
	echo=#运行错误，请检查后重试
	pause>nul
	goto Compile
)
set /p userInput=#回车重新运行,空格回车重新编译运行,Alt+Space+C快捷退出:
if "%userInput%"=="" (goto Run) else goto Compile

goto end
REM 帮助
:help
echo=
echo=#帮助
echo=
echo=			JavaCR - 方便Java的编译与运行
echo=
echo=	需电脑预先安装成功JDK,Java运行环境 且已配置成功安装目录系统环境变量
echo=
echo=	#使用方法为 %~nx0 [*.java源代码文件^|*.class字节码文件]
echo=
echo=		  推荐添加到代码编辑器运行内并添加调用快捷键
echo=					-
echo=		 F_Ms ^| imf_ms@yeah.net ^| f-ms.cn ^|  20151220
echo=
pause>nul
:end
exit/b