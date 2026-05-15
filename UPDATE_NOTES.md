# 🎉 NPC System Update - Control Panel Added!

## What's New?

### ✅ Custom Tablet-Style Dark Themed UI
I've added a beautiful, modern control panel to manage all NPC systems visually!

**Features:**
- 🎨 Dark gradient theme with cyan/teal accents
- 📱 Tablet-style design (900x650px)
- ✨ Smooth animations and transitions
- 🎯 4 tabs: Guard Zones, Patrols, Bodyguards, Hunters
- 🖱️ Interactive cards with hover effects
- 🎚️ Range sliders for precise control
- ⌨️ ESC key to close

---

## How to Use

### Opening the Panel
```
/npcpanel
```
*(Admin permission required)*

### What Each Tab Does

#### 🛡️ Guard Zones Tab
- View all configured guard zones
- **Spawn Guards** button - Activates guards in a zone
- **Clear Guards** button - Removes guards from a zone
- **Global Toggle** - Enable/disable all zones at once
- Shows: guard count, radius, required items, health/armor

#### 🚗 Patrols Tab
- View all patrol routes
- **Start Patrol** button - Spawns a patrol vehicle
- **Clear All Patrols** button - Removes all patrols
- Shows: vehicle, speed, waypoint count, weapons

#### 👔 Bodyguards Tab
- View all 3 bodyguard tiers with stats
- Input player ID and select tier
- **Give Bodyguard** - Grants bodyguard to player
- **Clear Bodyguards** - Removes player's bodyguards

#### 🎯 Hunters Tab
- View all 5 hunter levels
- Sliders to select level (1-5) and count (1-10)
- **Spawn Hunters** - Launches hunters
- **Clear All Hunters** - Removes all hunters

---

## About Guards (Answer to Your Question)

**Why you don't see guards:** Guards do NOT spawn automatically! This is by design to give admins full control.

**To spawn guards:**
1. Open control panel: `/npcpanel`
2. Go to **Guard Zones** tab
3. Find the zone you want (Cayo Perico, Fort Zancudo, etc.)
4. Click **Spawn Guards**

**Pre-configured zones:**
- ✅ Cayo Perico (15 guards)
- ✅ Fort Zancudo (20 guards)
- ✅ Grove Street Territory (8 guards)

---

## Files Added

```
prelude-npc/
├── html/
│   ├── index.html      (UI structure)
│   ├── style.css       (Dark tablet theme)
│   └── script.js       (Functionality)
├── fxmanifest.lua      (Updated with UI files)
├── client.lua          (Added NUI controls)
├── server.lua          (Added NUI endpoints)
├── README.md           (Updated with panel info)
├── CONTROL_PANEL_GUIDE.md  (New: Detailed UI guide)
└── COMMANDS.txt        (Updated with /npcpanel)
```

---

## Quick Start

1. **Restart the resource:**
   ```
   restart prelude-npc
   ```

2. **Open the control panel:**
   ```
   /npcpanel
   ```

3. **Spawn some guards:**
   - Click on Guard Zones tab
   - Click "Spawn Guards" on any zone
   - Watch them appear!

4. **Try the hunters:**
   - Click on Hunters tab
   - Adjust the sliders
   - Click "Spawn Hunters"
   - They'll chase you!

---

## Color Guide

- **Green buttons** = Spawn/Add actions ✅
- **Red buttons** = Clear/Remove actions ❌
- **Cyan/Teal** = Active/Selected elements 🎯
- **Dark gradients** = Background/Cards 🌙

---

## Technical Details

### UI Architecture
- **Frontend**: HTML/CSS/JavaScript
- **Framework**: jQuery for DOM manipulation
- **Communication**: NUI callbacks (client ↔ UI)
- **Theme**: Custom dark gradient design
- **Responsiveness**: Fixed tablet size (optimal for visibility)

### Integration
- Fully integrated with QBCore notifications
- Admin permission checks on all actions
- Real-time data updates from config
- Maintains all existing command functionality

---

## Legacy Commands

All old commands still work! The UI is just a better way to use them.

```
/spawnguards [zone]      → Use Guard Zones tab instead
/clearguards [zone]      → Use Guard Zones tab instead
/spawnpatrol [route]     → Use Patrols tab instead
/clearpatrols            → Use Patrols tab instead
/givebodyguard [id] [tier] → Use Bodyguards tab instead
/clearbodyguards [id]    → Use Bodyguards tab instead
/chaseme [level] [count] → Use Hunters tab instead (or keep using command)
/chaseoff                → Use Hunters tab instead
```

---

## Enjoy Your New Control Panel! 🎮

No more typing commands - everything is visual and intuitive!

**Need help?** Check `CONTROL_PANEL_GUIDE.md` for detailed instructions.
