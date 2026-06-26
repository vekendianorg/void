-- core/engines/arch.lua — Architecture detection + chain-based version resolution
-- Sets globals: DEVICE_ARCH, BaseLib, aobs, offsets
-- Depends on: loadModule, memory (already loaded), gg, showDialog, LOG,
--             DEFAULT_ARCH (set in main.lua)

-- ── Architecture detection ────────────────────────────────────────────────────

-- ELF e_machine values read from libcocos2dcpp.so at offset +0x10 (DWORD).
local ARCH_MAP = {
    [11993091] = "arm64-v8a",
    [4063235]  = "x86_64",
    [2621443]  = "armeabi-v7a",
    [196611]   = "x86",
}

local lib_ranges = gg.getRangesList("libcocos2dcpp.so")
if #lib_ranges > 0 then
    local elf_machine = gg.getValues({ { address = lib_ranges[1].start + 0x10, flags = gg.TYPE_DWORD } })[1]
    DEVICE_ARCH = ARCH_MAP[elf_machine and tonumber(elf_machine.value)] or "unknown"
    BaseLib     = lib_ranges[1].start
    LOG.info("Arch", string.format("Lib ranges: %d | BaseLib: 0x%X | e_machine: %s → %s",
        #lib_ranges, BaseLib, tostring(elf_machine and elf_machine.value), DEVICE_ARCH))
else
    LOG.warn("Arch", "libcocos2dcpp.so not found in ranges list")
end

if DEVICE_ARCH == "unknown" then
    LOG.warn("Arch", "Architecture unrecognized — ELF e_machine not in ARCH_MAP")
    showDialog(T("arch.warning_title"),
        T("arch.unknown_arch_msg"),
        T("common.proceed_anyway"))
end

if DEVICE_ARCH ~= "arm64-v8a" then
    LOG.warn("Arch", "Non-primary architecture: " .. DEVICE_ARCH .. " — lib patches may not work")
    showDialog(T("arch.warning_title"),
        T("arch.non_primary_arch_msg", DEVICE_ARCH),
        T("common.proceed_anyway"))
end


-- ── Version comparison ────────────────────────────────────────────────────────

-- Splits "1.73.5" into { 1, 73, 5 }.
local function parse_version(v)
    local ma, mi, pa = v:match("(%d+)%.(%d+)%.(%d+)")
    if not ma then return nil end
    return { tonumber(ma), tonumber(mi), tonumber(pa) }
end

-- Returns -1, 0, or 1 — same contract as C's strcmp.
local function cmp_version(a, b)
    for i = 1, 3 do
        if     a[i] < b[i] then return -1
        elseif a[i] > b[i] then return  1
        end
    end
    return 0
end


-- ── Chain resolution ──────────────────────────────────────────────────────────
--
-- The manifest supplies an ordered `chain` array per arch.  Each entry is:
--
--   { version = "1.73.3", file = "data/arm64-v8a/1.73.3.lua", full = true }
--
-- `full = true`  → the file is a complete baseline (aobs + offsets).
--                  The engine resets its accumulated state before applying it.
--
-- `full = false` (or absent) → the file is a diff.  Only the keys present
--                  inside `aobs` / `offsets` replace the matching keys in the
--                  accumulated state; everything else is kept as-is.
--
-- The engine walks the chain from the beginning up to (and including) the
-- closest entry whose version is ≤ the device's game version, accumulating
-- changes as it goes.  This means:
--
--   • Users on 1.73.3 see exactly the 1.73.3 data.
--   • Users on 1.73.5 see 1.73.3 base + whatever 1.73.5 changed.
--   • Users on 1.74.0 (a new era) see only the fresh 1.74.0 baseline because
--     that entry is marked `full = true`, resetting the accumulated state.
--   • Users on an unknown future version (e.g. 1.75.0) see the last known
--     entry and get a "running on newer version" warning — same behaviour as
--     the old default_base fallback, but now it's the most recent data rather
--     than the oldest.

local function resolve_chain(chain, device_ver_t)
    -- `state` is what we accumulate across the chain walk.
    local state = { aobs = {}, offsets = {} }
    -- `last_applied` tracks the highest version we successfully merged into
    -- state, for the "running on newer game" warning message.
    local last_applied = nil

    for _, entry in ipairs(chain) do
        local entry_ver_t = parse_version(entry.version)
        if not entry_ver_t then
            LOG.warn("Arch", "Chain entry has unparseable version: " .. tostring(entry.version) .. " — skipped")
            goto continue
        end

        -- Stop walking once the chain passes the device version.
        if cmp_version(entry_ver_t, device_ver_t) > 0 then
            LOG.info("Arch", "Chain walk stopped before " .. entry.version .. " (device is older)")
            break
        end

        -- Load the file.
        local ok, data = pcall(loadModule, entry.file)
        if not ok or type(data) ~= "table" then
            LOG.error("Arch", "Failed to load chain entry " .. entry.version .. " (" .. tostring(entry.file) .. "): " .. tostring(data))
            goto continue
        end

        LOG.info("Arch", string.format(
            "Chain entry %s loaded | aobs=%s  offsets=%s  full=%s",
            entry.version,
            type(data.aobs)    == "table" and tostring(#(function() local n=0; for _ in pairs(data.aobs)    do n=n+1 end; return n end)()) .. " groups" or "nil",
            type(data.offsets) == "table" and tostring(#(function() local n=0; for _ in pairs(data.offsets) do n=n+1 end; return n end)()) .. " keys"   or "nil",
            tostring(entry.full)))

        -- A full baseline resets accumulated state before merging.
        if entry.full then
            LOG.info("Arch", "Chain: full baseline reset at " .. entry.version)
            state = { aobs = {}, offsets = {} }
        end

        -- Merge aobs: per-group keys replace existing ones.
        if type(data.aobs) == "table" then
            for k, v in pairs(data.aobs) do
                state.aobs[k] = v
                LOG.dbg("Arch", "  aobs[" .. k .. "] merged")
            end
        else
            LOG.warn("Arch", "  No aobs table in " .. entry.version .. " — patch features will be unavailable")
        end

        -- Merge offsets: per-key replacement.
        if type(data.offsets) == "table" then
            for k, v in pairs(data.offsets) do
                state.offsets[k] = v
                LOG.dbg("Arch", "  offsets[" .. k .. "] = 0x" .. string.format("%X", v))
            end
        else
            LOG.warn("Arch", "  No offsets table in " .. entry.version)
        end

        last_applied = entry.version
        LOG.info("Arch", "Chain: applied " .. entry.version .. (entry.full and " [full]" or " [diff]"))

        ::continue::
    end

    return state, last_applied
end


-- ── Manifest loading ──────────────────────────────────────────────────────────

local manifest    = loadModule("data/manifest.lua")
local pkg_version = gg.getTargetInfo().versionName
LOG.info("Arch", "Game version: " .. tostring(pkg_version) .. " | Arch: " .. tostring(DEVICE_ARCH))

if type(pkg_version) ~= "string" then
    LOG.fatal("Arch", "pkg_version is not a string: " .. type(pkg_version))
    showDialog(T("common.warning"), T("arch.unknown_version_msg"), T("common.ok"))
    os.exit(0)
end

local device_ver_t = parse_version(pkg_version)
if not device_ver_t then
    LOG.fatal("Arch", "Could not parse game version: " .. pkg_version)
    showDialog(T("common.warning"), T("arch.unknown_version_msg"), T("common.ok"))
    os.exit(0)
end

-- Resolve which arch's tree to use.
local arch_t = manifest[DEVICE_ARCH]
if not arch_t then
    LOG.warn("Arch", string.format(
        "No manifest entry for '%s' — falling back to '%s' (lib patches likely won't match)",
        DEVICE_ARCH, DEFAULT_ARCH))
    arch_t = manifest[DEFAULT_ARCH]
end

if not arch_t or not arch_t.chain or #arch_t.chain == 0 then
    LOG.fatal("Arch", "Manifest missing or empty chain for resolved arch — cannot continue")
    showDialog(T("common.warning"), T("arch.no_base_data_msg"), T("common.ok"))
    os.exit(0)
end

-- Walk the chain.
local resolved, last_applied = resolve_chain(arch_t.chain, device_ver_t)

-- Warn if the game version is newer than anything in the chain.
local last_chain_ver_t = parse_version(arch_t.chain[#arch_t.chain].version)
if last_chain_ver_t and cmp_version(device_ver_t, last_chain_ver_t) > 0 then
    LOG.warn("Arch", string.format(
        "Game v%s is newer than the latest chain entry (%s) — using best available data",
        pkg_version, arch_t.chain[#arch_t.chain].version))
    showDialog(T("arch.warning_title"),
        T("arch.newer_version_msg", pkg_version, arch_t.chain[#arch_t.chain].version),
        T("common.proceed_anyway"))
end

local function count(t)
    local n = 0
    for _ in pairs(t) do n = n + 1 end
    return n
end

aobs    = resolved.aobs
offsets = resolved.offsets

LOG.info("Arch", string.format(
    "Data resolved | chain_applied=%s | aobs=%d groups | offsets=%d entries",
    tostring(last_applied), count(aobs), count(offsets)))
