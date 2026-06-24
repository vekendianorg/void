-- modules/registry.lua — Lazy tab module registry
-- Returns: tabHandlers (ordered list), categoryHandlers (id → render fn)
--
-- Tab modules are NOT loaded here. Each is loaded exactly once, the first
-- time its tab is opened by the user. This keeps startup allocation flat
-- regardless of how many tabs or features exist.
--
-- To add a tab:
--   1. Append an entry to TAB_DEFS.
--   2. Create the corresponding file in modules/tabs/.
--   3. Add icons to _TAB_ICONS in ui/ui.lua.

local TAB_DEFS = {
    -- { id, display_name_key }
    { "separator", "tabs.sep_game" },
    { "account", "tabs.account" },
    { "vehicle", "tabs.vehicle" },
    { "player", "tabs.player" },
    { "adventure", "tabs.adventure" },
    { "cups", "tabs.cups" },
    { "team", "tabs.team" },
    { "event", "tabs.event" },
    { "creative", "tabs.creative" },
    { "shop", "tabs.shop" },
    { "other", "tabs.other" },
    { "separator", "tabs.sep_script" },
    { "settings", "tabs.settings" },
    { "console", "tabs.console" },
    { "about", "tabs.about" },
}

-- tabHandlers: ordered list of { id, display_name } used by ui.lua for the sidebar.
-- display_name is resolved through T() here (not at TAB_DEFS-literal time) so
-- it always reflects the language active when the menu is (re)built.
local tabHandlers = {}
for _, def in ipairs(TAB_DEFS) do
    tabHandlers[#tabHandlers + 1] = { def[1], T(def[2]) }
end

-- loadCache: id → render function on success, false on permanent failure.
local loadCache = {}

-- categoryHandlers[id](container) — called by ui.lua when a tab is first rendered.
-- Lazily loads the tab file and delegates to its returned render function.
local categoryHandlers = {}

for _, def in ipairs(TAB_DEFS) do
    local id   = def[1]
    local path = "modules/tabs/" .. id .. ".lua"

    categoryHandlers[id] = function(container)
        -- Previously failed — show a permanent error card.
        if loadCache[id] == false then
            addModule(container, id .. "_err", id,
                T("registry.module_load_failed"), "ro", T("registry.error"), nil)
            return
        end

        -- First access: attempt to load.
        -- Soft load: a broken tab returns nil instead of os.exit()'ing the whole
        -- script, so the error card below can actually be shown (a plain
        -- pcall(loadModule, ...) can't catch the hard loader's os.exit).
        if not loadCache[id] then
            local result, err = loadModule(path, true)

            if type(result) == "function" then
                loadCache[id] = result
                LOG.info("Registry", "Module loaded OK: " .. id)
            else
                LOG.error("Registry", "Failed to load module [" .. id .. "]: " .. tostring(err))
                loadCache[id] = false
                addModule(container, id .. "_err", id,
                    T("registry.module_load_failed"), "ro", T("registry.error"), nil)
                return
            end
        end

        -- Run the module; isolate crashes so they don't bring down the whole UI.
        local ok, err = pcall(loadCache[id], container)
        if not ok then
            LOG.error("Registry", "Runtime error in module [" .. id .. "]: " .. tostring(err))
            addModule(container, id .. "_err", id,
                T("registry.module_runtime_error", tostring(err)), "ro", T("registry.error"), nil)
        end
    end
end

return tabHandlers, categoryHandlers
