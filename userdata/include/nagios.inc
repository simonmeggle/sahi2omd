_include('sprintf.inc');

function initialize($w, $c) {
$debug_indent = 0;
debug("========= function '" + arguments.callee.name + "' ===================");
	$casename = _scriptName();
	if (_suiteInfo() ) {
		$suitename = _suiteInfo().suiteName;
	} else {
		$suitename = $casename;
	}
	debug("This is Sahi Case " + $casename + " (Suite " + $suitename + ")");
   $warn = $w;
   $crit = $c;

   if (typeof($resultfile) == "undefined") { 
		debug("Called in DB mode.");
		$mode = "db";
	} else {
		debug("Called in NSCA mode; result file is " + $resultfile);
		$mode = "nsca";
	};
   
   $nagiosStartTime = (new Date().getTime() / 1000).toString();
   debug("$nagiosStartTime = " + $nagiosStartTime);
   _set($startURL, window.document.location.href);
   
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
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	//var $now = Math.floor(new Date().getTime() / 1000).toString();
	var $now = (new Date().getTime() / 1000).toString();
	var $stepduration = ($now - $stepstart).toFixed(2);
	$stepcount++;
	debug("Step #" + $stepcount + " (" + $stepname + "); duration " + $stepduration + " seconds" );
	$steps["step " + $stepcount + ": '" +$stepname+"'"] = {};
	$steps["step " + $stepcount + ": '" +$stepname+"'"]["duration"] = $stepduration;
	$steps["step " + $stepcount + ": '" +$stepname+"'"]["threshold"]  = $stepthreshold;
	
	$stepstart = $now; 
$debug_indent--;
}

function saveResult($msg) {
$debug_indent++;
debug("========= function '" + arguments.callee.name + "' ===================");
	debug("...");
	debug("...back again.");
	debug("got $msg = " + $msg);
   var $case_result = 0;
   var $db_result = 0;
   var $nagiosStopTime = Math.floor(new Date().getTime() / 1000).toString();
   var $duration = ($nagiosStopTime - $nagiosStartTime).toFixed(2); 
   debug("$nagiosStopTime = " + $nagiosStopTime + ", total case duration is " + $duration + " seconds.");
   if ( is_mode_db() ) {
		var db = _getDB("com.mysql.jdbc.Driver", "jdbc://localhost/sahi", "sahi", "sahi");
		if (typeof($db) !== 'undefined') {
			debug("DB driver loaded.")
		} else {
			throw("ERROR: failed to load DB driver.")
		}
   }
   debug("Determing case status:");
   if (ScriptRunner.hasErrors() > 0) {
	   // 1. Fatal exceptions? 
	   
       var $errmesg, $errmesg1, $errmesg2 = "";   
       if ($msg) {
          // Splitten der Meldung über "\n" in ein Array. Die ersten beiden Zeilen
          // der error-Message sollten ausreichend sein (eine manuelle Exception
          // enthält nur eine Zeile, das zweite Array-Element ist somit leer)
		  $msg = $msg.replace(';',',');
		  $msg = $msg.replace(',,',',');
		  $msg = $msg.replace("'","");
          var $msgparts = $msg.split('\n'); 
          $errmesg1 = $msgparts[0];
          $errmesg2 = $msg.split('\n')[1] || "";    
          if ($errmesg1) { $errmesg1 = $errmesg1.replace("\n", "").replace("\"", "'"); }
          if ($errmesg2) { $errmesg2 = ", " + $errmesg2.replace("\n", "").replace("\"", "'");   }
          
          $errmesg = " (" + $errmesg1 + $errmesg2 + ")";
       } else {
          $errmesg = "";
       }    
	   $case_result = 2;   
       $msg = sprintf('ended with errors%s', $errmesg );
	   debug("Case had exception -> case_result = " + $case_result + ", msg = " + $msg);
    } else {
		debug("Case had no exception, checking case and step runtimes...");
		$msg = 'ended OK';
		// 2.1 Now case duration
		$case_result = getcase_duration_result($duration, $warn, $crit ); 
		if ($case_result > 0) {
			$msg += sprintf(', exceeded runtime (w: %d s, c: %d s)',$warn, $crit); 
			debug("Case over runtime -> case_result = " + $case_result + ", msg = " + $msg);
		}
		// 2.2 todo step duration
		debug("checking step runtimes...");
		for (var $s in $steps) {
			debug(str_repeat(" ",4 + $debug_indent) + "--- Step " + $s + ":");
			var $step_result = getstep_result ($steps[$s]["duration"],$steps[$s]["threshold"]);			
			if ($step_result > 0) { 
				$msg += sprintf(', %s exceeded runtime (%0.2f s)', $s, $steps[$s]["duration"]);
				debug(str_repeat(" ",4 + $debug_indent) + $s + "was over runtime");
			}
			$case_result = getworststate($case_result, $step_result);
			debug(str_repeat(" ",4 + $debug_indent) + "new case_result = " + $case_result + ", msg = " + $msg);
		}		
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
	debug("  $duration = " + $duration);
	debug("  $warn = " + $warn);
	debug("  $crit = " + $crit);
	debug("  $msg = " + $msg);
	debug("  $browser = " + $browser);
	debug("  $lastpage = " + $lastpage);
	debug("------------------");
	
	if (is_mode_db() ) {
		//
	} else {
		write2CSV($suitename, $casename, $case_result.toString(), $duration, $warn.toString(), $crit.toString(), $msg, $browser, $lastpage);
	}
$debug_indent--;
}

function write2DB() {
$debug_indent++;
	//TODO
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
// compares script runtime against thresholds
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
	var $space = str_repeat(" ", $debug_indent * 4);
	_debugToFile($space + $message, $resultfile + '.debug');
}

function str_repeat (input, multiplier) {
    return new Array(multiplier + 1).join(input);
}