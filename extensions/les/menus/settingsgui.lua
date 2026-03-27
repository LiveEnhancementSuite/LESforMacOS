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
    { key = "enabledebug",           label = "デバッグモード",                 desc = "コンソール・再起動・Hammerspoon フォルダなどのオプションを表示" },
    { key = "checksanity",           label = "バージョン検証",                 desc = "macOS と Ableton Live のサポートバージョンを起動時に確認" },
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
local function buildSettingsHTML()
    -- ── CSS (static, no % escaping needed with concat approach) ──────────
    local css = table.concat({
        "* { box-sizing: border-box; margin: 0; padding: 0; }",
        "body {",
        "  font-family: -apple-system, BlinkMacSystemFont, 'SF Pro Display', sans-serif;",
        "  background: #1c1c1e; color: #e5e5ea;",
        "  font-size: 13px; line-height: 1.4;",
        "}",
        ".header {",
        "  background: #111113; padding: 14px 20px;",
        "  border-bottom: 1px solid #2c2c2e;",
        "  display: flex; align-items: center; justify-content: space-between;",
        "  position: sticky; top: 0; z-index: 100;",
        "}",
        ".header-text h1 { font-size: 15px; font-weight: 600; color: #fff; }",
        ".header-text p  { font-size: 11px; color: #8e8e93; margin-top: 2px; }",
        ".save-btn {",
        "  background: #0a84ff; color: #fff; border: none;",
        "  border-radius: 7px; padding: 7px 16px;",
        "  font-size: 13px; font-weight: 500; cursor: pointer;",
        "  transition: background 0.15s, opacity 0.15s;",
        "  opacity: 0.4; pointer-events: none;",
        "}",
        ".save-btn.dirty { opacity: 1; pointer-events: all; }",
        ".save-btn:hover { background: #0070e0; }",
        ".content { padding: 8px 20px 60px; }",
        ".section-label {",
        "  font-size: 11px; font-weight: 600; color: #8e8e93;",
        "  letter-spacing: 0.6px; text-transform: uppercase;",
        "  padding: 16px 0 6px; border-bottom: 1px solid #2c2c2e; margin-bottom: 2px;",
        "}",
        ".row {",
        "  display: flex; align-items: center; justify-content: space-between;",
        "  padding: 9px 0; border-bottom: 1px solid #2c2c2e; gap: 16px;",
        "}",
        ".row:last-child { border-bottom: none; }",
        ".row-info { flex: 1; min-width: 0; }",
        ".row-label { display: block; font-weight: 500; color: #d1d1d6; }",
        ".row-desc  { display: block; font-size: 11px; color: #636366; margin-top: 1px; }",
        "/* Toggle switch */",
        ".toggle { position: relative; display: inline-block; width: 42px; height: 24px; flex-shrink: 0; }",
        ".toggle input { opacity: 0; width: 0; height: 0; }",
        ".knob {",
        "  position: absolute; inset: 0; background: #3a3a3c;",
        "  border-radius: 24px; transition: background 0.2s; cursor: pointer;",
        "}",
        ".knob::before {",
        "  content: ''; position: absolute;",
        "  width: 18px; height: 18px; left: 3px; bottom: 3px;",
        "  background: #fff; border-radius: 50%;",
        "  transition: transform 0.2s;",
        "  box-shadow: 0 1px 4px rgba(0,0,0,0.5);",
        "}",
        "input:checked + .knob { background: #30d158; }",
        "input:checked + .knob::before { transform: translateX(18px); }",
        "/* Number / text input */",
        ".field {",
        "  width: 88px; flex-shrink: 0;",
        "  background: #2c2c2e; border: 1px solid #3a3a3c;",
        "  border-radius: 7px; color: #e5e5ea;",
        "  padding: 5px 9px; font-size: 13px; text-align: right;",
        "  -webkit-appearance: textfield; outline: none;",
        "}",
        ".field:focus { border-color: #0a84ff; }",
        ".text-field { text-align: left; }",
        "/* Toast */",
        ".toast {",
        "  position: fixed; bottom: 18px;",
        "  left: 0; right: 0; text-align: center;",
        "  pointer-events: none;",
        "}",
        ".toast span {",
        "  display: inline-block;",
        "  background: #30d158; color: #000;",
        "  padding: 7px 20px; border-radius: 20px;",
        "  font-weight: 600; font-size: 13px;",
        "  opacity: 0; transition: opacity 0.3s;",
        "}",
        ".toast span.show { opacity: 1; }",
    }, "\n")

    -- ── Toggle rows ───────────────────────────────────────────────────────
    local toggleRows = {}
    for _, s in ipairs(TOGGLE_DEFS) do
        local val = 0
        if settingsManager and settingsManager[s.key] then
            val = settingsManager[s.key]["value"] or 0
        end
        local checked = (tonumber(val) == 1) and " checked" or ""
        table.insert(toggleRows, table.concat({
            '<div class="row">',
            '  <div class="row-info">',
            '    <span class="row-label">', s.label, '</span>',
            '    <span class="row-desc">',  s.desc,  '</span>',
            '  </div>',
            '  <label class="toggle">',
            '    <input type="checkbox" data-key="', s.key, '"', checked, ' onchange="markDirty()">',
            '    <span class="knob"></span>',
            '  </label>',
            '</div>',
        }, "\n"))
    end

    -- ── Numeric rows ──────────────────────────────────────────────────────
    local numericRows = {}
    for _, s in ipairs(NUMERIC_DEFS) do
        local val = 0
        if settingsManager and settingsManager[s.key] then
            val = settingsManager[s.key]["value"] or 0
        end
        table.insert(numericRows, table.concat({
            '<div class="row">',
            '  <div class="row-info">',
            '    <span class="row-label">', s.label, '</span>',
            '    <span class="row-desc">',  s.desc,  '</span>',
            '  </div>',
            '  <input type="number" class="field"',
            '    data-key="', s.key, '" value="', tostring(val), '"',
            '    step="', s.step, '" min="', s.min, '" max="', s.max, '"',
            '    oninput="markDirty()">',
            '</div>',
        }, "\n"))
    end

    -- ── Piano roll macro row ──────────────────────────────────────────────
    local macroRaw = getRawPianorollMacro()
    local macroRow = table.concat({
        '<div class="row">',
        '  <div class="row-info">',
        '    <span class="row-label">ピアノロールマクロキー</span>',
        '    <span class="row-desc">ピアノロールマクロのトリガーキー（例: ` や 1 など 1 文字）</span>',
        '  </div>',
        '  <input type="text" class="field text-field" maxlength="1"',
        '    data-key="pianorollmacro" value="', macroRaw, '"',
        '    oninput="markDirty()">',
        '</div>',
    }, "\n")

    -- ── JavaScript ────────────────────────────────────────────────────────
    local js = table.concat({
        "var dirty = false;",
        "function markDirty() {",
        "  dirty = true;",
        "  document.getElementById('saveBtn').classList.add('dirty');",
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
        "  document.getElementById('saveBtn').classList.remove('dirty');",
        "  dirty = false;",
        "  var t = document.getElementById('toast');",
        "  t.classList.add('show');",
        "  setTimeout(function() { t.classList.remove('show'); }, 2000);",
        "}",
    }, "\n")

    -- ── Assemble full document ────────────────────────────────────────────
    return table.concat({
        "<!DOCTYPE html><html><head>",
        "<meta charset='UTF-8'>",
        "<style>", css, "</style>",
        "</head><body>",

        "<div class='header'>",
        "  <div class='header-text'>",
        "    <h1>LES 設定</h1>",
        "    <p>Live Enhancement Suite</p>",
        "  </div>",
        "  <button class='save-btn' id='saveBtn' onclick='saveSettings()'>保存して再起動</button>",
        "</div>",

        "<div class='content'>",
        "  <div class='section-label'>機能トグル</div>",
        table.concat(toggleRows, "\n"),

        "  <div class='section-label'>パフォーマンス・タイミング</div>",
        table.concat(numericRows, "\n"),

        "  <div class='section-label'>入力マッピング</div>",
        macroRow,
        "</div>",

        "<div class='toast'><span id='toast'>保存しました ✓</span></div>",
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
