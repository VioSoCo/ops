local term = require("term")
local event = require('event')
local serialization = require("serialization")
local component = require("component")

local gpu = component.gpu
local chatBox = component.isAvailable("chat_box") and component.chat_box or nil
local b_color = gpu.getBackground()

ctrlPressed = false
running = true
touchPos = { x = -1, y = -1 }

JSON = {}
JSON.parse = function(json)
    return serialization.unserialize(json);
end
JSON.string = function(object)
    return serialization.serialize(object);
end

local function touchHandler(id, _, cX, cY)
    touchPos = { x = cX or -1, y = cY or -1 }
end

local function downHandler(_, __, char, code)
    if (ctrlPressed and code == 16) then
        exit()
    end

    ctrlPressed = code == 29;
end

local colors = {
    ["0"] = 0x333333, ["1"] = 0x0000ff, ["2"] = 0x00ff00, ["3"] = 0x24b3a7,
    ["4"] = 0xff0000, ["5"] = 0x8b00ff, ["6"] = 0xffa500, ["7"] = 0xbbbbbb,
    ["8"] = 0x808080, ["9"] = 0x0000ff, ["a"] = 0x66ff66, ["b"] = 0x00ffff,
    ["c"] = 0xff6347, ["d"] = 0xff00ff, ["e"] = 0xffff00, ["f"] = 0xffffff,
    ["g"] = 0x00ff00, ["border"] = 0x525FE1,
}

function log(msg)
    if chatBox ~= nil then
        event.push("chat_say", msg)
    else
        for token in string.gmatch(msg, "[^§]+") do
            local color = colors[token[1]] or colors['f']
            gpu.serForeground(color)
            term.write(string.sub(token, 2))
        end
    end
end

local error = nil

event.listen('key_down', downHandler)
event.listen('touch', touchHandler)

function emptyFn()
end

function exit()
    running = false

    event.ignore('key_down', downHandler)
    event.ignore('touch', touchHandler)
    event.push('exit')
    os.sleep(0.3)
    gpu.setBackground(b_color)

    if not error then
        term.clear()
    end

    os.exit()
end
