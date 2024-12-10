peripheral.find("modem", rednet.open)
local rpc = require("rednet-wrapper")

function coords_func(x, y, z)
    print("My coords is: "..x..", "..y..", "..z..";")
end

rpc:register("coords", coords_func)
