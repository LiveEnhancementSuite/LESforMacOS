--
-- These globals can be set and accessed:
--
globals = {
    "rawrequire",
}

--
-- These globals can only be accessed:
--
read_globals = {
    "hs",
    "ls",
    "spoon",
}

--
-- LES extension files:
-- These files use many cross-module globals due to the
-- Hammerspoon architecture. Allow known LES globals.
--
files["extensions/les/**/*.lua"] = {
    globals = {
        -- Module system
        "module", "settingsManager",
        -- Helpers and utilities
        "ShellExec", "ShellCopy", "ShellRecursiveCopy",
        "ShellCreateDirectory", "ShellOverwriteFile",
        "ShellConcatenateFile", "ShellCreateEmptyFile",
        "ShellDeleteFile", "ShellNSOpen",
        "astSleep", "astBlockingQuery",
        "HSMakeAlert", "HSMakeQuery", "HSPlayAudioFile",
        "panicExit",
        -- String/IO utilities
        "strJoinArgs", "strJoinPaths", "strMultiLineTrim",
        "strQuote", "strSanitize",
        "fileToTable", "tableToFile", "ioIsFilePresent",
        -- Path globals
        "HomePath", "BundlePath", "ScriptUserPath",
        "ScriptUserResourcesPath", "BundleContentPath",
        "BundleResourcePath", "BundleResourceAssetsPath",
        "BundleIconPath",
        "GetDataPath", "GetUserPath", "GetBundleAssetsPath",
        -- Constants
        "programName", "programBundle", "programVersion",
        "programBugTracker", "programMinTarget", "programMaxTarget",
        "PATH_DELIMITER", "ARGS_DELIMITER",
        "targetName", "targetBundle", "targetMinVersion", "targetMaxVersion",
        -- Filenames
        "AppIcon", "FirstRun", "ConfigFile", "VersionFile",
        "ReadmeJingle", "MenuConfigFile", "StrictTimeModifier",
        "ScriptInitFile",
        -- Process communication
        "isHsAppObjLive", "isLiveFocused", "getLiveVersion",
        "getLiveHsAppObj", "invalidateLiveAppCache",
        "getValidTitles", "getTipValue",
        "_selectLiveMenuItem", "selectLiveMenuItem",
        -- Menu building
        "testmenuconfig", "readme", "buildPluginMenu",
        "clearcategories", "buildMenuBar", "rebuildRcMenu",
        "pluginArray", "pluginMenu", "pianoMenu", "LESmenubar",
        -- Lifecycle
        "reloadLES", "quickreload", "cheats", "cheatmenu",
        "InstallInsertWhere",
        "enablemacros", "disablemacros", "appwatch",
        "dingodango", "appwatcher", "threadsenabled",
        -- Shortcuts
        "directshyper", "buplicate", "buplicatelastshortcut",
        "spawnPluginMenu", "spawnPianoMenu",
        "firstRightClick", "titlebarheight",
        "bookmarkfunc", "loadPlugin",
        "modifierHandler", "keyhandlerevent",
        "timeRMBTime", "firstDown", "secondDown",
        -- VST
        "undo", "redo", "vstshenabled",
        -- Timer/tracking
        "setstricttime", "coolfunc", "timerfunc", "requesttime",
        "clock", "windowfilter", "trackname",
        -- Menu data
        "menu", "ShiftDoubleRightClickMenu", "getMenuBar",
    },
    ignore = {
        "111", -- Setting an undefined global variable
        "112", -- Mutating an undefined global variable
        "113", -- Accessing an undefined global variable
    }
}

--
-- Hammerspoon Tests:
--
files["**/test_*.lua"] = {
    read_globals = {
        "assertFalse",
        "assertGreaterThan",
        "assertGreaterThanOrEqualTo",
        "assertIsAlmostEqual",
        "assertIsBoolean",
        "assertIsEqual",
        "assertIsFunction",
        "assertIsNil",
        "assertIsNotNil",
        "assertIsNumber",
        "assertIsString",
        "assertIsTable",
        "assertIsType",
        "assertIsUserdata",
        "assertIsUserdataOfType",
        "assertLessThan",
        "assertLessThanOrEqualTo",
        "assertListsEqual",
        "assertTableNotEmpty",
        "assertTablesEqual",
        "assertTrue",
        "failure",
        "success",
    },
    ignore = {
        "111", -- Setting an undefined global variable
        "501" -- Line too long
    }
}

--
-- LES test files:
--
files["extensions/les/tests/**/*.lua"] = {
    read_globals = {
        "describe", "it", "pending",
        "before_each", "after_each",
        "setup", "teardown",
        "assert", "spy", "stub", "mock",
    }
}

--
-- Warnings to ignore:
--
ignore = {
    "631" -- Line is too long.
}

-- Maximum line length
max_line_length = 150
