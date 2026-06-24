-- core/utils/loader.lua — Lazy module registry
-- Usage:
--   loader.register("my_feature", "modules/features/my_feature.lua")
--   local mod = loader.get("my_feature")   -- loads on first call only
--   loader.preload({ "a", "b" })           -- bulk-load a subset
--
-- Globals set by main.lua are available since this loads after them.

local registry = {}  -- id → file path
local cache    = {}  -- id → loaded module (nil = not yet loaded)

local loader = {}

-- Register a module path under an id. Does NOT load the file.
function loader.register(id, path)
    registry[id] = path
end

-- Register a table of { id = path } pairs.
function loader.register_all(map)
    for id, path in pairs(map) do registry[id] = path end
end

-- Retrieve a module by id, loading it on first access.
function loader.get(id)
    if cache[id] ~= nil then
        LOG.dbg("Loader", "Cache hit: " .. id)
        return cache[id]
    end
    local path = registry[id]
    if not path then
        LOG.error("Loader", "Unknown module id: " .. id)
        error("loader: unknown module '" .. id .. "'", 2)
    end
    LOG.info("Loader", "Loading module: " .. id .. " → " .. path)
    local m = loadModule(path)
    cache[id] = m ~= nil and m or false  -- store false to distinguish nil return from "not loaded"
    LOG.info("Loader", "Module cached: " .. id .. " | type=" .. type(m))
    return m
end

-- Eagerly load a list of ids (e.g. for warm-start on tab open).
function loader.preload(ids)
    LOG.info("Loader", "Preloading " .. tostring(#ids) .. " module(s)")
    for _, id in ipairs(ids) do
        if not cache[id] then pcall(loader.get, id) end
    end
end

-- Evict a cached module (forces reload on next get).
function loader.evict(id)
    LOG.info("Loader", "Evicting: " .. id)
    cache[id] = nil
end

-- True if the module has been loaded into cache.
function loader.loaded(id) return cache[id] ~= nil end

return loader
