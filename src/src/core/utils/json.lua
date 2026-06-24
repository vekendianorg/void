--[[
  JSON encoder/decoder module
  Provides methods to serialize Lua tables to JSON and deserialize JSON strings back to Lua tables.
]]

local json = {}

---Escapes special characters in a string for JSON encoding.
---@param s string The string to escape
---@return string Escaped string with special characters properly encoded
local function escape_str(s)
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"', '\\"')
    s = s:gsub('\b', '\\b')
    s = s:gsub('\f', '\\f')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return s
end

---Encodes a Lua value (nil, boolean, number, string, table) to a JSON string.
---@param value any The value to encode (supports nil, boolean, number, string, table)
---@return string The JSON-encoded string representation
function json.encode(value)
    local t = type(value)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return tostring(value)
    elseif t == "number" then
        return tostring(value)
    elseif t == "string" then
        return '"' .. escape_str(value) .. '"'
    elseif t == "table" then
        local is_array  = true
        local max_index = 0
        for k, _ in pairs(value) do
            if type(k) ~= "number" then
                is_array = false
                break
            else
                if k > max_index then max_index = k end
            end
        end

        local items = {}
        if is_array then
            for i = 1, max_index do
                table.insert(items, json.encode(value[i]))
            end
            return "[" .. table.concat(items, ",") .. "]"
        else
            for k, v in pairs(value) do
                table.insert(items, '"' .. escape_str(k) .. '":' .. json.encode(v))
            end
            return "{" .. table.concat(items, ",") .. "}"
        end
    else
        print("Unsupported data type: " .. t)
    end
end

---Decodes a JSON string back into a Lua value.
---Arrays become Lua tables with numeric keys (1-indexed).
---Objects become Lua tables with string keys.
---@param input string The JSON string to decode
---@return any The decoded Lua value (nil, boolean, number, string, or table)
function json.decode(input)
    local pos = 1

    local parse_value, parse_string, parse_number, parse_array, parse_object, skip_whitespace

    ---Advances position past any whitespace characters
    function skip_whitespace()
        while pos <= #input and input:sub(pos, pos):match("%s") do
            pos = pos + 1
        end
    end

    ---Parses any JSON value (string, number, array, object, true, false, null)
    ---@return any The parsed value
    function parse_value()
        skip_whitespace()
        local c = input:sub(pos, pos)
        if     c == '"'                        then return parse_string()
        elseif c == '{'                        then return parse_object()
        elseif c == '['                        then return parse_array()
        elseif c:match("[%d%-]")               then return parse_number()
        elseif input:sub(pos, pos + 3) == "true"  then pos = pos + 4; return true
        elseif input:sub(pos, pos + 4) == "false" then pos = pos + 5; return false
        elseif input:sub(pos, pos + 3) == "null"  then pos = pos + 4; return nil
        else print("Invalid JSON at position " .. pos)
        end
    end

    ---Parses a JSON string value
    ---@return string The parsed string (with escape sequences resolved)
    function parse_string()
        pos = pos + 1
        local start_pos = pos
        local result    = ""
        while pos <= #input do
            local c = input:sub(pos, pos)
            if c == '"' then
                result = result .. input:sub(start_pos, pos - 1)
                pos = pos + 1
                return result
            elseif c == '\\' then
                result = result .. input:sub(start_pos, pos - 1)
                pos = pos + 1
                local esc = input:sub(pos, pos)
                if     esc == '"'  then result = result .. '"'
                elseif esc == '\\' then result = result .. '\\'
                elseif esc == '/'  then result = result .. '/'
                elseif esc == 'b'  then result = result .. '\b'
                elseif esc == 'f'  then result = result .. '\f'
                elseif esc == 'n'  then result = result .. '\n'
                elseif esc == 'r'  then result = result .. '\r'
                elseif esc == 't'  then result = result .. '\t'
                else print("Invalid escape sequence: \\" .. esc)
                end
                pos = pos + 1
                start_pos = pos
            else
                pos = pos + 1
            end
        end
        print("Unterminated string")
    end

    ---Parses a JSON number value (integer or float)
    ---@return number The parsed number
    function parse_number()
        local start_pos = pos
        while pos <= #input and input:sub(pos, pos):match("[0-9eE%+%-%.%.]") do
            pos = pos + 1
        end
        local num_str = input:sub(start_pos, pos - 1)
        local num     = tonumber(num_str)
        if not num then print("Invalid number: " .. num_str) end
        return num
    end

    ---Parses a JSON array value
    ---@return table A Lua table with numeric keys (1-indexed)
    function parse_array()
        pos = pos + 1
        local arr = {}
        skip_whitespace()
        if input:sub(pos, pos) == "]" then pos = pos + 1; return arr end
        while true do
            table.insert(arr, parse_value())
            skip_whitespace()
            local c = input:sub(pos, pos)
            if     c == "]" then pos = pos + 1; break
            elseif c == "," then pos = pos + 1
            else print("Expected ',' or ']' in array at position " .. pos)
            end
        end
        return arr
    end

    ---Parses a JSON object value
    ---@return table A Lua table with string keys
    function parse_object()
        pos = pos + 1
        local obj = {}
        skip_whitespace()
        if input:sub(pos, pos) == "}" then pos = pos + 1; return obj end
        while true do
            skip_whitespace()
            local key = parse_string()
            skip_whitespace()
            if input:sub(pos, pos) ~= ":" then
                print("Expected ':' after key at position " .. pos)
            end
            pos = pos + 1
            local value = parse_value()
            obj[key] = value
            skip_whitespace()
            local c = input:sub(pos, pos)
            if     c == "}" then pos = pos + 1; break
            elseif c == "," then pos = pos + 1
            else print("Expected ',' or '}' in object at position " .. pos)
            end
        end
        return obj
    end

    return parse_value()
end

return json
