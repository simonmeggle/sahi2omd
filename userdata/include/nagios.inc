_include('sprintf.inc');

function initialize($w, $c) {
   $warn = $w;
   $crit = $c;

   if (typeof($resultfile) == "undefined") { 
		$mode = "db";
	} else {
		$mode = "nsca";
	};
	
   //_alert($mode);
   //_alert($resultfile);
   
   //$nagiosStartTime = Math.floor(new Date().getTime() / 1000).toString();
   $nagiosStartTime = (new Date().getTime() / 1000).toString();
   //_alert($nagiosStartTime);
   _set($startURL, window.document.location.href);
   // Validierung der Thresholds
   if ($warn > 0 && $crit > 0 && $warn >= $crit) {
      throw "warning threshold must be less than critical threshold!";
   }
   $steps = {};
   $stepstart = $nagiosStartTime;
   $stepcount = 0;
   $output = "";
}

function step($stepname,$stepthreshold) {
	//var $now = Math.floor(new Date().getTime() / 1000).toString();
	var $now = (new Date().getTime() / 1000).toString();
	var $step_duration = ($now - $stepstart).toFixed(2);
	$stepcount++;
	//_alert("this is step " + $stepname + "; step duration was " + $step_duration + " seconds. Step number is " + $stepcount );
	$steps["step " + $stepcount + ": " +$stepname] = {};
	$steps["step " + $stepcount + ": " +$stepname]["duration"] = $step_duration;
	$steps["step " + $stepcount + ": " +$stepname]["result"]  = getstep_result ($step_duration, $stepthreshold);
	
	$stepstart = $now; 
}

function saveResult($msg) {
   var $case_duration_result;
   var step_duration_result; 
   var $case_result;
   var $total_result;
   var $nagiosStopTime = Math.floor(new Date().getTime() / 1000).toString();
   //var $duration = ($nagiosStopTime - $nagiosStartTime).toString(); 
   var $duration = ($nagiosStopTime - $nagiosStartTime).toFixed(2); 
   
   if (is_mode_db) {
		var db = _getDB("com.mysql.jdbc.Driver", "jdbc://localhost/sahi", "sahi", "sahi");
   }
// 1. Did we have exceptions? 
   if (ScriptRunner.hasErrors() > 0) {
       var $errmesg, $errmesg1, $errmesg2 = "";
       $case_result = "2";      
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
       $msg = sprintf('ended with errors%s', $errmesg );
// no script exceptions. 

   } else {
// 2.1 Now check script duration
		$case_duration_result = getcase_duration_result($duration, $warn, $crit ); 
		if ($case_duration_result > 0) {
			$msg += sprintf('ended OK but exceeded runtime thresholds (warn at %d s, crit at %d s)',$warn, $crit); 
		} else {
			$case_result = "0"; 
			$msg = "" ;
		}
	}

// 2.2 todo step duration
// 3. determine worstState
	
   $total_result = getworststate($case_result, $case_duration_result);
   _set($stopURL, window.document.location.href);
   _set($nagiosAgent, navigator.userAgent);
   // Agent description can contain semicolon, replace globally
   $nagiosAgent = $nagiosAgent.replace(/;/g,',');
   var $testname = _scriptName();
   var $suitename = "" ; 
   if (_suiteInfo() ) {
	 $suitename = _suiteInfo().suiteName;
	}
	write2CSV($suitename, $testname, $total_result, $duration, $warn, $crit, $msg, $nagiosAgent, $stopURL);
	if (is_mode_db() ) {
		//write2DB($suitename, $testname, $total_result, $duration, $warn, $crit, $msg, $nagiosAgent, $stopURL);
	} else {
		write2CSV($suitename, $testname, $total_result, $duration, $warn, $crit, $msg, $nagiosAgent, $stopURL);
	}
   	// for (var $s in $steps) {
		// for (var $i in $steps[$s]) {
			// _alert ($s + ": " + $i + "= " + $steps[$s][$i]);
		// }
	// }
}

function getworststate ($cres, $durres) {
   var $max = Math.max($cres,$durres);
   var $ret; 
   switch ($max) {
      case 0: $ret = "0";
                break;
      case 1: $ret = "1";
                break;
      case 2: $ret = "2";
                break;                            
   }
   return $ret; 
}

function getcase_duration_result ($dur, $w, $c) {
// compares script runtime against thresholds
// if thresholds are 0,0, OK is returned
//_alert("dur=" + $dur + "warn=" + $w + "crit=" + $c );
   var $ret = "0";
   if ($warn > 0 && $crit > 0) {
      if ( $dur >= $w ) {
        if ($dur < $c) {
           $ret = "1";    
        } else {
           $ret = "2";
        }
      }
   }	  
   return $ret;
}

function getstep_result ($dur, $threshold) {
// compares step runtime against one threshold
//_alert("dur=" + $dur + "warn=" + $w + "crit=" + $c );
	var $ret = "0";
	if ( $dur >= $threshold ) {    
		$ret = "1";    
    } 
   return $ret;
}

function is_mode_db () {
	if ($mode == "db") { 
		//_alert("This is mode DB"); 
		return true; 
	} else { 
		_alert("This is mode nsca!");
		//return false; 
	}
}

function write2CSV() {
	var $args = Array.prototype.slice.call(arguments);
	//_alert($args);
	var $values = new Array();
	$values[0] = $args;
	//_alert($resultfile);
	_writeCSVFile($values, $resultfile, false, ";");
}