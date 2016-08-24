@echo off
setlocal ENABLEDELAYEDEXPANSION
cd /d "%~dp0"

REM 程序配置
:: 文件夹深度
set "dirLevel=50"
set "rootDir=encrypt"
set "encryptNum=0"
set "encryptNumTemp=0"
set "encryptDirNum=0"
set "encryptDirName="

REM 程序初始化
set "encryptString="
if not exist "%rootDir%" md "%rootDir%"

cd "%rootDir%"

for /l %%a in (1,1,10000) do (
	call:getEncryptNum
	if "!errorlevel!"=="1" (
		exit/b
	)
	call:getNumDirName !encryptDirNum!
)

goto end

:getEncryptNum
set getEncryptNumTest=Yes
for /f %%a in ('dir/ad/b') do (
	set getEncryptNumTest=
	set "encryptNumTemp=%%a"
	set /a encryptNum+=!encryptNumTemp:~0,1!
)
if defined getEncryptNumTest (
	explorer %cd%
	exit/b 1
)
set /a encryptDirNum=!encryptNum! %% %dirLevel%
exit/b

:getNumDirName
::call:getNumDirName num
set getNumDirNameNumTemp=0
for /f %%a in ('dir/ad/b') do (
	set /a getNumDirNameNumTemp+=1
	if "!getNumDirNameNumTemp!"=="%~1" (
		cd %%~a
		exit/b
	)
)
exit/b

:end

















