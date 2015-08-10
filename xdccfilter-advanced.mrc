; XDCC Announcement Filter - v2
;
; Type /xdcca to bring up the XDCC Announcement window.
; This will intercept announcements.
; By typing the command again it'll realign itself to mIRC.
;
; If you have a script that adds a theme to your mIRC,
; you will need to adjust that script slightly
; so that the bots (halfops) messages do not show up in normal chat.
; Below is something you can add to it to 'adjust' it.
;
; NOTE, the following ONLY applies if you already have a "theme" script:
; 
; *   If this is the case, look for the event "on ^*:text:"
; *   You'll need to add something like this:
; *   ---------------------------------------
; *         if ($window(@xdcca)) {
; *           if ($network == Rizon && $nick ishop $chan) {
; *             haltdef | return
; *           }
; *         }
; *   ----------------------------------------
; *   This will need to go inside of your on text event,
; *   towards the top. 


; Command to create the XDCC Announce window.
; You can tweak the position.x and y, along with the width and height
; to adjust the size of the window. If you move your mIRC window or resize it
; you'll be able to type /xdcca again, and it'll reposition itself.

alias xdcca {
  var %position.x = $window(-3).dx
  var %position.y = $window(-3).dy
  var %width = $window(-3).dw
  var %height = 50

  ; If you want to change the height to be more dynamic:
  ; var %height = $window(-3).dh * 0.1


  var %xywh = %position.x %position.y $calc(%width - 130) 50

  window -adof -t32,64,120 +dL @xdcca %xywh
}


; This alias is used for formatting.
; You can use it to set up your own themes if you want..
; /_specialmsg window nickname message

alias _specialmsg {
  var %chan = $1 , %nick = $2 , %msg = $3-
  var %l = $len($timestamp .. %nick) , %l2 = %l + 5
  var %pre = $iif($_prefix(%chan,%nick),09 $+ $v1)
  if ($2 == $me) { var %nick = $+(%pre,10,$me,: ) }
  else { var %nick = $+(%pre,4,$2,: ) }
  echo -tcmbfli12 normal %chan %nick %msg
}

; Prefix. @ % +

alias -l _prefix { return $iif($left($nick($1,$2).pnick,1) isin $prefix,$v1,$null) }



; On text event to redirect bot messages to the @xdcca window - but only if it's open.

on ^*:text:*:#:{
  var %w = @xdcca , %text = $1-
  if ($window(%w)) {
    var %networks = Rizon
    if ($istok(%networks,$network,32) && $nick ishop $chan) {
      var %text = $regsubex(xdccanc,%text,/(\/?msg \S+ xdcc send #?\d+)/ig,\t 7[GETIT])
      _specialmsg @xdcca $nick %text
      haltdef
      return
    }
  }
  haltdef
}


; On active and appactive - this determines whether to show the window or not. (only shows in channels)
; Hides the window (because it's on top) when mIRC is not the active application.

on *:active:*:{
  var %w = @xdcca 
  if ($window(%w)) {
    if (#* iswm $active && #* !iswm $lactive) {
      window -o %w
    }
    elseif ($active != %w && #* !iswm $active) {
      window -uh %w
    }
  }
}
on *:appactive:{
  var %w = @xdcca 
  if ($window(%w)) {
    if ($appactive) { window -o %w }
    else { window -uh %w }
  }
}

;  On hotlink - Makes the [GETIT] tag clickable.
on ^*:hotlink:*GETIT*:*:{
  tokenize 32 $hotlinepos
  var %t = $gettok($hotline,$1,32)
  if (7[GETIT]* iswm %t) { return }
  halt
}
on *:hotlink:*GETIT*:*:{
  tokenize 32 $hotlinepos
  var %start = $calc($1 - 5) , %finish = $calc(%start + 4)
  var %t = $gettok($hotline,%start - %finish,32)
  if ($regex(%t,/^\/?msg (\S+) xdcc send (#?\d+)$/iS)) {
    msg $regml(1) xdcc send $regml(2)
  }
}
