--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

require("globals.constants")
require("globals.filenames")
require("util.string")

-- File operation functions using native Lua I/O and Hammerspoon APIs
-- instead of shelling out to zsh.

--- ShellExec is retained for commands that have no pure-Lua equivalent
--- (e.g. launchctl, open, sw_vers). Prefer the specific helpers below
--- for file operations.
---@param command string  Shell command to execute
---@return {command: string, stdout: string, ["return"]: number}
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

---@param source string  Source file path
---@param destination string  Destination file path (or directory with trailing /)
function ShellCopy(source, destination)
    -- If destination ends with /, append the source filename
    local dest = destination
    if dest:sub(-1) == PATH_DELIMITER then
        local filename = source:match("[^/]+$")
        if filename then
            dest = dest .. filename
        end
    end

    local srcFile = io.open(source, "rb")
    if srcFile == nil then
        print("ShellCopy(): failed to open source: " .. source)
        return
    end
    local content = srcFile:read("*a")
    srcFile:close()

    local dstFile = io.open(dest, "wb")
    if dstFile == nil then
        print("ShellCopy(): failed to open destination: " .. dest)
        return
    end
    dstFile:write(content)
    dstFile:close()
    print("ShellCopy(): copied " .. source .. " -> " .. dest)
end

-- Recursive copy using hs.fs for directory traversal and pure Lua I/O
function ShellRecursiveCopy(source, destination)
    local attrs = hs.fs.attributes(source)
    if attrs == nil then
        print("ShellRecursiveCopy(): source does not exist: " .. source)
        return
    end

    if attrs.mode == "file" then
        -- Single file copy
        ShellCopy(source, destination)
        return
    end

    if attrs.mode == "directory" then
        -- Ensure destination directory exists
        ShellCreateDirectory(destination)

        -- Iterate directory entries
        for entry in hs.fs.dir(source) do
            if entry ~= "." and entry ~= ".." then
                local srcPath = source .. PATH_DELIMITER .. entry
                local dstPath = destination .. PATH_DELIMITER .. entry
                ShellRecursiveCopy(srcPath, dstPath)
            end
        end
        print("ShellRecursiveCopy(): copied " .. source .. " -> " .. destination)
    end
end

-- Create directory (and parents) using hs.fs
function ShellCreateDirectory(destination)
    -- hs.fs.mkdir only creates one level, so we use a helper
    -- to create parent directories
    local function mkdirp(path)
        -- Check if directory already exists
        local attrs = hs.fs.attributes(path)
        if attrs and attrs.mode == "directory" then
            return true
        end
        -- Try to create parent first
        local parent = path:match("^(.+)/[^/]+$")
        if parent then
            mkdirp(parent)
        end
        return hs.fs.mkdir(path)
    end
    local result = mkdirp(destination)
    print("ShellCreateDirectory(): " .. destination .. " -> " .. tostring(result))
end

-- Overwrite file contents using Lua I/O
function ShellOverwriteFile(contents, destination)
    local f = io.open(destination, "w")
    if f == nil then
        print("ShellOverwriteFile(): failed to open: " .. destination)
        return
    end
    f:write(tostring(contents))
    f:close()
    print("ShellOverwriteFile(): wrote to " .. destination)
end

-- Append to file using Lua I/O
function ShellConcatenateFile(contents, destination)
    local f = io.open(destination, "a")
    if f == nil then
        print("ShellConcatenateFile(): failed to open: " .. destination)
        return
    end
    f:write(tostring(contents))
    f:close()
    print("ShellConcatenateFile(): appended to " .. destination)
end

-- Create empty file using Lua I/O
function ShellCreateEmptyFile(destination)
    local f = io.open(destination, "w")
    if f == nil then
        print("ShellCreateEmptyFile(): failed to create: " .. destination)
        return
    end
    f:close()
    print("ShellCreateEmptyFile(): created " .. destination)
end

-- Delete file using os.remove (works for files; directories must be empty)
function ShellDeleteFile(destination)
    local attrs = hs.fs.attributes(destination)
    if attrs == nil then
        print("ShellDeleteFile(): does not exist: " .. destination)
        return
    end
    if attrs.mode == "directory" then
        -- For directories, use hs.fs.rmdir or fall back to shell for -rf
        local ok = hs.fs.rmdir(destination)
        if not ok then
            -- Non-empty directory: fall back to shell rm -rf
            ShellExec("rm -rf " .. strQuote(destination))
        end
    else
        local ok, err = os.remove(destination)
        if not ok then
            print("ShellDeleteFile(): failed to delete " .. destination .. ": " .. tostring(err))
        else
            print("ShellDeleteFile(): deleted " .. destination)
        end
    end
end

-- Open a file with a specific application
function ShellNSOpen(filename, application)
    -- hs.application.launchOrFocus won't open a file,
    -- so we use os.execute with open
    os.execute("open " .. strQuote(filename) .. " -a " .. strQuote(application))
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
    local message = strMultiLineTrim(message)
    --
    hs.application.get(programName):activate()
    if blocking == true then
        hs.dialog.blockAlert(title, message, "Ok", "", style)
    else
        -- hs.dialog.alert is special, it requires you to specify placement
        -- coordinates which is annoying, so we need to know the size of our
        -- display before issue our dialog. It's center-ish.
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
function HSMakeQuery(title, message, style)
    --
    local style = style or "informational"
    local message = strMultiLineTrim(message)
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
  local message = strMultiLineTrim(message)
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
