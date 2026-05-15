# ⚡ QUICK START GUIDE

## 🚀 5-Minute Setup

### Step 1: Import Database (2 minutes)
```sql
-- Run this file in your database:
npc_system.sql
```
This creates 6 tables and imports pre-configured zones.

### Step 2: Check Config (1 minute)
Open `config.lua` and verify:
```lua
Config.UseDatabase = true    -- ✅ Should be true
Config.EnableBlips = false   -- ✅ Optional, your choice
Config.EnableZoneCreator = true   -- ✅ Should be true
Config.EnableRouteBuilder = true  -- ✅ Should be true
```

### Step 3: Restart Resource (30 seconds)
```
restart prelude-npc
```

### Step 4: Test (1 minute)
In-game commands:
```
/npcpanel    # Opens control panel
/createzone  # Test zone builder
/createroute # Test route builder
```

### Step 5: Create Your First Zone! (30 seconds)
1. Type `/createzone`
2. Press `E` to set center
3. Scroll mouse to adjust radius
4. Press `ENTER`
5. Fill in the form
6. Done! ✅

---

## 🎮 Essential Commands

```bash
# Main Interface
/npcpanel           # Visual control panel (USE THIS!)

# Creation Tools
/createzone         # Build a guard zone
/createroute        # Build a patrol route

# Quick Actions
/spawnguards 1      # Spawn guards in zone #1
/clearguards 1      # Clear guards from zone #1
/spawnpatrol 1      # Start patrol #1
```

---

## 📋 What's Different?

### Old Way:
1. Edit `config.lua`
2. Add zone manually
3. Restart resource
4. Hope it works

### New Way:
1. `/createzone`
2. Click, adjust, confirm
3. Done! Zone is live instantly

---

## 🎯 Pro Tips

1. **Use the Control Panel** - `/npcpanel` is your friend
2. **No Auto-Spawn** - Guards won't spawn until you activate them
3. **Custom Zones** - Show blue badges, can be deleted
4. **Preset Zones** - Show gray badges, protected from deletion
5. **Database Mode** - Everything you create is saved automatically

---

## 🛡️ Pre-Configured Content

You already have:
- ✅ 3 guard zones (Cayo Perico, Fort Zancudo, Grove Street)
- ✅ 2 patrol routes (Cayo/Fort perimeter patrols)
- ✅ 3 bodyguard tiers
- ✅ 5 hunter levels

Just open `/npcpanel` and spawn them!

---

## 🎨 UI Overview

### Guard Zones Tab:
- View all zones
- Spawn/Clear guards
- Create new zones
- Delete custom zones

### Patrols Tab:
- View all routes
- Start/Stop patrols
- Create new routes
- Delete custom routes

### Bodyguards Tab:
- View tiers
- Give to players
- Clear from players

### Hunters Tab:
- Spawn hunters
- Adjust level/count
- Clear all

---

## ⚠️ Common Issues

### "Guards not spawning"
→ They don't auto-spawn anymore! Use `/npcpanel` to manually spawn them.

### "Can't delete a zone"
→ Only custom zones can be deleted. Pre-configured zones are protected.

### "Zone builder not working"
→ Make sure `Config.EnableZoneCreator = true` in config.lua

### "Database errors"
→ Did you import `npc_system.sql`? Database mode requires it.

---

## 📱 Control Panel Features

### What You Can Do:
✅ Spawn guards with one click  
✅ Create zones visually  
✅ Delete custom content  
✅ Manage all NPCs  
✅ Real-time updates  

### What You Can't Do:
❌ Delete preset zones (by design)  
❌ Edit zones after creation (create new one instead)  

---

## 🔥 Try This Now!

**Create a zone around your current position:**
```
1. /createzone
2. Press E (sets center)
3. Scroll up a few times (adjust radius)
4. Press ENTER
5. Name it "My Test Zone"
6. Set guard count to 5
7. Click Submit
```

**You just created your first custom zone!** 🎉

Now open `/npcpanel` → Guard Zones tab → Find your zone → Click "Spawn"

Your guards are now active!

---

## 📚 Full Documentation

For detailed info, check:
- `INSTALLATION_GUIDE.md` - Complete setup guide
- `CHANGELOG.md` - What's new in v3.0
- `COMMANDS.txt` - All available commands
- `ENHANCEMENT_SUMMARY.md` - Technical details

---

## 🎯 Your Next Steps

1. ✅ Import database
2. ✅ Restart resource
3. ✅ Try `/npcpanel`
4. ✅ Create a test zone with `/createzone`
5. ✅ Create a test route with `/createroute`
6. ✅ Spawn some guards from the panel
7. ✅ Enjoy your all-in-one NPC system!

---

**That's it! You're ready to go!** 🚀

Need more help? Check the other documentation files or review the console logs.

---

**Version:** 3.0.0  
**Status:** Ready to use!  
**Time to awesome:** 5 minutes ⏱️
