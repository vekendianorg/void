--[[
  Architecture-aware type conversion and memory manipulation library.
  Optimized for high-performance hex scanning using the "h" prefix.
  Supports signed/unsigned integer logic, floating point, and architecture-specific opcodes.
]]

local cast = {}

-- ==========================================
-- INTERNAL HELPERS
-- ==========================================

---Converts binary strings to "h XX XX XX" format for high-speed scanning.
---@param binary_str string
---@return string
local function to_h(binary_str)
    local hex = {}
    for i = 1, #binary_str do
        hex[i] = string.format("%02X", string.byte(binary_str, i))
    end
    return "h " .. table.concat(hex, " ")
end

-- ==========================================
-- SIGNED / UNSIGNED LOGIC (Conversion)
-- ==========================================

function cast.to_uint8(val)  return val & 0xFF end
function cast.to_int8(val)   val = val & 0xFF; return (val >= 0x80) and (val - 0x100) or val end
function cast.to_uint16(val) return val & 0xFFFF end
function cast.to_int16(val)  val = val & 0xFFFF; return (val >= 0x8000) and (val - 0x10000) or val end
function cast.to_uint32(val) return val & 0xFFFFFFFF end
function cast.to_int32(val)  val = val & 0xFFFFFFFF; return (val >= 0x80000000) and (val - 0x100000000) or val end

-- ==========================================
-- NUMERIC HEX PACKERS (Fast H-Format)
-- ==========================================

---@param val number
function cast.byte(val)   return to_h(string.pack((val < 0) and "<b" or "<B", val)) end
---@param val number
function cast.word(val)   return to_h(string.pack((val < 0) and "<h" or "<H", val)) end
---@param val number
function cast.dword(val)  return to_h(string.pack((val < 0) and "<i4" or "<I4", val)) end
---@param val number
function cast.qword(val)  return to_h(string.pack((val < 0) and "<i8" or "<I8", val)) end
---@param val number
function cast.float(val)  return to_h(string.pack("<f", val)) end
---@param val number
function cast.double(val) return to_h(string.pack("<d", val)) end

---@param val number
---@param key number
function cast.xor(val, key)
    return to_h(string.pack("<I4", (val & 0xFFFFFFFF) ~ (key & 0xFFFFFFFF)))
end

-- ==========================================
-- TEXT & ENCODING TYPES
-- ==========================================

---@param text string
function cast.utf8(text) return to_h(text) end

---@param text string
function cast.utf16le(text)
    local output = ""
    for i = 1, #text do output = output .. string.pack("<I2", string.byte(text, i)) end
    return to_h(output)
end

---@param hex_str string
function cast.hex(hex_str)
    local c = hex_str:gsub("%s+", ""):upper()
    local f = {}
    for i = 1, #c, 2 do table.insert(f, c:sub(i, i+1)) end
    return "h " .. table.concat(f, " ")
end

-- ==========================================
-- ARCHITECTURE / OPCODE TYPES
-- ==========================================

---@param opcode number
function cast.arm32(opcode) return to_h(string.pack("<I4", opcode & 0xFFFFFFFF)) end
---@param opcode number
function cast.thumb(opcode) return to_h(string.pack("<I2", opcode & 0xFFFF)) end
---@param opcode number
function cast.arm64(opcode) return to_h(string.pack("<I4", opcode & 0xFFFFFFFF)) end

-- ==========================================
-- AOB UTILITY
-- ==========================================

---Combines multiple cast values into one sequence.
---@param values table
function cast.aob(values)
    local combined = ""
    for _, v in ipairs(values) do
        combined = combined .. v:sub(3) .. " "
    end
    return "h " .. combined:sub(1, -2)
end

return cast
