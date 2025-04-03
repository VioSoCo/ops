dofile("utils.lua")

local gui = require("sgui")
local component = require("component")

local MEController = component.isAvailable("me_controller") and component.me_controller or nil

MeUI = { id = 'meControllerFrame' }
MeUI.update = function ()
    local cpuStats = { idle = 0, busy = 0 }
    local frameBox = frameBoxes[MeUI.id]
    local xPos, yPos, lastY = frameBox.x, frameBox.y + 1, 0
    local bottomBox = { x = frameBox.x + frameBox.w - 21, y = frameBox.y + frameBox.h - 3 }

    local maxColumns = 5

    if MEController ~= nil then
        local processors = MEController.getCpus()
        
        for i = 1, #processors do
            local status = processors[i].busy and "&cВ работе" or "&aСвободен"
            local columnIndex = (i - 1) % maxColumns
            local rowIndex = math.floor((i - 1) / maxColumns)
            local x = xPos + columnIndex * math.floor(frameBox.w / maxColumns)
            local y = yPos + rowIndex
            gui.text(x, y, "&fCPU #" .. i .. ": ")
            gui.text(x+10, y, status)
            if processors[i].busy then
                cpuStats.busy = cpuStats.busy + 1
            else
                cpuStats.idle = cpuStats.idle + 1
            end
            lastY = yPos + math.floor((i+1) / maxColumns)
        end

        gui.text(bottomBox.x, bottomBox.y, "       ")
        gui.text(bottomBox.x, bottomBox.y, "&a" .. cpuStats.idle .. " &f/&4 " .. cpuStats.busy) -- 7 символов
    
        gui.text(bottomBox.x + 8 + 7, bottomBox.y, "   ") -- Обнуление пикселей количества процессоров gui.text(80+24, lastY, "   ")
        gui.text(bottomBox.x + 8, bottomBox.y, "&8Всего: &a" .. #processors) -- 10 символов
    else
        gui.text(bottomBox.x - 7, bottomBox.y, "&aНет подключенной МЭ сети(")
    end
end

MeUI.renderMain = function(fr, fc)
    return {
        fr = fr,
        fc = fc,
        title = "МЭ Процессы создания",
        color = gui.colors["border"],
        id = MeUI.id
    }
end