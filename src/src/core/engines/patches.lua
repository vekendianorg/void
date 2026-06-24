-- core/engines/patches.lua — Memory patch engine + architecture-aware module helper
-- Exposes globals: addArchModule
-- Depends on: memory, scheduler, gg (all loaded before this file)

-- ── Internal helpers ──────────────────────────────────────────────────────────
--- Reads bytes and compares against allowed values.
---@param base number
---@param patterns table
---@return boolean
local function verify_pattern(base, patterns)
    for _, check in ipairs(patterns) do
        local addr = base + check.offset

        local bytes = gg.getValues({
            {
                address = addr,
                flags = gg.TYPE_BYTE,
            }
        })

        if not bytes or not bytes[1] then
            return false
        end

        -- Read enough bytes for comparison
        local len = #check.valid[1]:gsub("^h%s*", ""):gsub("%s+", "") / 2

        local values = {}
        for i = 0, len - 1 do
            values[#values + 1] = {
                address = addr + i,
                flags = gg.TYPE_BYTE
            }
        end

        local read = gg.getValues(values)

        local hex = {}
        for _, v in ipairs(read) do
            hex[#hex + 1] = string.format("%02X", v.value & 0xFF)
        end

        local current = "h " .. table.concat(hex, " ")

        local ok = false
        for _, expected in ipairs(check.valid) do
            if current == expected then
                ok = true
                break
            end
        end

        if not ok then
            return false
        end
    end

    return true
end

---Returns true if `t` is a flat array of patch entries (each entry has a `scan` key).
---@param t table
---@return boolean
local function is_patch_list(t)
    return type(t) == "table" and type(t[1]) == "table" and t[1].scan ~= nil
end


-- ── Patch engine ──────────────────────────────────────────────────────────────

---Applies or reverts a set of memory patches.
---Addresses are resolved via AoB scan on first use and cached in persistent
---memory so subsequent calls skip the scan entirely.
---
---Patch entry format:
---  scan    = hex byte string for gg.TYPE_BYTE search
---  offset  = byte delta from scan hit to the target DWORD
---  patch   = value to write when enabling
---  unpatch = original value to restore when disabling
---
---@param id      string  Unique patch identifier (used as the cache key)
---@param entries table   Array of patch entries
---@param enable  boolean true → apply patch values, false → revert to unpatch values
---@return number fail_count Number of entries that could not be applied
local function apply_patch(id, entries, enable)
    local fail_count = 0
    local cached     = memory:load(id)

    if cached then
        -- Fast path: addresses already known, skip scanning.
        local writes = {}
        for i, entry in ipairs(entries) do
            if cached[i] then
                table.insert(writes, {
                    address = cached[i],
                    flags   = gg.TYPE_DWORD,
                    value   = enable and entry.patch or entry.unpatch,
                })
            else
                fail_count = fail_count + 1
            end
        end
        if #writes > 0 then gg.setValues(writes) end
    else
        -- Slow path: scan for each entry and cache found addresses.
        local new_cache = {}
        local writes    = {}

        gg.setRanges(8 | 16)
        for i, entry in ipairs(entries) do
            gg.clearResults()
            gg.searchNumber(entry.scan, gg.TYPE_BYTE)
            
            local result_count = gg.getResultsCount()
            
            if result_count > 0 then
                local results = gg.getResults(result_count)
                
                local target_addr
            
                if entry.pattern and #entry.pattern > 0 then
                    gg.refineNumber(results[1].value, 1)
                    local _results = gg.getResults(result_count)
                    for _, result in ipairs(_results) do
                        if verify_pattern(result.address, entry.pattern) then
                            target_addr = result.address + entry.offset
                            break
                        end
                    end
                else
                    -- Legacy behavior
                    target_addr = results[1].address + entry.offset
                end
            
                if target_addr then
                    new_cache[i] = target_addr
            
                    table.insert(writes, {
                        address = target_addr,
                        flags = gg.TYPE_DWORD,
                        value = enable and entry.patch or entry.unpatch
                    })
                else
                    fail_count = fail_count + 1
                end
            else
                fail_count = fail_count + 1
            end
        end

        gg.clearResults()
        if #writes     > 0 then gg.setValues(writes) end
        if fail_count == 0 then memory:save(id, new_cache) end
    end

    return fail_count
end


-- ── Architecture-aware module helper ─────────────────────────────────────────

---Creates a UI module card with automatic architecture validation.
---
---For "switch" mode with a patch table the engine handles enable/disable via
---apply_patch. For all other modes (button, slider, input, …) the value must
---value must be a callback: function(done, ...).
---
---Read-only ("ro") modules bypass arch resolution entirely.
---
---@param parent           View   Parent layout view
---@param id               string Unique module identifier
---@param title            string Display title
---@param desc             string Description shown in the card
---@param mode             string "switch" | "button" | "slider" | "input" | "ro" | …
---@param extra            any    Mode-specific config (options table, slider config, etc.)
---@param patch_or_callback any   Patch list or callback (from aobs table or inline fn)
function addArchModule(parent, id, title, desc, mode, extra, patch_or_callback)
    -- Read-only cards need no arch check.
    if mode == "ro" then
        addModule(parent, id, title, desc, mode, extra, nil)
        return
    end

    -- nil means the data key doesn't exist in aobs/offsets for this version.
    -- Show a "not available for this version" placeholder rather than an arch error.
    if patch_or_callback == nil then
        addModule(parent, id .. "_na", title,
            T("patches.no_data_this_version"),
            "ro", T("common.not_available"), nil)
        return
    end

    -- patch_or_callback is either a patch list or a callback at this point.
    local callback

    if mode == "switch" and is_patch_list(patch_or_callback) then
        -- Patch-backed toggle: delegate to apply_patch inside the scheduler.
        callback = function(done, state)
            scheduler:add(function(finish_task)
                local fail_count = apply_patch(id, patch_or_callback, state)
                if fail_count == 0 then
                    showToast(title .. (state and T("patches.suffix_enabled") or T("patches.suffix_disabled")))
                else
                    showToast(T("patches.pattern_not_found", fail_count))
                end
                gg.clearResults()
                finish_task()
                done()
            end)
        end
    else
        -- Callback-backed module: call directly without wrapping in scheduler:add.
        -- The callback is responsible for its own scheduler:add usage internally.
        -- Wrapping here would cause a deadlock if the callback also calls scheduler:add,
        -- because the outer task would never call finish_task() while waiting on the
        -- inner task, which can't run until the outer task finishes.
        callback = function(done, ...)
            patch_or_callback(done, ...)
        end
    end

    addModule(parent, id, title, desc, mode, extra, callback)
end
