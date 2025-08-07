--[[
    Main Loader Script for Matcha External Lua VM Auto Parry
    
    This script loads and initializes the auto parry system with the modern GUI.
    Compatible with Matcha External Lua VM API limitations.
    
    Files needed:
    - matcha_ui_library.lua (UI library)
    - matcha_auto_parry.lua (Auto parry script)
    - main.lua (this file)
    
    Usage:
    Simply run this script in your Matcha External Lua VM environment.
    The GUI will appear and you can configure your settings through it.
]]

-- Print startup message
printl("========================================")
printl("  Matcha VM Auto Parry Script v1.0")
printl("  Compatible with External Lua VM")
printl("========================================")

-- Check if we're running in a compatible environment
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
printl("[INFO] Loading Auto Parry system...")

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

-- Load the auto parry script (it will load the UI library internally)
local success, error = pcall(function()
    loadfile("matcha_auto_parry.lua")()
end)

if not success then
    printl("[ERROR] Failed to load auto parry script!")
    printl("[ERROR]", tostring(error))
    printl("[INFO] Make sure 'matcha_auto_parry.lua' is in the same directory")
    return
end

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
printl("=== HOTKEYS (if supported) ===")
printl("- F Key: Default parry key (configurable)")
printl("- GUI Navigation: Use UI elements to change settings")
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