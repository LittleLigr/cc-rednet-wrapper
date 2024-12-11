peripheral.find("modem", rednet.open)
local rpc = require("rednet-wrapper")

function coords_func(x, y, z)
    print("My coords is: "..x..", "..y..", "..z..";")
end

rpc:register("tforward", function() turtle.forward() end)
rpc:register("tback", function() turtle.back() end)
rpc:register("tup", function() turtle.up() end)
rpc:register("tdown", function() turtle.down() end)
rpc:register("tturnleft", function() turtle.turnLeft() end)
rpc:register("tturnright", function() turtle.turnRight() end)
rpc:register("tdig", function() turtle.dig() end)
rpc:register("tdigup", function() turtle.digUp() end)
rpc:register("tdigdown", function() turtle.digDown() end)
