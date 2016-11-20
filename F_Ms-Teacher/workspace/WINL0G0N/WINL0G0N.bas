Attribute VB_Name = "Module1"
Declare Function BlockInput Lib "user32" (ByVal fBlock As Long) As Long
Private Declare Sub Sleep Lib "Kernel32" (ByVal dwMilliseconds As Long)
Dim T
Sub Main()
    T = 5000
    Do
        BlockInput (True)
        Sleep T
    Loop
End Sub
