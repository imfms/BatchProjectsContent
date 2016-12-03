@echo off
setlocal ENABLEDELAYEDEXPANSION
set path=%path%;%~dp0
set version=20161203
title QQ_SLK2WAV QQ音频文件slk转wav批处理工具 ^| F_Ms - %version% ^| f-ms.cn

REM 输出格式设置
if /i "%~1"=="/mp3" (
	REM MP3
	set "outputFormat=mp3"
	set "formatMinSize=1"
	shift/1
) else (
	REM WAV
	set "outputFormat=wav"
	set "formatMinSize=40000"
)

REM 判断运行环境
if "%~1"=="" (
	echo=#简介
	echo=		 QQ_SLK2WAV
	echo=
	echo=     腾讯qq语音音频文件slk转wav批处理工具
	echo=  作者：F_Ms ^| 博客：f-ms.cn ^| 版本：%version%
	echo=
	echo=#使用方法：
	echo=	将要转换的QQ语音音频文件^(.slk^)或文件夹
	echo=	   拖动到本程序文件上即可^(非本窗口^)
	pause>nul
	exit/b
) else if not exist "%~1" if not exist "%~1\" (
	echo=#简介
	echo=		 QQ_SLK2WAV
	echo=
	echo=     腾讯qq语音音频文件slk转wav批处理工具
	echo=  作者：F_Ms ^| 博客：f-ms.cn ^| 版本：%version%
	echo=
	echo=#警告：
	echo=	指定文件或文件夹不存在
	pause>nul
	exit/b
)

color 0a
echo=
echo=#简介
echo=
echo=		 QQ_SLK2WAV
echo=
echo=     腾讯qq语音音频文件slk转wav批处理工具
echo=
echo=	  -使用到的第三方命令行工具-
echo=	      split(textutils)
echo=	  SilkDecoder(无原作者信息)
echo=	  FFmpeg (FFmpegDevelopers)
echo=	             敬上
echo=
echo=  作者：F_Ms ^| 博客：f-ms.cn ^| 版本：%version%
echo=
echo=#转换开始
echo=

REM 单文件转换
if not exist "%~1\" (
	REM 将转换路径设置为源文件路径下新文件夹内
	set "descDir=%~dpnx1"
	set "errorListFile=%~1.convert_error_infor.txt"
	call:convert "%~1" "!descDir!_after_convert" "!errorListFile!"
	goto converEnd
)

REM 相对全路径中截取子路径变量
set "baseDir=%~1"
if not "%baseDir:~-1%"=="\" set "baseDir=%baseDir%\"

REM 转换结果目录
set "descDir=%~1"
if "%descDir:~-1%"=="\" set "descDir=%descDir:~0,-1%"
set "descDir=%descDir%_after_convert\"

REM 转换错误信息路径
set "errorListFile=%baseDir:~0,-1%.convert_error_list.txt"

REM 目录遍历转换
for /r "%~1\" %%a in (*) do if exist "%%~a" (
	REM 将装换路径设置为原路径下新文件夹内,如果有子文件夹则拼合到新文件夹下
	set "targetDir=%%~dpa"
	set "targetDir=!targetDir:%baseDir%=!"
	call:convert "%%~a" "%descDir%!targetDir!" "%errorListFile%"
)

:converEnd
REM 安静模式
if /i "%~2"=="/Q" exit/b

REM 正常模式
echo=#转换结束
echo=
REM 如果有错误日志则打开错误日志
if exist "%errorListFile%" start "" "%errorListFile%"
pause>nul


goto end
REM --------------------------------------子程序区域--------------------------------------
:begin

REM 主子程序 call:convert "待转换文件" "转换结束目标路径"
:convert
cd /d "%~dp1"
set/p=^|	正在转换: "%~1" ^> <nul

REM 变量初始化
for %%a in (yuanFile tempFile newWavFileName fileTargetPath convertFailFileList) do set %%a=
set "fileTargetPath=%~2"
set "convertFailFileList=%~3"
set "yuanFile=%~1"
for /f "delims=" %%a in ("%yuanFile%") do (
	set "newWavFileName=%%~na.%outputFormat%"
	set "tempFile=%%~na"
)
set "tempFile=%tempFile: =%"

REM 文件前期处理
call:fileSizeTrue 50 "%~1"
if "%errorlevel%"=="0" (
	echo= #空文件,已跳过
	call:writeErrorLog 空文件 "%~1"
	exit/b 1
)

call:checkFileHeader "%~1"
if "%errorlevel%"=="0" (
	set tempFileSlk2Pcm=%~1
	set tempFilePcm2Wav=%~1.pcm
	goto passSplit
) else if "%errorlevel%"=="1" (
	echo= #文件头信息错误,已跳过
	call:writeErrorLog 文件类型错误	"%~1"
	exit/b 1
) else if "%errorlevel%"=="2" (
	echo= # AMR格式为通用格式,已跳过
	REM 拷贝直接拷贝源文件到目标路径
	if not exist "%fileTargetPath%" md "%fileTargetPath%"
	copy "%~1" "%fileTargetPath%\%newWavFileName%.amr">nul 2>nul
	call:writeErrorLog 通用音频格式	"%~1"
	exit/b 1
)
REM 裁剪无用文件头
call:GetFileSplitSize "%yuanFile%"
if not "%errorlevel%"=="0" (
	echo= #转换失败,疑似文件权限不足
	call:writeErrorLog 无访问权限	"%~1"
)
:passSplit

REM slk2pcm转换
call:slk2pcm "%tempFileSlk2Pcm%" "%tempFilePcm2Wav%"
if not "%errorlevel%"=="0" (
	set kbps=16000
	set tempFilePcm2Wav=%yuanFile%
	goto passSlk2Pcm
)
REM pcm2wav转换
set kbps=
set kbps=44100
:passSlk2Pcm
if not exist "%fileTargetPath%" md "%fileTargetPath%"
call:pcm2wav %kbps% "%tempFilePcm2Wav%" "%fileTargetPath%\%newWavFileName%"
if not "%errorlevel%"=="0" (
	echo= #转换失败,疑似指定文件编码类型错误
	call:writeErrorLog 文件编码错误	"%~1"
	call:DeleteTempFile
	exit/b 1
)

REM 判断是否真正执行成功
call:fileSizeTrue %formatMinSize% "%fileTargetPath%\%newWavFileName%"
if "%errorlevel%"=="0" if "%kbps%"=="44100" (
	set kbps=16000
	set tempFilePcm2Wav=%yuanFile%
	goto passSlk2Pcm
)
if "%errorlevel%"=="0" (
	if exist "%fileTargetPath%\%newWavFileName%" del /f /q "%fileTargetPath%\%newWavFileName%"
	echo= #转换失败,未知错误
	call:writeErrorLog 未知错误	"%~1"
	call:DeleteTempFile
	exit/b 1
)

echo= 转换成功
call:DeleteTempFile
exit/b 0

REM 检查文件文件头，是否为QQ语音文件 call:checkFileHeader file
REM 	返回值：1 - 指定文件错误, 2 - AMR文件, 3 - slk需要截首字节 0 - slk无需截首字节
:checkFileHeader
set fileHeaderTemp=
set /p fileHeaderTemp=<"%~1"
if not defined fileHeaderTemp exit/b 1
if /i "%fileHeaderTemp:~0,5%"=="#!AMR" exit/b 2
if /i "%fileHeaderTemp:~0,10%"=="#!SILK_V3" exit/b 3
if /i "%fileHeaderTemp:~0,9%"=="#!SILK_V3" exit/b 0
exit/b 1


REM 文件前期处理(去除首个字节) call:GetFileSplitSize "%yuanFile%"
:GetFileSplitSize
REM 获取文件后期裁剪长度
set fileSize=0
for  %%a in ("%~1") do set /a fileSize=%%~za+1
set tempFileSlk2Pcm=%tempFile%_ab
set tempFilePcm2Wav=%tempFile%_ab.pcm

REM 处理文件为双倍的长度
copy "%~1" "%~1_2" 0>nul 1>nul 2>nul
if not "%errorlevel%"=="0" exit/b %errorlevel%
copy /b "%~1"+"%~1_2" "%~1_3" 0>nul 1>nul 2>nul
if not "%errorlevel%"=="0" exit/b %errorlevel%
split -b %fileSize% "%~1_3" %tempFile%_ 0>nul 1>nul 2>nul
if not "%errorlevel%"=="0" exit/b %errorlevel%
exit/b 0

REM 判断结果是否为空文件 call:fileSizeTrue size file
REM   返回值：0 - 空, 1 - 非空
:fileSizeTrue
if not exist "%~2" exit/b 0
for %%a in ("%~2") do (
	if %%~za leq %~1 exit/b 0
)
exit/b 1

REM 删除临时文件 call:DeleteTempFile
:DeleteTempFile
for %%a in ("%yuanFile%_2","%yuanFile%_3","%tempFile%_aa" "%tempFile%_ab" "%tempFile%_ab.pcm" "%yuanFile%.pcm") do if exist "%%~a" del /f /q "%%~a"
exit/b 0

REM slk2pcm转换 call:slk2pcm inputFile outputFile
:slk2pcm
slk2pcm.exe "%~1" "%~2" -Fs_API 44100 0>nul 1>nul 2>nul
exit/b %errorlevel%

REM pcm2wav转换 call:pcm2wav 比特率 inputFile outputFile
:pcm2wav
if exist "%~3" del /f /q "%~3"
pcm2wav.exe -f s16le -ar %~1 -ac 1 -i "%~2" -ar 44100 -ac 2 -f %outputFormat% "%~3" 0>nul 1>nul 2>nul
exit/b %errorlevel%

REM 错误日志写入 错误类型 错误文件
:writeErrorLog
if not defined convertFailFileList exit/b

REM 写入错误文件头
if not exist "%convertFailFileList%" echo=#转换错误日志>"%convertFailFileList%"

REM 写入错误主题
echo=	"%~2"	%~1>>"%convertFailFileList%"
exit/b

:end