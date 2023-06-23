--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("helpers")
require("proccom")
require("globals.constants")
require("globals.filepaths")

-- TODO: Make them "global" within an app-specific context
--       We should try and do away with _true_ globals as much as we can
function initGlobals()
  function getMacOSVersion()
    function getDots(string)
      local ctr = 0
      for idx in string:gmatch('[.]') do
        ctr = ctr + 1
      end
      return ctr
    end
    local stdout = tostring(ShellExec("sw_vers -productVersion")["stdout"])
    while getDots(stdout) > 1 do
      stdout = stdout:sub(1, -2)
    end
    return tonumber(stdout)
  end
  _G.macOSVersion = getMacOSVersion()
end

function initModule()
  -- Initialize global values that are unlikely to change
  -- during the entire course of runtime
  initGlobals()

  -- Setup Hammerspoon
  hs.dockIcon(true)
  hs.menuIcon(false)
  hs.uploadCrashData(false)
  hs.openConsoleOnDockClick(true)
  hs.automaticallyCheckForUpdates(false)

  -- Pre-initialization sanity check
  if hs.processInfo["bundleID"] ~= programBundle then
    panicExit(string.format("initModule(): %s has incorrect bundleID %s", programName, programBundle))
  end

  -- Close all open windows of the application
  local selfApp = hs.application.find(programBundle)
  if selfApp == nil then
    panicExit(string.format("initModule(): %s has incorrect bundleID %s", programName, programBundle))
  else
    local selfWindows = selfApp:allWindows()
    if selfWindows ~= nil then
      for key, val in pairs(selfWindows) do
        val:close()
      end
    end
  end

  -- Check if we are using a validated version of macOS
  function pushVersionFailAlert(progName, minVer, maxVer, curVer)
    HSMakeAlert(programName, string.format([[
      %s is only validated to run between %s and %s and is currently being run on %s.

      The program may behave in an undefined manner and may cause disruption but will continue running until prompted to exit.

      If you believe this is in error or that the program must be updated to support a newer release of %s, please file an issue at %s.
    ]], programName, minVer, maxVer, curVer, progName, programBugTracker), true, "critical")
  end
  if macOSVersion == nil
     or macOSVersion < programMinTarget
     or programMaxTarget + 0.99 < macOSVersion
  then
    pushVersionFailAlert(
      "macOS",
      string.format("macOS %d", programMinTarget),
      string.format("macOS %d", programMaxTarget),
      (function()
        if macOSVersion == nil then
          return "an unknown version of macOS"
        else
          return string.format("macOS %s", macOSVersion)
        end
      end)())
  else
    print(string.format("initModule(): %s is running on macOS %s", programName, macOSVersion))
  end

  -- Check if we have a supported version of Ableton Live
  -- We only care about the _major_ version
  local liveVersion = nil
  local liveObj = getLiveHsAppObj()

  if liveObj ~= nil then
    -- The person could be running the Live bundle from a non-standard directory
    -- but we grant benefit of the doubt to an already running instance
    liveVersion = getLiveVersionFromPath(liveObj:path())
    if liveVersion == nil
       or liveVersion < targetMinVersion
       or targetMaxVersion < liveVersion
    then
      pushVersionFailAlert(
        "Live",
        string.format("Live %d", targetMinVersion),
        string.format("Live %d", targetMaxVersion),
        (function()
          if liveVersion == nil then
            return "an unknown version of Live"
          else
            return string.format("Live %d", liveVersion)
          end
        end)()
      )
    else
      print(string.format("initModule(): Detected Live %d is already running", liveVersion))
    end
  else
    -- There isn't a running instance of Live, so we have to now go seek it out.
    -- We will only check /Applications as searching the entire system is obtrusive
    -- and unnecessary for a basic sanity check.
    local foundValidLiveVersion = false
    for idx=1,20 do
      local pathString = string.format([[/Applications/Ableton Live %d Suite.app/Contents/MacOS/Live]], idx)
      if ShellExec(string.format([[ls "%s"]], pathString))["return"] == 0 then
        liveVersion = idx
        foundValidLiveVersion = liveVersion <= targetMinVersion or liveVersion >= targetMaxVersion
      end
      if foundValidLiveVersion == true then
        break
      end
    end
    if foundValidLiveVersion == false then
      pushVersionFailAlert(
        "Live",
        string.format("Live %d", targetMinVersion),
        string.format("Live %d", targetMaxVersion),
        (function()
          if liveVersion == nil then
            return "an unknown version of Live (or is not installed at all)"
          else
            return string.format("Live %d", liveVersion)
          end
        end)()
      )
    else
      print(string.format("initModule(): Detected Live %d installation at /Applications/Ableton Live %d Suite.app",
                          liveVersion, liveVersion))
    end
  end

  -- Testing if accessibility permissions have been granted
  if hs.accessibilityState() == false then
    -- Attempt at mitigating https://github.com/Hammerspoon/hammerspoon/issues/3301
    ShellExec(string.format("tccutil reset Accessibility %s", programBundle))

    -- macOS Ventura has introduced an *i n n o v a t i v e* redesign
    -- of the System Preferences (now called "System Settings") app
    -- It's broken a few things. We need to catch up. It just works (right?) :3
    local asyNavPath = nil
    if macOSVersion > 12 then
      asyNavPath = "System Settings > Privacy & Security > Accessibility"
    else
      asyNavPath = "System Preferences > Security & Privacy > Privacy > Accessibility"
    end

    HSMakeAlert(
      programName,
      string.format([[
        Please grant accessibility permissions by navigating to %s and enabling it for "%s".

        If it isn't already present, please drag and drop the application to the allowlist.
      ]], programName, asyNavPath, programName),
      true, "critical"
    )

    -- Yes, there's more *i n n o v a t i o n* done here, the older method of
    -- calling the Accessibility menu has been broken
    --
    -- You'll be greeted with "AppleEvent handler failed. number -10000" without
    -- the fix
    if macOSVersion > 12 then
      os.execute("open x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    else
      hs.osascript.applescript([[
        tell application "System Preferences"
          reveal anchor "Privacy_Accessibility" of pane id "com.apple.preference.security"
          activate
        end tell
      ]])
    end

    -- Terminate the program
    os.exit()
  end

  -- Upgrade from previous version
  function setCurVersion()
    ShellOverwriteFile(programVersion, JoinPaths(ScriptUserResourcesPath, VersionFile))
  end

  function testCurVersion()
    local filepath = GetDataPath("resources/version.txt")
    local filehandle = io.open(filepath, "r")
    if filehandle ~= nil then
      local versionarr = {}
      for line in filehandle:lines() do
        table.insert(versionarr, line);
      end
      io.close(filehandle)
      for i = 1, 1, 1 do
        return string.match(versionarr[i], programVersion) ~= nil
      end
    else
      setCurVersion()
      return true
    end
    return false
  end

  if testCurVersion() == false then
    ShellCopy(JoinPaths(BundleResourcePath, "jumpstart.lua"), GetDataPath("init.lua"))
    setCurVersion()
    print("initModule(): upgraded init.lua present in home directory")
    hs.reload()
  end
end
