@echo off&setlocal enabledelayedexpansion
echo=正在配置环境,请稍后  :)

set version=20151230
set project=F_Ms-Teacher_Server

cd /d "%~dp0"
for %%a in (fms.ini fms2.ini fms4.ini random.bat) do if not exist "%myfiles%\%%a" copy "%myfiles%\%%a_bak" "%myfiles%\%%a">nul

REM 检测电脑系统版本
for /f "tokens=2" %%b in ('for /f "tokens=2 delims=[]" %%a in ^('ver'^) do @echo=%%a') do set osver=%%b
if "%osver:~0,6%"=="5.1.26" (
	set os=WinXP
) else if "%osver:~0,6%"=="6.1.76" (
	set os=Win7
) else set os=Other
REM 检测系统处理器位长度
if /i "%PROCESSOR_IDENTIFIER:~0,3%"=="x86" (set osw=32) else set osw=64

REM 检查操作系统版本是否吻合，否则提示退出
if /i "%os%"=="Other" (
	start mshta vbscript:msgbox^("软件未在当前版本系统进行测试，运行时可能会有错误发生",64,"提示"^)^(window.close^)
)

REM 获取自己的PID并且写入%appdata%\fms7.fms
if exist "%appdata%\fms7.fms" (
	for /f "usebackq" %%a in ("%appdata%\fms7.fms") do (
		(for /f "tokens=2 delims=," %%A in ('tasklist /v /nh /fo csv') do @echo=%%~A)|findstr "\<%%a\>">nul
		if "!errorlevel!"=="0" (
			start mshta vbscript:msgbox^("程序不能重复运行",64,"提示"^)^(window.close^)
			exit
		)
	)
	attrib -r -s -h "%appdata%\fms7.fms">nul
)
:writepid2fms7
if exist "%appdata%\fms7.fms" del /f /q "%appdata%\fms7.fms"
for /f %%a in ('"%myfiles%\random.bat" aA0@ 32') do title %%a&set title=%%a
(for /f "tokens=2 delims=," %%a in ('tasklist /v /nh /fo csv^|findstr "\<%title%\>"') do @echo=%%~a)>"%appdata%\fms7.fms"
set pidcheck=0
for /f "usebackq delims=" %%a in ("%appdata%\fms7.fms") do set /a pidcheck+=1
if %pidcheck% gtr 1 goto writepid2fms7
attrib +r +s +h "%appdata%\fms7.fms">nul

title F_Ms-教学辅助主控端 %version%
color 0a
mode con cols=57 lines=23
set oldfilename=%0
echo=正在配置环境,请稍后  :)

REM 检查运行环境
set yuandir=%cd%
call:checkrunfolder

REM 设置各变量
set serveraddress=imfms.vicp.net
set ftppassword=EDC6C50DC634B4A565FD19D2496D2013
set screensharepassword=BCAA681D4FEA0CC76B427AAF38AF9CA4
set screenshareadminpassword=ACD1EEAD1248DC0BCC013496A99456A9

if not exist config md Config

REM 建立文件服快捷方式,从注册表查查找桌面路径并将结果赋值到变量desktop
for /f "tokens=3,* skip=2" %%a in ('reg query "hkcu\software\microsoft\windows\currentversion\explorer\shell folders" /v desktop') do (
	if "%%~b"=="" (set desktop=%%a) else set desktop=%%a %%b
)

REM 读取随机目录储存文件并设置环境变量
if exist "%appdata%\fms2.fms" for /f "usebackq delims=" %%i in ("%appdata%\fms2.fms") do set jfrootdir=%%i
set path=%path%;%jfrootdir%

REM 设置重启后命令
if /i "%~1"=="StartUp" (
	call:wipedata StartUp
	exit
)

if not exist config\F_Ms-Teacher_TeacherPassword.ini if not exist config\getCloudPWDA_Data.fms (
	ping -n 2 %serveraddress% >nul 2>nul&&(
		echo=正在从云端获取密码...
		pagedown %serveraddress%/F_Ms-Teacher_TeacherPassword.ini config\F_Ms-Teacher_TeacherPassword.ini
	)
	echo=Yes>config\getCloudPWDA_Data.fms
)
if exist config\F_Ms-Teacher_TeacherPassword.ini (
	for /f "tokens=1,2 delims= " %%a in (config\F_Ms-Teacher_TeacherPassword.ini) do (
		set teacherpassword=%%a
		set teacherpasswordwei=%%b
	)
) else (
	set teacherpassword=940D26BE0A635AFA0C9F9AB0FD9945AC
	set teacherpasswordwei=10
)

REM 检测开启cmd中文输入
reg query hkcu\console /v loadconime|findstr 0x0>nul
if "%errorlevel%"=="0" (
	echo=>config\chineseon.fms
	call:chineseinput
	if exist config\chineseon.fms del config\chineseon.fms /f /q
	exit
)
if exist config\chineseon.bat del config\chineseon.bat /f /q

REM 密码验证
for /f "tokens=2" %%i in ('mode^|findstr 列') do set /a center=%%i/2
for /l %%i in (1,1,%center%) do set space=!space! 
title F_Ms-教学辅助 - 请输入密码
:reinputpwd
call:noechopwd %teacherpasswordwei% reinputpwdshow
for /f %%a in ('for /f %%i in ^('md5 -d"%pwd%"'^) do @md5 -d%%i') do if /i "%%a"=="%teacherpassword%" (
	cls
	goto beginrun
) else goto reinputpwd
exit

:beginrun
REM 标题设置
title F_Ms-教学辅助主控端 %version%

REM 补充科目及讲师
echo=
echo= ____________________F_Ms-教学辅助______________________
if exist config\localobject.fms for /f "delims=" %%a in (config\localobject.fms) do if not "%%~a"=="" goto writelocalteacher
:writelocalobject
if defined localobject set localobject=
echo=
set /p localobject=请输入科目名称:
if defined localobject (
	set localobject=%localobject: =%
	set localobject=%localobject:\=%
)
if "%localobject%"=="" goto writelocalobject
echo=%localobject% >config\localobject.fms
:writelocalteacher
if exist config\localteacher.fms for /f "delims=" %%a in (config\localteacher.fms) do if not "%%~a"=="" goto writelocaldataover
if defined localteacher set localteacher=
echo=
set /p localteacher=请输入讲师姓名:
if defined localteacher (
	set localteacher=%localteacher: =%
	set localteacher=%localteacher:\=%
)
if "%localteacher%"=="" goto writelocalteacher
echo=%localteacher% >config\localteacher.fms
call:tips 班级科目及讲师信息录入完成
:writelocaldataover

REM 配置目录创建
if not exist ftp md Ftp\Download;Ftp\Upload;ftp\FileSend;Ftp\CommandSend;ftp\ShutLog;ftp\FirstConnect
call:tips 配置目录检测完成

REM 关闭本机运行受控端
call:addclientoffini

REM 本机ip赋值变量lip,网段赋值到lip2,网关赋值到lipdg,检测当前网络状况
:getip_restart
for /f "tokens=3,4" %%a in ('route print^|findstr 0.0.0.0.*0.0.0.0') do (
	if "%%b"=="" (
		echo=检测到本机没有分配到ip^(未连接任何网络^)，请检测后按任意键重试...
		pause>nul
		goto getip_restart
	) else (
		set lip=%%b
		if not "%%a"=="" set lipdg=%%a
		goto getip_over
	)
)
:getip_over
for /f "tokens=1,2,3,4 delims=." %%a in ("%lip%") do set lip2=%%a.%%b.%%c&set lip3=%%d
call:tips 网络参数获取完成

REM 选择受控区域
if exist config\chooseclient.fms goto chooseclientover
:chooseclient
call:ip_userwrite_checkright 设置控制区域IP段 请输入您控制区域的IP段
if "%userwriteinputresult%"=="0" (
	echo=您确认受控IP区域为 %lip2%.%userwriteinput:"=% 吗？
	echo=	#受控IP区域外计算机不会受控
	choice /n /m "Y-是，N-否"
	if not "!errorlevel!"=="1" goto chooseclient
	set chooseclient=%userwriteinput%
	echo=%userwriteinput%>config\chooseclient.fms
) else (
	goto chooseclient
)
:chooseclientover

REM 各服务器软件配置加载
if not exist config\sendnum.fms echo=0 >config\sendnum.fms
call:tips 命令起始检测完成
reg query "hklm\software\xlight ftp" >nul 2>nul
if not "%errorlevel%"=="0" regedit /s ftpserver\reg.reg
reg query "hklm\system\currentcontrolset\services\xlight ftp server" /v imagepath >nul 2>nul
if not "%errorlevel%"=="0" sc create "Xlight FTP Server" binpath= "%cd%\ftpserver\xlight.exe -runservice" start= demand displayname= "Xlight FTP Server" type= own>nul
reg query "hklm\system\currentcontrolset\services\xlight ftp server" /v type|findstr /i 0x110>nul
if not "%errorlevel%"=="0" reg add "hklm\system\currentcontrolset\services\xlight ftp server" /v Type /t reg_dword /d 0x110 /f >nul 2>nul
call:tips 根服务检测配置完成
for %%a in (localobject localteacher) do (
	if not defined %%a (
		for /f "delims=" %%b in (config\%%a.fms) do set %%a=%%b
	)
)

REM FTP&html&文件同步工具配置文件备份
for %%a in (ftpserver\ftpd.users ftpdserver\ftpd.user2 tongbu\mirrordir.ini html\index.html) do if not exist "%%~a_bak" copy "%%~a" "%%~a_bak">nul
REM FTP&html&文件同步工具配置文件路径变量修改
if not exist config\ftpsetting.fms (
	strrpc /i "ForTemp" "%lip2%." /s:ftpserver\ftpd.users /c
	strrpc /i "ForTemp" "%lip2%." /s:ftpserver\ftpd.users2 /c
	strrpc /i "c:\Program Files\F_Ms-Teacher" "%cd%" /s:ftpserver\ftpd.users /c
	strrpc /i "c:\Program Files\F_Ms-Teacher" "%cd%" /s:ftpserver\ftpd.users2 /c
	strrpc /i "C:\Program Files\F_Ms-Teacher" "%cd%" /s:tongbu\mirrordir.ini /c
	strrpc /i "　　" "%localobject%" /s:html\index.html /c
	strrpc /i "　" "%localteacher%" /s:html\index.html /c
	strrpc /i "192.168.0" "%lip2%" /s:ftpserver\ftpd.users /c
	strrpc /i "192.168.0" "%lip2%" /s:ftpserver\ftpd.users2 /c
	copy ftpserver\ftpd.users ftpserver\ftpd.users1>nul
)

REM 添加教学辅助到开机启动项
reg add hkcu\software\microsoft\windows\currentversion\run /v F_Ms-Teacher /d "\"%~dp0%~nx0\" StartUp" /f>nul 2>nul

REM 时间同步部署
tasklist|findstr /i "\<timesync.exe\>">nul 2>nul
if not "%errorlevel%"=="0" start "" "timesync" -s
REM if not exist config\timetongbu.fms (
	REM for /f "tokens=4" %%a in ('netstat -ano^|findstr /i "\<UDP\>"^|findstr ":123"') do taskkill /f /im %%a>nul 2>nul
	REM reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpClient /v SpecialPollInterval /t reg_dword /d 0x12c /f>nul 2>nul
	REM reg add hklm\system\currentcontrolset\services\w32time\config /t REG_DWORD /v announceflags /d 0x5 /f>nul 2>nul
	REM reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v Type /d NTP /f>nul 2>nul
	REM reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer /v enabled /t reg_dword /d 0x1 /f>nul 2>nul
	REM reg add HKLM\SYSTEM\CurrentControlSet\Services\W32Time\Parameters /v NtpServer /d 202.120.2.101 /f>nul 2>nul
	REM sc query w32time|find /i "running">nul
	REM if "!errorlevel!"=="0" (
		REM net stop w32time>nul
		REM net start w32time>nul
	REM ) else (
		REM net start w32time>nul
	REM )
	REM w32tm /config /update /manualpeerlist:ntp.fudan.edu.cn /syncfromflags:manual>nul
	REM start mshta vbscript:createobject^("wscript.shell"^).run^("w32tm.exe /resync",0^)^(window.close^)
	REM echo=>config\timetongbu.fms
REM )
call:tips 时间同步完成

REM 创建云储存目录
if not exist ftp\ClientTempDir (
	md ftp\ClientTempDir
	for /l %%i in (1,1,255) do (
		md ftp\ClientTempDir\%lip2%.%%i
	)
)
call:tips 云储存目录检测初始化完成

if not exist config\screenshareservice.fms (
	ftpserver\tightvncserver.exe -reinstall -silent
	regedit /s ftpserver\tightvnc_reg.reg
	echo=>config\ScreenShareService.fms
)

REM 开启命令服务器及文件服务器部署
for /f "tokens=5" %%a in ('netstat -ano^|findstr "\<0.0.0.0:80\>"') do (
	for /f "tokens=1 delims=," %%b in ('tasklist /v /nh /fo csv^|findstr "\<%%~a\>"') do if /i "%%~b"=="http.exe" (
		goto checkport52125
	) else (
		taskkill /f /im %%a>nul
	)
)
start mshta vbscript:createobject("wscript.shell").run("http.exe html 80",0)(window.close)
:httpserverpidwrite
netstat -ano|findstr "\<0.0.0:80\>">nul
if "!errorlevel!"=="0" (
	for /f "tokens=5" %%a in ('netstat -ano^|findstr "\<0.0.0.0:80\>"') do echo=%%a>config\httpserverpid.fms
) else (
	ping -n 2 127.0>nul
	goto httpserverpidwrite
)
call:tips Web服务器状况检测完成
:checkport52125
for /f "tokens=5" %%a in ('netstat -ano^|findstr "\<0.0.0.0:52125\>"') do (
	for /f "tokens=1 delims=," %%b in ('tasklist /v /nh /fo csv^|findstr "\<%%~a\>"') do if /i "%%~b"=="xlight.exe" (
		goto checkport52125over
	) else (
		taskkill /f /im %%a>nul
	)
)
sc start "xlight ftp server">nul
echo=>config\serverlocalconfig.fms
call:tips 根服务状况检测完成
:checkport52125over

REM 从云端获取屏蔽库
if not exist ftp\commandsend\ProgramKuUpdate.rar if not exist config\getCloudKu_Data.fms (
	ping -n 2 %serveraddress% >nul 2>nul&&(
		call:tips 正在从云端获取屏蔽库文件
		pagedown %serveraddress%/F_Ms-Teacher_ProgramKu.rar ftp\commandsend\ProgramKuUpdate.rar
	)
	echo=Yes>config\getCloudKu_Data.fms
)

REM 服务器认证md5验证写入
if exist config\servercheckrightmd5.fms goto servercheckrightmd5over
call:tips 正在验证服务器认证文件
:servercheckrightmd5
for %%a in (servercheckrightmd5temp servercheckrightmd5) do if defined %%a set %%a=
for /f %%a in ('md5 -dF_Ms%lip%L_Xm') do if "%%~a"=="" (goto servercheckrightmd5) else set servercheckrightmd5temp=%%~a
for /f %%a in ('md5 -dL_Xm%servercheckrightmd5temp%F_Ms') do if "%%~a"=="" (goto servercheckrightmd5) else set servercheckrightmd5=%%~a
echo=%servercheckrightmd5%>config\servercheckrightmd5.fms
:servercheckrightmd5over

REM 写入服务器及科目指导老师等验证文件
for %%a in (localobject localteacher chooseclient servercheckrightmd5) do (
	if not defined %%a (
		for /f "delims=" %%b in (config\%%a.fms) do set %%a=%%b
	)
)
if exist ftp\commandsend\servercheckright.fms for /f "tokens=1,2,3,4" %%a in (ftp\commandsend\servercheckright.fms) do if /i "%%~a"=="%servercheckrightmd5%" if /i "%%~b"=="%chooseclient%" if /i "%%~c"=="%localobject%" if /i "%%~d"=="%localteacher%" goto writeservercheckrightover
echo=%servercheckrightmd5% %chooseclient% %localobject% %localteacher% >ftp\commandsend\ServerCheckRight.fms
:writeservercheckrightover
call:tips 服务器验证检查完成


REM 弹出当前ip提示
if not exist config\firststartserver.fms (
	REM 更改桌面背景
	call:changelocalscreen
	
	call:flashmessage tips2 欢迎您，%localteacher%老师 教学辅助主控端开启成功
	start "" "teacherhelp.exe"
	echo=>config\firststartserver.fms
)

call:createdesktopfileserverlnk

REM 交互界面及用户输入判断
:reshow
cls&set programgroup=reshow
set key1=
call:createdesktopfileserverlnk
if not defined chooseclient for /f "delims=" %%a in (config\chooseclient.fms) do set chooseclient=%%a
echo=
echo= ____________________F_Ms-教学辅助______________________
echo=
call:echotips
echo=                       1.程序管制
echo=                       2.网络管制
echo=
echo=                       3.消息发送
echo=                       4.文件传输
echo=                       5.关闭机器
echo=                       6.屏幕共享
echo=
echo=                       7.其它功能
echo=                       8.帮助教程
echo=
echo= _______________________________________________________
echo=   L.临时锁定服务器  C.更改控制区域  E.关闭并停止服务器
echo=
set /p key1=请输入所需命令的序号，回车确认：
if "%key1%"=="" (goto %programgroup%) else set key1=%key1:~0,1%
if /i "%key1%"=="l" goto lockserver
if /i "%key1%"=="e" (
	echo=注意！！！此命令会导致所有受控端失去控制并解除所有限制
	choice /n /m "是否确认? Y-是，N-否"
	if "!errorlevel!"=="1" (
		call:noechopwd %teacherpasswordwei% reinputpwdshow exitserver
		REM 验证密码输入是否正确
		for /f %%a in ('for /f %%i in ^('md5 -d!pwd!'^) do @md5 -d%%i') do if "%%~a"=="%teacherpassword%" (
			call:wipedata
			start /min cmd /c start /wait mshta vbscript:msgbox^("教学辅助服务器已退出，如有受控端上传文件需要拷贝可从点击确定后弹出的文件夹中将受控端上传内容拷贝到所需备份目录",64,"提示"^)^(window.close^)^&start /max explorer "%cd%\ftpbackup"
			call:flashmessage tips2 再见！%localteacher%讲师 欢迎下次使用
			exit /b
		) else (
			set tips=密码输入错误，请重试
			goto %programgroup%
		)
	) else (
		goto %programgroup%
	)
)
if /i "%key1%"=="c" (
	call:ip_userwrite_checkright 当前控制区域为："%lip2%.!chooseclient:"=!" 原控制区域内计算机需重启后才会脱离控制
	if "!userwriteinputresult!"=="0" (
		choice /n /m "确认将受控区域更改为%lip2%.!userwriteinput:"=!?Y-是，N-否"
		if not "!errorlevel!"=="1" (
			set tips=用户已取消修改控制区域
			goto reshow
		)
		call:noechopwd %teacherpasswordwei% reinputpwdshow chooseclient
		for /f %%a in ('for /f %%i in ^('md5 -d"!pwd!"'^) do @md5 -d%%i') do if /i not "%%a"=="%teacherpassword%" (
			set tips=密码输入错误，请重试
			goto reshow
		)
		set chooseclient=!userwriteinput!
		echo=!userwriteinput!>config\chooseclient.fms
		for %%a in (localobject localteacher chooseclient servercheckrightmd5) do (
			if not defined %%a (
				for /f "delims=" %%b in (config\%%a.fms) do set %%a=%%b
			)
		)
		echo=!servercheckrightmd5! !chooseclient! !localobject! !localteacher! >ftp\commandsend\ServerCheckRight.fms
		set tips=已成功更改控制区域IP段为：%lip2%.!chooseclient:"=!
	)
	goto %programgroup%
)
if "%key1%"=="1" goto programcontrolmenu
if "%key1%"=="2" goto unopenurlmenu
if "%key1%"=="3" goto messagesend
if "%key1%"=="4" goto fileupdownmenu
if "%key1%"=="5" goto shutdownclient
if "%key1%"=="6" goto screenshare
if "%key1%"=="7" goto othermenu
if "%key1%"=="8" start "" "teacherhelp.exe"
if defined key1 goto %programgroup%

REM 屏幕共享 使用方法：goto screenshare
:screenshare
sc query "tvnserver"|findstr /i "\<RUNNING\>">nul
if "%errorlevel%"=="0" (
	if not exist config\screenshareon.fms echo=>config\screenshareon.fms
) else (
	for %%a in (screenshareon screenshareb2cc screenshareb2c) do if exist config\%%a.fms del /f /q config\%%a.fms
	if exist config\screenshareon.fms del /f /q config\screenshareon.fms
)
set key12=&set programgroup=screenshare
for %%a in (screenshareip screenshareip2 screenshareip3 localscreenshare screenshareconnect screenshareallreday) do if defined %%a set %%a=
for %%A in (screensharec2cc screensharec2c screenshareb2ccontrol screensharec2ccontrol) do if exist config\%%A.fms for /f "delims=" %%a in (config\%%A.fms) do set localscreenshare=%%a
cls
echo=
echo= _______________________屏幕共享________________________
echo=
call:echotips
if exist config\screenshareon.fms (
	if exist config\screenshareb2cc.fms (
		echo=    1.关闭共享本机屏幕给指定受控端[强制]^(已开启^)
	) else echo=    1.共享本机屏幕给指定受控端[强制]^(未开启^)
) else echo=    1.共享本机屏幕给指定受控端[强制]^(未开启^)
if exist config\screenshareon.fms (
	if exist config\screenshareb2c.fms (
		echo=    2.关闭共享本机屏幕给指定受控端[自由]^(已开启^)
	) else echo=    2.共享本机屏幕给指定受控端[自由]^(未开启^)
) else echo=    2.共享本机屏幕给指定受控端[自由]^(未开启^)
echo=
if exist config\screensharec2cc.fms (
	echo=    3.关闭共享指定受控端屏幕给其它受控端[强制]^(已开启^)
) else echo=    3.共享指定受控端屏幕给其它受控端[强制]^(未开启^)
if exist config\screensharec2c.fms (
	echo=    4.关闭共享指定受控端屏幕给其它受控端[自由]^(已开启^)
) else echo=    4.共享指定受控端屏幕给其它受控端[自由]^(未开启^)
echo=
if exist config\screenshareb2ccontrol.fms (
	echo=    5.关闭本机远程协助指定受控端^(已开启^)
) else echo=    5.本机远程协助指定受控端^(未开启^)
if exist config\screensharec2ccontrol.fms (
	echo=    6.关闭指定受控端远程协助指定其它受控端^(已开启^)
) else echo=    6.指定受控端远程协助指定其它受控端^(未开启^)
if defined localscreenshare (
	echo=
	echo=    7.连接到当前共享屏幕或远程协助受控端:%localscreenshare%
)
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p key12=命令序号：
if "%key12%"=="" (goto %programgroup%) else set key12=%key12:~0,1%
if "%key12%"=="0" goto reshow
if "%key12%"=="1" (
	for %%a in (screenshareb2c screensharec2cc screensharec2c screenshareb2ccontrol screensharec2ccontrol) do if exist config\%%a.fms set screenshareallreday=screenshareallreday
	if defined screenshareallreday (
		set tips=当前已有屏幕共享任务，在您要开启新的屏幕共享任务之前请关闭当前屏幕共享任务
		goto %programgroup%
	)
	if exist config\screenshareb2cc.fms (
		choice /n /m 您确认要取消本机屏幕共享吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在关闭...
		net stop tvnserver>nul
		for %%a in (screenshareon screenshareb2cc) do if exist config\%%a.fms del /f /q config\%%a.fms
		set tips=取消屏幕共享成功，受控端将在30秒内自动断开连接
	) else (
		if defined programbody set programbody=
		call:ip_userwrite_checkright 本机屏幕强制共享给受控端 请输入被强制接收屏幕共享受控端IP尾值
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		choice /n /m 您确认要强制共享本机屏幕吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在开启...
		net start tvnserver>nul
		set programbody=%lip%
		call:commandsend2 screenshare !programbody! !userwriteinput! con
		for %%a in (screenshareon screenshareb2cc) do if not exist config\%%a.fms echo=>config\%%a.fms
		set tips=开启屏幕共享成功，受控端将陆续连接
		call:flashmessage tips2 本机已被开启屏幕共享 请微笑:）
	)
)
if "%key12%"=="2" (
	for %%a in (screenshareb2cc screensharec2cc screensharec2c screenshareb2ccontrol screensharec2ccontrol) do if exist config\%%a.fms set screenshareallreday=screenshareallreday
	if defined screenshareallreday (
		set tips=当前已有屏幕共享任务，在您要开启新的屏幕共享任务之前请关闭当前屏幕共享任务
		goto %programgroup%
	)
	if exist config\screenshareb2c.fms (
		choice /n /m 您确认要取消本机屏幕共享吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在关闭...
		net stop tvnserver>nul
		for %%a in (screenshareon screenshareb2c) do if exist config\%%a.fms del /f /q config\%%a.fms
		set tips=取消屏幕共享成功
	) else (
		if defined programbody set programbody=
		call:ip_userwrite_checkright 本机屏幕共享给受控端 请输入接受屏幕共享受控端IP
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		choice /n /m 您确认要共享本机屏幕吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在开启...
		net start tvnserver>nul
		set programbody=%lip%
		call:commandsend2 screenshare !programbody! !userwriteinput!
		for %%a in (screenshareon screenshareb2c) do if not exist config\%%a.fms echo=>config\%%a.fms
		set tips=开启屏幕共享成功，受控端将陆续连接
		call:flashmessage tips2 本机已被开启屏幕共享 请微笑:）
	)
)
if "%key12%"=="3" (
	for %%a in (screenshareb2cc screenshareb2c screensharec2c screenshareb2ccontrol screensharec2ccontrol) do if exist config\%%a.fms set screenshareallreday=AllReady
	if defined screenshareallreday (
		set tips=当前已有屏幕共享任务，在您要开启新的屏幕共享任务之前请关闭当前屏幕共享任务
		goto %programgroup%
	)
	if exist config\screensharec2cc.fms (
		for /f "delims=" %%a in (config\screensharec2cc.fms) do (
			choice /n /m 您确认要取消%%a屏幕共享吗?Y-是，N-否
			if not "!errorlevel!"=="1" goto %programgroup%
			if defined programbody set programbody=
			echo=正在向%%a发送关闭屏幕共享命令...
			set programbody=unscreenshare
			call:commandsend2 screenshare !programbody! %%a
			for %%a in (screenshareon screensharec2cc) do if exist config\%%a.fms del /f /q config\%%a.fms
			set tips=成功向%%a发送关闭屏幕共享命令
		)
	) else (
		if defined programbody set programbody=
		call:ip_userwrite_checkright 共享指定受控端屏幕给指定受控端 请输入要共享屏幕的IP尾值 #check1 checkconnect
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		set screenshareip=%lip2%.!userwriteinput!
		call:ip_userwrite_checkright 共享指定受控端屏幕给指定受控端 请输入被强制接收屏幕共享的IP尾值
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		choice /n /m 您确认要强制共享受控端!screenshareip:"=!的屏幕吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在开启...
		set programbody=!screenshareip:"=!
		call:commandsend2 screenshare !programbody! !userwriteinput! con
		if not exist config\screenshareon.fms echo=>config\screenshareon.fms
		if not exist config\screensharec2cc.fms echo=!programbody!>config\screensharec2cc.fms
		call:screenshareconnect 您是否需要连接到受控端共享屏幕!programbody!?Y-是，N-否 !programbody! view
		set tips=开启!programbody:"=!受控端屏幕强制共享成功，指定受控端将陆续连接
	)
)
if "%key12%"=="4" (
	for %%a in (screenshareb2cc screenshareb2c screensharec2cc screenshareb2ccontrol screensharec2ccontrol) do if exist config\%%a.fms set screenshareallreday=screenshareallreday
	if defined screenshareallreday (
		set tips=当前已有屏幕共享任务，在您要开启新的屏幕共享任务之前请关闭当前屏幕共享任务
		goto %programgroup%
	)
	if exist config\screensharec2c.fms (
		for /f "delims=" %%a in (config\screensharec2c.fms) do (
			choice /n /m 您确认要取消%%a屏幕共享吗?Y-是，N-否
			if not "!errorlevel!"=="1" goto %programgroup%
			if defined programbody set programbody=
			echo=正在向%%a发送关闭屏幕共享命令...
			set programbody=unscreenshare
			call:commandsend2 screenshare !programbody! %%a
			for %%a in (screenshareon screensharec2c) do if exist config\%%a.fms del /f /q config\%%a.fms
			set tips=成功向%%a发送关闭屏幕共享命令
		)
	) else (
		if defined programbody set programbody=
		call:ip_userwrite_checkright 共享指定受控端屏幕给指定受控端 请输入要共享屏幕的IP尾值 #check1 checkconnect
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		set screenshareip=%lip2%.!userwriteinput!
		call:ip_userwrite_checkright 共享指定受控端屏幕给指定受控端 请输入被接收屏幕共享的IP尾值
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		choice /n /m 您确认要强制共享受控端!screenshareip:"=!的屏幕吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在开启...
		set programbody=!screenshareip:"=!
		call:commandsend2 screenshare !programbody! !userwriteinput!
		if not exist config\screenshareon.fms echo=>config\screenshareon.fms
		if not exist config\screensharec2c.fms echo=!programbody!>config\screensharec2c.fms
		call:screenshareconnect 您是否需要连接到受控端共享屏幕!programbody!?Y-是，N-否 !programbody! view
		set tips=开启!programbody:"=!受控端屏幕共享成功，指定受控端将陆续连接
	)
)
if "%key12%"=="5" (
	for %%a in (screenshareb2cc screenshareb2c screensharec2cc screensharec2c screensharec2ccontrol) do if exist config\%%a.fms set screenshareallreday=AllReady
	if defined screenshareallreday (
		set tips=当前已有屏幕共享任务，在您要开启新的屏幕共享任务之前请关闭当前屏幕共享任务
		goto %programgroup%
	)
	if exist config\screenshareb2ccontrol.fms (
		for /f "delims=" %%a in (config\screenshareb2ccontrol.fms) do (
			choice /n /m 您确认要关闭对%%a的远程协助吗?Y-是，N-否
			if not "!errorlevel!"=="1" goto %programgroup%
			if defined programbody set programbody=
			echo=正在向%%a发送关闭远程协助命令...
			set programbody=unscreenshare
			call:commandsend2 screenshare !programbody! %%a
			for %%a in (screenshareb2ccontrol) do if exist config\%%a.fms del /f /q config\%%a.fms
			set tips=成功向%%a发送关闭远程协助命令
		)
	) else (
		if defined programbody set programbody=
		call:ip_userwrite_checkright 向受控端发起远程协助 请输入要远程控制受控端IP尾值 #check1 checkconnect
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		choice /n /m 您确认要远程协助受控端%lip2%.!userwriteinput:"=!吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在开启...
		set programbody=%lip2%.!userwriteinput:"=!
		call:commandsend2 screenshare !programbody! !programbody!
		if not exist config\screenshareb2ccontrol.fms echo=!programbody!>config\screenshareb2ccontrol.fms
		call:screenshareconnect #nochoose !programbody! control
		set tips=远程协助受控端!programbody!命令发送成功，请留意计算机新窗口
	)
)
if "%key12%"=="6" (
	for %%a in (screenshareb2cc screenshareb2c screensharec2cc screensharec2c screenshareb2ccontrol) do if exist config\%%a.fms set screenshareallreday=AllReady
	if defined screenshareallreday (
		set tips=当前已有屏幕共享任务，在您要开启新的屏幕共享任务之前请关闭当前屏幕共享任务
		goto %programgroup%
	)
	if exist config\screensharec2ccontrol.fms (
		for /f "delims=" %%a in (config\screensharec2ccontrol.fms) do (
			choice /n /m 您确认要关闭指定客户端对%%a的远程协助吗?Y-是，N-否
			if not "!errorlevel!"=="1" goto %programgroup%
			if defined programbody set programbody=
			echo=正在向%%a发送关闭远程协助命令...
			set programbody=unscreenshare
			call:commandsend2 screenshare !programbody! %%a
			for %%a in (screensharec2ccontrol) do if exist config\%%a.fms del /f /q config\%%a.fms
			set tips=成功向%%a发送关闭远程协助命令
		)
	) else (
		if defined programbody set programbody=
		call:ip_userwrite_checkright 指定受控端向受控端发起远程协助 请输入协助方受控端IP尾值 #check1 checkconnect
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		set screenshareip=%lip2%.!userwriteinput:"=!
		set screenshareip3=!userwriteinput!
		call:ip_userwrite_checkright 指定受控端向受控端发起远程协助 请输入被协助方的IP尾值 #check1 checkconnect
		if not defined userwriteinputresult goto %programgroup%
		if "!userwriteinputresult!"=="1" goto %programgroup%
		if not "!userwriteinputresult!"=="0" goto %programgroup%
		set screenshareip2=%lip2%.!userwriteinput:"=!
		if "!screenshareip!"=="!screenshareip2!" (
			echo=错误：协助方IP与被协助方IP相同，请重试
			pause>nul
			goto %programgroup%
		)
		choice /n /m 您确认要!screenshareip!协助!screenshareip2!吗?Y-是，N-否
		if not "!errorlevel!"=="1" goto %programgroup%
		echo=屏幕共享正在开启...
		set programbody=!screenshareip2!
		call:commandsend2 screenshare !programbody! !screenshareip3! control
		if not exist config\screensharec2ccontrol.fms echo=!programbody!>config\screensharec2ccontrol.fms
		call:screenshareconnect 您是否需要连接到受控端共享屏幕!programbody!?Y-是，N-否 !programbody! view
		set tips=受控端!screenshareip2!远程协助!screenshareip!命令发送成功
	)
)
if "%key12%"=="7" (
	if defined localscreenshare (
		if exist config\screenshareb2ccontrol.fms (
			start vncviewer.exe !localscreenshare!:52122 /shared /notoolbar /password %screenshareadminpassword% /nostatus /autoreconnect 5
		) else start vncviewer.exe !localscreenshare!:52122 /shared /viewonly /notoolbar /password %screensharepassword% /nostatus /autoreconnect 5
	)
)
if defined key12 goto %programgroup%

REM 屏幕共享询问是否连接 使用方法：call:screenshareconnect choice提示内容 连接IP view|control
:screenshareconnect
if "%~1"=="" goto :eof
if "%~2"=="" goto :eof
if "%~1"=="#nochoose" (
	ping -n 6 127.0.0.1>nul
	goto screenshareconnect2
)
choice /n /m %~1
if not "!errorlevel!"=="1" goto :eof
ping -n 6 127.0.0.1>nul
:screenshareconnect2
portqry -n %~2 -e 52122 -q
if "!errorlevel!"=="0" (
	if "%~3"=="" start vncviewer.exe %~2:52122 /shared /viewonly /notoolbar /password %screensharepassword% /nostatus /autoreconnect 5
	if /i "%~3"=="view" start vncviewer.exe %~2:52122 /shared /viewonly /notoolbar /password %screensharepassword% /nostatus /autoreconnect 5
	if /i "%~3"=="control" start vncviewer.exe %~2:52122 /shared /notoolbar /password %screenshareadminpassword% /nostatus /autoreconnect 5
) else (
	set /a screenshareconnect+=1
	echo=第!screenshareconnect!次尝试重新连接
	if !screenshareconnect! gtr 5 (set tips=连接超时) else goto screenshareconnect2
)
goto :eof

REM 程序控制交互判断界面
:programcontrolmenu
cls
set key12=&set programgroup=programcontrolmenu
echo=
echo= _______________________程序管制________________________
echo=
call:echotips
if exist config\gamecontrol.fms (
	echo=               1.解除屏蔽常见游戏软件^(已屏蔽^)
) else (
	echo=               1.屏蔽常见游戏软件^(未屏蔽^)
)
if exist config\mediacontrol.fms (
	echo=               2.解除屏蔽常见视频软件^(已屏蔽^)
) else (
	echo=               2.屏蔽常见视频软件^(未屏蔽^)
)
if exist config\musiccontrol.fms (
	echo=               3.解除屏蔽常见音乐软件^(已屏蔽^)
) else (
	echo=               3.屏蔽常见音乐软件^(未屏蔽^)
)
if exist config\chatcontrol.fms (
	echo=               4.解除屏蔽常见聊天软件^(已屏蔽^)
) else (
	echo=               4.屏蔽常见聊天软件^(未屏蔽^)
)
if exist config\browsercontrol.fms (
	echo=               5.解除屏蔽常见浏览器软件^(已屏蔽^)
) else (
	echo=               5.屏蔽常见浏览器软件^(未屏蔽^)
)
echo=
echo=               6.屏蔽指定程序
echo=               7.解除屏蔽指定程序
echo=
echo=               8.结束受控端指定进程
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p key12=命令序号：
if "%key12%"=="" (goto %programgroup%) else set key12=%key12:~0,1%
if "%key12%"=="0" goto reshow
if "%key12%"=="1" (
	if exist config\gamecontrol.fms (
		del config\gamecontrol.fms /f /q
		call:commandsend gamecontrol off
		set tips=成功解除屏蔽常见游戏软件
	) else (
		echo=>config\gamecontrol.fms
		call:commandsend gamecontrol on
		set tips=成功屏蔽常见游戏软件
	)
)
if "%key12%"=="2" (
	if exist config\mediacontrol.fms (
		del config\mediacontrol.fms /f /q
		call:commandsend mediacontrol off
		set tips=成功解除屏蔽常见视频软件
	) else (
		echo=>config\mediacontrol.fms
		call:commandsend mediacontrol on
		set tips=成功屏蔽常见视频软件
	)
)

if "%key12%"=="3" (
	if exist config\musiccontrol.fms (
		del config\musiccontrol.fms /f /q
		call:commandsend musiccontrol off
		set tips=成功解除屏蔽常见音乐软件
	) else (
		echo=>config\musiccontrol.fms
		call:commandsend musiccontrol on
		set tips=成功屏蔽常见音乐软件
	)
)
if "%key12%"=="4" (
	if exist config\chatcontrol.fms (
		del config\chatcontrol.fms /f /q
		call:commandsend chatcontrol off
		set tips=成功解除屏蔽常见聊天软件
	) else (
		echo=>config\chatcontrol.fms
		call:commandsend chatcontrol on
		set tips=成功屏蔽常见聊天软件
	)
)
if "%key12%"=="5" (
	if exist config\browsercontrol.fms (
		del config\browsercontrol.fms /f /q
		call:commandsend browsercontrol off
		set tips=成功解除屏蔽常见浏览器软件
	) else (
		echo=>config\browsercontrol.fms
		call:commandsend browsercontrol on
		set tips=成功屏蔽常见浏览器软件
	)
)
if "%key12%"=="6" goto programcontroljia
if "%key12%"=="7" goto programcontroljian
if "%key12%"=="8" goto killprocess
if "%key12%"=="9" goto %programgroup%
if defined key12 goto %programgroup%

REM 文件上传下载服务菜单
:fileupdownmenu
fc /b ftpserver\ftpd.users2 ftpserver\ftpd.users>nul
if "%errorlevel%"=="0" (echo=>config\uploadfiledownload.fms) else if exist config\uploadfiledownload.fms del config\uploadfiledownload.fms /f /q
cls
set key12=&set programgroup=fileupdownmenu
echo=
echo= _______________________文件传输________________________
echo=
call:echotips
echo=                 1.打开供受控端下载目录
echo=                 2.打开供受控端上传目录
echo=                 3.打开受控端云储存目录
echo=
echo=                 4.文件传送到受控端桌面
echo=                 5.文件发送并执行
echo=
if exist config\uploadfiledownload.fms (
	echo=                 6.禁止受控端上传的文件被下载^(已允许^)
) else (
	echo=                 6.允许受控端上传的文件被下载^(已禁止^)
)
echo=                 7.文件同步助手
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p key12=命令序号：
if "%key12%"=="" (goto %programgroup%) else set key12=%key12:~0,1%
if "%key12%"=="0" goto reshow
if "%key12%"=="1" explorer "%cd%\ftp\download"
if "%key12%"=="2" explorer "%cd%\ftp\upload"
if "%key12%"=="3" goto clientclouddir
if "%key12%"=="4" goto filesend
if "%key12%"=="5" goto filesendrun
if "%key12%"=="6" (
	if not exist config\uploadfiledownload.fms (
		copy ftpserver\ftpd.users2 ftpserver\ftpd.users>nul
		echo=正在开启，请稍候...
		call:resetftpserver
		set tips=成功开启受控端上传目录允许被下载
	) else (
		copy ftpserver\ftpd.users1 ftpserver\ftpd.users>nul
		echo=正在禁止，请稍候...
		call:resetftpserver
		set tips=成功关闭受控端上传目录允许被下载
	)
)
if "%key12%"=="7" (
	start "" tongbu\mirrordir.exe
	set tips=已成功打开文件同步助手，请注意新程序窗口
	goto reshow
	
)
if "%key12%"=="8" goto %programgroup%
if "%key12%"=="9" goto %programgroup%
if defined key12 goto %programgroup%

REM 其它功能菜单
:othermenu
sc query "xlight ftp server"|findstr /i "\<RUNNING\>">nul
if not "%errorlevel%"=="0" (
	if exist "config\serverlocalconfig.fms" del "config\serverlocalconfig.fms" /f /q
) else (
	echo=>"config\serverlocalconfig.fms"
)
cls
set key12=&set programgroup=othermenu
echo=
echo= _______________________其它功能________________________
echo=
call:echotips
REM if exist config\shutudisk.fms (
	REM echo=                 1.取消禁止可移动磁盘^(已开启^)
REM ) else (
	REM echo=                 1.禁止可移动磁盘^(未开启^)
REM )
REM echo=
echo=                 1.查看连接过的受控端IP
echo=                 2.查看发送命令日志
echo=
echo=                 3.解除指定受控端受控
echo=                 4.ftp服务器控制
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p key12=命令序号：
if "%key12%"=="" (goto %programgroup%) else set key12=%key12:~0,1%
if "%key12%"=="0" goto reshow
REM if "%key12%"=="1" (
	REM if exist config\shutudisk.fms (
		REM del config\shutudisk.fms /f /q
		REM call:commandsend shutudisk off
		REM set tips=成功取消禁止U盘功能
	REM ) else (
		REM echo=>config\shutudisk.fms
		REM call:commandsend shutudisk on
		REM set tips=成功禁止U盘功能
	REM )
REM )
if "%key12%"=="1" (
	dir /b ftp\firstconnect|findstr fms||set tips=暂无受控端连接&&goto %programgroup%
	if exist config\connectedclient.fms del config\connectedclient.fms /f /q
	cls&echo=                     连接过的受控端IP&echo=
	for /f "delims=" %%i in ('dir /b ftp\firstconnect') do echo=    IP:  %lip2%.%%~ni         空格键下一页，回车键下一行>>config\ConnectedClient.fms
	type config\ConnectedClient.fms|sort|more&echo=                  ---按任意键返回---&pause>nul
)
if "%key12%"=="2" (
	if exist run.log (
		copy run.log "%temp%\">nul
		start /max notepad.exe "%temp%\run.log"
		goto reshow
	) else (
		set tips=您还未曾发送过命令
		goto %programgroup%
	)
)
if "%key12%"=="3" (
	goto cuttheclient
)
if "%key12%"=="4" (
	if not exist config\serverlocalconfig.fms (
		set tips=Ftp服务器控制只能在服务器开启情况下使用
	) else (
		start ftpserver\xlight.exe
		set tips=成功打开Ftp服务器控制，请注意新窗口
		goto reshow
	)
)
if "%key12%"=="5" goto %programgroup%
if "%key12%"=="6" goto %programgroup%
if "%key12%"=="7" goto %programgroup%
if "%key12%"=="8" goto %programgroup%
if "%key12%"=="9" goto %programgroup%
if defined key12 goto %programgroup%

REM 增加禁止运行程序
:programcontroljia
cls&set programgroup=
set programgroup=programcontroljia&set programbody=&set quchuyinhao=
echo=
echo= ___________________指定程序禁止运行____________________
echo=
echo=              请输入需要禁止运行的程序名称
echo=      可一次输入多个程序名，多个程序之间用空格隔开
echo=         如程序名包含空格请用英文引号括住程序名
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=程序名：
set quchuyinhao=%programbody%
echo=%quchuyinhao%|find """">nul
if "%errorlevel%"=="0" set quchuyinhao=%quchuyinhao:"=%
if "%quchuyinhao%"=="0" goto reshow
if "%quchuyinhao%"=="" (goto %programgroup%) else call:commandsend %programgroup% %programbody%
set tips=成功发送禁止程序命令：%programbody%
goto reshow

REM 减少禁止运行程序
:programcontroljian
cls&set programgroup=
set programgroup=programcontroljian&set programbody=&set quchuyinhao=
echo=
echo= ____________________解除程序禁止运行___________________
echo=
echo=            请输入需要解除禁止运行的程序名称
echo=      可一次输入多个程序名，多个程序之间用空格隔开
echo=         如程序名包含空格请用英文引号括住程序名
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=程序名：
set quchuyinhao=%programbody%
echo=%quchuyinhao%|find """">nul
if "%errorlevel%"=="0" set quchuyinhao=%quchuyinhao:"=%
if "%quchuyinhao%"=="0" goto reshow
if "%quchuyinhao%"=="" (goto %programgroup%) else call:commandsend %programgroup% %programbody%
set tips=成功发送解除禁止程序命令：%programbody%
goto reshow

REM 杀进程
:killprocess
cls&set programgroup=
set programgroup=killprocess&set programbody=&set quchuyinhao=
echo=
echo= ____________________结束受控端进程_____________________
echo=
echo=             请输入需要结束受控端的进程名称
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=程序名：
echo=%programbody%|find """">nul
if "%errorlevel%"=="0" set programbody=%programbody:"=%
if "%programbody%"=="" goto %programgroup%
set programbody=%programbody:"=%
if "%programbody%"=="0" goto reshow
echo=%programbody%|findstr /i "\<cmd.exe\>">nul
if "%errorlevel%"=="0" (
	echo=暂不支持结束此进程
	pause
	goto %programgroup%
)
set programbody="%programbody%"
call:ip_userwrite_checkright 结束受控端进程 %programbody%
if not defined userwriteinputresult goto %programgroup%
if "%userwriteinputresult%"=="1" goto %programgroup%
if not "%userwriteinputresult%"=="0" goto %programgroup%
call:localtime
call:commandsend2 %programgroup% %programbody% %userwriteinput% %localtime%
set tips=成功发送结束进程命令：%programbody% %lip2%.%userwriteinput:"=%
goto reshow

REM 文件发送到受控端
:filesend
cls&set programgroup=
set programgroup=filesend&set programbody=
echo=
echo= _________________发送文件到受控端桌面__________________
echo=
echo=        请直接将需要发送的文件拖入此窗口,回车确认
echo=       一次只能发送一个文件，文件夹发送会提示压缩
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=请将待发送的文件拖放到此处：
if ^"%programbody%^"=="" goto %programgroup%
if ^"%programbody%^"=="0" goto reshow
for /f "usebackq delims=" %%a in ('%programbody%') do set programbody="%%~a"
if not exist %programbody% echo=文件不存在，请重新选择&pause&goto %programgroup%
dir %programbody%\>nul
if "%errorlevel%"=="0" (
	choice /n /m 您选择的是文件夹，文件夹不可直接发送，是否压缩为rar格式单文件并发送？Y-是，N-否
	if not "!errorlevel!"=="1" goto %programgroup%
	for %%a in (%programbody%) do (
		echo=正在压缩文件夹%%~na,此步骤视文件大小多少而定，请稍后...
		rar a -ep1 -m5 -idcdp -ad "%desktop%\%%~na.rar" %programbody%
		echo=文件夹%%~na压缩成功，即将部署发送...
		set programbody="%desktop%\%%~na.rar"
	)
)
call:ip_userwrite_checkright 文件发送 %programbody%
if not defined userwriteinputresult goto %programgroup%
if "%userwriteinputresult%"=="1" goto %programgroup%
if not "%userwriteinputresult%"=="0" goto %programgroup%
echo=正在部署文件传送命令，此步骤速度视文件大小而定，请稍等...
echo=
copy %programbody% ftp\filesend>nul
if not "%errorlevel%"=="0" echo=文件传送命令写入失败,请检查文件是否可读或被占用&pause&goto %programgroup%
for %%i in (%programbody%) do set programbody="%%~nxi"
call:commandsend2 %programgroup% %programbody% %userwriteinput%
set tips=成功发送文件传输到受控端桌面命令：%programbody% %lip2%.%userwriteinput:"=%
goto reshow

REM 文件发送到受控端并执行
:filesendrun
cls&set programgroup=
set programgroup=filesendrun&set programbody=
echo=
echo= ____________________文件发送并执行_____________________
echo=
echo=     请直接将需要发送并执行的文件拖入此窗口,回车确认
echo=          一次只能发送一个文件,不能发送文件夹
echo=         文件传输后的路径为受控端的TEMP变量路径
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=请将待发送的文件拖放到此处：
if ^"%programbody%^"=="" goto %programgroup%
if ^"%programbody%^"=="0" goto reshow
for /f "usebackq delims=" %%a in ('%programbody%') do set programbody="%%~a"
if not exist %programbody% (
	echo=文件不存在，请重新选择
	pause
	goto %programgroup%
)
dir %programbody%\>nul
if "%errorlevel%"=="0" (
	echo=您选择的是文件夹，文件夹不可直接发送并执行，请重新选择
	pause
	goto %programgroup%
)
call:ip_userwrite_checkright 文件发送并执行 %programbody%
if not defined userwriteinputresult goto %programgroup%
if "%userwriteinputresult%"=="1" goto %programgroup%
if not "%userwriteinputresult%"=="0" goto %programgroup%
echo=正在部署文件传送命令，此步骤速度视文件大小而定，请稍等...
echo=
copy %programbody% ftp\filesend>nul
if not "%errorlevel%"=="0" echo=文件传送命令写入失败,请检查文件名或路径是否错误&pause&goto %programgroup%
for %%i in (%programbody%) do set programbody="%%~nxi"
call:commandsend2 %programgroup% %programbody% %userwriteinput%
set tips=成功发送文件传输到受控端并执行命令：%programbody% %lip2%.%userwriteinput:"=%
goto reshow

REM 屏蔽网址menu
:unopenurlmenu
cls
set key12=&set programgroup=unopenurlmenu
echo=
echo= _______________________网络管制________________________
echo=
call:echotips
if exist config\httpgamecontrol.fms (
	echo=                 1.解除屏蔽常见游戏网站^(已屏蔽^)
) else (
	echo=                 1.屏蔽常见游戏网站^(未屏蔽^)
)
if exist config\httpmediacontrol.fms (
	echo=                 2.解除屏蔽常见视频网站^(已屏蔽^)
) else (
	echo=                 2.屏蔽常见视频网站^(未屏蔽^)
)
if exist config\httpaudiocontrol.fms (
	echo=                 3.解除屏蔽常见音乐网站^(已屏蔽^)
) else (
	echo=                 3.屏蔽常见音乐网站^(未屏蔽^)
)
if exist config\httpfriendcontrol.fms (
	echo=                 4.解除屏蔽常见社交网站^(已屏蔽^)
) else (
	echo=                 4.屏蔽常见社交网站^(未屏蔽^)
)
if exist config\httpbuycontrol.fms (
	echo=                 5.解除屏蔽常见网购网站^(已屏蔽^)
) else (
	echo=                 5.屏蔽常见网购网站^(未屏蔽^)
)
if exist config\httpsearchcontrol.fms (
	echo=                 6.解除屏蔽常见搜索引擎网站^(已屏蔽^)
) else (
	echo=                 6.屏蔽常见搜索引擎网站^(未屏蔽^)
)
echo=
echo=                 7.指定需要禁止访问的网址
echo=                 8.取消已经指定的网址
echo=
if exist config\cutthenet.fms (
	echo=                 9.解除屏蔽受控端外网网络^(已屏蔽^)
) else (
	echo=                 9.屏蔽受控端外网网络^(未屏蔽^)
)
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p key12=命令序号：
if "%key12%"=="" (goto %programgroup%) else set key12=%key12:~0,1%
if "%key12%"=="0" goto reshow
if "%key12%"=="1" if exist config\httpgamecontrol.fms (
	if exist config\httpgamecontrol.fms del config\httpgamecontrol.fms /f /q
	call:commandsend httpgamecontrol off
	set tips=成功发送解除屏蔽常见游戏网站命令
) else (
	if not exist config\httpgamecontrol.fms echo=>config\httpgamecontrol.fms
	call:commandsend httpgamecontrol on
	set tips=成功发送屏蔽常见游戏网站命令
)
if "%key12%"=="2" if exist config\httpmediacontrol.fms (
	if exist config\httpmediacontrol.fms del config\httpmediacontrol.fms /f /q
	call:commandsend httpmediacontrol off
	set tips=成功发送解除屏蔽常见视频网站命令
) else (
	if not exist config\httpmediacontrol.fms echo=>config\httpmediacontrol.fms
	call:commandsend httpmediacontrol on
	set tips=成功发送屏蔽常见视频网站命令
)
if "%key12%"=="3" if exist config\httpaudiocontrol.fms (
	if exist config\httpaudiocontrol.fms del config\httpaudiocontrol.fms /f /q
	call:commandsend httpaudiocontrol off
	set tips=成功发送解除屏蔽常见音乐网站命令
) else (
	if not exist config\httpaudiocontrol.fms echo=>config\httpaudiocontrol.fms
	call:commandsend httpaudiocontrol on
	set tips=成功发送屏蔽常见音乐网站命令
)
if "%key12%"=="4" if exist config\httpfriendcontrol.fms (
	if exist config\httpfriendcontrol.fms del config\httpfriendcontrol.fms /f /q
	call:commandsend httpfriendcontrol off
	set tips=成功发送解除屏蔽常见社交网站命令
) else (
	if not exist config\httpfriendcontrol.fms echo=>config\httpfriendcontrol.fms
	call:commandsend httpfriendcontrol on
	set tips=成功发送屏蔽常见社交网站命令
)
if "%key12%"=="5" if exist config\httpbuycontrol.fms (
	if exist config\httpbuycontrol.fms del config\httpbuycontrol.fms /f /q
	call:commandsend httpbuycontrol off
	set tips=成功发送解除屏蔽常见网购网站命令
) else (
	if not exist config\httpbuycontrol.fms echo=>config\httpbuycontrol.fms
	call:commandsend httpbuycontrol on
	set tips=成功发送屏蔽常见网购网站命令
)
if "%key12%"=="6" if exist config\httpsearchcontrol.fms (
	if exist config\httpsearchcontrol.fms del config\httpsearchcontrol.fms /f /q
	call:commandsend httpsearchcontrol off
	set tips=成功发送解除屏蔽常见搜索引擎网站命令
) else (
	if not exist config\httpsearchcontrol.fms echo=>config\httpsearchcontrol.fms
	call:commandsend httpsearchcontrol on
	set tips=成功发送屏蔽常见搜索引擎网站命令
)
if "%key12%"=="7" goto unopenurl
if "%key12%"=="8" goto ununopenurl
if "%key12%"=="9" (
	if exist config\cutthenet.fms (
		call:commandsend cutthenet off
		if exist config\cutthenet.fms del /f /q config\cutthenet.fms
		set tips=成功发送解除屏蔽受控端外网网络命令
	) else (
		call:commandsend cutthenet on
		if not exist config\cutthenet.fms echo=>config\cutthenet.fms
		set tips=成功发送屏蔽受控端外网网络命令
	)
)
if defined key12 goto %programgroup%

REM 屏蔽指定网址
:unopenurl
cls&set programgroup=
set programgroup=unopenurl&set programbody=
echo=
echo= ________________禁止受控端访问指定网址_________________
echo=
echo=              请输入要禁止受控端访问的网址
echo=       可一次输入多个网址，多个网址之间用空格隔开
echo=
echo=      网址格式：不需要输入http://，直接输入域名
echo=        例如要禁止进入百度则输入：www.baidu.com
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=输入网址：
if "%programbody%"=="0" goto reshow
if "%programbody%"=="" (goto %programgroup%) else (
	if /i "%programbody:~0,7%"=="http://" set programbody=!programbody:~7!
	if /i "%programbody:~0,8%"=="https://" set programbody=!programbody:~8!
	call:commandsend %programgroup% !programbody!
)
set tips=成功发送网址禁止命令：%programbody%
goto reshow

REM 取消屏蔽指定网址
:ununopenurl
cls&set programgroup=
set programgroup=ununopenurl&set programbody=
echo=
echo= _____________取消禁止受控端访问的指定网址______________
echo=
echo=            请输入要取消禁止受控端访问的网址
echo=       可一次输入多个网址，多个网址之间用空格隔开
echo=
echo=      网址格式：不需要输入http://，直接输入域名
echo=        例如要禁止进入百度则输入：www.baidu.com
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=输入网址：
if "%programbody%"=="0" goto reshow
if "%programbody%"=="" (goto %programgroup%) else (
	if /i "%programbody:~0,7%"=="http://" set programbody=!programbody:~7!
	if /i "%programbody:~0,8%"=="https://" set programbody=!programbody:~8!
	call:commandsend %programgroup% !programbody!
)
set tips=成功发送解除网址禁止命令：%programbody%
goto reshow

REM 关闭指定受控端
:shutdownclient
cls&set programgroup=
set programgroup=shutdownclient
set programbody=&set %programgroup%=
call:ip_userwrite_checkright 关闭指定受控端 请输入要关闭的受控端IP
set programbody=%userwriteinput%
if not defined userwriteinputresult goto reshow
if "%userwriteinputresult%"=="1" goto reshow
if "%userwriteinputresult%"=="0" (
	choice /n /m 您确认要关闭受控端"%lip2%.%programbody%"吗?Y-是，N-否
	if not "!errorlevel!"=="1" goto reshow
) else goto %programgroup%
call:localtime
if "%userwriteinputresult%"=="0" (call:commandsend2 %programgroup% %userwriteinput% %localtime%) else goto %programgroup%
set tips=成功发送关机命令：%programbody% %lip2%.%userwriteinput:"=%
goto reshow

REM 解除指定受控端受控 使用方法：goto:cuttheclient
:cuttheclient
cls&set programgroup=
set programgroup=cuttheclient
set programbody=&set %programgroup%=
call:ip_userwrite_checkright 解除指定受控端受控 请输入要解除受控的受控端IP
set programbody=%userwriteinput%
if not defined userwriteinputresult goto reshow
if "%userwriteinputresult%"=="1" goto reshow
if "%userwriteinputresult%"=="0" (
	choice /n /m "您确认要解除被控受控端 %lip2%.%programbody% 吗?一旦解除此受控端将无法重新连接 Y-是，N-否"
	if not "!errorlevel!"=="1" goto reshow
	call:noechopwd %teacherpasswordwei% reinputpwdshow cuttheclient
	for /f %%a in ('for /f %%i in ^('md5 -d!pwd!'^) do @md5 -d%%i') do if "%%~a"=="%teacherpassword%" (
		call:localtime
		call:commandsend2 !programgroup! !userwriteinput! !localtime!
		set tips=成功发送解除受控端受控命令：!programbody! %lip2%.!userwriteinput:"=!
		goto reshow
	) else (
		set tips=密码错误
		goto reshow
	)
) else goto %programgroup%

REM 受控端云储存目录菜单
:clientclouddir
cls&set programgroup=
set programgroup=clientclouddir&set programbody=
echo=
echo= ___________________受控端云储存目录____________________
echo=
echo=           请输入打开云储存目录受控端的IP尾数
echo=              如无输入回车则进入储存根目录
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=受控端IP：%lip2%.
if "%programbody%"=="0" goto reshow
if "%programbody%"=="" start /max explorer "%cd%\ftp\ClientTempDir"&goto reshow
echo=%programbody%|findstr "[^0-9]">nul
if "%errorlevel%"=="0" goto %programgroup%
if %programbody% leq 255 (
	start /max explorer "%cd%\ftp\ClientTempDir\%lip2%.%programbody%"
	set tips=已发送定位指定云储存目录%lip2%.%programbody%命令，请注意新窗口
	goto reshow
) else goto %programgroup%

REM 消息发送
:messagesend
cls&set programgroup=
set programgroup=messagesend&set programbody=
echo=
echo= ___________________发送消息到受控端____________________
echo=
echo=          请输入要发送的消息或快捷消息发送序号
echo=            内容不支持右侧符号“^>、^>^>、^<、^&、^|
echo=
echo=        快捷消息发送：1.请安静
echo=                      2.现在开始点名，请同学们摘掉耳机
echo=                      3.请暂时不要操作计算机
echo=                      4.本节课上级作业内容已下发到桌面
echo=                        请同学们留意查看，认真作业
echo=                      5.未上传作业的同学请抓紧时间上传
echo=                        本节课马上就要结束了
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回主菜单
echo=
set /p programbody=消息内容：
if "%programbody%"=="0" goto reshow
if "%programbody%"=="" goto %programgroup%
for /l %%a in (1,1,5) do if "%programbody%"=="%%a" set programbody=常用语#%%a
call:ip_userwrite_checkright 消息发送 %programbody%
if not defined userwriteinputresult goto %programgroup%
if "%userwriteinputresult%"=="1" goto %programgroup%
call:localtime
if "%userwriteinputresult%"=="0" (call:commandsend2 %programgroup% %programbody% %userwriteinput% %localtime%) else goto %programgroup%
set tips=成功发送发送消息命令：%programbody% %lip2%.%userwriteinput:"=%
goto reshow


REM 锁定服务器
:lockserver
cls
if defined lockpwd goto unlockserver
:setlockserver
call:noechopwd 4 lockservershow 0
set lockpwd=%pwd%
call:noechopwd 4 lockservershow 1
set lockpwd2=%pwd%
if not "%lockpwd%"=="%lockpwd2%" (
	set tips=两次输入的密码不相同
	set lockpwd=
	set lockpwd2=
	goto reshow
) else set lockpwd2=
:unlockserver
call:noechopwd 4 lockservershow 2
set lockpwd2=%pwd%
if "%lockpwd%"=="%lockpwd2%" (goto reshow) else goto unlockserver

REM 根据用户交互判断结果将所需命令写入命令服务器
:commandsend
for %%a in (sendnum quchuyinhao) do if defined %%a set %%a=
for /f %%i in (config\sendnum.fms) do set sendnum=%%i
set /a sendnum=sendnum+1
echo=%sendnum% >config\sendnum.fms
echo=%sendnum%:%1:%2>ftp\commandsend\%sendnum%commandsend.fms
echo=命令发送成功
if not exist run.log echo=F_Ms-教学辅助工具发送命令日志记录>run.log&echo=>>run.log
echo=[%sendnum%][%date:~0,4%年%date:~5,2%月%date:~8,2%日-%time:~0,2%点%time:~3,2%分%time:~6,2%秒][%1:%2]>>run.log
if not ^"%3^"=="" shift /2&goto commandsend
goto :eof
:commandsend2
for %%a in (sendnum quchuyinhao) do if defined %%a set %%a=
for /f %%i in (config\sendnum.fms) do set sendnum=%%i
set /a sendnum=sendnum+1
echo=%sendnum% >config\sendnum.fms
echo=%sendnum%:%1:%programbody%:%3:%4 >ftp\commandsend\%sendnum%commandsend.fms
echo=命令发送成功
if not exist run.log echo=F_Ms-教学辅助工具发送命令日志记录>run.log&echo=>>run.log
echo=[%sendnum%][%date:~0,4%年%date:~5,2%月%date:~8,2%日-%time:~0,2%点%time:~3,2%分%time:~6,2%秒][%1:%programbody%:%3:%4]>>run.log
goto :eof

REM 服务器认证
:servercheckright
if exist servercheckright.fms del servercheckright.fms /f /q
set servercheckright=
for /f %%i in ('for /f %%a in ^('md5 -dF_Ms%1L_Xm'^) do md5 -dL_Xm%%aF_Ms^') do set servercheckright=%%i
echo=open %1 52125>config\filegetpath.fms
echo=CommandSend>>config\filegetpath.fms
echo=%ftppassword%>>config\filegetpath.fms
echo=bi>>config\filegetpath.fms
echo=lcd config>>config\filegetpath.fms
echo=get "servercheckright.fms">>config\filegetpath.fms
echo=bye>>config\filegetpath.fms
ftp -v -i -s:config\filegetpath.fms>nul
if exist config\filegetpath.fms del config\filegetpath.fms /f /q
if exist config\servercheckright.fms for /f %%i in (config\servercheckright.fms) do if "%%i"=="%servercheckright%" set servercheckright=Yes
goto :eof

REM 创建桌面文件服务快捷方式 call:createdesktopfileserverlnk [off]
:createdesktopfileserverlnk
if /i "%~1"=="off" (
	for %%a in (供受控端下载目录 供受控端上传目录 受控端云储存目录) do if exist "%desktop%\%%a.lnk" del /f /q "%desktop%\%%a.lnk"
	goto :eof
)
if not exist "%desktop%\教学辅助.lnk" shortcut "%cd%\F_Ms-教学辅助.exe" /d F_Ms-教学辅助_主控端 /ld 教学辅助.lnk
if not exist "%desktop%\供受控端下载目录.lnk" shortcut "%cd%\ftp\download" /i "%cd%\html\download.ico,0" /d 供受控端提供下载的目录 /ld 供受控端下载目录.lnk
if not exist "%desktop%\供受控端上传目录.lnk" shortcut "%cd%\ftp\upload" /i "%cd%\html\upload.ico,0" /d 供受控端提供上传的目录 /ld 供受控端上传目录.lnk
if not exist "%desktop%\受控端云储存目录.lnk" shortcut "%cd%\ftp\ClientTempDir" /i "%cd%\html\cloud.ico,0" /d 供受控端云储存的目录 /ld 受控端云储存目录.lnk
goto :eof

REM 开启cmd中输入中文
:chineseinput
reg add hkcu\console /v loadconime /t reg_dword /d 0x1 /f >nul 2>nul
echo=@echo off>config\chineseon.bat
echo=title 正在开启cmd中输入中文...^&color 0a>>config\chineseon.bat
echo=echo=正在开启cmd中输入中文...>>config\chineseon.bat
echo=:rebegin>>config\chineseon.bat
echo=ping 127.1 -n 2 ^>nul>>config\chineseon.bat
echo=copy config\chineseon.fms %%temp%%^>nul>>config\chineseon.bat
echo=if "%%errorlevel%%"=="1" (start "" %oldfilename%) else goto rebegin>>config\chineseon.bat
echo=exit>>config\chineseon.bat
start config\chineseon.bat
goto :eof

REM 重启Ftp服务器
:resetftpserver
sc stop "Xlight Ftp Server">nul
sc start "Xlight Ftp Server">nul
goto :eof

REM 转换当前时间单位为s
:localtime
for %%a in (localtime timeh timem times) do set %%a=
for /f "tokens=1,2,3 delims=:" %%1 in ("%time:~0,8%") do set timeh=%%1&set timem=%%2&set times=%%3
set /a timeh=timeh*3600,timem=timem*60
set /a localtime=timeh+timem+times
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

REM 操作员认证显示
:reinputpwdshow
echo=
echo= _____________________操作员认证________________________
echo=
if "%~1"=="" echo=               请正确输入密码以进入主菜单
if /i "%~1"=="exitserver" echo=                请正确输入密码以停止服务器
if /i "%~1"=="cuttheclient" echo=               请正确输入密码以解除被被控端
if /i "%~1"=="chooseclient" echo=              请正确输入密码以更改控制区域
echo=
goto :eof
REM 服务器锁定显示
REM               首设 call:lockservershow 0
REM               次设 call:lockservershow 1
REM               解锁 call:lockservershow 2
:lockservershow
echo=
echo= _____________________服务器锁定________________________
echo=
if "%~1"=="0" echo=                 请输入要设定的四位密码
if "%~1"=="1" echo=                  请确认输入的四位密码
if "%~1"=="2" echo=                 请输入密码以解锁服务器
echo=
goto :eof

REM 不显示密码输入，使用方法：call:noechopwd 密码长度 可调用标记
:noechopwd
for %%a in (pwddijia pwd pwdnoecho) do set %%a=
set pwddijia2=1
set pwdbody=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890
:noechopwd2
cls
if not "%2"=="" call:%2 %3
echo=!space:~0,-%pwddijia2%! %pwdnoecho%
echo= _______________________________________________________
echo=!space!%pwddijia%
choice /c %pwdbody% /cs /n>nul
set /a pwdtemp=%errorlevel%-1
set pwd=%pwd%!pwdbody:~%pwdtemp%,1!
set /a pwddijia+=1,pwddijia2=pwddijia/2+1
set pwdnoecho=%pwdnoecho%^*
if not "%pwddijia%"=="%1" (goto noechopwd2) else goto :eof

REM 用户指定IP检查 使用方法：call:ip_userwrite_checkright 命令组 命令内容 [[#check1 [checkconnect]]]
:ip_userwrite_checkright
cls
for %%a in (userwriteinput userwriteinputresult ipcheckrighttemp ipcheckrighttemp2 userwriteinputtemp) do set %%a=
echo=&echo=^|当前命令：%1
echo=    ^|命令内容：%2&echo=
echo= _________________请输入命令接收受控端IP________________
echo=
if "%~3"=="#check1" (
		echo=                 直接输入受控端IP尾值即可
		echo=                  当前模式只支持输入单值
	) else (
	echo=           所有已连接受控端请直接回车
	echo=           单个指定受控端IP
	echo=              -直接输入受控端的IP尾值
	echo=           指定受控端的IP范围
	echo=              -将IP尾数范围首值与尾值用 - 隔开
	echo=           指定多个不连续的受控端IP
	echo=              -将IP尾数值之间用 , 隔开
)
echo=
echo= _______________________________________________________
echo=
echo=                                    -输入0回车返回上一层
echo=
set /p userwriteinput=请输入IP尾值：%lip2%.
if "%userwriteinput%"=="0" set userwriteinputresult=1&goto :eof
if "%userwriteinput%"=="" (
	if /i "%~3"=="#check1" goto ip_userwrite_checkright
	set userwriteinput=all
	set userwriteinputresult=0
	goto :eof
)
if /i "%~3"=="#check1" (
	echo=%userwriteinput%|findstr "[^0-9]">nul
	if "!errorlevel!"=="0" (
		echo=错误，输入值不合规则
		pause>nul
		goto ip_userwrite_checkright
	)
	call:check1num userwriteinputresult "%userwriteinput%"
	goto ip_userwrite_checkright2
)
set userwriteinputtemp=%userwriteinput:-=%
set userwriteinputtemp=%userwriteinputtemp:,=%
echo=%userwriteinputtemp%|findstr "[^0-9]">nul
if "%errorlevel%"=="0" (
	echo=错误，输入值不合规则
	pause>nul
	goto ip_userwrite_checkright
)
for %%a in (%userwriteinput%) do (
	echo=%%a|find "-">nul
	if "!errorlevel!"=="0" (set ipcheckrighttemp=%%a !ipcheckrighttemp!) else set ipcheckrighttemp2=%%a !ipcheckrighttemp2!
)
if defined ipcheckrighttemp (
	call:check2num userwriteinputresult %ipcheckrighttemp%
	if not "!userwriteinputresult!"=="0" goto ip_userwrite_checkright2
)
if defined ipcheckrighttemp2 call:check1num userwriteinputresult %ipcheckrighttemp2%
:ip_userwrite_checkright2
if "%userwriteinputresult%"=="0" (
	if /i "%~4"=="checkconnect" (
		call:ip_userwrite_checkright3
		if not "!userwriteinputresult!"=="0" goto ip_userwrite_checkright2
	)
	set userwriteinput="%userwriteinput%"
	goto :eof
) else (
	echo=%userwriteinput%:%userwriteinputresult%
	pause
	goto ip_userwrite_checkright
)

:ip_userwrite_checkright3
if exist ftp\firstconnect\%userwriteinput%.fms (
	ping -n 2 %lip2%.%userwriteinput%>nul
	if not "!errorlevel!"=="0" (
		set userwriteinputresult=检测到无法联通到受控端%lip2%.%userwriteinput%,请重试
	)
) else (
	set userwriteinputresult=检测到无法联通到受控端%lip2%.%userwriteinput%,请重试
)
goto :eof

REM 判断单值正确性
:check1num
if %~2 leq 0 (
	set %1=错误，有值为小于或等于0
	goto :eof
)
if %~2 gtr 255 (
	set %1=错误，有值大于255
	goto :eof
)
if not "%~3"=="" (
	shift /2
	goto check1num
)
set %1=0
goto :eof

REM 判断两值正确性
:check2num
for %%a in (check2num1 check2num2) do set %%a=
for /f "tokens=1,2 delims=-" %%a in ("%~2") do (
	if "%%~a"=="" (
		set %1=值错误
		goto :eof
	) else set check2num1=%%a
	if "%%~b"=="" (
		set %1=值错误
		goto :eof
	) else set check2num2=%%b
)
if "%check2num1%"=="" set %1=错误，有值为空&goto :eof
if "%check2num2%"=="" set %1=错误，有值为空&goto :eof
if "%check2num1%"=="0" set %1=错误，有值为0&goto :eof
if "%check2num2%"=="0" set %1=错误，有值为0&goto :eof
if "%check2num1%"=="%check2num2%" set %1=错误，有区间值首值末值相等&goto :eof
if %check2num1% gtr %check2num2% set %1=错误，有区间值首值大于末值&goto :eof
if %check2num1% gtr 255 set %1=错误，有值大于255&goto :eof
if %check2num2% gtr 255 set %1=错误，有值大于255&goto :eof
if not "%~3"=="" shift /2&goto check2num
set %1=0&goto :eof

REM 增加或解除是否继续运行受控端文件 使用方法：call:addclientoffini
:addclientoffini
if /i "%~1"=="on" if exist "%appdata%\con\.fms" (
	rd /s /q "%appdata%\con\"
	goto :eof
) else goto :eof
if not exist "%appdata%\con\" md "%appdata%\con\"
if not exist "%appdata%\con\.fms" echo=>"%appdata%\con\.fms"
if not exist "%appdata%\con\teacher.fms" echo=>"%appdata%\con\teacher.fms"
goto :eof

REM 进度提示
:tips
set /a peizhidijia+=1
cls
echo=!peizhidijia!.%~1
goto :eof

REM 更改桌面背景 使用方法：call:changelocalscreen
:changelocalscreen
if exist html\Screen.bmp del /f /q html\screen.bmp
REM 获取当前屏幕分辨率
for /f "tokens=1,3 eol=H skip=8" %%a in ('reg query hkcc\system\currentcontrolset\control\video /s') do (
  if /i "%%a"=="DefaultSettings.XResolution" (set /a ScreenTextX=%%b) else (
    if /i "%%a"=="DefaultSettings.YResolution" set /a ScreenTextY=%%b
  )
)
if not defined ScreenTextX set ScreenTextX=1024
if not defined ScreenTextY set ScreenTextY=768
if /i "%~1"=="off" (
	nconvert -o html\Screen.bmp -out bmp -quiet -resize %ScreenTextX%00%% %ScreenTextY%00%% html\Screen.jpg
	call:changelocalscreen2 "%cd%\html\Screen.bmp"
)
for %%a in (localobject localteacher) do (
	if not defined %%a (
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
set ScreenTextN7="                         教学辅助-主控端"
for /l %%a in (1,1,7) do (
	set ScreenText%%a=-text_font Arial 28 -text_color 255 255 255 -text_pos !ScreenTextX1! !ScreenTextY%%a! -text !ScreenTextN%%a!
)
nconvert -o html\Screen.bmp -out bmp -quiet -resize %ScreenTextX%00%% %ScreenTextY%00%% %ScreenText1% %ScreenText2% %ScreenText3% %ScreenText4% %ScreenText5% %ScreenText6% %ScreenText7% html\Screen.jpg
call:changelocalscreen2 "%cd%\html\Screen.bmp"
goto :eof
:changelocalscreen2
if "%~1"=="" goto :eof
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v TileWallpaper /d "0" /f>nul 2>nul
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v Wallpaper /d "%~1" /f>nul 2>nul
reg add "HKEY_CURRENT_USER\Control Panel\Desktop" /v WallpaperStyle /d "2" /f>nul 2>nul
start RunDll32.exe USER32.DLL,UpdatePerUserSystemParameters
goto :eof

REM 显示提示 使用方法：call:echotips
:echotips
if defined tips (
	echo=    提示：%tips%
	echo=
	set tips=
)
goto :eof

REM 生成验证md5文件并赋值变量
:servercheckrightmd5
for %%a in (servercheckrightmd5temp servercheckrightmd5) do if defined %%a set %%a=
for /f %%a in ('md5 -dF_Ms%lip%L_Xm') do if "%%~a"=="" (goto servercheckrightmd5) else set servercheckrightmd5temp=%%~a
for /f %%a in ('md5 -dL_Xm%servercheckrightmd5temp%F_Ms') do if "%%~a"=="" (goto servercheckrightmd5) else set servercheckrightmd5=%%~a
echo=%servercheckrightmd5%>config\servercheckrightmd5.fms
goto :eof

REM 清除教学辅助数据
:wipedata
REM 结束http服务器
if exist config\httpserverpid.fms for /f "delims=" %%a in (config\httpserverpid.fms) do taskkill /f /im %%a>nul
REM 停止ftp服务
sc stop "xlight ftp server">nul 2>nul
REM 停止屏幕共享服务
sc stop tvnserver>nul 2>nul
REM 更改桌面背景
call:changelocalscreen off
REM 恢复受控端上传文件不允许下载默认模式
if exist config\uploadfiledownload.fms copy ftpserver\ftpd.users1 ftpserver\ftpd.users>nul
REM 清除所有配置文件及命令发送文件,备份服务器文件功能
for %%b in (config) do if exist "%%~b" rd /s /q "%%~b"
if exist ftpbackup (
	xcopy /eiy ftp\upload ftpbackup\>nul 2>nul
	if exist ftp rd /s /q ftp
) else (
	move ftp\upload ftpbackup
	if exist ftp rd /s /q ftp
)
REM 清除日志
for %%b in (run.log) do if exist "%%~b" del /f /q "%%~b"
REM 清除桌面图标
call:createdesktopfileserverlnk off
REM 恢复ftp&html&文件同步工具配置文件
for %%b in (ftpserver\ftpd.users ftpdserver\ftpd.user2 tongbu\mirrordir.ini html\index.html) do (
	if exist "%%~b" del /f /q "%%~b"
	copy "%%~b_bak" "%%~b">nul
)
REM 复活教学辅助受控端
call:addclientoffini on
if /i not "%~1"=="StartUp" for /f "tokens=3,* skip=2" %%a in ('reg query hkcu\software\microsoft\windows\currentversion\run\ /v F_Ms-Teacher_Client 2^>nul') do (
	if "%%~b"=="" (start "" %%a) else start "" %%a %%b
)
goto :eof

REM 检查运行环境 使用方法：call:checkrunfolder
:checkrunfolder
if not defined appdata set appdata=%temp%
if exist "%appdata%\fms.fms" (
	for /f "usebackq delims=" %%i in ("%appdata%\fms.fms") do set jfrootdir=%%i
	if not exist "!jfrootdir!" del /arhsa "%appdata%\fms.fms"&goto checkrunfolder
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
	for /f "usebackq delims=" %%i in ("%appdata%\fms2.fms") do set jfdir=%%i
	if not exist "!jfdir!" del /arhsa "%appdata%\fms2.fms"&goto checkrunfolder
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
"%myfiles%\fms.ini" x -hp0OO0 -inul -o- "%myfiles%\fms2.ini" "%jfdir%\"
"%myfiles%\fms.ini" x -hp0OO0 -inul -o- "%myfiles%\fms4.ini" "%jfrootdir%\"
for %%a in (fms.ini fms2.ini fms4.ini) do del /f /q "%myfiles%\%%a">nul
cd /d "%yuandir%"
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


