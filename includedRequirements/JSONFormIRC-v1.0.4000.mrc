#SReject/JSONForMirc/CompatMode off
alias JSONUrlMethod {
  if ($isid) return
  JSONHttpMethod $1-
}
alias JSONUrlHeader {
  if ($isid) return
  JSONHttpHeader $1-
}
alias JSONUrlGet {
  if ($isid) return
  JSONHttpFetch $1-
}
#SReject/JSONForMirc/CompatMode end
on *:LOAD:{
  JSONShutdown
  if ($~adiircexe) {
    if ($version < 2.8) {
      echo -ag [JSON For mIRC] AdiIRC v2.7 beta 01/28/2016 or later is required
      .unload -rs $qt($script)
    }
  }
  elseif ($version < 7.48) {
    echo -ag [JSON For mIRC] mIRC v7.48 or later is required
    .disable #SReject/JSONForMirc/CompatMode
    .unload -rs $qt($script)
  }
}
on *:START:JSONShutDown
on *:CLOSE:@SReject/JSONForMirc/Log:if $jsondebug { jsondebug off }
on *:EXIT:JSONShutDown
on *:UNLOAD:{
  .disable #SReject/JSONForMirc/CompatMode
  JSONShutDown
}
menu @SReject/JSONForMirc/Log {
  .$iif(!$jfm_SaveDebug,$style(2)) Clear: clear -@ $active
  .-
  .$iif(!$jfm_SaveDebug,$style(2)) Save: jfm_SaveDebug
  .-
  .Toggle Debug:jsondebug
  .-
  .Close:jsondebug off | close -@ $active
}
alias JSONOpen {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Switches,%Error,%Com $false,%Type text,%HttpOptions 0,%BVar,%BUnset $true
  jfm_log -I /JSONOpen $1-
  if (-* iswm $1) {
    %Switches = $mid($1,2-)
    tokenize 32 $2-
  }
  if ($jfm_ComInit) %Error = $v1
  elseif (!$regex(SReject/JSONOpen/switches,%Switches,^[dbfuUw]*$)) %Error = SWITCH_INVALID 
  elseif ($regex(%Switches,([dbfuUw]).*?\1)) %Error = SWITCH_DUPLICATE: $+ $regml(1)
  elseif ($regex(%Switches,/([bfuU])/g) > 1) %Error = SWITCH_CONFLICT: $+ $regml(1)
  elseif (u !isin %Switches) && (w isincs %Switches) { %Error = SWITCH_NOT_APPLICABLE:w }
  elseif ($0 < 2) %Error = PARAMETER_MISSING
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = NAME_INVALID
  elseif ($com(JSON: $+ $1)) %Error = NAME_INUSE
  elseif (u isin %Switches) && ($0 != 2) { %Error = PARAMETER_INVALID:URL_SPACES }
  elseif (b isincs %Switches) && ($0 != 2) { %Error = PARAMETER_INVALID:BVAR }
  elseif (b isincs %Switches) && (&* !iswm $2) { %Error = PARAMETER_INVALID:NOT_BVAR }
  elseif (b isincs %Switches) && (!$bvar($2,0)) { %Error = PARAMETER_INVALID:BVAR_EMPTY }
  elseif (f isincs %Switches) && (!$isfile($2-)) { %Error = PARAMETER_INVALID:FILE_DOESNOT_EXIST }
  else {
    %Com = JSON: $+ $1
    %BVar = $jfm_TmpBVar
    if (b isincs %Switches) {
      %Bvar = $2
      %BUnset = $false
    }
    elseif (u isin %Switches) {
      if (w isincs %Switches) inc %HttpOptions 1
      if (U isincs %Switches) inc %HttpOptions 2
      %Type = http
      bset -t %BVar 1 $2
    }
    elseif (f isincs %Switches) bread $qt($file($2-).longfn) 0 $file($file($2-).longfn).size %BVar
    else bset -t %BVar 1 $2-
    jfm_ToggleTimers -p
    %Error = $jfm_Create(%Com,%Type,%BVar,%HttpOptions)
    jfm_ToggleTimers -r
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%BUnset) bunset %BVar
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    if (%Com) && ($com(%Com)) { .timer $+ %Com -iom 1 0 JSONClose $unsafe($1) }
    jfm_log -EeDF %Error
  }
  else {
    if (d isincs %Switches) .timer $+ %Com -iom 1 0 JSONClose $unsafe($1)
    jfm_log -EsDF Created $1 (as com %Com $+ )
  }
}
alias JSONHttpMethod {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Com,%Method
  jfm_log -I /JSONHttpMethod $1-
  if ($jfm_ComInit) %Error = $v1
  elseif ($0 < 2) %Error = PARAMETER_MISSING
  elseif ($0 > 2) %Error = PARAMETER_INVALID
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = NAME_INVALID
  elseif (!$com(JSON: $+ $1)) %Error = HANDLE_DOES_NOT_EXIST
  else {
    %Com = JSON: $+ $1
    %Method = $regsubex($2,/(^\s+)|(\s*)$/g,)
    if (!$len(%Method)) %Error = INVALID_METHOD
    elseif ($jfm_Exec(%Com,httpSetMethod,%Method)) %Error = $v1
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeDF %Error
  }
  else jfm_log -EsDF Set Method to $+(',%Method,')
}
alias JSONHttpHeader {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Com,%Header
  jfm_log -I /JSONHttpHeader $1-
  if ($jfm_ComInit) %Error = $v1
  elseif ($0 < 3) %Error = PARAMETER_MISSING
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = INVALID_NAME
  elseif (!$com(JSON: $+ $1)) %Error = HANDLE_DOES_NOT_EXIST
  else {
    %Com = JSON: $+ $1
    %Header = $regsubex($2,/(^\s+)|(\s*:\s*$)/g,)
    if (!$len($2)) %Error = HEADER_EMPTY
    elseif ($regex($2,[\r:\n])) %Error = HEADER_INVALID
    elseif ($jfm_Exec(%Com,httpSetHeader,%Header,$3-)) %Error = $v1
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeDF %Error
  }
  else jfm_log -EsDF Stored Header $+(',%Header,: $3-,')
}
alias JSONHttpFetch {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Switches,%Error,%Com,%BVar,%BUnset
  jfm_log -I /JSONHttpFetch $1-
  if (-* iswm $1) {
    %Switches = $mid($1,2-)
    tokenize 32 $2-
  }
  if ($jfm_ComInit) %Error = $v1
  if ($0 == 0) || (%Switches != $null && $0 < 2) { %Error = PARAMETER_MISSING }
  elseif ($regex(%Switches,([^bf]))) %Error = SWITCH_INVALID: $+ $regml(1)
  elseif ($regex($1,/(?:^\d+$)|[*:? ]/i)) %Error = NAME_INVALID
  elseif (!$com(JSON: $+ $1)) %Error = HANDLE_DOES_NOT_EXIST
  elseif (b isincs %Switches) && (&* !iswm $2 || $0 > 2) { %Error = BVAR_INVALID }
  elseif (f isincs %Switches) && (!$isfile($2-)) { %Error = FILE_DOESNOT_EXIST }
  else {
    %Com = JSON: $+ $1
    if ($0 > 1) {
      %BVar = $jfm_tmpbvar
      %BUnset = $true
      if (b isincs %Switches) {
        %BVar = $2
        %BUnset = $false
      }
      elseif (f isincs %Switches) bread $qt($file($2-).longfn) 0 $file($2-).size %BVar
      else bset -t %BVar 1 $2-
      %Error = $jfm_Exec(%Com, httpSetData,& %BVar).fromBvar
    }
    if (!%Error) %Error = $jfm_Exec(%Com,parse)
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%BUnset) bunset %BVar
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeDF %Error
  }
  else jfm_log -EsDF Http Data retrieved
}
alias JSONClose {
  if ($isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Switches,%Error,%Match,%Com,%X 1
  jfm_log -I /JSONClose $1-
  if (-* iswm $1) {
    %Switches = $mid($1, 2-)
    tokenize 32 $2-
  }
  if ($0 < 1) %Error = PARAMTER_MISSING
  elseif ($0 > 1) %Error = PARAMETER_INVALID
  elseif ($regex(%Switches,/([^w])/)) %Error = SWITCH_UNKNOWN: $+ $regml(1) 
  elseif (: isin $1) && (w isincs %Switches || JSON:* !iswmcs $1) { %Error = PARAMETER_INVALID }
  else {
    %Match = $1
    if (JSON:* iswmcs $1) %Match = $gettok($1,2-,58)
    %Match = $replacecs(%Match,\E,\E\\E\Q)
    if (w isincs %Switches) %Match = $replacecs(%Match,?,\E[^:]\Q,*,\E[^:]*\Q)
    %Match = /^JSON:\Q $+ %Match $+ \E(?::\d+)?$/i
    %Match = $replacecs(%Match,\Q\E,)
    while (%X <= $com(0)) {
      %Com = $com(%X)
      if ($regex(%Com,%Match)) {
        .comclose %Com
        if ($timer(%Com)) .timer $+ %Com off
        jfm_log Closed %Com
      }
      else inc %X
    }
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeD /JSONClose %Error
  }
  else jfm_log -EsD All matching handles closed
}
alias JSONList {
  if ($isid) return
  var %X 1,%I 0
  jfm_log /JSONList $1-
  while ($com(%X)) {
    if (JSON:?* iswm $v1) {
      inc %I
      echo $color(info) -age * $chr(35) $+ %I $+ : $v2
    }
    inc %X
  }
  if (!%I) echo $color(info) -age * No active JSON handlers
}
alias JSONShutDown {
  if ($isid) return
  JSONClose -w *
  if ($JSONDebug) JSONDebug off
  if ($window(@SReject/JSONForMirc/Log)) close -@ $v1
  if ($com(SReject/JSONForMirc/JSONEngine)) .comclose $v1
  if ($com(SReject/JSONForMirc/JSONShell)) .comclose $v1
  if ($hget(SReject/JSONForMirc)) hfree $v1
}
alias JSONCompat {
  if ($isid) return $iif($group(#SReject/JSONForMirc/CompatMode) == on, $true, $false)
  .enable #SReject/JSONForMirc/CompatMode
}
alias JSON {
  if (!$isid) return
  if ($hget(SReject/JSONForMirc, Error)) hdel SReject/JSONForMirc Error
  var %X,%Args,%Params,%Error,%Com,%I 0,%Prefix,%Prop,%Suffix,%Offset 2,%Type,%Output,%Result,%ChildCom,%Call
  if (*ToFile iswm $prop) %Offset = 3
  if ($JSONDebug) {
    %X = 1
    while (%X <= $0) {
      if (%Args !== $null) %Args = %Args $+ $chr(44)
      %Args = %Args $+ $($ $+ %X, 2)
      if (%X >= %Offset) %Params = %Params $+ ,bstr,$ $+ %X
      inc %X
    }
  }
  elseif ($0 >= %Offset) {
    %X = %Offset
    while (%x <= $0) {
      %Params = %Params $+ ,bstr,$ $+ %X
      inc %x
    }
  }
  jfm_log -I $!JSON( $+ %Args $+ ) $+ $iif($prop !== $null, . $+ $prop)
  if (!$0) || ($0 == 1 && $1 == $null) {
    %Error = PARAMETER_MISSING
    goto error
  }
  if ($0 == 1) && ($1 == 0) && ($prop !== $null) {
    %Error = PROP_NOT_APPLICABLE
    goto error
  }
  if ($regex(name,$1,/^JSON:[^:?*]+(?::\d+)?$/i)) %Com = $1
  elseif (: isin $1 || * isin $1 || ? isin $1) || ($1 == 0 && $0 !== 1) { %Error = INVALID_NAME }
  elseif ($1 isnum 0- && . !isin $1) {
    %X = 1
    while ($com(%X)) {
      if ($regex($v1,/^JSON:[^:]+$/)) {
        inc %I
        if (%I === $1) {
          %Com = $com(%X)
          break
        }
      }
      inc %X
    }
    if ($1 === 0) {
      jfm_log -EsDF %I
      return %I
    }
  }
  else %Com = JSON: $+ $1
  if (!%Error) && (!$com(%Com)) { %Error = HANDLER_NOT_FOUND }
  elseif (* isin $prop) || (? isin $prop) { %Error = INVALID_PROP }
  else {
    if ($regex($prop, /^((?:fuzzy)?)(.*?)((?:to(?:bvar|file))?)?$/i)) {
      %Prefix = $regml(1)
      %Prop = $regml(2)
      %Suffix = $regml(3)
    }
    %Prop = $regsubex(%Prop, /^url/i, http)
    if ($JSONCompat) {
      if (%Prop == status) %Prop = state
      if (%Prop == data) %Prop = input
      if (%Prop == isRef) %Prop = isChild
      if (%Prop == isParent) %Prop = isContainer
    }
    if (%Suffix == tofile) {
      if ($0 < 2) %Error = INVALID_PARAMETERS
      elseif (!$len($2) || $isfile($2) || (!$regex($2, /[\\\/]/) && " isin $2)) { %Error = INVALID_FILE }
      else %Output = $longfn($2)
    }
  }
  if (%Error) goto error
  elseif ($0 == 1) && (!$prop) {
    %Result = $jfm_TmpBvar
    bset -t %Result 1 %Com
  }
  elseif (%Prop == isChild) {
    %Result = $jfm_TmpBvar
    if (JSON:?*:?* iswm %com) bset -t %Result 1 $true
    else bset -t %Result 1 $false
  }
  elseif ($wildtok(state|error|input|inputType|httpParse|httpHead|httpStatus|httpStatusText|httpHeaders|httpBody|httpResponse,%Prop,1,124)) {
    if ($jfm_Exec(%Com,$v1)) %Error = $v1
    else %Result = $hget(SReject/JSONForMirc,Exec)
  }
  elseif (%Prop == httpHeader) {
    if ($calc($0 - %Offset) < 0) %Error = INVALID_PARAMETERS
    elseif ($jfm_Exec(%Com,httpHeader,$($ $+ %Offset,2))) %Error = $v1
    else %Result = $hget(SReject/JSONForMirc,Exec)
  }
  elseif (%Prop == $null) || ($wildtok(path|pathLength|type|isContainer|length|value|string|debug, %Prop, 1, 124)) {
    %Prop = $v1
    if ($0 >= %Offset) {
      %ChildCom = JSON: $+ $gettok(%Com,2,58) $+ :
      %X = $ticks $+ 000000
      while ($com(%ChildCom $+ %X)) inc %X
      %ChildCom = %ChildCom $+ %X
      %Call = $!com( $+ %Com $+ ,walk,1,bool, $+ $iif(fuzzy == %Prefix,$true,$false) $+ %Params $+ ,dispatch* %ChildCom $+ )
      jfm_log %Call
      if (!$eval(%Call, 2)) || ($comerr) || (!$com(%ChildCom)) {
        %Error = $jfm_GetError
        goto error
      }
      .timer $+ %ChildCom -iom 1 0 JSONClose %ChildCom
      %Com = %ChildCom
      jfm_log
    }
    if ($JSONCompat) && ($prop == $null) {
      if ($jfm_exec(%Com,type)) %Error = $v1
      elseif ($bvar($hget(SReject/JSONForMirc,Exec), 1-).text == object) || ($v1 == array) {
        %Result = $jfm_TmpBvar
        bset -t %Result 1 %Com
      }
      elseif ($jfm_Exec(%Com, value)) %Error = $v1
      else %Result = $hget(SReject/JSONForMirc,Exec)
    }
    elseif (!%Prop) {
      %Result = $jfm_TmpBvar
      bset -t %Result 1 %Com
    }
    elseif (%Prop !== value) {
      if ($jfm_Exec(%Com,$v1)) %Error = $v1
      else %Result = $hget(SReject/JSONForMirc,Exec)
    }
    elseif ($jfm_Exec(%Com,type)) %Error = $v1
    elseif ($bvar($hget(SReject/JSONForMirc,Exec),1-).text == object) || ($v1 == array) { %Error = INVALID_TYPE }
    elseif ($jfm_Exec(%Com,value)) %Error = $v1
    else %Result = $hget(SReject/JSONForMirc,Exec)
  }
  else %Error = UNKNOWN_PROP
  if (!%Error) {
    if (%Suffix == tofile) {
      bwrite $qt(%Output) -1 -1 %Result
      bunset %Result
      %Result = %Output
    }
    elseif (%Suffix !== tobvar) %Result = $bvar(%Result,1,4000).text
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeDF %Error
  }
  else {
    jfm_log -EsDF %Result
    return %Result
  }
}
alias JSONForEach {
  if (!$isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Log,%Call,%X 0,%JSON,%Com,%ChildCom,%Result 0,%Name
  %Log = $!JSONForEach(
  if ($prop == walk) %Call = ,forEach,1,bool,$true,bool,$false
  elseif ($prop == fuzzy) %Call = ,forEach,1,bool,$false,bool,$true
  else %Call = ,forEach,1,bool,$false,bool,$false
  while (%X < $0) {
    inc %x
    %Log = %Log $+ $($ $+ %X, 2) $+ ,
    if (%X > 2) %Call = %Call $+ ,bstr, $+ $ $+ %X
  }
  jfm_log -I $left(%Log,-1) $+ $chr(41) $+ $iif($prop !== $null,. $+ $v1)
  if ($0 < 2) %Error = INVAID_PARAMETERS
  elseif ($1 == 0) %Error = INVALID_HANDLER
  elseif ($prop !== $null) && ($prop !== walk) && ($prop !== fuzzy) { %Error = INVALID_PROPERTY }
  elseif ($0 > 2) && ($prop == walk) { %Error = PARAMETERS_NOT_APPLICABLE }
  elseif (!$1) || ($1 == 0) || (!$regex($1,/^((?:[^?:*]+)|(?:JSON:[^?:*]+(?::\d+)))$/)) { %Error = NAME_INVALID }
  else {
    if (JSON:?* iswm $1) %JSON = $com($1)
    elseif ($regex($1,/^\d+$/i)) {
      %X = 1
      %JSON = 0
      while ($com(%X)) {
        if ($regex($1,/^JSON:[^?*:]+$/)) {
          inc %JSON
          if (%JSON == $1) {
            %JSON = $com(%X)
            break
          }
          elseif (%X == $com(0)) %JSON = $null
        }
        inc %X
      }
    }
    else %JSON = $com(JSON: $+ $1)
    if (!%JSON) %Error = HANDLE_NOT_FOUND
    else {
      %Com = $gettok(%JSON,1-2,58) $+ :
      %X = $ticks $+ 000000
      while ($com(%Com $+ %X)) inc %x
      %Com = %Com $+ %X
      %Call = $!com( $+ %JSON $+ %Call $+ ,dispatch* %Com $+ )
      jfm_log %Call
      if (!$(%Call, 2)) || ($comerr) || (!$com(%Com)) { %Error = $jfm_GetError }
      else {
        .timer $+ %Com -iom 1 0 JSONClose $unsafe(%Com)
        if (!$com(%Com, length, 2)) || ($comerr) { %Error = $jfm_GetError }
        elseif ($com(%Com).result) {
          %Result = $v1
          %X = 0
          %ChildCom = $gettok(%Com,1-2,58) $+ :
          %Name = $ticks
          while ($com(%ChildCom $+ %Name)) inc %Name
          %Name = %ChildCom $+ %Name
          hinc -m SReject/JSONForMirc ForEach/Index
          hadd -m SReject/JSONForMirc ForEach/ $+ $hget(SReject/JSONForMirc,ForEach/Index) %Name
          while (%X < %Result) {
            if (!$com(%Com,%X,2,dispatch* %Name) || $comerr) {
              %Error = $jfm_GetError
              break
            }
            jfm_log -I Calling $1 %Name
            $2 %Name
            .comclose %Name
            jfm_log -D
            inc %X
          }
          hdel SReject/JSONForMirc ForEach/ $+ $hget(SReject/JSONForMirc, ForEach/Index)
          hdec SReject/JSONForMirc ForEach/Index
          if ($hget(SReject/JSONForMirc, ForEach/Index) == 0) hdel SReject/JsonForMirc ForEach/Index
        }
      }
    }
  }
  :error
  if ($error) %Error = $error
  reseterror
  if (%Error) {
    if ($com(%Com)) .comclose $v1
    if (JSON:* iswm %Name && $com(%Name)) { .comclose %Name }
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeDF %Error
  }
  else {
    jfm_log -EsDF %Result
    return %Result
  }
}
alias JSONItem {
  var %Com = $hget(SReject/JSONForMirc,ForEach/ $+ $hget(SReject/JSONForMirc,ForEach/Index)),%Type,%Bvar,%Text
  if (!$isid || !%Com || !$com(%Com)) { return }
  if ($1 == Value || $1 == Valuetobvar) {
    %BVar = $jfm_TmpBVar
    noop $com(%Com, value, 1) $Com(%Com, %BVar).result
    if ($1 == valuetobvar) return %Bvar
    %Text = $bvar(%BVar, 1, 4000).text
    bunset %BVar
    return %Text
  }
  elseif ($1 == Length) {
    noop $com(%com, length, 1)
    return $com(%com).result
  }
  elseif ($1 == Type || $1 == IsContainer) {
    noop $com(%Com, type, 1)
    %type = $com(%Com).result
    if ($1 == type) return %Type
    if (%type == Object || %Type == Array) { return $true }
    return $false
  }
}
alias JSONPath {
  if (!$isid) return
  if ($hget(SReject/JSONForMirc,Error)) hdel SReject/JSONForMirc Error
  var %Error,%Param,%X 0,%JSON,%Result
  while (%X < $0) {
    inc %X
    %Param = %Param $+ $($ $+ %X,2) $+ ,
  }
  jfm_log -I $!JSONPath( $+ $left(%Param,-1) $+ )
  if ($0 !== 2) %Error = INVALID_PARAMETERS
  elseif ($prop !== $null) %Error = PROP_NOT_APPLICABLE
  elseif (!$1) || ($1 == 0) || (!$regex($1, /^(?:(?:JSON:[^?:*]+(?::\d+)*)?|([^?:*]+))$/i)) { %Error = NAME_INVALID }
  elseif ($2 !isnum 0-) || (. isin $2) { %Error = INVALID_INDEX }
  else {
    %JSON = $JSON($1)
    if ($JSONError) %Error = $v1
    elseif (!%JSON) %Error = HANDLER_NOT_FOUND
    elseif ($JSON(%JSON).pathLength == $null) %Error = $JSONError
    else {
      %Result = $v1
      if (!$2) noop
      elseif ($2 > %Result) unset %Result
      elseif (!$com(%JSON, pathAtIndex, 1, bstr, $calc($2 -1))) || ($comerr) { %Error = $jfm_GetError }
      else %Result = $com(%JSON).result
    }
  }
  :error
  if ($error) %Error = $v1
  reseterror
  if (%Error) {
    hadd -mu0 SReject/JSONForMirc Error %Error
    jfm_log -EeDF %Error
  }
  else {
    jfm_log -EsDF %Result
    return %Result
  }
}
alias JSONError if ($isid) return $hget(SReject/JSONForMirc,Error)
alias JSONVersion {
  if ($isid) {
    var %Ver 1.0.4000
    if ($0) return %Ver
    return SReject/JSONForMirc v $+ %Ver
  }
}
alias JSONDebug {
  var %State $false, %aline aline $color(info2) @SReject/JSONForMirc/Log
  if ($group(#SReject/JSONForMirc/Log) == on) {
    if (!$window(@SReject/JSONForMirc/Log)) .disable #SReject/JSONForMirc/log
    else %State = $true
  }
  if ($isid) return %State
  elseif (!$0) || ($1 == toggle) {
    if (%State) tokenize 32 disable
    else tokenize 32 enable
  }
  if ($1 == on) || ($1 == enable) {
    if (%State) {
      echo $color(info).dd -atngq * /JSONDebug: debug already enabled
      return
    }
    .enable #SReject/JSONForMirc/Log
    %State = $true
  }
  elseif ($1 == off) || ($1 == disable) {
    if (!%State) {
      echo $color(info).dd -atngq * /JSONDebug: debug already disabled
      return
    }
    .disable #SReject/JSONForMirc/Log
    %State = $false
  }
  else {
    echo $color(info).dd -atng * /JSONDebug: Unknown input
    return
  }
  if (%State) {
    if (!$window(@SReject/JSONForMirc/Log)) window -zk0ej10000 @SReject/JSONForMirc/Log
    %aline Debug now enabled
    if ($~adiircexe) %aline AdiIRC v $+ $version $iif($beta, beta $builddate) $bits $+ bit
    else %aline mIRC v $+ $version $iif($beta, beta $v1) $bits $+ bit
    %aline $JSONVersion $iif($JSONCompat, [CompatMode], [NormalMode])
    %aline -
  }
  elseif ($Window(@SReject/JSONForMirc/Log)) %aline [JSONDebug] Debug now disabled
  window -b @SReject/JSONForMirc/Log
}
alias -l jfm_TmpBVar {
  var %N $ticks $+ 00000
  jfm_log -I $!jfm_TmpBVar
  while ($bvar(&SReject/JSONForMirc/Tmp $+ %N)) inc %N
  jfm_log -EsD &SReject/JSONForMirc/Tmp $+ %N
  return &SReject/JSONForMirc/Tmp $+ %N
}
alias -l jfm_ComInit {
  var %Error,%Js $jfm_tmpbvar
  jfm_log -I $!jfm_ComInit
  if ($com(SReject/JSONForMirc/JSONShell) && $com(SReject/JSONForMirc/JSONEngine)) {
    jfm_log -EsD Already Initialized
    return
  }
  jfm_jscript %Js
  if ($com(SReject/JSONForMirc/JSONEngine)) .comclose $v1
  if ($com(SReject/JSONForMirc/JSONShell)) .comclose $v1
  if ($~adiircexe !== $null) && ($bits == 64) { .comopen SReject/JSONForMirc/JSONShell ScriptControl }
  else .comopen SReject/JSONForMirc/JSONShell MSScriptControl.ScriptControl
  if (!$com(SReject/JSONForMirc/JSONShell)) || ($comerr) { %Error = SCRIPTCONTROL_INIT_FAIL }
  elseif (!$com(SReject/JSONForMirc/JSONShell, language, 4, bstr, jscript)) || ($comerr) { %Error = LANGUAGE_SET_FAIL }
  elseif (!$com(SReject/JSONForMirc/JSONShell, AllowUI, 4, bool, $false)) || ($comerr) { %Error = ALLOWIU_SET_FAIL }
  elseif (!$com(SReject/JSONForMirc/JSONShell, timeout, 4, integer, -1)) || ($comerr) { %Error = TIMEOUT_SET_FAIL }
  elseif (!$com(SReject/JSONForMirc/JSONShell, ExecuteStatement, 1, &bstr, %Js)) || ($comerr) { %Error = JSCRIPT_EXEC_FAIL }
  elseif (!$com(SReject/JSONForMirc/JSONShell, Eval, 1, bstr, this, dispatch* SReject/JSONForMirc/JSONEngine)) || ($comerr) || (!$com(SReject/JSONForMirc/JSONEngine)) { %Error = ENGINE_GET_FAIL }
  :error
  if ($error) {
    %Error = $v1
    reseterror
  }
  if (%Error) {
    if ($com(SReject/JSONForMirc/JSONEngine)) .comclose $v1
    if ($com(SReject/JSONForMirc/JSONShell)) .comclose $v1
    jfm_log -EeD %Error
    return %Error
  }
  else jfm_log -EsD Successfully initialized
}
alias -l jfm_ToggleTimers {
  var %x 1,%timer
  while ($timer(%x)) {
    %timer = $v1
    if ($regex(%timer,/^JSON:[^\?\*\:]+$/i)) $+(.timer,%timer) $1
    inc %x
  }
}
alias -l jfm_GetError {
  var %Error = UNKNOWN
  jfm_log -I $!jfm_GetError
  if ($com(SReject/JSONForMirc/JSONShell).errortext) %Error = $v1
  if ($com(SReject/JSONForMirc/JSONShellError)) .comclose SReject/JSONForMirc/JSONShellError
  if ($com(SReject/JSONForMirc/JSONShell,Error,2,dispatch* SReject/JSONForMirc/JSONShellError)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError)) && ($com(SReject/JSONForMirc/JSONShellError,Description,2)) && (!$comerr) && ($com(SReject/JSONForMirc/JSONShellError).result !== $null) { %Error = $v1 }
  if ($com(SReject/JSONForMirc/JSONShellError)) .comclose SReject/JSONForMirc/JSONShellError
  jfm_log -EsD %Error
  return %Error
}
alias -l jfm_Create {
  var %Wait $iif(1 & $4,$true,$false),%Parse $iif(2 & $4,$false,$true),%Error
  jfm_log -I $!jfm_create( $+ $1 $+ , $+ $2 $+ , $+ $3 $+ , $+ $4 $+ , $+ $5 $+ )
  if (!$com(SReject/JSONForMirc/JSONEngine,JSONCreate,1,bstr,$2,&bstr,$3,bool,%Parse,dispatch* $1)) || ($comerr) || (!$com($1)) { %Error = $jfm_GetError }
  elseif ($2 !== http) || ($2 == http && !%Wait) { %Error = $jfm_Exec($1,parse) }
  if (%Error) {
    jfm_log -EeD %Error
    return %Error
  }
  jfm_log -EsD Created $1
}
alias -l jfm_Exec {
  var %Args,%Index 0,%Params,%Error
  if ($hget(SReject/JSONForMirc,Exec)) hdel SReject/JSONForMirc Exec
  while (%Index < $0) {
    inc %Index
    %Args = %Args $+ $iif($len(%Args),$chr(44)) $+ $($ $+ %Index,2)
    if (%Index >= 3) {
      if ($prop == fromBvar) && ($regex($($ $+ %Index,2),/^& (&\S+)$/)) { %Params = %Params $+ ,&bstr, $+ $regml(1) }
      else %Params = %Params $+ ,bstr,$ $+ %Index
    }
  }
  %Params = $!com($1,$2,1 $+ %Params $+ )
  jfm_log -I $!jfm_Exec( $+ %Args $+ )
  if (!$(%Params,2) || $comerr) {
    %Error = $jfm_GetError
    jfm_log -EeD %Error
    return %Error
  }
  else {
    hadd -mu0 SReject/JSONForMirc Exec $jfm_tmpbvar
    noop $com($1, $hget(SReject/JSONForMirc, Exec)).result
    jfm_log -EsD Result stored in $hget(SReject/JSONForMirc,Exec)
  }
}
#SReject/JSONForMirc/Log off
alias -l jfm_log {
  var %Switches,%Prefix ->,%Color 03,%Indent
  if (!$window(@SReject/JSONForMirc/Log)) {
    .JSONDebug off
    if ($hget(SReject/JSONForMirc,LogIndent)) hdel SReject/JSONForMirc LogIndent
  }
  else {
    if (-?* iswm $1) {
      %Switches = $mid($1, 2-)
      tokenize 32 $2-
    }
    if (i isincs %Switches) hinc -mu1 SReject/JSONForMirc LogIndent
    if ($0) {
      if (E isincs %Switches) %Prefix = <-
      if (e isincs %Switches) %Color = 04
      elseif (s isincs %Switches) %Color = 12
      elseif (l isincs %Switches) %Color = 13
      %Prefix = $chr(3) $+ %Color $+ %Prefix
      if (F !isincs %Switches) %Prefix = %Prefix $+ $chr(15)
      %Indent = $str($chr(15) $+ $chr(32), $calc($hget(SReject/JSONForMirc, LogIndent) *4))
      echo -gi $+ $calc(($hget(SReject/JSONForMirc, LogIndent) + 1) * 4 -1) @SReject/JSONForMirc/Log %Indent %Prefix $1-
    }
    if (I isincs %Switches) hinc -mu1 SReject/JSONForMirc LogIndent 1
    if (D isincs %Switches) && ($hget(SReject/JSONForMirc, LogIndent) > 0) { hdec -mu1 SReject/JSONForMirc LogIndent 1 }
  }
}
#SReject/JSONForMirc/Log end
alias -l jfm_log noop
alias -l jfm_SaveDebug {
  if ($isid) {
    if ($window(@SReject/JSONForMirc/Log)) && ($line(@SReject/JSONForMirc/Log, 0)) { return $true }
    return $false
  }
  var %File $sfile($envvar(USERPROFILE) $+ \Documents\JSONForMirc.log, JSONForMirc - Debug window, Save)
  if (%File) && (!$isfile(%File) || $input(Are you sure you want to overwrite $nopath(%File) $+ ?, qysa, @SReject/JSONForMirc/Log, Overwrite)) { savebuf @SReject/JSONForMirc/Log $qt(%File) }
}
alias -l jfm_badd {
  bset -t $1 $calc(1 + $bvar($1, 0)) $2-
}
alias -l jfm_jscript {
  jfm_badd $1 !function(){Array.prototype.forEach=function(c){for(var s=this,i=0;i<s.length;i++)c.call(s,s[i],i)};Array.prototype.find=function(c){for(var s=this,i=0;i<s.length;i+=1)if(c.call(s,s[i]))return s[i]};I=['MSXML2.SERVERXMLHTTP.6.0','MSXML2.SERVERXMLHTTP.3.0','MSXML2.SERVERXMLHTTP'].find(function(x){try{return new ActiveXObject(x),x}catch(e){}});function A(o){if(o===null)return 'null';return Object.prototype.toString.call(o).match(/^\[object ([^\]]+)\]$/)[1].toLowerCase()}function B(o){var k=[],i;for(i in o)if(C(o,i))k.push(i);return k}
  jfm_badd $1 function C(o,k){return Object.prototype.hasOwnProperty.call(o,k)}
  jfm_badd $1 function D(s){if(s._state!=='done'||s._error||!s._parse)throw new Error('NOT_D');return s}
  jfm_badd $1 function E(s){if(s._type!=='http')throw new Error('HTTP_NOT_INUSE');if(s._state!=='http_pending')throw new Error('HTTP_NOT_PENDING');return s._http}
  jfm_badd $1 function F(s){if(s._type!=='http')throw new Error('HTTP_NOT_INUSE');if(s._state!=='done')throw new Error('HTTP_PENDING');return s._http}
  jfm_badd $1 function G(v){var t=A(v),r='[';if(v===undefined||t==='function')return;if(v===null)return'null';if(t==='number')return isFinite(v)?v.toString():'null';if(t==='boolean')return v.toString();if(t==='string')return'"'+v.replace(/[\\"\u0000-\u001F\u2028\u2029]/g,function(c){return{'"':'\\"','\\':'\\\\','\b':'\\b','\f':'\\f','\n':'\\n','\r':'\\r','\t':'\\t'}[c]||'\\u'+(c.charCodeAt(0)+0x10000).toString(16).substr(1)})+'"';if(t==='array'){v.forEach(function(i,k){i=G(i);if(i)r+=(k?',':'')+i});return r+']'}r=[];B(v).forEach(function(k,o){o=G(v[k]);if(o)r.push(G(k)+':'+o)});return'{'+r.join(',')+'}'}
  jfm_badd $1 function H(p,j,s){s=this;if(p===undefined)p={};if(j===undefined){s._isChild=!1;s._json=p._json||{}}else{s._isChild=!0;s._json=j}s._state=p._state||'init';s._type=p._type||'text';s._parse=p._parse===!1?!1:!0;s._error=p._error||!1;s._input=p._input;s._http=p._http||{method:'GET',url:'',headers:[]}}
  jfm_badd $1 H.prototype={
  jfm_badd $1 state:function(){return this._state},
  jfm_badd $1 error:function(){return this._error.message},inputType:function(){return this._type},
  jfm_badd $1 input:function(){return this._input||null},
  jfm_badd $1 httpParse:function(){return this._parse},
  jfm_badd $1 httpSetMethod:function(m){E(this).method=m},
  jfm_badd $1 httpSetHeader:function(h,v){E(this).headers.push([h,v])},
  jfm_badd $1 httpSetData:function(d){E(this).data=d},
  jfm_badd $1 httpStatus:function(){return F(this).response.status},
  jfm_badd $1 httpStatusText:function(){return F(this).response.statusText},
  jfm_badd $1 httpHeaders:function(){return F(this).response.getAllResponseHeaders()},
  jfm_badd $1 httpHeader:function(h){return F(this).response.getResponseHeader(h)},
  jfm_badd $1 httpBody:function(){return F(this).response.responseBody},
  jfm_badd $1 httpHead:function (s){return s=this,s.httpStatus()+' '+s.httpStatusText()+'\r\n'+s.httpHeaders()},
  jfm_badd $1 httpResponse:function(){return this.httpHead()+'\r\n\r\n'+this._http.response.reponseText},
  jfm_badd $1 parse:function(){var s=this,d=!0,x=!1,y=!1,r,j;s.parse=function(){throw new Error('PARSE_NOT_PENDING')};s._state='done';try{if(s._type==='http'){try{if(s._http.data==undefined){d=!1;s._http.data=null}r=new ActiveXObject(I);s._http.response=r;r.open(s._http.method,s._http.url,!1);s._http.headers.forEach(function(h){r.setRequestHeader(h[0],h[1]);if(h[0].toLowerCase()==="content-type")x=!0;if(h[0].toLowerCase()==="content-length")y=!0});if(d){if(!x)r.setRequestHeader("Content-Type","application/x-www-form-urlencoded");if(!y){if(s._http.data==null)r.setRequestHeader("Content-Length",0);else r.setRequestHeader("Content-Length",String(s._http.data).length)}}r.send(s._http.data);if(s._parse===!1)return s;s._input=r.responseText}catch(e){e.message="HTTP: "+e.message;throw e}}j=String(s._input).replace(/[\u0000\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff]/g,function(c){return'\\u'+('0000'+c.charCodeAt(0).toString(16)).slice(-4)});if(!/^[\],:{}\s]*$/.test(j.replace(/\\(?:["\\\/bfnrt]|u[0-9a-fA-F]{4})/g,'@').replace(/"[^"\\\n\r]*"|true|false|null|-?\d+(?:\.\d*)?(?:[eE][+\-]?\d+)?/g,']').replace(/(?:^|:|,)(?:\s*\[)+/g,'')))throw new Error("INVALID_JSON");try{j=eval('('+j+')')}catch(e){throw new Error("INVALID_JSON")}s._json={path:[],value:j};return s}catch(e){s._error=e.message;throw e}},
  jfm_badd $1 walk:function(){var s=D(this),r=s._json.value,a=Array.prototype.slice.call(arguments),f=a.shift(),p=s._json.path.slice(0),t,m,i,k;while(a.length){t=A(r);m=String(a.shift());if(t!=='array'&&t!=='object')throw new Error('ILLEGAL_REFERENCE');if(f&&/^[~=]./.test(m)){i='~'===m.charAt(0);m=m.replace(/^[~=]\x20?/,'');if(t=='object'&&i){k=B(r);if(/^\d+$/.test(m)){m=parseInt(m,10);if(m>=k.length)throw new Error('FUZZY_INDEX_NOT_FOUND');m=k[m]}else if(!C(r,m)){m=m.toLowerCase();m=k.find(function(k){return m===k.toLowerCase()});if(m==undefined)throw new Error('FUZZY_MEMBER_NOT_FOUND')}}}if(!C(r,m))throw new Error('REFERENCE_NOT_FOUND');p.push(m);r=r[m]}return new H(s,{path:p,value:r})},
  jfm_badd $1 forEach:function(){var s=D(this),a=Array.prototype.slice.call(arguments),r=[],d=a[0]?Infinity:1;a.shift();function _(i,p,j){j=new H(s,{path:p,value:i});if(d!==Infinity&&a.length>1)j=j.walk.apply(j,a.slice(0));r.push(j)}function Z(i,p,c,t){t=A(i);p=p.slice(0);if(c>d)_(i,p);else if(t==='object')B(i).forEach(function(k,z){z=p.slice(0);z.push(k);Z(i[k],z,c+1)});else if(t==='array')i.forEach(function(v,k){z=p.slice(0);z.push(k);Z(v,z,c+1)});else _(i,p)}if(s.type()!=='object'&&s.type()!=='array')throw new Error('ILLEGAL_REFERENCE');Z(s._json.value,s._json.path.slice(0),1);return r},
  jfm_badd $1 type:function(){return A(D(this)._json.value)},
  jfm_badd $1 isContainer:function(){return(this.type()==="object"||this.type()==="array")},
  jfm_badd $1 pathLength:function(){return D(this)._json.path.length},
  jfm_badd $1 pathAtIndex:function(i){return D(this)._json.path[i]},
  jfm_badd $1 path:function(){var r='';D(this)._json.path.forEach(function(i){r+=(r?' ':'')+String(i).replace(/([\\ ])/g,function(c){return' '=== c?'\s':'\\'})});return r},
  jfm_badd $1 length:function(){var s=D(this),t=s.type();if(t==='string'||t==='array')return s._json.value.length;if(t==='object')return B(s._json.value).length;throw new Error('INVALID_TYPE')},
  jfm_badd $1 value:function(){return D(this)._json.value},
  jfm_badd $1 string:function(){return G(D(this)._json.value)},
  jfm_badd $1 debug:function(){var s=this,r={state:s._state,input:s._input,type:s._type,error:s._error,parse:s._parse,http:{url:s._http.url,method:s._http.method,headers:s._http.headers,data:s._http.data},isChild:s._isChild,json:s._json};if(s._type==="http"&&s._state==="done")r.http.response={status:s._http.response.status,statusText:s._http.response.statusText,headers:(s._http.response.getAllResponseHeaders()).split(/[\r\n]+/g),responseText:s._http.response.responseText};return G(r)}};
  jfm_badd $1 JSONCreate=function(t,i,p,s){s=new H();s._state='init';s._type=(t||'text').toLowerCase();s._parse=p===!1?!1:!0;if(s._type==='http'){if(!I){s._error='HTTP_NOT_FOUND';throw new Error('HTTP_NOT_FOUND')}s._state='http_pending';s._http.url=i}else{s._state='parse_pending';s._input=i}return s}}()
}
