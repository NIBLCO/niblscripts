# NIBL Search (v1.2) 
NIBL Search is a script that allows you to search the NIBL bots, without having to open your browser or use the !s command publically in a channel.   

## Requirements  
This script requires both JSONFormIRC (script) and MDX (dll).  I've included both here, as you never known when they'll disappear off the internet.  IRC and mIRC are slowly being forgotten.    

## Install
Download the files, the includedRequirements folder is required (just as the name states).  
Load the niblloader.mrc file in mIRC.  Using this command in mIRC:  /load -rs C:\whatever\the\path\is\NIBLsearch\niblloader.mrc    
  
If you wish to use the "Trust Bots" and "Retry DL if incomplete" options, you will want to press ALT+O in mIRC.  Go to "DCC" and under "On Send request:" on the right, set it to [x] Auto-get-file and [x] minimize.  Under "If file exists:" set those dropdown box to "Resume" next to the [Trusted] button.    

## Usage
Typing "/nibl" or "/nibl search words here" will open up the Dialog window.  
If you use the "retry" option in the dialog settings at the bottom, you'll automatically retry to download a file if it fails to download.   You can cancel this by typing "/cancelget Botname.#Packnumber" like: "/cancelget BoobzBot.#6969"
