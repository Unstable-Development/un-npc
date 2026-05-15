# Prelude NPC System

## Overview
Comprehensive NPC system featuring hunters, guard zones, patrol routes, and bodyguards with a sleek **tablet-style control panel UI**.

## 🎮 NEW: Tablet Control Panel

### Opening the Control Panel
```
/npcpanel
```
*(Admin permission required)*

A beautiful, modern dark-themed tablet interface that gives you complete control over all NPC systems. No more typing commands - everything is visual and intuitive!

### Control Panel Features
- **🛡️ Guard Zones Tab**: Spawn/clear guards, toggle zones, view zone details
- **🚗 Patrols Tab**: Start/stop patrols, view route information
- **👔 Bodyguards Tab**: View tiers, give/remove bodyguards for any player
- **🎯 Hunters Tab**: Spawn hunters with sliders for level and count

**UI Highlights:**
- Dark gradient theme with cyan accents
- Smooth animations and transitions
- Interactive cards with hover effects
- Range sliders for precise control
- Real-time notifications
- Responsive 900x650px tablet design

---

## Features

### 1. Hunter System (Original)
Aggressive NPCs in vehicles that chase and ram players.

**Commands:**
- `/chaseme [level] [count]` - Spawn hunter vehicles (level 1-5, count 1-10)
- `/chaseoff` - Remove all hunters

### 2. Guard Zones
Configurable areas with static guards that protect zones. Guards will attack players on sight unless they have the required item or identifier.

**⚠️ IMPORTANT:** Guards do NOT spawn automatically! You must spawn them using the control panel (/npcpanel) or admin commands. This gives you full control over when and where guards are active.

**Pre-configured Zones:**
- Cayo Perico (15 guards, requires "creampie" item)
- Fort Zancudo (20 guards, requires "military_id" item)
- Grove Street Territory (8 guards, requires "gang_bandana" item)

**Admin Commands:**
- **`/npcpanel`** - 🎯 **RECOMMENDED: Opens the visual control panel**
- `/spawnguards [zone name or number]` - Spawn guards in a specific zone
- `/clearguards [zone name or number/all]` - Clear guards from zone
- `/listzones` - List all guard zones
- `/toggleguardzones` - Enable/disable all guard zones

### 3. Patrol Routes
Vehicle patrols that follow waypoint routes and engage threats.

**Pre-configured Patrols:**
- Cayo Perico Perimeter
- Fort Zancudo Patrol

**Admin Commands:**
- **`/npcpanel`** - 🎯 **RECOMMENDED: Use the control panel**
- `/spawnpatrol [route name or number]` - Spawn a patrol vehicle
- `/clearpatrols` - Clear all patrols
- `/listpatrols` - List all patrol routes

### 4. Bodyguard System
Hire personal bodyguards that follow and protect you.

**Bodyguard Tiers:**
1. **Basic Security** - $5,000 (30 min)
   - Health: 150 | Armor: 50
   - Weapon: Pistol/Combat Pistol
   - Accuracy: 30%

2. **Professional Guard** - $15,000 (30 min)
   - Health: 250 | Armor: 100
   - Weapon: Carbine Rifle/Pump Shotgun
   - Accuracy: 50%

3. **Elite Mercenary** - $35,000 (30 min)
   - Health: 400 | Armor: 200
   - Weapon: Assault Rifle/Carbine/Special Carbine
   - Accuracy: 75%

**Hire Locations:**
- Downtown Security: -1082.82, -247.23, 37.76
- Sandy Shores Mercs: 1961.95, 3748.45, 32.34
- Paleto Bay Protection: -104.89, 6324.56, 31.52

**Limits:**
- Maximum 3 bodyguards active at once
- Bodyguards expire after their duration ends
- Bodyguards will defend you against attackers

**Admin Commands:**
- **`/npcpanel`** - 🎯 **RECOMMENDED: Use the control panel for easier management**
- `/givebodyguard [playerid] [tier]` - Give bodyguard to player (tier 1-3)
- `/clearbodyguards [playerid]` - Remove all bodyguards from player

## Configuration

### Adding Guard Zones
Edit `config.lua` and add to `Config.GuardZones`:

```lua
{
    name = "Your Zone Name",
    center = vector3(x, y, z),
    radius = 100.0,
    guardCount = 10,
    requiredItem = "itemname", -- false for none
    requiresIdentifier = false, -- or "license:xyz"
    pedModels = { 'model1', 'model2' },
    weapons = { 'WEAPON_PISTOL', 'WEAPON_SMG' },
    accuracy = 50,
    health = 200,
    armor = 100,
}
```

### Adding Patrol Routes
Edit `config.lua` and add to `Config.PatrolRoutes`:

```lua
{
    name = "Route Name",
    guardZone = "Associated Zone Name",
    vehicleModel = 'vehiclename',
    pedModel = 'pedmodel',
    weapon = 'WEAPON_CARBINERIFLE',
    speed = 25.0,
    waypoints = {
        vector4(x, y, z, heading),
        vector4(x, y, z, heading),
        -- Add more waypoints
    },
}
```

### Adding Bodyguard Locations
Edit `config.lua` and add to `Config.BodyguardLocations`:

```lua
{
    name = "Location Name",
    coords = vector3(x, y, z),
    radius = 2.5,
    heading = 0.0,
}
```

### Customizing Bodyguard Tiers
Edit `config.lua` > `Config.BodyguardTiers` to adjust:
- Price
- Duration
- Ped models
- Weapons
- Stats (health, armor, accuracy)

## Dependencies
- qb-core
- qb-target
- qb-menu
- codem-inventory (for item checks in guard zones)
- oxmysql

## Installation
1. Place resource in `resources/[02PRELUDE]/[SCRIPTS]/[PRELUDE]/prelude-npc`
2. Add `ensure prelude-npc` to server.cfg
3. Add required items to inventory:
   - creampie
   - military_id
   - gang_bandana
4. Restart server

## Item Setup
Add these items to your `codem-inventory/config/itemlist.lua`:

```lua
['creampie'] = {
    name = 'creampie',
    label = 'Cream Pie',
    weight = 200,
    type = 'item',
    image = 'creampie.png',
    unique = false,
    useable = true,
    shouldClose = true,
    description = 'Special access item'
},
['military_id'] = {
    name = 'military_id',
    label = 'Military ID',
    weight = 10,
    type = 'item',
    image = 'military_id.png',
    unique = true,
    useable = false,
    shouldClose = false,
    description = 'Military identification card'
},
['gang_bandana'] = {
    name = 'gang_bandana',
    label = 'Gang Bandana',
    weight = 50,
    type = 'item',
    image = 'gang_bandana.png',
    unique = false,
    useable = true,
    shouldClose = true,
    description = 'Gang affiliation marker'
},
```

## Notes
- No blips are created by this script
- Guards respawn after 5 minutes if zone is active
- Bodyguards automatically defend you when you're attacked
- Patrol guards will exit vehicles to engage threats
- All spawn positions use ground detection for proper placement
- Guard and bodyguard relationship groups are set up automatically

## Troubleshooting
- **Guards not spawning**: Check console for model load errors
- **Bodyguards not following**: Ensure qb-target is working
- **Item checks not working**: Verify items exist in inventory database
- **Menu not opening**: Check qb-menu is installed and working

## Credits
Original hunter system by Charlie
Enhanced with guard zones, patrols, bodyguards, and tablet control panel UI

---

**Version 2.0.0** - Now with Tablet Control Panel!
