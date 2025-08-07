-- ========== MATCHA VM OPTIMIZED AUTO PARRY SCRIPT ==========
--[[
    Auto-Parry Script for Matcha External Lua VM
    Optimized for Matcha VM's actual documented capabilities
    
    Features:
    - Full Drawing API support for visual ESP
    - WorldToScreen for proper 2D positioning
    - Proper game service access
    - Visual feedback and indicators
    - Modern GUI-like interface using Drawing
    
    Based on official Matcha VM documentation
]]

-- ========== CONFIGURATION ==========
local Config = {
    AutoParryEnabled = false,
    ParryDelay = 100, -- milliseconds
    ParryHoldTime = 500, -- milliseconds
    DetectionRange = 1000, -- studs
    ShowESP = false,
    DebugMode = false,
    ParryKey = 70, -- F key
    TeleportEnabled = true
}

-- ========== ANIMATION DATABASE ==========
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

-- ========== AUTO-PARRY STATE ==========
local AutoParryState = {
    IsActive = false,
    LastParryTime = 0,
    ParryCooldown = 500,
    ActiveAnimations = {},
    MonitoringActive = false
}

-- ========== UTILITY FUNCTIONS ==========
local function log(message)
    if Config.DebugMode then
        printl("[Auto-Parry Debug]", message)
    end
end

local function getLocalCharacter()
    local localPlayer = game:GetService("Players").LocalPlayer
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
    local id = tostring(animationId):match("rbxassetid://(%d+)")
    return id and CombatAnimations[id] ~= nil
end

-- ========== ANIMATION DETECTION SYSTEM ==========
local AnimationDetector = {}
AnimationDetector.__index = AnimationDetector

function AnimationDetector.new()
    local self = setmetatable({}, AnimationDetector)
    self.detectedAnimations = {}
    self.isRunning = false
    return self
end

function AnimationDetector:startMonitoring()
    if self.isRunning then return end
    self.isRunning = true
    AutoParryState.MonitoringActive = true
    
    log("Starting animation monitoring...")
    
    -- Main monitoring loop using proper scheduling
    local function monitorLoop()
        while self.isRunning do
            local players = game:GetService("Players"):GetPlayers()
            local localPlayer = game:GetService("Players").LocalPlayer
            
            for _, player in pairs(players) do
                if player ~= localPlayer and player.Character then
                    self:checkPlayerAnimations(player)
                end
            end
            
            self:cleanOldDetections()
            wait(0.01) -- 100 FPS monitoring
        end
    end
    
    -- Start monitoring in a separate thread
    coroutine.wrap(monitorLoop)()
end

function AnimationDetector:stopMonitoring()
    self.isRunning = false
    AutoParryState.MonitoringActive = false
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
    local success, animTracks = pcall(function()
        return humanoid:GetPlayingAnimationTracks()
    end)
    
    if not success or not animTracks then return end
    
    for _, animTrack in pairs(animTracks) do
        if animTrack.IsPlaying and animTrack.Animation then
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
    
    -- Check if we already detected this animation recently
    local key = player.Name .. "_" .. animationId
    if AutoParryState.ActiveAnimations[key] and 
       currentTime - AutoParryState.ActiveAnimations[key] < 0.5 then
        return
    end
    
    AutoParryState.ActiveAnimations[key] = currentTime
    
    local detection = {
        player = player,
        animationId = animationId,
        animationName = animName,
        time = currentTime,
        distance = distance
    }
    
    table.insert(self.detectedAnimations, detection)
    log("Detected: " .. animName .. " from " .. player.Name .. " (" .. math.floor(distance) .. " studs)")
    
    if Config.AutoParryEnabled then
        ParryExecutor:attemptParry(detection)
    end
end

function AnimationDetector:cleanOldDetections()
    local currentTime = tick()
    local newDetections = {}
    local newActiveAnimations = {}
    
    for _, detection in pairs(self.detectedAnimations) do
        if currentTime - detection.time < 3.0 then
            table.insert(newDetections, detection)
        end
    end
    
    for key, time in pairs(AutoParryState.ActiveAnimations) do
        if currentTime - time < 1.0 then
            newActiveAnimations[key] = time
        end
    end
    
    self.detectedAnimations = newDetections
    AutoParryState.ActiveAnimations = newActiveAnimations
end

-- ========== PARRY EXECUTION SYSTEM ==========
local ParryExecutor = {}
ParryExecutor.__index = ParryExecutor

function ParryExecutor:attemptParry(detection)
    local currentTime = tick()
    
    if currentTime - AutoParryState.LastParryTime < (AutoParryState.ParryCooldown / 1000) then
        log("Parry on cooldown")
        return false
    end
    
    -- Apply configured delay then execute
    coroutine.wrap(function()
        wait(Config.ParryDelay / 1000)
        self:executeParry(detection)
    end)()
    
    return true
end

function ParryExecutor:executeParry(detection)
    local localCharacter = getLocalCharacter()
    if not localCharacter then return end
    
    log("Executing parry against " .. detection.animationName .. " from " .. detection.player.Name)
    
    -- Execute parry using Matcha VM keypress functions
    keypress(Config.ParryKey)
    
    AutoParryState.LastParryTime = tick()
    
    -- Hold parry for configured duration
    coroutine.wrap(function()
        wait(Config.ParryHoldTime / 1000)
        keyrelease(Config.ParryKey)
        log("Parry hold duration complete")
    end)()
    
    -- Show visual feedback
    self:showParryFeedback(detection)
end

function ParryExecutor:showParryFeedback(detection)
    -- Create visual feedback using Matcha's Drawing API
    local feedbackText = Drawing.new("Text")
    feedbackText.Text = "PARRY! vs " .. detection.player.Name
    feedbackText.Position = Vector2(400, 300) -- Center of screen
    feedbackText.Color = Color3.new(1, 1, 0) -- Yellow
    feedbackText.Visible = true
    
    -- Create background square for better visibility
    local feedbackBg = Drawing.new("Square")
    feedbackBg.Size = Vector2(200, 30)
    feedbackBg.Position = Vector2(300, 285)
    feedbackBg.Color = Color3.new(0, 0, 0) -- Black background
    feedbackBg.Filled = true
    feedbackBg.Visible = true
    
    -- Remove after 1.5 seconds
    coroutine.wrap(function()
        wait(1.5)
        feedbackText:Remove()
        feedbackBg:Remove()
    end)()
end

-- ========== ESP SYSTEM ==========
local ESPManager = {}
ESPManager.espObjects = {}

function ESPManager:createESP(player)
    if not Config.ShowESP or self.espObjects[player] then return end
    
    local character = player.Character
    if not character then return end
    
    local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Create ESP box using Matcha's Drawing API
    local espBox = Drawing.new("Square")
    espBox.Size = Vector2(100, 120)
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
    
    local players = game:GetService("Players"):GetPlayers()
    local localPlayer = game:GetService("Players").LocalPlayer
    
    -- Create ESP for new players
    for _, player in pairs(players) do
        if player ~= localPlayer and player.Character then
            self:createESP(player)
        end
    end
    
    -- Update existing ESP using WorldToScreen
    for player, espData in pairs(self.espObjects) do
        if player.Character and player.Character == espData.character then
            local character = player.Character
            local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
            
            if humanoidRootPart then
                local screenPos, onScreen = WorldToScreen(humanoidRootPart.Position)
                
                if onScreen then
                    local distance = getDistanceFromPlayer(character)
                    
                    espData.box.Position = Vector2(screenPos.X - 50, screenPos.Y - 60)
                    espData.box.Visible = true
                    
                    espData.text.Position = Vector2(screenPos.X - 25, screenPos.Y - 80)
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
        espData.box:Remove()
        espData.text:Remove()
        self.espObjects[player] = nil
    end
end

function ESPManager:clearAllESP()
    for player, _ in pairs(self.espObjects) do
        self:removeESP(player)
    end
end

-- ========== TELEPORT FUNCTIONS ==========
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
    
    -- Example teleport coordinates
    local basePosition = Vector3(0, 50, 0)
    rootPart.CFrame = CFrame.new(basePosition)
    printl("[Teleport] Teleported to base!")
end

local function teleportToPlayer(playerName)
    local players = game:GetService("Players"):GetPlayers()
    local targetPlayer = nil
    
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
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
        printl("[Teleport] Teleported to", targetPlayer.Name)
    end
end

-- ========== MAIN GUI USING DRAWING API ==========
local GUI = {}
GUI.elements = {}
GUI.isVisible = false

function GUI:init()
    -- Create main window background
    local mainBg = Drawing.new("Square")
    mainBg.Size = Vector2(400, 300)
    mainBg.Position = Vector2(50, 50)
    mainBg.Color = Color3.new(0.1, 0.1, 0.1)
    mainBg.Filled = true
    mainBg.Visible = true
    
    -- Create title
    local title = Drawing.new("Text")
    title.Text = "Matcha Auto-Parry v2.0"
    title.Position = Vector2(150, 60)
    title.Color = Color3.new(1, 1, 1)
    title.Visible = true
    
    -- Create status indicators
    local statusY = 100
    local indicators = {
        {label = "Auto-Parry:", getValue = function() return Config.AutoParryEnabled and "ON" or "OFF" end},
        {label = "ESP:", getValue = function() return Config.ShowESP and "ON" or "OFF" end},
        {label = "Debug:", getValue = function() return Config.DebugMode and "ON" or "OFF" end},
        {label = "Monitoring:", getValue = function() return AutoParryState.MonitoringActive and "ACTIVE" or "INACTIVE" end},
        {label = "Parry Delay:", getValue = function() return Config.ParryDelay .. "ms" end},
        {label = "Hold Time:", getValue = function() return Config.ParryHoldTime .. "ms" end},
        {label = "Range:", getValue = function() return Config.DetectionRange .. " studs" end}
    }
    
    for i, indicator in ipairs(indicators) do
        local labelText = Drawing.new("Text")
        labelText.Text = indicator.label
        labelText.Position = Vector2(70, statusY + (i * 25))
        labelText.Color = Color3.new(0.8, 0.8, 0.8)
        labelText.Visible = true
        
        local valueText = Drawing.new("Text")
        valueText.Text = indicator.getValue()
        valueText.Position = Vector2(200, statusY + (i * 25))
        valueText.Color = Color3.new(0, 1, 0)
        valueText.Visible = true
        
        table.insert(self.elements, {label = labelText, value = valueText, getValue = indicator.getValue})
    end
    
    table.insert(self.elements, mainBg)
    table.insert(self.elements, title)
    
    self.isVisible = true
    
    -- Start update loop
    self:startUpdateLoop()
end

function GUI:startUpdateLoop()
    coroutine.wrap(function()
        while self.isVisible do
            self:update()
            wait(0.1) -- Update every 100ms
        end
    end)()
end

function GUI:update()
    for _, element in pairs(self.elements) do
        if element.getValue and element.value then
            element.value.Text = element.getValue()
        end
    end
end

function GUI:toggle()
    self.isVisible = not self.isVisible
    for _, element in pairs(self.elements) do
        if element.label then
            element.label.Visible = self.isVisible
            element.value.Visible = self.isVisible
        else
            element.Visible = self.isVisible
        end
    end
end

function GUI:cleanup()
    for _, element in pairs(self.elements) do
        if element.label then
            element.label:Remove()
            element.value:Remove()
        else
            element:Remove()
        end
    end
    self.elements = {}
    self.isVisible = false
end

-- ========== COMMAND SYSTEM ==========
local Commands = {}

Commands.help = function()
    printl("=== Matcha Auto-Parry Commands ===")
    printl("parry - Toggle auto-parry")
    printl("esp - Toggle ESP")
    printl("debug - Toggle debug mode")
    printl("gui - Toggle GUI")
    printl("delay [ms] - Set parry delay")
    printl("hold [ms] - Set hold time")
    printl("range [studs] - Set detection range")
    printl("tp base - Teleport to base")
    printl("tp [player] - Teleport to player")
    printl("status - Show current status")
end

Commands.parry = function()
    Config.AutoParryEnabled = not Config.AutoParryEnabled
    if Config.AutoParryEnabled then
        animationDetector:startMonitoring()
        printl("[Auto-Parry] ENABLED")
    else
        animationDetector:stopMonitoring()
        printl("[Auto-Parry] DISABLED")
    end
end

Commands.esp = function()
    Config.ShowESP = not Config.ShowESP
    printl("[ESP]", Config.ShowESP and "ENABLED" or "DISABLED")
    if not Config.ShowESP then
        ESPManager:clearAllESP()
    end
end

Commands.debug = function()
    Config.DebugMode = not Config.DebugMode
    printl("[Debug]", Config.DebugMode and "ENABLED" or "DISABLED")
end

Commands.gui = function()
    GUI:toggle()
    printl("[GUI]", GUI.isVisible and "SHOWN" or "HIDDEN")
end

Commands.delay = function(ms)
    if ms and tonumber(ms) then
        Config.ParryDelay = tonumber(ms)
        printl("[Config] Parry delay set to:", Config.ParryDelay .. "ms")
    else
        printl("[Config] Current parry delay:", Config.ParryDelay .. "ms")
    end
end

Commands.hold = function(ms)
    if ms and tonumber(ms) then
        Config.ParryHoldTime = tonumber(ms)
        printl("[Config] Hold time set to:", Config.ParryHoldTime .. "ms")
    else
        printl("[Config] Current hold time:", Config.ParryHoldTime .. "ms")
    end
end

Commands.range = function(studs)
    if studs and tonumber(studs) then
        Config.DetectionRange = tonumber(studs)
        printl("[Config] Detection range set to:", Config.DetectionRange .. " studs")
    else
        printl("[Config] Current detection range:", Config.DetectionRange .. " studs")
    end
end

Commands.tp = function(target)
    if not Config.TeleportEnabled then
        printl("[Teleport] Teleport is disabled")
        return
    end
    
    if target == "base" then
        teleportToBase()
    elseif target then
        teleportToPlayer(target)
    else
        printl("[Teleport] Usage: tp [base/player_name]")
    end
end

Commands.status = function()
    printl("=== Auto-Parry Status ===")
    printl("Auto-Parry:", Config.AutoParryEnabled and "ON" or "OFF")
    printl("ESP:", Config.ShowESP and "ON" or "OFF") 
    printl("Debug:", Config.DebugMode and "ON" or "OFF")
    printl("Monitoring:", AutoParryState.MonitoringActive and "ACTIVE" or "INACTIVE")
    printl("Parry Delay:", Config.ParryDelay .. "ms")
    printl("Hold Time:", Config.ParryHoldTime .. "ms")
    printl("Detection Range:", Config.DetectionRange .. " studs")
    printl("Roblox Active:", isrbxactive() and "YES" or "NO")
end

-- ========== INITIALIZATION ==========
local animationDetector = AnimationDetector.new()

-- Main execution loop
coroutine.wrap(function()
    printl("=== Matcha Auto-Parry Script v2.0 ===")
    printl("Optimized for Matcha VM capabilities")
    printl("Type Commands.help() for available commands")
    
    -- Initialize GUI
    GUI:init()
    
    while true do
        -- Update ESP
        ESPManager:updateESP()
        
        wait(1/60) -- 60 FPS
    end
end)()

-- ========== CLEANUP ==========
local function cleanup()
    if animationDetector then
        animationDetector:stopMonitoring()
    end
    ESPManager:clearAllESP()
    GUI:cleanup()
end

printl("[Auto-Parry] Matcha VM Optimized Script Loaded!")
printl("[Auto-Parry] Use Commands.help() to see available commands")
printl("[Auto-Parry] Use Commands.parry() to toggle auto-parry")

-- ========== END: MATCHA VM OPTIMIZED AUTO PARRY SCRIPT ==========