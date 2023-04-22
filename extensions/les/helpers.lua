require("globals.constants")

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
    local result = os.execute(
        [[/bin/zsh -c ']] .. command .. [[']]
    )
    print("Executed shell command " .. command .. " with return status " .. tostring(result))
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

function ShellNSOpen(filename)
    ShellExec("open " .. QuoteString(filename))
end

function ShellNSOpen(filename, application)
    ShellExec("open " .. QuoteString(filename) .. " -a " .. QuoteString(application))
end

-- Functions that interface with Hammerspoon
-- but exist only to reduce repetition
function HSPlayAudioFile(filepath)
    local soundobj = hs.sound.getByFile(filepath)
    soundobj:device(nil)
    soundobj:loopSound(false)
    soundobj:play()
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
    hs.application.get(ProgramName):activate()
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
