;
; Script Name:     XDCC-Filter (v1.0) Basic
; Created by:      Rand (#NIBL @ Rizon)
;
; Usage: Place into mIRC script folder (Should be C:\Users\username\AppData\Roaming\mIRC\scripts
;        /load -rs scripts\xdccfilter.mrc
;        
; Displays #NIBL XDCC announcements in a separate query tab.
; Like the advanced version, this also includes a "GETIT" function, which will download the file when you
; double click on the [GETIT] highlighted just after the bots announce message ( /msg Botname XDCC SEND # [GETIT])

on ^*:text:*:#nibl:{
  if ($nick ishop $chan) {
    haltdef
    var %w = @NIBL-XDCC , %text = $1-
    if (!$window(@NIBL-XDCC)) { window -e %w }
    var %text = $regsubex(xdccanc,%text,/(\/?msg \S+ xdcc send #?\d+)/ig,\t 7[GETIT])
    aline %w $timestamp > $chan - $nick : %text
  }
}

on ^*:hotlink:*GETIT*:@NIBL-XDCC:{
  tokenize 32 $hotlinepos
  var %t = $gettok($hotline,$1,32)
  if (7[GETIT]* iswm %t) { return }
  halt
}
on *:hotlink:*GETIT*:@NIBL-XDCC:{
  tokenize 32 $hotlinepos
  var %start = $calc($1 - 5) , %finish = $calc(%start + 4)
  var %t = $gettok($hotline,%start - %finish,32)
  if ($regex(%t,/^\/?msg (\S+) xdcc send (#?\d+)$/iS)) {
    msg $regml(1) xdcc send $regml(2)
  }
}
