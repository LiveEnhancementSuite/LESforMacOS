--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-------------------------------------------------
--  Project Notes (Timeline)                   --
--  Per-project notes stored as JSON           --
--  ~/.les/resources/notes/[project].json      --
-------------------------------------------------

local projectnotes = {}

---@type hs.webview|nil
local _webview = nil
---@type hs.webview.usercontent|nil
local _notesUC = nil
-- Track which project is currently open for the webview message handler
local _currentProject = nil
-- AI summary integration (lazy-loaded)
local _openai = nil

local NOTES_DIR = "notes"

--- Full path to the notes directory.
---@return string
local function notesDir()
    return strJoinPaths(ScriptUserResourcesPath, NOTES_DIR)
end

--- Full path to the notes file for a given project.
---@param projectName string
---@return string
local function notesFilePath(projectName)
    local sanitized = (projectName or "unsaved"):gsub("[%p%c]", "_")
    return strJoinPaths(notesDir(), sanitized .. ".json")
end

--- Load notes for a project. Returns an array sorted by timestamp ascending.
---@param projectName string
---@return table
function projectnotes.load(projectName)
    local path = notesFilePath(projectName)
    local f = io.open(path, "r")
    if not f then return {} end
    local raw = f:read("*a")
    f:close()
    if not raw or raw == "" then return {} end
    local ok, data = pcall(hs.json.decode, raw)
    if ok and type(data) == "table" then return data end
    return {}
end

--- Save notes for a project.
---@param projectName string
---@param notes table
function projectnotes.save(projectName, notes)
    ShellCreateDirectory(notesDir())
    local path = notesFilePath(projectName)
    local json = hs.json.encode(notes, true)
    local f = io.open(path, "w")
    if f then
        f:write(json)
        f:close()
    end
end

--- Append a new note entry.
---@param projectName string
---@param text string
function projectnotes.addNote(projectName, text)
    if not text or text:match("^%s*$") then return end
    local notes = projectnotes.load(projectName)
    notes[#notes + 1] = {
        timestamp = math.floor(hs.timer.secondsSinceEpoch()),
        body      = text,
    }
    projectnotes.save(projectName, notes)
end

--- Delete a note identified by its timestamp.
---@param projectName string
---@param timestamp number
function projectnotes.deleteNote(projectName, timestamp)
    if type(timestamp) ~= "number" then return end
    local notes = projectnotes.load(projectName)
    local newNotes = {}
    for _, n in ipairs(notes) do
        if n.timestamp ~= timestamp then
            newNotes[#newNotes + 1] = n
        end
    end
    projectnotes.save(projectName, newNotes)
end

-- ── HTML builder ──────────────────────────────────────────────────────

--- Escape text for safe HTML embedding.
---@param s string
---@return string
local function escapeHTML(s)
    return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;")
end

--- Build full HTML for the notes panel.
---@param projectName string
---@param notes table
---@return string
local function buildNotesHTML(projectName, notes)
    local displayName = (projectName == "unsaved_project")
        and "未保存のプロジェクト"
        or projectName:gsub("_", " ")

    -- Build timeline entries (newest first)
    local items = {}
    for i = #notes, 1, -1 do
        local n = notes[i]
        local dt = os.date("%Y/%m/%d %H:%M", n.timestamp)
        local body = escapeHTML(n.body):gsub("\n", "<br>")
        items[#items + 1] = string.format([[
<div class="note-item">
  <div class="note-meta">
    <span class="note-time">%s</span>
    <button class="delete-btn" onclick="deleteNote(%d)" title="削除">✕</button>
  </div>
  <div class="note-body">%s</div>
</div>]], dt, n.timestamp, body)
    end

    local timelineHTML = (#items > 0)
        and table.concat(items, "")
        or '<p class="empty">メモはまだありません。<br>下の入力欄から追加できます。</p>'

    return string.format([[<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%%; overflow: hidden; }
body {
    background: #1c1c1e;
    color: #e5e5ea;
    font-family: -apple-system, "Helvetica Neue", sans-serif;
    font-size: 13px;
    display: flex;
    flex-direction: column;
}
.header {
    padding: 14px 16px 12px;
    border-bottom: 1px solid #2c2c2e;
    flex-shrink: 0;
}
.project-label { font-size: 11px; color: #636366; margin-bottom: 3px; }
.project-name  { font-size: 15px; font-weight: 600; color: #fff; }
.timeline {
    flex: 1;
    overflow-y: auto;
    padding: 12px 16px;
}
.note-item {
    background: #2c2c2e;
    border-radius: 10px;
    padding: 10px 12px;
    margin-bottom: 10px;
}
.note-meta {
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 6px;
}
.note-time {
    font-size: 11px;
    color: #636366;
    font-variant-numeric: tabular-nums;
}
.delete-btn {
    background: none;
    border: none;
    color: #48484a;
    font-size: 12px;
    cursor: pointer;
    line-height: 1;
    padding: 0 2px;
}
.delete-btn:hover { color: #ff453a; }
.note-body { color: #e5e5ea; line-height: 1.55; white-space: pre-wrap; word-break: break-word; }
.empty { color: #48484a; text-align: center; margin-top: 48px; line-height: 1.8; }
.input-area {
    padding: 10px 16px 14px;
    border-top: 1px solid #2c2c2e;
    flex-shrink: 0;
    display: flex;
    gap: 8px;
    align-items: flex-end;
}
textarea {
    flex: 1;
    background: #2c2c2e;
    color: #e5e5ea;
    border: 1px solid #3a3a3c;
    border-radius: 8px;
    padding: 8px 10px;
    font-family: inherit;
    font-size: 13px;
    resize: none;
    min-height: 36px;
    max-height: 110px;
    outline: none;
    line-height: 1.45;
}
textarea:focus { border-color: #0a84ff; }
textarea::placeholder { color: #48484a; }
button.submit {
    background: #0a84ff;
    color: #fff;
    border: none;
    border-radius: 8px;
    padding: 0 14px;
    height: 36px;
    font-size: 13px;
    font-weight: 600;
    cursor: pointer;
    flex-shrink: 0;
}
button.submit:hover { background: #409cff; }
</style>
</head><body>
<div class="header">
  <div style="display:flex;justify-content:space-between;align-items:center;">
    <div>
      <div class="project-label">プロジェクトメモ</div>
      <div class="project-name">%s</div>
    </div>
    <button onclick="aiSummary()" id="aiBtn"
      style="background:#30d158;color:#000;border:none;border-radius:8px;padding:5px 12px;font-size:12px;font-weight:600;cursor:pointer;flex-shrink:0;">
      AI 要約</button>
  </div>
</div>
<div class="timeline" id="timeline">%s</div>
<div class="input-area">
  <textarea id="inp" placeholder="メモを入力... (Cmd+Enter で追加)" rows="1"
    oninput="resize(this)" onkeydown="onKey(event)"></textarea>
  <button class="submit" onclick="submit()">追加</button>
</div>
<script>
function resize(el) {
    el.style.height = 'auto';
    el.style.height = Math.min(el.scrollHeight, 110) + 'px';
}
function onKey(e) {
    if (e.key === 'Enter' && e.metaKey) { e.preventDefault(); submit(); }
}
// Always stringify: WKWebView → Lua is most reliable as JSON text
// (bridged NSDictionary tables can fail key lookups on the Lua side).
function post(payload) {
    window.webkit.messageHandlers.lesProjectNotes.postMessage(JSON.stringify(payload));
}
function submit() {
    var text = document.getElementById('inp').value.trim();
    if (!text) return;
    post({ action: 'add', text: text });
}
function deleteNote(ts) {
    if (!confirm('このメモを削除しますか？')) return;
    post({ action: 'delete', ts: ts });
}
function aiSummary() {
    var btn = document.getElementById('aiBtn');
    btn.textContent = '要約中...';
    btn.disabled = true;
    btn.style.opacity = '0.5';
    post({ action: 'ai-summary' });
}
document.getElementById('inp').focus();
</script>
</body></html>]], displayName, timelineHTML)
end

-- ── Webview lifecycle ─────────────────────────────────────────────────

--- Refresh webview content with latest notes for the current project.
local function refresh()
    if not _webview or not _currentProject then return end
    local notes = projectnotes.load(_currentProject)
    _webview:html(buildNotesHTML(_currentProject, notes))
end

--- Open (or focus) the project notes panel for the current project.
function openProjectNotes()
    local projectName = _G.trackname or "unsaved_project"

    -- If already open, just refresh and bring to front
    if _webview ~= nil then
        _currentProject = projectName
        refresh()
        local w = _webview:hswindow()
        if w then w:focus() end
        return
    end

    _currentProject = projectName

    local screen = hs.screen.mainScreen():frame()
    local W, H = 420, 540
    local x = math.floor(screen.x + screen.w - W - 40)
    local y = math.floor(screen.y + 60)

    -- WKWebView は les:// など非 http(s) のナビゲーションで NSURLErrorUnsupportedURL (-1002) になることがある。
    -- 長いメモでは les://note-add?text=... が URL 長制限を超える。postMessage で Lua に渡す。
    _notesUC = hs.webview.usercontent.new("lesProjectNotes")
    _notesUC:setCallback(function(msg)
        if type(msg) ~= "table" then return end
        local body = msg.body
        -- JS sends JSON.stringify(...); also accept a bridged table for safety
        if type(body) == "string" then
            local ok, decoded = pcall(hs.json.decode, body)
            if ok and type(decoded) == "table" then
                body = decoded
            else
                print("[projectnotes] message decode failed:", tostring(body):sub(1, 120))
                return
            end
        end
        if type(body) ~= "table" then return end
        local action = body.action
        if not _currentProject then return end

        if action == "add" then
            local text = body.text
            if type(text) == "string" then
                projectnotes.addNote(_currentProject, text)
                hs.timer.doAfter(0.05, refresh)
            end
        elseif action == "delete" then
            local ts = tonumber(body.ts)
            if type(ts) == "number" then
                projectnotes.deleteNote(_currentProject, ts)
                hs.timer.doAfter(0.05, refresh)
            else
                print("[projectnotes] delete ignored: invalid ts:", tostring(body.ts))
            end
        elseif action == "ai-summary" then
            if not _openai then _openai = require("ai.openai") end
            if not _openai.isConfigured() then
                HSMakeAlert(programName,
                    "AI 要約を使うには、設定画面で OpenAI API キーを入力してください。",
                    true, "warning")
                hs.timer.doAfter(0.05, refresh)
                return
            end
            local notes = projectnotes.load(_currentProject)
            if #notes == 0 then
                hs.timer.doAfter(0.05, refresh)
                return
            end
            local lines = {}
            for _, n in ipairs(notes) do
                lines[#lines + 1] = os.date("%Y/%m/%d %H:%M", n.timestamp) .. " - " .. n.body
            end
            local prompt = "以下はプロジェクト「" .. (_currentProject or "") .. "」のメモです:\n\n"
                .. table.concat(lines, "\n")
                .. "\n\n上記のメモを要約してください。進捗状況、残タスク、次にやるべきことを簡潔にまとめてください。"
            _openai.chat(
                {
                    { role = "system", content = "あなたは音楽制作プロジェクトのメモを要約するアシスタントです。日本語で簡潔に回答してください。" },
                    { role = "user",   content = prompt },
                },
                function(reply, err)
                    -- C1: err==nil implies reply is a non-empty string, but still
                    -- guard the type so a contract violation cannot crash the concat.
                    local summary
                    if err then
                        summary = "⚠ " .. tostring(err)
                    elseif type(reply) == "string" and reply ~= "" then
                        summary = "📋 AI 要約:\n" .. reply
                    else
                        summary = "⚠ AI 要約の取得に失敗しました（空の応答）。"
                    end
                    projectnotes.addNote(_currentProject, summary)
                    -- Always rebuild the HTML so the "AI 要約" button text/disabled
                    -- state is reset on BOTH success and error (never stranded at "要約中...").
                    hs.timer.doAfter(0.05, refresh)
                end
            )
        end
    end)

    _webview = hs.webview.new({ x = x, y = y, w = W, h = H }, { developerExtrasEnabled = false }, _notesUC)
    _webview:windowStyle({ "titled", "closable", "resizable", "nonactivating" })
    _webview:windowTitle("プロジェクトメモ")
    _webview:level(hs.drawing.windowLevels.floating)
    _webview:allowTextEntry(true)
    _webview:html(buildNotesHTML(projectName, projectnotes.load(projectName)))

    _webview:windowCallback(function(action)
        if action == "closing" then
            _webview = nil
            _notesUC = nil
            _currentProject = nil
        end
    end)

    _webview:show()
end

return projectnotes
