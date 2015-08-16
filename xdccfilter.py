# By Flintlock for NIBL
__module_name__ = "NIBL XDCC Filter"
__module_version__ = "1.1"
__module_description__ = "Displays #NIBL XDCC announcements in a separate tab."

import hexchat

newTab = "(NIBL-XDCC)"
channel = "#nibl"

def MakeTab():
    hexchat.command("QUERY {}".format(newTab))

def Redirect(word, word_eol, userdata):
    if hexchat.get_info("channel").lower() == channel and len(word) > 2 and word[2] == "%":
        tabContext = hexchat.find_context(channel=newTab)
        if tabContext is None:
            MakeTab()
            tabContext = hexchat.find_context(channel=newTab)
        tabContext.emit_print("Channel Message", word[0], word[1], word[2])
        return hexchat.EAT_ALL
    else:
        return hexchat.EAT_NONE

hexchat.hook_print("Channel Message", Redirect)

MakeTab()
