--  SPDX-License-Identifier: MIT
--  AI integration: shared OpenAI API client

local openai = {}

local API_URL = "https://api.openai.com/v1/chat/completions"

--- Get the configured API key.
---@return string
function openai.getKey()
    if settingsManager and settingsManager["openaikey"]
       and settingsManager["openaikey"]["value"] then
        return tostring(settingsManager["openaikey"]["value"])
    end
    return ""
end

--- Get the configured model name.
---@return string
function openai.getModel()
    if settingsManager and settingsManager["openaimodel"]
       and settingsManager["openaimodel"]["value"]
       and settingsManager["openaimodel"]["value"] ~= "" then
        return tostring(settingsManager["openaimodel"]["value"])
    end
    return "gpt-4o-mini"
end

--- Check whether an API key has been configured.
---@return boolean
function openai.isConfigured()
    local key = (openai.getKey() or ""):gsub("^%s*(.-)%s*$", "%1")
    return key ~= "" and not key:find("未設定", 1, true)
end

--- Send a chat completion request (async).
---@param messages table  Array of {role, content} message objects
---@param callback fun(reply: string|nil, err: string|nil)
function openai.chat(messages, callback)
    if not openai.isConfigured() then
        callback(nil, "APIキーが設定されていません。\n設定 → AI設定 で OpenAI API キーを入力してください。")
        return
    end

    local payload = hs.json.encode({
        model       = openai.getModel(),
        messages    = messages,
        temperature = 0.7,
    })

    local headers = {
        ["Content-Type"]  = "application/json",
        ["Authorization"] = "Bearer " .. openai.getKey(),
    }

    hs.http.asyncPost(API_URL, payload, headers, function(status, body, _)
        if status ~= 200 then
            local errMsg = "API エラー (HTTP " .. tostring(status) .. ")"
            local ok, decoded = pcall(hs.json.decode, body or "")
            if ok and type(decoded) == "table" and decoded.error then
                errMsg = errMsg .. ": " .. (decoded.error.message or "")
            end
            callback(nil, errMsg)
            return
        end

        local ok, decoded = pcall(hs.json.decode, body)
        local msg = ok and type(decoded) == "table" and decoded.choices
            and decoded.choices[1] and decoded.choices[1].message
        local content = msg and msg.content
        if type(content) == "string" and content ~= "" then
            callback(content, nil)
        else
            callback(nil, "空の応答が返されました")
        end
    end)
end

return openai
