' cscript.exe modwindow.vbs maximize "Exact window title"

Dim resm, title, oShell

title = WScript.Arguments(0)
action = WScript.Arguments(1)

Set oShell = CreateObject("WScript.Shell")
res = oShell.AppActivate(title)

If res = True Then

	Select Case action 
		Case "maximize"
			oShell.SendKeys("{F11}")
			'oShell.SendKeys("% ")
			'oShell.SendKeys("x")
		Case "minimize"
			'oShell.SendKeys("% ")
			'oShell.SendKeys("n")
	End Select	
	'WScript.Sleep 100
End If

Set oShell = Nothing
