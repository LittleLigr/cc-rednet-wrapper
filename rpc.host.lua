rpc = require('rednet-wrapper')
rpc_common = require('rpc.common')

local host = rpc:host("test", "server")

repeat
    print("Send message")
    host.coords(1, 2, 3)
    sleep(1)
until false