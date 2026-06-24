local paste = {}
local TAG = "PASTE_SERVICE"

function paste.post(content)
    -- Wrap everything in a protected call to intercept Java/Network crashes
    local status, res, err = pcall(function()
        local targetUrl = "https://paste.rs/"
        
        local url = luajava.newInstance("java.net.URL", targetUrl)
        local conn = url.openConnection()
        
        conn.setRequestMethod("POST")
        conn.setDoOutput(true)
        conn.setDoInput(true)
        conn.setRequestProperty("Content-Type", "text/plain; charset=utf-8")
        
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        
        conn.setRequestProperty("Content-Length", tostring(#content))
        
        local os = conn.getOutputStream()
        local javaString = luajava.newInstance("java.lang.String", content)
        local textBytes = javaString.getBytes("UTF-8")
        
        os.write(textBytes)
        os.flush()
        os.close()
        
        local responseCode = conn.getResponseCode()
        if responseCode == 200 or responseCode == 201 then
            local inputStream = conn.getInputStream()
            local isr = luajava.newInstance("java.io.InputStreamReader", inputStream, "UTF-8")
            local br = luajava.newInstance("java.io.BufferedReader", isr)
            
            local pasteUrl = br.readLine()
            
            br.close()
            conn.disconnect()
            
            return pasteUrl:gsub("%s+", "")
        else
            conn.disconnect()
            return nil, T("errors.http_error_code", tostring(responseCode))
        end
    end)

    if not status then
        LOG.error(TAG, "POST Request Crashed: " .. tostring(res))
        return nil, T("errors.crashed", tostring(res))
    end

    if not res and err then
        LOG.warn(TAG, "POST Server Rejected: " .. tostring(err))
    end

    return res, err
end

function paste.get(pasteUrl)
    if not pasteUrl or pasteUrl == "" then
        LOG.warn(TAG, "GET Aborted: URL parameter is missing or empty")
        return nil, T("errors.url_missing")
    end

    -- Wrap execution to handle invalid URLs or connection dropping out mid-stream
    local status, res, err = pcall(function()
        local urlInstance = luajava.newInstance("java.net.URL", pasteUrl)
        local conn = urlInstance.openConnection()
        
        conn.setRequestMethod("GET")
        conn.setDoInput(true)
        
        local responseCode = conn.getResponseCode()
        if responseCode == 200 then
            local inputStream = conn.getInputStream()
            local isr = luajava.newInstance("java.io.InputStreamReader", inputStream, "UTF-8")
            local br = luajava.newInstance("java.io.BufferedReader", isr)
            
            local content = ""
            local line = br.readLine()
            while line ~= nil do
                content = content .. line .. "\n"
                line = br.readLine()
            end
            
            br.close()
            conn.disconnect()
            
            if #content > 0 then
                content = content:sub(1, -2)
            end
            
            return content
        else
            conn.disconnect()
            return nil, T("errors.http_error_code", tostring(responseCode))
        end
    end)

    -- If pcall caught an exception (e.g., MalformedURLException)
    if not status then
        LOG.error(TAG, "GET Request Crashed: " .. tostring(res))
        return nil, T("errors.crashed", tostring(res))
    end

    if not res and err then
        LOG.warn(TAG, "GET Server Rejected: " .. tostring(err))
    end

    return res, err
end

return paste
