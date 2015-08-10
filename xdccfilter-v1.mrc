
;
; Script Name:     XDCC-Filter (v1.0) Basic
; Created by:      Rand (#NIBL @ Rizon)
;
; Usage: Place into mIRC script folder (Should be C:\Users\username\AppData\Roaming\mIRC\scripts
;        /load -rs scripts\XDCCadv.mrc
;        
; Displays #NIBL XDCC announcements in a separate query tab.

on ^*:text:*:#nibl:{
  if ($nick ishop $chan) {
    haltdef
    var %w = @XDCCadv
    if (!$window(@XDCCadv)) { window -e %w }
    aline %w $timestamp > $chan - $nick : $1-
  }
}
