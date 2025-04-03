dofile("sys.lua")
dofile("proxy.lua")

local computer = require("computer")

Proxy.waitClient()

while running do
    computer.pullSignal(0.3)
end