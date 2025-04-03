dofile("sys.lua")
dofile("config.lua")

local component = require("component")
local computer = require("computer")
local event = require("event")

local chatBox = component.isAvailable("chat_box") and component.chat_box or nil
local chatPermissions = {}  -- Хэш-таблица разрешений

Chat = {}
Chat._handler = function(id, adress, nick, msg)
    if (chatBox == nil) then
        return;
    end
    if chatPermissions[nick] then
        if "@exit" == msg then
            chatBox.say("§fЗакрываем программу")
            debug = true
        elseif "@reboot" == msg then
            chatBox.say("§e§lПерезагружаюсь")
            computer.shutdown(true)
        elseif "@help" == msg then
            chatBox.say("Версия программы 0.1")
            chatBox.say("@reboot - Перезагрузить ПК")
            chatBox.say("@exit - Закрыть программу")
        end
    end
end
Chat._sayhandler = function(_, msg)
    if (chatBox == nil) then
        return;
    end
    chatBox.say(msg)
end
Chat.init = function(name)
    if (chatBox == nil) then
        return
    end
    chatBox.setName("§9§l" .. name .."§7§o")

    -----------------------
    -- Установка разрешений
    for i = 1, #playersData do
        local playerName = playersData[i][1]
        if playerName then
            chatPermissions[playerName] = true
        end
    end

    event.listen("chat_say", Chat._sayhandler)
    event.listen("chat_message", Chat._handler)
end

local function exitHandler()
    event.ignore('exit', exitHandler)
    event.ignore("chat_say", Chat._sayhandler)
    event.ignore("chat_message", Chat._handler)
end

event.listen('exit', exitHandler)