local cjson = require "cjson"
local M = {}

function M:call(t)
	local tool = t.name
	local params = t.arguments --cjson.decode(t.arguments)
	if self[tool] == nil then
		error("No tool found: "..tool)
	end
	local res, err = self[tool](params)

	if not res then
		error(err)
	end

	if type(res) ~= "string" then
		res = tostring(res)
	end

	--update chat history
	local msg = {
		role = "tool",
		name = tool,
		arguments = params,
		content = res
	}
	self:append_message(msg)

	return res
end

M["append_message"] = function(self, t)
	local msg_history = self["read_file"]("messages.txt", true)
	local json = cjson.decode(msg_history)
	table.insert(json, t)
	msg_history = cjson.encode(json)
	self["write_file"]("messages.txt", msg_history)
end

M["list_dir"] = function (params)
	local cmd = "ls "..params.relative_workspace_path
	local handle, err = io.popen(cmd)
	if not handle then
		return nil, "Failed to execute list_dir: "..(err or "Uknown Error")
	end

	local res = handle:read("*a")
	handle:close()
	if res then
		return res, nil
	else
		return nil, "Failed to read handle list_dir"
	end
end

-- --- Search for a file by name within the current directory and all subdirectories.
-- This function executes the `find` command to search for a file with the provided name.
-- It returns either the found file's name or an error message.
--
-- @param param string A JSON string containing the search query. The `query` field
--        must contain the filename to search for.
-- @return string|nil The found file's name, or `nil` if no file was found.
-- @return string|nil An error message, or `nil` if no error occurred.

M["file_search"] = function (params)
    if type(params) ~= "table" then
	    error("file_search expected params as table but got "..type(params).." instead")
    end
    if type(params.query) ~= "string" then
	    error("file_search expected json.query as string but got "..type(params.query).." instead")
    end
    local filename = params.query

    -- avoid command injection
    filename = filename:gsub("([%%$()%.[]*+?^\\])", "%%%1")
    local cmd = string.format("find . -type f -name '%s'", filename)

    -- execute the command
    local handle, err = io.popen(cmd)
    if not handle then
        return nil, "Failed to execute file_search command: " .. (err or "Unknown error")
    end

    local result = handle:read("*a")
    handle:close()

    if result then
        return result, nil
    else
        return nil, "File not found"
    end
end


M["read_file"] = function(params, dev)
    local filename
    if not dev then
    	filename = params.relative_workspace_path
    else
	filename = params
    end
    local file, err = io.open(filename, "r")
    if not file then
        error("Could not open file: " .. err)
    end
    local content, read_err = file:read("*a")
    if not content then
        return nil, "Error reading file: " .. read_err
    end
    file:close()
    if dev then
    	return content, nil
    end
    if params.should_read_entire_file then
    	return content, nil
    end

    local partial = ""
    local line_no = 0
    for line in string.gmatch(content, "[^\n]+") do
	    line_no = line_no + 1
	    if line_no >= params.start_line_one_indexed and line_no <= params.end_line_one_indexed_inclusive then
	    	partial = partial .. line
	    end
    end

    print(partial)
    return partial, nil
end


M["write_file"] = function(filename, data)
    local file, err = io.open(filename, "w")
    if not file then
        return nil, "Could not open file: " .. err
    end
    local success, write_err = pcall(file.write, file, data)
    if not success then
        return nil, "Error writing to file: " .. write_err
    end
    file:close()
    return true, nil
end





return M

