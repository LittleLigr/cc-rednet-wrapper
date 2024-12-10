peripheral.find("modem", rednet.open)
local rpc = require("rednet-wrapper")
local rpc_common = require("rpc_common")

local client = rpc:client("test", "server")

repeat
    print("recieve message")
    rpc.tick()
until false
