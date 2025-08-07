-- ========== MATCHA VM COMPATIBLE AUTO PARRY SCRIPT ==========
--[[
    Auto-Parry Script for Matcha External Lua VM
    Fixed to use only documented Matcha VM functions
]]

-- ========== UI LIBRARY ==========
local UILib = {}

function UILib.new(title)
    local self = {
        Tabs = {},
        CurrentTab = nil,
        StatusText = Drawing.new("Text")
    }
    
    -- Setup status display
    self.StatusText.Text = title
    self.StatusText.Size = 16
    self.StatusText.Color = Color3.fromRGB(255, 255, 255)
    self.StatusText.Position = Vector2.new(10, 10)
    self.StatusText.Visible = true

    function self:Tab(name)
        local tab = { name = name, sections = {}, elements = {} }
        table.insert(self.Tabs, tab)
        self.CurrentTab = tab
        return tab
    end

    function self:Section(tab, title)
        local section = { title = title, elements = {} }
        table.insert(tab.sections, section)
        return section
    end

    function self:Toggle(tab, label, default, callback)
        local element = {
            type = "Toggle",
            label = label,
            value = default,
            callback = callback
        }
        table.insert(tab.elements, element)
        callback(default)
        return element
    end

    function self:Slider(tab, label, default, min, max, unit, callback)
        local element = {
            type = "Slider",
            label = label,
            value = default,
            min = min,
            max = max,
            unit = unit,
            callback = callback
        }
        table.insert(tab.elements, element)
        callback(default)
        return element
    end

    function self:Button(tab, label, callback)
        local element = {
            type = "Button",
            label = label,
            callback = callback
        }
        table.insert(tab.elements, element)
        return element
    end

    function self:CreateInput(tab, label, placeholder, callback)
        local element = {
            type = "Input",
            label = label,
            value = placeholder,
            callback = callback
        }
        table.insert(tab.elements, element)
        callback(placeholder)
        return element
    end

    function self:Step()
        -- Update status display
        if self.StatusText then
            self.StatusText.Text = "Auto-Parry: " .. (Config.AutoParryEnabled and "ON" or "OFF")
        end
    end

    return self
end

-- ========== CONFIGURATION ==========
local Config = {
    AutoParryEnabled = false,
    ParryDelay = 100,
    ParryHoldTime = 500,
    DetectionRange = 1000,
    ShowESP = false,
    TeleportEnabled = false,
    DebugMode = false,
    ParryKey = 70 -- F key
}

-- ========== ANIMATION DATABASE ==========
local CombatAnimations = {
    -- Rapier attacks
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
    
    -- Katana attacks
    ["16643599862"] = "Katana M1 #1",
    ["16643607813"] = "Katana M1 #2",
    ["16643611557"] = "Katana M1 #3",
    ["16643616187"] = "Katana M1 #4",
    
    -- Heavy attacks and abilities
    ["16643630630"] = "Heavy Attack",
    ["17291410659"] = "Special Ability",
    ["15656086351"] = "Dash Attack"
}

-- ========== CORE FUNCTIONS ==========
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

function GetLocalPlayer()
    return LocalPlayer
end

function GetLocalCharacter()
    local player = GetLocalPlayer()
    return player and player.Character
end

function GetLocalHumanoid()
    local character = GetLocalCharacter()
    return character and character:FindFirstChild("Humanoid")
end

function GetLocalRootPart()
    local character = GetLocalCharacter()
    return character and character:FindFirstChild("HumanoidRootPart")
end

function GetAllPlayers()
    return Players:GetPlayers()
end

function GetDistance(part1, part2)
    if not part1 or not part2 then return math.huge end
    local pos1 = part1.Position
    local pos2 = part2.Position
    return (pos1 - pos2).Magnitude
end

function IsPlayerInRange(player)
    local localRoot = GetLocalRootPart()
    local playerChar = player.Character
    local playerRoot = playerChar and playerChar:FindFirstChild("HumanoidRootPart")
    
    if not localRoot or not playerRoot then return false end
    
    local distance = GetDistance(localRoot, playerRoot)
    return distance <= Config.DetectionRange
end

function IsAttackAnimation(animationId)
    return CombatAnimations[tostring(animationId)] ~= nil
end

function CheckForAttacks()
    if not Config.AutoParryEnabled then return end
    
    local localPlayer = GetLocalPlayer()
    if not localPlayer then return end
    
    for _, player in pairs(GetAllPlayers()) do
        if player ~= localPlayer and player.Character then
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if humanoid and IsPlayerInRange(player) then
                local animator = humanoid:FindFirstChild("Animator")
                if animator then
                    for _, track in pairs(animator:GetPlayingAnimationTracks()) do
                        if track.Animation and IsAttackAnimation(track.Animation.AnimationId) then
                            if Config.DebugMode then
                                printl("Attack detected from " .. player.Name .. ": " .. (CombatAnimations[tostring(track.Animation.AnimationId)] or "Unknown"))
                            end
                            PerformParry()
                            return
                        end
                    end
                end
            end
        end
    end
end

function PerformParry()
    if not isrbxactive() then return end
    
    keypress(Config.ParryKey)
    wait(Config.ParryHoldTime / 1000)
    keyrelease(Config.ParryKey)
    
    if Config.DebugMode then
        printl("Parry executed!")
    end
end

-- ========== ESP FUNCTIONS ==========
local ESPObjects = {}

function CreateESP(player)
    if not Config.ShowESP then return end
    
    local esp = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Distance = Drawing.new("Text")
    }
    
    -- Box settings
    esp.Box.Visible = false
    esp.Box.Color = Color3.fromRGB(255, 0, 0)
    esp.Box.Thickness = 2
    esp.Box.Transparency = 0.8
    esp.Box.Filled = false
    
    -- Name settings
    esp.Name.Visible = false
    esp.Name.Color = Color3.fromRGB(255, 255, 255)
    esp.Name.Size = 16
    esp.Name.Center = true
    esp.Name.Outline = true
    esp.Name.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    -- Distance settings
    esp.Distance.Visible = false
    esp.Distance.Color = Color3.fromRGB(255, 255, 0)
    esp.Distance.Size = 14
    esp.Distance.Center = true
    esp.Distance.Outline = true
    esp.Distance.OutlineColor = Color3.fromRGB(0, 0, 0)
    
    ESPObjects[player] = esp
end

function UpdateESP()
    if not Config.ShowESP then 
        for _, esp in pairs(ESPObjects) do
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
        end
        return 
    end
    
    local localRoot = GetLocalRootPart()
    if not localRoot then return end
    
    for player, esp in pairs(ESPObjects) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local rootPart = player.Character.HumanoidRootPart
            local distance = GetDistance(localRoot, rootPart)
            
            if distance <= Config.DetectionRange then
                local screenPos, onScreen = WorldToScreen(rootPart.Position)
                
                if onScreen then
                    -- Update box
                    esp.Box.Size = Vector2.new(50, 60)
                    esp.Box.Position = Vector2.new(screenPos.X - 25, screenPos.Y - 30)
                    esp.Box.Visible = true
                    
                    -- Update name
                    esp.Name.Text = player.Name
                    esp.Name.Position = Vector2.new(screenPos.X, screenPos.Y - 40)
                    esp.Name.Visible = true
                    
                    -- Update distance
                    esp.Distance.Text = math.floor(distance) .. " studs"
                    esp.Distance.Position = Vector2.new(screenPos.X, screenPos.Y + 35)
                    esp.Distance.Visible = true
                else
                    esp.Box.Visible = false
                    esp.Name.Visible = false
                    esp.Distance.Visible = false
                end
            else
                esp.Box.Visible = false
                esp.Name.Visible = false
                esp.Distance.Visible = false
            end
        else
            esp.Box.Visible = false
            esp.Name.Visible = false
            esp.Distance.Visible = false
        end
    end
end

-- ========== TELEPORT FUNCTIONS ==========
function TeleportToPlayer(targetPlayer)
    if not Config.TeleportEnabled then return end
    
    local localChar = GetLocalCharacter()
    local localRoot = GetLocalRootPart()
    local targetChar = targetPlayer.Character
    local targetRoot = targetChar and targetChar:FindFirstChild("HumanoidRootPart")
    
    if localRoot and targetRoot then
        localRoot.CFrame = targetRoot.CFrame * CFrame.new(0, 0, 5)
        if Config.DebugMode then
            printl("Teleported to " .. targetPlayer.Name)
        end
    end
end

-- ========== UI SETUP ==========
local UI = UILib.new("🛡️ Auto-Parry Script")
local MainTab = UI:Tab("Main")

UI:Toggle(MainTab, "Auto Parry", Config.AutoParryEnabled, function(value)
    Config.AutoParryEnabled = value
    printl("Auto Parry " .. (value and "Enabled" or "Disabled"))
end)

UI:Slider(MainTab, "Parry Delay", Config.ParryDelay, 0, 500, "ms", function(value)
    Config.ParryDelay = value
end)

UI:Slider(MainTab, "Hold Time", Config.ParryHoldTime, 100, 1000, "ms", function(value)
    Config.ParryHoldTime = value
end)

UI:Slider(MainTab, "Detection Range", Config.DetectionRange, 500, 2000, "studs", function(value)
    Config.DetectionRange = value
end)

UI:Toggle(MainTab, "Show ESP", Config.ShowESP, function(value)
    Config.ShowESP = value
end)

UI:Toggle(MainTab, "Debug Mode", Config.DebugMode, function(value)
    Config.DebugMode = value
end)

UI:Button(MainTab, "Teleport to Nearest Player", function()
    local localRoot = GetLocalRootPart()
    if not localRoot then return end
    
    local nearestPlayer = nil
    local nearestDistance = math.huge
    
    for _, player in pairs(GetAllPlayers()) do
        if player ~= GetLocalPlayer() and player.Character then
            local distance = GetDistance(localRoot, player.Character:FindFirstChild("HumanoidRootPart"))
            if distance < nearestDistance then
                nearestDistance = distance
                nearestPlayer = player
            end
        end
    end
    
    if nearestPlayer then
        TeleportToPlayer(nearestPlayer)
    end
end)

-- ========== PLAYER MANAGEMENT ==========
function OnPlayerAdded(player)
    CreateESP(player)
end

function OnPlayerRemoving(player)
    if ESPObjects[player] then
        ESPObjects[player].Box:Remove()
        ESPObjects[player].Name:Remove()
        ESPObjects[player].Distance:Remove()
        ESPObjects[player] = nil
    end
end

-- Setup ESP for existing players
for _, player in pairs(GetAllPlayers()) do
    if player ~= GetLocalPlayer() then
        OnPlayerAdded(player)
    end
end

-- ========== MAIN LOOP ==========
printl("🛡️ Auto-Parry Script Loaded!")
printl("Press F1 to toggle Auto-Parry")

while true do
    if isrbxactive() then
        -- Check for F1 key to toggle
        if iskeypressed(112) then -- F1 key
            Config.AutoParryEnabled = not Config.AutoParryEnabled
            printl("Auto Parry " .. (Config.AutoParryEnabled and "Enabled" or "Disabled"))
            wait(0.2) -- Prevent spam
        end
        
        CheckForAttacks()
        UpdateESP()
        UI:Step()
    end
    
    wait(0.01) -- 100 FPS loop
end