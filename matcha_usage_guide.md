# Matcha Auto-Parry Script - Usage Guide

## Overview
This is a fixed version of the auto-parry script that's compatible with Matcha External Lua VM limitations. The script has been rewritten to only use functions and features that are supported by external Lua VMs.

## Key Fixes Made

### 1. Removed Unsupported Functions
**Original Issues:**
- `Drawing.new()` - Not supported in external VMs
- `WorldToScreen()` - Not available 
- `printl()` - Replaced with standard `print()`
- `spawn()` - Replaced with direct function calls
- Complex UI library with metamethods

**Fixed Versions:**
- Replaced Drawing API with print-based output
- Removed WorldToScreen dependencies 
- Used standard `print()` for all output
- Simplified UI to text-based interface
- Removed spawn() and used direct execution

### 2. Simplified Game Access
**Original Issues:**
- Complex game service access
- Unreliable player/character getting
- Advanced Roblox API usage

**Fixed Versions:**
- Multiple fallback methods for game access
- Protected calls (pcall) for error handling
- Simplified character and player detection
- Basic distance calculations without complex APIs

### 3. Compatible Animation Detection
**Original Issues:**
- Advanced animation track monitoring
- Complex animation databases
- Unreliable animation ID extraction

**Fixed Versions:**
- Protected animation track access
- Simplified animation ID matching
- Fallback systems for failed API calls
- Basic string pattern matching

### 4. Command-Based Interface
**Original Issues:**
- GUI-based controls requiring Drawing API
- Complex UI interactions
- Real-time UI updates

**Fixed Versions:**
- Text-based command system
- Print-based status displays
- Simple function calls for control
- No GUI dependencies

## How to Use

### 1. Basic Setup
```lua
-- Load the script (it will auto-initialize)
-- You'll see the startup message and available commands
```

### 2. Available Commands

#### Toggle Auto-Parry
```lua
Commands.parry("on")   -- Enable auto-parry
Commands.parry("off")  -- Disable auto-parry
Commands.parry()       -- Toggle current state
```

#### Configure Settings
```lua
Commands.delay(150)    -- Set parry delay to 150ms
Commands.hold(600)     -- Set hold time to 600ms
Commands.range(800)    -- Set detection range to 800 studs
```

#### Debug and Monitoring
```lua
Commands.debug("on")   -- Enable debug output
Commands.esp("on")     -- Enable basic ESP (text-based)
Commands.status()      -- Show current settings
```

#### Teleport Functions
```lua
Commands.teleport("base")        -- Teleport to base coordinates
Commands.teleport("playername")  -- Teleport to specific player
```

#### Help and Information
```lua
Commands.help()        -- Show all available commands
Commands.status()      -- Display current configuration
```

### 3. Configuration Options

All settings can be modified through commands:

| Setting | Default | Description |
|---------|---------|-------------|
| Parry Delay | 100ms | Delay before executing parry |
| Hold Time | 500ms | How long to hold parry key |
| Detection Range | 1000 studs | Maximum distance for detection |
| Parry Key | 70 (F key) | Key code for parry action |
| Debug Mode | Off | Enable detailed logging |

### 4. Supported Functions

The script only uses functions that should be available in Matcha VM:

#### Core Functions
- `print()` - For output
- `wait()` - For delays
- `tick()` or `os.clock()` - For timing
- `pcall()` - For error handling

#### Input Functions
- `keypress(keycode)` - Press key
- `keyrelease(keycode)` - Release key

#### Game Access (if available)
- `game.Players.LocalPlayer`
- `game:GetService("Players")`
- Basic character and humanoid access
- Position and CFrame manipulation

## Features

### ✅ Working Features
- **Auto-Parry Detection** - Monitors nearby players for combat animations
- **Configurable Timing** - Adjustable delay and hold times
- **Range Detection** - Distance-based monitoring
- **Command System** - Easy-to-use text commands
- **Basic ESP** - Text-based player listing with distances
- **Teleport Functions** - Basic teleportation if supported
- **Debug Logging** - Detailed output for troubleshooting

### ❌ Removed Features (Not VM Compatible)
- Visual GUI interface
- Drawing API-based ESP boxes
- Advanced visual feedback
- Complex UI interactions
- Real-time visual indicators

## Troubleshooting

### Common Issues

1. **Animation Detection Not Working**
   ```lua
   Commands.debug("on")  -- Enable debug to see detection attempts
   ```

2. **Parry Not Executing**
   - Check if keypress/keyrelease functions are available
   - Verify the parry key code (default: 70 for F key)
   - Ensure auto-parry is enabled

3. **No Player Detection**
   ```lua
   Commands.esp("on")    -- Check if players are being detected
   Commands.range(2000)  -- Increase detection range
   ```

4. **Script Not Loading**
   - Ensure all required functions are available in your VM
   - Check for error messages in output
   - Try running individual commands manually

### Debug Mode
Enable debug mode to see detailed information:
```lua
Commands.debug("on")
```

This will show:
- Animation detection attempts
- Player monitoring status
- Parry execution details
- Error messages and warnings

## Compatibility Notes

### Required Functions
Your Matcha VM must support:
- Basic Lua functions (print, wait, pcall, etc.)
- keypress/keyrelease for input simulation
- Basic game object access (game.Players, etc.)
- tick() or os.clock() for timing

### Optional Functions
If available, these enhance functionality:
- game:GetService() for reliable service access
- Advanced character/humanoid methods
- Position and CFrame manipulation for teleports

### Not Required
These are NOT needed (script will work without them):
- Drawing API
- WorldToScreen
- Complex UI libraries
- spawn() function
- Advanced metamethods

## Example Usage Session

```lua
-- 1. Load the script (automatic initialization)

-- 2. Check current status
Commands.status()

-- 3. Enable debug mode to see what's happening
Commands.debug("on")

-- 4. Configure settings
Commands.delay(120)    -- Faster parry delay
Commands.range(1500)   -- Longer detection range

-- 5. Enable auto-parry
Commands.parry("on")

-- 6. Enable ESP to monitor players
Commands.esp("on")

-- 7. Check status again
Commands.status()

-- 8. If needed, disable later
Commands.parry("off")
```

## Advanced Configuration

### Custom Animation Database
You can add more animation IDs to the CombatAnimations table:
```lua
CombatAnimations["your_animation_id"] = true
```

### Custom Keybind
Change the parry key by modifying:
```lua
Config.ParryKey = your_key_code  -- Replace with desired key code
```

### Custom Base Coordinates
Modify the teleport base location:
```lua
-- In Teleports.toBase() function
local basePos = Vector3.new(x, y, z)  -- Your coordinates
```

This script should now work within the constraints of Matcha External Lua VM while maintaining the core auto-parry functionality.