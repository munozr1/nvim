local cjson = require "cjson"
local M = {}

function M:call(t, id)
	local tool = t.name
	if not t.arguments then
		error("call => no arguments found")
	end
	local params = t.arguments --cjson.decode(t.arguments)
	if self[tool] == nil then
		error("No tool found: "..tool)
	end

	--exec the tool
	local res, err = self[tool](self, params)
	if not res then
		error("call => "..err)
	end

	if type(res) ~= "string" then
		res = tostring(res)
	end

	--update chat history
	local msg = {
		role = "tool",
		name = tool,
		tool_call_id = id,
		content = res,
		arguments = cjson.encode(params)
	}
	self:append_message(msg)

	return res
end

function M:append_message(t)
	local msg_history = self:read_file("messages.txt", true)
	local json = cjson.decode(msg_history)
	table.insert(json, t)
	msg_history = cjson.encode(json)
	self:write_file("messages.txt", msg_history)
end

function M:list_dir(params)
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


function M:read_file(params, dev)
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


function M:write_file (filename, data)
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

local function update_filename(path)
    return path:gsub("([^/]+)%.([^%.]+)$", "updated_%1.%2")
end

function M:edit_file(params)
    print("edit_file => params:", cjson.encode(params)) -- added debug line

    if type(params) ~= "table" then
        return nil, "edit_file expected params as table but got "..type(params)
    end

    if not params.target_file then
        return nil, "target_file is missing"
    end

    print("Editing file:", params.target_file)
    local filename = update_filename(params.target_file)

    local res, err = M:write_file(filename, params.code_edit)
    if not res then
        return nil, "Failed to write file: " .. (err or "Unknown error")
    end

    return "success", nil
end



return M

