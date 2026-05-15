# 📋 CHANGELOG - Version 3.0.0

## 🚀 Major Features

### Database Integration
- ✅ Complete SQL database system for storing zones and patrols
- ✅ Automatic migration of pre-configured zones to database
- ✅ Zone access logging system
- ✅ Preset save/load system
- ✅ Toggle between database mode and config-only mode

### In-Game Builders
- ✅ **Zone Builder** (`/createzone`) - Create guard zones visually in-game
  - Set zone center with marker
  - Adjust radius with mouse scroll
  - Live preview with radius circle
  - Configure all zone properties via menu
  
- ✅ **Route Builder** (`/createroute`) - Create patrol routes by driving
  - Add waypoints at your position
  - Visual waypoint markers
  - Line connections between waypoints
  - Undo last waypoint function
  - Configure vehicle, ped, weapons, and speed

### Enhanced UI
- ✅ "Create Zone" button in Guard Zones tab
- ✅ "Create Route" button in Patrols tab  
- ✅ Delete buttons for custom zones and routes
- ✅ Custom vs Preset badges on cards
- ✅ Improved panel header layout
- ✅ Empty state with quick create buttons
- ✅ Better visual feedback

### Zone Management
- ✅ Delete custom zones from control panel
- ✅ Delete custom patrol routes from control panel
- ✅ Differentiate between custom and preset content
- ✅ Prevent deletion of preset zones/routes
- ✅ Real-time zone data synchronization

### Configuration Options
- ✅ Optional blips system (disabled by default)
- ✅ Configurable permissions for each action
- ✅ Zone builder customization settings
- ✅ Route builder customization settings
- ✅ Auto-spawn settings (disabled by default for manual control)

### Performance & Quality
- ✅ Data caching system for reduced database queries
- ✅ Automatic zone/patrol reload on changes
- ✅ Network optimization for multi-player
- ✅ Better error handling and logging

---

## 🔧 Technical Changes

### New Files
- `npc_system.sql` - Database schema and initial data
- `server_sql.lua` - Server-side SQL operations handler
- `client_builders.lua` - In-game zone and route builders
- `INSTALLATION_GUIDE.md` - Comprehensive setup guide
- `CHANGELOG.md` - This file

### Modified Files
- `config.lua` - Added database, UI, and builder settings
- `fxmanifest.lua` - Updated to include new files
- `client.lua` - Added NUI callbacks for builders
- `html/index.html` - Enhanced UI with create/delete features
- `html/script.js` - Added zone/route management functions
- `html/style.css` - New styles for badges and buttons

### Database Tables
1. `npc_guard_zones` - Stores zone configurations
2. `npc_patrol_routes` - Stores patrol route configurations
3. `npc_guard_spawns` - Tracks active guard spawns
4. `npc_patrol_spawns` - Tracks active patrol spawns
5. `npc_presets` - Stores saved zone/patrol presets
6. `npc_zone_access_log` - Logs player zone access events

---

## 📝 Breaking Changes

### Auto-Spawn Disabled by Default
**Before:**
```lua
Config.AutoSpawnZones = { "Cayo Perico" }
Config.AutoSpawnPatrols = { "Cayo Perico Perimeter" }
```

**After:**
```lua
Config.AutoSpawnZones = {} -- Disabled for manual control
Config.AutoSpawnPatrols = {} -- Disabled for manual control
```

**Why:** Gives admins full control over when guards/patrols are active. Use the control panel to manually spawn them.

---

## 🎯 New Commands

### Player Commands
None added (all features admin-only)

### Admin Commands
```bash
/createzone     # Start in-game zone builder
/createroute    # Start in-game route builder
```

### Existing Commands (Updated)
All previous commands remain functional:
- `/npcpanel` - Opens enhanced control panel
- `/spawnguards [zone]` 
- `/clearguards [zone/all]`
- `/spawnpatrol [route]`
- `/clearpatrols`
- `/givebodyguard [id] [tier]`
- `/clearbodyguards [id]`
- `/listzones`
- `/listpatrols`
- `/toggleguardzones`
- `/chaseme [level] [count]`
- `/chaseoff`

---

## 🎨 UI Improvements

### Visual Enhancements
- Custom zones show blue "Custom" badge
- Preset zones show gray "Preset" badge
- Delete button (X) only appears on custom content
- Create buttons in panel headers
- Improved empty state messages
- Better responsive layout for header actions

### New Interactive Elements
- Create Zone button → Launches zone builder
- Create Route button → Launches route builder
- Delete Zone button → Removes custom zone (with confirmation)
- Delete Route button → Removes custom route (with confirmation)

---

## 🔒 Permission System

### New Permission Levels
```lua
Config.AdminPermissions = {
    controlPanel = 'god',      -- Open control panel
    createZones = 'admin',     -- Create/edit zones
    deleteZones = 'god',       -- Delete zones
    manageGuards = 'admin',    -- Spawn/clear guards
    managePatrols = 'admin',   -- Manage patrols
    manageBodyguards = 'admin' -- Bodyguard commands
}
```

Higher-level actions (delete) require higher permissions by default.

---

## 🐛 Bug Fixes

- Fixed waypoint count display in patrol cards
- Improved zone data synchronization across clients
- Better handling of missing database connection
- Proper cleanup on resource restart
- Fixed marker rendering in builders

---

## 📊 Performance Optimizations

- Zone/patrol data cached on server startup
- Reduced redundant database queries
- Optimized NUI data transfer
- Better entity cleanup on delete
- Improved network synchronization

---

## 🛠️ Developer Features

### New Exports
```lua
exports['prelude-npc']:GetCachedZones()
exports['prelude-npc']:GetCachedPatrols()
exports['prelude-npc']:ReloadFromDatabase()
```

### Server Events
```lua
-- Create zone
TriggerServerEvent('prelude-npc:server:createGuardZone', zoneData)

-- Delete zone
TriggerServerEvent('prelude-npc:server:deleteGuardZone', zoneName)

-- Create patrol route
TriggerServerEvent('prelude-npc:server:createPatrolRoute', routeData)

-- Delete patrol route
TriggerServerEvent('prelude-npc:server:deletePatrolRoute', routeName)

-- Get zones
TriggerServerEvent('prelude-npc:server:getGuardZones')

-- Get patrols
TriggerServerEvent('prelude-npc:server:getPatrolRoutes')

-- Log zone access
TriggerServerEvent('prelude-npc:server:logZoneAccess', zoneName, action)
```

### Client Events
```lua
-- Reload zones from database
TriggerClientEvent('prelude-npc:client:reloadZones', -1)

-- Reload patrols from database
TriggerClientEvent('prelude-npc:client:reloadPatrols', -1)

-- Receive zone data
RegisterNetEvent('prelude-npc:client:receiveGuardZones')

-- Receive patrol data
RegisterNetEvent('prelude-npc:client:receivePatrolRoutes')
```

---

## 📖 Documentation Updates

- New comprehensive installation guide
- Updated README with all features
- Command reference updated
- Control panel guide updated
- Added troubleshooting section

---

## 🔮 Future Roadmap

### Planned for v3.1
- Zone templates library
- JSON import/export
- Blip customization per zone
- Guard AI improvements

### Planned for v3.2
- Faction system
- Guard formations
- Dynamic spawning
- Event triggers

### Planned for v4.0
- Web admin panel
- Advanced AI behaviors
- Convoy system
- Performance dashboard

---

## 💬 Notes

### Migration from Previous Versions
1. Import `npc_system.sql` to your database
2. Pre-configured zones will be migrated automatically
3. No changes needed to existing configs
4. All old commands still work

### Compatibility
- ✅ QBCore (tested)
- ✅ ESX (supported, not tested)
- ✅ Standalone (partial support)

### Dependencies
- Required: oxmysql, qb-input
- Optional: None

---

## 🙏 Credits

**Original Script:** Charlie  
**Enhancements:** AI Integration  
**Version:** 3.0.0  
**Release Date:** February 16, 2026  

---

## 📞 Support

If you encounter issues:
1. Check INSTALLATION_GUIDE.md
2. Review server console logs
3. Verify database connection
4. Check config.lua settings

---

**Enjoy the enhanced NPC system!** 🎮
