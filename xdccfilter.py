# By Flintlock for NIBL
__module_name__ = "NIBL XDCC Filter"
__module_version__ = "1.2"
__module_description__ = "Displays #NIBL XDCC announcements in a separate tab."

import hexchat, platform, os

newTab = "(NIBL-XDCC)"
channel = "#nibl"
comp = platform.system()
user = "ghost"
nibl_dir = None
nibl_hook = None

def Main(word, word_eol, userdata):
    argc = len(word)

    if argc == 2:
        if "on" == word[1]:
            DoHook()
        elif "off" == word[1]:
            DelHook()
        elif "open" == word[1]:
            MakeTab()

    return hexchat.EAT_ALL

def MakeTab():
    tabContext = hexchat.find_context(channel=newTab)
    if tabContext is None:
        hexchat.command("QUERY {}".format(newTab))
    return hexchat.EAT_ALL

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

def DoHook():
    global nibl_hook
    if not os.path.exists(nibl_dir + "xdccfilter"):
        file = open(nibl_dir + "xdccfilter", 'w')
        file.close()
    if nibl_hook is None:
        nibl_hook = hexchat.hook_print("Channel Message", Redirect)
        hexchat.command("MENU -t1 ADD \"NIBL/XDCC Filter\" \"nxf on\" \"nxf off\"")
    print "NIBL XDCC Filter activated"
    return hexchat.EAT_ALL

def DelHook():
    global nibl_hook
    if os.path.exists(nibl_dir + "xdccfilter"):
        os.remove(nibl_dir + "xdccfilter")
    if nibl_hook is not None:
        hexchat.unhook(nibl_hook)
        nibl_hook = None
        hexchat.command("MENU -t0 ADD \"NIBL/XDCC Filter\" \"nxf on\" \"nxf off\"")
    print "NIBL XDCC Filter deactivated"
    return hexchat.EAT_ALL

def check_dirs(f):
    d = os.path.dirname(f)
    if not os.path.exists(d):
        os.makedirs(d)

try:
    cmd = os.popen("whoami")
    try:
        user = cmd.readlines()
        user = user[0].strip("\n")
        if 'Windows' == comp:
            user = user.split("\\")[1]
    finally:
        cmd.close()
except IOError:
    pass

if "ghost" != user:
    if 'Windows' == comp:
        nibl_dir = "C:/Users/"+user+"/.config/nibl/"
    else:
        nibl_dir = "/home/"+user+"/.config/nibl/"
    check_dirs(nibl_dir)

hexchat.hook_command("NXF", Main, help="/NXF <cmd>")

hexchat.command("MENU -p5 ADD NIBL")
if os.path.exists(nibl_dir + "xdccfilter"):
    hexchat.command("MENU -t1 ADD \"NIBL/XDCC Filter\" \"nxf on\" \"nxf off\"")
    hexchat.command("nxf on")
else:
    hexchat.command("MENU -t0 ADD \"NIBL/XDCC Filter\" \"nxf on\" \"nxf off\"")
hexchat.command("MENU ADD \"NIBL/XDCC Output\" \"nxf open\"")
