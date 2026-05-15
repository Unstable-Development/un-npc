# 📱 NPC Control Panel - Quick Start Guide

## Opening the Panel
Simply type in chat:
```
/npcpanel
```
*(Requires admin permission)*

## Navigation

The control panel has 4 main tabs:

### 🛡️ Guard Zones
**Purpose:** Manage static guards that protect specific areas

**What you'll see:**
- List of all configured guard zones
- Zone details: guard count, radius, required items, stats
- Global toggle switch to enable/disable all zones

**Actions:**
- **Spawn Guards**: Click to activate guards in that zone
- **Clear Guards**: Remove all guards from that zone
- **Toggle Switch**: Turn all guard zones on/off globally

**💡 Tip:** Guards won't spawn automatically - you must activate them first!

---

### 🚗 Patrols
**Purpose:** Manage vehicle patrols that drive routes

**What you'll see:**
- List of all configured patrol routes
- Route details: vehicle type, speed, waypoint count, weapons

**Actions:**
- **Start Patrol**: Launch a patrol on that route
- **Clear All Patrols**: Remove all active patrols

**💡 Tip:** Patrol guards will exit vehicles to engage threats!

---

### 👔 Bodyguards
**Purpose:** Manage player bodyguards

**What you'll see:**
- 3 bodyguard tiers with stats and pricing
- Player management controls

**Actions:**
1. Enter **Player ID** in the input field
2. Select **Bodyguard Tier** (1-3) from dropdown
3. Click **Give Bodyguard** to grant, or **Clear Bodyguards** to remove

**💡 Tip:** Players can have max 3 bodyguards at once!

---

### 🎯 Hunters
**Purpose:** Spawn vehicle hunters that chase players

**What you'll see:**
- 5 hunter level cards showing vehicles and speeds
- Sliders for level and count selection
- Spawn and clear buttons

**Actions:**
1. **Adjust Level Slider** (1-5): Sets hunter difficulty
2. **Adjust Count Slider** (1-10): Sets number of hunters
3. Click **Spawn Hunters** to launch them
4. Click **Clear All Hunters** to remove them

**💡 Tip:** Higher levels = faster, more aggressive vehicles!

---

## UI Features

### Color Coding
- **Green buttons** = Spawn/Activate actions
- **Red buttons** = Clear/Remove actions
- **Cyan/Teal** = Active elements and highlights

### Close the Panel
- Click the **X button** in top-right
- Press **ESC key**

### Visual Feedback
- Buttons glow on hover
- Cards highlight when you mouse over them
- Notifications appear for all actions

---

## Common Tasks

### "I want to activate guards at Cayo Perico"
1. Open `/npcpanel`
2. Go to **Guard Zones** tab
3. Find "Cayo Perico" card
4. Click **Spawn Guards** button
5. Done! 15 guards will spawn

### "I want to give myself bodyguards"
1. Type `/id` in chat to see your player ID
2. Open `/npcpanel`
3. Go to **Bodyguards** tab
4. Enter your ID number
5. Select tier (1, 2, or 3)
6. Click **Give Bodyguard**
7. Repeat up to 3 times for max bodyguards

### "I want to spawn hunters to chase someone"
1. Open `/npcpanel`
2. Go to **Hunters** tab
3. Set level slider (1-5) for difficulty
4. Set count slider for how many hunters
5. Click **Spawn Hunters**
6. Note: Hunters will chase YOU (the admin who spawned them)

### "I want to clear everything"
1. Open `/npcpanel`
2. Guard Zones tab → Click **Clear Guards** on each zone
3. Patrols tab → Click **Clear All Patrols**
4. Hunters tab → Click **Clear All Hunters**

---

## Troubleshooting

**Panel won't open?**
- Check you have admin permission
- Press F8 to check for errors
- Ensure resource is started (`ensure prelude-npc`)

**No guards spawning?**
- This is normal - guards must be manually spawned
- Use the control panel to spawn them
- Check F8 console for model errors

**UI looks broken?**
- Clear browser cache (`resmon` → restart resource)
- Check all HTML/CSS/JS files exist in `html/` folder

---

## Pro Tips

✅ **Use the toggle switch** on Guard Zones to quickly enable/disable all zones
✅ **Guards respect required items** - players with the item won't be attacked
✅ **Patrols are persistent** - they'll keep patrolling until cleared
✅ **Bodyguards have timers** - they expire after their duration
✅ **Hunter level 5** is extremely fast and aggressive

---

**Happy NPC Managing! 🎮**
