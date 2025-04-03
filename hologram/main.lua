dofile("sys.lua")
dofile("holo.lib")

local th = require("thread")
local com = require('component')
local gpu = com.isAvailable("gpu") and com.gpu or nil
local radar = com.isAvailable("radar") and com.radar or nil

local geo = { x0 = -19, z0 = -19, w = 39, l = 39 }
local Geo = {};
Geo.binds = {};

Geo.binds["000"] = com.proxy(com.get("23a032ec-925a-4666-b801-7eb7da7466ea"))
Geo.binds["100"] = com.proxy(com.get("1f5266d0-f139-4a30-bdcc-f958b764ff44"))
Geo.binds["001"] = com.proxy(com.get("021ce8e6-d008-44a1-88ca-dbcbe08ba879"))
Geo.binds["101"] = com.proxy(com.get("c666d1b4-b73c-4910-a42e-9a933fe7e774"))

Geo.binds["010"] = com.proxy(com.get("d2e038e9-7690-411e-b2bf-7d7dd6612a31"))
Geo.binds["110"] = com.proxy(com.get("f57f27ab-e3a1-4c07-a712-69fc0d28c315"))
Geo.binds["011"] = com.proxy(com.get("091238d7-f372-4df5-910d-738f1f38e89b"))
Geo.binds["111"] = com.proxy(com.get("35e7e096-fe43-4bb3-93cc-726a1576fb4b"))

Geo.scan = function(x, py, z)
    local px = math.floor(x / (geo.w + 1));
    local pz = math.floor(z / (geo.l + 1));

    local xr = x - px * geo.w + geo.x0 - 1
    local zr = (geo.l + geo.z0) - (z - pz * geo.l)

    print("py: "..py.." x: "..x.." z: "..z.." xr: "..xr.." zr: "..zr)
    return Geo.binds[px..py..pz].scan(xr, zr)
end

-- | 3 | 4 |
-- | 1 | 2 |
local d = 0.33;
-- y 1
Holo.bind({ x=0,y=0,z=0 }, "0c75c006").setTranslation(d, 0.25, -d) -- 1
Holo.bind({ x=49,y=0,z=0 }, "d7bccc48").setTranslation(-d, 0.25, -d) -- 2
Holo.bind({ x=0,y=0,z=49 }, "19b4d6e9").setTranslation(d, 0.25, d) -- 3
Holo.bind({ x=49,y=0,z=49 }, "a167f14f").setTranslation(-d, 0.25, d) -- 4
-- y 2
Holo.bind({ x=0,y=33,z=0 }, "da90ff8a").setTranslation(d, 0.25, -d) -- 1
Holo.bind({ x=49,y=33,z=0 }, "a3cb9e80").setTranslation(-d, 0.25, -d) -- 2
Holo.bind({ x=0,y=33,z=49 }, "a62ad6d6").setTranslation(d, 0.25, d) -- 3
Holo.bind({ x=49,y=33,z=49 }, "cb1be64b").setTranslation(-d, 0.25, d) -- 4
-- y 3
Holo.bind({ x=0,y=65,z=0 }, "a5221301").setTranslation(d, 0.25, -d) -- 1
Holo.bind({ x=49,y=65,z=0 }, "a93bb939").setTranslation(-d, 0.25, -d) -- 2
Holo.bind({ x=0,y=65,z=49 }, "a715c399").setTranslation(d, 0.25, d) -- 3
Holo.bind({ x=49,y=65,z=49 }, "b95f2bb0").setTranslation(-d, 0.25, d) -- 4

-- y 4
Holo.bind({ x=0,y=97,z=0 }, "c4ff114f").setTranslation(d, 0.25, -d) -- 1
Holo.bind({ x=49,y=97,z=0 }, "91841a3e").setTranslation(-d, 0.25, -d) -- 2
Holo.bind({ x=0,y=97,z=49 }, "3a85ca7b").setTranslation(d, 0.25, d) -- 3
Holo.bind({ x=49,y=97,z=49 }, "48b9e7b4").setTranslation(-d, 0.25, d) -- 4

local function scanBaze(x,z,sx,sz,py)
    local threadSize = 2;
    local threadsPayload = {}

    local tonumber = tonumber;
    local Floor = math.floor;
    local push = table.insert;

    for _y = 0, py do
        for _z = 1, sz, geo.l do
            for _x = 1, sx, geo.w do
                local endX = _x + geo.w - 1 > sx and sx or _x + geo.w - 1
                local endZ = _z + geo.l - 1 > sz and sz or _z + geo.l - 1
                push(threadsPayload, { x = _x, z = _z, w = endX, l = endZ, py = _y })
            end
        end
    end

    local threads = {}
    for t = 1, #threadsPayload do
        local payload = threadsPayload[t];

        push(threads, th.create(function()
            for _z = payload.z, payload.l do
                local calcedPos = {}
                for _x = payload.x, payload.w do
                    local scanData = Geo.scan(x + _x, payload.py, z + _z)
                    os.sleep(0);
                    for i = 1, 64 do
                        local scanDataEl = tonumber(scanData[i])
                        local rx = 8 + x + _x
                        local ry = i + payload.py * 64
                        local rz = 8 + z + _z
        
                        local c = Floor(scanDataEl > 0 and 1 or 0)
                        if (c > 0) then
                            push(calcedPos, { rx, ry, rz })
                        end
                    end
                end
                
                for i = 1, #calcedPos do
                    Holo.set(calcedPos[i][1], calcedPos[i][2], calcedPos[i][3], 1);
                end
            end
        end))
    end

    th.waitForAll(threads)
end

-- Holo.clear()
Holo.setScale(1)
Holo.setPaletteColor(1, 0x808080)
Holo.setPaletteColor(2, 0xff0000)
Holo.setRotationSpeed(0, 0, 0, 0)

print(JSON.string(radar.getPlayers(32)))
-- scanBaze(0, 0, 78, 78, 1)

local base = {};

for x = 1, 78 do
    print("#base: "..#base);
    for z = 1, 78 do
        for y = 1, 128, 32 do
            local bit32s = 0;
            for _y = y, 32 do
                if (Holo.get(x,_y,z)) then
                    bit32s = bit32s + math.pow(2, _y - 1)
                end
            end
            table.insert(base, x * 100 + z)
            table.insert(base, bit32s)
        end
    end
end

for i = 1, #base, 4 do
    local x = math.floor(base[i] / 100)
    local z = base[i] % 100
    local c1 = base[i + 1]
    local c2 = base[i + 2]
    local c3 = base[i + 3]

    Holo.set(calcedPos[i][1], calcedPos[i][2], calcedPos[i][3], 1);
end

print("#base: "..#base);

print("Все гуд, настройки голлограммы применены")