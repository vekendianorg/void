--[[
  core/engines/alloc.lua — Memory allocation management
  Finds and claims zero regions in game memory for structured data (pointer arrays, etc.)
]]

local alloc = {}

local _claimed = {}

local TAG = "alloc"

local DEFAULTS = {
  state  = "Ca",
  size   = { min = nil, max = nil },
  flags  = 4,
  step   = 4,
  align  = 4,
}

-- ─── helpers ──────────────────────────────────────────────────────────────────

local function mergeOpts(opts)
  local o = {}
  for k, v in pairs(DEFAULTS) do
    o[k] = (type(v) == "table") and { min = v.min, max = v.max } or v
  end
  if opts then
    for k, v in pairs(opts) do
      if k == "size" and type(v) == "table" then
        o.size = { min = v.min, max = v.max }
      else
        o[k] = v
      end
    end
  end
  return o
end

local function alignUp(addr, align)
  if align <= 1 then return addr end
  local rem = addr % align
  return rem == 0 and addr or (addr + align - rem)
end

local function isClaimed(base, size)
  for claimedBase, info in pairs(_claimed) do
    local claimedEnd = claimedBase + info.size
    local reqEnd     = base + size
    if base < claimedEnd and reqEnd > claimedBase then
      return true
    end
  end
  return false
end

local function readSlots(base, size, step, flags)
  local reads = {}
  local addr  = base
  while addr < base + size do
    table.insert(reads, { address = addr, flags = flags })
    addr = addr + step
  end
  return gg.getValues(reads)
end

local function allZero(values)
  if not values then return false end
  for _, v in ipairs(values) do
    if v.value ~= 0 then return false end
  end
  return true
end

-- ─── alloc.findEmpty ──────────────────────────────────────────────────────────

function alloc.findEmpty(size, opts)
  local o       = mergeOpts(opts)
  local minSize = (o.size.min ~= nil) and o.size.min or size
  local maxSize = o.size.max
  local regions = gg.getRangesList()

  LOG.dbg(TAG, string.format("findEmpty: scanning for %d bytes (state=%s, align=%d, flags=%d)", size, o.state, o.align, o.flags))

  local scanned, skippedState, skippedSize, skippedClaimed, skippedDirty = 0, 0, 0, 0, 0

  for _, region in ipairs(regions) do
    scanned = scanned + 1
    local regionSize = region["end"] - region.start

    if region.state ~= o.state then
      skippedState = skippedState + 1
    elseif regionSize < minSize or (maxSize ~= nil and regionSize > maxSize) then
      skippedSize = skippedSize + 1
    else
      local base = alignUp(region.start, o.align)
      if base + size > region["end"] then
        skippedSize = skippedSize + 1
      elseif isClaimed(base, size) then
        skippedClaimed = skippedClaimed + 1
        LOG.dbg(TAG, string.format("findEmpty: 0x%X already claimed, skipping", base))
      else
        local values = readSlots(base, size, o.step, o.flags)
        if allZero(values) then
          LOG.info(TAG, string.format("findEmpty: found empty region @ 0x%X (regionSize=%d)", base, regionSize))
          LOG.dbg(TAG, string.format("findEmpty: scanned=%d skippedState=%d skippedSize=%d skippedClaimed=%d skippedDirty=%d", scanned, skippedState, skippedSize, skippedClaimed, skippedDirty))
          return base
        else
          skippedDirty = skippedDirty + 1
        end
      end
    end
  end

  LOG.warn(TAG, string.format("findEmpty: no empty region found for %d bytes", size))
  LOG.dbg(TAG, string.format("findEmpty: scanned=%d skippedState=%d skippedSize=%d skippedClaimed=%d skippedDirty=%d", scanned, skippedState, skippedSize, skippedClaimed, skippedDirty))
  return nil
end

-- ─── alloc.new ────────────────────────────────────────────────────────────────

function alloc.new(size, opts)
  local o    = mergeOpts(opts)
  LOG.info(TAG, string.format("new: requesting %d bytes (flags=%d, step=%d, align=%d)", size, o.flags, o.step, o.align))

  local base = alloc.findEmpty(size, o)
  if not base then
    LOG.error(TAG, string.format("new: failed to allocate %d bytes", size))
    return nil
  end

  _claimed[base] = { size = size, step = o.step, flags = o.flags }
  LOG.info(TAG, string.format("new: claimed 0x%X (%d bytes)", base, size))

  return alloc.at(base, size, o)
end

-- ─── alloc.at ─────────────────────────────────────────────────────────────────

function alloc.at(base, size, opts)
  local o = mergeOpts(opts)
  LOG.info(TAG, string.format("at: wrapping 0x%X (%d bytes, flags=%d, step=%d)", base, size, o.flags, o.step))

  local handle = {
    base  = base,
    size  = size,
    step  = o.step,
    flags = o.flags,
  }

  function handle:read()
    LOG.dbg(TAG, string.format("read: 0x%X (%d bytes)", self.base, self.size))
    local values = readSlots(self.base, self.size, self.step, self.flags)
    if not values then
      LOG.warn(TAG, string.format("read: gg.getValues returned nil @ 0x%X", self.base))
    else
      LOG.dbg(TAG, string.format("read: got %d slots @ 0x%X", #values, self.base))
    end
    return values
  end

  function handle:write(values)
    LOG.info(TAG, string.format("write: %d values → 0x%X", #values, self.base))
    local writes = {}
    local addr   = self.base
    for i, v in ipairs(values) do
      table.insert(writes, { address = addr, flags = self.flags, value = v })
      LOG.dbg(TAG, string.format("write: [%d] 0x%X = %s", i, addr, tostring(v)))
      addr = addr + self.step
    end
    local result = gg.setValues(writes)
    if not result then
      LOG.error(TAG, string.format("write: gg.setValues failed @ 0x%X", self.base))
    else
      LOG.info(TAG, string.format("write: ok (%d slots written)", #writes))
    end
  end

  function handle:zero()
    LOG.info(TAG, string.format("zero: clearing 0x%X (%d bytes)", self.base, self.size))
    local slots = {}
    local addr  = self.base
    while addr < self.base + self.size do
      table.insert(slots, { address = addr, flags = self.flags, value = 0 })
      addr = addr + self.step
    end
    local result = gg.setValues(slots)
    if not result then
      LOG.error(TAG, string.format("zero: gg.setValues failed @ 0x%X", self.base))
    else
      LOG.dbg(TAG, string.format("zero: ok (%d slots cleared)", #slots))
    end
  end

  function handle:free()
    LOG.info(TAG, string.format("free: releasing 0x%X (%d bytes)", self.base, self.size))
    self:zero()
    _claimed[self.base] = nil
    LOG.info(TAG, string.format("free: 0x%X unclaimed", self.base))
  end

  function handle:dump()
    LOG.dbg(TAG, string.format("dump: 0x%X (%d bytes)", self.base, self.size))
    local values = self:read()
    if values then
      for i, v in ipairs(values) do
        LOG.dbg(TAG, string.format("dump: [%d] 0x%X = %s", i, v.address, tostring(v.value)))
      end
    else
      LOG.warn(TAG, string.format("dump: no values @ 0x%X", self.base))
    end
  end

  return handle
end

-- ─── alloc.claimed ────────────────────────────────────────────────────────────

function alloc.claimed()
  local out = {}
  for k, v in pairs(_claimed) do out[k] = v end
  return out
end

return alloc