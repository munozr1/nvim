local toolsDesc = require "curse.toolsDesc"
local cjson = require "cjson"
local deepseek_base_url = "https://api.deepseek.com"
local deepseek_api_key ="sk-13212ca51d0641a3b7acb7d78aa4b890"
local sysprompt = require "curse.sysPrompt"
local uv = vim.uv
local tools = require "curse.tools"

local M = {}

function M.completion(query, callback)
    --fetch chat history
    local chat_history_str = tools["read_file"]("messages.txt", true)
    local chat_history_json = cjson.decode(chat_history_str)
    local new_message = {role = "user", content = query}
    table.insert(chat_history_json, new_message)
    tools["write_file"]("messages.txt", cjson.encode(chat_history_json))
    table.insert(chat_history_json, 1, {role = "system", content = sysprompt})

    local body = {
        model = "deepseek-chat",
        messages = chat_history_json,
        stream = false,
	tools = cjson.decode(toolsDesc).tools,
	tool_choice = "auto"
    }

    local request_body = cjson.encode(body)

    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local response = {}

    local handle, _= uv.spawn("curl", {
        args = {
            "-s","-X", "POST", deepseek_base_url.."/chat/completions",
            "-H", "Authorization: Bearer "..deepseek_api_key,
            "-H", "Content-Type: application/json",
            "-d", request_body,
        },
        stdio = {nil, stdout, stderr}
    }, function(code, signal) -- on exit
        uv.read_stop(stdout)
        uv.read_stop(stderr)
        uv.close(stdout)
        uv.close(stderr)

        if code ~= 0 then
            vim.schedule(function()
                callback(nil, "Curl exited with code: " .. code .. " (Signal: " .. signal .. ")")
            end)
        end
    end)

    if not handle then
        vim.schedule(function()
            callback(nil, "Failed to start curl process")
        end)
        return
    end

    uv.read_start(stdout, function(err, data)
        assert(not err, err)
        if data then
            table.insert(response, data)
        else
            local json_str = table.concat(response)
            local success, parsed_response = pcall(cjson.decode, json_str)

            vim.schedule(function()
                if success then
                    callback(parsed_response, nil)
                else
                    callback(nil, "openai => completion => Failed to parse response JSON: " .. json_str)
                end
            end)
        end
    end)

    uv.read_start(stderr, function(err, data)
        assert(not err, err)
        if data then
            print("stderr:", data)
        end
    end)
end


function M.send_history(callback)
    --fetch chat history
    local chat_history_str = tools["read_file"]("messages.txt", true)
    local chat_history_json = cjson.decode(chat_history_str)
    table.insert(chat_history_json, 1, {role = "system", content = sysprompt})

    local body = {
        model = "deepseek-chat",
        messages = chat_history_json,
        stream = false,
	tools = cjson.decode(toolsDesc).tools,
	tool_choice = "auto"
    }

    local request_body = cjson.encode(body)

    local stdout = uv.new_pipe(false)
    local stderr = uv.new_pipe(false)

    local response = {}

    local handle, _= uv.spawn("curl", {
        args = {
            "-s","-X", "POST", deepseek_base_url.."/chat/completions",
            "-H", "Authorization: Bearer "..deepseek_api_key,
            "-H", "Content-Type: application/json",
            "-d", request_body,
        },
        stdio = {nil, stdout, stderr}
    }, function(code, signal) -- on exit
        uv.read_stop(stdout)
        uv.read_stop(stderr)
        uv.close(stdout)
        uv.close(stderr)

        if code ~= 0 then
            vim.schedule(function()
                callback(nil, "Curl exited with code: " .. code .. " (Signal: " .. signal .. ")")
            end)
        end
    end)

    if not handle then
        vim.schedule(function()
            callback(nil, "Failed to start curl process")
        end)
        return
    end

    uv.read_start(stdout, function(err, data)
        assert(not err, err)
        if data then
            table.insert(response, data)
        else
            local json_str = table.concat(response)
            local success, parsed_response = pcall(cjson.decode, json_str)

            vim.schedule(function()
                if success then
                    callback(parsed_response, nil)
                else
                    callback(nil, "openai => send_history => Failed to parse response JSON => json_str: " .. json_str)
                end
            end)
        end
    end)

    uv.read_start(stderr, function(err, data)
        assert(not err, err)
        if data then
            print("stderr:", data)
        end
    end)
end



return M

