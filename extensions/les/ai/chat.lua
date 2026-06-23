--  SPDX-License-Identifier: MIT
--  AI Chat Assistant — floating webview for music production Q&A

local openai = require("ai.openai")

local chat = {}

---@type hs.webview|nil
local _webview = nil
---@type hs.webview.usercontent|nil
local _uc = nil

-- Conversation history (reset on window close)
local _messages = {}

local SYSTEM_PROMPT = [[あなたは Ableton Live に特化した音楽制作アシスタントです。
ユーザーは Ableton Live + Live Enhancement Suite Custom (Hammerspoon ベースの拡張ツール) を使用しています。
質問には日本語で簡潔に回答してください。
ミキシング、サウンドデザイン、プラグイン選び、コード進行、作曲テクニックなどの質問に対応します。
回答は Markdown 形式で構いません。コードブロックは ```で囲んでください。]]

--- Escape for safe JS string embedding (single-quoted).
---@param s string
---@return string
local function jsEscape(s)
    return s:gsub("\\", "\\\\")
            :gsub("'", "\\'")
            :gsub("\n", "\\n")
            :gsub("\r", "\\r")
            :gsub("<", "\\x3c")
            :gsub(">", "\\x3e")
            :gsub("\u{2028}", "\\u2028")
            :gsub("\u{2029}", "\\u2029")
end

--- Build the chat HTML.
---@return string
local function buildHTML()
    return [[<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; overflow: hidden; }
body {
    background: #1c1c1e; color: #e5e5ea;
    font-family: -apple-system, "Helvetica Neue", sans-serif;
    font-size: 13px; display: flex; flex-direction: column;
}
.header {
    padding: 12px 16px; border-bottom: 1px solid #2c2c2e;
    display: flex; justify-content: space-between; align-items: center;
    flex-shrink: 0;
}
.header h1 { font-size: 14px; font-weight: 600; color: #fff; }
.header button {
    background: none; border: 1px solid #3a3a3c; color: #8e8e93;
    border-radius: 6px; padding: 3px 10px; font-size: 11px; cursor: pointer;
}
.header button:hover { border-color: #636366; color: #c7c7cc; }
.messages {
    flex: 1; overflow-y: auto; padding: 12px 16px;
    display: flex; flex-direction: column; gap: 10px;
}
.msg { max-width: 85%; padding: 9px 13px; border-radius: 14px; line-height: 1.5; white-space: pre-wrap; word-break: break-word; }
.msg.user { align-self: flex-end; background: #0a84ff; color: #fff; border-bottom-right-radius: 4px; }
.msg.assistant { align-self: flex-start; background: #2c2c2e; color: #e5e5ea; border-bottom-left-radius: 4px; }
.msg.error { align-self: flex-start; background: #3a1c1c; color: #ff6b6b; border-bottom-left-radius: 4px; }
.msg code { background: rgba(255,255,255,0.1); padding: 1px 4px; border-radius: 3px; font-size: 12px; }
.msg pre { background: rgba(0,0,0,0.3); padding: 8px 10px; border-radius: 6px; overflow-x: auto; margin: 6px 0; }
.msg pre code { background: none; padding: 0; }
.typing { align-self: flex-start; color: #636366; font-style: italic; padding: 4px 0; }
.input-area {
    padding: 10px 16px 14px; border-top: 1px solid #2c2c2e;
    flex-shrink: 0; display: flex; gap: 8px; align-items: flex-end;
}
textarea {
    flex: 1; background: #2c2c2e; color: #e5e5ea;
    border: 1px solid #3a3a3c; border-radius: 8px;
    padding: 8px 10px; font-family: inherit; font-size: 13px;
    resize: none; min-height: 36px; max-height: 110px;
    outline: none; line-height: 1.45;
}
textarea:focus { border-color: #0a84ff; }
textarea::placeholder { color: #48484a; }
textarea:disabled { opacity: 0.5; }
button.send {
    background: #0a84ff; color: #fff; border: none; border-radius: 8px;
    padding: 0 14px; height: 36px; font-size: 13px; font-weight: 600;
    cursor: pointer; flex-shrink: 0;
}
button.send:hover { background: #409cff; }
button.send:disabled { opacity: 0.4; cursor: default; }
.welcome { color: #636366; text-align: center; margin-top: 40px; line-height: 1.8; }
</style></head><body>
<div class="header">
  <h1>🤖 AI アシスタント</h1>
  <button onclick="clearChat()">会話クリア</button>
</div>
<div class="messages" id="messages">
  <div class="welcome">Ableton Live の音楽制作について<br>何でも質問してください。</div>
</div>
<div class="input-area">
  <textarea id="inp" placeholder="質問を入力... (Cmd+Enter で送信)" rows="1"
    oninput="resizeTA(this)" onkeydown="onKey(event)"></textarea>
  <button class="send" id="sendBtn" onclick="send()">送信</button>
</div>
<script>
var sending = false;
function resizeTA(el) {
    el.style.height = 'auto';
    el.style.height = Math.min(el.scrollHeight, 110) + 'px';
}
function onKey(e) {
    if (e.key === 'Enter' && e.metaKey) { e.preventDefault(); send(); }
}
function send() {
    if (sending) return;
    var inp = document.getElementById('inp');
    var text = inp.value.trim();
    if (!text) return;
    sending = true;
    inp.value = ''; inp.style.height = 'auto';
    inp.disabled = true;
    document.getElementById('sendBtn').disabled = true;
    addMessage('user', text);
    showTyping();
    // Stringify: bridged NSDictionary tables can fail key lookups on the Lua side
    window.webkit.messageHandlers.aichat.postMessage(JSON.stringify({action:'send', text: text}));
}
function addMessage(role, text) {
    removeTyping();
    var el = document.createElement('div');
    el.className = 'msg ' + role;
    el.textContent = text;
    document.getElementById('messages').appendChild(el);
    scrollBottom();
}
function showTyping() {
    removeTyping();
    var el = document.createElement('div');
    el.className = 'typing'; el.id = 'typing';
    el.textContent = '考え中...';
    document.getElementById('messages').appendChild(el);
    scrollBottom();
}
function removeTyping() {
    var t = document.getElementById('typing');
    if (t) t.remove();
}
function onReply() {
    sending = false;
    var inp = document.getElementById('inp');
    inp.disabled = false;
    document.getElementById('sendBtn').disabled = false;
    inp.focus();
}
function clearChat() {
    document.getElementById('messages').innerHTML =
        '<div class="welcome">Ableton Live の音楽制作について<br>何でも質問してください。</div>';
    window.webkit.messageHandlers.aichat.postMessage(JSON.stringify({action:'clear'}));
}
function scrollBottom() {
    var m = document.getElementById('messages');
    m.scrollTop = m.scrollHeight;
}
document.getElementById('inp').focus();
</script>
</body></html>]]
end

--- Build the system prompt, optionally enriched with project context.
---@return table
local function buildSystemMessages()
    local sys = SYSTEM_PROMPT
    -- Add current project context if available
    if _G.trackname and _G.trackname ~= "" then
        sys = sys .. "\n\n現在のプロジェクト: " .. _G.trackname
        -- _G.clock is an hs.timer userdata (arithmetic throws); read the real
        -- per-track elapsed-seconds counter instead.
        local secs = tonumber(_G["timer_" .. _G.trackname])
        if secs then
            local h = math.floor(secs / 3600)
            local m = math.floor((secs % 3600) / 60)
            sys = sys .. string.format("\nセッション時間: %d時間%d分", h, m)
        end
    end
    return {{ role = "system", content = sys }}
end

--- Handle a user message: call OpenAI and push reply to webview.
---@param text string
local function handleSend(text)
    _messages[#_messages + 1] = { role = "user", content = text }

    local apiMessages = buildSystemMessages()
    for _, m in ipairs(_messages) do
        apiMessages[#apiMessages + 1] = m
    end

    openai.chat(apiMessages, function(reply, err)
        if not _webview then
            print("[LES][ai.chat] reply dropped: webview already closed")
            return
        end
        if err or type(reply) ~= "string" or reply == "" then
            local errMsg = err or "空の応答が返されました"
            print("[LES][ai.chat] reply error: " .. tostring(errMsg))
            _webview:evaluateJavaScript(string.format(
                "removeTyping(); addMessage('error','%s'); onReply();", jsEscape(errMsg)))
        else
            _messages[#_messages + 1] = { role = "assistant", content = reply }
            _webview:evaluateJavaScript(string.format(
                "removeTyping(); addMessage('assistant','%s'); onReply();", jsEscape(reply)))
        end
    end)
end

--- Toggle the AI chat assistant window.
function chat.toggle()
    if _webview ~= nil then
        _webview:delete()
        _webview = nil
        _uc = nil
        return
    end

    _messages = {}

    _uc = hs.webview.usercontent.new("aichat")
    _uc:setCallback(function(msg)
        if type(msg) ~= "table" then return end
        local body = msg.body
        -- JS sends JSON.stringify(...); also accept a bridged table for safety
        if type(body) == "string" then
            local ok, decoded = pcall(hs.json.decode, body)
            if not ok or type(decoded) ~= "table" then return end
            body = decoded
        end
        if type(body) ~= "table" then return end
        if body.action == "send" and type(body.text) == "string" then
            handleSend(body.text)
        elseif body.action == "clear" then
            _messages = {}
        end
    end)

    local screen = hs.screen.mainScreen():frame()
    local W, H = 460, 580
    local x = math.floor(screen.x + screen.w - W - 40)
    local y = math.floor(screen.y + (screen.h - H) / 2)

    _webview = hs.webview.new(
        { x = x, y = y, w = W, h = H },
        { developerExtrasEnabled = false },
        _uc
    )
    _webview:windowStyle({ "titled", "closable", "resizable", "nonactivating" })
    _webview:windowTitle("AI アシスタント")
    _webview:level(hs.drawing.windowLevels.floating)
    _webview:allowTextEntry(true)
    _webview:html(buildHTML())
    _webview:windowCallback(function(action)
        if action == "closing" then
            _webview = nil
            _uc = nil
        end
    end)
    _webview:show()
end

return chat
