Config = Config or {}

-- ============================================
-- SYSTEM SETTINGS
-- ============================================
Config.UseDatabase = true -- Set to false to use config-only mode
Config.Framework = 'qb' -- 'qb' or 'esx'

-- UI & Visual Settings
Config.EnableBlips = false -- Show zone blips on map (optional)
Config.BlipSprite = 161 -- Default blip sprite
Config.BlipColor = 1 -- Default blip color (red)
Config.BlipScale = 0.8
Config.EnableZoneMarkers = true -- Show 3D markers at zone centers
Config.EnableRouteBuilder = true -- Enable in-game route builder
Config.EnableZoneCreator = true -- Enable in-game zone creator

-- Warning System Settings
Config.EnableWarnings = false -- Enable player warnings for restricted zones (disabled by default)
Config.WarningDistances = {
    approaching = 100.0, -- Yellow warning
    warning = 50.0, -- Orange warning
    trespassing = 0.0, -- Inside zone (red)
}
Config.WarningMessages = {
    approaching = "⚠️ Approaching restricted area",
    warning = "⚠️ WARNING: Restricted zone ahead!",
    trespassing = "🚨 TRESPASSING - Leave immediately or guards will engage!",
    hostile = "🚨 GUARDS ENGAGING - You are under attack!"
}
Config.ShowDistanceUI = true -- Show distance to nearest restricted zone

-- Guard AI Behavior Settings
Config.GuardBehaviors = {
    enabled = true,
    modes = {
        stationary = true, -- Guards stand still
        patrol = true, -- Guards walk around zone
        investigate = true, -- Guards check gunshots/disturbances
        callBackup = true, -- Guards radio for help when attacked
        takeCover = true, -- Guards use cover in combat
    },
    investigationRadius = 50.0, -- How far guards check disturbances
    backupDelay = 5000, -- ms before backup spawns
    coverSearchRadius = 20.0, -- How far to look for cover
    patrolSpeed = 1.0, -- Walking speed for patrol mode
}

-- Original hunter system settings
Config.SpawnDistanceBehind = 50.0
Config.SpawnSideOffset = 10.0
Config.DrivingStyle = 786603
Config.GiveWeapon = false
Config.WeaponName = 'WEAPON_PISTOL'

-- Hunter levels (vehicle chase system)
Config.Levels = {
    [1] = {
        VehicleModel = 'asea',
        DriverModel = 'a_m_y_hipster_01',
        ChaseCruiseSpeed = 40.0,
        Siren = false,
    },
    [2] = {
        VehicleModel = 'seminole',
        DriverModel = 'a_m_y_business_02',
        ChaseCruiseSpeed = 55.0,
        Siren = false,
    },
    [3] = {
        VehicleModel = 'banshee',
        DriverModel = 'g_m_y_lost_01',
        ChaseCruiseSpeed = 110.0,
        Siren = false,
    },
    [4] = {
        VehicleModel = 'turismor',
        DriverModel = 'g_m_y_mexgang_01',
        ChaseCruiseSpeed = 90.0,
        Siren = false,
    },
    [5] = {
        VehicleModel = 'osiris',
        DriverModel = 'g_m_y_salvaboss_01',
        ChaseCruiseSpeed = 110.0,
        Siren = false,
    },
}

-- Guard Zone Settings
Config.GuardZones = {
    -- Cayo Perico: Static guards around the main compound
    {
        name = "Cayo Perico",
        center = vector3(5207.70, -5107.27, 5.06),
        radius = 200.0,
        guardCount = 18,
        requiredJob = "cayo", -- Players with this job won't be attacked
        requiresIdentifier = false,
        pedModels = {
            'g_m_y_salvaboss_01',
            'g_m_y_salvagoon_01',
            'g_m_y_salvagoon_02',
            'g_m_y_salvagoon_03',
        },
        weapons = {
            'WEAPON_ASSAULTRIFLE',
            'WEAPON_CARBINERIFLE',
            'WEAPON_SPECIALCARBINE',
            'WEAPON_ADVANCEDRIFLE',
        },
        accuracy = 65,
        health = 400,
        armor = 200,
    },
    -- Cayo Perico: Roaming patrol guards around El Rubio's compound
    {
        name = "Cayo South Compound",
        center = vector3(4977.76, -5638.78, 22.50),
        radius = 120.0,
        guardCount = 10,
        requiredJob = "cayo",
        requiresIdentifier = false,
        patrolMode = true, -- Guards wander the zone instead of standing
        pedModels = {
            'g_m_y_salvaboss_01',
            'g_m_y_salvagoon_01',
            'g_m_y_salvagoon_02',
            'g_m_y_salvagoon_03',
        },
        weapons = {
            'WEAPON_CARBINERIFLE',
            'WEAPON_ASSAULTRIFLE',
            'WEAPON_SPECIALCARBINE',
        },
        accuracy = 60,
        health = 350,
        armor = 150,
    },
    -- Cayo Perico: Patrol guards near the north docks / landing strip
    {
        name = "Cayo North Dock",
        center = vector3(5170.81, -5115.10, 2.97),
        radius = 100.0,
        guardCount = 18,
        requiredJob = "cayo",
        requiresIdentifier = false,
        patrolMode = true,
        pedModels = {
            'g_m_y_salvagoon_01',
            'g_m_y_salvagoon_02',
            'g_m_y_salvagoon_03',
        },
        weapons = {
            'WEAPON_CARBINERIFLE',
            'WEAPON_ASSAULTRIFLE',
        },
        accuracy = 55,
        health = 300,
        armor = 100,
    },
    -- Cayo Perico: Patrol guards along the east cliffs / perimeter
    {
        name = "Cayo East Perimeter",
        center = vector3(5195.57, -5540.01, 12.50),
        radius = 120.0,
        guardCount = 8,
        requiredJob = "cayo",
        requiresIdentifier = false,
        patrolMode = true,
        pedModels = {
            'g_m_y_salvagoon_01',
            'g_m_y_salvagoon_02',
            'g_m_y_salvagoon_03',
        },
        weapons = {
            'WEAPON_CARBINERIFLE',
            'WEAPON_ASSAULTRIFLE',
            'WEAPON_MACHINEPISTOL',
        },
        accuracy = 55,
        health = 300,
        armor = 100,
    },
    -- Cayo Perico: Exact-position static AR guards at gate/entrance
    {
        name = "Cayo Gate Guards",
        center = vector3(5145.59, -4950.62, 14.31), -- center of the cluster (for threat detection radius)
        radius = 10.0,
        requiredJob = "cayo",
        requiresIdentifier = false,
        skipGroundCheck = true, -- Trust exact Z values provided
        positions = {
            { pos = vector3(5146.28, -4950.19, 14.21), heading = 0.0 },
            { pos = vector3(5151.88, -4944.77, 14.24), heading = 0.0 },
            { pos = vector3(5138.61, -4956.91, 14.49), heading = 0.0 },
        },
        pedModels = {
            'g_m_y_salvaboss_01',
            'g_m_y_salvagoon_01',
            'g_m_y_salvagoon_02',
        },
        weapons = {
            'WEAPON_ASSAULTRIFLE',
            'WEAPON_CARBINERIFLE',
            'WEAPON_SPECIALCARBINE',
        },
        accuracy = 70,
        health = 400,
        armor = 200,
    },
    -- Cayo Perico: Exact-position static AR guards (second cluster)
    {
        name = "Cayo AR Guards 2",
        center = vector3(5166.52, -4991.18, 12.34),
        radius = 40.0,
        requiredJob = "cayo",
        requiresIdentifier = false,
        skipGroundCheck = true,
        positions = {
            { pos = vector3(5141.89, -4996.33, 10.41), heading = 319.33 },
            { pos = vector3(5152.48, -4999.44, 10.24), heading = 358.91 },
            { pos = vector3(5181.17, -4989.03, 14.18), heading = 40.46 },
            { pos = vector3(5190.52, -4979.92, 14.53), heading = 54.48 },
        },
        pedModels = {
            'g_m_y_salvaboss_01',
            'g_m_y_salvagoon_01',
            'g_m_y_salvagoon_02',
            'g_m_y_salvagoon_03',
        },
        weapons = {
            'WEAPON_ASSAULTRIFLE',
            'WEAPON_CARBINERIFLE',
            'WEAPON_SPECIALCARBINE',
        },
        accuracy = 70,
        health = 400,
        armor = 200,
    },
    -- Cayo Perico: Exact-position snipers (second cluster)
    {
        name = "Cayo Sniper Post 2",
        center = vector3(5149.66, -5050.50, 17.27),
        radius = 20.0,
        requiredJob = "cayo",
        requiresIdentifier = false,
        skipGroundCheck = true,
        positions = {
            { pos = vector3(5145.96, -5050.61, 20.39), heading = 356.01, weapon = 'WEAPON_SNIPERRIFLE' },
            { pos = vector3(5151.51, -5050.62, 20.39), heading = 359.29, weapon = 'WEAPON_SNIPERRIFLE' },
            { pos = vector3(5151.51, -5050.27, 10.03), heading = 358.70, weapon = 'WEAPON_SNIPERRIFLE' },
        },
        pedModels = {
            'g_m_y_salvaboss_01',
            'g_m_y_salvagoon_01',
        },
        weapons = {
            'WEAPON_SNIPERRIFLE',
        },
        accuracy = 85,
        health = 400,
        armor = 200,
    },
    -- Cayo Perico: Exact-position sniper on elevated post
    {
        name = "Cayo Sniper Post",
        center = vector3(5150.56, -4933.28, 30.87),
        radius = 10.0,
        requiredJob = "cayo",
        requiresIdentifier = false,
        skipGroundCheck = true, -- Elevated position, skip ground snap
        positions = {
            { pos = vector3(5150.56, -4933.28, 30.87), heading = 0.0, weapon = 'WEAPON_SNIPERRIFLE' },
        },
        pedModels = {
            'g_m_y_salvaboss_01',
        },
        weapons = {
            'WEAPON_SNIPERRIFLE',
        },
        accuracy = 85,
        health = 400,
        armor = 200,
    },
}

-- ============================================
-- AGGRESSIVE NPC ZONES
-- ============================================
-- Street-level NPCs that wander areas and attack any player on sight.
-- Melee weapons only. No entry notifications. Always hostile.
Config.AutoSpawnAggressiveZones = true -- Auto-spawn all zones when resource starts
Config.AggressiveNPCZones = {
    {
        name = "Davis - Ballas Turf",
        center = vector3(-76.99, -1822.88, 26.94),
        radius = 80.0,
        npcCount = 6,
        attackRange = 18.0,
        pedModels = {
            'g_m_y_ballasog_01',
            'g_m_y_ballaeast_01',
            'g_m_y_ballasout_01',
        },
        weapons = { 'WEAPON_BAT', 'WEAPON_KNIFE', 'WEAPON_BOTTLE' },
        health = 150, armor = 0, accuracy = 40,
    },
    {
        name = "Chamberlain Hills - Families",
        center = vector3(69.79, -1922.44, 20.79),
        radius = 80.0,
        npcCount = 5,
        attackRange = 18.0,
        pedModels = {
            'g_m_y_famca_01',
            'g_m_y_famdnf_01',
            'g_m_y_famfor_01',
        },
        weapons = { 'WEAPON_CROWBAR', 'WEAPON_BAT', 'WEAPON_SWITCHBLADE' },
        health = 150, armor = 0, accuracy = 40,
    },
    {
        name = "Strawberry - Rough Block",
        center = vector3(-376.93, -1611.77, 29.29),
        radius = 70.0,
        npcCount = 5,
        attackRange = 18.0,
        pedModels = {
            'g_m_y_ballasog_01',
            'g_m_y_ballaeast_01',
            'a_m_y_genstreet_01',
            'a_m_y_genstreet_02',
        },
        weapons = { 'WEAPON_KNIFE', 'WEAPON_BOTTLE', 'WEAPON_BAT' },
        health = 150, armor = 0, accuracy = 35,
    },
    {
        name = "Rancho - Vagos Street",
        center = vector3(419.56, -1871.94, 25.97),
        radius = 75.0,
        npcCount = 6,
        attackRange = 18.0,
        pedModels = {
            'g_m_y_mexgang_01',
            'g_m_y_mexgoon_01',
            'g_m_y_mexgoon_02',
            'g_m_y_mexgoon_03',
        },
        weapons = { 'WEAPON_MACHETE', 'WEAPON_KNIFE', 'WEAPON_BAT' },
        health = 150, armor = 0, accuracy = 40,
    },
    {
        name = "Cypress Flats - East LS",
        center = vector3(866.28, -2102.69, 29.69),
        radius = 75.0,
        npcCount = 5,
        attackRange = 18.0,
        pedModels = {
            'g_m_y_mexgang_01',
            'g_m_y_lost_01',
            'a_m_y_genstreet_01',
        },
        weapons = { 'WEAPON_WRENCH', 'WEAPON_CROWBAR', 'WEAPON_HAMMER' },
        health = 150, armor = 0, accuracy = 35,
    },
    {
        name = "Mirror Park - Lost MC",
        center = vector3(1145.78, -759.59, 57.55),
        radius = 70.0,
        npcCount = 5,
        attackRange = 20.0,
        pedModels = {
            'g_m_y_lost_01',
            'g_m_y_lost_02',
            'g_m_y_lost_03',
        },
        weapons = { 'WEAPON_BAT', 'WEAPON_CROWBAR', 'WEAPON_WRENCH' },
        health = 175, armor = 0, accuracy = 45,
    },
    {
        name = "Sandy Shores - Rough Side",
        center = vector3(1726.52, 3714.18, 34.08),
        radius = 80.0,
        npcCount = 6,
        attackRange = 18.0,
        pedModels = {
            'a_m_y_soucal_01',
            'a_m_m_soucal_01',
            'a_m_y_genstreet_01',
            'a_m_y_genstreet_02',
        },
        weapons = { 'WEAPON_BAT', 'WEAPON_BOTTLE', 'WEAPON_KNIFE' },
        health = 150, armor = 0, accuracy = 35,
    },
    {
        name = "Harmony - Route 68 Trouble",
        center = vector3(494.11, 2656.12, 44.28),
        radius = 75.0,
        npcCount = 5,
        attackRange = 18.0,
        pedModels = {
            'a_m_y_soucal_01',
            'g_m_y_lost_01',
            'a_m_m_soucal_01',
        },
        weapons = { 'WEAPON_HATCHET', 'WEAPON_BAT', 'WEAPON_CROWBAR' },
        health = 150, armor = 0, accuracy = 35,
    },
    {
        name = "Vespucci - Beach Brawlers",
        center = vector3(-1367.59, -1305.10, 4.28),
        radius = 70.0,
        npcCount = 5,
        attackRange = 18.0,
        pedModels = {
            'a_m_y_genstreet_01',
            'a_m_y_genstreet_02',
            'a_m_m_genstreet_01',
        },
        weapons = { 'WEAPON_BOTTLE', 'WEAPON_BAT', 'WEAPON_POOLCUE' },
        health = 125, armor = 0, accuracy = 30,
    },
    {
        name = "Paleto Bay - Dockside",
        center = vector3(-353.22, 6117.52, 31.45),
        radius = 70.0,
        npcCount = 5,
        attackRange = 18.0,
        pedModels = {
            'a_m_y_genstreet_01',
            'a_m_m_farmer_01',
            'a_m_y_soucal_01',
        },
        weapons = { 'WEAPON_CROWBAR', 'WEAPON_WRENCH', 'WEAPON_BAT' },
        health = 150, armor = 0, accuracy = 35,
    },
}

-- Vehicle Patrol Routes
Config.PatrolRoutes = {
    -- Cayo Perico Patrol
    {
        name = "Cayo Perico Perimeter",
        guardZone = "Cayo Perico",
        requiredJob = "cayo",
        vehicleModel = 'mesa3',
        pedModel = 'g_m_y_salvaboss_01',
        weapon = 'WEAPON_CARBINERIFLE',
        speed = 100.0,
        center = vector3(5265.50, -5428.06, 65.60),
        radius = 400.0,
        spawnPoints = {
            vector4(5279.66, -5413.28, 65.78, 197.01),
            vector4(5337.64, -5486.83, 53.25, 239.53),
            vector4(5339.06, -5266.18, 32.58, 53.01),
            vector4(5225.33, -5032.07, 15.79, 219.45),
            vector4(5158.86, -5073.18, 3.22, 184.20),
            vector4(5058.20, -5231.08, 4.63, 26.74),
            vector4(4939.67, -5302.58, 5.43, 170.35),
            vector4(4884.07, -5485.66, 28.05, 237.81),
            vector4(4953.61, -5735.86, 21.35, 162.00),
            vector4(5160.79, -5225.79, 7.34, 175.71),
            vector4(4942.73, -5284.74, 4.55, 353.70),
            vector4(4979.56, -5585.03, 24.57, 217.97),
            vector4(5386.35, -5616.66, 52.37, 346.76),
            vector4(5520.55, -5233.38, 13.97, 356.61),
            vector4(5149.10, -5018.89, 6.88, 197.50),
            vector4(5230.40, -5138.26, 8.49, 216.82),
            vector4(5255.47, -5276.09, 26.06, 212.85),
            vector4(5023.17, -5185.31, 2.62, 158.69),

        },
    },
    -- Cayo Perico Barracks Patrol
    {
        name = "Cayo Perico Barracks",
        guardZone = "Cayo Perico",
        requiredJob = "cayo",
        vehicleModel = 'barracks',
        pedModel = 'g_m_y_salvaboss_01',
        weapon = 'WEAPON_CARBINERIFLE',
        speed = 20.0,
        center = vector3(5265.50, -5428.06, 65.60),
        radius = 400.0,
        spawnPoints = {
          
            vector4(5150.63, -5497.77, 51.31, 273.78),

        },
    },
    -- Fort Zancudo Patrol
    {
        name = "Fort Zancudo Patrol",
        guardZone = "Fort Zancudo",
        vehicleModel = 'barracks',
        pedModel = 's_m_y_marine_01',
        weapon = 'WEAPON_ASSAULTRIFLE',
        speed = 30.0,
        waypoints = {
            vector4(-2047.23, 3132.13, 32.81, 0.0),
            vector4(-1950.45, 3025.67, 32.81, 90.0),
            vector4(-2150.89, 2980.23, 32.81, 180.0),
            vector4(-2250.34, 3100.56, 32.81, 270.0),
        },
    },
}

-- Bodyguard Hire Locations
Config.BodyguardLocations = {
    {
        name = "Downtown Security",
        coords = vector3(-1082.82, -247.23, 37.76),
        radius = 2.5,
        heading = 207.87,
    },
    {
        name = "Sandy Shores Mercs",
        coords = vector3(1961.95, 3748.45, 32.34),
        radius = 2.5,
        heading = 120.45,
    },
    {
        name = "Paleto Bay Protection",
        coords = vector3(-104.89, 6324.56, 31.52),
        radius = 2.5,
        heading = 45.67,
    },
}

-- Bodyguard Tiers (max 3 active)
Config.BodyguardTiers = {
    [1] = {
        name = "Basic Security",
        price = 5000,
        duration = 30, -- minutes
        pedModels = {
            's_m_m_security_01',
            's_m_m_bouncer_01',
        },
        weapons = {
            'WEAPON_PISTOL',
            'WEAPON_COMBATPISTOL',
        },
        accuracy = 30,
        health = 150,
        armor = 50,
    },
    [2] = {
        name = "Professional Guard",
        price = 15000,
        duration = 30,
        pedModels = {
            's_m_m_fiboffice_01',
            's_m_m_fiboffice_02',
        },
        weapons = {
            'WEAPON_CARBINERIFLE',
            'WEAPON_PUMPSHOTGUN',
        },
        accuracy = 50,
        health = 250,
        armor = 100,
    },
    [3] = {
        name = "Elite Mercenary",
        price = 35000,
        duration = 30,
        pedModels = {
            's_m_y_blackops_01',
            's_m_y_blackops_02',
            's_m_y_blackops_03',
        },
        weapons = {
            'WEAPON_ASSAULTRIFLE',
            'WEAPON_CARBINERIFLE',
            'WEAPON_SPECIALCARBINE',
        },
        accuracy = 75,
        health = 400,
        armor = 200,
    },
}

-- General Settings
Config.MaxBodyguards = 3
Config.GuardDetectionRange = 30.0 -- Distance guards detect threats
Config.GuardAttackRange = 50.0 -- Distance guards will attack
Config.BodyguardFollowDistance = 3.0
Config.CheckInterval = 1000 -- ms between zone checks
Config.GuardRespawnTime = 300000 -- 5 minutes (ms)

-- Auto-Spawn Settings (spawn on resource start)
Config.AutoSpawnZones = { "Cayo Perico", "Cayo South Compound", "Cayo North Dock", "Cayo East Perimeter", "Cayo Gate Guards", "Cayo Sniper Post", "Cayo AR Guards 2", "Cayo Sniper Post 2" } -- Zone names to auto-spawn
Config.AutoSpawnPatrols = { "Cayo Perico Perimeter", "Cayo Perico Barracks" } -- Patrol names to auto-spawn
-- Note: Config.AutoSpawnAggressiveZones is defined in the AggressiveNPCZones section above

-- Permissions
Config.AdminPermissions = {
    controlPanel = 'god', -- Permission for /npcpanel
    createZones = 'admin', -- Permission to create zones
    deleteZones = 'god', -- Permission to delete zones
    manageGuards = 'admin', -- Permission to spawn/clear guards
    managePatrols = 'admin', -- Permission for patrols
    manageBodyguards = 'admin', -- Permission for bodyguard commands
}

-- Zone Builder Settings
Config.ZoneBuilder = {
    markerType = 1, -- Marker type for zone center
    markerColor = {r = 255, g = 0, b = 0, a = 100},
    maxRadius = 500.0,
    minRadius = 10.0,
    defaultRadius = 50.0,
    previewUpdateRate = 100, -- ms
}

-- Route Builder Settings
Config.RouteBuilder = {
    waypointMarker = 1,
    waypointColor = {r = 0, g = 255, b = 255, a = 200},
    maxWaypoints = 50,
    minWaypoints = 2,
    snapToGround = true,
    showConnections = true, -- Draw lines between waypoints
}

-- ============================================
-- ZONE TEMPLATES / SCENARIOS
-- ============================================
-- Quick-deploy pre-made scenarios for events
Config.ZoneTemplates = {
    -- Bank Heist Scenario
    {
        name = "Bank Heist Response",
        description = "Guards at all major banks in Los Santos",
        icon = "fa-building-columns",
        zones = {
            "Pacific Standard Bank",
            "Fleeca Bank - Legion Square",
            "Fleeca Bank - Hawick",
            "Fleeca Bank - Alta",
            "Fleeca Bank - Burton",
            "Fleeca Bank - Vinewood",
        },
        patrols = {},
        autoSpawn = true, -- Automatically spawn when activated
    },
    
    -- Prison Break Scenario
    {
        name = "Prison Lockdown",
        description = "Maximum security at Bolingbroke Penitentiary",
        icon = "fa-handcuffs",
        zones = {
            "Bolingbroke Prison",
        },
        patrols = {
            "Prison Perimeter",
        },
        autoSpawn = true,
    },
    
    -- Gang War Scenario
    {
        name = "Gang War",
        description = "Multiple gang territories with heavy guards and patrols",
        icon = "fa-gun",
        zones = {
            "Grove Street Territory",
            "Ballas Territory",
            "Vagos Territory",
            "Marabunta Territory",
        },
        patrols = {
            "Grove Street Patrol",
            "Ballas Patrol",
        },
        autoSpawn = true,
    },
    
    -- Military Lockdown
    {
        name = "Military Lockdown",
        description = "Fort Zancudo full alert + checkpoints across city",
        icon = "fa-shield",
        zones = {
            "Fort Zancudo",
            "Military Checkpoint - North",
            "Military Checkpoint - East",
            "Military Checkpoint - South",
        },
        patrols = {
            "Fort Zancudo Patrol",
            "Highway Patrol",
        },
        autoSpawn = true,
    },
    
    -- VIP Protection
    {
        name = "VIP Protection",
        description = "Governor's mansion + convoy guards",
        icon = "fa-user-tie",
        zones = {
            "Governor's Mansion",
            "City Hall",
        },
        patrols = {
            "VIP Convoy Route",
        },
        autoSpawn = true,
    },
    
    -- Cartel Operation
    {
        name = "Cartel Operations",
        description = "Cayo Perico + import locations heavily guarded",
        icon = "fa-skull-crossbones",
        zones = {
            "Cayo Perico",
            "Docks - Elysian Island",
            "Warehouse District",
        },
        patrols = {
            "Cayo Perico Perimeter",
            "Docks Patrol",
        },
        autoSpawn = true,
    },
    
    -- Emergency Services
    {
        name = "Emergency Response",
        description = "Hospital and police station protection",
        icon = "fa-truck-medical",
        zones = {
            "Pillbox Medical Center",
            "Mission Row PD",
            "Paleto Bay Sheriff",
            "Sandy Shores Sheriff",
        },
        patrols = {
            "Hospital Patrol",
            "MRPD Patrol",
        },
        autoSpawn = true,
    },
    
    -- Downtown Lockdown
    {
        name = "Downtown Lockdown",
        description = "Heavy security in central Los Santos",
        icon = "fa-building",
        zones = {
            "Legion Square",
            "City Hall",
            "Pacific Standard Bank",
            "Maze Bank Tower",
        },
        patrols = {
            "Downtown Patrol",
            "Vinewood Patrol",
        },
        autoSpawn = true,
    },
}

-- Quick Action Presets
Config.QuickActions = {
    spawnAllGuards = true, -- Enable "Spawn All Guards" button
    clearEverything = true, -- Enable "Clear Everything" button
    emergencyLockdown = true, -- Enable "Emergency Lockdown" button
    performanceCheck = true, -- Enable performance monitoring
}

return Config
