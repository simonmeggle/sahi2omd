_include('sprintf.inc');

function initialize($w, $c) {
   $warn = $w;
   $crit = $c;

   if (typeof($resultfile) == "undefined") { 
	$resultfile = "sahitask_manual.TMP";
	};
   //_alert($resultfile);
   
   $nagiosStartTime = Math.floor(new Date().getTime() /
       1000).toString();
   _set($startURL, window.document.location.href);
   // Validierung der Thresholds
   if ($warn > 0 && $crit > 0 && $warn >= $crit) {
      throw "warning threshold must be less than critical threshold!";
   }
}

function saveResult($msg) {
   var $duration_result;
   var $check_result;
   var $total_result;
   var $nagiosStopTime = Math.floor(new Date().getTime() / 1000).toString();
   var $duration = ($nagiosStopTime - $nagiosStartTime).toString(); 
// 1. determine check_result
   if (ScriptRunner.hasErrors() > 0) {
       var $errmesg, $errmesg1, $errmesg2 = "";
       $check_result = "2";      
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
   } else {
       $check_result = "0"; 
	   $msg = "" ;
   }
// 2. determine duration_result
	$duration_result = getduration_result($duration, $warn, $crit ); 
	if ($check_result == 0 && $duration_result > 0) {
	
		$msg += sprintf('ended OK but exceeded runtime thresholds (warn at %d s, crit at %d s)',$warn, $crit); 
	}
// 3. determine worstState
	
   $total_result = getworststate($check_result, $duration_result);
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

function getduration_result ($dur, $w, $c) {
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

function write2CSV() {
	var $args = Array.prototype.slice.call(arguments);
	//_alert($args);
	var $values = new Array();
	$values[0] = $args;
	//_alert($resultfile);
	_writeCSVFile($values, $resultfile, false, ";");
}