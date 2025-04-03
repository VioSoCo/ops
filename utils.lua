dofile("sys.lua")
dofile("config.lua")

local component = require("component")
local fs = require("filesystem")  -- Use the file system component for directory checks.

function energy(eu)
    if eu >= 1000000000000 then
        return string.format("%.1f TEU/t", eu / 1000000000000)
    elseif eu >= 1000000000 then
        return string.format("%.1f GEU/t", eu / 1000000000)
    elseif eu >= 1000000 then
        return string.format("%.1f MEU/t", eu / 1000000)
    elseif eu >= 1000 then
        return string.format("%.1f kEU/t", eu / 1000)
    else
        return string.format("%.1f EU/t", eu)
    end
end


function ensureDirectoryExists(path)
    if path and not fs.isDirectory(path) then
        fs.makeDirectory(path)
    end
end

function loadFileData(fileName)
    ensureDirectoryExists("/home/data")

    local file = io.open(fileName, "r")
    if file then
        local request = tonumber(file:read("*a"))
        file:close()
        return request or 0
    else
        return 0
    end
end

function saveFileData(integer, fileName)
    local file = io.open(fileName, "w")
    if file then
        file:write(tostring(integer))
        file:close()
    end
end

function getPlayerMessage(playerName)
    for _, playerData in ipairs(playersData) do
        if playerData[1] == playerName then
            local message = playerData[3] or "Зашел в игру"
            if playerData[2] == "W" then
                message = "Зашла в игру"
            end
            return message
        end
    end
    return "Зашел в игру"
end

function getComponentsByType(componentType)
    local components = {}
    for address in component.list(componentType) do
        table.insert(components, { address = address})
    end
    return components
end

function componentsCheck(components)
    local missingComponents = {}
    for _, comp in ipairs(components) do
        if not comp.component then
            table.insert(missingComponents, comp.name)
        end
    end
    if #missingComponents > 0 then
        print("The following components are missing:")
        for _, name in ipairs(missingComponents) do
            print(name)
        end
        return false
    end

    return true
end

function inBounds(pos)
    local inBound = touchPos.x >= pos.x and touchPos.x <= pos.x2 and touchPos.y >= pos.y and touchPos.y <= pos.y2
    if inBound then
        touchPos = { x = -1, y = -1 }
    end

    return inBound
end