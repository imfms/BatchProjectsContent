@echo off
setlocal ENABLEDELAYEDEXPANSION
color 0a
REM 设定版本及更新信息
set project=BFS_FileSearch
set version=20160629
set updateUrl=http://imfms.vicp.net

title BFS搜索 ^| %version% ^| F_Ms ^| Blog: f-ms.cn

REM 设定搜索分区库
set litter=A B C D E F G H I J K L M N O P Q R S T U V W X Y Z

:choosedrive
cls
for %%a in (existdrive userfilename userinput) do if defined %%a set %%a=
if not "%~1"=="" (
	call:existfolder %*
	if defined existfolder (
		set userinput=!existfolder!
		echo=#搜索目录:!userinput!
		goto searchfilename
	) else (
		echo=#错误:参数1:"%~1":文件不存在
		pause
		exit /b
	)
)
for %%a in (%litter%) do if exist %%a:\ (
	set existdrive=!existdrive! %%a
	for /f "tokens=4,*" %%A in ('vol %%a:') do if "%%~B"=="" (set label%%a=%%A) else set label%%a=%%A %%B
	if not defined label%%a set label%%a=[无卷标]
)
echo=-BFS文件搜索-
echo=#分区	#卷标
for %%a in (%existdrive::=%) do echo=  %%a	!label%%a!
if defined tips (
	call:searchresulthelp 2
	set tips=
)
set /p userinput=#分区或目录：
if not defined userinput (
	set tips=Yes
	goto choosedrive
)
if defined ##userinput set ##userinput=
set ##userinput=%userinput:"=%
if "%##userinput%"=="" (
	set tips=Yes
	goto choosedrive
)
if "%##userinput:~0,1%"=="?" (
	set tips=Yes
	goto choosedrive
)
if /i "%##userinput:~0,1%"=="@" (
	call:UpdateProjectVersion %project% %version% %updateUrl% "%~0"
	if not "!errorlevel!"=="0" (
		ping -n 3 127.1>nul 2>nul
		goto choosedrive
	)
)
if "%##userinput:~0,1%"=="$" (
	reg query hkcr\folder\shell\BFS搜索\command /ve>nul 2>nul
	if "!errorlevel!"=="0" (
		reg delete hkcr\folder\shell\BFS搜索 /f>nul 2>nul
		if "!errorlevel!"=="0" (echo=	#右键搜索菜单卸载成功) else echo=	#右键搜索菜单卸载失败，请尝试以管理员方式运行BFS搜索
		ping -n 3 127.1>nul 2>nul
	) else (
		reg add hkcr\folder\shell\BFS搜索\command /ve /t REG_EXPAND_SZ /d "\"%~dp0\%~nx0\" \"%%1\"" /f>nul 2>nul
		if "!errorlevel!"=="0" (echo=	#右键搜索菜单安装成功) else echo=	#右键搜索菜单安装失败，请尝试以管理员方式运行BFS搜索
		ping -n 3 127.1>nul 2>nul
	)
	goto choosedrive
)
if "%##userinput:~0,1%"=="," (
	echo=#将搜索所有分区
	set userinput=%existdrive%
	goto searchfilename
)
if "%##userinput:~0,1%"=="，" (
	echo=#将搜索所有分区
	set userinput=%existdrive%
	goto searchfilename
)
if "%##userinput:~0,1%"=="*" (
	echo=#将搜索所有分区
	set userinput=%existdrive%
	goto searchfilename
)
if "%##userinput:~0,2%"=="." goto end
if "%##userinput:~0,2%"=="。" goto end
call:existfolder %userinput%
if "%errorlevel%"=="2" goto choosedrive
if defined existfolder (
	if defined #existfolder (
	echo=#目录%#existfolder%不存在，将只搜索目录%existfolder%) else echo=#将搜索目录: %existfolder%
	set userinput=%existfolder%
	goto searchfilename
)
set userinput=%userinput::=%
set userinput=%userinput:\=%
set userinput=%userinput: =%
set userinput=%userinput:"=%
call:DefinedNoAbString "%userinput%"
if "%errorlevel%"=="0" (
	set tips=Yes
	goto choosedrive
)
call:convert userinput
call:wipe2 userinput
call:existcheck userinput
if not defined userinput goto choosedrive
if "%userinput: =%"=="" goto choosedrive
if defined userinput if defined #userinput (echo=#未发现分区 %#userinput% ，将只搜索分区 %userinput%) else echo=#将搜索分区: %userinput%
:searchfilename
for %%A in (userfilename #userfilename) do if defined %%A set %%A=
if defined tips (
	call:searchresulthelp 3
	set tips=
)
set /p userfilename=#搜索关键字:
if not defined userfilename (
	set tips=Yes
	goto searchfilename
)
:searchfilename2
set #userfilename=%userfilename:"=%
if "%#userfilename:~0,1%"==":" goto choosedrive
if "%#userfilename:~0,1%"=="/" (
	if /i "%#userfilename:~1,5%"=="image" (
		set userfilename=*.jpg *.jpeg *.bmp *.png *.gif *.raw *.pcx *.psd *.tiff *.svg
		goto searchfilename3
	)
	if /i "%#userfilename:~1,5%"=="video" (
		set userfilename=*.avi *.rmvb *.mkv *.mp4 *.3gp *.rm *.flv *.f4v *.mov *.ts *.vob *.wmv *.wmp
		goto searchfilename3
	)
	if /i "%#userfilename:~1,5%"=="audio" (
		set userfilename=*.mp3 *.flac *.ogg *.m4a *.ape *.wav *.mid *.cue
		goto searchfilename3
	)
	if /i "%#userfilename:~1,3%"=="txt" (
		set userfilename=*.doc *.txt *.xls *.ppt *.chm *.docx *.xlsx *.pptx *.et *.wps *.dps *.pdf *.rtf
		goto searchfilename3
	)
	if /i "%#userfilename:~1,8%"=="compress" (
		set userfilename=*.rar *.7z *.iso *.gho *.zip *.cab *.tar *.wim *.gzip *.gz
		goto searchfilename3
	)
	goto searchfilename
)
:searchfilename3
set searchfiledijia=
cls
echo=#正在搜索关键字 "%userfilename:"=%" ...
echo=
for %%a in (%userinput%) do (
	set userinputtemp=%%~a
	if "!userinputtemp:~1!"=="" (call:searchfile "%%~a:\" !userfilename!) else call:searchfile "%%~a" !userfilename!
	set userinputtemp=
)
if not defined searchfiledijia set searchfiledijia=0
echo=
echo=#搜索完毕,搜索关键字 "%userfilename:"=%" 共搜索到%searchfiledijia%个结果
if not defined searchfiledijia (goto searchfilename) else if "!searchfiledijia!"=="0" goto searchfilename
echo=
:searchfilenameopen
for %%a in (explorer findstr userinput2 #userinput2 userinputtemp2) do set %%a=
set /p userinput2=#请输入命令:
if defined userinput2 set #userinput2=%userinput2:"=%
if "%#userinput2%"=="" (
	call:searchresulthelp 1
	goto searchfilenameopen
) else (
	if "%#userinput2%"=="." (
		goto end
	) else (
		if "!userinput2!"==" " (
			call:searchresulthelp 1
			goto searchfilenameopen
		)
		if "!userinput2:~0,1!"=="0" goto choosedrive
		if "!userinput2:~0,1!"==":" goto choosedrive
		if "!userinput2:~0,1!"=="'" if "!#userinput2:~1!"=="" (goto searchfilename) else (
			set "userfilename=!userinput2:~1!"
			goto searchfilename2
		)
		if "!userinput2:~0,1!"==";" (
			call:echoresultlist
			goto searchfilenameopen
		)
		if "!userinput2:~-1!"==" " (
			set explorer=Yes
			set "userinput2=!userinput2:~,-1!"
		)
		if /i "!userinput2:~0,2!"=="/o" (
			call:callcommandgroup open
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/w" (
			call:callcommandgroup openwait
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/d" (
			call:callcommandgroup delete
			if "!errorlevel!"=="4" goto end
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/s" (
			call:callcommandgroup save
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/c" (
			call:callcommandgroup copy
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/r" (
			call:callcommandgroup ren
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/a" (
			call:callcommandgroup add
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if /i "!userinput2:~0,2!"=="/m" (
			call:callcommandgroup move
			if "!errorlevel!"=="4" goto end
			if "!errorlevel!"=="3" goto choosedrive
			goto searchfilenameopen
		)
		if "!userinput2:~0,2!"=="/-" (
			set findstr= /v
			set "userinput2=//!userinput2:~2!"
		)
		if "!userinput2:~0,2!"=="//" (
			if not "!userinput2:~2!"=="" (
				if not exist "%temp%\FileSearchTMP\" md "%temp%\FileSearchTMP\"
				if defined tempname set tempname=
				set tempname=%temp%\FileSearchTMP\!random!!random!!random!.tmp
				call:createresultfile "!tempname!"
				set searchfile2xulie=0
				cls
				echo=#正在搜索关键字 "!userinput2:~2!" ...
				echo=
				for /f "delims=" %%a in ('findstr !findstr! /i /c:"!userinput2:~2!" "!tempname!"') do (
					set /a searchfile2xulie+=1
					echo=[!searchfile2xulie!]"%%~a"[!searchfile2xulie!]
					set searchfiledijia!searchfile2xulie!=%%a
				)
				set /a searchfile2xulie+=1
				if defined searchfiledijia!searchfile2xulie! set searchfiledijia!searchfile2xulie!=
				set /a searchfile2xulie-=1
				echo=
				echo=#搜索完毕,关键字 "!userinput2:~2!" 共搜索到!searchfile2xulie!个结果
				if not defined searchfile2xulie (
					goto searchfilename
				) else (
					if "!searchfile2xulie!"=="0" goto searchfilename
				)
			)
		) else (
			call:DefinedNoNumberString "!userinput2!"
			if "!errorlevel!"=="0" (
				call:searchresulthelp 1
				goto searchfilenameopen
			) else (
				if !userinput2!0 gtr !searchfiledijia!0 (
					echo=	#输入序列无效，无此条目，请检查后重试
					goto searchfilenameopen
				)
				if defined searchfiledijia%userinput2% (
					if defined explorer (
						if exist "!searchfiledijia%userinput2: =%!" (start "" explorer /select,"!searchfiledijia%userinput2: =%!") else echo=	#指定序列文件"!searchfiledijia%userinput2: =%!"已不存在,已跳过命令
					) else start "" "!searchfiledijia%userinput2%!"
				)
				if not defined searchfiledijia%userinput2% echo=	#输入序列无效，无此条目，请检查后重试
			)
		)
	)
)
goto searchfilenameopen


goto end
:-------------------------------------子程序-------------------------------------

REM 文件搜索
:searchfile
for %%D in (searchfiletemp searchfiletemp2) do if defined %%D set %%D=
set userfilename2=%~2
set userfilename2=%userfilename2:"=%
if "%~1"=="" goto :eof
if "%userfilename2%"=="" goto :eof
if "!userfilename2:~0,1!"=="\" (set userfilename2=!userfilename2:~1!) else if "%userfilename2:**=%"=="%userfilename2%" if "%userfilename2:?=%"=="%userfilename2%" set searchfiletemp=*
for /r "%~1" %%b in ("%searchfiletemp%%userfilename2%%searchfiletemp%") do (
	if exist "%%~b" (
		set /a searchfiledijia+=1
		echo=[!searchfiledijia!]"%%~b"[!searchfiledijia!]
		set "searchfiledijia!searchfiledijia!=%%~b"
	)
)
set /a searchfiledijia+=1
if defined searchfiledijia!searchfiledijia! set searchfiledijia!searchfiledijia!=
set /a searchfiledijia-=1
if not "%~3"=="" (
	shift /2
	goto searchfile
)
goto :eof

REM 分别打开、复制、保存、删除组子程序
:callcommandgroup
if defined userinputtemp2 set userinputtemp2=

if "!#userinput2:~2!"=="" (
	echo=	#未发现操作参数,请检查后重试
) else (
	set callcommandgroupdijia=1
	for /l %%a in (1,1,4) do set callcommandgroupdijia%%a=
	for /f "tokens=1,*" %%a in ("!userinput2:~2!") do (
		set callcommandgroupdijia1=%%a
		for %%c in (%%b) do (
			set/a callcommandgroupdijia+=1
			set callcommandgroupdijia!callcommandgroupdijia!=%%c
		)
	)
	set userinput2=/c"!callcommandgroupdijia1!"	!callcommandgroupdijia2!	!callcommandgroupdijia3!	!callcommandgroupdijia4!
	
	for /f "tokens=1,2,3,4 delims=	" %%a in ("!userinput2:~2!") do (
		if "!#userinput2:~2,1!"=="*" (
			call:checkfolderfile %1 "%%~b" "%%~c" "%%~d"
			if "!errorlevel!"=="1" goto :eof
			call:chooseresultrun %1 "1-!searchfiledijia!" "%%~b" "%%~c" "%%~d"
			goto :eof
		)
		if "!#userinput2:~2,1!"=="," (
			call:checkfolderfile %1 "%%~b" "%%~c" "%%~d"
			if "!errorlevel!"=="1" goto :eof
			call:chooseresultrun %1 "1-!searchfiledijia!" "%%~b" "%%~c" "%%~d"
			goto :eof
		)
		call:checkfolderfile %1 "%%~b" "%%~c" "%%~d"
		if "!errorlevel!"=="1" goto :eof
		call:clearcontent "%%~a"
		if defined clearcontentresult (
			echo=	#!clearcontentresult!
			goto :eof
		) else (
			call:chooseresultrun %1 "!clearcontentresult2!" "%%~b" "%%~c" "%%~d"
			goto :eof
		)
	)
)
goto :eof

REM 从结果序号中提取并执行相关命令
:chooseresultrun
if "%~1"=="" goto :eof
if "%~2"=="" goto :eof
for %%a in (!#chooseresultrun!) do set chooseresultrun%%a=
if defined chooseresultrun set chooseresultrun=
for %%a in (%~2) do (
	set chooseresultrun=%%a
	if "!chooseresultrun!"=="!chooseresultrun:-=!" (
		if !chooseresultrun!0 gtr %searchfiledijia%0 (echo=	#序列%%a未发现有值，已跳过) else if defined chooseresultrun%%a (
			echo=	#序列%%a发现重复，已跳过
		) else (
			if defined searchfiledijia%%a (
				if exist "!searchfiledijia%%a!" (
					if /i "%~1"=="open" call:chooseresultrun2 open "!searchfiledijia%%a!"
					if /i "%~1"=="openwait" call:chooseresultrun2 openwait "!searchfiledijia%%a!"
					if /i "%~1"=="delete" call:chooseresultrun2 delete "!searchfiledijia%%a!"
					if /i "%~1"=="save" call:chooseresultrun2 save "!searchfiledijia%%a!" "%~3"
					if /i "%~1"=="copy" call:chooseresultrun2 copy "!searchfiledijia%%a!" "%~3"
					if /i "%~1"=="move" call:chooseresultrun2 move "!searchfiledijia%%a!" "%~3"
					if /i "%~1"=="ren" call:chooseresultrun2 ren "%%a" "!searchfiledijia%%a!" "%~3" "%~4"
					if /i "%~1"=="add" call:chooseresultrun2 add "%%a" "!searchfiledijia%%a!" "%~3" "%~4"
					set chooseresultrun%%a=Yes
					set #chooseresultrun=!#chooseresultrun! %%a
				) else echo=	#文件"!searchfiledijia%%a!"已不存在,已跳过
			) else (
				echo=	#序列%%a未发现有值，已跳过
			)
		)
	) else (
		for /f "tokens=1,2 delims=-" %%i in ("%%a") do (
			for /l %%A in (%%i,1,%%j) do (
				if %%A0 gtr %searchfiledijia%0 (echo=	#区间序列中[%%a]中序列%%A未发现有值，已跳过) else if defined chooseresultrun%%A (
					echo=	#区间序列中[%%a]中序列%%A发现重复，已跳过
				) else (
					if defined searchfiledijia%%A (
						if exist "!searchfiledijia%%A!" (
							if /i "%~1"=="open" call:chooseresultrun2 open "!searchfiledijia%%A!"
							if /i "%~1"=="openwait" call:chooseresultrun2 openwait "!searchfiledijia%%A!"
							if /i "%~1"=="delete" call:chooseresultrun2 delete "!searchfiledijia%%A!"
							if /i "%~1"=="save" call:chooseresultrun2 save "!searchfiledijia%%A!" "%~3"
							if /i "%~1"=="copy" call:chooseresultrun2 copy "!searchfiledijia%%A!" "%~3"
							if /i "%~1"=="move" call:chooseresultrun2 move "!searchfiledijia%%A!" "%~3"
							if /i "%~1"=="ren" call:chooseresultrun2 ren "%%A" "!searchfiledijia%%A!" "%~3" "%~4"
							if /i "%~1"=="add" call:chooseresultrun2 add "%%A" "!searchfiledijia%%A!" "%~3" "%~4"
							set chooseresultrun%%A=Yes
							set #chooseresultrun=!#chooseresultrun! %%A
						) else echo=	#文件"!searchfiledijia%%A!"已不存在,已跳过
					)
				)
			)
		)
	)
)
goto :eof
:chooseresultrun2
if defined filenametemp set filenametemp=
REM 打开
if /i "%~1"=="open" (
	start "" "%~2"
	echo=	#已打开文件"%~2"
	goto :eof
)
REM 等待打开
if /i "%~1"=="openwait" (
	echo=	#已打开文件"%~2"
	start /wait "" "%~2"
	goto :eof
)
REM 保存
if /i "%~1"=="save" call:chooseresultrun2save "%~2" "%~3"&goto :eof
REM 复制
if /i "%~1"=="copy" (
	if /i "%~dp2"=="%~3\" (
		echo=	#文件"%~nx2"所在文件夹与目标文件夹相同，已跳过
		goto :eof
	)
	if /i "%~dp2"=="%~3" (
		echo=	#文件"%~nx2"所在文件夹与目标文件夹相同，已跳过
		goto :eof
	)
	if exist "%~3\%~nx2" (
		call:chooseresultrun2random "%~3\%~nx2"
		call:chooseresultrun2copy "%~2" "!filenametemp!"
	) else (
		call:chooseresultrun2copy "%~2" "%~3"
	)
	if defined filenametemp (
		if exist "!filenametemp!" (echo=	#发现目标文件夹已有"%~nx2",文件"%~2"已成功复制到"!filenametemp!") else 	#文件"%~2"复制失败，权限不足或文件被占用
	) else (
		if exist "%~3\%~nx2" (echo=	#文件"%~2"已成功复制到"%~3\%~nx2") else 	#文件"%~2"复制失败，权限不足或文件被占用
	)
	goto :eof
)
REM 移动
if /i "%~1"=="move" (
	if /i "%~dp2"=="%~3\" (
		echo=	#文件"%~nx2"所在文件夹与目标文件夹相同，已跳过
		goto :eof
	)
	if /i "%~dp2"=="%~3" (
		echo=	#文件"%~nx2"所在文件夹与目标文件夹相同，已跳过
		goto :eof
	)
	if exist "%~3\%~nx2" (
		call:chooseresultrun2random "%~3\%~nx2"
		call:chooseresultrun2move "%~2" "!filenametemp!"
	) else (
		call:chooseresultrun2move "%~2" "%~3"
	)
	if defined filenametemp (
		if exist "!filenametemp!" (echo=	#发现目标文件夹已有"%~nx2",文件"%~2"已成功移动到"!filenametemp!") else 	#文件"%~2"移动失败，权限不足或文件被占用
	) else (
		if exist "%~3\%~nx2" (echo=	#文件"%~2"已成功移动到"%~3\%~nx2") else 	#文件"%~2"移动失败，权限不足或文件被占用
	)
	goto :eof
)
REM 删除
if /i "%~1"=="delete" (
	del /f /q "%~2"
	if exist "%~2" (
		echo=	#删除"%~2"失败,权限不足或文件被占用
	) else (
		echo=	#文件"%~2"删除完成
	)
	goto :eof
)
REM 名称替换
if /i "%~1"=="ren" (
	set "strrpcNameTemp=%~nx3"
	set "strrpcNameTemp=!strrpcNameTemp:%~4=%~5!"
	if exist "%~dp3\!strrpcNameTemp!" (echo=	#文件"!strrpcNameTemp!"已存在,已跳过名称替换) else (
		ren "%~3" "!strrpcNameTemp!"
		set "searchfiledijia%~2=%~dp3!strrpcNameTemp!"
		echo=	#文件"%~3"已重命名为"!strrpcNameTemp!"
	)
)

REM 名称添加
if /i "%~1"=="add" (
	set "strrpcNameTemp=%~4%~n3%~5%~x3"
	if exist "%~dp3\!strrpcNameTemp!" (echo=	#文件"!strrpcNameTemp!"已存在,已跳过名称添加) else (
		ren "%~3" "!strrpcNameTemp!"
		set "searchfiledijia%~2=%~dp3!strrpcNameTemp!"
		echo=	#文件"%~3"已重命名为"!strrpcNameTemp!"
	)
)
goto :eof


REM 整理结果序号提取内容
:clearcontent
if "%~1"=="" goto :eof
for %%a in (clearcontent clearcontentresult clearcontentresult2 clearcontentresult3) do if defined %%a set %%a=
set clearcontent=%~1
set clearcontent=%clearcontent:-=%
call:DefinedNoNumberString "!clearcontent:,=!"
if "!errorlevel!"=="0" (
	set clearcontentresult=包含违规或无效字符，请检查后重试
	goto :eof
)
for %%a in (%~1) do (
	set clearcontent=%%a
	if "!clearcontent!"=="!clearcontent:-=!" (
		set clearcontentresult2=!clearcontentresult2!,%%a
	) else (
		for /f "tokens=1,2,* delims=-" %%A in ("%%a") do (
			if "%%~A"=="" (
				set clearcontentresult=区间符"-"左、右有值为空，请检查后重试
				goto :eof
			)
			if "%%~B"=="" (
				set clearcontentresult=区间符"-"左、右有值为空，请检查后重试
				goto :eof
			)
			if not "%%~C"=="" (
				set clearcontentresult="%%~A-%%~B-%%~C"发现一个区间内多个区间符"-"，请检查后重试
				goto :eof
			)
			if "%%~A"=="%%~B" (
				set clearcontentresult2=!clearcontentresult2!,%%~A
				set clearcontentresult3=Yes
			)
			if "%%~A"=="0" (
				set clearcontentresult2=!clearcontentresult2!,1-%%~B
				set clearcontentresult3=Yes
			)
			if %%~A gtr %%~B (
				if "%%~B"=="0" (
					set clearcontentresult2=!clearcontentresult2!,1-%%~A
				) else (
					set clearcontentresult2=!clearcontentresult2!,%%~B-%%~A
				)
				set clearcontentresult3=Yes
			)
			if not defined clearcontentresult3 set clearcontentresult2=!clearcontentresult2!,%%~A-%%~B
		)
	)
)
goto :eof
REM 保存
:chooseresultrun2save
echo="%~1">>"%~2"
echo=	#"%~1"条目已写入"%~2"
goto :eof
REM 复制
:chooseresultrun2copy
copy "%~1" "%~2">nul 2>nul
goto :eof
REM 移动
:chooseresultrun2move
move "%~1" "%~2">nul 2>nul
goto :eof
REM 随机文件名
:chooseresultrun2random
set filenametemp=%~dpn1重复文件名项!random!!random!%~x1
goto :eof


REM 目录判断是否存在
:existfolder
if "%~1"=="" goto :eof
for %%a in (existfolder #existfolder) do if defined %%a set %%a=
:existfolder2
set existfolder2=%~1
if not "%existfolder2:~1,2%"==":\" goto :eof
if not "%existfolder2:~-1%"=="\" set existfolder2=%existfolder2%\
dir "%existfolder2%">nul 2>nul
if exist "%existfolder2%" (set existfolder=!existfolder! "!existfolder2!") else set #existfolder=!#existfolder! "!existfolder2!"
if not "%~2"=="" (
	shift /1
	goto existfolder2
)
goto :eof

REM 指定文件或目录合规判断
:checkfolderfile
if "%~1"=="" exit /b 1
for %%A in (copy move) do (
	if /i "%%A"=="%~1" (
		if "%%~b"=="" (
			echo=	#未指定操作路径,请重试
			exit/b 1
		) else (
			if not exist "%~2" (
				echo=	#指定操作路径"%~2"不存在,请检查后重试
				exit /b 1
			) else (
				dir "%~2">nul 2>nul||(
					echo=	#指定的操作路径"%~2"非文件夹,请检查后重试
					exit /b 1
				)
			)
		)
	)
)
for %%A in (save) do (
	if /i "%%A"=="%~1" (
		if "%~2"=="" (
			echo=	#未指定操作路径,请检查后重试
			exit/b 1
		)
		if exist "%~dp2\" (
			if exist "%~2" (
				echo=	#指定文件"%~2"已存在,请检查后重试
				exit /b 1
			)
		) else (
			echo=	#指定文件路径"%~dp2"不存在,请检查后重试
			exit /b 1
		)
	)
)
for %%A in (ren) do (
	if /i "%%A"=="%~1" if "%~2"=="" if "%~3"=="" (
		echo=	#未指定替换参数,请检查后重试
		exit/b 1
	)
)
exit /b 0

REM 小写转换为大写
:convert
if "%~1"=="" (goto :eof) else if not defined %~1 goto :eof
for %%a in ("a=A","b=B","c=C","d=D","e=E","f=F","g=G","h=H","i=I","j=J","k=K","l=L","m=M","n=N","o=O","p=P","q=Q","r=R","s=S","t=T","u=U","v=V","w=W","x=X","y=Y","z=Z") do set %~1=!%~1:%%~a!
goto :eof

REM 去除重复
:wipe2
if "%~1"=="" (goto :eof) else if defined %~1 (set %~1=!%~1: =!) else goto :eof
if defined wipe2result set wipe2result=
for %%a in (%litter%) do if not "!%~1:%%a=!"=="!%~1!" set wipe2result=!wipe2result! %%a
set %~1=%wipe2result:~1%
goto :eof

REM 判断变量中是否含有非数字字符 call:DefinedNoNumberString 被判断字符
REM					返回值0代表有非数字字符，返回值1代表无非数字字符
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

REM 判断变量中是否含有非a-z,A-Z字符 call:DefinedNoAbString 被判断字符
REM					返回值0代表有a-z,A-Z字符，返回值1代表无a-z,A-Z字符
:DefinedNoAbString
REM 判断子程序基本需求参数
if "%~1"=="" exit/b 2

REM 初始化子程序需求变量
for %%B in (DefinedNoAbString) do set %%B=
set DefinedNoAbString=%~1

REM 子程序开始运行
for %%B in (a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z,A,B,C,D,E,F,G,H,I,J,K,L,M,N,O,P,Q,R,S,T,U,V,W,X,Y,Z) do (
	set DefinedNoAbString=!DefinedNoAbString:%%B=!
	if not defined DefinedNoAbString exit/b 1
)
exit/b 0

REM 存在检查
:existcheck
if "%~1"=="" (goto :eof) else if not defined %~1 goto :eof
for %%a in (existcheck1 #%~1) do set %%a=
for %%a in (!%~1!) do if exist %%a:\ (set existcheck1=!existcheck1! %%a) else set #%~1=!#%~1! %%a
set %~1=%existcheck1%
goto :eof

REM 将结果写入文件
:createresultfile
if "%~1"=="" goto :eof
if not defined searchfiledijia1 goto :eof
set createresultfile=0
if not exist "%~d1\" goto :eof
if not exist "%~dp1" md "%~dp1"
echo=>"%~1"
:createresultfile2
set /a createresultfile+=1
if defined searchfiledijia!createresultfile! (
	echo=!searchfiledijia%createresultfile%!>>"%~1"
	set searchfiledijia!createresultfile!=
	goto createresultfile2
) else goto :eof
goto :eof

REM 重新显示列表
:echoresultlist
if not defined searchfiledijia1 goto :eof
set echoresultlist=0
cls
echo=#结果列表
echo=
:echoresultlist2
set /a echoresultlist+=1
if defined searchfiledijia%echoresultlist% (
	set echoresultlist2=!searchfiledijia%echoresultlist%:"=!
	if exist "!echoresultlist2!" echo=[!echoresultlist!]"!searchfiledijia%echoresultlist%!"[!echoresultlist!]
	goto echoresultlist2
) else (
	echo=
	goto :eof
)

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
set updateVersionPath=%temp%\%updateVersionName%%random%%ranom%%random%

REM 子程序开始运作
echo=#正在检测更新项目: %~1	当前版本: %~2
call:DownloadNetFile %~3/%updateVersionName% "%updateVersionPath%"
if not "%errorlevel%"=="0" (
	echo=	#更新失败,无法连接到服务器,请检查后重试
	exit/b
)
for /f "usebackq tokens=1,2 delims= " %%I in ("%updateVersionPath%") do (
	if %~2 lss %%I (
		echo=#检测到项目新版本 %%I 正在尝试更新项目...
		set updateNewVersion=%%I
		set updateNewVersionName=%%~J
		call:DownloadNetFile %~3/%%~J "%~dp0\%%~J"
		if "!errorlevel!"=="0" (
			set updateNewVersionPath=%~dp0%%~J
			echo=#项目 %~1 新版本 %%I 下载成功
			goto  UpdateProjectVersion2
		) else (
			if exist "%updateVersionPath%" del /f /q "%updateVersionPath%"
			echo=	#更新失败,无法从服务器下载更新文件,请稍后再试
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

REM call:DownloadNetFile 网址 路径及文件名
:下载网络文件 20151105
:DownloadNetFile
REM 检查子程序使用规则正确与否
if "%~2"=="" (
	echo=	#[Error %0:参数2]文件路径为空
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
echo=Set xPost = CreateObject("Microsoft.XMLHTTP") >"%downloadNetFileTempPath%"
echo=xPost.Open "GET",%downloadNetFileUrl%,0 >>"%downloadNetFileTempPath%"
echo=xPost.Send() >>"%downloadNetFileTempPath%"
echo=Set sGet = CreateObject("ADODB.Stream") >>"%downloadNetFileTempPath%"
echo=sGet.Mode = 3 >>"%downloadNetFileTempPath%"
echo=sGet.Type = 1 >>"%downloadNetFileTempPath%"
echo=sGet.Open() >>"%downloadNetFileTempPath%"
echo=sGet.Write(xPost.responseBody) >>"%downloadNetFileTempPath%"
echo=sGet.SaveToFile "%downloadNetFileFilePath%",2 >>"%downloadNetFileTempPath%"

REM 删除IE关于下载内容的缓存
for /f "tokens=3,* skip=2" %%- in ('reg query "hkcu\software\microsoft\windows\currentversion\explorer\shell folders" /v cache') do if "%%~."=="" (set downloadNetFileCachePath=%%-) else set downloadNetFileCachePath=%%- %%.
for /r "%downloadNetFileCachePath%" %%- in ("%~n1*") do if exist "%%~-" del /f /q "%%~-"

REM 运行脚本
cscript //b "%downloadNetFileTempPath%"

REM 删除临时文件
if exist "%downloadNetFIleTempPath%" del /f /q "%downloadNetFIleTempPath%"

REM 判断脚本运行结果
if exist "%downloadNetFileFilePath%" (exit/b 0) else exit/b 1

REM 搜索后命令帮助
:searchresulthelp
if "%~1"=="1" (
	echo=
	echo=#帮助
	echo=	1.输入";"可清屏并重新查看搜索结果
	echo=	2.输入搜索结果前或后"[]"中的文件序号可打开该文件
	echo=	  在文件序号后加一个空格则会使用Windows资源管理器打开文件所在路径
	echo=	3.输入"//"并在后面跟字符可从结果中筛选包含"//"后字符的结果^(此命令需要findstr^)
	echo=		例:从结果中筛选包含windows的结果 : //windows
	echo=	4.输入"/-"并在后面跟字符可从结果中筛选不包含"/-"后字符的结果^(此命令需要findstr^)
	echo=		例:从结果中筛选不包含windows的结果 : /-windows
	echo=	5.输入"'"并在后面跟关键字在当前指定搜索目录下重新搜索含有"'"后跟关键字的文件
	echo=	  也可只输入"'"后根据提示操作
	echo=		例:从当前指定搜索目录下重新搜索含有bfs的文件 : 'bfs
	echo=	6.输入 /o /w /d 分别代表 "打开" "陆续打开" "删除"
	echo=	  使用方法为可在 /o /w /d 后跟文件序号即可实现对文件的操作
	echo=	  对文件序号的指定可使用符号 "-" "," 与符号 "*" 其中 "-" 代表区间分隔符 "," 代表单个数值分隔符 "*" 代表所有
	echo=		例:将结果中所有文件删除: /d*
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件删除: /d1-5,9,11-13
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件打开: /o1-5,9,11-13
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件陆续打开: /w1-5,9,11-13
	echo=	7.输入 /c /m /s 分别代表 "复制到指定文件夹" "移动到指定文件夹" "保存条目到指定文本文档"
	echo=	  使用方法为可在 /c /m /s 后跟文件序号+空格+动作路径即可实现对文件的操作
	echo=	  对文件序号的指定可使用符号 "-" "," 与符号 "*" 其中 "-" 代表区间分隔符 "," 代表单个数值分隔符 "*" 代表所有
	echo=		例:将结果中所有文件复制到"d:\temp\" : /c* d:\temp\
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件复制到"d:\temp\" : /c1-5,9,11-13 d:\temp\
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件移动到"d:\temp\" : /m1-5,9,11-13 d:\temp\
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件条目保存到"d:\temp\list.txt" : /s1-5,9,11-13 d:\temp\list.txt
	echo=	8.输入 /r /a 分别代表替换文件名、文件名填充
	echo=	  使用方法为可在 /r 后跟文件序号+空格+被替换字符+空格+替换后字符 即可实现对文件的操作
	echo=	  使用方法为可在 /a 后跟文件序号+空格+文件名前添加字符+空格+文件名后添加字符 即可实现对文件的操作
	echo=	  对文件序号的指定可使用符号 "-" "," 与符号 "*" 其中 "-" 代表区间分隔符 "," 代表单个数值分隔符 "*" 代表所有
	echo=		例:将结果中所有文件名包含temp的内容替换为notemp : /r* temp notemp
	echo=		例:将结果中序号为1,2,3,4,5,9,11,12,13所代表的文件文件名中包含temp的内容替换为notemp : /r1-5,9,11-13 temp notemp
	echo=	9.输入"0"或":"可返回主菜单
	echo=	10.输入"."可退出
	echo=
)
if "%~1"=="2" (
	echo=
	echo=#帮助
	echo=	1.全盘搜索请输入","或"*"
	echo=	2.退出可输入"."
	echo=	3.此处可输入单个或多个分区盘符以指定搜索范围
	echo=	4.此处单个或多个目录以指定搜索范围
	echo=	  多个目录之间用空格分开且如果目录中含有空格请在两边加英文双引号
	echo=		例:指定C: D: E: 为搜索范围在此处输入"cde"即可
	echo=		例:指定目录c:\windows与d:\program files为搜索范围
	echo=		   在此处输入 c:\windows "d:\program files" 即可
	echo=
	reg query hkcr\folder\shell\BFS搜索\command /ve >nul 2>nul
	if "!errorlevel!"=="0" (echo=	5.卸载文件夹右键搜索菜单可输入 "$" ^(当前已安装^)) else echo=	5.安装文件夹右键搜索菜单可输入 "$" ^(当前未安装^)
	echo=		注意:卸载或安装右键菜单需要管理员权限
	echo=
	echo=	6.输入 "@" 可检测更新BFS搜索^(可能会被杀毒软件报毒，信任即可^)
	echo=
)
if "%~1"=="3" (
	echo=
	echo=#帮助
	echo=	1.如要搜索的文件中含有某个关键字直接输入所要搜索的关键字即可^(不区分大小写^)
	echo=	  可同时输入多组关键字,多个关键字之间用空格隔开
	echo=	  如关键字内有空格需用英文双引号括住
	echo=		例:搜索文件名中含有bfs或含有"g d"的文件输入:bfs "g d"
	echo=	2.如需搜索指定准确文件名需在文件名前加"\"
	echo=		例:搜索文件名为bfs.bat的文件: \bfs.bat
	echo=	3.搜索支持通配符"*","?"
	echo=		由于批处理的特殊符号特殊性,暂时无法通过关键字搜索文件名含有符号 "&" "^" 的文件
	echo=		含有 ";" 的文件需给关键字加上双引号
	echo=			^(通过其它关键字搜索出的结果含有符号 "&" ";" 不会有其它影响^)
	echo=	4.输入 ":" 可返回主菜单
	echo=
	echo=	5.快捷搜索
	echo=	  /image		常见图片类型
	echo=	  /video		常见视频类型
	echo=	  /audio		常见音频类型
	echo=	  /txt		常见文档类型
	echo=	  /compress	常见压缩文件类型
	echo=		例:搜索常见视频类型文件输入:/video
	echo=
)
if "%~1"=="4" (
	echo=#帮助
	echo=	1.如需指定所有搜索结果输入"*"即可
	echo=	2.如需指定单个结果输入结果序列号即可
	echo=	3.如需指定某个结果序列区间可将起始序列号与结束序列号用"-"连接，例如：5-19
	echo=	4.如需指定多个不连续结果序列可用","进行分割，例如：5,7,9,13
	echo=	  符号 "-" 与 "," 可以配合使用 例:1,2,5-19,30
	echo=	5.输入"0"或":"可返回主菜单
	echo=	6.输入"."可退出
	echo=
)
if "%~1"=="5" (
	echo=#帮助
	echo=	1.直接在此处输入目标路径即可
	echo=	2.输入"0"或":"可返回主菜单
	echo=	3.输入"."可退出
	echo=
)
goto :eof


:-----------------------------------子程序结束-----------------------------------
:end
exit /b