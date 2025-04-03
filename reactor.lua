dofile("sys.lua")
dofile("utils.lua")

local thread = require("thread")
local event = require('event')
local gui = require("sgui")
local component = require("component")
local unicode = require('unicode')

maxChambers = loadFileData(reactorCntFile)

local reactorUpdateInterval = 15 -- интервал обновления реакторов
reactors = {}
reactorsEuCache = {}
reactorsUpdateState = {}
updateThread = nil

reactorUI = { id = 'reactorEUFrame', inUpdateNow = false }
reactorUI._updateHandler = function()
    if reactorUI.inUpdateNow then
        return
    end

    -- log("запрос waitServerList")
    -- reactors = Proxy.waitServerList("reactor_chamber");
    -- log("Ответ от waitServerList: "..#reactors)

    reactorUI.inUpdateNow = true;
    local reactorChambers = component.list("reactor_chamber", true)
    local _reactors = {}

    for address, _  in reactorChambers do
        table.insert(_reactors, address)
    end

    reactors = _reactors

    if #reactors > maxChambers then
        saveFileData(#reactors, reactorCntFile)
        maxChambers = #reactors
    end

    local notFoundCnt = 0
    updateThread = thread.create(function()
        for i = 1, maxChambers do
            -- log("Зaпрос для реактора: "..reactors[i])
            if reactors[i] then
                reactorsUpdateState[reactors[i]] = true
                -- local reactorEnergy = Proxy.waitServerProxy(reactors[i], "getReactorEUOutput");
                -- log("Ответ от прокси: "..reactorEnergy)
                local reactorEnergy = component.proxy(reactors[i]).getReactorEUOutput();
                reactorsEuCache[reactors[i]] = reactorEnergy
            else
                notFoundCnt = notFoundCnt + 1
            end
            os.sleep(reactorUpdateInterval / maxChambers)
            reactorsUpdateState[reactors[i]] = false
        end
    
        if debug == true and notFoundCnt > 0 then
            log("§c§lНе смог найти реактор, в количестве: §e§l" .. notFoundCnt .. " штук! §fПроверьте или очистите данные! §a[rm " .. reactorCntFile .. "]")
        end

        reactorUI.inUpdateNow = false
    end)
    os.sleep(0)
end

reactorUI.update = function()
    local frameBox = frameBoxes[reactorUI.id]
    local xPos, yPos = frameBox.x, frameBox.y + 1
    local LastX, lastY = 0, 0
    local maxColumns = 5

    local totalEnergy = 0
    local colWidth = math.floor(frameBox.w / maxColumns)

    for i = 1, maxChambers do
        local columnIndex = (i - 1) % maxColumns
        local rowIndex = math.floor((i - 1) / maxColumns)
        local x = xPos + columnIndex * colWidth
        local y = yPos + rowIndex

        local symbol = (reactorsUpdateState[reactors[i]] and "&e" or "&f") .. unicode.char(0x2622)
        local reactorBut = renderTextButton(x, y, symbol.." &fРеактор " .. i .. ":")

        if reactors[i] then
            local reactorEnergy = reactorsEuCache[reactors[i]] and 0 + reactorsEuCache[reactors[i]] or 0
            totalEnergy = totalEnergy + reactorEnergy
            local energyColor = "&a"
            if (reactorEnergy < 420) then
                energyColor = "&4"
            end

            
            gui.text(x + 14, y, energyColor .. energy(reactorEnergy))
        else
            gui.text(x + 14, y, "&4OFF")
        end

        lastY, LastX = yPos + math.floor((i) / maxColumns), xPos + columnIndex * colWidth
    end
    local bottomBox = { x = frameBox.x + frameBox.w - 20, y = frameBox.y + frameBox.h - 3 }
    

    gui.text(bottomBox.x, bottomBox.y, "&fOut: &2" .. energy(totalEnergy)) -- длина 16

    os.sleep(0)
end

reactorUI.renderMain = function(fr, fc)
    return {
        fr = fr,
        fc = fc,
        title = "Реакторы",
        color = gui.colors["border"],
        id = reactorUI.id
    }
end

Proxy.initClient()
event.timer(1, reactorUI._updateHandler)
local updateReactorTimer = event.timer(reactorUpdateInterval + 3, reactorUI._updateHandler, math.huge)

local function exitHandler()
    event.ignore('exit', exitHandler)
    event.cancel(updateReactorTimer)
    updateThread:kill()
    updateThread = nil
    reactorUI = nil
end

event.listen('exit', exitHandler)