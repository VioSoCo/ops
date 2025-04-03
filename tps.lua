dofile("utils.lua")
dofile("chart.lua")

local gui = require("sgui")
local component = require("component")

local fs = require("filesystem")
local TC = 0.3;
local RO, RN, RD, TPS = 0, 0, 0;
local maxTpsHistoryLen = 50;
tpsHistory = {}

local function normTps(tps)
    return math.max(math.min(tonumber(tps), 20), 2)
end

local function time()
    local f = io.open(tpsFile, "w")
    f:write("test")
    f:close()
    return(fs.lastModified(tpsFile))
end

local function tpsFormat(tps)
    local nTPS = tonumber(tps)
    local color = "&f"
    if nTPS <= 10 then
        color = "&4"
    elseif nTPS <= 15 then
        color = "&e"
    elseif nTPS > 15 then 
        color = "&a"
    end

    return color .. tps
end

tpsUI = { id = 'tpsFrame' }
tpsUI.update = function()
    local frameBox = frameBoxes[tpsUI.id]
    local posX, posY = frameBox.x, frameBox.y + 1

    RO = time()
    os.sleep(TC) 
    RN = time()

    RD = RN - RO
    TPS = 20000 * TC / RD
    TPS = normTps(string.sub(TPS, 1, 5))

    table.insert(tpsHistory, TPS)
    if #tpsHistory > maxTpsHistoryLen then
        table.remove(tpsHistory, 1)
    end

    local sum = 0
    for i = 1, #tpsHistory do
        sum = sum + tpsHistory[i]
    end
    local averageTPS = string.sub(sum / #tpsHistory, 1, 5)

    gui.text(posX, posY, string.rep(" ", 6))
    gui.text(posX, posY + 14, string.rep(" ", 6))

    gui.text(posX, posY, tpsFormat(TPS))
    gui.text(posX + 6, posY, "&fСредний:"..tpsFormat(averageTPS))
    os.sleep(0)
end

tpsUI.renderMain = function(fr, fc)
    return {
        fr = fr,
        fc = fc,
        title = "TPS Сервера",
        color = gui.colors["border"],
        id = tpsUI.id
    }
end

tpsUIChart = { id = 'tpsFrameChart' }
tpsUIChart.update = function()
    local frameBox = frameBoxes[tpsUIChart.id]
    chartUI.render(frameBox, tpsHistory, maxTpsHistoryLen)
end

tpsUIChart.renderMain = function(fr, fc)
    return {
        fr = fr,
        fc = fc,
        title = "История TPS Сервера",
        color = gui.colors["border"],
        id = tpsUIChart.id
    }
end
