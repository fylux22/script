--[[
    Auto-Parry Script for Matcha External Lua VM
    Fixed and compatible with Matcha VM limitations
    Uses the modern UI library with sleek design
    
    Features:
    - Modern GUI matching reference design
    - Auto-parry detection using animation monitoring
    - Configurable timing and range settings
    - ESP system with visual indicators
    - Teleport functions
    - Clean visual feedback
    
    Controls:
    - Use GUI navigation for settings
    - All settings adjustable through UI
    
    Compatible with Matcha VM documented functions only
]]

-- Load the modern UI library
local UILib = loadfile("matcha_ui_library.lua")()

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

-- Initialize systems
local animationDetector = AnimationDetector.new()
local gui = createGUI()

-- Main execution loop
spawn(function()
    printl("[Auto-Parry] Script loaded! Modern GUI initialized.")
    printl("[Auto-Parry] Use the GUI to configure settings.")
    
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
printl("[Auto-Parry] Features: ESP, Auto-Parry, Teleports, Modern GUI")
printl("[Auto-Parry] Navigate the GUI to configure your settings.")