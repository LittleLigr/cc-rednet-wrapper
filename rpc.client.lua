rpc = require('rednet-wrapper')
rpc_common = require('rpc.client')

local client = rpc:client("test", "server")

repeat
    print("recieve message")
    rpc.tick()
until false
