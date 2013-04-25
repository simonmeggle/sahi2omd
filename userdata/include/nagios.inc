// Copyright (C) 2012  Simon Meggle, <simon.meggle@consol.de>

// this program Is free software; you can redistribute it And/Or
// modify it under the terms of the GNU General Public License
// As published by the Free Software Foundation; either version 2
// of the License, Or (at your Option) any later version.

// this program Is distributed In the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY Or FITNESS For A PARTICULAR PURPOSE.  See the
// GNU General Public License For more details.

// You should have received a copy of the GNU General Public License
// along With this program; If Not, write To the Free Software
// Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

_include('sprintf.inc');

function initialize($w, $c) {
	//onScriptError = onScriptFailure;
	$debug_indent = 0;
	$casename = _scriptName();
	$suitename = _suiteInfo().suiteName;
	browser = _suiteInfo().browserProcessName;
	screenshot_path = $sahi_userdata + '\\logs\\screenshots\\';
	screenshot_name = "";
	
	if ($casename == $suitename) {
		$suite = false; 
	} else {
		$suite = true;
	}
	
	$debugfile = "..\\temp\\" + $guid + "_" + $suitename + "_" + $casename + ".debug";
	debug("========= function '" + arguments.callee.name + "' ===================");
	debug("This is Sahi Case " + $casename + " (Suite " + $suitename + ")");
	$warn = $w;
	$crit = $c;

    if (is_mode_db()){ 
		$db = _getDB("com.mysql.jdbc.Driver", "jdbc:mysql://" + $mysql_host + "/sahi", $mysql_user, $mysql_password);
		if (typeof($db) == 'object') {
			debug("DB driver loaded.");
		} else {
			throw("ERROR: failed to load DB driver.");
		}			
	} else {
		$resultfile = "..\\..\\temp\\" + $guid + ".results";
		debug("Result file is " + $resultfile);
	}
 
   $nagiosStartTime = (new Date().getTime() / 1000).toString();
   debug("$nagiosStartTime = " + $nagiosStartTime);
   
   // Validierung der Thresholds
   if ($warn > 0 && $crit > 0 && $warn >= $crit) {
		debug ("ERROR: warning threshold must be less than critical threshold!");
		throw "warning threshold must be less than critical threshold!";
   }
   $steps = {};
   $stepstart = $nagiosStartTime;
   debug("$stepstart = " + $stepstart);
   $stepcount = 0;
   $output = "";
   debug("Now starting the sahi test case...");
   debug("...");
   debug("...");
}



function step($stepname,$stepthreshold) {
// call this function everytime a step should be _finished_ within a certain time. 
// It automatically resets the timer for possible further steps. 
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	//var $now = Math.floor(new Date().getTime() / 1000).toString();
	var $now = (new Date().getTime() / 1000).toString();
	var $stepduration = ($now - $stepstart).toFixed(2);
	var $stepres = ($stepduration > $stepthreshold ? 1 : 0);
	$stepcount++;
	$stepname = $stepname.replace(/ /g,'_');
	debug("Step #" + $stepcount + " (" + $stepname + "); duration = " + $stepduration + " seconds, threshold = " + $stepthreshold + ", stepres = " + $stepres );
	// $steps["s_" + $stepcount + "_" +$stepname] = {};
	// $steps["s_" + $stepcount + "_" +$stepname].duration = $stepduration;
	// $steps["s_" + $stepcount + "_" +$stepname].threshold  = $stepthreshold;
	// $steps["s_" + $stepcount + "_" +$stepname].stepres  = $stepres;
	$steps[$stepname] = {};
	$steps[$stepname].duration = $stepduration;
	$steps[$stepname].threshold  = $stepthreshold;
	$steps[$stepname].stepres  = $stepres;	
	$stepstart = $now; 
$debug_indent--;
}

function saveResult($msg) {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	debug("...");
	debug("...back again.");
	debug("got $msg = " + $msg);
   var $case_result = 0; // Result for NSCA = Nagios Std 0..2
   var $case_result_db = 0; // Result for DB = 0..4
   var $nagiosStopTime = (new Date().getTime() / 1000).toString();
   var $duration = ($nagiosStopTime - $nagiosStartTime).toFixed(2); 
   debug("$nagiosStopTime = " + $nagiosStopTime + ", total case duration is " + $duration + " seconds.");
   debug("Determing case status:");
   if (ScriptRunner.hasErrors() > 0) {
	   // 1. Fatal exceptions? 	   
       var $errmesg, $errmesg1, $errmesg2 = "";   
       if ($msg) {
			debug("Original msg: " + $msg);
          // Splitten der Meldung über "\n" in ein Array. Die ersten beiden Zeilen
          // der error-Message sollten ausreichend sein (eine manuelle Exception
          // enthält nur eine Zeile, das zweite Array-Element ist somit leer)
		  //$msg = $msg.replace(';',',');
		  //$msg = $msg.replace(',,',',');
		  //$msg = $msg.replace("'","\'");
		  //$msg = $msg.replace('"','\"');
		  //debug("Cleaned msg: " + $msg);
          var $msgparts = $msg.split('\n'); 
          $errmesg1 = $msgparts[0];
          $errmesg2 = $msg.split('\n')[1] || "";    
          //if ($errmesg1) { $errmesg1 = $errmesg1.replace("\n", "").replace("\"", "\'"); }
          if ($errmesg2) { $errmesg2 = ", " + $errmesg2; }
          
          $errmesg = " (" + $errmesg1 + $errmesg2 + "). ";
		  $errmesg = $errmesg.replace(/\n/g, "").replace(/"/g,'').replace(/'/g,"").replace(/;/g,"");
		  
       } else {
          $errmesg = "";
       }    
	   
	    if (screenshot_name) {
			$errmesg = $errmesg + " - A screenshot was captured (" + screenshot_name + ").";
		}
	   
		if (is_mode_db() ) {
			debug("Errormessage: " + $errmesg);
			$case_result_db = 4;
			$msg = $errmesg;
			debug("Case had exception -> case_result_db=" + $case_result_db + ", case_result=" + $case_result + ", msg = " + $msg);
		} else {
			debug("Errormessage: " + $errmesg);
			$case_result = 2;   
			$msg = sprintf('ended with errors%s', $errmesg );
			debug("Case had exception -> case_result=" + $case_result + ", msg = " + $msg);
		}
    } else {
		debug("Case had no exception, checking case and step runtimes...");
		$msg = 'Ok';
		// 2.1 case duration
		if (is_mode_db() ) {
			$case_result_db = getcase_duration_db_result($duration, $warn, $crit ); 
			if ($case_result_db > 0) {
				$msg += sprintf(', but case over runtime (%0.2f/%d/%d s)',$duration,$warn,$crit); 
				debug("Case over runtime -> case_result_db = " + $case_result_db );
			}			
		} else {
			$case_result = getcase_duration_result($duration, $warn, $crit ); 
			if ($case_result > 0) {
				$msg += sprintf(', but case over runtime (%0.2f/%d/%d s)',$duration,$warn,$crit); 
				debug("Case over runtime -> case_result = " + $case_result + ", msg = " + $msg);
			}
		}	
			
		// 2.2 step duration
		debug("checking step runtimes...");

		for (var $s in $steps) {
			debug(str_repeat(" ",4 + $debug_indent) + "--- Step " + $s + ":");
//			var $step_result = getstep_result ($steps[$s]["duration"],$steps[$s]["threshold"]);						
			if ($steps[$s]["stepres"] > 0) { 
				$msg += sprintf(', %s over runtime (%0.2f/%d s)', $s, $steps[$s]["duration"],$steps[$s]["threshold"]);
				debug(str_repeat(" ",4 + $debug_indent) + $s + " was over runtime");
			}
			if (is_mode_db() ) {
				$case_result_db = getworststate($case_result_db, $steps[$s]["stepres"]);
				debug(str_repeat(" ",4 + $debug_indent) + "new case_result_db = " + $case_result_db );
			} else {
				$case_result = getworststate($case_result, $steps[$s]["stepres"]);
				debug(str_repeat(" ",4 + $debug_indent) + "new case_result = " + $case_result + ", msg = " + $msg);
			}
		}	
		$msg += " ";		
	}
	_set($lastpage, window.document.location.href);
	_set($browser, navigator.userAgent);
	// Agent description can contain semicolon, replace globally
	$browser = $browser.replace(/;/g,',');

	debug("------------------");
	debug("Final result:");
	debug("  $suitename = " + $suitename);
	debug("  $casename = " + $casename);
	debug("  $case_result = " + $case_result);
	debug("  $case_result_db = " + $case_result_db);
	debug("  $duration = " + $duration);
	debug("  $warn = " + $warn);
	debug("  $crit = " + $crit);
	debug("  $msg = " + $msg);
	debug("  $browser = " + $browser);
	debug("  $lastpage = " + $lastpage);
	debug("------------------");
	
	if (is_mode_db() ) {
		write2DB($suitename, $casename, $case_result_db.toString(), $duration, $nagiosStartTime, $nagiosStopTime, $warn.toString(), $crit.toString(), $msg, $browser, $lastpage, $guid)
	} else {
		write2CSV($suitename, $casename, $case_result.toString(), $duration.replace('.',','), $warn.toString(), $crit.toString(), $msg, $browser, $lastpage);
	}
	debug("- Sahi Case " + $casename + "(ID " + $guid + ") ended -");
$debug_indent--;
}

function write2DB($suitename, $casename, $case_result_db, $duration, $nagiosStartTime, $nagiosStopTime,$warn, $crit, $msg, $browser, $lastpage, $guid) {
//		testcase1-4.suite, 1_OK_3stp_ok.sah, 0, 35, 45, 1,81, NaN, NaN, http://oxid/shop/, 1271BFEB-20FB-45D6-BC30-13D7C746BDC8, undefined, undefined
// ugly: $steps is not an argument
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	debug("got args: " + $suitename+", "+$casename+", "+$case_result_db+", "+$duration+", "+$nagiosStartTime+", "+$nagiosStopTime +", "+parseInt($warn)+", "+parseInt($crit)+", "+$msg+", "+$browser+", "+$lastpage+", "+$guid);
	var $stmt, $dbres, $suite_id;
	$suite_id = "NULL";
	// if suite: write only once
	if ($suite) {
		debug("Searching for a suite with this guid....");
		$stmt = "SELECT COUNT(*) AS count FROM sahi_suites where guid = '" + $guid + "'";
		debug("SQL: " + $stmt);
		$dbres = $db.select($stmt);
		debug("...found " + $dbres + " suite entries.");
		if ($dbres[0]['count'] == 0) {
			debug("Creating suite entry:");
			$stmt = sprintf("INSERT INTO sahi_suites (name, guid) VALUES ('%s','%s')",
				$suitename, $guid);
			debug("SQL: " + $stmt);
			$db.update($stmt);
		}
		// get Suite ID
		debug("Fetching suite id:");
		$stmt = "SELECT MAX(id) AS suite_id from sahi_suites";
		debug("SQL: " + $stmt)
		$dbres = $db.select($stmt);
		$suite_id = $dbres[0]['suite_id'];
		debug("Suite stored under ID " + $suite_id);
	}
	// write Case result
	debug("Storing Case result in DB...");
/* 	$stmt = sprintf("INSERT INTO sahi_cases (result, name, guid, start, stop, warning, critical, browser, lastpage, sahi_suites_id, duration,msg)" + 
		"VALUES ('%s', '%s','%s','%s','%s','%d','%d','%s','%s',"+$suite_id+",'%0.2f','%s')",
		$case_result_db, $casename, $guid, $nagiosStartTime, $nagiosStopTime,$warn,$crit,$browser,$lastpage, $duration, $msg); */
		
	$stmt = sprintf("INSERT INTO sahi_cases (result, name, guid, start, stop, warning, critical, browser, lastpage, sahi_suites_id, duration,msg)" + 
		"VALUES ('%s', '%s','%s','%s','%s','%d','%d','%s','%s',"+$suite_id+",'%0.2f','%s')",
		$case_result_db, $casename, $guid, $nagiosStartTime, $nagiosStopTime,$warn,$crit,$browser,$lastpage, $duration, $msg);
		
	debug("SQL: " + $stmt);
	$dbres = $db.update($stmt);
	// get Case ID
	$stmt = "SELECT MAX(id) AS case_id from sahi_cases";
	debug("SQL: " + $stmt);
	$dbres = $db.select($stmt);
	$case_id = $dbres[0]['case_id'];
	debug("Case stored under ID " + $case_id);
	
 	//store screenhot, if taken
	if (screenshot_name) {
		debug("Updating failed case " + $case_id + " with screenhot. ");
		$stmt = "UPDATE sahi_cases SET screenshot=LOAD_FILE('" + screenshot_path.replace(/\\/g,'/') + screenshot_name + "') WHERE id=" + $case_id ;
		debug($stmt);
		$db.update($stmt);			
	} 
	
	// write Step table
	debug("Storing step results in DB...");
	for (var $s in $steps) {
		debug(str_repeat(" ",4 + $debug_indent) + "--- Step " + $s + ":");
		$stmt = sprintf("INSERT INTO sahi_steps (result, name, warning, sahi_cases_id, duration)" + 
			"VALUES ('%d','%s','%s','%d','%0.2f')",
			parseInt($steps[$s]["stepres"]), $s,$steps[$s]["threshold"], parseInt($case_id), $steps[$s]["duration"]);
		debug("SQL: " + $stmt);
		$db.update($stmt);	
	}	
$debug_indent--;	
}

function write2CSV() {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	var $args = Array.prototype.slice.call(arguments);
	debug("got args: " + $args);
	var $values = new Array();
	$values[0] = $args;
	_writeCSVFile($values, $resultfile, false, ";");
$debug_indent--;	
}

function getworststate ($cres, $durres) {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	debug("got: $cres = " + $cres + ", $durres = " + $durres);
   var $max = Math.max($cres,$durres);
   debug("returning: " + $max);
	$debug_indent--; 
   return $max; 
}

function getcase_duration_result ($dur, $w, $c) {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
// compares script runtime against thresholds, returns common Nagios results
// if thresholds are 0,0, OK is returned
	debug("got: $dur = " + $dur + ", $w = " + $w + ", $c = " + $c);
   var $ret = "0";
   if ($warn > 0 && $crit > 0) {
      if ( $dur >= $w ) {
        if ($dur < $c) {
				$ret = "1";    
        } else {
				$ret = "2";    
        }
      }
   } else {
		debug("(No thresholds set; returning OK. )");
	}
	debug("Returning: " + $ret);
   $debug_indent--;   
   return $ret;
}

function getcase_duration_db_result ($dur, $w, $c) {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
// compares script runtime against thresholds, returns DB case results
// if thresholds are 0,0, OK is returned
	debug("got: $dur = " + $dur + ", $w = " + $w + ", $c = " + $c);
   var $ret = "0";
   if ($warn > 0 && $crit > 0) {
      if ( $dur >= $w ) {
        if ($dur < $c) {
				$ret = "2";    
        } else {
				$ret = "3";    
        }
      }
   } else {
		debug("(No thresholds set; returning OK. )");
	}
	debug("Returning: " + $ret);
   $debug_indent--;   
   return $ret;
}
function getstep_result ($dur, $threshold) {
$debug_indent += 1;
debug("========= function '" + arguments.callee.name + "' ===================");
// compares step runtime against one threshold
//_alert("dur=" + $dur + "threshold=" + $threshold );
	debug("got: $dur = " + $dur + ", $threshold = " + $threshold);
	var $ret = "0";
	if ( $dur >= $threshold ) {    
		$ret = "1";    
    } 
	debug("returning: " + $ret);
	$debug_indent -= 1; 
	return $ret;
}

function is_mode_db () {
$debug_indent++;

debug("========= function '" + arguments.callee.name + "' ===================");
	var $ret;
	if ($mode == "db") { 
		debug("This is mode DB"); 
		$ret = true; 
	} else { 
		debug("This is mode NSCA"); 
		$ret = false; 
	}
	$debug_indent--;
	return $ret;
}

function debugfunc() {
	debug(" " + arguments.callee.name + " ===================");
}

function debug($message) {
	if ($debug) {
		var $space = str_repeat(" ", $debug_indent * 4);
		_debugToFile($space + $message, $debugfile);
	}
}

function str_repeat (input, multiplier) {
    return new Array(multiplier + 1).join(input);
}

function TakeScreenshot() {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");

	if($capture) {
		if(browser.match(/(firefox|chrome|safari|iexplore)/)) {
			screenshot_name = Packages.net.sf.sahi.util.Utils.createLogFileName($casename) + '.jpg';
			var $fullname = screenshot_path + screenshot_name;	
			
			//_call(window.document.title = window.document.title.replace(/|/,''));
			_set($browsertitle,window.document.title );
			debug("Bringing browser window '" + $browsertitle + "' to foreground with: '" + $sahi_userdata + '\\bin\\modwindow.vbs \''+ $browsertitle +'\' maximize');
			_execute('cscript.exe ' + $sahi_userdata + '\\bin\\modwindow.vbs \''+ $browsertitle +'\' maximize', true);
			debug("Will make a screenshot with :" + '\"' + $irfanview_bin + '" /jpgq=10 /capture=2 ' + '/convert=' + $fullname);
			_execute('\"' + $irfanview_bin + '" /jpgq=10 /capture=2 ' + '/convert=' + $fullname, true);
		} else {
			// phantomJS render FIXME
		}
	} else {
		debug("Capture option is not set. Will not take any screenshot.");
	}
$debug_indent--;
}

function makeid(len) {
    var ret = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
    for( var i=0; i < len; i++ )
        ret += possible.charAt(Math.floor(Math.random() * possible.length));
    return ret;
}

function makenumber(len) {
    var ret = "";
    var possible = "123456789";
    for( var i=0; i < len; i++ )
        ret += possible.charAt(Math.floor(Math.random() * possible.length));
    return ret;
}

function onScriptFailure($exc){
//	_alert("onScriptFailure");
//	if ($exception_on_assert) {
//	_alert("... handle exception.");
		handle_exception($exc);
//	} 
} 
	 
function handle_exception($exc){
 	TakeScreenshot();
    _logExceptionAsFailure($exc); 
    $output = $exc['message'];
	
  if (! $output) { $output = $exc; }
  if (! $output) { $output = " "; }
} 
