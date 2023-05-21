--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")
require("globals.filenames")

-- Generic string manipulation helper functions
function QuoteString(string)
    return [["]] .. string .. [["]]
end

-- Platform specific constants
PathDelimiter = "/"
ArgumentDelimiter = " "

function JoinPaths(str1, str2)
    return str1 .. PathDelimiter .. str2
end

function JoinArguments (str1, str2)
    return str1 .. ArgumentDelimiter .. str2
end

-- Functions that leverage the zsh shell interpreter
--
-- TODO: Replace these with Lua alternatives
--       and eventually scrap our reliance on
--       the shell altogether
function ShellExec(command)
    local handle = io.popen(
        [[/bin/zsh -c ']] .. command .. [[']]
    )
    local result = handle:read("*a")
    local _return = {handle:close()}
    print("Executed shell command " .. command .. " with return status " .. tostring(_return[3]))
    return {
      ["command"] = command,
      ["stdout"] = result,
      ["return"] = tonumber(_return[3])
    }
end

function ShellCopy(source, destination)
    ShellExec(
        "cp " .. JoinArguments(QuoteString(source), QuoteString(destination))
    )
end

function ShellRecursiveCopy(source, destination)
    ShellExec(
        "cp -R " .. JoinArguments(QuoteString(source), QuoteString(destination))
    )
end

function ShellCreateDirectory(destination)
    ShellExec("mkdir -p "  .. QuoteString(destination))
end

function ShellOverwriteFile(contents, destination)
    ShellExec("echo " .. QuoteString(contents) .. " > " .. QuoteString(destination))
end

function ShellConcatenateFile(contents, destination)
    ShellExec("echo " .. QuoteString(contents) .. " >> " .. QuoteString(destination))
end

function ShellCreateEmptyFile(destination)
    ShellExec("touch " .. QuoteString(destination))
end

function ShellDeleteFile(destination)
    ShellExec("rm -rf " .. QuoteString(destination))
end

function ShellNSOpen(filename, application)
    ShellExec("open " .. QuoteString(filename) .. " -a " .. QuoteString(application))
end

-- Uses AppleScript to sleep for %duration% seconds
-- TODO: Try to find a non-AppleScript way to do this.
--       I've tried using hs.timer.usleep, os.execute'ing
--       /bin/sleep and trying a "pure Lua" function to
--       no avail.
--
--       Refactoring the code to use hs.timer.doAfter is non-trivial
function astSleep(duration)
    return hs.osascript.applescript(
      string.format([[delay %f]], tonumber(duration))
    )
end

-- Make an alert that displays a message with only acknowledgement as a reply (Ok)
-- Program execution _may_ be stalled if necessary
--
function HSMakeAlert(title, message, blocking, style)
    --
    local blocking = blocking or false
    local style = style or "informational"
    --
    hs.application.get(programName):activate()
    if blocking == true then
        hs.dialog.blockAlert(title, message, "Ok", "", style)
    else
        -- hs.dialog.alert is special, it requires you to specify placement
        -- coordinates which is annoying, so we need to know the size of our
        -- display before issue our dialog. It's center-ish.
        --
        -- TODO: maybe we should know this beforehand so we don't have to query
        -- it every time
        --
        local screen = hs.screen.mainScreen():currentMode()
        hs.dialog.alert(
            (screen["w"] / 2), (screen["h"] / 4),
            function() end, title, message, "Ok", nil, style
        )
    end
end

-- Make an alert that requires an affirmative decision (Yes/No)
-- Program execution _will_ be stalled
--
-- TODO: add functionality that allows setting the default button position
--
function HSMakeQuery(title, message, style)
    --
    local style = style or "informational"
    --
    return hs.dialog.blockAlert(title, message, "Yes", "No") == "Yes"
end

-- Currently there isn't equivalent functionality within Hammerspoon
-- to block an application's ability to accept an input unless the
-- dialog box is attended to.
--
-- So, we're still using AppleScript...
--
function astBlockingQuery(title, message)
  -- TODO: Come up with more elegant cleanup logic
  local _argCleanup = function(input)
    return
    string.gsub(
        string.gsub(input,
            [["]], [[\"]]               -- We must escape common special characters ourselves
        ), [[\n]], [[" & return & "]]   -- Newlines the way AppleScript wants them
    )
  end
  local b, t, o = hs.osascript.applescript(
      string.format(
          [[tell application "Live" to display dialog "%s" buttons {"Yes", "No"} default button "No" with title "%s"]],
          _argCleanup(message), _argCleanup(title)
      )
  )
  return o == [[{ 'bhit':'utxt'("Yes") }]]
end

-- Functions that interface with Hammerspoon
-- but exist only to reduce repetition
function HSPlayAudioFile(filepath, message)
    local message = message or nil
    local soundobj = hs.sound.getByFile(filepath)
    soundobj:device(nil)
    soundobj:loopSound(false)
    soundobj:play()
    if message ~= nil and type(message) == "string" then
        hs.timer.doAfter(
            math.ceil(soundobj:duration()),
            function() HSMakeAlert(programName, message) end
        )
    end
end

-- Exit application if there is an unrecoverable error
-- TODO: Find a better way to terminate an application if there's
--       major screwups, this'll do for now.
function panicExit(reason, fn)
  fn = fn or nil
  HSMakeAlert(programName, string.format([[
    Live Enhancement Suite has suffered a fatal error

    %s
  ]], reason), true, "critical")
  -- Allow us to sneak in a something before we say goodbye
  if type(fn) == "function" then fn() end
  os.exit()
end
