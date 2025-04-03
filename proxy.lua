dofile("sys.lua")
dofile("modem.lua")

local component = require("component")
local event = require('event')

Proxy = { debug = false }
Proxy.initClient = function()
    Modem.debug = true
    Modem.init()
end
Proxy.waitServerProxy = function(address, method)
    Modem.send('proxy_component_calc', {
        address = address,
        method = method,
    })
    local _, result = event.pull(10, address..string.lower(method))
    log('waitServerProxy result: §f'..result)

    return JSON.parse(result).result
end

Proxy.waitServerList = function(name)
    Modem.send('proxy_component_list', { name = name })
    local _, result = event.pull(5, "components_list"..name)
    log('§bwaitServerList §fresult len: §f'..#result)

    return JSON.parse(result)
end

Proxy.processProxyServer = function(_, json)
    local payload = JSON.parse(json)
    local result = component.proxy(payload.address)[payload.method]();

    if Proxy.debug then
        log('§bprocessProxyServer §fsuccess: §f'..payload.address..'/'..payload.method..' result: '..result)
    end

    Modem.send(payload.address..string.lower(payload.method), { result = result })
end

Proxy.processComponentsListServer = function(_, json)
    local payload = JSON.parse(json)
    if Proxy.debug then
        log('§bprocessComponentsListServer: §f'..payload.name)
    end

    local result = component.list(payload.name);

    local resultAraay = {}
    for address, _  in result do
        table.insert(resultAraay, address)
    end

    if Proxy.debug then
        log('§bprocessComponentsListServer: §f'..payload.name..' cnt: '..#resultAraay)
    end

    Modem.send("components_list"..payload.name, resultAraay)
end

Proxy.waitClient = function()
    Proxy.debug = true
    Modem.debug = true
    Modem.init()
    event.listen('proxy_component_list', Proxy.processComponentsListServer)
    event.listen('proxy_component_calc', Proxy.processProxyServer)

    event.timer(5, function()
        event.push('proxy_component_list', JSON.string({ name = "reactor_chamber" }))
    end)
end

local function exitHandler()
    event.ignore('proxy_component_list', Proxy.processComponentsListServer)
    event.ignore('proxy_component_calc', Proxy.processProxyServer)
    event.ignore('exit', exitHandler)

    Proxy = nil
end
event.listen('exit', exitHandler)