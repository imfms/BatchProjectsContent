@echo off&setlocal ENABLEDELAYEDEXPANSION
for /l %%i in (1,1,11) do set recentcommands%%i=&set min=&set max=
:recentcommands
if not exist a.txt set recentcommands1=您暂未使用过此功能&goto end
for /f "tokens=1,* delims=:" %%a in ('findstr /n "." "a.txt"') do set recentcommands%%a=%%b&set max=%a%
for /l %%i in (1,1,%max%) do echo=recentcommands%%i:!recentcommands%%i!
:end
pause