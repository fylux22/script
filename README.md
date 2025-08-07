# Matcha VM Auto Parry Script

A modern auto parry script designed specifically for the Matcha External Lua VM with a sleek GUI interface.

## Features

✅ **Auto Parry System**
- Detects combat animations from other players
- Automatically executes parries with configurable timing
- Supports multiple weapon types and monster attacks
- Customizable delay, hold time, and cooldown settings

✅ **ESP (Extra Sensory Perception)**
- Visual player indicators with distance display
- Configurable range settings
- Clean overlay design using Drawing API

✅ **Teleport Functions**
- Teleport to base functionality
- Easy-to-use GUI buttons

✅ **Modern GUI Interface**
- Dark theme with purple accents
- Clean checkbox toggles and sliders
- Organized tab system
- Real-time value updates

✅ **Matcha VM Compatible**
- Uses only documented Matcha External Lua VM functions
- Optimized for external lua environment limitations
- No dependency on unsupported libraries

## Installation

1. **Download Files**
   - `matcha_ui_library.lua` - The modern UI library
   - `matcha_auto_parry.lua` - The main auto parry script
   - `main.lua` - The loader script

2. **Place Files**
   - Place all three files in the same directory
   - Ensure your Matcha VM can access these files

3. **Run Script**
   ```lua
   -- Execute the main loader
   loadfile("main.lua")()
   ```

## Usage

### Initial Setup
1. Run the `main.lua` script in your Matcha External Lua VM
2. The GUI will appear on your screen with two tabs: "ESP" and "Auto-Parry"
3. Navigate through the interface to configure your settings

### ESP Configuration
- **Ally ESP**: Toggle to enable/disable ESP visualization
- **ESP Range**: Set the maximum distance for ESP detection (50-5000 studs)
- **Teleport to Base**: Quick teleport button

### Auto-Parry Configuration
- **Auto Parry**: Enable/disable the auto parry system
- **Parry Delay**: Time delay before executing parry (10-500ms)
- **Hold Time**: How long to hold the parry key (100-2000ms)
- **Detection Range**: Range for detecting combat animations (25-200 studs)
- **Parry Cooldown**: Minimum time between parries (100-2000ms)
- **Debug Mode**: Enable detailed logging for troubleshooting

### Controls
- **F Key**: Default parry key (configurable in script)
- **GUI Navigation**: Use the interface to adjust all settings
- All settings are applied in real-time

## Supported Animations

The script detects the following combat animations:

### Weapons
- **Rapier**: All M1 attack variations
- **Daemon/Daemon2**: Complete attack sets
- **Khopesh**: Full combat sequence
- **Odachi**: Attack animations
- **Mace**: All attack variations
- **Scythe/Heavy Scythe**: Complete movesets

### Monsters
- **Prowler**: Attack patterns and execute moves
- **Frostbat**: Dash attack sequences

## Configuration

### Parry Key Customization
Edit the `Config.ParryKey` value in `matcha_auto_parry.lua`:
```lua
local Config = {
    -- Other settings...
    ParryKey = 70 -- F key (change to desired key code)
}
```

### Animation Database
Add new animations to the `CombatAnimations` table:
```lua
local CombatAnimations = {
    ["ANIMATION_ID"] = "Animation Name",
    -- Add more animations as needed
}
```

### Visual Customization
Modify colors in `matcha_ui_library.lua`:
```lua
local Colors = {
    Background = Color3.new(25/255, 25/255, 35/255),
    Accent = Color3.new(200/255, 100/255, 255/255),
    -- Customize other colors...
}
```

## Troubleshooting

### Common Issues

**GUI Not Appearing**
- Ensure Drawing library is available
- Check that all files are in the same directory
- Verify Matcha VM compatibility

**Auto Parry Not Working**
- Enable "Auto Parry" toggle in GUI
- Check "Debug Mode" for detection logs
- Verify target is within detection range
- Ensure animations are in the database

**Performance Issues**
- Reduce detection range
- Increase parry cooldown
- Disable ESP if not needed

### Debug Mode
Enable debug mode to see detailed logs:
```
[Auto-Parry Debug] Detected: Rapier M1 #1 from PlayerName (45 studs)
[Auto-Parry Debug] Executing parry against Rapier M1 #1 from PlayerName
[Auto-Parry Debug] Parry hold duration complete
```

## API Reference

### Matcha VM Functions Used
- `Drawing.new()` - Create visual elements
- `printl()` - Console output
- `wait()` - Script delays
- `keypress()` / `keyrelease()` - Input simulation
- `WorldToScreen()` - 3D to 2D coordinate conversion
- `game` / `workspace` - Game hierarchy access

### Player Detection
- `game:GetPlayers()` - Get all players
- `player.Character` - Access player character
- `character:FindFirstChild()` - Find character components
- `humanoid:GetPlayingAnimationTracks()` - Get active animations

## Security & Performance

- **No External Dependencies**: Uses only Matcha VM documented functions
- **Efficient Monitoring**: 100 FPS animation detection with cleanup
- **Memory Management**: Automatic cleanup of old detections
- **Cooldown Protection**: Prevents spam and maintains performance

## Version History

**v1.0** - Initial Release
- Full auto parry system
- Modern GUI interface
- ESP functionality
- Matcha VM compatibility
- Comprehensive animation database

## Support

For issues, questions, or feature requests:
1. Check the troubleshooting section
2. Enable debug mode for detailed logs
3. Verify your Matcha VM version compatibility

## License

This script is provided as-is for educational purposes. Use responsibly and in accordance with your game's terms of service.

---

**Note**: This script is designed specifically for Matcha External Lua VM. It may not work with other lua executors due to API differences.