local nxdraw = {}
nxdraw.__index = nxdraw
local bLookup = {
  [1] = 0x1,  [2] = 0x8, [3] = 0x2,  [4] = 0x10, [5] = 0x4,  [6] = 0x20, [7] = 0x40, [8] = 0x80,
  ["1:1"] = 0x1,  ["2:1"] = 0x8, ["1:2"] = 0x2,  ["2:2"] = 0x10, ["1:3"] = 0x4,  ["2:3"] = 0x20, ["1:4"] = 0x40, ["2:4"] = 0x80,
}
local function dataToCell(celldata)
  local r = 0x2800
  for k, v in pairs(celldata) do
    if v == true then
      r = r + bLookup[k]
    end
  end
  return r
end
--Create new nxdraw
function nxdraw.new(width, height, default)
  local self = setmetatable({}, nxdraw)
  self.default = default or false
  self.canvasCWidth = width
  self.canvasCHeight = height
  self.canvasPWidth = width * 2
  self.canvasPHeight = height * 4
  self.screenData = {}
  self.dirty = {} -- all cells that have been changed since the last render
  self.touched = {} -- all cells that have ben changed do a non-default state

  for w=1, self.canvasCWidth do
    for h=1, self.canvasCHeight do
      local tmp_data = { ["1:1"] = self.default, ["2:1"] = self.default, ["1:2"] = self.default, ["2:2"] = self.default, ["1:3"] = self.default, ["2:3"] = self.default, ["1:4"] = self.default, ["2:4"] = self.default,}
        self:setCell(w, h, tmp_data)
    end
  end
  return self
end
function nxdraw.addDirty(self, theDirty)
  self.dirty[#self.dirty+1] = theDirty
end
function nxdraw.addTouched(self, theTouched)
end
--Clear touched screenData
function nxdraw.clear(self)
  local t = require("term")

  for k,v in pairs(self.touched) do
    local tmp_data = { ["1:1"] = self.default, ["2:1"] = self.default, ["1:2"] = self.default, ["2:2"] = self.default, ["1:3"] = self.default, ["2:3"] = self.default, ["1:4"] = self.default, ["2:4"] = self.default,}
      local w, h = v[1], v[2]
      self:setCell(w, h, tmp_data)
      self.dirty[tostring(w)..":"..tostring(h)] = {[1]=w, [2]=h}
  end
  self.touched = {}
end
--Render only dirty cells
function nxdraw.render(self)
  local t = require("term")

  for k,v in pairs(self.dirty) do
    local w, h = v[1], v[2]
    local d = self:getCell(w, h)
    local c = dataToCell(d)
    t.setCursor(w, h)
    t.write(utf8.char(c))
  end
  self.dirty = {}
end
--Clear all screenData
function nxdraw.clearAll(self)
  for w=1, self.canvasCWidth do
    for h=1, self.canvasCHeight do
      local tmp_data = { ["1:1"] = self.default, ["2:1"] = self.default, ["1:2"] = self.default, ["2:2"] = self.default, ["1:3"] = self.default, ["2:3"] = self.default, ["1:4"] = self.default, ["2:4"] = self.default,}
        self:setCell(w, h, tmp_data)
    end
  end
  self.touched = {}
end
--Render all the cells
function nxdraw.renderAll(self)
  local t = require("term")
  for h=1, self.canvasCHeight do
    for w=1, self.canvasCWidth do
      local d = self:getCell(w, h)
      local c = dataToCell(d)
      t.setCursor(w,h)
      t.write(utf8.char(c))
    end
  end
  self.dirty = {}
end
--Get contents of cell
function nxdraw.getCell(self, cx, cy)
  return(self.screenData[tostring(cx)..":"..tostring(cy)])
end
--Set contents of cell
function nxdraw.setCell(self, cx, cy, value)
  local cell_key = tostring(cx)..":"..tostring(cy)
  self.screenData[cell_key] = value
end
--Get state of pixel
function nxdraw.getPixel(self, xx, yy)
  if not (xx <= 0 or yy <= 0 or xx > self.canvasPWidth or yy > self.canvasPHeight) then
    local cx = math.ceil(xx / 2)
    local cy = math.ceil(yy / 4)
    local lx = (xx - ((cx-1)*2))
    local ly = (yy - ((cy-1)*4))
    return self.screenData[tostring(cx)..":"..tostring(cy)][tostring(lx)..":"..tostring(ly)]
  end
  return nil
end
--Set state of pixel
function nxdraw.setPixel(self, xx, yy, isVisible)
  if not (xx <= 0 or yy <= 0 or xx > self.canvasPWidth or yy > self.canvasPHeight) then
    local cx = math.ceil(xx / 2)
    local cy = math.ceil(yy / 4)
    local lx = (xx - ((cx-1)*2))
    local ly = (yy - ((cy-1)*4))

    local cell_key = tostring(cx)..":"..tostring(cy)

    self.screenData[cell_key][tostring(lx)..":"..tostring(ly)] = isVisible
    --self:addDirty({[1]=cx, [2]=cy})
    self.dirty[cell_key] = {[1]=cx, [2]=cy}
    self.touched[cell_key] = {[1]=cx, [2]=cy}
  end
end
--Draw line using Bresenhams line algorithm
function nxdraw.line(self, x1, y1, x2, y2)
  local delta_x = x2 - x1
  local ix = delta_x > 0 and 1 or -1
  delta_x = 2 * math.abs(delta_x)
  local delta_y = y2 - y1
  local iy = delta_y > 0 and 1 or -1
  delta_y = 2 * math.abs(delta_y)
  local error = 0
  self:setPixel(x1, y1, true)
  if delta_x >= delta_y then
    error = delta_y - delta_x / 2

    while x1 ~= x2 do
      if (error > 0) or ((error == 0) and (ix > 0)) then
        error = error - delta_x
        y1 = y1 + iy
      end
      error = error + delta_y
      x1 = x1 + ix
      self:setPixel(x1, y1, true)
    end
  else
    error = delta_x - delta_y / 2

    while y1 ~= y2 do
      if (error > 0) or ((error == 0) and (iy > 0)) then
        error = error - delta_y
        x1 = x1 + ix
      end

      error = error + delta_x
      y1 = y1 + iy

      self:setPixel(x1, y1, true)
    end
  end
end
function nxdraw.circle(self, x0, y0, radius)

  local x = radius-1
  local y = 0
  local dx = 1
  local dy = 1
  local err = dx - (radius * 2)

  while (x >= y) do
    self:setPixel(x0 + x, y0 + y, true)
    self:setPixel(x0 + y, y0 + x, true)
    self:setPixel(x0 - y, y0 + x, true)
    self:setPixel(x0 - x, y0 + y, true)
    self:setPixel(x0 - x, y0 - y, true)
    self:setPixel(x0 - y, y0 - x, true)
    self:setPixel(x0 + y, y0 - x, true)
    self:setPixel(x0 + x, y0 - y, true)

    if (err <= 0) then
      y = y + 1
      err = err + dy
      dy = dy + 2
    end

    if (err > 0) then
      x = x - 1
      dx = dx + 2
      err = err + (dx - (radius * 2))
    end
  end
end
function nxdraw.rectangle(self, x,y,w,h)
  self:line(x,y,      x+w,y)
  self:line(x,y,      x,y+h)
  self:line(x+w,y+h,  x+w,y)
  self:line(x+w,y+h,  x,y+h)
end
function nxdraw.fill(self, x, y, sval)
  local sval = sval or true
  local dval = self:getPixel(x, y)
  if (not (dval == nil)) then
    if dval ~= sval then
      self:setPixel(x, y, sval)
      self:fill(x+1,  y,    sval)
      self:fill(x-1,  y,    sval)
      self:fill(x,    y+1,  sval)
      self:fill(x,    y-1,  sval)
    end
  end
end
function nxdraw.vfill(self, x, y, sval)
  local sval = sval or true
  local dval = self:getPixel(x, y)
  if (not (dval == nil)) then
    if dval ~= sval then
      self:setPixel(x, y, sval)
      self:vfill(x,    y+1,  sval)
      self:vfill(x,    y-1,  sval)
    end
  end
end
function nxdraw.hfill(self, x, y, sval)
  local sval = sval or true
  local dval = self:getPixel(x, y)
  if (not (dval == nil)) then
    if dval ~= sval then
      self:setPixel(x, y, sval)
      self:hfill(x+1, y, sval)
      self:hfill(x-1, y, sval)
    end
  end
end

return nxdraw