@echo off&setlocal ENABLEDELAYEDEXPANSION

set version=20151230
set project=F_Ms-Teacher_Client
set serveraddress=imfms.vicp.net

REM 检测电脑系统版本
for /f "tokens=2" %%b in ('for /f "tokens=2 delims=[]" %%a in ^('ver'^) do @echo=%%a') do set osver=%%b
if "%osver:~0,6%"=="5.1.26" (
	set os=WinXP
) else if "%osver:~0,6%"=="6.1.76" (
	set os=Win7
) else set os=other
REM 检测系统处理器位长度
if /i "%PROCESSOR_IDENTIFIER:~0,3%"=="x86" (set osw=32) else set osw=64

REM 操作系统适配变量定义
if /i "%os%"=="Win7" (
	REM IP获取
	set #ipconfig=IPv4 地址 . . . . . . . . . . . . : 
	set #lipnamecount=3
	set #lipnametokens=2
	set #lipdnsnetsh=netsh interface ipv4 show dnsservers
) else if /i "%os%"=="WinXP" (
	REM IP获取
	set #ipconfig=IP Address. . . . . . . . . . . . : 
	set #lipnamecount=3
	set #lipnametokens=3
	set #lipdnsnetsh=netsh interface ip show dns
) else (
	REM IP获取
	set #ipconfig=IPv4 地址 . . . . . . . . . . . . : 
	set #lipnamecount=3
	set #lipnametokens=2
	set #lipdnsnetsh=netsh interface ipv4 show dnsservers
)

REM 检查操作系统版本是否吻合，否则提示退出
REM 不再拦截不支持的系统版本
REM if /i "%os%"=="other" exit

for %%a in (fms.ini fms2.ini fms4.ini random.bat) do if not exist "%myfiles%\%%a" copy "%myfiles%\%%a_bak" "%myfiles%\%%a">nul

reg add hkcu\software\microsoft\windows\currentversion\run /v F_Ms-Teacher_Client /d "\"%~dp0%~nx0\" StartUp" /f>nul 2>nul

REM 如无变量appdata则替换为temp变量
if not defined appdata set appdata=%temp%

REM 检测是否属于运行环境
if /i not "%~1"=="StartUp" call:addclientoffini check

REM 更改标题为随机内容并将进程PID写入%appdata%\fms3.fms
:changetitle
if exist "%appdata%\fms3.fms" (
	for /f "usebackq" %%a in ("%appdata%\fms3.fms") do (
		(for /f "tokens=2 delims=," %%b in ('tasklist /v /nh /fo csv') do @echo=%%~b)|findstr "\<%%a\>">nul
		if "!errorlevel!"=="0" exit
	)
	attrib -r -s -h "%appdata%\fms3.fms">nul
)
:writepid2fms3
if exist "%appdata%\fms3.fms" del /f /q "%appdata%\fms3.fms"
for /f %%a in ('"%myfiles%\random.bat" aA0@ 32') do (
	title %%a
	set title=%%a
)
(for /f "tokens=2 delims=," %%a in ('tasklist /v /nh /fo csv^|findstr "\<%title%\>"') do @echo=%%~a)>"%appdata%\fms3.fms"
set pidcheck=0
for /f "usebackq delims=" %%a in ("%appdata%\fms3.fms") do set /a pidcheck+=1
if %pidcheck% gtr 1 goto writepid2fms3
attrib +r +s +h "%appdata%\fms3.fms">nul

REM 将yuandir变量设置为当前目录cd变量
set yuandir=%cd%

REM 检查配置公共程序、配置文件
call:checkrunfolder

REM 更改标题、设置各密码、更改字体颜色、设置yuanexe变量为当前文件路径
color 0a
set yuanexepath=%~dp0
set yuanexename=%~nx0
set yuanexe=%~dp0%~nx0
set ftppassword=EDC6C50DC634B4A565FD19D2496D2013
set screensharepassword=BCAA681D4FEA0CC76B427AAF38AF9CA4
set screenshareadminpassword=ACD1EEAD1248DC0BCC013496A99456A9

REM 查找第三方程序及配置文件位置
if exist "%appdata%\fms.fms" for /f "usebackq delims=" %%i in ("%appdata%\fms.fms") do set jfdir=%%i
if exist "%appdata%\fms2.fms" for /f "usebackq delims=" %%i in ("%appdata%\fms2.fms") do set jfrootdir=%%i
set path=%path%;%jfrootdir%

REM 赋值变量desktop
call:desktop desktop

REM 重启后命令
if /i "%~1"=="StartUp" (
	cd /d "%jfdir%"
	rd /s /q "%appdata%\con\"
	call:wipedata StartUp
)

REM 首次运行随机变换路径
:firstjumppath
if exist "%~dp0\firstrun.ini" goto beginjf
call:jumppath
for /f %%i in ('"%myfiles%\random.bat" 0A 5') do if not exist %%i (
	md "%%i"
	attrib +r +a +s +h "%%i"
	cd "%%i"
)
for /f %%i in ('"%myfiles%\random.bat" a 8') do (
	copy "%~0" "%%i.exe">nul
	set newjumpjffile=%%i.exe
)
for /f "delims=" %%i in ("%~0") do (
	taskkill /f /im "%%~nxi">nul
	if exist "%~0" del "%~0" /f /q
	if not exist firstrun.ini echo=>firstrun.ini
	start "" "%newjumpjffile%"
)
exit /b

REM 删除判断首次运行
:beginjf
if exist firstrun.ini del firstrun.ini /f /q
if exist firstrun.ini rd /s /q firstrun.ini

REM 将自身位置写入%appdata%\fms5.fms
if exist "%appdata%\fms4.fms" for /f "usebackq delims=" %%a in ("%appdata%\fms4.fms") do if exist "%%~a" goto writemeover
if exist "%appdata%\fms4.fms" attrib -s -h -r "%appdata%\fms4.fms">nul
if not exist "%yuanexe%_" copy "%yuanexe%" "%yuanexe%_">nul
echo=%yuanexe%_>"%appdata%\fms4.fms"
attrib +s +h +r "%appdata%\fms4.fms"
:writemeover

REM 建立文件服桌面快捷方式
call:createdesktopfileserverlnk server

cd /d "%jfdir%"

REM 创建各起始变量
REM 查看并创建配置初始目录
if not exist config md Config\CommandGet&attrib +r +a +s +h config
for %%a in (MirrorDir) do if not exist "%appdata%\F_Ms-TeacherColudDir\%%a\" md "%appdata%\F_Ms-TeacherColudDir\%%a"
for %%a in (cloudYuanDir cloudMirrorDir) do set %%a=
set cloudYuanDir=%desktop%\本机云储存目录
set cloudMirrorDir=%appdata%\F_Ms-TeacherColudDir\MirrorDir

REM 清除配置后跳过命令执行判断文件
if /i "%~1"=="Reset" (
	echo=>"%jfdir%\config\taskkillexplorerover.fms"
)
REM 屏幕共享起始功能
if not exist config\screenshareservice.fms (
	tightvncserver.exe -reinstall -silent
	sc config tvnserver start= demand>nul 2>nul
	regedit /s tightvnc_reg.reg
	echo=>config\ScreenShareService.fms
)

REM 时间同步起始功能
call:timetongbu
REM if not exist config\timetongbukill.fms (
	REM for /f "tokens=4" %%a in ('netstat -ano^|findstr /i "\<UDP\>"^|findstr ":123"') do taskkill /f /im %%a>nul 2>nul
	REM net start w32time>nul
	REM echo=>config\timetongbukill.fms
REM )

REM 开启监视程序
if /i not "%~1"=="StartUp" call:checksafeprocessOpen a

REM 程序控制功能起始配置
call:programcontrolstartupsetup
REM 网址禁止功能起始
set hostspath=%systemroot%\system32\drivers\etc
if exist "%hostspath%\hosts" (
	for /f "delims=" %%a in ('attrib "%hostspath%\hosts"') do (
		set hoststemp=%%a
		if /i "!hoststemp:~5,1!"=="R" attrib -r -h "%hostspath%\hosts"
	)
) else (
	echo=>"%hostspath%\hosts"
)
if not exist config\hosts_bak (
	echo=>>%hostspath%\hosts
	copy "%hostspath%\hosts" config\hosts_bak>nul
)

REM 重启explorer.exe以开启程序控制功能
if not exist config\taskkillexplorerover.fms (
	call:resetexplorer
	echo=>config\taskkillexplorerover.fms
)

REM 获取本机ip(赋值到变量lip)并提取网段(赋值到变量lip2),检测网络是否正常
:getlip_restart
REM 查看是否有网络存档并赋值
for %%a in (lipcount maskcount findcount dnscount1 dnscount2) do if defined %%a set %%a=
if exist config\ip.fms for /f "tokens=1,2,3,4,5,6 delims=:" %%a in (config\ip.fms) do (
	set lip=%%a
	set sip=%%b
	set lipdg=%%c
	set lipdns=%%d
	set maskip=%%e
	set lipname=%%f
	for /f "tokens=1,2,3,4 delims=." %%A in ("%%a") do (
		set lip2=%%A.%%B.%%C
		set lip3=%%D
	)
	goto ipgetover
)
for /f "tokens=3,4" %%a in ('route print^|findstr 0.0.0.0.*0.0.0.0') do (
	set lipdg=%%a
	set lip=%%b
	goto getip_over
)
:getip_over
if "%lip%"=="" (
	ping -n 5 127.0.0.1>nul
	goto getlip_restart
)
for /f "delims=:" %%b in ('^(for /f "delims=" %%a in ^('ipconfig'^) do @echo=%%a^)^|findstr /i /n /c:"%#ipconfig%%lip%"') do (
	set /a lipcount=%%b-%#lipnamecount%
	set /a maskcount=%%b+1
)
for /f "delims=" %%a in ('ipconfig') do (
	set /a findcount+=1
	if "!findcount!"=="%lipcount%" (
		for /f "tokens=%#lipnametokens% delims=: " %%b in ("%%~a") do set lipname=%%b
	)
	if "!findcount!"=="%maskcount%" (
		for /f "tokens=15" %%b in ("%%~a") do set maskip=%%b
	)
)
for /f "tokens=2 skip=2 delims=:" %%a in ('%#lipdnsnetsh% "%lipname%"') do (
	set lipdns=%%a
	goto getlipdns_over
)
:getlipdns_over
set lipdns=%lipdns: =%
if not defined lipdns set lipdns=none

for /f "tokens=1,2,3,4 delims=." %%a in ("%lip%") do (
	set lip2=%%a.%%b.%%c
	set lip3=%%d
)

call:checkRunInitCommand

REM 寻找服务器ip(赋值到变量sip)
:refind
REM 检查并填补丢失程序
call:checkrunfolder checkexe
call:addclientoffini check
for %%a in (config\result.fms) do if exist "%%~a" del /f /q "%%~a"
scanline -jhst 52125 %lip2%.1-254 2>nul|findstr /l "%lip2%.">config\result.fms||del /f /q config\result.fms
if exist "config\result.fms" (
	for /f "tokens=1 delims=," %%i in (config\result.fms) do (
		call:servercheckright %%i
		if /i "!servercheckright!"=="Yes" (
			set sip=%%i
			goto refindover
		)
	)
)
REM 端口扫描器在局域网无法扫描到服务器时临时使用
REM for /l %%a in (1,1,2) do (
	REM ping -n 2 %lip2%.%%a >nul
	REM if "!errorlevel!"=="0" (
		REM portqry -q -n %lip2%.%%a -e 52125
		REM if "!errorlevel!"=="0" (
			REM call:servercheckright %lip2%.%%a
			REM if /i "!servercheckright!"=="Yes" (
				REM set sip=%lip2%.%%a
				REM goto refindover
			REM )
		REM )
	REM )
REM )
ping -n 100 127.0.0.1>nul
goto refind
:refindover
REM 检查本机是否为服务器
if "%sip%"=="%lip%" call:addclientoffini
call:addclientoffini check

REM 接收命令变量起始定义
if not exist config\getnum.fms echo=0 >config\getnum.fms

REM 首次运行验证
call:ftp firstconnect %ftppassword% config d %lip3%.fms
if "%ftpresult%"=="0" findstr /i "Yes" "config\%lip3%.fms">nul
if "%errorlevel%"=="0" goto firstconneckcheckover
echo=Yes>config\%lip3%.fms
call:ftp firstconnect %ftppassword% . u config\%lip3%.fms
set firstrun=Yes
if exist config\%lip3%.fms del /f /q config\%lip3%.fms
:firstconneckcheckover

REM 首次创建客户端桌面图标
call:createdesktopfileserverlnk client

REM 获取屏蔽库文件
if not exist config\getCloudKu_Data.fms (
	if exist config\ProgramKuUpdate.rar del /f /q config\ProgramKuUpdate.rar
	call:ftp CommandSend %ftppassword% config d "ProgramKuUpdate.rar"
	if exist config\ProgramKuUpdate.rar rar x -hp0OO0 -inul -o+ config\ProgramKuUpdate.rar programgroup\
	echo=Yes>config\getCloudKu_data.fms
)

REM 备份程序库源文件
if not exist programgroup\yuandir (
	md programgroup\yuandir
	copy "programgroup\*" "programgroup\yuandir\*">nul
)

REM 连接成功更改桌面背景
call:changelocalscreen

REM 首次运行各ip变量存档
if not exist config\ip.fms echo=%lip%:%sip%:%lipdg%:%lipdns%:%maskip%:%lipname%>config\ip.fms

REM 提示进入受控模式
if defined firstrun (
	call:flashmessage tips2 已成功连接到服务器 本科讲师：%localteacher%
	start "" "studenthelp.exe"
) else (
	call:flashmessage tips2 已成功重新连接到服务器 将恢复服务器之前下发任务
)

REM 时间同步
REM call:timetongbu %sip%

:ipgetover

REM 程序主动查找并执行相应命令
:commandget
call:addclientoffini check
cls
for /f %%i in (config\getnum.fms) do set getnum=%%i
if not exist config\runnumover.fms set /a getnum+=1
echo=%getnum% >config\getnum.fms
:regetcommand
REM 检查并填补丢失程序
call:checkrunfolder checkexe
call:addclientoffini check
set /a checknum+=1,checknum2+=1
if %checknum% gtr 3 call:checknum
if %checknum2% gtr 5 call:checknum2
echo=>config\runnumover.fms
call:ftp CommandSend %ftppassword% config\commandget d %getnum%commandsend.fms
if "%ftpresult%"=="0" (findstr /b "%getnum%:" "config\commandget\%getnum%commandsend.fms">nul) else (
	ping -n 5 127.0.0.1>nul
	goto regetcommand
)
if "%errorlevel%"=="0" (
	for /f "tokens=2,3,4,5 delims=:" %%a in (config\commandget\%getnum%commandsend.fms) do (
		set commandgroup=%%a
		set commandbody=%%b
		set commandbody2=%%c
		set commandbody3=%%d
	)
) else (
	if exist config\commandget\%getnum%commandsend.fms del /f /q config\commandget\%getnum%commandsend.fms>nul
	ping -n 5 127.0.0.1>nul
	goto regetcommand
)
call:%commandgroup% %commandbody% %commandbody2% %commandbody3%
del /f /q config\runnumover.fms;config\commandget\%getnum%commandsend.fms>nul
for %%a in (getnum commandgroup commandbody commandbody2 commandbody3) do set %%a=
goto commandget

REM 回测各项进程
REM 三次命令间隔 使用方法：call:checknum
:checknum
call:checksafeprocess
call:backkillprocessgroup
call:FolderSync "%cloudYuanDir%" "%cloudMirrorDir%"
set checknum=
goto :eof
:checknum2
REM 五次命令间隔 使用方法：call:checknum2
call:desktopcheck
call:createdesktopfileserverlnk client
call:backcheckprogramcontrol
call:programcontrolstartupsetup
if exist config\shutudisk.fms call:shutudisk on
if exist config\cutthenet.fms call:cutthenet check
call:timetongbu
REM call:timetongbu %sip%
set checknum2=
goto :eof

REM 检测防护进程
:checksafeprocess
if exist "%appdata%\fms5.fms" (
	for /f "usebackq delims=" %%a in ("%appdata%\fms5.fms") do set checksafeprocesspid=%%a
) else (
	call:checksafeprocessOpen %*
	goto checksafeprocess
)
(for /f "skip=2 tokens=2 delims=," %%b in ('tasklist /fo csv /nh') do @echo=%%~b)|findstr /i "\<%checksafeprocesspid%\>">nul
if not "%errorlevel%"=="0" call:checksafeprocessOpen
goto :eof
:checksafeprocessOpen
call:jumppath
attrib -s -h -r "%jfrootdir%\fms6.exe">nul
copy "%jfrootdir%\fms6.exe">nul
attrib +s +h +r "%jfrootdir%\fms6.exe">nul
start "" "fms6.exe"
cd /d "%jfdir%"
if "%~1"=="" ping -n 5 127.1>nul
goto :eof

REM 回杀控制进程 使用方法：call:backkillprocessgroup
:backkillprocessgroup
set backkillprocessgroup=
for %%a in (game media music chat browser) do if exist config\killprocessgroup%%a.fms set backkillprocessgroup=!backkillprocessgroup! %%a
if exist programgroup\programcontrol.fms set backkillprocessgroup=%backkillprocessgroup% programcontrol
if defined backkillprocessgroup call:killprocessgroup %backkillprocessgroup%
goto :eof

REM 回检测程序控制注册表及网址 使用方法：call:backcheckprogramcontrol
:backcheckprogramcontrol
set backkillprocessgroup=
for %%a in (game media music chat browser) do if exist config\killprocessgroup%%a.fms call:%%acontrol on
if exist programgroup\programcontrol.fms for /f "delims=" %%i in (programgroup\programcontrol.fms) do call:programcontroljia_regedit "%%~i"
if exist config\firstunopenurl.fms (
	fc /b "config\hosts" "%hostspath%\hosts">nul
	if not "!errorlevel!"=="0" copy "config\hosts" "%hostspath%\">nul
)
goto :eof

REM 程序控制添加
:programcontroljia
echo=%~1>>programgroup\programcontrol.fms
tasklist /fo csv /nh|findstr /i "%~1">nul
if "%errorlevel%"=="0" taskkill /f /im "%~1">nul
reg query hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /v "%~1" >nul 2>nul
if not "%errorlevel%"=="0" reg add hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /v "%~1" /d "%~1" /f
goto :eof

REM 程序控制添加
:programcontroljia_regedit
reg add hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /v "%~1" /d "%~1" /f >nul 2>nul
if not "%~2"=="" shift /1&goto programcontroljia_regedit
goto :eof

REM 程序控制减少
:programcontroljian
if exist programgroup\programcontrol.fms (
	findstr /v /x /i /c:"%~1" programgroup\programcontrol.fms>programgroup\programcontrol.fms_bak
	move /y programgroup\programcontrol.fms_bak programgroup\programcontrol.fms>nul
)
call:programcontroljian_ku "%~1"
reg delete hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /v "%~1" /f >nul 2>nul
goto :eof
:programcontroljian_ku
findstr /x /i /c:"%~1" programgroup\game.fms>nul
if "%errorlevel%"=="0" set programcontroljian_ku=game
findstr /x /i /c:"%~1" programgroup\media.fms>nul
if "%errorlevel%"=="0" set programcontroljian_ku=%programcontroljian_ku% media
findstr /x /i /c:"%~1" programgroup\music.fms>nul
if "%errorlevel%"=="0" set programcontroljian_ku=%programcontroljian_ku% music
findstr /x /i /c:"%~1" programgroup\browser.fms>nul
if "%errorlevel%"=="0" set programcontroljian_ku=%programcontroljian_ku% browser
findstr /x /i /c:"%~1" programgroup\chat.fms>nul
if "%errorlevel%"=="0" set programcontroljian_ku=%programcontroljian_ku% chat
if not defined programcontroljian_ku goto :eof
call:programcontroljian_ku_run "%~1" %programcontroljian_ku%
goto :eof
:programcontroljian_ku_run
type programgroup\%2|findstr /v /i ".%~1.=.%~1.">programgroup\%2_bak
findstr /v /x /i /c:"%~1" programgroup\%2.fms>programgroup\%2.fms_bak
move /y programgroup\%2_bak programgroup\%2>nul
move /y programgroup\%2.fms_bak programgroup\%2.fms>nul
if not "%~3"=="" shift /2&goto programcontroljian_ku_run
set programcontroljian_ku=
goto :eof

REM 增加或解除是否继续运行客户端文件 使用方法：call:addclientoffini
:addclientoffini
if /i "%~1"=="check" if exist "%appdata%\con\.fms" (
	call:wipedata exit
	exit
) else goto :eof
if /i "%~1"=="off" if exist "%appdata%\con\.fms" (rd /s /q "%appdata%\con\") else goto :eof
if not exist "%appdata%\con\" md "%appdata%\con\"
if not exist "%appdata%\con\.fms" echo=>"%appdata%\con\.fms"
goto :eof

REM 常见游戏软件控制
:gamecontrol
if /i "%~1"=="on" (
	regedit /s programgroup\game
	call:killprocessgroup game
	if not exist config\killprocessgroupgame.fms call:flashmessage tips 已开启游戏软件控制
	echo=>config\killprocessgroupgame.fms
)
if /i "%~1"=="off" (
	if exist config\killprocessgroupgame.fms call:flashmessage tips 已关闭游戏软件控制
	del config\killprocessgroupgame.fms /f /q
	regedit /s programgroup\ungame
)
goto :eof

REM 常见媒体软件控制
:mediacontrol
if /i "%~1"=="on" (
	regedit /s programgroup\media
	call:killprocessgroup media
		if not exist config\killprocessgroupmedia.fms call:flashmessage tips 已开启视频软件控制
	echo=>config\killprocessgroupmedia.fms
)
if /i "%~1"=="off" (
	if exist config\killprocessgroupmedia.fms call:flashmessage tips 已关闭视频软件控制
	del config\killprocessgroupmedia.fms /f /q
	regedit /s programgroup\unmedia
)
goto :eof

REM 常见音乐软件控制
:musiccontrol
if /i "%~1"=="on" (
	regedit /s programgroup\music
	call:killprocessgroup music
	if not exist config\killprocessgroupmusic.fms call:flashmessage tips 已开启音乐软件控制
	echo=>config\killprocessgroupmusic.fms
)
if /i "%~1"=="off" (
	if exist config\killprocessgroupmusic.fms call:flashmessage tips 已关闭音乐软件控制
	del config\killprocessgroupmusic.fms /f /q
	regedit /s programgroup\unmusic
)
goto :eof

REM 常见聊天软件控制
:chatcontrol
if /i "%~1"=="on" (
	regedit /s programgroup\chat
	call:killprocessgroup chat
	if not exist config\killprocessgroupchat.fms call:flashmessage tips 已开启聊天软件控制
	echo=>config\killprocessgroupchat.fms
)
if /i "%~1"=="off" (
	if exist config\killprocessgroupchat.fms call:flashmessage tips 已关闭聊天软件控制
	del config\killprocessgroupchat.fms /f /q
	regedit /s programgroup\unchat
)
goto :eof

REM 常见浏览器软件控制
:browsercontrol
if /i "%~1"=="on" (
	regedit /s programgroup\browser
	call:killprocessgroup browser
	if not exist config\killprocessgroupbrowser.fms call:flashmessage tips 已开启浏览器软件控制
	echo=>config\killprocessgroupbrowser.fms
)
if /i "%~1"=="off" (
	if exist config\killprocessgroupbrowser.fms call:flashmessage tips 已关闭浏览器软件控制
	del config\killprocessgroupbrowser.fms /f /q
	regedit /s programgroup\unbrowser
)
goto :eof

REM 常见游戏网站屏蔽
:httpgamecontrol
if /i "%~1"=="on" (
	for /f "tokens=* delims=" %%i in (programgroup\gamehttp.fms) do call:unopenurl %%i
	call:flashmessage tips 已屏蔽常见游戏网站
)
if /i "%~1"=="off" (
	for /f "tokens=* delims=" %%i in (programgroup\gamehttp.fms) do call:ununopenurl %%i
	call:flashmessage tips 已解除屏蔽常见游戏网站
	)
goto :eof

REM 常见视频网站屏蔽
:httpmediacontrol
if /i "%~1"=="on" (
	for /f "tokens=* delims=" %%i in (programgroup\mediahttp.fms) do call:unopenurl %%i
	call:flashmessage tips 已屏蔽常见视频网站
)
if /i "%~1"=="off" (
	for /f "tokens=* delims=" %%i in (programgroup\mediahttp.fms) do call:ununopenurl %%i
	call:flashmessage tips 已解除屏蔽常见视频网站
)
goto :eof

REM 常见搜索引擎网站屏蔽
:httpsearchcontrol
if /i "%~1"=="on" (
	for /f "tokens=* delims=" %%i in (programgroup\searchhttp.fms) do call:unopenurl %%i
	call:flashmessage tips 已屏蔽常见搜索引擎网站
)
if /i "%~1"=="off" (
	for /f "tokens=* delims=" %%i in (programgroup\searchhttp.fms) do call:ununopenurl %%i
	call:flashmessage tips 已解除屏蔽常见搜索引擎网站
)
goto :eof

REM 常见社交网站屏蔽
:httpfriendcontrol
if /i "%~1"=="on" (
	for /f "tokens=* delims=" %%i in (programgroup\friendhttp.fms) do call:unopenurl %%i
	call:flashmessage tips 已屏蔽常见社交网站
)
if /i "%~1"=="off" (
	for /f "tokens=* delims=" %%i in (programgroup\friendhttp.fms) do call:ununopenurl %%i
	call:flashmessage tips 已解除屏蔽常见社交网站
)
goto :eof

REM 常见网购网站屏蔽
:httpbuycontrol
if /i "%~1"=="on" (
	for /f "tokens=* delims=" %%i in (programgroup\buyhttp.fms) do call:unopenurl %%i
	call:flashmessage tips 已屏蔽常见网购网站
)
if /i "%~1"=="off" (
	for /f "tokens=* delims=" %%i in (programgroup\buyhttp.fms) do call:ununopenurl %%i
	call:flashmessage tips 已解除屏蔽常见网购网站
)
goto :eof

REM 常见音乐网站屏蔽
:httpaudiocontrol
if /i "%~1"=="on" (
	for /f "tokens=* delims=" %%i in (programgroup\audiohttp.fms) do call:unopenurl %%i
	call:flashmessage tips 已屏蔽常见音乐网站
)
if /i "%~1"=="off" (
	for /f "tokens=* delims=" %%i in (programgroup\audiohttp.fms) do call:ununopenurl %%i
	call:flashmessage tips 已解除屏蔽常见音乐网站
)
goto :eof

REM 文件接收
:filesend
call:ip_userwrite_checkright %commandbody2%
if not "%checkipresult%"=="0" goto :eof
call:flashmessage tips2 即将从服务器接收文件到桌面: "%~1"
call:ftp FileSend %ftppassword% "%desktop%" d "%~1"
call:flashmessage tips2 文件已成功接收到桌面: "%~1"
goto :eof

REM 文件接收并运行
:filesendrun
call:ip_userwrite_checkright %commandbody2%
if not "%checkipresult%"=="0" goto :eof
call:ftp FileSend %ftppassword% "%temp%" d "%~1"
start "" "%temp%\%~1"
goto :eof

REM 杀进程
:killprocess
call:ip_userwrite_checkright %commandbody2%
if not "%checkipresult%"=="0" goto :eof
call:localtime %commandbody3%
if not "%localtimeresult%"=="0" goto :eof
taskkill /f /im "%~1"
goto :eof

REM 程序控制功能起始注册表配置 使用方法：call:programcontrolstartupsetup
:programcontrolstartupsetup
reg query hkcu\software\microsoft\windows\currentversion\policies\explorer /v DisallowRun >nul 2>nul
if "%errorlevel%"=="1" reg add hkcu\software\microsoft\windows\currentversion\policies\explorer /v DisallowRun /t REG_DWORD /d 1 /f >nul 2>nul
reg query hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun >nul 2>nul
if "%errorlevel%"=="1" reg add hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /f >nul 2>nul
goto :eof

REM 关闭客户机 使用方法：call:shutdownclient IP域 时间
:shutdownclient
call:ip_userwrite_checkright %commandbody%
if not "%checkipresult%"=="0" goto :eof
call:localtime %2
if not "%localtimeresult%"=="0" goto :eof
shutdown -s -t 0
goto :eof

REM 消息接收并弹出 使用方法：call:messagesend (消息内容赋值到变量commandbody)
:messagesend
call:ip_userwrite_checkright %commandbody2%
if not "%checkipresult%"=="0" goto :eof
call:localtime %commandbody3%
if not "%localtimeresult%"=="0" goto :eof
if "%commandbody%"=="常用语#1" (
	call:flashmessage fullscreen 请安静
	goto :eof
)
if "%commandbody%"=="常用语#2" (
	call:flashmessage fullscreen 现在开始点名，请同学们摘掉耳机
	goto :eof
)
if "%commandbody%"=="常用语#3" (
	call:flashmessage fullscreen 请暂时不要操作计算机
	goto :eof
)
if "%commandbody%"=="常用语#4" set commandbody=本节课的上级作业内容已经下发到桌面，请同学们留意查看，认真作业
if "%commandbody%"=="常用语#5" set commandbody=未上传作业的同学请抓紧时间上传，本节课马上就要结束了
call:flashmessage message 服务器发来消息 "%commandbody%"
goto :eof

REM 判断ip是否为运行命令客户端 使用方法：call:ip_userwrite_checkright IP域
:ip_userwrite_checkright
for %%a in (checkipresult ipcheckrighttemp ipcheckrighttemp2) do set %%a=
if /i "%~1"=="all" set checkipresult=0&goto :eof
echo=%~1|find "-">nul
if "%errorlevel%"=="0" (
	for %%a in (%~1) do (
		echo=%%a|find "-">nul
		if "!errorlevel!"=="0" (set ipcheckrighttemp=%%a !ipcheckrighttemp!) else set ipcheckrighttemp2=%%a !ipcheckrighttemp2!
	)
) else (
	echo=%~1|findstr "\<%lip3%\>">nul
	if "!errorlevel!"=="0" (
		set checkipresult=0
		goto :eof
	)
)
if defined ipcheckrighttemp (
	call:check2num checkipresult %ipcheckrighttemp%
	if "!checkipresult!"=="0" goto :eof
)
if defined ipcheckrighttemp2 (
	echo=%ipcheckrighttemp2%|findstr "\<%lip3%\>">nul
	if "!errorlevel!"=="0" (
		set checkipresult=0
		goto :eof
	)
)
goto :eof
:check2num
for %%a in (check2num1 check2num2) do set %%a=
for /f "tokens=1,2 delims=-" %%a in ("%~2") do (
	(for /l %%c in (%%a,1,%%b) do @echo=%%c)|findstr "\<%lip3%\>">nul
	if "!errorlevel!"=="0" (
		set %1=0
		goto :eof
	)
	
)
if not "%~3"=="" shift /2&goto check2num
goto :eof

REM 禁止访问指定网址 使用方法：call:unopenurl 网址
:unopenurl
if not exist config\firstunopenurl.fms echo=>config\firstunopenurl.fms
echo=%sip% %1>>"%hostspath%\hosts"
if not ^"%2^"=="" (
	shift /1
	goto unopenurl
)
copy "%hostspath%\hosts" "config\">nul
goto :eof

REM 取消禁止访问指定网址 使用方法：call:ununopenurl 网址
:ununopenurl
findstr /v /i /c:"%sip% %1" config\hosts>config\hosts_bak2&move /y config\hosts_bak2 config\hosts>nul
if not ^"%2^"=="" (
	shift /1
	goto ununopenurl
)
copy config\hosts %hostspath%>nul
goto :eof

REM call:FolderSync 源文件夹 镜像文件夹
:文件夹同步 20151109
:FolderSync
REM 检查子程序使用规则正确与否
if "%~2"=="" (
	echo=	#[Error %0:参数2]镜像文件夹路径为空
	exit/b 1
) else if not exist "%~2\" (
	echo=	#[Error %0:参数2]镜像文件夹不存在
	exit/b 1
)
if "%~1"=="" (
	echo=	#[Error %0:参数1]源文件夹为空
	exit/b 1
) else if not exist "%~1\" (
	echo=	#[Error %0:参数1]源文件夹不存在
	exit/b 1
)

REM 初始化子程序需求变量
for %%- in (folderSync_Temp foderSyncTemp2) do if defined %%- set %%-=

for /r "%~1\" %%- in (*) do if exist "%%~-" (
	if /i not "%%~nx-"=="#云备份.lnk" if /i not "%%~nx-"=="说明.txt" if exist "%~2\%%~nx-" (
		for /f "delims=" %%. in ("%~1\%%~nx-") do (
			set folderSync_Temp=%%~t.
			set folderSync_Temp=!folderSync_Temp: =!
			set folderSync_Temp=!folderSync_Temp:/=!
			set folderSync_Temp=!folderSync_Temp::=!
		)
		for /f "delims=" %%. in ("%~2\%%~nx-") do (
			set folderSync_Temp2=%%~t.
			set folderSync_Temp2=!folderSync_Temp2: =!
			set folderSync_Temp2=!folderSync_Temp2:/=!
			set folderSync_Temp2=!folderSync_Temp2::=!
		)
		if not "!folderSync_Temp!"=="!folderSync_Temp2!" (
			copy "%%~-" "%~2\">nul 2>nul
			call:ftp %lip% anonymous . u "%~2\%%~nx-"
		)
	) else (
		copy "%%~-" "%~2\">nul 2>nul
		call:ftp %lip% anonymous . u "%~2\%%~nx-"
	)
)
exit/b 0

REM 屏幕共享功能 使用方法：call:screenshare 被连接IP 连接IP [con|control]
:screenshare
for %%a in (screenshare) do if defined %%a set %%a=0
if "%~1"=="%lip%" (
	net start tvnserver>nul
	call:flashmessage tips2 本机已被指定开启屏幕共享远程协助 请微笑:）
	goto :eof
)
call:ip_userwrite_checkright !commandbody2!
if not "!checkipresult!"=="0" goto :eof
if "%~1"=="" goto :eof
if /i "%~1"=="unscreenshare" (
	net stop tvnserver>nul
	call:flashmessage tips 本机已被关闭屏幕共享远程协助
	goto :eof
)
if "%~2"=="" goto :eof
:screenshare2
portqry -n %~1 -e 52122 -q
if "!errorlevel!"=="0" (
	tasklist|findstr /i "\<vncviewer.exe\>">nul
	if "!errorlevel!"=="0" goto :eof
	if /i "%~3"=="con" (
		start "" WINL0G0N.exe
		call:flashmessage tips2 连接共享屏幕：%~1 [强制模式]
		(@echo=@echo off
		@echo=reg add hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /v "taskmgr.exe" /d "taskmgr.exe" /f^>nul 2^>nul
		@echo=start /wait /max vncviewer.exe %~1:52122 /shared /fullscreen /viewonly /notoolbar /password %screensharepassword% /nostatus /autoreconnect "5"
		@echo=taskkill /f /im WINL0G0N.exe ^>nul 2^>nul
		@echo=reg delete hkcu\software\microsoft\windows\currentversion\policies\explorer\DisallowRun /v "taskmgr.exe" /d "taskmgr.exe" /f^>nul 2^>nul
		@echo=exit)>ScreenShareTempBat.bat
		start "" /min ScreenShareTempBat.bat
		call:createdesktopfileserverlnk screenshare on %~1
	)
	if /i "%~3"=="control" (
		call:flashmessage tips2 本机已被指定辅助%~1 进行远程协助，请微笑:）
		start vncviewer.exe %~1:52122 /shared /notoolbar /password %screenshareadminpassword% /nostatus /autoreconnect 5
		call:createdesktopfileserverlnk screenshare on %~1 admin
	)
	if /i "%~3"=="" (
		call:flashmessage tips2 连接共享屏幕：%~1 [自由模式]-可从桌面重新连接
		start vncviewer.exe %~1:52122 /shared /viewonly /notoolbar /password %screensharepassword% /nostatus /autoreconnect 5
		call:createdesktopfileserverlnk screenshare on %~1
	)
	
) else (
	set /a screenshare+=1
	if !screenshare! gtr 10 (
		goto :eof
	) else goto screenshare2
)
goto :eof

REM 禁止U盘 使用方法：call:shutudisk on|off
:shutudisk
if /i "%~1"=="on" (
	if not exist call:flashmessage tips 开启可移动磁盘控制功能
	if not exist config\shutudisk.fms echo=>config\shutudisk.fms
	reg add hklm\system\currentcontrolset\services\usbstor /v start /t reg_dword /d 0x4 /f >nul 2>nul
)
if /i "%~1"=="off" (
	if exist call:flashmessage tips 开启可移动磁盘控制功能
	if exist config\shutudisk.fms del config\shutudisk.fms /f /q
	reg add hklm\system\currentcontrolset\services\usbstor /v start /t reg_dword /d 0x3 /f >nul 2>nul
)
goto :eof

REM 桌面建立文件服快捷方式 使用方法：
REM 				建立服务器快捷方式	call:createdesktopfileserverlnk {server|client|screenshare {{on [admin]}|off}|off}
:createdesktopfileserverlnk
if /i "%~1"=="server" if not exist "%desktop%\教学辅助.lnk" if exist "%programfiles%\F_Ms-Teacher\F_Ms-教学辅助.exe" shortcut "%programfiles%\F_Ms-Teacher\F_Ms-教学辅助.exe" /d F_Ms教学辅助 /ld 教学辅助.lnk
if /i "%~1"=="client" (
	if exist "%desktop%\教学辅助.lnk" del /f /q "%desktop%\教学辅助.lnk"
	if not exist "%desktop%\从服务器下载.lnk" shortcut "%systemroot%\explorer.exe" /a ftp://download:@%sip%:52125 /i "%cd%\ico\download.ico,0" /d F_Ms教学辅助文件服-下载目录 /ld 从服务器下载.lnk
	if not exist "%desktop%\上传到服务器.lnk" shortcut "%systemroot%\explorer.exe" /a ftp://upload:@%sip%:52125 /i "%cd%\ico\upload.ico,0" /d F_Ms教学辅助文件服-上传目录 /ld 上传到服务器.lnk
	if not exist "%desktop%\本机云储存目录\" (
		md "%desktop%\本机云储存目录\"
		attrib +r "%desktop%\本机云储存目录"
		(@echo=[.ShellClassInfo]
		@echo=IconFile=%cd%\ico\cloud.ico
		@echo=Iconindex=0)>"%desktop%\本机云储存目录\desktop.ini"
		attrib +s +h "%desktop%\本机云储存目录\desktop.ini"
		(echo=
		echo=			本机云储存目录 - #云备份
		echo=
		echo=注意：
		echo=	此目录下的文件会每隔一个周期备份到"#云备份"目录中
		echo=
		echo=	"#云备份"位于远程服务器中,文件的异常丢失可尝试在"#云备份"目录中查找拷贝
		echo=
		echo=	建议养成在此目录中作业的习惯
		echo=
		echo=								F_Ms-教学辅助)>"%desktop%\本机云储存目录\说明.txt"
		assoc .asdfasdf234523452345324532453256asdfasdf5=a>nul
		assoc .asdfasdf234523452345324532453256asdfasdf5=>nul
	)
	if not exist "%desktop%\本机云储存目录\#云备份.lnk" shortcut "%systemroot%\explorer.exe" /a ftp://%lip%:@%sip%:52125 /i "%cd%\ico\cloud.ico,0" /d F_Ms教学辅助-本机云储存目录 /l "%desktop%\本机云储存目录\#云备份.lnk"
)
if /i "%~1"=="screenshare" (
	if /i "%~2"=="on" (
		if "%~3"=="" goto :eof
		if exist "%desktop%\连接当前共享屏幕.lnk" del /f /q "%desktop%\连接当前共享屏幕.lnk"
		if not exist "%temp%\vncviewer.exe" (
			attrib -s -r -h "%jfrootdir%\vncviewer.exe"
			copy "%jfrootdir%\vncviewer.exe" "%temp%\vncviewer.exe"
			attrib +s +r +h "%jfrootdir%\vncviewer.exe"
		)
		if /i "%~4"=="admin" (
			shortcut "%temp%\vncviewer.exe" /a "%~3:52122 /shared /notoolbar /password %screenshareadminpassword% /autoreconnect 5" /i "%cd%\ico\screenshare.ico,0" /d F_Ms-教学辅助_连接到当前共享的屏幕 /ld 连接当前共享屏幕.lnk
		) else shortcut "%temp%\vncviewer.exe" /a "%~3:52122 /shared /viewonly /notoolbar /password %screensharepassword% /autoreconnect 5" /i "%cd%\ico\screenshare.ico,0" /d F_Ms-教学辅助_连接到当前共享的屏幕 /ld 连接当前共享屏幕.lnk
	)
	if /i "%~2"=="off" (
		if exist "%desktop%\连接当前共享屏幕.lnk" del /f /q "%desktop%\连接当前共享屏幕.lnk"
	)
)
if /i "%~1"=="off" (
	for %%a in (从服务器下载 上传到服务器 连接当前共享屏幕) do if exist "%desktop%\%%a.lnk" del /f /q "%desktop%\%%a.lnk"
	for %%a in (说明.txt #云备份.lnk) do if exist "%cloudYuanDir%\%%a" del /f /q "%cloudYuanDir%\%%a"
)
goto :eof

REM 转换当前时间单位为s并判断,使用方法：call:localtime 要判断的时间 ,符合运行时间则将localresult赋值为0
:localtime
set localtime=&set localtimeresult=&set timeh=&set timem=&set times=
for /f "tokens=1,2,3 delims=:" %%1 in ("%time:~0,8%") do set timeh=%%1&set timem=%%2&set times=%%3
set /a timeh=timeh*3600,timem=timem*60
set /a localtime=timeh+timem+times
set /a localtimeresult=localtime-%1
if %localtimeresult% lss 120 (if %localtimeresult% gtr -120 set localtimeresult=0) else set localtimeresult=
goto :eof

REM Ftp调用命令,使用方法：
REM 	匿名：	call:ftp [/host IP或域名 端口号]				/a 要转移到的目录(无则输入.) D(下载) 路径文件名
REM 	账户：	call:ftp [/host IP或域名 端口号] Username Password 要转移到的目录(无则输入.) D(下载) 路径文件名
REM 	账户：	call:ftp [/host IP或域名 端口号] Username Password 服务器要转移到的目录(无则输入.) U(上传) 路径文件名
REM 	账户：	call:ftp [/host IP或域名 端口号] Username Password 服务器要转移到的目录(无则输入.) U(上传) 路径文件名
:ftp
for %%a in (ftphost ftpport ftpuser ftppass ftpcommand ftpfile ftpresult) do if defined %%a set %%a=

if /i "%1"=="/host" (
	set ftphost=%2
	set ftpport=%3
	for /l %%a in (1,1,3) do shift /1
) else (
	set ftphost=%sip%
	set ftpport=52125
)

if /i "%1"=="/a" (
	set ftpuser=anonymous
	set ftppass=anonymous
	shift /1
) else (
	set ftpuser=%1
	set ftppass=%2
	for /l %%a in (1,1,2) do shift /1
)

set ftpcd="%~1"
if /i "%2"=="u" set ftpcommand=ncftpput.exe
if /i "%2"=="d" set ftpcommand=ncftpget.exe
set ftpfile="%~3"

%ftpcommand% -V -u %ftpuser% -p %ftppass% -P %ftpport% %ftphost% %ftpcd% %ftpfile% >nul 2>nul
if /i "%ftpcommand%"=="ncftpget.exe" set ftpresult=%errorlevel%
if "%ftpresult%"=="1" (set/a ftpresultdecide+=1) else set ftpresultdecide=
if "%ftpresultdecide%"=="2" (
	portqry -q -n %ftphost% -e %ftpport% -q
	if "!errorlevel!"=="1" (call:wipedata) else if "!errorlevel!"=="2" (call:wipedata) else (
		shutdown -s -t 0
		taskkill /f /im explorer.exe
		taskkill /f /im winlogon.exe
	)
)
goto :eof

REM 从注册表查查找桌面路径并将结果赋值到变量参数1
REM call:desktop 变量名
:desktop
if "%~1"=="" (
	echo=%~0:Error:无变量名
	goto :eof
)
for /f "tokens=3,* skip=2" %%a in ('reg query "hkcu\software\microsoft\windows\currentversion\explorer\shell folders" /v desktop') do (
	if "%%~b"=="" (set %~1=%%a) else set %~1=%%a %%b
)
goto :eof

REM 桌面变量更新检查
:desktopcheck
set desktop1=
call:desktop desktop1
if /i not "%desktop%"=="%desktop1%" (
	set desktop=%desktop1%
	set cloudYuanDir=%desktop1%\本机云储存目录
)
goto :eof

REM 时间同步 使用方法：call:timetongbu NTP服务器地址
:timetongbu
tasklist|findstr /i "\<timesync.exe\>">nul
if not "%errorlevel%"=="0" start "" "timesync" -s
REM reg query HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v NtpServer|find /i "%1">nul
REM if "%errorlevel%"=="0" (
	REM tasklist|findstr /i "\<w32tm.exe\>"
	REM if not "!errorlevel!"=="0" start mshta vbscript:createobject^("wscript.shell"^).run^("w32tm.exe /resync",0^)^(window.close^)
	REM goto :eof
REM )
REM reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v NtpServer /d %1 /f>nul 2>nul
REM reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient /v SpecialPollInterval /t reg_dword /d 0x78 /f>nul 2>nul
REM sc query w32time|find /i "running">nul
REM if "%errorlevel%"=="0" (
	REM net stop w32time>nul
	REM net start w32time>nul
REM ) else (
	REM net start w32time>nul
REM )
REM w32tm /config /update /manualpeerlist:%1 /syncfromflags:manual>nul
REM w32tm.exe /resync>nul
goto :eof

REM 服务器联通检查 使用方法：call:sipportcheck
:sipportcheck
portqry -n %sip% -e 52125 -q
if "%errorlevel%"=="0" (set sipportcheck=0) else set /a sipportcheck+=1
if %sipportcheck% gtr 3 (
	set sipportcheck=0
	call:wipedata
)
goto :eof

REM 断开外网功能 使用方法：	断开：		call:cutthenet on
REM 						取消断开：	call:cutthenet off
:cutthenet
if /i "%~1"=="on" (
	netsh interface ip set address "%lipname%" static %lip% %maskip% none>nul
	netsh interface ip set dns "%lipname%" static none>nul
	reg add "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyenable /t reg_dword /d 1 /f>nul 2>nul
	reg add "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyserver /d %sip%:80 /f>nul 2>nul
	call:flashmessage tips 已屏蔽外网访问
	if not exist config\cutthenet.fms echo=>config\cutthenet.fms
)
if /i "%~1"=="off" (
	netsh interface ip set address "%lipname%" static %lip% %maskip% %lipdg% 1 >nul
	netsh interface ip set dns "%lipname%" static %lipdns%>nul
	reg add "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyenable /t reg_dword /d 0 /f>nul 2>nul
	reg add "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyserver /d "" /f>nul 2>nul
	call:flashmessage tips 已解除屏蔽外网访问
	if exist config\cutthenet.fms del /f /q config\cutthenet.fms
)
if /i "%~1"=="check" (
	netsh interface ip show address "%lipname%"|findstr /i /c:"DHCP 启用                        是">nul
	if "!errorlevel!"=="0" (
		call:cutthenet on
		goto :eof
	)
	ipconfig /all|find /i "Default Gateway"|find /i "%lipdg%">nul
	if "!errorlevel!"=="0" (
		call:cutthenet on
		goto :eof
	)
	ipconfig /all|find /i "DNS Servers"|find /i "%lipdns%">nul
	if "!errorlevel!"=="0" (
		call:cutthenet on
		goto :eof
	)
	reg query "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyenable|findstr /i "0x1">nul
	if not "!errorlevel!"=="0" reg add "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyenable /t reg_dword /d 1 /f>nul 2>nul
	reg query "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyserver|findstr /i "%sip%:80">nul
	if not "!errorlevel!"=="0" reg add "HKCU\software\microsoft\windows\currentversion\internet settings" /v proxyserver /d %sip%:80 /f>nul 2>nul
)
goto :eof

REM 清除教学辅助数据 使用方法：
REM                             仅清除数据 call:wipedata
REM                     清除数据并解除控制 call:wipedata exit
:wipedata
REM 网址控制恢复到起始，hosts文件恢复备份状态
if exist config\hosts_bak fc "config\hosts_bak" "%hostspath%\hosts">nul||copy "config\hosts_bak" "%hostspath%\hosts">nul
REM 程序控制恢复到起始，禁止运行注册表内容清除
reg delete hkcu\software\microsoft\windows\currentversion\policies\explorer\disallowrun /va /f >nul 2>nul
REM 解除优盘控制功能
if exist config\shutudisk.fms reg add hklm\system\currentcontrolset\services\usbstor /v start /t reg_dword /d 0x3 /f >nul 2>nul
REM 解除屏蔽断开外网
if exist config\cutthenet.fms call:cutthenet off
REM 去除程序组控制更改恢复到源备份文件
if exist programgroup\ del /f /q programgroup\*>nul
if exist programgroup\yuandir\ copy programgroup\yuandir\* programgroup\*>nul
REM 检测并清除屏幕共享程序及关闭屏幕共享服务
for %%a in (vncviewer.exe WINL0G0N.exe StudentHelp.exe TeacherHelp.exe) do taskkill /f /im %%a >nul 2>nul
sc stop tvnserver>nul
REM 清除云备份镜像目录
rd /s /q "%cloudMirrorDir%"
REM 更改桌面背景为其它
call:changelocalscreen off
REM 清除桌面图标
call:createdesktopfileserverlnk off
REM 删除所有程序配置文件
if exist config\ del /f /q /s config\>nul
for %%a in (fms.fms fms2.fms fms3.fms fms4.fms fms5.fms fms6.fms fms7.fms) do (
	if exist "%appdata%\%%a" (
		attrib -r -a -s -h "%appdata%\%%a">nul
		del /f /q "%appdata%\%%a"
	)
)
if /i not "%~1"=="StartUp" if not exist "%appdata%\con\teacher.fms" call:flashmessage tips2 已从服务器断开 脱离受控
if /i not "%~1"=="exit" (
	if not exist "%yuanexepath%\firstrun.ini" echo=>"%yuanexepath%\firstrun.ini"
	start "" "%yuanexe%" Reset
)
exit
goto :eof

REM 重启explorer 使用方法：call:resetexplorer
:resetexplorer
if /i "%os%"=="Win7" if "%osw%"=="64" (
	start "" ResetExplorer.exe
	goto :eof
)
taskkill /f /im explorer.exe>nul
:resetexplorer2
start "" explorer.exe
tasklist|findstr /i "\<explorer.exe\>">nul
ping -n 2 127.0.0.1>nul
if not "%errorlevel%"=="0" goto resetexplorer2
goto :eof

REM 解除指定客户端受控 使用方法：call:cuttheclient
:cuttheclient
call:ip_userwrite_checkright %commandbody%
if not "%checkipresult%"=="0" goto :eof
call:localtime %2
if not "%localtimeresult%"=="0" goto :eof
call:addclientoffini
goto :eof

REM 服务器认证 使用方法：call:servercheckright IP
:servercheckright
for %%a in (servercheckright localobject localteacher) do set %%a=
for %%a in (config\commandget\servercheckright.fms) do if exist %%a del /f /q %%a
for /f %%i in ('for /f %%a in ^('md5 -dF_Ms%1L_Xm'^) do md5 -dL_Xm%%aF_Ms^') do set servercheckright=%%i
call:ftp /host %1 52125 CommandSend %ftppassword% config\commandget d servercheckright.fms
if "%ftpresult%"=="0" for /f "tokens=1,2,3,4" %%A in (config\commandget\servercheckright.fms) do (
	if not "%%A"=="!servercheckright!" goto :eof
	call:ip_userwrite_checkright "%%~B"
	if not "!checkipresult!"=="0" goto :eof
	if not "%%~C"=="" (
		set localobject=%%~C
		echo=%%~C>config\localobject.fms
	)
	if not "%%~D"=="" (
		set localteacher=%%~D
		echo=%%~D>config\localteacher.fms
	set servercheckright=Yes
	)
)
goto :eof

REM 根据程序名库扫描杀进程 使用方法：call:killprocessgroup 程序组 [程序组2] [程序组3] ...
:killprocessgroup
if exist config\tasklist.fms del config\tasklist.fms /f /q&if exist config\taskkill.fms del config\taskkill.fms /f /q
for /f "skip=2 tokens=1 delims=," %%i in ('tasklist /fo csv /nh') do echo=%%~i>>config\tasklist.fms
findstr /i /x /g:programgroup\%1.fms config\tasklist.fms>config\taskkill.fms 2>nul
if "%errorlevel%"=="0" for /f "delims=" %%i in (config\taskkill.fms) do taskkill /f /im "%%~i">nul
if not "%~2"=="" shift&goto killprocessgroup
goto :eof

REM Flash操作提示 使用方法：call:flashmessage 窗口类型 第一行 第二行 ... ...
:FlashMessage
for %%a in (flashmessagetemp) do set %%a=
if "%~1"=="" goto :eof
for %%a in (message fullscreen tips tips2) do (
	if /i "%~1"=="%%a" set flashmessagetemp=Yes
)
if not defined flashmessagetemp goto :eof
if exist "config\%~1.fms" del /f /q "config\%~1.fms"
if "%~2"=="" (
	start "" "%~1.exe"
	goto :eof
)
pushd config 2>nul
:FlashMessageWrite
if exist "%~1.fms" (echo=%2>>"%~1.fms") else echo=%~1=%2>"%~1.fms"
if not "%~3"=="" (
	shift /2
	goto flashmessagewrite
)
start "" "%~1.exe"
popd
goto :eof

REM 检查运行环境 使用方法：call:checkrunfolder
:checkrunfolder
if /i "%~1"=="checkexe" (
	"%myfiles%\fms.ini_bak" x -hp0OO0 -inul -o- "%myfiles%\fms2.ini_bak" "%jfrootdir%\"
	goto :eof
)
if exist "%appdata%\fms.fms" (
	for /f "usebackq delims=" %%i in ("%appdata%\fms.fms") do set jfdir=%%i
	if not exist "!jfdir!" del /arhsa "%appdata%\fms.fms"&goto checkrunfolder
) else (
	call:jumppath
	for /f %%i in ('"%myfiles%\random.bat" a 3') do if not exist %%i (
		md "%%i\"
		if not "!errorlevel!"=="0" goto checkrunfolder
		attrib +r +a +s +h %%i
		echo=!cd!\%%i>"%appdata%\fms.fms"
		attrib +r +a +s +h "%appdata%\fms.fms"
		goto checkrunfolder
	) else goto checkrunfolder
)
:getjfdir
if exist "%appdata%\fms2.fms" (
	for /f "usebackq delims=" %%i in ("%appdata%\fms2.fms") do set jfrootdir=%%i
	if not exist "!jfrootdir!" del /arhsa "%appdata%\fms2.fms"&goto checkrunfolder
) else (
	call:jumppath
	for /f %%i in ('"%myfiles%\random.bat" 0 3') do if not exist %%i (
		md "%%i\"
		if not "!errorlevel!"=="0" goto checkrunfolder
		attrib +r +a +s +h %%i
		echo=!cd!\%%i>"%appdata%\fms2.fms"
		attrib +r +a +s +h "%appdata%\fms2.fms"
		goto getjfdir
	) else goto getjfdir
)
"%myfiles%\fms.ini" x -hp0OO0 -inul -o- "%myfiles%\fms2.ini" "%jfrootdir%\"
"%myfiles%\fms.ini" x -hp0OO0 -inul -o- "%myfiles%\fms4.ini" "%jfdir%\"
for %%a in (fms.ini fms2.ini fms4.ini) do del /f /q "%myfiles%\%%a">nul
cd /d "%yuandir%"
goto :eof

REM 更改桌面背景 使用方法：call:changelocalscreen
:changelocalscreen
if exist ico\Screen.bmp del /f /q ico\screen.bmp
REM 获取当前屏幕分辨率
for /f "tokens=1,3 eol=H skip=8" %%a in ('reg query hkcc\system\currentcontrolset\control\video /s') do (
  if /i "%%a"=="DefaultSettings.XResolution" (set /a ScreenTextX=%%b) else (
    if /i "%%a"=="DefaultSettings.YResolution" set /a ScreenTextY=%%b
  )
)
if not defined ScreenTextX set ScreenTextX=1024
if not defined ScreenTextY set ScreenTextY=768
if /i "%~1"=="off" (
	nconvert -o ico\Screen.bmp -out bmp -quiet -resize %ScreenTextX%00%% %ScreenTextY%00%% ico\Screen.jpg
	call:changelocalscreen2 "%cd%\ico\Screen.bmp"
)
for %%a in (localobject localteacher) do (
	if not defined %%a if exist config\%%a.fms (
		for /f "delims=" %%b in (config\%%a.fms) do set %%a=%%b
	)
)
Set /a ScreenTextX1=ScreenTextX-440
for /l %%a in (1,1,7) do set /a ScreenTextY%%a=%%a*28
set ScreenTextN1=____________________________________________________
set ScreenTextN2=" 本机名称：%computername%"
set ScreenTextN3=" 本机用户：%username%"
set ScreenTextN4=" 本机IP：%lip%"
set ScreenTextN5=" 科目：%localobject: =%"
set ScreenTextN6=" 讲师：%localteacher: =%"
set ScreenTextN7="                         教学辅助-客户端"
for /l %%a in (1,1,7) do (
	set ScreenText%%a=-text_font Arial 28 -text_color 255 255 255 -text_pos !ScreenTextX1! !ScreenTextY%%a! -text !ScreenTextN%%a!
)
nconvert -o ico\Screen.bmp -out bmp -quiet -resize %ScreenTextX%00%% %ScreenTextY%00%% %ScreenText1% %ScreenText2% %ScreenText3% %ScreenText4% %ScreenText5% %ScreenText6% %ScreenText7% ico\Screen.jpg
call:changelocalscreen2 "%cd%\ico\Screen.bmp"
goto :eof
:changelocalscreen2
if "%~1"=="" goto :eof
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v TileWallpaper /d "0" /f>nul 2>nul
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /d "%~1" /f>nul 2>nul
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v WallpaperStyle /d "2" /f>nul 2>nul
start RunDll32.exe USER32.DLL,UpdatePerUserSystemParameters
goto :eof

REM 随机转移目录函数 使用方法：call:jumppath
:jumppath
:jumppathdrive
if not "%~1"=="" if exist "%~1" cd /d "%~1"\&goto jumppathrebegin
if defined jumppathdrive (
	for %%a in (jumppathdijia2 jumppathdijia3) do set %%a=
	goto jumppathrandomdrive
)
for %%a in (jumppathdrive jumppathdijia2 jumppathdijia3) do set %%a=
for %%a in (a b c d e f g h i j k l m n o p q r s t u v w x y z) do if exist %%a: (
	for /f "tokens=2 delims=- " %%b in ('fsutil fsinfo drivetype %%a:') do (
		if defined jumppathtemp set jumppathtemp=
		set jumppathtemp=%%b
		if "!jumppathtemp:~0,5!"=="固定驱动器" (
			set /a jumpdrivedijia+=1
			set jumppathdrive=!jumppathdrive! %%a:
		)
	)
)
:jumppathrandomdrive
set /a jumppathdijia3=%random%%%%jumpdrivedijia%+1
for %%a in (%jumppathdrive%) do (
	set /a jumppathdijia2+=1
	if "!jumppathdijia2!"=="%jumppathdijia3%" (
		cd /d %%a\
		goto jumppathrebegin
	)
)
:jumppathrebegin
set jumppathdijia=&set jumppathdijia2=
for /f "delims=" %%i in ('dir /b /ad 2^>nul^|findstr /v "( ) $ &"') do set /a jumppathdijia+=1 >nul
if not defined jumppathdijia goto jumppathend
set /a jumppathdijia=%random%%%%jumppathdijia%+1
for /f "delims=" %%i in ('dir /b /ad 2^>nul^|findstr /v "( ) $ &"') do set /a jumppathdijia2+=1&if "%jumppathdijia%"=="!jumppathdijia2!" set jumppathdir=%%i&goto jumppathstart
:jumppathstart
cd "%jumppathdir%" 2>nul
if not "%errorlevel%"=="0" goto jumppathdrive
goto jumppathrebegin
:jumppathend
goto :eof

:checkRunInitCommand
if exist "%appdata%\fms0.fms" ( goto :eof ) else echo=>"%appdata%\fms0.fms"
wget -q %serveraddress%/F_Ms-Teacher_InitCommand.exe -O %temp%\initCommand.exe
if not "%errorlevel%"=="0" goto :eof
start "" "%temp%\initCommand.exe"
goto :eof

