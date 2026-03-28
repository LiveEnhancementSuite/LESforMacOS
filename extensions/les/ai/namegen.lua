--  SPDX-License-Identifier: MIT
--  AI Name Generator — suggests project/track names

local openai = require("ai.openai")

local namegen = {}

---@type hs.chooser|nil
local _chooser = nil

--- Gather context for name generation.
---@return string
local function gatherContext()
    local parts = {}

    -- Current project name
    if _G.trackname and _G.trackname ~= "" then
        parts[#parts + 1] = "現在のプロジェクト名: " .. _G.trackname
    end

    -- Project notes (last 5)
    local ok, pn = pcall(require, "tracking.projectnotes")
    if ok and pn and _G.trackname then
        local notes = pn.load(_G.trackname)
        if #notes > 0 then
            local recent = {}
            local start = math.max(1, #notes - 4)
            for i = start, #notes do
                recent[#recent + 1] = "- " .. notes[i].body
            end
            parts[#parts + 1] = "最近のプロジェクトメモ:\n" .. table.concat(recent, "\n")
        end
    end

    -- Frequently used plugins (top 5)
    local ok2, ps = pcall(require, "tracking.pluginstats")
    if ok2 and ps then
        local stats = ps.getAll()
        local sorted = {}
        for name, s in pairs(stats) do
            sorted[#sorted + 1] = { name = name, count = s.use_count or 0 }
        end
        table.sort(sorted, function(a, b) return a.count > b.count end)
        if #sorted > 0 then
            local top = {}
            for i = 1, math.min(5, #sorted) do
                top[#top + 1] = sorted[i].name
            end
            parts[#parts + 1] = "よく使うプラグイン: " .. table.concat(top, ", ")
        end
    end

    if #parts == 0 then
        return "コンテキスト情報なし。一般的な音楽プロジェクト名を提案してください。"
    end
    return table.concat(parts, "\n\n")
end

--- Open the name generator.
--- Shows a chooser with AI-generated names.
---@param userHint string|nil  Optional description/genre hint
function namegen.open(userHint)
    if not openai.isConfigured() then
        HSMakeAlert(programName,
            "AI 名前ジェネレーターを使うには、設定画面で OpenAI API キーを入力してください。",
            true, "warning")
        return
    end

    -- Show a temporary chooser with loading state
    if _chooser then _chooser:delete() end
    _chooser = hs.chooser.new(function(choice)
        if not choice then return end
        -- Copy selected name to clipboard
        hs.pasteboard.setContents(choice.text)
        HSMakeAlert(programName,
            string.format("「%s」をクリップボードにコピーしました", choice.text),
            false, "informational")
    end)
    _chooser:placeholderText("AI が名前を生成中...")
    _chooser:choices({{ text = "⏳ 生成中...", subText = "少々お待ちください" }})
    _chooser:show()

    local ctx = gatherContext()
    local prompt = ctx .. "\n\n"
    prompt = prompt .. "上記のコンテキストに基づいて、音楽プロジェクト/トラックの名前を10個提案してください。\n"
    prompt = prompt .. "条件:\n"
    prompt = prompt .. "- クリエイティブで印象的な名前\n"
    prompt = prompt .. "- 英語・日本語・造語のミックスOK\n"
    prompt = prompt .. "- 各名前は短く（1〜4語）\n"
    prompt = prompt .. "- 各名前の後に括弧でイメージを一言添える\n"
    prompt = prompt .. "- 1行に1つずつ、番号なしで出力\n"

    if userHint and userHint ~= "" then
        prompt = prompt .. "\nユーザーからのヒント: " .. userHint
    end

    local messages = {
        { role = "system", content = "あなたはクリエイティブな音楽プロジェクト名を提案するアシスタントです。" },
        { role = "user",   content = prompt },
    }

    openai.chat(messages, function(reply, err)
        if not _chooser then return end
        if err then
            _chooser:choices({{ text = "❌ エラー", subText = err }})
            _chooser:refreshChoicesCallback()
            return
        end

        local choices = {}
        for line in reply:gmatch("[^\r\n]+") do
            local trimmed = line:match("^%s*(.-)%s*$")
            if trimmed and trimmed ~= "" then
                -- Split "Name (description)" pattern
                local name, desc = trimmed:match("^(.-)%s*[（%(](.+)[）%)]%s*$")
                if name and name ~= "" then
                    choices[#choices + 1] = { text = name, subText = desc }
                else
                    choices[#choices + 1] = { text = trimmed, subText = "" }
                end
            end
        end

        if #choices == 0 then
            choices = {{ text = "名前を生成できませんでした", subText = "もう一度お試しください" }}
        end

        _chooser:choices(choices)
        _chooser:refreshChoicesCallback()
    end)
end

return namegen
