local rpc = require("rednet-wrapper")
local rpc_common = require("rpc_common")
local basalt = require("basalt")

local host = rpc:host("test", "server")

local main = basalt.createFrame()
local sub = { -- here we create a table where we gonna add some frames
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"), -- obviously the first one should be shown on program start
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
    main:addFrame():setPosition(1, 2):setSize("parent.w", "parent.h - 1"):hide(),
}

local function openSubFrame(id) -- we create a function which switches the frame for us
    if(sub[id]~=nil)then
        for k,v in pairs(sub)do
            v:hide()
        end
        sub[id]:show()
    end
end

local menubar = main:addMenubar():setScrollable() -- we create a menubar in our main frame.
    :setSize("parent.w")
    :onChange(function(self, val)
        openSubFrame(self:getItemIndex()) -- here we open the sub frame based on the table index
    end)
    :addItem("Drive")
    :addItem("Turtles")
    :addItem("Settings")

-- local control_menu = sub[1]:addButton()
-- control_menu:setPosition(1, 1) -- We want to change the default position of our button
-- control_menu:setSize(7, 1) -- And the default size.
-- control_menu:setText("control") 
-- control_menu:onClick(function() host.coords(1, 2, 3) end)

local drive_frame = sub[1]:addFrame():setSize("parent.w", "parent.h"):setPosition(1, 3)

local drive_frame_row1 = drive_frame:addFrame():setPosition(1,1):setSize("parent.w", "parent.h/3")
local drive_frame_row2 = drive_frame:addFrame():setPosition(1,4):setSize("parent.w", "parent.h/3")
local drive_frame_row3 = drive_frame:addFrame():setPosition(1,7):setSize("parent.w", "parent.h/3")


local drive_frame_row1_column1_rr = drive_frame_row1:addButton():setSize(3,3):setPosition(1,1):setText("^")
local drive_frame_row1_column2_up = drive_frame_row1:addButton():setSize(4,3):setPosition(4,1):setText("up")
local drive_frame_row1_column3_rl = drive_frame_row1:addButton():setSize(3,3):setPosition(8,1):setText(">")

local drive_frame_row2_column1_mr = drive_frame_row2:addButton():setSize(3,3):setPosition(1,1):setText("v")
local drive_frame_row2_column2_up = drive_frame_row2:addButton():setSize(4,3):setPosition(4,1):setText("down")
local drive_frame_row2_column3_ml = drive_frame_row2:addButton():setSize(3,3):setPosition(8,1):setText("<")

local dig_before_move = drive_frame_row1:addCheckbox():setPosition(12,2):setText("dig before")
local dig_after_move = drive_frame_row2:addCheckbox():setPosition(12,2):setText("dig after")

function build_drive_turtle(command, type)
    if dig_before_move.getValue() and type ~= nil then
        if type == 0 then
            host.tdig()
        elseif type == 1 then
            host.tdigup()
        elseif type == 2 then
            host.tdigdown()
        end
    end
    command()
    if dig_after_move.getValue() and type ~= nil then
        if type == 0 then
            host.tdig()
        elseif type == 1 then
            host.tdigup()
        elseif type == 2 then
            host.tdigdown()
        end
    end
end

drive_frame_row1_column1_rr:onClick(function() build_drive_turtle(host.tforward, 0) end)
drive_frame_row1_column2_up:onClick(function() build_drive_turtle(host.tup, 1) end)
drive_frame_row1_column3_rl:onClick(function() build_drive_turtle(host.tturnright, -1) end)
drive_frame_row2_column1_mr:onClick(function() build_drive_turtle(host.tback, -1) end)
drive_frame_row2_column2_up:onClick(function() build_drive_turtle(host.tdown, 2) end)
drive_frame_row2_column3_ml:onClick(function() build_drive_turtle(host.tturnleft, -1) end)

dig_after_move:onChange(function(self) 
    local checked = self:getValue() 
end)

-- local drive_frame_row3_column2_mr = drive_frame_row3:addButton():setSize(3,3):setPosition(1,1):setText("t")
-- local drive_frame_row3_column2_down = drive_frame_row3:addButton():setSize(3,3):setPosition(4,1):setText("v")
-- local drive_frame_row3_column2_ml = drive_frame_row3:addButton():setSize(3,3):setPosition(7,1):setText("d")

-- local drive_frame_row3_column2_down = drive_frame_row2:addButton():setSize(3,3):setPosition(1,1):setText("v")

-- local menu_button_turtles_group = AdvancedGUI.createComponent("button",9, 5, 8, 1, "turtles", function(self)
--     print("a")
--     local turtles = {rednet.lookup("test")}
--     turtle_label:setText(table.concat(turtles, ", "))
--     os.queueEvent("update")
-- end)


-- local myButton = AdvancedGUI.createComponent("button",0, 10, 10, 5, "Click Me", function(self)
--     host.coords(1, 2, 3)
-- end)


basalt.autoUpdate()
