@echo off
REM 宏观配置
setlocal ENABLEDELAYEDEXPANSION

:-----主命令区开始标记-----:
REM 设置版本及更新信息
set project=EasyDownloadNetShopPic
set version=20151127
set updateUrl=http://imfms.vicp.net

color 0a
cd /d "%~dp0"
set debug=1
set debug1=1

if defined MYFILES set path=%path%;%MYFILES%
title EDNSP网店图片离线工具 - F_Ms - %version%

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
if /i "%os%"=="WinXP" (
	echo=	#注意：Win7以下级别操作系统可能无法正常运行
	pause
)


REM 自动检测更新
if not "%debug1%"=="0" call:UpdateProjectVersion %project% %version% %updateUrl% "%~0"

:Begin
REM 初始化各变量
for %%a in (Url UrlType #UrlType UrlFile UrlTitle UrlStoreName UrlSellPoint KuDir UrlColorKind PictureDownloadUrlManage) do if defined %%a set %%a=
for %%a in (UrlSellPoint UrlColorKind UrlMainPicture UrlDetail UrlAttrib #UrlAttrib) do if defined %%a_Count set %%a_Count=
for %%a in (UrlSellPoint UrlColorKind UrlAttrib UrlMainPicture UrlDetail) do if defined %%a_File set %%a_File=
for %%a in (UrlColorKind UrlAttrib UrlMainPicture) do if defined %%a_Temp set %%a_Temp=

for /l %%a in (1,1,5) do if defined UrlSellPoint%%a set UrlSellPoint%%a=
for /l %%a in (1,1,30) do if defined UrlAttrib%%a set UrlAttrib%%a=
for /l %%a in (1,1,30) do if defined #UrlAttrib%%a set #UrlAttrib%%a=

	if "%debug1%"=="0" (
		set UrlFile=TMP\TB_Download20102321035977.TMP
		REM set UrlFile=TMP\袜子.TMP
		set UrlType=阿里巴巴
		set #UrlType=alibaba
		goto EasyDownloadNetShopPic_Debug
	)

cls
echo=#介绍
echo=			EDNSP 网店图片离线工具
echo=			EasyDownloadNetShopPic
echo=
echo=	本工具支持离线 淘宝、天猫、阿里巴巴 网店的图片到本地
echo=
echo=	 作者：F_Ms ^| 邮箱：imf_ms@yeah.net ^| 博客：f-ms.cn
echo=
echo=			   -版本:%version%-
echo=

REM 提示用户输入网址
:UserInputUrl
set /p Url=#请输入网店商品网址:
if not defined Url (
	echo=	#输入为空，请重试
	echo=
	goto Begin
)
set Url="%Url:"=%"

REM 检查网址
if /i not "%Url:~1,7%"=="http://" if /i not "%Url:~1,8%"=="https://" (
	echo=	#错误，请补全网址：需包含http://或https://
	goto Begin
)
for /f "tokens=2,3,4 delims=/." %%a in ("%Url:"=%") do (
	if /i "%%~c"=="com" (
		if /i "%%~b"=="taobao" (
			set UrlType=淘宝
			set #UrlType=taobao
			goto UrlCheckOver
		)
		if /i "%%~b"=="tmall" (
			set UrlType=天猫
			set #UrlType=tmall
			goto UrlCheckOver
		)
		if /i "%%~b"=="1688" (
			set UrlType=阿里巴巴
			set #UrlType=alibaba
			goto UrlCheckOver
		)
		
	) else (
		if /i "%%~a"=="taobao" if /i "%%~b"=="com" (
			set UrlType=淘宝
			goto UrlCheckOver
		)
		if /i "%%~a"=="tmall" if /i "%%~b"=="com" (
			set UrlType=天猫
			goto UrlCheckOver
		)
		if /i "%%~a"=="1688" if /i "%%~b"=="com" (
			set UrlType=阿里巴巴
			goto UrlCheckOver
		)
		
	)
)

echo=	#%Url%:非淘宝、天猫、或阿里巴巴网址，请重试
goto Begin

:UrlCheckOver
cls
REM 生成随机文件名
if not exist "TMP\" md "TMP"
set UrlFile=TMP\TB_Download%random%%random%%random%.TMP

REM 下载网页源文件
:DownloadUrl
echo=#正在下载商品网页源文件
aria2c -o "%UrlFile%" %Url%>nul
if not "%errorlevel%"=="0" (
	echo=	#下载失败，正在重试
	goto DownloadUrl
)

REM 前期网页文件基本处理
call:EraseSpace "%UrlFile%"

:!!!!!!!!
:EasyDownloadNetShopPic_Debug
:!!!!!!!!


if "%UrlType%"=="天猫" goto TmallDownload
if "%UrlType%"=="阿里巴巴" goto AlibabaDownload
if "%UrlType%"=="淘宝" goto TaobaoDownload

goto UrlPicDownloadOver

REM 淘宝偷图脚本
:TaobaoDownload
REM 获取商品关键字
echo=#正在获取商品关键字
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-main-title"
if "%errorlevel%"=="0" (
	echo=	#您输入的可能不是商品地址，如继续可能会下载失败
	pause
)
call:ChooseOneLine "%UrlFile%" %errorlevel% 1 UrlTitle
for /f tokens^=4^ delims^=^" %%a in ("%UrlTitle%") do set UrlTitle=%%a
echo=
echo=		%UrlTitle%
echo=

REM 获取店铺名
echo=#正在获取店铺名
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-shop-name" 1 5
call:ChooseOneLine "%UrlFile%" %errorlevel% 1 UrlStoreName
echo=
echo=		%UrlStoreName%
echo=

REM 创建存储目录
echo=#正在创建商品资源存储目录
set KuDir=%UrlType%_%UrlStoreName%-%UrlTitle%
title EDNSP网店图片离线工具-正在离线:%KuDir%
if not "%debug1%"=="0" if exist "%KuDir%\" (
	echo=	#发现存在下载目录"%KuDIr%",疑似本网址信息曾经下载过,请检查后重试
	pause>nul
	goto Begin
)
for %%a in (主图 详情 颜色分类) do (
	if not exist "%KuDir%\%%a" md "%KuDir%\%%a"
)
echo=start "" %url%>"%KuDIr%\打开源店铺.bat"

REM 写入商品信息
echo=#商城>>"%KuDIr%\商品信息.txt"
echo=	%UrlType%>>"%KuDIr%\商品信息.txt"
echo=#店铺名>>"%KuDIr%\商品信息.txt"
echo=	%UrlStoreName%>>"%KuDIr%\商品信息.txt"
echo=#商品关键字>>"%KuDIr%\商品信息.txt"
echo=	%UrlTitle%>>"%KuDIr%\商品信息.txt"

REM 获取商品卖点
echo=#正在获取商品卖点
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-subtitle"
call:ChooseOneLine "%UrlFile%" %errorlevel% 1 UrlSellPoint
for /f tokens^=3^ delims^=^" %%a in ("%UrlSellPoint%") do set UrlSellPoint=%%a
for /f "delims=><" %%a in ("%UrlSellPoint%") do set UrlSellPoint=%%a
if /i "%UrlSellPoint%"=="/p" (
	echo=	#无商品卖点
	goto %#UrlType%GetUrlSellPointOver
)
echo=
echo=		%UrlSellPoint%
echo=
echo=
echo=#商品卖点>>"%KuDIr%\商品信息.txt"
echo=	%UrlSellPoint%>>"%KuDIr%\商品信息.txt"
:taobaoGetUrlSellPointOver

REM 获取颜色分类
echo=#正在获取商品颜色分类
echo=
call:GetKeyWordLineNumberInFile "%UrlFile%" "J_TSaleProp tb-img tb-clearfix"
if "%errorlevel%"=="0" (
	echo=	#无颜色分类
	goto %#UrlType%GetUrlColorKindOver
)
set UrlColorKind_Temp=%errorlevel%
set UrlColorKind_File=TMP\TMP%random%%random%%random%.TMP
call:FindKeywordsCountInFile "%UrlFile%" "<li data-value="
call:GetKeyWordLineNumberInFile "%UrlFile%" "<li data-value=" %errorlevel% 4-%UrlColorKind_Temp%
call:ChooseOneLine "%UrlFile%" %UrlColorKind_Temp% %errorlevel% /f "%UrlColorKind_File%"
findstr /il "<span> href=" "%UrlColorKind_File%">"%UrlColorKind_File%2"
for /f "tokens=2 delims=<>" %%a in ('findstr /lic:"span" "%UrlColorKind_File%2"') do (
	set /a UrlCOlorKind_Count+=1
	set UrlCOlorKind!UrlCOlorKind_count!=%%a
)
echo=
echo=#颜色分类>>"%KuDir%\商品信息.txt"
for /l %%a in (1,1,%UrlColorKind_Count%) do (
	echo=	%%a.	!UrlColorKind%%a!
	call:GetKeyWordLineNumberInFile "%UrlColorKind_File%2" "!UrlColorKind%%a!" 1 -1
	call:ChooseOneLine "%UrlColorKind_File%2" !errorlevel! 1 PictureDownloadUrlManage
	call:PictureDownloadUrlManage 2 -10
	call:Convert2OK_Name UrlColorKind%%a
	if exist "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" !PictureDownloadUrlManage!>nul
		if "!errorlevel!"=="3" start /min /wait "" download.bat "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" !PictureDownloadUrlManage!
	)
	if not exist "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" echo=			#无图或图片下载失败:!PictureDownloadUrlManage!
	echo=	!UrlColorKind%%a!>>"%KuDir%\商品信息.txt"
)
echo=
:taobaoGetUrlColorKindOver

REM 获取商品主图
echo=#正在获取商品主图
echo=


call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-pic tb-s50"
set UrlMainPicture_Temp=%errorlevel%
set UrlMainPicture_File=TMP\UrlMainPicture%random%%random%%random%.TMP
call:FindKeywordsCountInFile "%UrlFile%" "tb-pic tb-s50"
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-pic tb-s50" %errorlevel% 2-%UrlMainPicture_Temp%
call:ChooseOneLine "%UrlFile%" %UrlMainPicture_Temp% %errorlevel% /f "%UrlMainPicture_File%"
for /f tokens^=4^ delims^=^" %%a in ('findstr /lic:"src=" "%UrlMainPicture_File%"') do (
	set /a UrlMainPicture_Count+=1
	echo=	!UrlMainPicture_Count!.	!UrlMainPicture_Count!.jpg
	set PictureDownloadUrlManage=%%a
	set PictureDownloadUrlManage="http://!PictureDownloadUrlManage:~2,-10!"
	if exist "%KuDir%\主图\!UrlMainPicture_Count!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\主图\!UrlMainPicture_Count!.jpg" !PictureDownloadUrlManage! >nul
		if not "!errorlevel!"=="0" start /min /wait "" download.bat "%KuDir%\主图\!UrlMainPicture_Count!.jpg" !PictureDownloadUrlManage!
	)
	if not exist "%KuDir%\主图\!UrlMainPicture_Count!.jpg" echo=			#无图或图片下载失败:!PictureDownloadUrlManage!
)
echo=

REM 获取商品属性
echo=#正在获取商品属性
echo=
echo=#商品属性>>"%KuDir%\商品信息.txt"
call:GetKeyWordLineNumberInFile "%UrlFile%" "attributes-list"
set UrlAttrib_Temp=%errorlevel%
set UrlAttrib_File=TMP\UrlAttrib%random%%random%%random%.TMP
call:GetKeyWordLineNumberInFile "%UrlFile%" "data-item-id=" 1 -%UrlAttrib_Temp%
call:ChooseOneLine "%UrlFile%" %UrlAttrib_Temp% %errorlevel% /f "%UrlAttrib_File%"
strrpc /s:"%UrlAttrib_File%" /c "("
strrpc /s:"%UrlAttrib_File%" /c ")"
for /f tokens^=2^,3^ delims^=^<^:^>^" %%a in ('findstr /lic:"title=" "%UrlAttrib_File%"') do (
	echo=	%%b	%%a
	echo=	%%b	%%a>>"%KuDir%\商品信息.txt"
)
echo=

REM 获取商品详情
set UrlDetail_File=TMP\UrlDetail%random%%random%%random%.TMP
if not exist "TMP\ClipTMP.TMP" echo=>"TMP\ClipTMP.TMP"
winclip -c "TMP\ClipTMP.TMP"
if exist "TMP\ClipTMP.TMP" del /f /q "TMP\ClipTMP.TMP"
echo=#正要获取商品详情,由于详情获取的特殊,需使用者操作一些内容
echo=	请用浏览器在商品页面加载完毕后按键盘 "F12" 键唤出审查元素开发人员工具
echo=		(如无法唤出开发人员工具请使用尝试其它浏览器，如:Chrome;猎豹;360)
echo=	将内容第二行 以^<html=开头的内容 复制即可
echo=
:taobaoGetUrlDetail3
ping -n 3 127.1>nul 2>nul
if exist "%UrlDetail_File%" del /f /q "%UrlDetail_File%"
winclip -p "%UrlDetail_File%"
for %%a in ("%UrlDetail_File%") do if "%%~za"=="2" (
	goto %#UrlType%GetUrlDetail3
) else (
	findstr /c:"描述加载中" "%UrlDetail_File%">nul
	if "!errorlevel!"=="0" goto %#UrlType%GetUrlDetail3
	findstr /c:"J_DivItemDesc" "%UrlDetail_File%">nul
	if not "!errorlevel!"=="0" goto %#UrlType%GetUrlDetail3
)
call:EraseSpace "%UrlDetail_File%"
echo=#正在获取商品详情
echo=
for /f tokens^=2^ delims^=^" %%a in ('findstr /c:"J_DivItemDesc" "%UrlDetail_File%"^|sed s/" "/\n/g^|sed s/"?"/\n/g^|findstr /ilc:"src="') do (
	set /a UrlDetail_Count+=1
	echo=	!UrlDetail_Count!.	!UrlDetail_Count!%%~xa
	if exist "%KuDir%\详情\!UrlDetail_Count!%%~xa" (echo=			#图片已存在) else aria2c -o "%KuDir%\详情\!UrlDetail_Count!%%~xa" "%%~a">nul
	if not "!errorlevel!"=="0" start /min /wait "" download.bat "%KuDir%\详情\!UrlDetail_Count!%%~xa" "%%~a"
)
echo=
goto UrlPicDownloadOver

goto UrlPicDownloadOver

REM 天猫偷图脚本
:TmallDownload
REM 获取商品关键字
echo=#正在获取商品关键字
call:GetKeyWordLineNumberInFile "%UrlFile%" "keywords"
if "%errorlevel%"=="0" (
	echo=	#您输入的可能不是商品地址，如继续可能会下载失败
	pause
)
call:ChooseOneLine "%UrlFIle%" %errorlevel% 1 UrlTitle
for /f "tokens=3,*" %%a in ("%UrlTitle%") do (
	if "%%~b"=="" (
		set UrlTitle=%%~a
	) else set UrlTitle=%%~a %%~b
)
for /f "tokens=2 delims==/>" %%a in ("%UrlTitle%") do set UrlTitle=%%~a
echo=
echo=		%UrlTitle%
echo=


REM 获取店铺名
echo=#正在获取店铺名
call:GetKeyWordLineNumberInFile "%UrlFile%" "slogo-shopname"
call:ChooseOneLine "%UrlFile%" %errorlevel% 1 UrlStoreName
for /f "tokens=4" %%a in ("%UrlStoreName%") do set UrlStoreName=%%~a
for /f "tokens=3 delims=<>" %%a in ("%UrlStoreName%") do set UrlStoreName=%%~a
echo=
echo=		%UrlStoreName%
echo=

REM 创建存储目录
echo=#正在创建商品资源存储目录
set KuDir=%UrlType%_%UrlStoreName%-%UrlTitle%
title EDNSP网店图片离线工具-正在离线:%KuDir%
if not "%debug1%"=="0" if exist "%KuDir%\" (
	echo=	#发现存在下载目录"%KuDIr%",疑似本网址信息曾经下载过,请检查后重试
	pause>nul
	goto Begin
)
for %%a in (主图 详情 颜色分类) do (
	if not exist "%KuDir%\%%a" md "%KuDir%\%%a"
)
echo=start "" %url%>"%KuDIr%\打开源店铺.bat"

REM 写入商品信息
echo=#商城>>"%KuDIr%\商品信息.txt"
echo=	%UrlType%>>"%KuDIr%\商品信息.txt"
echo=#店铺名>>"%KuDIr%\商品信息.txt"
echo=	%UrlStoreName%>>"%KuDIr%\商品信息.txt"
echo=#商品关键字>>"%KuDIr%\商品信息.txt"
echo=	%UrlTitle%>>"%KuDIr%\商品信息.txt"


REM 获取商品卖点
echo=#正在获取商品卖点
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-detail-hd" 1 5
call:ChooseOneLine "%UrlFile%" %errorlevel% 1 UrlSellPoint
if "%UrlSellPoint%"=="</p>" (
	set UrlSellPoint=
	echo=
	echo=		#无商品卖点
	echo=
	goto %#UrlType%GetUrlSellPointOver
)
call:Count 0 %UrlSellPoint%
set UrlSellPoint_Count=!errorlevel!
call:Content2Variable UrlSellPoint !UrlSellPoint_Count! %UrlSellPoint%
echo=
for /l %%a in (1,1,%UrlSellPoint_Count%) do echo=	%%a.	!UrlSellPoint%%a!
echo=

echo=#商品卖点>>"%KuDIr%\商品信息.txt"
(for /l %%a in (1,1,%UrlSellPoint_Count%) do echo=	!UrlSellPoint%%a!)>>"%KuDIr%\商品信息.txt"

:tmallGetUrlSellPointOver

REM 获取颜色分类
echo=#正在获取商品颜色分类
echo=
call:GetKeyWordLineNumberInFile "%UrlFile%" "tm-clear J_TSaleProp tb-img"
if "%UrlColorKind_Temp%"=="0" (
	echo=	#无颜色分类
	goto %#UrlType%GetUrlColorKindOver
)
set UrlColorKind_Temp=%errorlevel%
echo=#颜色分类>>"%KuDIr%\商品信息.txt"
set UrlColorKind_File=TMP\TMP%random%%random%%random%.TMP
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-amount tm-clear" 1 -%UrlColorKind_Temp%
call:ChooseOneLine "%UrlFile%" %UrlColorKind_Temp% %errorlevel% /f "%UrlColorKind_File%"
findstr /l "span href" "%UrlColorKind_File%">"%UrlColorKind_File%2"
for /f "tokens=2 delims=<>" %%a in ('findstr /lc:"span" "%UrlColorKind_File%2"') do (
	set /a UrlColorKind_Count+=1
	set UrlColorKind!UrlColorKind_count!=%%a
)
echo=
for /l %%a in (1,1,%UrlColorKind_Count%) do (
	echo=	%%a.	!UrlColorKind%%a!
	call:GetKeyWordLineNumberInFile "%UrlColorKind_File%2" "!UrlColorKind%%a!" 1 -1
	call:ChooseOneLine "%UrlColorKind_File%2" !errorlevel! 1 PictureDownloadUrlManage
	call:PictureDownloadUrlManage 2 -13
	call:Convert2OK_Name UrlColorKind%%a
	if exist "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" !PictureDownloadUrlManage!>nul
		if "!errorlevel!"=="3" start /min /wait "" download.bat "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" !PictureDownloadUrlManage!
	)
	if not exist "%KuDir%\颜色分类\!UrlColorKind%%a!.jpg" echo=			#无图或图片下载失败:!PictureDownloadUrlManage!
	echo=	!UrlColorKind%%a!>>"%KuDir%\商品信息.txt"
)
:tmallGetUrlColorKindOver
echo=

REM 获取主图
echo=#正在获取商品主图
echo=
call:GetKeyWordLineNumberInFile "%UrlFile%" "tb-selected"
set UrlMainPicture_Temp=%errorlevel%
set UrlMainPicture_File=TMP\UrlMainPicture%random%%random%%random%.TMP
call:GetKeyWordLineNumberInFile "%UrlFile%" "tm-action tm-clear" 1 -%errorlevel%
call:ChooseOneLine "%UrlFile%" %UrlMainPicture_Temp% %errorlevel% /f "%UrlMainPicture_File%"
echo=
for /f tokens^=4^ delims^=^" %%a in ('findstr /ilc:"img" "%UrlMainPicture_File%"') do (
	set /a UrlMainPicture_Count+=1
	echo=	!UrlMainPicture_Count!.	!UrlMainPicture_Count!.jpg
	set PictureDownloadUrlManage=%%a
	set PictureDownloadUrlManage="http://!PictureDownloadUrlManage:~2,-13!"
	if exist "%KuDir%\主图\!UrlMainPicture_Count!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\主图\!UrlMainPicture_Count!.jpg" !PictureDownloadUrlManage! >nul
		if not "!errorlevel!"=="0" start /min /wait "" download.bat "%KuDir%\主图\!UrlMainPicture_Count!.jpg" !PictureDownloadUrlManage!
	)
	if not exist "%KuDir%\主图\!UrlMainPicture_Count!.jpg" echo=			#无图或图片下载失败:!PictureDownloadUrlManage!
)
echo=

REM 获取商品属性
echo=#正在获取商品属性
echo=
echo=#商品属性>>"%KuDir%\商品信息.txt"
call:GetKeyWordLineNumberInFile "%UrlFIle%" "J_AttrUL"
set UrlAttrib_Temp=%errorlevel%
set UrlAttrib_File=TMP\UrlAttrib%random%%random%%random%.TMP
call:GetKeyWordLineNumberInFile "%UrlFile%" "健字号相关" 1 -%UrlAttrib_Temp%
call:ChooseOneLine "%UrlFile%" %UrlAttrib_Temp% %errorlevel% /f "%UrlAttrib_File%"
strrpc /s:"%UrlAttrib_File%" /c "("
strrpc /s:"%UrlAttrib_File%" /c ")"
for /f "tokens=1,2,3,4 delims=<>:" %%a in ('findstr /i /v "颜色分类 J_AttrUl" "%UrlAttrib_File%"') do (
	set UrlAttrib_Temp2=
	if "%%a"==" " (set UrlAttrib_Temp2=%%d) else set UrlAttrib_Temp2=%%c
	call:ReplaceVariableContent UrlAttrib_Temp2 ";" " " ":" " " "#" " " "&" " "
	call:UnicodeConvert UrlAttrib_Temp3 !UrlAttrib_Temp2:"=!
	if "%%a"==" " (
		echo=	%%c	!UrlAttrib_Temp3!
		echo=	%%c !UrlAttrib_Temp3!>>"%KuDir%\商品信息.txt"
	) else (
		echo=	%%b	!UrlAttrib_Temp3!
		echo=	%%b !UrlAttrib_Temp3!>>"%KuDir%\商品信息.txt"
	)
)
echo=

REM 获取商品详情
set UrlDetail_File=TMP\UrlDetail%random%%random%%random%.TMP
if not exist "TMP\ClipTMP.TMP" echo=>"TMP\ClipTMP.TMP"
winclip -c "TMP\ClipTMP.TMP"
if exist "TMP\ClipTMP.TMP" del /f /q "TMP\ClipTMP.TMP"
echo=#正要获取商品详情,由于详情获取的特殊,需使用者操作一些内容
echo=	请用浏览器在商品页面加载完毕后按键盘 "F12" 键唤出审查元素开发人员工具
echo=		(如无法唤出开发人员工具请使用尝试其它浏览器，如:Chrome;猎豹;360)
echo=	将内容第二行 以^<html=开头的内容 复制即可
echo=
:tmallGetUrlDetail3
ping -n 3 127.1>nul 2>nul
if exist "%UrlDetail_File%" del /f /q "%UrlDetail_File%"
winclip -p "%UrlDetail_File%"
for %%a in ("%UrlDetail_File%") do if "%%~za"=="2" (
	goto %#UrlType%GetUrlDetail3
) else (
	findstr /c:"content ke-post" "%UrlDetail_File%">nul
	if not "!errorlevel!"=="0" goto %#UrlType%GetUrlDetail3
)
call:EraseSpace "%UrlDetail_File%"
echo=#正在获取商品详情
echo=
for /f tokens^=2^ delims^=^" %%a in ('findstr /c:"content ke-post" "%UrlDetail_File%"^|sed s/" "/\n/g^|sed s/"?"/\n/g^|findstr /i "https"') do (
	set /a UrlDetail_Count+=1
	echo=	!UrlDetail_Count!.	!UrlDetail_Count!%%~xa
	if exist "%KuDir%\详情\!UrlDetail_Count!%%~xa" (echo=			#图片已存在) else aria2c -o "%KuDir%\详情\!UrlDetail_Count!%%~xa" "%%~a">nul
	if not "!errorlevel!"=="0" start /min /wait "" download.bat "%KuDir%\详情\!UrlDetail_Count!%%~xa" "%%~a"
)
echo=
goto UrlPicDownloadOver


goto UrlPicDownloadOver
REM 阿里巴巴偷图脚本
:AlibabaDownload
REM 获取商品关键字
echo=#正在获取商品关键字
call:GetKeyWordLineNumberInFile "%UrlFile%" "og:title"
if "%errorlevel%"=="0" (
	echo=	#您输入的可能不是商品地址，如继续可能会下载失败
	pause
)
call:ChooseOneLine "%UrlFIle%" %errorlevel% 1 UrlTitle
for /f "tokens=3,*" %%a in ("%UrlTitle%") do (
	if "%%~b"=="" (
		set UrlTitle=%%~a
	) else set UrlTitle=%%~a %%~b
)
for /f "tokens=2 delims==/>" %%a in ("%UrlTitle%") do set UrlTitle=%%~a
echo=
echo=		%UrlTitle%
echo=


REM 获取店铺名
echo=#正在获取店铺名
call:GetKeyWordLineNumberInFile "%UrlFile%" "og:product:nick"
call:ChooseOneLine "%UrlFile%" %errorlevel% 1 UrlStoreName
for /f tokens^=4^ delims^=^" %%a in ("%UrlStoreName%") do set UrlStoreName=%%~a
for /f "tokens=2" %%a in ("%UrlStoreName%") do set UrlStoreName=%%~a
echo=
echo=		%UrlStoreName%
echo=


REM 创建存储目录
echo=#正在创建商品资源存储目录
set KuDir=%UrlType%_%UrlStoreName%-%UrlTitle%
title EDNSP网店图片离线工具-正在离线:%KuDir%
if not "%debug1%"=="0" if exist "%KuDir%\" (
	echo=	#发现存在下载目录"%KuDIr%",疑似本网址信息曾经下载过,请检查后重试
	pause>nul
	goto Begin
)
for %%a in (主图 详情 颜色分类) do (
	if not exist "%KuDir%\%%a" md "%KuDir%\%%a"
)
echo=start "" %url%>"%KuDIr%\打开源店铺.bat"

REM 写入商品信息
echo=#商城>>"%KuDIr%\商品信息.txt"
echo=	%UrlType%>>"%KuDIr%\商品信息.txt"
echo=#店铺名>>"%KuDIr%\商品信息.txt"
echo=	%UrlStoreName%>>"%KuDIr%\商品信息.txt"
echo=#商品关键字>>"%KuDIr%\商品信息.txt"
echo=	%UrlTitle%>>"%KuDIr%\商品信息.txt"

REM 获取颜色分类
echo=#正在获取商品颜色分类
echo=
call:GetKeyWordLineNumberInFile "%UrlFile%" "unit-detail-spec-operator"
if "%errorlevel%"=="0" (
	goto %#UrlType%GetUrlColorKind2
)
set UrlColorKind_Temp=%errorlevel%
echo=#颜色分类>>"%KuDIr%\商品信息.txt"
set UrlColorKind_File=TMP\TMP%random%%random%%random%.TMP
call:FindKeywordsCountInFile "%UrlFile%" "unit-detail-spec-operator"
call:GetKeyWordLineNumberInFile "%UrlFile%" "unit-detail-spec-operator" %errorlevel% 6-%UrlColorKind_Temp%
call:ChooseOneLine "%UrlFile%" %UrlColorKind_Temp% %errorlevel% /f "%UrlColorKind_File%"
for /f tokens^=6^ delims^=^" %%a in ('findstr /lic:"unit-detail-spec-operator" "%UrlColorKind_File%"') do echo=	%%~a>>"%KuDir%\商品信息.txt"
for /f tokens^=4^,6^ delims^=^" %%a in ('findstr /l "data-lazy-src=" "%UrlColorKind_File%"') do (
	set pictureDownloadUrlManage=
	set /a UrlColorKind_Count+=1
	set UrlColorKind!UrlColorKind_Count!=%%~b
	echo=	!UrlColorKind_Count!.	%%~b
	set pictureDownloadUrlManage=%%~a
	set pictureDownloadUrlManage=!pictureDownloadUrlManage:~0,-10!%%~xa
	set UrlColorKind1=
	set UrlColorKind1=%%~b
	call:Convert2OK_Name UrlColorKind1
	if exist "%KuDir%\颜色分类\!UrlColorKind1!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\颜色分类\!UrlColorKind1!.jpg" !PictureDownloadUrlManage!>nul
		if "!errorlevel!"=="3" start /min /wait "" download.bat "%KuDir%\颜色分类\!UrlColorKind1!.jpg" !PictureDownloadUrlManage!
	)
	if not exist "%KuDir%\颜色分类\!UrlColorKind1!.jpg" echo=			#无图或图片下载失败:!PictureDownloadUrlManage!
)

:alibabaGetUrlColorKind2

call:GetKeyWordLineNumberInFile "%UrlFile%" ">颜色</span>"
if "%errorlevel%"=="0" (
	echo=	#无颜色分类
	goto %#UrlType%GetUrlColorKindOver
)
set UrlColorKind_Temp=%errorlevel%
call:FindKeywordsCountInFile "%UrlFile%" "data-sku-config"
call:GetKeyWordLineNumberInFile "%UrlFile%" "data-sku-config" %errorlevel% 30-%UrlColorKind_Temp%
echo=#颜色分类>>"%KuDIr%\商品信息.txt"
set UrlColorKind_File=TMP\TMP%random%%random%%random%.TMP
call:ChooseOneLine "%UrlFile%" %UrlColorKind_Temp% %errorlevel% /f "%UrlColorKind_File%"
for /f tokens^=4^,6^ delims^=^" %%a in ('findstr /lic:"data-sku-config" "%UrlColorKind_File%"') do (
	if /i "%%a"=="skuName" (echo=	%%~b>>"%KuDir%\商品信息.txt") else echo=	%%~a>>"%KuDir%\商品信息.txt"
)
for /f tokens^=4^,12^ delims^=^" %%a in ('findstr /lic:"data-imgs=" "%UrlColorKind_File%"') do (
	set /a UrlColorKind_Count+=1
	echo=	!UrlColorKind_Count!.	%%~a
	set UrlColorKind1=
	set UrlColorKind1=%%~a
	call:Convert2OK_Name UrlColorKind1
	if exist "%KuDir%\颜色分类\!UrlColorKind1!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\颜色分类\!UrlColorKind1!.jpg" %%~b>nul
		if "!errorlevel!"=="3" start /min /wait "" download.bat "%KuDir%\颜色分类\!UrlColorKind1!.jpg" "%%~b"
	)
	if not exist "%KuDir%\颜色分类\!UrlColorKind1!.jpg" echo=			#无图或图片下载失败:%%~b
)

:alibabaGetUrlColorKindOver
echo=

REM 获取主图
echo=#正在获取商品主图
echo=
call:GetKeyWordLineNumberInFile "%UrlFile%" "tab-content-container"
set UrlMainPicture_Temp=%errorlevel%
set UrlMainPicture_File=TMP\UrlMainPicture%random%%random%%random%.TMP
call:FindKeywordsCountInFile "%UrlFile%" "tab-trigger"
call:GetKeyWordLineNumberInFile "%UrlFile%" "tab-trigger" %errorlevel% 1-%UrlMainPicture_Temp%
call:ChooseOneLine "%UrlFile%" %UrlMainPicture_Temp% %errorlevel% /f "%UrlMainPicture_File%"
for /f tokens^=10^ delims^=^" %%a in ('findstr /ilc:"tab-trigger" "%UrlMainPicture_File%"') do (
	set /a UrlMainPicture_Count+=1
	echo=	!UrlMainPicture_Count!.	!UrlMainPicture_Count!.jpg
	if exist "%KuDir%\主图\!UrlMainPicture_Count!.jpg" (echo=			#图片已存在) else (
		aria2c -o "%KuDir%\主图\!UrlMainPicture_Count!.jpg" "%%~a" >nul
		if not "!errorlevel!"=="0" start /min /wait "" download.bat "%KuDir%\主图\!UrlMainPicture_Count!.jpg" "%%~a"
	)
	if not exist "%KuDir%\主图\!UrlMainPicture_Count!.jpg" echo=			#无图或图片下载失败:"%%~a"
)
echo=

REM 获取商品属性
echo=#正在获取商品属性
echo=
echo=#商品属性>>"%KuDir%\商品信息.txt"
call:GetKeyWordLineNumberInFile "%UrlFIle%" "mod-detail-attributes"
set UrlAttrib_Temp=%errorlevel%
set UrlAttrib_File=TMP\UrlAttrib%random%%random%%random%.TMP
call:FindKeywordsCountInFile "%UrlFile%" "de-value"
call:GetKeyWordLineNumberInFile "%UrlFile%" "de-value" %errorlevel% 1-%UrlAttrib_Temp%
call:ChooseOneLine "%UrlFile%" %UrlAttrib_Temp% %errorlevel% /f "%UrlAttrib_File%"
strrpc /s:"%UrlAttrib_File%" /c "("
strrpc /s:"%UrlAttrib_File%" /c ")"
(for /f tokens^=3^ delims^=^" %%a in ('findstr /lic:"de-feature" "%UrlAttrib_File%"') do @echo="%%a")>"%UrlAttrib_File%2"
for /f "usebackq tokens=2 delims=<>" %%a in ("%UrlAttrib_File%2") do (
	set /a UrlAttrib_Count+=1
	set UrlAttrib!UrlAttrib_Count!=%%~a
)

for /f "tokens=2 delims=<>" %%a in ('findstr /lic:"de-value" "%UrlAttrib_File%"') do (
	set /a #UrlAttrib_Count+=1
	set #UrlAttrib!#UrlAttrib_Count!=%%~a
)

for /l %%a in (1,1,%UrlAttrib_Count%) do (
	echo=	!UrlAttrib%%a!	!#UrlAttrib%%a! 
	echo=	!UrlAttrib%%a!	!#UrlAttrib%%a!>>"%KuDir%\商品信息.txt"
)
echo=

REM 获取商品详情
set UrlDetail_File=TMP\UrlDetail%random%%random%%random%.TMP
if not exist "TMP\ClipTMP.TMP" echo=>"TMP\ClipTMP.TMP"
winclip -c "TMP\ClipTMP.TMP"
if exist "TMP\ClipTMP.TMP" del /f /q "TMP\ClipTMP.TMP"
echo=#正要获取商品详情,由于详情获取的特殊,需使用者操作一些内容
echo=	请用浏览器在商品页面加载完毕后按键盘 "F12" 键唤出审查元素开发人员工具
echo=		(如无法唤出开发人员工具请使用尝试其它浏览器，如:Chrome;猎豹;360)
echo=	将内容第二行 以^<html=开头的内容 复制即可
echo=
:alibabaGetUrlDetail3
ping -n 3 127.1>nul 2>nul
if exist "%UrlDetail_File%" del /f /q "%UrlDetail_File%"
winclip -p "%UrlDetail_File%"
for %%a in ("%UrlDetail_File%") do if "%%~za"=="2" (
	goto %#UrlType%GetUrlDetail3
) else (
	findstr /c:"desc-lazyload-container" "%UrlDetail_File%">nul
	if not "!errorlevel!"=="0" goto %#UrlType%GetUrlDetail3
)
call:EraseSpace "%UrlDetail_File%"
echo=#正在获取商品详情
echo=
for /f tokens^=2^ delims^=^" %%a in ('findstr /c:"desc-lazyload-container" "%UrlDetail_File%"^|sed s/" "/\n/g^|sed s/"?"/\n/g^|findstr /ilc:"src="') do (
	set /a UrlDetail_Count+=1
	echo=	!UrlDetail_Count!.	!UrlDetail_Count!%%~xa
	if exist "%KuDir%\详情\!UrlDetail_Count!%%~xa" (echo=			#图片已存在) else aria2c -o "%KuDir%\详情\!UrlDetail_Count!%%~xa" "%%~a">nul
	if not "!errorlevel!"=="0" start /min /wait "" download.bat "%KuDir%\详情\!UrlDetail_Count!%%~xa" "%%~a"
)
echo=
goto UrlPicDownloadOver



:UrlPicDownloadOver

REM 检查并更改文件名为规范文件名
echo=#正在规范文件名

for /r "%cd%\%KuDir%\详情\" %%a in (*.*) do if exist "%%~a" (
	set changeFileName_Temp=
	set changeFileName_Temp=%%~na
	if "!changeFileName_Temp:~2,1!"=="" (
		if "!changeFileName_Temp:~1,1!"=="" (
			if exist "%%~dpa00%%~nxa" del /f /q "%%~dpa00%%~nxa"
			ren "%%~a" "00%%~nxa"
		) else (
			if exist "%%~dpa0%%~nxa" del /f /q "%%~dpa0%%~nxa"
			ren "%%~a" "0%%~nxa"
		)
	)
)

for /r "%cd%\%KuDir%\主图\" %%a in (*.*) do if exist "%%~a" (
	set changeFileName_Temp=
	set changeFileName_Temp=%%~na
	if "!changeFileName_Temp:~2,1!"=="" (
		if "!changeFileName_Temp:~1,1!"=="" (
			if exist "%%~dpa00%%~nxa" del /f /q "%%~dpa00%%~nxa"
			ren "%%~a" "00%%~nxa"
		) else (
			if exist "%%~dpa0%%~nxa" del /f /q "%%~dpa0%%~nxa"
			ren "%%~a" "0%%~nxa"
		)
	)
)


explorer "%KuDIr%"

REM 删除生成的临时文件
if not "%debug1%"=="0" for %%a in (UrlSellPoint_File UrlColorKind_File UrlAttrib_File UrlFile UrlDetail_File UrlMainPicture_File) do (
	if exist "!%%a!" del /f /q "!%%a!"
	if exist "!%%a!2" del /f /q "!%%a!2"
)

echo=#完成,已打开所在目录,程序即将退出
ping -n 5 127.1>nul 2>nul
:-----主命令区结束标记-----:
:-----子程序开始标记-----:
goto end

REM call:PictureDownloadUrlManage 图片下载时调用功能
:PictureDownloadUrlManage
	for /f "tokens=2 delims=()" %%b in ("%PictureDownloadUrlManage:"=%") do (
		set PictureDownloadUrlManage=%%b
		set PictureDownloadUrlManage="http://!PictureDownloadUrlManage:~%~1,%~2!"
	)
goto :eof

REM call:ChooseOneLine "文件" 开始行 几行 [变量 | /f "文件"](多行内容必须写入到文件)
:从一个文件中指定某一行.将行内容赋值到变量或写入到文件
:ChooseOneLine
	REM 初始化子程序需求变量
	for %%Y in (subroutine chooseOneLine_Skip chooseOneLine_LineNumber chooseOneLine_Dijia) do if defined %%Y set %%Y=
	set subroutine=ChooseOneLine
	
	REM 检查子程序使用基本规则正确与否
	if "%~4"=="" (
		call:ShowErrorMessage [参数4]行内容留存方法选择
		exit/b 1
	)
	if /i "%~4"=="/f" if "%~5"=="" (
		call:ShowErrorMessage [参数5]%~5,指定行内容写入文件路径为空
		exit/b 1
	) else if exist "%~5" (
		call:ShowErrorMessage [参数5]%~5,指定行内容写入文件已存在
		exit/b 1
	)
	if "%~3"=="" (
		call:ShowErrorMessage [参数]指定几行为空
		exit/b 1
	) else if %~3 lss 1 (
		call:ShowErrorMessage [参数3]%~3,指定几行值小于1
		exit/b 1
	)
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]开始行为空
		exit/b 1
	) else if %~3 gtr 1 if /i not "%~4"=="/f" (
		call:ShowErrorMessage [参数2]%~3,当提取行数多于一行时只能将行内容存储到文件
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]指定抽取行源文件为空
		exit/b 1
	) else if not exist "%~1" (
		call:ShowErrorMessage [参数1]%~1,指定抽取行源文件不存在
		exit/b 1
	)
	
	REM 子程序运作开始
	set /a chooseOneLine_Skip=%~2-1
	if "%chooseOneLine_Skip%"=="0" (set chooseOneLine_Skip=) else set chooseOneLine_Skip=skip=%chooseOneLine_Skip%
	set chooseOneLine_LineNumber=%~3
	for /f "usebackq %chooseOneLine_Skip% delims=" %%Y in ("%~1") do (
		if "%~3"=="1" (
			if /i "%~4"=="/f" (
				echo=%%Y>"%~5"
				exit/b 0
			) else (
				set %~4=%%Y
				exit/b 0
			)
		) else (
			echo=%%Y>>"%~5"
			set /a chooseOneLine_Dijia+=1
			if "!chooseOneLine_Dijia!"=="%~3" exit/b 0
		)
	)
exit/b 0

REM call:ReplaceVariableContent 变量名 替换内容 被替换内容 替换内容2 被替换内容2 ... ...
:替换变量内容
:ReplaceVariableContent
	REM 初始化子程序需求变量
	for %%X in (subroutine) do if defined %%X set %%X=
	set subroutine=ReplaceVariableContent
	
	:ReplaceVariableContent2
	REM 检查子程序使用基本规则正确与否
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]替换内容为空
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]变量名为空
		exit/b 1
	) else  if not defined %1 (
		call:ShowErrorMessage [参数1]%1变量不存在
		exit/b 1
	)
	REM 子程序运作开始
	set %1="!%1:%~2=%~3!"
	if not "%~4"=="" (
		shift/2
		shift/2
		goto ReplaceVariableContent2
	)
exit/b 0

REM call:ChooseFromVariable 源变量名 以空格分隔第某个值 结果被赋值变量 [/nocheck](不进行检查值是否存在)
:从变量中寻找以空格分隔的第某几个值
:ChooseFromVariable
	REM 初始化子程序需求变量
	for %%w in (subroutine ChooseFromVariable_DiJia ChooseFromVariable_Temp) do if defined %%w set %%w=
	set subroutine=ChooseFromVariable
	
	REM 检查子程序使用基本规则正确与否
	if "%~3"=="" (
		call:ShowErrorMessage [参数3]结果被赋值变量为空
		exit/b 1
	)
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]第某个值指定为空
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]%~1变量名为空
		exit/b 1
	) else if not defined %~1 (
		call:ShowErrorMessage [参数1]变量未被赋值
		exit/b 1
	)
	
	if /i "%~4"=="/nocheck" goto ChooseFromVariable2
	call:Count 0 !%~1!
	if %~2 gtr %errorlevel% (
		call:ShowErrorMessage [其它]%~2指定值不存在
	)
	:ChooseFromVariable2
	
	REM 子程序运作开始
	set ChooseFromVariable_Temp=!%~1:"=!
	for %%w in (%ChooseFromVariable_Temp%) do (
		set /a ChooseFromVariable_DiJia+=1
		if "!ChooseFromVariable_DiJia!"=="%~2" set %~3=%%w
	)
exit/b 0

REM call:EraseSpace "文件1" "文件2" ...
:去除文件中缩进与空白空行
:EraseSpace
	REM 初始化子程序需求变量
	for %%x in (subroutine) do if defined %%x set %%x=
	set subroutine=EraseSpace
	
	:EraseSpace2
	REM 检查子程序使用基本规则正确与否
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]文件指定为空
		exit/b 1
	) else if not exist "%~1" (
		call:ShowErrorMessage [参数1]%~1文件不存在
		exit/b 1
	)
	
	REM 子程序运作开始
	strrpc /s:"%~1" /c "	"
	strrpc /s:"%~1" /c "  "
	strrpc /s:"%~1" /c "  "
	strrpc /s:"%~1" /c /e "jikljiomijj89wjr98m34u3n8q9rcu32498rxmu89@#$"
	
	if not "%~2"=="" (
		shift/1
		goto EraseSpace2
	)
	
exit/b 0

REM call:GetKeyWordLineNumberInFile "文件" [/i(不区分大小写)] [/t(只搜索位于行首的)] "关键字" "出现多个选取第几个" "使结果偏移值"
:根据关键字从文件查找所在行返回行号
:GetKeyWordLineNumberInFile
	REM 初始化子程序需求变量
	for %%Z in (subroutine GetKeyWordLineNumberInFile_I GetKeyWordLineNumberInFile_T GetKeyWordLineNumberInFile_DiJia GetKeyWordLineNumberInFile_PianYiResult) do if defined %%Z set %%Z=
	set subroutine=GetKeyWordLineNumberInFile
	
	REM 检查子程序使用基本规则正确与否
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]关键字为空
		exit/b 1
	) else (
		if /i "%~2"=="/i" (
			set GetKeyWordLineNumberInFile_I=i
			shift/2
		)
		if /i "%~3"=="/t" (
			set GetKeyWordLineNumberInFile_T=b
			shift/2
		)
	)
	if not "%~3"=="" (
		call:CompareSize %~3 lss 1
		if "!errorlevel!"=="0" (
			call:ShowErrorMessage [参数3]%~3指定选取第几个数值小于1
			exit/b 1
		)
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]输入文件为空
		exit/b 1
	) else if not exist "%~1" (
		call:ShowErrorMessage [参数1]%~1输入文件不存在
		exit/b 1
	)
	
	REM 子程序运作开始
	for /f "delims=:" %%Z in ('findstr /%GetKeyWordLineNumberInFile_I%%GetKeyWordLineNumberInFile_T%nlc:"%~2" "%~1"') do (
		if "%~3"=="" (
			exit/b %%Z
		) else (
			set /a GetKeyWordLineNumberInFile_DiJia+=1
			if "!GetKeyWordLineNumberInFile_DiJia!"=="%~3" (
				if "%~4"=="" (exit/b %%Z) else (
					set /a GetKeyWordLineNumberInFile_PianYiResult=%%Z+%~4
					if !GetKeyWordLineNumberInFile_PianYiResult! leq 0 exit/b 0
					exit/b !GetKeyWordLineNumberInFile_PianYiResult!
				)
			)
		)
	)
	if not "%errorlevel%"=="0" (
		call:ShowErrorMessage [其它]未能从文件"%~1"中找到"%~2"
		exit/b 0
	)
call:ShowErrorMessage [结果]根据选取多项中第%~3个未能找到结果,或未能从文件"%~1"中找到"%~2"
exit/b 0

REM 显示错误
REM call:ShowErrorMessage 错误内容
:ShowErrorMessage
if defined subroutine echo=	#出现错误,子程序:%subroutine%,描述：%*
if not defined subroutine echo=	#出现错误,描述：%*
if "%debug%"=="0" pause
goto :eof

REM call:CompareSize 比较数 比较表达式(与if中相同) 被比较数
:比较大小
:CompareSize
	REM 初始化子程序需求变量
	for %%z in (subroutine) do if defined %%z set %%z=
	set subroutine=CompareSize
	
	REM 检查子程序使用基本规则正确与否
	if "%~3"=="" (
		call:ShowErrorMessage [参数3]无被比较数
		exit/b 1
	)
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]无比较表达式
		exit/b 1
	) else if /i not "%~2"=="equ" if /i not "%~2"=="neq" if /i not "%~2"=="lss" if /i not "%~2"=="leq" if /i not "%~2"=="gtr" if /i not "%~2"=="geq" (
		call:ShowErrorMessage [参数2]%~2表达式错误
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]无比较数
		exit/b 1
	)
	
	REM 子程序运作开始
if %~1 %~2 %~3 (exit/b 0) else exit/b 1

REM call:Convert2OK_Name 待转换变量名1 [待转换变量名2] [待转换变量名3] ...
:将含有文件名的变量转换为合规的文件名
:Convert2OK_Name
	REM 初始化子程序需求变量
	for %%z in (subroutine) do if defined %%v set %%v=
	set subroutine=Convert2OK_Name
	
	:Convert2OK_Name2
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]待转换变量为空
		exit/b 1
	)
	if not defined %~1 (
		call:ShowErrorMessage [参数1]%~1:待转换变量未被赋值
		exit/b 1
	)
	
	REM 子程序运作开始
	if not "!%~1!"=="!%~1::=!" set %~1=!%~1::=：!
	if not "!%~1!"=="!%~1:?=!" set %~1=!%~1:?=？!
	if not "!%~1!"=="!%~1:/=!" set %~1=!%~1:/= !
	if not "!%~1!"=="!%~1:\=!" set %~1=!%~1:\= !
	if not "!%~1!"=="!%~1:/*!" set %~1=!%~1:/*=!
	if not "!%~1!"=="!%~1:**=!" for /f "tokens=1-26 delims=*" %%A in ("!%~1!") do (
		set %~1=%%Ax%%Bx%%Cx%%Dx%%Ex%%Fx%%Gx%%Hx%%Ix%%Jx%%Kx%%Lx%%Mx%%Nx%%Ox%%Px%%Qx%%Rx%%Sx%%Tx%%Ux%%Vx%%Wx%%Xx%%Yx%%Z
		set %~1=!%~1:xxxxxxxxxxxx=!
		set %~1=!%~1:xxxxxx=!
		set %~1=!%~1:xxxx=!
		set %~1=!%~1:xx=!
	)
	
	set %~1=!%~1:"=!
	
	if not "%~2"=="" (
		shift/1
		goto Convert2OK_Name2
	)
exit/b 0


REM call:LitterConvert [ aA | Aa ] 要转换的变量
:字母大小写转换
:LitterConvert
	REM 初始化子程序需求变量
	for %%z in (subroutine) do if defined %%v set %%v=
	set subroutine=LitterConvert
	
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]转换参数未填写:aA^(转换为大写^)或Aa^(转换为小写^)
		exit/b 1
	) else if not "%~1"=="aA" if not "%~1"=="Aa" (
		call:ShowErrorMessage [参数1]%~1参数错误，请输入aA^(转换为大写^)或Aa^(转换为小写^)
		exit/b 1
	)
	:LitterConvert2
	REM 检查子程序使用基本规则正确与否
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]输入变量为空
		exit/b 1
	) else if not defined %~2 (
		call:ShowErrorMessage [参数2]%~2输入变量未被赋值
		exit/b 1
	)
	
	REM 子程序运作开始
	if "%~1"=="aA" for %%a in ("a=A","b=B","c=C","d=D","e=E","f=F","g=G","h=H","i=I","j=J","k=K","l=L","m=M","n=N","o=O","p=P","q=Q","r=R","s=S","t=T","u=U","v=V","w=W","x=X","y=Y","z=Z") do set %~2=!%~2:%%~a!
	if "%~1"=="Aa" for %%a in ("A=a","B=b","C=c","D=d","E=e","F=f","G=g","H=h","I=i","J=j","K=k","L=l","M=m","N=n","O=o","P=p","Q=q","R=r","S=s","T=t","U=u","V=v","W=w","X=x","Y=y","Z=z") do set %~2=!%~2:%%~a!
	if not "%~3"=="" (
		shift/2
		goto LitterConvert2
	)
exit/b 0

REM call:FindKeywordsCountInFile 文件 关键字 [偏移值]
:从文件中查找含有指定关键字的行的数量
:FindKeywordsCountInFile
	REM 初始化子程序需求变量
	for %%z in (subroutine FindKeywordsCountInFileTemp) do if defined %%v set %%v=
	set subroutine=FindKeywordsCountInFile
	
	REM 检查子程序使用基本规则正确与否
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]查找计数关键字未填写
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]指定文件为空
		exit/b 1
	) else if not exist "%~1" (
		call:ShowErrorMessage [参数1]"%~1"指定文件不存在
		exit/b 1
	)

	REM 子程序运作开始
	REM find /c "%~2" "%~1"
	for /f "tokens=2,3 delims=:" %%- in ('find /c "%~2" "%~1"') do (
		if "%%."=="" (set FindKeywordsCountInFileTemp=%%-) else set FindKeywordsCountInFileTemp=%%.
	)
	
	if "%FindKeywordsCountInFileTemp: =%"=="0" exit/b 0
	if not "%~3"=="" set /a FindKeywordsCountInFileTemp+=%~3
	if %FindKeywordsCountInFileTemp% leq 0 exit/b 0
	
exit/b %FindKeywordsCountInFileTemp%

REM call:Count 偏移值 第一 第二 第三 ..
:计数
:Count
	REM 初始化子程序需求变量
	for %%W in (subroutine Count_DiJia) do if defined %%W set %%W=
	set subroutine=Count
	
	REM 检查子程序使用基本规则正确与否
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]计数值为空
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]偏移值为空
	)
	
	REM 子程序运作开始
	:Count2
	set /a Count_DiJia+=1
	if "%~3"=="" (
		set /a Count_DiJia+=%~1
		exit/b !Count_DiJia!
	) else (
		shift/2
		goto Count2
	)
exit/b 0

REM call:Content2Variable 基本名 总数量 赋值内容1 赋值内容2 赋值内容3 ...
:内容赋值到变量
:Content2Variable
	REM 初始化子程序需求变量
	for %%Y in (subroutine %~1 Content2Variable_Content) do if defined %%Y set %%Y=
	set subroutine=Content2Variable
	
	REM 检查子程序使用基本规则正确与否
	if "%~4"=="" (
		call:ShowErrorMessage [参数3,*]赋值内容为空
		exit/b 1
	)
	if "%~3"=="" (
		call:ShowErrorMessage [参数2]总数量为空
		exit/b 1
	)
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]基本变量名为空
		exit/b 1
	)
	
	REM 子程序运作开始
	:Content2Variable2
	set Content2Variable_Content=!Content2Variable_Content! %3
	if not "%~4"=="" (
		shift /3
		goto Content2Variable2
	)
	call:Count 0 %Content2Variable_Content%
	if not "%~2"=="%errorlevel%" (
		call:ShowErrorMessage [其它]总数量与赋值内容数量不同
		exit/b 1
	)
	for /l %%V in (1,1,%~2) do (
		set Content2Variable_Content_Choose=
		call:ChooseFromVariable Content2Variable_Content %%V Content2Variable_Content_Choose /nocheck
		set %~1%%V=!Content2Variable_Content_Choose!
	)
exit/b 0

REM call:UpdateProjectVersion 项目名称 当前版本 更新地址 项目源文件名及路径("%~0")
:更新项目版本 20151106
:UpdateProjectVersion

REM 检查子程序使用基本规则正确与否
if "%~4"=="" (
	echo=	#[错误 %0:参数4]项目源文件名及路径为空
	exit/b 1
) else if "%~3"=="" (
	echo=	#[错误 %0:参数3]更新地址为空
	exit/b 1
) else if "%~2"=="" (
	echo=	#[错误 %0:参数2]当前版本为空
	exit/b 1
) else if "%~1"=="" (
	echo=	#[错误 %0:参数1]项目名称为空
	exit/b 1
)

REM 初始化子程序需求变量
for %%I in (updateVersionName updateVersionPath updateNewVersion updateNewVersionName updateVersionOldVersionPath) do if defined %%I set %%I=
set updateVersionName=%~1.Version
set updateVersionPath=TMP\%updateVersionName%%random%%ranom%%random%

REM 子程序开始运作
echo=#正在检测更新项目: %~1	当前版本: %~2
if exist "%updateVersionPath%" del /f /q "updateVersionPath%"
aria2c -o "%updateVersionPath%" "%~3/%updateVersionName%">nul
if not "%errorlevel%"=="0" (
	echo=	#更新失败,无法连接到服务器,请检查后重试
	exit/b
)
for /f "usebackq tokens=1,2 delims= " %%I in ("%updateVersionPath%") do (
	if %~2 lss %%I (
		echo=#检测到项目新版本 %%I 正在尝试更新项目...
		set updateNewVersion=%%I
		set updateNewVersionName=%%~J
		if exist "%%~J" del /f /q "%%~J"
		aria2c -o "%%~J" "%~3/%%~J">nul
		REM call:DownloadNetFile %~3/%%~J "%~dp4\%%~J"
		if "!errorlevel!"=="0" (
			set updateNewVersionPath=%~dp4%%~J
			echo=#项目 %~1 新版本 %%I 下载成功
			goto UpdateProjectVersion2
		) else (
			echo=	#更新失败,无法从服务器下载更新文件,请稍后再试
			if exist "%updateVersionPath%" del /f /q "%updateVersionPath%"
			exit/b 1
		)
	) else (
		if exist "%updateVersionPath%" del /f /q "%updateVersionPath%"
		echo=#已是最新版本,感谢您的关注
		exit/b 1
	)
)
:UpdateProjectVersion2
if exist "%updateVersionPath%" del /f /q "%updateVersionPath%"

REM 此处为新版本下载成功后要做的动作
REM 	%1	项目名称
REM 	%2	旧版本
REM 	"%~4"	项目旧版本源文件名及路径
REM 	%updateNewVersion%	更新后文件版本
REM 	%updateNewVersionPath%	更新后版本文件路径


REM 删除旧版本，打开新版本
echo=	#即将打开新版本项目 %1 %updateNewVersion%
ping -n 3 127.1>nul 2>nul
set updateVersionOldVersionPath=%~4
if /i "%updateVersionOldVersionPath:~-4%"==".exe" taskkill /f /im "%~nx4">nul 2>nul
(
	copy "%~4" "%~4_updatebak">nul 2>nul
	del /f /q "%~4"
	copy "%updateNewVersionPath%" "%~4">nul 2>nul
	if "!errorlevel!"=="0" (
		start "" "%~4"
		del /f /q "%~4_updatebak"
		del /f /q "%updateNewVersionPath%"
		exit
	) else (
		copy "%~4_updatebak" "%~4">nul 2>nul
		echo=#打开新版本失败，您可手动打开新版本项目 %updateNewVersionPath%
		del /f /q "%~4_updatebak"
		pause
		explorer /select,"%updateNewVersionPath%"
		exit
	)
)
exit/b 0

REM call:UnicodeConvert 被最终赋值变量名 转换值1 转换值2 转换值3 ...
:Unicode转换
:UnicodeConvert
	REM 初始化子程序需求变量
	for %%y in (subroutine Unicode_Result %~1) do if defined %%y set %%y=
	set subroutine=UnicodeConvert
	
	REM 检查子程序使用基本规则正确与否
	if "%~1"=="" (
		call:ShowErrorMessage [参数1]最终赋值变量名为空
		exit/b 1
	)
	:UnicodeConvert2
	if exist "%UnicodeTMPFile%" del /f /q "%UnicodeTMPFile%"
	set UnicodeTMPFile=TMP\Unicode%random%%random%%random%.TMP
	if "%~2"=="" (
		call:ShowErrorMessage [参数2]被转换值为空
		exit/b 1
	)
	REM 子程序运作开始
	call:Unicode%~2 2>"%UnicodeTMPFile%"
	for %%y in ("%UnicodeTMPFile%") do if "%%~zy"=="0" (
		set %~1=!%~1!%Unicode_Result%
	) else (
		set %~1=!%~1!%~2
	)
	:UnicodeConvert3
	if not "%~3"=="" (
		shift/2
		goto UnicodeConvert2
	)
exit/b 0

:Unicodenbsp
set Unicode_Result= 
exit/b
:Unicode！
set Unicode_Result=65281
exit/b
:Unicode65281
set Unicode_Result=！
exit/b
:Unicode￥
set Unicode_Result=65509
exit/b
:Unicode65509
set Unicode_Result=￥
exit/b
:Unicode…
set Unicode_Result=8230
exit/b
:Unicode8230
set Unicode_Result=…
exit/b
:Unicode（
set Unicode_Result=65288
exit/b
:Unicode65288
set Unicode_Result=（
exit/b
:Unicode）
set Unicode_Result=65289
exit/b
:Unicode65289
set Unicode_Result=）
exit/b
:Unicode—
set Unicode_Result=8212
exit/b
:Unicode8212
set Unicode_Result=—
exit/b
:Unicode、
set Unicode_Result=12289
exit/b
:Unicode12289
set Unicode_Result=、
exit/b
:Unicode】
set Unicode_Result=12305
exit/b
:Unicode12305
set Unicode_Result=】
exit/b
:Unicode【
set Unicode_Result=12304
exit/b
:Unicode12304
set Unicode_Result=【
exit/b
:Unicode：
set Unicode_Result=65306
exit/b
:Unicode65306
set Unicode_Result=：
exit/b
:Unicode；
set Unicode_Result=65307
exit/b
:Unicode65307
set Unicode_Result=；
exit/b
:Unicode”
set Unicode_Result=8220
exit/b
:Unicode8220
set Unicode_Result=”
exit/b
:Unicode‘
set Unicode_Result=8216
exit/b
:Unicode8216
set Unicode_Result=‘
exit/b
:Unicode”
set Unicode_Result=8221
exit/b
:Unicode8221
set Unicode_Result=”
exit/b
:Unicode’
set Unicode_Result=8217
exit/b
:Unicode8217
set Unicode_Result=’
exit/b
:Unicode》
set Unicode_Result=12299
exit/b
:Unicode12299
set Unicode_Result=》
exit/b
:Unicode《
set Unicode_Result=12298
exit/b
:Unicode12298
set Unicode_Result=《
exit/b
:Unicode。
set Unicode_Result=12290
exit/b
:Unicode12290
set Unicode_Result=。
exit/b
:Unicode，
set Unicode_Result=65292
exit/b
:Unicode65292
set Unicode_Result=，
exit/b
:Unicode21834
set Unicode_Result=啊
exit/b
:Unicode啊
set Unicode_Result=21834
exit/b
:Unicode38463
set Unicode_Result=阿
exit/b
:Unicode阿
set Unicode_Result=38463
exit/b
:Unicode22467
set Unicode_Result=埃
exit/b
:Unicode埃
set Unicode_Result=22467
exit/b
:Unicode25384
set Unicode_Result=挨
exit/b
:Unicode挨
set Unicode_Result=25384
exit/b
:Unicode21710
set Unicode_Result=哎
exit/b
:Unicode哎
set Unicode_Result=21710
exit/b
:Unicode21769
set Unicode_Result=唉
exit/b
:Unicode唉
set Unicode_Result=21769
exit/b
:Unicode21696
set Unicode_Result=哀
exit/b
:Unicode哀
set Unicode_Result=21696
exit/b
:Unicode30353
set Unicode_Result=皑
exit/b
:Unicode皑
set Unicode_Result=30353
exit/b
:Unicode30284
set Unicode_Result=癌
exit/b
:Unicode癌
set Unicode_Result=30284
exit/b
:Unicode34108
set Unicode_Result=蔼
exit/b
:Unicode蔼
set Unicode_Result=34108
exit/b
:Unicode30702
set Unicode_Result=矮
exit/b
:Unicode矮
set Unicode_Result=30702
exit/b
:Unicode33406
set Unicode_Result=艾
exit/b
:Unicode艾
set Unicode_Result=33406
exit/b
:Unicode30861
set Unicode_Result=碍
exit/b
:Unicode碍
set Unicode_Result=30861
exit/b
:Unicode29233
set Unicode_Result=爱
exit/b
:Unicode爱
set Unicode_Result=29233
exit/b
:Unicode38552
set Unicode_Result=隘
exit/b
:Unicode隘
set Unicode_Result=38552
exit/b
:Unicode38797
set Unicode_Result=鞍
exit/b
:Unicode鞍
set Unicode_Result=38797
exit/b
:Unicode27688
set Unicode_Result=氨
exit/b
:Unicode氨
set Unicode_Result=27688
exit/b
:Unicode23433
set Unicode_Result=安
exit/b
:Unicode安
set Unicode_Result=23433
exit/b
:Unicode20474
set Unicode_Result=俺
exit/b
:Unicode俺
set Unicode_Result=20474
exit/b
:Unicode25353
set Unicode_Result=按
exit/b
:Unicode按
set Unicode_Result=25353
exit/b
:Unicode26263
set Unicode_Result=暗
exit/b
:Unicode暗
set Unicode_Result=26263
exit/b
:Unicode23736
set Unicode_Result=岸
exit/b
:Unicode岸
set Unicode_Result=23736
exit/b
:Unicode33018
set Unicode_Result=胺
exit/b
:Unicode胺
set Unicode_Result=33018
exit/b
:Unicode26696
set Unicode_Result=案
exit/b
:Unicode案
set Unicode_Result=26696
exit/b
:Unicode32942
set Unicode_Result=肮
exit/b
:Unicode肮
set Unicode_Result=32942
exit/b
:Unicode26114
set Unicode_Result=昂
exit/b
:Unicode昂
set Unicode_Result=26114
exit/b
:Unicode30414
set Unicode_Result=盎
exit/b
:Unicode盎
set Unicode_Result=30414
exit/b
:Unicode20985
set Unicode_Result=凹
exit/b
:Unicode凹
set Unicode_Result=20985
exit/b
:Unicode25942
set Unicode_Result=敖
exit/b
:Unicode敖
set Unicode_Result=25942
exit/b
:Unicode29100
set Unicode_Result=熬
exit/b
:Unicode熬
set Unicode_Result=29100
exit/b
:Unicode32753
set Unicode_Result=翱
exit/b
:Unicode翱
set Unicode_Result=32753
exit/b
:Unicode34948
set Unicode_Result=袄
exit/b
:Unicode袄
set Unicode_Result=34948
exit/b
:Unicode20658
set Unicode_Result=傲
exit/b
:Unicode傲
set Unicode_Result=20658
exit/b
:Unicode22885
set Unicode_Result=奥
exit/b
:Unicode奥
set Unicode_Result=22885
exit/b
:Unicode25034
set Unicode_Result=懊
exit/b
:Unicode懊
set Unicode_Result=25034
exit/b
:Unicode28595
set Unicode_Result=澳
exit/b
:Unicode澳
set Unicode_Result=28595
exit/b
:Unicode33453
set Unicode_Result=芭
exit/b
:Unicode芭
set Unicode_Result=33453
exit/b
:Unicode25420
set Unicode_Result=捌
exit/b
:Unicode捌
set Unicode_Result=25420
exit/b
:Unicode25170
set Unicode_Result=扒
exit/b
:Unicode扒
set Unicode_Result=25170
exit/b
:Unicode21485
set Unicode_Result=叭
exit/b
:Unicode叭
set Unicode_Result=21485
exit/b
:Unicode21543
set Unicode_Result=吧
exit/b
:Unicode吧
set Unicode_Result=21543
exit/b
:Unicode31494
set Unicode_Result=笆
exit/b
:Unicode笆
set Unicode_Result=31494
exit/b
:Unicode20843
set Unicode_Result=八
exit/b
:Unicode八
set Unicode_Result=20843
exit/b
:Unicode30116
set Unicode_Result=疤
exit/b
:Unicode疤
set Unicode_Result=30116
exit/b
:Unicode24052
set Unicode_Result=巴
exit/b
:Unicode巴
set Unicode_Result=24052
exit/b
:Unicode25300
set Unicode_Result=拔
exit/b
:Unicode拔
set Unicode_Result=25300
exit/b
:Unicode36299
set Unicode_Result=跋
exit/b
:Unicode跋
set Unicode_Result=36299
exit/b
:Unicode38774
set Unicode_Result=靶
exit/b
:Unicode靶
set Unicode_Result=38774
exit/b
:Unicode25226
set Unicode_Result=把
exit/b
:Unicode把
set Unicode_Result=25226
exit/b
:Unicode32793
set Unicode_Result=耙
exit/b
:Unicode耙
set Unicode_Result=32793
exit/b
:Unicode22365
set Unicode_Result=坝
exit/b
:Unicode坝
set Unicode_Result=22365
exit/b
:Unicode38712
set Unicode_Result=霸
exit/b
:Unicode霸
set Unicode_Result=38712
exit/b
:Unicode32610
set Unicode_Result=罢
exit/b
:Unicode罢
set Unicode_Result=32610
exit/b
:Unicode29240
set Unicode_Result=爸
exit/b
:Unicode爸
set Unicode_Result=29240
exit/b
:Unicode30333
set Unicode_Result=白
exit/b
:Unicode白
set Unicode_Result=30333
exit/b
:Unicode26575
set Unicode_Result=柏
exit/b
:Unicode柏
set Unicode_Result=26575
exit/b
:Unicode30334
set Unicode_Result=百
exit/b
:Unicode百
set Unicode_Result=30334
exit/b
:Unicode25670
set Unicode_Result=摆
exit/b
:Unicode摆
set Unicode_Result=25670
exit/b
:Unicode20336
set Unicode_Result=佰
exit/b
:Unicode佰
set Unicode_Result=20336
exit/b
:Unicode36133
set Unicode_Result=败
exit/b
:Unicode败
set Unicode_Result=36133
exit/b
:Unicode25308
set Unicode_Result=拜
exit/b
:Unicode拜
set Unicode_Result=25308
exit/b
:Unicode31255
set Unicode_Result=稗
exit/b
:Unicode稗
set Unicode_Result=31255
exit/b
:Unicode26001
set Unicode_Result=斑
exit/b
:Unicode斑
set Unicode_Result=26001
exit/b
:Unicode29677
set Unicode_Result=班
exit/b
:Unicode班
set Unicode_Result=29677
exit/b
:Unicode25644
set Unicode_Result=搬
exit/b
:Unicode搬
set Unicode_Result=25644
exit/b
:Unicode25203
set Unicode_Result=扳
exit/b
:Unicode扳
set Unicode_Result=25203
exit/b
:Unicode33324
set Unicode_Result=般
exit/b
:Unicode般
set Unicode_Result=33324
exit/b
:Unicode39041
set Unicode_Result=颁
exit/b
:Unicode颁
set Unicode_Result=39041
exit/b
:Unicode26495
set Unicode_Result=板
exit/b
:Unicode板
set Unicode_Result=26495
exit/b
:Unicode29256
set Unicode_Result=版
exit/b
:Unicode版
set Unicode_Result=29256
exit/b
:Unicode25198
set Unicode_Result=扮
exit/b
:Unicode扮
set Unicode_Result=25198
exit/b
:Unicode25292
set Unicode_Result=拌
exit/b
:Unicode拌
set Unicode_Result=25292
exit/b
:Unicode20276
set Unicode_Result=伴
exit/b
:Unicode伴
set Unicode_Result=20276
exit/b
:Unicode29923
set Unicode_Result=瓣
exit/b
:Unicode瓣
set Unicode_Result=29923
exit/b
:Unicode21322
set Unicode_Result=半
exit/b
:Unicode半
set Unicode_Result=21322
exit/b
:Unicode21150
set Unicode_Result=办
exit/b
:Unicode办
set Unicode_Result=21150
exit/b
:Unicode32458
set Unicode_Result=绊
exit/b
:Unicode绊
set Unicode_Result=32458
exit/b
:Unicode37030
set Unicode_Result=邦
exit/b
:Unicode邦
set Unicode_Result=37030
exit/b
:Unicode24110
set Unicode_Result=帮
exit/b
:Unicode帮
set Unicode_Result=24110
exit/b
:Unicode26758
set Unicode_Result=梆
exit/b
:Unicode梆
set Unicode_Result=26758
exit/b
:Unicode27036
set Unicode_Result=榜
exit/b
:Unicode榜
set Unicode_Result=27036
exit/b
:Unicode33152
set Unicode_Result=膀
exit/b
:Unicode膀
set Unicode_Result=33152
exit/b
:Unicode32465
set Unicode_Result=绑
exit/b
:Unicode绑
set Unicode_Result=32465
exit/b
:Unicode26834
set Unicode_Result=棒
exit/b
:Unicode棒
set Unicode_Result=26834
exit/b
:Unicode30917
set Unicode_Result=磅
exit/b
:Unicode磅
set Unicode_Result=30917
exit/b
:Unicode34444
set Unicode_Result=蚌
exit/b
:Unicode蚌
set Unicode_Result=34444
exit/b
:Unicode38225
set Unicode_Result=镑
exit/b
:Unicode镑
set Unicode_Result=38225
exit/b
:Unicode20621
set Unicode_Result=傍
exit/b
:Unicode傍
set Unicode_Result=20621
exit/b
:Unicode35876
set Unicode_Result=谤
exit/b
:Unicode谤
set Unicode_Result=35876
exit/b
:Unicode33502
set Unicode_Result=苞
exit/b
:Unicode苞
set Unicode_Result=33502
exit/b
:Unicode32990
set Unicode_Result=胞
exit/b
:Unicode胞
set Unicode_Result=32990
exit/b
:Unicode21253
set Unicode_Result=包
exit/b
:Unicode包
set Unicode_Result=21253
exit/b
:Unicode35090
set Unicode_Result=褒
exit/b
:Unicode褒
set Unicode_Result=35090
exit/b
:Unicode21093
set Unicode_Result=剥
exit/b
:Unicode剥
set Unicode_Result=21093
exit/b
:Unicode34180
set Unicode_Result=薄
exit/b
:Unicode薄
set Unicode_Result=34180
exit/b
:Unicode38649
set Unicode_Result=雹
exit/b
:Unicode雹
set Unicode_Result=38649
exit/b
:Unicode20445
set Unicode_Result=保
exit/b
:Unicode保
set Unicode_Result=20445
exit/b
:Unicode22561
set Unicode_Result=堡
exit/b
:Unicode堡
set Unicode_Result=22561
exit/b
:Unicode39281
set Unicode_Result=饱
exit/b
:Unicode饱
set Unicode_Result=39281
exit/b
:Unicode23453
set Unicode_Result=宝
exit/b
:Unicode宝
set Unicode_Result=23453
exit/b
:Unicode25265
set Unicode_Result=抱
exit/b
:Unicode抱
set Unicode_Result=25265
exit/b
:Unicode25253
set Unicode_Result=报
exit/b
:Unicode报
set Unicode_Result=25253
exit/b
:Unicode26292
set Unicode_Result=暴
exit/b
:Unicode暴
set Unicode_Result=26292
exit/b
:Unicode35961
set Unicode_Result=豹
exit/b
:Unicode豹
set Unicode_Result=35961
exit/b
:Unicode40077
set Unicode_Result=鲍
exit/b
:Unicode鲍
set Unicode_Result=40077
exit/b
:Unicode29190
set Unicode_Result=爆
exit/b
:Unicode爆
set Unicode_Result=29190
exit/b
:Unicode26479
set Unicode_Result=杯
exit/b
:Unicode杯
set Unicode_Result=26479
exit/b
:Unicode30865
set Unicode_Result=碑
exit/b
:Unicode碑
set Unicode_Result=30865
exit/b
:Unicode24754
set Unicode_Result=悲
exit/b
:Unicode悲
set Unicode_Result=24754
exit/b
:Unicode21329
set Unicode_Result=卑
exit/b
:Unicode卑
set Unicode_Result=21329
exit/b
:Unicode21271
set Unicode_Result=北
exit/b
:Unicode北
set Unicode_Result=21271
exit/b
:Unicode36744
set Unicode_Result=辈
exit/b
:Unicode辈
set Unicode_Result=36744
exit/b
:Unicode32972
set Unicode_Result=背
exit/b
:Unicode背
set Unicode_Result=32972
exit/b
:Unicode36125
set Unicode_Result=贝
exit/b
:Unicode贝
set Unicode_Result=36125
exit/b
:Unicode38049
set Unicode_Result=钡
exit/b
:Unicode钡
set Unicode_Result=38049
exit/b
:Unicode20493
set Unicode_Result=倍
exit/b
:Unicode倍
set Unicode_Result=20493
exit/b
:Unicode29384
set Unicode_Result=狈
exit/b
:Unicode狈
set Unicode_Result=29384
exit/b
:Unicode22791
set Unicode_Result=备
exit/b
:Unicode备
set Unicode_Result=22791
exit/b
:Unicode24811
set Unicode_Result=惫
exit/b
:Unicode惫
set Unicode_Result=24811
exit/b
:Unicode28953
set Unicode_Result=焙
exit/b
:Unicode焙
set Unicode_Result=28953
exit/b
:Unicode34987
set Unicode_Result=被
exit/b
:Unicode被
set Unicode_Result=34987
exit/b
:Unicode22868
set Unicode_Result=奔
exit/b
:Unicode奔
set Unicode_Result=22868
exit/b
:Unicode33519
set Unicode_Result=苯
exit/b
:Unicode苯
set Unicode_Result=33519
exit/b
:Unicode26412
set Unicode_Result=本
exit/b
:Unicode本
set Unicode_Result=26412
exit/b
:Unicode31528
set Unicode_Result=笨
exit/b
:Unicode笨
set Unicode_Result=31528
exit/b
:Unicode23849
set Unicode_Result=崩
exit/b
:Unicode崩
set Unicode_Result=23849
exit/b
:Unicode32503
set Unicode_Result=绷
exit/b
:Unicode绷
set Unicode_Result=32503
exit/b
:Unicode29997
set Unicode_Result=甭
exit/b
:Unicode甭
set Unicode_Result=29997
exit/b
:Unicode27893
set Unicode_Result=泵
exit/b
:Unicode泵
set Unicode_Result=27893
exit/b
:Unicode36454
set Unicode_Result=蹦
exit/b
:Unicode蹦
set Unicode_Result=36454
exit/b
:Unicode36856
set Unicode_Result=迸
exit/b
:Unicode迸
set Unicode_Result=36856
exit/b
:Unicode36924
set Unicode_Result=逼
exit/b
:Unicode逼
set Unicode_Result=36924
exit/b
:Unicode40763
set Unicode_Result=鼻
exit/b
:Unicode鼻
set Unicode_Result=40763
exit/b
:Unicode27604
set Unicode_Result=比
exit/b
:Unicode比
set Unicode_Result=27604
exit/b
:Unicode37145
set Unicode_Result=鄙
exit/b
:Unicode鄙
set Unicode_Result=37145
exit/b
:Unicode31508
set Unicode_Result=笔
exit/b
:Unicode笔
set Unicode_Result=31508
exit/b
:Unicode24444
set Unicode_Result=彼
exit/b
:Unicode彼
set Unicode_Result=24444
exit/b
:Unicode30887
set Unicode_Result=碧
exit/b
:Unicode碧
set Unicode_Result=30887
exit/b
:Unicode34006
set Unicode_Result=蓖
exit/b
:Unicode蓖
set Unicode_Result=34006
exit/b
:Unicode34109
set Unicode_Result=蔽
exit/b
:Unicode蔽
set Unicode_Result=34109
exit/b
:Unicode27605
set Unicode_Result=毕
exit/b
:Unicode毕
set Unicode_Result=27605
exit/b
:Unicode27609
set Unicode_Result=毙
exit/b
:Unicode毙
set Unicode_Result=27609
exit/b
:Unicode27606
set Unicode_Result=毖
exit/b
:Unicode毖
set Unicode_Result=27606
exit/b
:Unicode24065
set Unicode_Result=币
exit/b
:Unicode币
set Unicode_Result=24065
exit/b
:Unicode24199
set Unicode_Result=庇
exit/b
:Unicode庇
set Unicode_Result=24199
exit/b
:Unicode30201
set Unicode_Result=痹
exit/b
:Unicode痹
set Unicode_Result=30201
exit/b
:Unicode38381
set Unicode_Result=闭
exit/b
:Unicode闭
set Unicode_Result=38381
exit/b
:Unicode25949
set Unicode_Result=敝
exit/b
:Unicode敝
set Unicode_Result=25949
exit/b
:Unicode24330
set Unicode_Result=弊
exit/b
:Unicode弊
set Unicode_Result=24330
exit/b
:Unicode24517
set Unicode_Result=必
exit/b
:Unicode必
set Unicode_Result=24517
exit/b
:Unicode36767
set Unicode_Result=辟
exit/b
:Unicode辟
set Unicode_Result=36767
exit/b
:Unicode22721
set Unicode_Result=壁
exit/b
:Unicode壁
set Unicode_Result=22721
exit/b
:Unicode33218
set Unicode_Result=臂
exit/b
:Unicode臂
set Unicode_Result=33218
exit/b
:Unicode36991
set Unicode_Result=避
exit/b
:Unicode避
set Unicode_Result=36991
exit/b
:Unicode38491
set Unicode_Result=陛
exit/b
:Unicode陛
set Unicode_Result=38491
exit/b
:Unicode38829
set Unicode_Result=鞭
exit/b
:Unicode鞭
set Unicode_Result=38829
exit/b
:Unicode36793
set Unicode_Result=边
exit/b
:Unicode边
set Unicode_Result=36793
exit/b
:Unicode32534
set Unicode_Result=编
exit/b
:Unicode编
set Unicode_Result=32534
exit/b
:Unicode36140
set Unicode_Result=贬
exit/b
:Unicode贬
set Unicode_Result=36140
exit/b
:Unicode25153
set Unicode_Result=扁
exit/b
:Unicode扁
set Unicode_Result=25153
exit/b
:Unicode20415
set Unicode_Result=便
exit/b
:Unicode便
set Unicode_Result=20415
exit/b
:Unicode21464
set Unicode_Result=变
exit/b
:Unicode变
set Unicode_Result=21464
exit/b
:Unicode21342
set Unicode_Result=卞
exit/b
:Unicode卞
set Unicode_Result=21342
exit/b
:Unicode36776
set Unicode_Result=辨
exit/b
:Unicode辨
set Unicode_Result=36776
exit/b
:Unicode36777
set Unicode_Result=辩
exit/b
:Unicode辩
set Unicode_Result=36777
exit/b
:Unicode36779
set Unicode_Result=辫
exit/b
:Unicode辫
set Unicode_Result=36779
exit/b
:Unicode36941
set Unicode_Result=遍
exit/b
:Unicode遍
set Unicode_Result=36941
exit/b
:Unicode26631
set Unicode_Result=标
exit/b
:Unicode标
set Unicode_Result=26631
exit/b
:Unicode24426
set Unicode_Result=彪
exit/b
:Unicode彪
set Unicode_Result=24426
exit/b
:Unicode33176
set Unicode_Result=膘
exit/b
:Unicode膘
set Unicode_Result=33176
exit/b
:Unicode34920
set Unicode_Result=表
exit/b
:Unicode表
set Unicode_Result=34920
exit/b
:Unicode40150
set Unicode_Result=鳖
exit/b
:Unicode鳖
set Unicode_Result=40150
exit/b
:Unicode24971
set Unicode_Result=憋
exit/b
:Unicode憋
set Unicode_Result=24971
exit/b
:Unicode21035
set Unicode_Result=别
exit/b
:Unicode别
set Unicode_Result=21035
exit/b
:Unicode30250
set Unicode_Result=瘪
exit/b
:Unicode瘪
set Unicode_Result=30250
exit/b
:Unicode24428
set Unicode_Result=彬
exit/b
:Unicode彬
set Unicode_Result=24428
exit/b
:Unicode25996
set Unicode_Result=斌
exit/b
:Unicode斌
set Unicode_Result=25996
exit/b
:Unicode28626
set Unicode_Result=濒
exit/b
:Unicode濒
set Unicode_Result=28626
exit/b
:Unicode28392
set Unicode_Result=滨
exit/b
:Unicode滨
set Unicode_Result=28392
exit/b
:Unicode23486
set Unicode_Result=宾
exit/b
:Unicode宾
set Unicode_Result=23486
exit/b
:Unicode25672
set Unicode_Result=摈
exit/b
:Unicode摈
set Unicode_Result=25672
exit/b
:Unicode20853
set Unicode_Result=兵
exit/b
:Unicode兵
set Unicode_Result=20853
exit/b
:Unicode20912
set Unicode_Result=冰
exit/b
:Unicode冰
set Unicode_Result=20912
exit/b
:Unicode26564
set Unicode_Result=柄
exit/b
:Unicode柄
set Unicode_Result=26564
exit/b
:Unicode19993
set Unicode_Result=丙
exit/b
:Unicode丙
set Unicode_Result=19993
exit/b
:Unicode31177
set Unicode_Result=秉
exit/b
:Unicode秉
set Unicode_Result=31177
exit/b
:Unicode39292
set Unicode_Result=饼
exit/b
:Unicode饼
set Unicode_Result=39292
exit/b
:Unicode28851
set Unicode_Result=炳
exit/b
:Unicode炳
set Unicode_Result=28851
exit/b
:Unicode30149
set Unicode_Result=病
exit/b
:Unicode病
set Unicode_Result=30149
exit/b
:Unicode24182
set Unicode_Result=并
exit/b
:Unicode并
set Unicode_Result=24182
exit/b
:Unicode29627
set Unicode_Result=玻
exit/b
:Unicode玻
set Unicode_Result=29627
exit/b
:Unicode33760
set Unicode_Result=菠
exit/b
:Unicode菠
set Unicode_Result=33760
exit/b
:Unicode25773
set Unicode_Result=播
exit/b
:Unicode播
set Unicode_Result=25773
exit/b
:Unicode25320
set Unicode_Result=拨
exit/b
:Unicode拨
set Unicode_Result=25320
exit/b
:Unicode38069
set Unicode_Result=钵
exit/b
:Unicode钵
set Unicode_Result=38069
exit/b
:Unicode27874
set Unicode_Result=波
exit/b
:Unicode波
set Unicode_Result=27874
exit/b
:Unicode21338
set Unicode_Result=博
exit/b
:Unicode博
set Unicode_Result=21338
exit/b
:Unicode21187
set Unicode_Result=勃
exit/b
:Unicode勃
set Unicode_Result=21187
exit/b
:Unicode25615
set Unicode_Result=搏
exit/b
:Unicode搏
set Unicode_Result=25615
exit/b
:Unicode38082
set Unicode_Result=铂
exit/b
:Unicode铂
set Unicode_Result=38082
exit/b
:Unicode31636
set Unicode_Result=箔
exit/b
:Unicode箔
set Unicode_Result=31636
exit/b
:Unicode20271
set Unicode_Result=伯
exit/b
:Unicode伯
set Unicode_Result=20271
exit/b
:Unicode24091
set Unicode_Result=帛
exit/b
:Unicode帛
set Unicode_Result=24091
exit/b
:Unicode33334
set Unicode_Result=舶
exit/b
:Unicode舶
set Unicode_Result=33334
exit/b
:Unicode33046
set Unicode_Result=脖
exit/b
:Unicode脖
set Unicode_Result=33046
exit/b
:Unicode33162
set Unicode_Result=膊
exit/b
:Unicode膊
set Unicode_Result=33162
exit/b
:Unicode28196
set Unicode_Result=渤
exit/b
:Unicode渤
set Unicode_Result=28196
exit/b
:Unicode27850
set Unicode_Result=泊
exit/b
:Unicode泊
set Unicode_Result=27850
exit/b
:Unicode39539
set Unicode_Result=驳
exit/b
:Unicode驳
set Unicode_Result=39539
exit/b
:Unicode25429
set Unicode_Result=捕
exit/b
:Unicode捕
set Unicode_Result=25429
exit/b
:Unicode21340
set Unicode_Result=卜
exit/b
:Unicode卜
set Unicode_Result=21340
exit/b
:Unicode21754
set Unicode_Result=哺
exit/b
:Unicode哺
set Unicode_Result=21754
exit/b
:Unicode34917
set Unicode_Result=补
exit/b
:Unicode补
set Unicode_Result=34917
exit/b
:Unicode22496
set Unicode_Result=埠
exit/b
:Unicode埠
set Unicode_Result=22496
exit/b
:Unicode19981
set Unicode_Result=不
exit/b
:Unicode不
set Unicode_Result=19981
exit/b
:Unicode24067
set Unicode_Result=布
exit/b
:Unicode布
set Unicode_Result=24067
exit/b
:Unicode27493
set Unicode_Result=步
exit/b
:Unicode步
set Unicode_Result=27493
exit/b
:Unicode31807
set Unicode_Result=簿
exit/b
:Unicode簿
set Unicode_Result=31807
exit/b
:Unicode37096
set Unicode_Result=部
exit/b
:Unicode部
set Unicode_Result=37096
exit/b
:Unicode24598
set Unicode_Result=怖
exit/b
:Unicode怖
set Unicode_Result=24598
exit/b
:Unicode25830
set Unicode_Result=擦
exit/b
:Unicode擦
set Unicode_Result=25830
exit/b
:Unicode29468
set Unicode_Result=猜
exit/b
:Unicode猜
set Unicode_Result=29468
exit/b
:Unicode35009
set Unicode_Result=裁
exit/b
:Unicode裁
set Unicode_Result=35009
exit/b
:Unicode26448
set Unicode_Result=材
exit/b
:Unicode材
set Unicode_Result=26448
exit/b
:Unicode25165
set Unicode_Result=才
exit/b
:Unicode才
set Unicode_Result=25165
exit/b
:Unicode36130
set Unicode_Result=财
exit/b
:Unicode财
set Unicode_Result=36130
exit/b
:Unicode30572
set Unicode_Result=睬
exit/b
:Unicode睬
set Unicode_Result=30572
exit/b
:Unicode36393
set Unicode_Result=踩
exit/b
:Unicode踩
set Unicode_Result=36393
exit/b
:Unicode37319
set Unicode_Result=采
exit/b
:Unicode采
set Unicode_Result=37319
exit/b
:Unicode24425
set Unicode_Result=彩
exit/b
:Unicode彩
set Unicode_Result=24425
exit/b
:Unicode33756
set Unicode_Result=菜
exit/b
:Unicode菜
set Unicode_Result=33756
exit/b
:Unicode34081
set Unicode_Result=蔡
exit/b
:Unicode蔡
set Unicode_Result=34081
exit/b
:Unicode39184
set Unicode_Result=餐
exit/b
:Unicode餐
set Unicode_Result=39184
exit/b
:Unicode21442
set Unicode_Result=参
exit/b
:Unicode参
set Unicode_Result=21442
exit/b
:Unicode34453
set Unicode_Result=蚕
exit/b
:Unicode蚕
set Unicode_Result=34453
exit/b
:Unicode27531
set Unicode_Result=残
exit/b
:Unicode残
set Unicode_Result=27531
exit/b
:Unicode24813
set Unicode_Result=惭
exit/b
:Unicode惭
set Unicode_Result=24813
exit/b
:Unicode24808
set Unicode_Result=惨
exit/b
:Unicode惨
set Unicode_Result=24808
exit/b
:Unicode28799
set Unicode_Result=灿
exit/b
:Unicode灿
set Unicode_Result=28799
exit/b
:Unicode33485
set Unicode_Result=苍
exit/b
:Unicode苍
set Unicode_Result=33485
exit/b
:Unicode33329
set Unicode_Result=舱
exit/b
:Unicode舱
set Unicode_Result=33329
exit/b
:Unicode20179
set Unicode_Result=仓
exit/b
:Unicode仓
set Unicode_Result=20179
exit/b
:Unicode27815
set Unicode_Result=沧
exit/b
:Unicode沧
set Unicode_Result=27815
exit/b
:Unicode34255
set Unicode_Result=藏
exit/b
:Unicode藏
set Unicode_Result=34255
exit/b
:Unicode25805
set Unicode_Result=操
exit/b
:Unicode操
set Unicode_Result=25805
exit/b
:Unicode31961
set Unicode_Result=糙
exit/b
:Unicode糙
set Unicode_Result=31961
exit/b
:Unicode27133
set Unicode_Result=槽
exit/b
:Unicode槽
set Unicode_Result=27133
exit/b
:Unicode26361
set Unicode_Result=曹
exit/b
:Unicode曹
set Unicode_Result=26361
exit/b
:Unicode33609
set Unicode_Result=草
exit/b
:Unicode草
set Unicode_Result=33609
exit/b
:Unicode21397
set Unicode_Result=厕
exit/b
:Unicode厕
set Unicode_Result=21397
exit/b
:Unicode31574
set Unicode_Result=策
exit/b
:Unicode策
set Unicode_Result=31574
exit/b
:Unicode20391
set Unicode_Result=侧
exit/b
:Unicode侧
set Unicode_Result=20391
exit/b
:Unicode20876
set Unicode_Result=册
exit/b
:Unicode册
set Unicode_Result=20876
exit/b
:Unicode27979
set Unicode_Result=测
exit/b
:Unicode测
set Unicode_Result=27979
exit/b
:Unicode23618
set Unicode_Result=层
exit/b
:Unicode层
set Unicode_Result=23618
exit/b
:Unicode36461
set Unicode_Result=蹭
exit/b
:Unicode蹭
set Unicode_Result=36461
exit/b
:Unicode25554
set Unicode_Result=插
exit/b
:Unicode插
set Unicode_Result=25554
exit/b
:Unicode21449
set Unicode_Result=叉
exit/b
:Unicode叉
set Unicode_Result=21449
exit/b
:Unicode33580
set Unicode_Result=茬
exit/b
:Unicode茬
set Unicode_Result=33580
exit/b
:Unicode33590
set Unicode_Result=茶
exit/b
:Unicode茶
set Unicode_Result=33590
exit/b
:Unicode26597
set Unicode_Result=查
exit/b
:Unicode查
set Unicode_Result=26597
exit/b
:Unicode30900
set Unicode_Result=碴
exit/b
:Unicode碴
set Unicode_Result=30900
exit/b
:Unicode25661
set Unicode_Result=搽
exit/b
:Unicode搽
set Unicode_Result=25661
exit/b
:Unicode23519
set Unicode_Result=察
exit/b
:Unicode察
set Unicode_Result=23519
exit/b
:Unicode23700
set Unicode_Result=岔
exit/b
:Unicode岔
set Unicode_Result=23700
exit/b
:Unicode24046
set Unicode_Result=差
exit/b
:Unicode差
set Unicode_Result=24046
exit/b
:Unicode35815
set Unicode_Result=诧
exit/b
:Unicode诧
set Unicode_Result=35815
exit/b
:Unicode25286
set Unicode_Result=拆
exit/b
:Unicode拆
set Unicode_Result=25286
exit/b
:Unicode26612
set Unicode_Result=柴
exit/b
:Unicode柴
set Unicode_Result=26612
exit/b
:Unicode35962
set Unicode_Result=豺
exit/b
:Unicode豺
set Unicode_Result=35962
exit/b
:Unicode25600
set Unicode_Result=搀
exit/b
:Unicode搀
set Unicode_Result=25600
exit/b
:Unicode25530
set Unicode_Result=掺
exit/b
:Unicode掺
set Unicode_Result=25530
exit/b
:Unicode34633
set Unicode_Result=蝉
exit/b
:Unicode蝉
set Unicode_Result=34633
exit/b
:Unicode39307
set Unicode_Result=馋
exit/b
:Unicode馋
set Unicode_Result=39307
exit/b
:Unicode35863
set Unicode_Result=谗
exit/b
:Unicode谗
set Unicode_Result=35863
exit/b
:Unicode32544
set Unicode_Result=缠
exit/b
:Unicode缠
set Unicode_Result=32544
exit/b
:Unicode38130
set Unicode_Result=铲
exit/b
:Unicode铲
set Unicode_Result=38130
exit/b
:Unicode20135
set Unicode_Result=产
exit/b
:Unicode产
set Unicode_Result=20135
exit/b
:Unicode38416
set Unicode_Result=阐
exit/b
:Unicode阐
set Unicode_Result=38416
exit/b
:Unicode39076
set Unicode_Result=颤
exit/b
:Unicode颤
set Unicode_Result=39076
exit/b
:Unicode26124
set Unicode_Result=昌
exit/b
:Unicode昌
set Unicode_Result=26124
exit/b
:Unicode29462
set Unicode_Result=猖
exit/b
:Unicode猖
set Unicode_Result=29462
exit/b
:Unicode22330
set Unicode_Result=场
exit/b
:Unicode场
set Unicode_Result=22330
exit/b
:Unicode23581
set Unicode_Result=尝
exit/b
:Unicode尝
set Unicode_Result=23581
exit/b
:Unicode24120
set Unicode_Result=常
exit/b
:Unicode常
set Unicode_Result=24120
exit/b
:Unicode38271
set Unicode_Result=长
exit/b
:Unicode长
set Unicode_Result=38271
exit/b
:Unicode20607
set Unicode_Result=偿
exit/b
:Unicode偿
set Unicode_Result=20607
exit/b
:Unicode32928
set Unicode_Result=肠
exit/b
:Unicode肠
set Unicode_Result=32928
exit/b
:Unicode21378
set Unicode_Result=厂
exit/b
:Unicode厂
set Unicode_Result=21378
exit/b
:Unicode25950
set Unicode_Result=敞
exit/b
:Unicode敞
set Unicode_Result=25950
exit/b
:Unicode30021
set Unicode_Result=畅
exit/b
:Unicode畅
set Unicode_Result=30021
exit/b
:Unicode21809
set Unicode_Result=唱
exit/b
:Unicode唱
set Unicode_Result=21809
exit/b
:Unicode20513
set Unicode_Result=倡
exit/b
:Unicode倡
set Unicode_Result=20513
exit/b
:Unicode36229
set Unicode_Result=超
exit/b
:Unicode超
set Unicode_Result=36229
exit/b
:Unicode25220
set Unicode_Result=抄
exit/b
:Unicode抄
set Unicode_Result=25220
exit/b
:Unicode38046
set Unicode_Result=钞
exit/b
:Unicode钞
set Unicode_Result=38046
exit/b
:Unicode26397
set Unicode_Result=朝
exit/b
:Unicode朝
set Unicode_Result=26397
exit/b
:Unicode22066
set Unicode_Result=嘲
exit/b
:Unicode嘲
set Unicode_Result=22066
exit/b
:Unicode28526
set Unicode_Result=潮
exit/b
:Unicode潮
set Unicode_Result=28526
exit/b
:Unicode24034
set Unicode_Result=巢
exit/b
:Unicode巢
set Unicode_Result=24034
exit/b
:Unicode21557
set Unicode_Result=吵
exit/b
:Unicode吵
set Unicode_Result=21557
exit/b
:Unicode28818
set Unicode_Result=炒
exit/b
:Unicode炒
set Unicode_Result=28818
exit/b
:Unicode36710
set Unicode_Result=车
exit/b
:Unicode车
set Unicode_Result=36710
exit/b
:Unicode25199
set Unicode_Result=扯
exit/b
:Unicode扯
set Unicode_Result=25199
exit/b
:Unicode25764
set Unicode_Result=撤
exit/b
:Unicode撤
set Unicode_Result=25764
exit/b
:Unicode25507
set Unicode_Result=掣
exit/b
:Unicode掣
set Unicode_Result=25507
exit/b
:Unicode24443
set Unicode_Result=彻
exit/b
:Unicode彻
set Unicode_Result=24443
exit/b
:Unicode28552
set Unicode_Result=澈
exit/b
:Unicode澈
set Unicode_Result=28552
exit/b
:Unicode37108
set Unicode_Result=郴
exit/b
:Unicode郴
set Unicode_Result=37108
exit/b
:Unicode33251
set Unicode_Result=臣
exit/b
:Unicode臣
set Unicode_Result=33251
exit/b
:Unicode36784
set Unicode_Result=辰
exit/b
:Unicode辰
set Unicode_Result=36784
exit/b
:Unicode23576
set Unicode_Result=尘
exit/b
:Unicode尘
set Unicode_Result=23576
exit/b
:Unicode26216
set Unicode_Result=晨
exit/b
:Unicode晨
set Unicode_Result=26216
exit/b
:Unicode24561
set Unicode_Result=忱
exit/b
:Unicode忱
set Unicode_Result=24561
exit/b
:Unicode27785
set Unicode_Result=沉
exit/b
:Unicode沉
set Unicode_Result=27785
exit/b
:Unicode38472
set Unicode_Result=陈
exit/b
:Unicode陈
set Unicode_Result=38472
exit/b
:Unicode36225
set Unicode_Result=趁
exit/b
:Unicode趁
set Unicode_Result=36225
exit/b
:Unicode34924
set Unicode_Result=衬
exit/b
:Unicode衬
set Unicode_Result=34924
exit/b
:Unicode25745
set Unicode_Result=撑
exit/b
:Unicode撑
set Unicode_Result=25745
exit/b
:Unicode31216
set Unicode_Result=称
exit/b
:Unicode称
set Unicode_Result=31216
exit/b
:Unicode22478
set Unicode_Result=城
exit/b
:Unicode城
set Unicode_Result=22478
exit/b
:Unicode27225
set Unicode_Result=橙
exit/b
:Unicode橙
set Unicode_Result=27225
exit/b
:Unicode25104
set Unicode_Result=成
exit/b
:Unicode成
set Unicode_Result=25104
exit/b
:Unicode21576
set Unicode_Result=呈
exit/b
:Unicode呈
set Unicode_Result=21576
exit/b
:Unicode20056
set Unicode_Result=乘
exit/b
:Unicode乘
set Unicode_Result=20056
exit/b
:Unicode31243
set Unicode_Result=程
exit/b
:Unicode程
set Unicode_Result=31243
exit/b
:Unicode24809
set Unicode_Result=惩
exit/b
:Unicode惩
set Unicode_Result=24809
exit/b
:Unicode28548
set Unicode_Result=澄
exit/b
:Unicode澄
set Unicode_Result=28548
exit/b
:Unicode35802
set Unicode_Result=诚
exit/b
:Unicode诚
set Unicode_Result=35802
exit/b
:Unicode25215
set Unicode_Result=承
exit/b
:Unicode承
set Unicode_Result=25215
exit/b
:Unicode36894
set Unicode_Result=逞
exit/b
:Unicode逞
set Unicode_Result=36894
exit/b
:Unicode39563
set Unicode_Result=骋
exit/b
:Unicode骋
set Unicode_Result=39563
exit/b
:Unicode31204
set Unicode_Result=秤
exit/b
:Unicode秤
set Unicode_Result=31204
exit/b
:Unicode21507
set Unicode_Result=吃
exit/b
:Unicode吃
set Unicode_Result=21507
exit/b
:Unicode30196
set Unicode_Result=痴
exit/b
:Unicode痴
set Unicode_Result=30196
exit/b
:Unicode25345
set Unicode_Result=持
exit/b
:Unicode持
set Unicode_Result=25345
exit/b
:Unicode21273
set Unicode_Result=匙
exit/b
:Unicode匙
set Unicode_Result=21273
exit/b
:Unicode27744
set Unicode_Result=池
exit/b
:Unicode池
set Unicode_Result=27744
exit/b
:Unicode36831
set Unicode_Result=迟
exit/b
:Unicode迟
set Unicode_Result=36831
exit/b
:Unicode24347
set Unicode_Result=弛
exit/b
:Unicode弛
set Unicode_Result=24347
exit/b
:Unicode39536
set Unicode_Result=驰
exit/b
:Unicode驰
set Unicode_Result=39536
exit/b
:Unicode32827
set Unicode_Result=耻
exit/b
:Unicode耻
set Unicode_Result=32827
exit/b
:Unicode40831
set Unicode_Result=齿
exit/b
:Unicode齿
set Unicode_Result=40831
exit/b
:Unicode20360
set Unicode_Result=侈
exit/b
:Unicode侈
set Unicode_Result=20360
exit/b
:Unicode23610
set Unicode_Result=尺
exit/b
:Unicode尺
set Unicode_Result=23610
exit/b
:Unicode36196
set Unicode_Result=赤
exit/b
:Unicode赤
set Unicode_Result=36196
exit/b
:Unicode32709
set Unicode_Result=翅
exit/b
:Unicode翅
set Unicode_Result=32709
exit/b
:Unicode26021
set Unicode_Result=斥
exit/b
:Unicode斥
set Unicode_Result=26021
exit/b
:Unicode28861
set Unicode_Result=炽
exit/b
:Unicode炽
set Unicode_Result=28861
exit/b
:Unicode20805
set Unicode_Result=充
exit/b
:Unicode充
set Unicode_Result=20805
exit/b
:Unicode20914
set Unicode_Result=冲
exit/b
:Unicode冲
set Unicode_Result=20914
exit/b
:Unicode34411
set Unicode_Result=虫
exit/b
:Unicode虫
set Unicode_Result=34411
exit/b
:Unicode23815
set Unicode_Result=崇
exit/b
:Unicode崇
set Unicode_Result=23815
exit/b
:Unicode23456
set Unicode_Result=宠
exit/b
:Unicode宠
set Unicode_Result=23456
exit/b
:Unicode25277
set Unicode_Result=抽
exit/b
:Unicode抽
set Unicode_Result=25277
exit/b
:Unicode37228
set Unicode_Result=酬
exit/b
:Unicode酬
set Unicode_Result=37228
exit/b
:Unicode30068
set Unicode_Result=畴
exit/b
:Unicode畴
set Unicode_Result=30068
exit/b
:Unicode36364
set Unicode_Result=踌
exit/b
:Unicode踌
set Unicode_Result=36364
exit/b
:Unicode31264
set Unicode_Result=稠
exit/b
:Unicode稠
set Unicode_Result=31264
exit/b
:Unicode24833
set Unicode_Result=愁
exit/b
:Unicode愁
set Unicode_Result=24833
exit/b
:Unicode31609
set Unicode_Result=筹
exit/b
:Unicode筹
set Unicode_Result=31609
exit/b
:Unicode20167
set Unicode_Result=仇
exit/b
:Unicode仇
set Unicode_Result=20167
exit/b
:Unicode32504
set Unicode_Result=绸
exit/b
:Unicode绸
set Unicode_Result=32504
exit/b
:Unicode30597
set Unicode_Result=瞅
exit/b
:Unicode瞅
set Unicode_Result=30597
exit/b
:Unicode19985
set Unicode_Result=丑
exit/b
:Unicode丑
set Unicode_Result=19985
exit/b
:Unicode33261
set Unicode_Result=臭
exit/b
:Unicode臭
set Unicode_Result=33261
exit/b
:Unicode21021
set Unicode_Result=初
exit/b
:Unicode初
set Unicode_Result=21021
exit/b
:Unicode20986
set Unicode_Result=出
exit/b
:Unicode出
set Unicode_Result=20986
exit/b
:Unicode27249
set Unicode_Result=橱
exit/b
:Unicode橱
set Unicode_Result=27249
exit/b
:Unicode21416
set Unicode_Result=厨
exit/b
:Unicode厨
set Unicode_Result=21416
exit/b
:Unicode36487
set Unicode_Result=躇
exit/b
:Unicode躇
set Unicode_Result=36487
exit/b
:Unicode38148
set Unicode_Result=锄
exit/b
:Unicode锄
set Unicode_Result=38148
exit/b
:Unicode38607
set Unicode_Result=雏
exit/b
:Unicode雏
set Unicode_Result=38607
exit/b
:Unicode28353
set Unicode_Result=滁
exit/b
:Unicode滁
set Unicode_Result=28353
exit/b
:Unicode38500
set Unicode_Result=除
exit/b
:Unicode除
set Unicode_Result=38500
exit/b
:Unicode26970
set Unicode_Result=楚
exit/b
:Unicode楚
set Unicode_Result=26970
exit/b
:Unicode30784
set Unicode_Result=础
exit/b
:Unicode础
set Unicode_Result=30784
exit/b
:Unicode20648
set Unicode_Result=储
exit/b
:Unicode储
set Unicode_Result=20648
exit/b
:Unicode30679
set Unicode_Result=矗
exit/b
:Unicode矗
set Unicode_Result=30679
exit/b
:Unicode25616
set Unicode_Result=搐
exit/b
:Unicode搐
set Unicode_Result=25616
exit/b
:Unicode35302
set Unicode_Result=触
exit/b
:Unicode触
set Unicode_Result=35302
exit/b
:Unicode22788
set Unicode_Result=处
exit/b
:Unicode处
set Unicode_Result=22788
exit/b
:Unicode25571
set Unicode_Result=揣
exit/b
:Unicode揣
set Unicode_Result=25571
exit/b
:Unicode24029
set Unicode_Result=川
exit/b
:Unicode川
set Unicode_Result=24029
exit/b
:Unicode31359
set Unicode_Result=穿
exit/b
:Unicode穿
set Unicode_Result=31359
exit/b
:Unicode26941
set Unicode_Result=椽
exit/b
:Unicode椽
set Unicode_Result=26941
exit/b
:Unicode20256
set Unicode_Result=传
exit/b
:Unicode传
set Unicode_Result=20256
exit/b
:Unicode33337
set Unicode_Result=船
exit/b
:Unicode船
set Unicode_Result=33337
exit/b
:Unicode21912
set Unicode_Result=喘
exit/b
:Unicode喘
set Unicode_Result=21912
exit/b
:Unicode20018
set Unicode_Result=串
exit/b
:Unicode串
set Unicode_Result=20018
exit/b
:Unicode30126
set Unicode_Result=疮
exit/b
:Unicode疮
set Unicode_Result=30126
exit/b
:Unicode31383
set Unicode_Result=窗
exit/b
:Unicode窗
set Unicode_Result=31383
exit/b
:Unicode24162
set Unicode_Result=幢
exit/b
:Unicode幢
set Unicode_Result=24162
exit/b
:Unicode24202
set Unicode_Result=床
exit/b
:Unicode床
set Unicode_Result=24202
exit/b
:Unicode38383
set Unicode_Result=闯
exit/b
:Unicode闯
set Unicode_Result=38383
exit/b
:Unicode21019
set Unicode_Result=创
exit/b
:Unicode创
set Unicode_Result=21019
exit/b
:Unicode21561
set Unicode_Result=吹
exit/b
:Unicode吹
set Unicode_Result=21561
exit/b
:Unicode28810
set Unicode_Result=炊
exit/b
:Unicode炊
set Unicode_Result=28810
exit/b
:Unicode25462
set Unicode_Result=捶
exit/b
:Unicode捶
set Unicode_Result=25462
exit/b
:Unicode38180
set Unicode_Result=锤
exit/b
:Unicode锤
set Unicode_Result=38180
exit/b
:Unicode22402
set Unicode_Result=垂
exit/b
:Unicode垂
set Unicode_Result=22402
exit/b
:Unicode26149
set Unicode_Result=春
exit/b
:Unicode春
set Unicode_Result=26149
exit/b
:Unicode26943
set Unicode_Result=椿
exit/b
:Unicode椿
set Unicode_Result=26943
exit/b
:Unicode37255
set Unicode_Result=醇
exit/b
:Unicode醇
set Unicode_Result=37255
exit/b
:Unicode21767
set Unicode_Result=唇
exit/b
:Unicode唇
set Unicode_Result=21767
exit/b
:Unicode28147
set Unicode_Result=淳
exit/b
:Unicode淳
set Unicode_Result=28147
exit/b
:Unicode32431
set Unicode_Result=纯
exit/b
:Unicode纯
set Unicode_Result=32431
exit/b
:Unicode34850
set Unicode_Result=蠢
exit/b
:Unicode蠢
set Unicode_Result=34850
exit/b
:Unicode25139
set Unicode_Result=戳
exit/b
:Unicode戳
set Unicode_Result=25139
exit/b
:Unicode32496
set Unicode_Result=绰
exit/b
:Unicode绰
set Unicode_Result=32496
exit/b
:Unicode30133
set Unicode_Result=疵
exit/b
:Unicode疵
set Unicode_Result=30133
exit/b
:Unicode33576
set Unicode_Result=茨
exit/b
:Unicode茨
set Unicode_Result=33576
exit/b
:Unicode30913
set Unicode_Result=磁
exit/b
:Unicode磁
set Unicode_Result=30913
exit/b
:Unicode38604
set Unicode_Result=雌
exit/b
:Unicode雌
set Unicode_Result=38604
exit/b
:Unicode36766
set Unicode_Result=辞
exit/b
:Unicode辞
set Unicode_Result=36766
exit/b
:Unicode24904
set Unicode_Result=慈
exit/b
:Unicode慈
set Unicode_Result=24904
exit/b
:Unicode29943
set Unicode_Result=瓷
exit/b
:Unicode瓷
set Unicode_Result=29943
exit/b
:Unicode35789
set Unicode_Result=词
exit/b
:Unicode词
set Unicode_Result=35789
exit/b
:Unicode27492
set Unicode_Result=此
exit/b
:Unicode此
set Unicode_Result=27492
exit/b
:Unicode21050
set Unicode_Result=刺
exit/b
:Unicode刺
set Unicode_Result=21050
exit/b
:Unicode36176
set Unicode_Result=赐
exit/b
:Unicode赐
set Unicode_Result=36176
exit/b
:Unicode27425
set Unicode_Result=次
exit/b
:Unicode次
set Unicode_Result=27425
exit/b
:Unicode32874
set Unicode_Result=聪
exit/b
:Unicode聪
set Unicode_Result=32874
exit/b
:Unicode33905
set Unicode_Result=葱
exit/b
:Unicode葱
set Unicode_Result=33905
exit/b
:Unicode22257
set Unicode_Result=囱
exit/b
:Unicode囱
set Unicode_Result=22257
exit/b
:Unicode21254
set Unicode_Result=匆
exit/b
:Unicode匆
set Unicode_Result=21254
exit/b
:Unicode20174
set Unicode_Result=从
exit/b
:Unicode从
set Unicode_Result=20174
exit/b
:Unicode19995
set Unicode_Result=丛
exit/b
:Unicode丛
set Unicode_Result=19995
exit/b
:Unicode20945
set Unicode_Result=凑
exit/b
:Unicode凑
set Unicode_Result=20945
exit/b
:Unicode31895
set Unicode_Result=粗
exit/b
:Unicode粗
set Unicode_Result=31895
exit/b
:Unicode37259
set Unicode_Result=醋
exit/b
:Unicode醋
set Unicode_Result=37259
exit/b
:Unicode31751
set Unicode_Result=簇
exit/b
:Unicode簇
set Unicode_Result=31751
exit/b
:Unicode20419
set Unicode_Result=促
exit/b
:Unicode促
set Unicode_Result=20419
exit/b
:Unicode36479
set Unicode_Result=蹿
exit/b
:Unicode蹿
set Unicode_Result=36479
exit/b
:Unicode31713
set Unicode_Result=篡
exit/b
:Unicode篡
set Unicode_Result=31713
exit/b
:Unicode31388
set Unicode_Result=窜
exit/b
:Unicode窜
set Unicode_Result=31388
exit/b
:Unicode25703
set Unicode_Result=摧
exit/b
:Unicode摧
set Unicode_Result=25703
exit/b
:Unicode23828
set Unicode_Result=崔
exit/b
:Unicode崔
set Unicode_Result=23828
exit/b
:Unicode20652
set Unicode_Result=催
exit/b
:Unicode催
set Unicode_Result=20652
exit/b
:Unicode33030
set Unicode_Result=脆
exit/b
:Unicode脆
set Unicode_Result=33030
exit/b
:Unicode30209
set Unicode_Result=瘁
exit/b
:Unicode瘁
set Unicode_Result=30209
exit/b
:Unicode31929
set Unicode_Result=粹
exit/b
:Unicode粹
set Unicode_Result=31929
exit/b
:Unicode28140
set Unicode_Result=淬
exit/b
:Unicode淬
set Unicode_Result=28140
exit/b
:Unicode32736
set Unicode_Result=翠
exit/b
:Unicode翠
set Unicode_Result=32736
exit/b
:Unicode26449
set Unicode_Result=村
exit/b
:Unicode村
set Unicode_Result=26449
exit/b
:Unicode23384
set Unicode_Result=存
exit/b
:Unicode存
set Unicode_Result=23384
exit/b
:Unicode23544
set Unicode_Result=寸
exit/b
:Unicode寸
set Unicode_Result=23544
exit/b
:Unicode30923
set Unicode_Result=磋
exit/b
:Unicode磋
set Unicode_Result=30923
exit/b
:Unicode25774
set Unicode_Result=撮
exit/b
:Unicode撮
set Unicode_Result=25774
exit/b
:Unicode25619
set Unicode_Result=搓
exit/b
:Unicode搓
set Unicode_Result=25619
exit/b
:Unicode25514
set Unicode_Result=措
exit/b
:Unicode措
set Unicode_Result=25514
exit/b
:Unicode25387
set Unicode_Result=挫
exit/b
:Unicode挫
set Unicode_Result=25387
exit/b
:Unicode38169
set Unicode_Result=错
exit/b
:Unicode错
set Unicode_Result=38169
exit/b
:Unicode25645
set Unicode_Result=搭
exit/b
:Unicode搭
set Unicode_Result=25645
exit/b
:Unicode36798
set Unicode_Result=达
exit/b
:Unicode达
set Unicode_Result=36798
exit/b
:Unicode31572
set Unicode_Result=答
exit/b
:Unicode答
set Unicode_Result=31572
exit/b
:Unicode30249
set Unicode_Result=瘩
exit/b
:Unicode瘩
set Unicode_Result=30249
exit/b
:Unicode25171
set Unicode_Result=打
exit/b
:Unicode打
set Unicode_Result=25171
exit/b
:Unicode22823
set Unicode_Result=大
exit/b
:Unicode大
set Unicode_Result=22823
exit/b
:Unicode21574
set Unicode_Result=呆
exit/b
:Unicode呆
set Unicode_Result=21574
exit/b
:Unicode27513
set Unicode_Result=歹
exit/b
:Unicode歹
set Unicode_Result=27513
exit/b
:Unicode20643
set Unicode_Result=傣
exit/b
:Unicode傣
set Unicode_Result=20643
exit/b
:Unicode25140
set Unicode_Result=戴
exit/b
:Unicode戴
set Unicode_Result=25140
exit/b
:Unicode24102
set Unicode_Result=带
exit/b
:Unicode带
set Unicode_Result=24102
exit/b
:Unicode27526
set Unicode_Result=殆
exit/b
:Unicode殆
set Unicode_Result=27526
exit/b
:Unicode20195
set Unicode_Result=代
exit/b
:Unicode代
set Unicode_Result=20195
exit/b
:Unicode36151
set Unicode_Result=贷
exit/b
:Unicode贷
set Unicode_Result=36151
exit/b
:Unicode34955
set Unicode_Result=袋
exit/b
:Unicode袋
set Unicode_Result=34955
exit/b
:Unicode24453
set Unicode_Result=待
exit/b
:Unicode待
set Unicode_Result=24453
exit/b
:Unicode36910
set Unicode_Result=逮
exit/b
:Unicode逮
set Unicode_Result=36910
exit/b
:Unicode24608
set Unicode_Result=怠
exit/b
:Unicode怠
set Unicode_Result=24608
exit/b
:Unicode32829
set Unicode_Result=耽
exit/b
:Unicode耽
set Unicode_Result=32829
exit/b
:Unicode25285
set Unicode_Result=担
exit/b
:Unicode担
set Unicode_Result=25285
exit/b
:Unicode20025
set Unicode_Result=丹
exit/b
:Unicode丹
set Unicode_Result=20025
exit/b
:Unicode21333
set Unicode_Result=单
exit/b
:Unicode单
set Unicode_Result=21333
exit/b
:Unicode37112
set Unicode_Result=郸
exit/b
:Unicode郸
set Unicode_Result=37112
exit/b
:Unicode25528
set Unicode_Result=掸
exit/b
:Unicode掸
set Unicode_Result=25528
exit/b
:Unicode32966
set Unicode_Result=胆
exit/b
:Unicode胆
set Unicode_Result=32966
exit/b
:Unicode26086
set Unicode_Result=旦
exit/b
:Unicode旦
set Unicode_Result=26086
exit/b
:Unicode27694
set Unicode_Result=氮
exit/b
:Unicode氮
set Unicode_Result=27694
exit/b
:Unicode20294
set Unicode_Result=但
exit/b
:Unicode但
set Unicode_Result=20294
exit/b
:Unicode24814
set Unicode_Result=惮
exit/b
:Unicode惮
set Unicode_Result=24814
exit/b
:Unicode28129
set Unicode_Result=淡
exit/b
:Unicode淡
set Unicode_Result=28129
exit/b
:Unicode35806
set Unicode_Result=诞
exit/b
:Unicode诞
set Unicode_Result=35806
exit/b
:Unicode24377
set Unicode_Result=弹
exit/b
:Unicode弹
set Unicode_Result=24377
exit/b
:Unicode34507
set Unicode_Result=蛋
exit/b
:Unicode蛋
set Unicode_Result=34507
exit/b
:Unicode24403
set Unicode_Result=当
exit/b
:Unicode当
set Unicode_Result=24403
exit/b
:Unicode25377
set Unicode_Result=挡
exit/b
:Unicode挡
set Unicode_Result=25377
exit/b
:Unicode20826
set Unicode_Result=党
exit/b
:Unicode党
set Unicode_Result=20826
exit/b
:Unicode33633
set Unicode_Result=荡
exit/b
:Unicode荡
set Unicode_Result=33633
exit/b
:Unicode26723
set Unicode_Result=档
exit/b
:Unicode档
set Unicode_Result=26723
exit/b
:Unicode20992
set Unicode_Result=刀
exit/b
:Unicode刀
set Unicode_Result=20992
exit/b
:Unicode25443
set Unicode_Result=捣
exit/b
:Unicode捣
set Unicode_Result=25443
exit/b
:Unicode36424
set Unicode_Result=蹈
exit/b
:Unicode蹈
set Unicode_Result=36424
exit/b
:Unicode20498
set Unicode_Result=倒
exit/b
:Unicode倒
set Unicode_Result=20498
exit/b
:Unicode23707
set Unicode_Result=岛
exit/b
:Unicode岛
set Unicode_Result=23707
exit/b
:Unicode31095
set Unicode_Result=祷
exit/b
:Unicode祷
set Unicode_Result=31095
exit/b
:Unicode23548
set Unicode_Result=导
exit/b
:Unicode导
set Unicode_Result=23548
exit/b
:Unicode21040
set Unicode_Result=到
exit/b
:Unicode到
set Unicode_Result=21040
exit/b
:Unicode31291
set Unicode_Result=稻
exit/b
:Unicode稻
set Unicode_Result=31291
exit/b
:Unicode24764
set Unicode_Result=悼
exit/b
:Unicode悼
set Unicode_Result=24764
exit/b
:Unicode36947
set Unicode_Result=道
exit/b
:Unicode道
set Unicode_Result=36947
exit/b
:Unicode30423
set Unicode_Result=盗
exit/b
:Unicode盗
set Unicode_Result=30423
exit/b
:Unicode24503
set Unicode_Result=德
exit/b
:Unicode德
set Unicode_Result=24503
exit/b
:Unicode24471
set Unicode_Result=得
exit/b
:Unicode得
set Unicode_Result=24471
exit/b
:Unicode30340
set Unicode_Result=的
exit/b
:Unicode的
set Unicode_Result=30340
exit/b
:Unicode36460
set Unicode_Result=蹬
exit/b
:Unicode蹬
set Unicode_Result=36460
exit/b
:Unicode28783
set Unicode_Result=灯
exit/b
:Unicode灯
set Unicode_Result=28783
exit/b
:Unicode30331
set Unicode_Result=登
exit/b
:Unicode登
set Unicode_Result=30331
exit/b
:Unicode31561
set Unicode_Result=等
exit/b
:Unicode等
set Unicode_Result=31561
exit/b
:Unicode30634
set Unicode_Result=瞪
exit/b
:Unicode瞪
set Unicode_Result=30634
exit/b
:Unicode20979
set Unicode_Result=凳
exit/b
:Unicode凳
set Unicode_Result=20979
exit/b
:Unicode37011
set Unicode_Result=邓
exit/b
:Unicode邓
set Unicode_Result=37011
exit/b
:Unicode22564
set Unicode_Result=堤
exit/b
:Unicode堤
set Unicode_Result=22564
exit/b
:Unicode20302
set Unicode_Result=低
exit/b
:Unicode低
set Unicode_Result=20302
exit/b
:Unicode28404
set Unicode_Result=滴
exit/b
:Unicode滴
set Unicode_Result=28404
exit/b
:Unicode36842
set Unicode_Result=迪
exit/b
:Unicode迪
set Unicode_Result=36842
exit/b
:Unicode25932
set Unicode_Result=敌
exit/b
:Unicode敌
set Unicode_Result=25932
exit/b
:Unicode31515
set Unicode_Result=笛
exit/b
:Unicode笛
set Unicode_Result=31515
exit/b
:Unicode29380
set Unicode_Result=狄
exit/b
:Unicode狄
set Unicode_Result=29380
exit/b
:Unicode28068
set Unicode_Result=涤
exit/b
:Unicode涤
set Unicode_Result=28068
exit/b
:Unicode32735
set Unicode_Result=翟
exit/b
:Unicode翟
set Unicode_Result=32735
exit/b
:Unicode23265
set Unicode_Result=嫡
exit/b
:Unicode嫡
set Unicode_Result=23265
exit/b
:Unicode25269
set Unicode_Result=抵
exit/b
:Unicode抵
set Unicode_Result=25269
exit/b
:Unicode24213
set Unicode_Result=底
exit/b
:Unicode底
set Unicode_Result=24213
exit/b
:Unicode22320
set Unicode_Result=地
exit/b
:Unicode地
set Unicode_Result=22320
exit/b
:Unicode33922
set Unicode_Result=蒂
exit/b
:Unicode蒂
set Unicode_Result=33922
exit/b
:Unicode31532
set Unicode_Result=第
exit/b
:Unicode第
set Unicode_Result=31532
exit/b
:Unicode24093
set Unicode_Result=帝
exit/b
:Unicode帝
set Unicode_Result=24093
exit/b
:Unicode24351
set Unicode_Result=弟
exit/b
:Unicode弟
set Unicode_Result=24351
exit/b
:Unicode36882
set Unicode_Result=递
exit/b
:Unicode递
set Unicode_Result=36882
exit/b
:Unicode32532
set Unicode_Result=缔
exit/b
:Unicode缔
set Unicode_Result=32532
exit/b
:Unicode39072
set Unicode_Result=颠
exit/b
:Unicode颠
set Unicode_Result=39072
exit/b
:Unicode25474
set Unicode_Result=掂
exit/b
:Unicode掂
set Unicode_Result=25474
exit/b
:Unicode28359
set Unicode_Result=滇
exit/b
:Unicode滇
set Unicode_Result=28359
exit/b
:Unicode30872
set Unicode_Result=碘
exit/b
:Unicode碘
set Unicode_Result=30872
exit/b
:Unicode28857
set Unicode_Result=点
exit/b
:Unicode点
set Unicode_Result=28857
exit/b
:Unicode20856
set Unicode_Result=典
exit/b
:Unicode典
set Unicode_Result=20856
exit/b
:Unicode38747
set Unicode_Result=靛
exit/b
:Unicode靛
set Unicode_Result=38747
exit/b
:Unicode22443
set Unicode_Result=垫
exit/b
:Unicode垫
set Unicode_Result=22443
exit/b
:Unicode30005
set Unicode_Result=电
exit/b
:Unicode电
set Unicode_Result=30005
exit/b
:Unicode20291
set Unicode_Result=佃
exit/b
:Unicode佃
set Unicode_Result=20291
exit/b
:Unicode30008
set Unicode_Result=甸
exit/b
:Unicode甸
set Unicode_Result=30008
exit/b
:Unicode24215
set Unicode_Result=店
exit/b
:Unicode店
set Unicode_Result=24215
exit/b
:Unicode24806
set Unicode_Result=惦
exit/b
:Unicode惦
set Unicode_Result=24806
exit/b
:Unicode22880
set Unicode_Result=奠
exit/b
:Unicode奠
set Unicode_Result=22880
exit/b
:Unicode28096
set Unicode_Result=淀
exit/b
:Unicode淀
set Unicode_Result=28096
exit/b
:Unicode27583
set Unicode_Result=殿
exit/b
:Unicode殿
set Unicode_Result=27583
exit/b
:Unicode30857
set Unicode_Result=碉
exit/b
:Unicode碉
set Unicode_Result=30857
exit/b
:Unicode21500
set Unicode_Result=叼
exit/b
:Unicode叼
set Unicode_Result=21500
exit/b
:Unicode38613
set Unicode_Result=雕
exit/b
:Unicode雕
set Unicode_Result=38613
exit/b
:Unicode20939
set Unicode_Result=凋
exit/b
:Unicode凋
set Unicode_Result=20939
exit/b
:Unicode20993
set Unicode_Result=刁
exit/b
:Unicode刁
set Unicode_Result=20993
exit/b
:Unicode25481
set Unicode_Result=掉
exit/b
:Unicode掉
set Unicode_Result=25481
exit/b
:Unicode21514
set Unicode_Result=吊
exit/b
:Unicode吊
set Unicode_Result=21514
exit/b
:Unicode38035
set Unicode_Result=钓
exit/b
:Unicode钓
set Unicode_Result=38035
exit/b
:Unicode35843
set Unicode_Result=调
exit/b
:Unicode调
set Unicode_Result=35843
exit/b
:Unicode36300
set Unicode_Result=跌
exit/b
:Unicode跌
set Unicode_Result=36300
exit/b
:Unicode29241
set Unicode_Result=爹
exit/b
:Unicode爹
set Unicode_Result=29241
exit/b
:Unicode30879
set Unicode_Result=碟
exit/b
:Unicode碟
set Unicode_Result=30879
exit/b
:Unicode34678
set Unicode_Result=蝶
exit/b
:Unicode蝶
set Unicode_Result=34678
exit/b
:Unicode36845
set Unicode_Result=迭
exit/b
:Unicode迭
set Unicode_Result=36845
exit/b
:Unicode35853
set Unicode_Result=谍
exit/b
:Unicode谍
set Unicode_Result=35853
exit/b
:Unicode21472
set Unicode_Result=叠
exit/b
:Unicode叠
set Unicode_Result=21472
exit/b
:Unicode19969
set Unicode_Result=丁
exit/b
:Unicode丁
set Unicode_Result=19969
exit/b
:Unicode30447
set Unicode_Result=盯
exit/b
:Unicode盯
set Unicode_Result=30447
exit/b
:Unicode21486
set Unicode_Result=叮
exit/b
:Unicode叮
set Unicode_Result=21486
exit/b
:Unicode38025
set Unicode_Result=钉
exit/b
:Unicode钉
set Unicode_Result=38025
exit/b
:Unicode39030
set Unicode_Result=顶
exit/b
:Unicode顶
set Unicode_Result=39030
exit/b
:Unicode40718
set Unicode_Result=鼎
exit/b
:Unicode鼎
set Unicode_Result=40718
exit/b
:Unicode38189
set Unicode_Result=锭
exit/b
:Unicode锭
set Unicode_Result=38189
exit/b
:Unicode23450
set Unicode_Result=定
exit/b
:Unicode定
set Unicode_Result=23450
exit/b
:Unicode35746
set Unicode_Result=订
exit/b
:Unicode订
set Unicode_Result=35746
exit/b
:Unicode20002
set Unicode_Result=丢
exit/b
:Unicode丢
set Unicode_Result=20002
exit/b
:Unicode19996
set Unicode_Result=东
exit/b
:Unicode东
set Unicode_Result=19996
exit/b
:Unicode20908
set Unicode_Result=冬
exit/b
:Unicode冬
set Unicode_Result=20908
exit/b
:Unicode33891
set Unicode_Result=董
exit/b
:Unicode董
set Unicode_Result=33891
exit/b
:Unicode25026
set Unicode_Result=懂
exit/b
:Unicode懂
set Unicode_Result=25026
exit/b
:Unicode21160
set Unicode_Result=动
exit/b
:Unicode动
set Unicode_Result=21160
exit/b
:Unicode26635
set Unicode_Result=栋
exit/b
:Unicode栋
set Unicode_Result=26635
exit/b
:Unicode20375
set Unicode_Result=侗
exit/b
:Unicode侗
set Unicode_Result=20375
exit/b
:Unicode24683
set Unicode_Result=恫
exit/b
:Unicode恫
set Unicode_Result=24683
exit/b
:Unicode20923
set Unicode_Result=冻
exit/b
:Unicode冻
set Unicode_Result=20923
exit/b
:Unicode27934
set Unicode_Result=洞
exit/b
:Unicode洞
set Unicode_Result=27934
exit/b
:Unicode20828
set Unicode_Result=兜
exit/b
:Unicode兜
set Unicode_Result=20828
exit/b
:Unicode25238
set Unicode_Result=抖
exit/b
:Unicode抖
set Unicode_Result=25238
exit/b
:Unicode26007
set Unicode_Result=斗
exit/b
:Unicode斗
set Unicode_Result=26007
exit/b
:Unicode38497
set Unicode_Result=陡
exit/b
:Unicode陡
set Unicode_Result=38497
exit/b
:Unicode35910
set Unicode_Result=豆
exit/b
:Unicode豆
set Unicode_Result=35910
exit/b
:Unicode36887
set Unicode_Result=逗
exit/b
:Unicode逗
set Unicode_Result=36887
exit/b
:Unicode30168
set Unicode_Result=痘
exit/b
:Unicode痘
set Unicode_Result=30168
exit/b
:Unicode37117
set Unicode_Result=都
exit/b
:Unicode都
set Unicode_Result=37117
exit/b
:Unicode30563
set Unicode_Result=督
exit/b
:Unicode督
set Unicode_Result=30563
exit/b
:Unicode27602
set Unicode_Result=毒
exit/b
:Unicode毒
set Unicode_Result=27602
exit/b
:Unicode29322
set Unicode_Result=犊
exit/b
:Unicode犊
set Unicode_Result=29322
exit/b
:Unicode29420
set Unicode_Result=独
exit/b
:Unicode独
set Unicode_Result=29420
exit/b
:Unicode35835
set Unicode_Result=读
exit/b
:Unicode读
set Unicode_Result=35835
exit/b
:Unicode22581
set Unicode_Result=堵
exit/b
:Unicode堵
set Unicode_Result=22581
exit/b
:Unicode30585
set Unicode_Result=睹
exit/b
:Unicode睹
set Unicode_Result=30585
exit/b
:Unicode36172
set Unicode_Result=赌
exit/b
:Unicode赌
set Unicode_Result=36172
exit/b
:Unicode26460
set Unicode_Result=杜
exit/b
:Unicode杜
set Unicode_Result=26460
exit/b
:Unicode38208
set Unicode_Result=镀
exit/b
:Unicode镀
set Unicode_Result=38208
exit/b
:Unicode32922
set Unicode_Result=肚
exit/b
:Unicode肚
set Unicode_Result=32922
exit/b
:Unicode24230
set Unicode_Result=度
exit/b
:Unicode度
set Unicode_Result=24230
exit/b
:Unicode28193
set Unicode_Result=渡
exit/b
:Unicode渡
set Unicode_Result=28193
exit/b
:Unicode22930
set Unicode_Result=妒
exit/b
:Unicode妒
set Unicode_Result=22930
exit/b
:Unicode31471
set Unicode_Result=端
exit/b
:Unicode端
set Unicode_Result=31471
exit/b
:Unicode30701
set Unicode_Result=短
exit/b
:Unicode短
set Unicode_Result=30701
exit/b
:Unicode38203
set Unicode_Result=锻
exit/b
:Unicode锻
set Unicode_Result=38203
exit/b
:Unicode27573
set Unicode_Result=段
exit/b
:Unicode段
set Unicode_Result=27573
exit/b
:Unicode26029
set Unicode_Result=断
exit/b
:Unicode断
set Unicode_Result=26029
exit/b
:Unicode32526
set Unicode_Result=缎
exit/b
:Unicode缎
set Unicode_Result=32526
exit/b
:Unicode22534
set Unicode_Result=堆
exit/b
:Unicode堆
set Unicode_Result=22534
exit/b
:Unicode20817
set Unicode_Result=兑
exit/b
:Unicode兑
set Unicode_Result=20817
exit/b
:Unicode38431
set Unicode_Result=队
exit/b
:Unicode队
set Unicode_Result=38431
exit/b
:Unicode23545
set Unicode_Result=对
exit/b
:Unicode对
set Unicode_Result=23545
exit/b
:Unicode22697
set Unicode_Result=墩
exit/b
:Unicode墩
set Unicode_Result=22697
exit/b
:Unicode21544
set Unicode_Result=吨
exit/b
:Unicode吨
set Unicode_Result=21544
exit/b
:Unicode36466
set Unicode_Result=蹲
exit/b
:Unicode蹲
set Unicode_Result=36466
exit/b
:Unicode25958
set Unicode_Result=敦
exit/b
:Unicode敦
set Unicode_Result=25958
exit/b
:Unicode39039
set Unicode_Result=顿
exit/b
:Unicode顿
set Unicode_Result=39039
exit/b
:Unicode22244
set Unicode_Result=囤
exit/b
:Unicode囤
set Unicode_Result=22244
exit/b
:Unicode38045
set Unicode_Result=钝
exit/b
:Unicode钝
set Unicode_Result=38045
exit/b
:Unicode30462
set Unicode_Result=盾
exit/b
:Unicode盾
set Unicode_Result=30462
exit/b
:Unicode36929
set Unicode_Result=遁
exit/b
:Unicode遁
set Unicode_Result=36929
exit/b
:Unicode25479
set Unicode_Result=掇
exit/b
:Unicode掇
set Unicode_Result=25479
exit/b
:Unicode21702
set Unicode_Result=哆
exit/b
:Unicode哆
set Unicode_Result=21702
exit/b
:Unicode22810
set Unicode_Result=多
exit/b
:Unicode多
set Unicode_Result=22810
exit/b
:Unicode22842
set Unicode_Result=夺
exit/b
:Unicode夺
set Unicode_Result=22842
exit/b
:Unicode22427
set Unicode_Result=垛
exit/b
:Unicode垛
set Unicode_Result=22427
exit/b
:Unicode36530
set Unicode_Result=躲
exit/b
:Unicode躲
set Unicode_Result=36530
exit/b
:Unicode26421
set Unicode_Result=朵
exit/b
:Unicode朵
set Unicode_Result=26421
exit/b
:Unicode36346
set Unicode_Result=跺
exit/b
:Unicode跺
set Unicode_Result=36346
exit/b
:Unicode33333
set Unicode_Result=舵
exit/b
:Unicode舵
set Unicode_Result=33333
exit/b
:Unicode21057
set Unicode_Result=剁
exit/b
:Unicode剁
set Unicode_Result=21057
exit/b
:Unicode24816
set Unicode_Result=惰
exit/b
:Unicode惰
set Unicode_Result=24816
exit/b
:Unicode22549
set Unicode_Result=堕
exit/b
:Unicode堕
set Unicode_Result=22549
exit/b
:Unicode34558
set Unicode_Result=蛾
exit/b
:Unicode蛾
set Unicode_Result=34558
exit/b
:Unicode23784
set Unicode_Result=峨
exit/b
:Unicode峨
set Unicode_Result=23784
exit/b
:Unicode40517
set Unicode_Result=鹅
exit/b
:Unicode鹅
set Unicode_Result=40517
exit/b
:Unicode20420
set Unicode_Result=俄
exit/b
:Unicode俄
set Unicode_Result=20420
exit/b
:Unicode39069
set Unicode_Result=额
exit/b
:Unicode额
set Unicode_Result=39069
exit/b
:Unicode35769
set Unicode_Result=讹
exit/b
:Unicode讹
set Unicode_Result=35769
exit/b
:Unicode23077
set Unicode_Result=娥
exit/b
:Unicode娥
set Unicode_Result=23077
exit/b
:Unicode24694
set Unicode_Result=恶
exit/b
:Unicode恶
set Unicode_Result=24694
exit/b
:Unicode21380
set Unicode_Result=厄
exit/b
:Unicode厄
set Unicode_Result=21380
exit/b
:Unicode25212
set Unicode_Result=扼
exit/b
:Unicode扼
set Unicode_Result=25212
exit/b
:Unicode36943
set Unicode_Result=遏
exit/b
:Unicode遏
set Unicode_Result=36943
exit/b
:Unicode37122
set Unicode_Result=鄂
exit/b
:Unicode鄂
set Unicode_Result=37122
exit/b
:Unicode39295
set Unicode_Result=饿
exit/b
:Unicode饿
set Unicode_Result=39295
exit/b
:Unicode24681
set Unicode_Result=恩
exit/b
:Unicode恩
set Unicode_Result=24681
exit/b
:Unicode32780
set Unicode_Result=而
exit/b
:Unicode而
set Unicode_Result=32780
exit/b
:Unicode20799
set Unicode_Result=儿
exit/b
:Unicode儿
set Unicode_Result=20799
exit/b
:Unicode32819
set Unicode_Result=耳
exit/b
:Unicode耳
set Unicode_Result=32819
exit/b
:Unicode23572
set Unicode_Result=尔
exit/b
:Unicode尔
set Unicode_Result=23572
exit/b
:Unicode39285
set Unicode_Result=饵
exit/b
:Unicode饵
set Unicode_Result=39285
exit/b
:Unicode27953
set Unicode_Result=洱
exit/b
:Unicode洱
set Unicode_Result=27953
exit/b
:Unicode20108
set Unicode_Result=二
exit/b
:Unicode二
set Unicode_Result=20108
exit/b
:Unicode36144
set Unicode_Result=贰
exit/b
:Unicode贰
set Unicode_Result=36144
exit/b
:Unicode21457
set Unicode_Result=发
exit/b
:Unicode发
set Unicode_Result=21457
exit/b
:Unicode32602
set Unicode_Result=罚
exit/b
:Unicode罚
set Unicode_Result=32602
exit/b
:Unicode31567
set Unicode_Result=筏
exit/b
:Unicode筏
set Unicode_Result=31567
exit/b
:Unicode20240
set Unicode_Result=伐
exit/b
:Unicode伐
set Unicode_Result=20240
exit/b
:Unicode20047
set Unicode_Result=乏
exit/b
:Unicode乏
set Unicode_Result=20047
exit/b
:Unicode38400
set Unicode_Result=阀
exit/b
:Unicode阀
set Unicode_Result=38400
exit/b
:Unicode27861
set Unicode_Result=法
exit/b
:Unicode法
set Unicode_Result=27861
exit/b
:Unicode29648
set Unicode_Result=珐
exit/b
:Unicode珐
set Unicode_Result=29648
exit/b
:Unicode34281
set Unicode_Result=藩
exit/b
:Unicode藩
set Unicode_Result=34281
exit/b
:Unicode24070
set Unicode_Result=帆
exit/b
:Unicode帆
set Unicode_Result=24070
exit/b
:Unicode30058
set Unicode_Result=番
exit/b
:Unicode番
set Unicode_Result=30058
exit/b
:Unicode32763
set Unicode_Result=翻
exit/b
:Unicode翻
set Unicode_Result=32763
exit/b
:Unicode27146
set Unicode_Result=樊
exit/b
:Unicode樊
set Unicode_Result=27146
exit/b
:Unicode30718
set Unicode_Result=矾
exit/b
:Unicode矾
set Unicode_Result=30718
exit/b
:Unicode38034
set Unicode_Result=钒
exit/b
:Unicode钒
set Unicode_Result=38034
exit/b
:Unicode32321
set Unicode_Result=繁
exit/b
:Unicode繁
set Unicode_Result=32321
exit/b
:Unicode20961
set Unicode_Result=凡
exit/b
:Unicode凡
set Unicode_Result=20961
exit/b
:Unicode28902
set Unicode_Result=烦
exit/b
:Unicode烦
set Unicode_Result=28902
exit/b
:Unicode21453
set Unicode_Result=反
exit/b
:Unicode反
set Unicode_Result=21453
exit/b
:Unicode36820
set Unicode_Result=返
exit/b
:Unicode返
set Unicode_Result=36820
exit/b
:Unicode33539
set Unicode_Result=范
exit/b
:Unicode范
set Unicode_Result=33539
exit/b
:Unicode36137
set Unicode_Result=贩
exit/b
:Unicode贩
set Unicode_Result=36137
exit/b
:Unicode29359
set Unicode_Result=犯
exit/b
:Unicode犯
set Unicode_Result=29359
exit/b
:Unicode39277
set Unicode_Result=饭
exit/b
:Unicode饭
set Unicode_Result=39277
exit/b
:Unicode27867
set Unicode_Result=泛
exit/b
:Unicode泛
set Unicode_Result=27867
exit/b
:Unicode22346
set Unicode_Result=坊
exit/b
:Unicode坊
set Unicode_Result=22346
exit/b
:Unicode33459
set Unicode_Result=芳
exit/b
:Unicode芳
set Unicode_Result=33459
exit/b
:Unicode26041
set Unicode_Result=方
exit/b
:Unicode方
set Unicode_Result=26041
exit/b
:Unicode32938
set Unicode_Result=肪
exit/b
:Unicode肪
set Unicode_Result=32938
exit/b
:Unicode25151
set Unicode_Result=房
exit/b
:Unicode房
set Unicode_Result=25151
exit/b
:Unicode38450
set Unicode_Result=防
exit/b
:Unicode防
set Unicode_Result=38450
exit/b
:Unicode22952
set Unicode_Result=妨
exit/b
:Unicode妨
set Unicode_Result=22952
exit/b
:Unicode20223
set Unicode_Result=仿
exit/b
:Unicode仿
set Unicode_Result=20223
exit/b
:Unicode35775
set Unicode_Result=访
exit/b
:Unicode访
set Unicode_Result=35775
exit/b
:Unicode32442
set Unicode_Result=纺
exit/b
:Unicode纺
set Unicode_Result=32442
exit/b
:Unicode25918
set Unicode_Result=放
exit/b
:Unicode放
set Unicode_Result=25918
exit/b
:Unicode33778
set Unicode_Result=菲
exit/b
:Unicode菲
set Unicode_Result=33778
exit/b
:Unicode38750
set Unicode_Result=非
exit/b
:Unicode非
set Unicode_Result=38750
exit/b
:Unicode21857
set Unicode_Result=啡
exit/b
:Unicode啡
set Unicode_Result=21857
exit/b
:Unicode39134
set Unicode_Result=飞
exit/b
:Unicode飞
set Unicode_Result=39134
exit/b
:Unicode32933
set Unicode_Result=肥
exit/b
:Unicode肥
set Unicode_Result=32933
exit/b
:Unicode21290
set Unicode_Result=匪
exit/b
:Unicode匪
set Unicode_Result=21290
exit/b
:Unicode35837
set Unicode_Result=诽
exit/b
:Unicode诽
set Unicode_Result=35837
exit/b
:Unicode21536
set Unicode_Result=吠
exit/b
:Unicode吠
set Unicode_Result=21536
exit/b
:Unicode32954
set Unicode_Result=肺
exit/b
:Unicode肺
set Unicode_Result=32954
exit/b
:Unicode24223
set Unicode_Result=废
exit/b
:Unicode废
set Unicode_Result=24223
exit/b
:Unicode27832
set Unicode_Result=沸
exit/b
:Unicode沸
set Unicode_Result=27832
exit/b
:Unicode36153
set Unicode_Result=费
exit/b
:Unicode费
set Unicode_Result=36153
exit/b
:Unicode33452
set Unicode_Result=芬
exit/b
:Unicode芬
set Unicode_Result=33452
exit/b
:Unicode37210
set Unicode_Result=酚
exit/b
:Unicode酚
set Unicode_Result=37210
exit/b
:Unicode21545
set Unicode_Result=吩
exit/b
:Unicode吩
set Unicode_Result=21545
exit/b
:Unicode27675
set Unicode_Result=氛
exit/b
:Unicode氛
set Unicode_Result=27675
exit/b
:Unicode20998
set Unicode_Result=分
exit/b
:Unicode分
set Unicode_Result=20998
exit/b
:Unicode32439
set Unicode_Result=纷
exit/b
:Unicode纷
set Unicode_Result=32439
exit/b
:Unicode22367
set Unicode_Result=坟
exit/b
:Unicode坟
set Unicode_Result=22367
exit/b
:Unicode28954
set Unicode_Result=焚
exit/b
:Unicode焚
set Unicode_Result=28954
exit/b
:Unicode27774
set Unicode_Result=汾
exit/b
:Unicode汾
set Unicode_Result=27774
exit/b
:Unicode31881
set Unicode_Result=粉
exit/b
:Unicode粉
set Unicode_Result=31881
exit/b
:Unicode22859
set Unicode_Result=奋
exit/b
:Unicode奋
set Unicode_Result=22859
exit/b
:Unicode20221
set Unicode_Result=份
exit/b
:Unicode份
set Unicode_Result=20221
exit/b
:Unicode24575
set Unicode_Result=忿
exit/b
:Unicode忿
set Unicode_Result=24575
exit/b
:Unicode24868
set Unicode_Result=愤
exit/b
:Unicode愤
set Unicode_Result=24868
exit/b
:Unicode31914
set Unicode_Result=粪
exit/b
:Unicode粪
set Unicode_Result=31914
exit/b
:Unicode20016
set Unicode_Result=丰
exit/b
:Unicode丰
set Unicode_Result=20016
exit/b
:Unicode23553
set Unicode_Result=封
exit/b
:Unicode封
set Unicode_Result=23553
exit/b
:Unicode26539
set Unicode_Result=枫
exit/b
:Unicode枫
set Unicode_Result=26539
exit/b
:Unicode34562
set Unicode_Result=蜂
exit/b
:Unicode蜂
set Unicode_Result=34562
exit/b
:Unicode23792
set Unicode_Result=峰
exit/b
:Unicode峰
set Unicode_Result=23792
exit/b
:Unicode38155
set Unicode_Result=锋
exit/b
:Unicode锋
set Unicode_Result=38155
exit/b
:Unicode39118
set Unicode_Result=风
exit/b
:Unicode风
set Unicode_Result=39118
exit/b
:Unicode30127
set Unicode_Result=疯
exit/b
:Unicode疯
set Unicode_Result=30127
exit/b
:Unicode28925
set Unicode_Result=烽
exit/b
:Unicode烽
set Unicode_Result=28925
exit/b
:Unicode36898
set Unicode_Result=逢
exit/b
:Unicode逢
set Unicode_Result=36898
exit/b
:Unicode20911
set Unicode_Result=冯
exit/b
:Unicode冯
set Unicode_Result=20911
exit/b
:Unicode32541
set Unicode_Result=缝
exit/b
:Unicode缝
set Unicode_Result=32541
exit/b
:Unicode35773
set Unicode_Result=讽
exit/b
:Unicode讽
set Unicode_Result=35773
exit/b
:Unicode22857
set Unicode_Result=奉
exit/b
:Unicode奉
set Unicode_Result=22857
exit/b
:Unicode20964
set Unicode_Result=凤
exit/b
:Unicode凤
set Unicode_Result=20964
exit/b
:Unicode20315
set Unicode_Result=佛
exit/b
:Unicode佛
set Unicode_Result=20315
exit/b
:Unicode21542
set Unicode_Result=否
exit/b
:Unicode否
set Unicode_Result=21542
exit/b
:Unicode22827
set Unicode_Result=夫
exit/b
:Unicode夫
set Unicode_Result=22827
exit/b
:Unicode25975
set Unicode_Result=敷
exit/b
:Unicode敷
set Unicode_Result=25975
exit/b
:Unicode32932
set Unicode_Result=肤
exit/b
:Unicode肤
set Unicode_Result=32932
exit/b
:Unicode23413
set Unicode_Result=孵
exit/b
:Unicode孵
set Unicode_Result=23413
exit/b
:Unicode25206
set Unicode_Result=扶
exit/b
:Unicode扶
set Unicode_Result=25206
exit/b
:Unicode25282
set Unicode_Result=拂
exit/b
:Unicode拂
set Unicode_Result=25282
exit/b
:Unicode36752
set Unicode_Result=辐
exit/b
:Unicode辐
set Unicode_Result=36752
exit/b
:Unicode24133
set Unicode_Result=幅
exit/b
:Unicode幅
set Unicode_Result=24133
exit/b
:Unicode27679
set Unicode_Result=氟
exit/b
:Unicode氟
set Unicode_Result=27679
exit/b
:Unicode31526
set Unicode_Result=符
exit/b
:Unicode符
set Unicode_Result=31526
exit/b
:Unicode20239
set Unicode_Result=伏
exit/b
:Unicode伏
set Unicode_Result=20239
exit/b
:Unicode20440
set Unicode_Result=俘
exit/b
:Unicode俘
set Unicode_Result=20440
exit/b
:Unicode26381
set Unicode_Result=服
exit/b
:Unicode服
set Unicode_Result=26381
exit/b
:Unicode28014
set Unicode_Result=浮
exit/b
:Unicode浮
set Unicode_Result=28014
exit/b
:Unicode28074
set Unicode_Result=涪
exit/b
:Unicode涪
set Unicode_Result=28074
exit/b
:Unicode31119
set Unicode_Result=福
exit/b
:Unicode福
set Unicode_Result=31119
exit/b
:Unicode34993
set Unicode_Result=袱
exit/b
:Unicode袱
set Unicode_Result=34993
exit/b
:Unicode24343
set Unicode_Result=弗
exit/b
:Unicode弗
set Unicode_Result=24343
exit/b
:Unicode29995
set Unicode_Result=甫
exit/b
:Unicode甫
set Unicode_Result=29995
exit/b
:Unicode25242
set Unicode_Result=抚
exit/b
:Unicode抚
set Unicode_Result=25242
exit/b
:Unicode36741
set Unicode_Result=辅
exit/b
:Unicode辅
set Unicode_Result=36741
exit/b
:Unicode20463
set Unicode_Result=俯
exit/b
:Unicode俯
set Unicode_Result=20463
exit/b
:Unicode37340
set Unicode_Result=釜
exit/b
:Unicode釜
set Unicode_Result=37340
exit/b
:Unicode26023
set Unicode_Result=斧
exit/b
:Unicode斧
set Unicode_Result=26023
exit/b
:Unicode33071
set Unicode_Result=脯
exit/b
:Unicode脯
set Unicode_Result=33071
exit/b
:Unicode33105
set Unicode_Result=腑
exit/b
:Unicode腑
set Unicode_Result=33105
exit/b
:Unicode24220
set Unicode_Result=府
exit/b
:Unicode府
set Unicode_Result=24220
exit/b
:Unicode33104
set Unicode_Result=腐
exit/b
:Unicode腐
set Unicode_Result=33104
exit/b
:Unicode36212
set Unicode_Result=赴
exit/b
:Unicode赴
set Unicode_Result=36212
exit/b
:Unicode21103
set Unicode_Result=副
exit/b
:Unicode副
set Unicode_Result=21103
exit/b
:Unicode35206
set Unicode_Result=覆
exit/b
:Unicode覆
set Unicode_Result=35206
exit/b
:Unicode36171
set Unicode_Result=赋
exit/b
:Unicode赋
set Unicode_Result=36171
exit/b
:Unicode22797
set Unicode_Result=复
exit/b
:Unicode复
set Unicode_Result=22797
exit/b
:Unicode20613
set Unicode_Result=傅
exit/b
:Unicode傅
set Unicode_Result=20613
exit/b
:Unicode20184
set Unicode_Result=付
exit/b
:Unicode付
set Unicode_Result=20184
exit/b
:Unicode38428
set Unicode_Result=阜
exit/b
:Unicode阜
set Unicode_Result=38428
exit/b
:Unicode29238
set Unicode_Result=父
exit/b
:Unicode父
set Unicode_Result=29238
exit/b
:Unicode33145
set Unicode_Result=腹
exit/b
:Unicode腹
set Unicode_Result=33145
exit/b
:Unicode36127
set Unicode_Result=负
exit/b
:Unicode负
set Unicode_Result=36127
exit/b
:Unicode23500
set Unicode_Result=富
exit/b
:Unicode富
set Unicode_Result=23500
exit/b
:Unicode35747
set Unicode_Result=讣
exit/b
:Unicode讣
set Unicode_Result=35747
exit/b
:Unicode38468
set Unicode_Result=附
exit/b
:Unicode附
set Unicode_Result=38468
exit/b
:Unicode22919
set Unicode_Result=妇
exit/b
:Unicode妇
set Unicode_Result=22919
exit/b
:Unicode32538
set Unicode_Result=缚
exit/b
:Unicode缚
set Unicode_Result=32538
exit/b
:Unicode21648
set Unicode_Result=咐
exit/b
:Unicode咐
set Unicode_Result=21648
exit/b
:Unicode22134
set Unicode_Result=噶
exit/b
:Unicode噶
set Unicode_Result=22134
exit/b
:Unicode22030
set Unicode_Result=嘎
exit/b
:Unicode嘎
set Unicode_Result=22030
exit/b
:Unicode35813
set Unicode_Result=该
exit/b
:Unicode该
set Unicode_Result=35813
exit/b
:Unicode25913
set Unicode_Result=改
exit/b
:Unicode改
set Unicode_Result=25913
exit/b
:Unicode27010
set Unicode_Result=概
exit/b
:Unicode概
set Unicode_Result=27010
exit/b
:Unicode38041
set Unicode_Result=钙
exit/b
:Unicode钙
set Unicode_Result=38041
exit/b
:Unicode30422
set Unicode_Result=盖
exit/b
:Unicode盖
set Unicode_Result=30422
exit/b
:Unicode28297
set Unicode_Result=溉
exit/b
:Unicode溉
set Unicode_Result=28297
exit/b
:Unicode24178
set Unicode_Result=干
exit/b
:Unicode干
set Unicode_Result=24178
exit/b
:Unicode29976
set Unicode_Result=甘
exit/b
:Unicode甘
set Unicode_Result=29976
exit/b
:Unicode26438
set Unicode_Result=杆
exit/b
:Unicode杆
set Unicode_Result=26438
exit/b
:Unicode26577
set Unicode_Result=柑
exit/b
:Unicode柑
set Unicode_Result=26577
exit/b
:Unicode31487
set Unicode_Result=竿
exit/b
:Unicode竿
set Unicode_Result=31487
exit/b
:Unicode32925
set Unicode_Result=肝
exit/b
:Unicode肝
set Unicode_Result=32925
exit/b
:Unicode36214
set Unicode_Result=赶
exit/b
:Unicode赶
set Unicode_Result=36214
exit/b
:Unicode24863
set Unicode_Result=感
exit/b
:Unicode感
set Unicode_Result=24863
exit/b
:Unicode31174
set Unicode_Result=秆
exit/b
:Unicode秆
set Unicode_Result=31174
exit/b
:Unicode25954
set Unicode_Result=敢
exit/b
:Unicode敢
set Unicode_Result=25954
exit/b
:Unicode36195
set Unicode_Result=赣
exit/b
:Unicode赣
set Unicode_Result=36195
exit/b
:Unicode20872
set Unicode_Result=冈
exit/b
:Unicode冈
set Unicode_Result=20872
exit/b
:Unicode21018
set Unicode_Result=刚
exit/b
:Unicode刚
set Unicode_Result=21018
exit/b
:Unicode38050
set Unicode_Result=钢
exit/b
:Unicode钢
set Unicode_Result=38050
exit/b
:Unicode32568
set Unicode_Result=缸
exit/b
:Unicode缸
set Unicode_Result=32568
exit/b
:Unicode32923
set Unicode_Result=肛
exit/b
:Unicode肛
set Unicode_Result=32923
exit/b
:Unicode32434
set Unicode_Result=纲
exit/b
:Unicode纲
set Unicode_Result=32434
exit/b
:Unicode23703
set Unicode_Result=岗
exit/b
:Unicode岗
set Unicode_Result=23703
exit/b
:Unicode28207
set Unicode_Result=港
exit/b
:Unicode港
set Unicode_Result=28207
exit/b
:Unicode26464
set Unicode_Result=杠
exit/b
:Unicode杠
set Unicode_Result=26464
exit/b
:Unicode31705
set Unicode_Result=篙
exit/b
:Unicode篙
set Unicode_Result=31705
exit/b
:Unicode30347
set Unicode_Result=皋
exit/b
:Unicode皋
set Unicode_Result=30347
exit/b
:Unicode39640
set Unicode_Result=高
exit/b
:Unicode高
set Unicode_Result=39640
exit/b
:Unicode33167
set Unicode_Result=膏
exit/b
:Unicode膏
set Unicode_Result=33167
exit/b
:Unicode32660
set Unicode_Result=羔
exit/b
:Unicode羔
set Unicode_Result=32660
exit/b
:Unicode31957
set Unicode_Result=糕
exit/b
:Unicode糕
set Unicode_Result=31957
exit/b
:Unicode25630
set Unicode_Result=搞
exit/b
:Unicode搞
set Unicode_Result=25630
exit/b
:Unicode38224
set Unicode_Result=镐
exit/b
:Unicode镐
set Unicode_Result=38224
exit/b
:Unicode31295
set Unicode_Result=稿
exit/b
:Unicode稿
set Unicode_Result=31295
exit/b
:Unicode21578
set Unicode_Result=告
exit/b
:Unicode告
set Unicode_Result=21578
exit/b
:Unicode21733
set Unicode_Result=哥
exit/b
:Unicode哥
set Unicode_Result=21733
exit/b
:Unicode27468
set Unicode_Result=歌
exit/b
:Unicode歌
set Unicode_Result=27468
exit/b
:Unicode25601
set Unicode_Result=搁
exit/b
:Unicode搁
set Unicode_Result=25601
exit/b
:Unicode25096
set Unicode_Result=戈
exit/b
:Unicode戈
set Unicode_Result=25096
exit/b
:Unicode40509
set Unicode_Result=鸽
exit/b
:Unicode鸽
set Unicode_Result=40509
exit/b
:Unicode33011
set Unicode_Result=胳
exit/b
:Unicode胳
set Unicode_Result=33011
exit/b
:Unicode30105
set Unicode_Result=疙
exit/b
:Unicode疙
set Unicode_Result=30105
exit/b
:Unicode21106
set Unicode_Result=割
exit/b
:Unicode割
set Unicode_Result=21106
exit/b
:Unicode38761
set Unicode_Result=革
exit/b
:Unicode革
set Unicode_Result=38761
exit/b
:Unicode33883
set Unicode_Result=葛
exit/b
:Unicode葛
set Unicode_Result=33883
exit/b
:Unicode26684
set Unicode_Result=格
exit/b
:Unicode格
set Unicode_Result=26684
exit/b
:Unicode34532
set Unicode_Result=蛤
exit/b
:Unicode蛤
set Unicode_Result=34532
exit/b
:Unicode38401
set Unicode_Result=阁
exit/b
:Unicode阁
set Unicode_Result=38401
exit/b
:Unicode38548
set Unicode_Result=隔
exit/b
:Unicode隔
set Unicode_Result=38548
exit/b
:Unicode38124
set Unicode_Result=铬
exit/b
:Unicode铬
set Unicode_Result=38124
exit/b
:Unicode20010
set Unicode_Result=个
exit/b
:Unicode个
set Unicode_Result=20010
exit/b
:Unicode21508
set Unicode_Result=各
exit/b
:Unicode各
set Unicode_Result=21508
exit/b
:Unicode32473
set Unicode_Result=给
exit/b
:Unicode给
set Unicode_Result=32473
exit/b
:Unicode26681
set Unicode_Result=根
exit/b
:Unicode根
set Unicode_Result=26681
exit/b
:Unicode36319
set Unicode_Result=跟
exit/b
:Unicode跟
set Unicode_Result=36319
exit/b
:Unicode32789
set Unicode_Result=耕
exit/b
:Unicode耕
set Unicode_Result=32789
exit/b
:Unicode26356
set Unicode_Result=更
exit/b
:Unicode更
set Unicode_Result=26356
exit/b
:Unicode24218
set Unicode_Result=庚
exit/b
:Unicode庚
set Unicode_Result=24218
exit/b
:Unicode32697
set Unicode_Result=羹
exit/b
:Unicode羹
set Unicode_Result=32697
exit/b
:Unicode22466
set Unicode_Result=埂
exit/b
:Unicode埂
set Unicode_Result=22466
exit/b
:Unicode32831
set Unicode_Result=耿
exit/b
:Unicode耿
set Unicode_Result=32831
exit/b
:Unicode26775
set Unicode_Result=梗
exit/b
:Unicode梗
set Unicode_Result=26775
exit/b
:Unicode24037
set Unicode_Result=工
exit/b
:Unicode工
set Unicode_Result=24037
exit/b
:Unicode25915
set Unicode_Result=攻
exit/b
:Unicode攻
set Unicode_Result=25915
exit/b
:Unicode21151
set Unicode_Result=功
exit/b
:Unicode功
set Unicode_Result=21151
exit/b
:Unicode24685
set Unicode_Result=恭
exit/b
:Unicode恭
set Unicode_Result=24685
exit/b
:Unicode40858
set Unicode_Result=龚
exit/b
:Unicode龚
set Unicode_Result=40858
exit/b
:Unicode20379
set Unicode_Result=供
exit/b
:Unicode供
set Unicode_Result=20379
exit/b
:Unicode36524
set Unicode_Result=躬
exit/b
:Unicode躬
set Unicode_Result=36524
exit/b
:Unicode20844
set Unicode_Result=公
exit/b
:Unicode公
set Unicode_Result=20844
exit/b
:Unicode23467
set Unicode_Result=宫
exit/b
:Unicode宫
set Unicode_Result=23467
exit/b
:Unicode24339
set Unicode_Result=弓
exit/b
:Unicode弓
set Unicode_Result=24339
exit/b
:Unicode24041
set Unicode_Result=巩
exit/b
:Unicode巩
set Unicode_Result=24041
exit/b
:Unicode27742
set Unicode_Result=汞
exit/b
:Unicode汞
set Unicode_Result=27742
exit/b
:Unicode25329
set Unicode_Result=拱
exit/b
:Unicode拱
set Unicode_Result=25329
exit/b
:Unicode36129
set Unicode_Result=贡
exit/b
:Unicode贡
set Unicode_Result=36129
exit/b
:Unicode20849
set Unicode_Result=共
exit/b
:Unicode共
set Unicode_Result=20849
exit/b
:Unicode38057
set Unicode_Result=钩
exit/b
:Unicode钩
set Unicode_Result=38057
exit/b
:Unicode21246
set Unicode_Result=勾
exit/b
:Unicode勾
set Unicode_Result=21246
exit/b
:Unicode27807
set Unicode_Result=沟
exit/b
:Unicode沟
set Unicode_Result=27807
exit/b
:Unicode33503
set Unicode_Result=苟
exit/b
:Unicode苟
set Unicode_Result=33503
exit/b
:Unicode29399
set Unicode_Result=狗
exit/b
:Unicode狗
set Unicode_Result=29399
exit/b
:Unicode22434
set Unicode_Result=垢
exit/b
:Unicode垢
set Unicode_Result=22434
exit/b
:Unicode26500
set Unicode_Result=构
exit/b
:Unicode构
set Unicode_Result=26500
exit/b
:Unicode36141
set Unicode_Result=购
exit/b
:Unicode购
set Unicode_Result=36141
exit/b
:Unicode22815
set Unicode_Result=够
exit/b
:Unicode够
set Unicode_Result=22815
exit/b
:Unicode36764
set Unicode_Result=辜
exit/b
:Unicode辜
set Unicode_Result=36764
exit/b
:Unicode33735
set Unicode_Result=菇
exit/b
:Unicode菇
set Unicode_Result=33735
exit/b
:Unicode21653
set Unicode_Result=咕
exit/b
:Unicode咕
set Unicode_Result=21653
exit/b
:Unicode31629
set Unicode_Result=箍
exit/b
:Unicode箍
set Unicode_Result=31629
exit/b
:Unicode20272
set Unicode_Result=估
exit/b
:Unicode估
set Unicode_Result=20272
exit/b
:Unicode27837
set Unicode_Result=沽
exit/b
:Unicode沽
set Unicode_Result=27837
exit/b
:Unicode23396
set Unicode_Result=孤
exit/b
:Unicode孤
set Unicode_Result=23396
exit/b
:Unicode22993
set Unicode_Result=姑
exit/b
:Unicode姑
set Unicode_Result=22993
exit/b
:Unicode40723
set Unicode_Result=鼓
exit/b
:Unicode鼓
set Unicode_Result=40723
exit/b
:Unicode21476
set Unicode_Result=古
exit/b
:Unicode古
set Unicode_Result=21476
exit/b
:Unicode34506
set Unicode_Result=蛊
exit/b
:Unicode蛊
set Unicode_Result=34506
exit/b
:Unicode39592
set Unicode_Result=骨
exit/b
:Unicode骨
set Unicode_Result=39592
exit/b
:Unicode35895
set Unicode_Result=谷
exit/b
:Unicode谷
set Unicode_Result=35895
exit/b
:Unicode32929
set Unicode_Result=股
exit/b
:Unicode股
set Unicode_Result=32929
exit/b
:Unicode25925
set Unicode_Result=故
exit/b
:Unicode故
set Unicode_Result=25925
exit/b
:Unicode39038
set Unicode_Result=顾
exit/b
:Unicode顾
set Unicode_Result=39038
exit/b
:Unicode22266
set Unicode_Result=固
exit/b
:Unicode固
set Unicode_Result=22266
exit/b
:Unicode38599
set Unicode_Result=雇
exit/b
:Unicode雇
set Unicode_Result=38599
exit/b
:Unicode21038
set Unicode_Result=刮
exit/b
:Unicode刮
set Unicode_Result=21038
exit/b
:Unicode29916
set Unicode_Result=瓜
exit/b
:Unicode瓜
set Unicode_Result=29916
exit/b
:Unicode21072
set Unicode_Result=剐
exit/b
:Unicode剐
set Unicode_Result=21072
exit/b
:Unicode23521
set Unicode_Result=寡
exit/b
:Unicode寡
set Unicode_Result=23521
exit/b
:Unicode25346
set Unicode_Result=挂
exit/b
:Unicode挂
set Unicode_Result=25346
exit/b
:Unicode35074
set Unicode_Result=褂
exit/b
:Unicode褂
set Unicode_Result=35074
exit/b
:Unicode20054
set Unicode_Result=乖
exit/b
:Unicode乖
set Unicode_Result=20054
exit/b
:Unicode25296
set Unicode_Result=拐
exit/b
:Unicode拐
set Unicode_Result=25296
exit/b
:Unicode24618
set Unicode_Result=怪
exit/b
:Unicode怪
set Unicode_Result=24618
exit/b
:Unicode26874
set Unicode_Result=棺
exit/b
:Unicode棺
set Unicode_Result=26874
exit/b
:Unicode20851
set Unicode_Result=关
exit/b
:Unicode关
set Unicode_Result=20851
exit/b
:Unicode23448
set Unicode_Result=官
exit/b
:Unicode官
set Unicode_Result=23448
exit/b
:Unicode20896
set Unicode_Result=冠
exit/b
:Unicode冠
set Unicode_Result=20896
exit/b
:Unicode35266
set Unicode_Result=观
exit/b
:Unicode观
set Unicode_Result=35266
exit/b
:Unicode31649
set Unicode_Result=管
exit/b
:Unicode管
set Unicode_Result=31649
exit/b
:Unicode39302
set Unicode_Result=馆
exit/b
:Unicode馆
set Unicode_Result=39302
exit/b
:Unicode32592
set Unicode_Result=罐
exit/b
:Unicode罐
set Unicode_Result=32592
exit/b
:Unicode24815
set Unicode_Result=惯
exit/b
:Unicode惯
set Unicode_Result=24815
exit/b
:Unicode28748
set Unicode_Result=灌
exit/b
:Unicode灌
set Unicode_Result=28748
exit/b
:Unicode36143
set Unicode_Result=贯
exit/b
:Unicode贯
set Unicode_Result=36143
exit/b
:Unicode20809
set Unicode_Result=光
exit/b
:Unicode光
set Unicode_Result=20809
exit/b
:Unicode24191
set Unicode_Result=广
exit/b
:Unicode广
set Unicode_Result=24191
exit/b
:Unicode36891
set Unicode_Result=逛
exit/b
:Unicode逛
set Unicode_Result=36891
exit/b
:Unicode29808
set Unicode_Result=瑰
exit/b
:Unicode瑰
set Unicode_Result=29808
exit/b
:Unicode35268
set Unicode_Result=规
exit/b
:Unicode规
set Unicode_Result=35268
exit/b
:Unicode22317
set Unicode_Result=圭
exit/b
:Unicode圭
set Unicode_Result=22317
exit/b
:Unicode30789
set Unicode_Result=硅
exit/b
:Unicode硅
set Unicode_Result=30789
exit/b
:Unicode24402
set Unicode_Result=归
exit/b
:Unicode归
set Unicode_Result=24402
exit/b
:Unicode40863
set Unicode_Result=龟
exit/b
:Unicode龟
set Unicode_Result=40863
exit/b
:Unicode38394
set Unicode_Result=闺
exit/b
:Unicode闺
set Unicode_Result=38394
exit/b
:Unicode36712
set Unicode_Result=轨
exit/b
:Unicode轨
set Unicode_Result=36712
exit/b
:Unicode39740
set Unicode_Result=鬼
exit/b
:Unicode鬼
set Unicode_Result=39740
exit/b
:Unicode35809
set Unicode_Result=诡
exit/b
:Unicode诡
set Unicode_Result=35809
exit/b
:Unicode30328
set Unicode_Result=癸
exit/b
:Unicode癸
set Unicode_Result=30328
exit/b
:Unicode26690
set Unicode_Result=桂
exit/b
:Unicode桂
set Unicode_Result=26690
exit/b
:Unicode26588
set Unicode_Result=柜
exit/b
:Unicode柜
set Unicode_Result=26588
exit/b
:Unicode36330
set Unicode_Result=跪
exit/b
:Unicode跪
set Unicode_Result=36330
exit/b
:Unicode36149
set Unicode_Result=贵
exit/b
:Unicode贵
set Unicode_Result=36149
exit/b
:Unicode21053
set Unicode_Result=刽
exit/b
:Unicode刽
set Unicode_Result=21053
exit/b
:Unicode36746
set Unicode_Result=辊
exit/b
:Unicode辊
set Unicode_Result=36746
exit/b
:Unicode28378
set Unicode_Result=滚
exit/b
:Unicode滚
set Unicode_Result=28378
exit/b
:Unicode26829
set Unicode_Result=棍
exit/b
:Unicode棍
set Unicode_Result=26829
exit/b
:Unicode38149
set Unicode_Result=锅
exit/b
:Unicode锅
set Unicode_Result=38149
exit/b
:Unicode37101
set Unicode_Result=郭
exit/b
:Unicode郭
set Unicode_Result=37101
exit/b
:Unicode22269
set Unicode_Result=国
exit/b
:Unicode国
set Unicode_Result=22269
exit/b
:Unicode26524
set Unicode_Result=果
exit/b
:Unicode果
set Unicode_Result=26524
exit/b
:Unicode35065
set Unicode_Result=裹
exit/b
:Unicode裹
set Unicode_Result=35065
exit/b
:Unicode36807
set Unicode_Result=过
exit/b
:Unicode过
set Unicode_Result=36807
exit/b
:Unicode21704
set Unicode_Result=哈
exit/b
:Unicode哈
set Unicode_Result=21704
exit/b
:Unicode39608
set Unicode_Result=骸
exit/b
:Unicode骸
set Unicode_Result=39608
exit/b
:Unicode23401
set Unicode_Result=孩
exit/b
:Unicode孩
set Unicode_Result=23401
exit/b
:Unicode28023
set Unicode_Result=海
exit/b
:Unicode海
set Unicode_Result=28023
exit/b
:Unicode27686
set Unicode_Result=氦
exit/b
:Unicode氦
set Unicode_Result=27686
exit/b
:Unicode20133
set Unicode_Result=亥
exit/b
:Unicode亥
set Unicode_Result=20133
exit/b
:Unicode23475
set Unicode_Result=害
exit/b
:Unicode害
set Unicode_Result=23475
exit/b
:Unicode39559
set Unicode_Result=骇
exit/b
:Unicode骇
set Unicode_Result=39559
exit/b
:Unicode37219
set Unicode_Result=酣
exit/b
:Unicode酣
set Unicode_Result=37219
exit/b
:Unicode25000
set Unicode_Result=憨
exit/b
:Unicode憨
set Unicode_Result=25000
exit/b
:Unicode37039
set Unicode_Result=邯
exit/b
:Unicode邯
set Unicode_Result=37039
exit/b
:Unicode38889
set Unicode_Result=韩
exit/b
:Unicode韩
set Unicode_Result=38889
exit/b
:Unicode21547
set Unicode_Result=含
exit/b
:Unicode含
set Unicode_Result=21547
exit/b
:Unicode28085
set Unicode_Result=涵
exit/b
:Unicode涵
set Unicode_Result=28085
exit/b
:Unicode23506
set Unicode_Result=寒
exit/b
:Unicode寒
set Unicode_Result=23506
exit/b
:Unicode20989
set Unicode_Result=函
exit/b
:Unicode函
set Unicode_Result=20989
exit/b
:Unicode21898
set Unicode_Result=喊
exit/b
:Unicode喊
set Unicode_Result=21898
exit/b
:Unicode32597
set Unicode_Result=罕
exit/b
:Unicode罕
set Unicode_Result=32597
exit/b
:Unicode32752
set Unicode_Result=翰
exit/b
:Unicode翰
set Unicode_Result=32752
exit/b
:Unicode25788
set Unicode_Result=撼
exit/b
:Unicode撼
set Unicode_Result=25788
exit/b
:Unicode25421
set Unicode_Result=捍
exit/b
:Unicode捍
set Unicode_Result=25421
exit/b
:Unicode26097
set Unicode_Result=旱
exit/b
:Unicode旱
set Unicode_Result=26097
exit/b
:Unicode25022
set Unicode_Result=憾
exit/b
:Unicode憾
set Unicode_Result=25022
exit/b
:Unicode24717
set Unicode_Result=悍
exit/b
:Unicode悍
set Unicode_Result=24717
exit/b
:Unicode28938
set Unicode_Result=焊
exit/b
:Unicode焊
set Unicode_Result=28938
exit/b
:Unicode27735
set Unicode_Result=汗
exit/b
:Unicode汗
set Unicode_Result=27735
exit/b
:Unicode27721
set Unicode_Result=汉
exit/b
:Unicode汉
set Unicode_Result=27721
exit/b
:Unicode22831
set Unicode_Result=夯
exit/b
:Unicode夯
set Unicode_Result=22831
exit/b
:Unicode26477
set Unicode_Result=杭
exit/b
:Unicode杭
set Unicode_Result=26477
exit/b
:Unicode33322
set Unicode_Result=航
exit/b
:Unicode航
set Unicode_Result=33322
exit/b
:Unicode22741
set Unicode_Result=壕
exit/b
:Unicode壕
set Unicode_Result=22741
exit/b
:Unicode22158
set Unicode_Result=嚎
exit/b
:Unicode嚎
set Unicode_Result=22158
exit/b
:Unicode35946
set Unicode_Result=豪
exit/b
:Unicode豪
set Unicode_Result=35946
exit/b
:Unicode27627
set Unicode_Result=毫
exit/b
:Unicode毫
set Unicode_Result=27627
exit/b
:Unicode37085
set Unicode_Result=郝
exit/b
:Unicode郝
set Unicode_Result=37085
exit/b
:Unicode22909
set Unicode_Result=好
exit/b
:Unicode好
set Unicode_Result=22909
exit/b
:Unicode32791
set Unicode_Result=耗
exit/b
:Unicode耗
set Unicode_Result=32791
exit/b
:Unicode21495
set Unicode_Result=号
exit/b
:Unicode号
set Unicode_Result=21495
exit/b
:Unicode28009
set Unicode_Result=浩
exit/b
:Unicode浩
set Unicode_Result=28009
exit/b
:Unicode21621
set Unicode_Result=呵
exit/b
:Unicode呵
set Unicode_Result=21621
exit/b
:Unicode21917
set Unicode_Result=喝
exit/b
:Unicode喝
set Unicode_Result=21917
exit/b
:Unicode33655
set Unicode_Result=荷
exit/b
:Unicode荷
set Unicode_Result=33655
exit/b
:Unicode33743
set Unicode_Result=菏
exit/b
:Unicode菏
set Unicode_Result=33743
exit/b
:Unicode26680
set Unicode_Result=核
exit/b
:Unicode核
set Unicode_Result=26680
exit/b
:Unicode31166
set Unicode_Result=禾
exit/b
:Unicode禾
set Unicode_Result=31166
exit/b
:Unicode21644
set Unicode_Result=和
exit/b
:Unicode和
set Unicode_Result=21644
exit/b
:Unicode20309
set Unicode_Result=何
exit/b
:Unicode何
set Unicode_Result=20309
exit/b
:Unicode21512
set Unicode_Result=合
exit/b
:Unicode合
set Unicode_Result=21512
exit/b
:Unicode30418
set Unicode_Result=盒
exit/b
:Unicode盒
set Unicode_Result=30418
exit/b
:Unicode35977
set Unicode_Result=貉
exit/b
:Unicode貉
set Unicode_Result=35977
exit/b
:Unicode38402
set Unicode_Result=阂
exit/b
:Unicode阂
set Unicode_Result=38402
exit/b
:Unicode27827
set Unicode_Result=河
exit/b
:Unicode河
set Unicode_Result=27827
exit/b
:Unicode28088
set Unicode_Result=涸
exit/b
:Unicode涸
set Unicode_Result=28088
exit/b
:Unicode36203
set Unicode_Result=赫
exit/b
:Unicode赫
set Unicode_Result=36203
exit/b
:Unicode35088
set Unicode_Result=褐
exit/b
:Unicode褐
set Unicode_Result=35088
exit/b
:Unicode40548
set Unicode_Result=鹤
exit/b
:Unicode鹤
set Unicode_Result=40548
exit/b
:Unicode36154
set Unicode_Result=贺
exit/b
:Unicode贺
set Unicode_Result=36154
exit/b
:Unicode22079
set Unicode_Result=嘿
exit/b
:Unicode嘿
set Unicode_Result=22079
exit/b
:Unicode40657
set Unicode_Result=黑
exit/b
:Unicode黑
set Unicode_Result=40657
exit/b
:Unicode30165
set Unicode_Result=痕
exit/b
:Unicode痕
set Unicode_Result=30165
exit/b
:Unicode24456
set Unicode_Result=很
exit/b
:Unicode很
set Unicode_Result=24456
exit/b
:Unicode29408
set Unicode_Result=狠
exit/b
:Unicode狠
set Unicode_Result=29408
exit/b
:Unicode24680
set Unicode_Result=恨
exit/b
:Unicode恨
set Unicode_Result=24680
exit/b
:Unicode21756
set Unicode_Result=哼
exit/b
:Unicode哼
set Unicode_Result=21756
exit/b
:Unicode20136
set Unicode_Result=亨
exit/b
:Unicode亨
set Unicode_Result=20136
exit/b
:Unicode27178
set Unicode_Result=横
exit/b
:Unicode横
set Unicode_Result=27178
exit/b
:Unicode34913
set Unicode_Result=衡
exit/b
:Unicode衡
set Unicode_Result=34913
exit/b
:Unicode24658
set Unicode_Result=恒
exit/b
:Unicode恒
set Unicode_Result=24658
exit/b
:Unicode36720
set Unicode_Result=轰
exit/b
:Unicode轰
set Unicode_Result=36720
exit/b
:Unicode21700
set Unicode_Result=哄
exit/b
:Unicode哄
set Unicode_Result=21700
exit/b
:Unicode28888
set Unicode_Result=烘
exit/b
:Unicode烘
set Unicode_Result=28888
exit/b
:Unicode34425
set Unicode_Result=虹
exit/b
:Unicode虹
set Unicode_Result=34425
exit/b
:Unicode40511
set Unicode_Result=鸿
exit/b
:Unicode鸿
set Unicode_Result=40511
exit/b
:Unicode27946
set Unicode_Result=洪
exit/b
:Unicode洪
set Unicode_Result=27946
exit/b
:Unicode23439
set Unicode_Result=宏
exit/b
:Unicode宏
set Unicode_Result=23439
exit/b
:Unicode24344
set Unicode_Result=弘
exit/b
:Unicode弘
set Unicode_Result=24344
exit/b
:Unicode32418
set Unicode_Result=红
exit/b
:Unicode红
set Unicode_Result=32418
exit/b
:Unicode21897
set Unicode_Result=喉
exit/b
:Unicode喉
set Unicode_Result=21897
exit/b
:Unicode20399
set Unicode_Result=侯
exit/b
:Unicode侯
set Unicode_Result=20399
exit/b
:Unicode29492
set Unicode_Result=猴
exit/b
:Unicode猴
set Unicode_Result=29492
exit/b
:Unicode21564
set Unicode_Result=吼
exit/b
:Unicode吼
set Unicode_Result=21564
exit/b
:Unicode21402
set Unicode_Result=厚
exit/b
:Unicode厚
set Unicode_Result=21402
exit/b
:Unicode20505
set Unicode_Result=候
exit/b
:Unicode候
set Unicode_Result=20505
exit/b
:Unicode21518
set Unicode_Result=后
exit/b
:Unicode后
set Unicode_Result=21518
exit/b
:Unicode21628
set Unicode_Result=呼
exit/b
:Unicode呼
set Unicode_Result=21628
exit/b
:Unicode20046
set Unicode_Result=乎
exit/b
:Unicode乎
set Unicode_Result=20046
exit/b
:Unicode24573
set Unicode_Result=忽
exit/b
:Unicode忽
set Unicode_Result=24573
exit/b
:Unicode29786
set Unicode_Result=瑚
exit/b
:Unicode瑚
set Unicode_Result=29786
exit/b
:Unicode22774
set Unicode_Result=壶
exit/b
:Unicode壶
set Unicode_Result=22774
exit/b
:Unicode33899
set Unicode_Result=葫
exit/b
:Unicode葫
set Unicode_Result=33899
exit/b
:Unicode32993
set Unicode_Result=胡
exit/b
:Unicode胡
set Unicode_Result=32993
exit/b
:Unicode34676
set Unicode_Result=蝴
exit/b
:Unicode蝴
set Unicode_Result=34676
exit/b
:Unicode29392
set Unicode_Result=狐
exit/b
:Unicode狐
set Unicode_Result=29392
exit/b
:Unicode31946
set Unicode_Result=糊
exit/b
:Unicode糊
set Unicode_Result=31946
exit/b
:Unicode28246
set Unicode_Result=湖
exit/b
:Unicode湖
set Unicode_Result=28246
exit/b
:Unicode24359
set Unicode_Result=弧
exit/b
:Unicode弧
set Unicode_Result=24359
exit/b
:Unicode34382
set Unicode_Result=虎
exit/b
:Unicode虎
set Unicode_Result=34382
exit/b
:Unicode21804
set Unicode_Result=唬
exit/b
:Unicode唬
set Unicode_Result=21804
exit/b
:Unicode25252
set Unicode_Result=护
exit/b
:Unicode护
set Unicode_Result=25252
exit/b
:Unicode20114
set Unicode_Result=互
exit/b
:Unicode互
set Unicode_Result=20114
exit/b
:Unicode27818
set Unicode_Result=沪
exit/b
:Unicode沪
set Unicode_Result=27818
exit/b
:Unicode25143
set Unicode_Result=户
exit/b
:Unicode户
set Unicode_Result=25143
exit/b
:Unicode33457
set Unicode_Result=花
exit/b
:Unicode花
set Unicode_Result=33457
exit/b
:Unicode21719
set Unicode_Result=哗
exit/b
:Unicode哗
set Unicode_Result=21719
exit/b
:Unicode21326
set Unicode_Result=华
exit/b
:Unicode华
set Unicode_Result=21326
exit/b
:Unicode29502
set Unicode_Result=猾
exit/b
:Unicode猾
set Unicode_Result=29502
exit/b
:Unicode28369
set Unicode_Result=滑
exit/b
:Unicode滑
set Unicode_Result=28369
exit/b
:Unicode30011
set Unicode_Result=画
exit/b
:Unicode画
set Unicode_Result=30011
exit/b
:Unicode21010
set Unicode_Result=划
exit/b
:Unicode划
set Unicode_Result=21010
exit/b
:Unicode21270
set Unicode_Result=化
exit/b
:Unicode化
set Unicode_Result=21270
exit/b
:Unicode35805
set Unicode_Result=话
exit/b
:Unicode话
set Unicode_Result=35805
exit/b
:Unicode27088
set Unicode_Result=槐
exit/b
:Unicode槐
set Unicode_Result=27088
exit/b
:Unicode24458
set Unicode_Result=徊
exit/b
:Unicode徊
set Unicode_Result=24458
exit/b
:Unicode24576
set Unicode_Result=怀
exit/b
:Unicode怀
set Unicode_Result=24576
exit/b
:Unicode28142
set Unicode_Result=淮
exit/b
:Unicode淮
set Unicode_Result=28142
exit/b
:Unicode22351
set Unicode_Result=坏
exit/b
:Unicode坏
set Unicode_Result=22351
exit/b
:Unicode27426
set Unicode_Result=欢
exit/b
:Unicode欢
set Unicode_Result=27426
exit/b
:Unicode29615
set Unicode_Result=环
exit/b
:Unicode环
set Unicode_Result=29615
exit/b
:Unicode26707
set Unicode_Result=桓
exit/b
:Unicode桓
set Unicode_Result=26707
exit/b
:Unicode36824
set Unicode_Result=还
exit/b
:Unicode还
set Unicode_Result=36824
exit/b
:Unicode32531
set Unicode_Result=缓
exit/b
:Unicode缓
set Unicode_Result=32531
exit/b
:Unicode25442
set Unicode_Result=换
exit/b
:Unicode换
set Unicode_Result=25442
exit/b
:Unicode24739
set Unicode_Result=患
exit/b
:Unicode患
set Unicode_Result=24739
exit/b
:Unicode21796
set Unicode_Result=唤
exit/b
:Unicode唤
set Unicode_Result=21796
exit/b
:Unicode30186
set Unicode_Result=痪
exit/b
:Unicode痪
set Unicode_Result=30186
exit/b
:Unicode35938
set Unicode_Result=豢
exit/b
:Unicode豢
set Unicode_Result=35938
exit/b
:Unicode28949
set Unicode_Result=焕
exit/b
:Unicode焕
set Unicode_Result=28949
exit/b
:Unicode28067
set Unicode_Result=涣
exit/b
:Unicode涣
set Unicode_Result=28067
exit/b
:Unicode23462
set Unicode_Result=宦
exit/b
:Unicode宦
set Unicode_Result=23462
exit/b
:Unicode24187
set Unicode_Result=幻
exit/b
:Unicode幻
set Unicode_Result=24187
exit/b
:Unicode33618
set Unicode_Result=荒
exit/b
:Unicode荒
set Unicode_Result=33618
exit/b
:Unicode24908
set Unicode_Result=慌
exit/b
:Unicode慌
set Unicode_Result=24908
exit/b
:Unicode40644
set Unicode_Result=黄
exit/b
:Unicode黄
set Unicode_Result=40644
exit/b
:Unicode30970
set Unicode_Result=磺
exit/b
:Unicode磺
set Unicode_Result=30970
exit/b
:Unicode34647
set Unicode_Result=蝗
exit/b
:Unicode蝗
set Unicode_Result=34647
exit/b
:Unicode31783
set Unicode_Result=簧
exit/b
:Unicode簧
set Unicode_Result=31783
exit/b
:Unicode30343
set Unicode_Result=皇
exit/b
:Unicode皇
set Unicode_Result=30343
exit/b
:Unicode20976
set Unicode_Result=凰
exit/b
:Unicode凰
set Unicode_Result=20976
exit/b
:Unicode24822
set Unicode_Result=惶
exit/b
:Unicode惶
set Unicode_Result=24822
exit/b
:Unicode29004
set Unicode_Result=煌
exit/b
:Unicode煌
set Unicode_Result=29004
exit/b
:Unicode26179
set Unicode_Result=晃
exit/b
:Unicode晃
set Unicode_Result=26179
exit/b
:Unicode24140
set Unicode_Result=幌
exit/b
:Unicode幌
set Unicode_Result=24140
exit/b
:Unicode24653
set Unicode_Result=恍
exit/b
:Unicode恍
set Unicode_Result=24653
exit/b
:Unicode35854
set Unicode_Result=谎
exit/b
:Unicode谎
set Unicode_Result=35854
exit/b
:Unicode28784
set Unicode_Result=灰
exit/b
:Unicode灰
set Unicode_Result=28784
exit/b
:Unicode25381
set Unicode_Result=挥
exit/b
:Unicode挥
set Unicode_Result=25381
exit/b
:Unicode36745
set Unicode_Result=辉
exit/b
:Unicode辉
set Unicode_Result=36745
exit/b
:Unicode24509
set Unicode_Result=徽
exit/b
:Unicode徽
set Unicode_Result=24509
exit/b
:Unicode24674
set Unicode_Result=恢
exit/b
:Unicode恢
set Unicode_Result=24674
exit/b
:Unicode34516
set Unicode_Result=蛔
exit/b
:Unicode蛔
set Unicode_Result=34516
exit/b
:Unicode22238
set Unicode_Result=回
exit/b
:Unicode回
set Unicode_Result=22238
exit/b
:Unicode27585
set Unicode_Result=毁
exit/b
:Unicode毁
set Unicode_Result=27585
exit/b
:Unicode24724
set Unicode_Result=悔
exit/b
:Unicode悔
set Unicode_Result=24724
exit/b
:Unicode24935
set Unicode_Result=慧
exit/b
:Unicode慧
set Unicode_Result=24935
exit/b
:Unicode21321
set Unicode_Result=卉
exit/b
:Unicode卉
set Unicode_Result=21321
exit/b
:Unicode24800
set Unicode_Result=惠
exit/b
:Unicode惠
set Unicode_Result=24800
exit/b
:Unicode26214
set Unicode_Result=晦
exit/b
:Unicode晦
set Unicode_Result=26214
exit/b
:Unicode36159
set Unicode_Result=贿
exit/b
:Unicode贿
set Unicode_Result=36159
exit/b
:Unicode31229
set Unicode_Result=秽
exit/b
:Unicode秽
set Unicode_Result=31229
exit/b
:Unicode20250
set Unicode_Result=会
exit/b
:Unicode会
set Unicode_Result=20250
exit/b
:Unicode28905
set Unicode_Result=烩
exit/b
:Unicode烩
set Unicode_Result=28905
exit/b
:Unicode27719
set Unicode_Result=汇
exit/b
:Unicode汇
set Unicode_Result=27719
exit/b
:Unicode35763
set Unicode_Result=讳
exit/b
:Unicode讳
set Unicode_Result=35763
exit/b
:Unicode35826
set Unicode_Result=诲
exit/b
:Unicode诲
set Unicode_Result=35826
exit/b
:Unicode32472
set Unicode_Result=绘
exit/b
:Unicode绘
set Unicode_Result=32472
exit/b
:Unicode33636
set Unicode_Result=荤
exit/b
:Unicode荤
set Unicode_Result=33636
exit/b
:Unicode26127
set Unicode_Result=昏
exit/b
:Unicode昏
set Unicode_Result=26127
exit/b
:Unicode23130
set Unicode_Result=婚
exit/b
:Unicode婚
set Unicode_Result=23130
exit/b
:Unicode39746
set Unicode_Result=魂
exit/b
:Unicode魂
set Unicode_Result=39746
exit/b
:Unicode27985
set Unicode_Result=浑
exit/b
:Unicode浑
set Unicode_Result=27985
exit/b
:Unicode28151
set Unicode_Result=混
exit/b
:Unicode混
set Unicode_Result=28151
exit/b
:Unicode35905
set Unicode_Result=豁
exit/b
:Unicode豁
set Unicode_Result=35905
exit/b
:Unicode27963
set Unicode_Result=活
exit/b
:Unicode活
set Unicode_Result=27963
exit/b
:Unicode20249
set Unicode_Result=伙
exit/b
:Unicode伙
set Unicode_Result=20249
exit/b
:Unicode28779
set Unicode_Result=火
exit/b
:Unicode火
set Unicode_Result=28779
exit/b
:Unicode33719
set Unicode_Result=获
exit/b
:Unicode获
set Unicode_Result=33719
exit/b
:Unicode25110
set Unicode_Result=或
exit/b
:Unicode或
set Unicode_Result=25110
exit/b
:Unicode24785
set Unicode_Result=惑
exit/b
:Unicode惑
set Unicode_Result=24785
exit/b
:Unicode38669
set Unicode_Result=霍
exit/b
:Unicode霍
set Unicode_Result=38669
exit/b
:Unicode36135
set Unicode_Result=货
exit/b
:Unicode货
set Unicode_Result=36135
exit/b
:Unicode31096
set Unicode_Result=祸
exit/b
:Unicode祸
set Unicode_Result=31096
exit/b
:Unicode20987
set Unicode_Result=击
exit/b
:Unicode击
set Unicode_Result=20987
exit/b
:Unicode22334
set Unicode_Result=圾
exit/b
:Unicode圾
set Unicode_Result=22334
exit/b
:Unicode22522
set Unicode_Result=基
exit/b
:Unicode基
set Unicode_Result=22522
exit/b
:Unicode26426
set Unicode_Result=机
exit/b
:Unicode机
set Unicode_Result=26426
exit/b
:Unicode30072
set Unicode_Result=畸
exit/b
:Unicode畸
set Unicode_Result=30072
exit/b
:Unicode31293
set Unicode_Result=稽
exit/b
:Unicode稽
set Unicode_Result=31293
exit/b
:Unicode31215
set Unicode_Result=积
exit/b
:Unicode积
set Unicode_Result=31215
exit/b
:Unicode31637
set Unicode_Result=箕
exit/b
:Unicode箕
set Unicode_Result=31637
exit/b
:Unicode32908
set Unicode_Result=肌
exit/b
:Unicode肌
set Unicode_Result=32908
exit/b
:Unicode39269
set Unicode_Result=饥
exit/b
:Unicode饥
set Unicode_Result=39269
exit/b
:Unicode36857
set Unicode_Result=迹
exit/b
:Unicode迹
set Unicode_Result=36857
exit/b
:Unicode28608
set Unicode_Result=激
exit/b
:Unicode激
set Unicode_Result=28608
exit/b
:Unicode35749
set Unicode_Result=讥
exit/b
:Unicode讥
set Unicode_Result=35749
exit/b
:Unicode40481
set Unicode_Result=鸡
exit/b
:Unicode鸡
set Unicode_Result=40481
exit/b
:Unicode23020
set Unicode_Result=姬
exit/b
:Unicode姬
set Unicode_Result=23020
exit/b
:Unicode32489
set Unicode_Result=绩
exit/b
:Unicode绩
set Unicode_Result=32489
exit/b
:Unicode32521
set Unicode_Result=缉
exit/b
:Unicode缉
set Unicode_Result=32521
exit/b
:Unicode21513
set Unicode_Result=吉
exit/b
:Unicode吉
set Unicode_Result=21513
exit/b
:Unicode26497
set Unicode_Result=极
exit/b
:Unicode极
set Unicode_Result=26497
exit/b
:Unicode26840
set Unicode_Result=棘
exit/b
:Unicode棘
set Unicode_Result=26840
exit/b
:Unicode36753
set Unicode_Result=辑
exit/b
:Unicode辑
set Unicode_Result=36753
exit/b
:Unicode31821
set Unicode_Result=籍
exit/b
:Unicode籍
set Unicode_Result=31821
exit/b
:Unicode38598
set Unicode_Result=集
exit/b
:Unicode集
set Unicode_Result=38598
exit/b
:Unicode21450
set Unicode_Result=及
exit/b
:Unicode及
set Unicode_Result=21450
exit/b
:Unicode24613
set Unicode_Result=急
exit/b
:Unicode急
set Unicode_Result=24613
exit/b
:Unicode30142
set Unicode_Result=疾
exit/b
:Unicode疾
set Unicode_Result=30142
exit/b
:Unicode27762
set Unicode_Result=汲
exit/b
:Unicode汲
set Unicode_Result=27762
exit/b
:Unicode21363
set Unicode_Result=即
exit/b
:Unicode即
set Unicode_Result=21363
exit/b
:Unicode23241
set Unicode_Result=嫉
exit/b
:Unicode嫉
set Unicode_Result=23241
exit/b
:Unicode32423
set Unicode_Result=级
exit/b
:Unicode级
set Unicode_Result=32423
exit/b
:Unicode25380
set Unicode_Result=挤
exit/b
:Unicode挤
set Unicode_Result=25380
exit/b
:Unicode20960
set Unicode_Result=几
exit/b
:Unicode几
set Unicode_Result=20960
exit/b
:Unicode33034
set Unicode_Result=脊
exit/b
:Unicode脊
set Unicode_Result=33034
exit/b
:Unicode24049
set Unicode_Result=己
exit/b
:Unicode己
set Unicode_Result=24049
exit/b
:Unicode34015
set Unicode_Result=蓟
exit/b
:Unicode蓟
set Unicode_Result=34015
exit/b
:Unicode25216
set Unicode_Result=技
exit/b
:Unicode技
set Unicode_Result=25216
exit/b
:Unicode20864
set Unicode_Result=冀
exit/b
:Unicode冀
set Unicode_Result=20864
exit/b
:Unicode23395
set Unicode_Result=季
exit/b
:Unicode季
set Unicode_Result=23395
exit/b
:Unicode20238
set Unicode_Result=伎
exit/b
:Unicode伎
set Unicode_Result=20238
exit/b
:Unicode31085
set Unicode_Result=祭
exit/b
:Unicode祭
set Unicode_Result=31085
exit/b
:Unicode21058
set Unicode_Result=剂
exit/b
:Unicode剂
set Unicode_Result=21058
exit/b
:Unicode24760
set Unicode_Result=悸
exit/b
:Unicode悸
set Unicode_Result=24760
exit/b
:Unicode27982
set Unicode_Result=济
exit/b
:Unicode济
set Unicode_Result=27982
exit/b
:Unicode23492
set Unicode_Result=寄
exit/b
:Unicode寄
set Unicode_Result=23492
exit/b
:Unicode23490
set Unicode_Result=寂
exit/b
:Unicode寂
set Unicode_Result=23490
exit/b
:Unicode35745
set Unicode_Result=计
exit/b
:Unicode计
set Unicode_Result=35745
exit/b
:Unicode35760
set Unicode_Result=记
exit/b
:Unicode记
set Unicode_Result=35760
exit/b
:Unicode26082
set Unicode_Result=既
exit/b
:Unicode既
set Unicode_Result=26082
exit/b
:Unicode24524
set Unicode_Result=忌
exit/b
:Unicode忌
set Unicode_Result=24524
exit/b
:Unicode38469
set Unicode_Result=际
exit/b
:Unicode际
set Unicode_Result=38469
exit/b
:Unicode22931
set Unicode_Result=妓
exit/b
:Unicode妓
set Unicode_Result=22931
exit/b
:Unicode32487
set Unicode_Result=继
exit/b
:Unicode继
set Unicode_Result=32487
exit/b
:Unicode32426
set Unicode_Result=纪
exit/b
:Unicode纪
set Unicode_Result=32426
exit/b
:Unicode22025
set Unicode_Result=嘉
exit/b
:Unicode嘉
set Unicode_Result=22025
exit/b
:Unicode26551
set Unicode_Result=枷
exit/b
:Unicode枷
set Unicode_Result=26551
exit/b
:Unicode22841
set Unicode_Result=夹
exit/b
:Unicode夹
set Unicode_Result=22841
exit/b
:Unicode20339
set Unicode_Result=佳
exit/b
:Unicode佳
set Unicode_Result=20339
exit/b
:Unicode23478
set Unicode_Result=家
exit/b
:Unicode家
set Unicode_Result=23478
exit/b
:Unicode21152
set Unicode_Result=加
exit/b
:Unicode加
set Unicode_Result=21152
exit/b
:Unicode33626
set Unicode_Result=荚
exit/b
:Unicode荚
set Unicode_Result=33626
exit/b
:Unicode39050
set Unicode_Result=颊
exit/b
:Unicode颊
set Unicode_Result=39050
exit/b
:Unicode36158
set Unicode_Result=贾
exit/b
:Unicode贾
set Unicode_Result=36158
exit/b
:Unicode30002
set Unicode_Result=甲
exit/b
:Unicode甲
set Unicode_Result=30002
exit/b
:Unicode38078
set Unicode_Result=钾
exit/b
:Unicode钾
set Unicode_Result=38078
exit/b
:Unicode20551
set Unicode_Result=假
exit/b
:Unicode假
set Unicode_Result=20551
exit/b
:Unicode31292
set Unicode_Result=稼
exit/b
:Unicode稼
set Unicode_Result=31292
exit/b
:Unicode20215
set Unicode_Result=价
exit/b
:Unicode价
set Unicode_Result=20215
exit/b
:Unicode26550
set Unicode_Result=架
exit/b
:Unicode架
set Unicode_Result=26550
exit/b
:Unicode39550
set Unicode_Result=驾
exit/b
:Unicode驾
set Unicode_Result=39550
exit/b
:Unicode23233
set Unicode_Result=嫁
exit/b
:Unicode嫁
set Unicode_Result=23233
exit/b
:Unicode27516
set Unicode_Result=歼
exit/b
:Unicode歼
set Unicode_Result=27516
exit/b
:Unicode30417
set Unicode_Result=监
exit/b
:Unicode监
set Unicode_Result=30417
exit/b
:Unicode22362
set Unicode_Result=坚
exit/b
:Unicode坚
set Unicode_Result=22362
exit/b
:Unicode23574
set Unicode_Result=尖
exit/b
:Unicode尖
set Unicode_Result=23574
exit/b
:Unicode31546
set Unicode_Result=笺
exit/b
:Unicode笺
set Unicode_Result=31546
exit/b
:Unicode38388
set Unicode_Result=间
exit/b
:Unicode间
set Unicode_Result=38388
exit/b
:Unicode29006
set Unicode_Result=煎
exit/b
:Unicode煎
set Unicode_Result=29006
exit/b
:Unicode20860
set Unicode_Result=兼
exit/b
:Unicode兼
set Unicode_Result=20860
exit/b
:Unicode32937
set Unicode_Result=肩
exit/b
:Unicode肩
set Unicode_Result=32937
exit/b
:Unicode33392
set Unicode_Result=艰
exit/b
:Unicode艰
set Unicode_Result=33392
exit/b
:Unicode22904
set Unicode_Result=奸
exit/b
:Unicode奸
set Unicode_Result=22904
exit/b
:Unicode32516
set Unicode_Result=缄
exit/b
:Unicode缄
set Unicode_Result=32516
exit/b
:Unicode33575
set Unicode_Result=茧
exit/b
:Unicode茧
set Unicode_Result=33575
exit/b
:Unicode26816
set Unicode_Result=检
exit/b
:Unicode检
set Unicode_Result=26816
exit/b
:Unicode26604
set Unicode_Result=柬
exit/b
:Unicode柬
set Unicode_Result=26604
exit/b
:Unicode30897
set Unicode_Result=碱
exit/b
:Unicode碱
set Unicode_Result=30897
exit/b
:Unicode30839
set Unicode_Result=硷
exit/b
:Unicode硷
set Unicode_Result=30839
exit/b
:Unicode25315
set Unicode_Result=拣
exit/b
:Unicode拣
set Unicode_Result=25315
exit/b
:Unicode25441
set Unicode_Result=捡
exit/b
:Unicode捡
set Unicode_Result=25441
exit/b
:Unicode31616
set Unicode_Result=简
exit/b
:Unicode简
set Unicode_Result=31616
exit/b
:Unicode20461
set Unicode_Result=俭
exit/b
:Unicode俭
set Unicode_Result=20461
exit/b
:Unicode21098
set Unicode_Result=剪
exit/b
:Unicode剪
set Unicode_Result=21098
exit/b
:Unicode20943
set Unicode_Result=减
exit/b
:Unicode减
set Unicode_Result=20943
exit/b
:Unicode33616
set Unicode_Result=荐
exit/b
:Unicode荐
set Unicode_Result=33616
exit/b
:Unicode27099
set Unicode_Result=槛
exit/b
:Unicode槛
set Unicode_Result=27099
exit/b
:Unicode37492
set Unicode_Result=鉴
exit/b
:Unicode鉴
set Unicode_Result=37492
exit/b
:Unicode36341
set Unicode_Result=践
exit/b
:Unicode践
set Unicode_Result=36341
exit/b
:Unicode36145
set Unicode_Result=贱
exit/b
:Unicode贱
set Unicode_Result=36145
exit/b
:Unicode35265
set Unicode_Result=见
exit/b
:Unicode见
set Unicode_Result=35265
exit/b
:Unicode38190
set Unicode_Result=键
exit/b
:Unicode键
set Unicode_Result=38190
exit/b
:Unicode31661
set Unicode_Result=箭
exit/b
:Unicode箭
set Unicode_Result=31661
exit/b
:Unicode20214
set Unicode_Result=件
exit/b
:Unicode件
set Unicode_Result=20214
exit/b
:Unicode20581
set Unicode_Result=健
exit/b
:Unicode健
set Unicode_Result=20581
exit/b
:Unicode33328
set Unicode_Result=舰
exit/b
:Unicode舰
set Unicode_Result=33328
exit/b
:Unicode21073
set Unicode_Result=剑
exit/b
:Unicode剑
set Unicode_Result=21073
exit/b
:Unicode39279
set Unicode_Result=饯
exit/b
:Unicode饯
set Unicode_Result=39279
exit/b
:Unicode28176
set Unicode_Result=渐
exit/b
:Unicode渐
set Unicode_Result=28176
exit/b
:Unicode28293
set Unicode_Result=溅
exit/b
:Unicode溅
set Unicode_Result=28293
exit/b
:Unicode28071
set Unicode_Result=涧
exit/b
:Unicode涧
set Unicode_Result=28071
exit/b
:Unicode24314
set Unicode_Result=建
exit/b
:Unicode建
set Unicode_Result=24314
exit/b
:Unicode20725
set Unicode_Result=僵
exit/b
:Unicode僵
set Unicode_Result=20725
exit/b
:Unicode23004
set Unicode_Result=姜
exit/b
:Unicode姜
set Unicode_Result=23004
exit/b
:Unicode23558
set Unicode_Result=将
exit/b
:Unicode将
set Unicode_Result=23558
exit/b
:Unicode27974
set Unicode_Result=浆
exit/b
:Unicode浆
set Unicode_Result=27974
exit/b
:Unicode27743
set Unicode_Result=江
exit/b
:Unicode江
set Unicode_Result=27743
exit/b
:Unicode30086
set Unicode_Result=疆
exit/b
:Unicode疆
set Unicode_Result=30086
exit/b
:Unicode33931
set Unicode_Result=蒋
exit/b
:Unicode蒋
set Unicode_Result=33931
exit/b
:Unicode26728
set Unicode_Result=桨
exit/b
:Unicode桨
set Unicode_Result=26728
exit/b
:Unicode22870
set Unicode_Result=奖
exit/b
:Unicode奖
set Unicode_Result=22870
exit/b
:Unicode35762
set Unicode_Result=讲
exit/b
:Unicode讲
set Unicode_Result=35762
exit/b
:Unicode21280
set Unicode_Result=匠
exit/b
:Unicode匠
set Unicode_Result=21280
exit/b
:Unicode37233
set Unicode_Result=酱
exit/b
:Unicode酱
set Unicode_Result=37233
exit/b
:Unicode38477
set Unicode_Result=降
exit/b
:Unicode降
set Unicode_Result=38477
exit/b
:Unicode34121
set Unicode_Result=蕉
exit/b
:Unicode蕉
set Unicode_Result=34121
exit/b
:Unicode26898
set Unicode_Result=椒
exit/b
:Unicode椒
set Unicode_Result=26898
exit/b
:Unicode30977
set Unicode_Result=礁
exit/b
:Unicode礁
set Unicode_Result=30977
exit/b
:Unicode28966
set Unicode_Result=焦
exit/b
:Unicode焦
set Unicode_Result=28966
exit/b
:Unicode33014
set Unicode_Result=胶
exit/b
:Unicode胶
set Unicode_Result=33014
exit/b
:Unicode20132
set Unicode_Result=交
exit/b
:Unicode交
set Unicode_Result=20132
exit/b
:Unicode37066
set Unicode_Result=郊
exit/b
:Unicode郊
set Unicode_Result=37066
exit/b
:Unicode27975
set Unicode_Result=浇
exit/b
:Unicode浇
set Unicode_Result=27975
exit/b
:Unicode39556
set Unicode_Result=骄
exit/b
:Unicode骄
set Unicode_Result=39556
exit/b
:Unicode23047
set Unicode_Result=娇
exit/b
:Unicode娇
set Unicode_Result=23047
exit/b
:Unicode22204
set Unicode_Result=嚼
exit/b
:Unicode嚼
set Unicode_Result=22204
exit/b
:Unicode25605
set Unicode_Result=搅
exit/b
:Unicode搅
set Unicode_Result=25605
exit/b
:Unicode38128
set Unicode_Result=铰
exit/b
:Unicode铰
set Unicode_Result=38128
exit/b
:Unicode30699
set Unicode_Result=矫
exit/b
:Unicode矫
set Unicode_Result=30699
exit/b
:Unicode20389
set Unicode_Result=侥
exit/b
:Unicode侥
set Unicode_Result=20389
exit/b
:Unicode33050
set Unicode_Result=脚
exit/b
:Unicode脚
set Unicode_Result=33050
exit/b
:Unicode29409
set Unicode_Result=狡
exit/b
:Unicode狡
set Unicode_Result=29409
exit/b
:Unicode35282
set Unicode_Result=角
exit/b
:Unicode角
set Unicode_Result=35282
exit/b
:Unicode39290
set Unicode_Result=饺
exit/b
:Unicode饺
set Unicode_Result=39290
exit/b
:Unicode32564
set Unicode_Result=缴
exit/b
:Unicode缴
set Unicode_Result=32564
exit/b
:Unicode32478
set Unicode_Result=绞
exit/b
:Unicode绞
set Unicode_Result=32478
exit/b
:Unicode21119
set Unicode_Result=剿
exit/b
:Unicode剿
set Unicode_Result=21119
exit/b
:Unicode25945
set Unicode_Result=教
exit/b
:Unicode教
set Unicode_Result=25945
exit/b
:Unicode37237
set Unicode_Result=酵
exit/b
:Unicode酵
set Unicode_Result=37237
exit/b
:Unicode36735
set Unicode_Result=轿
exit/b
:Unicode轿
set Unicode_Result=36735
exit/b
:Unicode36739
set Unicode_Result=较
exit/b
:Unicode较
set Unicode_Result=36739
exit/b
:Unicode21483
set Unicode_Result=叫
exit/b
:Unicode叫
set Unicode_Result=21483
exit/b
:Unicode31382
set Unicode_Result=窖
exit/b
:Unicode窖
set Unicode_Result=31382
exit/b
:Unicode25581
set Unicode_Result=揭
exit/b
:Unicode揭
set Unicode_Result=25581
exit/b
:Unicode25509
set Unicode_Result=接
exit/b
:Unicode接
set Unicode_Result=25509
exit/b
:Unicode30342
set Unicode_Result=皆
exit/b
:Unicode皆
set Unicode_Result=30342
exit/b
:Unicode31224
set Unicode_Result=秸
exit/b
:Unicode秸
set Unicode_Result=31224
exit/b
:Unicode34903
set Unicode_Result=街
exit/b
:Unicode街
set Unicode_Result=34903
exit/b
:Unicode38454
set Unicode_Result=阶
exit/b
:Unicode阶
set Unicode_Result=38454
exit/b
:Unicode25130
set Unicode_Result=截
exit/b
:Unicode截
set Unicode_Result=25130
exit/b
:Unicode21163
set Unicode_Result=劫
exit/b
:Unicode劫
set Unicode_Result=21163
exit/b
:Unicode33410
set Unicode_Result=节
exit/b
:Unicode节
set Unicode_Result=33410
exit/b
:Unicode26708
set Unicode_Result=桔
exit/b
:Unicode桔
set Unicode_Result=26708
exit/b
:Unicode26480
set Unicode_Result=杰
exit/b
:Unicode杰
set Unicode_Result=26480
exit/b
:Unicode25463
set Unicode_Result=捷
exit/b
:Unicode捷
set Unicode_Result=25463
exit/b
:Unicode30571
set Unicode_Result=睫
exit/b
:Unicode睫
set Unicode_Result=30571
exit/b
:Unicode31469
set Unicode_Result=竭
exit/b
:Unicode竭
set Unicode_Result=31469
exit/b
:Unicode27905
set Unicode_Result=洁
exit/b
:Unicode洁
set Unicode_Result=27905
exit/b
:Unicode32467
set Unicode_Result=结
exit/b
:Unicode结
set Unicode_Result=32467
exit/b
:Unicode35299
set Unicode_Result=解
exit/b
:Unicode解
set Unicode_Result=35299
exit/b
:Unicode22992
set Unicode_Result=姐
exit/b
:Unicode姐
set Unicode_Result=22992
exit/b
:Unicode25106
set Unicode_Result=戒
exit/b
:Unicode戒
set Unicode_Result=25106
exit/b
:Unicode34249
set Unicode_Result=藉
exit/b
:Unicode藉
set Unicode_Result=34249
exit/b
:Unicode33445
set Unicode_Result=芥
exit/b
:Unicode芥
set Unicode_Result=33445
exit/b
:Unicode30028
set Unicode_Result=界
exit/b
:Unicode界
set Unicode_Result=30028
exit/b
:Unicode20511
set Unicode_Result=借
exit/b
:Unicode借
set Unicode_Result=20511
exit/b
:Unicode20171
set Unicode_Result=介
exit/b
:Unicode介
set Unicode_Result=20171
exit/b
:Unicode30117
set Unicode_Result=疥
exit/b
:Unicode疥
set Unicode_Result=30117
exit/b
:Unicode35819
set Unicode_Result=诫
exit/b
:Unicode诫
set Unicode_Result=35819
exit/b
:Unicode23626
set Unicode_Result=届
exit/b
:Unicode届
set Unicode_Result=23626
exit/b
:Unicode24062
set Unicode_Result=巾
exit/b
:Unicode巾
set Unicode_Result=24062
exit/b
:Unicode31563
set Unicode_Result=筋
exit/b
:Unicode筋
set Unicode_Result=31563
exit/b
:Unicode26020
set Unicode_Result=斤
exit/b
:Unicode斤
set Unicode_Result=26020
exit/b
:Unicode37329
set Unicode_Result=金
exit/b
:Unicode金
set Unicode_Result=37329
exit/b
:Unicode20170
set Unicode_Result=今
exit/b
:Unicode今
set Unicode_Result=20170
exit/b
:Unicode27941
set Unicode_Result=津
exit/b
:Unicode津
set Unicode_Result=27941
exit/b
:Unicode35167
set Unicode_Result=襟
exit/b
:Unicode襟
set Unicode_Result=35167
exit/b
:Unicode32039
set Unicode_Result=紧
exit/b
:Unicode紧
set Unicode_Result=32039
exit/b
:Unicode38182
set Unicode_Result=锦
exit/b
:Unicode锦
set Unicode_Result=38182
exit/b
:Unicode20165
set Unicode_Result=仅
exit/b
:Unicode仅
set Unicode_Result=20165
exit/b
:Unicode35880
set Unicode_Result=谨
exit/b
:Unicode谨
set Unicode_Result=35880
exit/b
:Unicode36827
set Unicode_Result=进
exit/b
:Unicode进
set Unicode_Result=36827
exit/b
:Unicode38771
set Unicode_Result=靳
exit/b
:Unicode靳
set Unicode_Result=38771
exit/b
:Unicode26187
set Unicode_Result=晋
exit/b
:Unicode晋
set Unicode_Result=26187
exit/b
:Unicode31105
set Unicode_Result=禁
exit/b
:Unicode禁
set Unicode_Result=31105
exit/b
:Unicode36817
set Unicode_Result=近
exit/b
:Unicode近
set Unicode_Result=36817
exit/b
:Unicode28908
set Unicode_Result=烬
exit/b
:Unicode烬
set Unicode_Result=28908
exit/b
:Unicode28024
set Unicode_Result=浸
exit/b
:Unicode浸
set Unicode_Result=28024
exit/b
:Unicode23613
set Unicode_Result=尽
exit/b
:Unicode尽
set Unicode_Result=23613
exit/b
:Unicode21170
set Unicode_Result=劲
exit/b
:Unicode劲
set Unicode_Result=21170
exit/b
:Unicode33606
set Unicode_Result=荆
exit/b
:Unicode荆
set Unicode_Result=33606
exit/b
:Unicode20834
set Unicode_Result=兢
exit/b
:Unicode兢
set Unicode_Result=20834
exit/b
:Unicode33550
set Unicode_Result=茎
exit/b
:Unicode茎
set Unicode_Result=33550
exit/b
:Unicode30555
set Unicode_Result=睛
exit/b
:Unicode睛
set Unicode_Result=30555
exit/b
:Unicode26230
set Unicode_Result=晶
exit/b
:Unicode晶
set Unicode_Result=26230
exit/b
:Unicode40120
set Unicode_Result=鲸
exit/b
:Unicode鲸
set Unicode_Result=40120
exit/b
:Unicode20140
set Unicode_Result=京
exit/b
:Unicode京
set Unicode_Result=20140
exit/b
:Unicode24778
set Unicode_Result=惊
exit/b
:Unicode惊
set Unicode_Result=24778
exit/b
:Unicode31934
set Unicode_Result=精
exit/b
:Unicode精
set Unicode_Result=31934
exit/b
:Unicode31923
set Unicode_Result=粳
exit/b
:Unicode粳
set Unicode_Result=31923
exit/b
:Unicode32463
set Unicode_Result=经
exit/b
:Unicode经
set Unicode_Result=32463
exit/b
:Unicode20117
set Unicode_Result=井
exit/b
:Unicode井
set Unicode_Result=20117
exit/b
:Unicode35686
set Unicode_Result=警
exit/b
:Unicode警
set Unicode_Result=35686
exit/b
:Unicode26223
set Unicode_Result=景
exit/b
:Unicode景
set Unicode_Result=26223
exit/b
:Unicode39048
set Unicode_Result=颈
exit/b
:Unicode颈
set Unicode_Result=39048
exit/b
:Unicode38745
set Unicode_Result=静
exit/b
:Unicode静
set Unicode_Result=38745
exit/b
:Unicode22659
set Unicode_Result=境
exit/b
:Unicode境
set Unicode_Result=22659
exit/b
:Unicode25964
set Unicode_Result=敬
exit/b
:Unicode敬
set Unicode_Result=25964
exit/b
:Unicode38236
set Unicode_Result=镜
exit/b
:Unicode镜
set Unicode_Result=38236
exit/b
:Unicode24452
set Unicode_Result=径
exit/b
:Unicode径
set Unicode_Result=24452
exit/b
:Unicode30153
set Unicode_Result=痉
exit/b
:Unicode痉
set Unicode_Result=30153
exit/b
:Unicode38742
set Unicode_Result=靖
exit/b
:Unicode靖
set Unicode_Result=38742
exit/b
:Unicode31455
set Unicode_Result=竟
exit/b
:Unicode竟
set Unicode_Result=31455
exit/b
:Unicode31454
set Unicode_Result=竞
exit/b
:Unicode竞
set Unicode_Result=31454
exit/b
:Unicode20928
set Unicode_Result=净
exit/b
:Unicode净
set Unicode_Result=20928
exit/b
:Unicode28847
set Unicode_Result=炯
exit/b
:Unicode炯
set Unicode_Result=28847
exit/b
:Unicode31384
set Unicode_Result=窘
exit/b
:Unicode窘
set Unicode_Result=31384
exit/b
:Unicode25578
set Unicode_Result=揪
exit/b
:Unicode揪
set Unicode_Result=25578
exit/b
:Unicode31350
set Unicode_Result=究
exit/b
:Unicode究
set Unicode_Result=31350
exit/b
:Unicode32416
set Unicode_Result=纠
exit/b
:Unicode纠
set Unicode_Result=32416
exit/b
:Unicode29590
set Unicode_Result=玖
exit/b
:Unicode玖
set Unicode_Result=29590
exit/b
:Unicode38893
set Unicode_Result=韭
exit/b
:Unicode韭
set Unicode_Result=38893
exit/b
:Unicode20037
set Unicode_Result=久
exit/b
:Unicode久
set Unicode_Result=20037
exit/b
:Unicode28792
set Unicode_Result=灸
exit/b
:Unicode灸
set Unicode_Result=28792
exit/b
:Unicode20061
set Unicode_Result=九
exit/b
:Unicode九
set Unicode_Result=20061
exit/b
:Unicode37202
set Unicode_Result=酒
exit/b
:Unicode酒
set Unicode_Result=37202
exit/b
:Unicode21417
set Unicode_Result=厩
exit/b
:Unicode厩
set Unicode_Result=21417
exit/b
:Unicode25937
set Unicode_Result=救
exit/b
:Unicode救
set Unicode_Result=25937
exit/b
:Unicode26087
set Unicode_Result=旧
exit/b
:Unicode旧
set Unicode_Result=26087
exit/b
:Unicode33276
set Unicode_Result=臼
exit/b
:Unicode臼
set Unicode_Result=33276
exit/b
:Unicode33285
set Unicode_Result=舅
exit/b
:Unicode舅
set Unicode_Result=33285
exit/b
:Unicode21646
set Unicode_Result=咎
exit/b
:Unicode咎
set Unicode_Result=21646
exit/b
:Unicode23601
set Unicode_Result=就
exit/b
:Unicode就
set Unicode_Result=23601
exit/b
:Unicode30106
set Unicode_Result=疚
exit/b
:Unicode疚
set Unicode_Result=30106
exit/b
:Unicode38816
set Unicode_Result=鞠
exit/b
:Unicode鞠
set Unicode_Result=38816
exit/b
:Unicode25304
set Unicode_Result=拘
exit/b
:Unicode拘
set Unicode_Result=25304
exit/b
:Unicode29401
set Unicode_Result=狙
exit/b
:Unicode狙
set Unicode_Result=29401
exit/b
:Unicode30141
set Unicode_Result=疽
exit/b
:Unicode疽
set Unicode_Result=30141
exit/b
:Unicode23621
set Unicode_Result=居
exit/b
:Unicode居
set Unicode_Result=23621
exit/b
:Unicode39545
set Unicode_Result=驹
exit/b
:Unicode驹
set Unicode_Result=39545
exit/b
:Unicode33738
set Unicode_Result=菊
exit/b
:Unicode菊
set Unicode_Result=33738
exit/b
:Unicode23616
set Unicode_Result=局
exit/b
:Unicode局
set Unicode_Result=23616
exit/b
:Unicode21632
set Unicode_Result=咀
exit/b
:Unicode咀
set Unicode_Result=21632
exit/b
:Unicode30697
set Unicode_Result=矩
exit/b
:Unicode矩
set Unicode_Result=30697
exit/b
:Unicode20030
set Unicode_Result=举
exit/b
:Unicode举
set Unicode_Result=20030
exit/b
:Unicode27822
set Unicode_Result=沮
exit/b
:Unicode沮
set Unicode_Result=27822
exit/b
:Unicode32858
set Unicode_Result=聚
exit/b
:Unicode聚
set Unicode_Result=32858
exit/b
:Unicode25298
set Unicode_Result=拒
exit/b
:Unicode拒
set Unicode_Result=25298
exit/b
:Unicode25454
set Unicode_Result=据
exit/b
:Unicode据
set Unicode_Result=25454
exit/b
:Unicode24040
set Unicode_Result=巨
exit/b
:Unicode巨
set Unicode_Result=24040
exit/b
:Unicode20855
set Unicode_Result=具
exit/b
:Unicode具
set Unicode_Result=20855
exit/b
:Unicode36317
set Unicode_Result=距
exit/b
:Unicode距
set Unicode_Result=36317
exit/b
:Unicode36382
set Unicode_Result=踞
exit/b
:Unicode踞
set Unicode_Result=36382
exit/b
:Unicode38191
set Unicode_Result=锯
exit/b
:Unicode锯
set Unicode_Result=38191
exit/b
:Unicode20465
set Unicode_Result=俱
exit/b
:Unicode俱
set Unicode_Result=20465
exit/b
:Unicode21477
set Unicode_Result=句
exit/b
:Unicode句
set Unicode_Result=21477
exit/b
:Unicode24807
set Unicode_Result=惧
exit/b
:Unicode惧
set Unicode_Result=24807
exit/b
:Unicode28844
set Unicode_Result=炬
exit/b
:Unicode炬
set Unicode_Result=28844
exit/b
:Unicode21095
set Unicode_Result=剧
exit/b
:Unicode剧
set Unicode_Result=21095
exit/b
:Unicode25424
set Unicode_Result=捐
exit/b
:Unicode捐
set Unicode_Result=25424
exit/b
:Unicode40515
set Unicode_Result=鹃
exit/b
:Unicode鹃
set Unicode_Result=40515
exit/b
:Unicode23071
set Unicode_Result=娟
exit/b
:Unicode娟
set Unicode_Result=23071
exit/b
:Unicode20518
set Unicode_Result=倦
exit/b
:Unicode倦
set Unicode_Result=20518
exit/b
:Unicode30519
set Unicode_Result=眷
exit/b
:Unicode眷
set Unicode_Result=30519
exit/b
:Unicode21367
set Unicode_Result=卷
exit/b
:Unicode卷
set Unicode_Result=21367
exit/b
:Unicode32482
set Unicode_Result=绢
exit/b
:Unicode绢
set Unicode_Result=32482
exit/b
:Unicode25733
set Unicode_Result=撅
exit/b
:Unicode撅
set Unicode_Result=25733
exit/b
:Unicode25899
set Unicode_Result=攫
exit/b
:Unicode攫
set Unicode_Result=25899
exit/b
:Unicode25225
set Unicode_Result=抉
exit/b
:Unicode抉
set Unicode_Result=25225
exit/b
:Unicode25496
set Unicode_Result=掘
exit/b
:Unicode掘
set Unicode_Result=25496
exit/b
:Unicode20500
set Unicode_Result=倔
exit/b
:Unicode倔
set Unicode_Result=20500
exit/b
:Unicode29237
set Unicode_Result=爵
exit/b
:Unicode爵
set Unicode_Result=29237
exit/b
:Unicode35273
set Unicode_Result=觉
exit/b
:Unicode觉
set Unicode_Result=35273
exit/b
:Unicode20915
set Unicode_Result=决
exit/b
:Unicode决
set Unicode_Result=20915
exit/b
:Unicode35776
set Unicode_Result=诀
exit/b
:Unicode诀
set Unicode_Result=35776
exit/b
:Unicode32477
set Unicode_Result=绝
exit/b
:Unicode绝
set Unicode_Result=32477
exit/b
:Unicode22343
set Unicode_Result=均
exit/b
:Unicode均
set Unicode_Result=22343
exit/b
:Unicode33740
set Unicode_Result=菌
exit/b
:Unicode菌
set Unicode_Result=33740
exit/b
:Unicode38055
set Unicode_Result=钧
exit/b
:Unicode钧
set Unicode_Result=38055
exit/b
:Unicode20891
set Unicode_Result=军
exit/b
:Unicode军
set Unicode_Result=20891
exit/b
:Unicode21531
set Unicode_Result=君
exit/b
:Unicode君
set Unicode_Result=21531
exit/b
:Unicode23803
set Unicode_Result=峻
exit/b
:Unicode峻
set Unicode_Result=23803
exit/b
:Unicode20426
set Unicode_Result=俊
exit/b
:Unicode俊
set Unicode_Result=20426
exit/b
:Unicode31459
set Unicode_Result=竣
exit/b
:Unicode竣
set Unicode_Result=31459
exit/b
:Unicode27994
set Unicode_Result=浚
exit/b
:Unicode浚
set Unicode_Result=27994
exit/b
:Unicode37089
set Unicode_Result=郡
exit/b
:Unicode郡
set Unicode_Result=37089
exit/b
:Unicode39567
set Unicode_Result=骏
exit/b
:Unicode骏
set Unicode_Result=39567
exit/b
:Unicode21888
set Unicode_Result=喀
exit/b
:Unicode喀
set Unicode_Result=21888
exit/b
:Unicode21654
set Unicode_Result=咖
exit/b
:Unicode咖
set Unicode_Result=21654
exit/b
:Unicode21345
set Unicode_Result=卡
exit/b
:Unicode卡
set Unicode_Result=21345
exit/b
:Unicode21679
set Unicode_Result=咯
exit/b
:Unicode咯
set Unicode_Result=21679
exit/b
:Unicode24320
set Unicode_Result=开
exit/b
:Unicode开
set Unicode_Result=24320
exit/b
:Unicode25577
set Unicode_Result=揩
exit/b
:Unicode揩
set Unicode_Result=25577
exit/b
:Unicode26999
set Unicode_Result=楷
exit/b
:Unicode楷
set Unicode_Result=26999
exit/b
:Unicode20975
set Unicode_Result=凯
exit/b
:Unicode凯
set Unicode_Result=20975
exit/b
:Unicode24936
set Unicode_Result=慨
exit/b
:Unicode慨
set Unicode_Result=24936
exit/b
:Unicode21002
set Unicode_Result=刊
exit/b
:Unicode刊
set Unicode_Result=21002
exit/b
:Unicode22570
set Unicode_Result=堪
exit/b
:Unicode堪
set Unicode_Result=22570
exit/b
:Unicode21208
set Unicode_Result=勘
exit/b
:Unicode勘
set Unicode_Result=21208
exit/b
:Unicode22350
set Unicode_Result=坎
exit/b
:Unicode坎
set Unicode_Result=22350
exit/b
:Unicode30733
set Unicode_Result=砍
exit/b
:Unicode砍
set Unicode_Result=30733
exit/b
:Unicode30475
set Unicode_Result=看
exit/b
:Unicode看
set Unicode_Result=30475
exit/b
:Unicode24247
set Unicode_Result=康
exit/b
:Unicode康
set Unicode_Result=24247
exit/b
:Unicode24951
set Unicode_Result=慷
exit/b
:Unicode慷
set Unicode_Result=24951
exit/b
:Unicode31968
set Unicode_Result=糠
exit/b
:Unicode糠
set Unicode_Result=31968
exit/b
:Unicode25179
set Unicode_Result=扛
exit/b
:Unicode扛
set Unicode_Result=25179
exit/b
:Unicode25239
set Unicode_Result=抗
exit/b
:Unicode抗
set Unicode_Result=25239
exit/b
:Unicode20130
set Unicode_Result=亢
exit/b
:Unicode亢
set Unicode_Result=20130
exit/b
:Unicode28821
set Unicode_Result=炕
exit/b
:Unicode炕
set Unicode_Result=28821
exit/b
:Unicode32771
set Unicode_Result=考
exit/b
:Unicode考
set Unicode_Result=32771
exit/b
:Unicode25335
set Unicode_Result=拷
exit/b
:Unicode拷
set Unicode_Result=25335
exit/b
:Unicode28900
set Unicode_Result=烤
exit/b
:Unicode烤
set Unicode_Result=28900
exit/b
:Unicode38752
set Unicode_Result=靠
exit/b
:Unicode靠
set Unicode_Result=38752
exit/b
:Unicode22391
set Unicode_Result=坷
exit/b
:Unicode坷
set Unicode_Result=22391
exit/b
:Unicode33499
set Unicode_Result=苛
exit/b
:Unicode苛
set Unicode_Result=33499
exit/b
:Unicode26607
set Unicode_Result=柯
exit/b
:Unicode柯
set Unicode_Result=26607
exit/b
:Unicode26869
set Unicode_Result=棵
exit/b
:Unicode棵
set Unicode_Result=26869
exit/b
:Unicode30933
set Unicode_Result=磕
exit/b
:Unicode磕
set Unicode_Result=30933
exit/b
:Unicode39063
set Unicode_Result=颗
exit/b
:Unicode颗
set Unicode_Result=39063
exit/b
:Unicode31185
set Unicode_Result=科
exit/b
:Unicode科
set Unicode_Result=31185
exit/b
:Unicode22771
set Unicode_Result=壳
exit/b
:Unicode壳
set Unicode_Result=22771
exit/b
:Unicode21683
set Unicode_Result=咳
exit/b
:Unicode咳
set Unicode_Result=21683
exit/b
:Unicode21487
set Unicode_Result=可
exit/b
:Unicode可
set Unicode_Result=21487
exit/b
:Unicode28212
set Unicode_Result=渴
exit/b
:Unicode渴
set Unicode_Result=28212
exit/b
:Unicode20811
set Unicode_Result=克
exit/b
:Unicode克
set Unicode_Result=20811
exit/b
:Unicode21051
set Unicode_Result=刻
exit/b
:Unicode刻
set Unicode_Result=21051
exit/b
:Unicode23458
set Unicode_Result=客
exit/b
:Unicode客
set Unicode_Result=23458
exit/b
:Unicode35838
set Unicode_Result=课
exit/b
:Unicode课
set Unicode_Result=35838
exit/b
:Unicode32943
set Unicode_Result=肯
exit/b
:Unicode肯
set Unicode_Result=32943
exit/b
:Unicode21827
set Unicode_Result=啃
exit/b
:Unicode啃
set Unicode_Result=21827
exit/b
:Unicode22438
set Unicode_Result=垦
exit/b
:Unicode垦
set Unicode_Result=22438
exit/b
:Unicode24691
set Unicode_Result=恳
exit/b
:Unicode恳
set Unicode_Result=24691
exit/b
:Unicode22353
set Unicode_Result=坑
exit/b
:Unicode坑
set Unicode_Result=22353
exit/b
:Unicode21549
set Unicode_Result=吭
exit/b
:Unicode吭
set Unicode_Result=21549
exit/b
:Unicode31354
set Unicode_Result=空
exit/b
:Unicode空
set Unicode_Result=31354
exit/b
:Unicode24656
set Unicode_Result=恐
exit/b
:Unicode恐
set Unicode_Result=24656
exit/b
:Unicode23380
set Unicode_Result=孔
exit/b
:Unicode孔
set Unicode_Result=23380
exit/b
:Unicode25511
set Unicode_Result=控
exit/b
:Unicode控
set Unicode_Result=25511
exit/b
:Unicode25248
set Unicode_Result=抠
exit/b
:Unicode抠
set Unicode_Result=25248
exit/b
:Unicode21475
set Unicode_Result=口
exit/b
:Unicode口
set Unicode_Result=21475
exit/b
:Unicode25187
set Unicode_Result=扣
exit/b
:Unicode扣
set Unicode_Result=25187
exit/b
:Unicode23495
set Unicode_Result=寇
exit/b
:Unicode寇
set Unicode_Result=23495
exit/b
:Unicode26543
set Unicode_Result=枯
exit/b
:Unicode枯
set Unicode_Result=26543
exit/b
:Unicode21741
set Unicode_Result=哭
exit/b
:Unicode哭
set Unicode_Result=21741
exit/b
:Unicode31391
set Unicode_Result=窟
exit/b
:Unicode窟
set Unicode_Result=31391
exit/b
:Unicode33510
set Unicode_Result=苦
exit/b
:Unicode苦
set Unicode_Result=33510
exit/b
:Unicode37239
set Unicode_Result=酷
exit/b
:Unicode酷
set Unicode_Result=37239
exit/b
:Unicode24211
set Unicode_Result=库
exit/b
:Unicode库
set Unicode_Result=24211
exit/b
:Unicode35044
set Unicode_Result=裤
exit/b
:Unicode裤
set Unicode_Result=35044
exit/b
:Unicode22840
set Unicode_Result=夸
exit/b
:Unicode夸
set Unicode_Result=22840
exit/b
:Unicode22446
set Unicode_Result=垮
exit/b
:Unicode垮
set Unicode_Result=22446
exit/b
:Unicode25358
set Unicode_Result=挎
exit/b
:Unicode挎
set Unicode_Result=25358
exit/b
:Unicode36328
set Unicode_Result=跨
exit/b
:Unicode跨
set Unicode_Result=36328
exit/b
:Unicode33007
set Unicode_Result=胯
exit/b
:Unicode胯
set Unicode_Result=33007
exit/b
:Unicode22359
set Unicode_Result=块
exit/b
:Unicode块
set Unicode_Result=22359
exit/b
:Unicode31607
set Unicode_Result=筷
exit/b
:Unicode筷
set Unicode_Result=31607
exit/b
:Unicode20393
set Unicode_Result=侩
exit/b
:Unicode侩
set Unicode_Result=20393
exit/b
:Unicode24555
set Unicode_Result=快
exit/b
:Unicode快
set Unicode_Result=24555
exit/b
:Unicode23485
set Unicode_Result=宽
exit/b
:Unicode宽
set Unicode_Result=23485
exit/b
:Unicode27454
set Unicode_Result=款
exit/b
:Unicode款
set Unicode_Result=27454
exit/b
:Unicode21281
set Unicode_Result=匡
exit/b
:Unicode匡
set Unicode_Result=21281
exit/b
:Unicode31568
set Unicode_Result=筐
exit/b
:Unicode筐
set Unicode_Result=31568
exit/b
:Unicode29378
set Unicode_Result=狂
exit/b
:Unicode狂
set Unicode_Result=29378
exit/b
:Unicode26694
set Unicode_Result=框
exit/b
:Unicode框
set Unicode_Result=26694
exit/b
:Unicode30719
set Unicode_Result=矿
exit/b
:Unicode矿
set Unicode_Result=30719
exit/b
:Unicode30518
set Unicode_Result=眶
exit/b
:Unicode眶
set Unicode_Result=30518
exit/b
:Unicode26103
set Unicode_Result=旷
exit/b
:Unicode旷
set Unicode_Result=26103
exit/b
:Unicode20917
set Unicode_Result=况
exit/b
:Unicode况
set Unicode_Result=20917
exit/b
:Unicode20111
set Unicode_Result=亏
exit/b
:Unicode亏
set Unicode_Result=20111
exit/b
:Unicode30420
set Unicode_Result=盔
exit/b
:Unicode盔
set Unicode_Result=30420
exit/b
:Unicode23743
set Unicode_Result=岿
exit/b
:Unicode岿
set Unicode_Result=23743
exit/b
:Unicode31397
set Unicode_Result=窥
exit/b
:Unicode窥
set Unicode_Result=31397
exit/b
:Unicode33909
set Unicode_Result=葵
exit/b
:Unicode葵
set Unicode_Result=33909
exit/b
:Unicode22862
set Unicode_Result=奎
exit/b
:Unicode奎
set Unicode_Result=22862
exit/b
:Unicode39745
set Unicode_Result=魁
exit/b
:Unicode魁
set Unicode_Result=39745
exit/b
:Unicode20608
set Unicode_Result=傀
exit/b
:Unicode傀
set Unicode_Result=20608
exit/b
:Unicode39304
set Unicode_Result=馈
exit/b
:Unicode馈
set Unicode_Result=39304
exit/b
:Unicode24871
set Unicode_Result=愧
exit/b
:Unicode愧
set Unicode_Result=24871
exit/b
:Unicode28291
set Unicode_Result=溃
exit/b
:Unicode溃
set Unicode_Result=28291
exit/b
:Unicode22372
set Unicode_Result=坤
exit/b
:Unicode坤
set Unicode_Result=22372
exit/b
:Unicode26118
set Unicode_Result=昆
exit/b
:Unicode昆
set Unicode_Result=26118
exit/b
:Unicode25414
set Unicode_Result=捆
exit/b
:Unicode捆
set Unicode_Result=25414
exit/b
:Unicode22256
set Unicode_Result=困
exit/b
:Unicode困
set Unicode_Result=22256
exit/b
:Unicode25324
set Unicode_Result=括
exit/b
:Unicode括
set Unicode_Result=25324
exit/b
:Unicode25193
set Unicode_Result=扩
exit/b
:Unicode扩
set Unicode_Result=25193
exit/b
:Unicode24275
set Unicode_Result=廓
exit/b
:Unicode廓
set Unicode_Result=24275
exit/b
:Unicode38420
set Unicode_Result=阔
exit/b
:Unicode阔
set Unicode_Result=38420
exit/b
:Unicode22403
set Unicode_Result=垃
exit/b
:Unicode垃
set Unicode_Result=22403
exit/b
:Unicode25289
set Unicode_Result=拉
exit/b
:Unicode拉
set Unicode_Result=25289
exit/b
:Unicode21895
set Unicode_Result=喇
exit/b
:Unicode喇
set Unicode_Result=21895
exit/b
:Unicode34593
set Unicode_Result=蜡
exit/b
:Unicode蜡
set Unicode_Result=34593
exit/b
:Unicode33098
set Unicode_Result=腊
exit/b
:Unicode腊
set Unicode_Result=33098
exit/b
:Unicode36771
set Unicode_Result=辣
exit/b
:Unicode辣
set Unicode_Result=36771
exit/b
:Unicode21862
set Unicode_Result=啦
exit/b
:Unicode啦
set Unicode_Result=21862
exit/b
:Unicode33713
set Unicode_Result=莱
exit/b
:Unicode莱
set Unicode_Result=33713
exit/b
:Unicode26469
set Unicode_Result=来
exit/b
:Unicode来
set Unicode_Result=26469
exit/b
:Unicode36182
set Unicode_Result=赖
exit/b
:Unicode赖
set Unicode_Result=36182
exit/b
:Unicode34013
set Unicode_Result=蓝
exit/b
:Unicode蓝
set Unicode_Result=34013
exit/b
:Unicode23146
set Unicode_Result=婪
exit/b
:Unicode婪
set Unicode_Result=23146
exit/b
:Unicode26639
set Unicode_Result=栏
exit/b
:Unicode栏
set Unicode_Result=26639
exit/b
:Unicode25318
set Unicode_Result=拦
exit/b
:Unicode拦
set Unicode_Result=25318
exit/b
:Unicode31726
set Unicode_Result=篮
exit/b
:Unicode篮
set Unicode_Result=31726
exit/b
:Unicode38417
set Unicode_Result=阑
exit/b
:Unicode阑
set Unicode_Result=38417
exit/b
:Unicode20848
set Unicode_Result=兰
exit/b
:Unicode兰
set Unicode_Result=20848
exit/b
:Unicode28572
set Unicode_Result=澜
exit/b
:Unicode澜
set Unicode_Result=28572
exit/b
:Unicode35888
set Unicode_Result=谰
exit/b
:Unicode谰
set Unicode_Result=35888
exit/b
:Unicode25597
set Unicode_Result=揽
exit/b
:Unicode揽
set Unicode_Result=25597
exit/b
:Unicode35272
set Unicode_Result=览
exit/b
:Unicode览
set Unicode_Result=35272
exit/b
:Unicode25042
set Unicode_Result=懒
exit/b
:Unicode懒
set Unicode_Result=25042
exit/b
:Unicode32518
set Unicode_Result=缆
exit/b
:Unicode缆
set Unicode_Result=32518
exit/b
:Unicode28866
set Unicode_Result=烂
exit/b
:Unicode烂
set Unicode_Result=28866
exit/b
:Unicode28389
set Unicode_Result=滥
exit/b
:Unicode滥
set Unicode_Result=28389
exit/b
:Unicode29701
set Unicode_Result=琅
exit/b
:Unicode琅
set Unicode_Result=29701
exit/b
:Unicode27028
set Unicode_Result=榔
exit/b
:Unicode榔
set Unicode_Result=27028
exit/b
:Unicode29436
set Unicode_Result=狼
exit/b
:Unicode狼
set Unicode_Result=29436
exit/b
:Unicode24266
set Unicode_Result=廊
exit/b
:Unicode廊
set Unicode_Result=24266
exit/b
:Unicode37070
set Unicode_Result=郎
exit/b
:Unicode郎
set Unicode_Result=37070
exit/b
:Unicode26391
set Unicode_Result=朗
exit/b
:Unicode朗
set Unicode_Result=26391
exit/b
:Unicode28010
set Unicode_Result=浪
exit/b
:Unicode浪
set Unicode_Result=28010
exit/b
:Unicode25438
set Unicode_Result=捞
exit/b
:Unicode捞
set Unicode_Result=25438
exit/b
:Unicode21171
set Unicode_Result=劳
exit/b
:Unicode劳
set Unicode_Result=21171
exit/b
:Unicode29282
set Unicode_Result=牢
exit/b
:Unicode牢
set Unicode_Result=29282
exit/b
:Unicode32769
set Unicode_Result=老
exit/b
:Unicode老
set Unicode_Result=32769
exit/b
:Unicode20332
set Unicode_Result=佬
exit/b
:Unicode佬
set Unicode_Result=20332
exit/b
:Unicode23013
set Unicode_Result=姥
exit/b
:Unicode姥
set Unicode_Result=23013
exit/b
:Unicode37226
set Unicode_Result=酪
exit/b
:Unicode酪
set Unicode_Result=37226
exit/b
:Unicode28889
set Unicode_Result=烙
exit/b
:Unicode烙
set Unicode_Result=28889
exit/b
:Unicode28061
set Unicode_Result=涝
exit/b
:Unicode涝
set Unicode_Result=28061
exit/b
:Unicode21202
set Unicode_Result=勒
exit/b
:Unicode勒
set Unicode_Result=21202
exit/b
:Unicode20048
set Unicode_Result=乐
exit/b
:Unicode乐
set Unicode_Result=20048
exit/b
:Unicode38647
set Unicode_Result=雷
exit/b
:Unicode雷
set Unicode_Result=38647
exit/b
:Unicode38253
set Unicode_Result=镭
exit/b
:Unicode镭
set Unicode_Result=38253
exit/b
:Unicode34174
set Unicode_Result=蕾
exit/b
:Unicode蕾
set Unicode_Result=34174
exit/b
:Unicode30922
set Unicode_Result=磊
exit/b
:Unicode磊
set Unicode_Result=30922
exit/b
:Unicode32047
set Unicode_Result=累
exit/b
:Unicode累
set Unicode_Result=32047
exit/b
:Unicode20769
set Unicode_Result=儡
exit/b
:Unicode儡
set Unicode_Result=20769
exit/b
:Unicode22418
set Unicode_Result=垒
exit/b
:Unicode垒
set Unicode_Result=22418
exit/b
:Unicode25794
set Unicode_Result=擂
exit/b
:Unicode擂
set Unicode_Result=25794
exit/b
:Unicode32907
set Unicode_Result=肋
exit/b
:Unicode肋
set Unicode_Result=32907
exit/b
:Unicode31867
set Unicode_Result=类
exit/b
:Unicode类
set Unicode_Result=31867
exit/b
:Unicode27882
set Unicode_Result=泪
exit/b
:Unicode泪
set Unicode_Result=27882
exit/b
:Unicode26865
set Unicode_Result=棱
exit/b
:Unicode棱
set Unicode_Result=26865
exit/b
:Unicode26974
set Unicode_Result=楞
exit/b
:Unicode楞
set Unicode_Result=26974
exit/b
:Unicode20919
set Unicode_Result=冷
exit/b
:Unicode冷
set Unicode_Result=20919
exit/b
:Unicode21400
set Unicode_Result=厘
exit/b
:Unicode厘
set Unicode_Result=21400
exit/b
:Unicode26792
set Unicode_Result=梨
exit/b
:Unicode梨
set Unicode_Result=26792
exit/b
:Unicode29313
set Unicode_Result=犁
exit/b
:Unicode犁
set Unicode_Result=29313
exit/b
:Unicode40654
set Unicode_Result=黎
exit/b
:Unicode黎
set Unicode_Result=40654
exit/b
:Unicode31729
set Unicode_Result=篱
exit/b
:Unicode篱
set Unicode_Result=31729
exit/b
:Unicode29432
set Unicode_Result=狸
exit/b
:Unicode狸
set Unicode_Result=29432
exit/b
:Unicode31163
set Unicode_Result=离
exit/b
:Unicode离
set Unicode_Result=31163
exit/b
:Unicode28435
set Unicode_Result=漓
exit/b
:Unicode漓
set Unicode_Result=28435
exit/b
:Unicode29702
set Unicode_Result=理
exit/b
:Unicode理
set Unicode_Result=29702
exit/b
:Unicode26446
set Unicode_Result=李
exit/b
:Unicode李
set Unicode_Result=26446
exit/b
:Unicode37324
set Unicode_Result=里
exit/b
:Unicode里
set Unicode_Result=37324
exit/b
:Unicode40100
set Unicode_Result=鲤
exit/b
:Unicode鲤
set Unicode_Result=40100
exit/b
:Unicode31036
set Unicode_Result=礼
exit/b
:Unicode礼
set Unicode_Result=31036
exit/b
:Unicode33673
set Unicode_Result=莉
exit/b
:Unicode莉
set Unicode_Result=33673
exit/b
:Unicode33620
set Unicode_Result=荔
exit/b
:Unicode荔
set Unicode_Result=33620
exit/b
:Unicode21519
set Unicode_Result=吏
exit/b
:Unicode吏
set Unicode_Result=21519
exit/b
:Unicode26647
set Unicode_Result=栗
exit/b
:Unicode栗
set Unicode_Result=26647
exit/b
:Unicode20029
set Unicode_Result=丽
exit/b
:Unicode丽
set Unicode_Result=20029
exit/b
:Unicode21385
set Unicode_Result=厉
exit/b
:Unicode厉
set Unicode_Result=21385
exit/b
:Unicode21169
set Unicode_Result=励
exit/b
:Unicode励
set Unicode_Result=21169
exit/b
:Unicode30782
set Unicode_Result=砾
exit/b
:Unicode砾
set Unicode_Result=30782
exit/b
:Unicode21382
set Unicode_Result=历
exit/b
:Unicode历
set Unicode_Result=21382
exit/b
:Unicode21033
set Unicode_Result=利
exit/b
:Unicode利
set Unicode_Result=21033
exit/b
:Unicode20616
set Unicode_Result=傈
exit/b
:Unicode傈
set Unicode_Result=20616
exit/b
:Unicode20363
set Unicode_Result=例
exit/b
:Unicode例
set Unicode_Result=20363
exit/b
:Unicode20432
set Unicode_Result=俐
exit/b
:Unicode俐
set Unicode_Result=20432
exit/b
:Unicode30178
set Unicode_Result=痢
exit/b
:Unicode痢
set Unicode_Result=30178
exit/b
:Unicode31435
set Unicode_Result=立
exit/b
:Unicode立
set Unicode_Result=31435
exit/b
:Unicode31890
set Unicode_Result=粒
exit/b
:Unicode粒
set Unicode_Result=31890
exit/b
:Unicode27813
set Unicode_Result=沥
exit/b
:Unicode沥
set Unicode_Result=27813
exit/b
:Unicode38582
set Unicode_Result=隶
exit/b
:Unicode隶
set Unicode_Result=38582
exit/b
:Unicode21147
set Unicode_Result=力
exit/b
:Unicode力
set Unicode_Result=21147
exit/b
:Unicode29827
set Unicode_Result=璃
exit/b
:Unicode璃
set Unicode_Result=29827
exit/b
:Unicode21737
set Unicode_Result=哩
exit/b
:Unicode哩
set Unicode_Result=21737
exit/b
:Unicode20457
set Unicode_Result=俩
exit/b
:Unicode俩
set Unicode_Result=20457
exit/b
:Unicode32852
set Unicode_Result=联
exit/b
:Unicode联
set Unicode_Result=32852
exit/b
:Unicode33714
set Unicode_Result=莲
exit/b
:Unicode莲
set Unicode_Result=33714
exit/b
:Unicode36830
set Unicode_Result=连
exit/b
:Unicode连
set Unicode_Result=36830
exit/b
:Unicode38256
set Unicode_Result=镰
exit/b
:Unicode镰
set Unicode_Result=38256
exit/b
:Unicode24265
set Unicode_Result=廉
exit/b
:Unicode廉
set Unicode_Result=24265
exit/b
:Unicode24604
set Unicode_Result=怜
exit/b
:Unicode怜
set Unicode_Result=24604
exit/b
:Unicode28063
set Unicode_Result=涟
exit/b
:Unicode涟
set Unicode_Result=28063
exit/b
:Unicode24088
set Unicode_Result=帘
exit/b
:Unicode帘
set Unicode_Result=24088
exit/b
:Unicode25947
set Unicode_Result=敛
exit/b
:Unicode敛
set Unicode_Result=25947
exit/b
:Unicode33080
set Unicode_Result=脸
exit/b
:Unicode脸
set Unicode_Result=33080
exit/b
:Unicode38142
set Unicode_Result=链
exit/b
:Unicode链
set Unicode_Result=38142
exit/b
:Unicode24651
set Unicode_Result=恋
exit/b
:Unicode恋
set Unicode_Result=24651
exit/b
:Unicode28860
set Unicode_Result=炼
exit/b
:Unicode炼
set Unicode_Result=28860
exit/b
:Unicode32451
set Unicode_Result=练
exit/b
:Unicode练
set Unicode_Result=32451
exit/b
:Unicode31918
set Unicode_Result=粮
exit/b
:Unicode粮
set Unicode_Result=31918
exit/b
:Unicode20937
set Unicode_Result=凉
exit/b
:Unicode凉
set Unicode_Result=20937
exit/b
:Unicode26753
set Unicode_Result=梁
exit/b
:Unicode梁
set Unicode_Result=26753
exit/b
:Unicode31921
set Unicode_Result=粱
exit/b
:Unicode粱
set Unicode_Result=31921
exit/b
:Unicode33391
set Unicode_Result=良
exit/b
:Unicode良
set Unicode_Result=33391
exit/b
:Unicode20004
set Unicode_Result=两
exit/b
:Unicode两
set Unicode_Result=20004
exit/b
:Unicode36742
set Unicode_Result=辆
exit/b
:Unicode辆
set Unicode_Result=36742
exit/b
:Unicode37327
set Unicode_Result=量
exit/b
:Unicode量
set Unicode_Result=37327
exit/b
:Unicode26238
set Unicode_Result=晾
exit/b
:Unicode晾
set Unicode_Result=26238
exit/b
:Unicode20142
set Unicode_Result=亮
exit/b
:Unicode亮
set Unicode_Result=20142
exit/b
:Unicode35845
set Unicode_Result=谅
exit/b
:Unicode谅
set Unicode_Result=35845
exit/b
:Unicode25769
set Unicode_Result=撩
exit/b
:Unicode撩
set Unicode_Result=25769
exit/b
:Unicode32842
set Unicode_Result=聊
exit/b
:Unicode聊
set Unicode_Result=32842
exit/b
:Unicode20698
set Unicode_Result=僚
exit/b
:Unicode僚
set Unicode_Result=20698
exit/b
:Unicode30103
set Unicode_Result=疗
exit/b
:Unicode疗
set Unicode_Result=30103
exit/b
:Unicode29134
set Unicode_Result=燎
exit/b
:Unicode燎
set Unicode_Result=29134
exit/b
:Unicode23525
set Unicode_Result=寥
exit/b
:Unicode寥
set Unicode_Result=23525
exit/b
:Unicode36797
set Unicode_Result=辽
exit/b
:Unicode辽
set Unicode_Result=36797
exit/b
:Unicode28518
set Unicode_Result=潦
exit/b
:Unicode潦
set Unicode_Result=28518
exit/b
:Unicode20102
set Unicode_Result=了
exit/b
:Unicode了
set Unicode_Result=20102
exit/b
:Unicode25730
set Unicode_Result=撂
exit/b
:Unicode撂
set Unicode_Result=25730
exit/b
:Unicode38243
set Unicode_Result=镣
exit/b
:Unicode镣
set Unicode_Result=38243
exit/b
:Unicode24278
set Unicode_Result=廖
exit/b
:Unicode廖
set Unicode_Result=24278
exit/b
:Unicode26009
set Unicode_Result=料
exit/b
:Unicode料
set Unicode_Result=26009
exit/b
:Unicode21015
set Unicode_Result=列
exit/b
:Unicode列
set Unicode_Result=21015
exit/b
:Unicode35010
set Unicode_Result=裂
exit/b
:Unicode裂
set Unicode_Result=35010
exit/b
:Unicode28872
set Unicode_Result=烈
exit/b
:Unicode烈
set Unicode_Result=28872
exit/b
:Unicode21155
set Unicode_Result=劣
exit/b
:Unicode劣
set Unicode_Result=21155
exit/b
:Unicode29454
set Unicode_Result=猎
exit/b
:Unicode猎
set Unicode_Result=29454
exit/b
:Unicode29747
set Unicode_Result=琳
exit/b
:Unicode琳
set Unicode_Result=29747
exit/b
:Unicode26519
set Unicode_Result=林
exit/b
:Unicode林
set Unicode_Result=26519
exit/b
:Unicode30967
set Unicode_Result=磷
exit/b
:Unicode磷
set Unicode_Result=30967
exit/b
:Unicode38678
set Unicode_Result=霖
exit/b
:Unicode霖
set Unicode_Result=38678
exit/b
:Unicode20020
set Unicode_Result=临
exit/b
:Unicode临
set Unicode_Result=20020
exit/b
:Unicode37051
set Unicode_Result=邻
exit/b
:Unicode邻
set Unicode_Result=37051
exit/b
:Unicode40158
set Unicode_Result=鳞
exit/b
:Unicode鳞
set Unicode_Result=40158
exit/b
:Unicode28107
set Unicode_Result=淋
exit/b
:Unicode淋
set Unicode_Result=28107
exit/b
:Unicode20955
set Unicode_Result=凛
exit/b
:Unicode凛
set Unicode_Result=20955
exit/b
:Unicode36161
set Unicode_Result=赁
exit/b
:Unicode赁
set Unicode_Result=36161
exit/b
:Unicode21533
set Unicode_Result=吝
exit/b
:Unicode吝
set Unicode_Result=21533
exit/b
:Unicode25294
set Unicode_Result=拎
exit/b
:Unicode拎
set Unicode_Result=25294
exit/b
:Unicode29618
set Unicode_Result=玲
exit/b
:Unicode玲
set Unicode_Result=29618
exit/b
:Unicode33777
set Unicode_Result=菱
exit/b
:Unicode菱
set Unicode_Result=33777
exit/b
:Unicode38646
set Unicode_Result=零
exit/b
:Unicode零
set Unicode_Result=38646
exit/b
:Unicode40836
set Unicode_Result=龄
exit/b
:Unicode龄
set Unicode_Result=40836
exit/b
:Unicode38083
set Unicode_Result=铃
exit/b
:Unicode铃
set Unicode_Result=38083
exit/b
:Unicode20278
set Unicode_Result=伶
exit/b
:Unicode伶
set Unicode_Result=20278
exit/b
:Unicode32666
set Unicode_Result=羚
exit/b
:Unicode羚
set Unicode_Result=32666
exit/b
:Unicode20940
set Unicode_Result=凌
exit/b
:Unicode凌
set Unicode_Result=20940
exit/b
:Unicode28789
set Unicode_Result=灵
exit/b
:Unicode灵
set Unicode_Result=28789
exit/b
:Unicode38517
set Unicode_Result=陵
exit/b
:Unicode陵
set Unicode_Result=38517
exit/b
:Unicode23725
set Unicode_Result=岭
exit/b
:Unicode岭
set Unicode_Result=23725
exit/b
:Unicode39046
set Unicode_Result=领
exit/b
:Unicode领
set Unicode_Result=39046
exit/b
:Unicode21478
set Unicode_Result=另
exit/b
:Unicode另
set Unicode_Result=21478
exit/b
:Unicode20196
set Unicode_Result=令
exit/b
:Unicode令
set Unicode_Result=20196
exit/b
:Unicode28316
set Unicode_Result=溜
exit/b
:Unicode溜
set Unicode_Result=28316
exit/b
:Unicode29705
set Unicode_Result=琉
exit/b
:Unicode琉
set Unicode_Result=29705
exit/b
:Unicode27060
set Unicode_Result=榴
exit/b
:Unicode榴
set Unicode_Result=27060
exit/b
:Unicode30827
set Unicode_Result=硫
exit/b
:Unicode硫
set Unicode_Result=30827
exit/b
:Unicode39311
set Unicode_Result=馏
exit/b
:Unicode馏
set Unicode_Result=39311
exit/b
:Unicode30041
set Unicode_Result=留
exit/b
:Unicode留
set Unicode_Result=30041
exit/b
:Unicode21016
set Unicode_Result=刘
exit/b
:Unicode刘
set Unicode_Result=21016
exit/b
:Unicode30244
set Unicode_Result=瘤
exit/b
:Unicode瘤
set Unicode_Result=30244
exit/b
:Unicode27969
set Unicode_Result=流
exit/b
:Unicode流
set Unicode_Result=27969
exit/b
:Unicode26611
set Unicode_Result=柳
exit/b
:Unicode柳
set Unicode_Result=26611
exit/b
:Unicode20845
set Unicode_Result=六
exit/b
:Unicode六
set Unicode_Result=20845
exit/b
:Unicode40857
set Unicode_Result=龙
exit/b
:Unicode龙
set Unicode_Result=40857
exit/b
:Unicode32843
set Unicode_Result=聋
exit/b
:Unicode聋
set Unicode_Result=32843
exit/b
:Unicode21657
set Unicode_Result=咙
exit/b
:Unicode咙
set Unicode_Result=21657
exit/b
:Unicode31548
set Unicode_Result=笼
exit/b
:Unicode笼
set Unicode_Result=31548
exit/b
:Unicode31423
set Unicode_Result=窿
exit/b
:Unicode窿
set Unicode_Result=31423
exit/b
:Unicode38534
set Unicode_Result=隆
exit/b
:Unicode隆
set Unicode_Result=38534
exit/b
:Unicode22404
set Unicode_Result=垄
exit/b
:Unicode垄
set Unicode_Result=22404
exit/b
:Unicode25314
set Unicode_Result=拢
exit/b
:Unicode拢
set Unicode_Result=25314
exit/b
:Unicode38471
set Unicode_Result=陇
exit/b
:Unicode陇
set Unicode_Result=38471
exit/b
:Unicode27004
set Unicode_Result=楼
exit/b
:Unicode楼
set Unicode_Result=27004
exit/b
:Unicode23044
set Unicode_Result=娄
exit/b
:Unicode娄
set Unicode_Result=23044
exit/b
:Unicode25602
set Unicode_Result=搂
exit/b
:Unicode搂
set Unicode_Result=25602
exit/b
:Unicode31699
set Unicode_Result=篓
exit/b
:Unicode篓
set Unicode_Result=31699
exit/b
:Unicode28431
set Unicode_Result=漏
exit/b
:Unicode漏
set Unicode_Result=28431
exit/b
:Unicode38475
set Unicode_Result=陋
exit/b
:Unicode陋
set Unicode_Result=38475
exit/b
:Unicode33446
set Unicode_Result=芦
exit/b
:Unicode芦
set Unicode_Result=33446
exit/b
:Unicode21346
set Unicode_Result=卢
exit/b
:Unicode卢
set Unicode_Result=21346
exit/b
:Unicode39045
set Unicode_Result=颅
exit/b
:Unicode颅
set Unicode_Result=39045
exit/b
:Unicode24208
set Unicode_Result=庐
exit/b
:Unicode庐
set Unicode_Result=24208
exit/b
:Unicode28809
set Unicode_Result=炉
exit/b
:Unicode炉
set Unicode_Result=28809
exit/b
:Unicode25523
set Unicode_Result=掳
exit/b
:Unicode掳
set Unicode_Result=25523
exit/b
:Unicode21348
set Unicode_Result=卤
exit/b
:Unicode卤
set Unicode_Result=21348
exit/b
:Unicode34383
set Unicode_Result=虏
exit/b
:Unicode虏
set Unicode_Result=34383
exit/b
:Unicode40065
set Unicode_Result=鲁
exit/b
:Unicode鲁
set Unicode_Result=40065
exit/b
:Unicode40595
set Unicode_Result=麓
exit/b
:Unicode麓
set Unicode_Result=40595
exit/b
:Unicode30860
set Unicode_Result=碌
exit/b
:Unicode碌
set Unicode_Result=30860
exit/b
:Unicode38706
set Unicode_Result=露
exit/b
:Unicode露
set Unicode_Result=38706
exit/b
:Unicode36335
set Unicode_Result=路
exit/b
:Unicode路
set Unicode_Result=36335
exit/b
:Unicode36162
set Unicode_Result=赂
exit/b
:Unicode赂
set Unicode_Result=36162
exit/b
:Unicode40575
set Unicode_Result=鹿
exit/b
:Unicode鹿
set Unicode_Result=40575
exit/b
:Unicode28510
set Unicode_Result=潞
exit/b
:Unicode潞
set Unicode_Result=28510
exit/b
:Unicode31108
set Unicode_Result=禄
exit/b
:Unicode禄
set Unicode_Result=31108
exit/b
:Unicode24405
set Unicode_Result=录
exit/b
:Unicode录
set Unicode_Result=24405
exit/b
:Unicode38470
set Unicode_Result=陆
exit/b
:Unicode陆
set Unicode_Result=38470
exit/b
:Unicode25134
set Unicode_Result=戮
exit/b
:Unicode戮
set Unicode_Result=25134
exit/b
:Unicode39540
set Unicode_Result=驴
exit/b
:Unicode驴
set Unicode_Result=39540
exit/b
:Unicode21525
set Unicode_Result=吕
exit/b
:Unicode吕
set Unicode_Result=21525
exit/b
:Unicode38109
set Unicode_Result=铝
exit/b
:Unicode铝
set Unicode_Result=38109
exit/b
:Unicode20387
set Unicode_Result=侣
exit/b
:Unicode侣
set Unicode_Result=20387
exit/b
:Unicode26053
set Unicode_Result=旅
exit/b
:Unicode旅
set Unicode_Result=26053
exit/b
:Unicode23653
set Unicode_Result=履
exit/b
:Unicode履
set Unicode_Result=23653
exit/b
:Unicode23649
set Unicode_Result=屡
exit/b
:Unicode屡
set Unicode_Result=23649
exit/b
:Unicode32533
set Unicode_Result=缕
exit/b
:Unicode缕
set Unicode_Result=32533
exit/b
:Unicode34385
set Unicode_Result=虑
exit/b
:Unicode虑
set Unicode_Result=34385
exit/b
:Unicode27695
set Unicode_Result=氯
exit/b
:Unicode氯
set Unicode_Result=27695
exit/b
:Unicode24459
set Unicode_Result=律
exit/b
:Unicode律
set Unicode_Result=24459
exit/b
:Unicode29575
set Unicode_Result=率
exit/b
:Unicode率
set Unicode_Result=29575
exit/b
:Unicode28388
set Unicode_Result=滤
exit/b
:Unicode滤
set Unicode_Result=28388
exit/b
:Unicode32511
set Unicode_Result=绿
exit/b
:Unicode绿
set Unicode_Result=32511
exit/b
:Unicode23782
set Unicode_Result=峦
exit/b
:Unicode峦
set Unicode_Result=23782
exit/b
:Unicode25371
set Unicode_Result=挛
exit/b
:Unicode挛
set Unicode_Result=25371
exit/b
:Unicode23402
set Unicode_Result=孪
exit/b
:Unicode孪
set Unicode_Result=23402
exit/b
:Unicode28390
set Unicode_Result=滦
exit/b
:Unicode滦
set Unicode_Result=28390
exit/b
:Unicode21365
set Unicode_Result=卵
exit/b
:Unicode卵
set Unicode_Result=21365
exit/b
:Unicode20081
set Unicode_Result=乱
exit/b
:Unicode乱
set Unicode_Result=20081
exit/b
:Unicode25504
set Unicode_Result=掠
exit/b
:Unicode掠
set Unicode_Result=25504
exit/b
:Unicode30053
set Unicode_Result=略
exit/b
:Unicode略
set Unicode_Result=30053
exit/b
:Unicode25249
set Unicode_Result=抡
exit/b
:Unicode抡
set Unicode_Result=25249
exit/b
:Unicode36718
set Unicode_Result=轮
exit/b
:Unicode轮
set Unicode_Result=36718
exit/b
:Unicode20262
set Unicode_Result=伦
exit/b
:Unicode伦
set Unicode_Result=20262
exit/b
:Unicode20177
set Unicode_Result=仑
exit/b
:Unicode仑
set Unicode_Result=20177
exit/b
:Unicode27814
set Unicode_Result=沦
exit/b
:Unicode沦
set Unicode_Result=27814
exit/b
:Unicode32438
set Unicode_Result=纶
exit/b
:Unicode纶
set Unicode_Result=32438
exit/b
:Unicode35770
set Unicode_Result=论
exit/b
:Unicode论
set Unicode_Result=35770
exit/b
:Unicode33821
set Unicode_Result=萝
exit/b
:Unicode萝
set Unicode_Result=33821
exit/b
:Unicode34746
set Unicode_Result=螺
exit/b
:Unicode螺
set Unicode_Result=34746
exit/b
:Unicode32599
set Unicode_Result=罗
exit/b
:Unicode罗
set Unicode_Result=32599
exit/b
:Unicode36923
set Unicode_Result=逻
exit/b
:Unicode逻
set Unicode_Result=36923
exit/b
:Unicode38179
set Unicode_Result=锣
exit/b
:Unicode锣
set Unicode_Result=38179
exit/b
:Unicode31657
set Unicode_Result=箩
exit/b
:Unicode箩
set Unicode_Result=31657
exit/b
:Unicode39585
set Unicode_Result=骡
exit/b
:Unicode骡
set Unicode_Result=39585
exit/b
:Unicode35064
set Unicode_Result=裸
exit/b
:Unicode裸
set Unicode_Result=35064
exit/b
:Unicode33853
set Unicode_Result=落
exit/b
:Unicode落
set Unicode_Result=33853
exit/b
:Unicode27931
set Unicode_Result=洛
exit/b
:Unicode洛
set Unicode_Result=27931
exit/b
:Unicode39558
set Unicode_Result=骆
exit/b
:Unicode骆
set Unicode_Result=39558
exit/b
:Unicode32476
set Unicode_Result=络
exit/b
:Unicode络
set Unicode_Result=32476
exit/b
:Unicode22920
set Unicode_Result=妈
exit/b
:Unicode妈
set Unicode_Result=22920
exit/b
:Unicode40635
set Unicode_Result=麻
exit/b
:Unicode麻
set Unicode_Result=40635
exit/b
:Unicode29595
set Unicode_Result=玛
exit/b
:Unicode玛
set Unicode_Result=29595
exit/b
:Unicode30721
set Unicode_Result=码
exit/b
:Unicode码
set Unicode_Result=30721
exit/b
:Unicode34434
set Unicode_Result=蚂
exit/b
:Unicode蚂
set Unicode_Result=34434
exit/b
:Unicode39532
set Unicode_Result=马
exit/b
:Unicode马
set Unicode_Result=39532
exit/b
:Unicode39554
set Unicode_Result=骂
exit/b
:Unicode骂
set Unicode_Result=39554
exit/b
:Unicode22043
set Unicode_Result=嘛
exit/b
:Unicode嘛
set Unicode_Result=22043
exit/b
:Unicode21527
set Unicode_Result=吗
exit/b
:Unicode吗
set Unicode_Result=21527
exit/b
:Unicode22475
set Unicode_Result=埋
exit/b
:Unicode埋
set Unicode_Result=22475
exit/b
:Unicode20080
set Unicode_Result=买
exit/b
:Unicode买
set Unicode_Result=20080
exit/b
:Unicode40614
set Unicode_Result=麦
exit/b
:Unicode麦
set Unicode_Result=40614
exit/b
:Unicode21334
set Unicode_Result=卖
exit/b
:Unicode卖
set Unicode_Result=21334
exit/b
:Unicode36808
set Unicode_Result=迈
exit/b
:Unicode迈
set Unicode_Result=36808
exit/b
:Unicode33033
set Unicode_Result=脉
exit/b
:Unicode脉
set Unicode_Result=33033
exit/b
:Unicode30610
set Unicode_Result=瞒
exit/b
:Unicode瞒
set Unicode_Result=30610
exit/b
:Unicode39314
set Unicode_Result=馒
exit/b
:Unicode馒
set Unicode_Result=39314
exit/b
:Unicode34542
set Unicode_Result=蛮
exit/b
:Unicode蛮
set Unicode_Result=34542
exit/b
:Unicode28385
set Unicode_Result=满
exit/b
:Unicode满
set Unicode_Result=28385
exit/b
:Unicode34067
set Unicode_Result=蔓
exit/b
:Unicode蔓
set Unicode_Result=34067
exit/b
:Unicode26364
set Unicode_Result=曼
exit/b
:Unicode曼
set Unicode_Result=26364
exit/b
:Unicode24930
set Unicode_Result=慢
exit/b
:Unicode慢
set Unicode_Result=24930
exit/b
:Unicode28459
set Unicode_Result=漫
exit/b
:Unicode漫
set Unicode_Result=28459
exit/b
:Unicode35881
set Unicode_Result=谩
exit/b
:Unicode谩
set Unicode_Result=35881
exit/b
:Unicode33426
set Unicode_Result=芒
exit/b
:Unicode芒
set Unicode_Result=33426
exit/b
:Unicode33579
set Unicode_Result=茫
exit/b
:Unicode茫
set Unicode_Result=33579
exit/b
:Unicode30450
set Unicode_Result=盲
exit/b
:Unicode盲
set Unicode_Result=30450
exit/b
:Unicode27667
set Unicode_Result=氓
exit/b
:Unicode氓
set Unicode_Result=27667
exit/b
:Unicode24537
set Unicode_Result=忙
exit/b
:Unicode忙
set Unicode_Result=24537
exit/b
:Unicode33725
set Unicode_Result=莽
exit/b
:Unicode莽
set Unicode_Result=33725
exit/b
:Unicode29483
set Unicode_Result=猫
exit/b
:Unicode猫
set Unicode_Result=29483
exit/b
:Unicode33541
set Unicode_Result=茅
exit/b
:Unicode茅
set Unicode_Result=33541
exit/b
:Unicode38170
set Unicode_Result=锚
exit/b
:Unicode锚
set Unicode_Result=38170
exit/b
:Unicode27611
set Unicode_Result=毛
exit/b
:Unicode毛
set Unicode_Result=27611
exit/b
:Unicode30683
set Unicode_Result=矛
exit/b
:Unicode矛
set Unicode_Result=30683
exit/b
:Unicode38086
set Unicode_Result=铆
exit/b
:Unicode铆
set Unicode_Result=38086
exit/b
:Unicode21359
set Unicode_Result=卯
exit/b
:Unicode卯
set Unicode_Result=21359
exit/b
:Unicode33538
set Unicode_Result=茂
exit/b
:Unicode茂
set Unicode_Result=33538
exit/b
:Unicode20882
set Unicode_Result=冒
exit/b
:Unicode冒
set Unicode_Result=20882
exit/b
:Unicode24125
set Unicode_Result=帽
exit/b
:Unicode帽
set Unicode_Result=24125
exit/b
:Unicode35980
set Unicode_Result=貌
exit/b
:Unicode貌
set Unicode_Result=35980
exit/b
:Unicode36152
set Unicode_Result=贸
exit/b
:Unicode贸
set Unicode_Result=36152
exit/b
:Unicode20040
set Unicode_Result=么
exit/b
:Unicode么
set Unicode_Result=20040
exit/b
:Unicode29611
set Unicode_Result=玫
exit/b
:Unicode玫
set Unicode_Result=29611
exit/b
:Unicode26522
set Unicode_Result=枚
exit/b
:Unicode枚
set Unicode_Result=26522
exit/b
:Unicode26757
set Unicode_Result=梅
exit/b
:Unicode梅
set Unicode_Result=26757
exit/b
:Unicode37238
set Unicode_Result=酶
exit/b
:Unicode酶
set Unicode_Result=37238
exit/b
:Unicode38665
set Unicode_Result=霉
exit/b
:Unicode霉
set Unicode_Result=38665
exit/b
:Unicode29028
set Unicode_Result=煤
exit/b
:Unicode煤
set Unicode_Result=29028
exit/b
:Unicode27809
set Unicode_Result=没
exit/b
:Unicode没
set Unicode_Result=27809
exit/b
:Unicode30473
set Unicode_Result=眉
exit/b
:Unicode眉
set Unicode_Result=30473
exit/b
:Unicode23186
set Unicode_Result=媒
exit/b
:Unicode媒
set Unicode_Result=23186
exit/b
:Unicode38209
set Unicode_Result=镁
exit/b
:Unicode镁
set Unicode_Result=38209
exit/b
:Unicode27599
set Unicode_Result=每
exit/b
:Unicode每
set Unicode_Result=27599
exit/b
:Unicode32654
set Unicode_Result=美
exit/b
:Unicode美
set Unicode_Result=32654
exit/b
:Unicode26151
set Unicode_Result=昧
exit/b
:Unicode昧
set Unicode_Result=26151
exit/b
:Unicode23504
set Unicode_Result=寐
exit/b
:Unicode寐
set Unicode_Result=23504
exit/b
:Unicode22969
set Unicode_Result=妹
exit/b
:Unicode妹
set Unicode_Result=22969
exit/b
:Unicode23194
set Unicode_Result=媚
exit/b
:Unicode媚
set Unicode_Result=23194
exit/b
:Unicode38376
set Unicode_Result=门
exit/b
:Unicode门
set Unicode_Result=38376
exit/b
:Unicode38391
set Unicode_Result=闷
exit/b
:Unicode闷
set Unicode_Result=38391
exit/b
:Unicode20204
set Unicode_Result=们
exit/b
:Unicode们
set Unicode_Result=20204
exit/b
:Unicode33804
set Unicode_Result=萌
exit/b
:Unicode萌
set Unicode_Result=33804
exit/b
:Unicode33945
set Unicode_Result=蒙
exit/b
:Unicode蒙
set Unicode_Result=33945
exit/b
:Unicode27308
set Unicode_Result=檬
exit/b
:Unicode檬
set Unicode_Result=27308
exit/b
:Unicode30431
set Unicode_Result=盟
exit/b
:Unicode盟
set Unicode_Result=30431
exit/b
:Unicode38192
set Unicode_Result=锰
exit/b
:Unicode锰
set Unicode_Result=38192
exit/b
:Unicode29467
set Unicode_Result=猛
exit/b
:Unicode猛
set Unicode_Result=29467
exit/b
:Unicode26790
set Unicode_Result=梦
exit/b
:Unicode梦
set Unicode_Result=26790
exit/b
:Unicode23391
set Unicode_Result=孟
exit/b
:Unicode孟
set Unicode_Result=23391
exit/b
:Unicode30511
set Unicode_Result=眯
exit/b
:Unicode眯
set Unicode_Result=30511
exit/b
:Unicode37274
set Unicode_Result=醚
exit/b
:Unicode醚
set Unicode_Result=37274
exit/b
:Unicode38753
set Unicode_Result=靡
exit/b
:Unicode靡
set Unicode_Result=38753
exit/b
:Unicode31964
set Unicode_Result=糜
exit/b
:Unicode糜
set Unicode_Result=31964
exit/b
:Unicode36855
set Unicode_Result=迷
exit/b
:Unicode迷
set Unicode_Result=36855
exit/b
:Unicode35868
set Unicode_Result=谜
exit/b
:Unicode谜
set Unicode_Result=35868
exit/b
:Unicode24357
set Unicode_Result=弥
exit/b
:Unicode弥
set Unicode_Result=24357
exit/b
:Unicode31859
set Unicode_Result=米
exit/b
:Unicode米
set Unicode_Result=31859
exit/b
:Unicode31192
set Unicode_Result=秘
exit/b
:Unicode秘
set Unicode_Result=31192
exit/b
:Unicode35269
set Unicode_Result=觅
exit/b
:Unicode觅
set Unicode_Result=35269
exit/b
:Unicode27852
set Unicode_Result=泌
exit/b
:Unicode泌
set Unicode_Result=27852
exit/b
:Unicode34588
set Unicode_Result=蜜
exit/b
:Unicode蜜
set Unicode_Result=34588
exit/b
:Unicode23494
set Unicode_Result=密
exit/b
:Unicode密
set Unicode_Result=23494
exit/b
:Unicode24130
set Unicode_Result=幂
exit/b
:Unicode幂
set Unicode_Result=24130
exit/b
:Unicode26825
set Unicode_Result=棉
exit/b
:Unicode棉
set Unicode_Result=26825
exit/b
:Unicode30496
set Unicode_Result=眠
exit/b
:Unicode眠
set Unicode_Result=30496
exit/b
:Unicode32501
set Unicode_Result=绵
exit/b
:Unicode绵
set Unicode_Result=32501
exit/b
:Unicode20885
set Unicode_Result=冕
exit/b
:Unicode冕
set Unicode_Result=20885
exit/b
:Unicode20813
set Unicode_Result=免
exit/b
:Unicode免
set Unicode_Result=20813
exit/b
:Unicode21193
set Unicode_Result=勉
exit/b
:Unicode勉
set Unicode_Result=21193
exit/b
:Unicode23081
set Unicode_Result=娩
exit/b
:Unicode娩
set Unicode_Result=23081
exit/b
:Unicode32517
set Unicode_Result=缅
exit/b
:Unicode缅
set Unicode_Result=32517
exit/b
:Unicode38754
set Unicode_Result=面
exit/b
:Unicode面
set Unicode_Result=38754
exit/b
:Unicode33495
set Unicode_Result=苗
exit/b
:Unicode苗
set Unicode_Result=33495
exit/b
:Unicode25551
set Unicode_Result=描
exit/b
:Unicode描
set Unicode_Result=25551
exit/b
:Unicode30596
set Unicode_Result=瞄
exit/b
:Unicode瞄
set Unicode_Result=30596
exit/b
:Unicode34256
set Unicode_Result=藐
exit/b
:Unicode藐
set Unicode_Result=34256
exit/b
:Unicode31186
set Unicode_Result=秒
exit/b
:Unicode秒
set Unicode_Result=31186
exit/b
:Unicode28218
set Unicode_Result=渺
exit/b
:Unicode渺
set Unicode_Result=28218
exit/b
:Unicode24217
set Unicode_Result=庙
exit/b
:Unicode庙
set Unicode_Result=24217
exit/b
:Unicode22937
set Unicode_Result=妙
exit/b
:Unicode妙
set Unicode_Result=22937
exit/b
:Unicode34065
set Unicode_Result=蔑
exit/b
:Unicode蔑
set Unicode_Result=34065
exit/b
:Unicode28781
set Unicode_Result=灭
exit/b
:Unicode灭
set Unicode_Result=28781
exit/b
:Unicode27665
set Unicode_Result=民
exit/b
:Unicode民
set Unicode_Result=27665
exit/b
:Unicode25279
set Unicode_Result=抿
exit/b
:Unicode抿
set Unicode_Result=25279
exit/b
:Unicode30399
set Unicode_Result=皿
exit/b
:Unicode皿
set Unicode_Result=30399
exit/b
:Unicode25935
set Unicode_Result=敏
exit/b
:Unicode敏
set Unicode_Result=25935
exit/b
:Unicode24751
set Unicode_Result=悯
exit/b
:Unicode悯
set Unicode_Result=24751
exit/b
:Unicode38397
set Unicode_Result=闽
exit/b
:Unicode闽
set Unicode_Result=38397
exit/b
:Unicode26126
set Unicode_Result=明
exit/b
:Unicode明
set Unicode_Result=26126
exit/b
:Unicode34719
set Unicode_Result=螟
exit/b
:Unicode螟
set Unicode_Result=34719
exit/b
:Unicode40483
set Unicode_Result=鸣
exit/b
:Unicode鸣
set Unicode_Result=40483
exit/b
:Unicode38125
set Unicode_Result=铭
exit/b
:Unicode铭
set Unicode_Result=38125
exit/b
:Unicode21517
set Unicode_Result=名
exit/b
:Unicode名
set Unicode_Result=21517
exit/b
:Unicode21629
set Unicode_Result=命
exit/b
:Unicode命
set Unicode_Result=21629
exit/b
:Unicode35884
set Unicode_Result=谬
exit/b
:Unicode谬
set Unicode_Result=35884
exit/b
:Unicode25720
set Unicode_Result=摸
exit/b
:Unicode摸
set Unicode_Result=25720
exit/b
:Unicode25721
set Unicode_Result=摹
exit/b
:Unicode摹
set Unicode_Result=25721
exit/b
:Unicode34321
set Unicode_Result=蘑
exit/b
:Unicode蘑
set Unicode_Result=34321
exit/b
:Unicode27169
set Unicode_Result=模
exit/b
:Unicode模
set Unicode_Result=27169
exit/b
:Unicode33180
set Unicode_Result=膜
exit/b
:Unicode膜
set Unicode_Result=33180
exit/b
:Unicode30952
set Unicode_Result=磨
exit/b
:Unicode磨
set Unicode_Result=30952
exit/b
:Unicode25705
set Unicode_Result=摩
exit/b
:Unicode摩
set Unicode_Result=25705
exit/b
:Unicode39764
set Unicode_Result=魔
exit/b
:Unicode魔
set Unicode_Result=39764
exit/b
:Unicode25273
set Unicode_Result=抹
exit/b
:Unicode抹
set Unicode_Result=25273
exit/b
:Unicode26411
set Unicode_Result=末
exit/b
:Unicode末
set Unicode_Result=26411
exit/b
:Unicode33707
set Unicode_Result=莫
exit/b
:Unicode莫
set Unicode_Result=33707
exit/b
:Unicode22696
set Unicode_Result=墨
exit/b
:Unicode墨
set Unicode_Result=22696
exit/b
:Unicode40664
set Unicode_Result=默
exit/b
:Unicode默
set Unicode_Result=40664
exit/b
:Unicode27819
set Unicode_Result=沫
exit/b
:Unicode沫
set Unicode_Result=27819
exit/b
:Unicode28448
set Unicode_Result=漠
exit/b
:Unicode漠
set Unicode_Result=28448
exit/b
:Unicode23518
set Unicode_Result=寞
exit/b
:Unicode寞
set Unicode_Result=23518
exit/b
:Unicode38476
set Unicode_Result=陌
exit/b
:Unicode陌
set Unicode_Result=38476
exit/b
:Unicode35851
set Unicode_Result=谋
exit/b
:Unicode谋
set Unicode_Result=35851
exit/b
:Unicode29279
set Unicode_Result=牟
exit/b
:Unicode牟
set Unicode_Result=29279
exit/b
:Unicode26576
set Unicode_Result=某
exit/b
:Unicode某
set Unicode_Result=26576
exit/b
:Unicode25287
set Unicode_Result=拇
exit/b
:Unicode拇
set Unicode_Result=25287
exit/b
:Unicode29281
set Unicode_Result=牡
exit/b
:Unicode牡
set Unicode_Result=29281
exit/b
:Unicode20137
set Unicode_Result=亩
exit/b
:Unicode亩
set Unicode_Result=20137
exit/b
:Unicode22982
set Unicode_Result=姆
exit/b
:Unicode姆
set Unicode_Result=22982
exit/b
:Unicode27597
set Unicode_Result=母
exit/b
:Unicode母
set Unicode_Result=27597
exit/b
:Unicode22675
set Unicode_Result=墓
exit/b
:Unicode墓
set Unicode_Result=22675
exit/b
:Unicode26286
set Unicode_Result=暮
exit/b
:Unicode暮
set Unicode_Result=26286
exit/b
:Unicode24149
set Unicode_Result=幕
exit/b
:Unicode幕
set Unicode_Result=24149
exit/b
:Unicode21215
set Unicode_Result=募
exit/b
:Unicode募
set Unicode_Result=21215
exit/b
:Unicode24917
set Unicode_Result=慕
exit/b
:Unicode慕
set Unicode_Result=24917
exit/b
:Unicode26408
set Unicode_Result=木
exit/b
:Unicode木
set Unicode_Result=26408
exit/b
:Unicode30446
set Unicode_Result=目
exit/b
:Unicode目
set Unicode_Result=30446
exit/b
:Unicode30566
set Unicode_Result=睦
exit/b
:Unicode睦
set Unicode_Result=30566
exit/b
:Unicode29287
set Unicode_Result=牧
exit/b
:Unicode牧
set Unicode_Result=29287
exit/b
:Unicode31302
set Unicode_Result=穆
exit/b
:Unicode穆
set Unicode_Result=31302
exit/b
:Unicode25343
set Unicode_Result=拿
exit/b
:Unicode拿
set Unicode_Result=25343
exit/b
:Unicode21738
set Unicode_Result=哪
exit/b
:Unicode哪
set Unicode_Result=21738
exit/b
:Unicode21584
set Unicode_Result=呐
exit/b
:Unicode呐
set Unicode_Result=21584
exit/b
:Unicode38048
set Unicode_Result=钠
exit/b
:Unicode钠
set Unicode_Result=38048
exit/b
:Unicode37027
set Unicode_Result=那
exit/b
:Unicode那
set Unicode_Result=37027
exit/b
:Unicode23068
set Unicode_Result=娜
exit/b
:Unicode娜
set Unicode_Result=23068
exit/b
:Unicode32435
set Unicode_Result=纳
exit/b
:Unicode纳
set Unicode_Result=32435
exit/b
:Unicode27670
set Unicode_Result=氖
exit/b
:Unicode氖
set Unicode_Result=27670
exit/b
:Unicode20035
set Unicode_Result=乃
exit/b
:Unicode乃
set Unicode_Result=20035
exit/b
:Unicode22902
set Unicode_Result=奶
exit/b
:Unicode奶
set Unicode_Result=22902
exit/b
:Unicode32784
set Unicode_Result=耐
exit/b
:Unicode耐
set Unicode_Result=32784
exit/b
:Unicode22856
set Unicode_Result=奈
exit/b
:Unicode奈
set Unicode_Result=22856
exit/b
:Unicode21335
set Unicode_Result=南
exit/b
:Unicode南
set Unicode_Result=21335
exit/b
:Unicode30007
set Unicode_Result=男
exit/b
:Unicode男
set Unicode_Result=30007
exit/b
:Unicode38590
set Unicode_Result=难
exit/b
:Unicode难
set Unicode_Result=38590
exit/b
:Unicode22218
set Unicode_Result=囊
exit/b
:Unicode囊
set Unicode_Result=22218
exit/b
:Unicode25376
set Unicode_Result=挠
exit/b
:Unicode挠
set Unicode_Result=25376
exit/b
:Unicode33041
set Unicode_Result=脑
exit/b
:Unicode脑
set Unicode_Result=33041
exit/b
:Unicode24700
set Unicode_Result=恼
exit/b
:Unicode恼
set Unicode_Result=24700
exit/b
:Unicode38393
set Unicode_Result=闹
exit/b
:Unicode闹
set Unicode_Result=38393
exit/b
:Unicode28118
set Unicode_Result=淖
exit/b
:Unicode淖
set Unicode_Result=28118
exit/b
:Unicode21602
set Unicode_Result=呢
exit/b
:Unicode呢
set Unicode_Result=21602
exit/b
:Unicode39297
set Unicode_Result=馁
exit/b
:Unicode馁
set Unicode_Result=39297
exit/b
:Unicode20869
set Unicode_Result=内
exit/b
:Unicode内
set Unicode_Result=20869
exit/b
:Unicode23273
set Unicode_Result=嫩
exit/b
:Unicode嫩
set Unicode_Result=23273
exit/b
:Unicode33021
set Unicode_Result=能
exit/b
:Unicode能
set Unicode_Result=33021
exit/b
:Unicode22958
set Unicode_Result=妮
exit/b
:Unicode妮
set Unicode_Result=22958
exit/b
:Unicode38675
set Unicode_Result=霓
exit/b
:Unicode霓
set Unicode_Result=38675
exit/b
:Unicode20522
set Unicode_Result=倪
exit/b
:Unicode倪
set Unicode_Result=20522
exit/b
:Unicode27877
set Unicode_Result=泥
exit/b
:Unicode泥
set Unicode_Result=27877
exit/b
:Unicode23612
set Unicode_Result=尼
exit/b
:Unicode尼
set Unicode_Result=23612
exit/b
:Unicode25311
set Unicode_Result=拟
exit/b
:Unicode拟
set Unicode_Result=25311
exit/b
:Unicode20320
set Unicode_Result=你
exit/b
:Unicode你
set Unicode_Result=20320
exit/b
:Unicode21311
set Unicode_Result=匿
exit/b
:Unicode匿
set Unicode_Result=21311
exit/b
:Unicode33147
set Unicode_Result=腻
exit/b
:Unicode腻
set Unicode_Result=33147
exit/b
:Unicode36870
set Unicode_Result=逆
exit/b
:Unicode逆
set Unicode_Result=36870
exit/b
:Unicode28346
set Unicode_Result=溺
exit/b
:Unicode溺
set Unicode_Result=28346
exit/b
:Unicode34091
set Unicode_Result=蔫
exit/b
:Unicode蔫
set Unicode_Result=34091
exit/b
:Unicode25288
set Unicode_Result=拈
exit/b
:Unicode拈
set Unicode_Result=25288
exit/b
:Unicode24180
set Unicode_Result=年
exit/b
:Unicode年
set Unicode_Result=24180
exit/b
:Unicode30910
set Unicode_Result=碾
exit/b
:Unicode碾
set Unicode_Result=30910
exit/b
:Unicode25781
set Unicode_Result=撵
exit/b
:Unicode撵
set Unicode_Result=25781
exit/b
:Unicode25467
set Unicode_Result=捻
exit/b
:Unicode捻
set Unicode_Result=25467
exit/b
:Unicode24565
set Unicode_Result=念
exit/b
:Unicode念
set Unicode_Result=24565
exit/b
:Unicode23064
set Unicode_Result=娘
exit/b
:Unicode娘
set Unicode_Result=23064
exit/b
:Unicode37247
set Unicode_Result=酿
exit/b
:Unicode酿
set Unicode_Result=37247
exit/b
:Unicode40479
set Unicode_Result=鸟
exit/b
:Unicode鸟
set Unicode_Result=40479
exit/b
:Unicode23615
set Unicode_Result=尿
exit/b
:Unicode尿
set Unicode_Result=23615
exit/b
:Unicode25423
set Unicode_Result=捏
exit/b
:Unicode捏
set Unicode_Result=25423
exit/b
:Unicode32834
set Unicode_Result=聂
exit/b
:Unicode聂
set Unicode_Result=32834
exit/b
:Unicode23421
set Unicode_Result=孽
exit/b
:Unicode孽
set Unicode_Result=23421
exit/b
:Unicode21870
set Unicode_Result=啮
exit/b
:Unicode啮
set Unicode_Result=21870
exit/b
:Unicode38218
set Unicode_Result=镊
exit/b
:Unicode镊
set Unicode_Result=38218
exit/b
:Unicode38221
set Unicode_Result=镍
exit/b
:Unicode镍
set Unicode_Result=38221
exit/b
:Unicode28037
set Unicode_Result=涅
exit/b
:Unicode涅
set Unicode_Result=28037
exit/b
:Unicode24744
set Unicode_Result=您
exit/b
:Unicode您
set Unicode_Result=24744
exit/b
:Unicode26592
set Unicode_Result=柠
exit/b
:Unicode柠
set Unicode_Result=26592
exit/b
:Unicode29406
set Unicode_Result=狞
exit/b
:Unicode狞
set Unicode_Result=29406
exit/b
:Unicode20957
set Unicode_Result=凝
exit/b
:Unicode凝
set Unicode_Result=20957
exit/b
:Unicode23425
set Unicode_Result=宁
exit/b
:Unicode宁
set Unicode_Result=23425
exit/b
:Unicode25319
set Unicode_Result=拧
exit/b
:Unicode拧
set Unicode_Result=25319
exit/b
:Unicode27870
set Unicode_Result=泞
exit/b
:Unicode泞
set Unicode_Result=27870
exit/b
:Unicode29275
set Unicode_Result=牛
exit/b
:Unicode牛
set Unicode_Result=29275
exit/b
:Unicode25197
set Unicode_Result=扭
exit/b
:Unicode扭
set Unicode_Result=25197
exit/b
:Unicode38062
set Unicode_Result=钮
exit/b
:Unicode钮
set Unicode_Result=38062
exit/b
:Unicode32445
set Unicode_Result=纽
exit/b
:Unicode纽
set Unicode_Result=32445
exit/b
:Unicode33043
set Unicode_Result=脓
exit/b
:Unicode脓
set Unicode_Result=33043
exit/b
:Unicode27987
set Unicode_Result=浓
exit/b
:Unicode浓
set Unicode_Result=27987
exit/b
:Unicode20892
set Unicode_Result=农
exit/b
:Unicode农
set Unicode_Result=20892
exit/b
:Unicode24324
set Unicode_Result=弄
exit/b
:Unicode弄
set Unicode_Result=24324
exit/b
:Unicode22900
set Unicode_Result=奴
exit/b
:Unicode奴
set Unicode_Result=22900
exit/b
:Unicode21162
set Unicode_Result=努
exit/b
:Unicode努
set Unicode_Result=21162
exit/b
:Unicode24594
set Unicode_Result=怒
exit/b
:Unicode怒
set Unicode_Result=24594
exit/b
:Unicode22899
set Unicode_Result=女
exit/b
:Unicode女
set Unicode_Result=22899
exit/b
:Unicode26262
set Unicode_Result=暖
exit/b
:Unicode暖
set Unicode_Result=26262
exit/b
:Unicode34384
set Unicode_Result=虐
exit/b
:Unicode虐
set Unicode_Result=34384
exit/b
:Unicode30111
set Unicode_Result=疟
exit/b
:Unicode疟
set Unicode_Result=30111
exit/b
:Unicode25386
set Unicode_Result=挪
exit/b
:Unicode挪
set Unicode_Result=25386
exit/b
:Unicode25062
set Unicode_Result=懦
exit/b
:Unicode懦
set Unicode_Result=25062
exit/b
:Unicode31983
set Unicode_Result=糯
exit/b
:Unicode糯
set Unicode_Result=31983
exit/b
:Unicode35834
set Unicode_Result=诺
exit/b
:Unicode诺
set Unicode_Result=35834
exit/b
:Unicode21734
set Unicode_Result=哦
exit/b
:Unicode哦
set Unicode_Result=21734
exit/b
:Unicode27431
set Unicode_Result=欧
exit/b
:Unicode欧
set Unicode_Result=27431
exit/b
:Unicode40485
set Unicode_Result=鸥
exit/b
:Unicode鸥
set Unicode_Result=40485
exit/b
:Unicode27572
set Unicode_Result=殴
exit/b
:Unicode殴
set Unicode_Result=27572
exit/b
:Unicode34261
set Unicode_Result=藕
exit/b
:Unicode藕
set Unicode_Result=34261
exit/b
:Unicode21589
set Unicode_Result=呕
exit/b
:Unicode呕
set Unicode_Result=21589
exit/b
:Unicode20598
set Unicode_Result=偶
exit/b
:Unicode偶
set Unicode_Result=20598
exit/b
:Unicode27812
set Unicode_Result=沤
exit/b
:Unicode沤
set Unicode_Result=27812
exit/b
:Unicode21866
set Unicode_Result=啪
exit/b
:Unicode啪
set Unicode_Result=21866
exit/b
:Unicode36276
set Unicode_Result=趴
exit/b
:Unicode趴
set Unicode_Result=36276
exit/b
:Unicode29228
set Unicode_Result=爬
exit/b
:Unicode爬
set Unicode_Result=29228
exit/b
:Unicode24085
set Unicode_Result=帕
exit/b
:Unicode帕
set Unicode_Result=24085
exit/b
:Unicode24597
set Unicode_Result=怕
exit/b
:Unicode怕
set Unicode_Result=24597
exit/b
:Unicode29750
set Unicode_Result=琶
exit/b
:Unicode琶
set Unicode_Result=29750
exit/b
:Unicode25293
set Unicode_Result=拍
exit/b
:Unicode拍
set Unicode_Result=25293
exit/b
:Unicode25490
set Unicode_Result=排
exit/b
:Unicode排
set Unicode_Result=25490
exit/b
:Unicode29260
set Unicode_Result=牌
exit/b
:Unicode牌
set Unicode_Result=29260
exit/b
:Unicode24472
set Unicode_Result=徘
exit/b
:Unicode徘
set Unicode_Result=24472
exit/b
:Unicode28227
set Unicode_Result=湃
exit/b
:Unicode湃
set Unicode_Result=28227
exit/b
:Unicode27966
set Unicode_Result=派
exit/b
:Unicode派
set Unicode_Result=27966
exit/b
:Unicode25856
set Unicode_Result=攀
exit/b
:Unicode攀
set Unicode_Result=25856
exit/b
:Unicode28504
set Unicode_Result=潘
exit/b
:Unicode潘
set Unicode_Result=28504
exit/b
:Unicode30424
set Unicode_Result=盘
exit/b
:Unicode盘
set Unicode_Result=30424
exit/b
:Unicode30928
set Unicode_Result=磐
exit/b
:Unicode磐
set Unicode_Result=30928
exit/b
:Unicode30460
set Unicode_Result=盼
exit/b
:Unicode盼
set Unicode_Result=30460
exit/b
:Unicode30036
set Unicode_Result=畔
exit/b
:Unicode畔
set Unicode_Result=30036
exit/b
:Unicode21028
set Unicode_Result=判
exit/b
:Unicode判
set Unicode_Result=21028
exit/b
:Unicode21467
set Unicode_Result=叛
exit/b
:Unicode叛
set Unicode_Result=21467
exit/b
:Unicode20051
set Unicode_Result=乓
exit/b
:Unicode乓
set Unicode_Result=20051
exit/b
:Unicode24222
set Unicode_Result=庞
exit/b
:Unicode庞
set Unicode_Result=24222
exit/b
:Unicode26049
set Unicode_Result=旁
exit/b
:Unicode旁
set Unicode_Result=26049
exit/b
:Unicode32810
set Unicode_Result=耪
exit/b
:Unicode耪
set Unicode_Result=32810
exit/b
:Unicode32982
set Unicode_Result=胖
exit/b
:Unicode胖
set Unicode_Result=32982
exit/b
:Unicode25243
set Unicode_Result=抛
exit/b
:Unicode抛
set Unicode_Result=25243
exit/b
:Unicode21638
set Unicode_Result=咆
exit/b
:Unicode咆
set Unicode_Result=21638
exit/b
:Unicode21032
set Unicode_Result=刨
exit/b
:Unicode刨
set Unicode_Result=21032
exit/b
:Unicode28846
set Unicode_Result=炮
exit/b
:Unicode炮
set Unicode_Result=28846
exit/b
:Unicode34957
set Unicode_Result=袍
exit/b
:Unicode袍
set Unicode_Result=34957
exit/b
:Unicode36305
set Unicode_Result=跑
exit/b
:Unicode跑
set Unicode_Result=36305
exit/b
:Unicode27873
set Unicode_Result=泡
exit/b
:Unicode泡
set Unicode_Result=27873
exit/b
:Unicode21624
set Unicode_Result=呸
exit/b
:Unicode呸
set Unicode_Result=21624
exit/b
:Unicode32986
set Unicode_Result=胚
exit/b
:Unicode胚
set Unicode_Result=32986
exit/b
:Unicode22521
set Unicode_Result=培
exit/b
:Unicode培
set Unicode_Result=22521
exit/b
:Unicode35060
set Unicode_Result=裴
exit/b
:Unicode裴
set Unicode_Result=35060
exit/b
:Unicode36180
set Unicode_Result=赔
exit/b
:Unicode赔
set Unicode_Result=36180
exit/b
:Unicode38506
set Unicode_Result=陪
exit/b
:Unicode陪
set Unicode_Result=38506
exit/b
:Unicode37197
set Unicode_Result=配
exit/b
:Unicode配
set Unicode_Result=37197
exit/b
:Unicode20329
set Unicode_Result=佩
exit/b
:Unicode佩
set Unicode_Result=20329
exit/b
:Unicode27803
set Unicode_Result=沛
exit/b
:Unicode沛
set Unicode_Result=27803
exit/b
:Unicode21943
set Unicode_Result=喷
exit/b
:Unicode喷
set Unicode_Result=21943
exit/b
:Unicode30406
set Unicode_Result=盆
exit/b
:Unicode盆
set Unicode_Result=30406
exit/b
:Unicode30768
set Unicode_Result=砰
exit/b
:Unicode砰
set Unicode_Result=30768
exit/b
:Unicode25256
set Unicode_Result=抨
exit/b
:Unicode抨
set Unicode_Result=25256
exit/b
:Unicode28921
set Unicode_Result=烹
exit/b
:Unicode烹
set Unicode_Result=28921
exit/b
:Unicode28558
set Unicode_Result=澎
exit/b
:Unicode澎
set Unicode_Result=28558
exit/b
:Unicode24429
set Unicode_Result=彭
exit/b
:Unicode彭
set Unicode_Result=24429
exit/b
:Unicode34028
set Unicode_Result=蓬
exit/b
:Unicode蓬
set Unicode_Result=34028
exit/b
:Unicode26842
set Unicode_Result=棚
exit/b
:Unicode棚
set Unicode_Result=26842
exit/b
:Unicode30844
set Unicode_Result=硼
exit/b
:Unicode硼
set Unicode_Result=30844
exit/b
:Unicode31735
set Unicode_Result=篷
exit/b
:Unicode篷
set Unicode_Result=31735
exit/b
:Unicode33192
set Unicode_Result=膨
exit/b
:Unicode膨
set Unicode_Result=33192
exit/b
:Unicode26379
set Unicode_Result=朋
exit/b
:Unicode朋
set Unicode_Result=26379
exit/b
:Unicode40527
set Unicode_Result=鹏
exit/b
:Unicode鹏
set Unicode_Result=40527
exit/b
:Unicode25447
set Unicode_Result=捧
exit/b
:Unicode捧
set Unicode_Result=25447
exit/b
:Unicode30896
set Unicode_Result=碰
exit/b
:Unicode碰
set Unicode_Result=30896
exit/b
:Unicode22383
set Unicode_Result=坯
exit/b
:Unicode坯
set Unicode_Result=22383
exit/b
:Unicode30738
set Unicode_Result=砒
exit/b
:Unicode砒
set Unicode_Result=30738
exit/b
:Unicode38713
set Unicode_Result=霹
exit/b
:Unicode霹
set Unicode_Result=38713
exit/b
:Unicode25209
set Unicode_Result=批
exit/b
:Unicode批
set Unicode_Result=25209
exit/b
:Unicode25259
set Unicode_Result=披
exit/b
:Unicode披
set Unicode_Result=25259
exit/b
:Unicode21128
set Unicode_Result=劈
exit/b
:Unicode劈
set Unicode_Result=21128
exit/b
:Unicode29749
set Unicode_Result=琵
exit/b
:Unicode琵
set Unicode_Result=29749
exit/b
:Unicode27607
set Unicode_Result=毗
exit/b
:Unicode毗
set Unicode_Result=27607
exit/b
:Unicode21860
set Unicode_Result=啤
exit/b
:Unicode啤
set Unicode_Result=21860
exit/b
:Unicode33086
set Unicode_Result=脾
exit/b
:Unicode脾
set Unicode_Result=33086
exit/b
:Unicode30130
set Unicode_Result=疲
exit/b
:Unicode疲
set Unicode_Result=30130
exit/b
:Unicode30382
set Unicode_Result=皮
exit/b
:Unicode皮
set Unicode_Result=30382
exit/b
:Unicode21305
set Unicode_Result=匹
exit/b
:Unicode匹
set Unicode_Result=21305
exit/b
:Unicode30174
set Unicode_Result=痞
exit/b
:Unicode痞
set Unicode_Result=30174
exit/b
:Unicode20731
set Unicode_Result=僻
exit/b
:Unicode僻
set Unicode_Result=20731
exit/b
:Unicode23617
set Unicode_Result=屁
exit/b
:Unicode屁
set Unicode_Result=23617
exit/b
:Unicode35692
set Unicode_Result=譬
exit/b
:Unicode譬
set Unicode_Result=35692
exit/b
:Unicode31687
set Unicode_Result=篇
exit/b
:Unicode篇
set Unicode_Result=31687
exit/b
:Unicode20559
set Unicode_Result=偏
exit/b
:Unicode偏
set Unicode_Result=20559
exit/b
:Unicode29255
set Unicode_Result=片
exit/b
:Unicode片
set Unicode_Result=29255
exit/b
:Unicode39575
set Unicode_Result=骗
exit/b
:Unicode骗
set Unicode_Result=39575
exit/b
:Unicode39128
set Unicode_Result=飘
exit/b
:Unicode飘
set Unicode_Result=39128
exit/b
:Unicode28418
set Unicode_Result=漂
exit/b
:Unicode漂
set Unicode_Result=28418
exit/b
:Unicode29922
set Unicode_Result=瓢
exit/b
:Unicode瓢
set Unicode_Result=29922
exit/b
:Unicode31080
set Unicode_Result=票
exit/b
:Unicode票
set Unicode_Result=31080
exit/b
:Unicode25735
set Unicode_Result=撇
exit/b
:Unicode撇
set Unicode_Result=25735
exit/b
:Unicode30629
set Unicode_Result=瞥
exit/b
:Unicode瞥
set Unicode_Result=30629
exit/b
:Unicode25340
set Unicode_Result=拼
exit/b
:Unicode拼
set Unicode_Result=25340
exit/b
:Unicode39057
set Unicode_Result=频
exit/b
:Unicode频
set Unicode_Result=39057
exit/b
:Unicode36139
set Unicode_Result=贫
exit/b
:Unicode贫
set Unicode_Result=36139
exit/b
:Unicode21697
set Unicode_Result=品
exit/b
:Unicode品
set Unicode_Result=21697
exit/b
:Unicode32856
set Unicode_Result=聘
exit/b
:Unicode聘
set Unicode_Result=32856
exit/b
:Unicode20050
set Unicode_Result=乒
exit/b
:Unicode乒
set Unicode_Result=20050
exit/b
:Unicode22378
set Unicode_Result=坪
exit/b
:Unicode坪
set Unicode_Result=22378
exit/b
:Unicode33529
set Unicode_Result=苹
exit/b
:Unicode苹
set Unicode_Result=33529
exit/b
:Unicode33805
set Unicode_Result=萍
exit/b
:Unicode萍
set Unicode_Result=33805
exit/b
:Unicode24179
set Unicode_Result=平
exit/b
:Unicode平
set Unicode_Result=24179
exit/b
:Unicode20973
set Unicode_Result=凭
exit/b
:Unicode凭
set Unicode_Result=20973
exit/b
:Unicode29942
set Unicode_Result=瓶
exit/b
:Unicode瓶
set Unicode_Result=29942
exit/b
:Unicode35780
set Unicode_Result=评
exit/b
:Unicode评
set Unicode_Result=35780
exit/b
:Unicode23631
set Unicode_Result=屏
exit/b
:Unicode屏
set Unicode_Result=23631
exit/b
:Unicode22369
set Unicode_Result=坡
exit/b
:Unicode坡
set Unicode_Result=22369
exit/b
:Unicode27900
set Unicode_Result=泼
exit/b
:Unicode泼
set Unicode_Result=27900
exit/b
:Unicode39047
set Unicode_Result=颇
exit/b
:Unicode颇
set Unicode_Result=39047
exit/b
:Unicode23110
set Unicode_Result=婆
exit/b
:Unicode婆
set Unicode_Result=23110
exit/b
:Unicode30772
set Unicode_Result=破
exit/b
:Unicode破
set Unicode_Result=30772
exit/b
:Unicode39748
set Unicode_Result=魄
exit/b
:Unicode魄
set Unicode_Result=39748
exit/b
:Unicode36843
set Unicode_Result=迫
exit/b
:Unicode迫
set Unicode_Result=36843
exit/b
:Unicode31893
set Unicode_Result=粕
exit/b
:Unicode粕
set Unicode_Result=31893
exit/b
:Unicode21078
set Unicode_Result=剖
exit/b
:Unicode剖
set Unicode_Result=21078
exit/b
:Unicode25169
set Unicode_Result=扑
exit/b
:Unicode扑
set Unicode_Result=25169
exit/b
:Unicode38138
set Unicode_Result=铺
exit/b
:Unicode铺
set Unicode_Result=38138
exit/b
:Unicode20166
set Unicode_Result=仆
exit/b
:Unicode仆
set Unicode_Result=20166
exit/b
:Unicode33670
set Unicode_Result=莆
exit/b
:Unicode莆
set Unicode_Result=33670
exit/b
:Unicode33889
set Unicode_Result=葡
exit/b
:Unicode葡
set Unicode_Result=33889
exit/b
:Unicode33769
set Unicode_Result=菩
exit/b
:Unicode菩
set Unicode_Result=33769
exit/b
:Unicode33970
set Unicode_Result=蒲
exit/b
:Unicode蒲
set Unicode_Result=33970
exit/b
:Unicode22484
set Unicode_Result=埔
exit/b
:Unicode埔
set Unicode_Result=22484
exit/b
:Unicode26420
set Unicode_Result=朴
exit/b
:Unicode朴
set Unicode_Result=26420
exit/b
:Unicode22275
set Unicode_Result=圃
exit/b
:Unicode圃
set Unicode_Result=22275
exit/b
:Unicode26222
set Unicode_Result=普
exit/b
:Unicode普
set Unicode_Result=26222
exit/b
:Unicode28006
set Unicode_Result=浦
exit/b
:Unicode浦
set Unicode_Result=28006
exit/b
:Unicode35889
set Unicode_Result=谱
exit/b
:Unicode谱
set Unicode_Result=35889
exit/b
:Unicode26333
set Unicode_Result=曝
exit/b
:Unicode曝
set Unicode_Result=26333
exit/b
:Unicode28689
set Unicode_Result=瀑
exit/b
:Unicode瀑
set Unicode_Result=28689
exit/b
:Unicode26399
set Unicode_Result=期
exit/b
:Unicode期
set Unicode_Result=26399
exit/b
:Unicode27450
set Unicode_Result=欺
exit/b
:Unicode欺
set Unicode_Result=27450
exit/b
:Unicode26646
set Unicode_Result=栖
exit/b
:Unicode栖
set Unicode_Result=26646
exit/b
:Unicode25114
set Unicode_Result=戚
exit/b
:Unicode戚
set Unicode_Result=25114
exit/b
:Unicode22971
set Unicode_Result=妻
exit/b
:Unicode妻
set Unicode_Result=22971
exit/b
:Unicode19971
set Unicode_Result=七
exit/b
:Unicode七
set Unicode_Result=19971
exit/b
:Unicode20932
set Unicode_Result=凄
exit/b
:Unicode凄
set Unicode_Result=20932
exit/b
:Unicode28422
set Unicode_Result=漆
exit/b
:Unicode漆
set Unicode_Result=28422
exit/b
:Unicode26578
set Unicode_Result=柒
exit/b
:Unicode柒
set Unicode_Result=26578
exit/b
:Unicode27791
set Unicode_Result=沏
exit/b
:Unicode沏
set Unicode_Result=27791
exit/b
:Unicode20854
set Unicode_Result=其
exit/b
:Unicode其
set Unicode_Result=20854
exit/b
:Unicode26827
set Unicode_Result=棋
exit/b
:Unicode棋
set Unicode_Result=26827
exit/b
:Unicode22855
set Unicode_Result=奇
exit/b
:Unicode奇
set Unicode_Result=22855
exit/b
:Unicode27495
set Unicode_Result=歧
exit/b
:Unicode歧
set Unicode_Result=27495
exit/b
:Unicode30054
set Unicode_Result=畦
exit/b
:Unicode畦
set Unicode_Result=30054
exit/b
:Unicode23822
set Unicode_Result=崎
exit/b
:Unicode崎
set Unicode_Result=23822
exit/b
:Unicode33040
set Unicode_Result=脐
exit/b
:Unicode脐
set Unicode_Result=33040
exit/b
:Unicode40784
set Unicode_Result=齐
exit/b
:Unicode齐
set Unicode_Result=40784
exit/b
:Unicode26071
set Unicode_Result=旗
exit/b
:Unicode旗
set Unicode_Result=26071
exit/b
:Unicode31048
set Unicode_Result=祈
exit/b
:Unicode祈
set Unicode_Result=31048
exit/b
:Unicode31041
set Unicode_Result=祁
exit/b
:Unicode祁
set Unicode_Result=31041
exit/b
:Unicode39569
set Unicode_Result=骑
exit/b
:Unicode骑
set Unicode_Result=39569
exit/b
:Unicode36215
set Unicode_Result=起
exit/b
:Unicode起
set Unicode_Result=36215
exit/b
:Unicode23682
set Unicode_Result=岂
exit/b
:Unicode岂
set Unicode_Result=23682
exit/b
:Unicode20062
set Unicode_Result=乞
exit/b
:Unicode乞
set Unicode_Result=20062
exit/b
:Unicode20225
set Unicode_Result=企
exit/b
:Unicode企
set Unicode_Result=20225
exit/b
:Unicode21551
set Unicode_Result=启
exit/b
:Unicode启
set Unicode_Result=21551
exit/b
:Unicode22865
set Unicode_Result=契
exit/b
:Unicode契
set Unicode_Result=22865
exit/b
:Unicode30732
set Unicode_Result=砌
exit/b
:Unicode砌
set Unicode_Result=30732
exit/b
:Unicode22120
set Unicode_Result=器
exit/b
:Unicode器
set Unicode_Result=22120
exit/b
:Unicode27668
set Unicode_Result=气
exit/b
:Unicode气
set Unicode_Result=27668
exit/b
:Unicode36804
set Unicode_Result=迄
exit/b
:Unicode迄
set Unicode_Result=36804
exit/b
:Unicode24323
set Unicode_Result=弃
exit/b
:Unicode弃
set Unicode_Result=24323
exit/b
:Unicode27773
set Unicode_Result=汽
exit/b
:Unicode汽
set Unicode_Result=27773
exit/b
:Unicode27875
set Unicode_Result=泣
exit/b
:Unicode泣
set Unicode_Result=27875
exit/b
:Unicode35755
set Unicode_Result=讫
exit/b
:Unicode讫
set Unicode_Result=35755
exit/b
:Unicode25488
set Unicode_Result=掐
exit/b
:Unicode掐
set Unicode_Result=25488
exit/b
:Unicode24688
set Unicode_Result=恰
exit/b
:Unicode恰
set Unicode_Result=24688
exit/b
:Unicode27965
set Unicode_Result=洽
exit/b
:Unicode洽
set Unicode_Result=27965
exit/b
:Unicode29301
set Unicode_Result=牵
exit/b
:Unicode牵
set Unicode_Result=29301
exit/b
:Unicode25190
set Unicode_Result=扦
exit/b
:Unicode扦
set Unicode_Result=25190
exit/b
:Unicode38030
set Unicode_Result=钎
exit/b
:Unicode钎
set Unicode_Result=38030
exit/b
:Unicode38085
set Unicode_Result=铅
exit/b
:Unicode铅
set Unicode_Result=38085
exit/b
:Unicode21315
set Unicode_Result=千
exit/b
:Unicode千
set Unicode_Result=21315
exit/b
:Unicode36801
set Unicode_Result=迁
exit/b
:Unicode迁
set Unicode_Result=36801
exit/b
:Unicode31614
set Unicode_Result=签
exit/b
:Unicode签
set Unicode_Result=31614
exit/b
:Unicode20191
set Unicode_Result=仟
exit/b
:Unicode仟
set Unicode_Result=20191
exit/b
:Unicode35878
set Unicode_Result=谦
exit/b
:Unicode谦
set Unicode_Result=35878
exit/b
:Unicode20094
set Unicode_Result=乾
exit/b
:Unicode乾
set Unicode_Result=20094
exit/b
:Unicode40660
set Unicode_Result=黔
exit/b
:Unicode黔
set Unicode_Result=40660
exit/b
:Unicode38065
set Unicode_Result=钱
exit/b
:Unicode钱
set Unicode_Result=38065
exit/b
:Unicode38067
set Unicode_Result=钳
exit/b
:Unicode钳
set Unicode_Result=38067
exit/b
:Unicode21069
set Unicode_Result=前
exit/b
:Unicode前
set Unicode_Result=21069
exit/b
:Unicode28508
set Unicode_Result=潜
exit/b
:Unicode潜
set Unicode_Result=28508
exit/b
:Unicode36963
set Unicode_Result=遣
exit/b
:Unicode遣
set Unicode_Result=36963
exit/b
:Unicode27973
set Unicode_Result=浅
exit/b
:Unicode浅
set Unicode_Result=27973
exit/b
:Unicode35892
set Unicode_Result=谴
exit/b
:Unicode谴
set Unicode_Result=35892
exit/b
:Unicode22545
set Unicode_Result=堑
exit/b
:Unicode堑
set Unicode_Result=22545
exit/b
:Unicode23884
set Unicode_Result=嵌
exit/b
:Unicode嵌
set Unicode_Result=23884
exit/b
:Unicode27424
set Unicode_Result=欠
exit/b
:Unicode欠
set Unicode_Result=27424
exit/b
:Unicode27465
set Unicode_Result=歉
exit/b
:Unicode歉
set Unicode_Result=27465
exit/b
:Unicode26538
set Unicode_Result=枪
exit/b
:Unicode枪
set Unicode_Result=26538
exit/b
:Unicode21595
set Unicode_Result=呛
exit/b
:Unicode呛
set Unicode_Result=21595
exit/b
:Unicode33108
set Unicode_Result=腔
exit/b
:Unicode腔
set Unicode_Result=33108
exit/b
:Unicode32652
set Unicode_Result=羌
exit/b
:Unicode羌
set Unicode_Result=32652
exit/b
:Unicode22681
set Unicode_Result=墙
exit/b
:Unicode墙
set Unicode_Result=22681
exit/b
:Unicode34103
set Unicode_Result=蔷
exit/b
:Unicode蔷
set Unicode_Result=34103
exit/b
:Unicode24378
set Unicode_Result=强
exit/b
:Unicode强
set Unicode_Result=24378
exit/b
:Unicode25250
set Unicode_Result=抢
exit/b
:Unicode抢
set Unicode_Result=25250
exit/b
:Unicode27207
set Unicode_Result=橇
exit/b
:Unicode橇
set Unicode_Result=27207
exit/b
:Unicode38201
set Unicode_Result=锹
exit/b
:Unicode锹
set Unicode_Result=38201
exit/b
:Unicode25970
set Unicode_Result=敲
exit/b
:Unicode敲
set Unicode_Result=25970
exit/b
:Unicode24708
set Unicode_Result=悄
exit/b
:Unicode悄
set Unicode_Result=24708
exit/b
:Unicode26725
set Unicode_Result=桥
exit/b
:Unicode桥
set Unicode_Result=26725
exit/b
:Unicode30631
set Unicode_Result=瞧
exit/b
:Unicode瞧
set Unicode_Result=30631
exit/b
:Unicode20052
set Unicode_Result=乔
exit/b
:Unicode乔
set Unicode_Result=20052
exit/b
:Unicode20392
set Unicode_Result=侨
exit/b
:Unicode侨
set Unicode_Result=20392
exit/b
:Unicode24039
set Unicode_Result=巧
exit/b
:Unicode巧
set Unicode_Result=24039
exit/b
:Unicode38808
set Unicode_Result=鞘
exit/b
:Unicode鞘
set Unicode_Result=38808
exit/b
:Unicode25772
set Unicode_Result=撬
exit/b
:Unicode撬
set Unicode_Result=25772
exit/b
:Unicode32728
set Unicode_Result=翘
exit/b
:Unicode翘
set Unicode_Result=32728
exit/b
:Unicode23789
set Unicode_Result=峭
exit/b
:Unicode峭
set Unicode_Result=23789
exit/b
:Unicode20431
set Unicode_Result=俏
exit/b
:Unicode俏
set Unicode_Result=20431
exit/b
:Unicode31373
set Unicode_Result=窍
exit/b
:Unicode窍
set Unicode_Result=31373
exit/b
:Unicode20999
set Unicode_Result=切
exit/b
:Unicode切
set Unicode_Result=20999
exit/b
:Unicode33540
set Unicode_Result=茄
exit/b
:Unicode茄
set Unicode_Result=33540
exit/b
:Unicode19988
set Unicode_Result=且
exit/b
:Unicode且
set Unicode_Result=19988
exit/b
:Unicode24623
set Unicode_Result=怯
exit/b
:Unicode怯
set Unicode_Result=24623
exit/b
:Unicode31363
set Unicode_Result=窃
exit/b
:Unicode窃
set Unicode_Result=31363
exit/b
:Unicode38054
set Unicode_Result=钦
exit/b
:Unicode钦
set Unicode_Result=38054
exit/b
:Unicode20405
set Unicode_Result=侵
exit/b
:Unicode侵
set Unicode_Result=20405
exit/b
:Unicode20146
set Unicode_Result=亲
exit/b
:Unicode亲
set Unicode_Result=20146
exit/b
:Unicode31206
set Unicode_Result=秦
exit/b
:Unicode秦
set Unicode_Result=31206
exit/b
:Unicode29748
set Unicode_Result=琴
exit/b
:Unicode琴
set Unicode_Result=29748
exit/b
:Unicode21220
set Unicode_Result=勤
exit/b
:Unicode勤
set Unicode_Result=21220
exit/b
:Unicode33465
set Unicode_Result=芹
exit/b
:Unicode芹
set Unicode_Result=33465
exit/b
:Unicode25810
set Unicode_Result=擒
exit/b
:Unicode擒
set Unicode_Result=25810
exit/b
:Unicode31165
set Unicode_Result=禽
exit/b
:Unicode禽
set Unicode_Result=31165
exit/b
:Unicode23517
set Unicode_Result=寝
exit/b
:Unicode寝
set Unicode_Result=23517
exit/b
:Unicode27777
set Unicode_Result=沁
exit/b
:Unicode沁
set Unicode_Result=27777
exit/b
:Unicode38738
set Unicode_Result=青
exit/b
:Unicode青
set Unicode_Result=38738
exit/b
:Unicode36731
set Unicode_Result=轻
exit/b
:Unicode轻
set Unicode_Result=36731
exit/b
:Unicode27682
set Unicode_Result=氢
exit/b
:Unicode氢
set Unicode_Result=27682
exit/b
:Unicode20542
set Unicode_Result=倾
exit/b
:Unicode倾
set Unicode_Result=20542
exit/b
:Unicode21375
set Unicode_Result=卿
exit/b
:Unicode卿
set Unicode_Result=21375
exit/b
:Unicode28165
set Unicode_Result=清
exit/b
:Unicode清
set Unicode_Result=28165
exit/b
:Unicode25806
set Unicode_Result=擎
exit/b
:Unicode擎
set Unicode_Result=25806
exit/b
:Unicode26228
set Unicode_Result=晴
exit/b
:Unicode晴
set Unicode_Result=26228
exit/b
:Unicode27696
set Unicode_Result=氰
exit/b
:Unicode氰
set Unicode_Result=27696
exit/b
:Unicode24773
set Unicode_Result=情
exit/b
:Unicode情
set Unicode_Result=24773
exit/b
:Unicode39031
set Unicode_Result=顷
exit/b
:Unicode顷
set Unicode_Result=39031
exit/b
:Unicode35831
set Unicode_Result=请
exit/b
:Unicode请
set Unicode_Result=35831
exit/b
:Unicode24198
set Unicode_Result=庆
exit/b
:Unicode庆
set Unicode_Result=24198
exit/b
:Unicode29756
set Unicode_Result=琼
exit/b
:Unicode琼
set Unicode_Result=29756
exit/b
:Unicode31351
set Unicode_Result=穷
exit/b
:Unicode穷
set Unicode_Result=31351
exit/b
:Unicode31179
set Unicode_Result=秋
exit/b
:Unicode秋
set Unicode_Result=31179
exit/b
:Unicode19992
set Unicode_Result=丘
exit/b
:Unicode丘
set Unicode_Result=19992
exit/b
:Unicode37041
set Unicode_Result=邱
exit/b
:Unicode邱
set Unicode_Result=37041
exit/b
:Unicode29699
set Unicode_Result=球
exit/b
:Unicode球
set Unicode_Result=29699
exit/b
:Unicode27714
set Unicode_Result=求
exit/b
:Unicode求
set Unicode_Result=27714
exit/b
:Unicode22234
set Unicode_Result=囚
exit/b
:Unicode囚
set Unicode_Result=22234
exit/b
:Unicode37195
set Unicode_Result=酋
exit/b
:Unicode酋
set Unicode_Result=37195
exit/b
:Unicode27845
set Unicode_Result=泅
exit/b
:Unicode泅
set Unicode_Result=27845
exit/b
:Unicode36235
set Unicode_Result=趋
exit/b
:Unicode趋
set Unicode_Result=36235
exit/b
:Unicode21306
set Unicode_Result=区
exit/b
:Unicode区
set Unicode_Result=21306
exit/b
:Unicode34502
set Unicode_Result=蛆
exit/b
:Unicode蛆
set Unicode_Result=34502
exit/b
:Unicode26354
set Unicode_Result=曲
exit/b
:Unicode曲
set Unicode_Result=26354
exit/b
:Unicode36527
set Unicode_Result=躯
exit/b
:Unicode躯
set Unicode_Result=36527
exit/b
:Unicode23624
set Unicode_Result=屈
exit/b
:Unicode屈
set Unicode_Result=23624
exit/b
:Unicode39537
set Unicode_Result=驱
exit/b
:Unicode驱
set Unicode_Result=39537
exit/b
:Unicode28192
set Unicode_Result=渠
exit/b
:Unicode渠
set Unicode_Result=28192
exit/b
:Unicode21462
set Unicode_Result=取
exit/b
:Unicode取
set Unicode_Result=21462
exit/b
:Unicode23094
set Unicode_Result=娶
exit/b
:Unicode娶
set Unicode_Result=23094
exit/b
:Unicode40843
set Unicode_Result=龋
exit/b
:Unicode龋
set Unicode_Result=40843
exit/b
:Unicode36259
set Unicode_Result=趣
exit/b
:Unicode趣
set Unicode_Result=36259
exit/b
:Unicode21435
set Unicode_Result=去
exit/b
:Unicode去
set Unicode_Result=21435
exit/b
:Unicode22280
set Unicode_Result=圈
exit/b
:Unicode圈
set Unicode_Result=22280
exit/b
:Unicode39079
set Unicode_Result=颧
exit/b
:Unicode颧
set Unicode_Result=39079
exit/b
:Unicode26435
set Unicode_Result=权
exit/b
:Unicode权
set Unicode_Result=26435
exit/b
:Unicode37275
set Unicode_Result=醛
exit/b
:Unicode醛
set Unicode_Result=37275
exit/b
:Unicode27849
set Unicode_Result=泉
exit/b
:Unicode泉
set Unicode_Result=27849
exit/b
:Unicode20840
set Unicode_Result=全
exit/b
:Unicode全
set Unicode_Result=20840
exit/b
:Unicode30154
set Unicode_Result=痊
exit/b
:Unicode痊
set Unicode_Result=30154
exit/b
:Unicode25331
set Unicode_Result=拳
exit/b
:Unicode拳
set Unicode_Result=25331
exit/b
:Unicode29356
set Unicode_Result=犬
exit/b
:Unicode犬
set Unicode_Result=29356
exit/b
:Unicode21048
set Unicode_Result=券
exit/b
:Unicode券
set Unicode_Result=21048
exit/b
:Unicode21149
set Unicode_Result=劝
exit/b
:Unicode劝
set Unicode_Result=21149
exit/b
:Unicode32570
set Unicode_Result=缺
exit/b
:Unicode缺
set Unicode_Result=32570
exit/b
:Unicode28820
set Unicode_Result=炔
exit/b
:Unicode炔
set Unicode_Result=28820
exit/b
:Unicode30264
set Unicode_Result=瘸
exit/b
:Unicode瘸
set Unicode_Result=30264
exit/b
:Unicode21364
set Unicode_Result=却
exit/b
:Unicode却
set Unicode_Result=21364
exit/b
:Unicode40522
set Unicode_Result=鹊
exit/b
:Unicode鹊
set Unicode_Result=40522
exit/b
:Unicode27063
set Unicode_Result=榷
exit/b
:Unicode榷
set Unicode_Result=27063
exit/b
:Unicode30830
set Unicode_Result=确
exit/b
:Unicode确
set Unicode_Result=30830
exit/b
:Unicode38592
set Unicode_Result=雀
exit/b
:Unicode雀
set Unicode_Result=38592
exit/b
:Unicode35033
set Unicode_Result=裙
exit/b
:Unicode裙
set Unicode_Result=35033
exit/b
:Unicode32676
set Unicode_Result=群
exit/b
:Unicode群
set Unicode_Result=32676
exit/b
:Unicode28982
set Unicode_Result=然
exit/b
:Unicode然
set Unicode_Result=28982
exit/b
:Unicode29123
set Unicode_Result=燃
exit/b
:Unicode燃
set Unicode_Result=29123
exit/b
:Unicode20873
set Unicode_Result=冉
exit/b
:Unicode冉
set Unicode_Result=20873
exit/b
:Unicode26579
set Unicode_Result=染
exit/b
:Unicode染
set Unicode_Result=26579
exit/b
:Unicode29924
set Unicode_Result=瓤
exit/b
:Unicode瓤
set Unicode_Result=29924
exit/b
:Unicode22756
set Unicode_Result=壤
exit/b
:Unicode壤
set Unicode_Result=22756
exit/b
:Unicode25880
set Unicode_Result=攘
exit/b
:Unicode攘
set Unicode_Result=25880
exit/b
:Unicode22199
set Unicode_Result=嚷
exit/b
:Unicode嚷
set Unicode_Result=22199
exit/b
:Unicode35753
set Unicode_Result=让
exit/b
:Unicode让
set Unicode_Result=35753
exit/b
:Unicode39286
set Unicode_Result=饶
exit/b
:Unicode饶
set Unicode_Result=39286
exit/b
:Unicode25200
set Unicode_Result=扰
exit/b
:Unicode扰
set Unicode_Result=25200
exit/b
:Unicode32469
set Unicode_Result=绕
exit/b
:Unicode绕
set Unicode_Result=32469
exit/b
:Unicode24825
set Unicode_Result=惹
exit/b
:Unicode惹
set Unicode_Result=24825
exit/b
:Unicode28909
set Unicode_Result=热
exit/b
:Unicode热
set Unicode_Result=28909
exit/b
:Unicode22764
set Unicode_Result=壬
exit/b
:Unicode壬
set Unicode_Result=22764
exit/b
:Unicode20161
set Unicode_Result=仁
exit/b
:Unicode仁
set Unicode_Result=20161
exit/b
:Unicode20154
set Unicode_Result=人
exit/b
:Unicode人
set Unicode_Result=20154
exit/b
:Unicode24525
set Unicode_Result=忍
exit/b
:Unicode忍
set Unicode_Result=24525
exit/b
:Unicode38887
set Unicode_Result=韧
exit/b
:Unicode韧
set Unicode_Result=38887
exit/b
:Unicode20219
set Unicode_Result=任
exit/b
:Unicode任
set Unicode_Result=20219
exit/b
:Unicode35748
set Unicode_Result=认
exit/b
:Unicode认
set Unicode_Result=35748
exit/b
:Unicode20995
set Unicode_Result=刃
exit/b
:Unicode刃
set Unicode_Result=20995
exit/b
:Unicode22922
set Unicode_Result=妊
exit/b
:Unicode妊
set Unicode_Result=22922
exit/b
:Unicode32427
set Unicode_Result=纫
exit/b
:Unicode纫
set Unicode_Result=32427
exit/b
:Unicode25172
set Unicode_Result=扔
exit/b
:Unicode扔
set Unicode_Result=25172
exit/b
:Unicode20173
set Unicode_Result=仍
exit/b
:Unicode仍
set Unicode_Result=20173
exit/b
:Unicode26085
set Unicode_Result=日
exit/b
:Unicode日
set Unicode_Result=26085
exit/b
:Unicode25102
set Unicode_Result=戎
exit/b
:Unicode戎
set Unicode_Result=25102
exit/b
:Unicode33592
set Unicode_Result=茸
exit/b
:Unicode茸
set Unicode_Result=33592
exit/b
:Unicode33993
set Unicode_Result=蓉
exit/b
:Unicode蓉
set Unicode_Result=33993
exit/b
:Unicode33635
set Unicode_Result=荣
exit/b
:Unicode荣
set Unicode_Result=33635
exit/b
:Unicode34701
set Unicode_Result=融
exit/b
:Unicode融
set Unicode_Result=34701
exit/b
:Unicode29076
set Unicode_Result=熔
exit/b
:Unicode熔
set Unicode_Result=29076
exit/b
:Unicode28342
set Unicode_Result=溶
exit/b
:Unicode溶
set Unicode_Result=28342
exit/b
:Unicode23481
set Unicode_Result=容
exit/b
:Unicode容
set Unicode_Result=23481
exit/b
:Unicode32466
set Unicode_Result=绒
exit/b
:Unicode绒
set Unicode_Result=32466
exit/b
:Unicode20887
set Unicode_Result=冗
exit/b
:Unicode冗
set Unicode_Result=20887
exit/b
:Unicode25545
set Unicode_Result=揉
exit/b
:Unicode揉
set Unicode_Result=25545
exit/b
:Unicode26580
set Unicode_Result=柔
exit/b
:Unicode柔
set Unicode_Result=26580
exit/b
:Unicode32905
set Unicode_Result=肉
exit/b
:Unicode肉
set Unicode_Result=32905
exit/b
:Unicode33593
set Unicode_Result=茹
exit/b
:Unicode茹
set Unicode_Result=33593
exit/b
:Unicode34837
set Unicode_Result=蠕
exit/b
:Unicode蠕
set Unicode_Result=34837
exit/b
:Unicode20754
set Unicode_Result=儒
exit/b
:Unicode儒
set Unicode_Result=20754
exit/b
:Unicode23418
set Unicode_Result=孺
exit/b
:Unicode孺
set Unicode_Result=23418
exit/b
:Unicode22914
set Unicode_Result=如
exit/b
:Unicode如
set Unicode_Result=22914
exit/b
:Unicode36785
set Unicode_Result=辱
exit/b
:Unicode辱
set Unicode_Result=36785
exit/b
:Unicode20083
set Unicode_Result=乳
exit/b
:Unicode乳
set Unicode_Result=20083
exit/b
:Unicode27741
set Unicode_Result=汝
exit/b
:Unicode汝
set Unicode_Result=27741
exit/b
:Unicode20837
set Unicode_Result=入
exit/b
:Unicode入
set Unicode_Result=20837
exit/b
:Unicode35109
set Unicode_Result=褥
exit/b
:Unicode褥
set Unicode_Result=35109
exit/b
:Unicode36719
set Unicode_Result=软
exit/b
:Unicode软
set Unicode_Result=36719
exit/b
:Unicode38446
set Unicode_Result=阮
exit/b
:Unicode阮
set Unicode_Result=38446
exit/b
:Unicode34122
set Unicode_Result=蕊
exit/b
:Unicode蕊
set Unicode_Result=34122
exit/b
:Unicode29790
set Unicode_Result=瑞
exit/b
:Unicode瑞
set Unicode_Result=29790
exit/b
:Unicode38160
set Unicode_Result=锐
exit/b
:Unicode锐
set Unicode_Result=38160
exit/b
:Unicode38384
set Unicode_Result=闰
exit/b
:Unicode闰
set Unicode_Result=38384
exit/b
:Unicode28070
set Unicode_Result=润
exit/b
:Unicode润
set Unicode_Result=28070
exit/b
:Unicode33509
set Unicode_Result=若
exit/b
:Unicode若
set Unicode_Result=33509
exit/b
:Unicode24369
set Unicode_Result=弱
exit/b
:Unicode弱
set Unicode_Result=24369
exit/b
:Unicode25746
set Unicode_Result=撒
exit/b
:Unicode撒
set Unicode_Result=25746
exit/b
:Unicode27922
set Unicode_Result=洒
exit/b
:Unicode洒
set Unicode_Result=27922
exit/b
:Unicode33832
set Unicode_Result=萨
exit/b
:Unicode萨
set Unicode_Result=33832
exit/b
:Unicode33134
set Unicode_Result=腮
exit/b
:Unicode腮
set Unicode_Result=33134
exit/b
:Unicode40131
set Unicode_Result=鳃
exit/b
:Unicode鳃
set Unicode_Result=40131
exit/b
:Unicode22622
set Unicode_Result=塞
exit/b
:Unicode塞
set Unicode_Result=22622
exit/b
:Unicode36187
set Unicode_Result=赛
exit/b
:Unicode赛
set Unicode_Result=36187
exit/b
:Unicode19977
set Unicode_Result=三
exit/b
:Unicode三
set Unicode_Result=19977
exit/b
:Unicode21441
set Unicode_Result=叁
exit/b
:Unicode叁
set Unicode_Result=21441
exit/b
:Unicode20254
set Unicode_Result=伞
exit/b
:Unicode伞
set Unicode_Result=20254
exit/b
:Unicode25955
set Unicode_Result=散
exit/b
:Unicode散
set Unicode_Result=25955
exit/b
:Unicode26705
set Unicode_Result=桑
exit/b
:Unicode桑
set Unicode_Result=26705
exit/b
:Unicode21971
set Unicode_Result=嗓
exit/b
:Unicode嗓
set Unicode_Result=21971
exit/b
:Unicode20007
set Unicode_Result=丧
exit/b
:Unicode丧
set Unicode_Result=20007
exit/b
:Unicode25620
set Unicode_Result=搔
exit/b
:Unicode搔
set Unicode_Result=25620
exit/b
:Unicode39578
set Unicode_Result=骚
exit/b
:Unicode骚
set Unicode_Result=39578
exit/b
:Unicode25195
set Unicode_Result=扫
exit/b
:Unicode扫
set Unicode_Result=25195
exit/b
:Unicode23234
set Unicode_Result=嫂
exit/b
:Unicode嫂
set Unicode_Result=23234
exit/b
:Unicode29791
set Unicode_Result=瑟
exit/b
:Unicode瑟
set Unicode_Result=29791
exit/b
:Unicode33394
set Unicode_Result=色
exit/b
:Unicode色
set Unicode_Result=33394
exit/b
:Unicode28073
set Unicode_Result=涩
exit/b
:Unicode涩
set Unicode_Result=28073
exit/b
:Unicode26862
set Unicode_Result=森
exit/b
:Unicode森
set Unicode_Result=26862
exit/b
:Unicode20711
set Unicode_Result=僧
exit/b
:Unicode僧
set Unicode_Result=20711
exit/b
:Unicode33678
set Unicode_Result=莎
exit/b
:Unicode莎
set Unicode_Result=33678
exit/b
:Unicode30722
set Unicode_Result=砂
exit/b
:Unicode砂
set Unicode_Result=30722
exit/b
:Unicode26432
set Unicode_Result=杀
exit/b
:Unicode杀
set Unicode_Result=26432
exit/b
:Unicode21049
set Unicode_Result=刹
exit/b
:Unicode刹
set Unicode_Result=21049
exit/b
:Unicode27801
set Unicode_Result=沙
exit/b
:Unicode沙
set Unicode_Result=27801
exit/b
:Unicode32433
set Unicode_Result=纱
exit/b
:Unicode纱
set Unicode_Result=32433
exit/b
:Unicode20667
set Unicode_Result=傻
exit/b
:Unicode傻
set Unicode_Result=20667
exit/b
:Unicode21861
set Unicode_Result=啥
exit/b
:Unicode啥
set Unicode_Result=21861
exit/b
:Unicode29022
set Unicode_Result=煞
exit/b
:Unicode煞
set Unicode_Result=29022
exit/b
:Unicode31579
set Unicode_Result=筛
exit/b
:Unicode筛
set Unicode_Result=31579
exit/b
:Unicode26194
set Unicode_Result=晒
exit/b
:Unicode晒
set Unicode_Result=26194
exit/b
:Unicode29642
set Unicode_Result=珊
exit/b
:Unicode珊
set Unicode_Result=29642
exit/b
:Unicode33515
set Unicode_Result=苫
exit/b
:Unicode苫
set Unicode_Result=33515
exit/b
:Unicode26441
set Unicode_Result=杉
exit/b
:Unicode杉
set Unicode_Result=26441
exit/b
:Unicode23665
set Unicode_Result=山
exit/b
:Unicode山
set Unicode_Result=23665
exit/b
:Unicode21024
set Unicode_Result=删
exit/b
:Unicode删
set Unicode_Result=21024
exit/b
:Unicode29053
set Unicode_Result=煽
exit/b
:Unicode煽
set Unicode_Result=29053
exit/b
:Unicode34923
set Unicode_Result=衫
exit/b
:Unicode衫
set Unicode_Result=34923
exit/b
:Unicode38378
set Unicode_Result=闪
exit/b
:Unicode闪
set Unicode_Result=38378
exit/b
:Unicode38485
set Unicode_Result=陕
exit/b
:Unicode陕
set Unicode_Result=38485
exit/b
:Unicode25797
set Unicode_Result=擅
exit/b
:Unicode擅
set Unicode_Result=25797
exit/b
:Unicode36193
set Unicode_Result=赡
exit/b
:Unicode赡
set Unicode_Result=36193
exit/b
:Unicode33203
set Unicode_Result=膳
exit/b
:Unicode膳
set Unicode_Result=33203
exit/b
:Unicode21892
set Unicode_Result=善
exit/b
:Unicode善
set Unicode_Result=21892
exit/b
:Unicode27733
set Unicode_Result=汕
exit/b
:Unicode汕
set Unicode_Result=27733
exit/b
:Unicode25159
set Unicode_Result=扇
exit/b
:Unicode扇
set Unicode_Result=25159
exit/b
:Unicode32558
set Unicode_Result=缮
exit/b
:Unicode缮
set Unicode_Result=32558
exit/b
:Unicode22674
set Unicode_Result=墒
exit/b
:Unicode墒
set Unicode_Result=22674
exit/b
:Unicode20260
set Unicode_Result=伤
exit/b
:Unicode伤
set Unicode_Result=20260
exit/b
:Unicode21830
set Unicode_Result=商
exit/b
:Unicode商
set Unicode_Result=21830
exit/b
:Unicode36175
set Unicode_Result=赏
exit/b
:Unicode赏
set Unicode_Result=36175
exit/b
:Unicode26188
set Unicode_Result=晌
exit/b
:Unicode晌
set Unicode_Result=26188
exit/b
:Unicode19978
set Unicode_Result=上
exit/b
:Unicode上
set Unicode_Result=19978
exit/b
:Unicode23578
set Unicode_Result=尚
exit/b
:Unicode尚
set Unicode_Result=23578
exit/b
:Unicode35059
set Unicode_Result=裳
exit/b
:Unicode裳
set Unicode_Result=35059
exit/b
:Unicode26786
set Unicode_Result=梢
exit/b
:Unicode梢
set Unicode_Result=26786
exit/b
:Unicode25422
set Unicode_Result=捎
exit/b
:Unicode捎
set Unicode_Result=25422
exit/b
:Unicode31245
set Unicode_Result=稍
exit/b
:Unicode稍
set Unicode_Result=31245
exit/b
:Unicode28903
set Unicode_Result=烧
exit/b
:Unicode烧
set Unicode_Result=28903
exit/b
:Unicode33421
set Unicode_Result=芍
exit/b
:Unicode芍
set Unicode_Result=33421
exit/b
:Unicode21242
set Unicode_Result=勺
exit/b
:Unicode勺
set Unicode_Result=21242
exit/b
:Unicode38902
set Unicode_Result=韶
exit/b
:Unicode韶
set Unicode_Result=38902
exit/b
:Unicode23569
set Unicode_Result=少
exit/b
:Unicode少
set Unicode_Result=23569
exit/b
:Unicode21736
set Unicode_Result=哨
exit/b
:Unicode哨
set Unicode_Result=21736
exit/b
:Unicode37045
set Unicode_Result=邵
exit/b
:Unicode邵
set Unicode_Result=37045
exit/b
:Unicode32461
set Unicode_Result=绍
exit/b
:Unicode绍
set Unicode_Result=32461
exit/b
:Unicode22882
set Unicode_Result=奢
exit/b
:Unicode奢
set Unicode_Result=22882
exit/b
:Unicode36170
set Unicode_Result=赊
exit/b
:Unicode赊
set Unicode_Result=36170
exit/b
:Unicode34503
set Unicode_Result=蛇
exit/b
:Unicode蛇
set Unicode_Result=34503
exit/b
:Unicode33292
set Unicode_Result=舌
exit/b
:Unicode舌
set Unicode_Result=33292
exit/b
:Unicode33293
set Unicode_Result=舍
exit/b
:Unicode舍
set Unicode_Result=33293
exit/b
:Unicode36198
set Unicode_Result=赦
exit/b
:Unicode赦
set Unicode_Result=36198
exit/b
:Unicode25668
set Unicode_Result=摄
exit/b
:Unicode摄
set Unicode_Result=25668
exit/b
:Unicode23556
set Unicode_Result=射
exit/b
:Unicode射
set Unicode_Result=23556
exit/b
:Unicode24913
set Unicode_Result=慑
exit/b
:Unicode慑
set Unicode_Result=24913
exit/b
:Unicode28041
set Unicode_Result=涉
exit/b
:Unicode涉
set Unicode_Result=28041
exit/b
:Unicode31038
set Unicode_Result=社
exit/b
:Unicode社
set Unicode_Result=31038
exit/b
:Unicode35774
set Unicode_Result=设
exit/b
:Unicode设
set Unicode_Result=35774
exit/b
:Unicode30775
set Unicode_Result=砷
exit/b
:Unicode砷
set Unicode_Result=30775
exit/b
:Unicode30003
set Unicode_Result=申
exit/b
:Unicode申
set Unicode_Result=30003
exit/b
:Unicode21627
set Unicode_Result=呻
exit/b
:Unicode呻
set Unicode_Result=21627
exit/b
:Unicode20280
set Unicode_Result=伸
exit/b
:Unicode伸
set Unicode_Result=20280
exit/b
:Unicode36523
set Unicode_Result=身
exit/b
:Unicode身
set Unicode_Result=36523
exit/b
:Unicode28145
set Unicode_Result=深
exit/b
:Unicode深
set Unicode_Result=28145
exit/b
:Unicode23072
set Unicode_Result=娠
exit/b
:Unicode娠
set Unicode_Result=23072
exit/b
:Unicode32453
set Unicode_Result=绅
exit/b
:Unicode绅
set Unicode_Result=32453
exit/b
:Unicode31070
set Unicode_Result=神
exit/b
:Unicode神
set Unicode_Result=31070
exit/b
:Unicode27784
set Unicode_Result=沈
exit/b
:Unicode沈
set Unicode_Result=27784
exit/b
:Unicode23457
set Unicode_Result=审
exit/b
:Unicode审
set Unicode_Result=23457
exit/b
:Unicode23158
set Unicode_Result=婶
exit/b
:Unicode婶
set Unicode_Result=23158
exit/b
:Unicode29978
set Unicode_Result=甚
exit/b
:Unicode甚
set Unicode_Result=29978
exit/b
:Unicode32958
set Unicode_Result=肾
exit/b
:Unicode肾
set Unicode_Result=32958
exit/b
:Unicode24910
set Unicode_Result=慎
exit/b
:Unicode慎
set Unicode_Result=24910
exit/b
:Unicode28183
set Unicode_Result=渗
exit/b
:Unicode渗
set Unicode_Result=28183
exit/b
:Unicode22768
set Unicode_Result=声
exit/b
:Unicode声
set Unicode_Result=22768
exit/b
:Unicode29983
set Unicode_Result=生
exit/b
:Unicode生
set Unicode_Result=29983
exit/b
:Unicode29989
set Unicode_Result=甥
exit/b
:Unicode甥
set Unicode_Result=29989
exit/b
:Unicode29298
set Unicode_Result=牲
exit/b
:Unicode牲
set Unicode_Result=29298
exit/b
:Unicode21319
set Unicode_Result=升
exit/b
:Unicode升
set Unicode_Result=21319
exit/b
:Unicode32499
set Unicode_Result=绳
exit/b
:Unicode绳
set Unicode_Result=32499
exit/b
:Unicode30465
set Unicode_Result=省
exit/b
:Unicode省
set Unicode_Result=30465
exit/b
:Unicode30427
set Unicode_Result=盛
exit/b
:Unicode盛
set Unicode_Result=30427
exit/b
:Unicode21097
set Unicode_Result=剩
exit/b
:Unicode剩
set Unicode_Result=21097
exit/b
:Unicode32988
set Unicode_Result=胜
exit/b
:Unicode胜
set Unicode_Result=32988
exit/b
:Unicode22307
set Unicode_Result=圣
exit/b
:Unicode圣
set Unicode_Result=22307
exit/b
:Unicode24072
set Unicode_Result=师
exit/b
:Unicode师
set Unicode_Result=24072
exit/b
:Unicode22833
set Unicode_Result=失
exit/b
:Unicode失
set Unicode_Result=22833
exit/b
:Unicode29422
set Unicode_Result=狮
exit/b
:Unicode狮
set Unicode_Result=29422
exit/b
:Unicode26045
set Unicode_Result=施
exit/b
:Unicode施
set Unicode_Result=26045
exit/b
:Unicode28287
set Unicode_Result=湿
exit/b
:Unicode湿
set Unicode_Result=28287
exit/b
:Unicode35799
set Unicode_Result=诗
exit/b
:Unicode诗
set Unicode_Result=35799
exit/b
:Unicode23608
set Unicode_Result=尸
exit/b
:Unicode尸
set Unicode_Result=23608
exit/b
:Unicode34417
set Unicode_Result=虱
exit/b
:Unicode虱
set Unicode_Result=34417
exit/b
:Unicode21313
set Unicode_Result=十
exit/b
:Unicode十
set Unicode_Result=21313
exit/b
:Unicode30707
set Unicode_Result=石
exit/b
:Unicode石
set Unicode_Result=30707
exit/b
:Unicode25342
set Unicode_Result=拾
exit/b
:Unicode拾
set Unicode_Result=25342
exit/b
:Unicode26102
set Unicode_Result=时
exit/b
:Unicode时
set Unicode_Result=26102
exit/b
:Unicode20160
set Unicode_Result=什
exit/b
:Unicode什
set Unicode_Result=20160
exit/b
:Unicode39135
set Unicode_Result=食
exit/b
:Unicode食
set Unicode_Result=39135
exit/b
:Unicode34432
set Unicode_Result=蚀
exit/b
:Unicode蚀
set Unicode_Result=34432
exit/b
:Unicode23454
set Unicode_Result=实
exit/b
:Unicode实
set Unicode_Result=23454
exit/b
:Unicode35782
set Unicode_Result=识
exit/b
:Unicode识
set Unicode_Result=35782
exit/b
:Unicode21490
set Unicode_Result=史
exit/b
:Unicode史
set Unicode_Result=21490
exit/b
:Unicode30690
set Unicode_Result=矢
exit/b
:Unicode矢
set Unicode_Result=30690
exit/b
:Unicode20351
set Unicode_Result=使
exit/b
:Unicode使
set Unicode_Result=20351
exit/b
:Unicode23630
set Unicode_Result=屎
exit/b
:Unicode屎
set Unicode_Result=23630
exit/b
:Unicode39542
set Unicode_Result=驶
exit/b
:Unicode驶
set Unicode_Result=39542
exit/b
:Unicode22987
set Unicode_Result=始
exit/b
:Unicode始
set Unicode_Result=22987
exit/b
:Unicode24335
set Unicode_Result=式
exit/b
:Unicode式
set Unicode_Result=24335
exit/b
:Unicode31034
set Unicode_Result=示
exit/b
:Unicode示
set Unicode_Result=31034
exit/b
:Unicode22763
set Unicode_Result=士
exit/b
:Unicode士
set Unicode_Result=22763
exit/b
:Unicode19990
set Unicode_Result=世
exit/b
:Unicode世
set Unicode_Result=19990
exit/b
:Unicode26623
set Unicode_Result=柿
exit/b
:Unicode柿
set Unicode_Result=26623
exit/b
:Unicode20107
set Unicode_Result=事
exit/b
:Unicode事
set Unicode_Result=20107
exit/b
:Unicode25325
set Unicode_Result=拭
exit/b
:Unicode拭
set Unicode_Result=25325
exit/b
:Unicode35475
set Unicode_Result=誓
exit/b
:Unicode誓
set Unicode_Result=35475
exit/b
:Unicode36893
set Unicode_Result=逝
exit/b
:Unicode逝
set Unicode_Result=36893
exit/b
:Unicode21183
set Unicode_Result=势
exit/b
:Unicode势
set Unicode_Result=21183
exit/b
:Unicode26159
set Unicode_Result=是
exit/b
:Unicode是
set Unicode_Result=26159
exit/b
:Unicode21980
set Unicode_Result=嗜
exit/b
:Unicode嗜
set Unicode_Result=21980
exit/b
:Unicode22124
set Unicode_Result=噬
exit/b
:Unicode噬
set Unicode_Result=22124
exit/b
:Unicode36866
set Unicode_Result=适
exit/b
:Unicode适
set Unicode_Result=36866
exit/b
:Unicode20181
set Unicode_Result=仕
exit/b
:Unicode仕
set Unicode_Result=20181
exit/b
:Unicode20365
set Unicode_Result=侍
exit/b
:Unicode侍
set Unicode_Result=20365
exit/b
:Unicode37322
set Unicode_Result=释
exit/b
:Unicode释
set Unicode_Result=37322
exit/b
:Unicode39280
set Unicode_Result=饰
exit/b
:Unicode饰
set Unicode_Result=39280
exit/b
:Unicode27663
set Unicode_Result=氏
exit/b
:Unicode氏
set Unicode_Result=27663
exit/b
:Unicode24066
set Unicode_Result=市
exit/b
:Unicode市
set Unicode_Result=24066
exit/b
:Unicode24643
set Unicode_Result=恃
exit/b
:Unicode恃
set Unicode_Result=24643
exit/b
:Unicode23460
set Unicode_Result=室
exit/b
:Unicode室
set Unicode_Result=23460
exit/b
:Unicode35270
set Unicode_Result=视
exit/b
:Unicode视
set Unicode_Result=35270
exit/b
:Unicode35797
set Unicode_Result=试
exit/b
:Unicode试
set Unicode_Result=35797
exit/b
:Unicode25910
set Unicode_Result=收
exit/b
:Unicode收
set Unicode_Result=25910
exit/b
:Unicode25163
set Unicode_Result=手
exit/b
:Unicode手
set Unicode_Result=25163
exit/b
:Unicode39318
set Unicode_Result=首
exit/b
:Unicode首
set Unicode_Result=39318
exit/b
:Unicode23432
set Unicode_Result=守
exit/b
:Unicode守
set Unicode_Result=23432
exit/b
:Unicode23551
set Unicode_Result=寿
exit/b
:Unicode寿
set Unicode_Result=23551
exit/b
:Unicode25480
set Unicode_Result=授
exit/b
:Unicode授
set Unicode_Result=25480
exit/b
:Unicode21806
set Unicode_Result=售
exit/b
:Unicode售
set Unicode_Result=21806
exit/b
:Unicode21463
set Unicode_Result=受
exit/b
:Unicode受
set Unicode_Result=21463
exit/b
:Unicode30246
set Unicode_Result=瘦
exit/b
:Unicode瘦
set Unicode_Result=30246
exit/b
:Unicode20861
set Unicode_Result=兽
exit/b
:Unicode兽
set Unicode_Result=20861
exit/b
:Unicode34092
set Unicode_Result=蔬
exit/b
:Unicode蔬
set Unicode_Result=34092
exit/b
:Unicode26530
set Unicode_Result=枢
exit/b
:Unicode枢
set Unicode_Result=26530
exit/b
:Unicode26803
set Unicode_Result=梳
exit/b
:Unicode梳
set Unicode_Result=26803
exit/b
:Unicode27530
set Unicode_Result=殊
exit/b
:Unicode殊
set Unicode_Result=27530
exit/b
:Unicode25234
set Unicode_Result=抒
exit/b
:Unicode抒
set Unicode_Result=25234
exit/b
:Unicode36755
set Unicode_Result=输
exit/b
:Unicode输
set Unicode_Result=36755
exit/b
:Unicode21460
set Unicode_Result=叔
exit/b
:Unicode叔
set Unicode_Result=21460
exit/b
:Unicode33298
set Unicode_Result=舒
exit/b
:Unicode舒
set Unicode_Result=33298
exit/b
:Unicode28113
set Unicode_Result=淑
exit/b
:Unicode淑
set Unicode_Result=28113
exit/b
:Unicode30095
set Unicode_Result=疏
exit/b
:Unicode疏
set Unicode_Result=30095
exit/b
:Unicode20070
set Unicode_Result=书
exit/b
:Unicode书
set Unicode_Result=20070
exit/b
:Unicode36174
set Unicode_Result=赎
exit/b
:Unicode赎
set Unicode_Result=36174
exit/b
:Unicode23408
set Unicode_Result=孰
exit/b
:Unicode孰
set Unicode_Result=23408
exit/b
:Unicode29087
set Unicode_Result=熟
exit/b
:Unicode熟
set Unicode_Result=29087
exit/b
:Unicode34223
set Unicode_Result=薯
exit/b
:Unicode薯
set Unicode_Result=34223
exit/b
:Unicode26257
set Unicode_Result=暑
exit/b
:Unicode暑
set Unicode_Result=26257
exit/b
:Unicode26329
set Unicode_Result=曙
exit/b
:Unicode曙
set Unicode_Result=26329
exit/b
:Unicode32626
set Unicode_Result=署
exit/b
:Unicode署
set Unicode_Result=32626
exit/b
:Unicode34560
set Unicode_Result=蜀
exit/b
:Unicode蜀
set Unicode_Result=34560
exit/b
:Unicode40653
set Unicode_Result=黍
exit/b
:Unicode黍
set Unicode_Result=40653
exit/b
:Unicode40736
set Unicode_Result=鼠
exit/b
:Unicode鼠
set Unicode_Result=40736
exit/b
:Unicode23646
set Unicode_Result=属
exit/b
:Unicode属
set Unicode_Result=23646
exit/b
:Unicode26415
set Unicode_Result=术
exit/b
:Unicode术
set Unicode_Result=26415
exit/b
:Unicode36848
set Unicode_Result=述
exit/b
:Unicode述
set Unicode_Result=36848
exit/b
:Unicode26641
set Unicode_Result=树
exit/b
:Unicode树
set Unicode_Result=26641
exit/b
:Unicode26463
set Unicode_Result=束
exit/b
:Unicode束
set Unicode_Result=26463
exit/b
:Unicode25101
set Unicode_Result=戍
exit/b
:Unicode戍
set Unicode_Result=25101
exit/b
:Unicode31446
set Unicode_Result=竖
exit/b
:Unicode竖
set Unicode_Result=31446
exit/b
:Unicode22661
set Unicode_Result=墅
exit/b
:Unicode墅
set Unicode_Result=22661
exit/b
:Unicode24246
set Unicode_Result=庶
exit/b
:Unicode庶
set Unicode_Result=24246
exit/b
:Unicode25968
set Unicode_Result=数
exit/b
:Unicode数
set Unicode_Result=25968
exit/b
:Unicode28465
set Unicode_Result=漱
exit/b
:Unicode漱
set Unicode_Result=28465
exit/b
:Unicode24661
set Unicode_Result=恕
exit/b
:Unicode恕
set Unicode_Result=24661
exit/b
:Unicode21047
set Unicode_Result=刷
exit/b
:Unicode刷
set Unicode_Result=21047
exit/b
:Unicode32781
set Unicode_Result=耍
exit/b
:Unicode耍
set Unicode_Result=32781
exit/b
:Unicode25684
set Unicode_Result=摔
exit/b
:Unicode摔
set Unicode_Result=25684
exit/b
:Unicode34928
set Unicode_Result=衰
exit/b
:Unicode衰
set Unicode_Result=34928
exit/b
:Unicode29993
set Unicode_Result=甩
exit/b
:Unicode甩
set Unicode_Result=29993
exit/b
:Unicode24069
set Unicode_Result=帅
exit/b
:Unicode帅
set Unicode_Result=24069
exit/b
:Unicode26643
set Unicode_Result=栓
exit/b
:Unicode栓
set Unicode_Result=26643
exit/b
:Unicode25332
set Unicode_Result=拴
exit/b
:Unicode拴
set Unicode_Result=25332
exit/b
:Unicode38684
set Unicode_Result=霜
exit/b
:Unicode霜
set Unicode_Result=38684
exit/b
:Unicode21452
set Unicode_Result=双
exit/b
:Unicode双
set Unicode_Result=21452
exit/b
:Unicode29245
set Unicode_Result=爽
exit/b
:Unicode爽
set Unicode_Result=29245
exit/b
:Unicode35841
set Unicode_Result=谁
exit/b
:Unicode谁
set Unicode_Result=35841
exit/b
:Unicode27700
set Unicode_Result=水
exit/b
:Unicode水
set Unicode_Result=27700
exit/b
:Unicode30561
set Unicode_Result=睡
exit/b
:Unicode睡
set Unicode_Result=30561
exit/b
:Unicode31246
set Unicode_Result=税
exit/b
:Unicode税
set Unicode_Result=31246
exit/b
:Unicode21550
set Unicode_Result=吮
exit/b
:Unicode吮
set Unicode_Result=21550
exit/b
:Unicode30636
set Unicode_Result=瞬
exit/b
:Unicode瞬
set Unicode_Result=30636
exit/b
:Unicode39034
set Unicode_Result=顺
exit/b
:Unicode顺
set Unicode_Result=39034
exit/b
:Unicode33308
set Unicode_Result=舜
exit/b
:Unicode舜
set Unicode_Result=33308
exit/b
:Unicode35828
set Unicode_Result=说
exit/b
:Unicode说
set Unicode_Result=35828
exit/b
:Unicode30805
set Unicode_Result=硕
exit/b
:Unicode硕
set Unicode_Result=30805
exit/b
:Unicode26388
set Unicode_Result=朔
exit/b
:Unicode朔
set Unicode_Result=26388
exit/b
:Unicode28865
set Unicode_Result=烁
exit/b
:Unicode烁
set Unicode_Result=28865
exit/b
:Unicode26031
set Unicode_Result=斯
exit/b
:Unicode斯
set Unicode_Result=26031
exit/b
:Unicode25749
set Unicode_Result=撕
exit/b
:Unicode撕
set Unicode_Result=25749
exit/b
:Unicode22070
set Unicode_Result=嘶
exit/b
:Unicode嘶
set Unicode_Result=22070
exit/b
:Unicode24605
set Unicode_Result=思
exit/b
:Unicode思
set Unicode_Result=24605
exit/b
:Unicode31169
set Unicode_Result=私
exit/b
:Unicode私
set Unicode_Result=31169
exit/b
:Unicode21496
set Unicode_Result=司
exit/b
:Unicode司
set Unicode_Result=21496
exit/b
:Unicode19997
set Unicode_Result=丝
exit/b
:Unicode丝
set Unicode_Result=19997
exit/b
:Unicode27515
set Unicode_Result=死
exit/b
:Unicode死
set Unicode_Result=27515
exit/b
:Unicode32902
set Unicode_Result=肆
exit/b
:Unicode肆
set Unicode_Result=32902
exit/b
:Unicode23546
set Unicode_Result=寺
exit/b
:Unicode寺
set Unicode_Result=23546
exit/b
:Unicode21987
set Unicode_Result=嗣
exit/b
:Unicode嗣
set Unicode_Result=21987
exit/b
:Unicode22235
set Unicode_Result=四
exit/b
:Unicode四
set Unicode_Result=22235
exit/b
:Unicode20282
set Unicode_Result=伺
exit/b
:Unicode伺
set Unicode_Result=20282
exit/b
:Unicode20284
set Unicode_Result=似
exit/b
:Unicode似
set Unicode_Result=20284
exit/b
:Unicode39282
set Unicode_Result=饲
exit/b
:Unicode饲
set Unicode_Result=39282
exit/b
:Unicode24051
set Unicode_Result=巳
exit/b
:Unicode巳
set Unicode_Result=24051
exit/b
:Unicode26494
set Unicode_Result=松
exit/b
:Unicode松
set Unicode_Result=26494
exit/b
:Unicode32824
set Unicode_Result=耸
exit/b
:Unicode耸
set Unicode_Result=32824
exit/b
:Unicode24578
set Unicode_Result=怂
exit/b
:Unicode怂
set Unicode_Result=24578
exit/b
:Unicode39042
set Unicode_Result=颂
exit/b
:Unicode颂
set Unicode_Result=39042
exit/b
:Unicode36865
set Unicode_Result=送
exit/b
:Unicode送
set Unicode_Result=36865
exit/b
:Unicode23435
set Unicode_Result=宋
exit/b
:Unicode宋
set Unicode_Result=23435
exit/b
:Unicode35772
set Unicode_Result=讼
exit/b
:Unicode讼
set Unicode_Result=35772
exit/b
:Unicode35829
set Unicode_Result=诵
exit/b
:Unicode诵
set Unicode_Result=35829
exit/b
:Unicode25628
set Unicode_Result=搜
exit/b
:Unicode搜
set Unicode_Result=25628
exit/b
:Unicode33368
set Unicode_Result=艘
exit/b
:Unicode艘
set Unicode_Result=33368
exit/b
:Unicode25822
set Unicode_Result=擞
exit/b
:Unicode擞
set Unicode_Result=25822
exit/b
:Unicode22013
set Unicode_Result=嗽
exit/b
:Unicode嗽
set Unicode_Result=22013
exit/b
:Unicode33487
set Unicode_Result=苏
exit/b
:Unicode苏
set Unicode_Result=33487
exit/b
:Unicode37221
set Unicode_Result=酥
exit/b
:Unicode酥
set Unicode_Result=37221
exit/b
:Unicode20439
set Unicode_Result=俗
exit/b
:Unicode俗
set Unicode_Result=20439
exit/b
:Unicode32032
set Unicode_Result=素
exit/b
:Unicode素
set Unicode_Result=32032
exit/b
:Unicode36895
set Unicode_Result=速
exit/b
:Unicode速
set Unicode_Result=36895
exit/b
:Unicode31903
set Unicode_Result=粟
exit/b
:Unicode粟
set Unicode_Result=31903
exit/b
:Unicode20723
set Unicode_Result=僳
exit/b
:Unicode僳
set Unicode_Result=20723
exit/b
:Unicode22609
set Unicode_Result=塑
exit/b
:Unicode塑
set Unicode_Result=22609
exit/b
:Unicode28335
set Unicode_Result=溯
exit/b
:Unicode溯
set Unicode_Result=28335
exit/b
:Unicode23487
set Unicode_Result=宿
exit/b
:Unicode宿
set Unicode_Result=23487
exit/b
:Unicode35785
set Unicode_Result=诉
exit/b
:Unicode诉
set Unicode_Result=35785
exit/b
:Unicode32899
set Unicode_Result=肃
exit/b
:Unicode肃
set Unicode_Result=32899
exit/b
:Unicode37240
set Unicode_Result=酸
exit/b
:Unicode酸
set Unicode_Result=37240
exit/b
:Unicode33948
set Unicode_Result=蒜
exit/b
:Unicode蒜
set Unicode_Result=33948
exit/b
:Unicode31639
set Unicode_Result=算
exit/b
:Unicode算
set Unicode_Result=31639
exit/b
:Unicode34429
set Unicode_Result=虽
exit/b
:Unicode虽
set Unicode_Result=34429
exit/b
:Unicode38539
set Unicode_Result=隋
exit/b
:Unicode隋
set Unicode_Result=38539
exit/b
:Unicode38543
set Unicode_Result=随
exit/b
:Unicode随
set Unicode_Result=38543
exit/b
:Unicode32485
set Unicode_Result=绥
exit/b
:Unicode绥
set Unicode_Result=32485
exit/b
:Unicode39635
set Unicode_Result=髓
exit/b
:Unicode髓
set Unicode_Result=39635
exit/b
:Unicode30862
set Unicode_Result=碎
exit/b
:Unicode碎
set Unicode_Result=30862
exit/b
:Unicode23681
set Unicode_Result=岁
exit/b
:Unicode岁
set Unicode_Result=23681
exit/b
:Unicode31319
set Unicode_Result=穗
exit/b
:Unicode穗
set Unicode_Result=31319
exit/b
:Unicode36930
set Unicode_Result=遂
exit/b
:Unicode遂
set Unicode_Result=36930
exit/b
:Unicode38567
set Unicode_Result=隧
exit/b
:Unicode隧
set Unicode_Result=38567
exit/b
:Unicode31071
set Unicode_Result=祟
exit/b
:Unicode祟
set Unicode_Result=31071
exit/b
:Unicode23385
set Unicode_Result=孙
exit/b
:Unicode孙
set Unicode_Result=23385
exit/b
:Unicode25439
set Unicode_Result=损
exit/b
:Unicode损
set Unicode_Result=25439
exit/b
:Unicode31499
set Unicode_Result=笋
exit/b
:Unicode笋
set Unicode_Result=31499
exit/b
:Unicode34001
set Unicode_Result=蓑
exit/b
:Unicode蓑
set Unicode_Result=34001
exit/b
:Unicode26797
set Unicode_Result=梭
exit/b
:Unicode梭
set Unicode_Result=26797
exit/b
:Unicode21766
set Unicode_Result=唆
exit/b
:Unicode唆
set Unicode_Result=21766
exit/b
:Unicode32553
set Unicode_Result=缩
exit/b
:Unicode缩
set Unicode_Result=32553
exit/b
:Unicode29712
set Unicode_Result=琐
exit/b
:Unicode琐
set Unicode_Result=29712
exit/b
:Unicode32034
set Unicode_Result=索
exit/b
:Unicode索
set Unicode_Result=32034
exit/b
:Unicode38145
set Unicode_Result=锁
exit/b
:Unicode锁
set Unicode_Result=38145
exit/b
:Unicode25152
set Unicode_Result=所
exit/b
:Unicode所
set Unicode_Result=25152
exit/b
:Unicode22604
set Unicode_Result=塌
exit/b
:Unicode塌
set Unicode_Result=22604
exit/b
:Unicode20182
set Unicode_Result=他
exit/b
:Unicode他
set Unicode_Result=20182
exit/b
:Unicode23427
set Unicode_Result=它
exit/b
:Unicode它
set Unicode_Result=23427
exit/b
:Unicode22905
set Unicode_Result=她
exit/b
:Unicode她
set Unicode_Result=22905
exit/b
:Unicode22612
set Unicode_Result=塔
exit/b
:Unicode塔
set Unicode_Result=22612
exit/b
:Unicode29549
set Unicode_Result=獭
exit/b
:Unicode獭
set Unicode_Result=29549
exit/b
:Unicode25374
set Unicode_Result=挞
exit/b
:Unicode挞
set Unicode_Result=25374
exit/b
:Unicode36427
set Unicode_Result=蹋
exit/b
:Unicode蹋
set Unicode_Result=36427
exit/b
:Unicode36367
set Unicode_Result=踏
exit/b
:Unicode踏
set Unicode_Result=36367
exit/b
:Unicode32974
set Unicode_Result=胎
exit/b
:Unicode胎
set Unicode_Result=32974
exit/b
:Unicode33492
set Unicode_Result=苔
exit/b
:Unicode苔
set Unicode_Result=33492
exit/b
:Unicode25260
set Unicode_Result=抬
exit/b
:Unicode抬
set Unicode_Result=25260
exit/b
:Unicode21488
set Unicode_Result=台
exit/b
:Unicode台
set Unicode_Result=21488
exit/b
:Unicode27888
set Unicode_Result=泰
exit/b
:Unicode泰
set Unicode_Result=27888
exit/b
:Unicode37214
set Unicode_Result=酞
exit/b
:Unicode酞
set Unicode_Result=37214
exit/b
:Unicode22826
set Unicode_Result=太
exit/b
:Unicode太
set Unicode_Result=22826
exit/b
:Unicode24577
set Unicode_Result=态
exit/b
:Unicode态
set Unicode_Result=24577
exit/b
:Unicode27760
set Unicode_Result=汰
exit/b
:Unicode汰
set Unicode_Result=27760
exit/b
:Unicode22349
set Unicode_Result=坍
exit/b
:Unicode坍
set Unicode_Result=22349
exit/b
:Unicode25674
set Unicode_Result=摊
exit/b
:Unicode摊
set Unicode_Result=25674
exit/b
:Unicode36138
set Unicode_Result=贪
exit/b
:Unicode贪
set Unicode_Result=36138
exit/b
:Unicode30251
set Unicode_Result=瘫
exit/b
:Unicode瘫
set Unicode_Result=30251
exit/b
:Unicode28393
set Unicode_Result=滩
exit/b
:Unicode滩
set Unicode_Result=28393
exit/b
:Unicode22363
set Unicode_Result=坛
exit/b
:Unicode坛
set Unicode_Result=22363
exit/b
:Unicode27264
set Unicode_Result=檀
exit/b
:Unicode檀
set Unicode_Result=27264
exit/b
:Unicode30192
set Unicode_Result=痰
exit/b
:Unicode痰
set Unicode_Result=30192
exit/b
:Unicode28525
set Unicode_Result=潭
exit/b
:Unicode潭
set Unicode_Result=28525
exit/b
:Unicode35885
set Unicode_Result=谭
exit/b
:Unicode谭
set Unicode_Result=35885
exit/b
:Unicode35848
set Unicode_Result=谈
exit/b
:Unicode谈
set Unicode_Result=35848
exit/b
:Unicode22374
set Unicode_Result=坦
exit/b
:Unicode坦
set Unicode_Result=22374
exit/b
:Unicode27631
set Unicode_Result=毯
exit/b
:Unicode毯
set Unicode_Result=27631
exit/b
:Unicode34962
set Unicode_Result=袒
exit/b
:Unicode袒
set Unicode_Result=34962
exit/b
:Unicode30899
set Unicode_Result=碳
exit/b
:Unicode碳
set Unicode_Result=30899
exit/b
:Unicode25506
set Unicode_Result=探
exit/b
:Unicode探
set Unicode_Result=25506
exit/b
:Unicode21497
set Unicode_Result=叹
exit/b
:Unicode叹
set Unicode_Result=21497
exit/b
:Unicode28845
set Unicode_Result=炭
exit/b
:Unicode炭
set Unicode_Result=28845
exit/b
:Unicode27748
set Unicode_Result=汤
exit/b
:Unicode汤
set Unicode_Result=27748
exit/b
:Unicode22616
set Unicode_Result=塘
exit/b
:Unicode塘
set Unicode_Result=22616
exit/b
:Unicode25642
set Unicode_Result=搪
exit/b
:Unicode搪
set Unicode_Result=25642
exit/b
:Unicode22530
set Unicode_Result=堂
exit/b
:Unicode堂
set Unicode_Result=22530
exit/b
:Unicode26848
set Unicode_Result=棠
exit/b
:Unicode棠
set Unicode_Result=26848
exit/b
:Unicode33179
set Unicode_Result=膛
exit/b
:Unicode膛
set Unicode_Result=33179
exit/b
:Unicode21776
set Unicode_Result=唐
exit/b
:Unicode唐
set Unicode_Result=21776
exit/b
:Unicode31958
set Unicode_Result=糖
exit/b
:Unicode糖
set Unicode_Result=31958
exit/b
:Unicode20504
set Unicode_Result=倘
exit/b
:Unicode倘
set Unicode_Result=20504
exit/b
:Unicode36538
set Unicode_Result=躺
exit/b
:Unicode躺
set Unicode_Result=36538
exit/b
:Unicode28108
set Unicode_Result=淌
exit/b
:Unicode淌
set Unicode_Result=28108
exit/b
:Unicode36255
set Unicode_Result=趟
exit/b
:Unicode趟
set Unicode_Result=36255
exit/b
:Unicode28907
set Unicode_Result=烫
exit/b
:Unicode烫
set Unicode_Result=28907
exit/b
:Unicode25487
set Unicode_Result=掏
exit/b
:Unicode掏
set Unicode_Result=25487
exit/b
:Unicode28059
set Unicode_Result=涛
exit/b
:Unicode涛
set Unicode_Result=28059
exit/b
:Unicode28372
set Unicode_Result=滔
exit/b
:Unicode滔
set Unicode_Result=28372
exit/b
:Unicode32486
set Unicode_Result=绦
exit/b
:Unicode绦
set Unicode_Result=32486
exit/b
:Unicode33796
set Unicode_Result=萄
exit/b
:Unicode萄
set Unicode_Result=33796
exit/b
:Unicode26691
set Unicode_Result=桃
exit/b
:Unicode桃
set Unicode_Result=26691
exit/b
:Unicode36867
set Unicode_Result=逃
exit/b
:Unicode逃
set Unicode_Result=36867
exit/b
:Unicode28120
set Unicode_Result=淘
exit/b
:Unicode淘
set Unicode_Result=28120
exit/b
:Unicode38518
set Unicode_Result=陶
exit/b
:Unicode陶
set Unicode_Result=38518
exit/b
:Unicode35752
set Unicode_Result=讨
exit/b
:Unicode讨
set Unicode_Result=35752
exit/b
:Unicode22871
set Unicode_Result=套
exit/b
:Unicode套
set Unicode_Result=22871
exit/b
:Unicode29305
set Unicode_Result=特
exit/b
:Unicode特
set Unicode_Result=29305
exit/b
:Unicode34276
set Unicode_Result=藤
exit/b
:Unicode藤
set Unicode_Result=34276
exit/b
:Unicode33150
set Unicode_Result=腾
exit/b
:Unicode腾
set Unicode_Result=33150
exit/b
:Unicode30140
set Unicode_Result=疼
exit/b
:Unicode疼
set Unicode_Result=30140
exit/b
:Unicode35466
set Unicode_Result=誊
exit/b
:Unicode誊
set Unicode_Result=35466
exit/b
:Unicode26799
set Unicode_Result=梯
exit/b
:Unicode梯
set Unicode_Result=26799
exit/b
:Unicode21076
set Unicode_Result=剔
exit/b
:Unicode剔
set Unicode_Result=21076
exit/b
:Unicode36386
set Unicode_Result=踢
exit/b
:Unicode踢
set Unicode_Result=36386
exit/b
:Unicode38161
set Unicode_Result=锑
exit/b
:Unicode锑
set Unicode_Result=38161
exit/b
:Unicode25552
set Unicode_Result=提
exit/b
:Unicode提
set Unicode_Result=25552
exit/b
:Unicode39064
set Unicode_Result=题
exit/b
:Unicode题
set Unicode_Result=39064
exit/b
:Unicode36420
set Unicode_Result=蹄
exit/b
:Unicode蹄
set Unicode_Result=36420
exit/b
:Unicode21884
set Unicode_Result=啼
exit/b
:Unicode啼
set Unicode_Result=21884
exit/b
:Unicode20307
set Unicode_Result=体
exit/b
:Unicode体
set Unicode_Result=20307
exit/b
:Unicode26367
set Unicode_Result=替
exit/b
:Unicode替
set Unicode_Result=26367
exit/b
:Unicode22159
set Unicode_Result=嚏
exit/b
:Unicode嚏
set Unicode_Result=22159
exit/b
:Unicode24789
set Unicode_Result=惕
exit/b
:Unicode惕
set Unicode_Result=24789
exit/b
:Unicode28053
set Unicode_Result=涕
exit/b
:Unicode涕
set Unicode_Result=28053
exit/b
:Unicode21059
set Unicode_Result=剃
exit/b
:Unicode剃
set Unicode_Result=21059
exit/b
:Unicode23625
set Unicode_Result=屉
exit/b
:Unicode屉
set Unicode_Result=23625
exit/b
:Unicode22825
set Unicode_Result=天
exit/b
:Unicode天
set Unicode_Result=22825
exit/b
:Unicode28155
set Unicode_Result=添
exit/b
:Unicode添
set Unicode_Result=28155
exit/b
:Unicode22635
set Unicode_Result=填
exit/b
:Unicode填
set Unicode_Result=22635
exit/b
:Unicode30000
set Unicode_Result=田
exit/b
:Unicode田
set Unicode_Result=30000
exit/b
:Unicode29980
set Unicode_Result=甜
exit/b
:Unicode甜
set Unicode_Result=29980
exit/b
:Unicode24684
set Unicode_Result=恬
exit/b
:Unicode恬
set Unicode_Result=24684
exit/b
:Unicode33300
set Unicode_Result=舔
exit/b
:Unicode舔
set Unicode_Result=33300
exit/b
:Unicode33094
set Unicode_Result=腆
exit/b
:Unicode腆
set Unicode_Result=33094
exit/b
:Unicode25361
set Unicode_Result=挑
exit/b
:Unicode挑
set Unicode_Result=25361
exit/b
:Unicode26465
set Unicode_Result=条
exit/b
:Unicode条
set Unicode_Result=26465
exit/b
:Unicode36834
set Unicode_Result=迢
exit/b
:Unicode迢
set Unicode_Result=36834
exit/b
:Unicode30522
set Unicode_Result=眺
exit/b
:Unicode眺
set Unicode_Result=30522
exit/b
:Unicode36339
set Unicode_Result=跳
exit/b
:Unicode跳
set Unicode_Result=36339
exit/b
:Unicode36148
set Unicode_Result=贴
exit/b
:Unicode贴
set Unicode_Result=36148
exit/b
:Unicode38081
set Unicode_Result=铁
exit/b
:Unicode铁
set Unicode_Result=38081
exit/b
:Unicode24086
set Unicode_Result=帖
exit/b
:Unicode帖
set Unicode_Result=24086
exit/b
:Unicode21381
set Unicode_Result=厅
exit/b
:Unicode厅
set Unicode_Result=21381
exit/b
:Unicode21548
set Unicode_Result=听
exit/b
:Unicode听
set Unicode_Result=21548
exit/b
:Unicode28867
set Unicode_Result=烃
exit/b
:Unicode烃
set Unicode_Result=28867
exit/b
:Unicode27712
set Unicode_Result=汀
exit/b
:Unicode汀
set Unicode_Result=27712
exit/b
:Unicode24311
set Unicode_Result=廷
exit/b
:Unicode廷
set Unicode_Result=24311
exit/b
:Unicode20572
set Unicode_Result=停
exit/b
:Unicode停
set Unicode_Result=20572
exit/b
:Unicode20141
set Unicode_Result=亭
exit/b
:Unicode亭
set Unicode_Result=20141
exit/b
:Unicode24237
set Unicode_Result=庭
exit/b
:Unicode庭
set Unicode_Result=24237
exit/b
:Unicode25402
set Unicode_Result=挺
exit/b
:Unicode挺
set Unicode_Result=25402
exit/b
:Unicode33351
set Unicode_Result=艇
exit/b
:Unicode艇
set Unicode_Result=33351
exit/b
:Unicode36890
set Unicode_Result=通
exit/b
:Unicode通
set Unicode_Result=36890
exit/b
:Unicode26704
set Unicode_Result=桐
exit/b
:Unicode桐
set Unicode_Result=26704
exit/b
:Unicode37230
set Unicode_Result=酮
exit/b
:Unicode酮
set Unicode_Result=37230
exit/b
:Unicode30643
set Unicode_Result=瞳
exit/b
:Unicode瞳
set Unicode_Result=30643
exit/b
:Unicode21516
set Unicode_Result=同
exit/b
:Unicode同
set Unicode_Result=21516
exit/b
:Unicode38108
set Unicode_Result=铜
exit/b
:Unicode铜
set Unicode_Result=38108
exit/b
:Unicode24420
set Unicode_Result=彤
exit/b
:Unicode彤
set Unicode_Result=24420
exit/b
:Unicode31461
set Unicode_Result=童
exit/b
:Unicode童
set Unicode_Result=31461
exit/b
:Unicode26742
set Unicode_Result=桶
exit/b
:Unicode桶
set Unicode_Result=26742
exit/b
:Unicode25413
set Unicode_Result=捅
exit/b
:Unicode捅
set Unicode_Result=25413
exit/b
:Unicode31570
set Unicode_Result=筒
exit/b
:Unicode筒
set Unicode_Result=31570
exit/b
:Unicode32479
set Unicode_Result=统
exit/b
:Unicode统
set Unicode_Result=32479
exit/b
:Unicode30171
set Unicode_Result=痛
exit/b
:Unicode痛
set Unicode_Result=30171
exit/b
:Unicode20599
set Unicode_Result=偷
exit/b
:Unicode偷
set Unicode_Result=20599
exit/b
:Unicode25237
set Unicode_Result=投
exit/b
:Unicode投
set Unicode_Result=25237
exit/b
:Unicode22836
set Unicode_Result=头
exit/b
:Unicode头
set Unicode_Result=22836
exit/b
:Unicode36879
set Unicode_Result=透
exit/b
:Unicode透
set Unicode_Result=36879
exit/b
:Unicode20984
set Unicode_Result=凸
exit/b
:Unicode凸
set Unicode_Result=20984
exit/b
:Unicode31171
set Unicode_Result=秃
exit/b
:Unicode秃
set Unicode_Result=31171
exit/b
:Unicode31361
set Unicode_Result=突
exit/b
:Unicode突
set Unicode_Result=31361
exit/b
:Unicode22270
set Unicode_Result=图
exit/b
:Unicode图
set Unicode_Result=22270
exit/b
:Unicode24466
set Unicode_Result=徒
exit/b
:Unicode徒
set Unicode_Result=24466
exit/b
:Unicode36884
set Unicode_Result=途
exit/b
:Unicode途
set Unicode_Result=36884
exit/b
:Unicode28034
set Unicode_Result=涂
exit/b
:Unicode涂
set Unicode_Result=28034
exit/b
:Unicode23648
set Unicode_Result=屠
exit/b
:Unicode屠
set Unicode_Result=23648
exit/b
:Unicode22303
set Unicode_Result=土
exit/b
:Unicode土
set Unicode_Result=22303
exit/b
:Unicode21520
set Unicode_Result=吐
exit/b
:Unicode吐
set Unicode_Result=21520
exit/b
:Unicode20820
set Unicode_Result=兔
exit/b
:Unicode兔
set Unicode_Result=20820
exit/b
:Unicode28237
set Unicode_Result=湍
exit/b
:Unicode湍
set Unicode_Result=28237
exit/b
:Unicode22242
set Unicode_Result=团
exit/b
:Unicode团
set Unicode_Result=22242
exit/b
:Unicode25512
set Unicode_Result=推
exit/b
:Unicode推
set Unicode_Result=25512
exit/b
:Unicode39059
set Unicode_Result=颓
exit/b
:Unicode颓
set Unicode_Result=39059
exit/b
:Unicode33151
set Unicode_Result=腿
exit/b
:Unicode腿
set Unicode_Result=33151
exit/b
:Unicode34581
set Unicode_Result=蜕
exit/b
:Unicode蜕
set Unicode_Result=34581
exit/b
:Unicode35114
set Unicode_Result=褪
exit/b
:Unicode褪
set Unicode_Result=35114
exit/b
:Unicode36864
set Unicode_Result=退
exit/b
:Unicode退
set Unicode_Result=36864
exit/b
:Unicode21534
set Unicode_Result=吞
exit/b
:Unicode吞
set Unicode_Result=21534
exit/b
:Unicode23663
set Unicode_Result=屯
exit/b
:Unicode屯
set Unicode_Result=23663
exit/b
:Unicode33216
set Unicode_Result=臀
exit/b
:Unicode臀
set Unicode_Result=33216
exit/b
:Unicode25302
set Unicode_Result=拖
exit/b
:Unicode拖
set Unicode_Result=25302
exit/b
:Unicode25176
set Unicode_Result=托
exit/b
:Unicode托
set Unicode_Result=25176
exit/b
:Unicode33073
set Unicode_Result=脱
exit/b
:Unicode脱
set Unicode_Result=33073
exit/b
:Unicode40501
set Unicode_Result=鸵
exit/b
:Unicode鸵
set Unicode_Result=40501
exit/b
:Unicode38464
set Unicode_Result=陀
exit/b
:Unicode陀
set Unicode_Result=38464
exit/b
:Unicode39534
set Unicode_Result=驮
exit/b
:Unicode驮
set Unicode_Result=39534
exit/b
:Unicode39548
set Unicode_Result=驼
exit/b
:Unicode驼
set Unicode_Result=39548
exit/b
:Unicode26925
set Unicode_Result=椭
exit/b
:Unicode椭
set Unicode_Result=26925
exit/b
:Unicode22949
set Unicode_Result=妥
exit/b
:Unicode妥
set Unicode_Result=22949
exit/b
:Unicode25299
set Unicode_Result=拓
exit/b
:Unicode拓
set Unicode_Result=25299
exit/b
:Unicode21822
set Unicode_Result=唾
exit/b
:Unicode唾
set Unicode_Result=21822
exit/b
:Unicode25366
set Unicode_Result=挖
exit/b
:Unicode挖
set Unicode_Result=25366
exit/b
:Unicode21703
set Unicode_Result=哇
exit/b
:Unicode哇
set Unicode_Result=21703
exit/b
:Unicode34521
set Unicode_Result=蛙
exit/b
:Unicode蛙
set Unicode_Result=34521
exit/b
:Unicode27964
set Unicode_Result=洼
exit/b
:Unicode洼
set Unicode_Result=27964
exit/b
:Unicode23043
set Unicode_Result=娃
exit/b
:Unicode娃
set Unicode_Result=23043
exit/b
:Unicode29926
set Unicode_Result=瓦
exit/b
:Unicode瓦
set Unicode_Result=29926
exit/b
:Unicode34972
set Unicode_Result=袜
exit/b
:Unicode袜
set Unicode_Result=34972
exit/b
:Unicode27498
set Unicode_Result=歪
exit/b
:Unicode歪
set Unicode_Result=27498
exit/b
:Unicode22806
set Unicode_Result=外
exit/b
:Unicode外
set Unicode_Result=22806
exit/b
:Unicode35916
set Unicode_Result=豌
exit/b
:Unicode豌
set Unicode_Result=35916
exit/b
:Unicode24367
set Unicode_Result=弯
exit/b
:Unicode弯
set Unicode_Result=24367
exit/b
:Unicode28286
set Unicode_Result=湾
exit/b
:Unicode湾
set Unicode_Result=28286
exit/b
:Unicode29609
set Unicode_Result=玩
exit/b
:Unicode玩
set Unicode_Result=29609
exit/b
:Unicode39037
set Unicode_Result=顽
exit/b
:Unicode顽
set Unicode_Result=39037
exit/b
:Unicode20024
set Unicode_Result=丸
exit/b
:Unicode丸
set Unicode_Result=20024
exit/b
:Unicode28919
set Unicode_Result=烷
exit/b
:Unicode烷
set Unicode_Result=28919
exit/b
:Unicode23436
set Unicode_Result=完
exit/b
:Unicode完
set Unicode_Result=23436
exit/b
:Unicode30871
set Unicode_Result=碗
exit/b
:Unicode碗
set Unicode_Result=30871
exit/b
:Unicode25405
set Unicode_Result=挽
exit/b
:Unicode挽
set Unicode_Result=25405
exit/b
:Unicode26202
set Unicode_Result=晚
exit/b
:Unicode晚
set Unicode_Result=26202
exit/b
:Unicode30358
set Unicode_Result=皖
exit/b
:Unicode皖
set Unicode_Result=30358
exit/b
:Unicode24779
set Unicode_Result=惋
exit/b
:Unicode惋
set Unicode_Result=24779
exit/b
:Unicode23451
set Unicode_Result=宛
exit/b
:Unicode宛
set Unicode_Result=23451
exit/b
:Unicode23113
set Unicode_Result=婉
exit/b
:Unicode婉
set Unicode_Result=23113
exit/b
:Unicode19975
set Unicode_Result=万
exit/b
:Unicode万
set Unicode_Result=19975
exit/b
:Unicode33109
set Unicode_Result=腕
exit/b
:Unicode腕
set Unicode_Result=33109
exit/b
:Unicode27754
set Unicode_Result=汪
exit/b
:Unicode汪
set Unicode_Result=27754
exit/b
:Unicode29579
set Unicode_Result=王
exit/b
:Unicode王
set Unicode_Result=29579
exit/b
:Unicode20129
set Unicode_Result=亡
exit/b
:Unicode亡
set Unicode_Result=20129
exit/b
:Unicode26505
set Unicode_Result=枉
exit/b
:Unicode枉
set Unicode_Result=26505
exit/b
:Unicode32593
set Unicode_Result=网
exit/b
:Unicode网
set Unicode_Result=32593
exit/b
:Unicode24448
set Unicode_Result=往
exit/b
:Unicode往
set Unicode_Result=24448
exit/b
:Unicode26106
set Unicode_Result=旺
exit/b
:Unicode旺
set Unicode_Result=26106
exit/b
:Unicode26395
set Unicode_Result=望
exit/b
:Unicode望
set Unicode_Result=26395
exit/b
:Unicode24536
set Unicode_Result=忘
exit/b
:Unicode忘
set Unicode_Result=24536
exit/b
:Unicode22916
set Unicode_Result=妄
exit/b
:Unicode妄
set Unicode_Result=22916
exit/b
:Unicode23041
set Unicode_Result=威
exit/b
:Unicode威
set Unicode_Result=23041
exit/b
:Unicode24013
set Unicode_Result=巍
exit/b
:Unicode巍
set Unicode_Result=24013
exit/b
:Unicode24494
set Unicode_Result=微
exit/b
:Unicode微
set Unicode_Result=24494
exit/b
:Unicode21361
set Unicode_Result=危
exit/b
:Unicode危
set Unicode_Result=21361
exit/b
:Unicode38886
set Unicode_Result=韦
exit/b
:Unicode韦
set Unicode_Result=38886
exit/b
:Unicode36829
set Unicode_Result=违
exit/b
:Unicode违
set Unicode_Result=36829
exit/b
:Unicode26693
set Unicode_Result=桅
exit/b
:Unicode桅
set Unicode_Result=26693
exit/b
:Unicode22260
set Unicode_Result=围
exit/b
:Unicode围
set Unicode_Result=22260
exit/b
:Unicode21807
set Unicode_Result=唯
exit/b
:Unicode唯
set Unicode_Result=21807
exit/b
:Unicode24799
set Unicode_Result=惟
exit/b
:Unicode惟
set Unicode_Result=24799
exit/b
:Unicode20026
set Unicode_Result=为
exit/b
:Unicode为
set Unicode_Result=20026
exit/b
:Unicode28493
set Unicode_Result=潍
exit/b
:Unicode潍
set Unicode_Result=28493
exit/b
:Unicode32500
set Unicode_Result=维
exit/b
:Unicode维
set Unicode_Result=32500
exit/b
:Unicode33479
set Unicode_Result=苇
exit/b
:Unicode苇
set Unicode_Result=33479
exit/b
:Unicode33806
set Unicode_Result=萎
exit/b
:Unicode萎
set Unicode_Result=33806
exit/b
:Unicode22996
set Unicode_Result=委
exit/b
:Unicode委
set Unicode_Result=22996
exit/b
:Unicode20255
set Unicode_Result=伟
exit/b
:Unicode伟
set Unicode_Result=20255
exit/b
:Unicode20266
set Unicode_Result=伪
exit/b
:Unicode伪
set Unicode_Result=20266
exit/b
:Unicode23614
set Unicode_Result=尾
exit/b
:Unicode尾
set Unicode_Result=23614
exit/b
:Unicode32428
set Unicode_Result=纬
exit/b
:Unicode纬
set Unicode_Result=32428
exit/b
:Unicode26410
set Unicode_Result=未
exit/b
:Unicode未
set Unicode_Result=26410
exit/b
:Unicode34074
set Unicode_Result=蔚
exit/b
:Unicode蔚
set Unicode_Result=34074
exit/b
:Unicode21619
set Unicode_Result=味
exit/b
:Unicode味
set Unicode_Result=21619
exit/b
:Unicode30031
set Unicode_Result=畏
exit/b
:Unicode畏
set Unicode_Result=30031
exit/b
:Unicode32963
set Unicode_Result=胃
exit/b
:Unicode胃
set Unicode_Result=32963
exit/b
:Unicode21890
set Unicode_Result=喂
exit/b
:Unicode喂
set Unicode_Result=21890
exit/b
:Unicode39759
set Unicode_Result=魏
exit/b
:Unicode魏
set Unicode_Result=39759
exit/b
:Unicode20301
set Unicode_Result=位
exit/b
:Unicode位
set Unicode_Result=20301
exit/b
:Unicode28205
set Unicode_Result=渭
exit/b
:Unicode渭
set Unicode_Result=28205
exit/b
:Unicode35859
set Unicode_Result=谓
exit/b
:Unicode谓
set Unicode_Result=35859
exit/b
:Unicode23561
set Unicode_Result=尉
exit/b
:Unicode尉
set Unicode_Result=23561
exit/b
:Unicode24944
set Unicode_Result=慰
exit/b
:Unicode慰
set Unicode_Result=24944
exit/b
:Unicode21355
set Unicode_Result=卫
exit/b
:Unicode卫
set Unicode_Result=21355
exit/b
:Unicode30239
set Unicode_Result=瘟
exit/b
:Unicode瘟
set Unicode_Result=30239
exit/b
:Unicode28201
set Unicode_Result=温
exit/b
:Unicode温
set Unicode_Result=28201
exit/b
:Unicode34442
set Unicode_Result=蚊
exit/b
:Unicode蚊
set Unicode_Result=34442
exit/b
:Unicode25991
set Unicode_Result=文
exit/b
:Unicode文
set Unicode_Result=25991
exit/b
:Unicode38395
set Unicode_Result=闻
exit/b
:Unicode闻
set Unicode_Result=38395
exit/b
:Unicode32441
set Unicode_Result=纹
exit/b
:Unicode纹
set Unicode_Result=32441
exit/b
:Unicode21563
set Unicode_Result=吻
exit/b
:Unicode吻
set Unicode_Result=21563
exit/b
:Unicode31283
set Unicode_Result=稳
exit/b
:Unicode稳
set Unicode_Result=31283
exit/b
:Unicode32010
set Unicode_Result=紊
exit/b
:Unicode紊
set Unicode_Result=32010
exit/b
:Unicode38382
set Unicode_Result=问
exit/b
:Unicode问
set Unicode_Result=38382
exit/b
:Unicode21985
set Unicode_Result=嗡
exit/b
:Unicode嗡
set Unicode_Result=21985
exit/b
:Unicode32705
set Unicode_Result=翁
exit/b
:Unicode翁
set Unicode_Result=32705
exit/b
:Unicode29934
set Unicode_Result=瓮
exit/b
:Unicode瓮
set Unicode_Result=29934
exit/b
:Unicode25373
set Unicode_Result=挝
exit/b
:Unicode挝
set Unicode_Result=25373
exit/b
:Unicode34583
set Unicode_Result=蜗
exit/b
:Unicode蜗
set Unicode_Result=34583
exit/b
:Unicode28065
set Unicode_Result=涡
exit/b
:Unicode涡
set Unicode_Result=28065
exit/b
:Unicode31389
set Unicode_Result=窝
exit/b
:Unicode窝
set Unicode_Result=31389
exit/b
:Unicode25105
set Unicode_Result=我
exit/b
:Unicode我
set Unicode_Result=25105
exit/b
:Unicode26017
set Unicode_Result=斡
exit/b
:Unicode斡
set Unicode_Result=26017
exit/b
:Unicode21351
set Unicode_Result=卧
exit/b
:Unicode卧
set Unicode_Result=21351
exit/b
:Unicode25569
set Unicode_Result=握
exit/b
:Unicode握
set Unicode_Result=25569
exit/b
:Unicode27779
set Unicode_Result=沃
exit/b
:Unicode沃
set Unicode_Result=27779
exit/b
:Unicode24043
set Unicode_Result=巫
exit/b
:Unicode巫
set Unicode_Result=24043
exit/b
:Unicode21596
set Unicode_Result=呜
exit/b
:Unicode呜
set Unicode_Result=21596
exit/b
:Unicode38056
set Unicode_Result=钨
exit/b
:Unicode钨
set Unicode_Result=38056
exit/b
:Unicode20044
set Unicode_Result=乌
exit/b
:Unicode乌
set Unicode_Result=20044
exit/b
:Unicode27745
set Unicode_Result=污
exit/b
:Unicode污
set Unicode_Result=27745
exit/b
:Unicode35820
set Unicode_Result=诬
exit/b
:Unicode诬
set Unicode_Result=35820
exit/b
:Unicode23627
set Unicode_Result=屋
exit/b
:Unicode屋
set Unicode_Result=23627
exit/b
:Unicode26080
set Unicode_Result=无
exit/b
:Unicode无
set Unicode_Result=26080
exit/b
:Unicode33436
set Unicode_Result=芜
exit/b
:Unicode芜
set Unicode_Result=33436
exit/b
:Unicode26791
set Unicode_Result=梧
exit/b
:Unicode梧
set Unicode_Result=26791
exit/b
:Unicode21566
set Unicode_Result=吾
exit/b
:Unicode吾
set Unicode_Result=21566
exit/b
:Unicode21556
set Unicode_Result=吴
exit/b
:Unicode吴
set Unicode_Result=21556
exit/b
:Unicode27595
set Unicode_Result=毋
exit/b
:Unicode毋
set Unicode_Result=27595
exit/b
:Unicode27494
set Unicode_Result=武
exit/b
:Unicode武
set Unicode_Result=27494
exit/b
:Unicode20116
set Unicode_Result=五
exit/b
:Unicode五
set Unicode_Result=20116
exit/b
:Unicode25410
set Unicode_Result=捂
exit/b
:Unicode捂
set Unicode_Result=25410
exit/b
:Unicode21320
set Unicode_Result=午
exit/b
:Unicode午
set Unicode_Result=21320
exit/b
:Unicode33310
set Unicode_Result=舞
exit/b
:Unicode舞
set Unicode_Result=33310
exit/b
:Unicode20237
set Unicode_Result=伍
exit/b
:Unicode伍
set Unicode_Result=20237
exit/b
:Unicode20398
set Unicode_Result=侮
exit/b
:Unicode侮
set Unicode_Result=20398
exit/b
:Unicode22366
set Unicode_Result=坞
exit/b
:Unicode坞
set Unicode_Result=22366
exit/b
:Unicode25098
set Unicode_Result=戊
exit/b
:Unicode戊
set Unicode_Result=25098
exit/b
:Unicode38654
set Unicode_Result=雾
exit/b
:Unicode雾
set Unicode_Result=38654
exit/b
:Unicode26212
set Unicode_Result=晤
exit/b
:Unicode晤
set Unicode_Result=26212
exit/b
:Unicode29289
set Unicode_Result=物
exit/b
:Unicode物
set Unicode_Result=29289
exit/b
:Unicode21247
set Unicode_Result=勿
exit/b
:Unicode勿
set Unicode_Result=21247
exit/b
:Unicode21153
set Unicode_Result=务
exit/b
:Unicode务
set Unicode_Result=21153
exit/b
:Unicode24735
set Unicode_Result=悟
exit/b
:Unicode悟
set Unicode_Result=24735
exit/b
:Unicode35823
set Unicode_Result=误
exit/b
:Unicode误
set Unicode_Result=35823
exit/b
:Unicode26132
set Unicode_Result=昔
exit/b
:Unicode昔
set Unicode_Result=26132
exit/b
:Unicode29081
set Unicode_Result=熙
exit/b
:Unicode熙
set Unicode_Result=29081
exit/b
:Unicode26512
set Unicode_Result=析
exit/b
:Unicode析
set Unicode_Result=26512
exit/b
:Unicode35199
set Unicode_Result=西
exit/b
:Unicode西
set Unicode_Result=35199
exit/b
:Unicode30802
set Unicode_Result=硒
exit/b
:Unicode硒
set Unicode_Result=30802
exit/b
:Unicode30717
set Unicode_Result=矽
exit/b
:Unicode矽
set Unicode_Result=30717
exit/b
:Unicode26224
set Unicode_Result=晰
exit/b
:Unicode晰
set Unicode_Result=26224
exit/b
:Unicode22075
set Unicode_Result=嘻
exit/b
:Unicode嘻
set Unicode_Result=22075
exit/b
:Unicode21560
set Unicode_Result=吸
exit/b
:Unicode吸
set Unicode_Result=21560
exit/b
:Unicode38177
set Unicode_Result=锡
exit/b
:Unicode锡
set Unicode_Result=38177
exit/b
:Unicode29306
set Unicode_Result=牺
exit/b
:Unicode牺
set Unicode_Result=29306
exit/b
:Unicode31232
set Unicode_Result=稀
exit/b
:Unicode稀
set Unicode_Result=31232
exit/b
:Unicode24687
set Unicode_Result=息
exit/b
:Unicode息
set Unicode_Result=24687
exit/b
:Unicode24076
set Unicode_Result=希
exit/b
:Unicode希
set Unicode_Result=24076
exit/b
:Unicode24713
set Unicode_Result=悉
exit/b
:Unicode悉
set Unicode_Result=24713
exit/b
:Unicode33181
set Unicode_Result=膝
exit/b
:Unicode膝
set Unicode_Result=33181
exit/b
:Unicode22805
set Unicode_Result=夕
exit/b
:Unicode夕
set Unicode_Result=22805
exit/b
:Unicode24796
set Unicode_Result=惜
exit/b
:Unicode惜
set Unicode_Result=24796
exit/b
:Unicode29060
set Unicode_Result=熄
exit/b
:Unicode熄
set Unicode_Result=29060
exit/b
:Unicode28911
set Unicode_Result=烯
exit/b
:Unicode烯
set Unicode_Result=28911
exit/b
:Unicode28330
set Unicode_Result=溪
exit/b
:Unicode溪
set Unicode_Result=28330
exit/b
:Unicode27728
set Unicode_Result=汐
exit/b
:Unicode汐
set Unicode_Result=27728
exit/b
:Unicode29312
set Unicode_Result=犀
exit/b
:Unicode犀
set Unicode_Result=29312
exit/b
:Unicode27268
set Unicode_Result=檄
exit/b
:Unicode檄
set Unicode_Result=27268
exit/b
:Unicode34989
set Unicode_Result=袭
exit/b
:Unicode袭
set Unicode_Result=34989
exit/b
:Unicode24109
set Unicode_Result=席
exit/b
:Unicode席
set Unicode_Result=24109
exit/b
:Unicode20064
set Unicode_Result=习
exit/b
:Unicode习
set Unicode_Result=20064
exit/b
:Unicode23219
set Unicode_Result=媳
exit/b
:Unicode媳
set Unicode_Result=23219
exit/b
:Unicode21916
set Unicode_Result=喜
exit/b
:Unicode喜
set Unicode_Result=21916
exit/b
:Unicode38115
set Unicode_Result=铣
exit/b
:Unicode铣
set Unicode_Result=38115
exit/b
:Unicode27927
set Unicode_Result=洗
exit/b
:Unicode洗
set Unicode_Result=27927
exit/b
:Unicode31995
set Unicode_Result=系
exit/b
:Unicode系
set Unicode_Result=31995
exit/b
:Unicode38553
set Unicode_Result=隙
exit/b
:Unicode隙
set Unicode_Result=38553
exit/b
:Unicode25103
set Unicode_Result=戏
exit/b
:Unicode戏
set Unicode_Result=25103
exit/b
:Unicode32454
set Unicode_Result=细
exit/b
:Unicode细
set Unicode_Result=32454
exit/b
:Unicode30606
set Unicode_Result=瞎
exit/b
:Unicode瞎
set Unicode_Result=30606
exit/b
:Unicode34430
set Unicode_Result=虾
exit/b
:Unicode虾
set Unicode_Result=34430
exit/b
:Unicode21283
set Unicode_Result=匣
exit/b
:Unicode匣
set Unicode_Result=21283
exit/b
:Unicode38686
set Unicode_Result=霞
exit/b
:Unicode霞
set Unicode_Result=38686
exit/b
:Unicode36758
set Unicode_Result=辖
exit/b
:Unicode辖
set Unicode_Result=36758
exit/b
:Unicode26247
set Unicode_Result=暇
exit/b
:Unicode暇
set Unicode_Result=26247
exit/b
:Unicode23777
set Unicode_Result=峡
exit/b
:Unicode峡
set Unicode_Result=23777
exit/b
:Unicode20384
set Unicode_Result=侠
exit/b
:Unicode侠
set Unicode_Result=20384
exit/b
:Unicode29421
set Unicode_Result=狭
exit/b
:Unicode狭
set Unicode_Result=29421
exit/b
:Unicode19979
set Unicode_Result=下
exit/b
:Unicode下
set Unicode_Result=19979
exit/b
:Unicode21414
set Unicode_Result=厦
exit/b
:Unicode厦
set Unicode_Result=21414
exit/b
:Unicode22799
set Unicode_Result=夏
exit/b
:Unicode夏
set Unicode_Result=22799
exit/b
:Unicode21523
set Unicode_Result=吓
exit/b
:Unicode吓
set Unicode_Result=21523
exit/b
:Unicode25472
set Unicode_Result=掀
exit/b
:Unicode掀
set Unicode_Result=25472
exit/b
:Unicode38184
set Unicode_Result=锨
exit/b
:Unicode锨
set Unicode_Result=38184
exit/b
:Unicode20808
set Unicode_Result=先
exit/b
:Unicode先
set Unicode_Result=20808
exit/b
:Unicode20185
set Unicode_Result=仙
exit/b
:Unicode仙
set Unicode_Result=20185
exit/b
:Unicode40092
set Unicode_Result=鲜
exit/b
:Unicode鲜
set Unicode_Result=40092
exit/b
:Unicode32420
set Unicode_Result=纤
exit/b
:Unicode纤
set Unicode_Result=32420
exit/b
:Unicode21688
set Unicode_Result=咸
exit/b
:Unicode咸
set Unicode_Result=21688
exit/b
:Unicode36132
set Unicode_Result=贤
exit/b
:Unicode贤
set Unicode_Result=36132
exit/b
:Unicode34900
set Unicode_Result=衔
exit/b
:Unicode衔
set Unicode_Result=34900
exit/b
:Unicode33335
set Unicode_Result=舷
exit/b
:Unicode舷
set Unicode_Result=33335
exit/b
:Unicode38386
set Unicode_Result=闲
exit/b
:Unicode闲
set Unicode_Result=38386
exit/b
:Unicode28046
set Unicode_Result=涎
exit/b
:Unicode涎
set Unicode_Result=28046
exit/b
:Unicode24358
set Unicode_Result=弦
exit/b
:Unicode弦
set Unicode_Result=24358
exit/b
:Unicode23244
set Unicode_Result=嫌
exit/b
:Unicode嫌
set Unicode_Result=23244
exit/b
:Unicode26174
set Unicode_Result=显
exit/b
:Unicode显
set Unicode_Result=26174
exit/b
:Unicode38505
set Unicode_Result=险
exit/b
:Unicode险
set Unicode_Result=38505
exit/b
:Unicode29616
set Unicode_Result=现
exit/b
:Unicode现
set Unicode_Result=29616
exit/b
:Unicode29486
set Unicode_Result=献
exit/b
:Unicode献
set Unicode_Result=29486
exit/b
:Unicode21439
set Unicode_Result=县
exit/b
:Unicode县
set Unicode_Result=21439
exit/b
:Unicode33146
set Unicode_Result=腺
exit/b
:Unicode腺
set Unicode_Result=33146
exit/b
:Unicode39301
set Unicode_Result=馅
exit/b
:Unicode馅
set Unicode_Result=39301
exit/b
:Unicode32673
set Unicode_Result=羡
exit/b
:Unicode羡
set Unicode_Result=32673
exit/b
:Unicode23466
set Unicode_Result=宪
exit/b
:Unicode宪
set Unicode_Result=23466
exit/b
:Unicode38519
set Unicode_Result=陷
exit/b
:Unicode陷
set Unicode_Result=38519
exit/b
:Unicode38480
set Unicode_Result=限
exit/b
:Unicode限
set Unicode_Result=38480
exit/b
:Unicode32447
set Unicode_Result=线
exit/b
:Unicode线
set Unicode_Result=32447
exit/b
:Unicode30456
set Unicode_Result=相
exit/b
:Unicode相
set Unicode_Result=30456
exit/b
:Unicode21410
set Unicode_Result=厢
exit/b
:Unicode厢
set Unicode_Result=21410
exit/b
:Unicode38262
set Unicode_Result=镶
exit/b
:Unicode镶
set Unicode_Result=38262
exit/b
:Unicode39321
set Unicode_Result=香
exit/b
:Unicode香
set Unicode_Result=39321
exit/b
:Unicode31665
set Unicode_Result=箱
exit/b
:Unicode箱
set Unicode_Result=31665
exit/b
:Unicode35140
set Unicode_Result=襄
exit/b
:Unicode襄
set Unicode_Result=35140
exit/b
:Unicode28248
set Unicode_Result=湘
exit/b
:Unicode湘
set Unicode_Result=28248
exit/b
:Unicode20065
set Unicode_Result=乡
exit/b
:Unicode乡
set Unicode_Result=20065
exit/b
:Unicode32724
set Unicode_Result=翔
exit/b
:Unicode翔
set Unicode_Result=32724
exit/b
:Unicode31077
set Unicode_Result=祥
exit/b
:Unicode祥
set Unicode_Result=31077
exit/b
:Unicode35814
set Unicode_Result=详
exit/b
:Unicode详
set Unicode_Result=35814
exit/b
:Unicode24819
set Unicode_Result=想
exit/b
:Unicode想
set Unicode_Result=24819
exit/b
:Unicode21709
set Unicode_Result=响
exit/b
:Unicode响
set Unicode_Result=21709
exit/b
:Unicode20139
set Unicode_Result=享
exit/b
:Unicode享
set Unicode_Result=20139
exit/b
:Unicode39033
set Unicode_Result=项
exit/b
:Unicode项
set Unicode_Result=39033
exit/b
:Unicode24055
set Unicode_Result=巷
exit/b
:Unicode巷
set Unicode_Result=24055
exit/b
:Unicode27233
set Unicode_Result=橡
exit/b
:Unicode橡
set Unicode_Result=27233
exit/b
:Unicode20687
set Unicode_Result=像
exit/b
:Unicode像
set Unicode_Result=20687
exit/b
:Unicode21521
set Unicode_Result=向
exit/b
:Unicode向
set Unicode_Result=21521
exit/b
:Unicode35937
set Unicode_Result=象
exit/b
:Unicode象
set Unicode_Result=35937
exit/b
:Unicode33831
set Unicode_Result=萧
exit/b
:Unicode萧
set Unicode_Result=33831
exit/b
:Unicode30813
set Unicode_Result=硝
exit/b
:Unicode硝
set Unicode_Result=30813
exit/b
:Unicode38660
set Unicode_Result=霄
exit/b
:Unicode霄
set Unicode_Result=38660
exit/b
:Unicode21066
set Unicode_Result=削
exit/b
:Unicode削
set Unicode_Result=21066
exit/b
:Unicode21742
set Unicode_Result=哮
exit/b
:Unicode哮
set Unicode_Result=21742
exit/b
:Unicode22179
set Unicode_Result=嚣
exit/b
:Unicode嚣
set Unicode_Result=22179
exit/b
:Unicode38144
set Unicode_Result=销
exit/b
:Unicode销
set Unicode_Result=38144
exit/b
:Unicode28040
set Unicode_Result=消
exit/b
:Unicode消
set Unicode_Result=28040
exit/b
:Unicode23477
set Unicode_Result=宵
exit/b
:Unicode宵
set Unicode_Result=23477
exit/b
:Unicode28102
set Unicode_Result=淆
exit/b
:Unicode淆
set Unicode_Result=28102
exit/b
:Unicode26195
set Unicode_Result=晓
exit/b
:Unicode晓
set Unicode_Result=26195
exit/b
:Unicode23567
set Unicode_Result=小
exit/b
:Unicode小
set Unicode_Result=23567
exit/b
:Unicode23389
set Unicode_Result=孝
exit/b
:Unicode孝
set Unicode_Result=23389
exit/b
:Unicode26657
set Unicode_Result=校
exit/b
:Unicode校
set Unicode_Result=26657
exit/b
:Unicode32918
set Unicode_Result=肖
exit/b
:Unicode肖
set Unicode_Result=32918
exit/b
:Unicode21880
set Unicode_Result=啸
exit/b
:Unicode啸
set Unicode_Result=21880
exit/b
:Unicode31505
set Unicode_Result=笑
exit/b
:Unicode笑
set Unicode_Result=31505
exit/b
:Unicode25928
set Unicode_Result=效
exit/b
:Unicode效
set Unicode_Result=25928
exit/b
:Unicode26964
set Unicode_Result=楔
exit/b
:Unicode楔
set Unicode_Result=26964
exit/b
:Unicode20123
set Unicode_Result=些
exit/b
:Unicode些
set Unicode_Result=20123
exit/b
:Unicode27463
set Unicode_Result=歇
exit/b
:Unicode歇
set Unicode_Result=27463
exit/b
:Unicode34638
set Unicode_Result=蝎
exit/b
:Unicode蝎
set Unicode_Result=34638
exit/b
:Unicode38795
set Unicode_Result=鞋
exit/b
:Unicode鞋
set Unicode_Result=38795
exit/b
:Unicode21327
set Unicode_Result=协
exit/b
:Unicode协
set Unicode_Result=21327
exit/b
:Unicode25375
set Unicode_Result=挟
exit/b
:Unicode挟
set Unicode_Result=25375
exit/b
:Unicode25658
set Unicode_Result=携
exit/b
:Unicode携
set Unicode_Result=25658
exit/b
:Unicode37034
set Unicode_Result=邪
exit/b
:Unicode邪
set Unicode_Result=37034
exit/b
:Unicode26012
set Unicode_Result=斜
exit/b
:Unicode斜
set Unicode_Result=26012
exit/b
:Unicode32961
set Unicode_Result=胁
exit/b
:Unicode胁
set Unicode_Result=32961
exit/b
:Unicode35856
set Unicode_Result=谐
exit/b
:Unicode谐
set Unicode_Result=35856
exit/b
:Unicode20889
set Unicode_Result=写
exit/b
:Unicode写
set Unicode_Result=20889
exit/b
:Unicode26800
set Unicode_Result=械
exit/b
:Unicode械
set Unicode_Result=26800
exit/b
:Unicode21368
set Unicode_Result=卸
exit/b
:Unicode卸
set Unicode_Result=21368
exit/b
:Unicode34809
set Unicode_Result=蟹
exit/b
:Unicode蟹
set Unicode_Result=34809
exit/b
:Unicode25032
set Unicode_Result=懈
exit/b
:Unicode懈
set Unicode_Result=25032
exit/b
:Unicode27844
set Unicode_Result=泄
exit/b
:Unicode泄
set Unicode_Result=27844
exit/b
:Unicode27899
set Unicode_Result=泻
exit/b
:Unicode泻
set Unicode_Result=27899
exit/b
:Unicode35874
set Unicode_Result=谢
exit/b
:Unicode谢
set Unicode_Result=35874
exit/b
:Unicode23633
set Unicode_Result=屑
exit/b
:Unicode屑
set Unicode_Result=23633
exit/b
:Unicode34218
set Unicode_Result=薪
exit/b
:Unicode薪
set Unicode_Result=34218
exit/b
:Unicode33455
set Unicode_Result=芯
exit/b
:Unicode芯
set Unicode_Result=33455
exit/b
:Unicode38156
set Unicode_Result=锌
exit/b
:Unicode锌
set Unicode_Result=38156
exit/b
:Unicode27427
set Unicode_Result=欣
exit/b
:Unicode欣
set Unicode_Result=27427
exit/b
:Unicode36763
set Unicode_Result=辛
exit/b
:Unicode辛
set Unicode_Result=36763
exit/b
:Unicode26032
set Unicode_Result=新
exit/b
:Unicode新
set Unicode_Result=26032
exit/b
:Unicode24571
set Unicode_Result=忻
exit/b
:Unicode忻
set Unicode_Result=24571
exit/b
:Unicode24515
set Unicode_Result=心
exit/b
:Unicode心
set Unicode_Result=24515
exit/b
:Unicode20449
set Unicode_Result=信
exit/b
:Unicode信
set Unicode_Result=20449
exit/b
:Unicode34885
set Unicode_Result=衅
exit/b
:Unicode衅
set Unicode_Result=34885
exit/b
:Unicode26143
set Unicode_Result=星
exit/b
:Unicode星
set Unicode_Result=26143
exit/b
:Unicode33125
set Unicode_Result=腥
exit/b
:Unicode腥
set Unicode_Result=33125
exit/b
:Unicode29481
set Unicode_Result=猩
exit/b
:Unicode猩
set Unicode_Result=29481
exit/b
:Unicode24826
set Unicode_Result=惺
exit/b
:Unicode惺
set Unicode_Result=24826
exit/b
:Unicode20852
set Unicode_Result=兴
exit/b
:Unicode兴
set Unicode_Result=20852
exit/b
:Unicode21009
set Unicode_Result=刑
exit/b
:Unicode刑
set Unicode_Result=21009
exit/b
:Unicode22411
set Unicode_Result=型
exit/b
:Unicode型
set Unicode_Result=22411
exit/b
:Unicode24418
set Unicode_Result=形
exit/b
:Unicode形
set Unicode_Result=24418
exit/b
:Unicode37026
set Unicode_Result=邢
exit/b
:Unicode邢
set Unicode_Result=37026
exit/b
:Unicode34892
set Unicode_Result=行
exit/b
:Unicode行
set Unicode_Result=34892
exit/b
:Unicode37266
set Unicode_Result=醒
exit/b
:Unicode醒
set Unicode_Result=37266
exit/b
:Unicode24184
set Unicode_Result=幸
exit/b
:Unicode幸
set Unicode_Result=24184
exit/b
:Unicode26447
set Unicode_Result=杏
exit/b
:Unicode杏
set Unicode_Result=26447
exit/b
:Unicode24615
set Unicode_Result=性
exit/b
:Unicode性
set Unicode_Result=24615
exit/b
:Unicode22995
set Unicode_Result=姓
exit/b
:Unicode姓
set Unicode_Result=22995
exit/b
:Unicode20804
set Unicode_Result=兄
exit/b
:Unicode兄
set Unicode_Result=20804
exit/b
:Unicode20982
set Unicode_Result=凶
exit/b
:Unicode凶
set Unicode_Result=20982
exit/b
:Unicode33016
set Unicode_Result=胸
exit/b
:Unicode胸
set Unicode_Result=33016
exit/b
:Unicode21256
set Unicode_Result=匈
exit/b
:Unicode匈
set Unicode_Result=21256
exit/b
:Unicode27769
set Unicode_Result=汹
exit/b
:Unicode汹
set Unicode_Result=27769
exit/b
:Unicode38596
set Unicode_Result=雄
exit/b
:Unicode雄
set Unicode_Result=38596
exit/b
:Unicode29066
set Unicode_Result=熊
exit/b
:Unicode熊
set Unicode_Result=29066
exit/b
:Unicode20241
set Unicode_Result=休
exit/b
:Unicode休
set Unicode_Result=20241
exit/b
:Unicode20462
set Unicode_Result=修
exit/b
:Unicode修
set Unicode_Result=20462
exit/b
:Unicode32670
set Unicode_Result=羞
exit/b
:Unicode羞
set Unicode_Result=32670
exit/b
:Unicode26429
set Unicode_Result=朽
exit/b
:Unicode朽
set Unicode_Result=26429
exit/b
:Unicode21957
set Unicode_Result=嗅
exit/b
:Unicode嗅
set Unicode_Result=21957
exit/b
:Unicode38152
set Unicode_Result=锈
exit/b
:Unicode锈
set Unicode_Result=38152
exit/b
:Unicode31168
set Unicode_Result=秀
exit/b
:Unicode秀
set Unicode_Result=31168
exit/b
:Unicode34966
set Unicode_Result=袖
exit/b
:Unicode袖
set Unicode_Result=34966
exit/b
:Unicode32483
set Unicode_Result=绣
exit/b
:Unicode绣
set Unicode_Result=32483
exit/b
:Unicode22687
set Unicode_Result=墟
exit/b
:Unicode墟
set Unicode_Result=22687
exit/b
:Unicode25100
set Unicode_Result=戌
exit/b
:Unicode戌
set Unicode_Result=25100
exit/b
:Unicode38656
set Unicode_Result=需
exit/b
:Unicode需
set Unicode_Result=38656
exit/b
:Unicode34394
set Unicode_Result=虚
exit/b
:Unicode虚
set Unicode_Result=34394
exit/b
:Unicode22040
set Unicode_Result=嘘
exit/b
:Unicode嘘
set Unicode_Result=22040
exit/b
:Unicode39035
set Unicode_Result=须
exit/b
:Unicode须
set Unicode_Result=39035
exit/b
:Unicode24464
set Unicode_Result=徐
exit/b
:Unicode徐
set Unicode_Result=24464
exit/b
:Unicode35768
set Unicode_Result=许
exit/b
:Unicode许
set Unicode_Result=35768
exit/b
:Unicode33988
set Unicode_Result=蓄
exit/b
:Unicode蓄
set Unicode_Result=33988
exit/b
:Unicode37207
set Unicode_Result=酗
exit/b
:Unicode酗
set Unicode_Result=37207
exit/b
:Unicode21465
set Unicode_Result=叙
exit/b
:Unicode叙
set Unicode_Result=21465
exit/b
:Unicode26093
set Unicode_Result=旭
exit/b
:Unicode旭
set Unicode_Result=26093
exit/b
:Unicode24207
set Unicode_Result=序
exit/b
:Unicode序
set Unicode_Result=24207
exit/b
:Unicode30044
set Unicode_Result=畜
exit/b
:Unicode畜
set Unicode_Result=30044
exit/b
:Unicode24676
set Unicode_Result=恤
exit/b
:Unicode恤
set Unicode_Result=24676
exit/b
:Unicode32110
set Unicode_Result=絮
exit/b
:Unicode絮
set Unicode_Result=32110
exit/b
:Unicode23167
set Unicode_Result=婿
exit/b
:Unicode婿
set Unicode_Result=23167
exit/b
:Unicode32490
set Unicode_Result=绪
exit/b
:Unicode绪
set Unicode_Result=32490
exit/b
:Unicode32493
set Unicode_Result=续
exit/b
:Unicode续
set Unicode_Result=32493
exit/b
:Unicode36713
set Unicode_Result=轩
exit/b
:Unicode轩
set Unicode_Result=36713
exit/b
:Unicode21927
set Unicode_Result=喧
exit/b
:Unicode喧
set Unicode_Result=21927
exit/b
:Unicode23459
set Unicode_Result=宣
exit/b
:Unicode宣
set Unicode_Result=23459
exit/b
:Unicode24748
set Unicode_Result=悬
exit/b
:Unicode悬
set Unicode_Result=24748
exit/b
:Unicode26059
set Unicode_Result=旋
exit/b
:Unicode旋
set Unicode_Result=26059
exit/b
:Unicode29572
set Unicode_Result=玄
exit/b
:Unicode玄
set Unicode_Result=29572
exit/b
:Unicode36873
set Unicode_Result=选
exit/b
:Unicode选
set Unicode_Result=36873
exit/b
:Unicode30307
set Unicode_Result=癣
exit/b
:Unicode癣
set Unicode_Result=30307
exit/b
:Unicode30505
set Unicode_Result=眩
exit/b
:Unicode眩
set Unicode_Result=30505
exit/b
:Unicode32474
set Unicode_Result=绚
exit/b
:Unicode绚
set Unicode_Result=32474
exit/b
:Unicode38772
set Unicode_Result=靴
exit/b
:Unicode靴
set Unicode_Result=38772
exit/b
:Unicode34203
set Unicode_Result=薛
exit/b
:Unicode薛
set Unicode_Result=34203
exit/b
:Unicode23398
set Unicode_Result=学
exit/b
:Unicode学
set Unicode_Result=23398
exit/b
:Unicode31348
set Unicode_Result=穴
exit/b
:Unicode穴
set Unicode_Result=31348
exit/b
:Unicode38634
set Unicode_Result=雪
exit/b
:Unicode雪
set Unicode_Result=38634
exit/b
:Unicode34880
set Unicode_Result=血
exit/b
:Unicode血
set Unicode_Result=34880
exit/b
:Unicode21195
set Unicode_Result=勋
exit/b
:Unicode勋
set Unicode_Result=21195
exit/b
:Unicode29071
set Unicode_Result=熏
exit/b
:Unicode熏
set Unicode_Result=29071
exit/b
:Unicode24490
set Unicode_Result=循
exit/b
:Unicode循
set Unicode_Result=24490
exit/b
:Unicode26092
set Unicode_Result=旬
exit/b
:Unicode旬
set Unicode_Result=26092
exit/b
:Unicode35810
set Unicode_Result=询
exit/b
:Unicode询
set Unicode_Result=35810
exit/b
:Unicode23547
set Unicode_Result=寻
exit/b
:Unicode寻
set Unicode_Result=23547
exit/b
:Unicode39535
set Unicode_Result=驯
exit/b
:Unicode驯
set Unicode_Result=39535
exit/b
:Unicode24033
set Unicode_Result=巡
exit/b
:Unicode巡
set Unicode_Result=24033
exit/b
:Unicode27529
set Unicode_Result=殉
exit/b
:Unicode殉
set Unicode_Result=27529
exit/b
:Unicode27739
set Unicode_Result=汛
exit/b
:Unicode汛
set Unicode_Result=27739
exit/b
:Unicode35757
set Unicode_Result=训
exit/b
:Unicode训
set Unicode_Result=35757
exit/b
:Unicode35759
set Unicode_Result=讯
exit/b
:Unicode讯
set Unicode_Result=35759
exit/b
:Unicode36874
set Unicode_Result=逊
exit/b
:Unicode逊
set Unicode_Result=36874
exit/b
:Unicode36805
set Unicode_Result=迅
exit/b
:Unicode迅
set Unicode_Result=36805
exit/b
:Unicode21387
set Unicode_Result=压
exit/b
:Unicode压
set Unicode_Result=21387
exit/b
:Unicode25276
set Unicode_Result=押
exit/b
:Unicode押
set Unicode_Result=25276
exit/b
:Unicode40486
set Unicode_Result=鸦
exit/b
:Unicode鸦
set Unicode_Result=40486
exit/b
:Unicode40493
set Unicode_Result=鸭
exit/b
:Unicode鸭
set Unicode_Result=40493
exit/b
:Unicode21568
set Unicode_Result=呀
exit/b
:Unicode呀
set Unicode_Result=21568
exit/b
:Unicode20011
set Unicode_Result=丫
exit/b
:Unicode丫
set Unicode_Result=20011
exit/b
:Unicode33469
set Unicode_Result=芽
exit/b
:Unicode芽
set Unicode_Result=33469
exit/b
:Unicode29273
set Unicode_Result=牙
exit/b
:Unicode牙
set Unicode_Result=29273
exit/b
:Unicode34460
set Unicode_Result=蚜
exit/b
:Unicode蚜
set Unicode_Result=34460
exit/b
:Unicode23830
set Unicode_Result=崖
exit/b
:Unicode崖
set Unicode_Result=23830
exit/b
:Unicode34905
set Unicode_Result=衙
exit/b
:Unicode衙
set Unicode_Result=34905
exit/b
:Unicode28079
set Unicode_Result=涯
exit/b
:Unicode涯
set Unicode_Result=28079
exit/b
:Unicode38597
set Unicode_Result=雅
exit/b
:Unicode雅
set Unicode_Result=38597
exit/b
:Unicode21713
set Unicode_Result=哑
exit/b
:Unicode哑
set Unicode_Result=21713
exit/b
:Unicode20122
set Unicode_Result=亚
exit/b
:Unicode亚
set Unicode_Result=20122
exit/b
:Unicode35766
set Unicode_Result=讶
exit/b
:Unicode讶
set Unicode_Result=35766
exit/b
:Unicode28937
set Unicode_Result=焉
exit/b
:Unicode焉
set Unicode_Result=28937
exit/b
:Unicode21693
set Unicode_Result=咽
exit/b
:Unicode咽
set Unicode_Result=21693
exit/b
:Unicode38409
set Unicode_Result=阉
exit/b
:Unicode阉
set Unicode_Result=38409
exit/b
:Unicode28895
set Unicode_Result=烟
exit/b
:Unicode烟
set Unicode_Result=28895
exit/b
:Unicode28153
set Unicode_Result=淹
exit/b
:Unicode淹
set Unicode_Result=28153
exit/b
:Unicode30416
set Unicode_Result=盐
exit/b
:Unicode盐
set Unicode_Result=30416
exit/b
:Unicode20005
set Unicode_Result=严
exit/b
:Unicode严
set Unicode_Result=20005
exit/b
:Unicode30740
set Unicode_Result=研
exit/b
:Unicode研
set Unicode_Result=30740
exit/b
:Unicode34578
set Unicode_Result=蜒
exit/b
:Unicode蜒
set Unicode_Result=34578
exit/b
:Unicode23721
set Unicode_Result=岩
exit/b
:Unicode岩
set Unicode_Result=23721
exit/b
:Unicode24310
set Unicode_Result=延
exit/b
:Unicode延
set Unicode_Result=24310
exit/b
:Unicode35328
set Unicode_Result=言
exit/b
:Unicode言
set Unicode_Result=35328
exit/b
:Unicode39068
set Unicode_Result=颜
exit/b
:Unicode颜
set Unicode_Result=39068
exit/b
:Unicode38414
set Unicode_Result=阎
exit/b
:Unicode阎
set Unicode_Result=38414
exit/b
:Unicode28814
set Unicode_Result=炎
exit/b
:Unicode炎
set Unicode_Result=28814
exit/b
:Unicode27839
set Unicode_Result=沿
exit/b
:Unicode沿
set Unicode_Result=27839
exit/b
:Unicode22852
set Unicode_Result=奄
exit/b
:Unicode奄
set Unicode_Result=22852
exit/b
:Unicode25513
set Unicode_Result=掩
exit/b
:Unicode掩
set Unicode_Result=25513
exit/b
:Unicode30524
set Unicode_Result=眼
exit/b
:Unicode眼
set Unicode_Result=30524
exit/b
:Unicode34893
set Unicode_Result=衍
exit/b
:Unicode衍
set Unicode_Result=34893
exit/b
:Unicode28436
set Unicode_Result=演
exit/b
:Unicode演
set Unicode_Result=28436
exit/b
:Unicode33395
set Unicode_Result=艳
exit/b
:Unicode艳
set Unicode_Result=33395
exit/b
:Unicode22576
set Unicode_Result=堰
exit/b
:Unicode堰
set Unicode_Result=22576
exit/b
:Unicode29141
set Unicode_Result=燕
exit/b
:Unicode燕
set Unicode_Result=29141
exit/b
:Unicode21388
set Unicode_Result=厌
exit/b
:Unicode厌
set Unicode_Result=21388
exit/b
:Unicode30746
set Unicode_Result=砚
exit/b
:Unicode砚
set Unicode_Result=30746
exit/b
:Unicode38593
set Unicode_Result=雁
exit/b
:Unicode雁
set Unicode_Result=38593
exit/b
:Unicode21761
set Unicode_Result=唁
exit/b
:Unicode唁
set Unicode_Result=21761
exit/b
:Unicode24422
set Unicode_Result=彦
exit/b
:Unicode彦
set Unicode_Result=24422
exit/b
:Unicode28976
set Unicode_Result=焰
exit/b
:Unicode焰
set Unicode_Result=28976
exit/b
:Unicode23476
set Unicode_Result=宴
exit/b
:Unicode宴
set Unicode_Result=23476
exit/b
:Unicode35866
set Unicode_Result=谚
exit/b
:Unicode谚
set Unicode_Result=35866
exit/b
:Unicode39564
set Unicode_Result=验
exit/b
:Unicode验
set Unicode_Result=39564
exit/b
:Unicode27523
set Unicode_Result=殃
exit/b
:Unicode殃
set Unicode_Result=27523
exit/b
:Unicode22830
set Unicode_Result=央
exit/b
:Unicode央
set Unicode_Result=22830
exit/b
:Unicode40495
set Unicode_Result=鸯
exit/b
:Unicode鸯
set Unicode_Result=40495
exit/b
:Unicode31207
set Unicode_Result=秧
exit/b
:Unicode秧
set Unicode_Result=31207
exit/b
:Unicode26472
set Unicode_Result=杨
exit/b
:Unicode杨
set Unicode_Result=26472
exit/b
:Unicode25196
set Unicode_Result=扬
exit/b
:Unicode扬
set Unicode_Result=25196
exit/b
:Unicode20335
set Unicode_Result=佯
exit/b
:Unicode佯
set Unicode_Result=20335
exit/b
:Unicode30113
set Unicode_Result=疡
exit/b
:Unicode疡
set Unicode_Result=30113
exit/b
:Unicode32650
set Unicode_Result=羊
exit/b
:Unicode羊
set Unicode_Result=32650
exit/b
:Unicode27915
set Unicode_Result=洋
exit/b
:Unicode洋
set Unicode_Result=27915
exit/b
:Unicode38451
set Unicode_Result=阳
exit/b
:Unicode阳
set Unicode_Result=38451
exit/b
:Unicode27687
set Unicode_Result=氧
exit/b
:Unicode氧
set Unicode_Result=27687
exit/b
:Unicode20208
set Unicode_Result=仰
exit/b
:Unicode仰
set Unicode_Result=20208
exit/b
:Unicode30162
set Unicode_Result=痒
exit/b
:Unicode痒
set Unicode_Result=30162
exit/b
:Unicode20859
set Unicode_Result=养
exit/b
:Unicode养
set Unicode_Result=20859
exit/b
:Unicode26679
set Unicode_Result=样
exit/b
:Unicode样
set Unicode_Result=26679
exit/b
:Unicode28478
set Unicode_Result=漾
exit/b
:Unicode漾
set Unicode_Result=28478
exit/b
:Unicode36992
set Unicode_Result=邀
exit/b
:Unicode邀
set Unicode_Result=36992
exit/b
:Unicode33136
set Unicode_Result=腰
exit/b
:Unicode腰
set Unicode_Result=33136
exit/b
:Unicode22934
set Unicode_Result=妖
exit/b
:Unicode妖
set Unicode_Result=22934
exit/b
:Unicode29814
set Unicode_Result=瑶
exit/b
:Unicode瑶
set Unicode_Result=29814
exit/b
:Unicode25671
set Unicode_Result=摇
exit/b
:Unicode摇
set Unicode_Result=25671
exit/b
:Unicode23591
set Unicode_Result=尧
exit/b
:Unicode尧
set Unicode_Result=23591
exit/b
:Unicode36965
set Unicode_Result=遥
exit/b
:Unicode遥
set Unicode_Result=36965
exit/b
:Unicode31377
set Unicode_Result=窑
exit/b
:Unicode窑
set Unicode_Result=31377
exit/b
:Unicode35875
set Unicode_Result=谣
exit/b
:Unicode谣
set Unicode_Result=35875
exit/b
:Unicode23002
set Unicode_Result=姚
exit/b
:Unicode姚
set Unicode_Result=23002
exit/b
:Unicode21676
set Unicode_Result=咬
exit/b
:Unicode咬
set Unicode_Result=21676
exit/b
:Unicode33280
set Unicode_Result=舀
exit/b
:Unicode舀
set Unicode_Result=33280
exit/b
:Unicode33647
set Unicode_Result=药
exit/b
:Unicode药
set Unicode_Result=33647
exit/b
:Unicode35201
set Unicode_Result=要
exit/b
:Unicode要
set Unicode_Result=35201
exit/b
:Unicode32768
set Unicode_Result=耀
exit/b
:Unicode耀
set Unicode_Result=32768
exit/b
:Unicode26928
set Unicode_Result=椰
exit/b
:Unicode椰
set Unicode_Result=26928
exit/b
:Unicode22094
set Unicode_Result=噎
exit/b
:Unicode噎
set Unicode_Result=22094
exit/b
:Unicode32822
set Unicode_Result=耶
exit/b
:Unicode耶
set Unicode_Result=32822
exit/b
:Unicode29239
set Unicode_Result=爷
exit/b
:Unicode爷
set Unicode_Result=29239
exit/b
:Unicode37326
set Unicode_Result=野
exit/b
:Unicode野
set Unicode_Result=37326
exit/b
:Unicode20918
set Unicode_Result=冶
exit/b
:Unicode冶
set Unicode_Result=20918
exit/b
:Unicode20063
set Unicode_Result=也
exit/b
:Unicode也
set Unicode_Result=20063
exit/b
:Unicode39029
set Unicode_Result=页
exit/b
:Unicode页
set Unicode_Result=39029
exit/b
:Unicode25494
set Unicode_Result=掖
exit/b
:Unicode掖
set Unicode_Result=25494
exit/b
:Unicode19994
set Unicode_Result=业
exit/b
:Unicode业
set Unicode_Result=19994
exit/b
:Unicode21494
set Unicode_Result=叶
exit/b
:Unicode叶
set Unicode_Result=21494
exit/b
:Unicode26355
set Unicode_Result=曳
exit/b
:Unicode曳
set Unicode_Result=26355
exit/b
:Unicode33099
set Unicode_Result=腋
exit/b
:Unicode腋
set Unicode_Result=33099
exit/b
:Unicode22812
set Unicode_Result=夜
exit/b
:Unicode夜
set Unicode_Result=22812
exit/b
:Unicode28082
set Unicode_Result=液
exit/b
:Unicode液
set Unicode_Result=28082
exit/b
:Unicode19968
set Unicode_Result=一
exit/b
:Unicode一
set Unicode_Result=19968
exit/b
:Unicode22777
set Unicode_Result=壹
exit/b
:Unicode壹
set Unicode_Result=22777
exit/b
:Unicode21307
set Unicode_Result=医
exit/b
:Unicode医
set Unicode_Result=21307
exit/b
:Unicode25558
set Unicode_Result=揖
exit/b
:Unicode揖
set Unicode_Result=25558
exit/b
:Unicode38129
set Unicode_Result=铱
exit/b
:Unicode铱
set Unicode_Result=38129
exit/b
:Unicode20381
set Unicode_Result=依
exit/b
:Unicode依
set Unicode_Result=20381
exit/b
:Unicode20234
set Unicode_Result=伊
exit/b
:Unicode伊
set Unicode_Result=20234
exit/b
:Unicode34915
set Unicode_Result=衣
exit/b
:Unicode衣
set Unicode_Result=34915
exit/b
:Unicode39056
set Unicode_Result=颐
exit/b
:Unicode颐
set Unicode_Result=39056
exit/b
:Unicode22839
set Unicode_Result=夷
exit/b
:Unicode夷
set Unicode_Result=22839
exit/b
:Unicode36951
set Unicode_Result=遗
exit/b
:Unicode遗
set Unicode_Result=36951
exit/b
:Unicode31227
set Unicode_Result=移
exit/b
:Unicode移
set Unicode_Result=31227
exit/b
:Unicode20202
set Unicode_Result=仪
exit/b
:Unicode仪
set Unicode_Result=20202
exit/b
:Unicode33008
set Unicode_Result=胰
exit/b
:Unicode胰
set Unicode_Result=33008
exit/b
:Unicode30097
set Unicode_Result=疑
exit/b
:Unicode疑
set Unicode_Result=30097
exit/b
:Unicode27778
set Unicode_Result=沂
exit/b
:Unicode沂
set Unicode_Result=27778
exit/b
:Unicode23452
set Unicode_Result=宜
exit/b
:Unicode宜
set Unicode_Result=23452
exit/b
:Unicode23016
set Unicode_Result=姨
exit/b
:Unicode姨
set Unicode_Result=23016
exit/b
:Unicode24413
set Unicode_Result=彝
exit/b
:Unicode彝
set Unicode_Result=24413
exit/b
:Unicode26885
set Unicode_Result=椅
exit/b
:Unicode椅
set Unicode_Result=26885
exit/b
:Unicode34433
set Unicode_Result=蚁
exit/b
:Unicode蚁
set Unicode_Result=34433
exit/b
:Unicode20506
set Unicode_Result=倚
exit/b
:Unicode倚
set Unicode_Result=20506
exit/b
:Unicode24050
set Unicode_Result=已
exit/b
:Unicode已
set Unicode_Result=24050
exit/b
:Unicode20057
set Unicode_Result=乙
exit/b
:Unicode乙
set Unicode_Result=20057
exit/b
:Unicode30691
set Unicode_Result=矣
exit/b
:Unicode矣
set Unicode_Result=30691
exit/b
:Unicode20197
set Unicode_Result=以
exit/b
:Unicode以
set Unicode_Result=20197
exit/b
:Unicode33402
set Unicode_Result=艺
exit/b
:Unicode艺
set Unicode_Result=33402
exit/b
:Unicode25233
set Unicode_Result=抑
exit/b
:Unicode抑
set Unicode_Result=25233
exit/b
:Unicode26131
set Unicode_Result=易
exit/b
:Unicode易
set Unicode_Result=26131
exit/b
:Unicode37009
set Unicode_Result=邑
exit/b
:Unicode邑
set Unicode_Result=37009
exit/b
:Unicode23673
set Unicode_Result=屹
exit/b
:Unicode屹
set Unicode_Result=23673
exit/b
:Unicode20159
set Unicode_Result=亿
exit/b
:Unicode亿
set Unicode_Result=20159
exit/b
:Unicode24441
set Unicode_Result=役
exit/b
:Unicode役
set Unicode_Result=24441
exit/b
:Unicode33222
set Unicode_Result=臆
exit/b
:Unicode臆
set Unicode_Result=33222
exit/b
:Unicode36920
set Unicode_Result=逸
exit/b
:Unicode逸
set Unicode_Result=36920
exit/b
:Unicode32900
set Unicode_Result=肄
exit/b
:Unicode肄
set Unicode_Result=32900
exit/b
:Unicode30123
set Unicode_Result=疫
exit/b
:Unicode疫
set Unicode_Result=30123
exit/b
:Unicode20134
set Unicode_Result=亦
exit/b
:Unicode亦
set Unicode_Result=20134
exit/b
:Unicode35028
set Unicode_Result=裔
exit/b
:Unicode裔
set Unicode_Result=35028
exit/b
:Unicode24847
set Unicode_Result=意
exit/b
:Unicode意
set Unicode_Result=24847
exit/b
:Unicode27589
set Unicode_Result=毅
exit/b
:Unicode毅
set Unicode_Result=27589
exit/b
:Unicode24518
set Unicode_Result=忆
exit/b
:Unicode忆
set Unicode_Result=24518
exit/b
:Unicode20041
set Unicode_Result=义
exit/b
:Unicode义
set Unicode_Result=20041
exit/b
:Unicode30410
set Unicode_Result=益
exit/b
:Unicode益
set Unicode_Result=30410
exit/b
:Unicode28322
set Unicode_Result=溢
exit/b
:Unicode溢
set Unicode_Result=28322
exit/b
:Unicode35811
set Unicode_Result=诣
exit/b
:Unicode诣
set Unicode_Result=35811
exit/b
:Unicode35758
set Unicode_Result=议
exit/b
:Unicode议
set Unicode_Result=35758
exit/b
:Unicode35850
set Unicode_Result=谊
exit/b
:Unicode谊
set Unicode_Result=35850
exit/b
:Unicode35793
set Unicode_Result=译
exit/b
:Unicode译
set Unicode_Result=35793
exit/b
:Unicode24322
set Unicode_Result=异
exit/b
:Unicode异
set Unicode_Result=24322
exit/b
:Unicode32764
set Unicode_Result=翼
exit/b
:Unicode翼
set Unicode_Result=32764
exit/b
:Unicode32716
set Unicode_Result=翌
exit/b
:Unicode翌
set Unicode_Result=32716
exit/b
:Unicode32462
set Unicode_Result=绎
exit/b
:Unicode绎
set Unicode_Result=32462
exit/b
:Unicode33589
set Unicode_Result=茵
exit/b
:Unicode茵
set Unicode_Result=33589
exit/b
:Unicode33643
set Unicode_Result=荫
exit/b
:Unicode荫
set Unicode_Result=33643
exit/b
:Unicode22240
set Unicode_Result=因
exit/b
:Unicode因
set Unicode_Result=22240
exit/b
:Unicode27575
set Unicode_Result=殷
exit/b
:Unicode殷
set Unicode_Result=27575
exit/b
:Unicode38899
set Unicode_Result=音
exit/b
:Unicode音
set Unicode_Result=38899
exit/b
:Unicode38452
set Unicode_Result=阴
exit/b
:Unicode阴
set Unicode_Result=38452
exit/b
:Unicode23035
set Unicode_Result=姻
exit/b
:Unicode姻
set Unicode_Result=23035
exit/b
:Unicode21535
set Unicode_Result=吟
exit/b
:Unicode吟
set Unicode_Result=21535
exit/b
:Unicode38134
set Unicode_Result=银
exit/b
:Unicode银
set Unicode_Result=38134
exit/b
:Unicode28139
set Unicode_Result=淫
exit/b
:Unicode淫
set Unicode_Result=28139
exit/b
:Unicode23493
set Unicode_Result=寅
exit/b
:Unicode寅
set Unicode_Result=23493
exit/b
:Unicode39278
set Unicode_Result=饮
exit/b
:Unicode饮
set Unicode_Result=39278
exit/b
:Unicode23609
set Unicode_Result=尹
exit/b
:Unicode尹
set Unicode_Result=23609
exit/b
:Unicode24341
set Unicode_Result=引
exit/b
:Unicode引
set Unicode_Result=24341
exit/b
:Unicode38544
set Unicode_Result=隐
exit/b
:Unicode隐
set Unicode_Result=38544
exit/b
:Unicode21360
set Unicode_Result=印
exit/b
:Unicode印
set Unicode_Result=21360
exit/b
:Unicode33521
set Unicode_Result=英
exit/b
:Unicode英
set Unicode_Result=33521
exit/b
:Unicode27185
set Unicode_Result=樱
exit/b
:Unicode樱
set Unicode_Result=27185
exit/b
:Unicode23156
set Unicode_Result=婴
exit/b
:Unicode婴
set Unicode_Result=23156
exit/b
:Unicode40560
set Unicode_Result=鹰
exit/b
:Unicode鹰
set Unicode_Result=40560
exit/b
:Unicode24212
set Unicode_Result=应
exit/b
:Unicode应
set Unicode_Result=24212
exit/b
:Unicode32552
set Unicode_Result=缨
exit/b
:Unicode缨
set Unicode_Result=32552
exit/b
:Unicode33721
set Unicode_Result=莹
exit/b
:Unicode莹
set Unicode_Result=33721
exit/b
:Unicode33828
set Unicode_Result=萤
exit/b
:Unicode萤
set Unicode_Result=33828
exit/b
:Unicode33829
set Unicode_Result=营
exit/b
:Unicode营
set Unicode_Result=33829
exit/b
:Unicode33639
set Unicode_Result=荧
exit/b
:Unicode荧
set Unicode_Result=33639
exit/b
:Unicode34631
set Unicode_Result=蝇
exit/b
:Unicode蝇
set Unicode_Result=34631
exit/b
:Unicode36814
set Unicode_Result=迎
exit/b
:Unicode迎
set Unicode_Result=36814
exit/b
:Unicode36194
set Unicode_Result=赢
exit/b
:Unicode赢
set Unicode_Result=36194
exit/b
:Unicode30408
set Unicode_Result=盈
exit/b
:Unicode盈
set Unicode_Result=30408
exit/b
:Unicode24433
set Unicode_Result=影
exit/b
:Unicode影
set Unicode_Result=24433
exit/b
:Unicode39062
set Unicode_Result=颖
exit/b
:Unicode颖
set Unicode_Result=39062
exit/b
:Unicode30828
set Unicode_Result=硬
exit/b
:Unicode硬
set Unicode_Result=30828
exit/b
:Unicode26144
set Unicode_Result=映
exit/b
:Unicode映
set Unicode_Result=26144
exit/b
:Unicode21727
set Unicode_Result=哟
exit/b
:Unicode哟
set Unicode_Result=21727
exit/b
:Unicode25317
set Unicode_Result=拥
exit/b
:Unicode拥
set Unicode_Result=25317
exit/b
:Unicode20323
set Unicode_Result=佣
exit/b
:Unicode佣
set Unicode_Result=20323
exit/b
:Unicode33219
set Unicode_Result=臃
exit/b
:Unicode臃
set Unicode_Result=33219
exit/b
:Unicode30152
set Unicode_Result=痈
exit/b
:Unicode痈
set Unicode_Result=30152
exit/b
:Unicode24248
set Unicode_Result=庸
exit/b
:Unicode庸
set Unicode_Result=24248
exit/b
:Unicode38605
set Unicode_Result=雍
exit/b
:Unicode雍
set Unicode_Result=38605
exit/b
:Unicode36362
set Unicode_Result=踊
exit/b
:Unicode踊
set Unicode_Result=36362
exit/b
:Unicode34553
set Unicode_Result=蛹
exit/b
:Unicode蛹
set Unicode_Result=34553
exit/b
:Unicode21647
set Unicode_Result=咏
exit/b
:Unicode咏
set Unicode_Result=21647
exit/b
:Unicode27891
set Unicode_Result=泳
exit/b
:Unicode泳
set Unicode_Result=27891
exit/b
:Unicode28044
set Unicode_Result=涌
exit/b
:Unicode涌
set Unicode_Result=28044
exit/b
:Unicode27704
set Unicode_Result=永
exit/b
:Unicode永
set Unicode_Result=27704
exit/b
:Unicode24703
set Unicode_Result=恿
exit/b
:Unicode恿
set Unicode_Result=24703
exit/b
:Unicode21191
set Unicode_Result=勇
exit/b
:Unicode勇
set Unicode_Result=21191
exit/b
:Unicode29992
set Unicode_Result=用
exit/b
:Unicode用
set Unicode_Result=29992
exit/b
:Unicode24189
set Unicode_Result=幽
exit/b
:Unicode幽
set Unicode_Result=24189
exit/b
:Unicode20248
set Unicode_Result=优
exit/b
:Unicode优
set Unicode_Result=20248
exit/b
:Unicode24736
set Unicode_Result=悠
exit/b
:Unicode悠
set Unicode_Result=24736
exit/b
:Unicode24551
set Unicode_Result=忧
exit/b
:Unicode忧
set Unicode_Result=24551
exit/b
:Unicode23588
set Unicode_Result=尤
exit/b
:Unicode尤
set Unicode_Result=23588
exit/b
:Unicode30001
set Unicode_Result=由
exit/b
:Unicode由
set Unicode_Result=30001
exit/b
:Unicode37038
set Unicode_Result=邮
exit/b
:Unicode邮
set Unicode_Result=37038
exit/b
:Unicode38080
set Unicode_Result=铀
exit/b
:Unicode铀
set Unicode_Result=38080
exit/b
:Unicode29369
set Unicode_Result=犹
exit/b
:Unicode犹
set Unicode_Result=29369
exit/b
:Unicode27833
set Unicode_Result=油
exit/b
:Unicode油
set Unicode_Result=27833
exit/b
:Unicode28216
set Unicode_Result=游
exit/b
:Unicode游
set Unicode_Result=28216
exit/b
:Unicode37193
set Unicode_Result=酉
exit/b
:Unicode酉
set Unicode_Result=37193
exit/b
:Unicode26377
set Unicode_Result=有
exit/b
:Unicode有
set Unicode_Result=26377
exit/b
:Unicode21451
set Unicode_Result=友
exit/b
:Unicode友
set Unicode_Result=21451
exit/b
:Unicode21491
set Unicode_Result=右
exit/b
:Unicode右
set Unicode_Result=21491
exit/b
:Unicode20305
set Unicode_Result=佑
exit/b
:Unicode佑
set Unicode_Result=20305
exit/b
:Unicode37321
set Unicode_Result=釉
exit/b
:Unicode釉
set Unicode_Result=37321
exit/b
:Unicode35825
set Unicode_Result=诱
exit/b
:Unicode诱
set Unicode_Result=35825
exit/b
:Unicode21448
set Unicode_Result=又
exit/b
:Unicode又
set Unicode_Result=21448
exit/b
:Unicode24188
set Unicode_Result=幼
exit/b
:Unicode幼
set Unicode_Result=24188
exit/b
:Unicode36802
set Unicode_Result=迂
exit/b
:Unicode迂
set Unicode_Result=36802
exit/b
:Unicode28132
set Unicode_Result=淤
exit/b
:Unicode淤
set Unicode_Result=28132
exit/b
:Unicode20110
set Unicode_Result=于
exit/b
:Unicode于
set Unicode_Result=20110
exit/b
:Unicode30402
set Unicode_Result=盂
exit/b
:Unicode盂
set Unicode_Result=30402
exit/b
:Unicode27014
set Unicode_Result=榆
exit/b
:Unicode榆
set Unicode_Result=27014
exit/b
:Unicode34398
set Unicode_Result=虞
exit/b
:Unicode虞
set Unicode_Result=34398
exit/b
:Unicode24858
set Unicode_Result=愚
exit/b
:Unicode愚
set Unicode_Result=24858
exit/b
:Unicode33286
set Unicode_Result=舆
exit/b
:Unicode舆
set Unicode_Result=33286
exit/b
:Unicode20313
set Unicode_Result=余
exit/b
:Unicode余
set Unicode_Result=20313
exit/b
:Unicode20446
set Unicode_Result=俞
exit/b
:Unicode俞
set Unicode_Result=20446
exit/b
:Unicode36926
set Unicode_Result=逾
exit/b
:Unicode逾
set Unicode_Result=36926
exit/b
:Unicode40060
set Unicode_Result=鱼
exit/b
:Unicode鱼
set Unicode_Result=40060
exit/b
:Unicode24841
set Unicode_Result=愉
exit/b
:Unicode愉
set Unicode_Result=24841
exit/b
:Unicode28189
set Unicode_Result=渝
exit/b
:Unicode渝
set Unicode_Result=28189
exit/b
:Unicode28180
set Unicode_Result=渔
exit/b
:Unicode渔
set Unicode_Result=28180
exit/b
:Unicode38533
set Unicode_Result=隅
exit/b
:Unicode隅
set Unicode_Result=38533
exit/b
:Unicode20104
set Unicode_Result=予
exit/b
:Unicode予
set Unicode_Result=20104
exit/b
:Unicode23089
set Unicode_Result=娱
exit/b
:Unicode娱
set Unicode_Result=23089
exit/b
:Unicode38632
set Unicode_Result=雨
exit/b
:Unicode雨
set Unicode_Result=38632
exit/b
:Unicode19982
set Unicode_Result=与
exit/b
:Unicode与
set Unicode_Result=19982
exit/b
:Unicode23679
set Unicode_Result=屿
exit/b
:Unicode屿
set Unicode_Result=23679
exit/b
:Unicode31161
set Unicode_Result=禹
exit/b
:Unicode禹
set Unicode_Result=31161
exit/b
:Unicode23431
set Unicode_Result=宇
exit/b
:Unicode宇
set Unicode_Result=23431
exit/b
:Unicode35821
set Unicode_Result=语
exit/b
:Unicode语
set Unicode_Result=35821
exit/b
:Unicode32701
set Unicode_Result=羽
exit/b
:Unicode羽
set Unicode_Result=32701
exit/b
:Unicode29577
set Unicode_Result=玉
exit/b
:Unicode玉
set Unicode_Result=29577
exit/b
:Unicode22495
set Unicode_Result=域
exit/b
:Unicode域
set Unicode_Result=22495
exit/b
:Unicode33419
set Unicode_Result=芋
exit/b
:Unicode芋
set Unicode_Result=33419
exit/b
:Unicode37057
set Unicode_Result=郁
exit/b
:Unicode郁
set Unicode_Result=37057
exit/b
:Unicode21505
set Unicode_Result=吁
exit/b
:Unicode吁
set Unicode_Result=21505
exit/b
:Unicode36935
set Unicode_Result=遇
exit/b
:Unicode遇
set Unicode_Result=36935
exit/b
:Unicode21947
set Unicode_Result=喻
exit/b
:Unicode喻
set Unicode_Result=21947
exit/b
:Unicode23786
set Unicode_Result=峪
exit/b
:Unicode峪
set Unicode_Result=23786
exit/b
:Unicode24481
set Unicode_Result=御
exit/b
:Unicode御
set Unicode_Result=24481
exit/b
:Unicode24840
set Unicode_Result=愈
exit/b
:Unicode愈
set Unicode_Result=24840
exit/b
:Unicode27442
set Unicode_Result=欲
exit/b
:Unicode欲
set Unicode_Result=27442
exit/b
:Unicode29425
set Unicode_Result=狱
exit/b
:Unicode狱
set Unicode_Result=29425
exit/b
:Unicode32946
set Unicode_Result=育
exit/b
:Unicode育
set Unicode_Result=32946
exit/b
:Unicode35465
set Unicode_Result=誉
exit/b
:Unicode誉
set Unicode_Result=35465
exit/b
:Unicode28020
set Unicode_Result=浴
exit/b
:Unicode浴
set Unicode_Result=28020
exit/b
:Unicode23507
set Unicode_Result=寓
exit/b
:Unicode寓
set Unicode_Result=23507
exit/b
:Unicode35029
set Unicode_Result=裕
exit/b
:Unicode裕
set Unicode_Result=35029
exit/b
:Unicode39044
set Unicode_Result=预
exit/b
:Unicode预
set Unicode_Result=39044
exit/b
:Unicode35947
set Unicode_Result=豫
exit/b
:Unicode豫
set Unicode_Result=35947
exit/b
:Unicode39533
set Unicode_Result=驭
exit/b
:Unicode驭
set Unicode_Result=39533
exit/b
:Unicode40499
set Unicode_Result=鸳
exit/b
:Unicode鸳
set Unicode_Result=40499
exit/b
:Unicode28170
set Unicode_Result=渊
exit/b
:Unicode渊
set Unicode_Result=28170
exit/b
:Unicode20900
set Unicode_Result=冤
exit/b
:Unicode冤
set Unicode_Result=20900
exit/b
:Unicode20803
set Unicode_Result=元
exit/b
:Unicode元
set Unicode_Result=20803
exit/b
:Unicode22435
set Unicode_Result=垣
exit/b
:Unicode垣
set Unicode_Result=22435
exit/b
:Unicode34945
set Unicode_Result=袁
exit/b
:Unicode袁
set Unicode_Result=34945
exit/b
:Unicode21407
set Unicode_Result=原
exit/b
:Unicode原
set Unicode_Result=21407
exit/b
:Unicode25588
set Unicode_Result=援
exit/b
:Unicode援
set Unicode_Result=25588
exit/b
:Unicode36757
set Unicode_Result=辕
exit/b
:Unicode辕
set Unicode_Result=36757
exit/b
:Unicode22253
set Unicode_Result=园
exit/b
:Unicode园
set Unicode_Result=22253
exit/b
:Unicode21592
set Unicode_Result=员
exit/b
:Unicode员
set Unicode_Result=21592
exit/b
:Unicode22278
set Unicode_Result=圆
exit/b
:Unicode圆
set Unicode_Result=22278
exit/b
:Unicode29503
set Unicode_Result=猿
exit/b
:Unicode猿
set Unicode_Result=29503
exit/b
:Unicode28304
set Unicode_Result=源
exit/b
:Unicode源
set Unicode_Result=28304
exit/b
:Unicode32536
set Unicode_Result=缘
exit/b
:Unicode缘
set Unicode_Result=32536
exit/b
:Unicode36828
set Unicode_Result=远
exit/b
:Unicode远
set Unicode_Result=36828
exit/b
:Unicode33489
set Unicode_Result=苑
exit/b
:Unicode苑
set Unicode_Result=33489
exit/b
:Unicode24895
set Unicode_Result=愿
exit/b
:Unicode愿
set Unicode_Result=24895
exit/b
:Unicode24616
set Unicode_Result=怨
exit/b
:Unicode怨
set Unicode_Result=24616
exit/b
:Unicode38498
set Unicode_Result=院
exit/b
:Unicode院
set Unicode_Result=38498
exit/b
:Unicode26352
set Unicode_Result=曰
exit/b
:Unicode曰
set Unicode_Result=26352
exit/b
:Unicode32422
set Unicode_Result=约
exit/b
:Unicode约
set Unicode_Result=32422
exit/b
:Unicode36234
set Unicode_Result=越
exit/b
:Unicode越
set Unicode_Result=36234
exit/b
:Unicode36291
set Unicode_Result=跃
exit/b
:Unicode跃
set Unicode_Result=36291
exit/b
:Unicode38053
set Unicode_Result=钥
exit/b
:Unicode钥
set Unicode_Result=38053
exit/b
:Unicode23731
set Unicode_Result=岳
exit/b
:Unicode岳
set Unicode_Result=23731
exit/b
:Unicode31908
set Unicode_Result=粤
exit/b
:Unicode粤
set Unicode_Result=31908
exit/b
:Unicode26376
set Unicode_Result=月
exit/b
:Unicode月
set Unicode_Result=26376
exit/b
:Unicode24742
set Unicode_Result=悦
exit/b
:Unicode悦
set Unicode_Result=24742
exit/b
:Unicode38405
set Unicode_Result=阅
exit/b
:Unicode阅
set Unicode_Result=38405
exit/b
:Unicode32792
set Unicode_Result=耘
exit/b
:Unicode耘
set Unicode_Result=32792
exit/b
:Unicode20113
set Unicode_Result=云
exit/b
:Unicode云
set Unicode_Result=20113
exit/b
:Unicode37095
set Unicode_Result=郧
exit/b
:Unicode郧
set Unicode_Result=37095
exit/b
:Unicode21248
set Unicode_Result=匀
exit/b
:Unicode匀
set Unicode_Result=21248
exit/b
:Unicode38504
set Unicode_Result=陨
exit/b
:Unicode陨
set Unicode_Result=38504
exit/b
:Unicode20801
set Unicode_Result=允
exit/b
:Unicode允
set Unicode_Result=20801
exit/b
:Unicode36816
set Unicode_Result=运
exit/b
:Unicode运
set Unicode_Result=36816
exit/b
:Unicode34164
set Unicode_Result=蕴
exit/b
:Unicode蕴
set Unicode_Result=34164
exit/b
:Unicode37213
set Unicode_Result=酝
exit/b
:Unicode酝
set Unicode_Result=37213
exit/b
:Unicode26197
set Unicode_Result=晕
exit/b
:Unicode晕
set Unicode_Result=26197
exit/b
:Unicode38901
set Unicode_Result=韵
exit/b
:Unicode韵
set Unicode_Result=38901
exit/b
:Unicode23381
set Unicode_Result=孕
exit/b
:Unicode孕
set Unicode_Result=23381
exit/b
:Unicode21277
set Unicode_Result=匝
exit/b
:Unicode匝
set Unicode_Result=21277
exit/b
:Unicode30776
set Unicode_Result=砸
exit/b
:Unicode砸
set Unicode_Result=30776
exit/b
:Unicode26434
set Unicode_Result=杂
exit/b
:Unicode杂
set Unicode_Result=26434
exit/b
:Unicode26685
set Unicode_Result=栽
exit/b
:Unicode栽
set Unicode_Result=26685
exit/b
:Unicode21705
set Unicode_Result=哉
exit/b
:Unicode哉
set Unicode_Result=21705
exit/b
:Unicode28798
set Unicode_Result=灾
exit/b
:Unicode灾
set Unicode_Result=28798
exit/b
:Unicode23472
set Unicode_Result=宰
exit/b
:Unicode宰
set Unicode_Result=23472
exit/b
:Unicode36733
set Unicode_Result=载
exit/b
:Unicode载
set Unicode_Result=36733
exit/b
:Unicode20877
set Unicode_Result=再
exit/b
:Unicode再
set Unicode_Result=20877
exit/b
:Unicode22312
set Unicode_Result=在
exit/b
:Unicode在
set Unicode_Result=22312
exit/b
:Unicode21681
set Unicode_Result=咱
exit/b
:Unicode咱
set Unicode_Result=21681
exit/b
:Unicode25874
set Unicode_Result=攒
exit/b
:Unicode攒
set Unicode_Result=25874
exit/b
:Unicode26242
set Unicode_Result=暂
exit/b
:Unicode暂
set Unicode_Result=26242
exit/b
:Unicode36190
set Unicode_Result=赞
exit/b
:Unicode赞
set Unicode_Result=36190
exit/b
:Unicode36163
set Unicode_Result=赃
exit/b
:Unicode赃
set Unicode_Result=36163
exit/b
:Unicode33039
set Unicode_Result=脏
exit/b
:Unicode脏
set Unicode_Result=33039
exit/b
:Unicode33900
set Unicode_Result=葬
exit/b
:Unicode葬
set Unicode_Result=33900
exit/b
:Unicode36973
set Unicode_Result=遭
exit/b
:Unicode遭
set Unicode_Result=36973
exit/b
:Unicode31967
set Unicode_Result=糟
exit/b
:Unicode糟
set Unicode_Result=31967
exit/b
:Unicode20991
set Unicode_Result=凿
exit/b
:Unicode凿
set Unicode_Result=20991
exit/b
:Unicode34299
set Unicode_Result=藻
exit/b
:Unicode藻
set Unicode_Result=34299
exit/b
:Unicode26531
set Unicode_Result=枣
exit/b
:Unicode枣
set Unicode_Result=26531
exit/b
:Unicode26089
set Unicode_Result=早
exit/b
:Unicode早
set Unicode_Result=26089
exit/b
:Unicode28577
set Unicode_Result=澡
exit/b
:Unicode澡
set Unicode_Result=28577
exit/b
:Unicode34468
set Unicode_Result=蚤
exit/b
:Unicode蚤
set Unicode_Result=34468
exit/b
:Unicode36481
set Unicode_Result=躁
exit/b
:Unicode躁
set Unicode_Result=36481
exit/b
:Unicode22122
set Unicode_Result=噪
exit/b
:Unicode噪
set Unicode_Result=22122
exit/b
:Unicode36896
set Unicode_Result=造
exit/b
:Unicode造
set Unicode_Result=36896
exit/b
:Unicode30338
set Unicode_Result=皂
exit/b
:Unicode皂
set Unicode_Result=30338
exit/b
:Unicode28790
set Unicode_Result=灶
exit/b
:Unicode灶
set Unicode_Result=28790
exit/b
:Unicode29157
set Unicode_Result=燥
exit/b
:Unicode燥
set Unicode_Result=29157
exit/b
:Unicode36131
set Unicode_Result=责
exit/b
:Unicode责
set Unicode_Result=36131
exit/b
:Unicode25321
set Unicode_Result=择
exit/b
:Unicode择
set Unicode_Result=25321
exit/b
:Unicode21017
set Unicode_Result=则
exit/b
:Unicode则
set Unicode_Result=21017
exit/b
:Unicode27901
set Unicode_Result=泽
exit/b
:Unicode泽
set Unicode_Result=27901
exit/b
:Unicode36156
set Unicode_Result=贼
exit/b
:Unicode贼
set Unicode_Result=36156
exit/b
:Unicode24590
set Unicode_Result=怎
exit/b
:Unicode怎
set Unicode_Result=24590
exit/b
:Unicode22686
set Unicode_Result=增
exit/b
:Unicode增
set Unicode_Result=22686
exit/b
:Unicode24974
set Unicode_Result=憎
exit/b
:Unicode憎
set Unicode_Result=24974
exit/b
:Unicode26366
set Unicode_Result=曾
exit/b
:Unicode曾
set Unicode_Result=26366
exit/b
:Unicode36192
set Unicode_Result=赠
exit/b
:Unicode赠
set Unicode_Result=36192
exit/b
:Unicode25166
set Unicode_Result=扎
exit/b
:Unicode扎
set Unicode_Result=25166
exit/b
:Unicode21939
set Unicode_Result=喳
exit/b
:Unicode喳
set Unicode_Result=21939
exit/b
:Unicode28195
set Unicode_Result=渣
exit/b
:Unicode渣
set Unicode_Result=28195
exit/b
:Unicode26413
set Unicode_Result=札
exit/b
:Unicode札
set Unicode_Result=26413
exit/b
:Unicode36711
set Unicode_Result=轧
exit/b
:Unicode轧
set Unicode_Result=36711
exit/b
:Unicode38113
set Unicode_Result=铡
exit/b
:Unicode铡
set Unicode_Result=38113
exit/b
:Unicode38392
set Unicode_Result=闸
exit/b
:Unicode闸
set Unicode_Result=38392
exit/b
:Unicode30504
set Unicode_Result=眨
exit/b
:Unicode眨
set Unicode_Result=30504
exit/b
:Unicode26629
set Unicode_Result=栅
exit/b
:Unicode栅
set Unicode_Result=26629
exit/b
:Unicode27048
set Unicode_Result=榨
exit/b
:Unicode榨
set Unicode_Result=27048
exit/b
:Unicode21643
set Unicode_Result=咋
exit/b
:Unicode咋
set Unicode_Result=21643
exit/b
:Unicode20045
set Unicode_Result=乍
exit/b
:Unicode乍
set Unicode_Result=20045
exit/b
:Unicode28856
set Unicode_Result=炸
exit/b
:Unicode炸
set Unicode_Result=28856
exit/b
:Unicode35784
set Unicode_Result=诈
exit/b
:Unicode诈
set Unicode_Result=35784
exit/b
:Unicode25688
set Unicode_Result=摘
exit/b
:Unicode摘
set Unicode_Result=25688
exit/b
:Unicode25995
set Unicode_Result=斋
exit/b
:Unicode斋
set Unicode_Result=25995
exit/b
:Unicode23429
set Unicode_Result=宅
exit/b
:Unicode宅
set Unicode_Result=23429
exit/b
:Unicode31364
set Unicode_Result=窄
exit/b
:Unicode窄
set Unicode_Result=31364
exit/b
:Unicode20538
set Unicode_Result=债
exit/b
:Unicode债
set Unicode_Result=20538
exit/b
:Unicode23528
set Unicode_Result=寨
exit/b
:Unicode寨
set Unicode_Result=23528
exit/b
:Unicode30651
set Unicode_Result=瞻
exit/b
:Unicode瞻
set Unicode_Result=30651
exit/b
:Unicode27617
set Unicode_Result=毡
exit/b
:Unicode毡
set Unicode_Result=27617
exit/b
:Unicode35449
set Unicode_Result=詹
exit/b
:Unicode詹
set Unicode_Result=35449
exit/b
:Unicode31896
set Unicode_Result=粘
exit/b
:Unicode粘
set Unicode_Result=31896
exit/b
:Unicode27838
set Unicode_Result=沾
exit/b
:Unicode沾
set Unicode_Result=27838
exit/b
:Unicode30415
set Unicode_Result=盏
exit/b
:Unicode盏
set Unicode_Result=30415
exit/b
:Unicode26025
set Unicode_Result=斩
exit/b
:Unicode斩
set Unicode_Result=26025
exit/b
:Unicode36759
set Unicode_Result=辗
exit/b
:Unicode辗
set Unicode_Result=36759
exit/b
:Unicode23853
set Unicode_Result=崭
exit/b
:Unicode崭
set Unicode_Result=23853
exit/b
:Unicode23637
set Unicode_Result=展
exit/b
:Unicode展
set Unicode_Result=23637
exit/b
:Unicode34360
set Unicode_Result=蘸
exit/b
:Unicode蘸
set Unicode_Result=34360
exit/b
:Unicode26632
set Unicode_Result=栈
exit/b
:Unicode栈
set Unicode_Result=26632
exit/b
:Unicode21344
set Unicode_Result=占
exit/b
:Unicode占
set Unicode_Result=21344
exit/b
:Unicode25112
set Unicode_Result=战
exit/b
:Unicode战
set Unicode_Result=25112
exit/b
:Unicode31449
set Unicode_Result=站
exit/b
:Unicode站
set Unicode_Result=31449
exit/b
:Unicode28251
set Unicode_Result=湛
exit/b
:Unicode湛
set Unicode_Result=28251
exit/b
:Unicode32509
set Unicode_Result=绽
exit/b
:Unicode绽
set Unicode_Result=32509
exit/b
:Unicode27167
set Unicode_Result=樟
exit/b
:Unicode樟
set Unicode_Result=27167
exit/b
:Unicode31456
set Unicode_Result=章
exit/b
:Unicode章
set Unicode_Result=31456
exit/b
:Unicode24432
set Unicode_Result=彰
exit/b
:Unicode彰
set Unicode_Result=24432
exit/b
:Unicode28467
set Unicode_Result=漳
exit/b
:Unicode漳
set Unicode_Result=28467
exit/b
:Unicode24352
set Unicode_Result=张
exit/b
:Unicode张
set Unicode_Result=24352
exit/b
:Unicode25484
set Unicode_Result=掌
exit/b
:Unicode掌
set Unicode_Result=25484
exit/b
:Unicode28072
set Unicode_Result=涨
exit/b
:Unicode涨
set Unicode_Result=28072
exit/b
:Unicode26454
set Unicode_Result=杖
exit/b
:Unicode杖
set Unicode_Result=26454
exit/b
:Unicode19976
set Unicode_Result=丈
exit/b
:Unicode丈
set Unicode_Result=19976
exit/b
:Unicode24080
set Unicode_Result=帐
exit/b
:Unicode帐
set Unicode_Result=24080
exit/b
:Unicode36134
set Unicode_Result=账
exit/b
:Unicode账
set Unicode_Result=36134
exit/b
:Unicode20183
set Unicode_Result=仗
exit/b
:Unicode仗
set Unicode_Result=20183
exit/b
:Unicode32960
set Unicode_Result=胀
exit/b
:Unicode胀
set Unicode_Result=32960
exit/b
:Unicode30260
set Unicode_Result=瘴
exit/b
:Unicode瘴
set Unicode_Result=30260
exit/b
:Unicode38556
set Unicode_Result=障
exit/b
:Unicode障
set Unicode_Result=38556
exit/b
:Unicode25307
set Unicode_Result=招
exit/b
:Unicode招
set Unicode_Result=25307
exit/b
:Unicode26157
set Unicode_Result=昭
exit/b
:Unicode昭
set Unicode_Result=26157
exit/b
:Unicode25214
set Unicode_Result=找
exit/b
:Unicode找
set Unicode_Result=25214
exit/b
:Unicode27836
set Unicode_Result=沼
exit/b
:Unicode沼
set Unicode_Result=27836
exit/b
:Unicode36213
set Unicode_Result=赵
exit/b
:Unicode赵
set Unicode_Result=36213
exit/b
:Unicode29031
set Unicode_Result=照
exit/b
:Unicode照
set Unicode_Result=29031
exit/b
:Unicode32617
set Unicode_Result=罩
exit/b
:Unicode罩
set Unicode_Result=32617
exit/b
:Unicode20806
set Unicode_Result=兆
exit/b
:Unicode兆
set Unicode_Result=20806
exit/b
:Unicode32903
set Unicode_Result=肇
exit/b
:Unicode肇
set Unicode_Result=32903
exit/b
:Unicode21484
set Unicode_Result=召
exit/b
:Unicode召
set Unicode_Result=21484
exit/b
:Unicode36974
set Unicode_Result=遮
exit/b
:Unicode遮
set Unicode_Result=36974
exit/b
:Unicode25240
set Unicode_Result=折
exit/b
:Unicode折
set Unicode_Result=25240
exit/b
:Unicode21746
set Unicode_Result=哲
exit/b
:Unicode哲
set Unicode_Result=21746
exit/b
:Unicode34544
set Unicode_Result=蛰
exit/b
:Unicode蛰
set Unicode_Result=34544
exit/b
:Unicode36761
set Unicode_Result=辙
exit/b
:Unicode辙
set Unicode_Result=36761
exit/b
:Unicode32773
set Unicode_Result=者
exit/b
:Unicode者
set Unicode_Result=32773
exit/b
:Unicode38167
set Unicode_Result=锗
exit/b
:Unicode锗
set Unicode_Result=38167
exit/b
:Unicode34071
set Unicode_Result=蔗
exit/b
:Unicode蔗
set Unicode_Result=34071
exit/b
:Unicode36825
set Unicode_Result=这
exit/b
:Unicode这
set Unicode_Result=36825
exit/b
:Unicode27993
set Unicode_Result=浙
exit/b
:Unicode浙
set Unicode_Result=27993
exit/b
:Unicode29645
set Unicode_Result=珍
exit/b
:Unicode珍
set Unicode_Result=29645
exit/b
:Unicode26015
set Unicode_Result=斟
exit/b
:Unicode斟
set Unicode_Result=26015
exit/b
:Unicode30495
set Unicode_Result=真
exit/b
:Unicode真
set Unicode_Result=30495
exit/b
:Unicode29956
set Unicode_Result=甄
exit/b
:Unicode甄
set Unicode_Result=29956
exit/b
:Unicode30759
set Unicode_Result=砧
exit/b
:Unicode砧
set Unicode_Result=30759
exit/b
:Unicode33275
set Unicode_Result=臻
exit/b
:Unicode臻
set Unicode_Result=33275
exit/b
:Unicode36126
set Unicode_Result=贞
exit/b
:Unicode贞
set Unicode_Result=36126
exit/b
:Unicode38024
set Unicode_Result=针
exit/b
:Unicode针
set Unicode_Result=38024
exit/b
:Unicode20390
set Unicode_Result=侦
exit/b
:Unicode侦
set Unicode_Result=20390
exit/b
:Unicode26517
set Unicode_Result=枕
exit/b
:Unicode枕
set Unicode_Result=26517
exit/b
:Unicode30137
set Unicode_Result=疹
exit/b
:Unicode疹
set Unicode_Result=30137
exit/b
:Unicode35786
set Unicode_Result=诊
exit/b
:Unicode诊
set Unicode_Result=35786
exit/b
:Unicode38663
set Unicode_Result=震
exit/b
:Unicode震
set Unicode_Result=38663
exit/b
:Unicode25391
set Unicode_Result=振
exit/b
:Unicode振
set Unicode_Result=25391
exit/b
:Unicode38215
set Unicode_Result=镇
exit/b
:Unicode镇
set Unicode_Result=38215
exit/b
:Unicode38453
set Unicode_Result=阵
exit/b
:Unicode阵
set Unicode_Result=38453
exit/b
:Unicode33976
set Unicode_Result=蒸
exit/b
:Unicode蒸
set Unicode_Result=33976
exit/b
:Unicode25379
set Unicode_Result=挣
exit/b
:Unicode挣
set Unicode_Result=25379
exit/b
:Unicode30529
set Unicode_Result=睁
exit/b
:Unicode睁
set Unicode_Result=30529
exit/b
:Unicode24449
set Unicode_Result=征
exit/b
:Unicode征
set Unicode_Result=24449
exit/b
:Unicode29424
set Unicode_Result=狰
exit/b
:Unicode狰
set Unicode_Result=29424
exit/b
:Unicode20105
set Unicode_Result=争
exit/b
:Unicode争
set Unicode_Result=20105
exit/b
:Unicode24596
set Unicode_Result=怔
exit/b
:Unicode怔
set Unicode_Result=24596
exit/b
:Unicode25972
set Unicode_Result=整
exit/b
:Unicode整
set Unicode_Result=25972
exit/b
:Unicode25327
set Unicode_Result=拯
exit/b
:Unicode拯
set Unicode_Result=25327
exit/b
:Unicode27491
set Unicode_Result=正
exit/b
:Unicode正
set Unicode_Result=27491
exit/b
:Unicode25919
set Unicode_Result=政
exit/b
:Unicode政
set Unicode_Result=25919
exit/b
:Unicode24103
set Unicode_Result=帧
exit/b
:Unicode帧
set Unicode_Result=24103
exit/b
:Unicode30151
set Unicode_Result=症
exit/b
:Unicode症
set Unicode_Result=30151
exit/b
:Unicode37073
set Unicode_Result=郑
exit/b
:Unicode郑
set Unicode_Result=37073
exit/b
:Unicode35777
set Unicode_Result=证
exit/b
:Unicode证
set Unicode_Result=35777
exit/b
:Unicode33437
set Unicode_Result=芝
exit/b
:Unicode芝
set Unicode_Result=33437
exit/b
:Unicode26525
set Unicode_Result=枝
exit/b
:Unicode枝
set Unicode_Result=26525
exit/b
:Unicode25903
set Unicode_Result=支
exit/b
:Unicode支
set Unicode_Result=25903
exit/b
:Unicode21553
set Unicode_Result=吱
exit/b
:Unicode吱
set Unicode_Result=21553
exit/b
:Unicode34584
set Unicode_Result=蜘
exit/b
:Unicode蜘
set Unicode_Result=34584
exit/b
:Unicode30693
set Unicode_Result=知
exit/b
:Unicode知
set Unicode_Result=30693
exit/b
:Unicode32930
set Unicode_Result=肢
exit/b
:Unicode肢
set Unicode_Result=32930
exit/b
:Unicode33026
set Unicode_Result=脂
exit/b
:Unicode脂
set Unicode_Result=33026
exit/b
:Unicode27713
set Unicode_Result=汁
exit/b
:Unicode汁
set Unicode_Result=27713
exit/b
:Unicode20043
set Unicode_Result=之
exit/b
:Unicode之
set Unicode_Result=20043
exit/b
:Unicode32455
set Unicode_Result=织
exit/b
:Unicode织
set Unicode_Result=32455
exit/b
:Unicode32844
set Unicode_Result=职
exit/b
:Unicode职
set Unicode_Result=32844
exit/b
:Unicode30452
set Unicode_Result=直
exit/b
:Unicode直
set Unicode_Result=30452
exit/b
:Unicode26893
set Unicode_Result=植
exit/b
:Unicode植
set Unicode_Result=26893
exit/b
:Unicode27542
set Unicode_Result=殖
exit/b
:Unicode殖
set Unicode_Result=27542
exit/b
:Unicode25191
set Unicode_Result=执
exit/b
:Unicode执
set Unicode_Result=25191
exit/b
:Unicode20540
set Unicode_Result=值
exit/b
:Unicode值
set Unicode_Result=20540
exit/b
:Unicode20356
set Unicode_Result=侄
exit/b
:Unicode侄
set Unicode_Result=20356
exit/b
:Unicode22336
set Unicode_Result=址
exit/b
:Unicode址
set Unicode_Result=22336
exit/b
:Unicode25351
set Unicode_Result=指
exit/b
:Unicode指
set Unicode_Result=25351
exit/b
:Unicode27490
set Unicode_Result=止
exit/b
:Unicode止
set Unicode_Result=27490
exit/b
:Unicode36286
set Unicode_Result=趾
exit/b
:Unicode趾
set Unicode_Result=36286
exit/b
:Unicode21482
set Unicode_Result=只
exit/b
:Unicode只
set Unicode_Result=21482
exit/b
:Unicode26088
set Unicode_Result=旨
exit/b
:Unicode旨
set Unicode_Result=26088
exit/b
:Unicode32440
set Unicode_Result=纸
exit/b
:Unicode纸
set Unicode_Result=32440
exit/b
:Unicode24535
set Unicode_Result=志
exit/b
:Unicode志
set Unicode_Result=24535
exit/b
:Unicode25370
set Unicode_Result=挚
exit/b
:Unicode挚
set Unicode_Result=25370
exit/b
:Unicode25527
set Unicode_Result=掷
exit/b
:Unicode掷
set Unicode_Result=25527
exit/b
:Unicode33267
set Unicode_Result=至
exit/b
:Unicode至
set Unicode_Result=33267
exit/b
:Unicode33268
set Unicode_Result=致
exit/b
:Unicode致
set Unicode_Result=33268
exit/b
:Unicode32622
set Unicode_Result=置
exit/b
:Unicode置
set Unicode_Result=32622
exit/b
:Unicode24092
set Unicode_Result=帜
exit/b
:Unicode帜
set Unicode_Result=24092
exit/b
:Unicode23769
set Unicode_Result=峙
exit/b
:Unicode峙
set Unicode_Result=23769
exit/b
:Unicode21046
set Unicode_Result=制
exit/b
:Unicode制
set Unicode_Result=21046
exit/b
:Unicode26234
set Unicode_Result=智
exit/b
:Unicode智
set Unicode_Result=26234
exit/b
:Unicode31209
set Unicode_Result=秩
exit/b
:Unicode秩
set Unicode_Result=31209
exit/b
:Unicode31258
set Unicode_Result=稚
exit/b
:Unicode稚
set Unicode_Result=31258
exit/b
:Unicode36136
set Unicode_Result=质
exit/b
:Unicode质
set Unicode_Result=36136
exit/b
:Unicode28825
set Unicode_Result=炙
exit/b
:Unicode炙
set Unicode_Result=28825
exit/b
:Unicode30164
set Unicode_Result=痔
exit/b
:Unicode痔
set Unicode_Result=30164
exit/b
:Unicode28382
set Unicode_Result=滞
exit/b
:Unicode滞
set Unicode_Result=28382
exit/b
:Unicode27835
set Unicode_Result=治
exit/b
:Unicode治
set Unicode_Result=27835
exit/b
:Unicode31378
set Unicode_Result=窒
exit/b
:Unicode窒
set Unicode_Result=31378
exit/b
:Unicode20013
set Unicode_Result=中
exit/b
:Unicode中
set Unicode_Result=20013
exit/b
:Unicode30405
set Unicode_Result=盅
exit/b
:Unicode盅
set Unicode_Result=30405
exit/b
:Unicode24544
set Unicode_Result=忠
exit/b
:Unicode忠
set Unicode_Result=24544
exit/b
:Unicode38047
set Unicode_Result=钟
exit/b
:Unicode钟
set Unicode_Result=38047
exit/b
:Unicode34935
set Unicode_Result=衷
exit/b
:Unicode衷
set Unicode_Result=34935
exit/b
:Unicode32456
set Unicode_Result=终
exit/b
:Unicode终
set Unicode_Result=32456
exit/b
:Unicode31181
set Unicode_Result=种
exit/b
:Unicode种
set Unicode_Result=31181
exit/b
:Unicode32959
set Unicode_Result=肿
exit/b
:Unicode肿
set Unicode_Result=32959
exit/b
:Unicode37325
set Unicode_Result=重
exit/b
:Unicode重
set Unicode_Result=37325
exit/b
:Unicode20210
set Unicode_Result=仲
exit/b
:Unicode仲
set Unicode_Result=20210
exit/b
:Unicode20247
set Unicode_Result=众
exit/b
:Unicode众
set Unicode_Result=20247
exit/b
:Unicode33311
set Unicode_Result=舟
exit/b
:Unicode舟
set Unicode_Result=33311
exit/b
:Unicode21608
set Unicode_Result=周
exit/b
:Unicode周
set Unicode_Result=21608
exit/b
:Unicode24030
set Unicode_Result=州
exit/b
:Unicode州
set Unicode_Result=24030
exit/b
:Unicode27954
set Unicode_Result=洲
exit/b
:Unicode洲
set Unicode_Result=27954
exit/b
:Unicode35788
set Unicode_Result=诌
exit/b
:Unicode诌
set Unicode_Result=35788
exit/b
:Unicode31909
set Unicode_Result=粥
exit/b
:Unicode粥
set Unicode_Result=31909
exit/b
:Unicode36724
set Unicode_Result=轴
exit/b
:Unicode轴
set Unicode_Result=36724
exit/b
:Unicode32920
set Unicode_Result=肘
exit/b
:Unicode肘
set Unicode_Result=32920
exit/b
:Unicode24090
set Unicode_Result=帚
exit/b
:Unicode帚
set Unicode_Result=24090
exit/b
:Unicode21650
set Unicode_Result=咒
exit/b
:Unicode咒
set Unicode_Result=21650
exit/b
:Unicode30385
set Unicode_Result=皱
exit/b
:Unicode皱
set Unicode_Result=30385
exit/b
:Unicode23449
set Unicode_Result=宙
exit/b
:Unicode宙
set Unicode_Result=23449
exit/b
:Unicode26172
set Unicode_Result=昼
exit/b
:Unicode昼
set Unicode_Result=26172
exit/b
:Unicode39588
set Unicode_Result=骤
exit/b
:Unicode骤
set Unicode_Result=39588
exit/b
:Unicode29664
set Unicode_Result=珠
exit/b
:Unicode珠
set Unicode_Result=29664
exit/b
:Unicode26666
set Unicode_Result=株
exit/b
:Unicode株
set Unicode_Result=26666
exit/b
:Unicode34523
set Unicode_Result=蛛
exit/b
:Unicode蛛
set Unicode_Result=34523
exit/b
:Unicode26417
set Unicode_Result=朱
exit/b
:Unicode朱
set Unicode_Result=26417
exit/b
:Unicode29482
set Unicode_Result=猪
exit/b
:Unicode猪
set Unicode_Result=29482
exit/b
:Unicode35832
set Unicode_Result=诸
exit/b
:Unicode诸
set Unicode_Result=35832
exit/b
:Unicode35803
set Unicode_Result=诛
exit/b
:Unicode诛
set Unicode_Result=35803
exit/b
:Unicode36880
set Unicode_Result=逐
exit/b
:Unicode逐
set Unicode_Result=36880
exit/b
:Unicode31481
set Unicode_Result=竹
exit/b
:Unicode竹
set Unicode_Result=31481
exit/b
:Unicode28891
set Unicode_Result=烛
exit/b
:Unicode烛
set Unicode_Result=28891
exit/b
:Unicode29038
set Unicode_Result=煮
exit/b
:Unicode煮
set Unicode_Result=29038
exit/b
:Unicode25284
set Unicode_Result=拄
exit/b
:Unicode拄
set Unicode_Result=25284
exit/b
:Unicode30633
set Unicode_Result=瞩
exit/b
:Unicode瞩
set Unicode_Result=30633
exit/b
:Unicode22065
set Unicode_Result=嘱
exit/b
:Unicode嘱
set Unicode_Result=22065
exit/b
:Unicode20027
set Unicode_Result=主
exit/b
:Unicode主
set Unicode_Result=20027
exit/b
:Unicode33879
set Unicode_Result=著
exit/b
:Unicode著
set Unicode_Result=33879
exit/b
:Unicode26609
set Unicode_Result=柱
exit/b
:Unicode柱
set Unicode_Result=26609
exit/b
:Unicode21161
set Unicode_Result=助
exit/b
:Unicode助
set Unicode_Result=21161
exit/b
:Unicode34496
set Unicode_Result=蛀
exit/b
:Unicode蛀
set Unicode_Result=34496
exit/b
:Unicode36142
set Unicode_Result=贮
exit/b
:Unicode贮
set Unicode_Result=36142
exit/b
:Unicode38136
set Unicode_Result=铸
exit/b
:Unicode铸
set Unicode_Result=38136
exit/b
:Unicode31569
set Unicode_Result=筑
exit/b
:Unicode筑
set Unicode_Result=31569
exit/b
:Unicode20303
set Unicode_Result=住
exit/b
:Unicode住
set Unicode_Result=20303
exit/b
:Unicode27880
set Unicode_Result=注
exit/b
:Unicode注
set Unicode_Result=27880
exit/b
:Unicode31069
set Unicode_Result=祝
exit/b
:Unicode祝
set Unicode_Result=31069
exit/b
:Unicode39547
set Unicode_Result=驻
exit/b
:Unicode驻
set Unicode_Result=39547
exit/b
:Unicode25235
set Unicode_Result=抓
exit/b
:Unicode抓
set Unicode_Result=25235
exit/b
:Unicode29226
set Unicode_Result=爪
exit/b
:Unicode爪
set Unicode_Result=29226
exit/b
:Unicode25341
set Unicode_Result=拽
exit/b
:Unicode拽
set Unicode_Result=25341
exit/b
:Unicode19987
set Unicode_Result=专
exit/b
:Unicode专
set Unicode_Result=19987
exit/b
:Unicode30742
set Unicode_Result=砖
exit/b
:Unicode砖
set Unicode_Result=30742
exit/b
:Unicode36716
set Unicode_Result=转
exit/b
:Unicode转
set Unicode_Result=36716
exit/b
:Unicode25776
set Unicode_Result=撰
exit/b
:Unicode撰
set Unicode_Result=25776
exit/b
:Unicode36186
set Unicode_Result=赚
exit/b
:Unicode赚
set Unicode_Result=36186
exit/b
:Unicode31686
set Unicode_Result=篆
exit/b
:Unicode篆
set Unicode_Result=31686
exit/b
:Unicode26729
set Unicode_Result=桩
exit/b
:Unicode桩
set Unicode_Result=26729
exit/b
:Unicode24196
set Unicode_Result=庄
exit/b
:Unicode庄
set Unicode_Result=24196
exit/b
:Unicode35013
set Unicode_Result=装
exit/b
:Unicode装
set Unicode_Result=35013
exit/b
:Unicode22918
set Unicode_Result=妆
exit/b
:Unicode妆
set Unicode_Result=22918
exit/b
:Unicode25758
set Unicode_Result=撞
exit/b
:Unicode撞
set Unicode_Result=25758
exit/b
:Unicode22766
set Unicode_Result=壮
exit/b
:Unicode壮
set Unicode_Result=22766
exit/b
:Unicode29366
set Unicode_Result=状
exit/b
:Unicode状
set Unicode_Result=29366
exit/b
:Unicode26894
set Unicode_Result=椎
exit/b
:Unicode椎
set Unicode_Result=26894
exit/b
:Unicode38181
set Unicode_Result=锥
exit/b
:Unicode锥
set Unicode_Result=38181
exit/b
:Unicode36861
set Unicode_Result=追
exit/b
:Unicode追
set Unicode_Result=36861
exit/b
:Unicode36184
set Unicode_Result=赘
exit/b
:Unicode赘
set Unicode_Result=36184
exit/b
:Unicode22368
set Unicode_Result=坠
exit/b
:Unicode坠
set Unicode_Result=22368
exit/b
:Unicode32512
set Unicode_Result=缀
exit/b
:Unicode缀
set Unicode_Result=32512
exit/b
:Unicode35846
set Unicode_Result=谆
exit/b
:Unicode谆
set Unicode_Result=35846
exit/b
:Unicode20934
set Unicode_Result=准
exit/b
:Unicode准
set Unicode_Result=20934
exit/b
:Unicode25417
set Unicode_Result=捉
exit/b
:Unicode捉
set Unicode_Result=25417
exit/b
:Unicode25305
set Unicode_Result=拙
exit/b
:Unicode拙
set Unicode_Result=25305
exit/b
:Unicode21331
set Unicode_Result=卓
exit/b
:Unicode卓
set Unicode_Result=21331
exit/b
:Unicode26700
set Unicode_Result=桌
exit/b
:Unicode桌
set Unicode_Result=26700
exit/b
:Unicode29730
set Unicode_Result=琢
exit/b
:Unicode琢
set Unicode_Result=29730
exit/b
:Unicode33537
set Unicode_Result=茁
exit/b
:Unicode茁
set Unicode_Result=33537
exit/b
:Unicode37196
set Unicode_Result=酌
exit/b
:Unicode酌
set Unicode_Result=37196
exit/b
:Unicode21828
set Unicode_Result=啄
exit/b
:Unicode啄
set Unicode_Result=21828
exit/b
:Unicode30528
set Unicode_Result=着
exit/b
:Unicode着
set Unicode_Result=30528
exit/b
:Unicode28796
set Unicode_Result=灼
exit/b
:Unicode灼
set Unicode_Result=28796
exit/b
:Unicode27978
set Unicode_Result=浊
exit/b
:Unicode浊
set Unicode_Result=27978
exit/b
:Unicode20857
set Unicode_Result=兹
exit/b
:Unicode兹
set Unicode_Result=20857
exit/b
:Unicode21672
set Unicode_Result=咨
exit/b
:Unicode咨
set Unicode_Result=21672
exit/b
:Unicode36164
set Unicode_Result=资
exit/b
:Unicode资
set Unicode_Result=36164
exit/b
:Unicode23039
set Unicode_Result=姿
exit/b
:Unicode姿
set Unicode_Result=23039
exit/b
:Unicode28363
set Unicode_Result=滋
exit/b
:Unicode滋
set Unicode_Result=28363
exit/b
:Unicode28100
set Unicode_Result=淄
exit/b
:Unicode淄
set Unicode_Result=28100
exit/b
:Unicode23388
set Unicode_Result=孜
exit/b
:Unicode孜
set Unicode_Result=23388
exit/b
:Unicode32043
set Unicode_Result=紫
exit/b
:Unicode紫
set Unicode_Result=32043
exit/b
:Unicode20180
set Unicode_Result=仔
exit/b
:Unicode仔
set Unicode_Result=20180
exit/b
:Unicode31869
set Unicode_Result=籽
exit/b
:Unicode籽
set Unicode_Result=31869
exit/b
:Unicode28371
set Unicode_Result=滓
exit/b
:Unicode滓
set Unicode_Result=28371
exit/b
:Unicode23376
set Unicode_Result=子
exit/b
:Unicode子
set Unicode_Result=23376
exit/b
:Unicode33258
set Unicode_Result=自
exit/b
:Unicode自
set Unicode_Result=33258
exit/b
:Unicode28173
set Unicode_Result=渍
exit/b
:Unicode渍
set Unicode_Result=28173
exit/b
:Unicode23383
set Unicode_Result=字
exit/b
:Unicode字
set Unicode_Result=23383
exit/b
:Unicode39683
set Unicode_Result=鬃
exit/b
:Unicode鬃
set Unicode_Result=39683
exit/b
:Unicode26837
set Unicode_Result=棕
exit/b
:Unicode棕
set Unicode_Result=26837
exit/b
:Unicode36394
set Unicode_Result=踪
exit/b
:Unicode踪
set Unicode_Result=36394
exit/b
:Unicode23447
set Unicode_Result=宗
exit/b
:Unicode宗
set Unicode_Result=23447
exit/b
:Unicode32508
set Unicode_Result=综
exit/b
:Unicode综
set Unicode_Result=32508
exit/b
:Unicode24635
set Unicode_Result=总
exit/b
:Unicode总
set Unicode_Result=24635
exit/b
:Unicode32437
set Unicode_Result=纵
exit/b
:Unicode纵
set Unicode_Result=32437
exit/b
:Unicode37049
set Unicode_Result=邹
exit/b
:Unicode邹
set Unicode_Result=37049
exit/b
:Unicode36208
set Unicode_Result=走
exit/b
:Unicode走
set Unicode_Result=36208
exit/b
:Unicode22863
set Unicode_Result=奏
exit/b
:Unicode奏
set Unicode_Result=22863
exit/b
:Unicode25549
set Unicode_Result=揍
exit/b
:Unicode揍
set Unicode_Result=25549
exit/b
:Unicode31199
set Unicode_Result=租
exit/b
:Unicode租
set Unicode_Result=31199
exit/b
:Unicode36275
set Unicode_Result=足
exit/b
:Unicode足
set Unicode_Result=36275
exit/b
:Unicode21330
set Unicode_Result=卒
exit/b
:Unicode卒
set Unicode_Result=21330
exit/b
:Unicode26063
set Unicode_Result=族
exit/b
:Unicode族
set Unicode_Result=26063
exit/b
:Unicode31062
set Unicode_Result=祖
exit/b
:Unicode祖
set Unicode_Result=31062
exit/b
:Unicode35781
set Unicode_Result=诅
exit/b
:Unicode诅
set Unicode_Result=35781
exit/b
:Unicode38459
set Unicode_Result=阻
exit/b
:Unicode阻
set Unicode_Result=38459
exit/b
:Unicode32452
set Unicode_Result=组
exit/b
:Unicode组
set Unicode_Result=32452
exit/b
:Unicode38075
set Unicode_Result=钻
exit/b
:Unicode钻
set Unicode_Result=38075
exit/b
:Unicode32386
set Unicode_Result=纂
exit/b
:Unicode纂
set Unicode_Result=32386
exit/b
:Unicode22068
set Unicode_Result=嘴
exit/b
:Unicode嘴
set Unicode_Result=22068
exit/b
:Unicode37257
set Unicode_Result=醉
exit/b
:Unicode醉
set Unicode_Result=37257
exit/b
:Unicode26368
set Unicode_Result=最
exit/b
:Unicode最
set Unicode_Result=26368
exit/b
:Unicode32618
set Unicode_Result=罪
exit/b
:Unicode罪
set Unicode_Result=32618
exit/b
:Unicode23562
set Unicode_Result=尊
exit/b
:Unicode尊
set Unicode_Result=23562
exit/b
:Unicode20120
set Unicode_Result=亘
exit/b
:Unicode亘
set Unicode_Result=20120
exit/b
:Unicode19998
set Unicode_Result=丞
exit/b
:Unicode丞
set Unicode_Result=19998
exit/b
:Unicode39730
set Unicode_Result=鬲
exit/b
:Unicode鬲
set Unicode_Result=39730
exit/b
:Unicode23404
set Unicode_Result=孬
exit/b
:Unicode孬
set Unicode_Result=23404
exit/b
:Unicode22121
set Unicode_Result=噩
exit/b
:Unicode噩
set Unicode_Result=22121
exit/b
:Unicode20008
set Unicode_Result=丨
exit/b
:Unicode丨
set Unicode_Result=20008
exit/b
:Unicode31162
set Unicode_Result=禺
exit/b
:Unicode禺
set Unicode_Result=31162
exit/b
:Unicode20031
set Unicode_Result=丿
exit/b
:Unicode丿
set Unicode_Result=20031
exit/b
:Unicode21269
set Unicode_Result=匕
exit/b
:Unicode匕
set Unicode_Result=21269
exit/b
:Unicode20039
set Unicode_Result=乇
exit/b
:Unicode乇
set Unicode_Result=20039
exit/b
:Unicode22829
set Unicode_Result=夭
exit/b
:Unicode夭
set Unicode_Result=22829
exit/b
:Unicode29243
set Unicode_Result=爻
exit/b
:Unicode爻
set Unicode_Result=29243
exit/b
:Unicode21358
set Unicode_Result=卮
exit/b
:Unicode卮
set Unicode_Result=21358
exit/b
:Unicode27664
set Unicode_Result=氐
exit/b
:Unicode氐
set Unicode_Result=27664
exit/b
:Unicode22239
set Unicode_Result=囟
exit/b
:Unicode囟
set Unicode_Result=22239
exit/b
:Unicode32996
set Unicode_Result=胤
exit/b
:Unicode胤
set Unicode_Result=32996
exit/b
:Unicode39319
set Unicode_Result=馗
exit/b
:Unicode馗
set Unicode_Result=39319
exit/b
:Unicode27603
set Unicode_Result=毓
exit/b
:Unicode毓
set Unicode_Result=27603
exit/b
:Unicode30590
set Unicode_Result=睾
exit/b
:Unicode睾
set Unicode_Result=30590
exit/b
:Unicode40727
set Unicode_Result=鼗
exit/b
:Unicode鼗
set Unicode_Result=40727
exit/b
:Unicode20022
set Unicode_Result=丶
exit/b
:Unicode丶
set Unicode_Result=20022
exit/b
:Unicode20127
set Unicode_Result=亟
exit/b
:Unicode亟
set Unicode_Result=20127
exit/b
:Unicode40720
set Unicode_Result=鼐
exit/b
:Unicode鼐
set Unicode_Result=40720
exit/b
:Unicode20060
set Unicode_Result=乜
exit/b
:Unicode乜
set Unicode_Result=20060
exit/b
:Unicode20073
set Unicode_Result=乩
exit/b
:Unicode乩
set Unicode_Result=20073
exit/b
:Unicode20115
set Unicode_Result=亓
exit/b
:Unicode亓
set Unicode_Result=20115
exit/b
:Unicode33416
set Unicode_Result=芈
exit/b
:Unicode芈
set Unicode_Result=33416
exit/b
:Unicode23387
set Unicode_Result=孛
exit/b
:Unicode孛
set Unicode_Result=23387
exit/b
:Unicode21868
set Unicode_Result=啬
exit/b
:Unicode啬
set Unicode_Result=21868
exit/b
:Unicode22031
set Unicode_Result=嘏
exit/b
:Unicode嘏
set Unicode_Result=22031
exit/b
:Unicode20164
set Unicode_Result=仄
exit/b
:Unicode仄
set Unicode_Result=20164
exit/b
:Unicode21389
set Unicode_Result=厍
exit/b
:Unicode厍
set Unicode_Result=21389
exit/b
:Unicode21405
set Unicode_Result=厝
exit/b
:Unicode厝
set Unicode_Result=21405
exit/b
:Unicode21411
set Unicode_Result=厣
exit/b
:Unicode厣
set Unicode_Result=21411
exit/b
:Unicode21413
set Unicode_Result=厥
exit/b
:Unicode厥
set Unicode_Result=21413
exit/b
:Unicode21422
set Unicode_Result=厮
exit/b
:Unicode厮
set Unicode_Result=21422
exit/b
:Unicode38757
set Unicode_Result=靥
exit/b
:Unicode靥
set Unicode_Result=38757
exit/b
:Unicode36189
set Unicode_Result=赝
exit/b
:Unicode赝
set Unicode_Result=36189
exit/b
:Unicode21274
set Unicode_Result=匚
exit/b
:Unicode匚
set Unicode_Result=21274
exit/b
:Unicode21493
set Unicode_Result=叵
exit/b
:Unicode叵
set Unicode_Result=21493
exit/b
:Unicode21286
set Unicode_Result=匦
exit/b
:Unicode匦
set Unicode_Result=21286
exit/b
:Unicode21294
set Unicode_Result=匮
exit/b
:Unicode匮
set Unicode_Result=21294
exit/b
:Unicode21310
set Unicode_Result=匾
exit/b
:Unicode匾
set Unicode_Result=21310
exit/b
:Unicode36188
set Unicode_Result=赜
exit/b
:Unicode赜
set Unicode_Result=36188
exit/b
:Unicode21350
set Unicode_Result=卦
exit/b
:Unicode卦
set Unicode_Result=21350
exit/b
:Unicode21347
set Unicode_Result=卣
exit/b
:Unicode卣
set Unicode_Result=21347
exit/b
:Unicode20994
set Unicode_Result=刂
exit/b
:Unicode刂
set Unicode_Result=20994
exit/b
:Unicode21000
set Unicode_Result=刈
exit/b
:Unicode刈
set Unicode_Result=21000
exit/b
:Unicode21006
set Unicode_Result=刎
exit/b
:Unicode刎
set Unicode_Result=21006
exit/b
:Unicode21037
set Unicode_Result=刭
exit/b
:Unicode刭
set Unicode_Result=21037
exit/b
:Unicode21043
set Unicode_Result=刳
exit/b
:Unicode刳
set Unicode_Result=21043
exit/b
:Unicode21055
set Unicode_Result=刿
exit/b
:Unicode刿
set Unicode_Result=21055
exit/b
:Unicode21056
set Unicode_Result=剀
exit/b
:Unicode剀
set Unicode_Result=21056
exit/b
:Unicode21068
set Unicode_Result=剌
exit/b
:Unicode剌
set Unicode_Result=21068
exit/b
:Unicode21086
set Unicode_Result=剞
exit/b
:Unicode剞
set Unicode_Result=21086
exit/b
:Unicode21089
set Unicode_Result=剡
exit/b
:Unicode剡
set Unicode_Result=21089
exit/b
:Unicode21084
set Unicode_Result=剜
exit/b
:Unicode剜
set Unicode_Result=21084
exit/b
:Unicode33967
set Unicode_Result=蒯
exit/b
:Unicode蒯
set Unicode_Result=33967
exit/b
:Unicode21117
set Unicode_Result=剽
exit/b
:Unicode剽
set Unicode_Result=21117
exit/b
:Unicode21122
set Unicode_Result=劂
exit/b
:Unicode劂
set Unicode_Result=21122
exit/b
:Unicode21121
set Unicode_Result=劁
exit/b
:Unicode劁
set Unicode_Result=21121
exit/b
:Unicode21136
set Unicode_Result=劐
exit/b
:Unicode劐
set Unicode_Result=21136
exit/b
:Unicode21139
set Unicode_Result=劓
exit/b
:Unicode劓
set Unicode_Result=21139
exit/b
:Unicode20866
set Unicode_Result=冂
exit/b
:Unicode冂
set Unicode_Result=20866
exit/b
:Unicode32596
set Unicode_Result=罔
exit/b
:Unicode罔
set Unicode_Result=32596
exit/b
:Unicode20155
set Unicode_Result=亻
exit/b
:Unicode亻
set Unicode_Result=20155
exit/b
:Unicode20163
set Unicode_Result=仃
exit/b
:Unicode仃
set Unicode_Result=20163
exit/b
:Unicode20169
set Unicode_Result=仉
exit/b
:Unicode仉
set Unicode_Result=20169
exit/b
:Unicode20162
set Unicode_Result=仂
exit/b
:Unicode仂
set Unicode_Result=20162
exit/b
:Unicode20200
set Unicode_Result=仨
exit/b
:Unicode仨
set Unicode_Result=20200
exit/b
:Unicode20193
set Unicode_Result=仡
exit/b
:Unicode仡
set Unicode_Result=20193
exit/b
:Unicode20203
set Unicode_Result=仫
exit/b
:Unicode仫
set Unicode_Result=20203
exit/b
:Unicode20190
set Unicode_Result=仞
exit/b
:Unicode仞
set Unicode_Result=20190
exit/b
:Unicode20251
set Unicode_Result=伛
exit/b
:Unicode伛
set Unicode_Result=20251
exit/b
:Unicode20211
set Unicode_Result=仳
exit/b
:Unicode仳
set Unicode_Result=20211
exit/b
:Unicode20258
set Unicode_Result=伢
exit/b
:Unicode伢
set Unicode_Result=20258
exit/b
:Unicode20324
set Unicode_Result=佤
exit/b
:Unicode佤
set Unicode_Result=20324
exit/b
:Unicode20213
set Unicode_Result=仵
exit/b
:Unicode仵
set Unicode_Result=20213
exit/b
:Unicode20261
set Unicode_Result=伥
exit/b
:Unicode伥
set Unicode_Result=20261
exit/b
:Unicode20263
set Unicode_Result=伧
exit/b
:Unicode伧
set Unicode_Result=20263
exit/b
:Unicode20233
set Unicode_Result=伉
exit/b
:Unicode伉
set Unicode_Result=20233
exit/b
:Unicode20267
set Unicode_Result=伫
exit/b
:Unicode伫
set Unicode_Result=20267
exit/b
:Unicode20318
set Unicode_Result=佞
exit/b
:Unicode佞
set Unicode_Result=20318
exit/b
:Unicode20327
set Unicode_Result=佧
exit/b
:Unicode佧
set Unicode_Result=20327
exit/b
:Unicode25912
set Unicode_Result=攸
exit/b
:Unicode攸
set Unicode_Result=25912
exit/b
:Unicode20314
set Unicode_Result=佚
exit/b
:Unicode佚
set Unicode_Result=20314
exit/b
:Unicode20317
set Unicode_Result=佝
exit/b
:Unicode佝
set Unicode_Result=20317
exit/b
:Unicode20319
set Unicode_Result=佟
exit/b
:Unicode佟
set Unicode_Result=20319
exit/b
:Unicode20311
set Unicode_Result=佗
exit/b
:Unicode佗
set Unicode_Result=20311
exit/b
:Unicode20274
set Unicode_Result=伲
exit/b
:Unicode伲
set Unicode_Result=20274
exit/b
:Unicode20285
set Unicode_Result=伽
exit/b
:Unicode伽
set Unicode_Result=20285
exit/b
:Unicode20342
set Unicode_Result=佶
exit/b
:Unicode佶
set Unicode_Result=20342
exit/b
:Unicode20340
set Unicode_Result=佴
exit/b
:Unicode佴
set Unicode_Result=20340
exit/b
:Unicode20369
set Unicode_Result=侑
exit/b
:Unicode侑
set Unicode_Result=20369
exit/b
:Unicode20361
set Unicode_Result=侉
exit/b
:Unicode侉
set Unicode_Result=20361
exit/b
:Unicode20355
set Unicode_Result=侃
exit/b
:Unicode侃
set Unicode_Result=20355
exit/b
:Unicode20367
set Unicode_Result=侏
exit/b
:Unicode侏
set Unicode_Result=20367
exit/b
:Unicode20350
set Unicode_Result=佾
exit/b
:Unicode佾
set Unicode_Result=20350
exit/b
:Unicode20347
set Unicode_Result=佻
exit/b
:Unicode佻
set Unicode_Result=20347
exit/b
:Unicode20394
set Unicode_Result=侪
exit/b
:Unicode侪
set Unicode_Result=20394
exit/b
:Unicode20348
set Unicode_Result=佼
exit/b
:Unicode佼
set Unicode_Result=20348
exit/b
:Unicode20396
set Unicode_Result=侬
exit/b
:Unicode侬
set Unicode_Result=20396
exit/b
:Unicode20372
set Unicode_Result=侔
exit/b
:Unicode侔
set Unicode_Result=20372
exit/b
:Unicode20454
set Unicode_Result=俦
exit/b
:Unicode俦
set Unicode_Result=20454
exit/b
:Unicode20456
set Unicode_Result=俨
exit/b
:Unicode俨
set Unicode_Result=20456
exit/b
:Unicode20458
set Unicode_Result=俪
exit/b
:Unicode俪
set Unicode_Result=20458
exit/b
:Unicode20421
set Unicode_Result=俅
exit/b
:Unicode俅
set Unicode_Result=20421
exit/b
:Unicode20442
set Unicode_Result=俚
exit/b
:Unicode俚
set Unicode_Result=20442
exit/b
:Unicode20451
set Unicode_Result=俣
exit/b
:Unicode俣
set Unicode_Result=20451
exit/b
:Unicode20444
set Unicode_Result=俜
exit/b
:Unicode俜
set Unicode_Result=20444
exit/b
:Unicode20433
set Unicode_Result=俑
exit/b
:Unicode俑
set Unicode_Result=20433
exit/b
:Unicode20447
set Unicode_Result=俟
exit/b
:Unicode俟
set Unicode_Result=20447
exit/b
:Unicode20472
set Unicode_Result=俸
exit/b
:Unicode俸
set Unicode_Result=20472
exit/b
:Unicode20521
set Unicode_Result=倩
exit/b
:Unicode倩
set Unicode_Result=20521
exit/b
:Unicode20556
set Unicode_Result=偌
exit/b
:Unicode偌
set Unicode_Result=20556
exit/b
:Unicode20467
set Unicode_Result=俳
exit/b
:Unicode俳
set Unicode_Result=20467
exit/b
:Unicode20524
set Unicode_Result=倬
exit/b
:Unicode倬
set Unicode_Result=20524
exit/b
:Unicode20495
set Unicode_Result=倏
exit/b
:Unicode倏
set Unicode_Result=20495
exit/b
:Unicode20526
set Unicode_Result=倮
exit/b
:Unicode倮
set Unicode_Result=20526
exit/b
:Unicode20525
set Unicode_Result=倭
exit/b
:Unicode倭
set Unicode_Result=20525
exit/b
:Unicode20478
set Unicode_Result=俾
exit/b
:Unicode俾
set Unicode_Result=20478
exit/b
:Unicode20508
set Unicode_Result=倜
exit/b
:Unicode倜
set Unicode_Result=20508
exit/b
:Unicode20492
set Unicode_Result=倌
exit/b
:Unicode倌
set Unicode_Result=20492
exit/b
:Unicode20517
set Unicode_Result=倥
exit/b
:Unicode倥
set Unicode_Result=20517
exit/b
:Unicode20520
set Unicode_Result=倨
exit/b
:Unicode倨
set Unicode_Result=20520
exit/b
:Unicode20606
set Unicode_Result=偾
exit/b
:Unicode偾
set Unicode_Result=20606
exit/b
:Unicode20547
set Unicode_Result=偃
exit/b
:Unicode偃
set Unicode_Result=20547
exit/b
:Unicode20565
set Unicode_Result=偕
exit/b
:Unicode偕
set Unicode_Result=20565
exit/b
:Unicode20552
set Unicode_Result=偈
exit/b
:Unicode偈
set Unicode_Result=20552
exit/b
:Unicode20558
set Unicode_Result=偎
exit/b
:Unicode偎
set Unicode_Result=20558
exit/b
:Unicode20588
set Unicode_Result=偬
exit/b
:Unicode偬
set Unicode_Result=20588
exit/b
:Unicode20603
set Unicode_Result=偻
exit/b
:Unicode偻
set Unicode_Result=20603
exit/b
:Unicode20645
set Unicode_Result=傥
exit/b
:Unicode傥
set Unicode_Result=20645
exit/b
:Unicode20647
set Unicode_Result=傧
exit/b
:Unicode傧
set Unicode_Result=20647
exit/b
:Unicode20649
set Unicode_Result=傩
exit/b
:Unicode傩
set Unicode_Result=20649
exit/b
:Unicode20666
set Unicode_Result=傺
exit/b
:Unicode傺
set Unicode_Result=20666
exit/b
:Unicode20694
set Unicode_Result=僖
exit/b
:Unicode僖
set Unicode_Result=20694
exit/b
:Unicode20742
set Unicode_Result=儆
exit/b
:Unicode儆
set Unicode_Result=20742
exit/b
:Unicode20717
set Unicode_Result=僭
exit/b
:Unicode僭
set Unicode_Result=20717
exit/b
:Unicode20716
set Unicode_Result=僬
exit/b
:Unicode僬
set Unicode_Result=20716
exit/b
:Unicode20710
set Unicode_Result=僦
exit/b
:Unicode僦
set Unicode_Result=20710
exit/b
:Unicode20718
set Unicode_Result=僮
exit/b
:Unicode僮
set Unicode_Result=20718
exit/b
:Unicode20743
set Unicode_Result=儇
exit/b
:Unicode儇
set Unicode_Result=20743
exit/b
:Unicode20747
set Unicode_Result=儋
exit/b
:Unicode儋
set Unicode_Result=20747
exit/b
:Unicode20189
set Unicode_Result=仝
exit/b
:Unicode仝
set Unicode_Result=20189
exit/b
:Unicode27709
set Unicode_Result=氽
exit/b
:Unicode氽
set Unicode_Result=27709
exit/b
:Unicode20312
set Unicode_Result=佘
exit/b
:Unicode佘
set Unicode_Result=20312
exit/b
:Unicode20325
set Unicode_Result=佥
exit/b
:Unicode佥
set Unicode_Result=20325
exit/b
:Unicode20430
set Unicode_Result=俎
exit/b
:Unicode俎
set Unicode_Result=20430
exit/b
:Unicode40864
set Unicode_Result=龠
exit/b
:Unicode龠
set Unicode_Result=40864
exit/b
:Unicode27718
set Unicode_Result=汆
exit/b
:Unicode汆
set Unicode_Result=27718
exit/b
:Unicode31860
set Unicode_Result=籴
exit/b
:Unicode籴
set Unicode_Result=31860
exit/b
:Unicode20846
set Unicode_Result=兮
exit/b
:Unicode兮
set Unicode_Result=20846
exit/b
:Unicode24061
set Unicode_Result=巽
exit/b
:Unicode巽
set Unicode_Result=24061
exit/b
:Unicode40649
set Unicode_Result=黉
exit/b
:Unicode黉
set Unicode_Result=40649
exit/b
:Unicode39320
set Unicode_Result=馘
exit/b
:Unicode馘
set Unicode_Result=39320
exit/b
:Unicode20865
set Unicode_Result=冁
exit/b
:Unicode冁
set Unicode_Result=20865
exit/b
:Unicode22804
set Unicode_Result=夔
exit/b
:Unicode夔
set Unicode_Result=22804
exit/b
:Unicode21241
set Unicode_Result=勹
exit/b
:Unicode勹
set Unicode_Result=21241
exit/b
:Unicode21261
set Unicode_Result=匍
exit/b
:Unicode匍
set Unicode_Result=21261
exit/b
:Unicode35335
set Unicode_Result=訇
exit/b
:Unicode訇
set Unicode_Result=35335
exit/b
:Unicode21264
set Unicode_Result=匐
exit/b
:Unicode匐
set Unicode_Result=21264
exit/b
:Unicode20971
set Unicode_Result=凫
exit/b
:Unicode凫
set Unicode_Result=20971
exit/b
:Unicode22809
set Unicode_Result=夙
exit/b
:Unicode夙
set Unicode_Result=22809
exit/b
:Unicode20821
set Unicode_Result=兕
exit/b
:Unicode兕
set Unicode_Result=20821
exit/b
:Unicode20128
set Unicode_Result=亠
exit/b
:Unicode亠
set Unicode_Result=20128
exit/b
:Unicode20822
set Unicode_Result=兖
exit/b
:Unicode兖
set Unicode_Result=20822
exit/b
:Unicode20147
set Unicode_Result=亳
exit/b
:Unicode亳
set Unicode_Result=20147
exit/b
:Unicode34926
set Unicode_Result=衮
exit/b
:Unicode衮
set Unicode_Result=34926
exit/b
:Unicode34980
set Unicode_Result=袤
exit/b
:Unicode袤
set Unicode_Result=34980
exit/b
:Unicode20149
set Unicode_Result=亵
exit/b
:Unicode亵
set Unicode_Result=20149
exit/b
:Unicode33044
set Unicode_Result=脔
exit/b
:Unicode脔
set Unicode_Result=33044
exit/b
:Unicode35026
set Unicode_Result=裒
exit/b
:Unicode裒
set Unicode_Result=35026
exit/b
:Unicode31104
set Unicode_Result=禀
exit/b
:Unicode禀
set Unicode_Result=31104
exit/b
:Unicode23348
set Unicode_Result=嬴
exit/b
:Unicode嬴
set Unicode_Result=23348
exit/b
:Unicode34819
set Unicode_Result=蠃
exit/b
:Unicode蠃
set Unicode_Result=34819
exit/b
:Unicode32696
set Unicode_Result=羸
exit/b
:Unicode羸
set Unicode_Result=32696
exit/b
:Unicode20907
set Unicode_Result=冫
exit/b
:Unicode冫
set Unicode_Result=20907
exit/b
:Unicode20913
set Unicode_Result=冱
exit/b
:Unicode冱
set Unicode_Result=20913
exit/b
:Unicode20925
set Unicode_Result=冽
exit/b
:Unicode冽
set Unicode_Result=20925
exit/b
:Unicode20924
set Unicode_Result=冼
exit/b
:Unicode冼
set Unicode_Result=20924
exit/b
:Unicode20935
set Unicode_Result=凇
exit/b
:Unicode凇
set Unicode_Result=20935
exit/b
:Unicode20886
set Unicode_Result=冖
exit/b
:Unicode冖
set Unicode_Result=20886
exit/b
:Unicode20898
set Unicode_Result=冢
exit/b
:Unicode冢
set Unicode_Result=20898
exit/b
:Unicode20901
set Unicode_Result=冥
exit/b
:Unicode冥
set Unicode_Result=20901
exit/b
:Unicode35744
set Unicode_Result=讠
exit/b
:Unicode讠
set Unicode_Result=35744
exit/b
:Unicode35750
set Unicode_Result=讦
exit/b
:Unicode讦
set Unicode_Result=35750
exit/b
:Unicode35751
set Unicode_Result=讧
exit/b
:Unicode讧
set Unicode_Result=35751
exit/b
:Unicode35754
set Unicode_Result=讪
exit/b
:Unicode讪
set Unicode_Result=35754
exit/b
:Unicode35764
set Unicode_Result=讴
exit/b
:Unicode讴
set Unicode_Result=35764
exit/b
:Unicode35765
set Unicode_Result=讵
exit/b
:Unicode讵
set Unicode_Result=35765
exit/b
:Unicode35767
set Unicode_Result=讷
exit/b
:Unicode讷
set Unicode_Result=35767
exit/b
:Unicode35778
set Unicode_Result=诂
exit/b
:Unicode诂
set Unicode_Result=35778
exit/b
:Unicode35779
set Unicode_Result=诃
exit/b
:Unicode诃
set Unicode_Result=35779
exit/b
:Unicode35787
set Unicode_Result=诋
exit/b
:Unicode诋
set Unicode_Result=35787
exit/b
:Unicode35791
set Unicode_Result=诏
exit/b
:Unicode诏
set Unicode_Result=35791
exit/b
:Unicode35790
set Unicode_Result=诎
exit/b
:Unicode诎
set Unicode_Result=35790
exit/b
:Unicode35794
set Unicode_Result=诒
exit/b
:Unicode诒
set Unicode_Result=35794
exit/b
:Unicode35795
set Unicode_Result=诓
exit/b
:Unicode诓
set Unicode_Result=35795
exit/b
:Unicode35796
set Unicode_Result=诔
exit/b
:Unicode诔
set Unicode_Result=35796
exit/b
:Unicode35798
set Unicode_Result=诖
exit/b
:Unicode诖
set Unicode_Result=35798
exit/b
:Unicode35800
set Unicode_Result=诘
exit/b
:Unicode诘
set Unicode_Result=35800
exit/b
:Unicode35801
set Unicode_Result=诙
exit/b
:Unicode诙
set Unicode_Result=35801
exit/b
:Unicode35804
set Unicode_Result=诜
exit/b
:Unicode诜
set Unicode_Result=35804
exit/b
:Unicode35807
set Unicode_Result=诟
exit/b
:Unicode诟
set Unicode_Result=35807
exit/b
:Unicode35808
set Unicode_Result=诠
exit/b
:Unicode诠
set Unicode_Result=35808
exit/b
:Unicode35812
set Unicode_Result=诤
exit/b
:Unicode诤
set Unicode_Result=35812
exit/b
:Unicode35816
set Unicode_Result=诨
exit/b
:Unicode诨
set Unicode_Result=35816
exit/b
:Unicode35817
set Unicode_Result=诩
exit/b
:Unicode诩
set Unicode_Result=35817
exit/b
:Unicode35822
set Unicode_Result=诮
exit/b
:Unicode诮
set Unicode_Result=35822
exit/b
:Unicode35824
set Unicode_Result=诰
exit/b
:Unicode诰
set Unicode_Result=35824
exit/b
:Unicode35827
set Unicode_Result=诳
exit/b
:Unicode诳
set Unicode_Result=35827
exit/b
:Unicode35830
set Unicode_Result=诶
exit/b
:Unicode诶
set Unicode_Result=35830
exit/b
:Unicode35833
set Unicode_Result=诹
exit/b
:Unicode诹
set Unicode_Result=35833
exit/b
:Unicode35836
set Unicode_Result=诼
exit/b
:Unicode诼
set Unicode_Result=35836
exit/b
:Unicode35839
set Unicode_Result=诿
exit/b
:Unicode诿
set Unicode_Result=35839
exit/b
:Unicode35840
set Unicode_Result=谀
exit/b
:Unicode谀
set Unicode_Result=35840
exit/b
:Unicode35842
set Unicode_Result=谂
exit/b
:Unicode谂
set Unicode_Result=35842
exit/b
:Unicode35844
set Unicode_Result=谄
exit/b
:Unicode谄
set Unicode_Result=35844
exit/b
:Unicode35847
set Unicode_Result=谇
exit/b
:Unicode谇
set Unicode_Result=35847
exit/b
:Unicode35852
set Unicode_Result=谌
exit/b
:Unicode谌
set Unicode_Result=35852
exit/b
:Unicode35855
set Unicode_Result=谏
exit/b
:Unicode谏
set Unicode_Result=35855
exit/b
:Unicode35857
set Unicode_Result=谑
exit/b
:Unicode谑
set Unicode_Result=35857
exit/b
:Unicode35858
set Unicode_Result=谒
exit/b
:Unicode谒
set Unicode_Result=35858
exit/b
:Unicode35860
set Unicode_Result=谔
exit/b
:Unicode谔
set Unicode_Result=35860
exit/b
:Unicode35861
set Unicode_Result=谕
exit/b
:Unicode谕
set Unicode_Result=35861
exit/b
:Unicode35862
set Unicode_Result=谖
exit/b
:Unicode谖
set Unicode_Result=35862
exit/b
:Unicode35865
set Unicode_Result=谙
exit/b
:Unicode谙
set Unicode_Result=35865
exit/b
:Unicode35867
set Unicode_Result=谛
exit/b
:Unicode谛
set Unicode_Result=35867
exit/b
:Unicode35864
set Unicode_Result=谘
exit/b
:Unicode谘
set Unicode_Result=35864
exit/b
:Unicode35869
set Unicode_Result=谝
exit/b
:Unicode谝
set Unicode_Result=35869
exit/b
:Unicode35871
set Unicode_Result=谟
exit/b
:Unicode谟
set Unicode_Result=35871
exit/b
:Unicode35872
set Unicode_Result=谠
exit/b
:Unicode谠
set Unicode_Result=35872
exit/b
:Unicode35873
set Unicode_Result=谡
exit/b
:Unicode谡
set Unicode_Result=35873
exit/b
:Unicode35877
set Unicode_Result=谥
exit/b
:Unicode谥
set Unicode_Result=35877
exit/b
:Unicode35879
set Unicode_Result=谧
exit/b
:Unicode谧
set Unicode_Result=35879
exit/b
:Unicode35882
set Unicode_Result=谪
exit/b
:Unicode谪
set Unicode_Result=35882
exit/b
:Unicode35883
set Unicode_Result=谫
exit/b
:Unicode谫
set Unicode_Result=35883
exit/b
:Unicode35886
set Unicode_Result=谮
exit/b
:Unicode谮
set Unicode_Result=35886
exit/b
:Unicode35887
set Unicode_Result=谯
exit/b
:Unicode谯
set Unicode_Result=35887
exit/b
:Unicode35890
set Unicode_Result=谲
exit/b
:Unicode谲
set Unicode_Result=35890
exit/b
:Unicode35891
set Unicode_Result=谳
exit/b
:Unicode谳
set Unicode_Result=35891
exit/b
:Unicode35893
set Unicode_Result=谵
exit/b
:Unicode谵
set Unicode_Result=35893
exit/b
:Unicode35894
set Unicode_Result=谶
exit/b
:Unicode谶
set Unicode_Result=35894
exit/b
:Unicode21353
set Unicode_Result=卩
exit/b
:Unicode卩
set Unicode_Result=21353
exit/b
:Unicode21370
set Unicode_Result=卺
exit/b
:Unicode卺
set Unicode_Result=21370
exit/b
:Unicode38429
set Unicode_Result=阝
exit/b
:Unicode阝
set Unicode_Result=38429
exit/b
:Unicode38434
set Unicode_Result=阢
exit/b
:Unicode阢
set Unicode_Result=38434
exit/b
:Unicode38433
set Unicode_Result=阡
exit/b
:Unicode阡
set Unicode_Result=38433
exit/b
:Unicode38449
set Unicode_Result=阱
exit/b
:Unicode阱
set Unicode_Result=38449
exit/b
:Unicode38442
set Unicode_Result=阪
exit/b
:Unicode阪
set Unicode_Result=38442
exit/b
:Unicode38461
set Unicode_Result=阽
exit/b
:Unicode阽
set Unicode_Result=38461
exit/b
:Unicode38460
set Unicode_Result=阼
exit/b
:Unicode阼
set Unicode_Result=38460
exit/b
:Unicode38466
set Unicode_Result=陂
exit/b
:Unicode陂
set Unicode_Result=38466
exit/b
:Unicode38473
set Unicode_Result=陉
exit/b
:Unicode陉
set Unicode_Result=38473
exit/b
:Unicode38484
set Unicode_Result=陔
exit/b
:Unicode陔
set Unicode_Result=38484
exit/b
:Unicode38495
set Unicode_Result=陟
exit/b
:Unicode陟
set Unicode_Result=38495
exit/b
:Unicode38503
set Unicode_Result=陧
exit/b
:Unicode陧
set Unicode_Result=38503
exit/b
:Unicode38508
set Unicode_Result=陬
exit/b
:Unicode陬
set Unicode_Result=38508
exit/b
:Unicode38514
set Unicode_Result=陲
exit/b
:Unicode陲
set Unicode_Result=38514
exit/b
:Unicode38516
set Unicode_Result=陴
exit/b
:Unicode陴
set Unicode_Result=38516
exit/b
:Unicode38536
set Unicode_Result=隈
exit/b
:Unicode隈
set Unicode_Result=38536
exit/b
:Unicode38541
set Unicode_Result=隍
exit/b
:Unicode隍
set Unicode_Result=38541
exit/b
:Unicode38551
set Unicode_Result=隗
exit/b
:Unicode隗
set Unicode_Result=38551
exit/b
:Unicode38576
set Unicode_Result=隰
exit/b
:Unicode隰
set Unicode_Result=38576
exit/b
:Unicode37015
set Unicode_Result=邗
exit/b
:Unicode邗
set Unicode_Result=37015
exit/b
:Unicode37019
set Unicode_Result=邛
exit/b
:Unicode邛
set Unicode_Result=37019
exit/b
:Unicode37021
set Unicode_Result=邝
exit/b
:Unicode邝
set Unicode_Result=37021
exit/b
:Unicode37017
set Unicode_Result=邙
exit/b
:Unicode邙
set Unicode_Result=37017
exit/b
:Unicode37036
set Unicode_Result=邬
exit/b
:Unicode邬
set Unicode_Result=37036
exit/b
:Unicode37025
set Unicode_Result=邡
exit/b
:Unicode邡
set Unicode_Result=37025
exit/b
:Unicode37044
set Unicode_Result=邴
exit/b
:Unicode邴
set Unicode_Result=37044
exit/b
:Unicode37043
set Unicode_Result=邳
exit/b
:Unicode邳
set Unicode_Result=37043
exit/b
:Unicode37046
set Unicode_Result=邶
exit/b
:Unicode邶
set Unicode_Result=37046
exit/b
:Unicode37050
set Unicode_Result=邺
exit/b
:Unicode邺
set Unicode_Result=37050
exit/b
:Unicode37048
set Unicode_Result=邸
exit/b
:Unicode邸
set Unicode_Result=37048
exit/b
:Unicode37040
set Unicode_Result=邰
exit/b
:Unicode邰
set Unicode_Result=37040
exit/b
:Unicode37071
set Unicode_Result=郏
exit/b
:Unicode郏
set Unicode_Result=37071
exit/b
:Unicode37061
set Unicode_Result=郅
exit/b
:Unicode郅
set Unicode_Result=37061
exit/b
:Unicode37054
set Unicode_Result=邾
exit/b
:Unicode邾
set Unicode_Result=37054
exit/b
:Unicode37072
set Unicode_Result=郐
exit/b
:Unicode郐
set Unicode_Result=37072
exit/b
:Unicode37060
set Unicode_Result=郄
exit/b
:Unicode郄
set Unicode_Result=37060
exit/b
:Unicode37063
set Unicode_Result=郇
exit/b
:Unicode郇
set Unicode_Result=37063
exit/b
:Unicode37075
set Unicode_Result=郓
exit/b
:Unicode郓
set Unicode_Result=37075
exit/b
:Unicode37094
set Unicode_Result=郦
exit/b
:Unicode郦
set Unicode_Result=37094
exit/b
:Unicode37090
set Unicode_Result=郢
exit/b
:Unicode郢
set Unicode_Result=37090
exit/b
:Unicode37084
set Unicode_Result=郜
exit/b
:Unicode郜
set Unicode_Result=37084
exit/b
:Unicode37079
set Unicode_Result=郗
exit/b
:Unicode郗
set Unicode_Result=37079
exit/b
:Unicode37083
set Unicode_Result=郛
exit/b
:Unicode郛
set Unicode_Result=37083
exit/b
:Unicode37099
set Unicode_Result=郫
exit/b
:Unicode郫
set Unicode_Result=37099
exit/b
:Unicode37103
set Unicode_Result=郯
exit/b
:Unicode郯
set Unicode_Result=37103
exit/b
:Unicode37118
set Unicode_Result=郾
exit/b
:Unicode郾
set Unicode_Result=37118
exit/b
:Unicode37124
set Unicode_Result=鄄
exit/b
:Unicode鄄
set Unicode_Result=37124
exit/b
:Unicode37154
set Unicode_Result=鄢
exit/b
:Unicode鄢
set Unicode_Result=37154
exit/b
:Unicode37150
set Unicode_Result=鄞
exit/b
:Unicode鄞
set Unicode_Result=37150
exit/b
:Unicode37155
set Unicode_Result=鄣
exit/b
:Unicode鄣
set Unicode_Result=37155
exit/b
:Unicode37169
set Unicode_Result=鄱
exit/b
:Unicode鄱
set Unicode_Result=37169
exit/b
:Unicode37167
set Unicode_Result=鄯
exit/b
:Unicode鄯
set Unicode_Result=37167
exit/b
:Unicode37177
set Unicode_Result=鄹
exit/b
:Unicode鄹
set Unicode_Result=37177
exit/b
:Unicode37187
set Unicode_Result=酃
exit/b
:Unicode酃
set Unicode_Result=37187
exit/b
:Unicode37190
set Unicode_Result=酆
exit/b
:Unicode酆
set Unicode_Result=37190
exit/b
:Unicode21005
set Unicode_Result=刍
exit/b
:Unicode刍
set Unicode_Result=21005
exit/b
:Unicode22850
set Unicode_Result=奂
exit/b
:Unicode奂
set Unicode_Result=22850
exit/b
:Unicode21154
set Unicode_Result=劢
exit/b
:Unicode劢
set Unicode_Result=21154
exit/b
:Unicode21164
set Unicode_Result=劬
exit/b
:Unicode劬
set Unicode_Result=21164
exit/b
:Unicode21165
set Unicode_Result=劭
exit/b
:Unicode劭
set Unicode_Result=21165
exit/b
:Unicode21182
set Unicode_Result=劾
exit/b
:Unicode劾
set Unicode_Result=21182
exit/b
:Unicode21759
set Unicode_Result=哿
exit/b
:Unicode哿
set Unicode_Result=21759
exit/b
:Unicode21200
set Unicode_Result=勐
exit/b
:Unicode勐
set Unicode_Result=21200
exit/b
:Unicode21206
set Unicode_Result=勖
exit/b
:Unicode勖
set Unicode_Result=21206
exit/b
:Unicode21232
set Unicode_Result=勰
exit/b
:Unicode勰
set Unicode_Result=21232
exit/b
:Unicode21471
set Unicode_Result=叟
exit/b
:Unicode叟
set Unicode_Result=21471
exit/b
:Unicode29166
set Unicode_Result=燮
exit/b
:Unicode燮
set Unicode_Result=29166
exit/b
:Unicode30669
set Unicode_Result=矍
exit/b
:Unicode矍
set Unicode_Result=30669
exit/b
:Unicode24308
set Unicode_Result=廴
exit/b
:Unicode廴
set Unicode_Result=24308
exit/b
:Unicode20981
set Unicode_Result=凵
exit/b
:Unicode凵
set Unicode_Result=20981
exit/b
:Unicode20988
set Unicode_Result=凼
exit/b
:Unicode凼
set Unicode_Result=20988
exit/b
:Unicode39727
set Unicode_Result=鬯
exit/b
:Unicode鬯
set Unicode_Result=39727
exit/b
:Unicode21430
set Unicode_Result=厶
exit/b
:Unicode厶
set Unicode_Result=21430
exit/b
:Unicode24321
set Unicode_Result=弁
exit/b
:Unicode弁
set Unicode_Result=24321
exit/b
:Unicode30042
set Unicode_Result=畚
exit/b
:Unicode畚
set Unicode_Result=30042
exit/b
:Unicode24047
set Unicode_Result=巯
exit/b
:Unicode巯
set Unicode_Result=24047
exit/b
:Unicode22348
set Unicode_Result=坌
exit/b
:Unicode坌
set Unicode_Result=22348
exit/b
:Unicode22441
set Unicode_Result=垩
exit/b
:Unicode垩
set Unicode_Result=22441
exit/b
:Unicode22433
set Unicode_Result=垡
exit/b
:Unicode垡
set Unicode_Result=22433
exit/b
:Unicode22654
set Unicode_Result=塾
exit/b
:Unicode塾
set Unicode_Result=22654
exit/b
:Unicode22716
set Unicode_Result=墼
exit/b
:Unicode墼
set Unicode_Result=22716
exit/b
:Unicode22725
set Unicode_Result=壅
exit/b
:Unicode壅
set Unicode_Result=22725
exit/b
:Unicode22737
set Unicode_Result=壑
exit/b
:Unicode壑
set Unicode_Result=22737
exit/b
:Unicode22313
set Unicode_Result=圩
exit/b
:Unicode圩
set Unicode_Result=22313
exit/b
:Unicode22316
set Unicode_Result=圬
exit/b
:Unicode圬
set Unicode_Result=22316
exit/b
:Unicode22314
set Unicode_Result=圪
exit/b
:Unicode圪
set Unicode_Result=22314
exit/b
:Unicode22323
set Unicode_Result=圳
exit/b
:Unicode圳
set Unicode_Result=22323
exit/b
:Unicode22329
set Unicode_Result=圹
exit/b
:Unicode圹
set Unicode_Result=22329
exit/b
:Unicode22318
set Unicode_Result=圮
exit/b
:Unicode圮
set Unicode_Result=22318
exit/b
:Unicode22319
set Unicode_Result=圯
exit/b
:Unicode圯
set Unicode_Result=22319
exit/b
:Unicode22364
set Unicode_Result=坜
exit/b
:Unicode坜
set Unicode_Result=22364
exit/b
:Unicode22331
set Unicode_Result=圻
exit/b
:Unicode圻
set Unicode_Result=22331
exit/b
:Unicode22338
set Unicode_Result=坂
exit/b
:Unicode坂
set Unicode_Result=22338
exit/b
:Unicode22377
set Unicode_Result=坩
exit/b
:Unicode坩
set Unicode_Result=22377
exit/b
:Unicode22405
set Unicode_Result=垅
exit/b
:Unicode垅
set Unicode_Result=22405
exit/b
:Unicode22379
set Unicode_Result=坫
exit/b
:Unicode坫
set Unicode_Result=22379
exit/b
:Unicode22406
set Unicode_Result=垆
exit/b
:Unicode垆
set Unicode_Result=22406
exit/b
:Unicode22396
set Unicode_Result=坼
exit/b
:Unicode坼
set Unicode_Result=22396
exit/b
:Unicode22395
set Unicode_Result=坻
exit/b
:Unicode坻
set Unicode_Result=22395
exit/b
:Unicode22376
set Unicode_Result=坨
exit/b
:Unicode坨
set Unicode_Result=22376
exit/b
:Unicode22381
set Unicode_Result=坭
exit/b
:Unicode坭
set Unicode_Result=22381
exit/b
:Unicode22390
set Unicode_Result=坶
exit/b
:Unicode坶
set Unicode_Result=22390
exit/b
:Unicode22387
set Unicode_Result=坳
exit/b
:Unicode坳
set Unicode_Result=22387
exit/b
:Unicode22445
set Unicode_Result=垭
exit/b
:Unicode垭
set Unicode_Result=22445
exit/b
:Unicode22436
set Unicode_Result=垤
exit/b
:Unicode垤
set Unicode_Result=22436
exit/b
:Unicode22412
set Unicode_Result=垌
exit/b
:Unicode垌
set Unicode_Result=22412
exit/b
:Unicode22450
set Unicode_Result=垲
exit/b
:Unicode垲
set Unicode_Result=22450
exit/b
:Unicode22479
set Unicode_Result=埏
exit/b
:Unicode埏
set Unicode_Result=22479
exit/b
:Unicode22439
set Unicode_Result=垧
exit/b
:Unicode垧
set Unicode_Result=22439
exit/b
:Unicode22452
set Unicode_Result=垴
exit/b
:Unicode垴
set Unicode_Result=22452
exit/b
:Unicode22419
set Unicode_Result=垓
exit/b
:Unicode垓
set Unicode_Result=22419
exit/b
:Unicode22432
set Unicode_Result=垠
exit/b
:Unicode垠
set Unicode_Result=22432
exit/b
:Unicode22485
set Unicode_Result=埕
exit/b
:Unicode埕
set Unicode_Result=22485
exit/b
:Unicode22488
set Unicode_Result=埘
exit/b
:Unicode埘
set Unicode_Result=22488
exit/b
:Unicode22490
set Unicode_Result=埚
exit/b
:Unicode埚
set Unicode_Result=22490
exit/b
:Unicode22489
set Unicode_Result=埙
exit/b
:Unicode埙
set Unicode_Result=22489
exit/b
:Unicode22482
set Unicode_Result=埒
exit/b
:Unicode埒
set Unicode_Result=22482
exit/b
:Unicode22456
set Unicode_Result=垸
exit/b
:Unicode垸
set Unicode_Result=22456
exit/b
:Unicode22516
set Unicode_Result=埴
exit/b
:Unicode埴
set Unicode_Result=22516
exit/b
:Unicode22511
set Unicode_Result=埯
exit/b
:Unicode埯
set Unicode_Result=22511
exit/b
:Unicode22520
set Unicode_Result=埸
exit/b
:Unicode埸
set Unicode_Result=22520
exit/b
:Unicode22500
set Unicode_Result=埤
exit/b
:Unicode埤
set Unicode_Result=22500
exit/b
:Unicode22493
set Unicode_Result=埝
exit/b
:Unicode埝
set Unicode_Result=22493
exit/b
:Unicode22539
set Unicode_Result=堋
exit/b
:Unicode堋
set Unicode_Result=22539
exit/b
:Unicode22541
set Unicode_Result=堍
exit/b
:Unicode堍
set Unicode_Result=22541
exit/b
:Unicode22525
set Unicode_Result=埽
exit/b
:Unicode埽
set Unicode_Result=22525
exit/b
:Unicode22509
set Unicode_Result=埭
exit/b
:Unicode埭
set Unicode_Result=22509
exit/b
:Unicode22528
set Unicode_Result=堀
exit/b
:Unicode堀
set Unicode_Result=22528
exit/b
:Unicode22558
set Unicode_Result=堞
exit/b
:Unicode堞
set Unicode_Result=22558
exit/b
:Unicode22553
set Unicode_Result=堙
exit/b
:Unicode堙
set Unicode_Result=22553
exit/b
:Unicode22596
set Unicode_Result=塄
exit/b
:Unicode塄
set Unicode_Result=22596
exit/b
:Unicode22560
set Unicode_Result=堠
exit/b
:Unicode堠
set Unicode_Result=22560
exit/b
:Unicode22629
set Unicode_Result=塥
exit/b
:Unicode塥
set Unicode_Result=22629
exit/b
:Unicode22636
set Unicode_Result=塬
exit/b
:Unicode塬
set Unicode_Result=22636
exit/b
:Unicode22657
set Unicode_Result=墁
exit/b
:Unicode墁
set Unicode_Result=22657
exit/b
:Unicode22665
set Unicode_Result=墉
exit/b
:Unicode墉
set Unicode_Result=22665
exit/b
:Unicode22682
set Unicode_Result=墚
exit/b
:Unicode墚
set Unicode_Result=22682
exit/b
:Unicode22656
set Unicode_Result=墀
exit/b
:Unicode墀
set Unicode_Result=22656
exit/b
:Unicode39336
set Unicode_Result=馨
exit/b
:Unicode馨
set Unicode_Result=39336
exit/b
:Unicode40729
set Unicode_Result=鼙
exit/b
:Unicode鼙
set Unicode_Result=40729
exit/b
:Unicode25087
set Unicode_Result=懿
exit/b
:Unicode懿
set Unicode_Result=25087
exit/b
:Unicode33401
set Unicode_Result=艹
exit/b
:Unicode艹
set Unicode_Result=33401
exit/b
:Unicode33405
set Unicode_Result=艽
exit/b
:Unicode艽
set Unicode_Result=33405
exit/b
:Unicode33407
set Unicode_Result=艿
exit/b
:Unicode艿
set Unicode_Result=33407
exit/b
:Unicode33423
set Unicode_Result=芏
exit/b
:Unicode芏
set Unicode_Result=33423
exit/b
:Unicode33418
set Unicode_Result=芊
exit/b
:Unicode芊
set Unicode_Result=33418
exit/b
:Unicode33448
set Unicode_Result=芨
exit/b
:Unicode芨
set Unicode_Result=33448
exit/b
:Unicode33412
set Unicode_Result=芄
exit/b
:Unicode芄
set Unicode_Result=33412
exit/b
:Unicode33422
set Unicode_Result=芎
exit/b
:Unicode芎
set Unicode_Result=33422
exit/b
:Unicode33425
set Unicode_Result=芑
exit/b
:Unicode芑
set Unicode_Result=33425
exit/b
:Unicode33431
set Unicode_Result=芗
exit/b
:Unicode芗
set Unicode_Result=33431
exit/b
:Unicode33433
set Unicode_Result=芙
exit/b
:Unicode芙
set Unicode_Result=33433
exit/b
:Unicode33451
set Unicode_Result=芫
exit/b
:Unicode芫
set Unicode_Result=33451
exit/b
:Unicode33464
set Unicode_Result=芸
exit/b
:Unicode芸
set Unicode_Result=33464
exit/b
:Unicode33470
set Unicode_Result=芾
exit/b
:Unicode芾
set Unicode_Result=33470
exit/b
:Unicode33456
set Unicode_Result=芰
exit/b
:Unicode芰
set Unicode_Result=33456
exit/b
:Unicode33480
set Unicode_Result=苈
exit/b
:Unicode苈
set Unicode_Result=33480
exit/b
:Unicode33482
set Unicode_Result=苊
exit/b
:Unicode苊
set Unicode_Result=33482
exit/b
:Unicode33507
set Unicode_Result=苣
exit/b
:Unicode苣
set Unicode_Result=33507
exit/b
:Unicode33432
set Unicode_Result=芘
exit/b
:Unicode芘
set Unicode_Result=33432
exit/b
:Unicode33463
set Unicode_Result=芷
exit/b
:Unicode芷
set Unicode_Result=33463
exit/b
:Unicode33454
set Unicode_Result=芮
exit/b
:Unicode芮
set Unicode_Result=33454
exit/b
:Unicode33483
set Unicode_Result=苋
exit/b
:Unicode苋
set Unicode_Result=33483
exit/b
:Unicode33484
set Unicode_Result=苌
exit/b
:Unicode苌
set Unicode_Result=33484
exit/b
:Unicode33473
set Unicode_Result=苁
exit/b
:Unicode苁
set Unicode_Result=33473
exit/b
:Unicode33449
set Unicode_Result=芩
exit/b
:Unicode芩
set Unicode_Result=33449
exit/b
:Unicode33460
set Unicode_Result=芴
exit/b
:Unicode芴
set Unicode_Result=33460
exit/b
:Unicode33441
set Unicode_Result=芡
exit/b
:Unicode芡
set Unicode_Result=33441
exit/b
:Unicode33450
set Unicode_Result=芪
exit/b
:Unicode芪
set Unicode_Result=33450
exit/b
:Unicode33439
set Unicode_Result=芟
exit/b
:Unicode芟
set Unicode_Result=33439
exit/b
:Unicode33476
set Unicode_Result=苄
exit/b
:Unicode苄
set Unicode_Result=33476
exit/b
:Unicode33486
set Unicode_Result=苎
exit/b
:Unicode苎
set Unicode_Result=33486
exit/b
:Unicode33444
set Unicode_Result=芤
exit/b
:Unicode芤
set Unicode_Result=33444
exit/b
:Unicode33505
set Unicode_Result=苡
exit/b
:Unicode苡
set Unicode_Result=33505
exit/b
:Unicode33545
set Unicode_Result=茉
exit/b
:Unicode茉
set Unicode_Result=33545
exit/b
:Unicode33527
set Unicode_Result=苷
exit/b
:Unicode苷
set Unicode_Result=33527
exit/b
:Unicode33508
set Unicode_Result=苤
exit/b
:Unicode苤
set Unicode_Result=33508
exit/b
:Unicode33551
set Unicode_Result=茏
exit/b
:Unicode茏
set Unicode_Result=33551
exit/b
:Unicode33543
set Unicode_Result=茇
exit/b
:Unicode茇
set Unicode_Result=33543
exit/b
:Unicode33500
set Unicode_Result=苜
exit/b
:Unicode苜
set Unicode_Result=33500
exit/b
:Unicode33524
set Unicode_Result=苴
exit/b
:Unicode苴
set Unicode_Result=33524
exit/b
:Unicode33490
set Unicode_Result=苒
exit/b
:Unicode苒
set Unicode_Result=33490
exit/b
:Unicode33496
set Unicode_Result=苘
exit/b
:Unicode苘
set Unicode_Result=33496
exit/b
:Unicode33548
set Unicode_Result=茌
exit/b
:Unicode茌
set Unicode_Result=33548
exit/b
:Unicode33531
set Unicode_Result=苻
exit/b
:Unicode苻
set Unicode_Result=33531
exit/b
:Unicode33491
set Unicode_Result=苓
exit/b
:Unicode苓
set Unicode_Result=33491
exit/b
:Unicode33553
set Unicode_Result=茑
exit/b
:Unicode茑
set Unicode_Result=33553
exit/b
:Unicode33562
set Unicode_Result=茚
exit/b
:Unicode茚
set Unicode_Result=33562
exit/b
:Unicode33542
set Unicode_Result=茆
exit/b
:Unicode茆
set Unicode_Result=33542
exit/b
:Unicode33556
set Unicode_Result=茔
exit/b
:Unicode茔
set Unicode_Result=33556
exit/b
:Unicode33557
set Unicode_Result=茕
exit/b
:Unicode茕
set Unicode_Result=33557
exit/b
:Unicode33504
set Unicode_Result=苠
exit/b
:Unicode苠
set Unicode_Result=33504
exit/b
:Unicode33493
set Unicode_Result=苕
exit/b
:Unicode苕
set Unicode_Result=33493
exit/b
:Unicode33564
set Unicode_Result=茜
exit/b
:Unicode茜
set Unicode_Result=33564
exit/b
:Unicode33617
set Unicode_Result=荑
exit/b
:Unicode荑
set Unicode_Result=33617
exit/b
:Unicode33627
set Unicode_Result=荛
exit/b
:Unicode荛
set Unicode_Result=33627
exit/b
:Unicode33628
set Unicode_Result=荜
exit/b
:Unicode荜
set Unicode_Result=33628
exit/b
:Unicode33544
set Unicode_Result=茈
exit/b
:Unicode茈
set Unicode_Result=33544
exit/b
:Unicode33682
set Unicode_Result=莒
exit/b
:Unicode莒
set Unicode_Result=33682
exit/b
:Unicode33596
set Unicode_Result=茼
exit/b
:Unicode茼
set Unicode_Result=33596
exit/b
:Unicode33588
set Unicode_Result=茴
exit/b
:Unicode茴
set Unicode_Result=33588
exit/b
:Unicode33585
set Unicode_Result=茱
exit/b
:Unicode茱
set Unicode_Result=33585
exit/b
:Unicode33691
set Unicode_Result=莛
exit/b
:Unicode莛
set Unicode_Result=33691
exit/b
:Unicode33630
set Unicode_Result=荞
exit/b
:Unicode荞
set Unicode_Result=33630
exit/b
:Unicode33583
set Unicode_Result=茯
exit/b
:Unicode茯
set Unicode_Result=33583
exit/b
:Unicode33615
set Unicode_Result=荏
exit/b
:Unicode荏
set Unicode_Result=33615
exit/b
:Unicode33607
set Unicode_Result=荇
exit/b
:Unicode荇
set Unicode_Result=33607
exit/b
:Unicode33603
set Unicode_Result=荃
exit/b
:Unicode荃
set Unicode_Result=33603
exit/b
:Unicode33631
set Unicode_Result=荟
exit/b
:Unicode荟
set Unicode_Result=33631
exit/b
:Unicode33600
set Unicode_Result=荀
exit/b
:Unicode荀
set Unicode_Result=33600
exit/b
:Unicode33559
set Unicode_Result=茗
exit/b
:Unicode茗
set Unicode_Result=33559
exit/b
:Unicode33632
set Unicode_Result=荠
exit/b
:Unicode荠
set Unicode_Result=33632
exit/b
:Unicode33581
set Unicode_Result=茭
exit/b
:Unicode茭
set Unicode_Result=33581
exit/b
:Unicode33594
set Unicode_Result=茺
exit/b
:Unicode茺
set Unicode_Result=33594
exit/b
:Unicode33587
set Unicode_Result=茳
exit/b
:Unicode茳
set Unicode_Result=33587
exit/b
:Unicode33638
set Unicode_Result=荦
exit/b
:Unicode荦
set Unicode_Result=33638
exit/b
:Unicode33637
set Unicode_Result=荥
exit/b
:Unicode荥
set Unicode_Result=33637
exit/b
:Unicode33640
set Unicode_Result=荨
exit/b
:Unicode荨
set Unicode_Result=33640
exit/b
:Unicode33563
set Unicode_Result=茛
exit/b
:Unicode茛
set Unicode_Result=33563
exit/b
:Unicode33641
set Unicode_Result=荩
exit/b
:Unicode荩
set Unicode_Result=33641
exit/b
:Unicode33644
set Unicode_Result=荬
exit/b
:Unicode荬
set Unicode_Result=33644
exit/b
:Unicode33642
set Unicode_Result=荪
exit/b
:Unicode荪
set Unicode_Result=33642
exit/b
:Unicode33645
set Unicode_Result=荭
exit/b
:Unicode荭
set Unicode_Result=33645
exit/b
:Unicode33646
set Unicode_Result=荮
exit/b
:Unicode荮
set Unicode_Result=33646
exit/b
:Unicode33712
set Unicode_Result=莰
exit/b
:Unicode莰
set Unicode_Result=33712
exit/b
:Unicode33656
set Unicode_Result=荸
exit/b
:Unicode荸
set Unicode_Result=33656
exit/b
:Unicode33715
set Unicode_Result=莳
exit/b
:Unicode莳
set Unicode_Result=33715
exit/b
:Unicode33716
set Unicode_Result=莴
exit/b
:Unicode莴
set Unicode_Result=33716
exit/b
:Unicode33696
set Unicode_Result=莠
exit/b
:Unicode莠
set Unicode_Result=33696
exit/b
:Unicode33706
set Unicode_Result=莪
exit/b
:Unicode莪
set Unicode_Result=33706
exit/b
:Unicode33683
set Unicode_Result=莓
exit/b
:Unicode莓
set Unicode_Result=33683
exit/b
:Unicode33692
set Unicode_Result=莜
exit/b
:Unicode莜
set Unicode_Result=33692
exit/b
:Unicode33669
set Unicode_Result=莅
exit/b
:Unicode莅
set Unicode_Result=33669
exit/b
:Unicode33660
set Unicode_Result=荼
exit/b
:Unicode荼
set Unicode_Result=33660
exit/b
:Unicode33718
set Unicode_Result=莶
exit/b
:Unicode莶
set Unicode_Result=33718
exit/b
:Unicode33705
set Unicode_Result=莩
exit/b
:Unicode莩
set Unicode_Result=33705
exit/b
:Unicode33661
set Unicode_Result=荽
exit/b
:Unicode荽
set Unicode_Result=33661
exit/b
:Unicode33720
set Unicode_Result=莸
exit/b
:Unicode莸
set Unicode_Result=33720
exit/b
:Unicode33659
set Unicode_Result=荻
exit/b
:Unicode荻
set Unicode_Result=33659
exit/b
:Unicode33688
set Unicode_Result=莘
exit/b
:Unicode莘
set Unicode_Result=33688
exit/b
:Unicode33694
set Unicode_Result=莞
exit/b
:Unicode莞
set Unicode_Result=33694
exit/b
:Unicode33704
set Unicode_Result=莨
exit/b
:Unicode莨
set Unicode_Result=33704
exit/b
:Unicode33722
set Unicode_Result=莺
exit/b
:Unicode莺
set Unicode_Result=33722
exit/b
:Unicode33724
set Unicode_Result=莼
exit/b
:Unicode莼
set Unicode_Result=33724
exit/b
:Unicode33729
set Unicode_Result=菁
exit/b
:Unicode菁
set Unicode_Result=33729
exit/b
:Unicode33793
set Unicode_Result=萁
exit/b
:Unicode萁
set Unicode_Result=33793
exit/b
:Unicode33765
set Unicode_Result=菥
exit/b
:Unicode菥
set Unicode_Result=33765
exit/b
:Unicode33752
set Unicode_Result=菘
exit/b
:Unicode菘
set Unicode_Result=33752
exit/b
:Unicode22535
set Unicode_Result=堇
exit/b
:Unicode堇
set Unicode_Result=22535
exit/b
:Unicode33816
set Unicode_Result=萘
exit/b
:Unicode萘
set Unicode_Result=33816
exit/b
:Unicode33803
set Unicode_Result=萋
exit/b
:Unicode萋
set Unicode_Result=33803
exit/b
:Unicode33757
set Unicode_Result=菝
exit/b
:Unicode菝
set Unicode_Result=33757
exit/b
:Unicode33789
set Unicode_Result=菽
exit/b
:Unicode菽
set Unicode_Result=33789
exit/b
:Unicode33750
set Unicode_Result=菖
exit/b
:Unicode菖
set Unicode_Result=33750
exit/b
:Unicode33820
set Unicode_Result=萜
exit/b
:Unicode萜
set Unicode_Result=33820
exit/b
:Unicode33848
set Unicode_Result=萸
exit/b
:Unicode萸
set Unicode_Result=33848
exit/b
:Unicode33809
set Unicode_Result=萑
exit/b
:Unicode萑
set Unicode_Result=33809
exit/b
:Unicode33798
set Unicode_Result=萆
exit/b
:Unicode萆
set Unicode_Result=33798
exit/b
:Unicode33748
set Unicode_Result=菔
exit/b
:Unicode菔
set Unicode_Result=33748
exit/b
:Unicode33759
set Unicode_Result=菟
exit/b
:Unicode菟
set Unicode_Result=33759
exit/b
:Unicode33807
set Unicode_Result=萏
exit/b
:Unicode萏
set Unicode_Result=33807
exit/b
:Unicode33795
set Unicode_Result=萃
exit/b
:Unicode萃
set Unicode_Result=33795
exit/b
:Unicode33784
set Unicode_Result=菸
exit/b
:Unicode菸
set Unicode_Result=33784
exit/b
:Unicode33785
set Unicode_Result=菹
exit/b
:Unicode菹
set Unicode_Result=33785
exit/b
:Unicode33770
set Unicode_Result=菪
exit/b
:Unicode菪
set Unicode_Result=33770
exit/b
:Unicode33733
set Unicode_Result=菅
exit/b
:Unicode菅
set Unicode_Result=33733
exit/b
:Unicode33728
set Unicode_Result=菀
exit/b
:Unicode菀
set Unicode_Result=33728
exit/b
:Unicode33830
set Unicode_Result=萦
exit/b
:Unicode萦
set Unicode_Result=33830
exit/b
:Unicode33776
set Unicode_Result=菰
exit/b
:Unicode菰
set Unicode_Result=33776
exit/b
:Unicode33761
set Unicode_Result=菡
exit/b
:Unicode菡
set Unicode_Result=33761
exit/b
:Unicode33884
set Unicode_Result=葜
exit/b
:Unicode葜
set Unicode_Result=33884
exit/b
:Unicode33873
set Unicode_Result=葑
exit/b
:Unicode葑
set Unicode_Result=33873
exit/b
:Unicode33882
set Unicode_Result=葚
exit/b
:Unicode葚
set Unicode_Result=33882
exit/b
:Unicode33881
set Unicode_Result=葙
exit/b
:Unicode葙
set Unicode_Result=33881
exit/b
:Unicode33907
set Unicode_Result=葳
exit/b
:Unicode葳
set Unicode_Result=33907
exit/b
:Unicode33927
set Unicode_Result=蒇
exit/b
:Unicode蒇
set Unicode_Result=33927
exit/b
:Unicode33928
set Unicode_Result=蒈
exit/b
:Unicode蒈
set Unicode_Result=33928
exit/b
:Unicode33914
set Unicode_Result=葺
exit/b
:Unicode葺
set Unicode_Result=33914
exit/b
:Unicode33929
set Unicode_Result=蒉
exit/b
:Unicode蒉
set Unicode_Result=33929
exit/b
:Unicode33912
set Unicode_Result=葸
exit/b
:Unicode葸
set Unicode_Result=33912
exit/b
:Unicode33852
set Unicode_Result=萼
exit/b
:Unicode萼
set Unicode_Result=33852
exit/b
:Unicode33862
set Unicode_Result=葆
exit/b
:Unicode葆
set Unicode_Result=33862
exit/b
:Unicode33897
set Unicode_Result=葩
exit/b
:Unicode葩
set Unicode_Result=33897
exit/b
:Unicode33910
set Unicode_Result=葶
exit/b
:Unicode葶
set Unicode_Result=33910
exit/b
:Unicode33932
set Unicode_Result=蒌
exit/b
:Unicode蒌
set Unicode_Result=33932
exit/b
:Unicode33934
set Unicode_Result=蒎
exit/b
:Unicode蒎
set Unicode_Result=33934
exit/b
:Unicode33841
set Unicode_Result=萱
exit/b
:Unicode萱
set Unicode_Result=33841
exit/b
:Unicode33901
set Unicode_Result=葭
exit/b
:Unicode葭
set Unicode_Result=33901
exit/b
:Unicode33985
set Unicode_Result=蓁
exit/b
:Unicode蓁
set Unicode_Result=33985
exit/b
:Unicode33997
set Unicode_Result=蓍
exit/b
:Unicode蓍
set Unicode_Result=33997
exit/b
:Unicode34000
set Unicode_Result=蓐
exit/b
:Unicode蓐
set Unicode_Result=34000
exit/b
:Unicode34022
set Unicode_Result=蓦
exit/b
:Unicode蓦
set Unicode_Result=34022
exit/b
:Unicode33981
set Unicode_Result=蒽
exit/b
:Unicode蒽
set Unicode_Result=33981
exit/b
:Unicode34003
set Unicode_Result=蓓
exit/b
:Unicode蓓
set Unicode_Result=34003
exit/b
:Unicode33994
set Unicode_Result=蓊
exit/b
:Unicode蓊
set Unicode_Result=33994
exit/b
:Unicode33983
set Unicode_Result=蒿
exit/b
:Unicode蒿
set Unicode_Result=33983
exit/b
:Unicode33978
set Unicode_Result=蒺
exit/b
:Unicode蒺
set Unicode_Result=33978
exit/b
:Unicode34016
set Unicode_Result=蓠
exit/b
:Unicode蓠
set Unicode_Result=34016
exit/b
:Unicode33953
set Unicode_Result=蒡
exit/b
:Unicode蒡
set Unicode_Result=33953
exit/b
:Unicode33977
set Unicode_Result=蒹
exit/b
:Unicode蒹
set Unicode_Result=33977
exit/b
:Unicode33972
set Unicode_Result=蒴
exit/b
:Unicode蒴
set Unicode_Result=33972
exit/b
:Unicode33943
set Unicode_Result=蒗
exit/b
:Unicode蒗
set Unicode_Result=33943
exit/b
:Unicode34021
set Unicode_Result=蓥
exit/b
:Unicode蓥
set Unicode_Result=34021
exit/b
:Unicode34019
set Unicode_Result=蓣
exit/b
:Unicode蓣
set Unicode_Result=34019
exit/b
:Unicode34060
set Unicode_Result=蔌
exit/b
:Unicode蔌
set Unicode_Result=34060
exit/b
:Unicode29965
set Unicode_Result=甍
exit/b
:Unicode甍
set Unicode_Result=29965
exit/b
:Unicode34104
set Unicode_Result=蔸
exit/b
:Unicode蔸
set Unicode_Result=34104
exit/b
:Unicode34032
set Unicode_Result=蓰
exit/b
:Unicode蓰
set Unicode_Result=34032
exit/b
:Unicode34105
set Unicode_Result=蔹
exit/b
:Unicode蔹
set Unicode_Result=34105
exit/b
:Unicode34079
set Unicode_Result=蔟
exit/b
:Unicode蔟
set Unicode_Result=34079
exit/b
:Unicode34106
set Unicode_Result=蔺
exit/b
:Unicode蔺
set Unicode_Result=34106
exit/b
:Unicode34134
set Unicode_Result=蕖
exit/b
:Unicode蕖
set Unicode_Result=34134
exit/b
:Unicode34107
set Unicode_Result=蔻
exit/b
:Unicode蔻
set Unicode_Result=34107
exit/b
:Unicode34047
set Unicode_Result=蓿
exit/b
:Unicode蓿
set Unicode_Result=34047
exit/b
:Unicode34044
set Unicode_Result=蓼
exit/b
:Unicode蓼
set Unicode_Result=34044
exit/b
:Unicode34137
set Unicode_Result=蕙
exit/b
:Unicode蕙
set Unicode_Result=34137
exit/b
:Unicode34120
set Unicode_Result=蕈
exit/b
:Unicode蕈
set Unicode_Result=34120
exit/b
:Unicode34152
set Unicode_Result=蕨
exit/b
:Unicode蕨
set Unicode_Result=34152
exit/b
:Unicode34148
set Unicode_Result=蕤
exit/b
:Unicode蕤
set Unicode_Result=34148
exit/b
:Unicode34142
set Unicode_Result=蕞
exit/b
:Unicode蕞
set Unicode_Result=34142
exit/b
:Unicode34170
set Unicode_Result=蕺
exit/b
:Unicode蕺
set Unicode_Result=34170
exit/b
:Unicode30626
set Unicode_Result=瞢
exit/b
:Unicode瞢
set Unicode_Result=30626
exit/b
:Unicode34115
set Unicode_Result=蕃
exit/b
:Unicode蕃
set Unicode_Result=34115
exit/b
:Unicode34162
set Unicode_Result=蕲
exit/b
:Unicode蕲
set Unicode_Result=34162
exit/b
:Unicode34171
set Unicode_Result=蕻
exit/b
:Unicode蕻
set Unicode_Result=34171
exit/b
:Unicode34212
set Unicode_Result=薤
exit/b
:Unicode薤
set Unicode_Result=34212
exit/b
:Unicode34216
set Unicode_Result=薨
exit/b
:Unicode薨
set Unicode_Result=34216
exit/b
:Unicode34183
set Unicode_Result=薇
exit/b
:Unicode薇
set Unicode_Result=34183
exit/b
:Unicode34191
set Unicode_Result=薏
exit/b
:Unicode薏
set Unicode_Result=34191
exit/b
:Unicode34169
set Unicode_Result=蕹
exit/b
:Unicode蕹
set Unicode_Result=34169
exit/b
:Unicode34222
set Unicode_Result=薮
exit/b
:Unicode薮
set Unicode_Result=34222
exit/b
:Unicode34204
set Unicode_Result=薜
exit/b
:Unicode薜
set Unicode_Result=34204
exit/b
:Unicode34181
set Unicode_Result=薅
exit/b
:Unicode薅
set Unicode_Result=34181
exit/b
:Unicode34233
set Unicode_Result=薹
exit/b
:Unicode薹
set Unicode_Result=34233
exit/b
:Unicode34231
set Unicode_Result=薷
exit/b
:Unicode薷
set Unicode_Result=34231
exit/b
:Unicode34224
set Unicode_Result=薰
exit/b
:Unicode薰
set Unicode_Result=34224
exit/b
:Unicode34259
set Unicode_Result=藓
exit/b
:Unicode藓
set Unicode_Result=34259
exit/b
:Unicode34241
set Unicode_Result=藁
exit/b
:Unicode藁
set Unicode_Result=34241
exit/b
:Unicode34268
set Unicode_Result=藜
exit/b
:Unicode藜
set Unicode_Result=34268
exit/b
:Unicode34303
set Unicode_Result=藿
exit/b
:Unicode藿
set Unicode_Result=34303
exit/b
:Unicode34343
set Unicode_Result=蘧
exit/b
:Unicode蘧
set Unicode_Result=34343
exit/b
:Unicode34309
set Unicode_Result=蘅
exit/b
:Unicode蘅
set Unicode_Result=34309
exit/b
:Unicode34345
set Unicode_Result=蘩
exit/b
:Unicode蘩
set Unicode_Result=34345
exit/b
:Unicode34326
set Unicode_Result=蘖
exit/b
:Unicode蘖
set Unicode_Result=34326
exit/b
:Unicode34364
set Unicode_Result=蘼
exit/b
:Unicode蘼
set Unicode_Result=34364
exit/b
:Unicode24318
set Unicode_Result=廾
exit/b
:Unicode廾
set Unicode_Result=24318
exit/b
:Unicode24328
set Unicode_Result=弈
exit/b
:Unicode弈
set Unicode_Result=24328
exit/b
:Unicode22844
set Unicode_Result=夼
exit/b
:Unicode夼
set Unicode_Result=22844
exit/b
:Unicode22849
set Unicode_Result=奁
exit/b
:Unicode奁
set Unicode_Result=22849
exit/b
:Unicode32823
set Unicode_Result=耷
exit/b
:Unicode耷
set Unicode_Result=32823
exit/b
:Unicode22869
set Unicode_Result=奕
exit/b
:Unicode奕
set Unicode_Result=22869
exit/b
:Unicode22874
set Unicode_Result=奚
exit/b
:Unicode奚
set Unicode_Result=22874
exit/b
:Unicode22872
set Unicode_Result=奘
exit/b
:Unicode奘
set Unicode_Result=22872
exit/b
:Unicode21263
set Unicode_Result=匏
exit/b
:Unicode匏
set Unicode_Result=21263
exit/b
:Unicode23586
set Unicode_Result=尢
exit/b
:Unicode尢
set Unicode_Result=23586
exit/b
:Unicode23589
set Unicode_Result=尥
exit/b
:Unicode尥
set Unicode_Result=23589
exit/b
:Unicode23596
set Unicode_Result=尬
exit/b
:Unicode尬
set Unicode_Result=23596
exit/b
:Unicode23604
set Unicode_Result=尴
exit/b
:Unicode尴
set Unicode_Result=23604
exit/b
:Unicode25164
set Unicode_Result=扌
exit/b
:Unicode扌
set Unicode_Result=25164
exit/b
:Unicode25194
set Unicode_Result=扪
exit/b
:Unicode扪
set Unicode_Result=25194
exit/b
:Unicode25247
set Unicode_Result=抟
exit/b
:Unicode抟
set Unicode_Result=25247
exit/b
:Unicode25275
set Unicode_Result=抻
exit/b
:Unicode抻
set Unicode_Result=25275
exit/b
:Unicode25290
set Unicode_Result=拊
exit/b
:Unicode拊
set Unicode_Result=25290
exit/b
:Unicode25306
set Unicode_Result=拚
exit/b
:Unicode拚
set Unicode_Result=25306
exit/b
:Unicode25303
set Unicode_Result=拗
exit/b
:Unicode拗
set Unicode_Result=25303
exit/b
:Unicode25326
set Unicode_Result=拮
exit/b
:Unicode拮
set Unicode_Result=25326
exit/b
:Unicode25378
set Unicode_Result=挢
exit/b
:Unicode挢
set Unicode_Result=25378
exit/b
:Unicode25334
set Unicode_Result=拶
exit/b
:Unicode拶
set Unicode_Result=25334
exit/b
:Unicode25401
set Unicode_Result=挹
exit/b
:Unicode挹
set Unicode_Result=25401
exit/b
:Unicode25419
set Unicode_Result=捋
exit/b
:Unicode捋
set Unicode_Result=25419
exit/b
:Unicode25411
set Unicode_Result=捃
exit/b
:Unicode捃
set Unicode_Result=25411
exit/b
:Unicode25517
set Unicode_Result=掭
exit/b
:Unicode掭
set Unicode_Result=25517
exit/b
:Unicode25590
set Unicode_Result=揶
exit/b
:Unicode揶
set Unicode_Result=25590
exit/b
:Unicode25457
set Unicode_Result=捱
exit/b
:Unicode捱
set Unicode_Result=25457
exit/b
:Unicode25466
set Unicode_Result=捺
exit/b
:Unicode捺
set Unicode_Result=25466
exit/b
:Unicode25486
set Unicode_Result=掎
exit/b
:Unicode掎
set Unicode_Result=25486
exit/b
:Unicode25524
set Unicode_Result=掴
exit/b
:Unicode掴
set Unicode_Result=25524
exit/b
:Unicode25453
set Unicode_Result=捭
exit/b
:Unicode捭
set Unicode_Result=25453
exit/b
:Unicode25516
set Unicode_Result=掬
exit/b
:Unicode掬
set Unicode_Result=25516
exit/b
:Unicode25482
set Unicode_Result=掊
exit/b
:Unicode掊
set Unicode_Result=25482
exit/b
:Unicode25449
set Unicode_Result=捩
exit/b
:Unicode捩
set Unicode_Result=25449
exit/b
:Unicode25518
set Unicode_Result=掮
exit/b
:Unicode掮
set Unicode_Result=25518
exit/b
:Unicode25532
set Unicode_Result=掼
exit/b
:Unicode掼
set Unicode_Result=25532
exit/b
:Unicode25586
set Unicode_Result=揲
exit/b
:Unicode揲
set Unicode_Result=25586
exit/b
:Unicode25592
set Unicode_Result=揸
exit/b
:Unicode揸
set Unicode_Result=25592
exit/b
:Unicode25568
set Unicode_Result=揠
exit/b
:Unicode揠
set Unicode_Result=25568
exit/b
:Unicode25599
set Unicode_Result=揿
exit/b
:Unicode揿
set Unicode_Result=25599
exit/b
:Unicode25540
set Unicode_Result=揄
exit/b
:Unicode揄
set Unicode_Result=25540
exit/b
:Unicode25566
set Unicode_Result=揞
exit/b
:Unicode揞
set Unicode_Result=25566
exit/b
:Unicode25550
set Unicode_Result=揎
exit/b
:Unicode揎
set Unicode_Result=25550
exit/b
:Unicode25682
set Unicode_Result=摒
exit/b
:Unicode摒
set Unicode_Result=25682
exit/b
:Unicode25542
set Unicode_Result=揆
exit/b
:Unicode揆
set Unicode_Result=25542
exit/b
:Unicode25534
set Unicode_Result=掾
exit/b
:Unicode掾
set Unicode_Result=25534
exit/b
:Unicode25669
set Unicode_Result=摅
exit/b
:Unicode摅
set Unicode_Result=25669
exit/b
:Unicode25665
set Unicode_Result=摁
exit/b
:Unicode摁
set Unicode_Result=25665
exit/b
:Unicode25611
set Unicode_Result=搋
exit/b
:Unicode搋
set Unicode_Result=25611
exit/b
:Unicode25627
set Unicode_Result=搛
exit/b
:Unicode搛
set Unicode_Result=25627
exit/b
:Unicode25632
set Unicode_Result=搠
exit/b
:Unicode搠
set Unicode_Result=25632
exit/b
:Unicode25612
set Unicode_Result=搌
exit/b
:Unicode搌
set Unicode_Result=25612
exit/b
:Unicode25638
set Unicode_Result=搦
exit/b
:Unicode搦
set Unicode_Result=25638
exit/b
:Unicode25633
set Unicode_Result=搡
exit/b
:Unicode搡
set Unicode_Result=25633
exit/b
:Unicode25694
set Unicode_Result=摞
exit/b
:Unicode摞
set Unicode_Result=25694
exit/b
:Unicode25732
set Unicode_Result=撄
exit/b
:Unicode撄
set Unicode_Result=25732
exit/b
:Unicode25709
set Unicode_Result=摭
exit/b
:Unicode摭
set Unicode_Result=25709
exit/b
:Unicode25750
set Unicode_Result=撖
exit/b
:Unicode撖
set Unicode_Result=25750
exit/b
:Unicode25722
set Unicode_Result=摺
exit/b
:Unicode摺
set Unicode_Result=25722
exit/b
:Unicode25783
set Unicode_Result=撷
exit/b
:Unicode撷
set Unicode_Result=25783
exit/b
:Unicode25784
set Unicode_Result=撸
exit/b
:Unicode撸
set Unicode_Result=25784
exit/b
:Unicode25753
set Unicode_Result=撙
exit/b
:Unicode撙
set Unicode_Result=25753
exit/b
:Unicode25786
set Unicode_Result=撺
exit/b
:Unicode撺
set Unicode_Result=25786
exit/b
:Unicode25792
set Unicode_Result=擀
exit/b
:Unicode擀
set Unicode_Result=25792
exit/b
:Unicode25808
set Unicode_Result=擐
exit/b
:Unicode擐
set Unicode_Result=25808
exit/b
:Unicode25815
set Unicode_Result=擗
exit/b
:Unicode擗
set Unicode_Result=25815
exit/b
:Unicode25828
set Unicode_Result=擤
exit/b
:Unicode擤
set Unicode_Result=25828
exit/b
:Unicode25826
set Unicode_Result=擢
exit/b
:Unicode擢
set Unicode_Result=25826
exit/b
:Unicode25865
set Unicode_Result=攉
exit/b
:Unicode攉
set Unicode_Result=25865
exit/b
:Unicode25893
set Unicode_Result=攥
exit/b
:Unicode攥
set Unicode_Result=25893
exit/b
:Unicode25902
set Unicode_Result=攮
exit/b
:Unicode攮
set Unicode_Result=25902
exit/b
:Unicode24331
set Unicode_Result=弋
exit/b
:Unicode弋
set Unicode_Result=24331
exit/b
:Unicode24530
set Unicode_Result=忒
exit/b
:Unicode忒
set Unicode_Result=24530
exit/b
:Unicode29977
set Unicode_Result=甙
exit/b
:Unicode甙
set Unicode_Result=29977
exit/b
:Unicode24337
set Unicode_Result=弑
exit/b
:Unicode弑
set Unicode_Result=24337
exit/b
:Unicode21343
set Unicode_Result=卟
exit/b
:Unicode卟
set Unicode_Result=21343
exit/b
:Unicode21489
set Unicode_Result=叱
exit/b
:Unicode叱
set Unicode_Result=21489
exit/b
:Unicode21501
set Unicode_Result=叽
exit/b
:Unicode叽
set Unicode_Result=21501
exit/b
:Unicode21481
set Unicode_Result=叩
exit/b
:Unicode叩
set Unicode_Result=21481
exit/b
:Unicode21480
set Unicode_Result=叨
exit/b
:Unicode叨
set Unicode_Result=21480
exit/b
:Unicode21499
set Unicode_Result=叻
exit/b
:Unicode叻
set Unicode_Result=21499
exit/b
:Unicode21522
set Unicode_Result=吒
exit/b
:Unicode吒
set Unicode_Result=21522
exit/b
:Unicode21526
set Unicode_Result=吖
exit/b
:Unicode吖
set Unicode_Result=21526
exit/b
:Unicode21510
set Unicode_Result=吆
exit/b
:Unicode吆
set Unicode_Result=21510
exit/b
:Unicode21579
set Unicode_Result=呋
exit/b
:Unicode呋
set Unicode_Result=21579
exit/b
:Unicode21586
set Unicode_Result=呒
exit/b
:Unicode呒
set Unicode_Result=21586
exit/b
:Unicode21587
set Unicode_Result=呓
exit/b
:Unicode呓
set Unicode_Result=21587
exit/b
:Unicode21588
set Unicode_Result=呔
exit/b
:Unicode呔
set Unicode_Result=21588
exit/b
:Unicode21590
set Unicode_Result=呖
exit/b
:Unicode呖
set Unicode_Result=21590
exit/b
:Unicode21571
set Unicode_Result=呃
exit/b
:Unicode呃
set Unicode_Result=21571
exit/b
:Unicode21537
set Unicode_Result=吡
exit/b
:Unicode吡
set Unicode_Result=21537
exit/b
:Unicode21591
set Unicode_Result=呗
exit/b
:Unicode呗
set Unicode_Result=21591
exit/b
:Unicode21593
set Unicode_Result=呙
exit/b
:Unicode呙
set Unicode_Result=21593
exit/b
:Unicode21539
set Unicode_Result=吣
exit/b
:Unicode吣
set Unicode_Result=21539
exit/b
:Unicode21554
set Unicode_Result=吲
exit/b
:Unicode吲
set Unicode_Result=21554
exit/b
:Unicode21634
set Unicode_Result=咂
exit/b
:Unicode咂
set Unicode_Result=21634
exit/b
:Unicode21652
set Unicode_Result=咔
exit/b
:Unicode咔
set Unicode_Result=21652
exit/b
:Unicode21623
set Unicode_Result=呷
exit/b
:Unicode呷
set Unicode_Result=21623
exit/b
:Unicode21617
set Unicode_Result=呱
exit/b
:Unicode呱
set Unicode_Result=21617
exit/b
:Unicode21604
set Unicode_Result=呤
exit/b
:Unicode呤
set Unicode_Result=21604
exit/b
:Unicode21658
set Unicode_Result=咚
exit/b
:Unicode咚
set Unicode_Result=21658
exit/b
:Unicode21659
set Unicode_Result=咛
exit/b
:Unicode咛
set Unicode_Result=21659
exit/b
:Unicode21636
set Unicode_Result=咄
exit/b
:Unicode咄
set Unicode_Result=21636
exit/b
:Unicode21622
set Unicode_Result=呶
exit/b
:Unicode呶
set Unicode_Result=21622
exit/b
:Unicode21606
set Unicode_Result=呦
exit/b
:Unicode呦
set Unicode_Result=21606
exit/b
:Unicode21661
set Unicode_Result=咝
exit/b
:Unicode咝
set Unicode_Result=21661
exit/b
:Unicode21712
set Unicode_Result=哐
exit/b
:Unicode哐
set Unicode_Result=21712
exit/b
:Unicode21677
set Unicode_Result=咭
exit/b
:Unicode咭
set Unicode_Result=21677
exit/b
:Unicode21698
set Unicode_Result=哂
exit/b
:Unicode哂
set Unicode_Result=21698
exit/b
:Unicode21684
set Unicode_Result=咴
exit/b
:Unicode咴
set Unicode_Result=21684
exit/b
:Unicode21714
set Unicode_Result=哒
exit/b
:Unicode哒
set Unicode_Result=21714
exit/b
:Unicode21671
set Unicode_Result=咧
exit/b
:Unicode咧
set Unicode_Result=21671
exit/b
:Unicode21670
set Unicode_Result=咦
exit/b
:Unicode咦
set Unicode_Result=21670
exit/b
:Unicode21715
set Unicode_Result=哓
exit/b
:Unicode哓
set Unicode_Result=21715
exit/b
:Unicode21716
set Unicode_Result=哔
exit/b
:Unicode哔
set Unicode_Result=21716
exit/b
:Unicode21618
set Unicode_Result=呲
exit/b
:Unicode呲
set Unicode_Result=21618
exit/b
:Unicode21667
set Unicode_Result=咣
exit/b
:Unicode咣
set Unicode_Result=21667
exit/b
:Unicode21717
set Unicode_Result=哕
exit/b
:Unicode哕
set Unicode_Result=21717
exit/b
:Unicode21691
set Unicode_Result=咻
exit/b
:Unicode咻
set Unicode_Result=21691
exit/b
:Unicode21695
set Unicode_Result=咿
exit/b
:Unicode咿
set Unicode_Result=21695
exit/b
:Unicode21708
set Unicode_Result=哌
exit/b
:Unicode哌
set Unicode_Result=21708
exit/b
:Unicode21721
set Unicode_Result=哙
exit/b
:Unicode哙
set Unicode_Result=21721
exit/b
:Unicode21722
set Unicode_Result=哚
exit/b
:Unicode哚
set Unicode_Result=21722
exit/b
:Unicode21724
set Unicode_Result=哜
exit/b
:Unicode哜
set Unicode_Result=21724
exit/b
:Unicode21673
set Unicode_Result=咩
exit/b
:Unicode咩
set Unicode_Result=21673
exit/b
:Unicode21674
set Unicode_Result=咪
exit/b
:Unicode咪
set Unicode_Result=21674
exit/b
:Unicode21668
set Unicode_Result=咤
exit/b
:Unicode咤
set Unicode_Result=21668
exit/b
:Unicode21725
set Unicode_Result=哝
exit/b
:Unicode哝
set Unicode_Result=21725
exit/b
:Unicode21711
set Unicode_Result=哏
exit/b
:Unicode哏
set Unicode_Result=21711
exit/b
:Unicode21726
set Unicode_Result=哞
exit/b
:Unicode哞
set Unicode_Result=21726
exit/b
:Unicode21787
set Unicode_Result=唛
exit/b
:Unicode唛
set Unicode_Result=21787
exit/b
:Unicode21735
set Unicode_Result=哧
exit/b
:Unicode哧
set Unicode_Result=21735
exit/b
:Unicode21792
set Unicode_Result=唠
exit/b
:Unicode唠
set Unicode_Result=21792
exit/b
:Unicode21757
set Unicode_Result=哽
exit/b
:Unicode哽
set Unicode_Result=21757
exit/b
:Unicode21780
set Unicode_Result=唔
exit/b
:Unicode唔
set Unicode_Result=21780
exit/b
:Unicode21747
set Unicode_Result=哳
exit/b
:Unicode哳
set Unicode_Result=21747
exit/b
:Unicode21794
set Unicode_Result=唢
exit/b
:Unicode唢
set Unicode_Result=21794
exit/b
:Unicode21795
set Unicode_Result=唣
exit/b
:Unicode唣
set Unicode_Result=21795
exit/b
:Unicode21775
set Unicode_Result=唏
exit/b
:Unicode唏
set Unicode_Result=21775
exit/b
:Unicode21777
set Unicode_Result=唑
exit/b
:Unicode唑
set Unicode_Result=21777
exit/b
:Unicode21799
set Unicode_Result=唧
exit/b
:Unicode唧
set Unicode_Result=21799
exit/b
:Unicode21802
set Unicode_Result=唪
exit/b
:Unicode唪
set Unicode_Result=21802
exit/b
:Unicode21863
set Unicode_Result=啧
exit/b
:Unicode啧
set Unicode_Result=21863
exit/b
:Unicode21903
set Unicode_Result=喏
exit/b
:Unicode喏
set Unicode_Result=21903
exit/b
:Unicode21941
set Unicode_Result=喵
exit/b
:Unicode喵
set Unicode_Result=21941
exit/b
:Unicode21833
set Unicode_Result=啉
exit/b
:Unicode啉
set Unicode_Result=21833
exit/b
:Unicode21869
set Unicode_Result=啭
exit/b
:Unicode啭
set Unicode_Result=21869
exit/b
:Unicode21825
set Unicode_Result=啁
exit/b
:Unicode啁
set Unicode_Result=21825
exit/b
:Unicode21845
set Unicode_Result=啕
exit/b
:Unicode啕
set Unicode_Result=21845
exit/b
:Unicode21823
set Unicode_Result=唿
exit/b
:Unicode唿
set Unicode_Result=21823
exit/b
:Unicode21840
set Unicode_Result=啐
exit/b
:Unicode啐
set Unicode_Result=21840
exit/b
:Unicode21820
set Unicode_Result=唼
exit/b
:Unicode唼
set Unicode_Result=21820
exit/b
:Unicode21815
set Unicode_Result=唷
exit/b
:Unicode唷
set Unicode_Result=21815
exit/b
:Unicode21846
set Unicode_Result=啖
exit/b
:Unicode啖
set Unicode_Result=21846
exit/b
:Unicode21877
set Unicode_Result=啵
exit/b
:Unicode啵
set Unicode_Result=21877
exit/b
:Unicode21878
set Unicode_Result=啶
exit/b
:Unicode啶
set Unicode_Result=21878
exit/b
:Unicode21879
set Unicode_Result=啷
exit/b
:Unicode啷
set Unicode_Result=21879
exit/b
:Unicode21811
set Unicode_Result=唳
exit/b
:Unicode唳
set Unicode_Result=21811
exit/b
:Unicode21808
set Unicode_Result=唰
exit/b
:Unicode唰
set Unicode_Result=21808
exit/b
:Unicode21852
set Unicode_Result=啜
exit/b
:Unicode啜
set Unicode_Result=21852
exit/b
:Unicode21899
set Unicode_Result=喋
exit/b
:Unicode喋
set Unicode_Result=21899
exit/b
:Unicode21970
set Unicode_Result=嗒
exit/b
:Unicode嗒
set Unicode_Result=21970
exit/b
:Unicode21891
set Unicode_Result=喃
exit/b
:Unicode喃
set Unicode_Result=21891
exit/b
:Unicode21937
set Unicode_Result=喱
exit/b
:Unicode喱
set Unicode_Result=21937
exit/b
:Unicode21945
set Unicode_Result=喹
exit/b
:Unicode喹
set Unicode_Result=21945
exit/b
:Unicode21896
set Unicode_Result=喈
exit/b
:Unicode喈
set Unicode_Result=21896
exit/b
:Unicode21889
set Unicode_Result=喁
exit/b
:Unicode喁
set Unicode_Result=21889
exit/b
:Unicode21919
set Unicode_Result=喟
exit/b
:Unicode喟
set Unicode_Result=21919
exit/b
:Unicode21886
set Unicode_Result=啾
exit/b
:Unicode啾
set Unicode_Result=21886
exit/b
:Unicode21974
set Unicode_Result=嗖
exit/b
:Unicode嗖
set Unicode_Result=21974
exit/b
:Unicode21905
set Unicode_Result=喑
exit/b
:Unicode喑
set Unicode_Result=21905
exit/b
:Unicode21883
set Unicode_Result=啻
exit/b
:Unicode啻
set Unicode_Result=21883
exit/b
:Unicode21983
set Unicode_Result=嗟
exit/b
:Unicode嗟
set Unicode_Result=21983
exit/b
:Unicode21949
set Unicode_Result=喽
exit/b
:Unicode喽
set Unicode_Result=21949
exit/b
:Unicode21950
set Unicode_Result=喾
exit/b
:Unicode喾
set Unicode_Result=21950
exit/b
:Unicode21908
set Unicode_Result=喔
exit/b
:Unicode喔
set Unicode_Result=21908
exit/b
:Unicode21913
set Unicode_Result=喙
exit/b
:Unicode喙
set Unicode_Result=21913
exit/b
:Unicode21994
set Unicode_Result=嗪
exit/b
:Unicode嗪
set Unicode_Result=21994
exit/b
:Unicode22007
set Unicode_Result=嗷
exit/b
:Unicode嗷
set Unicode_Result=22007
exit/b
:Unicode21961
set Unicode_Result=嗉
exit/b
:Unicode嗉
set Unicode_Result=21961
exit/b
:Unicode22047
set Unicode_Result=嘟
exit/b
:Unicode嘟
set Unicode_Result=22047
exit/b
:Unicode21969
set Unicode_Result=嗑
exit/b
:Unicode嗑
set Unicode_Result=21969
exit/b
:Unicode21995
set Unicode_Result=嗫
exit/b
:Unicode嗫
set Unicode_Result=21995
exit/b
:Unicode21996
set Unicode_Result=嗬
exit/b
:Unicode嗬
set Unicode_Result=21996
exit/b
:Unicode21972
set Unicode_Result=嗔
exit/b
:Unicode嗔
set Unicode_Result=21972
exit/b
:Unicode21990
set Unicode_Result=嗦
exit/b
:Unicode嗦
set Unicode_Result=21990
exit/b
:Unicode21981
set Unicode_Result=嗝
exit/b
:Unicode嗝
set Unicode_Result=21981
exit/b
:Unicode21956
set Unicode_Result=嗄
exit/b
:Unicode嗄
set Unicode_Result=21956
exit/b
:Unicode21999
set Unicode_Result=嗯
exit/b
:Unicode嗯
set Unicode_Result=21999
exit/b
:Unicode21989
set Unicode_Result=嗥
exit/b
:Unicode嗥
set Unicode_Result=21989
exit/b
:Unicode22002
set Unicode_Result=嗲
exit/b
:Unicode嗲
set Unicode_Result=22002
exit/b
:Unicode22003
set Unicode_Result=嗳
exit/b
:Unicode嗳
set Unicode_Result=22003
exit/b
:Unicode21964
set Unicode_Result=嗌
exit/b
:Unicode嗌
set Unicode_Result=21964
exit/b
:Unicode21965
set Unicode_Result=嗍
exit/b
:Unicode嗍
set Unicode_Result=21965
exit/b
:Unicode21992
set Unicode_Result=嗨
exit/b
:Unicode嗨
set Unicode_Result=21992
exit/b
:Unicode22005
set Unicode_Result=嗵
exit/b
:Unicode嗵
set Unicode_Result=22005
exit/b
:Unicode21988
set Unicode_Result=嗤
exit/b
:Unicode嗤
set Unicode_Result=21988
exit/b
:Unicode36756
set Unicode_Result=辔
exit/b
:Unicode辔
set Unicode_Result=36756
exit/b
:Unicode22046
set Unicode_Result=嘞
exit/b
:Unicode嘞
set Unicode_Result=22046
exit/b
:Unicode22024
set Unicode_Result=嘈
exit/b
:Unicode嘈
set Unicode_Result=22024
exit/b
:Unicode22028
set Unicode_Result=嘌
exit/b
:Unicode嘌
set Unicode_Result=22028
exit/b
:Unicode22017
set Unicode_Result=嘁
exit/b
:Unicode嘁
set Unicode_Result=22017
exit/b
:Unicode22052
set Unicode_Result=嘤
exit/b
:Unicode嘤
set Unicode_Result=22052
exit/b
:Unicode22051
set Unicode_Result=嘣
exit/b
:Unicode嘣
set Unicode_Result=22051
exit/b
:Unicode22014
set Unicode_Result=嗾
exit/b
:Unicode嗾
set Unicode_Result=22014
exit/b
:Unicode22016
set Unicode_Result=嘀
exit/b
:Unicode嘀
set Unicode_Result=22016
exit/b
:Unicode22055
set Unicode_Result=嘧
exit/b
:Unicode嘧
set Unicode_Result=22055
exit/b
:Unicode22061
set Unicode_Result=嘭
exit/b
:Unicode嘭
set Unicode_Result=22061
exit/b
:Unicode22104
set Unicode_Result=噘
exit/b
:Unicode噘
set Unicode_Result=22104
exit/b
:Unicode22073
set Unicode_Result=嘹
exit/b
:Unicode嘹
set Unicode_Result=22073
exit/b
:Unicode22103
set Unicode_Result=噗
exit/b
:Unicode噗
set Unicode_Result=22103
exit/b
:Unicode22060
set Unicode_Result=嘬
exit/b
:Unicode嘬
set Unicode_Result=22060
exit/b
:Unicode22093
set Unicode_Result=噍
exit/b
:Unicode噍
set Unicode_Result=22093
exit/b
:Unicode22114
set Unicode_Result=噢
exit/b
:Unicode噢
set Unicode_Result=22114
exit/b
:Unicode22105
set Unicode_Result=噙
exit/b
:Unicode噙
set Unicode_Result=22105
exit/b
:Unicode22108
set Unicode_Result=噜
exit/b
:Unicode噜
set Unicode_Result=22108
exit/b
:Unicode22092
set Unicode_Result=噌
exit/b
:Unicode噌
set Unicode_Result=22092
exit/b
:Unicode22100
set Unicode_Result=噔
exit/b
:Unicode噔
set Unicode_Result=22100
exit/b
:Unicode22150
set Unicode_Result=嚆
exit/b
:Unicode嚆
set Unicode_Result=22150
exit/b
:Unicode22116
set Unicode_Result=噤
exit/b
:Unicode噤
set Unicode_Result=22116
exit/b
:Unicode22129
set Unicode_Result=噱
exit/b
:Unicode噱
set Unicode_Result=22129
exit/b
:Unicode22123
set Unicode_Result=噫
exit/b
:Unicode噫
set Unicode_Result=22123
exit/b
:Unicode22139
set Unicode_Result=噻
exit/b
:Unicode噻
set Unicode_Result=22139
exit/b
:Unicode22140
set Unicode_Result=噼
exit/b
:Unicode噼
set Unicode_Result=22140
exit/b
:Unicode22149
set Unicode_Result=嚅
exit/b
:Unicode嚅
set Unicode_Result=22149
exit/b
:Unicode22163
set Unicode_Result=嚓
exit/b
:Unicode嚓
set Unicode_Result=22163
exit/b
:Unicode22191
set Unicode_Result=嚯
exit/b
:Unicode嚯
set Unicode_Result=22191
exit/b
:Unicode22228
set Unicode_Result=囔
exit/b
:Unicode囔
set Unicode_Result=22228
exit/b
:Unicode22231
set Unicode_Result=囗
exit/b
:Unicode囗
set Unicode_Result=22231
exit/b
:Unicode22237
set Unicode_Result=囝
exit/b
:Unicode囝
set Unicode_Result=22237
exit/b
:Unicode22241
set Unicode_Result=囡
exit/b
:Unicode囡
set Unicode_Result=22241
exit/b
:Unicode22261
set Unicode_Result=囵
exit/b
:Unicode囵
set Unicode_Result=22261
exit/b
:Unicode22251
set Unicode_Result=囫
exit/b
:Unicode囫
set Unicode_Result=22251
exit/b
:Unicode22265
set Unicode_Result=囹
exit/b
:Unicode囹
set Unicode_Result=22265
exit/b
:Unicode22271
set Unicode_Result=囿
exit/b
:Unicode囿
set Unicode_Result=22271
exit/b
:Unicode22276
set Unicode_Result=圄
exit/b
:Unicode圄
set Unicode_Result=22276
exit/b
:Unicode22282
set Unicode_Result=圊
exit/b
:Unicode圊
set Unicode_Result=22282
exit/b
:Unicode22281
set Unicode_Result=圉
exit/b
:Unicode圉
set Unicode_Result=22281
exit/b
:Unicode22300
set Unicode_Result=圜
exit/b
:Unicode圜
set Unicode_Result=22300
exit/b
:Unicode24079
set Unicode_Result=帏
exit/b
:Unicode帏
set Unicode_Result=24079
exit/b
:Unicode24089
set Unicode_Result=帙
exit/b
:Unicode帙
set Unicode_Result=24089
exit/b
:Unicode24084
set Unicode_Result=帔
exit/b
:Unicode帔
set Unicode_Result=24084
exit/b
:Unicode24081
set Unicode_Result=帑
exit/b
:Unicode帑
set Unicode_Result=24081
exit/b
:Unicode24113
set Unicode_Result=帱
exit/b
:Unicode帱
set Unicode_Result=24113
exit/b
:Unicode24123
set Unicode_Result=帻
exit/b
:Unicode帻
set Unicode_Result=24123
exit/b
:Unicode24124
set Unicode_Result=帼
exit/b
:Unicode帼
set Unicode_Result=24124
exit/b
:Unicode24119
set Unicode_Result=帷
exit/b
:Unicode帷
set Unicode_Result=24119
exit/b
:Unicode24132
set Unicode_Result=幄
exit/b
:Unicode幄
set Unicode_Result=24132
exit/b
:Unicode24148
set Unicode_Result=幔
exit/b
:Unicode幔
set Unicode_Result=24148
exit/b
:Unicode24155
set Unicode_Result=幛
exit/b
:Unicode幛
set Unicode_Result=24155
exit/b
:Unicode24158
set Unicode_Result=幞
exit/b
:Unicode幞
set Unicode_Result=24158
exit/b
:Unicode24161
set Unicode_Result=幡
exit/b
:Unicode幡
set Unicode_Result=24161
exit/b
:Unicode23692
set Unicode_Result=岌
exit/b
:Unicode岌
set Unicode_Result=23692
exit/b
:Unicode23674
set Unicode_Result=屺
exit/b
:Unicode屺
set Unicode_Result=23674
exit/b
:Unicode23693
set Unicode_Result=岍
exit/b
:Unicode岍
set Unicode_Result=23693
exit/b
:Unicode23696
set Unicode_Result=岐
exit/b
:Unicode岐
set Unicode_Result=23696
exit/b
:Unicode23702
set Unicode_Result=岖
exit/b
:Unicode岖
set Unicode_Result=23702
exit/b
:Unicode23688
set Unicode_Result=岈
exit/b
:Unicode岈
set Unicode_Result=23688
exit/b
:Unicode23704
set Unicode_Result=岘
exit/b
:Unicode岘
set Unicode_Result=23704
exit/b
:Unicode23705
set Unicode_Result=岙
exit/b
:Unicode岙
set Unicode_Result=23705
exit/b
:Unicode23697
set Unicode_Result=岑
exit/b
:Unicode岑
set Unicode_Result=23697
exit/b
:Unicode23706
set Unicode_Result=岚
exit/b
:Unicode岚
set Unicode_Result=23706
exit/b
:Unicode23708
set Unicode_Result=岜
exit/b
:Unicode岜
set Unicode_Result=23708
exit/b
:Unicode23733
set Unicode_Result=岵
exit/b
:Unicode岵
set Unicode_Result=23733
exit/b
:Unicode23714
set Unicode_Result=岢
exit/b
:Unicode岢
set Unicode_Result=23714
exit/b
:Unicode23741
set Unicode_Result=岽
exit/b
:Unicode岽
set Unicode_Result=23741
exit/b
:Unicode23724
set Unicode_Result=岬
exit/b
:Unicode岬
set Unicode_Result=23724
exit/b
:Unicode23723
set Unicode_Result=岫
exit/b
:Unicode岫
set Unicode_Result=23723
exit/b
:Unicode23729
set Unicode_Result=岱
exit/b
:Unicode岱
set Unicode_Result=23729
exit/b
:Unicode23715
set Unicode_Result=岣
exit/b
:Unicode岣
set Unicode_Result=23715
exit/b
:Unicode23745
set Unicode_Result=峁
exit/b
:Unicode峁
set Unicode_Result=23745
exit/b
:Unicode23735
set Unicode_Result=岷
exit/b
:Unicode岷
set Unicode_Result=23735
exit/b
:Unicode23748
set Unicode_Result=峄
exit/b
:Unicode峄
set Unicode_Result=23748
exit/b
:Unicode23762
set Unicode_Result=峒
exit/b
:Unicode峒
set Unicode_Result=23762
exit/b
:Unicode23780
set Unicode_Result=峤
exit/b
:Unicode峤
set Unicode_Result=23780
exit/b
:Unicode23755
set Unicode_Result=峋
exit/b
:Unicode峋
set Unicode_Result=23755
exit/b
:Unicode23781
set Unicode_Result=峥
exit/b
:Unicode峥
set Unicode_Result=23781
exit/b
:Unicode23810
set Unicode_Result=崂
exit/b
:Unicode崂
set Unicode_Result=23810
exit/b
:Unicode23811
set Unicode_Result=崃
exit/b
:Unicode崃
set Unicode_Result=23811
exit/b
:Unicode23847
set Unicode_Result=崧
exit/b
:Unicode崧
set Unicode_Result=23847
exit/b
:Unicode23846
set Unicode_Result=崦
exit/b
:Unicode崦
set Unicode_Result=23846
exit/b
:Unicode23854
set Unicode_Result=崮
exit/b
:Unicode崮
set Unicode_Result=23854
exit/b
:Unicode23844
set Unicode_Result=崤
exit/b
:Unicode崤
set Unicode_Result=23844
exit/b
:Unicode23838
set Unicode_Result=崞
exit/b
:Unicode崞
set Unicode_Result=23838
exit/b
:Unicode23814
set Unicode_Result=崆
exit/b
:Unicode崆
set Unicode_Result=23814
exit/b
:Unicode23835
set Unicode_Result=崛
exit/b
:Unicode崛
set Unicode_Result=23835
exit/b
:Unicode23896
set Unicode_Result=嵘
exit/b
:Unicode嵘
set Unicode_Result=23896
exit/b
:Unicode23870
set Unicode_Result=崾
exit/b
:Unicode崾
set Unicode_Result=23870
exit/b
:Unicode23860
set Unicode_Result=崴
exit/b
:Unicode崴
set Unicode_Result=23860
exit/b
:Unicode23869
set Unicode_Result=崽
exit/b
:Unicode崽
set Unicode_Result=23869
exit/b
:Unicode23916
set Unicode_Result=嵬
exit/b
:Unicode嵬
set Unicode_Result=23916
exit/b
:Unicode23899
set Unicode_Result=嵛
exit/b
:Unicode嵛
set Unicode_Result=23899
exit/b
:Unicode23919
set Unicode_Result=嵯
exit/b
:Unicode嵯
set Unicode_Result=23919
exit/b
:Unicode23901
set Unicode_Result=嵝
exit/b
:Unicode嵝
set Unicode_Result=23901
exit/b
:Unicode23915
set Unicode_Result=嵫
exit/b
:Unicode嵫
set Unicode_Result=23915
exit/b
:Unicode23883
set Unicode_Result=嵋
exit/b
:Unicode嵋
set Unicode_Result=23883
exit/b
:Unicode23882
set Unicode_Result=嵊
exit/b
:Unicode嵊
set Unicode_Result=23882
exit/b
:Unicode23913
set Unicode_Result=嵩
exit/b
:Unicode嵩
set Unicode_Result=23913
exit/b
:Unicode23924
set Unicode_Result=嵴
exit/b
:Unicode嵴
set Unicode_Result=23924
exit/b
:Unicode23938
set Unicode_Result=嶂
exit/b
:Unicode嶂
set Unicode_Result=23938
exit/b
:Unicode23961
set Unicode_Result=嶙
exit/b
:Unicode嶙
set Unicode_Result=23961
exit/b
:Unicode23965
set Unicode_Result=嶝
exit/b
:Unicode嶝
set Unicode_Result=23965
exit/b
:Unicode35955
set Unicode_Result=豳
exit/b
:Unicode豳
set Unicode_Result=35955
exit/b
:Unicode23991
set Unicode_Result=嶷
exit/b
:Unicode嶷
set Unicode_Result=23991
exit/b
:Unicode24005
set Unicode_Result=巅
exit/b
:Unicode巅
set Unicode_Result=24005
exit/b
:Unicode24435
set Unicode_Result=彳
exit/b
:Unicode彳
set Unicode_Result=24435
exit/b
:Unicode24439
set Unicode_Result=彷
exit/b
:Unicode彷
set Unicode_Result=24439
exit/b
:Unicode24450
set Unicode_Result=徂
exit/b
:Unicode徂
set Unicode_Result=24450
exit/b
:Unicode24455
set Unicode_Result=徇
exit/b
:Unicode徇
set Unicode_Result=24455
exit/b
:Unicode24457
set Unicode_Result=徉
exit/b
:Unicode徉
set Unicode_Result=24457
exit/b
:Unicode24460
set Unicode_Result=後
exit/b
:Unicode後
set Unicode_Result=24460
exit/b
:Unicode24469
set Unicode_Result=徕
exit/b
:Unicode徕
set Unicode_Result=24469
exit/b
:Unicode24473
set Unicode_Result=徙
exit/b
:Unicode徙
set Unicode_Result=24473
exit/b
:Unicode24476
set Unicode_Result=徜
exit/b
:Unicode徜
set Unicode_Result=24476
exit/b
:Unicode24488
set Unicode_Result=徨
exit/b
:Unicode徨
set Unicode_Result=24488
exit/b
:Unicode29423
set Unicode_Result=狯
exit/b
:Unicode狯
set Unicode_Result=29423
exit/b
:Unicode29417
set Unicode_Result=狩
exit/b
:Unicode狩
set Unicode_Result=29417
exit/b
:Unicode29426
set Unicode_Result=狲
exit/b
:Unicode狲
set Unicode_Result=29426
exit/b
:Unicode29428
set Unicode_Result=狴
exit/b
:Unicode狴
set Unicode_Result=29428
exit/b
:Unicode29431
set Unicode_Result=狷
exit/b
:Unicode狷
set Unicode_Result=29431
exit/b
:Unicode29441
set Unicode_Result=猁
exit/b
:Unicode猁
set Unicode_Result=29441
exit/b
:Unicode29427
set Unicode_Result=狳
exit/b
:Unicode狳
set Unicode_Result=29427
exit/b
:Unicode29443
set Unicode_Result=猃
exit/b
:Unicode猃
set Unicode_Result=29443
exit/b
:Unicode29434
set Unicode_Result=狺
exit/b
:Unicode狺
set Unicode_Result=29434
exit/b
:Unicode29435
set Unicode_Result=狻
exit/b
:Unicode狻
set Unicode_Result=29435
exit/b
:Unicode29463
set Unicode_Result=猗
exit/b
:Unicode猗
set Unicode_Result=29463
exit/b
:Unicode29459
set Unicode_Result=猓
exit/b
:Unicode猓
set Unicode_Result=29459
exit/b
:Unicode29473
set Unicode_Result=猡
exit/b
:Unicode猡
set Unicode_Result=29473
exit/b
:Unicode29450
set Unicode_Result=猊
exit/b
:Unicode猊
set Unicode_Result=29450
exit/b
:Unicode29470
set Unicode_Result=猞
exit/b
:Unicode猞
set Unicode_Result=29470
exit/b
:Unicode29469
set Unicode_Result=猝
exit/b
:Unicode猝
set Unicode_Result=29469
exit/b
:Unicode29461
set Unicode_Result=猕
exit/b
:Unicode猕
set Unicode_Result=29461
exit/b
:Unicode29474
set Unicode_Result=猢
exit/b
:Unicode猢
set Unicode_Result=29474
exit/b
:Unicode29497
set Unicode_Result=猹
exit/b
:Unicode猹
set Unicode_Result=29497
exit/b
:Unicode29477
set Unicode_Result=猥
exit/b
:Unicode猥
set Unicode_Result=29477
exit/b
:Unicode29484
set Unicode_Result=猬
exit/b
:Unicode猬
set Unicode_Result=29484
exit/b
:Unicode29496
set Unicode_Result=猸
exit/b
:Unicode猸
set Unicode_Result=29496
exit/b
:Unicode29489
set Unicode_Result=猱
exit/b
:Unicode猱
set Unicode_Result=29489
exit/b
:Unicode29520
set Unicode_Result=獐
exit/b
:Unicode獐
set Unicode_Result=29520
exit/b
:Unicode29517
set Unicode_Result=獍
exit/b
:Unicode獍
set Unicode_Result=29517
exit/b
:Unicode29527
set Unicode_Result=獗
exit/b
:Unicode獗
set Unicode_Result=29527
exit/b
:Unicode29536
set Unicode_Result=獠
exit/b
:Unicode獠
set Unicode_Result=29536
exit/b
:Unicode29548
set Unicode_Result=獬
exit/b
:Unicode獬
set Unicode_Result=29548
exit/b
:Unicode29551
set Unicode_Result=獯
exit/b
:Unicode獯
set Unicode_Result=29551
exit/b
:Unicode29566
set Unicode_Result=獾
exit/b
:Unicode獾
set Unicode_Result=29566
exit/b
:Unicode33307
set Unicode_Result=舛
exit/b
:Unicode舛
set Unicode_Result=33307
exit/b
:Unicode22821
set Unicode_Result=夥
exit/b
:Unicode夥
set Unicode_Result=22821
exit/b
:Unicode39143
set Unicode_Result=飧
exit/b
:Unicode飧
set Unicode_Result=39143
exit/b
:Unicode22820
set Unicode_Result=夤
exit/b
:Unicode夤
set Unicode_Result=22820
exit/b
:Unicode22786
set Unicode_Result=夂
exit/b
:Unicode夂
set Unicode_Result=22786
exit/b
:Unicode39267
set Unicode_Result=饣
exit/b
:Unicode饣
set Unicode_Result=39267
exit/b
:Unicode39271
set Unicode_Result=饧
exit/b
:Unicode饧
set Unicode_Result=39271
exit/b
:Unicode39272
set Unicode_Result=饨
exit/b
:Unicode饨
set Unicode_Result=39272
exit/b
:Unicode39273
set Unicode_Result=饩
exit/b
:Unicode饩
set Unicode_Result=39273
exit/b
:Unicode39274
set Unicode_Result=饪
exit/b
:Unicode饪
set Unicode_Result=39274
exit/b
:Unicode39275
set Unicode_Result=饫
exit/b
:Unicode饫
set Unicode_Result=39275
exit/b
:Unicode39276
set Unicode_Result=饬
exit/b
:Unicode饬
set Unicode_Result=39276
exit/b
:Unicode39284
set Unicode_Result=饴
exit/b
:Unicode饴
set Unicode_Result=39284
exit/b
:Unicode39287
set Unicode_Result=饷
exit/b
:Unicode饷
set Unicode_Result=39287
exit/b
:Unicode39293
set Unicode_Result=饽
exit/b
:Unicode饽
set Unicode_Result=39293
exit/b
:Unicode39296
set Unicode_Result=馀
exit/b
:Unicode馀
set Unicode_Result=39296
exit/b
:Unicode39300
set Unicode_Result=馄
exit/b
:Unicode馄
set Unicode_Result=39300
exit/b
:Unicode39303
set Unicode_Result=馇
exit/b
:Unicode馇
set Unicode_Result=39303
exit/b
:Unicode39306
set Unicode_Result=馊
exit/b
:Unicode馊
set Unicode_Result=39306
exit/b
:Unicode39309
set Unicode_Result=馍
exit/b
:Unicode馍
set Unicode_Result=39309
exit/b
:Unicode39312
set Unicode_Result=馐
exit/b
:Unicode馐
set Unicode_Result=39312
exit/b
:Unicode39313
set Unicode_Result=馑
exit/b
:Unicode馑
set Unicode_Result=39313
exit/b
:Unicode39315
set Unicode_Result=馓
exit/b
:Unicode馓
set Unicode_Result=39315
exit/b
:Unicode39316
set Unicode_Result=馔
exit/b
:Unicode馔
set Unicode_Result=39316
exit/b
:Unicode39317
set Unicode_Result=馕
exit/b
:Unicode馕
set Unicode_Result=39317
exit/b
:Unicode24192
set Unicode_Result=庀
exit/b
:Unicode庀
set Unicode_Result=24192
exit/b
:Unicode24209
set Unicode_Result=庑
exit/b
:Unicode庑
set Unicode_Result=24209
exit/b
:Unicode24203
set Unicode_Result=庋
exit/b
:Unicode庋
set Unicode_Result=24203
exit/b
:Unicode24214
set Unicode_Result=庖
exit/b
:Unicode庖
set Unicode_Result=24214
exit/b
:Unicode24229
set Unicode_Result=庥
exit/b
:Unicode庥
set Unicode_Result=24229
exit/b
:Unicode24224
set Unicode_Result=庠
exit/b
:Unicode庠
set Unicode_Result=24224
exit/b
:Unicode24249
set Unicode_Result=庹
exit/b
:Unicode庹
set Unicode_Result=24249
exit/b
:Unicode24245
set Unicode_Result=庵
exit/b
:Unicode庵
set Unicode_Result=24245
exit/b
:Unicode24254
set Unicode_Result=庾
exit/b
:Unicode庾
set Unicode_Result=24254
exit/b
:Unicode24243
set Unicode_Result=庳
exit/b
:Unicode庳
set Unicode_Result=24243
exit/b
:Unicode36179
set Unicode_Result=赓
exit/b
:Unicode赓
set Unicode_Result=36179
exit/b
:Unicode24274
set Unicode_Result=廒
exit/b
:Unicode廒
set Unicode_Result=24274
exit/b
:Unicode24273
set Unicode_Result=廑
exit/b
:Unicode廑
set Unicode_Result=24273
exit/b
:Unicode24283
set Unicode_Result=廛
exit/b
:Unicode廛
set Unicode_Result=24283
exit/b
:Unicode24296
set Unicode_Result=廨
exit/b
:Unicode廨
set Unicode_Result=24296
exit/b
:Unicode24298
set Unicode_Result=廪
exit/b
:Unicode廪
set Unicode_Result=24298
exit/b
:Unicode33210
set Unicode_Result=膺
exit/b
:Unicode膺
set Unicode_Result=33210
exit/b
:Unicode24516
set Unicode_Result=忄
exit/b
:Unicode忄
set Unicode_Result=24516
exit/b
:Unicode24521
set Unicode_Result=忉
exit/b
:Unicode忉
set Unicode_Result=24521
exit/b
:Unicode24534
set Unicode_Result=忖
exit/b
:Unicode忖
set Unicode_Result=24534
exit/b
:Unicode24527
set Unicode_Result=忏
exit/b
:Unicode忏
set Unicode_Result=24527
exit/b
:Unicode24579
set Unicode_Result=怃
exit/b
:Unicode怃
set Unicode_Result=24579
exit/b
:Unicode24558
set Unicode_Result=忮
exit/b
:Unicode忮
set Unicode_Result=24558
exit/b
:Unicode24580
set Unicode_Result=怄
exit/b
:Unicode怄
set Unicode_Result=24580
exit/b
:Unicode24545
set Unicode_Result=忡
exit/b
:Unicode忡
set Unicode_Result=24545
exit/b
:Unicode24548
set Unicode_Result=忤
exit/b
:Unicode忤
set Unicode_Result=24548
exit/b
:Unicode24574
set Unicode_Result=忾
exit/b
:Unicode忾
set Unicode_Result=24574
exit/b
:Unicode24581
set Unicode_Result=怅
exit/b
:Unicode怅
set Unicode_Result=24581
exit/b
:Unicode24582
set Unicode_Result=怆
exit/b
:Unicode怆
set Unicode_Result=24582
exit/b
:Unicode24554
set Unicode_Result=忪
exit/b
:Unicode忪
set Unicode_Result=24554
exit/b
:Unicode24557
set Unicode_Result=忭
exit/b
:Unicode忭
set Unicode_Result=24557
exit/b
:Unicode24568
set Unicode_Result=忸
exit/b
:Unicode忸
set Unicode_Result=24568
exit/b
:Unicode24601
set Unicode_Result=怙
exit/b
:Unicode怙
set Unicode_Result=24601
exit/b
:Unicode24629
set Unicode_Result=怵
exit/b
:Unicode怵
set Unicode_Result=24629
exit/b
:Unicode24614
set Unicode_Result=怦
exit/b
:Unicode怦
set Unicode_Result=24614
exit/b
:Unicode24603
set Unicode_Result=怛
exit/b
:Unicode怛
set Unicode_Result=24603
exit/b
:Unicode24591
set Unicode_Result=怏
exit/b
:Unicode怏
set Unicode_Result=24591
exit/b
:Unicode24589
set Unicode_Result=怍
exit/b
:Unicode怍
set Unicode_Result=24589
exit/b
:Unicode24617
set Unicode_Result=怩
exit/b
:Unicode怩
set Unicode_Result=24617
exit/b
:Unicode24619
set Unicode_Result=怫
exit/b
:Unicode怫
set Unicode_Result=24619
exit/b
:Unicode24586
set Unicode_Result=怊
exit/b
:Unicode怊
set Unicode_Result=24586
exit/b
:Unicode24639
set Unicode_Result=怿
exit/b
:Unicode怿
set Unicode_Result=24639
exit/b
:Unicode24609
set Unicode_Result=怡
exit/b
:Unicode怡
set Unicode_Result=24609
exit/b
:Unicode24696
set Unicode_Result=恸
exit/b
:Unicode恸
set Unicode_Result=24696
exit/b
:Unicode24697
set Unicode_Result=恹
exit/b
:Unicode恹
set Unicode_Result=24697
exit/b
:Unicode24699
set Unicode_Result=恻
exit/b
:Unicode恻
set Unicode_Result=24699
exit/b
:Unicode24698
set Unicode_Result=恺
exit/b
:Unicode恺
set Unicode_Result=24698
exit/b
:Unicode24642
set Unicode_Result=恂
exit/b
:Unicode恂
set Unicode_Result=24642
exit/b
:Unicode24682
set Unicode_Result=恪
exit/b
:Unicode恪
set Unicode_Result=24682
exit/b
:Unicode24701
set Unicode_Result=恽
exit/b
:Unicode恽
set Unicode_Result=24701
exit/b
:Unicode24726
set Unicode_Result=悖
exit/b
:Unicode悖
set Unicode_Result=24726
exit/b
:Unicode24730
set Unicode_Result=悚
exit/b
:Unicode悚
set Unicode_Result=24730
exit/b
:Unicode24749
set Unicode_Result=悭
exit/b
:Unicode悭
set Unicode_Result=24749
exit/b
:Unicode24733
set Unicode_Result=悝
exit/b
:Unicode悝
set Unicode_Result=24733
exit/b
:Unicode24707
set Unicode_Result=悃
exit/b
:Unicode悃
set Unicode_Result=24707
exit/b
:Unicode24722
set Unicode_Result=悒
exit/b
:Unicode悒
set Unicode_Result=24722
exit/b
:Unicode24716
set Unicode_Result=悌
exit/b
:Unicode悌
set Unicode_Result=24716
exit/b
:Unicode24731
set Unicode_Result=悛
exit/b
:Unicode悛
set Unicode_Result=24731
exit/b
:Unicode24812
set Unicode_Result=惬
exit/b
:Unicode惬
set Unicode_Result=24812
exit/b
:Unicode24763
set Unicode_Result=悻
exit/b
:Unicode悻
set Unicode_Result=24763
exit/b
:Unicode24753
set Unicode_Result=悱
exit/b
:Unicode悱
set Unicode_Result=24753
exit/b
:Unicode24797
set Unicode_Result=惝
exit/b
:Unicode惝
set Unicode_Result=24797
exit/b
:Unicode24792
set Unicode_Result=惘
exit/b
:Unicode惘
set Unicode_Result=24792
exit/b
:Unicode24774
set Unicode_Result=惆
exit/b
:Unicode惆
set Unicode_Result=24774
exit/b
:Unicode24794
set Unicode_Result=惚
exit/b
:Unicode惚
set Unicode_Result=24794
exit/b
:Unicode24756
set Unicode_Result=悴
exit/b
:Unicode悴
set Unicode_Result=24756
exit/b
:Unicode24864
set Unicode_Result=愠
exit/b
:Unicode愠
set Unicode_Result=24864
exit/b
:Unicode24870
set Unicode_Result=愦
exit/b
:Unicode愦
set Unicode_Result=24870
exit/b
:Unicode24853
set Unicode_Result=愕
exit/b
:Unicode愕
set Unicode_Result=24853
exit/b
:Unicode24867
set Unicode_Result=愣
exit/b
:Unicode愣
set Unicode_Result=24867
exit/b
:Unicode24820
set Unicode_Result=惴
exit/b
:Unicode惴
set Unicode_Result=24820
exit/b
:Unicode24832
set Unicode_Result=愀
exit/b
:Unicode愀
set Unicode_Result=24832
exit/b
:Unicode24846
set Unicode_Result=愎
exit/b
:Unicode愎
set Unicode_Result=24846
exit/b
:Unicode24875
set Unicode_Result=愫
exit/b
:Unicode愫
set Unicode_Result=24875
exit/b
:Unicode24906
set Unicode_Result=慊
exit/b
:Unicode慊
set Unicode_Result=24906
exit/b
:Unicode24949
set Unicode_Result=慵
exit/b
:Unicode慵
set Unicode_Result=24949
exit/b
:Unicode25004
set Unicode_Result=憬
exit/b
:Unicode憬
set Unicode_Result=25004
exit/b
:Unicode24980
set Unicode_Result=憔
exit/b
:Unicode憔
set Unicode_Result=24980
exit/b
:Unicode24999
set Unicode_Result=憧
exit/b
:Unicode憧
set Unicode_Result=24999
exit/b
:Unicode25015
set Unicode_Result=憷
exit/b
:Unicode憷
set Unicode_Result=25015
exit/b
:Unicode25044
set Unicode_Result=懔
exit/b
:Unicode懔
set Unicode_Result=25044
exit/b
:Unicode25077
set Unicode_Result=懵
exit/b
:Unicode懵
set Unicode_Result=25077
exit/b
:Unicode24541
set Unicode_Result=忝
exit/b
:Unicode忝
set Unicode_Result=24541
exit/b
:Unicode38579
set Unicode_Result=隳
exit/b
:Unicode隳
set Unicode_Result=38579
exit/b
:Unicode38377
set Unicode_Result=闩
exit/b
:Unicode闩
set Unicode_Result=38377
exit/b
:Unicode38379
set Unicode_Result=闫
exit/b
:Unicode闫
set Unicode_Result=38379
exit/b
:Unicode38385
set Unicode_Result=闱
exit/b
:Unicode闱
set Unicode_Result=38385
exit/b
:Unicode38387
set Unicode_Result=闳
exit/b
:Unicode闳
set Unicode_Result=38387
exit/b
:Unicode38389
set Unicode_Result=闵
exit/b
:Unicode闵
set Unicode_Result=38389
exit/b
:Unicode38390
set Unicode_Result=闶
exit/b
:Unicode闶
set Unicode_Result=38390
exit/b
:Unicode38396
set Unicode_Result=闼
exit/b
:Unicode闼
set Unicode_Result=38396
exit/b
:Unicode38398
set Unicode_Result=闾
exit/b
:Unicode闾
set Unicode_Result=38398
exit/b
:Unicode38403
set Unicode_Result=阃
exit/b
:Unicode阃
set Unicode_Result=38403
exit/b
:Unicode38404
set Unicode_Result=阄
exit/b
:Unicode阄
set Unicode_Result=38404
exit/b
:Unicode38406
set Unicode_Result=阆
exit/b
:Unicode阆
set Unicode_Result=38406
exit/b
:Unicode38408
set Unicode_Result=阈
exit/b
:Unicode阈
set Unicode_Result=38408
exit/b
:Unicode38410
set Unicode_Result=阊
exit/b
:Unicode阊
set Unicode_Result=38410
exit/b
:Unicode38411
set Unicode_Result=阋
exit/b
:Unicode阋
set Unicode_Result=38411
exit/b
:Unicode38412
set Unicode_Result=阌
exit/b
:Unicode阌
set Unicode_Result=38412
exit/b
:Unicode38413
set Unicode_Result=阍
exit/b
:Unicode阍
set Unicode_Result=38413
exit/b
:Unicode38415
set Unicode_Result=阏
exit/b
:Unicode阏
set Unicode_Result=38415
exit/b
:Unicode38418
set Unicode_Result=阒
exit/b
:Unicode阒
set Unicode_Result=38418
exit/b
:Unicode38421
set Unicode_Result=阕
exit/b
:Unicode阕
set Unicode_Result=38421
exit/b
:Unicode38422
set Unicode_Result=阖
exit/b
:Unicode阖
set Unicode_Result=38422
exit/b
:Unicode38423
set Unicode_Result=阗
exit/b
:Unicode阗
set Unicode_Result=38423
exit/b
:Unicode38425
set Unicode_Result=阙
exit/b
:Unicode阙
set Unicode_Result=38425
exit/b
:Unicode38426
set Unicode_Result=阚
exit/b
:Unicode阚
set Unicode_Result=38426
exit/b
:Unicode20012
set Unicode_Result=丬
exit/b
:Unicode丬
set Unicode_Result=20012
exit/b
:Unicode29247
set Unicode_Result=爿
exit/b
:Unicode爿
set Unicode_Result=29247
exit/b
:Unicode25109
set Unicode_Result=戕
exit/b
:Unicode戕
set Unicode_Result=25109
exit/b
:Unicode27701
set Unicode_Result=氵
exit/b
:Unicode氵
set Unicode_Result=27701
exit/b
:Unicode27732
set Unicode_Result=汔
exit/b
:Unicode汔
set Unicode_Result=27732
exit/b
:Unicode27740
set Unicode_Result=汜
exit/b
:Unicode汜
set Unicode_Result=27740
exit/b
:Unicode27722
set Unicode_Result=汊
exit/b
:Unicode汊
set Unicode_Result=27722
exit/b
:Unicode27811
set Unicode_Result=沣
exit/b
:Unicode沣
set Unicode_Result=27811
exit/b
:Unicode27781
set Unicode_Result=沅
exit/b
:Unicode沅
set Unicode_Result=27781
exit/b
:Unicode27792
set Unicode_Result=沐
exit/b
:Unicode沐
set Unicode_Result=27792
exit/b
:Unicode27796
set Unicode_Result=沔
exit/b
:Unicode沔
set Unicode_Result=27796
exit/b
:Unicode27788
set Unicode_Result=沌
exit/b
:Unicode沌
set Unicode_Result=27788
exit/b
:Unicode27752
set Unicode_Result=汨
exit/b
:Unicode汨
set Unicode_Result=27752
exit/b
:Unicode27753
set Unicode_Result=汩
exit/b
:Unicode汩
set Unicode_Result=27753
exit/b
:Unicode27764
set Unicode_Result=汴
exit/b
:Unicode汴
set Unicode_Result=27764
exit/b
:Unicode27766
set Unicode_Result=汶
exit/b
:Unicode汶
set Unicode_Result=27766
exit/b
:Unicode27782
set Unicode_Result=沆
exit/b
:Unicode沆
set Unicode_Result=27782
exit/b
:Unicode27817
set Unicode_Result=沩
exit/b
:Unicode沩
set Unicode_Result=27817
exit/b
:Unicode27856
set Unicode_Result=泐
exit/b
:Unicode泐
set Unicode_Result=27856
exit/b
:Unicode27860
set Unicode_Result=泔
exit/b
:Unicode泔
set Unicode_Result=27860
exit/b
:Unicode27821
set Unicode_Result=沭
exit/b
:Unicode沭
set Unicode_Result=27821
exit/b
:Unicode27895
set Unicode_Result=泷
exit/b
:Unicode泷
set Unicode_Result=27895
exit/b
:Unicode27896
set Unicode_Result=泸
exit/b
:Unicode泸
set Unicode_Result=27896
exit/b
:Unicode27889
set Unicode_Result=泱
exit/b
:Unicode泱
set Unicode_Result=27889
exit/b
:Unicode27863
set Unicode_Result=泗
exit/b
:Unicode泗
set Unicode_Result=27863
exit/b
:Unicode27826
set Unicode_Result=沲
exit/b
:Unicode沲
set Unicode_Result=27826
exit/b
:Unicode27872
set Unicode_Result=泠
exit/b
:Unicode泠
set Unicode_Result=27872
exit/b
:Unicode27862
set Unicode_Result=泖
exit/b
:Unicode泖
set Unicode_Result=27862
exit/b
:Unicode27898
set Unicode_Result=泺
exit/b
:Unicode泺
set Unicode_Result=27898
exit/b
:Unicode27883
set Unicode_Result=泫
exit/b
:Unicode泫
set Unicode_Result=27883
exit/b
:Unicode27886
set Unicode_Result=泮
exit/b
:Unicode泮
set Unicode_Result=27886
exit/b
:Unicode27825
set Unicode_Result=沱
exit/b
:Unicode沱
set Unicode_Result=27825
exit/b
:Unicode27859
set Unicode_Result=泓
exit/b
:Unicode泓
set Unicode_Result=27859
exit/b
:Unicode27887
set Unicode_Result=泯
exit/b
:Unicode泯
set Unicode_Result=27887
exit/b
:Unicode27902
set Unicode_Result=泾
exit/b
:Unicode泾
set Unicode_Result=27902
exit/b
:Unicode27961
set Unicode_Result=洹
exit/b
:Unicode洹
set Unicode_Result=27961
exit/b
:Unicode27943
set Unicode_Result=洧
exit/b
:Unicode洧
set Unicode_Result=27943
exit/b
:Unicode27916
set Unicode_Result=洌
exit/b
:Unicode洌
set Unicode_Result=27916
exit/b
:Unicode27971
set Unicode_Result=浃
exit/b
:Unicode浃
set Unicode_Result=27971
exit/b
:Unicode27976
set Unicode_Result=浈
exit/b
:Unicode浈
set Unicode_Result=27976
exit/b
:Unicode27911
set Unicode_Result=洇
exit/b
:Unicode洇
set Unicode_Result=27911
exit/b
:Unicode27908
set Unicode_Result=洄
exit/b
:Unicode洄
set Unicode_Result=27908
exit/b
:Unicode27929
set Unicode_Result=洙
exit/b
:Unicode洙
set Unicode_Result=27929
exit/b
:Unicode27918
set Unicode_Result=洎
exit/b
:Unicode洎
set Unicode_Result=27918
exit/b
:Unicode27947
set Unicode_Result=洫
exit/b
:Unicode洫
set Unicode_Result=27947
exit/b
:Unicode27981
set Unicode_Result=浍
exit/b
:Unicode浍
set Unicode_Result=27981
exit/b
:Unicode27950
set Unicode_Result=洮
exit/b
:Unicode洮
set Unicode_Result=27950
exit/b
:Unicode27957
set Unicode_Result=洵
exit/b
:Unicode洵
set Unicode_Result=27957
exit/b
:Unicode27930
set Unicode_Result=洚
exit/b
:Unicode洚
set Unicode_Result=27930
exit/b
:Unicode27983
set Unicode_Result=浏
exit/b
:Unicode浏
set Unicode_Result=27983
exit/b
:Unicode27986
set Unicode_Result=浒
exit/b
:Unicode浒
set Unicode_Result=27986
exit/b
:Unicode27988
set Unicode_Result=浔
exit/b
:Unicode浔
set Unicode_Result=27988
exit/b
:Unicode27955
set Unicode_Result=洳
exit/b
:Unicode洳
set Unicode_Result=27955
exit/b
:Unicode28049
set Unicode_Result=涑
exit/b
:Unicode涑
set Unicode_Result=28049
exit/b
:Unicode28015
set Unicode_Result=浯
exit/b
:Unicode浯
set Unicode_Result=28015
exit/b
:Unicode28062
set Unicode_Result=涞
exit/b
:Unicode涞
set Unicode_Result=28062
exit/b
:Unicode28064
set Unicode_Result=涠
exit/b
:Unicode涠
set Unicode_Result=28064
exit/b
:Unicode27998
set Unicode_Result=浞
exit/b
:Unicode浞
set Unicode_Result=27998
exit/b
:Unicode28051
set Unicode_Result=涓
exit/b
:Unicode涓
set Unicode_Result=28051
exit/b
:Unicode28052
set Unicode_Result=涔
exit/b
:Unicode涔
set Unicode_Result=28052
exit/b
:Unicode27996
set Unicode_Result=浜
exit/b
:Unicode浜
set Unicode_Result=27996
exit/b
:Unicode28000
set Unicode_Result=浠
exit/b
:Unicode浠
set Unicode_Result=28000
exit/b
:Unicode28028
set Unicode_Result=浼
exit/b
:Unicode浼
set Unicode_Result=28028
exit/b
:Unicode28003
set Unicode_Result=浣
exit/b
:Unicode浣
set Unicode_Result=28003
exit/b
:Unicode28186
set Unicode_Result=渚
exit/b
:Unicode渚
set Unicode_Result=28186
exit/b
:Unicode28103
set Unicode_Result=淇
exit/b
:Unicode淇
set Unicode_Result=28103
exit/b
:Unicode28101
set Unicode_Result=淅
exit/b
:Unicode淅
set Unicode_Result=28101
exit/b
:Unicode28126
set Unicode_Result=淞
exit/b
:Unicode淞
set Unicode_Result=28126
exit/b
:Unicode28174
set Unicode_Result=渎
exit/b
:Unicode渎
set Unicode_Result=28174
exit/b
:Unicode28095
set Unicode_Result=涿
exit/b
:Unicode涿
set Unicode_Result=28095
exit/b
:Unicode28128
set Unicode_Result=淠
exit/b
:Unicode淠
set Unicode_Result=28128
exit/b
:Unicode28177
set Unicode_Result=渑
exit/b
:Unicode渑
set Unicode_Result=28177
exit/b
:Unicode28134
set Unicode_Result=淦
exit/b
:Unicode淦
set Unicode_Result=28134
exit/b
:Unicode28125
set Unicode_Result=淝
exit/b
:Unicode淝
set Unicode_Result=28125
exit/b
:Unicode28121
set Unicode_Result=淙
exit/b
:Unicode淙
set Unicode_Result=28121
exit/b
:Unicode28182
set Unicode_Result=渖
exit/b
:Unicode渖
set Unicode_Result=28182
exit/b
:Unicode28075
set Unicode_Result=涫
exit/b
:Unicode涫
set Unicode_Result=28075
exit/b
:Unicode28172
set Unicode_Result=渌
exit/b
:Unicode渌
set Unicode_Result=28172
exit/b
:Unicode28078
set Unicode_Result=涮
exit/b
:Unicode涮
set Unicode_Result=28078
exit/b
:Unicode28203
set Unicode_Result=渫
exit/b
:Unicode渫
set Unicode_Result=28203
exit/b
:Unicode28270
set Unicode_Result=湮
exit/b
:Unicode湮
set Unicode_Result=28270
exit/b
:Unicode28238
set Unicode_Result=湎
exit/b
:Unicode湎
set Unicode_Result=28238
exit/b
:Unicode28267
set Unicode_Result=湫
exit/b
:Unicode湫
set Unicode_Result=28267
exit/b
:Unicode28338
set Unicode_Result=溲
exit/b
:Unicode溲
set Unicode_Result=28338
exit/b
:Unicode28255
set Unicode_Result=湟
exit/b
:Unicode湟
set Unicode_Result=28255
exit/b
:Unicode28294
set Unicode_Result=溆
exit/b
:Unicode溆
set Unicode_Result=28294
exit/b
:Unicode28243
set Unicode_Result=湓
exit/b
:Unicode湓
set Unicode_Result=28243
exit/b
:Unicode28244
set Unicode_Result=湔
exit/b
:Unicode湔
set Unicode_Result=28244
exit/b
:Unicode28210
set Unicode_Result=渲
exit/b
:Unicode渲
set Unicode_Result=28210
exit/b
:Unicode28197
set Unicode_Result=渥
exit/b
:Unicode渥
set Unicode_Result=28197
exit/b
:Unicode28228
set Unicode_Result=湄
exit/b
:Unicode湄
set Unicode_Result=28228
exit/b
:Unicode28383
set Unicode_Result=滟
exit/b
:Unicode滟
set Unicode_Result=28383
exit/b
:Unicode28337
set Unicode_Result=溱
exit/b
:Unicode溱
set Unicode_Result=28337
exit/b
:Unicode28312
set Unicode_Result=溘
exit/b
:Unicode溘
set Unicode_Result=28312
exit/b
:Unicode28384
set Unicode_Result=滠
exit/b
:Unicode滠
set Unicode_Result=28384
exit/b
:Unicode28461
set Unicode_Result=漭
exit/b
:Unicode漭
set Unicode_Result=28461
exit/b
:Unicode28386
set Unicode_Result=滢
exit/b
:Unicode滢
set Unicode_Result=28386
exit/b
:Unicode28325
set Unicode_Result=溥
exit/b
:Unicode溥
set Unicode_Result=28325
exit/b
:Unicode28327
set Unicode_Result=溧
exit/b
:Unicode溧
set Unicode_Result=28327
exit/b
:Unicode28349
set Unicode_Result=溽
exit/b
:Unicode溽
set Unicode_Result=28349
exit/b
:Unicode28347
set Unicode_Result=溻
exit/b
:Unicode溻
set Unicode_Result=28347
exit/b
:Unicode28343
set Unicode_Result=溷
exit/b
:Unicode溷
set Unicode_Result=28343
exit/b
:Unicode28375
set Unicode_Result=滗
exit/b
:Unicode滗
set Unicode_Result=28375
exit/b
:Unicode28340
set Unicode_Result=溴
exit/b
:Unicode溴
set Unicode_Result=28340
exit/b
:Unicode28367
set Unicode_Result=滏
exit/b
:Unicode滏
set Unicode_Result=28367
exit/b
:Unicode28303
set Unicode_Result=溏
exit/b
:Unicode溏
set Unicode_Result=28303
exit/b
:Unicode28354
set Unicode_Result=滂
exit/b
:Unicode滂
set Unicode_Result=28354
exit/b
:Unicode28319
set Unicode_Result=溟
exit/b
:Unicode溟
set Unicode_Result=28319
exit/b
:Unicode28514
set Unicode_Result=潢
exit/b
:Unicode潢
set Unicode_Result=28514
exit/b
:Unicode28486
set Unicode_Result=潆
exit/b
:Unicode潆
set Unicode_Result=28486
exit/b
:Unicode28487
set Unicode_Result=潇
exit/b
:Unicode潇
set Unicode_Result=28487
exit/b
:Unicode28452
set Unicode_Result=漤
exit/b
:Unicode漤
set Unicode_Result=28452
exit/b
:Unicode28437
set Unicode_Result=漕
exit/b
:Unicode漕
set Unicode_Result=28437
exit/b
:Unicode28409
set Unicode_Result=滹
exit/b
:Unicode滹
set Unicode_Result=28409
exit/b
:Unicode28463
set Unicode_Result=漯
exit/b
:Unicode漯
set Unicode_Result=28463
exit/b
:Unicode28470
set Unicode_Result=漶
exit/b
:Unicode漶
set Unicode_Result=28470
exit/b
:Unicode28491
set Unicode_Result=潋
exit/b
:Unicode潋
set Unicode_Result=28491
exit/b
:Unicode28532
set Unicode_Result=潴
exit/b
:Unicode潴
set Unicode_Result=28532
exit/b
:Unicode28458
set Unicode_Result=漪
exit/b
:Unicode漪
set Unicode_Result=28458
exit/b
:Unicode28425
set Unicode_Result=漉
exit/b
:Unicode漉
set Unicode_Result=28425
exit/b
:Unicode28457
set Unicode_Result=漩
exit/b
:Unicode漩
set Unicode_Result=28457
exit/b
:Unicode28553
set Unicode_Result=澉
exit/b
:Unicode澉
set Unicode_Result=28553
exit/b
:Unicode28557
set Unicode_Result=澍
exit/b
:Unicode澍
set Unicode_Result=28557
exit/b
:Unicode28556
set Unicode_Result=澌
exit/b
:Unicode澌
set Unicode_Result=28556
exit/b
:Unicode28536
set Unicode_Result=潸
exit/b
:Unicode潸
set Unicode_Result=28536
exit/b
:Unicode28530
set Unicode_Result=潲
exit/b
:Unicode潲
set Unicode_Result=28530
exit/b
:Unicode28540
set Unicode_Result=潼
exit/b
:Unicode潼
set Unicode_Result=28540
exit/b
:Unicode28538
set Unicode_Result=潺
exit/b
:Unicode潺
set Unicode_Result=28538
exit/b
:Unicode28625
set Unicode_Result=濑
exit/b
:Unicode濑
set Unicode_Result=28625
exit/b
:Unicode28617
set Unicode_Result=濉
exit/b
:Unicode濉
set Unicode_Result=28617
exit/b
:Unicode28583
set Unicode_Result=澧
exit/b
:Unicode澧
set Unicode_Result=28583
exit/b
:Unicode28601
set Unicode_Result=澹
exit/b
:Unicode澹
set Unicode_Result=28601
exit/b
:Unicode28598
set Unicode_Result=澶
exit/b
:Unicode澶
set Unicode_Result=28598
exit/b
:Unicode28610
set Unicode_Result=濂
exit/b
:Unicode濂
set Unicode_Result=28610
exit/b
:Unicode28641
set Unicode_Result=濡
exit/b
:Unicode濡
set Unicode_Result=28641
exit/b
:Unicode28654
set Unicode_Result=濮
exit/b
:Unicode濮
set Unicode_Result=28654
exit/b
:Unicode28638
set Unicode_Result=濞
exit/b
:Unicode濞
set Unicode_Result=28638
exit/b
:Unicode28640
set Unicode_Result=濠
exit/b
:Unicode濠
set Unicode_Result=28640
exit/b
:Unicode28655
set Unicode_Result=濯
exit/b
:Unicode濯
set Unicode_Result=28655
exit/b
:Unicode28698
set Unicode_Result=瀚
exit/b
:Unicode瀚
set Unicode_Result=28698
exit/b
:Unicode28707
set Unicode_Result=瀣
exit/b
:Unicode瀣
set Unicode_Result=28707
exit/b
:Unicode28699
set Unicode_Result=瀛
exit/b
:Unicode瀛
set Unicode_Result=28699
exit/b
:Unicode28729
set Unicode_Result=瀹
exit/b
:Unicode瀹
set Unicode_Result=28729
exit/b
:Unicode28725
set Unicode_Result=瀵
exit/b
:Unicode瀵
set Unicode_Result=28725
exit/b
:Unicode28751
set Unicode_Result=灏
exit/b
:Unicode灏
set Unicode_Result=28751
exit/b
:Unicode28766
set Unicode_Result=灞
exit/b
:Unicode灞
set Unicode_Result=28766
exit/b
:Unicode23424
set Unicode_Result=宀
exit/b
:Unicode宀
set Unicode_Result=23424
exit/b
:Unicode23428
set Unicode_Result=宄
exit/b
:Unicode宄
set Unicode_Result=23428
exit/b
:Unicode23445
set Unicode_Result=宕
exit/b
:Unicode宕
set Unicode_Result=23445
exit/b
:Unicode23443
set Unicode_Result=宓
exit/b
:Unicode宓
set Unicode_Result=23443
exit/b
:Unicode23461
set Unicode_Result=宥
exit/b
:Unicode宥
set Unicode_Result=23461
exit/b
:Unicode23480
set Unicode_Result=宸
exit/b
:Unicode宸
set Unicode_Result=23480
exit/b
:Unicode29999
set Unicode_Result=甯
exit/b
:Unicode甯
set Unicode_Result=29999
exit/b
:Unicode39582
set Unicode_Result=骞
exit/b
:Unicode骞
set Unicode_Result=39582
exit/b
:Unicode25652
set Unicode_Result=搴
exit/b
:Unicode搴
set Unicode_Result=25652
exit/b
:Unicode23524
set Unicode_Result=寤
exit/b
:Unicode寤
set Unicode_Result=23524
exit/b
:Unicode23534
set Unicode_Result=寮
exit/b
:Unicode寮
set Unicode_Result=23534
exit/b
:Unicode35120
set Unicode_Result=褰
exit/b
:Unicode褰
set Unicode_Result=35120
exit/b
:Unicode23536
set Unicode_Result=寰
exit/b
:Unicode寰
set Unicode_Result=23536
exit/b
:Unicode36423
set Unicode_Result=蹇
exit/b
:Unicode蹇
set Unicode_Result=36423
exit/b
:Unicode35591
set Unicode_Result=謇
exit/b
:Unicode謇
set Unicode_Result=35591
exit/b
:Unicode36790
set Unicode_Result=辶
exit/b
:Unicode辶
set Unicode_Result=36790
exit/b
:Unicode36819
set Unicode_Result=迓
exit/b
:Unicode迓
set Unicode_Result=36819
exit/b
:Unicode36821
set Unicode_Result=迕
exit/b
:Unicode迕
set Unicode_Result=36821
exit/b
:Unicode36837
set Unicode_Result=迥
exit/b
:Unicode迥
set Unicode_Result=36837
exit/b
:Unicode36846
set Unicode_Result=迮
exit/b
:Unicode迮
set Unicode_Result=36846
exit/b
:Unicode36836
set Unicode_Result=迤
exit/b
:Unicode迤
set Unicode_Result=36836
exit/b
:Unicode36841
set Unicode_Result=迩
exit/b
:Unicode迩
set Unicode_Result=36841
exit/b
:Unicode36838
set Unicode_Result=迦
exit/b
:Unicode迦
set Unicode_Result=36838
exit/b
:Unicode36851
set Unicode_Result=迳
exit/b
:Unicode迳
set Unicode_Result=36851
exit/b
:Unicode36840
set Unicode_Result=迨
exit/b
:Unicode迨
set Unicode_Result=36840
exit/b
:Unicode36869
set Unicode_Result=逅
exit/b
:Unicode逅
set Unicode_Result=36869
exit/b
:Unicode36868
set Unicode_Result=逄
exit/b
:Unicode逄
set Unicode_Result=36868
exit/b
:Unicode36875
set Unicode_Result=逋
exit/b
:Unicode逋
set Unicode_Result=36875
exit/b
:Unicode36902
set Unicode_Result=逦
exit/b
:Unicode逦
set Unicode_Result=36902
exit/b
:Unicode36881
set Unicode_Result=逑
exit/b
:Unicode逑
set Unicode_Result=36881
exit/b
:Unicode36877
set Unicode_Result=逍
exit/b
:Unicode逍
set Unicode_Result=36877
exit/b
:Unicode36886
set Unicode_Result=逖
exit/b
:Unicode逖
set Unicode_Result=36886
exit/b
:Unicode36897
set Unicode_Result=逡
exit/b
:Unicode逡
set Unicode_Result=36897
exit/b
:Unicode36917
set Unicode_Result=逵
exit/b
:Unicode逵
set Unicode_Result=36917
exit/b
:Unicode36918
set Unicode_Result=逶
exit/b
:Unicode逶
set Unicode_Result=36918
exit/b
:Unicode36909
set Unicode_Result=逭
exit/b
:Unicode逭
set Unicode_Result=36909
exit/b
:Unicode36911
set Unicode_Result=逯
exit/b
:Unicode逯
set Unicode_Result=36911
exit/b
:Unicode36932
set Unicode_Result=遄
exit/b
:Unicode遄
set Unicode_Result=36932
exit/b
:Unicode36945
set Unicode_Result=遑
exit/b
:Unicode遑
set Unicode_Result=36945
exit/b
:Unicode36946
set Unicode_Result=遒
exit/b
:Unicode遒
set Unicode_Result=36946
exit/b
:Unicode36944
set Unicode_Result=遐
exit/b
:Unicode遐
set Unicode_Result=36944
exit/b
:Unicode36968
set Unicode_Result=遨
exit/b
:Unicode遨
set Unicode_Result=36968
exit/b
:Unicode36952
set Unicode_Result=遘
exit/b
:Unicode遘
set Unicode_Result=36952
exit/b
:Unicode36962
set Unicode_Result=遢
exit/b
:Unicode遢
set Unicode_Result=36962
exit/b
:Unicode36955
set Unicode_Result=遛
exit/b
:Unicode遛
set Unicode_Result=36955
exit/b
:Unicode26297
set Unicode_Result=暹
exit/b
:Unicode暹
set Unicode_Result=26297
exit/b
:Unicode36980
set Unicode_Result=遴
exit/b
:Unicode遴
set Unicode_Result=36980
exit/b
:Unicode36989
set Unicode_Result=遽
exit/b
:Unicode遽
set Unicode_Result=36989
exit/b
:Unicode36994
set Unicode_Result=邂
exit/b
:Unicode邂
set Unicode_Result=36994
exit/b
:Unicode37000
set Unicode_Result=邈
exit/b
:Unicode邈
set Unicode_Result=37000
exit/b
:Unicode36995
set Unicode_Result=邃
exit/b
:Unicode邃
set Unicode_Result=36995
exit/b
:Unicode37003
set Unicode_Result=邋
exit/b
:Unicode邋
set Unicode_Result=37003
exit/b
:Unicode24400
set Unicode_Result=彐
exit/b
:Unicode彐
set Unicode_Result=24400
exit/b
:Unicode24407
set Unicode_Result=彗
exit/b
:Unicode彗
set Unicode_Result=24407
exit/b
:Unicode24406
set Unicode_Result=彖
exit/b
:Unicode彖
set Unicode_Result=24406
exit/b
:Unicode24408
set Unicode_Result=彘
exit/b
:Unicode彘
set Unicode_Result=24408
exit/b
:Unicode23611
set Unicode_Result=尻
exit/b
:Unicode尻
set Unicode_Result=23611
exit/b
:Unicode21675
set Unicode_Result=咫
exit/b
:Unicode咫
set Unicode_Result=21675
exit/b
:Unicode23632
set Unicode_Result=屐
exit/b
:Unicode屐
set Unicode_Result=23632
exit/b
:Unicode23641
set Unicode_Result=屙
exit/b
:Unicode屙
set Unicode_Result=23641
exit/b
:Unicode23409
set Unicode_Result=孱
exit/b
:Unicode孱
set Unicode_Result=23409
exit/b
:Unicode23651
set Unicode_Result=屣
exit/b
:Unicode屣
set Unicode_Result=23651
exit/b
:Unicode23654
set Unicode_Result=屦
exit/b
:Unicode屦
set Unicode_Result=23654
exit/b
:Unicode32700
set Unicode_Result=羼
exit/b
:Unicode羼
set Unicode_Result=32700
exit/b
:Unicode24362
set Unicode_Result=弪
exit/b
:Unicode弪
set Unicode_Result=24362
exit/b
:Unicode24361
set Unicode_Result=弩
exit/b
:Unicode弩
set Unicode_Result=24361
exit/b
:Unicode24365
set Unicode_Result=弭
exit/b
:Unicode弭
set Unicode_Result=24365
exit/b
:Unicode33396
set Unicode_Result=艴
exit/b
:Unicode艴
set Unicode_Result=33396
exit/b
:Unicode24380
set Unicode_Result=弼
exit/b
:Unicode弼
set Unicode_Result=24380
exit/b
:Unicode39739
set Unicode_Result=鬻
exit/b
:Unicode鬻
set Unicode_Result=39739
exit/b
:Unicode23662
set Unicode_Result=屮
exit/b
:Unicode屮
set Unicode_Result=23662
exit/b
:Unicode22913
set Unicode_Result=妁
exit/b
:Unicode妁
set Unicode_Result=22913
exit/b
:Unicode22915
set Unicode_Result=妃
exit/b
:Unicode妃
set Unicode_Result=22915
exit/b
:Unicode22925
set Unicode_Result=妍
exit/b
:Unicode妍
set Unicode_Result=22925
exit/b
:Unicode22953
set Unicode_Result=妩
exit/b
:Unicode妩
set Unicode_Result=22953
exit/b
:Unicode22954
set Unicode_Result=妪
exit/b
:Unicode妪
set Unicode_Result=22954
exit/b
:Unicode22947
set Unicode_Result=妣
exit/b
:Unicode妣
set Unicode_Result=22947
exit/b
:Unicode22935
set Unicode_Result=妗
exit/b
:Unicode妗
set Unicode_Result=22935
exit/b
:Unicode22986
set Unicode_Result=姊
exit/b
:Unicode姊
set Unicode_Result=22986
exit/b
:Unicode22955
set Unicode_Result=妫
exit/b
:Unicode妫
set Unicode_Result=22955
exit/b
:Unicode22942
set Unicode_Result=妞
exit/b
:Unicode妞
set Unicode_Result=22942
exit/b
:Unicode22948
set Unicode_Result=妤
exit/b
:Unicode妤
set Unicode_Result=22948
exit/b
:Unicode22994
set Unicode_Result=姒
exit/b
:Unicode姒
set Unicode_Result=22994
exit/b
:Unicode22962
set Unicode_Result=妲
exit/b
:Unicode妲
set Unicode_Result=22962
exit/b
:Unicode22959
set Unicode_Result=妯
exit/b
:Unicode妯
set Unicode_Result=22959
exit/b
:Unicode22999
set Unicode_Result=姗
exit/b
:Unicode姗
set Unicode_Result=22999
exit/b
:Unicode22974
set Unicode_Result=妾
exit/b
:Unicode妾
set Unicode_Result=22974
exit/b
:Unicode23045
set Unicode_Result=娅
exit/b
:Unicode娅
set Unicode_Result=23045
exit/b
:Unicode23046
set Unicode_Result=娆
exit/b
:Unicode娆
set Unicode_Result=23046
exit/b
:Unicode23005
set Unicode_Result=姝
exit/b
:Unicode姝
set Unicode_Result=23005
exit/b
:Unicode23048
set Unicode_Result=娈
exit/b
:Unicode娈
set Unicode_Result=23048
exit/b
:Unicode23011
set Unicode_Result=姣
exit/b
:Unicode姣
set Unicode_Result=23011
exit/b
:Unicode23000
set Unicode_Result=姘
exit/b
:Unicode姘
set Unicode_Result=23000
exit/b
:Unicode23033
set Unicode_Result=姹
exit/b
:Unicode姹
set Unicode_Result=23033
exit/b
:Unicode23052
set Unicode_Result=娌
exit/b
:Unicode娌
set Unicode_Result=23052
exit/b
:Unicode23049
set Unicode_Result=娉
exit/b
:Unicode娉
set Unicode_Result=23049
exit/b
:Unicode23090
set Unicode_Result=娲
exit/b
:Unicode娲
set Unicode_Result=23090
exit/b
:Unicode23092
set Unicode_Result=娴
exit/b
:Unicode娴
set Unicode_Result=23092
exit/b
:Unicode23057
set Unicode_Result=娑
exit/b
:Unicode娑
set Unicode_Result=23057
exit/b
:Unicode23075
set Unicode_Result=娣
exit/b
:Unicode娣
set Unicode_Result=23075
exit/b
:Unicode23059
set Unicode_Result=娓
exit/b
:Unicode娓
set Unicode_Result=23059
exit/b
:Unicode23104
set Unicode_Result=婀
exit/b
:Unicode婀
set Unicode_Result=23104
exit/b
:Unicode23143
set Unicode_Result=婧
exit/b
:Unicode婧
set Unicode_Result=23143
exit/b
:Unicode23114
set Unicode_Result=婊
exit/b
:Unicode婊
set Unicode_Result=23114
exit/b
:Unicode23125
set Unicode_Result=婕
exit/b
:Unicode婕
set Unicode_Result=23125
exit/b
:Unicode23100
set Unicode_Result=娼
exit/b
:Unicode娼
set Unicode_Result=23100
exit/b
:Unicode23138
set Unicode_Result=婢
exit/b
:Unicode婢
set Unicode_Result=23138
exit/b
:Unicode23157
set Unicode_Result=婵
exit/b
:Unicode婵
set Unicode_Result=23157
exit/b
:Unicode33004
set Unicode_Result=胬
exit/b
:Unicode胬
set Unicode_Result=33004
exit/b
:Unicode23210
set Unicode_Result=媪
exit/b
:Unicode媪
set Unicode_Result=23210
exit/b
:Unicode23195
set Unicode_Result=媛
exit/b
:Unicode媛
set Unicode_Result=23195
exit/b
:Unicode23159
set Unicode_Result=婷
exit/b
:Unicode婷
set Unicode_Result=23159
exit/b
:Unicode23162
set Unicode_Result=婺
exit/b
:Unicode婺
set Unicode_Result=23162
exit/b
:Unicode23230
set Unicode_Result=媾
exit/b
:Unicode媾
set Unicode_Result=23230
exit/b
:Unicode23275
set Unicode_Result=嫫
exit/b
:Unicode嫫
set Unicode_Result=23275
exit/b
:Unicode23218
set Unicode_Result=媲
exit/b
:Unicode媲
set Unicode_Result=23218
exit/b
:Unicode23250
set Unicode_Result=嫒
exit/b
:Unicode嫒
set Unicode_Result=23250
exit/b
:Unicode23252
set Unicode_Result=嫔
exit/b
:Unicode嫔
set Unicode_Result=23252
exit/b
:Unicode23224
set Unicode_Result=媸
exit/b
:Unicode媸
set Unicode_Result=23224
exit/b
:Unicode23264
set Unicode_Result=嫠
exit/b
:Unicode嫠
set Unicode_Result=23264
exit/b
:Unicode23267
set Unicode_Result=嫣
exit/b
:Unicode嫣
set Unicode_Result=23267
exit/b
:Unicode23281
set Unicode_Result=嫱
exit/b
:Unicode嫱
set Unicode_Result=23281
exit/b
:Unicode23254
set Unicode_Result=嫖
exit/b
:Unicode嫖
set Unicode_Result=23254
exit/b
:Unicode23270
set Unicode_Result=嫦
exit/b
:Unicode嫦
set Unicode_Result=23270
exit/b
:Unicode23256
set Unicode_Result=嫘
exit/b
:Unicode嫘
set Unicode_Result=23256
exit/b
:Unicode23260
set Unicode_Result=嫜
exit/b
:Unicode嫜
set Unicode_Result=23260
exit/b
:Unicode23305
set Unicode_Result=嬉
exit/b
:Unicode嬉
set Unicode_Result=23305
exit/b
:Unicode23319
set Unicode_Result=嬗
exit/b
:Unicode嬗
set Unicode_Result=23319
exit/b
:Unicode23318
set Unicode_Result=嬖
exit/b
:Unicode嬖
set Unicode_Result=23318
exit/b
:Unicode23346
set Unicode_Result=嬲
exit/b
:Unicode嬲
set Unicode_Result=23346
exit/b
:Unicode23351
set Unicode_Result=嬷
exit/b
:Unicode嬷
set Unicode_Result=23351
exit/b
:Unicode23360
set Unicode_Result=孀
exit/b
:Unicode孀
set Unicode_Result=23360
exit/b
:Unicode23573
set Unicode_Result=尕
exit/b
:Unicode尕
set Unicode_Result=23573
exit/b
:Unicode23580
set Unicode_Result=尜
exit/b
:Unicode尜
set Unicode_Result=23580
exit/b
:Unicode23386
set Unicode_Result=孚
exit/b
:Unicode孚
set Unicode_Result=23386
exit/b
:Unicode23397
set Unicode_Result=孥
exit/b
:Unicode孥
set Unicode_Result=23397
exit/b
:Unicode23411
set Unicode_Result=孳
exit/b
:Unicode孳
set Unicode_Result=23411
exit/b
:Unicode23377
set Unicode_Result=孑
exit/b
:Unicode孑
set Unicode_Result=23377
exit/b
:Unicode23379
set Unicode_Result=孓
exit/b
:Unicode孓
set Unicode_Result=23379
exit/b
:Unicode23394
set Unicode_Result=孢
exit/b
:Unicode孢
set Unicode_Result=23394
exit/b
:Unicode39541
set Unicode_Result=驵
exit/b
:Unicode驵
set Unicode_Result=39541
exit/b
:Unicode39543
set Unicode_Result=驷
exit/b
:Unicode驷
set Unicode_Result=39543
exit/b
:Unicode39544
set Unicode_Result=驸
exit/b
:Unicode驸
set Unicode_Result=39544
exit/b
:Unicode39546
set Unicode_Result=驺
exit/b
:Unicode驺
set Unicode_Result=39546
exit/b
:Unicode39551
set Unicode_Result=驿
exit/b
:Unicode驿
set Unicode_Result=39551
exit/b
:Unicode39549
set Unicode_Result=驽
exit/b
:Unicode驽
set Unicode_Result=39549
exit/b
:Unicode39552
set Unicode_Result=骀
exit/b
:Unicode骀
set Unicode_Result=39552
exit/b
:Unicode39553
set Unicode_Result=骁
exit/b
:Unicode骁
set Unicode_Result=39553
exit/b
:Unicode39557
set Unicode_Result=骅
exit/b
:Unicode骅
set Unicode_Result=39557
exit/b
:Unicode39560
set Unicode_Result=骈
exit/b
:Unicode骈
set Unicode_Result=39560
exit/b
:Unicode39562
set Unicode_Result=骊
exit/b
:Unicode骊
set Unicode_Result=39562
exit/b
:Unicode39568
set Unicode_Result=骐
exit/b
:Unicode骐
set Unicode_Result=39568
exit/b
:Unicode39570
set Unicode_Result=骒
exit/b
:Unicode骒
set Unicode_Result=39570
exit/b
:Unicode39571
set Unicode_Result=骓
exit/b
:Unicode骓
set Unicode_Result=39571
exit/b
:Unicode39574
set Unicode_Result=骖
exit/b
:Unicode骖
set Unicode_Result=39574
exit/b
:Unicode39576
set Unicode_Result=骘
exit/b
:Unicode骘
set Unicode_Result=39576
exit/b
:Unicode39579
set Unicode_Result=骛
exit/b
:Unicode骛
set Unicode_Result=39579
exit/b
:Unicode39580
set Unicode_Result=骜
exit/b
:Unicode骜
set Unicode_Result=39580
exit/b
:Unicode39581
set Unicode_Result=骝
exit/b
:Unicode骝
set Unicode_Result=39581
exit/b
:Unicode39583
set Unicode_Result=骟
exit/b
:Unicode骟
set Unicode_Result=39583
exit/b
:Unicode39584
set Unicode_Result=骠
exit/b
:Unicode骠
set Unicode_Result=39584
exit/b
:Unicode39586
set Unicode_Result=骢
exit/b
:Unicode骢
set Unicode_Result=39586
exit/b
:Unicode39587
set Unicode_Result=骣
exit/b
:Unicode骣
set Unicode_Result=39587
exit/b
:Unicode39589
set Unicode_Result=骥
exit/b
:Unicode骥
set Unicode_Result=39589
exit/b
:Unicode39591
set Unicode_Result=骧
exit/b
:Unicode骧
set Unicode_Result=39591
exit/b
:Unicode32415
set Unicode_Result=纟
exit/b
:Unicode纟
set Unicode_Result=32415
exit/b
:Unicode32417
set Unicode_Result=纡
exit/b
:Unicode纡
set Unicode_Result=32417
exit/b
:Unicode32419
set Unicode_Result=纣
exit/b
:Unicode纣
set Unicode_Result=32419
exit/b
:Unicode32421
set Unicode_Result=纥
exit/b
:Unicode纥
set Unicode_Result=32421
exit/b
:Unicode32424
set Unicode_Result=纨
exit/b
:Unicode纨
set Unicode_Result=32424
exit/b
:Unicode32425
set Unicode_Result=纩
exit/b
:Unicode纩
set Unicode_Result=32425
exit/b
:Unicode32429
set Unicode_Result=纭
exit/b
:Unicode纭
set Unicode_Result=32429
exit/b
:Unicode32432
set Unicode_Result=纰
exit/b
:Unicode纰
set Unicode_Result=32432
exit/b
:Unicode32446
set Unicode_Result=纾
exit/b
:Unicode纾
set Unicode_Result=32446
exit/b
:Unicode32448
set Unicode_Result=绀
exit/b
:Unicode绀
set Unicode_Result=32448
exit/b
:Unicode32449
set Unicode_Result=绁
exit/b
:Unicode绁
set Unicode_Result=32449
exit/b
:Unicode32450
set Unicode_Result=绂
exit/b
:Unicode绂
set Unicode_Result=32450
exit/b
:Unicode32457
set Unicode_Result=绉
exit/b
:Unicode绉
set Unicode_Result=32457
exit/b
:Unicode32459
set Unicode_Result=绋
exit/b
:Unicode绋
set Unicode_Result=32459
exit/b
:Unicode32460
set Unicode_Result=绌
exit/b
:Unicode绌
set Unicode_Result=32460
exit/b
:Unicode32464
set Unicode_Result=绐
exit/b
:Unicode绐
set Unicode_Result=32464
exit/b
:Unicode32468
set Unicode_Result=绔
exit/b
:Unicode绔
set Unicode_Result=32468
exit/b
:Unicode32471
set Unicode_Result=绗
exit/b
:Unicode绗
set Unicode_Result=32471
exit/b
:Unicode32475
set Unicode_Result=绛
exit/b
:Unicode绛
set Unicode_Result=32475
exit/b
:Unicode32480
set Unicode_Result=绠
exit/b
:Unicode绠
set Unicode_Result=32480
exit/b
:Unicode32481
set Unicode_Result=绡
exit/b
:Unicode绡
set Unicode_Result=32481
exit/b
:Unicode32488
set Unicode_Result=绨
exit/b
:Unicode绨
set Unicode_Result=32488
exit/b
:Unicode32491
set Unicode_Result=绫
exit/b
:Unicode绫
set Unicode_Result=32491
exit/b
:Unicode32494
set Unicode_Result=绮
exit/b
:Unicode绮
set Unicode_Result=32494
exit/b
:Unicode32495
set Unicode_Result=绯
exit/b
:Unicode绯
set Unicode_Result=32495
exit/b
:Unicode32497
set Unicode_Result=绱
exit/b
:Unicode绱
set Unicode_Result=32497
exit/b
:Unicode32498
set Unicode_Result=绲
exit/b
:Unicode绲
set Unicode_Result=32498
exit/b
:Unicode32525
set Unicode_Result=缍
exit/b
:Unicode缍
set Unicode_Result=32525
exit/b
:Unicode32502
set Unicode_Result=绶
exit/b
:Unicode绶
set Unicode_Result=32502
exit/b
:Unicode32506
set Unicode_Result=绺
exit/b
:Unicode绺
set Unicode_Result=32506
exit/b
:Unicode32507
set Unicode_Result=绻
exit/b
:Unicode绻
set Unicode_Result=32507
exit/b
:Unicode32510
set Unicode_Result=绾
exit/b
:Unicode绾
set Unicode_Result=32510
exit/b
:Unicode32513
set Unicode_Result=缁
exit/b
:Unicode缁
set Unicode_Result=32513
exit/b
:Unicode32514
set Unicode_Result=缂
exit/b
:Unicode缂
set Unicode_Result=32514
exit/b
:Unicode32515
set Unicode_Result=缃
exit/b
:Unicode缃
set Unicode_Result=32515
exit/b
:Unicode32519
set Unicode_Result=缇
exit/b
:Unicode缇
set Unicode_Result=32519
exit/b
:Unicode32520
set Unicode_Result=缈
exit/b
:Unicode缈
set Unicode_Result=32520
exit/b
:Unicode32523
set Unicode_Result=缋
exit/b
:Unicode缋
set Unicode_Result=32523
exit/b
:Unicode32524
set Unicode_Result=缌
exit/b
:Unicode缌
set Unicode_Result=32524
exit/b
:Unicode32527
set Unicode_Result=缏
exit/b
:Unicode缏
set Unicode_Result=32527
exit/b
:Unicode32529
set Unicode_Result=缑
exit/b
:Unicode缑
set Unicode_Result=32529
exit/b
:Unicode32530
set Unicode_Result=缒
exit/b
:Unicode缒
set Unicode_Result=32530
exit/b
:Unicode32535
set Unicode_Result=缗
exit/b
:Unicode缗
set Unicode_Result=32535
exit/b
:Unicode32537
set Unicode_Result=缙
exit/b
:Unicode缙
set Unicode_Result=32537
exit/b
:Unicode32540
set Unicode_Result=缜
exit/b
:Unicode缜
set Unicode_Result=32540
exit/b
:Unicode32539
set Unicode_Result=缛
exit/b
:Unicode缛
set Unicode_Result=32539
exit/b
:Unicode32543
set Unicode_Result=缟
exit/b
:Unicode缟
set Unicode_Result=32543
exit/b
:Unicode32545
set Unicode_Result=缡
exit/b
:Unicode缡
set Unicode_Result=32545
exit/b
:Unicode32546
set Unicode_Result=缢
exit/b
:Unicode缢
set Unicode_Result=32546
exit/b
:Unicode32547
set Unicode_Result=缣
exit/b
:Unicode缣
set Unicode_Result=32547
exit/b
:Unicode32548
set Unicode_Result=缤
exit/b
:Unicode缤
set Unicode_Result=32548
exit/b
:Unicode32549
set Unicode_Result=缥
exit/b
:Unicode缥
set Unicode_Result=32549
exit/b
:Unicode32550
set Unicode_Result=缦
exit/b
:Unicode缦
set Unicode_Result=32550
exit/b
:Unicode32551
set Unicode_Result=缧
exit/b
:Unicode缧
set Unicode_Result=32551
exit/b
:Unicode32554
set Unicode_Result=缪
exit/b
:Unicode缪
set Unicode_Result=32554
exit/b
:Unicode32555
set Unicode_Result=缫
exit/b
:Unicode缫
set Unicode_Result=32555
exit/b
:Unicode32556
set Unicode_Result=缬
exit/b
:Unicode缬
set Unicode_Result=32556
exit/b
:Unicode32557
set Unicode_Result=缭
exit/b
:Unicode缭
set Unicode_Result=32557
exit/b
:Unicode32559
set Unicode_Result=缯
exit/b
:Unicode缯
set Unicode_Result=32559
exit/b
:Unicode32560
set Unicode_Result=缰
exit/b
:Unicode缰
set Unicode_Result=32560
exit/b
:Unicode32561
set Unicode_Result=缱
exit/b
:Unicode缱
set Unicode_Result=32561
exit/b
:Unicode32562
set Unicode_Result=缲
exit/b
:Unicode缲
set Unicode_Result=32562
exit/b
:Unicode32563
set Unicode_Result=缳
exit/b
:Unicode缳
set Unicode_Result=32563
exit/b
:Unicode32565
set Unicode_Result=缵
exit/b
:Unicode缵
set Unicode_Result=32565
exit/b
:Unicode24186
set Unicode_Result=幺
exit/b
:Unicode幺
set Unicode_Result=24186
exit/b
:Unicode30079
set Unicode_Result=畿
exit/b
:Unicode畿
set Unicode_Result=30079
exit/b
:Unicode24027
set Unicode_Result=巛
exit/b
:Unicode巛
set Unicode_Result=24027
exit/b
:Unicode30014
set Unicode_Result=甾
exit/b
:Unicode甾
set Unicode_Result=30014
exit/b
:Unicode37013
set Unicode_Result=邕
exit/b
:Unicode邕
set Unicode_Result=37013
exit/b
:Unicode29582
set Unicode_Result=玎
exit/b
:Unicode玎
set Unicode_Result=29582
exit/b
:Unicode29585
set Unicode_Result=玑
exit/b
:Unicode玑
set Unicode_Result=29585
exit/b
:Unicode29614
set Unicode_Result=玮
exit/b
:Unicode玮
set Unicode_Result=29614
exit/b
:Unicode29602
set Unicode_Result=玢
exit/b
:Unicode玢
set Unicode_Result=29602
exit/b
:Unicode29599
set Unicode_Result=玟
exit/b
:Unicode玟
set Unicode_Result=29599
exit/b
:Unicode29647
set Unicode_Result=珏
exit/b
:Unicode珏
set Unicode_Result=29647
exit/b
:Unicode29634
set Unicode_Result=珂
exit/b
:Unicode珂
set Unicode_Result=29634
exit/b
:Unicode29649
set Unicode_Result=珑
exit/b
:Unicode珑
set Unicode_Result=29649
exit/b
:Unicode29623
set Unicode_Result=玷
exit/b
:Unicode玷
set Unicode_Result=29623
exit/b
:Unicode29619
set Unicode_Result=玳
exit/b
:Unicode玳
set Unicode_Result=29619
exit/b
:Unicode29632
set Unicode_Result=珀
exit/b
:Unicode珀
set Unicode_Result=29632
exit/b
:Unicode29641
set Unicode_Result=珉
exit/b
:Unicode珉
set Unicode_Result=29641
exit/b
:Unicode29640
set Unicode_Result=珈
exit/b
:Unicode珈
set Unicode_Result=29640
exit/b
:Unicode29669
set Unicode_Result=珥
exit/b
:Unicode珥
set Unicode_Result=29669
exit/b
:Unicode29657
set Unicode_Result=珙
exit/b
:Unicode珙
set Unicode_Result=29657
exit/b
:Unicode39036
set Unicode_Result=顼
exit/b
:Unicode顼
set Unicode_Result=39036
exit/b
:Unicode29706
set Unicode_Result=琊
exit/b
:Unicode琊
set Unicode_Result=29706
exit/b
:Unicode29673
set Unicode_Result=珩
exit/b
:Unicode珩
set Unicode_Result=29673
exit/b
:Unicode29671
set Unicode_Result=珧
exit/b
:Unicode珧
set Unicode_Result=29671
exit/b
:Unicode29662
set Unicode_Result=珞
exit/b
:Unicode珞
set Unicode_Result=29662
exit/b
:Unicode29626
set Unicode_Result=玺
exit/b
:Unicode玺
set Unicode_Result=29626
exit/b
:Unicode29682
set Unicode_Result=珲
exit/b
:Unicode珲
set Unicode_Result=29682
exit/b
:Unicode29711
set Unicode_Result=琏
exit/b
:Unicode琏
set Unicode_Result=29711
exit/b
:Unicode29738
set Unicode_Result=琪
exit/b
:Unicode琪
set Unicode_Result=29738
exit/b
:Unicode29787
set Unicode_Result=瑛
exit/b
:Unicode瑛
set Unicode_Result=29787
exit/b
:Unicode29734
set Unicode_Result=琦
exit/b
:Unicode琦
set Unicode_Result=29734
exit/b
:Unicode29733
set Unicode_Result=琥
exit/b
:Unicode琥
set Unicode_Result=29733
exit/b
:Unicode29736
set Unicode_Result=琨
exit/b
:Unicode琨
set Unicode_Result=29736
exit/b
:Unicode29744
set Unicode_Result=琰
exit/b
:Unicode琰
set Unicode_Result=29744
exit/b
:Unicode29742
set Unicode_Result=琮
exit/b
:Unicode琮
set Unicode_Result=29742
exit/b
:Unicode29740
set Unicode_Result=琬
exit/b
:Unicode琬
set Unicode_Result=29740
exit/b
:Unicode29723
set Unicode_Result=琛
exit/b
:Unicode琛
set Unicode_Result=29723
exit/b
:Unicode29722
set Unicode_Result=琚
exit/b
:Unicode琚
set Unicode_Result=29722
exit/b
:Unicode29761
set Unicode_Result=瑁
exit/b
:Unicode瑁
set Unicode_Result=29761
exit/b
:Unicode29788
set Unicode_Result=瑜
exit/b
:Unicode瑜
set Unicode_Result=29788
exit/b
:Unicode29783
set Unicode_Result=瑗
exit/b
:Unicode瑗
set Unicode_Result=29783
exit/b
:Unicode29781
set Unicode_Result=瑕
exit/b
:Unicode瑕
set Unicode_Result=29781
exit/b
:Unicode29785
set Unicode_Result=瑙
exit/b
:Unicode瑙
set Unicode_Result=29785
exit/b
:Unicode29815
set Unicode_Result=瑷
exit/b
:Unicode瑷
set Unicode_Result=29815
exit/b
:Unicode29805
set Unicode_Result=瑭
exit/b
:Unicode瑭
set Unicode_Result=29805
exit/b
:Unicode29822
set Unicode_Result=瑾
exit/b
:Unicode瑾
set Unicode_Result=29822
exit/b
:Unicode29852
set Unicode_Result=璜
exit/b
:Unicode璜
set Unicode_Result=29852
exit/b
:Unicode29838
set Unicode_Result=璎
exit/b
:Unicode璎
set Unicode_Result=29838
exit/b
:Unicode29824
set Unicode_Result=璀
exit/b
:Unicode璀
set Unicode_Result=29824
exit/b
:Unicode29825
set Unicode_Result=璁
exit/b
:Unicode璁
set Unicode_Result=29825
exit/b
:Unicode29831
set Unicode_Result=璇
exit/b
:Unicode璇
set Unicode_Result=29831
exit/b
:Unicode29835
set Unicode_Result=璋
exit/b
:Unicode璋
set Unicode_Result=29835
exit/b
:Unicode29854
set Unicode_Result=璞
exit/b
:Unicode璞
set Unicode_Result=29854
exit/b
:Unicode29864
set Unicode_Result=璨
exit/b
:Unicode璨
set Unicode_Result=29864
exit/b
:Unicode29865
set Unicode_Result=璩
exit/b
:Unicode璩
set Unicode_Result=29865
exit/b
:Unicode29840
set Unicode_Result=璐
exit/b
:Unicode璐
set Unicode_Result=29840
exit/b
:Unicode29863
set Unicode_Result=璧
exit/b
:Unicode璧
set Unicode_Result=29863
exit/b
:Unicode29906
set Unicode_Result=瓒
exit/b
:Unicode瓒
set Unicode_Result=29906
exit/b
:Unicode29882
set Unicode_Result=璺
exit/b
:Unicode璺
set Unicode_Result=29882
exit/b
:Unicode38890
set Unicode_Result=韪
exit/b
:Unicode韪
set Unicode_Result=38890
exit/b
:Unicode38891
set Unicode_Result=韫
exit/b
:Unicode韫
set Unicode_Result=38891
exit/b
:Unicode38892
set Unicode_Result=韬
exit/b
:Unicode韬
set Unicode_Result=38892
exit/b
:Unicode26444
set Unicode_Result=杌
exit/b
:Unicode杌
set Unicode_Result=26444
exit/b
:Unicode26451
set Unicode_Result=杓
exit/b
:Unicode杓
set Unicode_Result=26451
exit/b
:Unicode26462
set Unicode_Result=杞
exit/b
:Unicode杞
set Unicode_Result=26462
exit/b
:Unicode26440
set Unicode_Result=杈
exit/b
:Unicode杈
set Unicode_Result=26440
exit/b
:Unicode26473
set Unicode_Result=杩
exit/b
:Unicode杩
set Unicode_Result=26473
exit/b
:Unicode26533
set Unicode_Result=枥
exit/b
:Unicode枥
set Unicode_Result=26533
exit/b
:Unicode26503
set Unicode_Result=枇
exit/b
:Unicode枇
set Unicode_Result=26503
exit/b
:Unicode26474
set Unicode_Result=杪
exit/b
:Unicode杪
set Unicode_Result=26474
exit/b
:Unicode26483
set Unicode_Result=杳
exit/b
:Unicode杳
set Unicode_Result=26483
exit/b
:Unicode26520
set Unicode_Result=枘
exit/b
:Unicode枘
set Unicode_Result=26520
exit/b
:Unicode26535
set Unicode_Result=枧
exit/b
:Unicode枧
set Unicode_Result=26535
exit/b
:Unicode26485
set Unicode_Result=杵
exit/b
:Unicode杵
set Unicode_Result=26485
exit/b
:Unicode26536
set Unicode_Result=枨
exit/b
:Unicode枨
set Unicode_Result=26536
exit/b
:Unicode26526
set Unicode_Result=枞
exit/b
:Unicode枞
set Unicode_Result=26526
exit/b
:Unicode26541
set Unicode_Result=枭
exit/b
:Unicode枭
set Unicode_Result=26541
exit/b
:Unicode26507
set Unicode_Result=枋
exit/b
:Unicode枋
set Unicode_Result=26507
exit/b
:Unicode26487
set Unicode_Result=杷
exit/b
:Unicode杷
set Unicode_Result=26487
exit/b
:Unicode26492
set Unicode_Result=杼
exit/b
:Unicode杼
set Unicode_Result=26492
exit/b
:Unicode26608
set Unicode_Result=柰
exit/b
:Unicode柰
set Unicode_Result=26608
exit/b
:Unicode26633
set Unicode_Result=栉
exit/b
:Unicode栉
set Unicode_Result=26633
exit/b
:Unicode26584
set Unicode_Result=柘
exit/b
:Unicode柘
set Unicode_Result=26584
exit/b
:Unicode26634
set Unicode_Result=栊
exit/b
:Unicode栊
set Unicode_Result=26634
exit/b
:Unicode26601
set Unicode_Result=柩
exit/b
:Unicode柩
set Unicode_Result=26601
exit/b
:Unicode26544
set Unicode_Result=枰
exit/b
:Unicode枰
set Unicode_Result=26544
exit/b
:Unicode26636
set Unicode_Result=栌
exit/b
:Unicode栌
set Unicode_Result=26636
exit/b
:Unicode26585
set Unicode_Result=柙
exit/b
:Unicode柙
set Unicode_Result=26585
exit/b
:Unicode26549
set Unicode_Result=枵
exit/b
:Unicode枵
set Unicode_Result=26549
exit/b
:Unicode26586
set Unicode_Result=柚
exit/b
:Unicode柚
set Unicode_Result=26586
exit/b
:Unicode26547
set Unicode_Result=枳
exit/b
:Unicode枳
set Unicode_Result=26547
exit/b
:Unicode26589
set Unicode_Result=柝
exit/b
:Unicode柝
set Unicode_Result=26589
exit/b
:Unicode26624
set Unicode_Result=栀
exit/b
:Unicode栀
set Unicode_Result=26624
exit/b
:Unicode26563
set Unicode_Result=柃
exit/b
:Unicode柃
set Unicode_Result=26563
exit/b
:Unicode26552
set Unicode_Result=枸
exit/b
:Unicode枸
set Unicode_Result=26552
exit/b
:Unicode26594
set Unicode_Result=柢
exit/b
:Unicode柢
set Unicode_Result=26594
exit/b
:Unicode26638
set Unicode_Result=栎
exit/b
:Unicode栎
set Unicode_Result=26638
exit/b
:Unicode26561
set Unicode_Result=柁
exit/b
:Unicode柁
set Unicode_Result=26561
exit/b
:Unicode26621
set Unicode_Result=柽
exit/b
:Unicode柽
set Unicode_Result=26621
exit/b
:Unicode26674
set Unicode_Result=栲
exit/b
:Unicode栲
set Unicode_Result=26674
exit/b
:Unicode26675
set Unicode_Result=栳
exit/b
:Unicode栳
set Unicode_Result=26675
exit/b
:Unicode26720
set Unicode_Result=桠
exit/b
:Unicode桠
set Unicode_Result=26720
exit/b
:Unicode26721
set Unicode_Result=桡
exit/b
:Unicode桡
set Unicode_Result=26721
exit/b
:Unicode26702
set Unicode_Result=桎
exit/b
:Unicode桎
set Unicode_Result=26702
exit/b
:Unicode26722
set Unicode_Result=桢
exit/b
:Unicode桢
set Unicode_Result=26722
exit/b
:Unicode26692
set Unicode_Result=桄
exit/b
:Unicode桄
set Unicode_Result=26692
exit/b
:Unicode26724
set Unicode_Result=桤
exit/b
:Unicode桤
set Unicode_Result=26724
exit/b
:Unicode26755
set Unicode_Result=梃
exit/b
:Unicode梃
set Unicode_Result=26755
exit/b
:Unicode26653
set Unicode_Result=栝
exit/b
:Unicode栝
set Unicode_Result=26653
exit/b
:Unicode26709
set Unicode_Result=桕
exit/b
:Unicode桕
set Unicode_Result=26709
exit/b
:Unicode26726
set Unicode_Result=桦
exit/b
:Unicode桦
set Unicode_Result=26726
exit/b
:Unicode26689
set Unicode_Result=桁
exit/b
:Unicode桁
set Unicode_Result=26689
exit/b
:Unicode26727
set Unicode_Result=桧
exit/b
:Unicode桧
set Unicode_Result=26727
exit/b
:Unicode26688
set Unicode_Result=桀
exit/b
:Unicode桀
set Unicode_Result=26688
exit/b
:Unicode26686
set Unicode_Result=栾
exit/b
:Unicode栾
set Unicode_Result=26686
exit/b
:Unicode26698
set Unicode_Result=桊
exit/b
:Unicode桊
set Unicode_Result=26698
exit/b
:Unicode26697
set Unicode_Result=桉
exit/b
:Unicode桉
set Unicode_Result=26697
exit/b
:Unicode26665
set Unicode_Result=栩
exit/b
:Unicode栩
set Unicode_Result=26665
exit/b
:Unicode26805
set Unicode_Result=梵
exit/b
:Unicode梵
set Unicode_Result=26805
exit/b
:Unicode26767
set Unicode_Result=梏
exit/b
:Unicode梏
set Unicode_Result=26767
exit/b
:Unicode26740
set Unicode_Result=桴
exit/b
:Unicode桴
set Unicode_Result=26740
exit/b
:Unicode26743
set Unicode_Result=桷
exit/b
:Unicode桷
set Unicode_Result=26743
exit/b
:Unicode26771
set Unicode_Result=梓
exit/b
:Unicode梓
set Unicode_Result=26771
exit/b
:Unicode26731
set Unicode_Result=桫
exit/b
:Unicode桫
set Unicode_Result=26731
exit/b
:Unicode26818
set Unicode_Result=棂
exit/b
:Unicode棂
set Unicode_Result=26818
exit/b
:Unicode26990
set Unicode_Result=楮
exit/b
:Unicode楮
set Unicode_Result=26990
exit/b
:Unicode26876
set Unicode_Result=棼
exit/b
:Unicode棼
set Unicode_Result=26876
exit/b
:Unicode26911
set Unicode_Result=椟
exit/b
:Unicode椟
set Unicode_Result=26911
exit/b
:Unicode26912
set Unicode_Result=椠
exit/b
:Unicode椠
set Unicode_Result=26912
exit/b
:Unicode26873
set Unicode_Result=棹
exit/b
:Unicode棹
set Unicode_Result=26873
exit/b
:Unicode26916
set Unicode_Result=椤
exit/b
:Unicode椤
set Unicode_Result=26916
exit/b
:Unicode26864
set Unicode_Result=棰
exit/b
:Unicode棰
set Unicode_Result=26864
exit/b
:Unicode26891
set Unicode_Result=椋
exit/b
:Unicode椋
set Unicode_Result=26891
exit/b
:Unicode26881
set Unicode_Result=椁
exit/b
:Unicode椁
set Unicode_Result=26881
exit/b
:Unicode26967
set Unicode_Result=楗
exit/b
:Unicode楗
set Unicode_Result=26967
exit/b
:Unicode26851
set Unicode_Result=棣
exit/b
:Unicode棣
set Unicode_Result=26851
exit/b
:Unicode26896
set Unicode_Result=椐
exit/b
:Unicode椐
set Unicode_Result=26896
exit/b
:Unicode26993
set Unicode_Result=楱
exit/b
:Unicode楱
set Unicode_Result=26993
exit/b
:Unicode26937
set Unicode_Result=椹
exit/b
:Unicode椹
set Unicode_Result=26937
exit/b
:Unicode26976
set Unicode_Result=楠
exit/b
:Unicode楠
set Unicode_Result=26976
exit/b
:Unicode26946
set Unicode_Result=楂
exit/b
:Unicode楂
set Unicode_Result=26946
exit/b
:Unicode26973
set Unicode_Result=楝
exit/b
:Unicode楝
set Unicode_Result=26973
exit/b
:Unicode27012
set Unicode_Result=榄
exit/b
:Unicode榄
set Unicode_Result=27012
exit/b
:Unicode26987
set Unicode_Result=楫
exit/b
:Unicode楫
set Unicode_Result=26987
exit/b
:Unicode27008
set Unicode_Result=榀
exit/b
:Unicode榀
set Unicode_Result=27008
exit/b
:Unicode27032
set Unicode_Result=榘
exit/b
:Unicode榘
set Unicode_Result=27032
exit/b
:Unicode27000
set Unicode_Result=楸
exit/b
:Unicode楸
set Unicode_Result=27000
exit/b
:Unicode26932
set Unicode_Result=椴
exit/b
:Unicode椴
set Unicode_Result=26932
exit/b
:Unicode27084
set Unicode_Result=槌
exit/b
:Unicode槌
set Unicode_Result=27084
exit/b
:Unicode27015
set Unicode_Result=榇
exit/b
:Unicode榇
set Unicode_Result=27015
exit/b
:Unicode27016
set Unicode_Result=榈
exit/b
:Unicode榈
set Unicode_Result=27016
exit/b
:Unicode27086
set Unicode_Result=槎
exit/b
:Unicode槎
set Unicode_Result=27086
exit/b
:Unicode27017
set Unicode_Result=榉
exit/b
:Unicode榉
set Unicode_Result=27017
exit/b
:Unicode26982
set Unicode_Result=楦
exit/b
:Unicode楦
set Unicode_Result=26982
exit/b
:Unicode26979
set Unicode_Result=楣
exit/b
:Unicode楣
set Unicode_Result=26979
exit/b
:Unicode27001
set Unicode_Result=楹
exit/b
:Unicode楹
set Unicode_Result=27001
exit/b
:Unicode27035
set Unicode_Result=榛
exit/b
:Unicode榛
set Unicode_Result=27035
exit/b
:Unicode27047
set Unicode_Result=榧
exit/b
:Unicode榧
set Unicode_Result=27047
exit/b
:Unicode27067
set Unicode_Result=榻
exit/b
:Unicode榻
set Unicode_Result=27067
exit/b
:Unicode27051
set Unicode_Result=榫
exit/b
:Unicode榫
set Unicode_Result=27051
exit/b
:Unicode27053
set Unicode_Result=榭
exit/b
:Unicode榭
set Unicode_Result=27053
exit/b
:Unicode27092
set Unicode_Result=槔
exit/b
:Unicode槔
set Unicode_Result=27092
exit/b
:Unicode27057
set Unicode_Result=榱
exit/b
:Unicode榱
set Unicode_Result=27057
exit/b
:Unicode27073
set Unicode_Result=槁
exit/b
:Unicode槁
set Unicode_Result=27073
exit/b
:Unicode27082
set Unicode_Result=槊
exit/b
:Unicode槊
set Unicode_Result=27082
exit/b
:Unicode27103
set Unicode_Result=槟
exit/b
:Unicode槟
set Unicode_Result=27103
exit/b
:Unicode27029
set Unicode_Result=榕
exit/b
:Unicode榕
set Unicode_Result=27029
exit/b
:Unicode27104
set Unicode_Result=槠
exit/b
:Unicode槠
set Unicode_Result=27104
exit/b
:Unicode27021
set Unicode_Result=榍
exit/b
:Unicode榍
set Unicode_Result=27021
exit/b
:Unicode27135
set Unicode_Result=槿
exit/b
:Unicode槿
set Unicode_Result=27135
exit/b
:Unicode27183
set Unicode_Result=樯
exit/b
:Unicode樯
set Unicode_Result=27183
exit/b
:Unicode27117
set Unicode_Result=槭
exit/b
:Unicode槭
set Unicode_Result=27117
exit/b
:Unicode27159
set Unicode_Result=樗
exit/b
:Unicode樗
set Unicode_Result=27159
exit/b
:Unicode27160
set Unicode_Result=樘
exit/b
:Unicode樘
set Unicode_Result=27160
exit/b
:Unicode27237
set Unicode_Result=橥
exit/b
:Unicode橥
set Unicode_Result=27237
exit/b
:Unicode27122
set Unicode_Result=槲
exit/b
:Unicode槲
set Unicode_Result=27122
exit/b
:Unicode27204
set Unicode_Result=橄
exit/b
:Unicode橄
set Unicode_Result=27204
exit/b
:Unicode27198
set Unicode_Result=樾
exit/b
:Unicode樾
set Unicode_Result=27198
exit/b
:Unicode27296
set Unicode_Result=檠
exit/b
:Unicode檠
set Unicode_Result=27296
exit/b
:Unicode27216
set Unicode_Result=橐
exit/b
:Unicode橐
set Unicode_Result=27216
exit/b
:Unicode27227
set Unicode_Result=橛
exit/b
:Unicode橛
set Unicode_Result=27227
exit/b
:Unicode27189
set Unicode_Result=樵
exit/b
:Unicode樵
set Unicode_Result=27189
exit/b
:Unicode27278
set Unicode_Result=檎
exit/b
:Unicode檎
set Unicode_Result=27278
exit/b
:Unicode27257
set Unicode_Result=橹
exit/b
:Unicode橹
set Unicode_Result=27257
exit/b
:Unicode27197
set Unicode_Result=樽
exit/b
:Unicode樽
set Unicode_Result=27197
exit/b
:Unicode27176
set Unicode_Result=樨
exit/b
:Unicode樨
set Unicode_Result=27176
exit/b
:Unicode27224
set Unicode_Result=橘
exit/b
:Unicode橘
set Unicode_Result=27224
exit/b
:Unicode27260
set Unicode_Result=橼
exit/b
:Unicode橼
set Unicode_Result=27260
exit/b
:Unicode27281
set Unicode_Result=檑
exit/b
:Unicode檑
set Unicode_Result=27281
exit/b
:Unicode27280
set Unicode_Result=檐
exit/b
:Unicode檐
set Unicode_Result=27280
exit/b
:Unicode27305
set Unicode_Result=檩
exit/b
:Unicode檩
set Unicode_Result=27305
exit/b
:Unicode27287
set Unicode_Result=檗
exit/b
:Unicode檗
set Unicode_Result=27287
exit/b
:Unicode27307
set Unicode_Result=檫
exit/b
:Unicode檫
set Unicode_Result=27307
exit/b
:Unicode29495
set Unicode_Result=猷
exit/b
:Unicode猷
set Unicode_Result=29495
exit/b
:Unicode29522
set Unicode_Result=獒
exit/b
:Unicode獒
set Unicode_Result=29522
exit/b
:Unicode27521
set Unicode_Result=殁
exit/b
:Unicode殁
set Unicode_Result=27521
exit/b
:Unicode27522
set Unicode_Result=殂
exit/b
:Unicode殂
set Unicode_Result=27522
exit/b
:Unicode27527
set Unicode_Result=殇
exit/b
:Unicode殇
set Unicode_Result=27527
exit/b
:Unicode27524
set Unicode_Result=殄
exit/b
:Unicode殄
set Unicode_Result=27524
exit/b
:Unicode27538
set Unicode_Result=殒
exit/b
:Unicode殒
set Unicode_Result=27538
exit/b
:Unicode27539
set Unicode_Result=殓
exit/b
:Unicode殓
set Unicode_Result=27539
exit/b
:Unicode27533
set Unicode_Result=殍
exit/b
:Unicode殍
set Unicode_Result=27533
exit/b
:Unicode27546
set Unicode_Result=殚
exit/b
:Unicode殚
set Unicode_Result=27546
exit/b
:Unicode27547
set Unicode_Result=殛
exit/b
:Unicode殛
set Unicode_Result=27547
exit/b
:Unicode27553
set Unicode_Result=殡
exit/b
:Unicode殡
set Unicode_Result=27553
exit/b
:Unicode27562
set Unicode_Result=殪
exit/b
:Unicode殪
set Unicode_Result=27562
exit/b
:Unicode36715
set Unicode_Result=轫
exit/b
:Unicode轫
set Unicode_Result=36715
exit/b
:Unicode36717
set Unicode_Result=轭
exit/b
:Unicode轭
set Unicode_Result=36717
exit/b
:Unicode36721
set Unicode_Result=轱
exit/b
:Unicode轱
set Unicode_Result=36721
exit/b
:Unicode36722
set Unicode_Result=轲
exit/b
:Unicode轲
set Unicode_Result=36722
exit/b
:Unicode36723
set Unicode_Result=轳
exit/b
:Unicode轳
set Unicode_Result=36723
exit/b
:Unicode36725
set Unicode_Result=轵
exit/b
:Unicode轵
set Unicode_Result=36725
exit/b
:Unicode36726
set Unicode_Result=轶
exit/b
:Unicode轶
set Unicode_Result=36726
exit/b
:Unicode36728
set Unicode_Result=轸
exit/b
:Unicode轸
set Unicode_Result=36728
exit/b
:Unicode36727
set Unicode_Result=轷
exit/b
:Unicode轷
set Unicode_Result=36727
exit/b
:Unicode36729
set Unicode_Result=轹
exit/b
:Unicode轹
set Unicode_Result=36729
exit/b
:Unicode36730
set Unicode_Result=轺
exit/b
:Unicode轺
set Unicode_Result=36730
exit/b
:Unicode36732
set Unicode_Result=轼
exit/b
:Unicode轼
set Unicode_Result=36732
exit/b
:Unicode36734
set Unicode_Result=轾
exit/b
:Unicode轾
set Unicode_Result=36734
exit/b
:Unicode36737
set Unicode_Result=辁
exit/b
:Unicode辁
set Unicode_Result=36737
exit/b
:Unicode36738
set Unicode_Result=辂
exit/b
:Unicode辂
set Unicode_Result=36738
exit/b
:Unicode36740
set Unicode_Result=辄
exit/b
:Unicode辄
set Unicode_Result=36740
exit/b
:Unicode36743
set Unicode_Result=辇
exit/b
:Unicode辇
set Unicode_Result=36743
exit/b
:Unicode36747
set Unicode_Result=辋
exit/b
:Unicode辋
set Unicode_Result=36747
exit/b
:Unicode36749
set Unicode_Result=辍
exit/b
:Unicode辍
set Unicode_Result=36749
exit/b
:Unicode36750
set Unicode_Result=辎
exit/b
:Unicode辎
set Unicode_Result=36750
exit/b
:Unicode36751
set Unicode_Result=辏
exit/b
:Unicode辏
set Unicode_Result=36751
exit/b
:Unicode36760
set Unicode_Result=辘
exit/b
:Unicode辘
set Unicode_Result=36760
exit/b
:Unicode36762
set Unicode_Result=辚
exit/b
:Unicode辚
set Unicode_Result=36762
exit/b
:Unicode36558
set Unicode_Result=軎
exit/b
:Unicode軎
set Unicode_Result=36558
exit/b
:Unicode25099
set Unicode_Result=戋
exit/b
:Unicode戋
set Unicode_Result=25099
exit/b
:Unicode25111
set Unicode_Result=戗
exit/b
:Unicode戗
set Unicode_Result=25111
exit/b
:Unicode25115
set Unicode_Result=戛
exit/b
:Unicode戛
set Unicode_Result=25115
exit/b
:Unicode25119
set Unicode_Result=戟
exit/b
:Unicode戟
set Unicode_Result=25119
exit/b
:Unicode25122
set Unicode_Result=戢
exit/b
:Unicode戢
set Unicode_Result=25122
exit/b
:Unicode25121
set Unicode_Result=戡
exit/b
:Unicode戡
set Unicode_Result=25121
exit/b
:Unicode25125
set Unicode_Result=戥
exit/b
:Unicode戥
set Unicode_Result=25125
exit/b
:Unicode25124
set Unicode_Result=戤
exit/b
:Unicode戤
set Unicode_Result=25124
exit/b
:Unicode25132
set Unicode_Result=戬
exit/b
:Unicode戬
set Unicode_Result=25132
exit/b
:Unicode33255
set Unicode_Result=臧
exit/b
:Unicode臧
set Unicode_Result=33255
exit/b
:Unicode29935
set Unicode_Result=瓯
exit/b
:Unicode瓯
set Unicode_Result=29935
exit/b
:Unicode29940
set Unicode_Result=瓴
exit/b
:Unicode瓴
set Unicode_Result=29940
exit/b
:Unicode29951
set Unicode_Result=瓿
exit/b
:Unicode瓿
set Unicode_Result=29951
exit/b
:Unicode29967
set Unicode_Result=甏
exit/b
:Unicode甏
set Unicode_Result=29967
exit/b
:Unicode29969
set Unicode_Result=甑
exit/b
:Unicode甑
set Unicode_Result=29969
exit/b
:Unicode29971
set Unicode_Result=甓
exit/b
:Unicode甓
set Unicode_Result=29971
exit/b
:Unicode25908
set Unicode_Result=攴
exit/b
:Unicode攴
set Unicode_Result=25908
exit/b
:Unicode26094
set Unicode_Result=旮
exit/b
:Unicode旮
set Unicode_Result=26094
exit/b
:Unicode26095
set Unicode_Result=旯
exit/b
:Unicode旯
set Unicode_Result=26095
exit/b
:Unicode26096
set Unicode_Result=旰
exit/b
:Unicode旰
set Unicode_Result=26096
exit/b
:Unicode26122
set Unicode_Result=昊
exit/b
:Unicode昊
set Unicode_Result=26122
exit/b
:Unicode26137
set Unicode_Result=昙
exit/b
:Unicode昙
set Unicode_Result=26137
exit/b
:Unicode26482
set Unicode_Result=杲
exit/b
:Unicode杲
set Unicode_Result=26482
exit/b
:Unicode26115
set Unicode_Result=昃
exit/b
:Unicode昃
set Unicode_Result=26115
exit/b
:Unicode26133
set Unicode_Result=昕
exit/b
:Unicode昕
set Unicode_Result=26133
exit/b
:Unicode26112
set Unicode_Result=昀
exit/b
:Unicode昀
set Unicode_Result=26112
exit/b
:Unicode28805
set Unicode_Result=炅
exit/b
:Unicode炅
set Unicode_Result=28805
exit/b
:Unicode26359
set Unicode_Result=曷
exit/b
:Unicode曷
set Unicode_Result=26359
exit/b
:Unicode26141
set Unicode_Result=昝
exit/b
:Unicode昝
set Unicode_Result=26141
exit/b
:Unicode26269
set Unicode_Result=暝
exit/b
:Unicode暝
set Unicode_Result=26269
exit/b
:Unicode26302
set Unicode_Result=暾
exit/b
:Unicode暾
set Unicode_Result=26302
exit/b
:Unicode26331
set Unicode_Result=曛
exit/b
:Unicode曛
set Unicode_Result=26331
exit/b
:Unicode26332
set Unicode_Result=曜
exit/b
:Unicode曜
set Unicode_Result=26332
exit/b
:Unicode26342
set Unicode_Result=曦
exit/b
:Unicode曦
set Unicode_Result=26342
exit/b
:Unicode26345
set Unicode_Result=曩
exit/b
:Unicode曩
set Unicode_Result=26345
exit/b
:Unicode36146
set Unicode_Result=贲
exit/b
:Unicode贲
set Unicode_Result=36146
exit/b
:Unicode36147
set Unicode_Result=贳
exit/b
:Unicode贳
set Unicode_Result=36147
exit/b
:Unicode36150
set Unicode_Result=贶
exit/b
:Unicode贶
set Unicode_Result=36150
exit/b
:Unicode36155
set Unicode_Result=贻
exit/b
:Unicode贻
set Unicode_Result=36155
exit/b
:Unicode36157
set Unicode_Result=贽
exit/b
:Unicode贽
set Unicode_Result=36157
exit/b
:Unicode36160
set Unicode_Result=赀
exit/b
:Unicode赀
set Unicode_Result=36160
exit/b
:Unicode36165
set Unicode_Result=赅
exit/b
:Unicode赅
set Unicode_Result=36165
exit/b
:Unicode36166
set Unicode_Result=赆
exit/b
:Unicode赆
set Unicode_Result=36166
exit/b
:Unicode36168
set Unicode_Result=赈
exit/b
:Unicode赈
set Unicode_Result=36168
exit/b
:Unicode36169
set Unicode_Result=赉
exit/b
:Unicode赉
set Unicode_Result=36169
exit/b
:Unicode36167
set Unicode_Result=赇
exit/b
:Unicode赇
set Unicode_Result=36167
exit/b
:Unicode36173
set Unicode_Result=赍
exit/b
:Unicode赍
set Unicode_Result=36173
exit/b
:Unicode36181
set Unicode_Result=赕
exit/b
:Unicode赕
set Unicode_Result=36181
exit/b
:Unicode36185
set Unicode_Result=赙
exit/b
:Unicode赙
set Unicode_Result=36185
exit/b
:Unicode35271
set Unicode_Result=觇
exit/b
:Unicode觇
set Unicode_Result=35271
exit/b
:Unicode35274
set Unicode_Result=觊
exit/b
:Unicode觊
set Unicode_Result=35274
exit/b
:Unicode35275
set Unicode_Result=觋
exit/b
:Unicode觋
set Unicode_Result=35275
exit/b
:Unicode35276
set Unicode_Result=觌
exit/b
:Unicode觌
set Unicode_Result=35276
exit/b
:Unicode35278
set Unicode_Result=觎
exit/b
:Unicode觎
set Unicode_Result=35278
exit/b
:Unicode35279
set Unicode_Result=觏
exit/b
:Unicode觏
set Unicode_Result=35279
exit/b
:Unicode35280
set Unicode_Result=觐
exit/b
:Unicode觐
set Unicode_Result=35280
exit/b
:Unicode35281
set Unicode_Result=觑
exit/b
:Unicode觑
set Unicode_Result=35281
exit/b
:Unicode29294
set Unicode_Result=牮
exit/b
:Unicode牮
set Unicode_Result=29294
exit/b
:Unicode29343
set Unicode_Result=犟
exit/b
:Unicode犟
set Unicode_Result=29343
exit/b
:Unicode29277
set Unicode_Result=牝
exit/b
:Unicode牝
set Unicode_Result=29277
exit/b
:Unicode29286
set Unicode_Result=牦
exit/b
:Unicode牦
set Unicode_Result=29286
exit/b
:Unicode29295
set Unicode_Result=牯
exit/b
:Unicode牯
set Unicode_Result=29295
exit/b
:Unicode29310
set Unicode_Result=牾
exit/b
:Unicode牾
set Unicode_Result=29310
exit/b
:Unicode29311
set Unicode_Result=牿
exit/b
:Unicode牿
set Unicode_Result=29311
exit/b
:Unicode29316
set Unicode_Result=犄
exit/b
:Unicode犄
set Unicode_Result=29316
exit/b
:Unicode29323
set Unicode_Result=犋
exit/b
:Unicode犋
set Unicode_Result=29323
exit/b
:Unicode29325
set Unicode_Result=犍
exit/b
:Unicode犍
set Unicode_Result=29325
exit/b
:Unicode29327
set Unicode_Result=犏
exit/b
:Unicode犏
set Unicode_Result=29327
exit/b
:Unicode29330
set Unicode_Result=犒
exit/b
:Unicode犒
set Unicode_Result=29330
exit/b
:Unicode25352
set Unicode_Result=挈
exit/b
:Unicode挈
set Unicode_Result=25352
exit/b
:Unicode25394
set Unicode_Result=挲
exit/b
:Unicode挲
set Unicode_Result=25394
exit/b
:Unicode25520
set Unicode_Result=掰
exit/b
:Unicode掰
set Unicode_Result=25520
exit/b
:Unicode25663
set Unicode_Result=搿
exit/b
:Unicode搿
set Unicode_Result=25663
exit/b
:Unicode25816
set Unicode_Result=擘
exit/b
:Unicode擘
set Unicode_Result=25816
exit/b
:Unicode32772
set Unicode_Result=耄
exit/b
:Unicode耄
set Unicode_Result=32772
exit/b
:Unicode27626
set Unicode_Result=毪
exit/b
:Unicode毪
set Unicode_Result=27626
exit/b
:Unicode27635
set Unicode_Result=毳
exit/b
:Unicode毳
set Unicode_Result=27635
exit/b
:Unicode27645
set Unicode_Result=毽
exit/b
:Unicode毽
set Unicode_Result=27645
exit/b
:Unicode27637
set Unicode_Result=毵
exit/b
:Unicode毵
set Unicode_Result=27637
exit/b
:Unicode27641
set Unicode_Result=毹
exit/b
:Unicode毹
set Unicode_Result=27641
exit/b
:Unicode27653
set Unicode_Result=氅
exit/b
:Unicode氅
set Unicode_Result=27653
exit/b
:Unicode27655
set Unicode_Result=氇
exit/b
:Unicode氇
set Unicode_Result=27655
exit/b
:Unicode27654
set Unicode_Result=氆
exit/b
:Unicode氆
set Unicode_Result=27654
exit/b
:Unicode27661
set Unicode_Result=氍
exit/b
:Unicode氍
set Unicode_Result=27661
exit/b
:Unicode27669
set Unicode_Result=氕
exit/b
:Unicode氕
set Unicode_Result=27669
exit/b
:Unicode27672
set Unicode_Result=氘
exit/b
:Unicode氘
set Unicode_Result=27672
exit/b
:Unicode27673
set Unicode_Result=氙
exit/b
:Unicode氙
set Unicode_Result=27673
exit/b
:Unicode27674
set Unicode_Result=氚
exit/b
:Unicode氚
set Unicode_Result=27674
exit/b
:Unicode27681
set Unicode_Result=氡
exit/b
:Unicode氡
set Unicode_Result=27681
exit/b
:Unicode27689
set Unicode_Result=氩
exit/b
:Unicode氩
set Unicode_Result=27689
exit/b
:Unicode27684
set Unicode_Result=氤
exit/b
:Unicode氤
set Unicode_Result=27684
exit/b
:Unicode27690
set Unicode_Result=氪
exit/b
:Unicode氪
set Unicode_Result=27690
exit/b
:Unicode27698
set Unicode_Result=氲
exit/b
:Unicode氲
set Unicode_Result=27698
exit/b
:Unicode25909
set Unicode_Result=攵
exit/b
:Unicode攵
set Unicode_Result=25909
exit/b
:Unicode25941
set Unicode_Result=敕
exit/b
:Unicode敕
set Unicode_Result=25941
exit/b
:Unicode25963
set Unicode_Result=敫
exit/b
:Unicode敫
set Unicode_Result=25963
exit/b
:Unicode29261
set Unicode_Result=牍
exit/b
:Unicode牍
set Unicode_Result=29261
exit/b
:Unicode29266
set Unicode_Result=牒
exit/b
:Unicode牒
set Unicode_Result=29266
exit/b
:Unicode29270
set Unicode_Result=牖
exit/b
:Unicode牖
set Unicode_Result=29270
exit/b
:Unicode29232
set Unicode_Result=爰
exit/b
:Unicode爰
set Unicode_Result=29232
exit/b
:Unicode34402
set Unicode_Result=虢
exit/b
:Unicode虢
set Unicode_Result=34402
exit/b
:Unicode21014
set Unicode_Result=刖
exit/b
:Unicode刖
set Unicode_Result=21014
exit/b
:Unicode32927
set Unicode_Result=肟
exit/b
:Unicode肟
set Unicode_Result=32927
exit/b
:Unicode32924
set Unicode_Result=肜
exit/b
:Unicode肜
set Unicode_Result=32924
exit/b
:Unicode32915
set Unicode_Result=肓
exit/b
:Unicode肓
set Unicode_Result=32915
exit/b
:Unicode32956
set Unicode_Result=肼
exit/b
:Unicode肼
set Unicode_Result=32956
exit/b
:Unicode26378
set Unicode_Result=朊
exit/b
:Unicode朊
set Unicode_Result=26378
exit/b
:Unicode32957
set Unicode_Result=肽
exit/b
:Unicode肽
set Unicode_Result=32957
exit/b
:Unicode32945
set Unicode_Result=肱
exit/b
:Unicode肱
set Unicode_Result=32945
exit/b
:Unicode32939
set Unicode_Result=肫
exit/b
:Unicode肫
set Unicode_Result=32939
exit/b
:Unicode32941
set Unicode_Result=肭
exit/b
:Unicode肭
set Unicode_Result=32941
exit/b
:Unicode32948
set Unicode_Result=肴
exit/b
:Unicode肴
set Unicode_Result=32948
exit/b
:Unicode32951
set Unicode_Result=肷
exit/b
:Unicode肷
set Unicode_Result=32951
exit/b
:Unicode32999
set Unicode_Result=胧
exit/b
:Unicode胧
set Unicode_Result=32999
exit/b
:Unicode33000
set Unicode_Result=胨
exit/b
:Unicode胨
set Unicode_Result=33000
exit/b
:Unicode33001
set Unicode_Result=胩
exit/b
:Unicode胩
set Unicode_Result=33001
exit/b
:Unicode33002
set Unicode_Result=胪
exit/b
:Unicode胪
set Unicode_Result=33002
exit/b
:Unicode32987
set Unicode_Result=胛
exit/b
:Unicode胛
set Unicode_Result=32987
exit/b
:Unicode32962
set Unicode_Result=胂
exit/b
:Unicode胂
set Unicode_Result=32962
exit/b
:Unicode32964
set Unicode_Result=胄
exit/b
:Unicode胄
set Unicode_Result=32964
exit/b
:Unicode32985
set Unicode_Result=胙
exit/b
:Unicode胙
set Unicode_Result=32985
exit/b
:Unicode32973
set Unicode_Result=胍
exit/b
:Unicode胍
set Unicode_Result=32973
exit/b
:Unicode32983
set Unicode_Result=胗
exit/b
:Unicode胗
set Unicode_Result=32983
exit/b
:Unicode26384
set Unicode_Result=朐
exit/b
:Unicode朐
set Unicode_Result=26384
exit/b
:Unicode32989
set Unicode_Result=胝
exit/b
:Unicode胝
set Unicode_Result=32989
exit/b
:Unicode33003
set Unicode_Result=胫
exit/b
:Unicode胫
set Unicode_Result=33003
exit/b
:Unicode33009
set Unicode_Result=胱
exit/b
:Unicode胱
set Unicode_Result=33009
exit/b
:Unicode33012
set Unicode_Result=胴
exit/b
:Unicode胴
set Unicode_Result=33012
exit/b
:Unicode33005
set Unicode_Result=胭
exit/b
:Unicode胭
set Unicode_Result=33005
exit/b
:Unicode33037
set Unicode_Result=脍
exit/b
:Unicode脍
set Unicode_Result=33037
exit/b
:Unicode33038
set Unicode_Result=脎
exit/b
:Unicode脎
set Unicode_Result=33038
exit/b
:Unicode33010
set Unicode_Result=胲
exit/b
:Unicode胲
set Unicode_Result=33010
exit/b
:Unicode33020
set Unicode_Result=胼
exit/b
:Unicode胼
set Unicode_Result=33020
exit/b
:Unicode26389
set Unicode_Result=朕
exit/b
:Unicode朕
set Unicode_Result=26389
exit/b
:Unicode33042
set Unicode_Result=脒
exit/b
:Unicode脒
set Unicode_Result=33042
exit/b
:Unicode35930
set Unicode_Result=豚
exit/b
:Unicode豚
set Unicode_Result=35930
exit/b
:Unicode33078
set Unicode_Result=脶
exit/b
:Unicode脶
set Unicode_Result=33078
exit/b
:Unicode33054
set Unicode_Result=脞
exit/b
:Unicode脞
set Unicode_Result=33054
exit/b
:Unicode33068
set Unicode_Result=脬
exit/b
:Unicode脬
set Unicode_Result=33068
exit/b
:Unicode33048
set Unicode_Result=脘
exit/b
:Unicode脘
set Unicode_Result=33048
exit/b
:Unicode33074
set Unicode_Result=脲
exit/b
:Unicode脲
set Unicode_Result=33074
exit/b
:Unicode33096
set Unicode_Result=腈
exit/b
:Unicode腈
set Unicode_Result=33096
exit/b
:Unicode33100
set Unicode_Result=腌
exit/b
:Unicode腌
set Unicode_Result=33100
exit/b
:Unicode33107
set Unicode_Result=腓
exit/b
:Unicode腓
set Unicode_Result=33107
exit/b
:Unicode33140
set Unicode_Result=腴
exit/b
:Unicode腴
set Unicode_Result=33140
exit/b
:Unicode33113
set Unicode_Result=腙
exit/b
:Unicode腙
set Unicode_Result=33113
exit/b
:Unicode33114
set Unicode_Result=腚
exit/b
:Unicode腚
set Unicode_Result=33114
exit/b
:Unicode33137
set Unicode_Result=腱
exit/b
:Unicode腱
set Unicode_Result=33137
exit/b
:Unicode33120
set Unicode_Result=腠
exit/b
:Unicode腠
set Unicode_Result=33120
exit/b
:Unicode33129
set Unicode_Result=腩
exit/b
:Unicode腩
set Unicode_Result=33129
exit/b
:Unicode33148
set Unicode_Result=腼
exit/b
:Unicode腼
set Unicode_Result=33148
exit/b
:Unicode33149
set Unicode_Result=腽
exit/b
:Unicode腽
set Unicode_Result=33149
exit/b
:Unicode33133
set Unicode_Result=腭
exit/b
:Unicode腭
set Unicode_Result=33133
exit/b
:Unicode33127
set Unicode_Result=腧
exit/b
:Unicode腧
set Unicode_Result=33127
exit/b
:Unicode22605
set Unicode_Result=塍
exit/b
:Unicode塍
set Unicode_Result=22605
exit/b
:Unicode23221
set Unicode_Result=媵
exit/b
:Unicode媵
set Unicode_Result=23221
exit/b
:Unicode33160
set Unicode_Result=膈
exit/b
:Unicode膈
set Unicode_Result=33160
exit/b
:Unicode33154
set Unicode_Result=膂
exit/b
:Unicode膂
set Unicode_Result=33154
exit/b
:Unicode33169
set Unicode_Result=膑
exit/b
:Unicode膑
set Unicode_Result=33169
exit/b
:Unicode28373
set Unicode_Result=滕
exit/b
:Unicode滕
set Unicode_Result=28373
exit/b
:Unicode33187
set Unicode_Result=膣
exit/b
:Unicode膣
set Unicode_Result=33187
exit/b
:Unicode33194
set Unicode_Result=膪
exit/b
:Unicode膪
set Unicode_Result=33194
exit/b
:Unicode33228
set Unicode_Result=臌
exit/b
:Unicode臌
set Unicode_Result=33228
exit/b
:Unicode26406
set Unicode_Result=朦
exit/b
:Unicode朦
set Unicode_Result=26406
exit/b
:Unicode33226
set Unicode_Result=臊
exit/b
:Unicode臊
set Unicode_Result=33226
exit/b
:Unicode33211
set Unicode_Result=膻
exit/b
:Unicode膻
set Unicode_Result=33211
exit/b
:Unicode33217
set Unicode_Result=臁
exit/b
:Unicode臁
set Unicode_Result=33217
exit/b
:Unicode33190
set Unicode_Result=膦
exit/b
:Unicode膦
set Unicode_Result=33190
exit/b
:Unicode27428
set Unicode_Result=欤
exit/b
:Unicode欤
set Unicode_Result=27428
exit/b
:Unicode27447
set Unicode_Result=欷
exit/b
:Unicode欷
set Unicode_Result=27447
exit/b
:Unicode27449
set Unicode_Result=欹
exit/b
:Unicode欹
set Unicode_Result=27449
exit/b
:Unicode27459
set Unicode_Result=歃
exit/b
:Unicode歃
set Unicode_Result=27459
exit/b
:Unicode27462
set Unicode_Result=歆
exit/b
:Unicode歆
set Unicode_Result=27462
exit/b
:Unicode27481
set Unicode_Result=歙
exit/b
:Unicode歙
set Unicode_Result=27481
exit/b
:Unicode39121
set Unicode_Result=飑
exit/b
:Unicode飑
set Unicode_Result=39121
exit/b
:Unicode39122
set Unicode_Result=飒
exit/b
:Unicode飒
set Unicode_Result=39122
exit/b
:Unicode39123
set Unicode_Result=飓
exit/b
:Unicode飓
set Unicode_Result=39123
exit/b
:Unicode39125
set Unicode_Result=飕
exit/b
:Unicode飕
set Unicode_Result=39125
exit/b
:Unicode39129
set Unicode_Result=飙
exit/b
:Unicode飙
set Unicode_Result=39129
exit/b
:Unicode39130
set Unicode_Result=飚
exit/b
:Unicode飚
set Unicode_Result=39130
exit/b
:Unicode27571
set Unicode_Result=殳
exit/b
:Unicode殳
set Unicode_Result=27571
exit/b
:Unicode24384
set Unicode_Result=彀
exit/b
:Unicode彀
set Unicode_Result=24384
exit/b
:Unicode27586
set Unicode_Result=毂
exit/b
:Unicode毂
set Unicode_Result=27586
exit/b
:Unicode35315
set Unicode_Result=觳
exit/b
:Unicode觳
set Unicode_Result=35315
exit/b
:Unicode26000
set Unicode_Result=斐
exit/b
:Unicode斐
set Unicode_Result=26000
exit/b
:Unicode40785
set Unicode_Result=齑
exit/b
:Unicode齑
set Unicode_Result=40785
exit/b
:Unicode26003
set Unicode_Result=斓
exit/b
:Unicode斓
set Unicode_Result=26003
exit/b
:Unicode26044
set Unicode_Result=於
exit/b
:Unicode於
set Unicode_Result=26044
exit/b
:Unicode26054
set Unicode_Result=旆
exit/b
:Unicode旆
set Unicode_Result=26054
exit/b
:Unicode26052
set Unicode_Result=旄
exit/b
:Unicode旄
set Unicode_Result=26052
exit/b
:Unicode26051
set Unicode_Result=旃
exit/b
:Unicode旃
set Unicode_Result=26051
exit/b
:Unicode26060
set Unicode_Result=旌
exit/b
:Unicode旌
set Unicode_Result=26060
exit/b
:Unicode26062
set Unicode_Result=旎
exit/b
:Unicode旎
set Unicode_Result=26062
exit/b
:Unicode26066
set Unicode_Result=旒
exit/b
:Unicode旒
set Unicode_Result=26066
exit/b
:Unicode26070
set Unicode_Result=旖
exit/b
:Unicode旖
set Unicode_Result=26070
exit/b
:Unicode28800
set Unicode_Result=炀
exit/b
:Unicode炀
set Unicode_Result=28800
exit/b
:Unicode28828
set Unicode_Result=炜
exit/b
:Unicode炜
set Unicode_Result=28828
exit/b
:Unicode28822
set Unicode_Result=炖
exit/b
:Unicode炖
set Unicode_Result=28822
exit/b
:Unicode28829
set Unicode_Result=炝
exit/b
:Unicode炝
set Unicode_Result=28829
exit/b
:Unicode28859
set Unicode_Result=炻
exit/b
:Unicode炻
set Unicode_Result=28859
exit/b
:Unicode28864
set Unicode_Result=烀
exit/b
:Unicode烀
set Unicode_Result=28864
exit/b
:Unicode28855
set Unicode_Result=炷
exit/b
:Unicode炷
set Unicode_Result=28855
exit/b
:Unicode28843
set Unicode_Result=炫
exit/b
:Unicode炫
set Unicode_Result=28843
exit/b
:Unicode28849
set Unicode_Result=炱
exit/b
:Unicode炱
set Unicode_Result=28849
exit/b
:Unicode28904
set Unicode_Result=烨
exit/b
:Unicode烨
set Unicode_Result=28904
exit/b
:Unicode28874
set Unicode_Result=烊
exit/b
:Unicode烊
set Unicode_Result=28874
exit/b
:Unicode28944
set Unicode_Result=焐
exit/b
:Unicode焐
set Unicode_Result=28944
exit/b
:Unicode28947
set Unicode_Result=焓
exit/b
:Unicode焓
set Unicode_Result=28947
exit/b
:Unicode28950
set Unicode_Result=焖
exit/b
:Unicode焖
set Unicode_Result=28950
exit/b
:Unicode28975
set Unicode_Result=焯
exit/b
:Unicode焯
set Unicode_Result=28975
exit/b
:Unicode28977
set Unicode_Result=焱
exit/b
:Unicode焱
set Unicode_Result=28977
exit/b
:Unicode29043
set Unicode_Result=煳
exit/b
:Unicode煳
set Unicode_Result=29043
exit/b
:Unicode29020
set Unicode_Result=煜
exit/b
:Unicode煜
set Unicode_Result=29020
exit/b
:Unicode29032
set Unicode_Result=煨
exit/b
:Unicode煨
set Unicode_Result=29032
exit/b
:Unicode28997
set Unicode_Result=煅
exit/b
:Unicode煅
set Unicode_Result=28997
exit/b
:Unicode29042
set Unicode_Result=煲
exit/b
:Unicode煲
set Unicode_Result=29042
exit/b
:Unicode29002
set Unicode_Result=煊
exit/b
:Unicode煊
set Unicode_Result=29002
exit/b
:Unicode29048
set Unicode_Result=煸
exit/b
:Unicode煸
set Unicode_Result=29048
exit/b
:Unicode29050
set Unicode_Result=煺
exit/b
:Unicode煺
set Unicode_Result=29050
exit/b
:Unicode29080
set Unicode_Result=熘
exit/b
:Unicode熘
set Unicode_Result=29080
exit/b
:Unicode29107
set Unicode_Result=熳
exit/b
:Unicode熳
set Unicode_Result=29107
exit/b
:Unicode29109
set Unicode_Result=熵
exit/b
:Unicode熵
set Unicode_Result=29109
exit/b
:Unicode29096
set Unicode_Result=熨
exit/b
:Unicode熨
set Unicode_Result=29096
exit/b
:Unicode29088
set Unicode_Result=熠
exit/b
:Unicode熠
set Unicode_Result=29088
exit/b
:Unicode29152
set Unicode_Result=燠
exit/b
:Unicode燠
set Unicode_Result=29152
exit/b
:Unicode29140
set Unicode_Result=燔
exit/b
:Unicode燔
set Unicode_Result=29140
exit/b
:Unicode29159
set Unicode_Result=燧
exit/b
:Unicode燧
set Unicode_Result=29159
exit/b
:Unicode29177
set Unicode_Result=燹
exit/b
:Unicode燹
set Unicode_Result=29177
exit/b
:Unicode29213
set Unicode_Result=爝
exit/b
:Unicode爝
set Unicode_Result=29213
exit/b
:Unicode29224
set Unicode_Result=爨
exit/b
:Unicode爨
set Unicode_Result=29224
exit/b
:Unicode28780
set Unicode_Result=灬
exit/b
:Unicode灬
set Unicode_Result=28780
exit/b
:Unicode28952
set Unicode_Result=焘
exit/b
:Unicode焘
set Unicode_Result=28952
exit/b
:Unicode29030
set Unicode_Result=煦
exit/b
:Unicode煦
set Unicode_Result=29030
exit/b
:Unicode29113
set Unicode_Result=熹
exit/b
:Unicode熹
set Unicode_Result=29113
exit/b
:Unicode25150
set Unicode_Result=戾
exit/b
:Unicode戾
set Unicode_Result=25150
exit/b
:Unicode25149
set Unicode_Result=戽
exit/b
:Unicode戽
set Unicode_Result=25149
exit/b
:Unicode25155
set Unicode_Result=扃
exit/b
:Unicode扃
set Unicode_Result=25155
exit/b
:Unicode25160
set Unicode_Result=扈
exit/b
:Unicode扈
set Unicode_Result=25160
exit/b
:Unicode25161
set Unicode_Result=扉
exit/b
:Unicode扉
set Unicode_Result=25161
exit/b
:Unicode31035
set Unicode_Result=礻
exit/b
:Unicode礻
set Unicode_Result=31035
exit/b
:Unicode31040
set Unicode_Result=祀
exit/b
:Unicode祀
set Unicode_Result=31040
exit/b
:Unicode31046
set Unicode_Result=祆
exit/b
:Unicode祆
set Unicode_Result=31046
exit/b
:Unicode31049
set Unicode_Result=祉
exit/b
:Unicode祉
set Unicode_Result=31049
exit/b
:Unicode31067
set Unicode_Result=祛
exit/b
:Unicode祛
set Unicode_Result=31067
exit/b
:Unicode31068
set Unicode_Result=祜
exit/b
:Unicode祜
set Unicode_Result=31068
exit/b
:Unicode31059
set Unicode_Result=祓
exit/b
:Unicode祓
set Unicode_Result=31059
exit/b
:Unicode31066
set Unicode_Result=祚
exit/b
:Unicode祚
set Unicode_Result=31066
exit/b
:Unicode31074
set Unicode_Result=祢
exit/b
:Unicode祢
set Unicode_Result=31074
exit/b
:Unicode31063
set Unicode_Result=祗
exit/b
:Unicode祗
set Unicode_Result=31063
exit/b
:Unicode31072
set Unicode_Result=祠
exit/b
:Unicode祠
set Unicode_Result=31072
exit/b
:Unicode31087
set Unicode_Result=祯
exit/b
:Unicode祯
set Unicode_Result=31087
exit/b
:Unicode31079
set Unicode_Result=祧
exit/b
:Unicode祧
set Unicode_Result=31079
exit/b
:Unicode31098
set Unicode_Result=祺
exit/b
:Unicode祺
set Unicode_Result=31098
exit/b
:Unicode31109
set Unicode_Result=禅
exit/b
:Unicode禅
set Unicode_Result=31109
exit/b
:Unicode31114
set Unicode_Result=禊
exit/b
:Unicode禊
set Unicode_Result=31114
exit/b
:Unicode31130
set Unicode_Result=禚
exit/b
:Unicode禚
set Unicode_Result=31130
exit/b
:Unicode31143
set Unicode_Result=禧
exit/b
:Unicode禧
set Unicode_Result=31143
exit/b
:Unicode31155
set Unicode_Result=禳
exit/b
:Unicode禳
set Unicode_Result=31155
exit/b
:Unicode24529
set Unicode_Result=忑
exit/b
:Unicode忑
set Unicode_Result=24529
exit/b
:Unicode24528
set Unicode_Result=忐
exit/b
:Unicode忐
set Unicode_Result=24528
exit/b
:Unicode24636
set Unicode_Result=怼
exit/b
:Unicode怼
set Unicode_Result=24636
exit/b
:Unicode24669
set Unicode_Result=恝
exit/b
:Unicode恝
set Unicode_Result=24669
exit/b
:Unicode24666
set Unicode_Result=恚
exit/b
:Unicode恚
set Unicode_Result=24666
exit/b
:Unicode24679
set Unicode_Result=恧
exit/b
:Unicode恧
set Unicode_Result=24679
exit/b
:Unicode24641
set Unicode_Result=恁
exit/b
:Unicode恁
set Unicode_Result=24641
exit/b
:Unicode24665
set Unicode_Result=恙
exit/b
:Unicode恙
set Unicode_Result=24665
exit/b
:Unicode24675
set Unicode_Result=恣
exit/b
:Unicode恣
set Unicode_Result=24675
exit/b
:Unicode24747
set Unicode_Result=悫
exit/b
:Unicode悫
set Unicode_Result=24747
exit/b
:Unicode24838
set Unicode_Result=愆
exit/b
:Unicode愆
set Unicode_Result=24838
exit/b
:Unicode24845
set Unicode_Result=愍
exit/b
:Unicode愍
set Unicode_Result=24845
exit/b
:Unicode24925
set Unicode_Result=慝
exit/b
:Unicode慝
set Unicode_Result=24925
exit/b
:Unicode25001
set Unicode_Result=憩
exit/b
:Unicode憩
set Unicode_Result=25001
exit/b
:Unicode24989
set Unicode_Result=憝
exit/b
:Unicode憝
set Unicode_Result=24989
exit/b
:Unicode25035
set Unicode_Result=懋
exit/b
:Unicode懋
set Unicode_Result=25035
exit/b
:Unicode25041
set Unicode_Result=懑
exit/b
:Unicode懑
set Unicode_Result=25041
exit/b
:Unicode25094
set Unicode_Result=戆
exit/b
:Unicode戆
set Unicode_Result=25094
exit/b
:Unicode32896
set Unicode_Result=肀
exit/b
:Unicode肀
set Unicode_Result=32896
exit/b
:Unicode32895
set Unicode_Result=聿
exit/b
:Unicode聿
set Unicode_Result=32895
exit/b
:Unicode27795
set Unicode_Result=沓
exit/b
:Unicode沓
set Unicode_Result=27795
exit/b
:Unicode27894
set Unicode_Result=泶
exit/b
:Unicode泶
set Unicode_Result=27894
exit/b
:Unicode28156
set Unicode_Result=淼
exit/b
:Unicode淼
set Unicode_Result=28156
exit/b
:Unicode30710
set Unicode_Result=矶
exit/b
:Unicode矶
set Unicode_Result=30710
exit/b
:Unicode30712
set Unicode_Result=矸
exit/b
:Unicode矸
set Unicode_Result=30712
exit/b
:Unicode30720
set Unicode_Result=砀
exit/b
:Unicode砀
set Unicode_Result=30720
exit/b
:Unicode30729
set Unicode_Result=砉
exit/b
:Unicode砉
set Unicode_Result=30729
exit/b
:Unicode30743
set Unicode_Result=砗
exit/b
:Unicode砗
set Unicode_Result=30743
exit/b
:Unicode30744
set Unicode_Result=砘
exit/b
:Unicode砘
set Unicode_Result=30744
exit/b
:Unicode30737
set Unicode_Result=砑
exit/b
:Unicode砑
set Unicode_Result=30737
exit/b
:Unicode26027
set Unicode_Result=斫
exit/b
:Unicode斫
set Unicode_Result=26027
exit/b
:Unicode30765
set Unicode_Result=砭
exit/b
:Unicode砭
set Unicode_Result=30765
exit/b
:Unicode30748
set Unicode_Result=砜
exit/b
:Unicode砜
set Unicode_Result=30748
exit/b
:Unicode30749
set Unicode_Result=砝
exit/b
:Unicode砝
set Unicode_Result=30749
exit/b
:Unicode30777
set Unicode_Result=砹
exit/b
:Unicode砹
set Unicode_Result=30777
exit/b
:Unicode30778
set Unicode_Result=砺
exit/b
:Unicode砺
set Unicode_Result=30778
exit/b
:Unicode30779
set Unicode_Result=砻
exit/b
:Unicode砻
set Unicode_Result=30779
exit/b
:Unicode30751
set Unicode_Result=砟
exit/b
:Unicode砟
set Unicode_Result=30751
exit/b
:Unicode30780
set Unicode_Result=砼
exit/b
:Unicode砼
set Unicode_Result=30780
exit/b
:Unicode30757
set Unicode_Result=砥
exit/b
:Unicode砥
set Unicode_Result=30757
exit/b
:Unicode30764
set Unicode_Result=砬
exit/b
:Unicode砬
set Unicode_Result=30764
exit/b
:Unicode30755
set Unicode_Result=砣
exit/b
:Unicode砣
set Unicode_Result=30755
exit/b
:Unicode30761
set Unicode_Result=砩
exit/b
:Unicode砩
set Unicode_Result=30761
exit/b
:Unicode30798
set Unicode_Result=硎
exit/b
:Unicode硎
set Unicode_Result=30798
exit/b
:Unicode30829
set Unicode_Result=硭
exit/b
:Unicode硭
set Unicode_Result=30829
exit/b
:Unicode30806
set Unicode_Result=硖
exit/b
:Unicode硖
set Unicode_Result=30806
exit/b
:Unicode30807
set Unicode_Result=硗
exit/b
:Unicode硗
set Unicode_Result=30807
exit/b
:Unicode30758
set Unicode_Result=砦
exit/b
:Unicode砦
set Unicode_Result=30758
exit/b
:Unicode30800
set Unicode_Result=硐
exit/b
:Unicode硐
set Unicode_Result=30800
exit/b
:Unicode30791
set Unicode_Result=硇
exit/b
:Unicode硇
set Unicode_Result=30791
exit/b
:Unicode30796
set Unicode_Result=硌
exit/b
:Unicode硌
set Unicode_Result=30796
exit/b
:Unicode30826
set Unicode_Result=硪
exit/b
:Unicode硪
set Unicode_Result=30826
exit/b
:Unicode30875
set Unicode_Result=碛
exit/b
:Unicode碛
set Unicode_Result=30875
exit/b
:Unicode30867
set Unicode_Result=碓
exit/b
:Unicode碓
set Unicode_Result=30867
exit/b
:Unicode30874
set Unicode_Result=碚
exit/b
:Unicode碚
set Unicode_Result=30874
exit/b
:Unicode30855
set Unicode_Result=碇
exit/b
:Unicode碇
set Unicode_Result=30855
exit/b
:Unicode30876
set Unicode_Result=碜
exit/b
:Unicode碜
set Unicode_Result=30876
exit/b
:Unicode30881
set Unicode_Result=碡
exit/b
:Unicode碡
set Unicode_Result=30881
exit/b
:Unicode30883
set Unicode_Result=碣
exit/b
:Unicode碣
set Unicode_Result=30883
exit/b
:Unicode30898
set Unicode_Result=碲
exit/b
:Unicode碲
set Unicode_Result=30898
exit/b
:Unicode30905
set Unicode_Result=碹
exit/b
:Unicode碹
set Unicode_Result=30905
exit/b
:Unicode30885
set Unicode_Result=碥
exit/b
:Unicode碥
set Unicode_Result=30885
exit/b
:Unicode30932
set Unicode_Result=磔
exit/b
:Unicode磔
set Unicode_Result=30932
exit/b
:Unicode30937
set Unicode_Result=磙
exit/b
:Unicode磙
set Unicode_Result=30937
exit/b
:Unicode30921
set Unicode_Result=磉
exit/b
:Unicode磉
set Unicode_Result=30921
exit/b
:Unicode30956
set Unicode_Result=磬
exit/b
:Unicode磬
set Unicode_Result=30956
exit/b
:Unicode30962
set Unicode_Result=磲
exit/b
:Unicode磲
set Unicode_Result=30962
exit/b
:Unicode30981
set Unicode_Result=礅
exit/b
:Unicode礅
set Unicode_Result=30981
exit/b
:Unicode30964
set Unicode_Result=磴
exit/b
:Unicode磴
set Unicode_Result=30964
exit/b
:Unicode30995
set Unicode_Result=礓
exit/b
:Unicode礓
set Unicode_Result=30995
exit/b
:Unicode31012
set Unicode_Result=礤
exit/b
:Unicode礤
set Unicode_Result=31012
exit/b
:Unicode31006
set Unicode_Result=礞
exit/b
:Unicode礞
set Unicode_Result=31006
exit/b
:Unicode31028
set Unicode_Result=礴
exit/b
:Unicode礴
set Unicode_Result=31028
exit/b
:Unicode40859
set Unicode_Result=龛
exit/b
:Unicode龛
set Unicode_Result=40859
exit/b
:Unicode40697
set Unicode_Result=黹
exit/b
:Unicode黹
set Unicode_Result=40697
exit/b
:Unicode40699
set Unicode_Result=黻
exit/b
:Unicode黻
set Unicode_Result=40699
exit/b
:Unicode40700
set Unicode_Result=黼
exit/b
:Unicode黼
set Unicode_Result=40700
exit/b
:Unicode30449
set Unicode_Result=盱
exit/b
:Unicode盱
set Unicode_Result=30449
exit/b
:Unicode30468
set Unicode_Result=眄
exit/b
:Unicode眄
set Unicode_Result=30468
exit/b
:Unicode30477
set Unicode_Result=眍
exit/b
:Unicode眍
set Unicode_Result=30477
exit/b
:Unicode30457
set Unicode_Result=盹
exit/b
:Unicode盹
set Unicode_Result=30457
exit/b
:Unicode30471
set Unicode_Result=眇
exit/b
:Unicode眇
set Unicode_Result=30471
exit/b
:Unicode30472
set Unicode_Result=眈
exit/b
:Unicode眈
set Unicode_Result=30472
exit/b
:Unicode30490
set Unicode_Result=眚
exit/b
:Unicode眚
set Unicode_Result=30490
exit/b
:Unicode30498
set Unicode_Result=眢
exit/b
:Unicode眢
set Unicode_Result=30498
exit/b
:Unicode30489
set Unicode_Result=眙
exit/b
:Unicode眙
set Unicode_Result=30489
exit/b
:Unicode30509
set Unicode_Result=眭
exit/b
:Unicode眭
set Unicode_Result=30509
exit/b
:Unicode30502
set Unicode_Result=眦
exit/b
:Unicode眦
set Unicode_Result=30502
exit/b
:Unicode30517
set Unicode_Result=眵
exit/b
:Unicode眵
set Unicode_Result=30517
exit/b
:Unicode30520
set Unicode_Result=眸
exit/b
:Unicode眸
set Unicode_Result=30520
exit/b
:Unicode30544
set Unicode_Result=睐
exit/b
:Unicode睐
set Unicode_Result=30544
exit/b
:Unicode30545
set Unicode_Result=睑
exit/b
:Unicode睑
set Unicode_Result=30545
exit/b
:Unicode30535
set Unicode_Result=睇
exit/b
:Unicode睇
set Unicode_Result=30535
exit/b
:Unicode30531
set Unicode_Result=睃
exit/b
:Unicode睃
set Unicode_Result=30531
exit/b
:Unicode30554
set Unicode_Result=睚
exit/b
:Unicode睚
set Unicode_Result=30554
exit/b
:Unicode30568
set Unicode_Result=睨
exit/b
:Unicode睨
set Unicode_Result=30568
exit/b
:Unicode30562
set Unicode_Result=睢
exit/b
:Unicode睢
set Unicode_Result=30562
exit/b
:Unicode30565
set Unicode_Result=睥
exit/b
:Unicode睥
set Unicode_Result=30565
exit/b
:Unicode30591
set Unicode_Result=睿
exit/b
:Unicode睿
set Unicode_Result=30591
exit/b
:Unicode30605
set Unicode_Result=瞍
exit/b
:Unicode瞍
set Unicode_Result=30605
exit/b
:Unicode30589
set Unicode_Result=睽
exit/b
:Unicode睽
set Unicode_Result=30589
exit/b
:Unicode30592
set Unicode_Result=瞀
exit/b
:Unicode瞀
set Unicode_Result=30592
exit/b
:Unicode30604
set Unicode_Result=瞌
exit/b
:Unicode瞌
set Unicode_Result=30604
exit/b
:Unicode30609
set Unicode_Result=瞑
exit/b
:Unicode瞑
set Unicode_Result=30609
exit/b
:Unicode30623
set Unicode_Result=瞟
exit/b
:Unicode瞟
set Unicode_Result=30623
exit/b
:Unicode30624
set Unicode_Result=瞠
exit/b
:Unicode瞠
set Unicode_Result=30624
exit/b
:Unicode30640
set Unicode_Result=瞰
exit/b
:Unicode瞰
set Unicode_Result=30640
exit/b
:Unicode30645
set Unicode_Result=瞵
exit/b
:Unicode瞵
set Unicode_Result=30645
exit/b
:Unicode30653
set Unicode_Result=瞽
exit/b
:Unicode瞽
set Unicode_Result=30653
exit/b
:Unicode30010
set Unicode_Result=町
exit/b
:Unicode町
set Unicode_Result=30010
exit/b
:Unicode30016
set Unicode_Result=畀
exit/b
:Unicode畀
set Unicode_Result=30016
exit/b
:Unicode30030
set Unicode_Result=畎
exit/b
:Unicode畎
set Unicode_Result=30030
exit/b
:Unicode30027
set Unicode_Result=畋
exit/b
:Unicode畋
set Unicode_Result=30027
exit/b
:Unicode30024
set Unicode_Result=畈
exit/b
:Unicode畈
set Unicode_Result=30024
exit/b
:Unicode30043
set Unicode_Result=畛
exit/b
:Unicode畛
set Unicode_Result=30043
exit/b
:Unicode30066
set Unicode_Result=畲
exit/b
:Unicode畲
set Unicode_Result=30066
exit/b
:Unicode30073
set Unicode_Result=畹
exit/b
:Unicode畹
set Unicode_Result=30073
exit/b
:Unicode30083
set Unicode_Result=疃
exit/b
:Unicode疃
set Unicode_Result=30083
exit/b
:Unicode32600
set Unicode_Result=罘
exit/b
:Unicode罘
set Unicode_Result=32600
exit/b
:Unicode32609
set Unicode_Result=罡
exit/b
:Unicode罡
set Unicode_Result=32609
exit/b
:Unicode32607
set Unicode_Result=罟
exit/b
:Unicode罟
set Unicode_Result=32607
exit/b
:Unicode35400
set Unicode_Result=詈
exit/b
:Unicode詈
set Unicode_Result=35400
exit/b
:Unicode32616
set Unicode_Result=罨
exit/b
:Unicode罨
set Unicode_Result=32616
exit/b
:Unicode32628
set Unicode_Result=罴
exit/b
:Unicode罴
set Unicode_Result=32628
exit/b
:Unicode32625
set Unicode_Result=罱
exit/b
:Unicode罱
set Unicode_Result=32625
exit/b
:Unicode32633
set Unicode_Result=罹
exit/b
:Unicode罹
set Unicode_Result=32633
exit/b
:Unicode32641
set Unicode_Result=羁
exit/b
:Unicode羁
set Unicode_Result=32641
exit/b
:Unicode32638
set Unicode_Result=罾
exit/b
:Unicode罾
set Unicode_Result=32638
exit/b
:Unicode30413
set Unicode_Result=盍
exit/b
:Unicode盍
set Unicode_Result=30413
exit/b
:Unicode30437
set Unicode_Result=盥
exit/b
:Unicode盥
set Unicode_Result=30437
exit/b
:Unicode34866
set Unicode_Result=蠲
exit/b
:Unicode蠲
set Unicode_Result=34866
exit/b
:Unicode38021
set Unicode_Result=钅
exit/b
:Unicode钅
set Unicode_Result=38021
exit/b
:Unicode38022
set Unicode_Result=钆
exit/b
:Unicode钆
set Unicode_Result=38022
exit/b
:Unicode38023
set Unicode_Result=钇
exit/b
:Unicode钇
set Unicode_Result=38023
exit/b
:Unicode38027
set Unicode_Result=钋
exit/b
:Unicode钋
set Unicode_Result=38027
exit/b
:Unicode38026
set Unicode_Result=钊
exit/b
:Unicode钊
set Unicode_Result=38026
exit/b
:Unicode38028
set Unicode_Result=钌
exit/b
:Unicode钌
set Unicode_Result=38028
exit/b
:Unicode38029
set Unicode_Result=钍
exit/b
:Unicode钍
set Unicode_Result=38029
exit/b
:Unicode38031
set Unicode_Result=钏
exit/b
:Unicode钏
set Unicode_Result=38031
exit/b
:Unicode38032
set Unicode_Result=钐
exit/b
:Unicode钐
set Unicode_Result=38032
exit/b
:Unicode38036
set Unicode_Result=钔
exit/b
:Unicode钔
set Unicode_Result=38036
exit/b
:Unicode38039
set Unicode_Result=钗
exit/b
:Unicode钗
set Unicode_Result=38039
exit/b
:Unicode38037
set Unicode_Result=钕
exit/b
:Unicode钕
set Unicode_Result=38037
exit/b
:Unicode38042
set Unicode_Result=钚
exit/b
:Unicode钚
set Unicode_Result=38042
exit/b
:Unicode38043
set Unicode_Result=钛
exit/b
:Unicode钛
set Unicode_Result=38043
exit/b
:Unicode38044
set Unicode_Result=钜
exit/b
:Unicode钜
set Unicode_Result=38044
exit/b
:Unicode38051
set Unicode_Result=钣
exit/b
:Unicode钣
set Unicode_Result=38051
exit/b
:Unicode38052
set Unicode_Result=钤
exit/b
:Unicode钤
set Unicode_Result=38052
exit/b
:Unicode38059
set Unicode_Result=钫
exit/b
:Unicode钫
set Unicode_Result=38059
exit/b
:Unicode38058
set Unicode_Result=钪
exit/b
:Unicode钪
set Unicode_Result=38058
exit/b
:Unicode38061
set Unicode_Result=钭
exit/b
:Unicode钭
set Unicode_Result=38061
exit/b
:Unicode38060
set Unicode_Result=钬
exit/b
:Unicode钬
set Unicode_Result=38060
exit/b
:Unicode38063
set Unicode_Result=钯
exit/b
:Unicode钯
set Unicode_Result=38063
exit/b
:Unicode38064
set Unicode_Result=钰
exit/b
:Unicode钰
set Unicode_Result=38064
exit/b
:Unicode38066
set Unicode_Result=钲
exit/b
:Unicode钲
set Unicode_Result=38066
exit/b
:Unicode38068
set Unicode_Result=钴
exit/b
:Unicode钴
set Unicode_Result=38068
exit/b
:Unicode38070
set Unicode_Result=钶
exit/b
:Unicode钶
set Unicode_Result=38070
exit/b
:Unicode38071
set Unicode_Result=钷
exit/b
:Unicode钷
set Unicode_Result=38071
exit/b
:Unicode38072
set Unicode_Result=钸
exit/b
:Unicode钸
set Unicode_Result=38072
exit/b
:Unicode38073
set Unicode_Result=钹
exit/b
:Unicode钹
set Unicode_Result=38073
exit/b
:Unicode38074
set Unicode_Result=钺
exit/b
:Unicode钺
set Unicode_Result=38074
exit/b
:Unicode38076
set Unicode_Result=钼
exit/b
:Unicode钼
set Unicode_Result=38076
exit/b
:Unicode38077
set Unicode_Result=钽
exit/b
:Unicode钽
set Unicode_Result=38077
exit/b
:Unicode38079
set Unicode_Result=钿
exit/b
:Unicode钿
set Unicode_Result=38079
exit/b
:Unicode38084
set Unicode_Result=铄
exit/b
:Unicode铄
set Unicode_Result=38084
exit/b
:Unicode38088
set Unicode_Result=铈
exit/b
:Unicode铈
set Unicode_Result=38088
exit/b
:Unicode38089
set Unicode_Result=铉
exit/b
:Unicode铉
set Unicode_Result=38089
exit/b
:Unicode38090
set Unicode_Result=铊
exit/b
:Unicode铊
set Unicode_Result=38090
exit/b
:Unicode38091
set Unicode_Result=铋
exit/b
:Unicode铋
set Unicode_Result=38091
exit/b
:Unicode38092
set Unicode_Result=铌
exit/b
:Unicode铌
set Unicode_Result=38092
exit/b
:Unicode38093
set Unicode_Result=铍
exit/b
:Unicode铍
set Unicode_Result=38093
exit/b
:Unicode38094
set Unicode_Result=铎
exit/b
:Unicode铎
set Unicode_Result=38094
exit/b
:Unicode38096
set Unicode_Result=铐
exit/b
:Unicode铐
set Unicode_Result=38096
exit/b
:Unicode38097
set Unicode_Result=铑
exit/b
:Unicode铑
set Unicode_Result=38097
exit/b
:Unicode38098
set Unicode_Result=铒
exit/b
:Unicode铒
set Unicode_Result=38098
exit/b
:Unicode38101
set Unicode_Result=铕
exit/b
:Unicode铕
set Unicode_Result=38101
exit/b
:Unicode38102
set Unicode_Result=铖
exit/b
:Unicode铖
set Unicode_Result=38102
exit/b
:Unicode38103
set Unicode_Result=铗
exit/b
:Unicode铗
set Unicode_Result=38103
exit/b
:Unicode38105
set Unicode_Result=铙
exit/b
:Unicode铙
set Unicode_Result=38105
exit/b
:Unicode38104
set Unicode_Result=铘
exit/b
:Unicode铘
set Unicode_Result=38104
exit/b
:Unicode38107
set Unicode_Result=铛
exit/b
:Unicode铛
set Unicode_Result=38107
exit/b
:Unicode38110
set Unicode_Result=铞
exit/b
:Unicode铞
set Unicode_Result=38110
exit/b
:Unicode38111
set Unicode_Result=铟
exit/b
:Unicode铟
set Unicode_Result=38111
exit/b
:Unicode38112
set Unicode_Result=铠
exit/b
:Unicode铠
set Unicode_Result=38112
exit/b
:Unicode38114
set Unicode_Result=铢
exit/b
:Unicode铢
set Unicode_Result=38114
exit/b
:Unicode38116
set Unicode_Result=铤
exit/b
:Unicode铤
set Unicode_Result=38116
exit/b
:Unicode38117
set Unicode_Result=铥
exit/b
:Unicode铥
set Unicode_Result=38117
exit/b
:Unicode38119
set Unicode_Result=铧
exit/b
:Unicode铧
set Unicode_Result=38119
exit/b
:Unicode38120
set Unicode_Result=铨
exit/b
:Unicode铨
set Unicode_Result=38120
exit/b
:Unicode38122
set Unicode_Result=铪
exit/b
:Unicode铪
set Unicode_Result=38122
exit/b
:Unicode38121
set Unicode_Result=铩
exit/b
:Unicode铩
set Unicode_Result=38121
exit/b
:Unicode38123
set Unicode_Result=铫
exit/b
:Unicode铫
set Unicode_Result=38123
exit/b
:Unicode38126
set Unicode_Result=铮
exit/b
:Unicode铮
set Unicode_Result=38126
exit/b
:Unicode38127
set Unicode_Result=铯
exit/b
:Unicode铯
set Unicode_Result=38127
exit/b
:Unicode38131
set Unicode_Result=铳
exit/b
:Unicode铳
set Unicode_Result=38131
exit/b
:Unicode38132
set Unicode_Result=铴
exit/b
:Unicode铴
set Unicode_Result=38132
exit/b
:Unicode38133
set Unicode_Result=铵
exit/b
:Unicode铵
set Unicode_Result=38133
exit/b
:Unicode38135
set Unicode_Result=铷
exit/b
:Unicode铷
set Unicode_Result=38135
exit/b
:Unicode38137
set Unicode_Result=铹
exit/b
:Unicode铹
set Unicode_Result=38137
exit/b
:Unicode38140
set Unicode_Result=铼
exit/b
:Unicode铼
set Unicode_Result=38140
exit/b
:Unicode38141
set Unicode_Result=铽
exit/b
:Unicode铽
set Unicode_Result=38141
exit/b
:Unicode38143
set Unicode_Result=铿
exit/b
:Unicode铿
set Unicode_Result=38143
exit/b
:Unicode38147
set Unicode_Result=锃
exit/b
:Unicode锃
set Unicode_Result=38147
exit/b
:Unicode38146
set Unicode_Result=锂
exit/b
:Unicode锂
set Unicode_Result=38146
exit/b
:Unicode38150
set Unicode_Result=锆
exit/b
:Unicode锆
set Unicode_Result=38150
exit/b
:Unicode38151
set Unicode_Result=锇
exit/b
:Unicode锇
set Unicode_Result=38151
exit/b
:Unicode38153
set Unicode_Result=锉
exit/b
:Unicode锉
set Unicode_Result=38153
exit/b
:Unicode38154
set Unicode_Result=锊
exit/b
:Unicode锊
set Unicode_Result=38154
exit/b
:Unicode38157
set Unicode_Result=锍
exit/b
:Unicode锍
set Unicode_Result=38157
exit/b
:Unicode38158
set Unicode_Result=锎
exit/b
:Unicode锎
set Unicode_Result=38158
exit/b
:Unicode38159
set Unicode_Result=锏
exit/b
:Unicode锏
set Unicode_Result=38159
exit/b
:Unicode38162
set Unicode_Result=锒
exit/b
:Unicode锒
set Unicode_Result=38162
exit/b
:Unicode38163
set Unicode_Result=锓
exit/b
:Unicode锓
set Unicode_Result=38163
exit/b
:Unicode38164
set Unicode_Result=锔
exit/b
:Unicode锔
set Unicode_Result=38164
exit/b
:Unicode38165
set Unicode_Result=锕
exit/b
:Unicode锕
set Unicode_Result=38165
exit/b
:Unicode38166
set Unicode_Result=锖
exit/b
:Unicode锖
set Unicode_Result=38166
exit/b
:Unicode38168
set Unicode_Result=锘
exit/b
:Unicode锘
set Unicode_Result=38168
exit/b
:Unicode38171
set Unicode_Result=锛
exit/b
:Unicode锛
set Unicode_Result=38171
exit/b
:Unicode38173
set Unicode_Result=锝
exit/b
:Unicode锝
set Unicode_Result=38173
exit/b
:Unicode38174
set Unicode_Result=锞
exit/b
:Unicode锞
set Unicode_Result=38174
exit/b
:Unicode38175
set Unicode_Result=锟
exit/b
:Unicode锟
set Unicode_Result=38175
exit/b
:Unicode38178
set Unicode_Result=锢
exit/b
:Unicode锢
set Unicode_Result=38178
exit/b
:Unicode38186
set Unicode_Result=锪
exit/b
:Unicode锪
set Unicode_Result=38186
exit/b
:Unicode38187
set Unicode_Result=锫
exit/b
:Unicode锫
set Unicode_Result=38187
exit/b
:Unicode38185
set Unicode_Result=锩
exit/b
:Unicode锩
set Unicode_Result=38185
exit/b
:Unicode38188
set Unicode_Result=锬
exit/b
:Unicode锬
set Unicode_Result=38188
exit/b
:Unicode38193
set Unicode_Result=锱
exit/b
:Unicode锱
set Unicode_Result=38193
exit/b
:Unicode38194
set Unicode_Result=锲
exit/b
:Unicode锲
set Unicode_Result=38194
exit/b
:Unicode38196
set Unicode_Result=锴
exit/b
:Unicode锴
set Unicode_Result=38196
exit/b
:Unicode38198
set Unicode_Result=锶
exit/b
:Unicode锶
set Unicode_Result=38198
exit/b
:Unicode38199
set Unicode_Result=锷
exit/b
:Unicode锷
set Unicode_Result=38199
exit/b
:Unicode38200
set Unicode_Result=锸
exit/b
:Unicode锸
set Unicode_Result=38200
exit/b
:Unicode38204
set Unicode_Result=锼
exit/b
:Unicode锼
set Unicode_Result=38204
exit/b
:Unicode38206
set Unicode_Result=锾
exit/b
:Unicode锾
set Unicode_Result=38206
exit/b
:Unicode38207
set Unicode_Result=锿
exit/b
:Unicode锿
set Unicode_Result=38207
exit/b
:Unicode38210
set Unicode_Result=镂
exit/b
:Unicode镂
set Unicode_Result=38210
exit/b
:Unicode38197
set Unicode_Result=锵
exit/b
:Unicode锵
set Unicode_Result=38197
exit/b
:Unicode38212
set Unicode_Result=镄
exit/b
:Unicode镄
set Unicode_Result=38212
exit/b
:Unicode38213
set Unicode_Result=镅
exit/b
:Unicode镅
set Unicode_Result=38213
exit/b
:Unicode38214
set Unicode_Result=镆
exit/b
:Unicode镆
set Unicode_Result=38214
exit/b
:Unicode38217
set Unicode_Result=镉
exit/b
:Unicode镉
set Unicode_Result=38217
exit/b
:Unicode38220
set Unicode_Result=镌
exit/b
:Unicode镌
set Unicode_Result=38220
exit/b
:Unicode38222
set Unicode_Result=镎
exit/b
:Unicode镎
set Unicode_Result=38222
exit/b
:Unicode38223
set Unicode_Result=镏
exit/b
:Unicode镏
set Unicode_Result=38223
exit/b
:Unicode38226
set Unicode_Result=镒
exit/b
:Unicode镒
set Unicode_Result=38226
exit/b
:Unicode38227
set Unicode_Result=镓
exit/b
:Unicode镓
set Unicode_Result=38227
exit/b
:Unicode38228
set Unicode_Result=镔
exit/b
:Unicode镔
set Unicode_Result=38228
exit/b
:Unicode38230
set Unicode_Result=镖
exit/b
:Unicode镖
set Unicode_Result=38230
exit/b
:Unicode38231
set Unicode_Result=镗
exit/b
:Unicode镗
set Unicode_Result=38231
exit/b
:Unicode38232
set Unicode_Result=镘
exit/b
:Unicode镘
set Unicode_Result=38232
exit/b
:Unicode38233
set Unicode_Result=镙
exit/b
:Unicode镙
set Unicode_Result=38233
exit/b
:Unicode38235
set Unicode_Result=镛
exit/b
:Unicode镛
set Unicode_Result=38235
exit/b
:Unicode38238
set Unicode_Result=镞
exit/b
:Unicode镞
set Unicode_Result=38238
exit/b
:Unicode38239
set Unicode_Result=镟
exit/b
:Unicode镟
set Unicode_Result=38239
exit/b
:Unicode38237
set Unicode_Result=镝
exit/b
:Unicode镝
set Unicode_Result=38237
exit/b
:Unicode38241
set Unicode_Result=镡
exit/b
:Unicode镡
set Unicode_Result=38241
exit/b
:Unicode38242
set Unicode_Result=镢
exit/b
:Unicode镢
set Unicode_Result=38242
exit/b
:Unicode38244
set Unicode_Result=镤
exit/b
:Unicode镤
set Unicode_Result=38244
exit/b
:Unicode38245
set Unicode_Result=镥
exit/b
:Unicode镥
set Unicode_Result=38245
exit/b
:Unicode38246
set Unicode_Result=镦
exit/b
:Unicode镦
set Unicode_Result=38246
exit/b
:Unicode38247
set Unicode_Result=镧
exit/b
:Unicode镧
set Unicode_Result=38247
exit/b
:Unicode38248
set Unicode_Result=镨
exit/b
:Unicode镨
set Unicode_Result=38248
exit/b
:Unicode38249
set Unicode_Result=镩
exit/b
:Unicode镩
set Unicode_Result=38249
exit/b
:Unicode38250
set Unicode_Result=镪
exit/b
:Unicode镪
set Unicode_Result=38250
exit/b
:Unicode38251
set Unicode_Result=镫
exit/b
:Unicode镫
set Unicode_Result=38251
exit/b
:Unicode38252
set Unicode_Result=镬
exit/b
:Unicode镬
set Unicode_Result=38252
exit/b
:Unicode38255
set Unicode_Result=镯
exit/b
:Unicode镯
set Unicode_Result=38255
exit/b
:Unicode38257
set Unicode_Result=镱
exit/b
:Unicode镱
set Unicode_Result=38257
exit/b
:Unicode38258
set Unicode_Result=镲
exit/b
:Unicode镲
set Unicode_Result=38258
exit/b
:Unicode38259
set Unicode_Result=镳
exit/b
:Unicode镳
set Unicode_Result=38259
exit/b
:Unicode38202
set Unicode_Result=锺
exit/b
:Unicode锺
set Unicode_Result=38202
exit/b
:Unicode30695
set Unicode_Result=矧
exit/b
:Unicode矧
set Unicode_Result=30695
exit/b
:Unicode30700
set Unicode_Result=矬
exit/b
:Unicode矬
set Unicode_Result=30700
exit/b
:Unicode38601
set Unicode_Result=雉
exit/b
:Unicode雉
set Unicode_Result=38601
exit/b
:Unicode31189
set Unicode_Result=秕
exit/b
:Unicode秕
set Unicode_Result=31189
exit/b
:Unicode31213
set Unicode_Result=秭
exit/b
:Unicode秭
set Unicode_Result=31213
exit/b
:Unicode31203
set Unicode_Result=秣
exit/b
:Unicode秣
set Unicode_Result=31203
exit/b
:Unicode31211
set Unicode_Result=秫
exit/b
:Unicode秫
set Unicode_Result=31211
exit/b
:Unicode31238
set Unicode_Result=稆
exit/b
:Unicode稆
set Unicode_Result=31238
exit/b
:Unicode23879
set Unicode_Result=嵇
exit/b
:Unicode嵇
set Unicode_Result=23879
exit/b
:Unicode31235
set Unicode_Result=稃
exit/b
:Unicode稃
set Unicode_Result=31235
exit/b
:Unicode31234
set Unicode_Result=稂
exit/b
:Unicode稂
set Unicode_Result=31234
exit/b
:Unicode31262
set Unicode_Result=稞
exit/b
:Unicode稞
set Unicode_Result=31262
exit/b
:Unicode31252
set Unicode_Result=稔
exit/b
:Unicode稔
set Unicode_Result=31252
exit/b
:Unicode31289
set Unicode_Result=稹
exit/b
:Unicode稹
set Unicode_Result=31289
exit/b
:Unicode31287
set Unicode_Result=稷
exit/b
:Unicode稷
set Unicode_Result=31287
exit/b
:Unicode31313
set Unicode_Result=穑
exit/b
:Unicode穑
set Unicode_Result=31313
exit/b
:Unicode40655
set Unicode_Result=黏
exit/b
:Unicode黏
set Unicode_Result=40655
exit/b
:Unicode39333
set Unicode_Result=馥
exit/b
:Unicode馥
set Unicode_Result=39333
exit/b
:Unicode31344
set Unicode_Result=穰
exit/b
:Unicode穰
set Unicode_Result=31344
exit/b
:Unicode30344
set Unicode_Result=皈
exit/b
:Unicode皈
set Unicode_Result=30344
exit/b
:Unicode30350
set Unicode_Result=皎
exit/b
:Unicode皎
set Unicode_Result=30350
exit/b
:Unicode30355
set Unicode_Result=皓
exit/b
:Unicode皓
set Unicode_Result=30355
exit/b
:Unicode30361
set Unicode_Result=皙
exit/b
:Unicode皙
set Unicode_Result=30361
exit/b
:Unicode30372
set Unicode_Result=皤
exit/b
:Unicode皤
set Unicode_Result=30372
exit/b
:Unicode29918
set Unicode_Result=瓞
exit/b
:Unicode瓞
set Unicode_Result=29918
exit/b
:Unicode29920
set Unicode_Result=瓠
exit/b
:Unicode瓠
set Unicode_Result=29920
exit/b
:Unicode29996
set Unicode_Result=甬
exit/b
:Unicode甬
set Unicode_Result=29996
exit/b
:Unicode40480
set Unicode_Result=鸠
exit/b
:Unicode鸠
set Unicode_Result=40480
exit/b
:Unicode40482
set Unicode_Result=鸢
exit/b
:Unicode鸢
set Unicode_Result=40482
exit/b
:Unicode40488
set Unicode_Result=鸨
exit/b
:Unicode鸨
set Unicode_Result=40488
exit/b
:Unicode40489
set Unicode_Result=鸩
exit/b
:Unicode鸩
set Unicode_Result=40489
exit/b
:Unicode40490
set Unicode_Result=鸪
exit/b
:Unicode鸪
set Unicode_Result=40490
exit/b
:Unicode40491
set Unicode_Result=鸫
exit/b
:Unicode鸫
set Unicode_Result=40491
exit/b
:Unicode40492
set Unicode_Result=鸬
exit/b
:Unicode鸬
set Unicode_Result=40492
exit/b
:Unicode40498
set Unicode_Result=鸲
exit/b
:Unicode鸲
set Unicode_Result=40498
exit/b
:Unicode40497
set Unicode_Result=鸱
exit/b
:Unicode鸱
set Unicode_Result=40497
exit/b
:Unicode40502
set Unicode_Result=鸶
exit/b
:Unicode鸶
set Unicode_Result=40502
exit/b
:Unicode40504
set Unicode_Result=鸸
exit/b
:Unicode鸸
set Unicode_Result=40504
exit/b
:Unicode40503
set Unicode_Result=鸷
exit/b
:Unicode鸷
set Unicode_Result=40503
exit/b
:Unicode40505
set Unicode_Result=鸹
exit/b
:Unicode鸹
set Unicode_Result=40505
exit/b
:Unicode40506
set Unicode_Result=鸺
exit/b
:Unicode鸺
set Unicode_Result=40506
exit/b
:Unicode40510
set Unicode_Result=鸾
exit/b
:Unicode鸾
set Unicode_Result=40510
exit/b
:Unicode40513
set Unicode_Result=鹁
exit/b
:Unicode鹁
set Unicode_Result=40513
exit/b
:Unicode40514
set Unicode_Result=鹂
exit/b
:Unicode鹂
set Unicode_Result=40514
exit/b
:Unicode40516
set Unicode_Result=鹄
exit/b
:Unicode鹄
set Unicode_Result=40516
exit/b
:Unicode40518
set Unicode_Result=鹆
exit/b
:Unicode鹆
set Unicode_Result=40518
exit/b
:Unicode40519
set Unicode_Result=鹇
exit/b
:Unicode鹇
set Unicode_Result=40519
exit/b
:Unicode40520
set Unicode_Result=鹈
exit/b
:Unicode鹈
set Unicode_Result=40520
exit/b
:Unicode40521
set Unicode_Result=鹉
exit/b
:Unicode鹉
set Unicode_Result=40521
exit/b
:Unicode40523
set Unicode_Result=鹋
exit/b
:Unicode鹋
set Unicode_Result=40523
exit/b
:Unicode40524
set Unicode_Result=鹌
exit/b
:Unicode鹌
set Unicode_Result=40524
exit/b
:Unicode40526
set Unicode_Result=鹎
exit/b
:Unicode鹎
set Unicode_Result=40526
exit/b
:Unicode40529
set Unicode_Result=鹑
exit/b
:Unicode鹑
set Unicode_Result=40529
exit/b
:Unicode40533
set Unicode_Result=鹕
exit/b
:Unicode鹕
set Unicode_Result=40533
exit/b
:Unicode40535
set Unicode_Result=鹗
exit/b
:Unicode鹗
set Unicode_Result=40535
exit/b
:Unicode40538
set Unicode_Result=鹚
exit/b
:Unicode鹚
set Unicode_Result=40538
exit/b
:Unicode40539
set Unicode_Result=鹛
exit/b
:Unicode鹛
set Unicode_Result=40539
exit/b
:Unicode40540
set Unicode_Result=鹜
exit/b
:Unicode鹜
set Unicode_Result=40540
exit/b
:Unicode40542
set Unicode_Result=鹞
exit/b
:Unicode鹞
set Unicode_Result=40542
exit/b
:Unicode40547
set Unicode_Result=鹣
exit/b
:Unicode鹣
set Unicode_Result=40547
exit/b
:Unicode40550
set Unicode_Result=鹦
exit/b
:Unicode鹦
set Unicode_Result=40550
exit/b
:Unicode40551
set Unicode_Result=鹧
exit/b
:Unicode鹧
set Unicode_Result=40551
exit/b
:Unicode40552
set Unicode_Result=鹨
exit/b
:Unicode鹨
set Unicode_Result=40552
exit/b
:Unicode40553
set Unicode_Result=鹩
exit/b
:Unicode鹩
set Unicode_Result=40553
exit/b
:Unicode40554
set Unicode_Result=鹪
exit/b
:Unicode鹪
set Unicode_Result=40554
exit/b
:Unicode40555
set Unicode_Result=鹫
exit/b
:Unicode鹫
set Unicode_Result=40555
exit/b
:Unicode40556
set Unicode_Result=鹬
exit/b
:Unicode鹬
set Unicode_Result=40556
exit/b
:Unicode40561
set Unicode_Result=鹱
exit/b
:Unicode鹱
set Unicode_Result=40561
exit/b
:Unicode40557
set Unicode_Result=鹭
exit/b
:Unicode鹭
set Unicode_Result=40557
exit/b
:Unicode40563
set Unicode_Result=鹳
exit/b
:Unicode鹳
set Unicode_Result=40563
exit/b
:Unicode30098
set Unicode_Result=疒
exit/b
:Unicode疒
set Unicode_Result=30098
exit/b
:Unicode30100
set Unicode_Result=疔
exit/b
:Unicode疔
set Unicode_Result=30100
exit/b
:Unicode30102
set Unicode_Result=疖
exit/b
:Unicode疖
set Unicode_Result=30102
exit/b
:Unicode30112
set Unicode_Result=疠
exit/b
:Unicode疠
set Unicode_Result=30112
exit/b
:Unicode30109
set Unicode_Result=疝
exit/b
:Unicode疝
set Unicode_Result=30109
exit/b
:Unicode30124
set Unicode_Result=疬
exit/b
:Unicode疬
set Unicode_Result=30124
exit/b
:Unicode30115
set Unicode_Result=疣
exit/b
:Unicode疣
set Unicode_Result=30115
exit/b
:Unicode30131
set Unicode_Result=疳
exit/b
:Unicode疳
set Unicode_Result=30131
exit/b
:Unicode30132
set Unicode_Result=疴
exit/b
:Unicode疴
set Unicode_Result=30132
exit/b
:Unicode30136
set Unicode_Result=疸
exit/b
:Unicode疸
set Unicode_Result=30136
exit/b
:Unicode30148
set Unicode_Result=痄
exit/b
:Unicode痄
set Unicode_Result=30148
exit/b
:Unicode30129
set Unicode_Result=疱
exit/b
:Unicode疱
set Unicode_Result=30129
exit/b
:Unicode30128
set Unicode_Result=疰
exit/b
:Unicode疰
set Unicode_Result=30128
exit/b
:Unicode30147
set Unicode_Result=痃
exit/b
:Unicode痃
set Unicode_Result=30147
exit/b
:Unicode30146
set Unicode_Result=痂
exit/b
:Unicode痂
set Unicode_Result=30146
exit/b
:Unicode30166
set Unicode_Result=痖
exit/b
:Unicode痖
set Unicode_Result=30166
exit/b
:Unicode30157
set Unicode_Result=痍
exit/b
:Unicode痍
set Unicode_Result=30157
exit/b
:Unicode30179
set Unicode_Result=痣
exit/b
:Unicode痣
set Unicode_Result=30179
exit/b
:Unicode30184
set Unicode_Result=痨
exit/b
:Unicode痨
set Unicode_Result=30184
exit/b
:Unicode30182
set Unicode_Result=痦
exit/b
:Unicode痦
set Unicode_Result=30182
exit/b
:Unicode30180
set Unicode_Result=痤
exit/b
:Unicode痤
set Unicode_Result=30180
exit/b
:Unicode30187
set Unicode_Result=痫
exit/b
:Unicode痫
set Unicode_Result=30187
exit/b
:Unicode30183
set Unicode_Result=痧
exit/b
:Unicode痧
set Unicode_Result=30183
exit/b
:Unicode30211
set Unicode_Result=瘃
exit/b
:Unicode瘃
set Unicode_Result=30211
exit/b
:Unicode30193
set Unicode_Result=痱
exit/b
:Unicode痱
set Unicode_Result=30193
exit/b
:Unicode30204
set Unicode_Result=痼
exit/b
:Unicode痼
set Unicode_Result=30204
exit/b
:Unicode30207
set Unicode_Result=痿
exit/b
:Unicode痿
set Unicode_Result=30207
exit/b
:Unicode30224
set Unicode_Result=瘐
exit/b
:Unicode瘐
set Unicode_Result=30224
exit/b
:Unicode30208
set Unicode_Result=瘀
exit/b
:Unicode瘀
set Unicode_Result=30208
exit/b
:Unicode30213
set Unicode_Result=瘅
exit/b
:Unicode瘅
set Unicode_Result=30213
exit/b
:Unicode30220
set Unicode_Result=瘌
exit/b
:Unicode瘌
set Unicode_Result=30220
exit/b
:Unicode30231
set Unicode_Result=瘗
exit/b
:Unicode瘗
set Unicode_Result=30231
exit/b
:Unicode30218
set Unicode_Result=瘊
exit/b
:Unicode瘊
set Unicode_Result=30218
exit/b
:Unicode30245
set Unicode_Result=瘥
exit/b
:Unicode瘥
set Unicode_Result=30245
exit/b
:Unicode30232
set Unicode_Result=瘘
exit/b
:Unicode瘘
set Unicode_Result=30232
exit/b
:Unicode30229
set Unicode_Result=瘕
exit/b
:Unicode瘕
set Unicode_Result=30229
exit/b
:Unicode30233
set Unicode_Result=瘙
exit/b
:Unicode瘙
set Unicode_Result=30233
exit/b
:Unicode30235
set Unicode_Result=瘛
exit/b
:Unicode瘛
set Unicode_Result=30235
exit/b
:Unicode30268
set Unicode_Result=瘼
exit/b
:Unicode瘼
set Unicode_Result=30268
exit/b
:Unicode30242
set Unicode_Result=瘢
exit/b
:Unicode瘢
set Unicode_Result=30242
exit/b
:Unicode30240
set Unicode_Result=瘠
exit/b
:Unicode瘠
set Unicode_Result=30240
exit/b
:Unicode30272
set Unicode_Result=癀
exit/b
:Unicode癀
set Unicode_Result=30272
exit/b
:Unicode30253
set Unicode_Result=瘭
exit/b
:Unicode瘭
set Unicode_Result=30253
exit/b
:Unicode30256
set Unicode_Result=瘰
exit/b
:Unicode瘰
set Unicode_Result=30256
exit/b
:Unicode30271
set Unicode_Result=瘿
exit/b
:Unicode瘿
set Unicode_Result=30271
exit/b
:Unicode30261
set Unicode_Result=瘵
exit/b
:Unicode瘵
set Unicode_Result=30261
exit/b
:Unicode30275
set Unicode_Result=癃
exit/b
:Unicode癃
set Unicode_Result=30275
exit/b
:Unicode30270
set Unicode_Result=瘾
exit/b
:Unicode瘾
set Unicode_Result=30270
exit/b
:Unicode30259
set Unicode_Result=瘳
exit/b
:Unicode瘳
set Unicode_Result=30259
exit/b
:Unicode30285
set Unicode_Result=癍
exit/b
:Unicode癍
set Unicode_Result=30285
exit/b
:Unicode30302
set Unicode_Result=癞
exit/b
:Unicode癞
set Unicode_Result=30302
exit/b
:Unicode30292
set Unicode_Result=癔
exit/b
:Unicode癔
set Unicode_Result=30292
exit/b
:Unicode30300
set Unicode_Result=癜
exit/b
:Unicode癜
set Unicode_Result=30300
exit/b
:Unicode30294
set Unicode_Result=癖
exit/b
:Unicode癖
set Unicode_Result=30294
exit/b
:Unicode30315
set Unicode_Result=癫
exit/b
:Unicode癫
set Unicode_Result=30315
exit/b
:Unicode30319
set Unicode_Result=癯
exit/b
:Unicode癯
set Unicode_Result=30319
exit/b
:Unicode32714
set Unicode_Result=翊
exit/b
:Unicode翊
set Unicode_Result=32714
exit/b
:Unicode31462
set Unicode_Result=竦
exit/b
:Unicode竦
set Unicode_Result=31462
exit/b
:Unicode31352
set Unicode_Result=穸
exit/b
:Unicode穸
set Unicode_Result=31352
exit/b
:Unicode31353
set Unicode_Result=穹
exit/b
:Unicode穹
set Unicode_Result=31353
exit/b
:Unicode31360
set Unicode_Result=窀
exit/b
:Unicode窀
set Unicode_Result=31360
exit/b
:Unicode31366
set Unicode_Result=窆
exit/b
:Unicode窆
set Unicode_Result=31366
exit/b
:Unicode31368
set Unicode_Result=窈
exit/b
:Unicode窈
set Unicode_Result=31368
exit/b
:Unicode31381
set Unicode_Result=窕
exit/b
:Unicode窕
set Unicode_Result=31381
exit/b
:Unicode31398
set Unicode_Result=窦
exit/b
:Unicode窦
set Unicode_Result=31398
exit/b
:Unicode31392
set Unicode_Result=窠
exit/b
:Unicode窠
set Unicode_Result=31392
exit/b
:Unicode31404
set Unicode_Result=窬
exit/b
:Unicode窬
set Unicode_Result=31404
exit/b
:Unicode31400
set Unicode_Result=窨
exit/b
:Unicode窨
set Unicode_Result=31400
exit/b
:Unicode31405
set Unicode_Result=窭
exit/b
:Unicode窭
set Unicode_Result=31405
exit/b
:Unicode31411
set Unicode_Result=窳
exit/b
:Unicode窳
set Unicode_Result=31411
exit/b
:Unicode34916
set Unicode_Result=衤
exit/b
:Unicode衤
set Unicode_Result=34916
exit/b
:Unicode34921
set Unicode_Result=衩
exit/b
:Unicode衩
set Unicode_Result=34921
exit/b
:Unicode34930
set Unicode_Result=衲
exit/b
:Unicode衲
set Unicode_Result=34930
exit/b
:Unicode34941
set Unicode_Result=衽
exit/b
:Unicode衽
set Unicode_Result=34941
exit/b
:Unicode34943
set Unicode_Result=衿
exit/b
:Unicode衿
set Unicode_Result=34943
exit/b
:Unicode34946
set Unicode_Result=袂
exit/b
:Unicode袂
set Unicode_Result=34946
exit/b
:Unicode34978
set Unicode_Result=袢
exit/b
:Unicode袢
set Unicode_Result=34978
exit/b
:Unicode35014
set Unicode_Result=裆
exit/b
:Unicode裆
set Unicode_Result=35014
exit/b
:Unicode34999
set Unicode_Result=袷
exit/b
:Unicode袷
set Unicode_Result=34999
exit/b
:Unicode35004
set Unicode_Result=袼
exit/b
:Unicode袼
set Unicode_Result=35004
exit/b
:Unicode35017
set Unicode_Result=裉
exit/b
:Unicode裉
set Unicode_Result=35017
exit/b
:Unicode35042
set Unicode_Result=裢
exit/b
:Unicode裢
set Unicode_Result=35042
exit/b
:Unicode35022
set Unicode_Result=裎
exit/b
:Unicode裎
set Unicode_Result=35022
exit/b
:Unicode35043
set Unicode_Result=裣
exit/b
:Unicode裣
set Unicode_Result=35043
exit/b
:Unicode35045
set Unicode_Result=裥
exit/b
:Unicode裥
set Unicode_Result=35045
exit/b
:Unicode35057
set Unicode_Result=裱
exit/b
:Unicode裱
set Unicode_Result=35057
exit/b
:Unicode35098
set Unicode_Result=褚
exit/b
:Unicode褚
set Unicode_Result=35098
exit/b
:Unicode35068
set Unicode_Result=裼
exit/b
:Unicode裼
set Unicode_Result=35068
exit/b
:Unicode35048
set Unicode_Result=裨
exit/b
:Unicode裨
set Unicode_Result=35048
exit/b
:Unicode35070
set Unicode_Result=裾
exit/b
:Unicode裾
set Unicode_Result=35070
exit/b
:Unicode35056
set Unicode_Result=裰
exit/b
:Unicode裰
set Unicode_Result=35056
exit/b
:Unicode35105
set Unicode_Result=褡
exit/b
:Unicode褡
set Unicode_Result=35105
exit/b
:Unicode35097
set Unicode_Result=褙
exit/b
:Unicode褙
set Unicode_Result=35097
exit/b
:Unicode35091
set Unicode_Result=褓
exit/b
:Unicode褓
set Unicode_Result=35091
exit/b
:Unicode35099
set Unicode_Result=褛
exit/b
:Unicode褛
set Unicode_Result=35099
exit/b
:Unicode35082
set Unicode_Result=褊
exit/b
:Unicode褊
set Unicode_Result=35082
exit/b
:Unicode35124
set Unicode_Result=褴
exit/b
:Unicode褴
set Unicode_Result=35124
exit/b
:Unicode35115
set Unicode_Result=褫
exit/b
:Unicode褫
set Unicode_Result=35115
exit/b
:Unicode35126
set Unicode_Result=褶
exit/b
:Unicode褶
set Unicode_Result=35126
exit/b
:Unicode35137
set Unicode_Result=襁
exit/b
:Unicode襁
set Unicode_Result=35137
exit/b
:Unicode35174
set Unicode_Result=襦
exit/b
:Unicode襦
set Unicode_Result=35174
exit/b
:Unicode35195
set Unicode_Result=襻
exit/b
:Unicode襻
set Unicode_Result=35195
exit/b
:Unicode30091
set Unicode_Result=疋
exit/b
:Unicode疋
set Unicode_Result=30091
exit/b
:Unicode32997
set Unicode_Result=胥
exit/b
:Unicode胥
set Unicode_Result=32997
exit/b
:Unicode30386
set Unicode_Result=皲
exit/b
:Unicode皲
set Unicode_Result=30386
exit/b
:Unicode30388
set Unicode_Result=皴
exit/b
:Unicode皴
set Unicode_Result=30388
exit/b
:Unicode30684
set Unicode_Result=矜
exit/b
:Unicode矜
set Unicode_Result=30684
exit/b
:Unicode32786
set Unicode_Result=耒
exit/b
:Unicode耒
set Unicode_Result=32786
exit/b
:Unicode32788
set Unicode_Result=耔
exit/b
:Unicode耔
set Unicode_Result=32788
exit/b
:Unicode32790
set Unicode_Result=耖
exit/b
:Unicode耖
set Unicode_Result=32790
exit/b
:Unicode32796
set Unicode_Result=耜
exit/b
:Unicode耜
set Unicode_Result=32796
exit/b
:Unicode32800
set Unicode_Result=耠
exit/b
:Unicode耠
set Unicode_Result=32800
exit/b
:Unicode32802
set Unicode_Result=耢
exit/b
:Unicode耢
set Unicode_Result=32802
exit/b
:Unicode32805
set Unicode_Result=耥
exit/b
:Unicode耥
set Unicode_Result=32805
exit/b
:Unicode32806
set Unicode_Result=耦
exit/b
:Unicode耦
set Unicode_Result=32806
exit/b
:Unicode32807
set Unicode_Result=耧
exit/b
:Unicode耧
set Unicode_Result=32807
exit/b
:Unicode32809
set Unicode_Result=耩
exit/b
:Unicode耩
set Unicode_Result=32809
exit/b
:Unicode32808
set Unicode_Result=耨
exit/b
:Unicode耨
set Unicode_Result=32808
exit/b
:Unicode32817
set Unicode_Result=耱
exit/b
:Unicode耱
set Unicode_Result=32817
exit/b
:Unicode32779
set Unicode_Result=耋
exit/b
:Unicode耋
set Unicode_Result=32779
exit/b
:Unicode32821
set Unicode_Result=耵
exit/b
:Unicode耵
set Unicode_Result=32821
exit/b
:Unicode32835
set Unicode_Result=聃
exit/b
:Unicode聃
set Unicode_Result=32835
exit/b
:Unicode32838
set Unicode_Result=聆
exit/b
:Unicode聆
set Unicode_Result=32838
exit/b
:Unicode32845
set Unicode_Result=聍
exit/b
:Unicode聍
set Unicode_Result=32845
exit/b
:Unicode32850
set Unicode_Result=聒
exit/b
:Unicode聒
set Unicode_Result=32850
exit/b
:Unicode32873
set Unicode_Result=聩
exit/b
:Unicode聩
set Unicode_Result=32873
exit/b
:Unicode32881
set Unicode_Result=聱
exit/b
:Unicode聱
set Unicode_Result=32881
exit/b
:Unicode35203
set Unicode_Result=覃
exit/b
:Unicode覃
set Unicode_Result=35203
exit/b
:Unicode39032
set Unicode_Result=顸
exit/b
:Unicode顸
set Unicode_Result=39032
exit/b
:Unicode39040
set Unicode_Result=颀
exit/b
:Unicode颀
set Unicode_Result=39040
exit/b
:Unicode39043
set Unicode_Result=颃
exit/b
:Unicode颃
set Unicode_Result=39043
exit/b
:Unicode39049
set Unicode_Result=颉
exit/b
:Unicode颉
set Unicode_Result=39049
exit/b
:Unicode39052
set Unicode_Result=颌
exit/b
:Unicode颌
set Unicode_Result=39052
exit/b
:Unicode39053
set Unicode_Result=颍
exit/b
:Unicode颍
set Unicode_Result=39053
exit/b
:Unicode39055
set Unicode_Result=颏
exit/b
:Unicode颏
set Unicode_Result=39055
exit/b
:Unicode39060
set Unicode_Result=颔
exit/b
:Unicode颔
set Unicode_Result=39060
exit/b
:Unicode39066
set Unicode_Result=颚
exit/b
:Unicode颚
set Unicode_Result=39066
exit/b
:Unicode39067
set Unicode_Result=颛
exit/b
:Unicode颛
set Unicode_Result=39067
exit/b
:Unicode39070
set Unicode_Result=颞
exit/b
:Unicode颞
set Unicode_Result=39070
exit/b
:Unicode39071
set Unicode_Result=颟
exit/b
:Unicode颟
set Unicode_Result=39071
exit/b
:Unicode39073
set Unicode_Result=颡
exit/b
:Unicode颡
set Unicode_Result=39073
exit/b
:Unicode39074
set Unicode_Result=颢
exit/b
:Unicode颢
set Unicode_Result=39074
exit/b
:Unicode39077
set Unicode_Result=颥
exit/b
:Unicode颥
set Unicode_Result=39077
exit/b
:Unicode39078
set Unicode_Result=颦
exit/b
:Unicode颦
set Unicode_Result=39078
exit/b
:Unicode34381
set Unicode_Result=虍
exit/b
:Unicode虍
set Unicode_Result=34381
exit/b
:Unicode34388
set Unicode_Result=虔
exit/b
:Unicode虔
set Unicode_Result=34388
exit/b
:Unicode34412
set Unicode_Result=虬
exit/b
:Unicode虬
set Unicode_Result=34412
exit/b
:Unicode34414
set Unicode_Result=虮
exit/b
:Unicode虮
set Unicode_Result=34414
exit/b
:Unicode34431
set Unicode_Result=虿
exit/b
:Unicode虿
set Unicode_Result=34431
exit/b
:Unicode34426
set Unicode_Result=虺
exit/b
:Unicode虺
set Unicode_Result=34426
exit/b
:Unicode34428
set Unicode_Result=虼
exit/b
:Unicode虼
set Unicode_Result=34428
exit/b
:Unicode34427
set Unicode_Result=虻
exit/b
:Unicode虻
set Unicode_Result=34427
exit/b
:Unicode34472
set Unicode_Result=蚨
exit/b
:Unicode蚨
set Unicode_Result=34472
exit/b
:Unicode34445
set Unicode_Result=蚍
exit/b
:Unicode蚍
set Unicode_Result=34445
exit/b
:Unicode34443
set Unicode_Result=蚋
exit/b
:Unicode蚋
set Unicode_Result=34443
exit/b
:Unicode34476
set Unicode_Result=蚬
exit/b
:Unicode蚬
set Unicode_Result=34476
exit/b
:Unicode34461
set Unicode_Result=蚝
exit/b
:Unicode蚝
set Unicode_Result=34461
exit/b
:Unicode34471
set Unicode_Result=蚧
exit/b
:Unicode蚧
set Unicode_Result=34471
exit/b
:Unicode34467
set Unicode_Result=蚣
exit/b
:Unicode蚣
set Unicode_Result=34467
exit/b
:Unicode34474
set Unicode_Result=蚪
exit/b
:Unicode蚪
set Unicode_Result=34474
exit/b
:Unicode34451
set Unicode_Result=蚓
exit/b
:Unicode蚓
set Unicode_Result=34451
exit/b
:Unicode34473
set Unicode_Result=蚩
exit/b
:Unicode蚩
set Unicode_Result=34473
exit/b
:Unicode34486
set Unicode_Result=蚶
exit/b
:Unicode蚶
set Unicode_Result=34486
exit/b
:Unicode34500
set Unicode_Result=蛄
exit/b
:Unicode蛄
set Unicode_Result=34500
exit/b
:Unicode34485
set Unicode_Result=蚵
exit/b
:Unicode蚵
set Unicode_Result=34485
exit/b
:Unicode34510
set Unicode_Result=蛎
exit/b
:Unicode蛎
set Unicode_Result=34510
exit/b
:Unicode34480
set Unicode_Result=蚰
exit/b
:Unicode蚰
set Unicode_Result=34480
exit/b
:Unicode34490
set Unicode_Result=蚺
exit/b
:Unicode蚺
set Unicode_Result=34490
exit/b
:Unicode34481
set Unicode_Result=蚱
exit/b
:Unicode蚱
set Unicode_Result=34481
exit/b
:Unicode34479
set Unicode_Result=蚯
exit/b
:Unicode蚯
set Unicode_Result=34479
exit/b
:Unicode34505
set Unicode_Result=蛉
exit/b
:Unicode蛉
set Unicode_Result=34505
exit/b
:Unicode34511
set Unicode_Result=蛏
exit/b
:Unicode蛏
set Unicode_Result=34511
exit/b
:Unicode34484
set Unicode_Result=蚴
exit/b
:Unicode蚴
set Unicode_Result=34484
exit/b
:Unicode34537
set Unicode_Result=蛩
exit/b
:Unicode蛩
set Unicode_Result=34537
exit/b
:Unicode34545
set Unicode_Result=蛱
exit/b
:Unicode蛱
set Unicode_Result=34545
exit/b
:Unicode34546
set Unicode_Result=蛲
exit/b
:Unicode蛲
set Unicode_Result=34546
exit/b
:Unicode34541
set Unicode_Result=蛭
exit/b
:Unicode蛭
set Unicode_Result=34541
exit/b
:Unicode34547
set Unicode_Result=蛳
exit/b
:Unicode蛳
set Unicode_Result=34547
exit/b
:Unicode34512
set Unicode_Result=蛐
exit/b
:Unicode蛐
set Unicode_Result=34512
exit/b
:Unicode34579
set Unicode_Result=蜓
exit/b
:Unicode蜓
set Unicode_Result=34579
exit/b
:Unicode34526
set Unicode_Result=蛞
exit/b
:Unicode蛞
set Unicode_Result=34526
exit/b
:Unicode34548
set Unicode_Result=蛴
exit/b
:Unicode蛴
set Unicode_Result=34548
exit/b
:Unicode34527
set Unicode_Result=蛟
exit/b
:Unicode蛟
set Unicode_Result=34527
exit/b
:Unicode34520
set Unicode_Result=蛘
exit/b
:Unicode蛘
set Unicode_Result=34520
exit/b
:Unicode34513
set Unicode_Result=蛑
exit/b
:Unicode蛑
set Unicode_Result=34513
exit/b
:Unicode34563
set Unicode_Result=蜃
exit/b
:Unicode蜃
set Unicode_Result=34563
exit/b
:Unicode34567
set Unicode_Result=蜇
exit/b
:Unicode蜇
set Unicode_Result=34567
exit/b
:Unicode34552
set Unicode_Result=蛸
exit/b
:Unicode蛸
set Unicode_Result=34552
exit/b
:Unicode34568
set Unicode_Result=蜈
exit/b
:Unicode蜈
set Unicode_Result=34568
exit/b
:Unicode34570
set Unicode_Result=蜊
exit/b
:Unicode蜊
set Unicode_Result=34570
exit/b
:Unicode34573
set Unicode_Result=蜍
exit/b
:Unicode蜍
set Unicode_Result=34573
exit/b
:Unicode34569
set Unicode_Result=蜉
exit/b
:Unicode蜉
set Unicode_Result=34569
exit/b
:Unicode34595
set Unicode_Result=蜣
exit/b
:Unicode蜣
set Unicode_Result=34595
exit/b
:Unicode34619
set Unicode_Result=蜻
exit/b
:Unicode蜻
set Unicode_Result=34619
exit/b
:Unicode34590
set Unicode_Result=蜞
exit/b
:Unicode蜞
set Unicode_Result=34590
exit/b
:Unicode34597
set Unicode_Result=蜥
exit/b
:Unicode蜥
set Unicode_Result=34597
exit/b
:Unicode34606
set Unicode_Result=蜮
exit/b
:Unicode蜮
set Unicode_Result=34606
exit/b
:Unicode34586
set Unicode_Result=蜚
exit/b
:Unicode蜚
set Unicode_Result=34586
exit/b
:Unicode34699
set Unicode_Result=螋
exit/b
:Unicode螋
set Unicode_Result=34699
exit/b
:Unicode34643
set Unicode_Result=蝓
exit/b
:Unicode蝓
set Unicode_Result=34643
exit/b
:Unicode34659
set Unicode_Result=蝣
exit/b
:Unicode蝣
set Unicode_Result=34659
exit/b
:Unicode34684
set Unicode_Result=蝼
exit/b
:Unicode蝼
set Unicode_Result=34684
exit/b
:Unicode34660
set Unicode_Result=蝤
exit/b
:Unicode蝤
set Unicode_Result=34660
exit/b
:Unicode34649
set Unicode_Result=蝙
exit/b
:Unicode蝙
set Unicode_Result=34649
exit/b
:Unicode34661
set Unicode_Result=蝥
exit/b
:Unicode蝥
set Unicode_Result=34661
exit/b
:Unicode34707
set Unicode_Result=螓
exit/b
:Unicode螓
set Unicode_Result=34707
exit/b
:Unicode34735
set Unicode_Result=螯
exit/b
:Unicode螯
set Unicode_Result=34735
exit/b
:Unicode34728
set Unicode_Result=螨
exit/b
:Unicode螨
set Unicode_Result=34728
exit/b
:Unicode34770
set Unicode_Result=蟒
exit/b
:Unicode蟒
set Unicode_Result=34770
exit/b
:Unicode34758
set Unicode_Result=蟆
exit/b
:Unicode蟆
set Unicode_Result=34758
exit/b
:Unicode34696
set Unicode_Result=螈
exit/b
:Unicode螈
set Unicode_Result=34696
exit/b
:Unicode34693
set Unicode_Result=螅
exit/b
:Unicode螅
set Unicode_Result=34693
exit/b
:Unicode34733
set Unicode_Result=螭
exit/b
:Unicode螭
set Unicode_Result=34733
exit/b
:Unicode34711
set Unicode_Result=螗
exit/b
:Unicode螗
set Unicode_Result=34711
exit/b
:Unicode34691
set Unicode_Result=螃
exit/b
:Unicode螃
set Unicode_Result=34691
exit/b
:Unicode34731
set Unicode_Result=螫
exit/b
:Unicode螫
set Unicode_Result=34731
exit/b
:Unicode34789
set Unicode_Result=蟥
exit/b
:Unicode蟥
set Unicode_Result=34789
exit/b
:Unicode34732
set Unicode_Result=螬
exit/b
:Unicode螬
set Unicode_Result=34732
exit/b
:Unicode34741
set Unicode_Result=螵
exit/b
:Unicode螵
set Unicode_Result=34741
exit/b
:Unicode34739
set Unicode_Result=螳
exit/b
:Unicode螳
set Unicode_Result=34739
exit/b
:Unicode34763
set Unicode_Result=蟋
exit/b
:Unicode蟋
set Unicode_Result=34763
exit/b
:Unicode34771
set Unicode_Result=蟓
exit/b
:Unicode蟓
set Unicode_Result=34771
exit/b
:Unicode34749
set Unicode_Result=螽
exit/b
:Unicode螽
set Unicode_Result=34749
exit/b
:Unicode34769
set Unicode_Result=蟑
exit/b
:Unicode蟑
set Unicode_Result=34769
exit/b
:Unicode34752
set Unicode_Result=蟀
exit/b
:Unicode蟀
set Unicode_Result=34752
exit/b
:Unicode34762
set Unicode_Result=蟊
exit/b
:Unicode蟊
set Unicode_Result=34762
exit/b
:Unicode34779
set Unicode_Result=蟛
exit/b
:Unicode蟛
set Unicode_Result=34779
exit/b
:Unicode34794
set Unicode_Result=蟪
exit/b
:Unicode蟪
set Unicode_Result=34794
exit/b
:Unicode34784
set Unicode_Result=蟠
exit/b
:Unicode蟠
set Unicode_Result=34784
exit/b
:Unicode34798
set Unicode_Result=蟮
exit/b
:Unicode蟮
set Unicode_Result=34798
exit/b
:Unicode34838
set Unicode_Result=蠖
exit/b
:Unicode蠖
set Unicode_Result=34838
exit/b
:Unicode34835
set Unicode_Result=蠓
exit/b
:Unicode蠓
set Unicode_Result=34835
exit/b
:Unicode34814
set Unicode_Result=蟾
exit/b
:Unicode蟾
set Unicode_Result=34814
exit/b
:Unicode34826
set Unicode_Result=蠊
exit/b
:Unicode蠊
set Unicode_Result=34826
exit/b
:Unicode34843
set Unicode_Result=蠛
exit/b
:Unicode蠛
set Unicode_Result=34843
exit/b
:Unicode34849
set Unicode_Result=蠡
exit/b
:Unicode蠡
set Unicode_Result=34849
exit/b
:Unicode34873
set Unicode_Result=蠹
exit/b
:Unicode蠹
set Unicode_Result=34873
exit/b
:Unicode34876
set Unicode_Result=蠼
exit/b
:Unicode蠼
set Unicode_Result=34876
exit/b
:Unicode32566
set Unicode_Result=缶
exit/b
:Unicode缶
set Unicode_Result=32566
exit/b
:Unicode32578
set Unicode_Result=罂
exit/b
:Unicode罂
set Unicode_Result=32578
exit/b
:Unicode32580
set Unicode_Result=罄
exit/b
:Unicode罄
set Unicode_Result=32580
exit/b
:Unicode32581
set Unicode_Result=罅
exit/b
:Unicode罅
set Unicode_Result=32581
exit/b
:Unicode33296
set Unicode_Result=舐
exit/b
:Unicode舐
set Unicode_Result=33296
exit/b
:Unicode31482
set Unicode_Result=竺
exit/b
:Unicode竺
set Unicode_Result=31482
exit/b
:Unicode31485
set Unicode_Result=竽
exit/b
:Unicode竽
set Unicode_Result=31485
exit/b
:Unicode31496
set Unicode_Result=笈
exit/b
:Unicode笈
set Unicode_Result=31496
exit/b
:Unicode31491
set Unicode_Result=笃
exit/b
:Unicode笃
set Unicode_Result=31491
exit/b
:Unicode31492
set Unicode_Result=笄
exit/b
:Unicode笄
set Unicode_Result=31492
exit/b
:Unicode31509
set Unicode_Result=笕
exit/b
:Unicode笕
set Unicode_Result=31509
exit/b
:Unicode31498
set Unicode_Result=笊
exit/b
:Unicode笊
set Unicode_Result=31498
exit/b
:Unicode31531
set Unicode_Result=笫
exit/b
:Unicode笫
set Unicode_Result=31531
exit/b
:Unicode31503
set Unicode_Result=笏
exit/b
:Unicode笏
set Unicode_Result=31503
exit/b
:Unicode31559
set Unicode_Result=筇
exit/b
:Unicode筇
set Unicode_Result=31559
exit/b
:Unicode31544
set Unicode_Result=笸
exit/b
:Unicode笸
set Unicode_Result=31544
exit/b
:Unicode31530
set Unicode_Result=笪
exit/b
:Unicode笪
set Unicode_Result=31530
exit/b
:Unicode31513
set Unicode_Result=笙
exit/b
:Unicode笙
set Unicode_Result=31513
exit/b
:Unicode31534
set Unicode_Result=笮
exit/b
:Unicode笮
set Unicode_Result=31534
exit/b
:Unicode31537
set Unicode_Result=笱
exit/b
:Unicode笱
set Unicode_Result=31537
exit/b
:Unicode31520
set Unicode_Result=笠
exit/b
:Unicode笠
set Unicode_Result=31520
exit/b
:Unicode31525
set Unicode_Result=笥
exit/b
:Unicode笥
set Unicode_Result=31525
exit/b
:Unicode31524
set Unicode_Result=笤
exit/b
:Unicode笤
set Unicode_Result=31524
exit/b
:Unicode31539
set Unicode_Result=笳
exit/b
:Unicode笳
set Unicode_Result=31539
exit/b
:Unicode31550
set Unicode_Result=笾
exit/b
:Unicode笾
set Unicode_Result=31550
exit/b
:Unicode31518
set Unicode_Result=笞
exit/b
:Unicode笞
set Unicode_Result=31518
exit/b
:Unicode31576
set Unicode_Result=筘
exit/b
:Unicode筘
set Unicode_Result=31576
exit/b
:Unicode31578
set Unicode_Result=筚
exit/b
:Unicode筚
set Unicode_Result=31578
exit/b
:Unicode31557
set Unicode_Result=筅
exit/b
:Unicode筅
set Unicode_Result=31557
exit/b
:Unicode31605
set Unicode_Result=筵
exit/b
:Unicode筵
set Unicode_Result=31605
exit/b
:Unicode31564
set Unicode_Result=筌
exit/b
:Unicode筌
set Unicode_Result=31564
exit/b
:Unicode31581
set Unicode_Result=筝
exit/b
:Unicode筝
set Unicode_Result=31581
exit/b
:Unicode31584
set Unicode_Result=筠
exit/b
:Unicode筠
set Unicode_Result=31584
exit/b
:Unicode31598
set Unicode_Result=筮
exit/b
:Unicode筮
set Unicode_Result=31598
exit/b
:Unicode31611
set Unicode_Result=筻
exit/b
:Unicode筻
set Unicode_Result=31611
exit/b
:Unicode31586
set Unicode_Result=筢
exit/b
:Unicode筢
set Unicode_Result=31586
exit/b
:Unicode31602
set Unicode_Result=筲
exit/b
:Unicode筲
set Unicode_Result=31602
exit/b
:Unicode31601
set Unicode_Result=筱
exit/b
:Unicode筱
set Unicode_Result=31601
exit/b
:Unicode31632
set Unicode_Result=箐
exit/b
:Unicode箐
set Unicode_Result=31632
exit/b
:Unicode31654
set Unicode_Result=箦
exit/b
:Unicode箦
set Unicode_Result=31654
exit/b
:Unicode31655
set Unicode_Result=箧
exit/b
:Unicode箧
set Unicode_Result=31655
exit/b
:Unicode31672
set Unicode_Result=箸
exit/b
:Unicode箸
set Unicode_Result=31672
exit/b
:Unicode31660
set Unicode_Result=箬
exit/b
:Unicode箬
set Unicode_Result=31660
exit/b
:Unicode31645
set Unicode_Result=箝
exit/b
:Unicode箝
set Unicode_Result=31645
exit/b
:Unicode31656
set Unicode_Result=箨
exit/b
:Unicode箨
set Unicode_Result=31656
exit/b
:Unicode31621
set Unicode_Result=箅
exit/b
:Unicode箅
set Unicode_Result=31621
exit/b
:Unicode31658
set Unicode_Result=箪
exit/b
:Unicode箪
set Unicode_Result=31658
exit/b
:Unicode31644
set Unicode_Result=箜
exit/b
:Unicode箜
set Unicode_Result=31644
exit/b
:Unicode31650
set Unicode_Result=箢
exit/b
:Unicode箢
set Unicode_Result=31650
exit/b
:Unicode31659
set Unicode_Result=箫
exit/b
:Unicode箫
set Unicode_Result=31659
exit/b
:Unicode31668
set Unicode_Result=箴
exit/b
:Unicode箴
set Unicode_Result=31668
exit/b
:Unicode31697
set Unicode_Result=篑
exit/b
:Unicode篑
set Unicode_Result=31697
exit/b
:Unicode31681
set Unicode_Result=篁
exit/b
:Unicode篁
set Unicode_Result=31681
exit/b
:Unicode31692
set Unicode_Result=篌
exit/b
:Unicode篌
set Unicode_Result=31692
exit/b
:Unicode31709
set Unicode_Result=篝
exit/b
:Unicode篝
set Unicode_Result=31709
exit/b
:Unicode31706
set Unicode_Result=篚
exit/b
:Unicode篚
set Unicode_Result=31706
exit/b
:Unicode31717
set Unicode_Result=篥
exit/b
:Unicode篥
set Unicode_Result=31717
exit/b
:Unicode31718
set Unicode_Result=篦
exit/b
:Unicode篦
set Unicode_Result=31718
exit/b
:Unicode31722
set Unicode_Result=篪
exit/b
:Unicode篪
set Unicode_Result=31722
exit/b
:Unicode31756
set Unicode_Result=簌
exit/b
:Unicode簌
set Unicode_Result=31756
exit/b
:Unicode31742
set Unicode_Result=篾
exit/b
:Unicode篾
set Unicode_Result=31742
exit/b
:Unicode31740
set Unicode_Result=篼
exit/b
:Unicode篼
set Unicode_Result=31740
exit/b
:Unicode31759
set Unicode_Result=簏
exit/b
:Unicode簏
set Unicode_Result=31759
exit/b
:Unicode31766
set Unicode_Result=簖
exit/b
:Unicode簖
set Unicode_Result=31766
exit/b
:Unicode31755
set Unicode_Result=簋
exit/b
:Unicode簋
set Unicode_Result=31755
exit/b
:Unicode31775
set Unicode_Result=簟
exit/b
:Unicode簟
set Unicode_Result=31775
exit/b
:Unicode31786
set Unicode_Result=簪
exit/b
:Unicode簪
set Unicode_Result=31786
exit/b
:Unicode31782
set Unicode_Result=簦
exit/b
:Unicode簦
set Unicode_Result=31782
exit/b
:Unicode31800
set Unicode_Result=簸
exit/b
:Unicode簸
set Unicode_Result=31800
exit/b
:Unicode31809
set Unicode_Result=籁
exit/b
:Unicode籁
set Unicode_Result=31809
exit/b
:Unicode31808
set Unicode_Result=籀
exit/b
:Unicode籀
set Unicode_Result=31808
exit/b
:Unicode33278
set Unicode_Result=臾
exit/b
:Unicode臾
set Unicode_Result=33278
exit/b
:Unicode33281
set Unicode_Result=舁
exit/b
:Unicode舁
set Unicode_Result=33281
exit/b
:Unicode33282
set Unicode_Result=舂
exit/b
:Unicode舂
set Unicode_Result=33282
exit/b
:Unicode33284
set Unicode_Result=舄
exit/b
:Unicode舄
set Unicode_Result=33284
exit/b
:Unicode33260
set Unicode_Result=臬
exit/b
:Unicode臬
set Unicode_Result=33260
exit/b
:Unicode34884
set Unicode_Result=衄
exit/b
:Unicode衄
set Unicode_Result=34884
exit/b
:Unicode33313
set Unicode_Result=舡
exit/b
:Unicode舡
set Unicode_Result=33313
exit/b
:Unicode33314
set Unicode_Result=舢
exit/b
:Unicode舢
set Unicode_Result=33314
exit/b
:Unicode33315
set Unicode_Result=舣
exit/b
:Unicode舣
set Unicode_Result=33315
exit/b
:Unicode33325
set Unicode_Result=舭
exit/b
:Unicode舭
set Unicode_Result=33325
exit/b
:Unicode33327
set Unicode_Result=舯
exit/b
:Unicode舯
set Unicode_Result=33327
exit/b
:Unicode33320
set Unicode_Result=舨
exit/b
:Unicode舨
set Unicode_Result=33320
exit/b
:Unicode33323
set Unicode_Result=舫
exit/b
:Unicode舫
set Unicode_Result=33323
exit/b
:Unicode33336
set Unicode_Result=舸
exit/b
:Unicode舸
set Unicode_Result=33336
exit/b
:Unicode33339
set Unicode_Result=舻
exit/b
:Unicode舻
set Unicode_Result=33339
exit/b
:Unicode33331
set Unicode_Result=舳
exit/b
:Unicode舳
set Unicode_Result=33331
exit/b
:Unicode33332
set Unicode_Result=舴
exit/b
:Unicode舴
set Unicode_Result=33332
exit/b
:Unicode33342
set Unicode_Result=舾
exit/b
:Unicode舾
set Unicode_Result=33342
exit/b
:Unicode33348
set Unicode_Result=艄
exit/b
:Unicode艄
set Unicode_Result=33348
exit/b
:Unicode33353
set Unicode_Result=艉
exit/b
:Unicode艉
set Unicode_Result=33353
exit/b
:Unicode33355
set Unicode_Result=艋
exit/b
:Unicode艋
set Unicode_Result=33355
exit/b
:Unicode33359
set Unicode_Result=艏
exit/b
:Unicode艏
set Unicode_Result=33359
exit/b
:Unicode33370
set Unicode_Result=艚
exit/b
:Unicode艚
set Unicode_Result=33370
exit/b
:Unicode33375
set Unicode_Result=艟
exit/b
:Unicode艟
set Unicode_Result=33375
exit/b
:Unicode33384
set Unicode_Result=艨
exit/b
:Unicode艨
set Unicode_Result=33384
exit/b
:Unicode34942
set Unicode_Result=衾
exit/b
:Unicode衾
set Unicode_Result=34942
exit/b
:Unicode34949
set Unicode_Result=袅
exit/b
:Unicode袅
set Unicode_Result=34949
exit/b
:Unicode34952
set Unicode_Result=袈
exit/b
:Unicode袈
set Unicode_Result=34952
exit/b
:Unicode35032
set Unicode_Result=裘
exit/b
:Unicode裘
set Unicode_Result=35032
exit/b
:Unicode35039
set Unicode_Result=裟
exit/b
:Unicode裟
set Unicode_Result=35039
exit/b
:Unicode35166
set Unicode_Result=襞
exit/b
:Unicode襞
set Unicode_Result=35166
exit/b
:Unicode32669
set Unicode_Result=羝
exit/b
:Unicode羝
set Unicode_Result=32669
exit/b
:Unicode32671
set Unicode_Result=羟
exit/b
:Unicode羟
set Unicode_Result=32671
exit/b
:Unicode32679
set Unicode_Result=羧
exit/b
:Unicode羧
set Unicode_Result=32679
exit/b
:Unicode32687
set Unicode_Result=羯
exit/b
:Unicode羯
set Unicode_Result=32687
exit/b
:Unicode32688
set Unicode_Result=羰
exit/b
:Unicode羰
set Unicode_Result=32688
exit/b
:Unicode32690
set Unicode_Result=羲
exit/b
:Unicode羲
set Unicode_Result=32690
exit/b
:Unicode31868
set Unicode_Result=籼
exit/b
:Unicode籼
set Unicode_Result=31868
exit/b
:Unicode25929
set Unicode_Result=敉
exit/b
:Unicode敉
set Unicode_Result=25929
exit/b
:Unicode31889
set Unicode_Result=粑
exit/b
:Unicode粑
set Unicode_Result=31889
exit/b
:Unicode31901
set Unicode_Result=粝
exit/b
:Unicode粝
set Unicode_Result=31901
exit/b
:Unicode31900
set Unicode_Result=粜
exit/b
:Unicode粜
set Unicode_Result=31900
exit/b
:Unicode31902
set Unicode_Result=粞
exit/b
:Unicode粞
set Unicode_Result=31902
exit/b
:Unicode31906
set Unicode_Result=粢
exit/b
:Unicode粢
set Unicode_Result=31906
exit/b
:Unicode31922
set Unicode_Result=粲
exit/b
:Unicode粲
set Unicode_Result=31922
exit/b
:Unicode31932
set Unicode_Result=粼
exit/b
:Unicode粼
set Unicode_Result=31932
exit/b
:Unicode31933
set Unicode_Result=粽
exit/b
:Unicode粽
set Unicode_Result=31933
exit/b
:Unicode31937
set Unicode_Result=糁
exit/b
:Unicode糁
set Unicode_Result=31937
exit/b
:Unicode31943
set Unicode_Result=糇
exit/b
:Unicode糇
set Unicode_Result=31943
exit/b
:Unicode31948
set Unicode_Result=糌
exit/b
:Unicode糌
set Unicode_Result=31948
exit/b
:Unicode31949
set Unicode_Result=糍
exit/b
:Unicode糍
set Unicode_Result=31949
exit/b
:Unicode31944
set Unicode_Result=糈
exit/b
:Unicode糈
set Unicode_Result=31944
exit/b
:Unicode31941
set Unicode_Result=糅
exit/b
:Unicode糅
set Unicode_Result=31941
exit/b
:Unicode31959
set Unicode_Result=糗
exit/b
:Unicode糗
set Unicode_Result=31959
exit/b
:Unicode31976
set Unicode_Result=糨
exit/b
:Unicode糨
set Unicode_Result=31976
exit/b
:Unicode33390
set Unicode_Result=艮
exit/b
:Unicode艮
set Unicode_Result=33390
exit/b
:Unicode26280
set Unicode_Result=暨
exit/b
:Unicode暨
set Unicode_Result=26280
exit/b
:Unicode32703
set Unicode_Result=羿
exit/b
:Unicode羿
set Unicode_Result=32703
exit/b
:Unicode32718
set Unicode_Result=翎
exit/b
:Unicode翎
set Unicode_Result=32718
exit/b
:Unicode32725
set Unicode_Result=翕
exit/b
:Unicode翕
set Unicode_Result=32725
exit/b
:Unicode32741
set Unicode_Result=翥
exit/b
:Unicode翥
set Unicode_Result=32741
exit/b
:Unicode32737
set Unicode_Result=翡
exit/b
:Unicode翡
set Unicode_Result=32737
exit/b
:Unicode32742
set Unicode_Result=翦
exit/b
:Unicode翦
set Unicode_Result=32742
exit/b
:Unicode32745
set Unicode_Result=翩
exit/b
:Unicode翩
set Unicode_Result=32745
exit/b
:Unicode32750
set Unicode_Result=翮
exit/b
:Unicode翮
set Unicode_Result=32750
exit/b
:Unicode32755
set Unicode_Result=翳
exit/b
:Unicode翳
set Unicode_Result=32755
exit/b
:Unicode31992
set Unicode_Result=糸
exit/b
:Unicode糸
set Unicode_Result=31992
exit/b
:Unicode32119
set Unicode_Result=絷
exit/b
:Unicode絷
set Unicode_Result=32119
exit/b
:Unicode32166
set Unicode_Result=綦
exit/b
:Unicode綦
set Unicode_Result=32166
exit/b
:Unicode32174
set Unicode_Result=綮
exit/b
:Unicode綮
set Unicode_Result=32174
exit/b
:Unicode32327
set Unicode_Result=繇
exit/b
:Unicode繇
set Unicode_Result=32327
exit/b
:Unicode32411
set Unicode_Result=纛
exit/b
:Unicode纛
set Unicode_Result=32411
exit/b
:Unicode40632
set Unicode_Result=麸
exit/b
:Unicode麸
set Unicode_Result=40632
exit/b
:Unicode40628
set Unicode_Result=麴
exit/b
:Unicode麴
set Unicode_Result=40628
exit/b
:Unicode36211
set Unicode_Result=赳
exit/b
:Unicode赳
set Unicode_Result=36211
exit/b
:Unicode36228
set Unicode_Result=趄
exit/b
:Unicode趄
set Unicode_Result=36228
exit/b
:Unicode36244
set Unicode_Result=趔
exit/b
:Unicode趔
set Unicode_Result=36244
exit/b
:Unicode36241
set Unicode_Result=趑
exit/b
:Unicode趑
set Unicode_Result=36241
exit/b
:Unicode36273
set Unicode_Result=趱
exit/b
:Unicode趱
set Unicode_Result=36273
exit/b
:Unicode36199
set Unicode_Result=赧
exit/b
:Unicode赧
set Unicode_Result=36199
exit/b
:Unicode36205
set Unicode_Result=赭
exit/b
:Unicode赭
set Unicode_Result=36205
exit/b
:Unicode35911
set Unicode_Result=豇
exit/b
:Unicode豇
set Unicode_Result=35911
exit/b
:Unicode35913
set Unicode_Result=豉
exit/b
:Unicode豉
set Unicode_Result=35913
exit/b
:Unicode37194
set Unicode_Result=酊
exit/b
:Unicode酊
set Unicode_Result=37194
exit/b
:Unicode37200
set Unicode_Result=酐
exit/b
:Unicode酐
set Unicode_Result=37200
exit/b
:Unicode37198
set Unicode_Result=酎
exit/b
:Unicode酎
set Unicode_Result=37198
exit/b
:Unicode37199
set Unicode_Result=酏
exit/b
:Unicode酏
set Unicode_Result=37199
exit/b
:Unicode37220
set Unicode_Result=酤
exit/b
:Unicode酤
set Unicode_Result=37220
exit/b
:Unicode37218
set Unicode_Result=酢
exit/b
:Unicode酢
set Unicode_Result=37218
exit/b
:Unicode37217
set Unicode_Result=酡
exit/b
:Unicode酡
set Unicode_Result=37217
exit/b
:Unicode37232
set Unicode_Result=酰
exit/b
:Unicode酰
set Unicode_Result=37232
exit/b
:Unicode37225
set Unicode_Result=酩
exit/b
:Unicode酩
set Unicode_Result=37225
exit/b
:Unicode37231
set Unicode_Result=酯
exit/b
:Unicode酯
set Unicode_Result=37231
exit/b
:Unicode37245
set Unicode_Result=酽
exit/b
:Unicode酽
set Unicode_Result=37245
exit/b
:Unicode37246
set Unicode_Result=酾
exit/b
:Unicode酾
set Unicode_Result=37246
exit/b
:Unicode37234
set Unicode_Result=酲
exit/b
:Unicode酲
set Unicode_Result=37234
exit/b
:Unicode37236
set Unicode_Result=酴
exit/b
:Unicode酴
set Unicode_Result=37236
exit/b
:Unicode37241
set Unicode_Result=酹
exit/b
:Unicode酹
set Unicode_Result=37241
exit/b
:Unicode37260
set Unicode_Result=醌
exit/b
:Unicode醌
set Unicode_Result=37260
exit/b
:Unicode37253
set Unicode_Result=醅
exit/b
:Unicode醅
set Unicode_Result=37253
exit/b
:Unicode37264
set Unicode_Result=醐
exit/b
:Unicode醐
set Unicode_Result=37264
exit/b
:Unicode37261
set Unicode_Result=醍
exit/b
:Unicode醍
set Unicode_Result=37261
exit/b
:Unicode37265
set Unicode_Result=醑
exit/b
:Unicode醑
set Unicode_Result=37265
exit/b
:Unicode37282
set Unicode_Result=醢
exit/b
:Unicode醢
set Unicode_Result=37282
exit/b
:Unicode37283
set Unicode_Result=醣
exit/b
:Unicode醣
set Unicode_Result=37283
exit/b
:Unicode37290
set Unicode_Result=醪
exit/b
:Unicode醪
set Unicode_Result=37290
exit/b
:Unicode37293
set Unicode_Result=醭
exit/b
:Unicode醭
set Unicode_Result=37293
exit/b
:Unicode37294
set Unicode_Result=醮
exit/b
:Unicode醮
set Unicode_Result=37294
exit/b
:Unicode37295
set Unicode_Result=醯
exit/b
:Unicode醯
set Unicode_Result=37295
exit/b
:Unicode37301
set Unicode_Result=醵
exit/b
:Unicode醵
set Unicode_Result=37301
exit/b
:Unicode37300
set Unicode_Result=醴
exit/b
:Unicode醴
set Unicode_Result=37300
exit/b
:Unicode37306
set Unicode_Result=醺
exit/b
:Unicode醺
set Unicode_Result=37306
exit/b
:Unicode35925
set Unicode_Result=豕
exit/b
:Unicode豕
set Unicode_Result=35925
exit/b
:Unicode40574
set Unicode_Result=鹾
exit/b
:Unicode鹾
set Unicode_Result=40574
exit/b
:Unicode36280
set Unicode_Result=趸
exit/b
:Unicode趸
set Unicode_Result=36280
exit/b
:Unicode36331
set Unicode_Result=跫
exit/b
:Unicode跫
set Unicode_Result=36331
exit/b
:Unicode36357
set Unicode_Result=踅
exit/b
:Unicode踅
set Unicode_Result=36357
exit/b
:Unicode36441
set Unicode_Result=蹙
exit/b
:Unicode蹙
set Unicode_Result=36441
exit/b
:Unicode36457
set Unicode_Result=蹩
exit/b
:Unicode蹩
set Unicode_Result=36457
exit/b
:Unicode36277
set Unicode_Result=趵
exit/b
:Unicode趵
set Unicode_Result=36277
exit/b
:Unicode36287
set Unicode_Result=趿
exit/b
:Unicode趿
set Unicode_Result=36287
exit/b
:Unicode36284
set Unicode_Result=趼
exit/b
:Unicode趼
set Unicode_Result=36284
exit/b
:Unicode36282
set Unicode_Result=趺
exit/b
:Unicode趺
set Unicode_Result=36282
exit/b
:Unicode36292
set Unicode_Result=跄
exit/b
:Unicode跄
set Unicode_Result=36292
exit/b
:Unicode36310
set Unicode_Result=跖
exit/b
:Unicode跖
set Unicode_Result=36310
exit/b
:Unicode36311
set Unicode_Result=跗
exit/b
:Unicode跗
set Unicode_Result=36311
exit/b
:Unicode36314
set Unicode_Result=跚
exit/b
:Unicode跚
set Unicode_Result=36314
exit/b
:Unicode36318
set Unicode_Result=跞
exit/b
:Unicode跞
set Unicode_Result=36318
exit/b
:Unicode36302
set Unicode_Result=跎
exit/b
:Unicode跎
set Unicode_Result=36302
exit/b
:Unicode36303
set Unicode_Result=跏
exit/b
:Unicode跏
set Unicode_Result=36303
exit/b
:Unicode36315
set Unicode_Result=跛
exit/b
:Unicode跛
set Unicode_Result=36315
exit/b
:Unicode36294
set Unicode_Result=跆
exit/b
:Unicode跆
set Unicode_Result=36294
exit/b
:Unicode36332
set Unicode_Result=跬
exit/b
:Unicode跬
set Unicode_Result=36332
exit/b
:Unicode36343
set Unicode_Result=跷
exit/b
:Unicode跷
set Unicode_Result=36343
exit/b
:Unicode36344
set Unicode_Result=跸
exit/b
:Unicode跸
set Unicode_Result=36344
exit/b
:Unicode36323
set Unicode_Result=跣
exit/b
:Unicode跣
set Unicode_Result=36323
exit/b
:Unicode36345
set Unicode_Result=跹
exit/b
:Unicode跹
set Unicode_Result=36345
exit/b
:Unicode36347
set Unicode_Result=跻
exit/b
:Unicode跻
set Unicode_Result=36347
exit/b
:Unicode36324
set Unicode_Result=跤
exit/b
:Unicode跤
set Unicode_Result=36324
exit/b
:Unicode36361
set Unicode_Result=踉
exit/b
:Unicode踉
set Unicode_Result=36361
exit/b
:Unicode36349
set Unicode_Result=跽
exit/b
:Unicode跽
set Unicode_Result=36349
exit/b
:Unicode36372
set Unicode_Result=踔
exit/b
:Unicode踔
set Unicode_Result=36372
exit/b
:Unicode36381
set Unicode_Result=踝
exit/b
:Unicode踝
set Unicode_Result=36381
exit/b
:Unicode36383
set Unicode_Result=踟
exit/b
:Unicode踟
set Unicode_Result=36383
exit/b
:Unicode36396
set Unicode_Result=踬
exit/b
:Unicode踬
set Unicode_Result=36396
exit/b
:Unicode36398
set Unicode_Result=踮
exit/b
:Unicode踮
set Unicode_Result=36398
exit/b
:Unicode36387
set Unicode_Result=踣
exit/b
:Unicode踣
set Unicode_Result=36387
exit/b
:Unicode36399
set Unicode_Result=踯
exit/b
:Unicode踯
set Unicode_Result=36399
exit/b
:Unicode36410
set Unicode_Result=踺
exit/b
:Unicode踺
set Unicode_Result=36410
exit/b
:Unicode36416
set Unicode_Result=蹀
exit/b
:Unicode蹀
set Unicode_Result=36416
exit/b
:Unicode36409
set Unicode_Result=踹
exit/b
:Unicode踹
set Unicode_Result=36409
exit/b
:Unicode36405
set Unicode_Result=踵
exit/b
:Unicode踵
set Unicode_Result=36405
exit/b
:Unicode36413
set Unicode_Result=踽
exit/b
:Unicode踽
set Unicode_Result=36413
exit/b
:Unicode36401
set Unicode_Result=踱
exit/b
:Unicode踱
set Unicode_Result=36401
exit/b
:Unicode36425
set Unicode_Result=蹉
exit/b
:Unicode蹉
set Unicode_Result=36425
exit/b
:Unicode36417
set Unicode_Result=蹁
exit/b
:Unicode蹁
set Unicode_Result=36417
exit/b
:Unicode36418
set Unicode_Result=蹂
exit/b
:Unicode蹂
set Unicode_Result=36418
exit/b
:Unicode36433
set Unicode_Result=蹑
exit/b
:Unicode蹑
set Unicode_Result=36433
exit/b
:Unicode36434
set Unicode_Result=蹒
exit/b
:Unicode蹒
set Unicode_Result=36434
exit/b
:Unicode36426
set Unicode_Result=蹊
exit/b
:Unicode蹊
set Unicode_Result=36426
exit/b
:Unicode36464
set Unicode_Result=蹰
exit/b
:Unicode蹰
set Unicode_Result=36464
exit/b
:Unicode36470
set Unicode_Result=蹶
exit/b
:Unicode蹶
set Unicode_Result=36470
exit/b
:Unicode36476
set Unicode_Result=蹼
exit/b
:Unicode蹼
set Unicode_Result=36476
exit/b
:Unicode36463
set Unicode_Result=蹯
exit/b
:Unicode蹯
set Unicode_Result=36463
exit/b
:Unicode36468
set Unicode_Result=蹴
exit/b
:Unicode蹴
set Unicode_Result=36468
exit/b
:Unicode36485
set Unicode_Result=躅
exit/b
:Unicode躅
set Unicode_Result=36485
exit/b
:Unicode36495
set Unicode_Result=躏
exit/b
:Unicode躏
set Unicode_Result=36495
exit/b
:Unicode36500
set Unicode_Result=躔
exit/b
:Unicode躔
set Unicode_Result=36500
exit/b
:Unicode36496
set Unicode_Result=躐
exit/b
:Unicode躐
set Unicode_Result=36496
exit/b
:Unicode36508
set Unicode_Result=躜
exit/b
:Unicode躜
set Unicode_Result=36508
exit/b
:Unicode36510
set Unicode_Result=躞
exit/b
:Unicode躞
set Unicode_Result=36510
exit/b
:Unicode35960
set Unicode_Result=豸
exit/b
:Unicode豸
set Unicode_Result=35960
exit/b
:Unicode35970
set Unicode_Result=貂
exit/b
:Unicode貂
set Unicode_Result=35970
exit/b
:Unicode35978
set Unicode_Result=貊
exit/b
:Unicode貊
set Unicode_Result=35978
exit/b
:Unicode35973
set Unicode_Result=貅
exit/b
:Unicode貅
set Unicode_Result=35973
exit/b
:Unicode35992
set Unicode_Result=貘
exit/b
:Unicode貘
set Unicode_Result=35992
exit/b
:Unicode35988
set Unicode_Result=貔
exit/b
:Unicode貔
set Unicode_Result=35988
exit/b
:Unicode26011
set Unicode_Result=斛
exit/b
:Unicode斛
set Unicode_Result=26011
exit/b
:Unicode35286
set Unicode_Result=觖
exit/b
:Unicode觖
set Unicode_Result=35286
exit/b
:Unicode35294
set Unicode_Result=觞
exit/b
:Unicode觞
set Unicode_Result=35294
exit/b
:Unicode35290
set Unicode_Result=觚
exit/b
:Unicode觚
set Unicode_Result=35290
exit/b
:Unicode35292
set Unicode_Result=觜
exit/b
:Unicode觜
set Unicode_Result=35292
exit/b
:Unicode35301
set Unicode_Result=觥
exit/b
:Unicode觥
set Unicode_Result=35301
exit/b
:Unicode35307
set Unicode_Result=觫
exit/b
:Unicode觫
set Unicode_Result=35307
exit/b
:Unicode35311
set Unicode_Result=觯
exit/b
:Unicode觯
set Unicode_Result=35311
exit/b
:Unicode35390
set Unicode_Result=訾
exit/b
:Unicode訾
set Unicode_Result=35390
exit/b
:Unicode35622
set Unicode_Result=謦
exit/b
:Unicode謦
set Unicode_Result=35622
exit/b
:Unicode38739
set Unicode_Result=靓
exit/b
:Unicode靓
set Unicode_Result=38739
exit/b
:Unicode38633
set Unicode_Result=雩
exit/b
:Unicode雩
set Unicode_Result=38633
exit/b
:Unicode38643
set Unicode_Result=雳
exit/b
:Unicode雳
set Unicode_Result=38643
exit/b
:Unicode38639
set Unicode_Result=雯
exit/b
:Unicode雯
set Unicode_Result=38639
exit/b
:Unicode38662
set Unicode_Result=霆
exit/b
:Unicode霆
set Unicode_Result=38662
exit/b
:Unicode38657
set Unicode_Result=霁
exit/b
:Unicode霁
set Unicode_Result=38657
exit/b
:Unicode38664
set Unicode_Result=霈
exit/b
:Unicode霈
set Unicode_Result=38664
exit/b
:Unicode38671
set Unicode_Result=霏
exit/b
:Unicode霏
set Unicode_Result=38671
exit/b
:Unicode38670
set Unicode_Result=霎
exit/b
:Unicode霎
set Unicode_Result=38670
exit/b
:Unicode38698
set Unicode_Result=霪
exit/b
:Unicode霪
set Unicode_Result=38698
exit/b
:Unicode38701
set Unicode_Result=霭
exit/b
:Unicode霭
set Unicode_Result=38701
exit/b
:Unicode38704
set Unicode_Result=霰
exit/b
:Unicode霰
set Unicode_Result=38704
exit/b
:Unicode38718
set Unicode_Result=霾
exit/b
:Unicode霾
set Unicode_Result=38718
exit/b
:Unicode40832
set Unicode_Result=龀
exit/b
:Unicode龀
set Unicode_Result=40832
exit/b
:Unicode40835
set Unicode_Result=龃
exit/b
:Unicode龃
set Unicode_Result=40835
exit/b
:Unicode40837
set Unicode_Result=龅
exit/b
:Unicode龅
set Unicode_Result=40837
exit/b
:Unicode40838
set Unicode_Result=龆
exit/b
:Unicode龆
set Unicode_Result=40838
exit/b
:Unicode40839
set Unicode_Result=龇
exit/b
:Unicode龇
set Unicode_Result=40839
exit/b
:Unicode40840
set Unicode_Result=龈
exit/b
:Unicode龈
set Unicode_Result=40840
exit/b
:Unicode40841
set Unicode_Result=龉
exit/b
:Unicode龉
set Unicode_Result=40841
exit/b
:Unicode40842
set Unicode_Result=龊
exit/b
:Unicode龊
set Unicode_Result=40842
exit/b
:Unicode40844
set Unicode_Result=龌
exit/b
:Unicode龌
set Unicode_Result=40844
exit/b
:Unicode40702
set Unicode_Result=黾
exit/b
:Unicode黾
set Unicode_Result=40702
exit/b
:Unicode40715
set Unicode_Result=鼋
exit/b
:Unicode鼋
set Unicode_Result=40715
exit/b
:Unicode40717
set Unicode_Result=鼍
exit/b
:Unicode鼍
set Unicode_Result=40717
exit/b
:Unicode38585
set Unicode_Result=隹
exit/b
:Unicode隹
set Unicode_Result=38585
exit/b
:Unicode38588
set Unicode_Result=隼
exit/b
:Unicode隼
set Unicode_Result=38588
exit/b
:Unicode38589
set Unicode_Result=隽
exit/b
:Unicode隽
set Unicode_Result=38589
exit/b
:Unicode38606
set Unicode_Result=雎
exit/b
:Unicode雎
set Unicode_Result=38606
exit/b
:Unicode38610
set Unicode_Result=雒
exit/b
:Unicode雒
set Unicode_Result=38610
exit/b
:Unicode30655
set Unicode_Result=瞿
exit/b
:Unicode瞿
set Unicode_Result=30655
exit/b
:Unicode38624
set Unicode_Result=雠
exit/b
:Unicode雠
set Unicode_Result=38624
exit/b
:Unicode37518
set Unicode_Result=銎
exit/b
:Unicode銎
set Unicode_Result=37518
exit/b
:Unicode37550
set Unicode_Result=銮
exit/b
:Unicode銮
set Unicode_Result=37550
exit/b
:Unicode37576
set Unicode_Result=鋈
exit/b
:Unicode鋈
set Unicode_Result=37576
exit/b
:Unicode37694
set Unicode_Result=錾
exit/b
:Unicode錾
set Unicode_Result=37694
exit/b
:Unicode37738
set Unicode_Result=鍪
exit/b
:Unicode鍪
set Unicode_Result=37738
exit/b
:Unicode37834
set Unicode_Result=鏊
exit/b
:Unicode鏊
set Unicode_Result=37834
exit/b
:Unicode37775
set Unicode_Result=鎏
exit/b
:Unicode鎏
set Unicode_Result=37775
exit/b
:Unicode37950
set Unicode_Result=鐾
exit/b
:Unicode鐾
set Unicode_Result=37950
exit/b
:Unicode37995
set Unicode_Result=鑫
exit/b
:Unicode鑫
set Unicode_Result=37995
exit/b
:Unicode40063
set Unicode_Result=鱿
exit/b
:Unicode鱿
set Unicode_Result=40063
exit/b
:Unicode40066
set Unicode_Result=鲂
exit/b
:Unicode鲂
set Unicode_Result=40066
exit/b
:Unicode40069
set Unicode_Result=鲅
exit/b
:Unicode鲅
set Unicode_Result=40069
exit/b
:Unicode40070
set Unicode_Result=鲆
exit/b
:Unicode鲆
set Unicode_Result=40070
exit/b
:Unicode40071
set Unicode_Result=鲇
exit/b
:Unicode鲇
set Unicode_Result=40071
exit/b
:Unicode40072
set Unicode_Result=鲈
exit/b
:Unicode鲈
set Unicode_Result=40072
exit/b
:Unicode31267
set Unicode_Result=稣
exit/b
:Unicode稣
set Unicode_Result=31267
exit/b
:Unicode40075
set Unicode_Result=鲋
exit/b
:Unicode鲋
set Unicode_Result=40075
exit/b
:Unicode40078
set Unicode_Result=鲎
exit/b
:Unicode鲎
set Unicode_Result=40078
exit/b
:Unicode40080
set Unicode_Result=鲐
exit/b
:Unicode鲐
set Unicode_Result=40080
exit/b
:Unicode40081
set Unicode_Result=鲑
exit/b
:Unicode鲑
set Unicode_Result=40081
exit/b
:Unicode40082
set Unicode_Result=鲒
exit/b
:Unicode鲒
set Unicode_Result=40082
exit/b
:Unicode40084
set Unicode_Result=鲔
exit/b
:Unicode鲔
set Unicode_Result=40084
exit/b
:Unicode40085
set Unicode_Result=鲕
exit/b
:Unicode鲕
set Unicode_Result=40085
exit/b
:Unicode40090
set Unicode_Result=鲚
exit/b
:Unicode鲚
set Unicode_Result=40090
exit/b
:Unicode40091
set Unicode_Result=鲛
exit/b
:Unicode鲛
set Unicode_Result=40091
exit/b
:Unicode40094
set Unicode_Result=鲞
exit/b
:Unicode鲞
set Unicode_Result=40094
exit/b
:Unicode40095
set Unicode_Result=鲟
exit/b
:Unicode鲟
set Unicode_Result=40095
exit/b
:Unicode40096
set Unicode_Result=鲠
exit/b
:Unicode鲠
set Unicode_Result=40096
exit/b
:Unicode40097
set Unicode_Result=鲡
exit/b
:Unicode鲡
set Unicode_Result=40097
exit/b
:Unicode40098
set Unicode_Result=鲢
exit/b
:Unicode鲢
set Unicode_Result=40098
exit/b
:Unicode40099
set Unicode_Result=鲣
exit/b
:Unicode鲣
set Unicode_Result=40099
exit/b
:Unicode40101
set Unicode_Result=鲥
exit/b
:Unicode鲥
set Unicode_Result=40101
exit/b
:Unicode40102
set Unicode_Result=鲦
exit/b
:Unicode鲦
set Unicode_Result=40102
exit/b
:Unicode40103
set Unicode_Result=鲧
exit/b
:Unicode鲧
set Unicode_Result=40103
exit/b
:Unicode40104
set Unicode_Result=鲨
exit/b
:Unicode鲨
set Unicode_Result=40104
exit/b
:Unicode40105
set Unicode_Result=鲩
exit/b
:Unicode鲩
set Unicode_Result=40105
exit/b
:Unicode40107
set Unicode_Result=鲫
exit/b
:Unicode鲫
set Unicode_Result=40107
exit/b
:Unicode40109
set Unicode_Result=鲭
exit/b
:Unicode鲭
set Unicode_Result=40109
exit/b
:Unicode40110
set Unicode_Result=鲮
exit/b
:Unicode鲮
set Unicode_Result=40110
exit/b
:Unicode40112
set Unicode_Result=鲰
exit/b
:Unicode鲰
set Unicode_Result=40112
exit/b
:Unicode40113
set Unicode_Result=鲱
exit/b
:Unicode鲱
set Unicode_Result=40113
exit/b
:Unicode40114
set Unicode_Result=鲲
exit/b
:Unicode鲲
set Unicode_Result=40114
exit/b
:Unicode40115
set Unicode_Result=鲳
exit/b
:Unicode鲳
set Unicode_Result=40115
exit/b
:Unicode40116
set Unicode_Result=鲴
exit/b
:Unicode鲴
set Unicode_Result=40116
exit/b
:Unicode40117
set Unicode_Result=鲵
exit/b
:Unicode鲵
set Unicode_Result=40117
exit/b
:Unicode40118
set Unicode_Result=鲶
exit/b
:Unicode鲶
set Unicode_Result=40118
exit/b
:Unicode40119
set Unicode_Result=鲷
exit/b
:Unicode鲷
set Unicode_Result=40119
exit/b
:Unicode40122
set Unicode_Result=鲺
exit/b
:Unicode鲺
set Unicode_Result=40122
exit/b
:Unicode40123
set Unicode_Result=鲻
exit/b
:Unicode鲻
set Unicode_Result=40123
exit/b
:Unicode40124
set Unicode_Result=鲼
exit/b
:Unicode鲼
set Unicode_Result=40124
exit/b
:Unicode40125
set Unicode_Result=鲽
exit/b
:Unicode鲽
set Unicode_Result=40125
exit/b
:Unicode40132
set Unicode_Result=鳄
exit/b
:Unicode鳄
set Unicode_Result=40132
exit/b
:Unicode40133
set Unicode_Result=鳅
exit/b
:Unicode鳅
set Unicode_Result=40133
exit/b
:Unicode40134
set Unicode_Result=鳆
exit/b
:Unicode鳆
set Unicode_Result=40134
exit/b
:Unicode40135
set Unicode_Result=鳇
exit/b
:Unicode鳇
set Unicode_Result=40135
exit/b
:Unicode40138
set Unicode_Result=鳊
exit/b
:Unicode鳊
set Unicode_Result=40138
exit/b
:Unicode40139
set Unicode_Result=鳋
exit/b
:Unicode鳋
set Unicode_Result=40139
exit/b
:Unicode40140
set Unicode_Result=鳌
exit/b
:Unicode鳌
set Unicode_Result=40140
exit/b
:Unicode40141
set Unicode_Result=鳍
exit/b
:Unicode鳍
set Unicode_Result=40141
exit/b
:Unicode40142
set Unicode_Result=鳎
exit/b
:Unicode鳎
set Unicode_Result=40142
exit/b
:Unicode40143
set Unicode_Result=鳏
exit/b
:Unicode鳏
set Unicode_Result=40143
exit/b
:Unicode40144
set Unicode_Result=鳐
exit/b
:Unicode鳐
set Unicode_Result=40144
exit/b
:Unicode40147
set Unicode_Result=鳓
exit/b
:Unicode鳓
set Unicode_Result=40147
exit/b
:Unicode40148
set Unicode_Result=鳔
exit/b
:Unicode鳔
set Unicode_Result=40148
exit/b
:Unicode40149
set Unicode_Result=鳕
exit/b
:Unicode鳕
set Unicode_Result=40149
exit/b
:Unicode40151
set Unicode_Result=鳗
exit/b
:Unicode鳗
set Unicode_Result=40151
exit/b
:Unicode40152
set Unicode_Result=鳘
exit/b
:Unicode鳘
set Unicode_Result=40152
exit/b
:Unicode40153
set Unicode_Result=鳙
exit/b
:Unicode鳙
set Unicode_Result=40153
exit/b
:Unicode40156
set Unicode_Result=鳜
exit/b
:Unicode鳜
set Unicode_Result=40156
exit/b
:Unicode40157
set Unicode_Result=鳝
exit/b
:Unicode鳝
set Unicode_Result=40157
exit/b
:Unicode40159
set Unicode_Result=鳟
exit/b
:Unicode鳟
set Unicode_Result=40159
exit/b
:Unicode40162
set Unicode_Result=鳢
exit/b
:Unicode鳢
set Unicode_Result=40162
exit/b
:Unicode38780
set Unicode_Result=靼
exit/b
:Unicode靼
set Unicode_Result=38780
exit/b
:Unicode38789
set Unicode_Result=鞅
exit/b
:Unicode鞅
set Unicode_Result=38789
exit/b
:Unicode38801
set Unicode_Result=鞑
exit/b
:Unicode鞑
set Unicode_Result=38801
exit/b
:Unicode38802
set Unicode_Result=鞒
exit/b
:Unicode鞒
set Unicode_Result=38802
exit/b
:Unicode38804
set Unicode_Result=鞔
exit/b
:Unicode鞔
set Unicode_Result=38804
exit/b
:Unicode38831
set Unicode_Result=鞯
exit/b
:Unicode鞯
set Unicode_Result=38831
exit/b
:Unicode38827
set Unicode_Result=鞫
exit/b
:Unicode鞫
set Unicode_Result=38827
exit/b
:Unicode38819
set Unicode_Result=鞣
exit/b
:Unicode鞣
set Unicode_Result=38819
exit/b
:Unicode38834
set Unicode_Result=鞲
exit/b
:Unicode鞲
set Unicode_Result=38834
exit/b
:Unicode38836
set Unicode_Result=鞴
exit/b
:Unicode鞴
set Unicode_Result=38836
exit/b
:Unicode39601
set Unicode_Result=骱
exit/b
:Unicode骱
set Unicode_Result=39601
exit/b
:Unicode39600
set Unicode_Result=骰
exit/b
:Unicode骰
set Unicode_Result=39600
exit/b
:Unicode39607
set Unicode_Result=骷
exit/b
:Unicode骷
set Unicode_Result=39607
exit/b
:Unicode40536
set Unicode_Result=鹘
exit/b
:Unicode鹘
set Unicode_Result=40536
exit/b
:Unicode39606
set Unicode_Result=骶
exit/b
:Unicode骶
set Unicode_Result=39606
exit/b
:Unicode39610
set Unicode_Result=骺
exit/b
:Unicode骺
set Unicode_Result=39610
exit/b
:Unicode39612
set Unicode_Result=骼
exit/b
:Unicode骼
set Unicode_Result=39612
exit/b
:Unicode39617
set Unicode_Result=髁
exit/b
:Unicode髁
set Unicode_Result=39617
exit/b
:Unicode39616
set Unicode_Result=髀
exit/b
:Unicode髀
set Unicode_Result=39616
exit/b
:Unicode39621
set Unicode_Result=髅
exit/b
:Unicode髅
set Unicode_Result=39621
exit/b
:Unicode39618
set Unicode_Result=髂
exit/b
:Unicode髂
set Unicode_Result=39618
exit/b
:Unicode39627
set Unicode_Result=髋
exit/b
:Unicode髋
set Unicode_Result=39627
exit/b
:Unicode39628
set Unicode_Result=髌
exit/b
:Unicode髌
set Unicode_Result=39628
exit/b
:Unicode39633
set Unicode_Result=髑
exit/b
:Unicode髑
set Unicode_Result=39633
exit/b
:Unicode39749
set Unicode_Result=魅
exit/b
:Unicode魅
set Unicode_Result=39749
exit/b
:Unicode39747
set Unicode_Result=魃
exit/b
:Unicode魃
set Unicode_Result=39747
exit/b
:Unicode39751
set Unicode_Result=魇
exit/b
:Unicode魇
set Unicode_Result=39751
exit/b
:Unicode39753
set Unicode_Result=魉
exit/b
:Unicode魉
set Unicode_Result=39753
exit/b
:Unicode39752
set Unicode_Result=魈
exit/b
:Unicode魈
set Unicode_Result=39752
exit/b
:Unicode39757
set Unicode_Result=魍
exit/b
:Unicode魍
set Unicode_Result=39757
exit/b
:Unicode39761
set Unicode_Result=魑
exit/b
:Unicode魑
set Unicode_Result=39761
exit/b
:Unicode39144
set Unicode_Result=飨
exit/b
:Unicode飨
set Unicode_Result=39144
exit/b
:Unicode39181
set Unicode_Result=餍
exit/b
:Unicode餍
set Unicode_Result=39181
exit/b
:Unicode39214
set Unicode_Result=餮
exit/b
:Unicode餮
set Unicode_Result=39214
exit/b
:Unicode39253
set Unicode_Result=饕
exit/b
:Unicode饕
set Unicode_Result=39253
exit/b
:Unicode39252
set Unicode_Result=饔
exit/b
:Unicode饔
set Unicode_Result=39252
exit/b
:Unicode39647
set Unicode_Result=髟
exit/b
:Unicode髟
set Unicode_Result=39647
exit/b
:Unicode39649
set Unicode_Result=髡
exit/b
:Unicode髡
set Unicode_Result=39649
exit/b
:Unicode39654
set Unicode_Result=髦
exit/b
:Unicode髦
set Unicode_Result=39654
exit/b
:Unicode39663
set Unicode_Result=髯
exit/b
:Unicode髯
set Unicode_Result=39663
exit/b
:Unicode39659
set Unicode_Result=髫
exit/b
:Unicode髫
set Unicode_Result=39659
exit/b
:Unicode39675
set Unicode_Result=髻
exit/b
:Unicode髻
set Unicode_Result=39675
exit/b
:Unicode39661
set Unicode_Result=髭
exit/b
:Unicode髭
set Unicode_Result=39661
exit/b
:Unicode39673
set Unicode_Result=髹
exit/b
:Unicode髹
set Unicode_Result=39673
exit/b
:Unicode39688
set Unicode_Result=鬈
exit/b
:Unicode鬈
set Unicode_Result=39688
exit/b
:Unicode39695
set Unicode_Result=鬏
exit/b
:Unicode鬏
set Unicode_Result=39695
exit/b
:Unicode39699
set Unicode_Result=鬓
exit/b
:Unicode鬓
set Unicode_Result=39699
exit/b
:Unicode39711
set Unicode_Result=鬟
exit/b
:Unicode鬟
set Unicode_Result=39711
exit/b
:Unicode39715
set Unicode_Result=鬣
exit/b
:Unicode鬣
set Unicode_Result=39715
exit/b
:Unicode40637
set Unicode_Result=麽
exit/b
:Unicode麽
set Unicode_Result=40637
exit/b
:Unicode40638
set Unicode_Result=麾
exit/b
:Unicode麾
set Unicode_Result=40638
exit/b
:Unicode32315
set Unicode_Result=縻
exit/b
:Unicode縻
set Unicode_Result=32315
exit/b
:Unicode40578
set Unicode_Result=麂
exit/b
:Unicode麂
set Unicode_Result=40578
exit/b
:Unicode40583
set Unicode_Result=麇
exit/b
:Unicode麇
set Unicode_Result=40583
exit/b
:Unicode40584
set Unicode_Result=麈
exit/b
:Unicode麈
set Unicode_Result=40584
exit/b
:Unicode40587
set Unicode_Result=麋
exit/b
:Unicode麋
set Unicode_Result=40587
exit/b
:Unicode40594
set Unicode_Result=麒
exit/b
:Unicode麒
set Unicode_Result=40594
exit/b
:Unicode37846
set Unicode_Result=鏖
exit/b
:Unicode鏖
set Unicode_Result=37846
exit/b
:Unicode40605
set Unicode_Result=麝
exit/b
:Unicode麝
set Unicode_Result=40605
exit/b
:Unicode40607
set Unicode_Result=麟
exit/b
:Unicode麟
set Unicode_Result=40607
exit/b
:Unicode40667
set Unicode_Result=黛
exit/b
:Unicode黛
set Unicode_Result=40667
exit/b
:Unicode40668
set Unicode_Result=黜
exit/b
:Unicode黜
set Unicode_Result=40668
exit/b
:Unicode40669
set Unicode_Result=黝
exit/b
:Unicode黝
set Unicode_Result=40669
exit/b
:Unicode40672
set Unicode_Result=黠
exit/b
:Unicode黠
set Unicode_Result=40672
exit/b
:Unicode40671
set Unicode_Result=黟
exit/b
:Unicode黟
set Unicode_Result=40671
exit/b
:Unicode40674
set Unicode_Result=黢
exit/b
:Unicode黢
set Unicode_Result=40674
exit/b
:Unicode40681
set Unicode_Result=黩
exit/b
:Unicode黩
set Unicode_Result=40681
exit/b
:Unicode40679
set Unicode_Result=黧
exit/b
:Unicode黧
set Unicode_Result=40679
exit/b
:Unicode40677
set Unicode_Result=黥
exit/b
:Unicode黥
set Unicode_Result=40677
exit/b
:Unicode40682
set Unicode_Result=黪
exit/b
:Unicode黪
set Unicode_Result=40682
exit/b
:Unicode40687
set Unicode_Result=黯
exit/b
:Unicode黯
set Unicode_Result=40687
exit/b
:Unicode40738
set Unicode_Result=鼢
exit/b
:Unicode鼢
set Unicode_Result=40738
exit/b
:Unicode40748
set Unicode_Result=鼬
exit/b
:Unicode鼬
set Unicode_Result=40748
exit/b
:Unicode40751
set Unicode_Result=鼯
exit/b
:Unicode鼯
set Unicode_Result=40751
exit/b
:Unicode40761
set Unicode_Result=鼹
exit/b
:Unicode鼹
set Unicode_Result=40761
exit/b
:Unicode40759
set Unicode_Result=鼷
exit/b
:Unicode鼷
set Unicode_Result=40759
exit/b
:Unicode40765
set Unicode_Result=鼽
exit/b
:Unicode鼽
set Unicode_Result=40765
exit/b
:Unicode40766
set Unicode_Result=鼾
exit/b
:Unicode鼾
set Unicode_Result=40766
exit/b
:Unicode4077222
set Unicode_Result=齄
exit/b
:Unicode齄
set Unicode_Result=4077222
exit/b

:-----子程序结束标记-----:
:end

