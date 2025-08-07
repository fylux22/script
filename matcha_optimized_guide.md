# Matcha VM Optimized Auto-Parry Script - Complete Guide

## Overview
This is the **fully optimized** version of the auto-parry script, specifically designed to take advantage of all the capabilities documented in the official Matcha VM documentation. Unlike the previous simplified version, this script now includes:

- ✅ **Full Drawing API support** for visual ESP and GUI
- ✅ **WorldToScreen** functionality for proper 2D positioning
- ✅ **Visual feedback and indicators**
- ✅ **Real-time GUI interface** using Drawing library
- ✅ **Advanced ESP system** with visual boxes and text
- ✅ **Proper game service access** using documented methods

## Key Improvements from Original Script

### ✅ **Restored Visual Features**
Based on Matcha VM docs, these features are actually supported:
- **Drawing API** - `Drawing.new("Text")`, `Drawing.new("Square")`, etc.
- **WorldToScreen** - For converting 3D positions to screen coordinates
- **printl()** - Official logging function
- **isrbxactive()** - Check if Roblox window is active

### ✅ **Enhanced Game Access**
- Proper use of `game:GetService("Players")`
- Access to `workspace.CurrentCamera`
- Full Instance methods like `FindFirstChild()`, `GetChildren()`, etc.
- Animation track monitoring with `GetPlayingAnimationTracks()`

### ✅ **Visual Interface**
- Real-time GUI showing current status
- Visual ESP boxes around players
- On-screen parry feedback notifications
- Dynamic status updates

## Installation & Usage

### 1. Load the Script
Simply run the optimized script in your Matcha VM. It will automatically:
- Initialize all systems
- Create the visual GUI
- Start monitoring loops
- Display startup messages

### 2. Available Commands

All commands are accessed through the `Commands` table:

#### **Core Controls**
```lua
Commands.help()          -- Show all available commands
Commands.parry()         -- Toggle auto-parry on/off
Commands.status()        -- Display current settings
Commands.gui()           -- Toggle GUI visibility
```

#### **Configuration**
```lua
Commands.delay(120)      -- Set parry delay to 120ms
Commands.hold(600)       -- Set hold time to 600ms  
Commands.range(1500)     -- Set detection range to 1500 studs
```

#### **Visual Features**
```lua
Commands.esp()           -- Toggle ESP (visual boxes around players)
Commands.debug()         -- Toggle debug logging
```

#### **Teleportation**
```lua
Commands.tp("base")      -- Teleport to base coordinates
Commands.tp("username")  -- Teleport to specific player
```

### 3. GUI Interface

The script creates a visual GUI window showing:
- **Auto-Parry Status** - ON/OFF
- **ESP Status** - Enabled/Disabled  
- **Debug Mode** - Active/Inactive
- **Monitoring Status** - Active/Inactive
- **Current Settings** - Delay, hold time, range
- **Real-time Updates** - Values update automatically

Toggle GUI visibility: `Commands.gui()`

## Features Breakdown

### 🎯 **Auto-Parry System**
- **Animation Detection** - Monitors all nearby players for combat animations
- **Smart Timing** - Configurable delay and hold times
- **Cooldown Protection** - Prevents spam parrying
- **Visual Feedback** - Shows "PARRY!" notification on screen when triggered
- **Range-Based** - Only detects players within specified range

### 👁️ **ESP System**
- **Visual Boxes** - Red squares around enemy players
- **Player Names** - Shows username above each player
- **Distance Display** - Shows distance in meters
- **Dynamic Updates** - ESP follows players as they move
- **WorldToScreen** - Properly converts 3D positions to screen coordinates

### 🖥️ **GUI Interface**
- **Real-time Status** - Live updates of all settings
- **Professional Look** - Clean black background with colored text
- **Always Visible** - Stays on screen for easy monitoring
- **Toggle Support** - Can be hidden/shown as needed

### 🚀 **Teleport Functions**
- **Base Teleport** - Quick return to safe coordinates
- **Player Teleport** - Teleport to any player by name
- **Fuzzy Matching** - Partial name matching (e.g., "john" finds "john123")
- **Safety Checks** - Validates targets before teleporting

### 🐛 **Debug System**
- **Detailed Logging** - Shows detection attempts and execution details
- **Animation Monitoring** - Logs which animations are detected
- **Performance Info** - Tracks timing and cooldowns
- **Error Handling** - Graceful failure with informative messages

## Advanced Configuration

### Animation Database
Add custom animations to detect:
```lua
CombatAnimations["your_animation_id"] = "Custom Attack Name"
```

### Custom Keybind
Change the parry key:
```lua
Config.ParryKey = 71  -- G key instead of F
```

### Base Coordinates
Modify teleport destination:
```lua
-- In teleportToBase() function
local basePosition = Vector3(100, 50, 200)  -- Your custom coordinates
```

### GUI Positioning
Adjust GUI location:
```lua
-- In GUI:init() function
mainBg.Position = Vector2(100, 100)  -- Different position
```

## Technical Details

### Supported Matcha VM Functions Used
- ✅ `Drawing.new()` and all Drawing properties
- ✅ `WorldToScreen()` for coordinate conversion
- ✅ `printl()` for logging
- ✅ `wait()` for timing
- ✅ `keypress()` / `keyrelease()` for input
- ✅ `isrbxactive()` for window detection
- ✅ `game:GetService()` for proper service access
- ✅ All Instance methods and properties
- ✅ `tick()` for precise timing
- ✅ `Vector2()` and `Vector3()` constructors
- ✅ `Color3.new()` for colors

### Performance Optimizations
- **Coroutine-based** - Non-blocking execution
- **Protected Calls** - Error handling with pcall()
- **Efficient Loops** - 60 FPS main loop, 100 FPS monitoring
- **Memory Management** - Automatic cleanup of old data
- **Conditional Updates** - Only updates when necessary

## Example Usage Session

```lua
-- 1. Script loads automatically with GUI

-- 2. Check current status
Commands.status()

-- 3. Enable features
Commands.parry()         -- Enable auto-parry
Commands.esp()           -- Enable ESP
Commands.debug()         -- Enable debug logging

-- 4. Configure settings
Commands.delay(100)      -- Faster parry (100ms delay)
Commands.range(1200)     -- Longer detection range

-- 5. Monitor in real-time
-- GUI shows live updates of all settings
-- ESP shows boxes around nearby players
-- Debug shows detection attempts in console

-- 6. Use additional features
Commands.tp("base")      -- Quick escape if needed
Commands.gui()           -- Hide GUI temporarily

-- 7. Check if working
Commands.status()        -- Verify all settings
-- Watch for "PARRY!" notifications on screen
```

## Troubleshooting

### Visual Issues
- **GUI not showing**: Use `Commands.gui()` to toggle
- **ESP not visible**: Try `Commands.esp()` and ensure players are nearby
- **Colors wrong**: Check if Roblox is in light/dark mode

### Detection Issues
- **No parries triggering**: Enable debug with `Commands.debug()`
- **Too many false parries**: Increase delay with `Commands.delay(150)`
- **Missing detections**: Increase range with `Commands.range(1500)`

### Performance Issues
- **Script lagging**: Check if too many ESP objects are active
- **Input delay**: Verify Roblox window is active with `isrbxactive()`

## Comparison: Before vs After

| Feature | Original Script | Optimized Script |
|---------|----------------|------------------|
| Drawing API | ❌ Removed | ✅ Full support |
| ESP System | ❌ Text-only | ✅ Visual boxes + text |
| WorldToScreen | ❌ Not used | ✅ Proper 2D positioning |
| GUI Interface | ❌ Command-only | ✅ Real-time visual GUI |
| Visual Feedback | ❌ Console only | ✅ On-screen notifications |
| Game Access | ⚠️ Basic | ✅ Full service access |
| Error Handling | ⚠️ Limited | ✅ Comprehensive pcall usage |

## Final Notes

This optimized version takes full advantage of Matcha VM's documented capabilities, providing a professional-grade auto-parry script with visual interface and comprehensive features. The script is designed to be:

- **User-friendly** - Visual interface with real-time updates
- **Reliable** - Comprehensive error handling and fallbacks
- **Performant** - Optimized loops and memory management
- **Configurable** - All settings easily adjustable
- **Feature-rich** - ESP, teleports, debug tools, and more

The script maintains all the core auto-parry functionality while adding a modern, visual interface that makes it much easier to use and monitor.