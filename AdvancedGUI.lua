-- AdvancedGUI: A Comprehensive GUI Library for CC: Tweaked
local AdvancedGUI = {}

-- Utility functions
local function deepCopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepCopy(orig_key)] = deepCopy(orig_value)
        end
        setmetatable(copy, deepCopy(getmetatable(orig)))
    else
        copy = orig
    end
    return copy
end

-- Theme
local defaultTheme = {
    background = colors.lightGray,
    text = colors.black,
    button = colors.gray,
    buttonText = colors.white,
    input = colors.white,
    inputText = colors.black,
    slider = colors.gray,
    sliderHandle = colors.white,
    checkbox = colors.gray,
    checkboxChecked = colors.green,
    radio = colors.gray,
    radioSelected = colors.green,
    dialogBackground = colors.lightGray,
    dialogBorder = colors.gray,
}

local currentTheme = deepCopy(defaultTheme)

function AdvancedGUI.setTheme(newTheme)
    for k, v in pairs(newTheme) do
        currentTheme[k] = v
    end
end

-- Base component class
local Component = {}
Component.__index = Component

function Component:new(x, y, width, height)
    local self = setmetatable({}, Component)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.visible = true
    return self
end

function Component:draw()
    -- To be overridden by subclasses
end

function Component:handleEvent(event, x, y)
    -- To be overridden by subclasses
end

function Component:setPosition(x, y)
    self.x = x
    self.y = y
end

function Component:setSize(width, height)
    self.width = width
    self.height = height
end

function Component:setVisible(visible)
    self.visible = visible
end

-- Group component
local Group = setmetatable({}, { __index = Component })
Group.__index = Group

function Group:new(x, y, width, height, orientation, padding, spacing)
    local self = setmetatable(Component:new(x, y, width, height), Group)
    self.orientation = orientation or "vertical"
    self.padding = padding or 1
    self.spacing = spacing or 1
    self.children = {}
    return self
end

function Group:addChild(child)
    table.insert(self.children, child)
    self:updateChildrenPositions()
end

function Group:updateChildrenPositions()
    local currentX, currentY = self.x + self.padding, self.y + self.padding
    for _, child in ipairs(self.children) do
        child:setPosition(currentX, currentY)
        if self.orientation == "vertical" then
            currentY = currentY + child.height + self.spacing
        else
            currentX = currentX + child.width + self.spacing
        end
    end
end

function Group:draw()
    if not self.visible then return end
    for _, child in ipairs(self.children) do
        child:draw()
    end
end

function Group:handleEvent(event, x, y)
    if not self.visible then return false end
    for _, child in ipairs(self.children) do
        if child:handleEvent(event, x, y) then
            return true
        end
    end
    return false
end

-- Label component
local Label = setmetatable({}, { __index = Component })
Label.__index = Label

function Label:new(x, y, width, height, text, fgColor, bgColor)
    local self = setmetatable(Component:new(x, y, width, height), Label)
    self.text = text
    self.selectionStart = nil
    self.selectionEnd = nil
    self.fgColor = fgColor or nil
    self.bgColor = bgColor or nil
    return self
end

function Label:draw()
    if not self.visible then return end
    term.setTextColor(self.fgColor or currentTheme.text)
    term.setBackgroundColor(self.bgColor or currentTheme.background)
    term.setCursorPos(self.x, self.y)
    term.write(self.text:sub(1, self.width))

    -- Draw selection
    if self.selectionStart and self.selectionEnd then
        local start = math.min(self.selectionStart, self.selectionEnd)
        local endPos = math.max(self.selectionStart, self.selectionEnd)
        term.setTextColor(currentTheme.background)
        term.setBackgroundColor(currentTheme.text)
        term.setCursorPos(self.x + start - 1, self.y)
        term.write(self.text:sub(start, endPos))
    end
end

function Label:handleEvent(event, x, y)
    if not self.visible then return false end
    if event == "mouse_click" and x >= self.x and x < self.x + self.width and y == self.y then
        self.selectionStart = x - self.x + 1
        self.selectionEnd = self.selectionStart
        return true
    elseif event == "mouse_drag" and self.selectionStart then
        self.selectionEnd = math.min(math.max(1, x - self.x + 1), #self.text)
        return true
    elseif event == "mouse_up" and self.selectionStart then
        if self.selectionStart == self.selectionEnd then
            self.selectionStart = nil
            self.selectionEnd = nil
        else
            -- Open context menu
            local menu = AdvancedGUI.ContextMenu:new(x, y, { "Copy" })
            menu:show()
            local selection = menu:waitForSelection()
            if selection == "Copy" then
                local start = math.min(self.selectionStart, self.selectionEnd)
                local endPos = math.max(self.selectionStart, self.selectionEnd)
                AdvancedGUI.setClipboard(self.text:sub(start, endPos))
            end
        end
        return true
    end
    return false
end

function Label:setText(text)
    self.text = text
    self.selectionStart = nil
    self.selectionEnd = nil
end

local Input = setmetatable({}, { __index = Component })
Input.__index = Input

function Input:new(x, y, width, height, placeholder)
    local self = setmetatable(Component:new(x, y, width, height), Input)
    self.text = ""
    self.placeholder = placeholder or ""
    self.cursorPos = 1
    self.focused = false
    return self
end

function Input:draw()
    if not self.visible then return end

    -- Draw background
    term.setBackgroundColor(colors.white)
    term.setCursorPos(self.x, self.y)
    term.write(string.rep(" ", self.width)) -- Fill with spaces to clear previous text

    -- Draw input text
    term.setTextColor(currentTheme.inputText)
    term.setBackgroundColor(currentTheme.input)
    term.setCursorPos(self.x, self.y)

    local displayText = self.text
    if #displayText == 0 and not self.focused then
        displayText = self.placeholder
        term.setTextColor(colors.lightGray)
    else
        term.setTextColor(currentTheme.inputText)
    end

    -- Calculate the start position for scrolling
    local scrollStart = math.max(1, self.cursorPos - self.width + 1)
    displayText = displayText:sub(scrollStart)

    -- Limit to width
    term.write(displayText:sub(1, self.width))

    if self.focused then
        term.setCursorPos(self.x + self.cursorPos - scrollStart - 1, self.y)
        term.setCursorBlink(true)
    end
end

function Input:handleEvent(event, button, x, y)
    if not self.visible then return false end
    if event == "mouse_click" and x >= self.x and x < self.x + self.width and y == self.y then
        self.focused = true
        self.cursorPos = x - self.x + 1
        return true
    elseif event == "char" and self.focused then
        self.text = self.text:sub(1, self.cursorPos - 1) .. button .. self.text:sub(self.cursorPos)
        self.cursorPos = self.cursorPos + 1
        self:adjustCursorPosition()
        return true
    elseif event == "key" and self.focused then
        if button == keys.backspace and self.cursorPos > 1 then
            self.text = self.text:sub(1, self.cursorPos - 2) .. self.text:sub(self.cursorPos)
            self.cursorPos = self.cursorPos - 1
            self:adjustCursorPosition()
        elseif button == keys.delete and self.cursorPos <= #self.text then
            self.text = self.text:sub(1, self.cursorPos - 1) .. self.text:sub(self.cursorPos + 1)
            self:adjustCursorPosition()
        elseif button == keys.left and self.cursorPos > 1 then
            self.cursorPos = self.cursorPos - 1
        elseif button == keys.right and self.cursorPos <= #self.text then
            self.cursorPos = self.cursorPos + 1
        elseif button == keys.enter then
            self.focused = false
            term.setCursorBlink(false)
            return self.text
        end
        return true
    end
    return false
end

function Input:setText(text)
    self.text = text
    self.cursorPos = #text + 1
    self:adjustCursorPosition()
end

function Input:getText()
    return self.text
end

function Input:adjustCursorPosition()
    if self.cursorPos > #self.text + 1 then
        self.cursorPos = #self.text + 1
    end
end

-- Button component
local Button = setmetatable({}, { __index = Component })
Button.__index = Button

function Button:new(x, y, width, height, text, onClick)
    local self = setmetatable(Component:new(x, y, width, height), Button)
    self.text = text
    self.onClick = onClick
    return self
end

function Button:draw()
    if not self.visible then return end
    term.setBackgroundColor(currentTheme.button)
    term.setTextColor(currentTheme.buttonText)
    for i = 1, self.height do
        term.setCursorPos(self.x, self.y + i - 1)
        term.write(string.rep(" ", self.width))
    end
    local textX = self.x + math.floor((self.width - #self.text) / 2)
    local textY = self.y + math.floor(self.height / 2)
    term.setCursorPos(textX, textY)
    term.write(self.text)
end

function Button:handleEvent(event, button, x, y)
    if not self.visible then return false end
    if event == "mouse_click" and x >= self.x and x < self.x + self.width and y >= self.y and y < self.y + self.height then
        if self.onClick then
            self.onClick(self)
        end
        return true
    end
    return false
end

function Button:setText(text)
    self.text = text
end

-- Slider component
local Slider = setmetatable({}, { __index = Component })
Slider.__index = Slider

function Slider:new(x, y, width, min, max, value, onChange)
    local self = setmetatable(Component:new(x, y, width, 1), Slider)
    self.min = min
    self.max = max
    self.value = value
    self.onChange = onChange
    return self
end

function Slider:draw()
    if not self.visible then return end
    term.setBackgroundColor(currentTheme.slider)
    term.setCursorPos(self.x, self.y)
    term.write(string.rep("-", self.width))

    local handlePos = math.floor((self.value - self.min) / (self.max - self.min) * (self.width - 1)) + self.x
    term.setBackgroundColor(currentTheme.sliderHandle)
    term.setCursorPos(handlePos, self.y)
    term.write(" ")
end

function Slider:handleEvent(event, x, y)
    if not self.visible then return false end
    if (event == "mouse_click" or event == "mouse_drag") and x >= self.x and x < self.x + self.width and y == self.y then
        local newValue = math.floor((x - self.x) / (self.width - 1) * (self.max - self.min) + self.min)
        if newValue ~= self.value then
            self.value = newValue
            if self.onChange then
                self.onChange(self.value)
            end
        end
        return true
    end
    return false
end

function Slider:setValue(value)
    self.value = math.max(self.min, math.min(self.max, value))
    if self.onChange then
        self.onChange(self.value)
    end
end

function Slider:getValue()
    return self.value
end

-- Box component
local Box = setmetatable({}, { __index = Component })
Box.__index = Box

function Box:new(x, y, width, height, filled, fgColor, bgColor)
    local self = setmetatable(Component:new(x, y, width, height), Box)
    self.filled = filled or false
    self.fgColor = fgColor or colors.white            -- Default foreground color
    self.bgColor = bgColor or currentTheme.background -- Default background color
    return self
end

function Box:draw()
    if not self.visible then return end
    if self.filled then
        term.setBackgroundColor(self.bgColor)
        term.setTextColor(self.fgColor)

        for i = 1, self.height do
            term.setCursorPos(self.x, self.y + i - 1)
            if i == 1 or i == self.height or not self.filled then
                term.write(string.rep("-", self.width))
            else
                term.write("|" .. string.rep(self.filled and " " or "-", self.width - 2) .. "|")
            end
        end
    else
        local fgColor = self.fgColor
        local bgColor = self.bgColor
        local x = self.x
        local y = self.y
        local width = self.width
        local height = self.height
        term.setBackgroundColor(bgColor)
        term.setTextColor(fgColor)
        term.setCursorPos(x - 1, y - 1)
        term.write("\x9C" .. ("\x8C"):rep(width))
        -- Draw the top-right corner.
        term.setBackgroundColor(fgColor)
        term.setTextColor(bgColor)
        term.write("\x93")
        -- Draw the right border.
        for i = 1, height do
            term.setCursorPos(term.getCursorPos() - 1, y + i - 1)
            term.write("\x95")
        end
        -- Draw the left border.
        term.setBackgroundColor(bgColor)
        term.setTextColor(fgColor)
        for i = 1, height do
            term.setCursorPos(x - 1, y + i - 1)
            term.write("\x95")
        end
        -- Draw the bottom border and corners.
        term.setCursorPos(x - 1, y + height)
        term.write("\x8D" .. ("\x8C"):rep(width) .. "\x8E")
    end
end

function Box:setFilled(filled)
    self.filled = filled
end

-- Dialog component
local Dialog = setmetatable({}, { __index = Component })
Dialog.__index = Dialog

function Dialog:new(x, y, width, height, title, content)
    local self = setmetatable(Component:new(x, y, width, height), Dialog)
    self.title = title
    self.content = content
    self.visible = false
    return self
end

function Dialog:draw()
    if not self.visible then return end
    term.setBackgroundColor(currentTheme.dialogBackground)
    term.setTextColor(currentTheme.text)
    for i = 1, self.height do
        term.setCursorPos(self.x, self.y + i - 1)
        if i == 1 or i == self.height then
            term.write(string.rep("-", self.width))
        else
            term.write("|" .. string.rep(" ", self.width - 2) .. "|")
        end
    end

    -- Draw title
    term.setCursorPos(self.x + 2, self.y)
    term.write(self.title)

    -- Draw content
    local contentY = self.y + 2
    for _, line in ipairs(self.content) do
        term.setCursorPos(self.x + 2, contentY)
        term.write(line)
        contentY = contentY + 1
    end
end

function Dialog:show()
    self.visible = true
end

function Dialog:hide()
    self.visible = false
end

function Dialog:setContent(content)
    self.content = content
end

-- RadioButtonList component
local RadioButtonList = setmetatable({}, { __index = Component })
RadioButtonList.__index = RadioButtonList

function RadioButtonList:new(x, y, width, options, selectedIndex, onChange)
    local self = setmetatable(Component:new(x, y, width, #options), RadioButtonList)
    self.options = options
    self.selectedIndex = selectedIndex or 1
    self.onChange = onChange
    return self
end

function RadioButtonList:draw()
    if not self.visible then return end
    term.setTextColor(currentTheme.text)
    term.setBackgroundColor(currentTheme.background)
    for i, option in ipairs(self.options) do
        term.setCursorPos(self.x, self.y + i - 1)
        if i == self.selectedIndex then
            term.setTextColor(currentTheme.radioSelected)
            term.write("(*) " .. option)
        else
            term.setTextColor(currentTheme.radio)
            term.write("( ) " .. option)
        end
    end
end

function RadioButtonList:handleEvent(event, button, x, y)
    if not self.visible then return false end
    if event == "mouse_click" and x >= self.x and x < self.x + self.width and y >= self.y and y < self.y + #self.options then
        local netermdex = y - self.y + 1
        if netermdex ~= self.selectedIndex then
            self.selectedIndex = netermdex
            if self.onChange then
                self.onChange(self.selectedIndex, self.options[self.selectedIndex])
            end
        end
        return true
    end
    return false
end

function RadioButtonList:setSelectedIndex(index)
    if index >= 1 and index <= #self.options then
        self.selectedIndex = index
        if self.onChange then
            self.onChange(self.selectedIndex, self.options[self.selectedIndex])
        end
    end
end

function RadioButtonList:getSelectedIndex()
    return self.selectedIndex
end

function RadioButtonList:getSelectedOption()
    return self.options[self.selectedIndex]
end

-- Checkbox component
local Checkbox = setmetatable({}, { __index = Component })
Checkbox.__index = Checkbox

function Checkbox:new(x, y, width, text, checked, onChange)
    local self = setmetatable(Component:new(x, y, width, 1), Checkbox)
    self.text = text
    self.checked = checked or false
    self.onChange = onChange
    return self
end

function Checkbox:draw()
    if not self.visible then return end
    term.setTextColor(currentTheme.text)
    term.setBackgroundColor(currentTheme.background)
    term.setCursorPos(self.x, self.y)
    if self.checked then
        term.setTextColor(currentTheme.checkboxChecked)
        term.write("[X] " .. self.text)
    else
        term.setTextColor(currentTheme.checkbox)
        term.write("[ ] " .. self.text)
    end
end

function Checkbox:handleEvent(event, button, x, y)
    if not self.visible then return false end
    if event == "mouse_click" and x >= self.x and x < self.x + self.width and y == self.y then
        self.checked = not self.checked
        if self.onChange then
            self.onChange(self.checked)
        end
        return true
    end
    return false
end

function Checkbox:setChecked(checked)
    self.checked = checked
    if self.onChange then
        self.onChange(self.checked)
    end
end

function Checkbox:isChecked()
    return self.checked
end

-- ContextMenu component
local ContextMenu = setmetatable({}, { __index = Component })
ContextMenu.__index = ContextMenu

function ContextMenu:new(x, y, options, fgColor, bgColor)
    local self = setmetatable(Component:new(x, y, 0, #options), ContextMenu)
    local longestOption = 1
    for _, option in pairs(options) do
        if string.len(option) > longestOption then
            longestOption = string.len(option)
        end
    end
    longestOption = longestOption + 1
    self.options = options
    self.width = longestOption
    self.fgColor = fgColor
    self.bgColor = bgColor
    self.visible = false
    return self
end

function ContextMenu:draw()
    if not self.visible then return end
    term.setTextColor(self.fgColor or currentTheme.text)
    term.setBackgroundColor(self.bgColor or currentTheme.background)
    for i, option in ipairs(self.options) do
        term.setCursorPos(self.x + 1, self.y + i)
        term.write(" " .. option .. string.rep(" ", self.width - #option - 1) .. " ")
    end
end

function ContextMenu:handleEvent(event, button, x, y)
    if not self.visible then return false end
    if event == "mouse_click" and button == 1 and x >= self.x + 1 and x < self.x + 1 + self.width and y >= self.y + 1 and y < self.y + 1 + #self.options then
        local selectedIndex = y - self.y
        self.visible = false
        return self.options[selectedIndex]
    elseif event == "mouse_click" then
        self.visible = false
    end
    return false
end

function ContextMenu:show()
    self.visible = true
end

function ContextMenu:hide()
    self.visible = false
end

function ContextMenu:waitForSelection()
    self:show()
    while self.visible do
        local event, p1, p2, p3 = os.pullEvent()
        local result = self:handleEvent(event, p1, p2, p3)
        if result then
            return result
        end
    end
end

local Icon = setmetatable({}, { __index = Component })
Icon.__index = Icon

function Icon:new(x, y, width, height, iconData)
    local self = setmetatable(Component:new(x, y, width, height), Icon)
    self.iconData = iconData
    return self
end

function Icon:draw()
    if not self.visible then return end
    for row = 1, #self.iconData do
        for col = 1, #self.iconData[row] do
            local pixel = self.iconData[row][col]
            term.setCursorPos(self.x + col - 1, self.y + row - 1)
            term.setTextColor(pixel.textColor)
            term.setBackgroundColor(pixel.bgColor)
            term.write(pixel.char)
        end
    end
end

function AdvancedGUI.createIcon(x, y, iconData)
    return Icon:new(x, y, #iconData[1], #iconData, iconData)
end

-- Clipboard functionality
local clipboard = ""

function AdvancedGUI.setClipboard(text)
    clipboard = text
end

function AdvancedGUI.getClipboard()
    return clipboard
end

-- Main AdvancedGUI class
function AdvancedGUI.createComponent(componentType, ...)
    local componentClasses = {
        group = Group,
        label = Label,
        input = Input,
        button = Button,
        slider = Slider,
        box = Box,
        dialog = Dialog,
        radioButtonList = RadioButtonList,
        checkbox = Checkbox,
        contextMenu = ContextMenu
    }

    local class = componentClasses[componentType]
    if class then
        return class:new(...)
    else
        error("Unknown component type: " .. componentType)
    end
end

function AdvancedGUI.run(components)
    local function drawAll()
        term.setBackgroundColor(currentTheme.background)
        term.clear()
        for _, component in ipairs(components) do
            component:draw()
        end
    end

    drawAll()

    while true do
        local event, p1, p2, p3 = os.pullEvent()
        local handled = false
        for _, component in ipairs(components) do
            if component.handleEvent and component:handleEvent(event, p1, p2, p3) then
                handled = true
                break
            end
        end
        drawAll()
    end
end

return AdvancedGUI
