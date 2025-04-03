dofile("sys.lua")
dofile("utils.lua")
dofile("ui.lua")
dofile("chat.lua")
dofile("tps.lua")

local event = require('event')
local keyboard = require("keyboard")
local component = require("component")
local computer = require("computer")
local term = require("term")
local gui = require("sgui")
local unicode = require('unicode')

local radar = component.isAvailable("radar") and component.radar or nil
local gpu = component.isAvailable("gpu") and component.gpu or nil

gpu.setResolution(160, 50)
widthGui, heightGui = gpu.getResolution()

local boss = 'webdevery'
local playersChache = '/home/data/players.json'
local playersScoreJSON = loadFileData(playersChache)
local PlayersScore = playersScoreJSON == nil and {} or JSON.parse(playersScoreJSON);

local tick = 0;
local function updatePlayersDisplay()
    local players = radar.getPlayers();
    for i = #players, 1, -1 do
        if players[i].name == boss then
            table.remove(players, i);
        end
    end

    local usersBox = frameBoxes[frameNames.usersFrame]
    local maxRowsPerColumn = 4 -- Максимальное количество записей в одном столбце

    local nameList = {};
    for i = 1, #players do
        local player = players[i].name
        PlayersScore[player] = (PlayersScore[player] or 0) + 1
        table.insert(nameList, "&2" .. player) -- .. " &3" .. PlayersScore[player])
    end

    renderList(usersBox, nameList, 'users-list')

    tick = tick + 1
    if tick % 20 == 0 then
        tick = 0
        saveFileData(JSON.string(PlayersScore), playersChache)
    end
end

local function updateTopDisplay()
    local players = {};

    for name, score in pairs(PlayersScore) do
        if (not (name == boss)) then
            table.insert(players, { name = name, score = score })
        end
    end

    table.sort(players, function(a,b) return a.score > b.score end)

    local topBox = frameBoxes["TOP"]
    local maxRowsPerColumn = 4 -- Максимальное количество записей в одном столбце

    local nameList = {};
    for i = 1, #players do
        local player = players[i]
        local color = '&f'
        if i == 1 then
            color = '&6'
        elseif i == 2 then
            color = '&c'
        elseif i == 3 then
            color = '&4'
        elseif i <= 10 then
            color = '&2'
        end

        table.insert(nameList, "&f".. i ..": " .. color .. player.name) -- .. " - &3" .. player.score)
    end

    renderList(topBox, nameList, 'top-list')
end

local function updateBossDisplay()
    for i = 1, #playersData do
        computer.removeUser(playersData[i][1])
    end

    local frameBox = frameBoxes[frameNames.bossFrame]
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
            event.push('chat_say', "§e" .. player .. "§c§l Примчал накодить порядки")
            playersData[i][4] = true
        elseif not isOnline and playersData[i][4] then
            event.push('chat_say', "§e" .. player .. "§c§l Ушел отдыхать")
            playersData[i][4] = false
        end
        computer.addUser(playersData[i][1])
    end
end

framesColor = gui.colors["border"]
frames = {
    { fr = 2, cols = {
        { fc = 4, title = "Top посетителей XXX сикрет шопа", color = framesColor, id = "TOP" },
        tpsUI.renderMain(0, 2),
        { fc = 1, title = "Босс", color = framesColor, id = frameNames.bossFrame },
    }},
    { fr = 3, title = "Сейчас на варпе", color = framesColor, id = frameNames.usersFrame },
    tpsUIChart.renderMain(4, 0)
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

    Chat.init("Варп XXX")
    renderScene(true)

    return true
end
local initResult = init()

while initResult and running do
    updatePlayersDisplay()
    updateBossDisplay()
    updateTopDisplay()

    tpsUI.update()
    tpsUIChart.update()

    local xButPos = renderTextButton(widthGui - 2, 1, "&4"..unicode.char(0x2716));

    if inBounds(xButPos) then
        exit()
    end

    os.sleep(0)
    computer.pullSignal(0.05)
end