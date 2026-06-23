--  SPDX-License-Identifier: MIT
--
--  LES unit tests for helpers.lua
--
--  These tests verify the file operation helpers that replaced
--  the original shell-based implementations.
--
--  Run with: busted extensions/les/tests/
--  Or via Docker: docker build -f Dockerfile.test -t les-test . && docker run --rm les-test

-- Mock hs namespace for standalone testing
local lfs_ok, lfs = pcall(require, "lfs")

local hs_mock = {
    fs = {
        attributes = function(path)
            if lfs_ok then
                local attrs = lfs.attributes(path)
                if attrs then
                    return { mode = attrs.mode }
                end
                return nil
            end
            -- Fallback: try to distinguish files from directories
            local f = io.open(path, "r")
            if f then
                f:close()
                return { mode = "file" }
            end
            -- Check if it's a directory
            local ok = os.execute("test -d '" .. path .. "' 2>/dev/null")
            if ok then
                return { mode = "directory" }
            end
            return nil
        end,
        mkdir = function(path)
            local ok = os.execute("mkdir '" .. path .. "' 2>/dev/null")
            return ok ~= nil
        end,
        rmdir = function(path)
            return os.remove(path) ~= nil
        end,
        symlinkAttributes = function(path)
            if lfs_ok then
                local attrs = lfs.symlinkattributes(path)
                if attrs then
                    return { mode = attrs.mode }
                end
                return nil
            end
            -- Fallback: same as attributes (no symlink distinction without lfs)
            local f = io.open(path, "r")
            if f then
                f:close()
                return { mode = "file" }
            end
            local ok = os.execute("test -d '" .. path .. "' 2>/dev/null")
            if ok then
                return { mode = "directory" }
            end
            return nil
        end,
        dir = function(path)
            if lfs_ok then
                return lfs.dir(path)
            end
            -- Fallback: list entries via `ls -1a` and iterate them.
            local entries = {}
            local handle = io.popen("ls -1a '" .. path .. "' 2>/dev/null")
            if handle then
                for line in handle:lines() do
                    entries[#entries + 1] = line
                end
                handle:close()
            end
            local i = 0
            return function()
                i = i + 1
                return entries[i]
            end
        end,
    }
}

-- Ensure hs is available globally for all require'd modules
rawset(_G, "hs", rawget(_G, "hs") or hs_mock)

-- Load dependencies
package.path = package.path .. ";extensions/les/?.lua"
require("globals.constants")
require("util.string")

describe("String utilities", function()
    describe("strQuote", function()
        it("should wrap string in single quotes", function()
            assert.are.equal("'hello'", strQuote("hello"))
        end)

        it("should handle empty strings", function()
            assert.are.equal("''", strQuote(""))
        end)

        it("should handle paths with spaces", function()
            assert.are.equal("'/path/to/my file'", strQuote("/path/to/my file"))
        end)

        it("should escape embedded single quotes (POSIX safe)", function()
            -- o'brien -> 'o'\''brien' : close quote, escaped quote, reopen quote
            assert.are.equal("'o'\\''brien'", strQuote("o'brien"))
        end)

        it("should coerce non-string input", function()
            assert.are.equal("'123'", strQuote(123))
        end)
    end)

    describe("strJoinPaths", function()
        it("should join two path segments", function()
            assert.are.equal("/home/user/.les/settings.ini",
                strJoinPaths("/home/user/.les", "settings.ini"))
        end)

        it("should use PATH_DELIMITER", function()
            assert.are.equal("a/b", strJoinPaths("a", "b"))
        end)
    end)

    describe("strJoinArgs", function()
        it("should join arguments with space", function()
            assert.are.equal("arg1 arg2", strJoinArgs("arg1", "arg2"))
        end)
    end)

    describe("strSanitize", function()
        it("should remove special characters", function()
            assert.are.equal("HelloWorld", strSanitize("Hello!@#World"))
        end)

        it("should keep spaces and alphanumeric", function()
            assert.are.equal("Hello World 123", strSanitize("Hello World 123"))
        end)

        it("should trim whitespace", function()
            assert.are.equal("hello", strSanitize("  hello  "))
        end)
    end)

    describe("strMultiLineTrim", function()
        it("should trim leading whitespace from each line", function()
            local input = [[
                Hello
                World
            ]]
            local result = strMultiLineTrim(input)
            assert.truthy(result:find("Hello"))
            assert.truthy(result:find("World"))
        end)
    end)
end)

describe("IO utilities", function()
    require("util.io")
    local testDir = os.tmpname() .. "_les_test"
    local testFile = testDir .. "/test.txt"

    setup(function()
        os.execute("mkdir -p " .. testDir)
    end)

    teardown(function()
        os.execute("rm -rf " .. testDir)
    end)

    describe("ioIsFilePresent", function()
        it("should return false for non-existent files", function()
            assert.is_false(ioIsFilePresent(testDir .. "/nonexistent.txt"))
        end)

        it("should return true for existing files", function()
            local f = io.open(testFile, "w")
            f:write("test")
            f:close()
            assert.is_true(ioIsFilePresent(testFile))
        end)
    end)

    describe("fileToTable", function()
        it("should read file lines into table", function()
            local f = io.open(testFile, "w")
            f:write("line1\nline2\nline3\n")
            f:close()

            local result = {}
            fileToTable(testFile, result)
            assert.are.equal(3, #result)
            assert.are.equal("line1", result[1])
            assert.are.equal("line2", result[2])
            assert.are.equal("line3", result[3])
        end)
    end)

    describe("tableToFile", function()
        it("should write table lines to file", function()
            local data = {"alpha", "beta", "gamma"}
            tableToFile(testFile, data)

            local result = {}
            fileToTable(testFile, result)
            assert.are.equal(3, #result)
            assert.are.equal("alpha", result[1])
        end)
    end)
end)

describe("File operation helpers", function()
    require("helpers")
    local testDir = os.tmpname() .. "_les_helpers_test"
    local srcFile = testDir .. "/source.txt"
    local dstFile = testDir .. "/dest.txt"

    setup(function()
        os.execute("mkdir -p " .. testDir)
    end)

    teardown(function()
        os.execute("rm -rf " .. testDir)
    end)

    describe("ShellCreateEmptyFile", function()
        it("should create an empty file", function()
            local path = testDir .. "/empty.txt"
            ShellCreateEmptyFile(path)
            assert.is_true(ioIsFilePresent(path))
        end)
    end)

    describe("ShellOverwriteFile", function()
        it("should write content to file", function()
            ShellOverwriteFile("hello world", dstFile)
            local f = io.open(dstFile, "r")
            local content = f:read("*a")
            f:close()
            assert.are.equal("hello world", content)
        end)

        it("should overwrite existing content", function()
            ShellOverwriteFile("first", dstFile)
            ShellOverwriteFile("second", dstFile)
            local f = io.open(dstFile, "r")
            local content = f:read("*a")
            f:close()
            assert.are.equal("second", content)
        end)
    end)

    describe("ShellConcatenateFile", function()
        it("should append content to file", function()
            ShellOverwriteFile("hello", dstFile)
            ShellConcatenateFile(" world", dstFile)
            local f = io.open(dstFile, "r")
            local content = f:read("*a")
            f:close()
            assert.are.equal("hello world", content)
        end)
    end)

    describe("ShellCopy", function()
        it("should copy file contents", function()
            ShellOverwriteFile("copy test data", srcFile)
            ShellCopy(srcFile, dstFile)
            local f = io.open(dstFile, "r")
            local content = f:read("*a")
            f:close()
            assert.are.equal("copy test data", content)
        end)

        it("should copy to directory with trailing slash", function()
            local subdir = testDir .. "/subdir/"
            os.execute("mkdir -p " .. subdir)
            ShellOverwriteFile("dir copy test", srcFile)
            ShellCopy(srcFile, subdir)
            local f = io.open(subdir .. "source.txt", "r")
            assert.is_not_nil(f)
            local content = f:read("*a")
            f:close()
            assert.are.equal("dir copy test", content)
        end)
    end)

    describe("ShellDeleteFile", function()
        it("should delete a file", function()
            local path = testDir .. "/to_delete.txt"
            ShellCreateEmptyFile(path)
            assert.is_true(ioIsFilePresent(path))
            ShellDeleteFile(path)
            assert.is_false(ioIsFilePresent(path))
        end)

        it("should handle non-existent files gracefully", function()
            assert.has_no.errors(function()
                ShellDeleteFile(testDir .. "/nonexistent_file.txt")
            end)
        end)

        it("should recursively delete a non-empty directory (no shell)", function()
            local nest = testDir .. "/nuke"
            ShellCreateDirectory(nest .. "/inner")
            ShellCreateEmptyFile(nest .. "/a.txt")
            ShellCreateEmptyFile(nest .. "/inner/b.txt")
            assert.is_true(ioIsFilePresent(nest .. "/inner/b.txt"))
            ShellDeleteFile(nest)
            local attrs = hs.fs.attributes(nest)
            assert.is_nil(attrs)
        end)
    end)

    describe("ShellCreateDirectory", function()
        it("should create nested directories", function()
            local deepPath = testDir .. "/a/b/c"
            ShellCreateDirectory(deepPath)
            local attrs = hs.fs.attributes(deepPath)
            assert.is_not_nil(attrs)
            assert.are.equal("directory", attrs.mode)
        end)
    end)
end)
