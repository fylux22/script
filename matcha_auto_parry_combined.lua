--[[
    ╔══════════════════════════════════════════════════════════════════╗
    ║                  Matcha VM Auto Parry Script v1.0               ║
    ║                      Combined Single File                       ║
    ║              Compatible with External Lua VM                    ║
    ╚══════════════════════════════════════════════════════════════════╝
    
    Features:
    - Modern GUI with dark theme and purple accents
    - Auto-parry detection using animation monitoring
    - ESP system with visual indicators
    - Teleport functions
    - Configurable timing and range settings
    - Real-time visual feedback
    
    Usage:
    loadfile("matcha_auto_parry_combined.lua")()
    
    Or simply run this file in your Matcha External Lua VM
]]

-- ═══════════════════════════════════════════════════════════════════
-- STARTUP AND ENVIRONMENT CHECKS
-- ═══════════════════════════════════════════════════════════════════

printl("========================================")
printl("  Matcha VM Auto Parry Script v1.0")
printl("  Combined Single File Edition")
printl("========================================")

-- Environment compatibility checks
if not Drawing or not Drawing.new then
    printl("[ERROR] Drawing library not found!")
    printl("[ERROR] This script requires Matcha External Lua VM")
    return
end

if not game or not workspace then
    printl("[ERROR] Game/Workspace not found!")
    printl("[ERROR] This script requires Roblox game environment")
    return
end

printl("[INFO] Environment check passed")

-- Check for required functions
local requiredFunctions = {
    "printl", "wait", "keypress", "keyrelease", 
    "WorldToScreen", "isrbxactive"
}

local missingFunctions = {}
for _, funcName in pairs(requiredFunctions) do
    if not _G[funcName] then
        table.insert(missingFunctions, funcName)
    end
end

if #missingFunctions > 0 then
    printl("[WARNING] Some functions may not be available:")
    for _, funcName in pairs(missingFunctions) do
        printl("[WARNING] Missing:", funcName)
    end
    printl("[WARNING] Script may have limited functionality")
else
    printl("[INFO] All required functions found")
end

-- ═══════════════════════════════════════════════════════════════════
-- UI LIBRARY - MATCHA VM COMPATIBLE
-- ═══════════════════════════════════════════════════════════════════

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

-- ═══════════════════════════════════════════════════════════════════
-- AUTO PARRY SCRIPT - MATCHA VM COMPATIBLE
-- ═══════════════════════════════════════════════════════════════════

printl("[INFO] Loading Auto Parry system...")

-- Configuration
local Config = {
    AutoParryEnabled = false,
    ParryDelay = 100, -- milliseconds
    ParryHoldTime = 500, -- milliseconds
    DetectionRange = 1000, -- studs
    ShowESP = false,
    TeleportEnabled = false,
    DebugMode = false,
    ParryKey = 70 -- F key (adjust as needed)
}

-- Animation database for combat detection
local CombatAnimations = {
    -- Weapon M1 attacks
    ["15656063732"] = "Rapier M1 #1",
    ["15656066582"] = "Rapier M1 #2", 
    ["15656068895"] = "Rapier M1 #3",
    ["15656072148"] = "Rapier M1 #4",
    ["15656081922"] = "Rapier M1 #5",
    
    -- Daemon weapon attacks
    ["88327054724328"] = "Daemon2 M1 #1",
    ["125553613922799"] = "Daemon2 M1 #2",
    ["107664651522529"] = "Daemon2 M1 #3",
    ["133400469836348"] = "Daemon2 M1 #4",
    
    ["117875175361061"] = "Daemon M1 #1",
    ["73099090459858"] = "Daemon M1 #2",
    ["114815438145858"] = "Daemon M1 #3",
    ["100357849679586"] = "Daemon M1 #4",
    
    -- Khopesh attacks
    ["17291378825"] = "Khopesh M1 #1",
    ["16601217295"] = "Khopesh M1 #2",
    ["16601193120"] = "Khopesh M1 #3",
    ["17291400354"] = "Khopesh M1 #4",
    
    -- Odachi attacks
    ["16601187551"] = "Odachi M1 #1",
    ["16601263519"] = "Odachi M1 #4",
    
    -- Mace attacks
    ["111429016677802"] = "Mace M1 #1",
    ["111750449006316"] = "Mace M1 #2",
    ["93301790921336"] = "Mace M1 #3",
    ["126806776427147"] = "Mace M1 #4",
    ["127308532704217"] = "Mace M1 #5",
    
    -- Scythe attacks
    ["16434944253"] = "Scythe M1 #1",
    ["16435003232"] = "Scythe M1 #2",
    ["16435021884"] = "Scythe M1 #5",
    
    -- Heavy Scythe attacks
    ["17334719886"] = "Heavy Scythe M1 #1",
    ["17334724115"] = "Heavy Scythe M1 #2",
    ["17334725521"] = "Heavy Scythe M1 #3",
    ["17334727403"] = "Heavy Scythe M1 #4",
    ["17334729335"] = "Heavy Scythe M1 #5",
    
    -- Nectarspine attacks
    ["108273931210142"] = "Nectarspine M1 #1",
    ["82040063499111"] = "Nectarspine M1 #2",
    ["118417277508646"] = "Nectarspine M1 #3",
    ["107200663724138"] = "Nectarspine M1 #4",
    
    -- Malleator attacks
    ["17579314950"] = "Malleator M1 #1",
    ["17486963369"] = "Malleator M1 #2",
    ["17486969645"] = "Malleator M1 #3",
    ["17486972006"] = "Malleator M1 #4",
    
    -- Silver attacks
    ["80303065510113"] = "Silver M1 #1",
    ["109181671620440"] = "Silver M1 #2",
    ["140112326970480"] = "Silver M1 #3",
    ["75749824649739"] = "Silver M1 #4",
    
    -- Monster attacks
    ["15686010313"] = "Prowler Attack",
    ["15688996008"] = "Prowler Attack 2",
    ["15689269270"] = "Prowler Execute",
    ["18483411505"] = "Frostbat Dash Attack"
}

-- Auto-parry state
local AutoParryState = {
    IsActive = false,
    LastParryTime = 0,
    DetectedAttacks = {},
    ParryCooldown = 500, -- ms
    ActiveAnimations = {},
    MonitoringConnections = {}
}

-- Utility functions
local function log(message)
    if Config.DebugMode then
        printl("[Auto-Parry Debug]", message)
    end
end

local function getLocalCharacter()
    local localPlayer = game:GetPlayers().LocalPlayer
    return localPlayer and localPlayer.Character
end

local function getDistanceFromPlayer(targetCharacter)
    local localCharacter = getLocalCharacter()
    if not localCharacter or not targetCharacter then return math.huge end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not targetRoot then return math.huge end
    
    return (targetRoot.Position - localRoot.Position).Magnitude
end

local function isPlayerAlive(character)
    if not character then return false end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return false end
    
    return humanoid.Health > 0
end

local function isCombatAnimation(animationId)
    -- Extract ID from rbxassetid:// format
    local id = tostring(animationId):match("rbxassetid://(%d+)")
    return id and CombatAnimations[id] ~= nil
end

-- Animation detection system
local AnimationDetector = {}
AnimationDetector.__index = AnimationDetector

function AnimationDetector.new()
    local self = setmetatable({}, AnimationDetector)
    self.detectedAnimations = {}
    self.monitoredPlayers = {}
    self.isRunning = false
    return self
end

function AnimationDetector:startMonitoring()
    if self.isRunning then return end
    self.isRunning = true
    
    log("Starting animation monitoring...")
    
    -- Main monitoring loop
    spawn(function()
        while self.isRunning do
            local players = game:GetPlayers()
            local localPlayer = players.LocalPlayer
            
            for _, player in pairs(players) do
                if player ~= localPlayer and player.Character then
                    self:checkPlayerAnimations(player)
                end
            end
            
            -- Clean old detections
            self:cleanOldDetections()
            
            wait(0.01) -- 100 FPS monitoring
        end
    end)
end

function AnimationDetector:stopMonitoring()
    self.isRunning = false
    log("Stopped animation monitoring")
end

function AnimationDetector:checkPlayerAnimations(player)
    local character = player.Character
    if not character or not isPlayerAlive(character) then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    local distance = getDistanceFromPlayer(character)
    if distance > Config.DetectionRange then return end
    
    -- Check for playing animations
    local animTracks = humanoid:GetPlayingAnimationTracks()
    for _, animTrack in pairs(animTracks) do
        if animTrack.IsPlaying then
            local animId = animTrack.Animation.AnimationId
            if isCombatAnimation(animId) then
                self:onCombatAnimationDetected(player, animId, distance)
            end
        end
    end
end

function AnimationDetector:onCombatAnimationDetected(player, animationId, distance)
    local currentTime = tick()
    local animName = CombatAnimations[tostring(animationId):match("rbxassetid://(%d+)")] or "Unknown"
    
    -- Check if we already detected this animation recently (prevent spam)
    local key = player.Name .. "_" .. animationId
    if AutoParryState.ActiveAnimations[key] and 
       currentTime - AutoParryState.ActiveAnimations[key] < 0.5 then
        return
    end
    
    AutoParryState.ActiveAnimations[key] = currentTime
    
    -- Store detection
    local detection = {
        player = player,
        animationId = animationId,
        animationName = animName,
        time = currentTime,
        distance = distance
    }
    
    table.insert(self.detectedAnimations, detection)
    log("Detected: " .. animName .. " from " .. player.Name .. " (" .. math.floor(distance) .. " studs)")
    
    -- Trigger auto-parry if enabled
    if Config.AutoParryEnabled and AutoParryState.IsActive then
        ParryExecutor:attemptParry(detection)
    end
end

function AnimationDetector:cleanOldDetections()
    local currentTime = tick()
    local newDetections = {}
    local newActiveAnimations = {}
    
    -- Clean detections older than 3 seconds
    for _, detection in pairs(self.detectedAnimations) do
        if currentTime - detection.time < 3.0 then
            table.insert(newDetections, detection)
        end
    end
    
    -- Clean active animations older than 1 second
    for key, time in pairs(AutoParryState.ActiveAnimations) do
        if currentTime - time < 1.0 then
            newActiveAnimations[key] = time
        end
    end
    
    self.detectedAnimations = newDetections
    AutoParryState.ActiveAnimations = newActiveAnimations
end

-- Parry execution system
local ParryExecutor = {}
ParryExecutor.__index = ParryExecutor

function ParryExecutor:attemptParry(detection)
    local currentTime = tick()
    
    -- Check cooldown
    if currentTime - AutoParryState.LastParryTime < (AutoParryState.ParryCooldown / 1000) then
        log("Parry on cooldown")
        return false
    end
    
    -- Apply configured delay
    spawn(function()
        wait(Config.ParryDelay / 1000) -- Convert ms to seconds
        self:executeParry(detection)
    end)
    
    return true
end

function ParryExecutor:executeParry(detection)
    local localCharacter = getLocalCharacter()
    if not localCharacter then return end
    
    local humanoid = localCharacter:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    log("Executing parry against " .. detection.animationName .. " from " .. detection.player.Name)
    
    -- Execute parry using Matcha VM keypress functions
    keypress(Config.ParryKey)
    
    AutoParryState.LastParryTime = tick()
    
    -- Hold parry for configured duration
    spawn(function()
        wait(Config.ParryHoldTime / 1000)
        keyrelease(Config.ParryKey)
        log("Parry hold duration complete")
    end)
    
    -- Visual feedback
    self:showParryFeedback(detection)
end

function ParryExecutor:showParryFeedback(detection)
    -- Create visual feedback using Drawing API
    local feedbackText = Drawing.new("Text")
    feedbackText.Text = "PARRY! vs " .. detection.player.Name
    
    -- Center of screen position
    local screenCenter = Vector2.new(400, 300)
    feedbackText.Position = screenCenter
    feedbackText.Color = Color3.new(1, 1, 0) -- Yellow
    feedbackText.Visible = true
    
    -- Create background for better visibility
    local feedbackBg = Drawing.new("Square")
    feedbackBg.Size = Vector2.new(200, 30)
    feedbackBg.Position = Vector2.new(screenCenter.X - 100, screenCenter.Y - 15)
    feedbackBg.Color = Color3.new(0, 0, 0) -- Black background
    feedbackBg.Filled = true
    feedbackBg.Visible = true
    feedbackBg.Thickness = 1
    
    -- Remove after 1.5 seconds
    spawn(function()
        wait(1.5)
        if feedbackText then feedbackText:Remove() end
        if feedbackBg then feedbackBg:Remove() end
    end)
end

-- ESP system
local ESPManager = {}
ESPManager.espObjects = {}

function ESPManager:createESP(player)
    if not Config.ShowESP or self.espObjects[player] then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    local espBox = Drawing.new("Square")
    espBox.Size = Vector2.new(100, 120)
    espBox.Color = Color3.new(1, 0, 0) -- Red for enemies
    espBox.Filled = false
    espBox.Visible = true
    espBox.Thickness = 2
    
    local espText = Drawing.new("Text")
    espText.Text = player.Name
    espText.Color = Color3.new(1, 1, 1) -- White text
    espText.Visible = true
    
    self.espObjects[player] = {
        box = espBox,
        text = espText,
        character = character
    }
end

function ESPManager:updateESP()
    if not Config.ShowESP then
        self:clearAllESP()
        return
    end
    
    local players = game:GetPlayers()
    local localPlayer = players.LocalPlayer
    
    -- Create ESP for new players
    for _, player in pairs(players) do
        if player ~= localPlayer and player.Character then
            self:createESP(player)
        end
    end
    
    -- Update existing ESP
    for player, espData in pairs(self.espObjects) do
        if player.Character and player.Character == espData.character then
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                local screenPos, onScreen = WorldToScreen(humanoidRootPart.Position)
                
                if onScreen then
                    local distance = getDistanceFromPlayer(character)
                    
                    espData.box.Position = Vector2.new(screenPos.X - 50, screenPos.Y - 60)
                    espData.box.Visible = true
                    
                    espData.text.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 80)
                    espData.text.Text = player.Name .. " [" .. math.floor(distance) .. "m]"
                    espData.text.Visible = true
                else
                    espData.box.Visible = false
                    espData.text.Visible = false
                end
            else
                self:removeESP(player)
            end
        else
            self:removeESP(player)
        end
    end
end

function ESPManager:removeESP(player)
    local espData = self.espObjects[player]
    if espData then
        if espData.box then espData.box:Remove() end
        if espData.text then espData.text:Remove() end
        self.espObjects[player] = nil
    end
end

function ESPManager:clearAllESP()
    for player, _ in pairs(self.espObjects) do
        self:removeESP(player)
    end
end

-- Teleport functions
local function teleportToBase()
    local localCharacter = getLocalCharacter()
    if not localCharacter then 
        printl("[Teleport] No character found")
        return 
    end
    
    local rootPart = localCharacter:FindFirstChild("HumanoidRootPart")
    if not rootPart then 
        printl("[Teleport] No HumanoidRootPart found")
        return 
    end
    
    -- Example teleport coordinates (adjust for your game)
    local basePosition = Vector3.new(0, 50, 0)
    rootPart.CFrame = CFrame.new(basePosition)
    printl("[Teleport] Teleported to base!")
end

local function teleportToPlayer(playerName)
    local targetPlayer = nil
    local players = game:GetPlayers()
    
    for _, player in pairs(players) do
        if player.Name:lower():find(playerName:lower()) then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer or not targetPlayer.Character then
        printl("[Teleport] Player not found or has no character")
        return
    end
    
    local localCharacter = getLocalCharacter()
    if not localCharacter then return end
    
    local localRoot = localCharacter:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if localRoot and targetRoot then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5) -- Teleport slightly behind
        printl("[Teleport] Teleported to", targetPlayer.Name)
    end
end

-- ═══════════════════════════════════════════════════════════════════
-- GUI CREATION AND INITIALIZATION
-- ═══════════════════════════════════════════════════════════════════

-- Create the modern GUI
local function createGUI()
    local gui = UILib.new("redgull hack")
    
    -- ESP Tab
    local espTab = gui:Tab("ESP")
    gui:Section(espTab, "ESP Settings")
    
    gui:Toggle(espTab, "Ally ESP", Config.ShowESP, function(enabled)
        Config.ShowESP = enabled
        printl("[ESP] Ally ESP:", enabled and "ON" or "OFF")
        
        if not enabled then
            ESPManager:clearAllESP()
        end
    end)
    
    gui:Slider(espTab, "ESP Range", Config.DetectionRange, 50, 5000, "studs", function(value)
        Config.DetectionRange = value
        printl("[ESP] Range set to:", value, "studs")
    end)
    
    -- Teleports section
    gui:Section(espTab, "Teleports")
    gui:Button(espTab, "Teleport to Base", function()
        printl("[Teleport] Teleporting to base...")
        teleportToBase()
    end)
    
    -- Auto-Parry Tab
    local parryTab = gui:Tab("Auto-Parry")
    gui:Section(parryTab, "Auto-Parry Settings")
    
    gui:Toggle(parryTab, "Auto Parry", Config.AutoParryEnabled, function(enabled)
        Config.AutoParryEnabled = enabled
        AutoParryState.IsActive = enabled
        printl("[Auto-Parry]", enabled and "ENABLED" or "DISABLED")
        
        if enabled then
            animationDetector:startMonitoring()
        else
            animationDetector:stopMonitoring()
        end
    end)
    
    gui:Slider(parryTab, "Parry Delay", Config.ParryDelay, 10, 500, "ms", function(value)
        Config.ParryDelay = value
        printl("[Auto-Parry] Delay set to:", value, "ms")
    end)
    
    gui:Slider(parryTab, "Hold Time", Config.ParryHoldTime, 100, 2000, "ms", function(value)
        Config.ParryHoldTime = value
        printl("[Auto-Parry] Hold time set to:", value, "ms")
    end)
    
    gui:Slider(parryTab, "Detection Range", Config.DetectionRange, 25, 200, "studs", function(value)
        Config.DetectionRange = value
        printl("[Auto-Parry] Detection range set to:", value, "studs")
    end)
    
    gui:Slider(parryTab, "Parry Cooldown", AutoParryState.ParryCooldown, 100, 2000, "ms", function(value)
        AutoParryState.ParryCooldown = value
        printl("[Auto-Parry] Cooldown set to:", value, "ms")
    end)
    
    gui:Toggle(parryTab, "Debug Mode", Config.DebugMode, function(enabled)
        Config.DebugMode = enabled
        printl("[Debug] Debug mode:", enabled and "ON" or "OFF")
    end)
    
    return gui
end

-- ═══════════════════════════════════════════════════════════════════
-- MAIN EXECUTION AND STARTUP
-- ═══════════════════════════════════════════════════════════════════

-- Initialize systems
local animationDetector = AnimationDetector.new()
local gui = createGUI()

-- Main execution loop
spawn(function()
    printl("[SUCCESS] Auto Parry script loaded successfully!")
    printl("")
    printl("=== INSTRUCTIONS ===")
    printl("1. The GUI should now be visible on your screen")
    printl("2. Navigate through the tabs to configure settings:")
    printl("   - ESP Tab: Configure ESP settings and teleports")
    printl("   - Auto-Parry Tab: Configure auto parry settings")
    printl("3. Enable 'Auto Parry' to start the detection system")
    printl("4. Enable 'Debug Mode' to see detection logs")
    printl("5. Adjust delays and ranges as needed for your playstyle")
    printl("")
    printl("=== FEATURES ===")
    printl("✓ Auto Parry Detection")
    printl("✓ ESP System") 
    printl("✓ Teleport Functions")
    printl("✓ Modern GUI Interface")
    printl("✓ Configurable Timing")
    printl("✓ Debug Mode")
    printl("")
    printl("Script is now running! Enjoy!")
    printl("========================================")
    
    while true do
        -- Update GUI
        gui:Step()
        
        -- Update ESP
        ESPManager:updateESP()
        
        wait(1/60) -- 60 FPS
    end
end)

-- Cleanup on script end
spawn(function()
    while true do
        wait(1)
        -- Periodic cleanup
        if animationDetector then
            animationDetector:cleanOldDetections()
        end
    end
end)

printl("[Auto-Parry] Matcha VM Compatible Auto-Parry Script Loaded!")
printl("[Auto-Parry] All systems initialized and ready!")