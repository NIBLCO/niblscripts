# By Flintlock for NIBL
__module_name__ = "NIBL XDCC Filter"
__module_version__ = "1.0"
__module_description__ = "Displays #NIBL XDCC announcements in a separate tab."

import hexchat

newTab = "(NIBL-XDCC)"
channel = "#nibl"

def GetNick(hostString):
    # :nick!user@h.o.s.t
    return hostString[1:].split("!")[0]

def MakeTab():
    hexchat.command("QUERY {}".format(newTab))

def Redirect(word, word_eol, userdata):
    if word[2].lower() == channel:
        nick = GetNick(word[0])
        for user in hexchat.get_list("users"):
            if nick == user.nick:
                if user.prefix == "%":
                    tabContext = hexchat.find_context(channel=newTab)
                    if tabContext is None:
                        MakeTab()
                        tabContext = hexchat.find_context(channel=newTab)
                    tabContext.emit_print("Channel Message", "{}".format(nick), "{}".format(word_eol[3][1:]), "%")
                    return hexchat.EAT_ALL
                else:
                    break
    return hexchat.EAT_NONE

hexchat.hook_server("PRIVMSG", Redirect)

MakeTab()
