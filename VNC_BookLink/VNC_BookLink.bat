@echo off
cd /d "%~dp0"
color 0a
setlocal ENABLEDELAYEDEXPANSION
REM 设定版本及更新信息
set project=VNC_BookLink
set version=20160114
set workViewerAppUrl=http://imfms.vicp.net/VNC_BookLink-UltraVNC_Viewer.exe
set workWindowManageAppUrl=http://imfms.vicp.net/cmdow.exe
set workResolutionGetAppUrl=http://imfms.vicp.net/scrnres.exe

REM 设置标题
title VNC_BookLink VNC通讯录连接工具 - F_Ms_%version%

REM 设定全局基本变量
set workDir=#VNC_BookLink
set workBook=%workDir%\%workDir%_Book.ini
set workConnectConfig=%workDir%\%workDir%.ini
set workViewerApp=%workDir%\UltraVNC_Viewer.exe
set workWindowManageApp=%workDir%\cmdow.exe
set workResolutionGetApp=%workDir%\scrnres.exe
set workConfig=%workDir%\%workDir%_ConncetConfig.ini

REM 检查工作目录及配置文件
for %%a in (userInput) do set %%a=
if not exist "%workDir%\" md "%workDir%\"
if not exist "%workBook%" (if a==b echo=创建空文件)>"%workBook%"
set userInput=
if not exist "%workViewerApp%" (
	set /p userInput=#连接程序UltraVNC_Viewer.exe不存在，输入 Y 下载，输入其它则跳过：
	if defined userInput (
		if /i "!userInput!"=="y" (
			echo=#正在下载:
			echo=	下载方法是调用VBS脚本，可能会被报毒,信任即可
			echo=	程序为从UltraVNC官网下载的1.2.0.9_x86版本
			echo=	此版本会被报毒,具体原因不明,作者使用未发现异常
			echo=	如不放心可到UltraVNC官网自行下载此版本
			call:DownloadNetFile "%workViewerAppUrl%" "%workViewerApp%"
			if "!errorlevel!"=="0" (
				set tips=调用主程序下载成功
			) else (
				echo=#下载失败,请检查网络
				ping -n 3 127.1>nul 2>nul
				set tips=调用主程序下载失败,请检查网络
			)
		)
	)
)
if not exist "%workConfig%" (
	echo=;可在此设置VNC_Viewer连接参数
	echo=;如想要连接时全屏直接在下一行添加 /fullscreen 即可
	echo=;具体配置参数可查看弹出的VNC_Viewer帮助窗口
	echo=;注意:无需输入域名和密码参数
	echo=;只有非;开头的一行内容有效,请将所有参数直接写入到下一行
)>"%workConfig%"
for /f "usebackq" %%a in ("%workConfig%") do (
	set workVNC_Config=%%a
	goto DefinedClient
)
set workVNC_Config=
REM 进入主菜单
:DefinedClient
cls
echo=
if defined tips (
	echo=#VNC客户端通讯录 ^| 提示：%tips%
	set tips=
) else echo=#VNC客户端通讯录

REM 检查是否已有客户端
for /f "usebackq" %%a in ("%workBook%") do goto DefinedClient2
echo=
echo=	检测到通讯录客户端为空，试着添加一个吧
call:AddClient2Book
goto DefinedClient

:DefinedClient2
REM 显示通讯录客户端
for %%a in (definedClientEchoDijia definedClientInput) do set %%a=
echo=____________________________^|UVNC-Viewer,cmdow,scrnres
echo=
echo=#序列	名称		地址			备注
for /f "usebackq tokens=1-3,5 delims=	" %%a in ("%workBook%") do (
	set /a definedClientEchoDijia+=1
	echo=  !definedClientEchoDijia!	%%a	%%b:%%c	%%d
)
echo=______________________________________________________
echo=  作者：F_Ms ^| 邮箱：imf_ms@yeah.net ^| 博客：f-ms.cn

REM 帮助
if defined help (
	echo=
	echo=#帮助：输入客户端序列号 = 进入客户端详情
	echo=       输入客户端序列号+空格 = 直接连接客户端
	echo=       输入 A = 添加新的客户端到通讯录
	echo=       输入 C = 配置UltraVNC-Viewer连接参数
	echo=       输入 W = 屏幕墙功能
	echo=               ^(该功能使用了Ritchie Lawrence的cmdow窗口控制命令行工具
	echo=                和Frank P. Westlake的scrnres屏幕分辨率获取工具^)
	echo=           屏幕墙指定客户端可使用单数分隔符 , 和 区间数分隔符 -
	echo=               例子:将序列1,2,3,5,7,8,9代表的客户端加入到屏幕墙并显示
	echo=                   1-3,5,7-9 
	set help=
) else echo=

REM 提示用户输入命令
set /p definedClientInput=#请输入命令:
if not defined definedClientInput (
	set help=yes
	goto DefinedClient
)
	REM 添加客户端
if /i "%definedClientInput: =%"=="A" (
	call:AddClient2Book
	goto DefinedClient
)
	REM 配置UltraVNC-Viewer连接参数
if /i "%definedClientInput: =%"=="C" (
	start "" "%workViewerApp%" /?
	start /wait "" notepad "%workConfig%"
	for /f "usebackq" %%a in ("%workConfig%") do (
		set workVNC_Config=%%a
		goto DefinedClient
	)
	set workVNC_Config=
)
	REM 屏幕墙功能
if /i "%definedClientInput:~0,1%"=="W" (
		REM 屏幕墙调用程序下载
	if not exist "%workWindowManageApp%" (
		set userInput=
		set /p userInput=#屏幕墙依赖程序cmdow.exe不存在,输入 Y 下载，输入其它则取消：
		if defined userInput (
			if /i "!userInput!"=="y" (
				echo=#正在下载:
				echo=	下载方法是调用VBS脚本，可能会被报毒,信任即可
				call:DownloadNetFile "%workWindowManageAppUrl%" "%workWindowManageApp%"
				if "!errorlevel!"=="0" (
					set tips=cmdow.exe下载成功
					echo=	#cmdow.exe下载成功
					echo=
				) else (
					echo=#下载失败,请检查网络
					ping -n 3 127.1>nul 2>nul
					set tips=cmdow.exe下载失败,请检查网络
					goto DefinedClient
				)
			) else goto DefinedClient
		) else goto DefinedClient
	)
	if not exist "%workResolutionGetApp%" (
		set userInput=
		set /p userInput=#屏幕墙依赖程序scrnres.exe不存在,输入 Y 下载，输入其它则取消：
		if defined userInput (
			if /i "!userInput!"=="y" (
				echo=#正在下载:
				echo=	下载方法是调用VBS脚本，可能会被报毒,信任即可
				call:DownloadNetFile "%workResolutionGetAppUrl%" "%workResolutionGetApp%"
				if "!errorlevel!"=="0" (
					set tips=scrnres.exe下载成功
					echo=	#scrnres.exe下载成功
					echo=
				) else (
					echo=#下载失败,请检查网络
					ping -n 3 127.1>nul 2>nul
					set tips=scrnres.exe下载失败,请检查网络
					goto DefinedClient
				)
			) else goto DefinedClient
		) else goto DefinedClient
	)
	if "%definedClientInput:~1%"=="" (
		for %%a in (screenWallClient) do set %%a=
		set /p screenWallClient=	#请指定显示到屏幕墙的客户端:
		if not defined screenWallClient (
			set help=yes
			goto DefinedClient
		)
	) else set screenWallClient=%definedClientInput:~1%
	call:clearPecifiedParameters "!screenWallClient!"
	if not "!errorlevel!"=="0" (
		set help=yes
		goto DefinedClient
	)
	call:screenWall "!clearPecifiedParametersResult2!"
)
REM 直接连接或进入客户端详情判断
call:DefinedNoNumberString "%definedClientInput: =%"
if "%errorlevel%"=="1" if not "%definedClientInput%"=="0" if %definedClientInput% leq %definedClientEchoDijia% (
	call:Database_Read  "%workBook%" "	" "%definedClientInput%" "1-5" "clientName clientHost clientPort clientPassword clientRemarks"
	if "%definedClientInput:~-1%"==" " if exist "%workViewerApp%" (
		start "" "!workViewerApp!" !workVNC_Config! !clientHost!:!clientPort! /password !clientPassword!
		goto DefinedClient
	) else (
		set tips=调用主程序不存在，无法连接
		goto DefinedClient
	)
	goto ClientDetail
) else set tips=序列 %definedClientInput: =% 不存在，请检查后重试
goto DefinedClient

REM 客户端详情
:ClientDetail
for %%a in (clientDetailInput clientDetailInput2) do set %%a=
cls
echo=
if defined tips (
	echo=#客户端 %clientName% 详情 ^| 提示：%tips%
	set tips=
) else echo=#客户端 %clientName% 详情
echo=___________________________________^|VNC通讯录工具
echo=
if exist "%workViewerApp%" (echo=	      [输入1连接到此客户端]) else echo=	  [调用主程序不存在，无法连接]
echo=
echo=	名称：%clientName% [输入2修改]
echo=
echo=	地址：%clientHost% [输入3修改]
echo=
echo=	端口：%clientPort% [输入4修改]
echo=
echo=	密码：%clientPassword% [输入5修改]
echo=
echo=	备注：%clientRemarks% [输入6修改]
echo=
echo=	[D-删除] [T-条目置顶] [0-返回上层]
echo=_________________________________________________

set /p clientDetailInput=#请输入命令:
if not defined clientDetailInput goto ClientDetail
call:DefinedNoNumberString "%ClientDetail%"
if "%errorlevel%"=="0" goto ClientDetail
if "%clientDetailInput%"=="1" (
	if exist "%workViewerApp%" (start "" "%workViewerApp%" %workVNC_Config% %clientHost%:%clientPort% /password %clientPassword%) else set tips=调用主程序不存在，无法连接
)
if /i "%clientDetailInput%"=="t" (
	if not "%definedClientInput%"=="1" call:Database_Sort /q "%workbook%" "%definedClientInput%" "1"
	set tips=条目 %clientName% 已置顶
)
if "%clientDetailInput%"=="2" (
	set /p clientDetailInput2=#请输入新名称:
	if defined clientDetailInput2 (
		call:Database_Update /q "%workBook%" "	" "%definedClientInput%" "1" "!clientDetailInput2!"
		call:Database_Read /q "%workBook%" "	" "%definedClientInput%" "1" clientName
		set tips=修改名称成功
	) else set tips=修改名称失败:用户取消
)
if "%clientDetailInput%"=="3" (
	set /p clientDetailInput2=#请输入新地址:
	if defined clientDetailInput2 (
		call:Database_Update /q "%workBook%" "	" "%definedClientInput%" "2" "!clientDetailInput2!"
		call:Database_Read /q "%workBook%" "	" "%definedClientInput%" "2" clientHost
		set tips=修改地址成功
	) else set tips=修改地址失败:用户取消
)
if "%clientDetailInput%"=="4" (
	set /p clientDetailInput2=#请输入新端口:
	if defined clientDetailInput2 (
		call:NetPortTest !clientDetailInput2!
		if not "!errorlevel!"=="0" (
			set tips=端口修改失败:输入错误
			goto ClientDetail
		)
		call:Database_Update /q "%workBook%" "	" "%definedClientInput%" "3" "!clientDetailInput2!"
		call:Database_Read /q "%workBook%" "	" "%definedClientInput%" "3" clientPort
		set tips=修改端口成功
	) else set tips=修改端口失败:用户取消
)
if "%clientDetailInput%"=="5" (
	set /p clientDetailInput2=#请输入新密码:
	if defined clientDetailInput2 (
		call:Database_Update /q "%workBook%" "	" "%definedClientInput%" "4" "!clientDetailInput2!"
		call:Database_Read /q "%workBook%" "	" "%definedClientInput%" "4" clientPassword
		set tips=修改密码成功
	) else set tips=修改密码失败:用户取消
)
if "%clientDetailInput%"=="6" (
	set /p clientDetailInput2=#请输入新备注:
	if defined clientDetailInput2 (
		call:Database_Update /q "%workBook%" "	" "%definedClientInput%" "5" "!clientDetailInput2!"
		call:Database_Read /q "%workBook%" "	" "%definedClientInput%" "5" clientRemarks
		set tips=修改备注成功
	) else set tips=修改备注失败:用户取消
)
if /i "%clientDetailInput%"=="d" (
	call:Database_DeleteLine /q "%workBook%" %definedClientInput% 1
	set tips=删除 %clientName% 成功
	goto DefinedClient
)
if "%clientDetailInput%"=="0" goto DefinedClient
goto ClientDetail

goto end
:子程序区域开始:

REM 添加一个客户端到通讯录	call:AddClient2Book
:AddClient2Book
REM 判断子程序基本需求参数

REM 初始化子程序需求变量
for %%A in (addClientName addClientHost addClientPort addClientRemarks addClientPassword addClientName_Temp) do set %%A=

REM 子程序运行
echo=
echo=#添加客户端到通讯录

:AddClient2Book_ClientName
if defined addClientName set addClientName=
set /p addClientName=^|	请输入客户端名称:
if not defined addClientName goto AddClient2Book_ClientName
REM 判断数据库中是否已存在此名称条目
call:Database_Find /q /i "%workBook%" "	" "%addClientName%" "0" "1" "addClientName_Temp"
if "%errorlevel%"=="0" (
	echo=		#注意：名称为 %addClientName% 的客户端已存在, 请输入一个新的名称
	set addClientName=
	goto AddClient2Book_ClientName
)

:AddClient2Book_ClientHost
REM 由于输入有可能是域名，对用户输入不做过多判断
if defined addClientHost set addClientHost=
set /p addClientHost=^|	请输入客户端地址:
if defined addClientHost (
	if not "%addClientHost%"=="%addClientHost: =%" goto AddClient2Book_ClientHost
) else goto AddClient2Book_ClientHost

:AddClient2Book_ClientPort
if defined addClientPort set addClientPort=
set /p addClientPort=^|	请输入客户端服务端口[1-65535],忽略则默认5900):
if defined addClientPort (
	call:NetPortTest %addClientPort%
	if not "!errorlevel!"=="0" goto AddClient2Book_ClientPort
) else set addClientPort=5900

:AddClient2Book_ClientPassword
if defined addClientPassword set addClientPassword=
set /p addClientPassword=^|	请输入客户端密码:
if not defined addClientPassword goto AddClient2Book_ClientPassword

:AddClient2Book_ClientRemarks
if defined addClientRemarks set addClientRemarks=
set /p addClientRemarks=^|	请输入备注信息(可忽略):
if not defined addClientRemarks set addClientRemarks=无备注

call:Database_Insert /q "%workBook%" "	" "%addClientName%" "%addClientHost%" "%addClientPort%" "%addClientPassword%" "%addClientRemarks%"
set tips=名称为 %addClientName% 的客户端 已添加到通讯录
exit/b 0

REM 判断端口是否符合标准	call:NetPortTest 端口号
REM 						返回值为0则是合规，1为不合规,2为无参数
:NetPortTest
if "%~1"=="" exit/b 2
call:DefinedNoNumberString "%~1"
if "%errorlevel%"=="0" exit/b 1
if %~1 geq 1 if %~1 leq 65535 exit/b 0
exit/b 1


REM 判断变量中是否含有非数字字符 call:DefinedNoNumberString 被判断字符
REM					返回值0代表有非数字字符，返回值1代表无非数字字符
REM 版本：20151231
:DefinedNoNumberString
REM 判断子程序基本需求参数
if "%~1"=="" exit/b 2

REM 初始化子程序需求变量
for %%B in (DefinedNoNumberString) do set %%B=
set DefinedNoNumberString=%~1

REM 子程序开始运行
for /l %%B in (0,1,9) do (
	set DefinedNoNumberString=!DefinedNoNumberString:%%B=!
	if not defined DefinedNoNumberString exit/b 1
)
exit/b 0

REM call:DownloadNetFile 网址 路径及文件名
REM 下载网络文件 版本：20160114
:DownloadNetFile
REM 检查子程序使用规则正确与否
if "%~2"=="" (
	echo=	#[Error %0:参数2]文件路径及文件名为空
	exit/b 1
) else if "%~1"=="" (
	echo=	#[Error %0:参数1]网址为空
	exit/b 1
)

REM 初始化子程序需求变量
for %%- in (downloadNetFileTempPath downloadNetFileUrl downloadNetFileCachePath) do if defined %%- set %%-=
set downloadNetFileTempPath=%temp%\downloadNetFileTempPath%random%%random%%random%.vbs
set downloadNetFileUrl="%~1"
set downloadNetFileUrl="%downloadNetFileUrl:"=%"
set downloadNetFileFilePath=%~2

REM 生成动作脚本
(
	echo=Set xPost = CreateObject^("Microsoft.XMLHTTP"^)
	echo=xPost.Open "GET",%downloadNetFileUrl%,0
	echo=xPost.Send^(^)
	echo=Set sGet = CreateObject^("ADODB.Stream"^)
	echo=sGet.Mode = 3
	echo=sGet.Type = 1
	echo=sGet.Open^(^)
	echo=sGet.Write^(xPost.responseBody^)
	echo=sGet.SaveToFile "%downloadNetFileFilePath%",2
)>"%downloadNetFileTempPath%"

REM 删除IE关于下载内容的缓存
for /f "tokens=3,* skip=2" %%- in ('reg query "hkcu\software\microsoft\windows\currentversion\explorer\shell folders" /v cache') do if "%%~."=="" (set downloadNetFileCachePath=%%-) else set downloadNetFileCachePath=%%- %%.
for /r "%downloadNetFileCachePath%" %%- in ("%~n1*") do if exist "%%~-" del /f /q "%%~-"

REM 运行脚本
cscript //b "%downloadNetFileTempPath%"

REM 删除临时文件
if exist "%downloadNetFIleTempPath%" del /f /q "%downloadNetFIleTempPath%"

REM 判断脚本运行结果
if exist "%downloadNetFileFilePath%" (exit/b 0) else exit/b 1

REM 检查指定参数是否符合标准并纠正参数
:clearPecifiedParameters
if "%~1"=="" exit/b 1
for %%a in (clearPecifiedParameters clearPecifiedParametersResult2 clearPecifiedParametersresult3) do if defined %%a set %%a=
set clearPecifiedParameters=%~1
set clearPecifiedParameters=%clearPecifiedParameters:-=%
call:DefinedNoNumberString "!clearPecifiedParameters:,=!"
if "!errorlevel!"=="0" (
	set tips=包含违规或无效字符，请检查后重试
	exit/b 1
)
for %%a in (%~1) do (
	set clearPecifiedParameters=%%a
	if "!clearPecifiedParameters!"=="!clearPecifiedParameters:-=!" (
		set clearPecifiedParametersResult2=!clearPecifiedParametersResult2!,%%a
	) else (
		for /f "tokens=1,2,* delims=-" %%A in ("%%a") do (
			if "%%~A"=="" (
				set tips=区间符"-"左、右有值为空，请检查后重试
				set help=yes
				exit/b 1
			)
			if "%%~B"=="" (
				set tips=区间符"-"左、右有值为空，请检查后重试
				set help=yes
				exit/b 1
			)
			if not "%%~C"=="" (
				set tips="%%~A-%%~B-%%~C"发现一个区间内多个区间符"-"，请检查后重试
				set help=yes
				exit/b 1
			)
			if "%%~A"=="%%~B" (
				set clearPecifiedParametersResult2=!clearPecifiedParametersResult2!,%%~A
				set clearPecifiedParametersresult3=Yes
			)
			if "%%~A"=="0" (
				set clearPecifiedParametersResult2=!clearPecifiedParametersResult2!,1-%%~B
				set clearPecifiedParametersresult3=Yes
			)
			if %%~A gtr %%~B (
				if "%%~B"=="0" (
					set clearPecifiedParametersResult2=!clearPecifiedParametersResult2!,1-%%~A
				) else (
					set clearPecifiedParametersResult2=!clearPecifiedParametersResult2!,%%~B-%%~A
				)
				set clearPecifiedParametersresult3=Yes
			)
			if not defined clearPecifiedParametersresult3 set clearPecifiedParametersResult2=!clearPecifiedParametersResult2!,%%~A-%%~B
		)
	)
)
exit/b 0

REM 从指定参数中部署屏幕墙元素
:screenWall
REM 接收用户指定客户端分析调用
if "%~1"=="" exit/b 0
for %%a in (screenWall screenWallCount screenWall5) do set %%a=
for /f "tokens=1 delims==" %%a in ('set screenWallCount 2^>nul') do set %%a=
for /f "tokens=1 delims==" %%a in ('set screenWall 2^>nul') do set %%a=
if defined screenWall set screenWall=
REM 检测当前是否有程序为 vncviewer %名称% viewonly
for /f "tokens=1,8,9,*" %%a in ('%workWindowManageApp% /t /b /f') do (
	if "%%~b"=="UltraVNC_Viewer" if not "%%~c"=="." %workWindowManageApp% "%%~a" /ren ". %%~c %%~d"
)
REM 打开屏幕墙并计数调整元素位置
:screenWall5
for %%a in (%~1) do (
	set screenWall=%%a
	if "!screenWall!"=="!screenWall:-=!" (
		if !screenWall!0 leq %definedClientEchoDijia%0 (
			if defined screenWall5 (call:screenWall2 %%a) else set /a screenWallCount+=1
		)
	) else for /f "tokens=1,2 delims=-" %%i in ("%%a") do for /l %%A in (%%i,1,%%j) do if %%A0 leq %definedClientEchoDijia%0 (
		if defined screenWall5 (call:screenWall2 %%A) else set /a screenWallCount+=1
	)
)
if not defined screenWall5 (
	
	REM 获取分屏细节
	set screenNum=0
	set screenNum_Max=0
	:screenWall3
	set /a screenNum+=1
	set /a screenNum_Max=screenNum*screenNum
	if not !screenWallCount!0 leq !screenNum_Max!0 goto screenWall3

	REM 获取当前屏幕分辨率
	for /f "tokens=1,3 delims= " %%y in ('%workResolutionGetApp%') do (
		set screenX=%%~y
		set screenY=%%~z
	)

	REM 屏幕墙元素分配信息，获取单位长宽变量
	set /a basicWallX=screenX/screenNum
	set /a basicWallY=screenY/screenNum

	REM 调整墙元素位置
	set localWallLine=0
	set localWallColumn=0
	
	set screenWall5=Yes
	set screenWallCount=0
	goto screenWall5
)

REM 开启屏幕墙控制台
%workWindowManageApp% @ /min
start "此窗口内回车关闭屏幕墙" /wait cmd /c mode con cols=55 lines=1^&%workWindowManageApp% @ /top /act^&pause^>nul
for /l %%z in (1,1,%screenWallCount%) do (
	for /f "tokens=1,2 delims=," %%x in ("!screenWall%%z!") do (
		%workWindowManageApp% %%x /end
	)
)

%workWindowManageApp% @ /res /act
exit/b 0
:screenWall2
set /a screenWallCount+=1
REM 获取服务器的名称和域名、密码
call:Database_Read /q "%workBook%" "	" "%~1" "1-4" "clientName clientHost clientPort clientPassword"
REM 创建连接到指定服务器的viewer
start "" "!workViewerApp!" /viewonly /notoolbar /nostatus /autoscaling !clientHost!:!clientPort! /password !clientPassword!
set screenWallCount_Temp=0
:screenWall2_2
for /f "tokens=1,8,9" %%I in ('%workWindowManageApp% /t /b /f') do (
	if "%%~J"=="UltraVNC_Viewer" if not "%%~K"=="." if not "%%~K"=="屏幕墙" (
		%workWindowManageApp% "%%~I" /ren "屏幕墙 %clientName%|%screenWallCount%"
		set screenWall%screenWallCount%=%%~I,%clientName%
	)
)
if not defined screenWall%screenWallCount% (
	set /a screenWallCount_Temp+=1
	if !screenWallCount_Temp!0 gtr 30 exit/b 0
	ping -n 3 127.1>nul 2>nul
	goto screenWall2_2
)

REM 调整屏幕墙元素位置
set /a localWallX=basicWallX*!localWallColumn!
set /a localWallY=basicWallY*!localWallLine!
for /f "tokens=1,2 delims=," %%x in ("!screenWall%screenWallCount%!") do (
	%workWindowManageApp% %%~x /siz !basicWallX! !basicWallY! /mov !localWallX! !localWallY! /top
)
set /a localWallColumn+=1
if "!localWallColumn!0"=="!screenNum!0" (
	set localWallColumn=0
	set /a localWallLine+=1
)

exit/b 0


:---------------------Database_Insert---------------------:


REM 插入数据到指定文本数据库文件中
REM call:Database_Insert [/Q(安静模式，不提示错误)] "数据源" [/LN [插入到行位置(默认底部追加)]] "数据列分隔符" "数据1" "数据2" "数据3" "..."
REM 例子：将数据"data1" "data2" "data3" 以 "	"为分隔符插入到文本数据库文件" "c:\users\a\Database.ini"
REM					call:Database_Insert "c:\users\a\Database.ini" "	" "data1" "data2" "data3"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20151208
:Database_Insert
REM 检查子程序运行基本需求参数
for %%A in (d_I_ErrorPrint d_I_LineNumber d_I_Value) do set %%A=
if /i "%~1"=="/q" (
	shift/1
) else set d_I_ErrorPrint=Yes

if "%~2"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数3-指定分隔符为空]
	exit/b 2
)
if /i "%~2"=="/LN" if "%~3"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数3-指定插入行号为空]
	exit/b 2
) else (
	set d_I_LineNumber=%~3
	shift/2
	shift/2
)
if defined d_I_LineNumber if %d_I_LineNumber%0 lss 10 (
	if defined d_I_ErrorPrint echo=	[错误%0:参数3-指定插入行号小于1]
	exit/b 2
)
if "%~3"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数3-指定写入数据为空]
	exit/b 2
)
if "%~2"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数2-指定分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_I_Count d_I_Pass1 d_I_Temp_File) do set %%_=
for /l %%_ in (1,1,31) do set d_I_Value%%_=
if defined d_I_LineNumber (
	set d_I_Temp_File=%~1_Temp
	if exist "%d_I_Temp_File%" del /f /q "%d_I_Temp_File%"
)

REM 子程序开始运作
REM 提取用户指定值
:Database_Insert1
set /a d_I_Count+=1
set d_I_Value%d_I_Count%=%~3
if not "%~4"=="" (
	shift/3
	goto Database_Insert1
)
for /l %%_ in (1,1,%d_I_Count%) do (
	set d_I_Value=!d_I_Value!%~2!d_I_Value%%_!
)
set d_I_Value=%d_I_Value:~1%
REM 未指定插入行号情况
if not defined d_I_LineNumber (
	echo=%d_I_Value%
	exit/b 0
)>>"%~1"
REM 指定插入行号情况
REM 检测插入行是否存在
set /a d_I_Pass1=%d_I_LineNumber%-1
if "%d_I_Pass1%"=="0" (set d_I_Pass1=) else set d_I_Pass1=skip=%d_I_Pass1%
for /f "usebackq %d_I_Pass1% eol=^ delims=" %%? in ("%~1") do goto Database_Insert2
if defined d_I_ErrorPrint echo=	[错误%0:结果:查无此行:%d_I_LineNumber%]
exit/b 1
:Database_Insert2
set d_I_Count=
REM 指定行前段数据写入临时文件
set /a d_I_Count2=%d_I_LineNumber%-1
if "%d_I_Count2%"=="0" goto Database_Insert3
for /f "usebackq eol=^ delims=" %%? in ("%~1") do (
	set /a d_I_Count+=1
	echo=%%?
	if "!d_I_Count!"=="%d_I_Count2%" goto Database_Insert3
)>>"%d_I_Temp_File%"
:Database_Insert3
REM 写入插入数据到临时文件
echo=%d_I_Value%>>"%d_I_Temp_File%"

REM 写入插入行后部数据到临时文件
(
	for /f "usebackq %d_I_Pass1% eol=^ delims=" %%? in ("%~1") do echo=%%?
)>>"%d_I_Temp_File%"

REM 将临时文本数据库文件覆盖源文本数据库文件
copy "%d_I_Temp_File%" "%~1">nul 2>nul
if not "%errorlevel%"=="0" (
	if defined d_I_ErrorPrint echo=	[错误%0:结果:数据覆盖失败，疑似权限不足或文件不存在]
	exit/b 1
)
if exist "%d_I_Temp_File%" del /f /q "%d_I_Temp_File%"
exit/b 0


:---------------------Database_Read---------------------:

REM 从指定文件、指定行、指定分隔符、指定列获取内容赋值到指定变量
REM call:Database_Read [/Q(安静模式，不提示错误)] "数据源文件" "数据列分隔符" "数据所在行" "以分隔符为分割的N列数据(列目号与列目号之间使用,分割，且可以区间分割符-)" "单个或多个变量(多个变量之间使用空格或,进行分割)"
REM 例子：从文件 "c:\users\a\Database.ini" 中将以 "	" 为分隔符的第4行数据的第1,2,3,6列数据分别赋值到var1,var2,var3,var4
REM					call:Database_Read "c:\users\a\Database.ini" "	" "4" "1-3,6" "var1 var2 var3 var4"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20151127
:Database_Read
REM 检查子程序运行基本需求参数
set d_R_ErrorPrint=
if /i "%~1"=="/q" (shift/1) else set d_R_ErrorPrint=Yes
if "%~5"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数5-指定被赋值变量名为空]
	exit/b 2
)
if "%~4"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数4-指定列目号为空]
	exit/b 2
)
if "%~3"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数3-指定行号为空]
	exit/b 2
)
if %~3 lss 1 (
	if defined d_R_ErrorPrint echo=	[错误%0:参数3-指定行号小于1:%~3]
	exit/b 2
)
if "%~2"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数2-指定分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_R_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_R_Count d_R_Pass) do set %%_=
for /l %%_ in (1,1,31) do if defined d_R_Count%%_ set d_R_Count%%_=
set /a d_R_Pass=%~3-1
if "%d_R_Pass%"=="0" (set d_R_Pass=) else set d_R_Pass=skip=%d_R_Pass%

REM 子程序开始运作
for %%_ in (%~5) do (
	set /a d_R_Count+=1
	set d_R_Count!d_R_Count!=%%_
)
set d_R_Count=
for /f "usebackq eol=^ %d_R_Pass% tokens=%~4 delims=%~2" %%? in ("%~1") do (
	for %%_ in ("!d_R_Count1!=%%~?","!d_R_Count2!=%%~@","!d_R_Count3!=%%~A","!d_R_Count4!=%%~B","!d_R_Count5!=%%~C","!d_R_Count6!=%%~D","!d_R_Count7!=%%~E","!d_R_Count8!=%%~F","!d_R_Count9!=%%~G","!d_R_Count10!=%%~H","!d_R_Count11!=%%~I","!d_R_Count12!=%%~J","!d_R_Count13!=%%~K","!d_R_Count14!=%%~L","!d_R_Count15!=%%~M","!d_R_Count16!=%%~N","!d_R_Count17!=%%~O","!d_R_Count18!=%%~P","!d_R_Count19!=%%~Q","!d_R_Count20!=%%~R","!d_R_Count21!=%%~S","!d_R_Count22!=%%~T","!d_R_Count23!=%%~U","!d_R_Count24!=%%~V","!d_R_Count25!=%%~W","!d_R_Count26!=%%~X","!d_R_Count27!=%%~Y","!d_R_Count28!=%%~Z","!d_R_Count29!=%%~[","!d_R_Count30!=%%~\","!d_R_Count31!=%%~]") do (
		set /a d_R_Count+=1
		if defined d_R_Count!d_R_Count! set %%_
	)
	exit/b 0
)
if not defined d_R_Count if defined d_R_ErrorPrint echo=	[错误%0:结果-查无此行:%~3]
exit/b 1


:---------------------Database_Sort---------------------:

REM 排序行数据使其转移到指定行
REM call:Database_Sort [/Q(安静模式，不提示错误)] "数据源" "欲排序行号" "排序后行号"
REM 例子：把文件 "c:\users\a\Database.ini" 中第四行排序到原第二行的位置
REM					call:Database_Sort "c:\users\a\Database.ini" "4" "2"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序，3-两排序行值相同
REM 版本:20151204
:Database_Sort
REM 检查子程序运行基本需求参数
for %%A in (d_S_ErrorPrint) do set %%A=
if /i "%~1"=="/q" (
	shift/1
) else set d_S_ErrorPrint=Yes
if "%~3"=="" (
	if defined d_S_ErrorPrint echo=	[错误%0:参数3-指定排序后所在行为空]
	exit/b 2
)
if %~3 lss 0 (
	if defined d_S_ErrorPrint echo=	[错误%0:参数3-指定排序后所在行小于0:%~2]
)
if "%~2"=="" (
	if defined d_S_ErrorPrint echo=	[错误%0:参数2-指定欲排序行为空]
	exit/b 3
)
if %~2 lss 0 (
	if defined d_S_ErrorPrint echo=	[错误%0:参数2-指定欲排序行小于0:%~2]
)
if "%~2"=="%~3" (
	if defined d_S_ErrorPrint echo=	[错误%0:参数2;参数1:欲排序行与排序后所在行相同，无实际意义，请检查后重试:%~2:%~3]
	exit/b 1
)
if "%~1"=="" (
	if defined d_S_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_S_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_S_Count d_S_Count2 d_S_Pass1 d_S_Pass2 d_S_Pass3 d_S_Temp_File) do set %%_=
set d_S_Temp_File=%~1_Temp
if exist "%d_S_Temp_File%" del /f /q "%d_S_Temp_File%"


if %~2 lss %~3 (
	REM 前端内容
	set /a d_S_Count1=%~2-1
	REM 起始行后，结束行前
	set /a d_S_Pass1=%~2
	set /a d_S_Count2=%~3-%~2
	REM 起始行内容
	set /a d_S_Pass2=%~2-1
	set /a d_S_LineDefinedCheck1=%~2-1
	REM 结束行后(包括结束行)
	set /a d_S_Pass3=%~3
	set /a d_S_LineDefinedCheck2=%~3-1
) else (
	REM 前端内容
	set /a d_S_Count1=%~3-1
	REM 起始行内容
	set /a d_S_Pass1=%~2-1
	set /a d_S_LineDefinedCheck1=%~2-1
	REM 结束行(包括结束行)到起始行之间内容
	set /a d_S_Pass2=%~3-1
	set /a d_S_Count2=%~2-%~3
	set /a d_S_LineDefinedCheck2=%~3-1
	REM 起始行后内容
	set /a d_S_Pass3=%~2
)

for %%_ in (d_S_LineDefinedCheck1 d_S_LineDefinedCheck2 d_S_Pass1 d_S_Pass2 d_S_Pass3) do if "!%%_!"=="0" (set %%_=) else set %%_=skip=!%%_!

REM 判定是否有指定删除行
for /f "usebackq eol=^ %d_S_LineDefinedCheck1% delims=" %%? in ("%~1") do goto Database_Sort_2
if defined d_S_ErrorPrint (
	echo=	[错误:%0:结果:查无此行:%~2]
)
exit/b 1
:Database_Sort_2
for /f "usebackq eol=^ %d_S_LineDefinedCheck2% delims=" %%? in ("%~1") do goto Database_Sort_3
if defined d_S_ErrorPrint (
	echo=	[错误:%0:结果:查无此行:%~3]
)
:Database_Sort_3

REM 子程序开始运作
REM 文本数据库前端内容写入
if not "%d_S_Count1%"=="0" for /f "usebackq eol=^ delims=" %%_ in ("%~1") do (
	set /a d_S_Count+=1
	echo=%%_
	if "!d_S_Count!"=="!d_S_Count1!" goto Database_Sort1
)>>"%d_S_Temp_File%"

:Database_Sort1
set d_S_Count=
(
	if %~2 lss %~3 (
		for /f "usebackq %d_S_Pass1% eol=^ delims=" %%_ in ("%~1") do (
			set /a d_S_Count+=1
			echo=%%_
			if "!d_S_Count!"=="%d_S_Count2%" goto Database_Sort2
		)
	) else (
		for /f "usebackq %d_S_Pass1% eol=^ delims=" %%_ in ("%~1") do (
			echo=%%_
			goto Database_Sort2
		)
	)
)>>"%d_S_Temp_File%"

:Database_Sort2
set d_S_Count=
(
	if %~2 lss %~3 (
		for /f "usebackq %d_S_Pass2% eol=^ delims=" %%_ in ("%~1") do (
			echo=%%_
			goto Database_Sort3
		)
	) else (
		for /f "usebackq %d_S_Pass2% eol=^ delims=" %%_ in ("%~1") do (
			set /a d_S_Count+=1
			echo=%%_
			if "!d_S_Count!"=="%d_S_Count2%" goto Database_Sort3
		)
	)
)>>"%d_S_Temp_File%"
:Database_Sort3
for /f "usebackq %d_S_Pass3% eol=^ delims=" %%_ in ("%~1") do (
	echo=%%_
)>>"%d_S_Temp_File%"

REM 将临时文本数据库文件覆盖源文本数据库文件
copy "%d_S_Temp_File%" "%~1">nul 2>nul
if not "%errorlevel%"=="0" (
	if defined d_S_ErrorPrint echo=	[错误%0:结果:数据覆盖失败，疑似权限不足或文件不存在]
	exit/b 1
)
if exist "%d_S_Temp_File%" del /f /q "%d_S_Temp_File%"
exit/b 0

:---------------------Database_Update---------------------:


REM 修改指定文件的指定行以指定分隔符分割的指定列的内容
REM call:Database_Update [/Q(安静模式，不提示错误)] "数据源" "数据列分隔符" "欲修改数据所在开始行号" "以分隔符为分割的N列数据(列号与列号之间使用,分割，且可以区间分割符-)" "该行第一列修改后数据" "该行第二列修改后数据" ...
REM 例子：从文件 "c:\users\a\Database.ini" 中第4行以 "	" 为分隔1,2,3,6列数据修改为分别修改为 string1 string2 string3 string4
REM					call:Database_Update "c:\users\a\Database.ini" "	" "4" "1-3,6" "string1" "string2" "string3" "string4"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20151130
:Database_Update
REM 检查子程序运行基本需求参数
for %%A in (d_U_ErrorPrint) do set %%A=
if /i "%~1"=="/q" (
	shift/1
) else set d_U_ErrorPrint=Yes
if "%~5"=="" (
	if defined d_U_ErrorPrint echo=	[错误%0:参数5-指定修改后数据为空]
	exit/b 2
)
if "%~4"=="" (
	if defined d_U_ErrorPrint echo=	[错误%0:参数4-指定列号为空]
	exit/b 2
)
if "%~3"=="" (
	if defined d_U_ErrorPrint echo=	[错误%0:参数3-指定行号为空]
	exit/b 2
)
if %~3 lss 1 (
	if defined d_U_ErrorPrint echo=	[错误%0:参数3-指定行号小于1:%~3]
	exit/b 2
)
if "%~2"=="" (
	if defined d_U_ErrorPrint echo=	[错误%0:参数2-数据列分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_U_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_U_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)
REM 初始化变量
for %%_ in (d_U_Count d_U_Pass1 d_U_Pass2 d_U_Pass3 d_U_Temp_File d_U_FinalValue d_U_Value) do set %%_=
for /l %%_ in (1,1,31) do (
	set d_U_Value%%_=
	set d_U_FinalValue%%_=
)
set d_U_Temp_File=%~1_Temp
if exist "%d_U_Temp_File%" del /f /q "%d_U_Temp_File%"
set /a d_U_Pass3=%~3
set /a d_U_Pass2=%~3-1
set /a d_U_Pass1=%~3-1

set d_U_Pass3=skip=%d_U_Pass3%
if "%d_U_Pass2%"=="0" (set d_U_Pass2=) else set d_U_Pass2=skip=%d_U_Pass2%

REM 判定是否有指定修改行
for /f "usebackq eol=^ %d_U_Pass2% delims=" %%? in ("%~1") do goto Database_Updata_2
if defined d_U_ErrorPrint (
	echo=	[错误:%0:结果:查无此行:%~3]
)
exit/b 1
:Database_Updata_2
if %d_U_Pass1% leq 0 goto Database_Updata2

REM 子程序开始运作
REM 共分三阶段进行修改，将文本数据库源文件分为三阶段：修改行前内容提取写入，修改行提取修改并写入，修改行后内容提取并写入 进行修改文本数据库

REM 修改行前内容提取写入阶段
:Database_Updata1

(
	for /f "usebackq eol=^ delims=" %%? in ("%~1") do (
		set /a d_U_Count+=1
		echo=%%?
		if "!d_U_Count!"=="%d_U_Pass1%" goto Database_Updata2
	)
)>>"%d_U_Temp_File%"

REM 修改行提取修改并写入阶段
:Database_Updata2
set d_U_Count=

:Database_Updata2_2
REM 将用户指定修改内容赋值到序列变量
set /a d_U_Count+=1
set d_U_Value%d_U_Count%=%~5
if not "%~6"=="" (
	shift/5
	goto Database_Updata2_2
)

set d_U_Count=

REM 将用户指定修改内容赋值到行整体数据位置序列变量
for /f "tokens=%~4 delims=," %%? in ("1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31") do set d_U_Column=%%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%]
for /f "delims=%%" %%a in ("%d_U_Column%") do set d_U_Column=%%a
for %%a in (%d_U_Column%) do (
	set /a d_U_Count+=1
	call:Database_Updata_Var d_U_FinalValue%%a d_U_Value!d_U_Count!
)

set d_U_Count=

REM 将文本数据库修改行不被修改的数据赋值到行整体数据位置序列变量(已经被赋值的序列变量则跳过)
for /f "usebackq eol=^ tokens=1-31 %d_U_Pass2% delims=%~2" %%? in ("%~1") do (
	for %%_ in ("%%?" "%%@" "%%A" "%%B" "%%C" "%%D" "%%E" "%%F" "%%G" "%%H" "%%I" "%%J" "%%K" "%%L" "%%M" "%%N" "%%O" "%%P" "%%Q" "%%R" "%%S" "%%T" "%%U" "%%V" "%%W" "%%X" "%%Y" "%%Z" "%%[" "%%\" "%%]") do (
		if "%%~_"=="" goto Database_Updata2_3
		set /a d_U_Count+=1
		if not defined d_U_FinalValue!d_U_Count! set d_U_FinalValue!d_U_Count!=%%~_
	)
	goto Database_Updata2_3
)
:Database_Updata2_3
if "%d_U_FinalValue1%"=="" (
	if not defined d_U_ErrorPrint echo=	[错误%0:结果:查无此行]
	exit/b 1
)
REM 将修改后修改行正式写入临时文本数据库文件
for /l %%_ in (1,1,%d_U_Count%) do (
	set d_U_FinalValue=!d_U_FinalValue!%~2!d_U_FinalValue%%_!
)
set d_U_FinalValue=%d_U_FinalValue:~1%
(echo=%d_U_FinalValue%)>>"%d_U_Temp_File%"

REM 修改行后内容提取并写入阶段
:Database_Updata3
(
	for /f "usebackq %d_U_Pass3% eol=^ delims=" %%? in ("%~1") do echo=%%?
)>>"%d_U_Temp_File%"

REM 将临时文本数据库文件覆盖源文本数据库文件，修改完毕
copy "%d_U_Temp_File%" "%~1">nul 2>nul
if not "%errorlevel%"=="0" (
	if defined d_U_ErrorPrint echo=	[错误%0:结果:修改后数据覆盖失败，疑似权限不足或文件不存在]
	exit/b 1
)
if exist "%d_U_Temp_File%" del /f /q "%d_U_Temp_File%"
exit/b 0

REM 由于变量深度问题延伸出的子程序
:Database_Updata_Var
set %~1=!%~2!
exit/b 0

:---------------------Database_Find---------------------:

REM 从指定文件、指定行、指定分隔符、指定列、指定字符串搜索并将搜索结果的行列号写入到指定变量中
REM call:Database_Find [/Q(安静模式，不提示错误)] [/i(不区分大小写)] "数据源" "数据列分隔符"  "查找字符串" "查找数据行(支持单数分隔符,与区间连续分隔符-,0为指定全部行)" "查找数据列(支持单数分隔符,与区间连续分隔符-)" "查找结果行号列号结果接受赋值变量名"
	REM 注意：-------------------------------------------------------------------------------------------------------------------------------
	REM 	结果变量的输出格式为："行 列","行 列","..."依次递加，例如第二行第三列和第五行第六列的赋值内容就为："2 3","5 6"
	REM 	可以使用 'for %%a in (%结果变量%) do for /f "tokens=1,2" %%b in ("%%~a") do echo=第%%b行，第%%c列' 的方法进行结果使用
	REM -------------------------------------------------------------------------------------------------------------------------------------
REM 例子：从文件 "c:\users\a\Database.ini"中第三到五行以"	"为分隔符的第一列中不区分大小写的查找字符串data(完全匹配)并将搜索结果的行列号赋值到变量result
REM					call:Database_Find /i "c:\users\a\Database.ini" "	" "data" "3-5" "1" "result"
REM 返回值详情：0-根据指定字符串找到结果并已赋值变量，1-未查找到结果，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20151202
:Database_Find
REM 检查子程序运行基本需求参数
for %%A in (d_F_ErrorPrint d_F_Insensitive) do set %%A=
if /i "%~1"=="/i" (
	set d_F_Insensitive=/i
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set d_F_ErrorPrint=Yes
if /i "%~1"=="/i" (
	set d_F_Insensitive=/i
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set d_F_ErrorPrint=Yes

if "%~6"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数6-指定接受结果变量名为空]
	exit/b 2
)
if "%~5"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数5-指定查找列号为空]
	exit/b 2
)
if "%~4"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数4-指定查找行号为空]
	exit/b 2
)
if "%~3"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数3-指定查找字符串为空]
	exit/b 2
)
if "%~2"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数2-指定数据列分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_F_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_F_Count d_F_StringTest d_F_Count2 d_F_Pass %~6) do set %%_=
for /f "delims==" %%_ in ('set d_F_AlreadyLineNumber 2^>nul') do set %%_=
for /f "delims==" %%_ in ('set d_F_Column 2^>nul') do set %%_=

REM 子程序开始运作
REM 判断用户输入行号是否符合规则
set d_F_StringTest=%~4
for %%_ in (1,2,3,4,5,6,7,8,9,0,",",-) do if defined d_F_StringTest set d_F_StringTest=!d_F_StringTest:%%~_=!
if defined d_F_StringTest (
	if defined d_F_ErrorPrint echo=	[错误%0:参数4:指定查找行号不符合规则:%~4]
	exit/b 2
)

REM 将列号赋值到列变量
for /f "tokens=%~5" %%? in ("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31") do for /f "delims=%%" %%_ in ("%%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%]") do for %%: in (%%_) do (
	set /a d_F_Count+=1
	set d_F_Column!d_F_Count!=%%:
)

set d_F_Count=
REM 根据行号进行拆分执行命令
for %%_ in (%~4) do (
	set d_F_Pass=
	set d_F_Pass=%%~_
	if "!d_F_Pass!"=="!d_F_Pass:-=!" (
		if "%%~_"=="0" (
			set d_F_Count2=0
			set d_F_Count=No
			set d_F_Pass=
		) else (
			set /a d_F_Count2=%%~_-1
			set /a d_F_Pass=%%~_-1
			set d_F_Count=0
			if "!d_F_Pass!"=="0" (set d_F_Pass=) else set d_F_Pass=skip=!d_F_Pass!
		)
		call:Database_Find_Run "%~1" "%~2" "%~5" "%~3" "%~6"
	) else (
		for /f "tokens=1,2 delims=-" %%: in ("%%~_") do (
			if "%%~:"=="%%~;" (
				set /a d_F_Count2=%%~:-1
				set /a d_F_Pass=%%~:-1
				set d_F_Count=0
			) else call:Database_Find2 "%%~:" "%%~;"
			if "!d_F_Pass!"=="0" (set d_F_Pass=) else set d_F_Pass=skip=!d_F_Pass!
			call:Database_Find_Run "%~1" "%~2" "%~5" "%~3" "%~6"
		)
	)
)

if defined %~6 (set %~6=!%~6:~1!) else (
	if defined d_F_ErrorPrint echo=	[结果%0:根据关键字"%~3"未能从指定文件行列中找到结果]
	exit/b 1
)
exit/b 0

REM call:Database_Find_Run "文件" "分隔符" "列" "查找字符串" "变量名"
:Database_Find_Run
set d_F_Count3=
for /f "usebackq %d_F_Pass% eol=^ tokens=%~3 delims=%~2" %%? in ("%~1") do (
	set /a d_F_Count3+=1
	set /a d_F_Count2+=1

	if not defined d_F_AlreadyLineNumber!d_F_Count2! (
		set d_F_AlreadyLineNumber!d_F_Count2!=Yes
		if "%%?"=="%%~?" (
			if %d_F_Insensitive% "%%?"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column1!"
		)
		if "%%@"=="%%~@" (
			if %d_F_Insensitive% "%%@"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column2!"
		)
		if "%%A"=="%%~A" (
			if %d_F_Insensitive% "%%A"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column3!"
		)
		if "%%B"=="%%~B" (
			if %d_F_Insensitive% "%%B"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column4!"
		)
		if "%%C"=="%%~C" (
			if %d_F_Insensitive% "%%C"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column5!"
		)
		if "%%D"=="%%~D" (
			if %d_F_Insensitive% "%%D"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column6!"
		)
		if "%%E"=="%%~E" (
			if %d_F_Insensitive% "%%E"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column7!"
		)
		if "%%F"=="%%~F" (
			if %d_F_Insensitive% "%%F"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column8!"
		)
		if "%%G"=="%%~G" (
			if %d_F_Insensitive% "%%G"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column9!"
		)
		if "%%H"=="%%~H" (
			if %d_F_Insensitive% "%%H"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column10!"
		)
		if "%%I"=="%%~I" (
			if %d_F_Insensitive% "%%I"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column11!"
		)
		if "%%J"=="%%~J" (
			if %d_F_Insensitive% "%%J"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column12!"
		)
		if "%%K"=="%%~K" (
			if %d_F_Insensitive% "%%K"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column13!"
		)
		if "%%L"=="%%~L" (
			if %d_F_Insensitive% "%%L"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column14!"
		)
		if "%%M"=="%%~M" (
			if %d_F_Insensitive% "%%M"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column15!"
		)
		if "%%N"=="%%~N" (
			if %d_F_Insensitive% "%%N"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column16!"
		)
		if "%%O"=="%%~O" (
			if %d_F_Insensitive% "%%O"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column17!"
		)
		if "%%P"=="%%~P" (
			if %d_F_Insensitive% "%%P"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column18!"
		)
		if "%%Q"=="%%~Q" (
			if %d_F_Insensitive% "%%Q"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column19!"
		)
		if "%%R"=="%%~R" (
			if %d_F_Insensitive% "%%R"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column20!"
		)
		if "%%S"=="%%~S" (
			if %d_F_Insensitive% "%%S"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column21!"
		)
		if "%%T"=="%%~T" (
			if %d_F_Insensitive% "%%T"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column22!"
		)
		if "%%U"=="%%~U" (
			if %d_F_Insensitive% "%%U"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column23!"
		)
		if "%%V"=="%%~V" (
			if %d_F_Insensitive% "%%V"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column24!"
		)
		if "%%W"=="%%~W" (
			if %d_F_Insensitive% "%%W"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column25!"
		)
		if "%%X"=="%%~X" (
			if %d_F_Insensitive% "%%X"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column26!"
		)
		if "%%Y"=="%%~Y" (
			if %d_F_Insensitive% "%%Y"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column27!"
		)
		if "%%Z"=="%%~Z" (
			if %d_F_Insensitive% "%%Z"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column28!"
		)
		if "%%["=="%%~[" (
			if %d_F_Insensitive% "%%["=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column29!"
		)
		if "%%\"=="%%~\" (
			if %d_F_Insensitive% "%%\"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column30!"
		)
		if "%%]"=="%%~]" (
			if %d_F_Insensitive% "%%]"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column31!"
		)
	)
	if /i not "%d_F_Count%"=="No" (
		if "%d_F_Count%"=="0" exit/b
		if "!d_F_Count3!"=="%d_F_Count%" exit/b
	)
)
exit/b

REM 可能由于嵌套深度原因导致的问题不得不写出一个子程序进行判断
REM call:Database_Find2 第一个值 第二个值
:Database_Find2
if %~10 gtr %~20 (
	set /a d_F_Count2=%~2-1
	set /a d_F_Pass=%~2-1
	set /a d_F_Count=%~1-%~2+1
) else (
	set /a d_F_Count2=%~1-1
	set /a d_F_Pass=%~1-1
	set /a d_F_Count=%~2-%~1+1
)
exit/b

:---------------------Database_DeleteLine---------------------:

REM 删除指定文件指定行
REM call:Database_DeleteLine [/Q(安静模式，不提示错误)] "数据源" "欲删除数据起始行" "从起始行开始继续向下删除多少行(包括本行，向下到结尾请输入0)"
REM 例子：把文件 "c:\users\a\Database.ini" 中第二第三行删除
REM					call:Database_DeleteLine "c:\users\a\Database.ini" "2" "2"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 版本:20151130
:Database_DeleteLine
REM 检查子程序运行基本需求参数
for %%A in (d_DL_ErrorPrint) do set %%A=
if /i "%~1"=="/q" (
	shift/1
) else set d_DL_ErrorPrint=Yes
if "%~3"=="" (
	if defined d_DL_ErrorPrint echo=	[错误%0:参数3-指定偏移行为空]
	exit/b 2
)
if %~3 lss 0 (
	if defined d_DL_ErrorPrint echo=	[错误%0:参数3-指定偏移行小于0:%~4]
)
if "%~2"=="" (
	if defined d_DL_ErrorPrint echo=	[错误%0:参数2-指定起始行号为空]
	exit/b 2
)
if %~2 lss 1 (
	if defined d_DL_ErrorPrint echo=	[错误%0:参数2-指定起始行号小于1:%~3]
	exit/b 2
)
if "%~1"=="" (
	if defined d_DL_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_DL_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)

REM 初始化变量
for %%_ in (d_DL_Count d_DL_Pass1 d_DL_Pass2 d_DL_Pass3 d_DL_Temp_File) do set %%_=
set d_DL_Temp_File=%~1_Temp
if exist "%d_DL_Temp_File%" del /f /q "%d_DL_Temp_File%"
set /a d_DL_Pass3=%~2-1
set /a d_DL_Pass2=%~2+%~3-1
set /a d_DL_Pass1=%~2-1

if "%d_DL_Pass3%"=="0" (set d_DL_Pass3=) else set d_DL_Pass3=skip=%d_DL_Pass3%
if "%d_DL_Pass2%"=="0" (set d_DL_Pass2=) else set d_DL_Pass2=skip=%d_DL_Pass2%

REM 判定是否有指定删除行
for /f "usebackq eol=^ %d_DL_Pass3% delims=" %%? in ("%~1") do goto Database_Updata_2
if defined d_DL_ErrorPrint (
	echo=	[错误:%0:结果:查无此行:%~3]
)
exit/b 1
:Database_Updata_2
if %d_DL_Pass1% leq 0 goto Database_Updata2
REM 子程序开始运作
REM 将删除行前内容写入到临时文本数据库文件
:Database_Updata1
(
	for /f "usebackq eol=^ delims=" %%? in ("%~1") do (
		set /a d_DL_Count+=1
		echo=%%?
		if "!d_DL_Count!"=="%d_DL_Pass1%" goto Database_Updata2
	)
)>>"%d_DL_Temp_File%"

REM 将删除行后内容写入到临时文本数据库文件
:Database_Updata2
if "%~3"=="0" (
	if "%~2"=="1" (if "a"=="b" echo=此处生成空文件)>>"%d_DL_Temp_File%"
) else (
	for /f "usebackq %d_DL_Pass2% eol=^ delims=" %%? in ("%~1") do echo=%%?
)>>"%d_DL_Temp_File%"

REM 将临时文本数据库文件覆盖源文本数据库文件
copy "%d_DL_Temp_File%" "%~1">nul 2>nul
if not "%errorlevel%"=="0" (
	if defined d_DL_ErrorPrint echo=	[错误%0:结果:删除后数据覆盖失败，疑似权限不足或文件不存在]
	exit/b 1
)
if exist "%d_DL_Temp_File%" del /f /q "%d_DL_Temp_File%"
exit/b 0

:子程序区域结束:
:end