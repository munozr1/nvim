local cjson = require "cjson"
local tools = require "curse.tools"
local M = {}

function M.addContext()
	local width = 40
	local height = 10

	local opts = {
		relative = 'editor',
		width = width,
		height = height,
		row = (vim.o.lines - height) /2,
		col = (vim.o.columns - width) /2,
		style = 'minimal',
		border = 'rounded',
	}

	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')


	local win = vim.api.nvim_open_win(buf, true, opts)

	vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
		"line 1",
		"line 2",
		"line 3",
		"line 4",
	})


	vim.api.nvim_buf_set_keymap(buf, 'n', 'q', ':close<CR>', {noremap = true, silent=true})

	return buf, win
end

local function handle_response_callback(res, err)

    if res == nil then
	tools:write_file("err.txt", err)
        print("handle_response_callback Error => " .. err)
        return
    end

    if res.error_msg or res.error then
        print("LLM ERR: " .. (res.error_msg or res.error.message))
        return
    end


    local choices = res.choices[1]

    if choices.finish_reason == "tool_calls" and choices.message.tool_calls then
        for _, tool in ipairs(choices.message.tool_calls) do
            tools:write_file("tool_calls.txt", cjson.encode(tool))
            local toolMsg = {
                role = "assistant",
                content = choices.message.content or "",
                tool_calls = choices.message.tool_calls
            }
            tools:append_message(toolMsg)
            tool["function"].arguments = cjson.decode(tool["function"].arguments)
            tools:call(tool["function"], tool.id)
        end
        return
    end

    if choices.finish_reason == "stop" then
	    tools:write_file("stop_calls.txt", cjson.encode(res))
	    tools:append_message(choices.message)
	    return
    end

    print("LLM response not recognized: ", cjson.encode(res))
end



function M.query()
	local openai = require "curse.openai"
	openai.send_history(handle_response_callback)

end


return M
