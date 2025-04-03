local com = require("component")
local gui = require("sgui")
local gpu = com.isAvailable("gpu") and com.gpu or nil

function renderFrameGroup(box, frames, _res)
    local res = _res;
    local fr, fc = 0, 0

    for i = 1, #frames do
        local frame = frames[i]
        fr = fr + (frame.fr and frame.fr or 0)
        fc = fc + (frame.fc and frame.fc or 0)
    end

    local x2 = box.x
    local y2 = box.y
    for i = 1, #frames do
        local frame = frames[i]

        local w = fc > 0 and box.w / fc * frame.fc or box.w
        local h = fr > 0 and box.h / fr * frame.fr or box.h

        local x = x2
        local y = y2

        if frame.cols then
            res = renderFrameGroup({ x = x, y = y, w = w, h = h }, frame.cols, res)
            y2 = y2 + h + 1
        elseif frame.rows then
            res = renderFrameGroup({ x = x, y = y, w = w, h = h }, frame.rows, res)
            x2 = x2 + w + 1
        else
            res[frame.id] = renderFrame(x, y, w, h, frame.title, frame.color)

            x2 = fc > 0 and res[frame.id].x2 or x2
            y2 = fr > 0 and res[frame.id].y2 or y2
        end
    end

    return res;
end

function renderFrame(x, y, _w, _h, title, color)
    local w = math.floor(_w + 0.5)
    local h = math.floor(_h + 0.5)
    gui.drawFrame(x, y, w, h, title, color)

    return { x = x + 1, y = y + 1, w = w, h = h, x2 = x + w, y2 = y + h }
end

function renderTextButton(x, y, str)
    gui.text(x, y, str)

    return { x = x, y = y, x2 = x + string.len(str), y2 = y }
end

local function compareList(l1, l2)
    if not #l1 == #l2 then return false; end
    for i = 1, #l1 do
        if not l1[i] == l2[i] then break; return false; end
    end

    return true;
end


local function maxStrWidth(list)
    local width = 0
    for i = 1, #list do
        local _, c = list[i]:gsub("&","")
        local len = string.len(list[i]) - c;
        width = len > width and len or width;
    end
    return width;
end

function copyTable(t)
    local t2 = {}
    for k,v in pairs(t) do t2[k] = v end
    return t2
end

local listRenderCache = {}
function renderList(box, list, id)
    local colWidth = maxStrWidth(list)
    local numColumns = math.floor((box.w - 2) / (colWidth + 1));

    if listRenderCache[id] == nil or not (listRenderCache[id][1] == colWidth) or not (#listRenderCache[id][2] == #list) then
        gpu.fill(box.x, box.y, box.w - 2, box.h - 2, " ")
    else
        local oldList = listRenderCache[id][2]
        for i = 1, #oldList do
            if not oldList[i] == list[i] then
                gui.text(x, y, string.rep(" ", string.len(oldList[i])))
            end
        end
    end

    for i = 1, #list do
        local item = list[i]

        local colIndex = (i - 1) % numColumns
        local rowIndex = math.floor((i - 1) / numColumns)

        local x = box.x + colIndex * colWidth + 1
        local y = box.y + rowIndex + 1

        if y < box.y + box.h - 3 then
            gui.text(x, y, item)
        end
    end

    listRenderCache[id] = { colWidth, copyTable(list) }
end