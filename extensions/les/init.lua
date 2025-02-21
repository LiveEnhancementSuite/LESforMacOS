console = hs.appfinder.windowFromWindowTitle("Hammerspoon Console")
currentdir = hs.fs.currentDir()

if console then
    console:close()
end -- attempts to close the console if it's up
print(currentdir)

-- enables the dock icon while initializing
hs.dockIcon(true)
hs.menuIcon(false)
hs.uploadCrashData(false)
hs.openConsoleOnDockClick(true)
-- don't update hammerspoon and undo all my changes, please!
hs.automaticallyCheckForUpdates(false)

bundlePath = hs.processInfo["bundlePath"]

if hs.accessibilityState() == false then -- testing if hammerspoon has accessibility access.
    hs.osascript.applescript(
        [[tell application "System Events" to display dialog "Accessibility access is disabled which prevents LES from working properly." & return & "Please turn on accessibility access in" & return & "Preferences > Security & Privacy > Privacy > Accessibility, and try again." buttons {"Ok"} default button "Ok" with title "Live Enhancement Suite"]])
    os.execute([[open /System/Library/PreferencePanes/Security.prefPane]])
    os.exit()
end

package.path = package.path .. ";" .. bundlePath .. [[/Contents/Resources/extensions/hs/les/?.lua]]
dofile(bundlePath .. [[/Contents/Resources/extensions/hs/les/LESmain.lua]])
