dofile("sys.lua")
local nxdraw = require("nxdraw")
local component = require("component")
local term = require("term")
local event = require('event')

local gpu = component.isAvailable("gpu") and component.gpu or nil

utf8 = require('unicode')
tc = nxdraw.new(160, 50, false)

local function normX(pos)
    return math.floor(pos / 2 + 0.5)
end
local function normY(pos)
    return math.floor(pos / 4 + 0.5)
end

local function setColor(tps)
    local nTPS = tonumber(tps)
    local color = 0xffffff
    if nTPS <= 10 then
        color = 0xff0000
    elseif nTPS <= 15 then
        color = 0xffff00
    elseif nTPS > 15 then 
        color = 0x66ff66
    end
    gpu.setForeground(color)
end

local function render(x, y, v)
    gpu.set(math.floor(x), math.floor(y), v)
end

local function renderLine(x,y,x2,y2)
    tc:line(math.floor(x), math.floor(y), math.floor(x2), math.floor(y2))
end

local function safeCenterX(x, v, box)
    local len = string.len(v)
    local shift = math.floor(len / 2)
    local c = x - shift
    if c + len >= box.x + box.w then
        return box.x + box.w - len
    elseif c <= box.x then
        return box.x
    else
        return c
    end
end

local extremumP = {}

local function renderChart(box, points, cnt)
    local normBox = { x = normX(box.x), y = normY(box.y), w = normX(box.w), h = normY(box.h) }
    if #points < 2 then
        return
    end

    tc:clear()

    local lMin = math.min(table.unpack(points)) + 1.0 - 1.0
    local lMax = math.max(table.unpack(points)) + 1.0 - 1.0

    local min = 2
    local max = 20
    local k = box.h / ((max - min) <= 0 and 2 or max - min)

    local step = box.w / cnt
    local lastPos = { x = math.floor(box.x), y = math.floor(box.y + box.h / 2) }

    for i = 1, #extremumP, 1 do
        exP = extremumP[i]
        render(safeCenterX(exP.x, exP.v, normBox), exP.y, string.rep(" ", string.len(exP.v)))
    end

    extremumP = {}

    local findedTop = false
    local findedBot = false
    for i = 1, #points, 1 do
        local p = math.max(math.min(points[i] - 1.0 + 1.0, 20), 2)

        local x = math.floor(box.x + i * step)
        local y = math.floor(box.y + k * (max - p))

        renderLine(lastPos.x, lastPos.y, x, y)

        local tx = normX(x)
        if p >= lMax and not findedTop then
            table.insert(extremumP, { x = tx, y = normY(y) - 1, v = " " .. math.floor(p * 100) / 100 })
            findedTop = true
        elseif p <= lMin and not findedBot then
            table.insert(extremumP, { x = tx, y = normY(y) + 1, v = " " .. math.floor(p * 100) / 100 })
            findedBot = true
        end

        lastPos.x = x
        lastPos.y = y
    end

    tc:render()

    for i = 1, #extremumP, 1 do
        exP = extremumP[i]
        setColor(exP.v)
        render(safeCenterX(exP.x, exP.v, normBox), exP.y, exP.v)
    end
    
    os.sleep(0)
end

chartUI = {}
chartUI.render = function(_box, points, cnt)
    local xk,yk = 2,4
    local box = { x = _box.x * xk, y = (_box.y) * yk, w = (_box.w - 4) * xk, h = (_box.h - 5) * yk }
    local cX = math.floor(box.w / 2 + box.x)
    local cY = math.floor(box.h / 2 + box.y)

    local chartX = math.floor(cX - box.w / 2 + 0.5)
    local chartY = math.floor(cY - box.h / 2 + 0.5)

    renderChart({ x = chartX, y = chartY, w = box.w, h = box.h }, points, cnt)
end

local function exitHandler()
    event.ignore('exit', exitHandler)
    chartUI = { render = emptyFn }
    tc = nil
end
event.listen('exit', exitHandler)

