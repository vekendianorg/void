UI = {
    BG = 0x800D001A,
    BG_IMAGE = {
        PATH  = "no_media",
        ALPHA = 255
    },
    HEADER = 0x80110022,
    CARD = 0x331A0028,
    ACCENT = 0x608F3BE8,
    MUTED = 0x4D3D1060,
    TEXT = 0xFFFFFFFF,
    SUB = 0xDDBB99FF,
    RED = 0xFFFF3366,
    GREEN = 0xFF39FF14,
    STROKE = 0x4D4400AA,
    LOGO = 0xFFE040FB,
    GLOW = 0xFFFFFFFF,
    GLASS = 0x18FFFFFF,
    OVERLAY = 0xAA000000,
    TABS_ICON = ">",
    -- Risk-level palette for card badges (see ui.lua buildRiskPill).
    -- BG is a translucent pill fill; TEXT is the solid text/stroke color.
    RISK = {
        VERY_LOW  = { BG = 0x664CAF50, TEXT = 0xFF4CAF50 },
        LOW       = { BG = 0x668BC34A, TEXT = 0xFF8BC34A },
        MEDIUM    = { BG = 0x66FFC107, TEXT = 0xFFFFC107 },
        HIGH      = { BG = 0x66FF5722, TEXT = 0xFFFF5722 },
        VERY_HIGH = { BG = 0x66F44336, TEXT = 0xFFF44336 },
    },
    -- Release-channel badge colors (badge text = RELEASE_CHANNEL from main.lua)
    CHANNEL = {
        ["FOR DEV"]    = { BG = 0x66FFC107, TEXT = 0xFFFFC107 },
        ["FOR TESTER"] = { BG = 0x664CAF50, TEXT = 0xFF4CAF50 },
        ["FOR USER"]   = { BG = 0x66E040FB, TEXT = 0xFFE040FB },
    },
    -- Console tab palette (edit here to retheme the Console tab).
    CONSOLE = {
        INFO      = 0xFFFFFFFF,  -- info-level log text
        WARN      = 0xFFE040FB,  -- warning-level log text
        ERROR     = 0xFFFF3366,  -- error/fatal log text
        DEBUG     = 0xDD5A4A66,  -- debug-level log text (muted)
        CRASH     = 0xFFFF3366,  -- crash card header
        TIMESTAMP = 0x88FFFFFF,  -- timestamps (dimmed white)
    },
    -- Minimized-state icon look: "pill" (default, full-width bar with title
    -- + subtitle + close button), "circle", or "square" (compact draggable
    -- bubble showing just the "V" logo letter). Changeable in Settings.
    ICON_STYLE = "pill"
}

return UI