-- ========== MATCHA VM OPTIMIZED AUTO-PARRY SCRIPT ==========
--[[
    Enhanced Auto-Parry Script for Matcha External Lua VM
    
    Features:
    - Proper player event handling for joining/leaving
    - Configurable parry cooldown to prevent spam
    - Enhanced ESP with better visuals and performance
    - Modular code structure for easy maintenance
    - Performance optimized with appropriate wait times
    - Uses only documented Matcha VM functions
    
    Author: Enhanced for Matcha VM compatibility
    Version: 2.0
]]

-- ========== CONFIGURATION ==========
local Config = {
    -- Auto-Parry Settings
    AutoParryEnabled = false,
    ParryDelay = 150,           -- milliseconds between parries (cooldown)
    ParryHoldTime = 300,        -- milliseconds to hold parry key
    DetectionRange = 15,        -- studs for enemy detection
    ParryKey = 70,              -- F key (70 = F)
    
    -- ESP Settings
    ShowESP = false,
    ESPColor = {255, 0, 0},     -- Red color for enemy boxes
    ESPTextColor = {255, 255, 255}, -- White text
    ESPDistance = 100,          -- Maximum ESP render distance
    
    -- Performance Settings
    UpdateRate = 60,            -- FPS for main loop (60 = 16.67ms wait)
    ESPUpdateRate = 30,         -- FPS for ESP updates (30 = 33.33ms wait)
    
    -- Debug Settings
    DebugMode = false,
    ShowPerformanceStats = false
}

-- ========== ANIMATION DATABASE ==========
local CombatAnimations = {
    -- Rapier Weapon Attacks
    ["15656063732"] = {name = "Rapier M1 #1", weight = 1.0},
    ["15656066582"] = {name = "Rapier M1 #2", weight = 1.0}, 
    ["15656068895"] = {name = "Rapier M1 #3", weight = 1.0},
    ["15656072148"] = {name = "Rapier M1 #4", weight = 1.0},
    ["15656081922"] = {name = "Rapier M1 #5", weight = 1.0},
    
    -- Daemon Weapon Attacks
    ["88327054724328"] = {name = "Daemon2 M1 #1", weight = 1.2},
    ["125553613922799"] = {name = "Daemon2 M1 #2", weight = 1.2},
    ["107664651522529"] = {name = "Daemon2 M1 #3", weight = 1.2},
    ["133400469836348"] = {name = "Daemon2 M1 #4", weight = 1.2},
    
    ["117875175361061"] = {name = "Daemon M1 #1", weight = 1.1},
    ["73099090459858"] = {name = "Daemon M1 #2", weight = 1.1},
    ["114815438145858"] = {name = "Daemon M1 #3", weight = 1.1},
    ["100357849679586"] = {name = "Daemon M1 #4", weight = 1.1},
    
    -- Khopesh Weapon Attacks
    ["17291378825"] = {name = "Khopesh M1 #1", weight = 0.9},
    ["16601217295"] = {name = "Khopesh M1 #2", weight = 0.9},
    ["16601193120"] = {name = "Khopesh M1 #3", weight = 0.9},
    ["17291400354"] = {name = "Khopesh M1 #4", weight = 0.9},
    
    -- Katana Weapon Attacks
    ["16643599862"] = {name = "Katana M1 #1", weight = 1.0},
    ["16643607813"] = {name = "Katana M1 #2", weight = 1.0},
    ["16643611557"] = {name = "Katana M1 #3", weight = 1.0},
    ["16643616187"] = {name = "Katana M1 #4", weight = 1.0},
    
    -- Special Attacks
    ["16643630630"] = {name = "Heavy Attack", weight = 1.5},
    ["17291410659"] = {name = "Special Ability", weight = 2.0},
    ["15656086351"] = {name = "Dash Attack", weight = 1.3}
}

-- ========== GLOBAL VARIABLES ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- Performance tracking
local PerformanceStats = {
    LastParryTime = 0,
    TotalParries = 0,
    AttacksDetected = 0,
    ESPObjectCount = 0,
    LastUpdateTime = 0
}

-- ESP Management
local ESPObjects = {}
local ESPUpdateQueue = {}

-- Player tracking
local TrackedPlayers = {}

-- ========== UTILITY FUNCTIONS ==========

--- Get current tick time in milliseconds
--- @return number Current time in milliseconds
local function GetCurrentTime()
    return tick() * 1000
end

--- Safe way to get local player
--- @return Instance|nil LocalPlayer instance
local function GetLocalPlayer()
    return LocalPlayer
end

--- Safe way to get local character
--- @return Instance|nil Character instance
local function GetLocalCharacter()
    local player = GetLocalPlayer()
    return player and player.Character
end

--- Safe way to get local humanoid root part
--- @return Instance|nil HumanoidRootPart instance
local function GetLocalRootPart()
    local character = GetLocalCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

--- Calculate 3D distance between two parts
--- @param part1 Instance First part
--- @param part2 Instance Second part
--- @return number Distance in studs
local function CalculateDistance(part1, part2)
    if not part1 or not part2 then 
        return math.huge 
    end
    
    local pos1 = part1.Position
    local pos2 = part2.Position
    return (pos1 - pos2).Magnitude
end

--- Check if player is within detection range
--- @param player Instance Player to check
--- @return boolean True if in range
local function IsPlayerInRange(player)
    local localRoot = GetLocalRootPart()
    local playerChar = player.Character
    local playerRoot = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not playerRoot then 
        return false 
    end
    
    local distance = CalculateDistance(localRoot, playerRoot)
    return distance <= Config.DetectionRange
end

--- Check if animation ID is a combat animation
--- @param animationId string Animation ID to check
--- @return table|nil Animation data if found
local function GetCombatAnimation(animationId)
    return CombatAnimations[tostring(animationId)]
end

--- Debug logging function
--- @param message string Message to log
--- @param level string Log level (info, warn, error)
local function DebugLog(message, level)
    if not Config.DebugMode then return end
    
    local prefix = "[AUTO-PARRY] "
    if level == "warn" then
        warn(prefix .. message)
    elseif level == "error" then
        warn(prefix .. "ERROR: " .. message)
    else
        printl(prefix .. message)
    end
end

-- ========== PARRY SYSTEM ==========

--- Check if parry is on cooldown
--- @return boolean True if on cooldown
local function IsParryOnCooldown()
    local currentTime = GetCurrentTime()
    return (currentTime - PerformanceStats.LastParryTime) < Config.ParryDelay
end

--- Execute parry action with proper timing
local function ExecuteParry()
    if not isrbxactive() then 
        DebugLog("Roblox not active, skipping parry", "warn")
        return 
    end
    
    if IsParryOnCooldown() then
        DebugLog("Parry on cooldown, skipping", "info")
        return
    end
    
    -- Update parry statistics
    PerformanceStats.LastParryTime = GetCurrentTime()
    PerformanceStats.TotalParries = PerformanceStats.TotalParries + 1
    
    -- Execute parry sequence
    keypress(Config.ParryKey)
    DebugLog("Parry key pressed (Key: " .. Config.ParryKey .. ")", "info")
    
    -- Hold for configured time
    wait(Config.ParryHoldTime / 1000)
    
    keyrelease(Config.ParryKey)
    DebugLog("Parry executed successfully", "info")
end

--- Scan for attack animations on all nearby players
local function ScanForAttacks()
    if not Config.AutoParryEnabled then return end
    
    local localPlayer = GetLocalPlayer()
    if not localPlayer then return end
    
    local attacksFound = 0
    
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= localPlayer and player.Character then
            if IsPlayerInRange(player) then
                local humanoid = player.Character:FindFirstChild("Humanoid")
                if humanoid then
                    local animator = humanoid:FindFirstChild("Animator")
                    if animator then
                        -- Check playing animation tracks
                        for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                            if track.Animation then
                                local animData = GetCombatAnimation(track.Animation.AnimationId)
                                if animData then
                                    attacksFound = attacksFound + 1
                                    PerformanceStats.AttacksDetected = PerformanceStats.AttacksDetected + 1
                                    
                                    DebugLog("Attack detected: " .. animData.name .. " from " .. player.Name, "info")
                                    ExecuteParry()
                                    return -- Only parry once per scan
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-- ========== ESP SYSTEM ==========

--- Create ESP objects for a player
--- @param player Instance Player to create ESP for
local function CreatePlayerESP(player)
    if not Config.ShowESP or ESPObjects[player] then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        NameLabel = Drawing.new("Text"),
        DistanceLabel = Drawing.new("Text"),
        HealthBar = Drawing.new("Square"),
        HealthBarBG = Drawing.new("Square")
    }
    
    -- Configure box
    esp.Box.Visible = false
    esp.Box.Color = Color3.fromRGB(Config.ESPColor[1], Config.ESPColor[2], Config.ESPColor[3])
    esp.Box.Thickness = 2
    esp.Box.Transparency = 0.7
    esp.Box.Filled = false
    
    -- Configure name label
    esp.NameLabel.Visible = false
    esp.NameLabel.Color = Color3.fromRGB(Config.ESPTextColor[1], Config.ESPTextColor[2], Config.ESPTextColor[3])
    esp.NameLabel.Size = 16
    esp.NameLabel.Center = true
    esp.NameLabel.Outline = true
    esp.NameLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.NameLabel.Font = 3 -- Gotham font
    
    -- Configure distance label
    esp.DistanceLabel.Visible = false
    esp.DistanceLabel.Color = Color3.fromRGB(255, 255, 0)
    esp.DistanceLabel.Size = 14
    esp.DistanceLabel.Center = true
    esp.DistanceLabel.Outline = true
    esp.DistanceLabel.OutlineColor = Color3.fromRGB(0, 0, 0)
    esp.DistanceLabel.Font = 3
    
    -- Configure health bar background
    esp.HealthBarBG.Visible = false
    esp.HealthBarBG.Color = Color3.fromRGB(0, 0, 0)
    esp.HealthBarBG.Filled = true
    esp.HealthBarBG.Transparency = 0.5
    
    -- Configure health bar
    esp.HealthBar.Visible = false
    esp.HealthBar.Color = Color3.fromRGB(0, 255, 0)
    esp.HealthBar.Filled = true
    esp.HealthBar.Transparency = 0.8
    
    ESPObjects[player] = esp
    PerformanceStats.ESPObjectCount = PerformanceStats.ESPObjectCount + 1
    
    DebugLog("Created ESP for player: " .. player.Name, "info")
end

--- Remove ESP objects for a player
--- @param player Instance Player to remove ESP for
local function RemovePlayerESP(player)
    local esp = ESPObjects[player]
    if not esp then return end
    
    -- Clean up all drawing objects
    esp.Box:Remove()
    esp.NameLabel:Remove()
    esp.DistanceLabel:Remove()
    esp.HealthBar:Remove()
    esp.HealthBarBG:Remove()
    
    ESPObjects[player] = nil
    PerformanceStats.ESPObjectCount = math.max(0, PerformanceStats.ESPObjectCount - 1)
    
    DebugLog("Removed ESP for player: " .. player.Name, "info")
end

--- Update ESP for a specific player
--- @param player Instance Player to update ESP for
local function UpdatePlayerESP(player)
    local esp = ESPObjects[player]
    if not esp or not Config.ShowESP then 
        if esp then
            esp.Box.Visible = false
            esp.NameLabel.Visible = false
            esp.DistanceLabel.Visible = false
            esp.HealthBar.Visible = false
            esp.HealthBarBG.Visible = false
        end
        return 
    end
    
    local localRoot = GetLocalRootPart()
    local character = player.Character
    local humanoid = character and character:FindFirstChild("Humanoid")
    local rootPart = character and character:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not rootPart or not humanoid then
        esp.Box.Visible = false
        esp.NameLabel.Visible = false
        esp.DistanceLabel.Visible = false
        esp.HealthBar.Visible = false
        esp.HealthBarBG.Visible = false
        return
    end
    
    local distance = CalculateDistance(localRoot, rootPart)
    
    -- Only show ESP for players within ESP distance
    if distance > Config.ESPDistance then
        esp.Box.Visible = false
        esp.NameLabel.Visible = false
        esp.DistanceLabel.Visible = false
        esp.HealthBar.Visible = false
        esp.HealthBarBG.Visible = false
        return
    end
    
    -- Convert 3D position to 2D screen position
    local screenPos, onScreen = WorldToScreen(rootPart.Position)
    
    if onScreen then
        local boxSize = math.max(40, 100 - distance)
        local boxHeight = boxSize * 1.5
        
        -- Update box
        esp.Box.Size = Vector2.new(boxSize, boxHeight)
        esp.Box.Position = Vector2.new(screenPos.X - boxSize/2, screenPos.Y - boxHeight/2)
        esp.Box.Visible = true
        
        -- Update name label
        esp.NameLabel.Text = player.Name
        esp.NameLabel.Position = Vector2.new(screenPos.X, screenPos.Y - boxHeight/2 - 20)
        esp.NameLabel.Visible = true
        
        -- Update distance label
        esp.DistanceLabel.Text = math.floor(distance) .. " studs"
        esp.DistanceLabel.Position = Vector2.new(screenPos.X, screenPos.Y + boxHeight/2 + 5)
        esp.DistanceLabel.Visible = true
        
        -- Update health bar
        local healthPercent = humanoid.Health / humanoid.MaxHealth
        local healthBarWidth = boxSize * 0.8
        local healthBarHeight = 4
        
        -- Health bar background
        esp.HealthBarBG.Size = Vector2.new(healthBarWidth, healthBarHeight)
        esp.HealthBarBG.Position = Vector2.new(screenPos.X - healthBarWidth/2, screenPos.Y + boxHeight/2 + 20)
        esp.HealthBarBG.Visible = true
        
        -- Health bar
        esp.HealthBar.Size = Vector2.new(healthBarWidth * healthPercent, healthBarHeight)
        esp.HealthBar.Position = Vector2.new(screenPos.X - healthBarWidth/2, screenPos.Y + boxHeight/2 + 20)
        esp.HealthBar.Color = Color3.fromRGB(
            math.floor(255 * (1 - healthPercent)),
            math.floor(255 * healthPercent),
            0
        )
        esp.HealthBar.Visible = true
        
        -- Change box color based on distance
        if distance <= Config.DetectionRange then
            esp.Box.Color = Color3.fromRGB(255, 0, 0) -- Red for in attack range
        else
            esp.Box.Color = Color3.fromRGB(255, 165, 0) -- Orange for visible
        end
    else
        esp.Box.Visible = false
        esp.NameLabel.Visible = false
        esp.DistanceLabel.Visible = false
        esp.HealthBar.Visible = false
        esp.HealthBarBG.Visible = false
    end
end

--- Update all ESP objects
local function UpdateAllESP()
    for player, _ in pairs(ESPObjects) do
        if player and player.Parent then
            UpdatePlayerESP(player)
        else
            RemovePlayerESP(player)
        end
    end
end

-- ========== PLAYER EVENT HANDLING ==========

--- Handle player joining the game
--- @param player Instance Player that joined
local function OnPlayerAdded(player)
    if player == GetLocalPlayer() then return end
    
    TrackedPlayers[player] = true
    CreatePlayerESP(player)
    
    DebugLog("Player joined: " .. player.Name, "info")
end

--- Handle player leaving the game
--- @param player Instance Player that left
local function OnPlayerRemoving(player)
    TrackedPlayers[player] = nil
    RemovePlayerESP(player)
    
    DebugLog("Player left: " .. player.Name, "info")
end

--- Initialize player tracking for existing players
local function InitializePlayerTracking()
    for _, player in pairs(Players:GetPlayers()) do
        OnPlayerAdded(player)
    end
end

-- ========== UI SYSTEM ==========

--- Simple UI status display
local StatusDisplay = {
    Title = Drawing.new("Text"),
    Status = Drawing.new("Text"),
    Stats = Drawing.new("Text")
}

--- Initialize status display
local function InitializeStatusDisplay()
    -- Title
    StatusDisplay.Title.Text = "🛡️ AUTO-PARRY v2.0"
    StatusDisplay.Title.Size = 18
    StatusDisplay.Title.Color = Color3.fromRGB(255, 255, 255)
    StatusDisplay.Title.Position = Vector2.new(10, 10)
    StatusDisplay.Title.Visible = true
    StatusDisplay.Title.Font = 3
    StatusDisplay.Title.Outline = true
    StatusDisplay.Title.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    -- Status
    StatusDisplay.Status.Text = "Status: DISABLED"
    StatusDisplay.Status.Size = 14
    StatusDisplay.Status.Color = Color3.fromRGB(255, 100, 100)
    StatusDisplay.Status.Position = Vector2.new(10, 35)
    StatusDisplay.Status.Visible = true
    StatusDisplay.Status.Font = 3
    StatusDisplay.Status.Outline = true
    StatusDisplay.Status.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    -- Stats
    StatusDisplay.Stats.Text = ""
    StatusDisplay.Stats.Size = 12
    StatusDisplay.Stats.Color = Color3.fromRGB(200, 200, 200)
    StatusDisplay.Stats.Position = Vector2.new(10, 55)
    StatusDisplay.Stats.Visible = Config.ShowPerformanceStats
    StatusDisplay.Stats.Font = 3
    StatusDisplay.Stats.Outline = true
    StatusDisplay.Stats.OutlineColor = Color3.fromRGB(0, 0, 0)
end

--- Update status display
local function UpdateStatusDisplay()
    -- Update status
    if Config.AutoParryEnabled then
        StatusDisplay.Status.Text = "Status: ENABLED"
        StatusDisplay.Status.Color = Color3.fromRGB(100, 255, 100)
    else
        StatusDisplay.Status.Text = "Status: DISABLED" 
        StatusDisplay.Status.Color = Color3.fromRGB(255, 100, 100)
    end
    
    -- Update stats if enabled
    if Config.ShowPerformanceStats then
        StatusDisplay.Stats.Text = string.format(
            "Parries: %d | Attacks: %d | ESP Objects: %d",
            PerformanceStats.TotalParries,
            PerformanceStats.AttacksDetected,
            PerformanceStats.ESPObjectCount
        )
        StatusDisplay.Stats.Visible = true
    else
        StatusDisplay.Stats.Visible = false
    end
end

-- ========== INPUT HANDLING ==========

--- Handle key inputs for toggles and controls
local function HandleInputs()
    if not isrbxactive() then return end
    
    -- F1 - Toggle Auto-Parry
    if iskeypressed(112) then -- F1
        Config.AutoParryEnabled = not Config.AutoParryEnabled
        printl("Auto-Parry " .. (Config.AutoParryEnabled and "ENABLED" or "DISABLED"))
        wait(0.2) -- Prevent spam
    end
    
    -- F2 - Toggle ESP
    if iskeypressed(113) then -- F2
        Config.ShowESP = not Config.ShowESP
        printl("ESP " .. (Config.ShowESP and "ENABLED" or "DISABLED"))
        wait(0.2)
    end
    
    -- F3 - Toggle Debug Mode
    if iskeypressed(114) then -- F3
        Config.DebugMode = not Config.DebugMode
        printl("Debug Mode " .. (Config.DebugMode and "ENABLED" or "DISABLED"))
        wait(0.2)
    end
    
    -- F4 - Toggle Performance Stats
    if iskeypressed(115) then -- F4
        Config.ShowPerformanceStats = not Config.ShowPerformanceStats
        printl("Performance Stats " .. (Config.ShowPerformanceStats and "ENABLED" or "DISABLED"))
        wait(0.2)
    end
end

-- ========== MAIN EXECUTION ==========

--- Initialize all systems
local function Initialize()
    printl("🛡️ Auto-Parry Script v2.0 Loading...")
    
    -- Initialize subsystems
    InitializeStatusDisplay()
    InitializePlayerTracking()
    
    -- Performance optimization: pre-calculate wait times
    local mainLoopWait = 1 / Config.UpdateRate
    local espUpdateWait = 1 / Config.ESPUpdateRate
    
    printl("✅ Auto-Parry Script v2.0 Loaded Successfully!")
    printl("Controls:")
    printl("F1 - Toggle Auto-Parry")
    printl("F2 - Toggle ESP") 
    printl("F3 - Toggle Debug Mode")
    printl("F4 - Toggle Performance Stats")
    
    return mainLoopWait, espUpdateWait
end

--- Main execution loop
local function RunMainLoop()
    local mainLoopWait, espUpdateWait = Initialize()
    local lastESPUpdate = 0
    local currentTime = 0
    
    while true do
        currentTime = GetCurrentTime()
        
        if isrbxactive() then
            -- Handle user inputs
            HandleInputs()
            
            -- Update status display
            UpdateStatusDisplay()
            
            -- Scan for attacks (main feature)
            ScanForAttacks()
            
            -- Update ESP at lower frequency for performance
            if currentTime - lastESPUpdate >= (espUpdateWait * 1000) then
                UpdateAllESP()
                lastESPUpdate = currentTime
            end
            
            PerformanceStats.LastUpdateTime = currentTime
        end
        
        wait(mainLoopWait)
    end
end

-- ========== START EXECUTION ==========
RunMainLoop()