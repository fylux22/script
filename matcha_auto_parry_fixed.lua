-- ========== START: MATCHA COMPATIBLE AUTO PARRY SCRIPT ==========
--[[
    Auto-Parry Script for Matcha External Lua VM
    Fixed and compatible with Matcha VM limitations
    
    Features:
    - Simplified UI system compatible with external VMs
    - Auto-parry detection using basic functions only
    - Configurable timing and range settings
    - Basic visual feedback
    - Teleport functions using supported APIs
    
    Compatible Functions Used:
    - print() for output
    - wait() for delays  
    - keypress() / keyrelease() for input
    - tick() for timing
    - game service access for player/character data
    - Basic table and string operations
]]

-- ========== SIMPLIFIED UI LIBRARY ==========
local SimpleUI = {}

function SimpleUI.new(title)
    local ui = {
        title = title or "Script UI",
        settings = {}
    }
    
    -- Print-based UI system for external VM compatibility
    function ui:show()
        print("========================================")
        print("  " .. self.title)
        print("========================================")
        for key, value in pairs(self.settings) do
            local status = value and "ON" or "OFF"
            if type(value) == "number" then
                status = tostring(value)
            end
            print(key .. ": " .. status)
        end
        print("========================================")
    end
    
    function ui:set(key, value)
        self.settings[key] = value
        print("[UI] " .. key .. " set to: " .. tostring(value))
    end
    
    function ui:get(key)
        return self.settings[key]
    end
    
    return ui
end

-- ========== CONFIGURATION ==========
local Config = {
    AutoParryEnabled = false,
    ParryDelay = 100, -- milliseconds
    ParryHoldTime = 500, -- milliseconds
    DetectionRange = 1000, -- studs
    DebugMode = false,
    ParryKey = 70, -- F key
    ESPEnabled = false,
    TeleportEnabled = false
}

-- ========== ANIMATION DATABASE ==========
local CombatAnimations = {
    -- Simplified animation database - add more as needed
    ["15656063732"] = true, -- Rapier M1 #1
    ["15656066582"] = true, -- Rapier M1 #2
    ["15656068895"] = true, -- Rapier M1 #3
    ["15656072148"] = true, -- Rapier M1 #4
    ["15656081922"] = true, -- Rapier M1 #5
    ["88327054724328"] = true, -- Daemon2 M1 #1
    ["125553613922799"] = true, -- Daemon2 M1 #2
    ["107664651522529"] = true, -- Daemon2 M1 #3
    ["133400469836348"] = true, -- Daemon2 M1 #4
    ["117875175361061"] = true, -- Daemon M1 #1
    ["73099090459858"] = true, -- Daemon M1 #2
    ["114815438145858"] = true, -- Daemon M1 #3
    ["100357849679586"] = true, -- Daemon M1 #4
}

-- ========== UTILITY FUNCTIONS ==========
local function log(message)
    if Config.DebugMode then
        print("[Debug] " .. tostring(message))
    end
end

local function getTime()
    -- Use tick() if available, otherwise fallback to os.clock
    if tick then
        return tick()
    elseif os and os.clock then
        return os.clock() * 1000 -- convert to milliseconds
    else
        return 0
    end
end

-- ========== SIMPLIFIED GAME ACCESS ==========
local GameAccess = {}

function GameAccess.getLocalPlayer()
    -- Try different methods to access local player
    if game and game.Players and game.Players.LocalPlayer then
        return game.Players.LocalPlayer
    elseif game and game.GetService then
        local success, players = pcall(game.GetService, game, "Players")
        if success and players.LocalPlayer then
            return players.LocalPlayer
        end
    end
    return nil
end

function GameAccess.getLocalCharacter()
    local player = self.getLocalPlayer()
    if player and player.Character then
        return player.Character
    end
    return nil
end

function GameAccess.getAllPlayers()
    local players = {}
    if game and game.Players then
        for _, player in pairs(game.Players:GetPlayers and game.Players:GetPlayers() or {}) do
            if player ~= GameAccess.getLocalPlayer() then
                table.insert(players, player)
            end
        end
    end
    return players
end

function GameAccess.getDistance(char1, char2)
    if not char1 or not char2 then return math.huge end
    
    local root1 = char1:FindFirstChild("HumanoidRootPart")
    local root2 = char2:FindFirstChild("HumanoidRootPart")
    
    if not root1 or not root2 then return math.huge end
    
    local pos1 = root1.Position
    local pos2 = root2.Position
    
    -- Simple distance calculation
    local dx = pos1.X - pos2.X
    local dy = pos1.Y - pos2.Y
    local dz = pos1.Z - pos2.Z
    
    return math.sqrt(dx*dx + dy*dy + dz*dz)
end

-- ========== AUTO-PARRY SYSTEM ==========
local AutoParry = {
    isActive = false,
    lastParryTime = 0,
    cooldownMs = 500,
    detectedAnimations = {}
}

function AutoParry:start()
    if self.isActive then return end
    
    self.isActive = true
    log("Auto-parry system started")
    
    -- Start monitoring loop
    self:monitorLoop()
end

function AutoParry:stop()
    self.isActive = false
    log("Auto-parry system stopped")
end

function AutoParry:monitorLoop()
    while self.isActive do
        self:checkForCombatAnimations()
        wait(0.01) -- 100 FPS monitoring
    end
end

function AutoParry:checkForCombatAnimations()
    local currentTime = getTime()
    local localChar = GameAccess.getLocalCharacter()
    
    if not localChar then return end
    
    local players = GameAccess.getAllPlayers()
    
    for _, player in pairs(players) do
        if player.Character then
            local distance = GameAccess.getDistance(localChar, player.Character)
            
            if distance <= Config.DetectionRange then
                self:checkPlayerAnimations(player, distance, currentTime)
            end
        end
    end
end

function AutoParry:checkPlayerAnimations(player, distance, currentTime)
    local character = player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Try to get animation tracks - this may not work in all VMs
    local success, animTracks = pcall(function()
        return humanoid:GetPlayingAnimationTracks()
    end)
    
    if not success then return end
    
    for _, track in pairs(animTracks or {}) do
        if track.IsPlaying and track.Animation then
            local animId = tostring(track.Animation.AnimationId):match("(%d+)")
            
            if animId and CombatAnimations[animId] then
                self:onCombatDetected(player.Name, animId, distance, currentTime)
            end
        end
    end
end

function AutoParry:onCombatDetected(playerName, animId, distance, currentTime)
    if not Config.AutoParryEnabled then return end
    
    -- Check cooldown
    if currentTime - self.lastParryTime < self.cooldownMs then
        log("Parry on cooldown")
        return
    end
    
    log("Combat detected from " .. playerName .. " at " .. math.floor(distance) .. " studs")
    
    -- Execute parry after delay
    wait(Config.ParryDelay / 1000)
    self:executeParry(playerName)
end

function AutoParry:executeParry(targetName)
    log("Executing parry against " .. targetName)
    
    -- Press parry key
    if keypress then
        keypress(Config.ParryKey)
    end
    
    self.lastParryTime = getTime()
    
    -- Hold for specified duration
    wait(Config.ParryHoldTime / 1000)
    
    -- Release parry key
    if keyrelease then
        keyrelease(Config.ParryKey)
    end
    
    print("[PARRY] Executed against " .. targetName)
end

-- ========== TELEPORT FUNCTIONS ==========
local Teleports = {}

function Teleports.toBase()
    local character = GameAccess.getLocalCharacter()
    if not character then
        print("[Teleport] No character found")
        return
    end
    
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not rootPart then
        print("[Teleport] No HumanoidRootPart found")
        return
    end
    
    -- Example base coordinates - adjust as needed
    local basePos = Vector3.new(0, 50, 0)
    
    local success = pcall(function()
        rootPart.CFrame = CFrame.new(basePos)
    end)
    
    if success then
        print("[Teleport] Teleported to base!")
    else
        print("[Teleport] Failed to teleport")
    end
end

function Teleports.toPlayer(targetName)
    local localChar = GameAccess.getLocalCharacter()
    if not localChar then
        print("[Teleport] No local character")
        return
    end
    
    local players = GameAccess.getAllPlayers()
    local targetPlayer = nil
    
    for _, player in pairs(players) do
        if player.Name:lower():find(targetName:lower()) then
            targetPlayer = player
            break
        end
    end
    
    if not targetPlayer or not targetPlayer.Character then
        print("[Teleport] Player not found: " .. targetName)
        return
    end
    
    local localRoot = localChar:FindFirstChild("HumanoidRootPart")
    local targetRoot = targetPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if localRoot and targetRoot then
        local success = pcall(function()
            localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
        end)
        
        if success then
            print("[Teleport] Teleported to " .. targetPlayer.Name)
        else
            print("[Teleport] Failed to teleport to " .. targetPlayer.Name)
        end
    end
end

-- ========== ESP SYSTEM (SIMPLIFIED) ==========
local ESP = {
    enabled = false,
    lastUpdate = 0
}

function ESP:toggle()
    self.enabled = not self.enabled
    print("[ESP] " .. (self.enabled and "Enabled" or "Disabled"))
    
    if self.enabled then
        self:startLoop()
    end
end

function ESP:startLoop()
    while self.enabled do
        self:updateESP()
        wait(0.1) -- Update every 100ms
    end
end

function ESP:updateESP()
    if not self.enabled then return end
    
    local currentTime = getTime()
    if currentTime - self.lastUpdate < 100 then return end
    
    self.lastUpdate = currentTime
    local localChar = GameAccess.getLocalCharacter()
    if not localChar then return end
    
    local players = GameAccess.getAllPlayers()
    
    print("[ESP] === Player List ===")
    for _, player in pairs(players) do
        if player.Character then
            local distance = GameAccess.getDistance(localChar, player.Character)
            print("[ESP] " .. player.Name .. " - " .. math.floor(distance) .. " studs")
        end
    end
end

-- ========== MAIN UI AND CONTROLS ==========
local ui = SimpleUI.new("Matcha Auto-Parry v1.0")

-- Initialize UI settings
ui:set("Auto Parry", Config.AutoParryEnabled)
ui:set("Parry Delay (ms)", Config.ParryDelay)
ui:set("Hold Time (ms)", Config.ParryHoldTime)
ui:set("Detection Range", Config.DetectionRange)
ui:set("Debug Mode", Config.DebugMode)
ui:set("ESP", Config.ESPEnabled)

-- ========== COMMAND SYSTEM ==========
local Commands = {}

function Commands.help()
    print("Available commands:")
    print("  help - Show this help")
    print("  parry [on/off] - Toggle auto-parry")
    print("  delay [ms] - Set parry delay")
    print("  hold [ms] - Set hold time")
    print("  range [studs] - Set detection range")
    print("  debug [on/off] - Toggle debug mode")
    print("  esp [on/off] - Toggle ESP")
    print("  teleport base - Teleport to base")
    print("  teleport [player] - Teleport to player")
    print("  status - Show current settings")
end

function Commands.parry(state)
    if state == "on" then
        Config.AutoParryEnabled = true
        AutoParry:start()
    elseif state == "off" then
        Config.AutoParryEnabled = false
        AutoParry:stop()
    else
        Config.AutoParryEnabled = not Config.AutoParryEnabled
        if Config.AutoParryEnabled then
            AutoParry:start()
        else
            AutoParry:stop()
        end
    end
    
    ui:set("Auto Parry", Config.AutoParryEnabled)
    print("[Config] Auto-parry: " .. (Config.AutoParryEnabled and "ON" or "OFF"))
end

function Commands.delay(ms)
    if ms and tonumber(ms) then
        Config.ParryDelay = tonumber(ms)
        ui:set("Parry Delay (ms)", Config.ParryDelay)
        print("[Config] Parry delay set to: " .. Config.ParryDelay .. "ms")
    else
        print("[Config] Current parry delay: " .. Config.ParryDelay .. "ms")
    end
end

function Commands.hold(ms)
    if ms and tonumber(ms) then
        Config.ParryHoldTime = tonumber(ms)
        ui:set("Hold Time (ms)", Config.ParryHoldTime)
        print("[Config] Hold time set to: " .. Config.ParryHoldTime .. "ms")
    else
        print("[Config] Current hold time: " .. Config.ParryHoldTime .. "ms")
    end
end

function Commands.range(studs)
    if studs and tonumber(studs) then
        Config.DetectionRange = tonumber(studs)
        ui:set("Detection Range", Config.DetectionRange)
        print("[Config] Detection range set to: " .. Config.DetectionRange .. " studs")
    else
        print("[Config] Current detection range: " .. Config.DetectionRange .. " studs")
    end
end

function Commands.debug(state)
    if state == "on" then
        Config.DebugMode = true
    elseif state == "off" then
        Config.DebugMode = false
    else
        Config.DebugMode = not Config.DebugMode
    end
    
    ui:set("Debug Mode", Config.DebugMode)
    print("[Config] Debug mode: " .. (Config.DebugMode and "ON" or "OFF"))
end

function Commands.esp(state)
    if state == "on" then
        Config.ESPEnabled = true
        ESP:toggle()
    elseif state == "off" then
        Config.ESPEnabled = false
        ESP.enabled = false
    else
        Config.ESPEnabled = not Config.ESPEnabled
        ESP:toggle()
    end
    
    ui:set("ESP", Config.ESPEnabled)
end

function Commands.teleport(target)
    if not Config.TeleportEnabled then
        print("[Teleport] Teleport is disabled")
        return
    end
    
    if target == "base" then
        Teleports.toBase()
    elseif target then
        Teleports.toPlayer(target)
    else
        print("[Teleport] Usage: teleport [base/player_name]")
    end
end

function Commands.status()
    print("========== Current Settings ==========")
    ui:show()
end

-- ========== INITIALIZATION ==========
local function initialize()
    print("========================================")
    print("  Matcha Auto-Parry Script v1.0")
    print("  Compatible with External Lua VM")
    print("========================================")
    print("")
    print("Type 'help' for available commands")
    print("Basic usage:")
    print("  parry on/off - Toggle auto-parry")
    print("  status - Show current settings")
    print("")
    
    -- Show initial UI
    ui:show()
    
    -- Enable teleports if supported
    Config.TeleportEnabled = true
    
    print("Script loaded successfully!")
    print("Auto-parry is currently: " .. (Config.AutoParryEnabled and "ON" or "OFF"))
end

-- ========== MAIN EXECUTION ==========
-- Start the script
initialize()

-- Example of how to use the command system
-- You can call these functions manually or set up input handling

--[[
Usage examples:
Commands.help()
Commands.parry("on")
Commands.delay(150)
Commands.debug("on")
Commands.status()
]]

-- ========== END: MATCHA COMPATIBLE AUTO PARRY SCRIPT ==========