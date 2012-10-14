Option Explicit
' NSCA
' -mode nsca -m 1 -f testcases\0_OK_3stp_ok.sah -b firefox -capture -u http://oxid/shop/ -n omd1 -h sahidose -s 0_OK_3stp_ok.sah
' DB
' -mode db -m 1 -f testcases\0_OK_3stp_ok.sah -b firefox -capture -u http://oxid/shop/ -n omd1 -h sahidose -s 0_OK_3stp_ok.sah

Const bWaitOnReturn = True
Dim sahi_home, sahi_userdata, sahi_scripts, sahi_results, send_nsca_bin, send_nsca_cfg, sahi2omd_cfg,send_nsca_port,mode
Dim debug, version, FSObject, debugfile, objdebug, mysql_connector,mysql_user,mysql_password,mysql_host,mysql_dbname,mysql_odbcdriver
Dim command,guid,resultfile, nscadatafile,timenow,timestart,timeend,Wshell,runtime, arr_results, capture, modwindow
Dim i,file,url,browser,warning,critical,nagios,hostname,service,maxthreads,singlesession,help,helpstring,expandsuite,printcfg

guid = get_guid()

 ' Überprüfung ob Sahi läuft
 ' Überprüfung ob gültiger Testcase angegeben wurde
 ' Überprüfung ob results erzeugt werden konnten
 ' automatische Erkennung ob suite oder einzel-Test
 
' ##############################################################################
' Configuration 
' ##############################################################################

debug = 1

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
' where to write Nagios configuration samples (option -p) FIXME
sahi2omd_cfg = sahi_userdata & "\sahi2omd.cfg"
' Debug File 
debugfile = sahi_userdata & "\temp\" & guid & "sahi2omd.log"
' MySQL Hostname
mysql_host = "localhost"
' MySQL Sahi Database Name
mysql_dbname = "sahi"
' MySQL ODBC Driver 
mysql_odbcdriver = "MySQL ODBC 5.1 Driver"
' MySQL Connector; if you use mode 'mysql' this (or a newer) driver has to be present
mysql_connector = sahi_home & "\extlib\db\mysql-connector-java-5.1.21-bin.jar"
' MySQL user
mysql_user = "sahi"
' MySQL password
mysql_password = "sahipw"
' modwindow script
modwindow = sahi_userdata & "\bin\modwindow.vbs"

' ##############################################################################
' Don't change anything below
' ##############################################################################

' MAIN =====================================================================================
helpstring = "Get help with parameter /?."

Set FSObject = CreateObject("Scripting.FileSystemObject")

If debug = 1 Then 
	Set objdebug = FSObject.CreateTextFile(debugfile, True)	
End If 

dbg "Sahi2OMD.vbs started..."
dbg "Parsing Arguments..."
Do While i < WScript.Arguments.Count
	If WScript.Arguments(i) = "/?" Or WScript.Arguments(i) = "-?" Then
		help = 1
		Exit Do
	ElseIf WScript.Arguments(i) = "/mode" Or WScript.Arguments(i) = "-mode" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			mode = LCase(WScript.Arguments(i))
		Else
			WScript.echo "ERROR: You must specify a mode (nsca/db). " & helpstring 
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/f" Or WScript.Arguments(i) = "-f" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			file = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the sahi test case (.sah) or suite (.suite) file (-f). " & helpstring 
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/u" Or WScript.Arguments(i) = "-u" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			url = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify a start URL (-u). "  & helpstring
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/b" Or WScript.Arguments(i) = "-b" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			browser = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify a browser type (ie|firefox|firefox4|chrome|safari|opera) with -b. " & helpstring
			WScript.quit(1)
		End If
	ElseIf WScript.Arguments(i) = "/w" Or WScript.Arguments(i) = "-w" Then
		i = i + 1
		warning = Int(WScript.Arguments(i))	
	ElseIf WScript.Arguments(i) = "/c" Or WScript.Arguments(i) = "-c" Then
		i = i + 1
		critical = Int(WScript.Arguments(i))				
	ElseIf WScript.Arguments(i) = "/n" Or WScript.Arguments(i) = "-n" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			nagios = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the receiving monitoring server (-n). "  & helpstring
			WScript.quit(1)
		End If	
	ElseIf WScript.Arguments(i) = "/h" Or WScript.Arguments(i) = "-h" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			hostname = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the host (-h) and servicedescription (-s) on the monitoring system. "  & helpstring
			WScript.quit(1)
		End If	
	ElseIf WScript.Arguments(i) = "/s" Or WScript.Arguments(i) = "-s" Then
		i = i + 1
		If i < WScript.Arguments.Count Then
			service = WScript.Arguments(i)
		Else
			WScript.echo "ERROR: Please specify the host (-h) and servicedescription (-s) on the monitoring system."  & helpstring
			WScript.quit(1)
		End If	
	ElseIf WScript.Arguments(i) = "/e" Or WScript.Arguments(i) = "-e" Then
		expandsuite = True
	ElseIf WScript.Arguments(i) = "/z" Or WScript.Arguments(i) = "-z" Then
		singlesession = True
	ElseIf WScript.Arguments(i) = "/p" Or WScript.Arguments(i) = "-p" Then
		printcfg = True
	ElseIf WScript.Arguments(i) = "/capture" Or WScript.Arguments(i) = "-capture" Then
		capture = True
	ElseIf WScript.Arguments(i) = "/m" Or WScript.Arguments(i) = "-m" Then
		i = i + 1
		maxthreads = WScript.Arguments(i)		
	End If
	i = i + 1
Loop

If help = 1 Then
	Call about()
	WScript.Quit(1)
End If

If mode = "" Then
	WScript.echo "ERROR: You must specify a mode (nsca/db). "  & helpstring
	WScript.quit(1)
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



If maxthreads = "" Then
	maxthreads = 1
End If

If expandsuite = "" Then
	expandsuite = "false"
End If

If printcfg = "" Then
	printcfg = "false"
End If

If singlesession = "" Then
	singlesession = "false"
End If

If (warning > critical) Then
	WScript.echo "ERROR: Warning threshold (-w) must be lower than critical threshold (-c). "  & helpstring
	WScript.quit(1)
End If
		


' Health checks
If (is_mode_nsca) Then 
	nsca_health_or_die
Else
	file_Exists_OrDie mysql_connector, "Script ERROR: sahi2omd.vbs was called with mode 'db', but no MySQL Connector file was found." & _
		"Please specify the correct mysql_connector in the config section of sahi2omd.vbs." 
End If 

If capture Then
	file_Exists_OrDie modwindow, "Script ERROR: Could not find '" & modwindow & "'!"
End If


If Not sahi_health Then
	dbg "Script ERROR: Sahi does not run. Exiting. "
	die "Script ERROR: Sahi does not run. Verify that Sahi is started and ready to run the tests. "  & helpstring, 3
Else
	dbg "Sahi process is running properly. "
End If

dir_Exists_or_create(sahi_userdata & "\logs\screenshots")

' check if Sahi Suite / Case File is present
file_Exists_OrDie sahi_scripts & "\" & file, "Sahi Test/Suite file " & sahi_scripts & "\" & file & " could not be found! "  & helpstring

' RUN TESTS  -----------------------------------------------------------------------------------
command = "java -cp " & sahi_home & "\lib\ant-sahi.jar net.sf.sahi.test.TestRunner -test " &  _
	sahi_scripts & "\" & file & " -browserType " & browser & " -baseURL " & url & " -host localhost " &_
	"-port 9999 -threads " & maxthreads & " -useSingleSession " & singlesession 
' add guid
command = command & " -initJS " & Chr(34) & "var $guid=" & Chr(39) & guid & Chr(39) & Chr(59)
' add sahi userdata dir
command = command & "var $sahi_userdata=" & Chr(39) & Replace(sahi_userdata, "\", "\\" ) & Chr(39) & Chr(59)
' add capture mode
command = command & "var $capture=" & Chr(39) & capture & Chr(39) & Chr(59)
' add working mode variable (db/nsca)
command = command & "var $mode=" & Chr(39) & mode & Chr(39) & Chr(59) & Chr(34)

dbg "Now calling Sahi command: '" & command & "'"
Set Wshell = WScript.CreateObject("WScript.shell")
Wshell.run command, 1, bWaitOnReturn
Set Wshell = Nothing


If (is_mode_db) Then

	' guid is stored in the very end of each run. This is to prevent check_mysql_health on the Nagios
	' side to read out suite/case results while the whole suite/case is still running.
	dbg "...all Sahi cases were executed. Storing ID of this run (" & guid & ") into database."
	store_guid guid,mysql_user,mysql_password,mysql_host,mysql_dbname,mysql_odbcdriver
Else
	' check if NSCA result file was created
	file_Exists_OrDie resultfile, "sahi2omd.vbs cannot find the result file " & resultfile

	' read TMP-resultfile and send the data to OMD (or DB... todo)
	dbg "Now reading in result file " & resultfile & " ..."
	data2OMD(resultfile)

	Set FSObject = Nothing
End If

dbg "- Script ended. -"
' End MAIN ==========================================================================================

' helper functions -----------------------------------------------------------------------------------
Sub data2OMD (resultfile)
	Dim arr_results, i, j, worststate, currentstate, durationstate, durationresult, suite, perfdata, check_command, output, case_shortname
	worststate = 0
	perfdata = ""
	check_command = ""
	output = ""
	suite = ""
	' read check results from TMP file
	arr_results = ReadDataToArray(resultfile)
	
	If (expandsuite = "false") Then
		' collect all tests as suite result
		dbg "expandsuite is not set - this case/suite will be treated as a single nagios service..."
		
		For i = 0 To UBound(arr_results, 1)  
			' arr_results(n,0) = suitename
			' arr_results(n,1) = casename
			' arr_results(n,2) = case_result
			' arr_results(n,3) = case_duration
			' arr_results(n,4) = case_warn
			' arr_results(n,5) = case_crit
			' arr_results(n,6) = msg
			' arr_results(n,7) = browser
			' arr_results(n,8) = lastpage
			
			' do we have a suite? 
			If (Abs(StrComp(arr_results(i,0), arr_results(i,1), 1))) Then
				suite = arr_results(i,0)
				dbg "Suitename != Casename -> This Case ran within suite " & suite
			Else 
				dbg "Suitename == Casename -> This Case did not run within a suite."
			End If
			output = output & state2str(arr_results(i,2)) & ": Case " & Chr(39) & arr_results(i,1) & Chr(39) & _
				" (" & arr_results(i,3) & "s) " & arr_results(i,6) 
			
			' total runtime = runtime_case1 + runtime_case2 + ... 
			runtime = runtime + CDbl(arr_results(i,3))
			dbg("Total runtime is now: " & runtime)
			currentstate = arr_results(i,2)
			If (currentstate > worststate) Then
				worststate = currentstate
			End If
			case_shortname = Left( arr_results(i,1), Len(arr_results(i,1))-4)
	
			perfdata = perfdata & case_shortname & "=" & arr_results(i, 3) & "s;" & arr_results(i, 4) & ";" & arr_results(i, 5) & ";; "
			dbg("perfdata is now: " & perfdata)
		Next 
		' verify that each row of the csv file contains 8 elements
		If ( UBound(arr_results,2) > 8) Then
			die "After test execution, an error occurred while reading in the sahi result data file: " & _
				"Found more than 8 elements in one row; check " & resultfile & ".",3
		ElseIf ( UBound(arr_results,2) < 8) Then
			die "After test execution, an error occurred while reading in the sahi result data file: " & _
				"Found less than 8 elements in one row; check " & resultfile & ".",3
		End If 
		check_command = "[check_sahi_case]"
		
		' SUITE RESULT
		If ( Len(suite) > 0 ) Then
			' if there are errors, we dont care for the total runtime!
			If (worststate > 0) Then
				output = state2str(worststate) & ": Suite " & Chr(39) & suite & Chr(39) & _
					" (" & runtime & "s) ended " & state2oknok(worststate) & " " & output 
			Else
				durationresult = getduration_result(runtime, warning, critical)
				If (durationresult > 0) Then
					output = " beyond runtime (w: " & warning & ", c: " & critical & ") " & output 
				End If			
				output = state2str(durationresult) & ": Suite " & Chr(39) & UCase(suite) & Chr(39) & " (" & runtime & " s) " & output
			End If
			check_command = "[check_sahi_suite]"
			' if run in a suite, include total runtime in performance data
			perfdata = perfdata & suite & "=" & runtime & "s;" & warning & ";" & critical & ";; "
			
		End If
		perfdata = perfdata & check_command
		
		If printcfg Then
			printConfiguration hostname, service
		End If 
		' fixme: Alternative send2DB
		send2NSCA hostname, service, worststate, output, perfdata, nagios
	Else
		dbg "expandsuite option is set - will treat each sahi test as a separate service..."
		' each test is a separate Nagios service, service_description = sahitestfilename.sah
		For i=0 To UBound(arr_results,1)  	
			output = state2str(arr_results(i,2)) & ": Sahi test " & Chr(39) & arr_results(i,1) & Chr(39) & _
				" (" & arr_results(i,3) & "s) " & arr_results(i,6) 
			currentstate = arr_results(i,2)			
			perfdata = arr_results(i,1) & "=" & arr_results(i,3) & "s;" & arr_results(i,4) & ";" & arr_results(i,5) & ";; [check_sahi_case]"
			send2NSCA hostname, arr_results(i,1), currentstate, output, perfdata, nagios	
		Next 
	End If 
End Sub

Sub printConfiguration (inhostname, inservice)
	Dim objFSO, objFile
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set objFile = objFSO.CreateTextFile(sahi2omd_cfg, True)
	
	
End Sub

Sub send2NSCA (inhostname, inservice, instatus, inoutput, inperfdata, innagios)
	dbg "Sending NSCA data to OMD..."
	Dim command, objFile, nscadata, Wshell, delim
	Set objFile = FSObject.CreateTextFile(nscadatafile, True)
	' if we send an error message, we dont need perfdata
	If (inperfdata = "") Then
		delim = ""
	Else
		delim = "|"
	End If
	nscadata = inhostname & Chr(44) & inservice & Chr(44) & instatus & Chr(44) & inoutput & delim & inperfdata & Chr(13) & Chr(10)
	dbg "NSCAdata are: " & nscadata
	objFile.Write nscadata
	objFile.Close
	command = "cmd /c < " & nscadatafile & " " & send_nsca_bin & " -H " & innagios & " -p " & send_nsca_port & " -c " & send_nsca_cfg & " -d ,"
	dbg "Executing NSCA command '" & command & "'"
	Set Wshell = WScript.CreateObject("WScript.shell")
	Wshell.run command, 0, bWaitOnReturn
	Set Wshell = Nothing
	Set objFile = Nothing
End Sub 

Function dir_Exists_or_create(indir)
	Dim ret, dirnew
	dbg "Checking presence of screenshot folder '" & indir & "'..."
	If Not FSObject.FolderExists (indir) Then
		dbg "Folder does not exist. Creating..."
		dirnew = FSObject.CreateFolder(indir)
	Else
		dbg "Folder exists."
	End If
End Function

Sub file_Exists_OrDie(infile, InStr)
	If Not file_Exists(infile) Then
		die "UNKNOWN: " & InStr, 3
	End If
End Sub

Function file_Exists(infile)
	Dim ret
	If Not FSObject.FileExists(infile) Then
		file_Exists = False
	Else
		file_Exists = True
	End If
End Function

Sub file_Exists_OrDie(infile, InStr)
	If Not file_Exists(infile) Then
		die "UNKNOWN: " & InStr, 3
	End If
End Sub

Sub die(inmsg, instate)
	If (is_mode_nsca) Then
		send2NSCA hostname, service, instate, inmsg, "", nagios	
	End If
	WScript.echo inmsg
	WScript.quit
End Sub

Function nsca_params_ok
	Dim ret
	ret = ""

	If nagios = "" Then
		ret = "ERROR: Please specify the receiving monitoring server (-n). " 
	End If
	If hostname = "" Then
		ret = ret & "ERROR: Please specify a host (-h) on the monitoring system. "
	End If	
	If service = "" Then
		ret = ret & "ERROR: Please specify a servicedescription (-s) on the monitoring system. " 
	End If

	nsca_params_ok = ret
	
End Function

Function nsca_health
	' Check if NSCA is useable, but don't die, if not
	If file_Exists (send_nsca_bin) And file_Exists (send_nsca_cfg) And nsca_params_ok Then
		resultfile = sahi_results & "\\" & guid & ".results"	
		nscadatafile = sahi_results & "\\" & guid & ".nsca"
		nsca_health = True
	Else
		nsca_health = False
	End If	
End Function

Function nsca_health_or_die
	Dim parmmsg
	' Check if NSCA is useable, if not, die 
	If Not file_Exists (send_nsca_bin) Then 
		WScript.echo "NSCA binary " & send_nsca_bin & " could not be found!"
		WScript.quit
	End If

	If Not file_Exists (send_nsca_cfg) Then 
		WScript.Echo "NSCA config file " & send_nsca_cfg & " could not be found!"
		WScript.quit
	End If

	parmmsg = nsca_params_ok
	If Len(parmmsg) > 0 Then 
		WScript.Echo "For NSCA mode, you need to specify hostname, service, and the recieving OMD server. " & parmmsg
		WScript.Quit
	End If

	' ok, set NSCA variables
	resultfile = sahi_results & "\\" & guid & ".results"	
	nscadatafile = sahi_results & "\\" & guid & ".nsca"
	nsca_health_or_die = True
End Function

Function sahi_health 
	Dim strComputer, objWMIService, colProcesses, ret
	strComputer = "."
	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
	Set colProcesses = objWMIService.ExecQuery("Select * from Win32_Process Where Name = 'java.exe'")
	If colProcesses.Count = 0 Then
		ret = False
	Else
		ret = True
	End If
	Set objWMIService = Nothing
	Set colProcesses = Nothing
	sahi_health = ret
End Function

Function getduration_result (dur, w, c)
' compares total script runtime against thresholds
' if no thresholds are set (=0), OK is returned
	Dim ret
	ret = 0
	
	If ((w > 0) And (c > 0)) Then 
		If ( dur >= w ) Then
			If (dur < c) Then
				ret = 1    
			Else
				ret = 2
			End If
		End If
	End If
	getduration_result = ret
End Function
	
Function state2str (instate)
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
End Function	
	
Function state2oknok (instate)
	Dim ret
	If (instate > 0) Then
		ret = "with errors:"
	Else
		ret = "without errors:"
	End If
	state2oknok = ret
End Function	
	
Function ReadDataToArray (filename) 
 
 Dim objFSO, result, i, j, n, strLine, infile
  Set objFSO = CreateObject("Scripting.FileSystemObject")    
  result = Array ()  
  Set infile = objFSO.OpenTextFile(filename, 1, False)  
  ReDim result(0,1)  
  i = 0  
  n = 0

  Do Until infile.AtEndofStream    
        strLine = infile.Readline  
	
        ' check if not empty line, with correct information  
        If ((strLine <> "") And (InStr(strLine, """") <> 0)) Then  
	
          ' split line to know how many elemtns to process'  
		  strLine = Split (strLine, ";")  
		  ReDim result(n, UBound(strLine))    
		  n = n + 1
          i = i + 1                          
        End If                                
  Loop  

  Set infile = objFSO.OpenTextFile(filename, 1, False)  
  i = 0  
  Do Until infile.AtEndofStream    
    strLine = infile.Readline  
	' strLine = "login_logout.sah";"login_logout.sah";"0";"1";"15";"20";"";"Mozilla/5.0 (Windows NT 5.1, rv:10.0.2) Gecko/20100101 Firefox/10.0.2";"http://oxid/shop/"
    ' check if not empty line, with correct information  
    If ((strLine <> "") And (InStr(strLine, """") <> 0)) Then  
      strLine = Split (strLine, ";")          
      For j = 0 To UBound(strLine)  
			result(i,j) = Replace(strLine(j), Chr(34), "" )
			dbg result(i,j)
      Next                                                                                                                
      i = i + 1                          
    End If                                
  Loop  
  Set infile = Nothing
  Set objFSO = Nothing
  dbg "...done"
  ReadDataToArray = result   
End Function 


Sub about()
		WScript.echo "Startup script for sahi tests which sends results to a OMD monitoring server." & VbCrLf & _
					 "2012 by Simon Meggle, ConSol GmbH <simon.meggle@consol.de>" & VbCrLf & _
					 "Usage:" & VbCrLf & VbCrLf & _
		             "sahi2omd.vbs [-mode (nsca|db)] [-f <sahi file>] [-u <startURL>] [-b <browser>]" & VbCrLf & _
		             "            [-w <warning (sec)>] [-c <critical (sec)>]" & VbCrLf & _
		             "            [-n <monitoring server>] [-h <hostname>]" & VbCrLf & _
		             "            [-s <servicedescription>] [-z ] [-m <maxsessions> ] [-e] [-p]" & VbCrLf & _					 
		             "" & VbCrLf & _
		             "Parameters:" & VbCrLf & _
					 "-mode       nsca: send results via NSCA, db: save results in local database." & VbCrLf & _
		             "-f          Sahi test case (.sah) or test suite (.suite) file. " & VbCrLf & _
		             "            Relative to sahi_scripts (see config config section in this script)" & VbCrLf & _
		             "            e.g. '-f intranet\instranet_login.sah" & VbCrLf & _
		             "" & VbCrLf & _
		             "-u          URL the test/suite should start from." & VbCrLf & _
		             "            e.h. http://intranet.mydomain.local" & VbCrLf & _
		             "" & VbCrLf & _
		             "-b          Browser type. See Sahi Dashboard -> configure for allowed values." & VbCrLf & _
		             "" & VbCrLf & _ 
		             "-w          warning runtime threshold (seconds) for the whole check." & VbCrLf & _
		             "-c          critical runtime threshold (seconds) for the whole check." & VbCrLf & _
		             "" & VbCrLf & _
		             "-n          receiving monitoring server" & VbCrLf & _
		             "-h          hostname" & VbCrLf & _
		             "-s          servicedescription" & VbCrLf & _
					 "-p          create Nagios host and service objects in file sahi2omd.cfg" & VbCrLf & _
		             "" & VbCrLf & _
		             "-z          use singlesession (does not re-open the browser for each test case." & VbCrLf & _
					 "            (default: false)" & VbCrLf & _
		             "-m          maximum number of simultaneous threads (default: 1)" & VbCrLf & _
					 "-e          expand suite testcases into separate services " & VbCrLf & _
					 "            service_description= Sahi testcase filename (.sah) (default: false)" & VbCrLf & _
					 " " & VbCrLf & _					 
					 "-capture    create a screenshot if a case fails." & VbCrLf & _
		             "For any other settings see config section in this script. " & VbCrLf 
End Sub


Sub EchoOut2DArray (arr)  
  For i=0 To UBound(arr,1)  
    For j=0 To UBound(arr,2)       
      WScript.echo "[" & i & "," & j & "] = " & arr(i,j)  
    Next  
  Next     
End Sub 

Sub dbg(message)
    If debug = 1 Then
        WScript.echo Time & ": " & message
		objdebug.write Time & ": " & message & VbCrLf
    End If
End Sub

Function is_mode_nsca()
	If StrComp(mode, "nsca",1) Then
	  is_mode_nsca = False	
	Else 
	  is_mode_nsca = True
	End If
End Function
Function is_mode_db()
	If StrComp(mode, "db",1) Then
	  is_mode_db = False
	Else 
	  is_mode_db = True
	End If
End Function


Function get_guid()
 	Dim UpdateID, TypeLib
	Set TypeLib = CreateObject("Scriptlet.TypeLib")
	UpdateID = Trim(UCase(Mid(TypeLib.guid, 2, 36)))
	get_guid = UpdateID
End Function

Function store_guid(inguid,user,pwd,host,db,driver )
	Dim rec_count, myconn, connection, result, sql, i	
	i = 1
	On Error Resume Next
	Set myconn = CreateObject("adodb.connection")
	
	connection = "driver" & Chr(61) & "{" & mysql_odbcdriver & "};server" & Chr(61) & _
		host & ";uid" & Chr(61) & user & ";pwd" & Chr(61) & pwd & ";database" & Chr(61) & db
	Do Until i > 3
		myconn.open (connection)
		Set result = CreateObject("adodb.recordset")
		sql = "insert into sahi_jobs (guid) values ('" & inguid & "')"
		myconn.execute sql,rec_count
	
		If Err.number > 0 Or rec_count = 0 Then
	   		If i < 3  Then
				dbg "WARNING: Storing ID " & inguid & " failed " & i & " times. Retry..."
			Else
				dbg "FATAL ERROR: Storing ID " & inguid & " failed. Error message: " & Err.Description & ". Giving up!"
			End If 
			i = i + 1
		Else
			Exit Do
		End If
	Loop
End Function

