dofile("sys.lua")

local event = require('event')
local component = require("component")
local modem = component.isAvailable("modem") and component.modem or nil

local function shortJson(obj)
    local payload = type(obj.payload) == 'table' and JSON.string(obj.payload) or obj.payload
    return 'type: '..obj.type..' payload: '..string.sub(payload, 1, 16)..'...'
end

Modem = { debug = false, port = 2000 }
Modem._handler = function(_, __, sender, port, distance, json)
    local object = JSON.parse(json);

    if Modem.debug then
        log('§ahandler §fsender: '..sender..' port: '..port..' distance: '..distance..' '..shortJson(object))
    end

    event.push(object.type, JSON.string(object.payload))
    os.sleep(0)
end
Modem.init = function()
    if (modem == nil) then
        return;
    end
    event.listen('modem_message', Modem._handler)
    modem.open(Modem.port);
end
Modem.send = function(type, payload)
    if (modem == nil) then
        return;
    end
    local obj = { type = type, payload = payload }
    local json = JSON.string(obj)

    local success = modem.broadcast(Modem.port, json)
    if Modem.debug then
        log((success and '§aУспешная' or '§cНеудачная(')..'Отправка json '..shortJson(obj))
    end
    os.sleep(0)
end
Modem.listen = function(type, handler)
    return event.listen(type, handler)
end
Modem.ignore = function(type, handler)
    event.ignore(type, handler)
end
Modem.destroy = function()
    event.ignore('modem_message', Modem._handler)
end
local function exitHandler()
    event.ignore('exit', exitHandler)
    Modem.destroy()
    Modem = nil
end
event.listen('exit', exitHandler)

-- Modem.debug = true
-- Modem.init()
-- local cnt = 0
-- while running do
--     Modem.send("testType", "message "..cnt)
--     cnt = cnt + 1

--     os.sleep(0.3)
-- end