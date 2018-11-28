; NIBL Search - Loader.
; You can use this to load in mIRC + JSON for mIRC.

on *:load:{
  ; Check to see if an /nibl command already exists.
  if ($isalias(nibl)) {
    ; Ask permission to unload old /nibl command file
    var %autounload = $?!="You already have a file that contains an /nibl command. $crlf $+ Press [Yes] to automatically unload the file. $crlf $+ Press [No] to cancel installation of nibl.mrc"
    if (%autounload) {
      ; Unload the old /nibl command file.
      var %oldfile = $isalias(nibl).fname 
      unload -rs $qt(%oldfile) 
      echo -s NIBL Search INSTALLATION: Uninstalled old nibl file: $qt(%oldfile)
      ; Load the new file.
      _niblLoader
    }
    else {
      ; Inform the user that they chose to not install nibl.mrc with the loader.
      echo -s NIBL Search INSTALLATION: WARNING:  nibl.mrc was not installed with niblloader.mrc.  If you change your mind, you can run the niblloader again by typing: /load -rs $qt($script)
    }
  }
  else {
    ; No other /nibl command detected, load nibl.mrc
    _niblLoader
  }

  ; Check to see if a $json identifier already exists
  if ($isalias(json)) {
    ; Ask permission to load old $json identifier file
    var %autounload = $?!="You already have a file that contains a $!json identifier. $crlf $+ Press [Yes] to automatically unload the file. $crlf $+ Press [No] to cancel installation of nibl.mrc"
    if (%autounload) {
      ; Unload the old $json identifier file.
      var %oldfile = $isalias(json).fname 
      unload -rs $qt(%oldfile)
      echo -s NIBL Search INSTALLATION: Uninstalled old json file: $qt(%oldfile)
      ; Load the new file.
      _jsonLoader
    }
    else {
      ; Inform the user that they chose to not install JSONFormIRC with the loader.
      echo -s NIBL Search INSTALLATION: WARNING: JSONFormIRC-v1.0.4000.mrc was not installed with niblloader.mrc.  This is OK if you have a newer version.  If you do not, /nibl can not function without it.
    }
  }
  else {
    ; No other $json identifier detected, load JSONFormIRC
    _jsonLoader
  }

  ; Unload this script now that we've finished everything.
  unload -rs $qt($script)
}

alias -l _niblLoader {
  load -rs $qt($+($scriptdir,nibl.mrc))
  echo -s NIBL Search INSTALLATION: Installed new nibl file: $qt($+($scriptdir,nibl.mrc))
}
alias -l _jsonLoader {
  load -rs $qt($+($scriptdir,includedRequirements\JSONFormIRC-v1.0.4000.mrc))
  echo -s NIBL Search INSTALLATION: Installed new json file: $qt($+($scriptdir,includedRequirements\JSONFormIRC-v1.0.4000.mrc))
}