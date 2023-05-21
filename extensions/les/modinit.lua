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

function initModule()
  -- Pre-initialization sanity check
  if hs.processInfo["bundleID"] ~= programBundle then
    panicExit(string.format("initModule(): %s has incorrect bundleID %s", programName, programBundle))
  end

  -- Check if we are using a validated version of macOS
  function pushVersionFailAlert(progName, minVer, maxVer, curVer)
    HSMakeAlert(programName, string.format([[
      %s is only validated to run between %s and %s and is currently being run on %s.

      The program may behave in an undefined manner and may cause disruption but will continue running until prompted to exit.

      If you believe this is in error or that the program must be updated to support a newer release of %s, please file an issue at %s.
    ]], programName, minVer, maxVer, curVer, progName, programBugTracker), true, "critical")
  end
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
  local macOSVersion = getMacOSVersion()
  if macOSVersion == nil
     or macOSVersion < programMinTarget
     or programMaxTarget < macOSVersion
  then
    pushVersionFailAlert(
      "macOS",
      string.format("macOS %.2f", programMinTarget),
      string.format("macOS %d", programMaxTarget - 0.99),
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
end
