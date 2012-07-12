Option Explicit

Const bWaitOnReturn = TRUE
Dim sahi_home, sahi_userdata, sahi_scripts, sahi_results, send_nsca_bin, send_nsca_cfg, send_nsca_port
Dim debug, version, FSObject
Dim command,jobid,resultfile, nscadatafile,timenow,timestart,timeend,Wshell,runtime, arr_results, outputstring
Dim i,file,url,browser,warning,critical,nagios,hostname,service,maxthreads,singlesession,help,helpstring

 ' �berpr�fung ob Sahi l�uft
 ' �berpr�fung ob g�ltiger Testcase angegeben wurde
 ' �berpr�fung ob results erzeugt werden konnten
 ' automatische Erkennung ob suite oder einzel-Test
 
' ##############################################################################
' Configuration 
' ##############################################################################

' Sahi installation path
sahi_home = "C:\sahi"
' Sahi userdata 
sahi_userdata = sahi_home & "\userdata"
' Sahi Script directory
sahi_scripts = sahi_userdata & "\scripts"
' result file path (remember the double Backslashes!)
sahi_results = "C:\\sahi\\userdata\\temp"
' send_nsca executable
send_nsca_bin = "C:\Programme\send_nsca\send_nsca.exe"
' send_nsca config file
send_nsca_cfg = "C:\Programme\send_nsca\send_nsca.cfg"
' send_nsca port
send_nsca_port = 5667

' ##############################################################################
' Don't change anything below
' ##############################################################################
helpstring = "Get help with parameter /?."

Do While i < Wscript.Arguments.Count
	If WScript.Arguments(i) = "/?" or WScript.Arguments(i) = "-?" then
		help = 1
		exit do
	ElseIf WScript.Arguments(i) = "/f" or WScript.Arguments(i) = "-f" then
		i = i + 1
		If i < Wscript.Arguments.Count Then
			file = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the sahi test case (.sah) or suite (.suite) file (-f). " & helpstring 
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/u" or WScript.Arguments(i) = "-u" then
		i = i + 1
		If i < Wscript.Arguments.Count Then
			url = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify a start URL (-u). "  & helpstring
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/b" or WScript.Arguments(i) = "-b" then
		i = i + 1
		If i < Wscript.Arguments.Count Then
			browser = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify a browser type (ie|firefox|firefox4|chrome|safari|opera) with -b. " & helpstring
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/w" or WScript.Arguments(i) = "-w" then
		i = i + 1
		warning = Int(WScript.Arguments(i))	
	ElseIf WScript.Arguments(i) = "/c" or WScript.Arguments(i) = "-c" then
		i = i + 1
		critical = Int(WScript.Arguments(i))				
	ElseIf WScript.Arguments(i) = "/n" or WScript.Arguments(i) = "-n" then
		i = i + 1
		If i < Wscript.Arguments.Count Then
			nagios = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the receiving monitoring server (-n). "  & helpstring
			WScript.quit(1)
		End If	
	ElseIf WScript.Arguments(i) = "/h" or WScript.Arguments(i) = "-h" then
		i = i + 1
		If i < Wscript.Arguments.Count Then
			hostname = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the host (-h) and servicedescription (-s) on the monitoring system. "  & helpstring
			WScript.quit(1)
		End If	
	ElseIf WScript.Arguments(i) = "/s" or WScript.Arguments(i) = "-s" then
		i = i + 1
		If i < Wscript.Arguments.Count Then
			service = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the host (-h) and servicedescription (-s) on the monitoring system."  & helpstring
			WScript.quit(1)
		End If	
	ElseIf WScript.Arguments(i) = "/z" or WScript.Arguments(i) = "-z" then
		singlesession = true
	ElseIf WScript.Arguments(i) = "/m" or WScript.Arguments(i) = "-m" then
		i = i + 1
		maxthreads = WScript.Arguments(i)		
	End If
	i = i + 1
Loop

If help = 1 Then
	Call about()
	WScript.Quit(1)
End If
	
If file = "" Then
	WScript.echo "ERROR: Please specify a test file/suite (-f) relative to the sahi/userdata/scripts directory. "  & helpstring
	WScript.quit(1)
End If

If browser = "" Then
	WScript.echo "ERROR: Please specify a browser type (-b). "  & helpstring
	WScript.quit(1)
End If

If browser = "" Then
	WScript.echo "ERROR: Please specify a browser type (-b). "  & helpstring
	WScript.quit(1)
End If

If url = "" Then
	WScript.echo "ERROR: Please specify a base url (-u). "  & helpstring
	WScript.quit(1)
End If

If nagios = "" Then
	WScript.echo "ERROR: Please specify the receiving monitoring server (-n). "  & helpstring
	WScript.quit(1)
End If

If hostname = "" Then
	WScript.echo "ERROR: Please specify a host (-h) on the monitoring system. "  & helpstring
	WScript.quit(1)
End If

If service = "" Then
	WScript.echo "ERROR: Please specify a servicedescription (-s) on the monitoring system. "  & helpstring
	WScript.quit(1)
End If

If maxthreads = "" Then
	maxthreads = 1
End If

If singlesession = "" Then
	singlesession = "false"
End If

If (warning > critical) Then
	WScript.echo "ERROR: Warning threshold (-w) must be lower than critical threshold (-c). "  & helpstring
	WScript.quit(1)
End If
		

Set FSObject = CreateObject("Scripting.FileSystemObject")
jobid = get_jobid
resultfile = sahi_results & "\\" & jobid & "_sahitestdata.TMP"
nscadatafile = sahi_results & "\\" & jobid & "_nscadata.TMP"

' HEALTH CHECKS -----------------------------------------------------------------------------------
' check if sahi is running
if not sahirunning then
	die 3, "UNKNOWN: Sahi does not run. Verify that Sahi is started and ready to run the tests. "  & helpstring
end if
' check if we have a existent check file
filexistsOrDie sahi_scripts & "\" & file, "Sahi Test/Suite file " & sahi_scripts & "\" & file & " could not be found! "  & helpstring
' check if NSCA can work (theoretically...)
filexistsOrDie send_nsca_bin, "NSCA binary " & send_nsca_bin & " could not be found!"
filexistsOrDie send_nsca_cfg, "NSCA config file " & send_nsca_cfg & " could not be found!"

' RUN TESTS  -----------------------------------------------------------------------------------
command = "java -cp " & sahi_home & "\lib\ant-sahi.jar net.sf.sahi.test.TestRunner -test " &  _
	sahi_scripts & "\" & file & " -browserType " & browser & " -baseURL " & url & " -host localhost " &_
	"-port 9999 -threads " & maxthreads & " -useSingleSession " & singlesession & _
	" -initJS " & Chr(34) & "var $resultfile=" & Chr(39) & resultfile & Chr(39) & Chr(59) & Chr(34)

Set Wshell = WScript.CreateObject("WScript.shell")
timeStart = Timer
Wshell.run command, 1, bWaitOnReturn
Set Wshell = Nothing
timeend = Timer
runtime = Round(timeend-timestart,0)

' check if the sahi check was able to create the test result file
filexistsOrDie resultfile, "Cannot find the result file " & resultfile

' read TMP-resultfile and send the data to OMD (or DB... todo)
data2OMD(resultfile)

Set FSObject = Nothing

Sub data2OMD (resultfile)
	Dim arr_results, i, j, worststate, currentstate, durationstate, durationresult, suite, perfdata, check_command, output
	worststate = 0
	perfdata = ""
	check_command = ""
	output = ""
	suite = ""
	' read check results from TMP file
	arr_results = ReadDataToArray(resultfile)
	
	' TEST RESULTS
	for i=0 to UBound(arr_results,1)  
		if (Abs(StrComp(arr_results(i,0), arr_results(i,1), 1))) then
			suite = arr_results(i,0)
		end if
		output = output & state2str(arr_results(i,2)) & ": Sahi test " & Chr(39) & arr_results(i,1) & Chr(39) & _
			" (" & arr_results(i,3) & "s) " & arr_results(i,6) 
		currentstate = arr_results(i,2)
		if (currentstate > worststate) then
			worststate = currentstate
		end if
		
		perfdata = perfdata & arr_results(i,1) & "=" & arr_results(i,3) & "s;" & arr_results(i,4) & ";" & arr_results(i,5) & ";; "
	next 
	' verify that each row of the csv file contains 8 elements
	if ( UBound(arr_results,2) > 8) then
		die 3, "After test execution, an error occurred while reading in the sahi result data file: " & _
			"Found more than 8 elements in one row; check " & resultfile & "."
	elseif ( UBound(arr_results,2) < 8) then
		die 3, "After test execution, an error occurred while reading in the sahi result data file: " & _
			"Found less than 8 elements in one row; check " & resultfile & "."
	end if 
	check_command = "[check_sahi_case]"
	
	' SUITE RESULT
	if ( Len(suite) > 0 ) then
		' if there are errors, we dont care for the total runtime!
		if (worststate > 0) then
			output = state2str(worststate) & ": Sahi suite " & Chr(39) & suite & Chr(39) & _
				" (total " & runtime & "s) ended " & state2oknok(worststate) & " " & output 
		else
			durationresult = getduration_result(runtime, warning, critical)
			if (durationresult > 0) then
				output = " exceeded runtime (warn: " & warning & ", crit: " & critical & ") " & output 
			end if			
			output = state2str(durationresult) & ": Sahi suite " & Chr(39) & UCase(suite) & Chr(39) & " (total " & runtime & " s) " & output
		end if
		check_command = "[check_sahi_suite]"
		' if run in a suite, include total runtime in performance data
		perfdata = perfdata & suite & "=" & runtime & "s;" & warning & ";" & critical & ";; "
		
	end if
	perfdata = perfdata & check_command
	' fixme: Alternative send2DB
	send2NSCA hostname, service, worststate, output, perfdata, nagios
end sub

sub send2NSCA (inhostname, inservice, instatus, inoutput, inperfdata, innagios)
	'wscript.echo "sto"
	Dim command, objFSO, objFile, nscadata, Wshell, delim
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFSO.CreateTextFile(nscadatafile, True)
	' if we send an error message, we dont need perfdata
	if (inperfdata = "") then
		delim = ""
	else
		delim = "|"
	end if
	nscadata = inhostname & Chr(44) & inservice & Chr(44) & instatus & Chr(44) & inoutput & delim & inperfdata & Chr(13) & chr(10)
	objFile.Write nscadata
	objFile.Close
	command = "cmd /c < " & nscadatafile & " " & send_nsca_bin & " -H " & innagios & " -p " & send_nsca_port & " -c " & send_nsca_cfg & " -d ,"
	Set Wshell = WScript.CreateObject("WScript.shell")
	Wshell.run command, 0, bWaitOnReturn
	Set Wshell = Nothing
	Set objFSO = Nothing
	Set objFile = Nothing
end sub 

sub filexistsOrDie(infile, instr)
	if not FSObject.FileExists(infile) then
		die 3, "UNKNOWN: " & instr
	end if
end sub

sub die(instate, inmsg)
	send2NSCA hostname, service, instate, inmsg, "", nagios
	wscript.echo inmsg
	Wscript.quit
end sub

function sahirunning 
	Dim strComputer, objWMIService, colProcesses, ret
	strComputer = "."
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
	Set colProcesses = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'java.exe'")
	If colProcesses.Count = 0 Then
		ret = false
	Else
		ret = true
	End If
	Set objWMIService = Nothing
	Set colProcesses = Nothing
	sahirunning = ret
end function

function getduration_result (dur, w, c)
' compares total script runtime against thresholds
' if no thresholds are set (=0), OK is returned
	Dim ret
	ret = 0
	
	if ((w > 0) and (c > 0)) then 
		if ( dur >= w ) then
			if (dur < c) then
				ret = 1    
			else
				ret = 2
			end if
		end if
	end if
	getduration_result = ret
end function
	
function state2str (instate)
	Dim ret	
	Select Case instate
	Case 0
		ret = "OK"
	Case 1
		ret = "WARNING"
	Case 2 
		ret = "CRITICAL"
	End Select 
	state2str = ret
end function	
	
function state2oknok (instate)
	Dim ret
	if (instate > 0) then
		ret = "with errors:"
	else
		ret = "without errors:"
	end if
	state2oknok = ret
end function	
	
function ReadDataToArray (filename) 
 Dim objFSO, result, i, j, n, strLine, InFile
  Set objFSO = CreateObject("Scripting.FileSystemObject")    
  result = array ()  
  Set InFile = objFSO.OpenTextFile(filename, 1, False)  
  ReDim result(0,1)  
  i = 0  
  n = 0

  do until InFile.AtEndofStream    
        strLine = InFile.Readline  
	
        ' check if not empty line, with correct information  
        if ((strLine <> "") and (InStr(strLine, """") <> 0)) then  
	
          ' split line to know how many elemtns to process'  
		  strLine = split (strLine, ";")  
		  ReDim result(n, UBound(strLine))    
		  n = n + 1
          i = i + 1                          
        end if                                
  loop  

  Set InFile = objFSO.OpenTextFile(filename, 1, False)  
  i = 0  
  do until InFile.AtEndofStream    
    strLine = InFile.Readline  
    ' check if not empty line, with correct information  
    if ((strLine <> "") and (InStr(strLine, """") <> 0)) then  
      strLine = split (strLine, ";")          
      for j = 0 to UBound(strLine)  
			result(i,j) = Replace(strLine(j), Chr(34), "" )
      next                                                                                                                
      i = i + 1                          
    end if                                
  loop  
  Set InFile = Nothing
  Set objFSO = Nothing
  ReadDataToArray = result   
end function 


Sub about()
		WScript.echo "Startup script for sahi tests which sends results to a OMD monitoring server." & vbcrlf & _
					 "2012 by Simon Meggle, ConSol GmbH <simon.meggle@consol.de>" & vbcrlf & _
					 "Usage:" & vbcrlf & vbcrlf & _
		             "sahi2omd.vbs  [-f <sahi file>] [-u <startURL>] [-b <browser>]" & vbcrlf & _
		             "        [-w <warning (sec)>] [-c <critical (sec)>]" & vbcrlf & _
		             "        [-n <monitoring server>] [-h <hostname>]" & vbcrlf & _
		             "        [-s <servicedescription>] [-z ] [-m <maxsessions> ]" & vbcrlf & _					 
		             "" & vbcrlf & _
		             "Parameters:" & vbcrlf & _
		             "-f      Sahi test case (.sah) or test suite (.suite) file. " & vbcrlf & _
		             "        Relative to sahi_scripts (see config config section in this script)" & vbcrlf & _
		             "        e.g. '-f intranet\instranet_login.sah" & vbcrlf & _
		             "" & vbcrlf & _
		             "-u      URL the test/suite should start from." & vbcrlf & _
		             "        e.h. http://intranet.mydomain.local" & vbcrlf & _
		             "" & vbcrlf & _
		             "-b      Browser type. See Sahi Dashboard -> configure for allowed values." & vbcrlf & _
		             "" & vbcrlf & _ 
		             "-w      warning runtime threshold (seconds) for the whole check." & vbcrlf & _
		             "-c      critical runtime threshold (seconds) for the whole check." & vbcrlf & _
		             "" & vbcrlf & _
		             "-n      receiving monitoring server" & vbcrlf & _
		             "-h      hostname" & vbcrlf & _
		             "-s      servicedescription" & vbcrlf & _
		             "" & vbcrlf & _
		             "-z      use singlesession (does not re-open the browser for each test case." & vbcrlf & _
					 "        (default: false)" & vbcrlf & _
		             "-m      maximum number of simultaneous threads (default: 1)" & vbcrlf & _
					 " " & vbcrlf & _					 
		             "For any other settings see config section in this script. " & vbcrlf 
End Sub

Function get_jobid()
	Dim rdnum
	Randomize
	rdnum = Rnd
	get_jobid = Int(rdnum * 1000000) 
End Function 

sub EchoOut2DArray (arr)  
  for i=0 to UBound(arr,1)  
    for j=0 to UBound(arr,2)       
      wscript.echo "[" & i & "," & j & "] = " & arr(i,j)  
    next  
  next     
end sub 


