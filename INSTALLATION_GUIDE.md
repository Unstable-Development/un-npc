# 🎉 PRELUDE NPC SYSTEM - ENHANCED VERSION

## 🆕 What's New in This Update

### Major Features Added:
✅ **SQL Database Support** - Store custom zones and patrols in the database  
✅ **In-Game Zone Builder** - Create guard zones visually with markers  
✅ **In-Game Route Builder** - Build patrol routes by driving and placing waypoints  
✅ **Zone Management** - Delete custom zones directly from the control panel  
✅ **Route Management** - Delete custom patrol routes  
✅ **Optional Blips** - Toggle zone blips on/off in config  
✅ **Preset System** - Save and load zone/patrol configurations  
✅ **Access Logging** - Track player zone access in database  
✅ **Enhanced UI** - Better control panel with create/delete buttons

---

## 📦 Installation

### 1. Database Setup

Run the SQL file in your database:
```sql
-- Import the file: npc_system.sql
```

This creates the following tables:
- `npc_guard_zones` - Stores guard zones
- `npc_patrol_routes` - Stores patrol routes  
- `npc_guard_spawns` - Tracks active guards
- `npc_patrol_spawns` - Tracks active patrols
- `npc_presets` - Saves zone/patrol presets
- `npc_zone_access_log` - Logs player zone access

Pre-configured zones and patrols are automatically inserted.

### 2. Resource Setup

Make sure you have these dependencies:
- `qb-core` (or ESX)
- `oxmysql`
- `qb-input`

### 3. Configuration

Edit `config.lua`:

```lua
-- Enable database mode (set to false for config-only mode)
Config.UseDatabase = true

-- Optional blips (set to true if you want zone markers on map)
Config.EnableBlips = false

-- Enable in-game builders
Config.EnableZoneCreator = true
Config.EnableRouteBuilder = true
```

### 4. Start Resource

```
ensure prelude-npc
```

---

## 🎮 How to Use

### Control Panel
```
/npcpanel
```
Opens the visual control panel with all features.

### In-Game Zone Creator
```
/createzone
```

**Instructions:**
1. Press command to start zone builder
2. Position yourself where you want the zone center
3. Press **E** to set the zone center
4. Use **Mouse Scroll** to adjust radius
5. Press **ENTER** when satisfied
6. Fill in zone details (name, guard count, stats, etc.)
7. Zone is saved to database

**Controls:**
- `E` - Set zone center
- `Scroll Up/Down` - Increase/decrease radius
- `ENTER` - Confirm and save
- `X` - Cancel

### In-Game Route Builder
```
/createroute
```

**Instructions:**
1. Press command to start route builder
2. Drive or walk to each waypoint location
3. Press **E** at each waypoint to add it
4. Add at least 2 waypoints (up to 50)
5. Press **Z** to undo last waypoint if needed
6. Press **ENTER** when done
7. Fill in route details (name, vehicle, speed, etc.)
8. Route is saved to database

**Controls:**
- `E` - Add waypoint at current position
- `Z` - Remove last waypoint
- `ENTER` - Confirm and save
- `X` - Cancel

---

## 🛡️ Guard Zones

### Pre-Configured Zones:
1. **Cayo Perico** - 15 guards, requires "creampie" item
2. **Fort Zancudo** - 20 military guards, requires "military_id"
3. **Grove Street Territory** - 8 gang guards, requires "gang_bandana"

### Custom Zones:
Create your own zones using `/createzone`:
- Set any location
- Configure guard count (1-100)
- Set required items for access
- Customize guard stats (health, armor, accuracy)
- Choose guard models and weapons

### Managing Zones:
From the control panel:
- **Spawn Guards** - Activate guards in a zone
- **Clear Guards** - Remove all guards from a zone
- **Delete Zone** - Remove custom zones (pre-configured zones cannot be deleted)

Custom zones show a blue "Custom" badge, pre-configured zones show a gray "Preset" badge.

---

## 🚗 Patrol Routes

### Pre-Configured Routes:
1. **Cayo Perico Perimeter** - Mesa patrol vehicle
2. **Fort Zancudo Patrol** - Military barracks patrol

### Custom Routes:
Create your own routes using `/createroute`:
- Drive the route you want patrols to follow
- Add waypoints at turns and important positions
- Configure vehicle model, ped, weapons, and speed
- Link to a guard zone (optional)

### Managing Routes:
From the control panel:
- **Start Patrol** - Spawn a patrol on the route
- **Clear All Patrols** - Remove all active patrols
- **Delete Route** - Remove custom routes

---

## 👔 Bodyguard System

Three tiers available:

**Tier 1 - Basic Security** ($5,000)
- Health: 150 | Armor: 50
- Weapons: Pistol/Combat Pistol
- Accuracy: 30%
- Duration: 30 minutes

**Tier 2 - Professional Guard** ($15,000)
- Health: 250 | Armor: 100
- Weapons: Carbine Rifle/Pump Shotgun
- Accuracy: 50%
- Duration: 30 minutes

**Tier 3 - Elite Mercenary** ($35,000)
- Health: 400 | Armor: 200
- Weapons: Assault Rifle/Carbine/Special Carbine
- Accuracy: 75%
- Duration: 30 minutes

Maximum 3 bodyguards per player.

---

## 🎯 Hunter System

Spawn aggressive NPCs that chase players:

**Levels:**
1. Asea (40 km/h)
2. Seminole (55 km/h)
3. Banshee (110 km/h)
4. Turismo R (90 km/h)
5. Osiris (110 km/h)

**Types:**
- Vehicle Hunters - Chase in cars
- Pedestrian Hunters - Chase on foot

**Commands:**
```
/chaseme [level] [count]  - Spawn hunters
/chaseoff                 - Remove hunters
```

---

## ⚙️ Admin Commands

```
/npcpanel                   - Open control panel (RECOMMENDED)
/createzone                 - Start zone builder
/createroute                - Start route builder

/spawnguards [zone]         - Spawn guards in zone
/clearguards [zone/all]     - Clear guards
/spawnpatrol [route]        - Spawn patrol
/clearpatrols               - Clear all patrols

/givebodyguard [id] [tier]  - Give bodyguard to player
/clearbodyguards [id]       - Remove player bodyguards

/listzones                  - List all zones
/listpatrols                - List all routes
/toggleguardzones           - Toggle zones on/off
```

---

## 🔧 Advanced Configuration

### Permissions
Edit in `config.lua`:
```lua
Config.AdminPermissions = {
    controlPanel = 'god',      -- Permission for /npcpanel
    createZones = 'admin',     -- Permission to create zones
    deleteZones = 'god',       -- Permission to delete zones
    manageGuards = 'admin',    -- Permission to spawn/clear guards
    managePatrols = 'admin',   -- Permission for patrols
    manageBodyguards = 'admin' -- Permission for bodyguard commands
}
```

### Zone Builder Settings
```lua
Config.ZoneBuilder = {
    markerType = 1,                             -- Marker type for zone center
    markerColor = {r = 255, g = 0, b = 0, a = 100},
    maxRadius = 500.0,                          -- Maximum zone radius
    minRadius = 10.0,                           -- Minimum zone radius
    defaultRadius = 50.0,                       -- Starting radius
    previewUpdateRate = 100,                    -- Preview refresh rate (ms)
}
```

### Route Builder Settings
```lua
Config.RouteBuilder = {
    waypointMarker = 1,                         -- Waypoint marker type
    waypointColor = {r = 0, g = 255, b = 255, a = 200},
    maxWaypoints = 50,                          -- Maximum waypoints per route
    minWaypoints = 2,                           -- Minimum waypoints required
    snapToGround = true,                        -- Snap waypoints to ground
    showConnections = true,                     -- Draw lines between waypoints
}
```

### Optional Blips
```lua
Config.EnableBlips = false                      -- Show zone blips on map
Config.BlipSprite = 161                         -- Blip sprite ID
Config.BlipColor = 1                            -- Blip color (red)
Config.BlipScale = 0.8                          -- Blip size
```

---

## 📊 Database Mode vs Config Mode

### Database Mode (Recommended)
```lua
Config.UseDatabase = true
```
- Zones and patrols stored in database
- Create/delete zones in-game
- Persistent across server restarts
- Multiple admins can manage zones
- Access logging enabled

### Config Mode
```lua
Config.UseDatabase = false
```
- Zones and patrols from config.lua only
- No in-game creation/deletion
- Manual config editing required
- Lighter on database queries

---

## 🎨 UI Features

### Control Panel Tabs:

**1. Guard Zones**
- View all zones (custom + preset)
- Spawn/clear guards
- Delete custom zones
- Create new zones
- Global toggle switch

**2. Patrols**
- View all routes (custom + preset)
- Start/stop patrols
- Delete custom routes
- Create new routes

**3. Bodyguards**
- View tier information
- Give bodyguards to players
- Clear player bodyguards

**4. Hunters**
- Spawn vehicle/pedestrian hunters
- Adjust level and count with sliders
- Target specific players
- Clear all hunters

---

## 🔒 Security Features

### Access Control
- Required items for zone access
- Identifier-based access (license, discord, etc.)
- Access logging to database

### Permissions
- Different permission levels for different actions
- Separate create/delete permissions
- Configurable per-action permissions

---

## 💡 Tips & Best Practices

1. **Start with small zones** - Test with 5-10 guards before creating massive zones
2. **Use required items** - Give players items to bypass guards for RP scenarios
3. **Link patrols to zones** - Patrols can be associated with guard zones
4. **Save presets** - Save your favorite configurations for quick deployment
5. **Monitor performance** - Many active guards/patrols can impact performance
6. **Regular backups** - Back up your database regularly

---

## 🐛 Troubleshooting

### Guards not spawning?
- Check if zone is toggled on in control panel
- Verify database mode is enabled if using custom zones
- Check server console for errors

### Zone builder not working?
- Verify `Config.EnableZoneCreator = true`
- Check you have admin permissions
- Ensure `qb-input` is running

### Route builder issues?
- Verify `Config.EnableRouteBuilder = true`
- Make sure you add at least 2 waypoints
- Check for conflicts with other scripts

### Database errors?
- Verify `oxmysql` is running
- Check SQL file was imported correctly
- Ensure connection string is correct

---

## 📝 Export Functions

For developers integrating with other resources:

```lua
-- Get all cached zones from database
local zones = exports['prelude-npc']:GetCachedZones()

-- Get all cached patrol routes
local patrols = exports['prelude-npc']:GetCachedPatrols()

-- Reload data from database
exports['prelude-npc']:ReloadFromDatabase()

-- Check if player has active bodyguards
local hasBodyguards = exports['prelude-npc']:HasActiveBodyguards(source)

-- Get bodyguard count for player
local count = exports['prelude-npc']:GetBodyguardCount(source)
```

---

## 🎯 Future Enhancements (Planned)

- [ ] Zone/route templates library
- [ ] Import/export configurations as JSON
- [ ] Enhanced AI behaviors (cover, formations)
- [ ] Faction system with relationships
- [ ] Dynamic spawning based on player count
- [ ] Event-triggered spawning
- [ ] Convoy support for patrols
- [ ] NPC customization (outfits, vehicles)
- [ ] Performance monitoring dashboard
- [ ] Web-based admin panel

---

## 📄 License & Credits

Created by Charlie  
Enhanced AI Integration  
Version 3.0.0  

**Requirements:**
- QBCore or ESX
- oxmysql
- qb-input

---

## 🤝 Support

For issues or questions:
1. Check the troubleshooting section
2. Review your server console logs
3. Verify all dependencies are running
4. Check config settings

---

Enjoy your enhanced NPC system! 🎮
