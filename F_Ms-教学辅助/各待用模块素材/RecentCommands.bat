@echo off&setlocal ENABLEDELAYEDEXPANSION
for /l %%i in (1,1,11) do set recentcommands%%i=&set min=&set max=
:recentcommands
if not exist a.txt set recentcommands1=您暂未使用过此功能&goto end
for /f "delims=:" %%i in ('findstr /n . a.txt') do set max=%%i
if %max% leq 10 (
	for /f "tokens=1,* delims=:" %%a in ('findstr /n "." "a.txt"') do set recentcommands%%a=%%b
) else (
	set /a min=max-9
	for /f "tokens=1,* delims=:" %%a in ('findstr /n "." "a.txt"') do (
		if %%a geq !min! (
			set /a recentcommands11+=1
			set recentcommands!recentcommands11!=%%b
		)
	)
)
for /l %%i in (1,1,10) do echo=recentcommands%%i:!recentcommands%%i!
:end
pause