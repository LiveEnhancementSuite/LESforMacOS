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