local menuConfigWebview = nil
local menuConfigUC = nil

local function readMenuConfig()
    local path = strJoinPaths(ScriptUserPath, "menuconfig.ini")
    local f = io.open(path, "r")
    if not f then return "" end
    local content = f:read("*a")
    f:close()
    return content
end

local function writeMenuConfig(content)
    local path = strJoinPaths(ScriptUserPath, "menuconfig.ini")
    local tmpPath = path .. ".tmp"
    local f = io.open(tmpPath, "w")
    if not f then return false end
    f:write(content)
    f:close()
    return os.rename(tmpPath, path) ~= nil
end

local CSS = table.concat({
    "*{box-sizing:border-box;margin:0;padding:0}",
    "body{font-family:-apple-system,BlinkMacSystemFont,sans-serif;background:#1e1e2e;",
    "color:#cdd6f4;padding:14px;height:100vh;display:flex;flex-direction:column;gap:10px}",
    "h1{font-size:16px;font-weight:600;color:#cba6f7}",
    ".legend{background:#181825;border:1px solid #313244;border-radius:8px;padding:10px;",
    "font-size:11px;line-height:1.9;color:#a6adc8}",
    ".legend code{color:#a6e3a1;font-family:'SF Mono',Menlo,monospace;font-weight:600}",
    "#editor{flex:1;font-family:'SF Mono',Menlo,monospace;font-size:12px;line-height:1.5;",
    "background:#181825;color:#cdd6f4;border:1px solid #313244;border-radius:8px;",
    "padding:12px;resize:none;outline:none;min-height:0}",
    ".buttons{display:flex;gap:8px;justify-content:flex-end}",
    ".btn{padding:7px 20px;border:none;border-radius:6px;cursor:pointer;",
    "font-size:13px;font-weight:500}",
    ".btn-primary{background:#89b4fa;color:#1e1e2e}",
    ".btn-primary:hover{background:#74c7ec}",
    ".btn-secondary{background:#313244;color:#cdd6f4}",
    ".btn-secondary:hover{background:#45475a}",
    "#toast{position:fixed;bottom:14px;left:50%;transform:translateX(-50%);",
    "padding:7px 16px;border-radius:6px;font-size:12px;display:none}",
    ".tok{background:#a6e3a1;color:#1e1e2e}",
    ".terr{background:#f38ba8;color:#1e1e2e}",
}, "")

local function buildMenuConfigHTML(content)
    local jsonContent = hs.json.encode(content) or '""'
    local js = table.concat({
        "var ed=document.getElementById('editor');",
        "ed.value=", jsonContent, ";",
        "function save(){",
        "window.webkit.messageHandlers.lesMenuConfig.postMessage(",
        "JSON.stringify({action:'save',data:ed.value}));}",
        "function cancel(){",
        "window.webkit.messageHandlers.lesMenuConfig.postMessage(",
        "JSON.stringify({action:'cancel'}));}",
        "function saveResult(ok,msg){",
        "var t=document.getElementById('toast');",
        "t.textContent=msg;t.className=ok?'tok':'terr';t.style.display='block';}",
    }, "")
    return table.concat({
        "<!DOCTYPE html><html lang='ja'><head><meta charset='UTF-8'>",
        "<style>", CSS, "</style></head><body>",
        "<h1>プラグインメニュー設定</h1>",
        "<div class='legend'>",
        "<code>/カテゴリ名</code> トップレベルカテゴリ &nbsp; ",
        "<code>//サブカテゴリ</code> サブカテゴリ &nbsp; ",
        "<code>..</code> 1階層上へ &nbsp; ",
        "<code>--</code> セパレーター<br>",
        "プラグイン: 名前行＋検索クエリ行の2行ペア &nbsp; ",
        "<code>/nocategory</code> カテゴリなしセクション &nbsp; ",
        "<code>End</code> 終端",
        "</div>",
        "<textarea id='editor'></textarea>",
        "<div class='buttons'>",
        "<button class='btn btn-secondary' onclick='cancel()'>キャンセル</button>",
        "<button class='btn btn-primary' onclick='save()'>保存</button>",
        "</div>",
        "<div id='toast'></div>",
        "<script>", js, "</script>",
        "</body></html>",
    }, "")
end

local function closeGui()
    if menuConfigWebview ~= nil then
        pcall(function() menuConfigWebview:delete() end)
        menuConfigWebview = nil
    end
end

function openMenuConfigGUI()
    closeGui()
    menuConfigUC = nil
    local content = readMenuConfig()
    menuConfigUC = hs.webview.usercontent.new("lesMenuConfig")
    menuConfigUC:setCallback(function(msg)
        local bodyRaw = msg
        if type(msg) == "table" and msg.body ~= nil then
            bodyRaw = msg.body
        end
        if type(bodyRaw) ~= "string" then return end
        local body = hs.json.decode(bodyRaw)
        if not body then return end
        local action = body.action
        if action == "save" then
            local newContent = body.data
            if type(newContent) ~= "string" then return end
            local ok = writeMenuConfig(newContent)
            pcall(buildPluginMenu)
            pcall(rebuildRcMenu)
            local wv = menuConfigWebview
            if wv then
                if ok then
                    wv:evaluateJavaScript("saveResult(true,'保存しました')")
                    hs.timer.doAfter(1.5, closeGui)
                else
                    wv:evaluateJavaScript("saveResult(false,'保存に失敗しました')")
                end
            end
        elseif action == "cancel" then
            closeGui()
        end
    end)
    local screen = hs.screen.mainScreen():frame()
    local w, h = 700, 620
    local x = screen.x + math.floor((screen.w - w) / 2)
    local y = screen.y + math.floor((screen.h - h) / 2)
    menuConfigWebview = hs.webview.new({x = x, y = y, w = w, h = h}, {}, menuConfigUC)
    menuConfigWebview:windowStyle({"titled", "closable", "resizable"})
    menuConfigWebview:windowTitle("プラグインメニュー設定 — Live Enhancement Suite Custom")
    menuConfigWebview:html(buildMenuConfigHTML(content))
    menuConfigWebview:show()
    menuConfigWebview:hswindow():focus()
end
