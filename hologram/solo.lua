dofile("sys.lua")
dofile("holo.lib")

local com = require('component')

local gpu = com.isAvailable("gpu") and com.gpu or nil
local holo = com.isAvailable("hologram") and com.hologram or nil

local size = { x = 48, z = 48, y = 32 }

local imgForChar = {
    S = {
        "-1111-",
        "11--11",
        "11----",
        "-1111-",
        "----11",
        "11--11",
        "-1111-",
    },
    Y = {
        "11--11",
        "11--11",
        "11--11",
        "-1111-",
        "--11--",
        "--11--",
        "--11--",
    },
    T = {
        "111111",
        "--11--",
        "--11--",
        "--11--",
        "--11--",
        "--11--",
        "--11--",
    },
    E = {
        "111111",
        "11----",
        "11----",
        "111111",
        "11----",
        "11----",
        "111111",
    },
    M = {
        "11----11",
        "111--111",
        "11111111",
        "11-11-11",
        "11----11",
        "11----11",
        "11----11",
    },
    X = {
        "11--11",
        "11--11",
        "-1111-",
        "--11--",
        "-1111-",
        "11--11",
        "11--11",
    },
}

local imageText = "SYSTEM"

local depth = 4;
local function renderImage(string)
    local width = 0;
    local height = 0;

    for c = 1, string.len(string) do
        local char = string.sub(string, c, c)
        local imageStrs = imgForChar[char]

        height = height < #imageStrs and #imageStrs or height
        width = width + #imageStrs[1] + 1
    end

    local yOffset = size.y / 2 + math.floor(height / 2)
    local xOffset = size.x / 2 - math.floor(width / 2)
    local zOffset = size.z / 2 - math.floor(depth / 2)

    print("height: ".. height .. " width: ".. width .. " string: ".. string)
    print("yOffset: ".. yOffset .. " xOffset: ".. xOffset .. " zOffset: ".. zOffset)

    local xCharOffset = 0;
    for c = 1, string.len(string) do
        local char = string.sub(string, c, c)
        local imageStrs = imgForChar[char]
        
        print("c: ".. c .. " char: ".. char .. " started")
        for z = 1, depth do
            for y = 1, #imageStrs do
                local row = imageStrs[y];
                if z == 1 then print(row) end

                for x = 1, string.len(row) do
                    local char = string.sub(row, x, x)

                    holos.set(xOffset + x + xCharOffset, yOffset - y, zOffset + z, char == '-' and false or tonumber(char) or 0);
                end
            end
        end

        xCharOffset = xCharOffset + string.len(imageStrs[1]) + 1;
    end
end

holo.clear()
holo.setScale(1)
holo.setPaletteColor(1, 0x147b01)
holo.setTranslation(0, 0.3, 0)
holo.setRotationSpeed(50, 0, 50, 0)

renderImage(imageText)
print("Все гуд, настройки голлограммы применены")