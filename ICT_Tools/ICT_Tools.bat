@echo off&setlocal ENABLEDELAYEDEXPANSION&title ICT工具箱&color 0a
cd /d "%~dp0"
set askopenict=
tasklist /fo csv /nh /fi "windowtitle eq TR-518FE" 2>nul|find """" >nul
if not "%errorlevel%"=="0" call:openict
:mainmenu
cls&set date=&set mainmenu=
echo=&echo=_______________________ICT工具箱_______________________&echo=
if defined result echo 提示：&echo      %result%&set result=&echo=
echo=		1.不良产品记录与查询
echo=		2.已测产品计数查询[日期格式:2XXXXXXXX]
echo=		3.计算机文件搜索
echo=		4.打印自定义内容
echo=		5.ICT常见英语解释

echo=
echo=		a.关于ICT工具箱
echo=______________________________________________________
echo=                                        输入Q退出
echo=
set /p mainmenu=请输入命令序号：
if not exist %date:~0,10%\barcode md %date:~0,10%\BarCode
if not exist %date:~0,10%\Log\In md %date:~0,10%\Log\In
if not exist %date:~0,10%\Log\All md %date:~0,10%\Log\All
if not defined mainmenu goto mainmenu
if /i "%mainmenu%"=="q" exit /b
if /i "%mainmenu%"=="a" goto about
if "%mainmenu%"=="1" goto barcode
if "%mainmenu%"=="2" goto overtestcount
if "%mainmenu:~0,1%"=="2" (
	if not "%mainmenu:~8,1%"=="" (
		if "%mainmenu:~9%"=="" (
			echo %mainmenu%|findstr [a-z]>nul&&set result=格式错误，范例：2008年5月1日-220080501&&goto mainmenu
			set date=%mainmenu:~1,4%-%mainmenu:~5,2%-%mainmenu:~7,2%
			goto overtestcount
)))
if "%mainmenu%"=="3" goto filesearch
if "%mainmenu%"=="4" goto printmenu
if "%mainmenu%"=="5" goto ictenglish
if not "%mainmenu:~12,1%"=="" if "%mainmenu:~13%"=="" set barcode=%mainmenu%&goto wrong
if defined mainmenu set result=命令输入错误，请检查后重试
goto mainmenu

:barcode
cls&set date=&set barcode=&set print=
echo=&echo=__________________不良产品记录与查询__________________&echo=
if defined result echo 提示：&echo      %result%&set result=&echo=
echo=		1.未贴码
echo=		2.已贴标签
echo 		3.日志统计与查询[日期格式:3XXXXXXXX]
echo=______________________________________________________
echo=                                     输入Q返回主菜单
set /p barcode=请扫不良品条码：
if not defined barcode goto barcode
if "%barcode%"=="q" goto mainmenu
if "%barcode%"=="1" set err2=无条码&goto write2
if "%barcode%"=="2" set err2=已贴不良标签&goto write2
if "%barcode%"=="3" goto Log
if "%barcode:~0,1%"=="3" (
	if not "%barcode:~8,1%"=="" (
		if "%barcode:~9%"=="" (
			echo %barcode%|findstr [a-z]>nul&&set result=格式错误，范例：2008年5月1日-320080501&&goto barcode
			set date=%barcode:~1,4%-%barcode:~5,2%-%barcode:~7,2%
			if not exist !date! set result=日期!date!没有日志文件，请检查后重试&set date=&goto barcode
			goto log
)))
if "%barcode:~12,1%"=="" set result=输入错误&goto barcode
if not "%barcode:~13%"=="" set result=输入错误&goto barcode
goto wrong
:wrong
cls
echo=&echo=_____________________不良产品记录_____________________&echo=
echo=不良状况代码：
echo=      1-连锡,2-空焊,3-脚未出,4-掉件,5-反向,6-零件不良
echo=格式：
echo=      不良零件名称 不良状况代码(名称和代码用空格隔开)
echo=      如有多个不良零件可用“.”分割,将被转换为“与”
echo=      结尾加P打印不良内容，后附空格可再跟打印备注
echo=范例：
echo=     U1连锡：U1 1        C56与C57连锡：C56.C57 1
echo=     R1与R2连锡打印不良内容：R1.R2 1p
echo=     R3与R4空焊打印不良内容备注为“侧面”R3.R4 2p 侧面
echo=______________________________________________________
echo=%barcode%:
if exist %date:~0,10%\BarCode\%barcode% (findstr /n . %date:~0,10%\BarCode\%barcode%) else echo=              此条码暂无重复测试记录
echo=______________________________________________________
set wrong=&set err=&set err2=&set err3=
echo=                                       输入Q返回
set /p wrong=请输入不良信息：
if not defined wrong goto wrong
if /i "%wrong%"=="q" goto barcode
echo=%wrong%|find " ">nul
echo=%wrong%|findstr /b [a-z]
if not  "%errorlevel%"=="0" goto wrong
call:convert
:write
echo %time:~0,8% %err% %err2%>>%date:~0,10%\BarCode\%barcode%
set num=
if exist %date:~0,10%\Log\In\%err%%err2% for /f "tokens=3" %%a in (%date:~0,10%\Log\In\%err%%err2%) do set num=%%a
set /a num+=1
echo %err% %err2% %num% >%date:~0,10%\Log\In\%err%%err2%
set result=%barcode%:%err%%err2% : %num% 已录入
:write2
set num=
if exist %date:~0,10%\log\All\%err2% for /f %%a in (%date:~0,10%\log\All\%err2%) do set num=%%a
set /a num+=1
echo %num% >%date:~0,10%\Log\All\%err2%
if "%err2%"=="无条码" set result=无条码 : %num% 已录入
if "%err2%"=="已贴不良标签" set result=已贴不良标签 : %num% 已录入
set num=
if exist %date:~0,10%\log\All\All for /f %%a in (%date:~0,10%\log\All\All) do set num=%%a
set /a num+=1
echo %num% >%date:~0,10%\Log\All\All
if /i "%print%"=="Yes" echo=正在发送打印命令，如长时停留此页面请检查打印机设置或连接&call:print "----产品不良状况 %date:~0,10% %time:~0,8%-----" "%barcode%：%err%%err2%" "%err3%"
goto barcode

:log
cls
echo %date:~0,10%:&echo=______________不良产品记录日志统计与查询______________&echo=
set rizhifenxiang=
for %%a in (all 连锡 空焊 脚未出 掉件 反向 无条码 已贴不良标签 零件不良) do set error%%a=
for %%a in (all 连锡 空焊 脚未出 掉件 反向 无条码 已贴不良标签 零件不良) do (
	if exist %date:~0,10%\log\all\%%a (for /f %%b in (%date:~0,10%\log\all\%%a) do set error%%a=%%b)else set error%%a=0
)
echo 共计不良 %errorall%
echo 连锡 %error连锡% , 空焊 %error空焊% , 脚未出 %error脚未出% , 掉件 %error掉件% , 反向 %error反向%
echo 无条码 %error无条码% , 已贴不良标签 %error已贴不良标签% , 零件不良 %error零件不良%
echo=&echo=______________________________________________________
for /f "delims=" %%a in ('dir /b %date:~0,10%\Log\In') do for /f "tokens=1-3" %%i in (%date:~0,10%\Log\In\%%a) do echo %%i%%j %%k&set rizhifenxiang=%%i%%j%%k	!rizhifenxiang!
echo=                                            F_Ms
echo=______________________________________________________
echo=                                   输入 P 打印日志
set user=
set /p user=请输入关键字进行搜索：
if not defined user goto barcode
if /i "%user%"=="p" call:print "----产品不良日志 %date:~0,10% %time:~0,8%-----" "共计不良:%errorall%" "连锡:%error连锡%	空焊:%error空焊%	脚未出:%error脚未出%	掉件:%error掉件%	反向:%error反向%	零件不良:%error零件不良%	无条码:%error无条码%	已贴不良标签:%error已贴不良标签%" " " "分项：" "%rizhifenxiang%"&set result=产品不良日志打印命令已发出&goto barcode
pushd %date:~0,10%\barcode
findstr /l /i "%user%" *
if not "%errorlevel%"=="0" echo 根据关键字未查找到内容，请重试
popd
pause>nul
goto barcode

:overtestcount
echo=正在查找数据库并计算，请稍后... ...
for /l %%a in (1,1,4) do set overtestcount%%a=&set fordo=
echo=>firstdelete.ini
if exist datapath.ini (set fordo=for /f "delims=" %%a in ^(datapath.ini^)) else set fordo=for /r c:\ %%a in ^(%date:~0,4%%date:~5,2%%date:~8,2%.dat^)
%fordo% do if exist "%%a" (
	if exist firstdelete.ini (echo=%%~dpa>datapath.ini&del firstdelete.ini /f /q) else echo=%%~dpa>>datapath.ini
	for /f %%b in ('type "%%~dpa\%date:~0,4%%date:~5,2%%date:~8,2%.dat"^|find /c "PASS"') do set /a overtestcount1=overtestcount1+%%b
	for /f %%b in ('type "%%~dpa\%date:~0,4%%date:~5,2%%date:~8,2%.dat"^|findstr /v /b /i ", ooooooooooooo"^|find /c "PASS"') do set /a overtestcount2=overtestcount2+%%b
	for /f %%b in ('type "%%~dpa\%date:~0,4%%date:~5,2%%date:~8,2%.dat"^|findstr /v /b /i ", ooooooooooooo"^|find /c "FAIL"') do set /a overtestcount3=overtestcount3+%%b
)
for /l %%a in (1,1,3) do if not defined overtestcount%%a set overtestcount%%a=0
set /a overtestcount4=overtestcount1-overtestcount2
cls&echo %date:~0,10%:&echo=_____________________已测产品计数_____________________&echo=
echo=不含待测：%overtestcount2% (插件参考数据)
echo=包含待测：%overtestcount1%
echo=待测数量：%overtestcount4%
echo=入网数量：%overtestcount3%
echo=                                            F_Ms
echo=______________________________________________________
set user=
echo=
echo=输入 P 打印结果，输入 C 打开计算器
echo=如果觉得数据不准确可输入 S 进行重新搜索数据库文件
set /p user=
if /i "%user%"=="p" echo=正在发送打印命令，如长时停留此页面请检查打印机设置或连接& call:print "----ICT产品记数 %date:~0,10% %time:~0,8%-----" "不含待测：%overtestcount2% (插件参考数据)" "包含待测：%overtestcount1%" "待测数量：%overtestcount4%" "入网数量：%overtestcount3%"
if /i "%user%"=="c" calc.exe
if /i "%user%"=="s" if exist datapath.ini del datapath.ini /f /q&cls&goto overtestcount
goto mainmenu

:convert
for /f "tokens=1,2,3" %%a in ("%wrong%") do set err=%%a&set err2=%%b&set err3=%%c
if /i "%err2:~-1%"=="p" set err2=%err2:~0,-1%&set print=Yes
if not "%err2%"=="1" if not "%err2%"=="2" if not "%err2%"=="3" if not "%err2%"=="4" if not "%err2%"=="5" if not "%err2%"=="6"  goto wrong
set err=%err:a=A%
set err=%err:b=B%
set err=%err:c=C%
set err=%err:d=D%
set err=%err:e=E%
set err=%err:f=F%
set err=%err:g=G%
set err=%err:h=H%
set err=%err:i=I%
set err=%err:j=J%
set err=%err:k=K%
set err=%err:l=L%
set err=%err:m=M%
set err=%err:n=N%
set err=%err:o=O%
set err=%err:p=P%
set err=%err:q=Q%
set err=%err:r=R%
set err=%err:s=S%
set err=%err:t=T%
set err=%err:u=U%
set err=%err:v=V%
set err=%err:w=W%
set err=%err:x=X%
set err=%err:y=Y%
set err=%err:z=Z%
set err=%err:.=与%
set err2=%err2:1=连锡%
set err2=%err2:2=空焊%
set err2=%err2:3=脚未出%
set err2=%err2:4=掉件%
set err2=%err2:5=反向%
set err2=%err2:6=零件不良%
if not "%err3%"=="" set err3=备注:%err3%
goto :eof

:printmenu
cls&set diyprint=
echo=&echo=_______________ICT打印机自定义内容打印________________&echo=
echo=   请输入要打印的内容，如内容中包含空格则会分行打印
echo=       用英文引号 " 括住的含有空格的内容不会分行
echo=   范例：
echo=        a b c d - 共4行     分别为a,b,c,d
echo=        a "b c" d - 共3行   分别为a,b c,d
echo=        "a b" "c d" - 共2行 分别为a b,c d
echo=______________________________________________________
echo=                                       输入Q返回
set /p diyprint=:
if not defined diyprint goto printmenu
if /i "%diyprint:"=%"=="q" goto mainmenu
call:print /d %diyprint%
echo=正在发送打印命令，如长时停留此页面请检查打印机设置或连接
goto mainmenu

:print
set user=&set diy=
if exist "%temp%\~printer.tmp" del "%temp%\~printer.tmp" /f /q
if /i "%~1"=="/d" set diy=yes&shift /1
:printstart
if "%~1"=="" goto :eof
echo=%~1 >>"%temp%\~printer.tmp"
if not "%~2"=="" shift /1&goto printstart
if defined diy echo=_______打印内容预览_______&type "%temp%\~printer.tmp"&echo=_________预览结束_________&set /p user=确认打印请输入P：&if /i not "!user!"=="p" goto :eof
echo=                                   F_Ms>>"%temp%\~printer.tmp"
for /l %%a in (1,1,10) do echo=>>"%temp%\~printer.tmp"
print "%temp%\~printer.tmp">nul
goto :eof

:openict
echo=_______________________ICT工具箱_______________________
echo=
echo=       检测到尚未打开ICT测试程序^(TRI^),是否打开？
echo=               回车打开，输入其它则跳过
echo=______________________________________________________
set /p askopenict=
tasklist /fo csv /nh /fi "windowtitle eq TR-518FE" 2>nul|find """" >nul
if not "%errorlevel%"=="0" if "%askopenict%"=="" (
	if exist ictpath.ini for /f "delims=" %%a in (ictpath.ini) do if exist "%%a" pushd "%%~dpa"&start "" "%%~nxa"&popd&goto ictopenover
	if exist "%userprofile%\桌面\tri.lnk" start "" "%userprofile%\桌面\tri.lnk" &goto ictopenover
	for /r c:\ %%a in (ew518fe.exe) do if exist "%%a" echo=%%~a>ictpath.ini&pushd "%%~dpa"&start "" "%%~nxa"&popd&goto ictopenover
	set ictpath=
	echo=程序未能自动搜索到TRI主程序，请输入主程序路径：
	set /p ictpath=^(也可将主程序拖如此窗口^)：
	set ictpath=!ictpath:"=!
	if exist "!ictpath!" if /i "!ictpath:~-4!"==".exe" echo "!ictpath!">ictpath.ini&start "" "!ictpath!"&goto ictopenover
	
) else goto :eof
:ictopenover
cls
echo=		      帐户登陆
echo=
echo=		操作者：TRI   (大写)
echo=		密码：  TRI   (大写)
echo=		工号：	120137853
echo=
echo=	20秒钟后自动跳转到ICT工具箱主菜单
ping -n 20 127.1 >nul 2>nul
goto :eof

:filesearch
cls
set drive=&set userfilename=&set userdrive=&set filesearchdijia=&set tempuserdrive=
for %%a in (A:\ B:\ C:\ D:\ E:\ F:\ G:\ H:\ I:\ J:\ K:\ L:\ M:\ N:\ O:\ P:\ Q:\ R:\ S:\ T:\ U:\ V:\ W:\ X:\ Y:\ Z:\) do if exist %%a set drive=!drive! %%a
if "%drive:~4%"=="" set userdrive=%drive%&echo=当前磁盘只有一个分区!userdrive!&goto filesearchfilename
echo=&echo=_______________________文件搜索_______________________&echo=
if defined result echo 提示：&echo      %result%&set result=&echo=
echo= 当前主机分区  %drive:\=%
echo=______________________________________________________
echo=                   搜索全盘请输入 ALL , 返回请输入 QQ
set /p userdrive=请输入要搜索的盘符：
if not defined userdrive goto filesearch
if /i "%userdrive%"=="qq" goto mainmenu
if /i "%userdrive%"=="all" set userdrive=%drive%&goto filesearchfilename
if not "%userdrive:~1,1%"=="" goto filesearch
echo %userdrive%|findstr [a-z]>nul
if not "%errorlevel%"=="0" (goto filesearch) else set userdrive=%userdrive%:\
if not exist %userdrive% set result=分区 %userdrive% 不存在,请检查后重试&goto filesearch
:filesearchfilename
set /p userfilename=请输入要搜索的文件名：
if not defined userfilename goto filesearchfilename
echo=正在搜索文件"%userfilename:"=%"，请稍等...
echo=&echo=_______________________搜索结果_______________________
for %%a in (%userdrive%) do set tempuserdrive=%%a&call:filesearchstart
if not defined filesearchdijia set filesearchdijia=0
echo=&echo=搜索完毕,搜索%userfilename:"=%共找到%filesearchdijia%个文件%&pause>nul
goto mainmenu
:filesearchstart
for /r %tempuserdrive% %%b in (%userfilename%) do if exist "%%b" echo %%b&set /a filesearchdijia+=1
goto :eof

:ictenglish
cls
echo=&echo=____________________ICT常见英语解释___________________&echo=
echo=      TEST  - tai_si_te    - 测试  -ICT测试 治具首按键
echo=      ABORT - e_bao_er_te  - 停止  -        治具中按键
echo=      DOWN  - da_wen       - 下降  -        治具尾按键
echo=      PASS  - pa_si        - 通过  -          良品标识
echo=      FAIL  - fei_ou       - 失败  -        不良品标识
echo=     SHORT  - shao_er_te   - 短小  -      短路不良标识
echo=      SAVE  - sei_fu       - 保存
echo=     PRINT  - pu_rin_te    - 打印  -      打印不良标识
echo=     WI/SOP -                               作业指导书
echo=      GO/NO-GO Sample -
echo=        - gou_no_gou_sai_mu_pou    -   良品/不良品样机
echo=______________________________________________________
pause>nul&goto mainmenu

:about
cls
set space1=                          
set space2=                              
for /l %%a in (1,1,6) do echo=
echo=%space1%F_Ms
echo=
echo=%space2%ICT工具箱
echo=%space2%2014年12月-2015年3月
echo=%space2%勤工俭学ChiconyPower
echo=%space2%任L18线ICT测试作业员
echo=%space2%为便于查看当日已测试
echo=%space2%通过的板机数量从而估
echo=%space2%测剩余工作时间和记录
echo=%space2%不良品错误原因统计和
echo=%space2%搜索而于工作闲暇时间
echo=%space2%创作此BAT
pause>nul&goto mainmenu