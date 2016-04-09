; NIBL - Bot search.
; This script pulls it's information from NIBL's website.
;           
;
; Usage:    /nibl [-b botname] [search terms]
;           
; Examples: Search for all packs on a bot:   /nibl -b bot
;           Use search term on all bots:     /nibl some show
;           Use search term on specific bot: /nibl -b bot some show
;           To cancel an auto-retry attempt: /cancelget Botname.#PackNumber
;            
; Creator:  Rand (@Rizon)
; Version:  0.3
;        
;         Changelog:
;           0.3 - Added a "Retry" option - for incomplete downloads.  On by default.
;                 You can /cancelget Botname.#PackNumber, to cancel a specific retry attempt.
;           0.2 - Added a "Trust" bot option - auto accepts downloads from bots.
;           0.1 - Initial release.


; Quick Customization Section!
;
; Alternating Colors:
;     The two lines below control the 'alternating colors' of the text.
;     In my client 0 is white and 14 is a darker gray.
;     Change these two numbers to fit your needs.

alias -l _nibl.color.main { return 0 }
alias -l _nibl.color.alt { return 14 }

; Headers:
;    _nibl.headers.repeat
;      Controls how often you see
;      "Bot  Pack  Size  File" repeated.
;      0 = Disabled.   1 = Every other line.
;      2 = Every 2 lines.  so on and so forth.
;      Default is 10.
;    _nibl.headers.visible
;      Set to 0 to disable.
;      Set to 1 to always display repeat headers.
;      Set to 2 to only display repeat headers when searching a specific bot.
;      Default is 2 - so that it only shows when searching a specific bot. ie /nibl -b bot search.

alias -l _nibl.headers.repeat { return 0 }
alias -l _nibl.headers.visible { return 0 }


; Bot name seperator:
;    This controls whether or not there will
;    be a seperator when moving on to the next bot.
;    1 for on, 0 for off. Default is 1.

alias -l _nibl.bot.name.seperator { return 0 }

; Automatically "TRUST" the bots that you try to download from!
;    This will allow you to automatically add a bot to your 'trusted' list.
;    It will accept the file sends from the bots automatically.
;    Default option for this is 1, "on".  You can set this to 0 to disable.
;    ... If you want this feature to work:
;    Press ALT + O, Select "DCC"
;    Set "On Send request:" to:
;       [x] Auto-get file and [x] minize
;       If file exists:
;          [Resume]  [Trusted]
;
;    Set these options if you want

alias -l _add.bot.to.trusted { return 1 }

; If your download is incomplete, re-request the file from the bot.
;    Note: You must enable mIRC's "auto resume" feature.
;       Alt+O > DCC > [x] Auto-get file and [x] Minimize
;       Alt+O > DCC > If file exists [Resume]
;       Alt+O > DCC > [Trusted] > [x] Limit auto-get to trusted users.
;       Alt+O > DCC > [Trusted] > [x] Show get dialog for non-trusted users.
;
;    Default option for this is 1, "on."  You can set this to 0 to disable.

alias -l _nibl.bot.file.retry { return 1 }

;
; Don't change anything below here unless you know what you're doing!
; --------------------------------------------------------------------
;


alias nibl {
  var %n = nibl
  if ($sock(%n)) return

  if ($$1 == -b) { var %botname = $$2 , %search = $3- }
  else { var %botname = 0, %search = $$1- }

  sockopen %n nibl.co.uk 80
  sockmark %n %botname %search
  if (!$window(@nibl)) { window -aeh -t14,44,58,67,75 @nibl }
  echo -act notice * Loading NIBL results for your search: $iif($1 == -b,$+([,%botname,])) %search
  window -h @nibl
  clear @nibl
  aline @nibl 4>5 Searching $iif($1 == -b, bot: 7 $+ %botname) $iif(%search,5for:7 %search)
}



on *:sockopen:nibl:{
  tokenize 32 $sock(nibl).mark
  var %s = sockwrite -n $sockname
  var %botname = $1 , %search = $regsubex($2-,/([^A-Za-z0-9])/g,% $+ $base($asc(\t),10,16))

  if (%botname == 0) {
    %s GET /bots.php?search= $+ %search HTTP/1.0
  }
  else {
    %s GET /bots.php?bot= $+ %botname $+ &search= $+ %search HTTP/1.0
  }
  %s Host: nibl.co.uk
  %s
}

on *:sockread:nibl:{
  var %botcheck = $gettok($sock(nibl).mark,1,32)
  if ($sockerr) return
  sockread %s
  while ($sockbr) {
    if ($regex(%s,/<tr class=\"botlistitem.*?\" botname=\"(.+?)\" botpack=\"(.+?)\"/)) {
      set %nibl.bot $regml(1)
      set %nibl.pack $regml(2)
    }
    if ($regex(%s,/<td class=\"filesize\">(.+?)<\/td>/)) {
      set %nibl.size $regml(1)
    }
    if ($regex(%s,/<td class=\"filename\">(.+)/)) {
      set %nibl.name $regml(1)
      if ($_nibl.bot.name.seperator) {
        if (%nibllastbot != %nibl.bot) {
          aline @nibl 
          aline @nibl 7 $chr(9) Bot $chr(9) Pack $chr(9) Size $chr(9) File
          aline @nibl 9 $chr(9) %nibl.bot
          unset %niblcount
        }
      }
      inc %niblcount

      aline @nibl 4[NIBLGET]  $+ $iif(2 // %niblcount,$_nibl.color.alt,$_nibl.color.main) $chr(9) %nibl.bot $chr(9) $(#,0) $+ %nibl.pack $chr(9) %nibl.size $chr(9) %nibl.name
      if ($_nibl.headers.visible == 1 || ($_nibl.headers.visible == 2 && %botcheck != 0)) {
        if ($_nibl.headers.repeat // %niblcount) {
          aline @nibl 7 $chr(9) Bot $chr(9) Pack $chr(9) Size $chr(9) File
        }
      }
      set %nibllastbot %nibl.bot
      unset %nibl.*
    }
    sockread %s
  }
}

on *:sockclose:nibl:{
  window -aew3 @nibl
  unset %nibl*
}

on ^*:hotlink:[NIBLGET]:@nibl:{
  if ($strip($1) == [NIBLGET]) return
  halt
}
on *:hotlink:[NIBLGET]:@nibl:{
  tokenize 32 $replace($hotline,$chr(9),$chr(32))
  var %nick = $3 , %pack = $4 , %file = $6-
  if (#nibl !ischan) { echo -a *** Error:  Try joining #NIBL first! Rizon network. | return }
  if (%nick !ison #nibl && %nick !ison #horriblesubs) { echo -a *** Error:  Silly bastard!  The bot $qt(%nick) isn't even on #NIBL! (network : $network - current) | return }
  _getPack %nick %pack %file
}
on ^*:hotlink:[CANCELGET]:*:{
  if ($strip($gettok($hotline,1,32)) != [CANCELGET]) halt
  if ($strip($1) == [CANCELGET]) return
  halt
}
on *:hotlink:[CANCELGET]:*:{
  tokenize 32 $hotline
  if ($hget(niblget,$2)) {
    echo -sa 4> 5Removing auto-retry for:07 $2 5-7 $hget(niblget,$2)
    hdel niblget $2
    .timer. $+ $2 off
  }
  else {
    echo -a 4> 5No auto-retry set for:07 $2
  }
}

alias -l _getPack {
  var %nick = $1 , %pack = $2 , %file = $3- , %np = $+(%nick,.,%pack)
  if ($_add.bot.to.trusted == 1) {
    .dcc trust $address(%nick,3)
  }
  echo -a 4> 5Fetching:4 %file     5From:4 %nick     5Pack:04 %pack
  .msg %nick xdcc send %pack
  hadd -m niblget %np %file
}

on *:getfail:*:{
  if (!$_nibl.bot.file.retry) return
  var %n = niblget , %f = $nopath($filename) , %nickwm = $nick $+ .*
  if ($hfind(%n,%f,1).data != $null) {
    var %np = $v1
    if (%nickwm iswm %np) {
      if ($regex(%np,/^(.+?)\.(#.+?)$/)) {
        echo -s Failure to get file from $regml(1), and requesting the file (pack $regml(2) ) again in 15 seconds.
        echo -s To cancel this, double click the word "CANCELGET" in the line below. Or type: /cancelget %np
        echo -sa 4[CANCELGET]7 %np 5-7 %f     5(auto retry in 15sec)
        beep 1
        .timer. $+ %np 1 15 msg $regml(1) xdcc get $regml(2) 
      }
    }
  }
}
alias cancelget {
  .timer. $+ $1 off
  hdel niblget $1
  echo -a Cancelled retries for $1
}
on *:filercvd:*:{
  var %n = niblget , %f = $nopath($filename) , %nickwm = $nick $+ .*
  if ($hfind(%n,%f,1).data != $null) {
    var %np = $v1
    if (%nickwm iswm %np) {
      echo -s File recieved.  Removing %np from the watch list.
      hdel niblget %np
    }
  }
}
alias stripFluff { return $regsubex($1-,/\.|-|_/g,$chr(32)) }
