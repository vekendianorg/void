local catbox = {}
local TAG = "CATBOX_SERVICE"

-- Helper to safely generate a primitive byte[] buffer
local function getByteBuffer(size)
    return Array.newInstance(Byte.TYPE, size)
end

-- ==========================================
-- UPLOAD
-- ==========================================
function catbox.upload(filePath, fileName)
    if not filePath or filePath == "" then
        if LOG and LOG.warn then LOG.warn(TAG, "Upload Aborted: File path is missing") end
        return nil, T("errors.file_path_missing")
    end

    -- Automatically extract filename from path if not provided
    fileName = fileName or filePath:match("[^/]+$") or "void_export_image.png"

    local status, res, err = pcall(function()
        local targetUrl = "https://catbox.moe/user/api.php"
        local url = luajava.newInstance("java.net.URL", targetUrl)
        local conn = url.openConnection()
        
        local boundary = "----VekendianVoidBoundary" .. tostring(os.time())
        
        conn.setDoOutput(true)
        conn.setRequestMethod("POST")
        conn.setRequestProperty("Content-Type", "multipart/form-data; boundary=" .. boundary)
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        
        local os_stream = conn.getOutputStream()
        local dos = luajava.newInstance("java.io.DataOutputStream", os_stream)
        
        dos.writeBytes("--" .. boundary .. "\r\n")
        dos.writeBytes("Content-Disposition: form-data; name=\"reqtype\"\r\n\r\n")
        dos.writeBytes("fileupload\r\n")
        
        dos.writeBytes("--" .. boundary .. "\r\n")
        dos.writeBytes("Content-Disposition: form-data; name=\"fileToUpload\"; filename=\"" .. fileName .. "\"\r\n")
        dos.writeBytes("Content-Type: application/octet-stream\r\n\r\n")
        
        local fis = luajava.newInstance("java.io.FileInputStream", filePath)
        local buffer = getByteBuffer(4096)
        
        local bytesRead = fis.read(buffer)
        while bytesRead ~= -1 do
            dos.write(buffer, 0, bytesRead)
            bytesRead = fis.read(buffer)
        end
        fis.close()
        
        dos.writeBytes("\r\n--" .. boundary .. "--\r\n")
        dos.flush()
        dos.close()
        
        local responseCode = conn.getResponseCode()
        if responseCode == 200 then
            local is = conn.getInputStream()
            local isr = luajava.newInstance("java.io.InputStreamReader", is)
            local br = luajava.newInstance("java.io.BufferedReader", isr)
            
            local catboxUrl = br.readLine()
            
            br.close()
            conn.disconnect()
            return catboxUrl
        else
            conn.disconnect()
            return nil, T("errors.http_error_code", tostring(responseCode))
        end
    end)

    if not status then
        if LOG and LOG.error then LOG.error(TAG, "Upload Request Crashed: " .. tostring(res)) end
        return nil, T("errors.crashed", tostring(res))
    end

    if not res and err then
        if LOG and LOG.warn then LOG.warn(TAG, "Catbox Server Rejected: " .. tostring(err)) end
    end

    return res, err
end

-- ==========================================
-- DOWNLOAD
-- ==========================================
function catbox.download(fileUrl, destPath)
    if not fileUrl or fileUrl == "" then
        if LOG and LOG.warn then LOG.warn(TAG, "Download Aborted: URL is missing") end
        return nil, T("errors.download_url_missing")
    end
    
    if not destPath or destPath == "" then
        if LOG and LOG.warn then LOG.warn(TAG, "Download Aborted: Destination path missing") end
        return nil, T("errors.dest_path_missing")
    end

    local status, res, err = pcall(function()
        local urlInstance = luajava.newInstance("java.net.URL", fileUrl)
        local conn = urlInstance.openConnection()
        
        conn.setRequestMethod("GET")
        conn.setDoInput(true)
        conn.setRequestProperty("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64)")
        
        local responseCode = conn.getResponseCode()
        if responseCode == 200 then
            local inputStream = conn.getInputStream()
            local fos = luajava.newInstance("java.io.FileOutputStream", destPath)
            
            -- Patched the buffer initialization here as well
            local buffer = getByteBuffer(4096)
            
            local bytesRead = inputStream.read(buffer)
            while bytesRead ~= -1 do
                fos.write(buffer, 0, bytesRead)
                bytesRead = inputStream.read(buffer)
            end
            
            fos.flush()
            fos.close()
            inputStream.close()
            conn.disconnect()
            
            return destPath
        else
            conn.disconnect()
            return nil, T("errors.http_error_code", tostring(responseCode))
        end
    end)

    if not status then
        if LOG and LOG.error then LOG.error(TAG, "Download Request Crashed: " .. tostring(res)) end
        return nil, T("errors.crashed", tostring(res))
    end

    if not res and err then
        if LOG and LOG.warn then LOG.warn(TAG, "Catbox Server Rejected Download: " .. tostring(err)) end
    end

    return res, err
end

return catbox
