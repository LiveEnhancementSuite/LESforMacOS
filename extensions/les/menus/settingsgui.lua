--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-----------------------------------------------
--  Settings GUI (hs.webview)                --
--  HTML/CSS-based settings panel            --
--  Replaces manual settings.ini text edit   --
-----------------------------------------------

---@type hs.webview|nil
local settingsWebview = nil
---@type hs.webview.usercontent|nil
local settingsUC = nil

-- Binary settings definition: {key, display label, short description}
local TOGGLE_DEFS = {
    { key = "autoadd",               label = "プラグイン自動追加",          desc = "選択後に自動でトラックへ追加する" },
    { key = "resettobrowserbookmark",label = "ブックマークへリセット",       desc = "追加後にブックマーク位置をクリック（フルスクリーン時のみ）" },
    { key = "disableloop",           label = "MIDIループ無効化",             desc = "Cmd+Shift+M で作成したクリップのループをオフにする" },
    { key = "saveasnewver",          label = "バージョン保存 (Cmd+Alt+S)",   desc = "FL Studio 風の _2, _3 ... 付き新規保存" },
    { key = "altgrmarker",           label = "Alt+L でマーカー追加",         desc = "Shift+L の代わりに Alt+L を使用（大文字入力と競合しない）" },
    { key = "double0todelete",       label = "0×2 で削除",                   desc = "0 キーを素早く 2 回押して Delete を実行" },
    { key = "absolutereplace",       label = "絶対置換ショートカット",        desc = "Ctrl+Alt+D（絶対複製）と Ctrl+Alt+V（絶対貼付け）を有効化" },
    { key = "ctrlabsoluteduplicate", label = "Cmd+Ctrl+D で絶対複製",        desc = "Dock の非表示ショートカットと競合しない代替マッピング" },
    { key = "enableclosewindow",     label = "Ctrl+W でウィンドウを閉じる",  desc = "Ctrl+W / Ctrl+Shift+W を有効化" },
    { key = "vstshortcuts",          label = "VST ショートカット",            desc = "FabFilter Pro-Q 3 など VST 専用の Undo/Redo" },
    { key = "dynamicreload",         label = "動的リロード",                  desc = "メニューを開くたびに menuconfig.ini を再読み込み（重い場合は無効化）" },
    { key = "texticon",              label = "テキストアイコン",               desc = "メニューバーのアイコンを \"LES\" テキストで表示" },
    { key = "addtostartup",          label = "ログイン時に自動起動",           desc = "macOS ログイン時に LES を起動" },
    { key = "launchwithlive",         label = "Live 起動時に自動起動",          desc = "Ableton Live の起動を検知して LES を自動起動（Launch Agent）" },
    { key = "notifyexport",          label = "エクスポート完了通知",            desc = "レンダリング完了時に macOS 通知センターへ通知" },
    { key = "notifyhourly",          label = "1時間ごとの作業時間通知",         desc = "プロジェクトのセッション時間が 1 時間経過するたびに通知" },
    { key = "enabledebug",           label = "デバッグモード",                 desc = "コンソール・再起動・Hammerspoon フォルダなどのオプションを表示" },
    { key = "checksanity",           label = "バージョン検証",                 desc = "macOS と Ableton Live のサポートバージョンを起動時に確認" },
}

-- AI text settings: {key, label, desc, placeholder}
local AI_DEFS = {
    { key = "openaikey",   label = "OpenAI API キー",     desc = "AI 機能で使用する API キー（platform.openai.com/api-keys で取得）", placeholder = "sk-..." },
    { key = "openaimodel", label = "AI モデル",           desc = "使用するモデル名（例: gpt-4o-mini, gpt-4o, gpt-4.1-mini）",         placeholder = "gpt-4o-mini" },
}

-- Numeric settings definition: {key, label, desc, step, min, max}
local NUMERIC_DEFS = {
    { key = "loadspeed",  label = "ロード待機時間（秒）",    desc = "プラグイン検索後に追加するまでの待機秒数（HDDが遅い場合は増やす）",   step = "0.1", min = "0.1", max = "10.0" },
    { key = "bookmarkx",  label = "ブックマーク X 座標（px）", desc = "resettobrowserbookmark のクリック先 X 座標",                          step = "1",   min = "0",   max = "9999" },
    { key = "bookmarky",  label = "ブックマーク Y 座標（px）", desc = "resettobrowserbookmark のクリック先 Y 座標",                          step = "1",   min = "0",   max = "9999" },
}

-- Read the raw (pre-parse) pianorollmacro character from settings.ini
local function getRawPianorollMacro()
    local lines = {}
    local ok = pcall(function() fileToTable("settings.ini", lines) end)
    if not ok then return "`" end
    for _, line in ipairs(lines) do
        if type(line) == "string"
           and line:find("pianorollmacro")
           and line:find("=")
           and not line:find("^%s*;")
        then
            local val = line:match("=%s*(.*)")
            if val then
                return val:match("^%s*(.-)%s*$") or "`"
            end
        end
    end
    return "`"
end

-- Build the complete HTML document for the settings panel.
-- Uses pre-compiled Tailwind-equivalent utilities (offline, no CDN).
local function buildSettingsHTML()
    -- ── Load bundled CSS from assets ────────────────────────────────────
    local cssPath = BundleResourcePath .. "/assets/settings-tw.css"
    local css = ""
    local f = io.open(cssPath, "r")
    if f then
        css = f:read("*a")
        f:close()
    end

    -- ── Toggle rows ─────────────────────────────────────────────────────
    local toggleRows = {}
    for _, s in ipairs(TOGGLE_DEFS) do
        local val = 0
        if settingsManager and settingsManager[s.key] then
            val = settingsManager[s.key]["value"] or 0
        end
        local checked = (tonumber(val) == 1) and " checked" or ""
        table.insert(toggleRows, table.concat({
            '<div class="flex items-center justify-between py-2.5 border-b border-surface-border gap-4 last:border-b-0">',
            '  <div class="flex-1 min-w-0">',
            '    <span class="block font-medium text-label">', s.label, '</span>',
            '    <span class="block text-[11px] text-label-dim mt-px">', s.desc, '</span>',
            '  </div>',
            '  <label class="relative inline-block w-[42px] h-6 shrink-0">',
            '    <input type="checkbox" class="opacity-0 w-0 h-0" data-key="', s.key, '"', checked, ' onchange="markDirty()">',
            '    <span class="toggle-knob absolute inset-0 bg-surface-hover rounded-full cursor-pointer transition-colors duration-200"></span>',
            '  </label>',
            '</div>',
        }, "\n"))
    end

    -- ── Numeric rows ────────────────────────────────────────────────────
    local numericRows = {}
    for _, s in ipairs(NUMERIC_DEFS) do
        local val = 0
        if settingsManager and settingsManager[s.key] then
            val = settingsManager[s.key]["value"] or 0
        end
        table.insert(numericRows, table.concat({
            '<div class="flex items-center justify-between py-2.5 border-b border-surface-border gap-4 last:border-b-0">',
            '  <div class="flex-1 min-w-0">',
            '    <span class="block font-medium text-label">', s.label, '</span>',
            '    <span class="block text-[11px] text-label-dim mt-px">', s.desc, '</span>',
            '  </div>',
            '  <input type="number"',
            '    class="w-[88px] shrink-0 bg-input-bg border border-input-border rounded-lg text-[#e5e5ea] px-2.5 py-1.5 text-[13px] text-right appearance-textfield outline-none focus:border-accent"',
            '    data-key="', s.key, '" value="', tostring(val), '"',
            '    step="', s.step, '" min="', s.min, '" max="', s.max, '"',
            '    oninput="markDirty()">',
            '</div>',
        }, "\n"))
    end

    -- ── Piano roll macro row ────────────────────────────────────────────
    local macroRaw = getRawPianorollMacro()
    local macroRow = table.concat({
        '<div class="flex items-center justify-between py-2.5 border-b border-surface-border gap-4 last:border-b-0">',
        '  <div class="flex-1 min-w-0">',
        '    <span class="block font-medium text-label">ピアノロールマクロキー</span>',
        '    <span class="block text-[11px] text-label-dim mt-px">ピアノロールマクロのトリガーキー（例: ` や 1 など 1 文字）</span>',
        '  </div>',
        '  <input type="text" maxlength="1"',
        '    class="w-[88px] shrink-0 bg-input-bg border border-input-border rounded-lg text-[#e5e5ea] px-2.5 py-1.5 text-[13px] text-left outline-none focus:border-accent"',
        '    data-key="pianorollmacro" value="', macroRaw, '"',
        '    oninput="markDirty()">',
        '</div>',
    }, "\n")

    -- ── AI settings rows ──────────────────────────────────────────────────
    local aiRows = {}
    for _, s in ipairs(AI_DEFS) do
        local val = ""
        if settingsManager and settingsManager[s.key] then
            val = settingsManager[s.key]["value"] or ""
        end
        local inputType = (s.key == "openaikey") and "password" or "text"
        table.insert(aiRows, table.concat({
            '<div class="flex items-center justify-between py-2.5 border-b border-surface-border gap-4 last:border-b-0">',
            '  <div class="flex-1 min-w-0">',
            '    <span class="block font-medium text-label">', s.label, '</span>',
            '    <span class="block text-[11px] text-label-dim mt-px">', s.desc, '</span>',
            '  </div>',
            '  <input type="', inputType, '"',
            '    class="w-[200px] shrink-0 bg-input-bg border border-input-border rounded-lg text-[#e5e5ea] px-2.5 py-1.5 text-[13px] outline-none focus:border-accent"',
            '    data-key="', s.key, '" value="', tostring(val), '"',
            '    placeholder="', s.placeholder, '"',
            '    oninput="markDirty()">',
            '</div>',
        }, "\n"))
    end

    -- ── JavaScript ──────────────────────────────────────────────────────
    local js = table.concat({
        "var dirty = false;",
        "function markDirty() {",
        "  dirty = true;",
        "  var btn = document.getElementById('saveBtn');",
        "  btn.classList.remove('opacity-40', 'pointer-events-none');",
        "  btn.classList.add('opacity-100', 'cursor-pointer');",
        "}",
        "function saveSettings() {",
        "  var settings = {};",
        "  document.querySelectorAll('[data-key]').forEach(function(el) {",
        "    if (el.type === 'checkbox') {",
        "      settings[el.dataset.key] = el.checked ? '1' : '0';",
        "    } else {",
        "      settings[el.dataset.key] = el.value;",
        "    }",
        "  });",
        "  window.webkit.messageHandlers.lesmessages.postMessage({action:'save', data:settings});",
        "  var btn = document.getElementById('saveBtn');",
        "  btn.classList.add('opacity-40', 'pointer-events-none');",
        "  btn.classList.remove('opacity-100', 'cursor-pointer');",
        "  dirty = false;",
        "  var t = document.getElementById('toast');",
        "  t.classList.remove('opacity-0');",
        "  t.classList.add('opacity-100');",
        "  setTimeout(function() { t.classList.remove('opacity-100'); t.classList.add('opacity-0'); }, 2000);",
        "}",
    }, "\n")

    -- ── Assemble full document ──────────────────────────────────────────
    return table.concat({
        "<!DOCTYPE html><html><head>",
        "<meta charset='UTF-8'>",
        "<style>", css, "</style>",
        "</head>",
        "<body class='bg-surface text-[#e5e5ea] text-[13px] leading-snug font-[-apple-system,BlinkMacSystemFont,sans-serif]'>",

        "<div class='sticky top-0 z-50 bg-surface-header border-b border-surface-border flex items-center justify-between px-5 py-3.5'>",
        "  <div>",
        "    <h1 class='text-[15px] font-semibold text-white'>LES 設定</h1>",
        "    <p class='text-[11px] text-label-muted mt-0.5'>Live Enhancement Suite Custom</p>",
        "  </div>",
        "  <button id='saveBtn' onclick='saveSettings()'",
        "    class='bg-accent text-white border-none rounded-lg px-4 py-1.5 text-[13px] font-medium transition-all duration-150 opacity-40 pointer-events-none hover:bg-accent-hover'>",
        "    保存して再起動",
        "  </button>",
        "</div>",

        "<div class='px-5 pt-2 pb-16'>",
        "  <div class='text-[11px] font-semibold text-label-muted tracking-wider uppercase pt-4 pb-1.5 border-b border-surface-border mb-0.5'>機能トグル</div>",
        table.concat(toggleRows, "\n"),

        "  <div class='text-[11px] font-semibold text-label-muted tracking-wider uppercase pt-4 pb-1.5 border-b border-surface-border mb-0.5'>パフォーマンス・タイミング</div>",
        table.concat(numericRows, "\n"),

        "  <div class='text-[11px] font-semibold text-label-muted tracking-wider uppercase pt-4 pb-1.5 border-b border-surface-border mb-0.5'>入力マッピング</div>",
        macroRow,

        "  <div class='text-[11px] font-semibold text-label-muted tracking-wider uppercase pt-4 pb-1.5 border-b border-surface-border mb-0.5'>AI 設定</div>",
        table.concat(aiRows, "\n"),
        "</div>",

        "<div class='fixed bottom-5 left-0 right-0 text-center pointer-events-none'>",
        "  <span id='toast' class='inline-block bg-accent-green text-black px-5 py-1.5 rounded-full font-semibold text-[13px] opacity-0 transition-opacity duration-300'>保存しました</span>",
        "</div>",

        "<script>", js, "</script>",
        "</body></html>",
    }, "\n")
end

--- Open the settings GUI webview panel.
--- Saves via settingsManager:writeVal() then calls reloadLES().
function openSettingsGUI()
    -- Destroy any previous instance
    if settingsWebview ~= nil then
        settingsWebview:delete()
        settingsWebview = nil
    end
    if settingsUC ~= nil then
        settingsUC = nil
    end

    -- Set up JS→Lua message bridge
    settingsUC = hs.webview.usercontent.new("lesmessages")
    settingsUC:setCallback(function(msg)
        if type(msg) ~= "table" or type(msg.body) ~= "table" then return end
        if msg.body.action == "save" then
            local data = msg.body.data
            if type(data) ~= "table" then return end
            for key, val in pairs(data) do
                if settingsManager and settingsManager[key] ~= nil and type(settingsManager[key]) == "table" then
                    settingsManager:writeVal(key, val)
                end
            end
            -- Close and reload after a short delay so the toast is visible
            hs.timer.doAfter(0.6, function()
                if settingsWebview ~= nil then
                    settingsWebview:delete()
                    settingsWebview = nil
                end
                reloadLES()
            end)
        end
    end)

    -- Center on main screen
    local screen = hs.screen.mainScreen():frame()
    local w, h   = 520, 640
    local x = screen.x + math.floor((screen.w - w) / 2)
    local y = screen.y + math.floor((screen.h - h) / 2)

    settingsWebview = hs.webview.new(
        {x = x, y = y, w = w, h = h},
        {developerExtrasEnabled = false},
        settingsUC
    )
    settingsWebview:windowStyle({"titled", "closable", "resizable"})
    settingsWebview:windowTitle("LES 設定")
    settingsWebview:allowTextEntry(true)
    settingsWebview:html(buildSettingsHTML())
    settingsWebview:show()
    settingsWebview:bringToFront()
end
