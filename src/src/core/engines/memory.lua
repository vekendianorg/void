--[[
  Persistent memory handler module
  Manages saving and loading of game state data.

  Two storage scopes:
    Process-scoped  (save / load)             — tied to the current target PID.
                                                Data is wiped automatically when
                                                the process changes (game restart).
    Global-scoped   (save_global / load_global) — PID-independent; survives
                                                across restarts. Intended for user
                                                preferences such as UI colors that
                                                should never be cleared by a process
                                                switch.
]]

-- NOTE: File is imported globally in main.lua; no local import needed here.

-- Shared serializer used by both save scopes.
-- Handles tables (recursively), strings, and scalar values.
local function serialize(v)
    if type(v) == "table" then
        local s = "{"
        for k, val in pairs(v) do
            local key = type(k) == "number" and "[" .. k .. "]" or string.format("[%q]", k)
            s = s .. key .. "=" .. serialize(val) .. ","
        end
        return s .. "}"
    elseif type(v) == "string" then
        return string.format("%q", v)
    else
        return tostring(v)
    end
end

local memory = {
    -- ── Process-scoped helpers ────────────────────────────────────────────────

    ---Checks whether the current GG session is still attached to the same PID.
    ---Clears all process-scoped data automatically when the process changes.
    ---@return boolean True if session is valid (same PID), false if it changed.
    _check_session = function(self)
        local target = gg.getTargetInfo()
        if not target then return false end

        local current_pid = target.pid
        local pid_file    = gg.FILES_DIR .. "/" .. target.packageName

        local old_pid
        local f = io.open(pid_file, "r")
        if f then
            old_pid = tonumber(f:read("*all"))
            f:close()
        end

        if old_pid ~= current_pid then
            self:clear_all()
            f = io.open(pid_file, "w")
            if f then
                f:write(tostring(current_pid))
                f:close()
            end
            return false
        end
        return true
    end,

    ---Saves data to process-scoped persistent storage.
    ---Keyed by package name + PID; automatically invalidated on process change.
    ---@param id   string Unique identifier (e.g. "gamestatus", "toggle_states")
    ---@param data any    Data to persist (tables are serialized recursively)
    ---@return boolean True if the write succeeded
    save = function(self, id, data)
        self:_check_session()
        local target = gg.getTargetInfo()
        if not (target and data ~= nil) then
            LOG.warn("Memory", "save() skipped — no target or nil data | id=" .. tostring(id))
            return false
        end

        local file_path = gg.FILES_DIR .. "/" .. target.packageName .. "-memoryHandlers-" .. id
        local f = io.open(file_path, "w")
        if f then
            f:write("return " .. serialize(data))
            f:close()
            LOG.dbg("Memory", "Saved: " .. id)
            return true
        end
        LOG.error("Memory", "save() failed to open file for: " .. id)
        return false
    end,

    ---Loads previously saved process-scoped data.
    ---Returns nil if the session changed or the data file does not exist.
    ---@param id string Unique identifier for the data to load
    ---@return any Loaded data, or nil
    load = function(self, id)
        if not self:_check_session() then
            LOG.dbg("Memory", "load() skipped — session changed | id=" .. tostring(id))
            return nil
        end

        local target = gg.getTargetInfo()
        if not target then return nil end
        local file_path = gg.FILES_DIR .. "/" .. target.packageName .. "-memoryHandlers-" .. id
        local chunk = loadfile(file_path)
        if chunk then
            LOG.dbg("Memory", "Loaded: " .. id)
        else
            LOG.dbg("Memory", "No cache for: " .. id)
        end
        return chunk and chunk() or nil
    end,

    ---Deletes a single process-scoped cache entry by id.
    ---Safe to call even if the entry does not exist.
    ---@param id string Unique identifier to delete
    ---@return boolean True if the file was deleted, false if it didn't exist or failed
    delete = function(self, id)
        local target = gg.getTargetInfo()
        if not target then
            LOG.warn("Memory", "delete() skipped — no target | id=" .. tostring(id))
            return false
        end
        local file_path = gg.FILES_DIR .. "/" .. target.packageName .. "-memoryHandlers-" .. id
        local ok = os.remove(file_path)
        if ok then
            LOG.info("Memory", "Deleted: " .. id)
        else
            LOG.dbg("Memory", "delete() — file not found or already gone: " .. id)
        end
        return ok ~= nil
    end,

    ---Deletes all process-scoped data files for the current package.
    ---Called automatically when a PID change is detected.
    ---@return nil
    clear_all = function(self)
        local target = gg.getTargetInfo()
        if not target then return end
        local prefix    = target.packageName .. "-memoryHandlers-"
        local directory = File(gg.FILES_DIR)
        local files     = directory:listFiles()
        local count = 0
        if files then
            for i = 1, #files do
                local file = files[i]
                if file:getName():find(prefix, 1, true) == 1 then
                    file:delete()
                    count = count + 1
                end
            end
        end
        LOG.info("Memory", "clear_all() removed " .. tostring(count) .. " cache files")
    end,

    -- ── Global-scoped helpers ─────────────────────────────────────────────────

    ---Saves data to global persistent storage.
    ---Not tied to any process or package; survives game restarts and
    ---process switches. Intended for user preferences (UI colors, etc.).
    ---@param id   string Unique identifier (e.g. "ui_prefs")
    ---@param data any    Data to persist (tables are serialized recursively)
    ---@return boolean True if the write succeeded
    save_global = function(self, id, data)
        if data == nil then return false end
        local file_path = gg.FILES_DIR .. "/void-global-" .. id
        local f = io.open(file_path, "w")
        if f then
            f:write("return " .. serialize(data))
            f:close()
            return true
        end
        return false
    end,

    ---Loads previously saved global data.
    ---Returns nil if the file does not exist or cannot be parsed.
    ---@param id string Unique identifier for the data to load
    ---@return any Loaded data, or nil
    load_global = function(self, id)
        local file_path = gg.FILES_DIR .. "/void-global-" .. id
        local chunk = loadfile(file_path)
        return chunk and chunk() or nil
    end,

    ---Deletes a single global cache entry by id.
    ---Safe to call even if the entry does not exist.
    ---@param id string Unique identifier to delete
    ---@return boolean True if the file was deleted, false if it didn't exist or failed
    delete_global = function(self, id)
        local file_path = gg.FILES_DIR .. "/void-global-" .. id
        local ok = os.remove(file_path)
        if ok then
            LOG.info("Memory", "Deleted global: " .. id)
        else
            LOG.dbg("Memory", "delete_global() — file not found or already gone: " .. id)
        end
        return ok ~= nil
    end,

    ---Deletes all global cache files (void-global-* prefix).
    ---Use with caution — this wipes all persisted user preferences and global state.
    ---@return nil
    clear_all_global = function(self)
        local prefix    = "void-global-"
        local directory = File(gg.FILES_DIR)
        local files     = directory:listFiles()
        local count = 0
        if files then
            for i = 1, #files do
                local file = files[i]
                if file:getName():find(prefix, 1, true) == 1 then
                    file:delete()
                    count = count + 1
                end
            end
        end
        LOG.info("Memory", "clear_all_global() removed " .. tostring(count) .. " global files")
    end,
}

return memory
