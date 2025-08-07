--[[
    Matcha VM UI Library - Adapted for External Lua VM
    Uses the Drawing library provided by Matcha External Lua VM
    
    Features:
    - Dark theme with purple accents
    - Clean checkbox toggles  
    - Horizontal sliders with value display
    - Modern button styling
    - Collapsible sections
    
    Usage:
    local UILib = loadfile("matcha_ui_library.lua")()
    local gui = UILib.new("Auto Parry Script")
    local mainTab = gui:Tab("Main")
    gui:Toggle(mainTab, "Auto Parry", false, function(enabled) end)
    gui:Slider(mainTab, "Range", 1000, 1, 5000, "studs", function(value) end)
    gui:Button(mainTab, "Teleport to Base", function() end)
    
    -- Main loop
    while true do
        gui:Step()
        wait(1/60)
    end
]]

local UILib = {}
UILib.__index = UILib

-- Modern color scheme
local Colors = {
    Background = Color3.new(25/255, 25/255, 35/255),        -- Dark background
    Secondary = Color3.new(35/255, 35/255, 45/255),         -- Secondary panels
    Accent = Color3.new(200/255, 100/255, 255/255),         -- Purple accent
    AccentHover = Color3.new(220/255, 120/255, 255/255),    -- Lighter purple
    Text = Color3.new(1, 1, 1),                             -- White text
    TextSecondary = Color3.new(180/255, 180/255, 190/255),  -- Gray text
    Border = Color3.new(60/255, 60/255, 70/255),            -- Border color
    Success = Color3.new(100/255, 255/255, 150/255),        -- Green for enabled states
    SliderFill = Color3.new(160/255, 80/255, 220/255)       -- Slider fill color
}

-- Navigation state for keyboard-based input
local NavigationState = {
    selectedTab = 1,
    selectedItem = 1,
    maxItems = 0,
    inputMode = false,
    inputBuffer = "",
    cursorBlink = 0,
    cursorVisible = true,
    mousePos = Vector2.new(0, 0)
}

function UILib.new(title)
    local self = setmetatable({}, UILib)
    
    -- Main window properties
    self.Title = title or "Script GUI"
    self.Position = Vector2.new(50, 50)
    self.Size = Vector2.new(280, 350)
    self.Visible = true
    self.Dragging = false
    self.DragStart = Vector2.new(0, 0)
    self.DragStartPos = Vector2.new(0, 0)
    
    -- Tab system
    self.Tabs = {}
    self.ActiveTab = 1
    self.Drawings = {}
    
    -- Create main window structure
    self:CreateMainWindow()
    
    return self
end

function UILib:CreateMainWindow()
    -- Main background
    local mainBg = Drawing.new("Square")
    mainBg.Size = self.Size
    mainBg.Position = self.Position
    mainBg.Color = Colors.Background
    mainBg.Filled = true
    mainBg.Visible = true
    mainBg.Thickness = 1
    table.insert(self.Drawings, mainBg)
    
    -- Title bar
    local titleBar = Drawing.new("Square")
    titleBar.Size = Vector2.new(self.Size.X, 28)
    titleBar.Position = self.Position
    titleBar.Color = Colors.Secondary
    titleBar.Filled = true
    titleBar.Visible = true
    titleBar.Thickness = 1
    table.insert(self.Drawings, titleBar)
    
    -- Title text
    local titleText = Drawing.new("Text")
    titleText.Text = self.Title
    titleText.Position = Vector2.new(self.Position.X + 10, self.Position.Y + 6)
    titleText.Color = Colors.Text
    titleText.Visible = true
    table.insert(self.Drawings, titleText)
    
    -- Close button (visual only)
    local closeBtn = Drawing.new("Square")
    closeBtn.Size = Vector2.new(18, 18)
    closeBtn.Position = Vector2.new(self.Position.X + self.Size.X - 25, self.Position.Y + 5)
    closeBtn.Color = Colors.Accent
    closeBtn.Filled = true
    closeBtn.Visible = true
    closeBtn.Thickness = 1
    table.insert(self.Drawings, closeBtn)
    
    local closeText = Drawing.new("Text")
    closeText.Text = "X"
    closeText.Position = Vector2.new(self.Position.X + self.Size.X - 20, self.Position.Y + 8)
    closeText.Color = Colors.Text
    closeText.Visible = true
    table.insert(self.Drawings, closeText)
end

function UILib:Tab(name)
    local tab = {
        Name = name,
        Items = {},
        Collapsed = false,
        Drawings = {}
    }
    
    table.insert(self.Tabs, tab)
    return #self.Tabs -- Return tab index
end

function UILib:Toggle(tabIndex, label, defaultValue, callback)
    local tab = self.Tabs[tabIndex]
    if not tab then return end
    
    local item = {
        Type = "toggle",
        Label = label,
        Value = defaultValue or false,
        Callback = callback,
        Drawings = {}
    }
    
    -- Create toggle visuals
    local toggleBg = Drawing.new("Square")
    toggleBg.Size = Vector2.new(12, 12)
    toggleBg.Color = Colors.Border
    toggleBg.Filled = false
    toggleBg.Thickness = 1
    toggleBg.Visible = true
    table.insert(item.Drawings, toggleBg)
    
    local toggleFill = Drawing.new("Square")
    toggleFill.Size = Vector2.new(8, 8)
    toggleFill.Color = Colors.Accent
    toggleFill.Filled = true
    toggleFill.Visible = defaultValue
    toggleFill.Thickness = 1
    table.insert(item.Drawings, toggleFill)
    
    local labelText = Drawing.new("Text")
    labelText.Text = label
    labelText.Color = Colors.Text
    labelText.Visible = true
    table.insert(item.Drawings, labelText)
    
    table.insert(tab.Items, item)
    return item
end

function UILib:Slider(tabIndex, label, defaultValue, min, max, suffix, callback)
    local tab = self.Tabs[tabIndex]
    if not tab then return end
    
    local item = {
        Type = "slider",
        Label = label,
        Value = defaultValue or min,
        Min = min,
        Max = max,
        Suffix = suffix or "",
        Callback = callback,
        Drawings = {}
    }
    
    -- Slider track (background)
    local sliderTrack = Drawing.new("Square")
    sliderTrack.Size = Vector2.new(120, 4)
    sliderTrack.Color = Colors.Border
    sliderTrack.Filled = true
    sliderTrack.Visible = true
    sliderTrack.Thickness = 1
    table.insert(item.Drawings, sliderTrack)
    
    -- Slider fill
    local sliderFill = Drawing.new("Square")
    sliderFill.Size = Vector2.new(60, 4)
    sliderFill.Color = Colors.SliderFill
    sliderFill.Filled = true
    sliderFill.Visible = true
    sliderFill.Thickness = 1
    table.insert(item.Drawings, sliderFill)
    
    -- Label text
    local labelText = Drawing.new("Text")
    labelText.Text = label
    labelText.Color = Colors.Text
    labelText.Visible = true
    table.insert(item.Drawings, labelText)
    
    -- Value display
    local valueText = Drawing.new("Text")
    valueText.Text = tostring(defaultValue) .. " " .. suffix
    valueText.Color = Colors.TextSecondary
    valueText.Visible = true
    table.insert(item.Drawings, valueText)
    
    table.insert(tab.Items, item)
    return item
end

function UILib:Button(tabIndex, label, callback)
    local tab = self.Tabs[tabIndex]
    if not tab then return end
    
    local item = {
        Type = "button",
        Label = label,
        Callback = callback,
        Selected = false,
        Drawings = {}
    }
    
    -- Button background
    local buttonBg = Drawing.new("Square")
    buttonBg.Size = Vector2.new(240, 22)
    buttonBg.Color = Colors.Secondary
    buttonBg.Filled = true
    buttonBg.Visible = true
    buttonBg.Thickness = 1
    table.insert(item.Drawings, buttonBg)
    
    -- Button text
    local buttonText = Drawing.new("Text")
    buttonText.Text = ":: " .. label .. " ::"
    buttonText.Color = Colors.Text
    buttonText.Visible = true
    table.insert(item.Drawings, buttonText)
    
    table.insert(tab.Items, item)
    return item
end

function UILib:Section(tabIndex, name)
    local tab = self.Tabs[tabIndex]
    if not tab then return end
    
    local item = {
        Type = "section",
        Label = name,
        Collapsed = false,
        Drawings = {}
    }
    
    -- Section header
    local sectionBg = Drawing.new("Square")
    sectionBg.Size = Vector2.new(240, 20)
    sectionBg.Color = Colors.Secondary
    sectionBg.Filled = true
    sectionBg.Visible = true
    sectionBg.Thickness = 1
    table.insert(item.Drawings, sectionBg)
    
    local sectionText = Drawing.new("Text")
    sectionText.Text = name .. " [-]"
    sectionText.Color = Colors.Text
    sectionText.Visible = true
    table.insert(item.Drawings, sectionText)
    
    table.insert(tab.Items, item)
    return item
end

function UILib:UpdateNavigation()
    -- Update cursor blink
    NavigationState.cursorBlink = NavigationState.cursorBlink + 1
    if NavigationState.cursorBlink >= 60 then
        NavigationState.cursorVisible = not NavigationState.cursorVisible
        NavigationState.cursorBlink = 0
    end
    
    -- Update max items for current tab
    if self.Tabs[NavigationState.selectedTab] then
        NavigationState.maxItems = #self.Tabs[NavigationState.selectedTab].Items
    end
    
    -- Clamp selection
    if NavigationState.selectedItem > NavigationState.maxItems then
        NavigationState.selectedItem = NavigationState.maxItems
    end
    if NavigationState.selectedItem < 1 and NavigationState.maxItems > 0 then
        NavigationState.selectedItem = 1
    end
end

function UILib:HandleInput()
    -- Basic input handling would go here
    -- For now, we'll simulate with simple navigation
    local tab = self.Tabs[NavigationState.selectedTab]
    if not tab or NavigationState.selectedItem <= 0 then return end
    
    local item = tab.Items[NavigationState.selectedItem]
    if not item then return end
    
    -- Simulate selection (would normally be triggered by input)
    if item.Type == "toggle" then
        item.Value = not item.Value
        item.Drawings[2].Visible = item.Value
        if item.Callback then
            item.Callback(item.Value)
        end
    elseif item.Type == "button" then
        if item.Callback then
            item.Callback()
        end
    elseif item.Type == "slider" then
        -- Simulate slider adjustment
        local step = (item.Max - item.Min) / 20
        item.Value = item.Value + step
        if item.Value > item.Max then
            item.Value = item.Min
        end
        if item.Callback then
            item.Callback(item.Value)
        end
    end
end

function UILib:Step()
    if not self.Visible then return end
    
    self:UpdateNavigation()
    
    -- Update main window position for all drawings
    for _, drawing in ipairs(self.Drawings) do
        drawing.Visible = self.Visible
    end
    
    -- Render current tab
    local currentTab = self.Tabs[self.ActiveTab]
    if not currentTab then return end
    
    local yOffset = 40 -- Start below title bar
    
    for itemIndex, item in ipairs(currentTab.Items) do
        local isSelected = (NavigationState.selectedItem == itemIndex)
        local itemY = self.Position.Y + yOffset
        
        if item.Type == "toggle" then
            -- Position toggle elements
            local checkboxX = self.Position.X + self.Size.X - 25
            
            item.Drawings[1].Position = Vector2.new(checkboxX, itemY + 2)
            item.Drawings[2].Position = Vector2.new(checkboxX + 2, itemY + 4)
            item.Drawings[3].Position = Vector2.new(self.Position.X + 15, itemY)
            
            -- Update colors for selection
            item.Drawings[1].Color = isSelected and Colors.AccentHover or Colors.Border
            item.Drawings[3].Color = isSelected and Colors.AccentHover or Colors.Text
            
            yOffset = yOffset + 25
            
        elseif item.Type == "slider" then
            -- Position slider elements
            local sliderX = self.Position.X + self.Size.X - 140
            
            item.Drawings[3].Position = Vector2.new(self.Position.X + 15, itemY)
            item.Drawings[1].Position = Vector2.new(sliderX, itemY + 8)
            item.Drawings[2].Position = Vector2.new(sliderX, itemY + 8)
            item.Drawings[4].Position = Vector2.new(sliderX + 125, itemY)
            
            -- Calculate slider fill width
            local fillPercent = (item.Value - item.Min) / (item.Max - item.Min)
            item.Drawings[2].Size = Vector2.new(120 * fillPercent, 4)
            
            -- Update value text
            item.Drawings[4].Text = string.format("%.0f %s", item.Value, item.Suffix)
            
            -- Update colors for selection
            item.Drawings[3].Color = isSelected and Colors.AccentHover or Colors.Text
            item.Drawings[1].Color = isSelected and Colors.AccentHover or Colors.Border
            
            yOffset = yOffset + 25
            
        elseif item.Type == "button" then
            -- Position button elements
            item.Drawings[1].Position = Vector2.new(self.Position.X + 15, itemY)
            item.Drawings[2].Position = Vector2.new(self.Position.X + 25, itemY + 4)
            
            -- Update colors for selection
            item.Drawings[1].Color = isSelected and Colors.Accent or Colors.Secondary
            
            yOffset = yOffset + 30
            
        elseif item.Type == "section" then
            -- Position section elements
            item.Drawings[1].Position = Vector2.new(self.Position.X + 10, itemY)
            item.Drawings[2].Position = Vector2.new(self.Position.X + 15, itemY + 2)
            
            -- Update colors for selection
            item.Drawings[1].Color = isSelected and Colors.Accent or Colors.Secondary
            
            yOffset = yOffset + 25
        end
    end
    
    -- Update window height based on content
    local newHeight = math.max(200, yOffset + 20)
    self.Size = Vector2.new(self.Size.X, newHeight)
    if self.Drawings[1] then
        self.Drawings[1].Size = self.Size
    end
end

function UILib:Destroy()
    -- Clean up all drawings
    for _, drawing in ipairs(self.Drawings) do
        if drawing and drawing.Remove then
            drawing:Remove()
        end
    end
    
    for _, tab in ipairs(self.Tabs) do
        for _, item in ipairs(tab.Items) do
            for _, drawing in ipairs(item.Drawings) do
                if drawing and drawing.Remove then
                    drawing:Remove()
                end
            end
        end
        for _, drawing in ipairs(tab.Drawings) do
            if drawing and drawing.Remove then
                drawing:Remove()
            end
        end
    end
    
    self.Tabs = {}
    self.Drawings = {}
end

-- Utility functions for navigation (would be triggered by actual input)
function UILib:SimulateEnter()
    self:HandleInput()
end

function UILib:NavigateUp()
    NavigationState.selectedItem = NavigationState.selectedItem - 1
    if NavigationState.selectedItem < 1 then
        NavigationState.selectedItem = NavigationState.maxItems
    end
end

function UILib:NavigateDown()
    NavigationState.selectedItem = NavigationState.selectedItem + 1
    if NavigationState.selectedItem > NavigationState.maxItems then
        NavigationState.selectedItem = 1
    end
end

return UILib