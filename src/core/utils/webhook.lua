--[[
  core/utils/webhook.lua — Discord Webhook client for VOID v1
  Uses LuaJava via luajava.newInstance (GG style, matches catbox/paste).
]]

local TAG = "[WEBHOOK]"

local WEBHOOK_URL = "https://discord.com/api/webhooks/1521096416942887033/i6d9Dv-zKzdmMOJ8x1lL90FMIUcQbSv6uLcvN0ci3NTE7m_MJiO0WSrX7StLnvLWUfxv"

local webhook = {}
webhook.__index = webhook

-- ─── Helpers ─────────────────────────────────────────────────────────────────

local function escape_json(s)
    s = tostring(s)
    s = s:gsub('\\', '\\\\')
    s = s:gsub('"',  '\\"')
    s = s:gsub('\n', '\\n')
    s = s:gsub('\r', '\\r')
    s = s:gsub('\t', '\\t')
    return s
end

local function build_json(t)
    if #t > 0 then
        local arr = {}
        for i = 1, #t do
            local v, vt = t[i], type(t[i])
            local val
            if vt == "string"  then val = '"' .. escape_json(v) .. '"'
            elseif vt == "boolean" or vt == "number" then val = tostring(v)
            elseif vt == "table" then val = build_json(v)
            end
            arr[#arr + 1] = val or "null"
        end
        return "[" .. table.concat(arr, ",") .. "]"
    end
    local parts = {}
    for k, v in pairs(t) do
        local vt  = type(v)
        local val
        if vt == "string"  then val = '"' .. escape_json(v) .. '"'
        elseif vt == "boolean" or vt == "number" then val = tostring(v)
        elseif vt == "table" then val = build_json(v)
        end
        if val then parts[#parts + 1] = '"' .. tostring(k) .. '":' .. val end
    end
    return "{" .. table.concat(parts, ",") .. "}"
end

local function write_bytes(conn, str)
    local jStr = luajava.newInstance("java.lang.String", str)
    local dos  = luajava.newInstance("java.io.DataOutputStream", conn.getOutputStream())
    dos.write(jStr.getBytes("UTF-8"))
    dos.flush()
    dos.close()
end

local function read_response(conn)
    local isr = luajava.newInstance("java.io.InputStreamReader", conn.getInputStream(), "UTF-8")
    local br  = luajava.newInstance("java.io.BufferedReader", isr)
    local out, line = "", br.readLine()
    while line ~= nil do
        out  = out .. line .. "\n"
        line = br.readLine()
    end
    br.close()
    return out
end

local function http_post_json(json_body)
    local code
    local ok, err = pcall(function()
        local url  = luajava.newInstance("java.net.URL", WEBHOOK_URL)
        local conn = url.openConnection()
        conn.setRequestMethod("POST")
        conn.setDoOutput(true)
        conn.setConnectTimeout(8000)
        conn.setReadTimeout(8000)
        conn.setRequestProperty("Content-Type", "application/json")
        conn.setRequestProperty("User-Agent", "VOID/1.0")
        write_bytes(conn, json_body)
        code = conn.getResponseCode()
        conn.disconnect()
    end)
    if not ok then return nil, tostring(err) end
    return code
end

local function http_post_multipart(boundary, body)
    local code
    local ok, err = pcall(function()
        local url  = luajava.newInstance("java.net.URL", WEBHOOK_URL)
        local conn = url.openConnection()
        conn.setRequestMethod("POST")
        conn.setDoOutput(true)
        conn.setConnectTimeout(8000)
        conn.setReadTimeout(8000)
        conn.setRequestProperty("Content-Type", "multipart/form-data; boundary=" .. boundary)
        conn.setRequestProperty("User-Agent", "VOID/1.0")
        write_bytes(conn, body)
        code = conn.getResponseCode()
        conn.disconnect()
    end)
    if not ok then return nil, tostring(err) end
    return code
end

local function truncate(s, max)
    s = tostring(s)
    if #s <= max then return s end
    return s:sub(1, max - 18) .. "\n...[truncated]"
end

local function get_device_tag()
    local ok, result = pcall(function()
        local Build = luajava.bindClass("android.os.Build")
        local parts = {
            tostring(Build.MANUFACTURER    or "unknown"),
            tostring(Build.MODEL           or "unknown"),
            tostring(Build.VERSION.RELEASE or "?"),
        }
        return table.concat(parts, "_"):lower():gsub("%s+", "_")
    end)
    return (ok and result) or "unknown_device"
end

-- ─── Constructor ─────────────────────────────────────────────────────────────

function webhook.new(username, avatar)
    return setmetatable({
        _username = username or "Void",
        _avatar   = avatar   or nil,
    }, webhook)
end

-- ─── API ─────────────────────────────────────────────────────────────────────

function webhook:send(content, opts)
    opts = opts or {}
    local payload = {
        content          = truncate(tostring(content), 2000),
        username         = self._username,
        allowed_mentions = { parse = opts.everyone and { "everyone" } or {} },
    }
    if self._avatar then payload.avatar_url = self._avatar end
    if opts.tts     then payload.tts        = true         end

    local code, err = http_post_json(build_json(payload))
    if not code then
        if LOG then LOG.error(TAG, "send failed: " .. tostring(err)) end
        return false, err
    end
    return (code == 204 or code == 200), code
end

function webhook:embed(opts)
    assert(type(opts) == "table", TAG .. " opts must be table")
    local emb = {}
    if opts.title       then emb.title       = opts.title                       end
    if opts.description then emb.description = truncate(opts.description, 4000) end
    if opts.color       then emb.color       = opts.color                       end
    if opts.footer      then emb.footer      = opts.footer                      end
    if opts.fields      then emb.fields      = opts.fields                      end
    if opts.timestamp   then
        local ok, ts = pcall(os.date, "!%Y-%m-%dT%H:%M:%SZ")
        emb.timestamp = (ok and ts) or "1970-01-01T00:00:00Z"
    end

    local payload = {
        embeds           = { emb },
        username         = self._username,
        allowed_mentions = { parse = {} },
    }
    if self._avatar then payload.avatar_url = self._avatar end

    local code, err = http_post_json(build_json(payload))
    if not code then
        if LOG then LOG.error(TAG, "embed failed: " .. tostring(err)) end
        return false, err
    end
    return (code == 204 or code == 200), code
end

function webhook:log(title, body, color)
    return self:embed({
        title       = title,
        description = "```\n" .. tostring(body) .. "\n```",
        color       = color or 0x5865F2,
        timestamp   = true,
    })
end

function webhook:file(content, caption, filename)
    content  = tostring(content)
    filename = filename or (get_device_tag() .. "_" .. tostring(os.time()) .. ".txt")

    local boundary = "VOIDboundary" .. tostring(os.time())
    local CRLF     = "\r\n"

    local json_cap = '{"content":' .. (caption and ('"' .. escape_json(caption) .. '"') or '""')
                  .. ',"allowed_mentions":{"parse":[]}}'

    local body = ""
        .. "--" .. boundary .. CRLF
        .. 'Content-Disposition: form-data; name="payload_json"' .. CRLF
        .. "Content-Type: application/json" .. CRLF
        .. CRLF
        .. json_cap .. CRLF
        .. "--" .. boundary .. CRLF
        .. 'Content-Disposition: form-data; name="file"; filename="' .. filename .. '"' .. CRLF
        .. "Content-Type: text/plain; charset=utf-8" .. CRLF
        .. CRLF
        .. content .. CRLF
        .. "--" .. boundary .. "--" .. CRLF

    local code, err = http_post_multipart(boundary, body)
    if not code then
        if LOG then LOG.error(TAG, "file upload failed: " .. tostring(err)) end
        return false, err
    end
    return (code == 204 or code == 200), code
end

return webhook
