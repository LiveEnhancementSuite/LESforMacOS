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
---@type hs.timer|nil
local pendingReloadTimer = nil

-- Distinct marker the GUI puts in the openaikey input when the user clicks '削除'.
-- It can never collide with a real OpenAI key (those start with 'sk-' and never
-- contain '__'). collectGuiPatchFromData() maps it to the '未設定' default sentinel.
local CLEAR_OPENAIKEY_MARKER = "__CLEAR_OPENAIKEY__"

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
    local ok = pcall(function() fileToTable(GetDataPath(ConfigFile), lines) end)
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

--- Escape for use inside double-quoted HTML attributes (settings values, macro key).
---@param str string|number|nil
---@return string
local function escapeHtmlAttr(str)
    return (tostring(str or ""):gsub("&", "&amp;"):gsub('"', "&quot;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
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
        '    data-key="pianorollmacro" value="', escapeHtmlAttr(macroRaw), '"',
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
        -- '未設定' sentinel must never reach the DOM; display it (and an unconfigured key) as empty.
        if tostring(val) == "未設定" then
            val = ""
        end
        local inputClass =
            "w-[200px] shrink-0 bg-input-bg border border-input-border rounded-lg text-[#e5e5ea] px-2.5 py-1.5 text-[13px] outline-none focus:border-accent"
        local renderVal = val
        local placeholder = s.placeholder
        if s.key == "openaikey" then
            -- SECURITY: never emit the real API key into the DOM. Blank field == "keep existing".
            renderVal = ""
            local hasKey = (val ~= nil and val ~= "" and tostring(val) ~= "未設定")
            placeholder = hasKey and "保存済み（変更する場合のみ入力）" or "sk-..."
        end
        -- For the API key, offer a '削除' affordance: a blank field means
        -- "keep existing", so removing the key needs an explicit clear marker.
        local clearBtn = ""
        if s.key == "openaikey" then
            clearBtn = table.concat({
                '    <button type="button"',
                '      class="shrink-0 bg-transparent text-accent-red border border-input-border rounded-lg px-2 py-1.5 text-[12px] cursor-pointer hover:border-accent-red"',
                '      onclick="clearApiKey(this)">削除</button>',
            }, "\n")
        end
        table.insert(aiRows, table.concat({
            '<div class="flex items-center justify-between py-2.5 border-b border-surface-border gap-4 last:border-b-0">',
            '  <div class="flex-1 min-w-0">',
            '    <span class="block font-medium text-label">', s.label, '</span>',
            '    <span class="block text-[11px] text-label-dim mt-px">', s.desc, '</span>',
            '  </div>',
            '  <div class="flex items-center gap-2 shrink-0">',
            '  <input type="text" spellcheck="false" autocomplete="off" autocorrect="off" autocapitalize="off"',
            '    class="', inputClass, '"',
            '    data-key="', s.key, '" value="', escapeHtmlAttr(renderVal), '"',
            '    placeholder="', escapeHtmlAttr(placeholder), '"',
            '    oninput="markDirty()">',
            clearBtn,
            '  </div>',
            '</div>',
        }, "\n"))
    end

    -- ── JavaScript ──────────────────────────────────────────────────────
    -- JSON-encode the clear marker so it is a safe, properly-quoted JS string literal.
    local CLEAR_MARKER_JS = "'__CLEAR_OPENAIKEY__'"
    local okEnc, encMarker = pcall(hs.json.encode, CLEAR_OPENAIKEY_MARKER)
    if okEnc and type(encMarker) == "string" then
        CLEAR_MARKER_JS = encMarker
    end
    local js = table.concat({
        "var dirty = false;",
        "function markDirty() {",
        "  setDirty(true);",
        "}",
        "// '削除' affordance for the API key: a blank field means 'keep existing',",
        "// so clearing the key needs an explicit marker Lua maps to the default sentinel.",
        "function clearApiKey(btn) {",
        "  var el = document.querySelector('[data-key=\"openaikey\"]');",
        "  if (!el) return;",
        "  el.value = " .. CLEAR_MARKER_JS .. ";",
        "  el.placeholder = '削除されます';",
        "  markDirty();",
        "}",
        "function showToast(text, ok) {",
        "  var t = document.getElementById('toast');",
        "  if (!t) return;",
        "  t.textContent = text;",
        "  t.classList.remove('bg-accent-green', 'bg-accent-red', 'text-black', 'text-white');",
        "  if (ok) { t.classList.add('bg-accent-green', 'text-black'); }",
        "  else { t.classList.add('bg-accent-red', 'text-white'); }",
        "  t.classList.remove('opacity-0');",
        "  t.classList.add('opacity-100');",
        "}",
        "function hideToast() {",
        "  var t = document.getElementById('toast');",
        "  if (!t) return;",
        "  t.classList.remove('opacity-100');",
        "  t.classList.add('opacity-0');",
        "}",
        "function setDirty(d) {",
        "  dirty = d;",
        "  var btn = document.getElementById('saveBtn');",
        "  if (!btn) return;",
        "  if (d) {",
        "    btn.classList.remove('opacity-40', 'pointer-events-none');",
        "    btn.classList.add('opacity-100', 'cursor-pointer');",
        "  } else {",
        "    btn.classList.add('opacity-40', 'pointer-events-none');",
        "    btn.classList.remove('opacity-100', 'cursor-pointer');",
        "  }",
        "}",
        "// Called from Lua via evaluateJavaScript once the write outcome is known.",
        "function saveResult(ok, message) {",
        "  // Bump the save token so a real Lua reply cancels any pending watchdog timer.",
        "  window._saveTok = (window._saveTok||0)+1;",
        "  if (ok) {",
        "    showToast(message || '保存しました', true);",
        "    setDirty(false);",
        "  } else {",
        "    showToast(message || '保存に失敗しました', false);",
        "    setDirty(true);",
        "    setTimeout(hideToast, 3000);",
        "  }",
        "}",
        "function saveSettings() {",
        "  var settings = {};",
        "  document.querySelectorAll('[data-key]').forEach(function(el) {",
        "    var k = el.getAttribute('data-key');",
        "    if (!k) return;",
        "    if (el.type === 'checkbox') {",
        "      settings[k] = el.checked ? '1' : '0';",
        "    } else {",
        "      settings[k] = el.value;",
        "    }",
        "  });",
        "  // Always stringify: WKWebView → Lua is most reliable as JSON text (nested dicts can break pairs()/keys).",
        "  window.webkit.messageHandlers.lesmessages.postMessage(JSON.stringify({ action: 'save', data: settings }));",
        "  // Neutral 'saving' state; the Lua callback reports success/failure via saveResult().",
        "  var btn = document.getElementById('saveBtn');",
        "  if (btn) { btn.classList.add('opacity-40', 'pointer-events-none'); btn.classList.remove('opacity-100', 'cursor-pointer'); }",
        "  showToast('保存中...', true);",
        "  // Watchdog: a dropped/garbled WK bridge message must not hang the UI forever.",
        "  // A real Lua reply bumps window._saveTok via saveResult(), which cancels this.",
        "  window._saveTok = (window._saveTok||0)+1; var t = window._saveTok;",
        "  setTimeout(function(){ if (window._saveTok === t) saveResult(false, '保存に失敗しました（応答なし）'); }, 5000);",
        "}",
    }, "\n")

    -- ── Assemble full document ──────────────────────────────────────────
    return table.concat({
        "<!DOCTYPE html><html><head>",
        "<meta charset='UTF-8'>",
        "<style>", css,
        "\n.bg-accent-red { background-color: #ff453a; }",
        "\n.text-accent-red { color: #ff453a; }",
        "\n.hover\\:border-accent-red:hover { border-color: #ff453a; }\n</style>",
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

--- WKWebView may deliver msg.body as a JSON string or a bridged NSDictionary (Lua table).
---@param body any
---@return table|nil
local function decodeWebviewMessageBody(body)
    if type(body) == "table" then
        return body
    end
    if type(body) == "string" then
        local ok, t = pcall(hs.json.decode, body)
        if ok and type(t) == "table" then
            return t
        end
        print("[settingsgui] save: json decode failed, first 240 chars:", (body or ""):sub(1, 240))
        return nil
    end
    print("[settingsgui] save: unexpected message body type:", type(body))
    return nil
end

--- JSON round-trip forces plain Lua tables with string keys (NSDictionary bridges can confuse pairs()).
---@param t table|nil
---@return table|nil
local function canonicalizeWebviewTable(t)
    if type(t) ~= "table" then
        return nil
    end
    local ok, j = pcall(hs.json.encode, t)
    if not ok or type(j) ~= "string" then
        return t
    end
    local ok2, dec = pcall(hs.json.decode, j)
    if ok2 and type(dec) == "table" then
        return dec
    end
    return t
end

--- If `data` arrived as a JSON string (double-encoding), decode to a table.
---@param data any
---@return table|nil
local function normalizeSettingsDataTable(data)
    if type(data) == "table" then
        return data
    end
    if type(data) == "string" then
        local ok, t = pcall(hs.json.decode, data)
        if ok and type(t) == "table" then
            return t
        end
    end
    return nil
end

--- Build the patch map using known GUI keys first (avoids lost keys when WK bridge tables do not iterate).
---@param data table
---@return table<string, string|number|boolean>
local function collectGuiPatchFromData(data)
    if type(data) ~= "table" or not settingsManager then
        return {}
    end
    local canon = canonicalizeWebviewTable(data) or data
    local patch = {}
    local function pullKey(k)
        if type(k) ~= "string" or type(settingsManager[k]) ~= "table" then
            return
        end
        local v = canon[k]
        if v == nil then
            v = data[k]
        end
        if v == nil then
            return
        end
        if k == "openaikey" then
            local trimmed = tostring(v):gsub("^%s*(.-)%s*$", "%1")
            if trimmed == CLEAR_OPENAIKEY_MARKER then
                -- Explicit '削除' click: clear the key by writing the default sentinel.
                patch[k] = "未設定"
                return
            end
            -- Blank/whitespace-only means "keep existing"; '未設定' sentinel must never enter the patch.
            if trimmed == "" or trimmed == "未設定" then
                return
            end
        end
        patch[k] = v
    end
    for _, row in ipairs(TOGGLE_DEFS) do
        pullKey(row.key)
    end
    for _, row in ipairs(NUMERIC_DEFS) do
        pullKey(row.key)
    end
    for _, row in ipairs(AI_DEFS) do
        pullKey(row.key)
    end
    pullKey("pianorollmacro")
    for k in pairs(canon) do
        if type(k) == "string" and type(settingsManager[k]) == "table" and patch[k] == nil then
            -- Route through pullKey so openaikey blank/sentinel handling applies here too.
            pullKey(k)
        end
    end
    return patch
end

--- Report a save outcome back to the webview's JS saveResult() handler.
---@param ok boolean whether the write succeeded
---@param message string|nil toast text to display
---@return nil
local function reportSaveResult(ok, message)
    if settingsWebview == nil then
        return
    end
    local okFlag = ok and "true" or "false"
    -- JSON-encode the message so quotes/newlines cannot break out of the JS string literal.
    local msgJson = "''"
    if message ~= nil then
        local encOk, enc = pcall(hs.json.encode, tostring(message))
        if encOk and type(enc) == "string" then
            msgJson = enc
        end
    end
    local jsCode = "if (typeof saveResult === 'function') { saveResult(" .. okFlag .. ", " .. msgJson .. "); }"
    pcall(function()
        settingsWebview:evaluateJavaScript(jsCode)
    end)
end

--- Open the settings GUI webview panel.
--- Saves via settingsManager:writeFromGui() then calls reloadLES().
function openSettingsGUI()
    -- Cancel any pending teardown so reopening within the reload window is never destroyed.
    if pendingReloadTimer ~= nil then
        pcall(function() pendingReloadTimer:stop() end)
        pendingReloadTimer = nil
    end
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
        if msg == nil then
            return
        end
        local bodyRaw = msg
        if type(msg) == "table" and msg.body ~= nil then
            bodyRaw = msg.body
        end
        local body = decodeWebviewMessageBody(bodyRaw)
        if not body then
            return
        end
        body = canonicalizeWebviewTable(body) or body
        local action = body.action or body.Action
        if tostring(action or "") ~= "save" then
            return
        end
        local rawData = body.data or body.Data
        local data = normalizeSettingsDataTable(rawData)
        if data == nil and type(rawData) == "table" then
            data = rawData
        end
        if type(data) ~= "table" then
            print(
                "[settingsgui] save: body.data missing or not a table (got "
                    .. tostring(type(rawData))
                    .. " / normalized "
                    .. tostring(type(data))
                    .. ")"
            )
            reportSaveResult(false, "保存できませんでした（フォームの値を認識できません）")
            HSMakeAlert(
                programName,
                "設定を保存できませんでした（フォームの値を認識できません）。\nコンソールの [settingsgui] ログを確認してください。",
                true,
                "warning"
            )
            return
        end
        local patch = collectGuiPatchFromData(data)
        local dataKeyCount = 0
        for _ in pairs(data) do
            dataKeyCount = dataKeyCount + 1
        end
        local patchKeys = {}
        for k in pairs(patch) do
            patchKeys[#patchKeys + 1] = k
        end
        table.sort(patchKeys)
        local patchCount = #patchKeys
        print(
            string.format(
                "[settingsgui] save: data keys=%d patch keys=%d patch=%s",
                dataKeyCount,
                patchCount,
                table.concat(patchKeys, ",")
            )
        )
        if settingsManager and next(patch) ~= nil then
            print("[settingsgui] save: calling writeFromGui with", patchCount, "keys")
            local okWrite = settingsManager:writeFromGui(patch)
            if not okWrite then
                -- Report failure to the GUI: red toast, keep dirty=true and the button enabled.
                reportSaveResult(false, "保存に失敗しました（設定ファイルへ書き込めません）")
                HSMakeAlert(
                    programName,
                    "設定ファイルへ書き込めませんでした（権限またはディスク容量を確認してください）。\n"
                        .. "~/.les/settings.ini",
                    true,
                    "critical"
                )
                return
            end
            -- Success: green toast (superseded by the imminent reload).
            reportSaveResult(true, "保存しました")
            -- Apply settings IMMEDIATELY. reloadLES() runs in-VM (it rebuilds config
            -- in-process and does NOT call hs.reload()), so the apply must not depend
            -- on whether the panel is reopened within the cosmetic teardown window.
            pcall(reloadLES)
            pcall(function()
                if hs.notify then
                    hs.notify
                        .new({ title = programName or "LES", informativeText = "設定を保存しました。まもなく再起動します。" })
                        :send()
                end
            end)
            -- Cosmetic teardown only: delete the webview after a short delay so the
            -- toast stays visible. The apply (reloadLES) already happened above.
            if pendingReloadTimer ~= nil then
                pcall(function() pendingReloadTimer:stop() end)
                pendingReloadTimer = nil
            end
            local wv = settingsWebview
            pendingReloadTimer = hs.timer.doAfter(0.6, function()
                pendingReloadTimer = nil
                if wv then
                    pcall(function() wv:delete() end)
                end
                if settingsWebview == wv then
                    settingsWebview = nil
                end
            end)
        else
            -- Empty patch: report failure to the GUI, keep dirty=true and the button enabled.
            reportSaveResult(false, "保存できませんでした（有効な設定キーがありません）")
            HSMakeAlert(
                programName,
                "設定を保存できませんでした（有効な設定キーがありません）。\n"
                    .. "アプリを最新ビルドに更新するか、~/.les/settings.ini を直接編集してください。",
                true,
                "warning"
            )
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
