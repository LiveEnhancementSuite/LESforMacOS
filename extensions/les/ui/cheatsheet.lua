--  SPDX-License-Identifier: MIT
--
--  Copyright (c) 2019-2023 LESforMacOS authors, see AUTHORS.txt
--  for a list
--
--  Distributed under the MIT software license, see the accompanying
--  file COPYING.txt or visit https://opensource.org/license/mit/

-------------------------------------------------
--  Keyboard Shortcut Cheatsheet Overlay       --
--  Toggle with Cmd+Shift+/                    --
-------------------------------------------------

local cheatsheet = {}

---@type hs.webview|nil
local _webview = nil

-- Shortcut definitions displayed in the overlay.
-- Use { section = "..." } for section headers, { key = "...", desc = "..." } for rows.
local SHORTCUTS = {
    { section = "プラグイン" },
    { key = "ダブル右クリック",              desc = "プラグインメニュー" },
    { key = "Shift + ダブル右クリック",      desc = "ピアノロールメニュー" },
    { key = "Cmd+Shift+F",                   desc = "プラグイン検索 UI" },
    { section = "ピアノロール" },
    { key = "` (バッククォート)",             desc = "ピアノロールマクロ" },
    { section = "プロジェクト操作" },
    { key = "Cmd+B",                         desc = "トラック / クリップ複製" },
    { key = "Cmd+Alt+S",                     desc = "プロジェクトバージョニング" },
    { key = "Shift+L / Alt+L",              desc = "マーカー作成" },
    { key = "Ctrl+W",                        desc = "ウィンドウ最小化" },
    { key = "Ctrl+Shift+W",                  desc = "ウィンドウ表示" },
    { key = "Ctrl+Alt+D",                    desc = "Absolute Replace（ドラッグ）" },
    { key = "Ctrl+Alt+V",                    desc = "Absolute Replace（貼り付け）" },
    { section = "ノート編集" },
    { key = "Alt + クリック",                desc = "中クリックエミュレーション" },
    { key = "Alt（ホールド）",               desc = "エンベロープモード切替" },
    { key = "0 × 2",                         desc = "ダブル 0 削除（ノート削除）" },
    { section = "FabFilter Pro-Q 3" },
    { key = "Cmd+Z",                         desc = "Undo（Pro-Q 3 フォーカス時）" },
    { key = "Cmd+Shift+Z",                   desc = "Redo（Pro-Q 3 フォーカス時）" },
    { section = "LES 管理" },
    { key = "Cmd+Shift+1",                   desc = "マクロ 有効 / 無効切替" },
    { key = "Cmd+Shift+/",                   desc = "ショートカット一覧（このウィンドウ）" },
}

--- Build the HTML content for the cheatsheet.
---@return string
local function buildHTML()
    local rows = {}
    for _, item in ipairs(SHORTCUTS) do
        if item.section then
            rows[#rows + 1] = string.format(
                '<tr><td colspan="2" class="section">%s</td></tr>', item.section)
        else
            rows[#rows + 1] = string.format(
                '<tr><td class="key">%s</td><td class="desc">%s</td></tr>',
                item.key, item.desc)
        end
    end

    return [[<!DOCTYPE html><html><head><meta charset="utf-8">
<style>
* { box-sizing: border-box; margin: 0; padding: 0; }
html, body { height: 100%; }
body {
    background: rgba(28,28,30,0.95);
    color: #e5e5ea;
    font-family: -apple-system, "Helvetica Neue", sans-serif;
    font-size: 13px;
    padding: 18px 20px 14px;
    border-radius: 14px;
    overflow: hidden;
}
h1 {
    font-size: 14px;
    font-weight: 600;
    color: #fff;
    margin-bottom: 14px;
    text-align: center;
    letter-spacing: 0.01em;
}
table { width: 100%; border-collapse: collapse; }
td { padding: 3px 8px; vertical-align: middle; }
td.section {
    font-size: 10px;
    font-weight: 700;
    text-transform: uppercase;
    letter-spacing: 0.1em;
    color: #48484a;
    padding-top: 11px;
    padding-bottom: 4px;
    border-bottom: 1px solid #2c2c2e;
    padding-left: 0;
}
td.key {
    font-family: "SF Mono", "Menlo", monospace;
    font-size: 11.5px;
    color: #0a84ff;
    white-space: nowrap;
    width: 48%;
    padding-left: 0;
}
td.desc { color: #c7c7cc; }
.hint {
    text-align: center;
    color: #3a3a3c;
    font-size: 11px;
    margin-top: 14px;
}
</style></head><body>
<h1>⌨&nbsp;&nbsp;Live Enhancement Suite Custom — ショートカット</h1>
<table>]] .. table.concat(rows, "\n") .. [[</table>
<p class="hint">Cmd+Shift+/ または ウィンドウを閉じて非表示</p>
</body></html>]]
end

--- Toggle the cheatsheet overlay. Opens if closed, closes if open.
function cheatsheet.toggle()
    if _webview ~= nil then
        _webview:delete()
        _webview = nil
        return
    end

    local screen = hs.screen.mainScreen():frame()
    local W, H = 490, 570
    local x = math.floor(screen.x + (screen.w - W) / 2)
    local y = math.floor(screen.y + (screen.h - H) / 2)

    _webview = hs.webview.new({ x = x, y = y, w = W, h = H })
    _webview:windowStyle({ "titled", "closable", "nonactivating" })
    _webview:windowTitle("ショートカット一覧")
    _webview:level(hs.drawing.windowLevels.floating)
    _webview:alpha(0.97)
    _webview:allowTextEntry(false)
    _webview:html(buildHTML())
    _webview:windowCallback(function(action)
        if action == "closing" then
            _webview = nil
        end
    end)
    _webview:show()
end

return cheatsheet
