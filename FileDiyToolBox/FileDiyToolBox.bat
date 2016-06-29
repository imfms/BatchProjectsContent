@echo off
cd /d "%~dp0"
setlocal ENABLEDELAYEDEXPANSION
title 文档收集便捷工具箱 20160625 ^| F_Ms ^| f-ms.cn

REM 工具箱基本变量配置
REM set debug=yes
set workDir=FileDiyToolBox
set mainListFile=%workDir%\mainList.ini

REM 工具箱基本目录配置
if not exist "%workDir%\" md "%workDir%\"
if not exist "%mainListFile%" call:createEmptyFile "%mainListFile%"

REM 参数控制
call:argsGet %*

REM 主列表
:mainList
cls
echo=#文档收集便捷工具箱
echo=#主列表

REM 子列表为空的话提示用户添加列表
for /f "usebackq eol= delims=" %%a in ("%mainListFile%") do goto mainList3
echo=#当前子列表为空,请试着添加一个列表
call:addToolToMainList "%mainListFile%"
goto mainList
:mainList3

REM 参数指定子列表直接进入
if defined fDTB_mainListArgs (
	set mainList_userInput=%fDTB_mainListArgs%
	set fDTB_mainListArgs=
	goto mainList4
)

echo=#序列	名称	备注
REM 显示列表
call:Database_Print /ln /q /head " " "%mainListFile%" "	" "	" "0" "1,3"

REM 提示用户选择子列表
set mainList_userInput=
set subListName=
set/p mainList_userInput=#请选择子列表(?):
if not defined mainList_userInput goto mainList
:mainList4
if "%mainList_userInput:~0,1%"=="+" (
	call:addToolToMainList "%mainListFile%" "%mainList_userInput:~1%"
	goto mainList
)
REM 用户删除情况
set mainList_doFlag=
if "%mainList_userInput:~0,1%"=="-" (
	if "%mainList_userInput:~1%"=="" (
		set/p mainList_userInput=#请输入被删除工具的名称或序列:
		set mainList_userInput=-!mainList_userInput!
	)
	call:queRen #确认删除?||goto mainList
	set mainList_userInput=!mainList_userInput:~1!
	set mainList_doFlag=delete
)
REM 帮助
if "%mainList_userInput:~0,1%"=="?" (
	call:help 1
	goto mainList
)
if "%mainList_userInput:~0,1%"=="？" (
	call:help 1
	goto mainList
)
REM 修改
if "%mainList_userInput:~0,1%"=="#" (
	if "%mainList_userInput:~1%"=="" (
		set/p mainList_userInput=#请输入要修改列表的名称或序列:
		set mainList_userInput=#!mainList_userInput!
	)
	set mainList_userInput=!mainList_userInput:~1!
	set mainList_doFlag=change
)
call:DefinedNoNumberString "%mainList_userInput%"
if "%errorlevel%"=="1" goto mainList2

REM 用户输入列表名情况
set mainList_findTemp=
call:Database_Find /q /i "%mainListFile%" "	" "%mainList_userInput%" "0" "1" "mainList_findTemp"
if defined mainList_findTemp (
	for /f "tokens=1" %%a in (%mainList_findTemp%) do set mainList_userInput=%%~a
) else goto mainList

REM 用户输入序号情况
:mainList2
REM 修改情况
if /i "%mainList_doFlag%"=="change" (
	call:changeMainList "%mainList_userInput%" "%mainListFile%"
	goto mainList
)

REM 根据用户选择获取子列表
call:Database_Read /q "%mainListFile%" "	" "%mainList_userInput%" "1-2" "subListName subListFile"
set subListFile=%workDir%\%subListFile%

REM 用户删除列表情况
if /i "%mainList_doFlag%"=="delete" (
	call:Database_DeleteLine /q "%mainListFile%" "%mainList_userInput%" "1"
	if exist "%subListFile%" del /f /q "%subListFile%"
	goto mainList
)

if not defined subListName goto mainList

:subList
cls
echo=#文档收集便捷工具箱
echo=#子列表 : %subListName%
REM 子列表下工具为空的话提示用户添加工具
for /f "usebackq eol= delims=" %%a in ("%subListFile%") do goto subList2
echo=#当前列表工具为空,请试着添加一项工具
call:addToolToSubList "%subListName%" "%subListFile%"
goto subList
:subList2

REM 参数指定子列表直接进入
if defined fDTB_subListArgs (
	set subList_userInput=%fDTB_subListArgs%
	set fDTB_subListArgs=
	goto subList4
)

echo=#序列	名称	备注
call:Database_Print /ln /q /head " " "%subListFile%" "	" "	" "0" "1,3"

REM 提示用户选择工具
set subList_userInput=
set/p subList_userInput=#请选择工具(?):
if not defined subList_userInput goto subList
:subList4
set subList_doFlag=
REM 打开工具目录
if "%subList_userInput:~-1%"==" " if not "%subList_userInput:~0,1%"==" " (
	set subList_userInput=%subList_userInput:~0,-1%
	set subList_doFlag=openDir
)
REM 添加
if "%subList_userInput:~0,1%"=="+" (
	call:addToolToSubList "%subListName%" "%subListFile%" "%subList_userInput:~1%"
	goto subList
)
REM 删除
if "%subList_userInput:~0,1%"=="-" (
	if "%subList_userInput:~1%"=="" (
		set/p subList_userInput=#请输入被删除工具的名称或序列:
		set subList_userInput=-!subList_userInput!
	)
	call:queRen #确认删除?||goto subList
	set subList_userInput=!subList_userInput:~1!
	set subList_doFlag=delete
)
REM 修改
if "%subList_userInput:~0,1%"=="#" (
	if "%subList_userInput:~1%"=="" (
		set/p subList_userInput=#请输入要修改工具的名称或序列:
		set subList_userInput=#!subList_userInput!
	)
	set subList_userInput=!subList_userInput:~1!
	set subList_doFlag=change
)
REM 返回主菜单
if "%subList_userInput:~0,1%"=="0" (
	goto mainList
)
REM 帮助
if "%subList_userInput:~0,1%"=="?" (
	call:help 2
	goto subList
)
if "%subList_userInput:~0,1%"=="？" (
	call:help 2
	goto subList
)

call:DefinedNoNumberString "%subList_userInput%"
if "%errorlevel%"=="1" goto subList3
REM 用户输入工具名情况
set subList_findTemp=
call:Database_Find /q /i /first "%subListFile%" "	" "%subList_userInput%" "0" "1" "subList_findTemp"
if defined subList_findTemp (
	for /f "tokens=1" %%a in (%subList_findTemp%) do set subList_userInput=%%~a
) else goto subList

REM 用户输入序号情况
:subList3

REM 删除情况
if /i "%subList_doFlag%"=="delete" (
	call:Database_DeleteLine /q "%subListFile%" "%subList_userInput%" "1"
	goto subList
)
REM 修改情况
if /i "%subList_doFlag%"=="change" (
	call:changeSubList "%subList_userInput%" "%subListFile%"
	goto subList
)

REM 根据用户选择获取工具并打开
for %%a in (subList_userInput_path, subList_userInput_args, subList_userInput_startPath) do set %%a=
call:Database_Read /q "%subListFile%" "	" "%subList_userInput%" "2,4,5" "subList_userInput_path subList_userInput_args subList_userInput_startPath"

if not defined subList_userInput_path goto subList
if not exist "%subList_userInput_path%" (
	echo=#错误:指定工具已不存在,请检查是否已将工具移动或删除
	echo=	可使用 #工具名称 命令进行修改路径
	pause
	goto subList
)

REM 批处理脚本打开方法处理
set fDTB_Run_method=start /normal ""
for %%a in (".bat", ".cmd") do if /i "%subList_userInput_path:~-4%"=="%%~a" set fDTB_Run_method=

REM 起始目录处理
REM 起始目录存在情况
if defined fDTB_Run_startPath set "subList_userInput_startPath=%fDTB_Run_startPath%" & goto subList4
if defined subList_userInput_startPath if not "%subList_userInput_startPath%"==" " if exist "%subList_userInput_startPath%" (
	goto subList4
) else call:queRen "#检测到起始目录已不存在,是否以工具目录为起始目录打开?"||goto subList
REM 起始目录不存在情况
if exist "%subList_userInput_path%\" (
	set "subList_userInput_startPath=%subList_userInput_path%"
) else for %%a in ("%subList_userInput_path%") do set "subList_userInput_startPath=%%~dpa"

:subList4
pushd "%subList_userInput_startPath%"
if /i "%subList_doFlag%"=="openDir" (
	start /normal "" explorer.exe /select,"%subList_userInput_path%"
) else (
	REM 根据参数打开工具
	%fDTB_Run_method% "%subList_userInput_path%" %subList_userInput_args% %fDTB_Run_Args%
)
popd
exit/b 0



goto end
:-----------------------------------------------------------子程序开始分割线-----------------------------------------------------------:

REM 向子列表中添加工具
REM call:addToolToSubList "子列表名称" "子列表文件路径"
:addToolToSubList
REM 运行参数检查
if "%~2"=="" (
	if defined debug (
		echo=#addToolToSubList:子列表文件路径为空
		pause
	)
	exit/b 2
) else if not exist "%~2" (
	if defined debug (
		echo=#addToolToSubList:子列表文件路径不存在
		pause
	)
	exit/b 2
) else if "%~1"=="" (
	if defined debug (
		echo=#addToolToSubList:子列表名称为空
		pause
	)
	exit/b 2
)

echo=#添加工具到: %~1
if not "%~3"=="" (
	set aTTSL_toolName=%~3
	shift/3
	goto addToolToSubList_name2
)

:addToolToSubList_name
set aTTSL_toolName=
set /p aTTSL_toolName=^|	工具名称:
:addToolToSubList_name2
if not defined aTTSL_toolName goto addToolToSubList_name
call:checkToolName "%aTTSL_toolName%" "%~2"
if not "%errorlevel%"=="0" (
	goto addToolToSubList_name
)
:addToolToSubList_path
set aTTSL_toolPath=
set /p aTTSL_toolPath=^|	工具路径:
if not defined aTTSL_toolPath goto addToolToSubList_path
set aTTSL_toolPath=%aTTSL_toolPath:"=%
if not exist "%aTTSL_toolPath%" (
	call:pathFind /q "%aTTSL_toolPath%" aTTSL_toolPath||(
		echo=		文件不存在,请重试
		goto addToolToSubList_Path
	)
)

:addToolToSubList_startPath
set aTTSL_toolStartPath=
set /p aTTSL_toolStartPath=^|	起始目录(可选):
REM 起始目录默认为工具所在路径
if not defined aTTSL_toolStartPath (
	set aTTSL_toolStartPath= 
	goto addToolToSubList_args
)
REM 用户输入必须为文件夹
set aTTSL_toolStartPath=%aTTSL_toolStartPath:"=%
if not exist "%aTTSL_toolStartPath%" (
	echo=		目录不存在,请重试
	goto addToolToSubList_startPath
)
if not exist "%aTTSL_toolStartPath%\" (
	echo=		输入非目录,请重试
	goto addToolToSubList_startPath
)

:addToolToSubList_args
set aTTSL_toolArgs=
set /p aTTSL_toolArgs=^|	运行参数(可选):
if not defined aTTSL_toolArgs set aTTSL_toolArgs= 

:addToolToSubList_comment
set aTTSL_toolComment=
set /p aTTSL_toolComment=^|	备注(可选):
if not defined aTTSL_toolComment set aTTSL_toolComment=无
call:Database_Insert /q "%~2" "	" "%aTTSL_toolName%" "%aTTSL_toolPath%" "%aTTSL_toolComment%" "%aTTSL_toolArgs%" "%aTTSL_toolStartPath%"
exit/b 0

REM 修改子列表内容
REM call:changeMainList "修改数据行标" "数据文件位置"
:changeMainList
if "%~2"=="" (
	if defined debug (
		echo=#错误:changeMainList:未指定数据文件位置
		pause
	)
	exit/b 2
) else if not exist "%~2" (
	if defined debug (
		echo=#错误:changeMainList:指定数据文件不存在
		pause
	)
	exit/b 2
)
if "%~1"=="" (
	if defined debug (
		echo=#错误:changeMainList:未指定修改数据行标
		pause
	)
	exit/b 2
) else (
	call:DefinedNoNumberString "%~1"&&(
		if defined debug (
			echo=#错误:changeMainList:指定修改数据行标不合规
			pause
		)
		exit/b 2
	)
)
for %%a in (changeMainList_name changeMainList_comment) do set %%a=
call:Database_Read /q "%~2" "	" "%~1" "1,3" "changeMainList_name changeMainList_comment"
:changeMainList2
cls
echo=#文档收集便捷工具箱
echo=#列表属性修改
echo= 1. 名称: %changeMainList_name%
echo= 2. 备注: %changeMainList_comment%

set changeMainList_userInput=
set/p changeMainList_userInput=#请选择属性(?):
if not defined changeMainList_userInput goto changeMainList2
if "%changeMainList_userInput%"=="?" (
	call:help 3
)
if "%changeMainList_userInput%"=="？" (
	call:help 3
)
if not %changeMainlist_userInput% geq 0 goto changeMainList2
if not %changeMainlist_userInput% leq 2 goto changeMainList2
if "%changeMainlist_userInput%"=="0" exit/b 0

set changeMainList_newAttrib=
set/p changeMainList_newAttrib=#请输入新内容:
if not defined changeMainList_newAttrib goto changeMainList2

REM 去除半角引号
set "changeMainList_newAttrib=%changeMainList_newAttrib:"=%"

REM 修改名称
if "%changeMainlist_userInput%"=="1" (
	call:checkToolName "%changeMainList_newAttrib%" "%~2"||(
		pause
		goto changeMainList2
	)
	call:Database_Update /q "%~2" "	" "%~1" "1" "%changeMainList_newAttrib%"
	set "changeMainList_name=%changeMainList_newAttrib%"
)
REM 修改备注
if "%changeMainlist_userInput%"=="2" (
	call:Database_Update /q "%~2" "	" "%~1" "3" "%changeMainList_newAttrib%"
	set "changeMainList_comment=%changeMainList_newAttrib%"
)
goto changeMainList2
exit/b 0

REM 修改工具内容
REM call:changeSubList "修改数据行标" "数据文件位置"
:changeSubList
if "%~2"=="" (
	if defined debug (
		echo=#错误:changeSubList:未指定数据文件位置
		pause
	)
	exit/b 2
) else if not exist "%~2" (
	if defined debug (
		echo=#错误:changeSubList:指定数据文件不存在
		pause
	)
	exit/b 2
)
if "%~1"=="" (
	if defined debug (
		echo=#错误:changeSubList:未指定修改数据行标
		pause
	)
	exit/b 2
) else (
	call:DefinedNoNumberString "%~1"&&(
		if defined debug (
			echo=#错误:changeSubList:指定修改数据行标不合规
			pause
		)
		exit/b 2
	)
)
for %%a in (changeSubList_name changeSubList_path changeSubList_comment changeSubList_args changeSubList_startPath) do set %%a=
call:Database_Read /q "%~2" "	" "%~1" "1-5" "changeSubList_name changeSubList_path changeSubList_comment changeSubList_args changeSubList_startPath"
:changeSubList2
cls
echo=#文档收集便捷工具箱
echo=#工具属性修改
echo= 1. 名称: %changeSubList_name%
echo= 2. 路径: %changeSubList_path%
echo= 3. 参数: %changeSubList_args%
echo= 4. 起始目录: %changeSubList_startPath%
echo= 5. 备注: %changeSubList_comment%

set changeSubList_userInput=
set/p changeSubList_userInput=#请选择属性(?):
if not defined changeSubList_userInput goto changeSubList2
if "%changeSubList_userInput%"=="?" (
	call:help 3
)
if "%changeSubList_userInput%"=="？" (
	call:help 3
)
if not %changeSublist_userInput% geq 0 goto changeSubList2
if not %changeSublist_userInput% leq 5 goto changeSubList2
if "%changeSublist_userInput%"=="0" exit/b 0

set changeSubList_newAttrib=
set/p changeSubList_newAttrib=#请输入新内容:
if not defined changeSubList_newAttrib goto changeSubList2

REM 去除半角引号
set "changeSublist_newAttrib=%changeSublist_newAttrib:"=%"

REM 修改名称
if "%changeSublist_userInput%"=="1" (
	call:checkToolName "%changeSubList_newAttrib%" "%~2"||(
		pause
		goto changeSubList2
	)
	call:Database_Update /q "%~2" "	" "%~1" "1" "%changeSubList_newAttrib%"
	set "changeSubList_name=%changeSubList_newAttrib%"
)
REM 修改路径
if "%changeSublist_userInput%"=="2" (
	if not exist "!changeSublist_newAttrib!" (
		call:pathFind /q "%changeSublist_newAttrib%" changeSublist_newAttrib||(
			echo=		文件不存在,请重试
			pause
			goto changeSubList2
		)
	)
	call:Database_Update /q "%~2" "	" "%~1" "2" "!changeSubList_newAttrib!"
	set "changeSubList_path=!changeSubList_newAttrib!"
)
REM 修改参数
if "%changeSublist_userInput%"=="3" (
	call:Database_Update /q "%~2" "	" "%~1" "4" "%changeSubList_newAttrib%"
	set "changeSubList_args=%changeSubList_newAttrib%"
)
REM 修改起始目录
if "%changeSublist_userInput%"=="4" (
	if not "!changeSubList_newAttrib!"==" " (
		if not exist "!changeSublist_newAttrib!" (
			echo=		路径不存在,请重试
			pause
			goto changeSubList2
		)
		if not exist "!changeSublist_newAttrib!\" (
			echo=		输入非目录,请重试
			pause
			goto changeSubList2
		)
	)
	call:Database_Update /q "%~2" "	" "%~1" "5" "!changeSubList_newAttrib!"
	set "changeSubList_startPath=!changeSubList_newAttrib!"
)
REM 修改备注
if "%changeSublist_userInput%"=="5" (
	call:Database_Update /q "%~2" "	" "%~1" "3" "%changeSubList_newAttrib%"
	set "changeSubList_comment=%changeSubList_newAttrib%"
)
goto changeSubList2
exit/b 0



REM 向主列表中添加子列表
REM call:addToolToMainList "主列表库文件路径"
:addToolToMainList
REM 运行参数检查
if "%~1"=="" (
	if defined debug (
		echo=#addToolToMainList:主列表库文件路径为空
		pause
	)
	exit/b 2
) else if not exist "%~1" (
	if defined debug (
		echo=#addToolToMainList:主列表库文件路径不存在
		pause
	)
	exit/b 2
)

echo=#添加列表
if not "%~2"=="" (
	set aTTML_toolName=%~2
	shift/2
	goto addToolToMainList_name2
)

:addToolToMainList_name
set aTTML_toolName=
set /p aTTML_toolName=^|	列表名称:
:addToolToMainList_name2
if not defined aTTML_toolName goto addToolToMainList_name
call:checkToolName "%aTTML_toolName%" "%~1"
if not "%errorlevel%"=="0" (
	goto addToolToMainList_name
)

:addToolToMainList_comment
set aTTML_toolComment=
set /p aTTML_toolComment=^|	备注(可选):
if not defined aTTML_toolComment set aTTML_toolComment=无
call:Database_Insert /q "%~1" "	" "%aTTML_toolName%" "%aTTML_toolName%.txtDB" "%aTTML_toolComment%"
call:createEmptyFile "%workDir%\%aTTML_toolName%.txtDB"
exit/b 0

REM 列表/工具名称合规判断
REM call:checkToolName "名称" "库重复检查文件"
:checkToolName
if "%~2"=="" (
	if defined debug (
		echo=#错误:checkToolName:未指定库重复检查文件
		pause
	)
	exit/b 2
) else if not exist "%~2" (
	if defined debug (
		echo=#错误:checkToolName:指定库重复检查文件不存在
		pause
	)
)
if "%~1"=="" (
	if defined debug (
		echo=#错误:checkToolName:未指定检测名称
		pause
	)
	exit/b 2
)
set checkToolName_toolName=
set checkToolName_toolName=%~1
if not defined checkToolName_toolName exit/b 1
if "%checkToolName_toolName:~0,1%"=="+" (
	echo=		名称不能以 + - # ?^(保留符^) 开头，请尝试更换名称
	exit/b 1
)
if "%checkToolName_toolName:~0,1%"=="-" (
	echo=		名称不能以 + - # ?^(保留符^) 开头，请尝试更换名称
	exit/b 1
)
if "%checkToolName_toolName:~-1%"==" " (
	echo=		名称不能以空格结尾，请尝试更换名称
	exit/b 1
)
if "%checkToolName_toolName:~0,1%"=="?" (
	echo=		名称不能以 + - # ?^(保留符^) 开头，请尝试更换名称
	exit/b 1
)
if "%checkToolName_toolName:~0,1%"=="#" (
	echo=		名称不能以 + - # ?^(保留符^) 开头，请尝试更换名称
	exit/b 1
)
if "%checkToolName_toolName:~0,1%"=="？" (
	echo=		名称不能以 + - # ?^(保留符^) 开头，请尝试更换名称
	exit/b 1
)
if /i "%checkToolName_toolName%"=="/args" (
	echo=		名称不能为 /args /path ^(保留字^)，请尝试更换名称
	exit/b 1
)
if /i "%checkToolName_toolName%"=="/path" (
	echo=		名称不能为 /args /path ^(保留字^)，请尝试更换名称
	exit/b 1
)


call:DefinedNoNumberString "%checkToolName_toolName:~0,1%"
if "%errorlevel%"=="1" (
	echo=		名称不能以数字开头,请尝试更换名称
	exit/b 1
)
call:Database_Find /q /i /first "%~2" "	" "%checkToolName_toolName%" "0" "1" "checkToolName_find2temp"
if defined checkToolName_find2temp (
	echo=		名称: %checkToolName_toolName% 已存在, 请尝试更换名称
	exit/b 1
)
exit/b 0

REM 参数获取
REM call:argsGet %*
:argsGet
for %%a in (fDTB_Run_Args, fDTB_mainListArgs, fDTB_subListArgs, fDTB_Run_startPath) do set %%a=

:argsGet1_2
set fDTB_Run_ArgsTemp=
set fDTB_Run_ArgsTemp=%1
if defined fDTB_Run_ArgsTemp if /i "/path"=="%~1" (
	if exist "%~2\" (
		set "fDTB_Run_startPath=%~2"
	)
	shift/1
	shift/1
	goto argsGet1_2
) else if /i "/args"=="%~1" (
	shift/1
	goto argsGet2
) else (
	if not defined fDTB_mainListArgs (
		set fDTB_mainListArgs=%~1
	) else if not defined fDTB_subListArgs (
		set fDTB_subListArgs=%~1
	)
	shift/1
	goto argsGet1_2
)
exit/b 0

:argsGet2
set fDTB_Run_ArgsTemp=
set fDTB_Run_ArgsTemp=%1
if not defined fDTB_Run_ArgsTemp goto argsGet3
set fDTB_Run_Args=%fDTB_Run_Args% %1
shift/1
goto argsGet2
:argsGet3
exit/b 0

REM 确认？
REM 20160502
REM call:queRen ["提示内容"] ["确认按键"] ["取消按键"]
REM 返回值：0-用户确认，1-用户取消
:queRen
set queRen_tips=确认?
set queRen_yes=Y
set queRen_no=

if not "%~1"=="" set queRen_tips=%~1
if not "%~2"=="" set queRen_yes=%~2
if not "%~3"=="" set queRen_no=%~3
set queRen_tips=%queRen_tips% [是:%queRen_yes%
if defined queRen_no (
	set queRen_tips=%queRen_tips%/否:%queRen_no%]
) else (
	set queRen_tips=%queRen_tips%]
)

:queRen2
set queRen_user=
set /p queRen_user=%queRen_tips%:
if defined queRen_user (
	
	if /i "%queRen_user%"=="%queRen_yes%" exit/b 0
	if defined queRen_no if /i not "%queRen_user%"=="%queRen_no%" goto queRen2
	
) else (
	if defined queRen_no goto queRen2
)
exit/b 1

REM 创建空文件 20160425
REM call:createEmptyFile "文件名"
REM 返回值：1 - 文件生成失败， 2 - 调用参数错误， 0 - 成功
:createEmptyFile
REM 判断参数是否正确
if "%~1"=="" (
	if defined debug (
		echo=#createEmptyFile:参数为空
		pause
	)
	exit/b 2
)

REM 生成空文件
(
	if a==b echo=此处用于生成空文件
)>"%~1"

if exist "%~1" (
	exit/b 0
) else if defined debug (
	echo=#createEmptyFile:文件生成失败
	pause
)
exit/b 1

REM 帮助
REM call:help [1/2/3]
REM  1 - 主列表帮助
REM  2 - 工具帮助
:help
if "%~1"=="" exit/b 1
if "%~1"=="1" (
	echo=#列表帮助
	echo=	输入列表序列号或名称可直接进入列表
	echo=	+ 添加列表,可在+后直接跟欲添加列表的名称即可
	echo=	- 删除列表,可在-后直接跟欲删除列表序列号或名称
	echo=	# 修改列表,可在#后直接跟欲修改列表序列号或名称
	echo=
	echo=	支持参数调用: "%~nx0" [列表序列或名称] [工具序列或名称] [/path 起始目录] [/args [参数1 参数2 ...]]
	echo=	  例如:
	echo=		打开tool列表: "%~nx0" tool
	echo=		打开tool列表下的ec: "%~nx0" tool ec
	echo=		打开第1个列表的第2项工具: "%~nx0" 1 2
	echo=		打开第1个列表的第2项工具,起始目录为c:\windows: "%~nx0" 1 2 /path c:\windows
	echo=			如工具已有起始目录则失效，将使用参数指定的起始目录
	echo=		打开tool列表下的ec并将参数/f /q传递给ec: "%~nx0" tool ec /args /f /q
	echo=			如果工具已有参数则指定参数会添加到已有参数后
	echo=		打开tool列表下ec并将参数,起始目录为c:\windows并将/f /q参数传递
	echo=			"%~nx0" tool ec /path c:\windows /args /f /q
	echo=
	pause
)
if "%~1"=="2" (
	echo=#工具帮助
	echo=	输入工具序列号或名称可直接打开工具
	echo=	  工具序列号或名称后跟空格可打开工具所在目录
	echo=	+ 添加工具,可在+后直接跟欲添加工具名称
	echo=	- 删除工具,可在-后直接跟欲删除工具序列号或名称
	echo=	# 修改工具,可在#后直接跟欲修改工具序列号或名称
	echo=	0 返回主列表
	echo=
	pause
)
if "%~1"=="3" (
	echo=#修改帮助
	echo=	输入指定属性序列号即可修改指定属性
	echo=	0 返回主列表
	echo=	起始目录中设置为空格则工具启动的起始目录为工具所在目录
	pause
)

exit/b 0


REM 从Path目录中查找找到的第一个指定程序可执行程序(pathext扩展名)的全路径
REM call:pathFind [/Q(安静模式)] "查找程序名" "全路径结果接收变量"
REM errorlevel: 0 - 找到, 1 - 未找到, 2 - 参数错误
REM 20160507
:pathFind
REM 使用参数判断
set pathFindQuit=
if /i "%~1"=="/q" (
	set pathFindQuit=yes
	shift/1
)
if "%~2"=="" (
	if not defined pathFindQuit (
		echo=	#错误:pathFind:未指定全路径结果接收变量
		pause
	)
	exit/b 2
)
if "%~1"=="" (
	if not defined pathFindQuit (
		echo=	#错误:pathFind:未指定查找程序名
		pause
	)
	exit/b 2
)
set pathFind_appName=%~1
for %%a in (/,\,:) do if not "%pathFind_appName%"=="!pathFind_appName:%%a=!" exit/b 1

REM 初始化变量
set %~2=
if defined pathext (set pathFind_pathextTemp=%pathext%;.lnk) else set pathFind_pathextTemp=.EXE;.BAT;.CMD;.VBS;.lnk
if not defined path exit/b 1

REM 如果指定程序名含有扩展名的判断
if not "%~x1"=="" set "pathFind_pathextTemp=%~x1"

REM 解析path目录
for /f "delims==" %%a in ('set pathFind_parsePath 2^>nul') do set %%a=
set pathFind_parsePath_count=0
set pathFind_pathTemp=
set pathFind_pathTemp=%path%

:pathFind_parsePath2
set /a pathFind_parsePath_count+=1
for /f "tokens=1,* delims=;" %%a in ("%pathFind_pathTemp%") do (
	set "pathFind_parsePath%pathFind_parsePath_count%=%%~a"
	if not "%%~b"=="" (
		set pathFind_pathTemp=
		set "pathFind_pathTemp=%%~b"
		goto pathFind_parsePath2
	)
)

REM 开始查找
for /l %%a in (1,1,%pathFind_parsePath_count%) do (
	for %%b in (%pathFind_pathextTemp%) do (
		if exist "!pathFind_parsePath%%a!\%~n1%%~b" (
			set "%~2=!pathFind_parsePath%%a!\%~n1%%~b"
			exit/b 0
		)
	)
)
exit/b 1


REM 判断变量中是否含有非数字字符 call:DefinedNoNumberString 被判断字符
REM	返回值0代表有非数字字符，返回值1代表无非数字字符，返回值2代表参数为空
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
REM __________________________________________________________________批处理文本数据库工具箱____________________________________________________________________________
REM 
REM                                                          本工具箱致力于文本数据库的操作效率简易化
REM                                                                        -20160625-
REM                                                     作者：F_Ms | 邮箱：imf_ms@yeah.net | 博客：f-ms.cn
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM 使用方法：
REM 	将子程序模块直接复制到自己代码中后直接根据使用方法调用即可(不会被正常运行到的位置)，每个子程序都可以独立运行，不需要的模块直抛弃就好了
REM 	所有子程序没有使用第三方工具，也没有使用不稳定的结果截取命令结果输出判断，兼容性无问题，WinXP/Win7/Win10测试均未出问题
REM 
REM 注意事项：
REM 	子程序运行需要变量延迟，setlocal ENABLEDELAYEDEXPANSION请注意开启
REM 	子程序使用了以下for %变量 (按十进制ASCII编码字符集排序),请在编写程序时for嵌套中调用批处理时避开这些变量名
REM 		%%; %%: %%^> %%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%] %%_
REM 	所有子程序未做过多特殊字符的处理及测试，故像"< > ( ) | &"等这些字符的兼容性就很难保证了
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_Read	从指定文件、指定行、指定分隔符、指定列获取内容赋值到指定变量
REM 		call:Database_Read [/Q(安静模式，不提示错误)] "数据源文件" "数据列分隔符" "数据所在行" "以分隔符为分割的N列数据(列目号与列目号之间使用,分割，且可以区间分割符-)" "单个或多个变量(多个变量之间使用空格或,进行分割)"
REM 			例子：从文件 "c:\users\a\Database.ini" 中将以 "	" 为分隔符的第4行数据的第1,2,3,6列数据分别赋值到var1,var2,var3,var4
REM					call:Database_Read "c:\users\a\Database.ini" "	" "4" "1-3,6" "var1 var2 var3 var4"
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_Update	修改指定文件的指定行以指定分隔符分割的指定列的内容
REM 		call:Database_Update [/Q(安静模式，不提示错误)] "数据源" "数据列分隔符" "欲修改数据所在开始行号" "以分隔符为分割的N列数据(列号与列号之间使用,分割，且可以区间分割符-)" "该行第一列修改后数据" "该行第二列修改后数据" ...
REM 			例子：从文件 "c:\users\a\Database.ini" 中第4行以 "	" 为分隔1,2,3,6列数据修改为分别修改为 string1 string2 string3 string4
REM					call:Database_Update "c:\users\a\Database.ini" "	" "4" "1-3,6" "string1" "string2" "string3" "string4"
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_Print	从指定文件、指定行、指定分隔符、指定列获取内容并打印到屏幕或文件
REM call:Database_Print [/Q(安静模式，不提示错误)] [/LN(显示数据在整体打印内容中的序号,非数据在数据源文件中的行号)] [/HEAD 打印行头添加内容] [/FOOT 打印行尾追加内容] "数据源" "数据提取分隔符" "数据打印分隔符" "打印数据行(支持单数分隔符,与区间连续分隔符-,0为指定全部行)" "以分隔符为分割的N列数据(列号与列号之间使用,分割，且可以区间分割符-)" [/F 文件(将内容输出到文件)] 
REM 			例子：将文件 "c:\users\a\Database.ini" 中的第4-5行以 "	" 为分隔符的第1,2,3,6列数据以"*"为分隔符打印出来
REM 				call:Database_Print "c:\users\a\Database.ini" "	" "*" "4-5" 1-3,6"
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_Find	从指定文件、指定行、指定分隔符、指定列、指定字符串搜索并将搜索结果的行列号写入到指定变量中
REM 		call:Database_Find [/Q(安静模式，不提示错误)] [/i(不区分大小写)] [/first(返回查找到的第一个结果)] "数据源" "数据列分隔符"  "查找字符串" "查找数据行(支持单数分隔符,与区间连续分隔符-,0为指定全部行)" "查找数据列(支持单数分隔符,与区间连续分隔符-)" "查找结果行号列号结果接受赋值变量名"
REM 			注意---------------------------------------------------------------------------------------------------------------------------------
REM 				结果变量的输出格式为："行 列","行 列","..."依次递加，例如第二行第三列和第五行第六列的赋值内容就为："2 3","5 6"
REM 				可以使用 'for %%a in (%结果变量%) do for /f "tokens=1,2" %%b in ("%%~a") do echo=第%%b行，第%%c列' 的方法进行结果使用
REM 				---------------------------------------------------------------------------------------------------------------------------------
REM 			例子：从文件 "c:\users\a\Database.ini"中第三到五行以"	"为分隔符的第一列中不区分大小写的查找字符串data(完全匹配)并将搜索结果的行列号赋值到变量result
REM 				call:Database_Find /i "c:\users\a\Database.ini" "	" "data" "3-5" "1" "result"
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_Insert	插入数据到指定文本数据库文件中
REM 		call:Database_Insert [/Q(安静模式，不提示错误)] "数据源" [/LN [插入到行位置(默认底部追加)]] "数据列分隔符" "数据1" "数据2" "数据3" "..."
REM 			例子：将数据"data1" "data2" "data3" 以 "	"为分隔符插入到文本数据库文件" "c:\users\a\Database.ini"
REM 				call:Database_Insert "c:\users\a\Database.ini" "	" "data1" "data2" "data3"
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_Sort	排序行数据使其转移到指定行
REM 		call:Database_Sort [/Q(安静模式，不提示错误)] "数据源" "欲排序行号" "排序后行号"
REM 			例子：把文件 "c:\users\a\Database.ini" 中第四行排序到原第二行的位置
REM 				call:Database_Sort "c:\users\a\Database.ini" "4" "2"
REM ____________________________________________________________________________________________________________________________________________________________________
REM 
REM #	Database_DeleteLine	删除指定文件指定行
REM 		call:Database_DeleteLine [/Q(安静模式，不提示错误)] "数据源" "欲删除数据起始行" "从起始行开始继续向下删除多少行(包括本行，向下到结尾请输入0)"
REM 			例子：把文件 "c:\users\a\Database.ini" 中第二第三行删除
REM 				call:Database_DeleteLine "c:\users\a\Database.ini" "2" "2"
REM ____________________________________________________________________________________________________________________________________________________________________

:---------------------Database_Print---------------------:

REM 从指定文件、指定行、指定分隔符、指定列获取内容并打印到屏幕或文件
REM call:Database_Print [/Q(安静模式，不提示错误)] [/LN(显示数据在整体打印内容中的序号,非数据在数据源文件中的行号)] [/HEAD 打印行头添加内容] [/FOOT 打印行尾追加内容] "数据源" "数据提取分隔符" "数据打印分隔符" "打印数据行(支持单数分隔符,与区间连续分隔符-,0为指定全部行)" "以分隔符为分割的N列数据(列号与列号之间使用,分割，且可以区间分割符-)" [/F 文件(将内容输出到文件)] 
REM 例子：将文件 "c:\users\a\Database.ini" 中的第4-5行以 "	" 为分隔符的第1,2,3,6列数据以"*"为分隔符打印出来
REM					call:Database_Print "c:\users\a\Database.ini" "	" "*" "4-5" 1-3,6"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20160625
:Database_Print
REM 检查子程序运行基本需求参数
for %%A in (d_P_ErrorPrint d_P_LineNumber d_P_PrintHead d_P_PrintFoot) do set "%%A="
if /i "%~1"=="/ln" (
	set "d_P_LineNumber=Yes"
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set "d_P_ErrorPrint=Yes"
if /i "%~1"=="/ln" (
	set "d_P_LineNumber=Yes"
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set "d_P_ErrorPrint=Yes"

if /i "%~1"=="/head" (
	set "d_P_PrintHead=%~2"
	shift/1
	shift/1
) else if /i "%~1"=="/foot" (
	set "d_P_PrintFoot=%~2"
	shift/1
	shift/1
)
if /i "%~1"=="/head" (
	set "d_P_PrintHead=%~2"
	shift/1
	shift/1
) else if /i "%~1"=="/foot" (
	set "d_P_PrintFoot=%~2"
	shift/1
	shift/1
)

if /i "%~6"=="/f" if "%~7"=="" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数7-指定输出文件为空]
)
if "%~5"=="" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数6-指定列目号为空]
	exit/b 2
)
if "%~4"=="" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数4-指定行号为空]
	exit/b 2
)
if "%~3"=="" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数3-指定数据打印分隔符为空]
	exit/b 2
)
if "%~2"=="" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数2-指定数据提取分隔符为空]
	exit/b 2
)
if "%~1"=="" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数1-指定数据源文件为空]
	exit/b 2
) else if not exist "%~1" (
	if defined d_P_ErrorPrint echo=	[错误%0:参数1-指定数据源文件不存在:%~1]
	exit/b 2
)
REM 初始化变量
for %%_ in (d_P_Count d_P_Count2 d_P_Count3 d_P_ValueTemp d_P_StringTest d_P_Count4 d_P_Pass) do set "%%_="
for /f "delims==" %%_ in ('set d_P_AlreadyLineNumber 2^>nul') do set "%%_="
if /i "%~6"=="/f" (
	set d_P_File=">>"%~7""
	if exist "%~7" del /f /q "%~7"
) else set "d_P_File= "

REM 子程序开始运作

REM 判断用户输入行号是否符合规则
set "d_P_StringTest=%~4"
for %%_ in (1,2,3,4,5,6,7,8,9,0,",",-) do if defined d_P_StringTest set "d_P_StringTest=!d_P_StringTest:%%~_=!"
if defined d_P_StringTest (
	if defined d_P_ErrorPrint echo=	[错误%0:参数4:指定查找行不符合规则:%~4]
	exit/b 2
)
for %%_ in (%~4) do (
	set "d_P_Pass="
	set "d_P_Pass=%%~_"
	if "!d_P_Pass!"=="!d_P_Pass:-=!" (
		if "%%~_"=="0" (
			set "d_P_Count2=0"
			set "d_P_Count=No"
			set "d_P_Pass="
			) else (
			set /a "d_P_Count2=%%~_-1"
			set /a "d_P_Pass=%%~_-1"
			set "d_P_Count=0"
			if "!d_P_Pass!"=="0" (set "d_P_Pass=") else set "d_P_Pass=skip=!d_P_Pass!"
			)
		call:Database_Print_Run "%~1" "%~2" "%~3" "%~5"
	) else (
		for /f "tokens=1,2 delims=-" %%: in ("%%~_") do (
			if "%%~:"=="%%~;" (
				set "d_P_Count2=%%~:-1"
				set /a "d_P_Pass=%%~:-1"
				set "d_P_Count=0"
				) else call:Database_Print2 "%%~:" "%%~;"
			if "!d_P_Pass!"=="0" (set "d_P_Pass=") else set "d_P_Pass=skip=!d_P_Pass!"
			call:Database_Print_Run "%~1" "%~2" "%~3" "%~5"
		)
	)
)
exit/b 0


REM call:Database_Print_Run "文件" "数据提取分隔符" "数据打印分隔符" "列号"
:Database_Print_Run
set "d_P_Count3="
(
	for /f "usebackq %d_P_Pass% eol=^ tokens=%~4 delims=%~2" %%? in ("%~1") do (
		set /a "d_P_Count3+=1"
		set /a "d_P_Count2+=1"
		
		if not defined d_P_AlreadyLineNumber!d_P_Count2! (
			set "d_P_AlreadyLineNumber!d_P_Count2!=Yes"
			set /a "d_P_Count4+=1"
			
			if defined d_P_LineNumber set "d_P_LineNumber=!d_P_Count4!.%~3"
			for /f "eol=^ delims=%%" %%^> in ("!d_P_LineNumber!%%?%~3%%@%~3%%A%~3%%B%~3%%C%~3%%D%~3%%E%~3%%F%~3%%G%~3%%H%~3%%I%~3%%J%~3%%K%~3%%L%~3%%M%~3%%N%~3%%O%~3%%P%~3%%Q%~3%%R%~3%%S%~3%%T%~3%%U%~3%%V%~3%%W%~3%%X%~3%%Y%~3%%Z%~3%%[%~3%%\%~3%%]") do set d_P_ValueTemp=%%^>
			if "!d_P_ValueTemp:~-1!"=="%~3" (echo=%d_P_PrintHead%!d_P_ValueTemp:~0,-1!%d_P_PrintFoot%) else echo=%d_P_PrintHead%!d_P_ValueTemp!%d_P_PrintFoot%
		)
		if /i not "%d_P_Count%"=="No" (
			if "%d_P_Count%"=="0" exit/b 0
			if "!d_P_Count3!"=="%d_P_Count%" exit/b 0
		)
	)
)%d_P_File:~1,1%%d_P_File:~2,-1%

exit/b 0

REM 可能由于嵌套深度原因导致的问题不得不写出一个子程序进行判断
REM call:Database_Print2 第一个值 第二个值
:Database_Print2
if %~10 gtr %~20 (
	set /a "d_P_Count2=%~2-1"
	set /a "d_P_Pass=%~2-1"
	set /a "d_P_Count=%~1-%~2+1"
) else (
	set /a "d_P_Count2=%~1-1"
	set /a "d_P_Pass=%~1-1"
	set /a "d_P_Count=%~2-%~1+1"
)
exit/b


:---------------------Database_Insert---------------------:


REM 插入数据到指定文本数据库文件中
REM call:Database_Insert [/Q(安静模式，不提示错误)] "数据源" [/LN [插入到行位置(默认底部追加)]] "数据列分隔符" "数据1" "数据2" "数据3" "..."
REM 例子：将数据"data1" "data2" "data3" 以 "	"为分隔符插入到文本数据库文件" "c:\users\a\Database.ini"
REM					call:Database_Insert "c:\users\a\Database.ini" "	" "data1" "data2" "data3"
REM 返回值详情：0-运行正常，1-查无此行，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20160507
:Database_Insert
REM 检查子程序运行基本需求参数
for %%A in (d_I_ErrorPrint d_I_LineNumber d_I_Value) do set "%%A="
if /i "%~1"=="/q" (
	shift/1
) else set "d_I_ErrorPrint=Yes"

if "%~2"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数3-指定分隔符为空]
	exit/b 2
)
if /i "%~2"=="/LN" if "%~3"=="" (
	if defined d_I_ErrorPrint echo=	[错误%0:参数3-指定插入行号为空]
	exit/b 2
) else (
	set "d_I_LineNumber=%~3"
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
for %%_ in (d_I_Count d_I_Pass1 d_I_Temp_File) do set "%%_="
for /l %%_ in (1,1,31) do set "d_I_Value%%_="
if defined d_I_LineNumber (
	set "d_I_Temp_File=%~1_Temp"
	if exist "%d_I_Temp_File%" del /f /q "%d_I_Temp_File%"
)

REM 子程序开始运作
REM 提取用户指定值
:Database_Insert1
set /a "d_I_Count+=1"
set "d_I_Value%d_I_Count%=%~3"
if not "%~4"=="" (
	shift/3
	goto Database_Insert1
)
for /l %%_ in (1,1,%d_I_Count%) do (
	set "d_I_Value=!d_I_Value!%~2!d_I_Value%%_!"
)
set "d_I_Value=%d_I_Value:~1%"
REM 未指定插入行号情况
if not defined d_I_LineNumber call:Database_Insert_Echo d_I_Value>>"%~1"&exit/b 0
REM 指定插入行号情况
REM 检测插入行是否存在
set /a "d_I_Pass1=%d_I_LineNumber%-1"
if "%d_I_Pass1%"=="0" (set "d_I_Pass1=") else set "d_I_Pass1=skip=%d_I_Pass1%"
for /f "usebackq %d_I_Pass1% eol=^ delims=" %%? in ("%~1") do goto Database_Insert2
if defined d_I_ErrorPrint echo=	[错误%0:结果:查无此行:%d_I_LineNumber%]
exit/b 1
:Database_Insert2
set "d_I_Count="
REM 指定行前段数据写入临时文件
set /a "d_I_Count2=%d_I_LineNumber%-1"
if "%d_I_Count2%"=="0" goto Database_Insert3
for /f "usebackq eol=^ delims=" %%? in ("%~1") do (
	set /a "d_I_Count+=1"
	echo=%%?
	if "!d_I_Count!"=="%d_I_Count2%" goto Database_Insert3
)>>"%d_I_Temp_File%"
:Database_Insert3
REM 写入插入数据到临时文件
call:Database_Insert_Echo d_I_Value>>"%d_I_Temp_File%"
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

REM 用于解决输出到数据不能结尾为空格+0/1/2/3和不能含有()问题
REM call:Database_Insert_Echo 变量名
:Database_Insert_Echo
echo=!%~1!
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
set "d_R_ErrorPrint="
if /i "%~1"=="/q" (shift/1) else set "d_R_ErrorPrint=Yes"
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
for %%_ in (d_R_Count d_R_Pass) do set "%%_="
for /l %%_ in (1,1,31) do if defined d_R_Count%%_ set "d_R_Count%%_="
set /a "d_R_Pass=%~3-1"
if "%d_R_Pass%"=="0" (set "d_R_Pass=") else set "d_R_Pass=skip=%d_R_Pass%"

REM 子程序开始运作
for %%_ in (%~5) do (
	set /a "d_R_Count+=1"
	set "d_R_Count!d_R_Count!=%%_"
)
set "d_R_Count="
for /f "usebackq eol=^ %d_R_Pass% tokens=%~4 delims=%~2" %%? in ("%~1") do (
	for %%_ in ("!d_R_Count1!=%%~?","!d_R_Count2!=%%~@","!d_R_Count3!=%%~A","!d_R_Count4!=%%~B","!d_R_Count5!=%%~C","!d_R_Count6!=%%~D","!d_R_Count7!=%%~E","!d_R_Count8!=%%~F","!d_R_Count9!=%%~G","!d_R_Count10!=%%~H","!d_R_Count11!=%%~I","!d_R_Count12!=%%~J","!d_R_Count13!=%%~K","!d_R_Count14!=%%~L","!d_R_Count15!=%%~M","!d_R_Count16!=%%~N","!d_R_Count17!=%%~O","!d_R_Count18!=%%~P","!d_R_Count19!=%%~Q","!d_R_Count20!=%%~R","!d_R_Count21!=%%~S","!d_R_Count22!=%%~T","!d_R_Count23!=%%~U","!d_R_Count24!=%%~V","!d_R_Count25!=%%~W","!d_R_Count26!=%%~X","!d_R_Count27!=%%~Y","!d_R_Count28!=%%~Z","!d_R_Count29!=%%~[","!d_R_Count30!=%%~\","!d_R_Count31!=%%~]") do (
		set /a "d_R_Count+=1"
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
for %%A in (d_S_ErrorPrint) do set "%%A="
if /i "%~1"=="/q" (
	shift/1
) else set "d_S_ErrorPrint=Yes"
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
for %%_ in (d_S_Count d_S_Count2 d_S_Pass1 d_S_Pass2 d_S_Pass3 d_S_Temp_File) do set "%%_="
set "d_S_Temp_File=%~1_Temp"
if exist "%d_S_Temp_File%" del /f /q "%d_S_Temp_File%"


if %~2 lss %~3 (
	REM 前端内容
	set /a "d_S_Count1=%~2-1"
	REM 起始行后，结束行前
	set /a "d_S_Pass1=%~2
	set /a "d_S_Count2=%~3-%~2"
	REM 起始行内容
	set /a "d_S_Pass2=%~2-1"
	set /a "d_S_LineDefinedCheck1=%~2-1"
	REM 结束行后(包括结束行)
	set /a "d_S_Pass3=%~3"
	set /a "d_S_LineDefinedCheck2=%~3-1"
) else (
	REM 前端内容
	set /a "d_S_Count1=%~3-1"
	REM 起始行内容
	set /a "d_S_Pass1=%~2-1"
	set /a "d_S_LineDefinedCheck1=%~2-1"
	REM 结束行(包括结束行)到起始行之间内容
	set /a "d_S_Pass2=%~3-1"
	set /a "d_S_Count2=%~2-%~3"
	set /a "d_S_LineDefinedCheck2=%~3-1"
	REM 起始行后内容
	set /a "d_S_Pass3=%~2"
)

for %%_ in (d_S_LineDefinedCheck1 d_S_LineDefinedCheck2 d_S_Pass1 d_S_Pass2 d_S_Pass3) do if "!%%_!"=="0" (set "%%_=") else set "%%_=skip=!%%_!"

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
	set /a "d_S_Count+=1"
	echo=%%_
	if "!d_S_Count!"=="!d_S_Count1!" goto Database_Sort1
)>>"%d_S_Temp_File%"

:Database_Sort1
set "d_S_Count="
(
	if %~2 lss %~3 (
		for /f "usebackq %d_S_Pass1% eol=^ delims=" %%_ in ("%~1") do (
			set /a "d_S_Count+=1"
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
set "d_S_Count="
(
	if %~2 lss %~3 (
		for /f "usebackq %d_S_Pass2% eol=^ delims=" %%_ in ("%~1") do (
			echo=%%_
			goto Database_Sort3
		)
	) else (
		for /f "usebackq %d_S_Pass2% eol=^ delims=" %%_ in ("%~1") do (
			set /a "d_S_Count+=1"
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
for %%A in (d_U_ErrorPrint) do set "%%A="
if /i "%~1"=="/q" (
	shift/1
) else set "d_U_ErrorPrint=Yes"
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
for %%_ in (d_U_Count d_U_Pass1 d_U_Pass2 d_U_Pass3 d_U_Temp_File d_U_FinalValue d_U_Value) do set "%%_="
for /l %%_ in (1,1,31) do (
	set "d_U_Value%%_="
	set "d_U_FinalValue%%_="
)
set "d_U_Temp_File=%~1_Temp"
if exist "%d_U_Temp_File%" del /f /q "%d_U_Temp_File%"
set /a "d_U_Pass3=%~3"
set /a "d_U_Pass2=%~3-1"
set /a "d_U_Pass1=%~3-1"

set "d_U_Pass3=skip=%d_U_Pass3%"
if "%d_U_Pass2%"=="0" (set "d_U_Pass2=") else set "d_U_Pass2=skip=%d_U_Pass2%"

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
		set /a "d_U_Count+=1"
		echo=%%?
		if "!d_U_Count!"=="%d_U_Pass1%" goto Database_Updata2
	)
)>>"%d_U_Temp_File%"

REM 修改行提取修改并写入阶段
:Database_Updata2
set "d_U_Count="

:Database_Updata2_2
REM 将用户指定修改内容赋值到序列变量
set /a "d_U_Count+=1"
set "d_U_Value%d_U_Count%=%~5"
if not "%~6"=="" (
	shift/5
	goto Database_Updata2_2
)

set "d_U_Count="

REM 将用户指定修改内容赋值到行整体数据位置序列变量
for /f "tokens=%~4 delims=," %%? in ("1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31") do set "d_U_Column=%%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%]"
for /f "delims=%%" %%a in ("%d_U_Column%") do set "d_U_Column=%%a"
for %%a in (%d_U_Column%) do (
	set /a "d_U_Count+=1"
	call:Database_Updata_Var d_U_FinalValue%%a d_U_Value!d_U_Count!
)

set "d_U_Count="

REM 将文本数据库修改行不被修改的数据赋值到行整体数据位置序列变量(已经被赋值的序列变量则跳过)
for /f "usebackq eol=^ tokens=1-31 %d_U_Pass2% delims=%~2" %%? in ("%~1") do (
	for %%_ in ("%%?" "%%@" "%%A" "%%B" "%%C" "%%D" "%%E" "%%F" "%%G" "%%H" "%%I" "%%J" "%%K" "%%L" "%%M" "%%N" "%%O" "%%P" "%%Q" "%%R" "%%S" "%%T" "%%U" "%%V" "%%W" "%%X" "%%Y" "%%Z" "%%[" "%%\" "%%]") do (
		if "%%~_"=="" goto Database_Updata2_3
		set /a "d_U_Count+=1"
		if not defined d_U_FinalValue!d_U_Count! set "d_U_FinalValue!d_U_Count!=%%~_"
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
	set "d_U_FinalValue=!d_U_FinalValue!%~2!d_U_FinalValue%%_!"
)
set "d_U_FinalValue=%d_U_FinalValue:~1%"
call:Database_Update_Echo d_U_FinalValue>>"%d_U_Temp_File%"

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
set "%~1=!%~2!"
exit/b 0
REM 用于解决输出到数据不能结尾为空格+0/1/2/3和不能含有()问题
REM call:Database_Update_Echo 变量名
:Database_Update_Echo
echo=!%~1!
exit/b 0

:---------------------Database_Find---------------------:

REM 从指定文件、指定行、指定分隔符、指定列、指定字符串搜索并将搜索结果的行列号写入到指定变量中
REM call:Database_Find [/Q(安静模式，不提示错误)] [/i(不区分大小写)] [/first(返回查找到的第一个结果)] "数据源" "数据列分隔符"  "查找字符串" "查找数据行(支持单数分隔符,与区间连续分隔符-,0为指定全部行)" "查找数据列(支持单数分隔符,与区间连续分隔符-)" "查找结果行号列号结果接受赋值变量名"
	REM 注意：-------------------------------------------------------------------------------------------------------------------------------
	REM 	结果变量的输出格式为："行 列","行 列","..."依次递加，例如第二行第三列和第五行第六列的赋值内容就为："2 3","5 6"
	REM 	可以使用 'for %%a in (%结果变量%) do for /f "tokens=1,2" %%b in ("%%~a") do echo=第%%b行，第%%c列' 的方法进行结果使用
	REM -------------------------------------------------------------------------------------------------------------------------------------
REM 例子：从文件 "c:\users\a\Database.ini"中第三到五行以"	"为分隔符的第一列中不区分大小写的查找字符串data(完全匹配)并将搜索结果的行列号赋值到变量result
REM					call:Database_Find /i "c:\users\a\Database.ini" "	" "data" "3-5" "1" "result"
REM 返回值详情：0-根据指定字符串找到结果并已赋值变量，1-未查找到结果，2-参数不符合子程序
REM 注意：列数值最高只支持到31列，推荐在创建数据的时候使用制表符"	"为分隔符，以防后期数据和分隔符混淆,文本数据库中不要含有空行和空值，防止返回数据错误
REM 版本:20160625
:Database_Find
REM 检查子程序运行基本需求参数
for %%A in (d_F_ErrorPrint d_F_Insensitive d_F_FindFirst) do set "%%A="
if /i "%~1"=="/i" (
	set "d_F_Insensitive=/i"
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set "d_F_ErrorPrint=Yes"
if /i "%~1"=="/i" (
	set "d_F_Insensitive=/i"
	shift/1
) else if /i "%~1"=="/q" (shift/1) else set "d_F_ErrorPrint=Yes"

if /i "%~1"=="/first" (
	set d_F_FindFirst=Yes
	shift/1
)

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
for %%_ in (d_F_Count d_F_StringTest d_F_Count2 d_F_Pass %~6) do set "%%_="
for /f "delims==" %%_ in ('set d_F_AlreadyLineNumber 2^>nul') do set "%%_="
for /f "delims==" %%_ in ('set d_F_Column 2^>nul') do set "%%_="

REM 子程序开始运作
REM 判断用户输入行号是否符合规则
set "d_F_StringTest=%~4"
for %%_ in (1,2,3,4,5,6,7,8,9,0,",",-) do if defined d_F_StringTest set "d_F_StringTest=!d_F_StringTest:%%~_=!"
if defined d_F_StringTest (
	if defined d_F_ErrorPrint echo=	[错误%0:参数4:指定查找行号不符合规则:%~4]
	exit/b 2
)

REM 将列号赋值到列变量
for /f "tokens=%~5" %%? in ("1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31") do for /f "delims=%%" %%_ in ("%%? %%@ %%A %%B %%C %%D %%E %%F %%G %%H %%I %%J %%K %%L %%M %%N %%O %%P %%Q %%R %%S %%T %%U %%V %%W %%X %%Y %%Z %%[ %%\ %%]") do for %%: in (%%_) do (
	set /a "d_F_Count+=1"
	set "d_F_Column!d_F_Count!=%%:"
)
set "d_F_Count="
REM 根据行号进行拆分执行命令
for %%_ in (%~4) do (
	set "d_F_Pass="
	set "d_F_Pass=%%~_"
	if "!d_F_Pass!"=="!d_F_Pass:-=!" (
		if "%%~_"=="0" (
			set "d_F_Count2=0"
			set "d_F_Count=No"
			set "d_F_Pass="
		) else (
			set /a "d_F_Count2=%%~_-1"
			set /a "d_F_Pass=%%~_-1"
			set "d_F_Count=0"
			if "!d_F_Pass!"=="0" (set "d_F_Pass=") else set "d_F_Pass=skip=!d_F_Pass!"
		)
		call:Database_Find_Run "%~1" "%~2" "%~5" "%~3" "%~6"
		if defined d_F_FindFirst if defined %~6 (
			set "%~6=!%~6:~1!"
			exit/b 0
		)
	) else (
		for /f "tokens=1,2 delims=-" %%: in ("%%~_") do (
			if "%%~:"=="%%~;" (
				set /a "d_F_Count2=%%~:-1"
				set /a "d_F_Pass=%%~:-1"
				set "d_F_Count=0"
			) else call:Database_Find2 "%%~:" "%%~;"
			if "!d_F_Pass!"=="0" (set "d_F_Pass=") else set "d_F_Pass=skip=!d_F_Pass!"
			call:Database_Find_Run "%~1" "%~2" "%~5" "%~3" "%~6"
			if defined d_F_FindFirst if defined %~6 (
				set "%~6=!%~6:~1!"
				exit/b 0
			)
		)
	)
)

if defined %~6 (set "%~6=!%~6:~1!") else (
	if defined d_F_ErrorPrint echo=	[结果%0:根据关键字"%~3"未能从指定文件行列中找到结果]
	exit/b 1
)
exit/b 0

REM call:Database_Find_Run "文件" "分隔符" "列" "查找字符串" "变量名"
:Database_Find_Run
set "d_F_Count3="
for /f "usebackq %d_F_Pass% eol=^ tokens=%~3 delims=%~2" %%? in ("%~1") do (
	set /a "d_F_Count3+=1"
	set /a "d_F_Count2+=1"
	
	if not defined d_F_AlreadyLineNumber!d_F_Count2! (
		set "d_F_AlreadyLineNumber!d_F_Count2!=Yes"
		
		if "%%?"=="%%~?" (
			if %d_F_Insensitive% "%%?"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column1!"&if defined d_F_FindFirst exit/b
		)
		if "%%@"=="%%~@" (
			if %d_F_Insensitive% "%%@"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column2!"&if defined d_F_FindFirst exit/b
		)
		if "%%A"=="%%~A" (
			if %d_F_Insensitive% "%%A"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column3!"&if defined d_F_FindFirst exit/b
		)
		if "%%B"=="%%~B" (
			if %d_F_Insensitive% "%%B"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column4!"&if defined d_F_FindFirst exit/b
		)
		if "%%C"=="%%~C" (
			if %d_F_Insensitive% "%%C"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column5!"&if defined d_F_FindFirst exit/b
		)
		if "%%D"=="%%~D" (
			if %d_F_Insensitive% "%%D"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column6!"&if defined d_F_FindFirst exit/b
		)
		if "%%E"=="%%~E" (
			if %d_F_Insensitive% "%%E"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column7!"&if defined d_F_FindFirst exit/b
		)
		if "%%F"=="%%~F" (
			if %d_F_Insensitive% "%%F"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column8!"&if defined d_F_FindFirst exit/b
		)
		if "%%G"=="%%~G" (
			if %d_F_Insensitive% "%%G"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column9!"&if defined d_F_FindFirst exit/b
		)
		if "%%H"=="%%~H" (
			if %d_F_Insensitive% "%%H"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column10!"&if defined d_F_FindFirst exit/b
		)
		if "%%I"=="%%~I" (
			if %d_F_Insensitive% "%%I"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column11!"&if defined d_F_FindFirst exit/b
		)
		if "%%J"=="%%~J" (
			if %d_F_Insensitive% "%%J"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column12!"&if defined d_F_FindFirst exit/b
		)
		if "%%K"=="%%~K" (
			if %d_F_Insensitive% "%%K"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column13!"&if defined d_F_FindFirst exit/b
		)
		if "%%L"=="%%~L" (
			if %d_F_Insensitive% "%%L"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column14!"&if defined d_F_FindFirst exit/b
		)
		if "%%M"=="%%~M" (
			if %d_F_Insensitive% "%%M"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column15!"&if defined d_F_FindFirst exit/b
		)
		if "%%N"=="%%~N" (
			if %d_F_Insensitive% "%%N"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column16!"&if defined d_F_FindFirst exit/b
		)
		if "%%O"=="%%~O" (
			if %d_F_Insensitive% "%%O"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column17!"&if defined d_F_FindFirst exit/b
		)
		if "%%P"=="%%~P" (
			if %d_F_Insensitive% "%%P"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column18!"&if defined d_F_FindFirst exit/b
		)
		if "%%Q"=="%%~Q" (
			if %d_F_Insensitive% "%%Q"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column19!"&if defined d_F_FindFirst exit/b
		)
		if "%%R"=="%%~R" (
			if %d_F_Insensitive% "%%R"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column20!"&if defined d_F_FindFirst exit/b
		)
		if "%%S"=="%%~S" (
			if %d_F_Insensitive% "%%S"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column21!"&if defined d_F_FindFirst exit/b
		)
		if "%%T"=="%%~T" (
			if %d_F_Insensitive% "%%T"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column22!"&if defined d_F_FindFirst exit/b
		)
		if "%%U"=="%%~U" (
			if %d_F_Insensitive% "%%U"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column23!"&if defined d_F_FindFirst exit/b
		)
		if "%%V"=="%%~V" (
			if %d_F_Insensitive% "%%V"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column24!"&if defined d_F_FindFirst exit/b
		)
		if "%%W"=="%%~W" (
			if %d_F_Insensitive% "%%W"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column25!"&if defined d_F_FindFirst exit/b
		)
		if "%%X"=="%%~X" (
			if %d_F_Insensitive% "%%X"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column26!"&if defined d_F_FindFirst exit/b
		)
		if "%%Y"=="%%~Y" (
			if %d_F_Insensitive% "%%Y"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column27!"&if defined d_F_FindFirst exit/b
		)
		if "%%Z"=="%%~Z" (
			if %d_F_Insensitive% "%%Z"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column28!"&if defined d_F_FindFirst exit/b
		)
		if "%%["=="%%~[" (
			if %d_F_Insensitive% "%%["=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column29!"&if defined d_F_FindFirst exit/b
		)
		if "%%\"=="%%~\" (
			if %d_F_Insensitive% "%%\"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column30!"&if defined d_F_FindFirst exit/b
		)
		if "%%]"=="%%~]" (
			if %d_F_Insensitive% "%%]"=="%~4" set %~5=!%~5!,"!d_F_Count2! !d_F_Column31!"&if defined d_F_FindFirst exit/b
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
	set /a "d_F_Count2=%~2-1"
	set /a "d_F_Pass=%~2-1"
	set /a "d_F_Count=%~1-%~2+1"
) else (
	set /a "d_F_Count2=%~1-1"
	set /a "d_F_Pass=%~1-1"
	set /a "d_F_Count=%~2-%~1+1"
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
for %%A in (d_DL_ErrorPrint) do set "%%A="
if /i "%~1"=="/q" (
	shift/1
) else set "d_DL_ErrorPrint=Yes"
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
for %%_ in (d_DL_Count d_DL_Pass1 d_DL_Pass2 d_DL_Pass3 d_DL_Temp_File) do set "%%_="
set "d_DL_Temp_File=%~1_Temp"
if exist "%d_DL_Temp_File%" del /f /q "%d_DL_Temp_File%"
set /a "d_DL_Pass3=%~2-1"
set /a "d_DL_Pass2=%~2+%~3-1"
set /a "d_DL_Pass1=%~2-1"

if "%d_DL_Pass3%"=="0" (set "d_DL_Pass3=") else set "d_DL_Pass3=skip=%d_DL_Pass3%"
if "%d_DL_Pass2%"=="0" (set "d_DL_Pass2=") else set "d_DL_Pass2=skip=%d_DL_Pass2%"

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
		set /a "d_DL_Count+=1"
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

:-----------------------------------------------------------子程序结束分割线-----------------------------------------------------------:
:end