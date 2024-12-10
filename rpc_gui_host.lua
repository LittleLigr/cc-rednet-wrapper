local rpc = require("rednet-wrapper")
local rpc_common = require("rpc_common")
local AdvancedGUI = require("creapack").import("advgui")

local host = rpc:host("test", "server")

local myButton = AdvancedGUI.createComponent("button",0, 0, 22, 22, "Click Me", function()
    host.coords(1, 2, 3)
end)

local components = { myButton }
AdvancedGUI.run(components)
