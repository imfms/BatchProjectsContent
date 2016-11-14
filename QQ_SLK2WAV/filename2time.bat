@echo off

if "%1"=="" (
	echo=#未指定目录
	pause
	exit/b 0
)

for /r "%~1\" %%a in (*) do if exist "%%~a" call:fileName2Time "%%~a"

echo=Over.
pause

::-------------------------------------子程序-------------------------------------::
goto end

REM 修改指定文件名为该文件的时间
REM call:fileName2Time File
:fileName2Time

call:getFileTime "%~1"

set fileTimeName=%fileTimeName%_%random%%random%

REM 获取文件扩展名
set fileExName=
for %%B in ("%~1") do set fileExName=%%~xB
if defined fileExName (
	set fileTimeName=%fileTimeName%%fileExName%
)

REM 执行文件名更改
echo=^| "%~1" -^> %fileTimeName%
ren "%~1" %fileTimeName%

exit/b 0


REM 获取文件时间
REM call:getFileTime File
:getFileTime
 
set fileTimeName=
for %%A in ("%~1") do (
	set "fileTimeName=%%~tA"
)
set fileTimeName=%fileTimeName: =%
set fileTimeName=%fileTimeName::=%
set fileTimeName=%fileTimeName:/=%
exit/b 0

:end