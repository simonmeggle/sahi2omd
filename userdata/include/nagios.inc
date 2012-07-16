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
	var $stepduration = ($now - $stepstart).toFixed(2);
	$stepcount++;
	//_alert("this is step " + $stepname + "; step duration was " + $stepduration + " seconds. Step number is " + $stepcount );
	$steps["step " + $stepcount + ": '" +$stepname+"'"] = {};
	$steps["step " + $stepcount + ": '" +$stepname+"'"]["duration"] = $stepduration;
	$steps["step " + $stepcount + ": '" +$stepname+"'"]["threshold"]  = $stepthreshold;
	
	$stepstart = $now; 
}

function saveResult($msg) {
   var $nsca_result = 0;
   var $db_result = 0;
   var $suitename;
   var $nagiosStopTime = Math.floor(new Date().getTime() / 1000).toString();
   var $duration = ($nagiosStopTime - $nagiosStartTime).toFixed(2); 
   
   if (is_mode_db) {
		var db = _getDB("com.mysql.jdbc.Driver", "jdbc://localhost/sahi", "sahi", "sahi");
   }
   
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
	   $nsca_result = 2;   
	   $db_result = 4;
       $msg = sprintf('ended with errors%s', $errmesg );
    } else {
		$msg = 'ended OK';
		// 2.1 Now case duration
		$nsca_result = getcase_duration_result($duration, $warn, $crit ); 
		if ($nsca_result > 0) {
			$msg += sprintf(', exceeded runtime (w: %d s, c: %d s)',$warn, $crit); 
			switch ($nsca_result) {
				case 1: $db_result = 3;
					break;
				case 2: $db_result = 2;
					break;
			}
		}
		// 2.2 todo step duration
		for (var $s in $steps) {
			var $step_result = getstep_result ($steps[$s]["duration"],$steps[$s]["threshold"]);			
			if ($step_result > 0) { 
				$msg += sprintf(', %s exceeded runtime (%0.2f s)', $s, $steps[$s]["duration"]);
			}
			$nsca_result = getworststate($nsca_result, $step_result);
			$db_result = getworststate($db_result, $step_result);
		}		
	}
	_alert ("Message is: " + $msg + ", nsca_result is" + $nsca_result + ", db_result = " + $db_result);
	_set($stopURL, window.document.location.href);
	_set($nagiosAgent, navigator.userAgent);
	// Agent description can contain semicolon, replace globally
	$nagiosAgent = $nagiosAgent.replace(/;/g,',');
	var $testname = _scriptName();
	
	if (_suiteInfo() ) {
		$suitename = _suiteInfo().suiteName;
	} else {
		$suitename = '';
	}
	//write2CSV($suitename, $testname, $total_result, $duration, $warn, $crit, $msg, $nagiosAgent, $stopURL);
	if (is_mode_db() ) {
		//write2DB($suitename, $testname, $total_result, $duration, $warn, $crit, $msg, $nagiosAgent, $stopURL);
	} else {
		//_alert ("will noe write to CSV!");
		write2CSV($suitename, $testname, $nsca_result, $duration, $warn, $crit, $msg, $nagiosAgent, $stopURL);
	}

}

function write2DB() {
	//TODO
}

function write2CSV() {
	var $args = Array.prototype.slice.call(arguments);
	//_alert($args);
	var $values = new Array();
	$values[0] = $args;
	//_alert($resultfile);
	_writeCSVFile($values, $resultfile, false, ";");
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
//_alert("dur=" + $dur + "threshold=" + $threshold );
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
		//_alert("This is mode nsca!");
		return false; 
	}
}

