dofile("sys.lua")
dofile("utils.lua")
dofile("ui.lua")
dofile("chat.lua")
dofile("flux.lua")
dofile("reactor.lua")
dofile("me.lua")
dofile("tps.lua")

local event = require('event')
local keyboard = require("keyboard")
local component = require("component")
local computer = require("computer")
local term = require("term")
local gui = require("sgui")
local unicode = require('unicode')

local gpu = component.isAvailable("gpu") and component.gpu or nil

gpu.setResolution(160, 50)
widthGui, heightGui = gpu.getResolution()

local function updatePlayersDisplay()
    for i = 1, #playersData do
        computer.removeUser(playersData[i][1])
    end

    local frameBox = frameBoxes[frameNames.usersFrame]
    local numColumns = 3 -- Количество столбцов
    local maxRowsPerColumn = 4 -- Максимальное количество записей в одном столбце
    local columnWidth = math.floor(frameBox.w / numColumns) -- Ширина столбца

    for i = 1, #playersData do
        local player = playersData[i][1]
        local isOnline = computer.addUser(player)

        local columnIndex = (i - 1) % numColumns
        local rowIndex = math.floor((i - 1) / numColumns) % maxRowsPerColumn + 1 -- Учитываем ограничение по количеству записей в столбце

        local x = frameBox.x + columnIndex * columnWidth
        local y = rowIndex + 3

        if i <= 12 then
            local prefix = ""
            if isOnline then
                prefix = "&2" -- Зеленый цвет для игроков в сети
            else
                prefix = "&4" -- Красный цвет для игроков не в сети
            end
            prefix = prefix .. player
            gui.text(x, y, prefix)
        end
        local message = getPlayerMessage(player)
        if isOnline and not playersData[i][4] then
            event.push('chat_say', "§e" .. player .. "§a§l " .. message)
            playersData[i][4] = true
        elseif not isOnline and playersData[i][4] then
            event.push('chat_say', "§e" .. player .. "§c§l покинул игру!")
            playersData[i][4] = false
        end
        computer.addUser(playersData[i][1])
    end
end

framesColor = gui.colors["border"]
frames = {
    { fr = 2, cols = {
        fluxUI.renderMain(0, 2),
        { fc = 2, title = "Игроки", color = framesColor, id = frameNames.usersFrame },
        tpsUI.renderMain(0, 1),
    }},
    tpsUIChart.renderMain(2, 0),
    MeUI.renderMain(4, 0),
    reactorUI.renderMain(4, 0)
}

local function renderScene(clear)
    if clear then
        term.clear()
    end

    gui.drawMain("&d" .. TableTitle, gui.colors["9"], "1.1")
    local mainBox = { x = 2, y = 2, w = widthGui - 2.5, h = heightGui - 2.5 }

    frameBoxes = renderFrameGroup(mainBox, frames, {})
end

local function init()
    -----------------------
    -- Проверка компонентов
    local successCheck = componentsCheck({
        {name = "GPU", component = gpu},
    })

    if not successCheck then
        return false
    end

    Chat.init("Мониторинг")
    renderScene(true)

    return true
end
local initResult = init()

while initResult and running do
    fluxUI.update()
    updatePlayersDisplay()
    MeUI.update()
    tpsUI.update()
    tpsUIChart.update()

    reactorUI.update()

    local xButPos = renderTextButton(widthGui - 2, 1, "&4"..unicode.char(0x2716));

    if inBounds(xButPos) then
        exit()
    end

    os.sleep(0)
    computer.pullSignal(0.05)
end