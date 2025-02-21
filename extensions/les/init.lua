console = hs.appfinder.windowFromWindowTitle("Hammerspoon Console")
if console then console:close() end -- attempts to close the console if it's up
hs.dockIcon(true) -- enables the dock icon while initializing
currentdir = hs.fs.currentDir()
print(currentdir)
hs.menuIcon(false)
hs.automaticallyCheckForUpdates(false) -- don't update hammerspoon and undo all my changes, please!
hs.uploadCrashData(false)
hs.openConsoleOnDockClick(true)

bundlePath = hs.processInfo["bundlePath"]

if bundlePath == "/Applications/Live Enhancement Suite.app" then
  print("hammerspoon is in applications dir")
else
  hs.osascript.applescript([[tell application "System Events" to display dialog "Error: LES was not detected in the Applications folder." & return & "Please move the LES app to the Applications folder." buttons {"Ok"} default button "Ok" with title "Live Enhancement Suite" with icon POSIX file "/Applications/Live Enhancement Suite.app/Contents/Resources/AppIcon.icns"]])
  os.exit()
end

if hs.accessibilityState() == false then -- testing if hammerspoon has accessibility access.
  hs.osascript.applescript([[tell application "System Events" to display dialog "Accessibility access is disabled which prevents LES from working properly." & return & "Please turn on accessibility access in" & return & "Preferences > Security & Privacy > Privacy > Accessibility, and try again." buttons {"Ok"} default button "Ok" with title "Live Enhancement Suite" with icon POSIX file "/Applications/Live Enhancement Suite.app/Contents/Resources/AppIcon.icns"]])
  os.execute([[open /System/Library/PreferencePanes/Security.prefPane]])
  os.exit()
end

dofile(bundlePath .. [[/Contents/Resources/extensions/hs/les/LESmain.lua]])