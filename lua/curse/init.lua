local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
--local builtin = require "telescope.builtin"
local conf = require("telescope.config").values
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"

local cjson = require "cjson"
local tools = require "curse.tools"
local M = {}
local contextfiles = {}

local _addfile= function(opts)
  opts = opts or {}
  pickers.new(opts, {
    prompt_title = "Add Files",
    finder = finders.new_oneshot_job({ "find", "." }, opts ),
    sorter = conf.generic_sorter(opts),
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)
        local selection = action_state.get_selected_entry()
        if selection then
          local file_path = selection[1]
          if file_path then
		  table.insert(contextfiles, file_path)
          else
		  tools:write_file("err.txt", "Error: Selected entry has no path.")
          end
          else
		  tools:write_file("err.txt", "Error: No file selected.")
        end
      end)
      return true
    end,
  }):find()
end


function M.addContext()
	_addfile()
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
	--openai.send_history(handle_response_callback)
	openai.completion("summarize this file", handle_response_callback, contextfiles)

end


return M
