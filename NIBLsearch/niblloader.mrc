; NIBL Search - Loader.
; You can use this to load in mIRC + JSON for mIRC.

on *:load:{
  load -rs $qt($+($scriptdir,nibl.mrc))
  load -rs $qt($+($scriptdir,includedRequirements\JSONFormIRC-v1.0.4000.mrc))
  unload -rs $qt($script)
}
