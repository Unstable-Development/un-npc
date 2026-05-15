Config = Config or {}
local QBCore = exports['qb-core']:GetCoreObject()

-- Storage tables
local spawned = {} -- Hunter vehicles: { {veh=entity, ped=entity}, ... }
local pedestrianHunters = {} -- Pedestrian hunters: { {ped=entity, targetId=playerId}, ... }
local guardZones = {} -- Active guard zones
local patrols = {} -- Active patrol vehicles
local bodyguards = {} -- Player's bodyguards
local aggressiveNPCZones = {} -- Active aggressive NPC zones
local guardZonesEnabled = true
local zoneAccessCache = {} -- Cache for zone access checks

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function log(msg)
    print(('[prelude-npc] %s'):format(msg))
end

local function joaatSafe(model)
    return type(model) == 'number' and model or joaat(model)
end

local function loadModel(model)
    local hash = joaatSafe(model)
    if not IsModelInCdimage(hash) then
        log(('Model not in CD image: %s'):format(tostring(model)))
        return nil
    end
    RequestModel(hash)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(hash) do
        Wait(10)
        if GetGameTimer() > timeout then
            log(('Model load timeout: %s'):format(tostring(model)))
            return nil
        end
    end
    return hash
end

local function safeDelete(ent)
    if ent and DoesEntityExist(ent) then
        SetEntityAsMissionEntity(ent, true, true)
        DeleteEntity(ent)
    end
end

local function makeNetworked(ent)
    if not ent or not DoesEntityExist(ent) then return end
    NetworkRegisterEntityAsNetworked(ent)
    local netId = NetworkGetNetworkIdFromEntity(ent)
    if netId then
        SetNetworkIdCanMigrate(netId, true)
        SetNetworkIdExistsOnAllMachines(netId, true)
    end
end

local function getRandomFromTable(tbl)
    if not tbl or #tbl == 0 then return nil end
    return tbl[math.random(#tbl)]
end

local function isPlayerNearCoords(coords, radius)
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    return #(playerCoords - coords) <= radius
end

-- ============================================
-- HUNTER SYSTEM (Original functionality)
-- ============================================

local function cleanupHunters()
    for i = #spawned, 1, -1 do
        local h = spawned[i]
        if h then
            safeDelete(h.ped)
            safeDelete(h.veh)
        end
        table.remove(spawned, i)
    end
    for i = #pedestrianHunters, 1, -1 do
        local h = pedestrianHunters[i]
        if h then
            safeDelete(h.ped)
        end
        table.remove(pedestrianHunters, i)
    end
end

local function spawnHunter(level)
    level = level or 1
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end
    
    local levelConfig = Config.Levels[level]
    if not levelConfig then
        log(('Invalid level: %d'):format(level))
        return
    end
    
    local playerPed = PlayerPedId()
    if not DoesEntityExist(playerPed) then
        log('Player ped missing')
        return
    end
    
    spawnHunterAtCoords(level, GetEntityCoords(playerPed), GetPlayerServerId(PlayerId()))
end

local function spawnHunterAtCoords(level, targetCoords, targetPlayerId)
    level = level or 1
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end
    
    local levelConfig = Config.Levels[level]
    if not levelConfig then
        log(('Invalid level: %d'):format(level))
        return
    end
    
    if not targetCoords then
        log('No target coordinates provided')
        return
    end
    
    local vehHash = loadModel(levelConfig.VehicleModel)
    if not vehHash then
        log(('Vehicle model failed to load: %s'):format(levelConfig.VehicleModel))
        return
    end
    
    local pedHash = loadModel(levelConfig.DriverModel)
    if not pedHash then
        log(('Driver model failed to load: %s'):format(levelConfig.DriverModel))
        SetModelAsNoLongerNeeded(vehHash)
        return
    end
    
    -- pick spawn point behind target with slight left/right offset
    local side = (math.random() * 2.0 - 1.0) * Config.SpawnSideOffset
    local heading = 0.0 -- Default heading
    
    -- Calculate spawn position relative to target
    local angle = math.random() * 2 * math.pi
    local offsetX = math.cos(angle) * Config.SpawnDistanceBehind + side
    local offsetY = math.sin(angle) * Config.SpawnDistanceBehind
    
    local spawnPos = vector3(targetCoords.x + offsetX, targetCoords.y + offsetY, targetCoords.z)
    
    local x, y, z = spawnPos.x, spawnPos.y, spawnPos.z
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 50.0, false)
    if found then z = groundZ + 1.0 end
    
    -- create vehicle
    local veh = CreateVehicle(vehHash, x, y, z, heading, true, true)
    if not DoesEntityExist(veh) then
        log('CreateVehicle failed')
        SetModelAsNoLongerNeeded(vehHash)
        SetModelAsNoLongerNeeded(pedHash)
        return
    end
    
    makeNetworked(veh)
    SetEntityAsMissionEntity(veh, true, true)
    
    SetVehicleOnGroundProperly(veh)
    SetVehicleEngineOn(veh, true, true, false)
    SetVehicleDoorsLocked(veh, 2)
    if levelConfig.Siren then
        SetVehicleSiren(veh, true)
    end
    
    -- create ped separately + warp into driver seat
    local driver = CreatePed(4, pedHash, x, y, z + 1.0, heading, true, true)
    if not DoesEntityExist(driver) then
        log('CreatePed failed (driver not created)')
        safeDelete(veh)
        SetModelAsNoLongerNeeded(vehHash)
        SetModelAsNoLongerNeeded(pedHash)
        return
    end
    
    makeNetworked(driver)
    SetEntityAsMissionEntity(driver, true, true)
    
    -- shove them into the car
    TaskWarpPedIntoVehicle(driver, veh, -1)
    Wait(0)
    
    -- sanity checks
    if GetPedInVehicleSeat(veh, -1) ~= driver then
        Wait(200)
        TaskWarpPedIntoVehicle(driver, veh, -1)
        Wait(0)
    end
    
    if GetPedInVehicleSeat(veh, -1) ~= driver then
        log('Driver failed to enter vehicle (seat not taken)')
        safeDelete(driver)
        safeDelete(veh)
        SetModelAsNoLongerNeeded(vehHash)
        SetModelAsNoLongerNeeded(pedHash)
        return
    end
    
    -- behavior tuning
    SetBlockingOfNonTemporaryEvents(driver, true)
    SetPedKeepTask(driver, true)
    SetPedFleeAttributes(driver, 0, false)
    SetPedCanBeDraggedOut(driver, false)
    
    SetDriverAbility(driver, 1.0)
    SetDriverAggressiveness(driver, 1.0)
    
    if Config.GiveWeapon then
        GiveWeaponToPed(driver, joaatSafe(Config.WeaponName), 120, false, true)
    end
    
    -- Get the target ped
    local targetPed = GetPlayerPed(GetPlayerFromServerId(targetPlayerId))
    if not DoesEntityExist(targetPed) then
        targetPed = PlayerPedId() -- Fallback to self
    end
    
    -- DO THE CHASE
    TaskVehicleChase(driver, targetPed)
    SetDriveTaskDrivingStyle(driver, Config.DrivingStyle)
    SetDriveTaskCruiseSpeed(driver, levelConfig.ChaseCruiseSpeed)
    
    -- make them more willing to ram
    SetTaskVehicleChaseBehaviorFlag(driver, 1, true)
    SetTaskVehicleChaseBehaviorFlag(driver, 2, true)
    SetTaskVehicleChaseBehaviorFlag(driver, 4, true)
    
    table.insert(spawned, { veh = veh, ped = driver, targetId = targetPlayerId })
    
    SetModelAsNoLongerNeeded(vehHash)
    SetModelAsNoLongerNeeded(pedHash)
    
    log(('Level %d hunter spawned and chasing player %d'):format(level, targetPlayerId))
end

local function spawnPedestrianHunter(level, targetCoords, targetPlayerId)
    level = level or 1
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end
    
    local levelConfig = Config.Levels[level]
    if not levelConfig then
        log(('Invalid level: %d'):format(level))
        return
    end
    
    if not targetCoords then
        log('No target coordinates provided for pedestrian hunter')
        return
    end
    
    local pedHash = loadModel(levelConfig.DriverModel)
    if not pedHash then
        log(('Driver model failed to load: %s'):format(levelConfig.DriverModel))
        return
    end
    
    -- Calculate spawn position (30-60 meters away in a random direction)
    local spawnDistance = math.random(30, 60)
    local angle = math.random() * 2 * math.pi
    local offsetX = math.cos(angle) * spawnDistance
    local offsetY = math.sin(angle) * spawnDistance
    
    local spawnPos = vector3(
        targetCoords.x + offsetX,
        targetCoords.y + offsetY,
        targetCoords.z
    )
    
    -- Get ground Z
    local found, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
    if found then
        spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ)
    end
    
    local heading = math.deg(math.atan2(targetCoords.y - spawnPos.y, targetCoords.x - spawnPos.x))
    
    -- Create ped
    local hunter = CreatePed(4, pedHash, spawnPos.x, spawnPos.y, spawnPos.z, heading, true, true)
    if not DoesEntityExist(hunter) then
        log('CreatePed failed (hunter not created)')
        SetModelAsNoLongerNeeded(pedHash)
        return
    end
    
    makeNetworked(hunter)
    SetEntityAsMissionEntity(hunter, true, true)
    
    -- Setup hunter behavior
    SetBlockingOfNonTemporaryEvents(hunter, true)
    SetPedKeepTask(hunter, true)
    SetPedFleeAttributes(hunter, 0, false)
    SetPedCombatAttributes(hunter, 46, true)
    SetPedCombatAbility(hunter, 100)
    SetPedCombatMovement(hunter, 2) -- Offensive
    SetPedCombatRange(hunter, 2) -- Far
    
    if Config.GiveWeapon then
        GiveWeaponToPed(hunter, joaatSafe(Config.WeaponName), 250, false, true)
    end
    
    SetPedRelationshipGroupHash(hunter, joaat('GUARD'))
    
    -- Store hunter
    table.insert(pedestrianHunters, {
        ped = hunter,
        targetId = targetPlayerId,
        level = level
    })
    
    SetModelAsNoLongerNeeded(pedHash)
    
    log(('Level %d pedestrian hunter spawned'):format(level))
end

-- Update thread for pedestrian hunters
CreateThread(function()
    while true do
        Wait(1000)
        
        for i = #pedestrianHunters, 1, -1 do
            local hunter = pedestrianHunters[i]
            
            if not DoesEntityExist(hunter.ped) or IsEntityDead(hunter.ped) then
                table.remove(pedestrianHunters, i)
            else
                -- Get target player
                local targetPed = GetPlayerPed(GetPlayerFromServerId(hunter.targetId))
                
                if targetPed and DoesEntityExist(targetPed) then
                    local hunterPos = GetEntityCoords(hunter.ped)
                    local targetPos = GetEntityCoords(targetPed)
                    local distance = #(hunterPos - targetPos)
                    
                    -- If not in combat, chase the target
                    if not IsPedInCombat(hunter.ped, targetPed) then
                        if distance > 2.0 then
                            TaskGoToEntity(hunter.ped, targetPed, -1, 1.0, 2.0, 1073741824, 0)
                        else
                            TaskCombatPed(hunter.ped, targetPed, 0, 16)
                        end
                    end
                else
                    -- Target not found, wander
                    if not IsPedInCombat(hunter.ped, 0) then
                        TaskWanderStandard(hunter.ped, 10.0, 10)
                    end
                end
            end
        end
    end
end)

-- Update thread for vehicle hunters (keep them chasing correct target)
CreateThread(function()
    while true do
        Wait(2000)
        
        for i = #spawned, 1, -1 do
            local hunter = spawned[i]
            
            if not DoesEntityExist(hunter.veh) or not DoesEntityExist(hunter.ped) then
                table.remove(spawned, i)
            else
                local targetPed = GetPlayerPed(GetPlayerFromServerId(hunter.targetId))
                
                if targetPed and DoesEntityExist(targetPed) then
                    -- Ensure they're still chasing the correct target
                    if not IsPedInCombat(hunter.ped, targetPed) then
                        TaskVehicleChase(hunter.ped, targetPed)
                    end
                end
            end
        end
    end
end)

-- ============================================
-- GUARD ZONE SYSTEM
-- ============================================

local function spawnStaticGuard(zoneConfig, position, heading)
    local pedModel = getRandomFromTable(zoneConfig.pedModels)
    local weapon = getRandomFromTable(zoneConfig.weapons)
    
    if not pedModel or not weapon then return nil end
    
    local pedHash = loadModel(pedModel)
    if not pedHash then return nil end
    
    local guard = CreatePed(4, pedHash, position.x, position.y, position.z, heading or 0.0, true, true)
    if not DoesEntityExist(guard) then
        SetModelAsNoLongerNeeded(pedHash)
        return nil
    end
    
    makeNetworked(guard)
    SetEntityAsMissionEntity(guard, true, true)
    
    -- Setup guard
    SetPedArmour(guard, zoneConfig.armor or 0)
    SetEntityHealth(guard, zoneConfig.health or 200)
    SetPedAccuracy(guard, zoneConfig.accuracy or 50)
    
    GiveWeaponToPed(guard, joaatSafe(weapon), 250, false, true)
    SetPedDropsWeaponsWhenDead(guard, false)
    SetPedCanRagdoll(guard, true)
    
    SetPedFleeAttributes(guard, 0, false)
    SetPedCombatAttributes(guard, 46, true)
    SetPedCombatAttributes(guard, 0, false)
    SetPedCombatAbility(guard, 100)
    SetPedCombatMovement(guard, 3)
    SetPedCombatRange(guard, 2)
    SetPedSeeingRange(guard, Config.GuardDetectionRange)
    SetPedHearingRange(guard, Config.GuardDetectionRange)
    SetPedAlertness(guard, 3)
    
    SetPedRelationshipGroupHash(guard, joaat('GUARD'))
    SetBlockingOfNonTemporaryEvents(guard, true)
    
    if zoneConfig.patrolMode then
        TaskWanderInArea(guard, zoneConfig.center.x, zoneConfig.center.y, zoneConfig.center.z, zoneConfig.radius * 0.7, 1.0, 10.0)
    else
        TaskGuardCurrentPosition(guard, 15.0, 15.0, true)
    end
    
    SetModelAsNoLongerNeeded(pedHash)
    
    return guard
end

local function spawnGuardZone(zoneIndex)
    local zoneConfig = Config.GuardZones[zoneIndex]
    if not zoneConfig then return end
    
    -- Clear existing guards in this zone
    if guardZones[zoneIndex] then
        for _, guard in ipairs(guardZones[zoneIndex].guards) do
            safeDelete(guard)
        end
    end
    
    guardZones[zoneIndex] = {
        config = zoneConfig,
        guards = {},
        lastCheck = 0
    }
    
    if zoneConfig.positions then
        -- Exact-position placement
        for _, entry in ipairs(zoneConfig.positions) do
            local spawnPos = entry.pos
            if not zoneConfig.skipGroundCheck then
                local found, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
                if found then spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ) end
            end
            -- Allow per-entry weapon override via a temporary clone of zoneConfig
            local cfg = zoneConfig
            if entry.weapon then
                cfg = {}
                for k, v in pairs(zoneConfig) do cfg[k] = v end
                cfg.weapons = { entry.weapon }
            end
            local guard = spawnStaticGuard(cfg, spawnPos, entry.heading or math.random() * 360.0)
            if guard then
                table.insert(guardZones[zoneIndex].guards, guard)
            end
        end
    else
        -- Circular placement around center
        local angleStep = (2 * math.pi) / zoneConfig.guardCount
        local spawnRadius = zoneConfig.radius * 0.7
        
        for i = 1, zoneConfig.guardCount do
            local angle = angleStep * i
            local offsetX = math.cos(angle) * spawnRadius
            local offsetY = math.sin(angle) * spawnRadius
            
            local spawnPos = vector3(
                zoneConfig.center.x + offsetX,
                zoneConfig.center.y + offsetY,
                zoneConfig.center.z
            )
            
            local found, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
            if found then
                spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ)
            end
            
            local heading = math.deg(math.atan2(offsetY, offsetX)) + 180.0
            
            local guard = spawnStaticGuard(zoneConfig, spawnPos, heading)
            if guard then
                table.insert(guardZones[zoneIndex].guards, guard)
            end
        end
    end
    
    log(('Spawned %d guards in zone: %s'):format(#guardZones[zoneIndex].guards, zoneConfig.name))
end

local function checkGuardZoneThreat(zoneIndex)
    if not guardZones[zoneIndex] then return end
    if not guardZonesEnabled then return end
    
    local zone = guardZones[zoneIndex]
    
    -- Re-assign wandering for patrol mode guards that have finished their task
    if zone.config.patrolMode then
        for _, guard in ipairs(zone.guards) do
            if DoesEntityExist(guard) and not IsEntityDead(guard) and not IsPedInCombat(guard, 0) then
                local taskStatus = GetScriptTaskStatus(guard, joaat('SCRIPT_TASK_WANDER_IN_AREA'))
                if taskStatus == 7 then
                    TaskWanderInArea(guard, zone.config.center.x, zone.config.center.y, zone.config.center.z, zone.config.radius * 0.7, 1.0, 10.0)
                end
            end
        end
    end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    
    -- Check if player is in zone
    local distToZone = #(playerCoords - zone.config.center)
    if distToZone > zone.config.radius then return end
    
    -- Check access (cached)
    local zoneName = zone.config.name
    if zoneAccessCache[zoneName] == nil then
        if zone.config.requiredJob then
            TriggerServerEvent('prelude-npc:server:checkJobAccess', zoneName, zone.config.requiredJob)
        elseif zone.config.requiredItem then
            TriggerServerEvent('prelude-npc:server:checkItemAccess', zoneName, zone.config.requiredItem)
        else
            zoneAccessCache[zoneName] = false -- No access check = always attack
        end
        return
    end
    
    -- If player has access (has the item), don't attack
    if zoneAccessCache[zoneName] == true then return end
    
    -- Attack player if they don't have access
    for _, guard in ipairs(zone.guards) do
        if DoesEntityExist(guard) and not IsEntityDead(guard) then
            local guardCoords = GetEntityCoords(guard)
            local distToPlayer = #(guardCoords - playerCoords)
            
            if distToPlayer <= Config.GuardAttackRange then
                if not IsPedInCombat(guard, playerPed) then
                    TaskCombatPed(guard, playerPed, 0, 16)
                end
            end
        end
    end
end

-- ============================================
-- AGGRESSIVE NPC SYSTEM
-- ============================================
-- Melee-only street NPCs that wander zones and attack players on sight.
-- No entry warnings. Always hostile. Auto-spawned on resource start.

local function spawnAggressiveNPC(zoneConfig, position, heading)
    local pedModel = getRandomFromTable(zoneConfig.pedModels)
    local weapon = getRandomFromTable(zoneConfig.weapons)

    if not pedModel or not weapon then return nil end

    local pedHash = loadModel(pedModel)
    if not pedHash then return nil end

    local npc = CreatePed(4, pedHash, position.x, position.y, position.z, heading or 0.0, true, true)
    if not DoesEntityExist(npc) then
        SetModelAsNoLongerNeeded(pedHash)
        return nil
    end

    makeNetworked(npc)
    SetEntityAsMissionEntity(npc, true, true)

    SetEntityHealth(npc, zoneConfig.health or 150)
    SetPedArmour(npc, zoneConfig.armor or 0)
    SetPedAccuracy(npc, zoneConfig.accuracy or 40)

    -- Melee weapon only
    GiveWeaponToPed(npc, joaatSafe(weapon), 1, false, true)
    SetCurrentPedWeapon(npc, joaatSafe(weapon), true)
    SetPedDropsWeaponsWhenDead(npc, false)
    SetPedCanRagdoll(npc, true)

    -- Melee-focused combat settings
    SetPedFleeAttributes(npc, 0, false)
    SetPedCombatAttributes(npc, 46, true)  -- Always fight
    SetPedCombatAbility(npc, 50)
    SetPedCombatMovement(npc, 3)           -- Aggressive
    SetPedCombatRange(npc, 0)              -- Close/melee range only
    SetPedSeeingRange(npc, zoneConfig.attackRange or 18.0)
    SetPedHearingRange(npc, zoneConfig.attackRange or 18.0)
    SetPedAlertness(npc, 2)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetPedKeepTask(npc, true)

    SetPedRelationshipGroupHash(npc, joaat('AGGRESSIVE_NPC'))

    -- Wander within the zone radius
    TaskWanderInArea(npc, position.x, position.y, position.z, zoneConfig.radius * 0.7, 1.0, 10.0)

    SetModelAsNoLongerNeeded(pedHash)
    return npc
end

local function spawnAggressiveZone(zoneIndex)
    local zoneConfig = Config.AggressiveNPCZones[zoneIndex]
    if not zoneConfig then return end

    -- Clear existing NPCs in the zone first
    if aggressiveNPCZones[zoneIndex] then
        for _, npcData in ipairs(aggressiveNPCZones[zoneIndex].npcs) do
            safeDelete(npcData.ped)
        end
    end

    aggressiveNPCZones[zoneIndex] = { config = zoneConfig, npcs = {} }

    local angleStep = (2 * math.pi) / zoneConfig.npcCount
    local spawnRadius = zoneConfig.radius * 0.6

    for i = 1, zoneConfig.npcCount do
        local angle = (angleStep * i) + (math.random() * 0.5 - 0.25)
        local dist = spawnRadius * (0.4 + math.random() * 0.6)
        local spawnPos = vector3(
            zoneConfig.center.x + math.cos(angle) * dist,
            zoneConfig.center.y + math.sin(angle) * dist,
            zoneConfig.center.z
        )

        local found, groundZ = GetGroundZFor_3dCoord(spawnPos.x, spawnPos.y, spawnPos.z + 50.0, false)
        if found then spawnPos = vector3(spawnPos.x, spawnPos.y, groundZ) end

        local npc = spawnAggressiveNPC(zoneConfig, spawnPos, math.random() * 360.0)
        if npc then
            table.insert(aggressiveNPCZones[zoneIndex].npcs, { ped = npc })
        end
        Wait(50)
    end

    log(('Spawned %d aggressive NPCs in zone: %s'):format(#aggressiveNPCZones[zoneIndex].npcs, zoneConfig.name))
end

local function clearAllAggressiveNPCZones()
    for zoneIndex, zone in pairs(aggressiveNPCZones) do
        for _, npcData in ipairs(zone.npcs) do
            safeDelete(npcData.ped)
        end
        aggressiveNPCZones[zoneIndex] = nil
    end
    log('All aggressive NPC zones cleared')
end

-- ============================================
-- PATROL SYSTEM
-- ============================================

local function spawnPatrolVehicle(routeIndex)
    local route = Config.PatrolRoutes[routeIndex]
    if not route then return end

    -- Inner helper: create one vehicle+driver at a given vector4 point
    local function spawnVehicleAtPoint(sp)
        local vehHash = loadModel(route.vehicleModel)
        if not vehHash then return nil end
        local pedHash = loadModel(route.pedModel)
        if not pedHash then
            SetModelAsNoLongerNeeded(vehHash)
            return nil
        end
        local veh = CreateVehicle(vehHash, sp.x, sp.y, sp.z, sp.w, true, true)
        if not DoesEntityExist(veh) then
            SetModelAsNoLongerNeeded(vehHash)
            SetModelAsNoLongerNeeded(pedHash)
            return nil
        end
        makeNetworked(veh)
        SetEntityAsMissionEntity(veh, true, true)
        SetVehicleOnGroundProperly(veh)
        SetVehicleEngineOn(veh, true, true, false)
        local driver = CreatePed(4, pedHash, sp.x, sp.y, sp.z, sp.w, true, true)
        if not DoesEntityExist(driver) then
            safeDelete(veh)
            SetModelAsNoLongerNeeded(vehHash)
            SetModelAsNoLongerNeeded(pedHash)
            return nil
        end
        makeNetworked(driver)
        SetEntityAsMissionEntity(driver, true, true)
        TaskWarpPedIntoVehicle(driver, veh, -1)
        Wait(100)
        SetBlockingOfNonTemporaryEvents(driver, true)
        SetPedKeepTask(driver, true)
        SetPedFleeAttributes(driver, 0, false)
        SetPedCombatAttributes(driver, 46, true)
        SetDriverAbility(driver, 1.0)
        -- Use neutral relationship group so native AI never auto-attacks the player.
        -- All combat is managed exclusively by doCombatCheck.
        SetPedRelationshipGroupHash(driver, joaat('PATROL_DRIVER'))
        if route.weapon then
            GiveWeaponToPed(driver, joaatSafe(route.weapon), 250, false, true)
        end
        SetModelAsNoLongerNeeded(vehHash)
        SetModelAsNoLongerNeeded(pedHash)
        return { vehicle = veh, driver = driver }
    end

    if route.spawnPoints and #route.spawnPoints > 0 then
        -- Multi-vehicle: one vehicle per spawn point, each wanders freely within radius
        local entry = { vehicles = {}, route = route }
        for _, sp in ipairs(route.spawnPoints) do
            local result = spawnVehicleAtPoint(sp)
            if result then
                TaskVehicleDriveWander(result.driver, result.vehicle, route.speed or 25.0, 786603)
                table.insert(entry.vehicles, result)
            end
            Wait(200)
        end
        patrols[routeIndex] = entry
        log(('Patrol spawned: %s (%d vehicles)'):format(route.name, #entry.vehicles))
        return
    end

    -- Single-vehicle fallback (center-based wander or waypoint-based)
    if not route.center and (not route.waypoints or #route.waypoints == 0) then return end
    local spawnX, spawnY, spawnZ, spawnH
    if route.center then
        local angle = math.random() * 2 * math.pi
        spawnX = route.center.x + math.cos(angle) * (route.radius * 0.5)
        spawnY = route.center.y + math.sin(angle) * (route.radius * 0.5)
        spawnZ = route.center.z
        spawnH = math.deg(angle)
        local found, groundZ = GetGroundZFor_3dCoord(spawnX, spawnY, spawnZ + 50.0, false)
        if found then spawnZ = groundZ end
    else
        local sp = route.waypoints[1]
        spawnX, spawnY, spawnZ, spawnH = sp.x, sp.y, sp.z, sp.w
    end
    local result = spawnVehicleAtPoint({ x = spawnX, y = spawnY, z = spawnZ, w = spawnH })
    if not result then return end
    if route.center then
        TaskVehicleDriveWander(result.driver, result.vehicle, route.speed or 25.0, 786603)
    end
    patrols[routeIndex] = {
        vehicle = result.vehicle,
        driver = result.driver,
        route = route,
        currentWaypoint = 1
    }
    log(('Patrol spawned: %s'):format(route.name))
end

local function updatePatrols()
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)

    local function doCombatCheck(veh, driver, route)
        local distToPlayer = #(GetEntityCoords(veh) - playerCoords)
        if distToPlayer > Config.GuardAttackRange then return end

        -- Resolve requiredJob: direct on route first, then fall back to linked guard zone
        local requiredJob = route.requiredJob
        if not requiredJob and route.guardZone then
            for _, zone in ipairs(Config.GuardZones) do
                if zone.name == route.guardZone then
                    requiredJob = zone.requiredJob
                    break
                end
            end
        end

        -- Build a cache key for this patrol's access
        local cacheKey = route.name

        if requiredJob then
            if zoneAccessCache[cacheKey] == nil then
                -- Fire check and wait for response — do NOT attack yet
                TriggerServerEvent('prelude-npc:server:checkJobAccess', cacheKey, requiredJob)
                return
            end
            local hasAccess = zoneAccessCache[cacheKey]
            if hasAccess then
                -- Player is allowed — stop any accidental combat
                if IsPedInCombat(driver, playerPed) then
                    ClearPedTasks(driver)
                    TaskVehicleDriveWander(driver, veh, route.speed or 25.0, 786603)
                end
                return
            end
            -- Access denied — attack
            if not IsPedInCombat(driver, playerPed) then
                ClearPedTasks(driver)
                TaskLeaveVehicle(driver, veh, 0)
                TaskCombatPed(driver, playerPed, 0, 16)
            end
        end
        -- No requiredJob at all: do nothing (never attack)
    end

    for routeIndex, patrol in pairs(patrols) do
        if patrol.vehicles then
            -- Multi-vehicle patrol (spawnPoints-based)
            for i = #patrol.vehicles, 1, -1 do
                local entry = patrol.vehicles[i]
                if not DoesEntityExist(entry.vehicle) or not DoesEntityExist(entry.driver) then
                    safeDelete(entry.vehicle)
                    safeDelete(entry.driver)
                    table.remove(patrol.vehicles, i)
                else
                    if patrol.route.center then
                        local vehCoords = GetEntityCoords(entry.vehicle)
                        local distToCenter = #(vehCoords - patrol.route.center)
                        if distToCenter > patrol.route.radius then
                            local c = patrol.route.center
                            TaskVehicleDriveToCoord(entry.driver, entry.vehicle, c.x, c.y, c.z,
                                patrol.route.speed or 25.0, 0, GetEntityModel(entry.vehicle), 786603, 5.0, true)
                        else
                            local status = GetScriptTaskStatus(entry.driver, joaat('SCRIPT_TASK_VEHICLE_DRIVE_WANDER'))
                            if status == 7 then
                                TaskVehicleDriveWander(entry.driver, entry.vehicle, patrol.route.speed or 25.0, 786603)
                            end
                        end
                    end
                    doCombatCheck(entry.vehicle, entry.driver, patrol.route)
                end
            end
            if #patrol.vehicles == 0 then
                patrols[routeIndex] = nil
            end
        elseif not DoesEntityExist(patrol.vehicle) or not DoesEntityExist(patrol.driver) then
            patrols[routeIndex] = nil
        else
            local vehCoords = GetEntityCoords(patrol.vehicle)
            if patrol.route.center then
                local distToCenter = #(vehCoords - patrol.route.center)
                if distToCenter > patrol.route.radius then
                    local c = patrol.route.center
                    TaskVehicleDriveToCoord(patrol.driver, patrol.vehicle, c.x, c.y, c.z,
                        patrol.route.speed or 25.0, 0, GetEntityModel(patrol.vehicle), 786603, 5.0, true)
                else
                    local status = GetScriptTaskStatus(patrol.driver, joaat('SCRIPT_TASK_VEHICLE_DRIVE_WANDER'))
                    if status == 7 then
                        TaskVehicleDriveWander(patrol.driver, patrol.vehicle, patrol.route.speed or 25.0, 786603)
                    end
                end
            else
                local waypoint = patrol.route.waypoints[patrol.currentWaypoint]
                local distToWaypoint = #(vehCoords - vector3(waypoint.x, waypoint.y, waypoint.z))
                if distToWaypoint < 15.0 then
                    patrol.currentWaypoint = patrol.currentWaypoint + 1
                    if patrol.currentWaypoint > #patrol.route.waypoints then
                        patrol.currentWaypoint = 1
                    end
                    waypoint = patrol.route.waypoints[patrol.currentWaypoint]
                    TaskVehicleDriveToCoord(patrol.driver, patrol.vehicle, waypoint.x, waypoint.y, waypoint.z,
                        patrol.route.speed or 25.0, 0, GetEntityModel(patrol.vehicle), 786603, 1.0, true)
                end
            end
            doCombatCheck(patrol.vehicle, patrol.driver, patrol.route)
        end
    end
end

-- ============================================
-- BODYGUARD SYSTEM
-- ============================================

local function spawnBodyguard(tier, guardId)
    local tierConfig = Config.BodyguardTiers[tier]
    if not tierConfig then return end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local playerHeading = GetEntityHeading(playerPed)
    
    local pedModel = getRandomFromTable(tierConfig.pedModels)
    local weapon = getRandomFromTable(tierConfig.weapons)
    
    if not pedModel or not weapon then return end
    
    local pedHash = loadModel(pedModel)
    if not pedHash then return end
    
    -- Spawn near player
    local spawnOffset = vector3(
        math.cos(math.rad(playerHeading + (guardId * 60))) * 2.0,
        math.sin(math.rad(playerHeading + (guardId * 60))) * 2.0,
        0.0
    )
    
    local spawnPos = playerCoords + spawnOffset
    
    local bodyguard = CreatePed(4, pedHash, spawnPos.x, spawnPos.y, spawnPos.z, playerHeading, true, true)
    if not DoesEntityExist(bodyguard) then
        SetModelAsNoLongerNeeded(pedHash)
        return
    end
    
    makeNetworked(bodyguard)
    SetEntityAsMissionEntity(bodyguard, true, true)
    
    -- Setup bodyguard
    SetPedArmour(bodyguard, tierConfig.armor or 0)
    SetEntityHealth(bodyguard, tierConfig.health or 200)
    SetPedAccuracy(bodyguard, tierConfig.accuracy or 50)
    
    GiveWeaponToPed(bodyguard, joaatSafe(weapon), 250, false, true)
    SetCurrentPedWeapon(bodyguard, joaatSafe(weapon), true)
    SetPedDropsWeaponsWhenDead(bodyguard, false)
    SetPedCanRagdoll(bodyguard, true)
    
    -- Combat attributes for aggressive engagement
    SetPedFleeAttributes(bodyguard, 0, false)
    SetPedCombatAttributes(bodyguard, 46, true) -- Always fight, never surrender
    SetPedCombatAttributes(bodyguard, 5, true) -- Can attack friendly (for defense)
    SetPedCombatAttributes(bodyguard, 2, true) -- Can do drivebys
    SetPedCombatAttributes(bodyguard, 1, true) -- Can use cover
    SetPedCombatAttributes(bodyguard, 3, true) -- Can leave vehicle
    SetPedCombatAbility(bodyguard, 100)
    SetPedCombatMovement(bodyguard, 2)
    SetPedCombatRange(bodyguard, 2)
    SetPedSeeingRange(bodyguard, 100.0)
    SetPedHearingRange(bodyguard, 100.0)
    SetPedAlertness(bodyguard, 3) -- Maximum alertness
    
    -- Ensure they're ready to fight
    SetCanAttackFriendly(bodyguard, true, true)
    SetPedCanAttackFriendly(bodyguard, true, true)
    
    SetPedRelationshipGroupHash(bodyguard, joaat('BODYGUARD'))
    SetPedAsGroupMember(bodyguard, GetPedGroupIndex(playerPed))
    SetPedNeverLeavesGroup(bodyguard, true)
    
    SetPedKeepTask(bodyguard, true)
    TaskFollowToOffsetOfEntity(bodyguard, playerPed, 0.0, -Config.BodyguardFollowDistance, 0.0, 5.0, -1, 2.5, true)
    
    SetModelAsNoLongerNeeded(pedHash)
    
    table.insert(bodyguards, {
        ped = bodyguard,
        tier = tier,
        id = guardId
    })
    
    log(('Bodyguard %d (Tier %d) spawned'):format(guardId, tier))
end

local function updateBodyguards()
    local playerPed = PlayerPedId()
    
    for i = #bodyguards, 1, -1 do
        local bg = bodyguards[i]
        
        if not DoesEntityExist(bg.ped) or IsEntityDead(bg.ped) then
            table.remove(bodyguards, i)
        else
            -- Make sure they're following
            if not IsPedInCombat(bg.ped, playerPed) then
                local currentTask = GetScriptTaskStatus(bg.ped, joaat("SCRIPT_TASK_FOLLOW_TO_OFFSET_OF_ENTITY"))
                if currentTask ~= 1 and currentTask ~= 0 then
                    TaskFollowToOffsetOfEntity(bg.ped, playerPed, 0.0, -Config.BodyguardFollowDistance, 0.0, 5.0, -1, 2.5, true)
                end
            end
            
            -- Check for nearby threats
            local nearbyPeds = GetNearbyPeds(bg.ped, Config.GuardDetectionRange)
            for _, targetPed in ipairs(nearbyPeds) do
                if DoesEntityExist(targetPed) and not IsEntityDead(targetPed) then
                    if IsPedInCombat(targetPed, playerPed) then
                        if not IsPedInCombat(bg.ped, targetPed) then
                            TaskCombatPed(bg.ped, targetPed, 0, 16)
                        end
                    end
                end
            end
        end
    end
end

function GetNearbyPeds(ped, radius)
    local peds = {}
    local pedCoords = GetEntityCoords(ped)
    local handle, targetPed = FindFirstPed()
    local success
    
    repeat
        local targetCoords = GetEntityCoords(targetPed)
        if targetPed ~= ped and #(pedCoords - targetCoords) <= radius then
            table.insert(peds, targetPed)
        end
        success, targetPed = FindNextPed(handle)
    until not success
    
    EndFindPed(handle)
    return peds
end

local function dismissAllBodyguards()
    for _, bg in ipairs(bodyguards) do
        safeDelete(bg.ped)
    end
    bodyguards = {}
    log('All bodyguards dismissed')
end

-- ============================================
-- BODYGUARD HIRE INTERACTIONS
-- ============================================

local function showBodyguardMenu()
    local menuOptions = {}
    
    for tier, config in ipairs(Config.BodyguardTiers) do
        table.insert(menuOptions, {
            header = config.name,
            txt = string.format('Price: $%d | Duration: %d min | Health: %d | Armor: %d', 
                config.price, config.duration, config.health, config.armor),
            params = {
                isServer = true,
                event = 'prelude-npc:server:hireBodyguard',
                args = { tier = tier }
            }
        })
    end
    
    table.insert(menuOptions, {
        header = 'Dismiss All Bodyguards',
        txt = 'Send all your bodyguards away',
        params = {
            isServer = true,
            event = 'prelude-npc:server:dismissBodyguards'
        }
    })
    
    exports['qb-menu']:openMenu(menuOptions)
end

CreateThread(function()
    for _, location in ipairs(Config.BodyguardLocations) do
        exports['qb-target']:AddCircleZone(location.name, location.coords, location.radius, {
            name = location.name,
            debugPoly = false,
        }, {
            options = {
                {
                    type = "client",
                    event = "prelude-npc:client:openBodyguardMenu",
                    icon = "fas fa-user-shield",
                    label = "Hire Bodyguard",
                }
            },
            distance = 2.5
        })
    end
end)

RegisterNetEvent('prelude-npc:client:openBodyguardMenu', function()
    showBodyguardMenu()
end)

RegisterNetEvent('prelude-npc:client:spawnBodyguard', function(tier, guardId)
    spawnBodyguard(tier, guardId)
end)

RegisterNetEvent('prelude-npc:client:dismissAllBodyguards', function()
    dismissAllBodyguards()
end)

RegisterNetEvent('prelude-npc:client:zoneAccessResult', function(zoneName, hasAccess)
    zoneAccessCache[zoneName] = hasAccess
end)

RegisterNetEvent('prelude-npc:client:spawnHunterAtCoords', function(coords, targetId, level, count, hunterType)
    if hunterType == 'pedestrian' then
        for i = 1, count do
            spawnPedestrianHunter(level, coords, targetId)
            Wait(150)
        end
    else
        -- For vehicle hunters, we need to modify spawnHunter to accept target coords
        for i = 1, count do
            spawnHunterAtCoords(level, coords, targetId)
            Wait(150)
        end
    end
end)

-- ============================================
-- ADMIN COMMANDS (Client Events)
-- ============================================

RegisterNetEvent('prelude-npc:client:adminSpawnGuards', function(zoneArg)
    local zoneIndex = tonumber(zoneArg)
    
    if not zoneIndex then
        -- Find by name
        for i, zone in ipairs(Config.GuardZones) do
            if zone.name:lower():find(zoneArg:lower()) then
                zoneIndex = i
                break
            end
        end
    end
    
    if zoneIndex and Config.GuardZones[zoneIndex] then
        spawnGuardZone(zoneIndex)
    end
end)

RegisterNetEvent('prelude-npc:client:adminClearGuards', function(zoneArg)
    if zoneArg == 'all' then
        for zoneIndex, zone in pairs(guardZones) do
            for _, guard in ipairs(zone.guards) do
                safeDelete(guard)
            end
            guardZones[zoneIndex] = nil
        end
        log('All guard zones cleared')
    else
        local zoneIndex = tonumber(zoneArg)
        
        if not zoneIndex then
            for i, zone in ipairs(Config.GuardZones) do
                if zone.name:lower():find(zoneArg:lower()) then
                    zoneIndex = i
                    break
                end
            end
        end
        
        if zoneIndex and guardZones[zoneIndex] then
            for _, guard in ipairs(guardZones[zoneIndex].guards) do
                safeDelete(guard)
            end
            guardZones[zoneIndex] = nil
            log(('Guard zone %d cleared'):format(zoneIndex))
        end
    end
end)

RegisterNetEvent('prelude-npc:client:adminSpawnPatrol', function(routeArg)
    local routeIndex = tonumber(routeArg)
    
    if not routeIndex then
        for i, route in ipairs(Config.PatrolRoutes) do
            if route.name:lower():find(routeArg:lower()) then
                routeIndex = i
                break
            end
        end
    end
    
    if routeIndex and Config.PatrolRoutes[routeIndex] then
        spawnPatrolVehicle(routeIndex)
    end
end)

RegisterNetEvent('prelude-npc:client:adminClearPatrols', function()
    for _, patrol in pairs(patrols) do
        if patrol.vehicles then
            for _, entry in ipairs(patrol.vehicles) do
                safeDelete(entry.driver)
                safeDelete(entry.vehicle)
            end
        else
            safeDelete(patrol.driver)
            safeDelete(patrol.vehicle)
        end
    end
    patrols = {}
    log('All patrols cleared')
end)

RegisterNetEvent('prelude-npc:client:adminClearAggressiveZones', function()
    clearAllAggressiveNPCZones()
end)

RegisterNetEvent('prelude-npc:client:toggleGuardZones', function()
    guardZonesEnabled = not guardZonesEnabled
    log(('Guard zones %s'):format(guardZonesEnabled and 'enabled' or 'disabled'))
end)

-- ============================================
-- MAIN THREADS
-- ============================================

-- Guard zone monitoring thread
CreateThread(function()
    while true do
        Wait(Config.CheckInterval)
        
        -- Proximity-based spawn: spawn any auto-spawn zone the player is near that hasn't spawned yet
        if Config.AutoSpawnZones then
            local playerCoords = GetEntityCoords(PlayerPedId())
            for i, zoneConfig in ipairs(Config.GuardZones) do
                if not guardZones[i] then
                    for _, zoneName in ipairs(Config.AutoSpawnZones) do
                        if zoneConfig.name == zoneName then
                            local dist = #(playerCoords - zoneConfig.center)
                            if dist <= (zoneConfig.radius + 150.0) then
                                spawnGuardZone(i)
                            end
                            break
                        end
                    end
                end
            end
        end
        
        for zoneIndex, _ in pairs(guardZones) do
            checkGuardZoneThreat(zoneIndex)
        end
    end
end)

-- Patrol update thread
CreateThread(function()
    while true do
        Wait(2000)
        
        -- Proximity-based spawn: spawn any auto-spawn patrol route the player is near
        if Config.AutoSpawnPatrols then
            local playerCoords = GetEntityCoords(PlayerPedId())
            for i, route in ipairs(Config.PatrolRoutes) do
                if not patrols[i] then
                    for _, routeName in ipairs(Config.AutoSpawnPatrols) do
                        if route.name == routeName then
                            -- Determine reference point for proximity check
                            local refPoint
                            if route.center then
                                refPoint = route.center
                            elseif route.spawnPoints and route.spawnPoints[1] then
                                local sp = route.spawnPoints[1]
                                refPoint = vector3(sp.x, sp.y, sp.z)
                            elseif route.waypoints and route.waypoints[1] then
                                local wp = route.waypoints[1]
                                refPoint = vector3(wp.x, wp.y, wp.z)
                            end
                            if refPoint and #(playerCoords - refPoint) <= 300.0 then
                                spawnPatrolVehicle(i)
                            end
                            break
                        end
                    end
                end
            end
        end
        
        updatePatrols()
    end
end)

-- Bodyguard update thread
CreateThread(function()
    while true do
        Wait(1000)
        if #bodyguards > 0 then
            updateBodyguards()
        end
    end
end)

-- Aggressive NPC update thread
-- Checks player proximity and triggers melee attacks; resumes wandering when player leaves
CreateThread(function()
    while true do
        Wait(500)
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)

        for zoneIndex, zone in pairs(aggressiveNPCZones) do
            for i = #zone.npcs, 1, -1 do
                local npcData = zone.npcs[i]

                if not DoesEntityExist(npcData.ped) or IsEntityDead(npcData.ped) then
                    table.remove(zone.npcs, i)
                else
                    local npcCoords = GetEntityCoords(npcData.ped)
                    local distToPlayer = #(npcCoords - playerCoords)
                    local attackRange = zone.config.attackRange or 18.0

                    if distToPlayer <= attackRange then
                        if not IsPedInCombat(npcData.ped, playerPed) then
                            TaskCombatPed(npcData.ped, playerPed, 0, 16)
                        end
                    elseif not IsPedInCombat(npcData.ped, 0) then
                        -- Player left range; re-assign wander task if completed
                        local taskStatus = GetScriptTaskStatus(npcData.ped, joaat('SCRIPT_TASK_WANDER_IN_AREA'))
                        if taskStatus == 7 then
                            TaskWanderInArea(npcData.ped, zone.config.center.x, zone.config.center.y, zone.config.center.z, zone.config.radius * 0.7, 1.0, 10.0)
                        end
                    end
                end
            end
        end
    end
end)

-- Relationship setup
CreateThread(function()
    -- Guard relationship group
    AddRelationshipGroup('GUARD')
    SetRelationshipBetweenGroups(5, joaat('GUARD'), joaat('PLAYER'))
    SetRelationshipBetweenGroups(5, joaat('PLAYER'), joaat('GUARD'))
    
    -- Bodyguard relationship group
    AddRelationshipGroup('BODYGUARD')
    SetRelationshipBetweenGroups(0, joaat('BODYGUARD'), joaat('PLAYER'))
    SetRelationshipBetweenGroups(0, joaat('PLAYER'), joaat('BODYGUARD'))
    SetRelationshipBetweenGroups(5, joaat('BODYGUARD'), joaat('GUARD'))
    SetRelationshipBetweenGroups(5, joaat('GUARD'), joaat('BODYGUARD'))

    -- Aggressive NPC relationship group (always hostile to player)
    AddRelationshipGroup('AGGRESSIVE_NPC')
    SetRelationshipBetweenGroups(5, joaat('AGGRESSIVE_NPC'), joaat('PLAYER'))
    SetRelationshipBetweenGroups(5, joaat('PLAYER'), joaat('AGGRESSIVE_NPC'))
    SetRelationshipBetweenGroups(0, joaat('AGGRESSIVE_NPC'), joaat('AGGRESSIVE_NPC'))

    -- Patrol vehicle driver group: NEUTRAL to player so native AI never auto-attacks.
    -- doCombatCheck handles all combat decisions for patrol drivers.
    AddRelationshipGroup('PATROL_DRIVER')
    SetRelationshipBetweenGroups(3, joaat('PATROL_DRIVER'), joaat('PLAYER'))
    SetRelationshipBetweenGroups(3, joaat('PLAYER'), joaat('PATROL_DRIVER'))
end)

-- Auto-spawn guards and patrols on resource start
CreateThread(function()
    Wait(2000) -- Give time for resource to fully load
    
    -- Auto-spawn configured guard zones
    if Config.AutoSpawnZones then
        for _, zoneName in ipairs(Config.AutoSpawnZones) do
            for i, zone in ipairs(Config.GuardZones) do
                if zone.name == zoneName then
                    spawnGuardZone(i)
                    log(('Auto-spawned guard zone: %s'):format(zoneName))
                    Wait(500)
                    break
                end
            end
        end
    end
    
    -- Auto-spawn configured patrol routes
    -- Pre-warm the job-access cache BEFORE vehicles spawn so drivers never
    -- see a nil cache and accidentally start combat on first spawn.
    if Config.AutoSpawnPatrols then
        for _, routeName in ipairs(Config.AutoSpawnPatrols) do
            for i, route in ipairs(Config.PatrolRoutes) do
                if route.name == routeName then
                    if route.requiredJob then
                        TriggerServerEvent('prelude-npc:server:checkJobAccess', route.name, route.requiredJob)
                        Wait(600) -- wait for server round-trip to populate cache
                    end
                    spawnPatrolVehicle(i)
                    log(('Auto-spawned patrol route: %s'):format(routeName))
                    Wait(500)
                    break
                end
            end
        end
    end

    -- Auto-spawn all aggressive NPC zones
    if Config.AutoSpawnAggressiveZones and Config.AggressiveNPCZones then
        for i = 1, #Config.AggressiveNPCZones do
            spawnAggressiveZone(i)
            log(('Auto-spawned aggressive zone: %s'):format(Config.AggressiveNPCZones[i].name))
            Wait(300)
        end
    end
end)

-- ============================================
-- COMMANDS (Hunter system)
-- ============================================


RegisterCommand('chaseme', function(_, args)
    local level = tonumber(args[1]) or 1
    local count = tonumber(args[2]) or 1
    
    if level < 1 then level = 1 end
    if level > 5 then level = 5 end
    if count < 1 then count = 1 end
    if count > 10 then count = 10 end
    
    log(('Spawning %d level %d hunter(s)'):format(count, level))
    
    for _ = 1, count do
        spawnHunter(level)
        Wait(150)
    end
end, false)

RegisterCommand('chaseoff', function()
    cleanupHunters()
    log('Hunters removed.')
    QBCore.Functions.Notify('Hunters removed.', 'success')
end, false)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(res)
    if res == GetCurrentResourceName() then
        cleanupHunters()
        
        -- Clean up guard zones
        for _, zone in pairs(guardZones) do
            for _, guard in ipairs(zone.guards) do
                safeDelete(guard)
            end
        end
        
        -- Clean up patrols
        for _, patrol in pairs(patrols) do
            if patrol.vehicles then
                for _, entry in ipairs(patrol.vehicles) do
                    safeDelete(entry.driver)
                    safeDelete(entry.vehicle)
                end
            else
                safeDelete(patrol.driver)
                safeDelete(patrol.vehicle)
            end
        end
        
        -- Clean up bodyguards
        dismissAllBodyguards()

        -- Clean up aggressive NPCs
        clearAllAggressiveNPCZones()

        -- Close UI
        SetNuiFocus(false, false)
        SendNUIMessage({ action = 'closeTablet' })
    end
end)

-- ============================================
-- NUI CONTROL PANEL
-- ============================================

local tabletOpen = false

local function prepareUIData()
    -- Prepare guard zones data
    local zonesData = {}
    for i, zone in ipairs(Config.GuardZones) do
        table.insert(zonesData, {
            name = zone.name,
            guardCount = zone.guardCount,
            radius = zone.radius,
            requiredItem = zone.requiredItem,
            health = zone.health,
            armor = zone.armor
        })
    end
    
    -- Prepare patrol routes data
    local routesData = {}
    for i, route in ipairs(Config.PatrolRoutes) do
        table.insert(routesData, {
            name = route.name,
            vehicleModel = route.vehicleModel,
            speed = route.speed,
            waypointCount = #route.waypoints,
            weapon = route.weapon or 'None'
        })
    end
    
    -- Prepare bodyguard tiers data
    local tiersData = {}
    for tier, config in ipairs(Config.BodyguardTiers) do
        table.insert(tiersData, {
            name = config.name,
            price = config.price,
            duration = config.duration,
            health = config.health,
            armor = config.armor,
            accuracy = config.accuracy
        })
    end
    
    -- Prepare scenarios/templates data
    local scenariosData = {}
    if Config.ZoneTemplates then
        for _, template in ipairs(Config.ZoneTemplates) do
            table.insert(scenariosData, {
                name = template.name,
                description = template.description,
                icon = template.icon,
                zones = template.zones,
                patrols = template.patrols or {}
            })
        end
    end
    
    -- Prepare aggressive NPC zones data
    local aggressiveZonesUIData = {}
    for i, zone in ipairs(Config.AggressiveNPCZones or {}) do
        table.insert(aggressiveZonesUIData, {
            name = zone.name,
            npcCount = zone.npcCount,
            radius = zone.radius,
            attackRange = zone.attackRange or 18.0,
            health = zone.health,
            armor = zone.armor,
            accuracy = zone.accuracy,
            active = aggressiveNPCZones[i] ~= nil
        })
    end

    return {
        guardZones = zonesData,
        patrolRoutes = routesData,
        bodyguardTiers = tiersData,
        scenarios = scenariosData,
        aggressiveZones = aggressiveZonesUIData
    }
end

local function openControlPanel()
    if tabletOpen then return end
    
    tabletOpen = true
    local data = prepareUIData()
    
    SetNuiFocus(true, true)
    SendNUIMessage({
        action = 'openTablet',
        data = data
    })
end

local function closeControlPanel()
    if not tabletOpen then return end
    
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeTablet' })
end

-- NUI Callbacks
RegisterNUICallback('closeUI', function(data, cb)
    closeControlPanel()
    cb('ok')
end)

RegisterNUICallback('toggleGuardZones', function(data, cb)
    guardZonesEnabled = data.enabled
    QBCore.Functions.Notify(('Guard zones %s'):format(guardZonesEnabled and 'enabled' or 'disabled'), 'success')
    cb('ok')
end)

RegisterNUICallback('spawnGuards', function(data, cb)
    local zoneId = data.zoneId
    if zoneId and Config.GuardZones[zoneId] then
        spawnGuardZone(zoneId)
        QBCore.Functions.Notify(('Spawning guards in zone: %s'):format(Config.GuardZones[zoneId].name), 'success')
    end
    cb('ok')
end)

RegisterNUICallback('clearGuards', function(data, cb)
    local zoneId = data.zoneId
    if zoneId and guardZones[zoneId] then
        for _, guard in ipairs(guardZones[zoneId].guards) do
            safeDelete(guard)
        end
        guardZones[zoneId] = nil
        QBCore.Functions.Notify(('Cleared guards in zone: %s'):format(Config.GuardZones[zoneId].name), 'success')
    end
    cb('ok')
end)

RegisterNUICallback('spawnPatrol', function(data, cb)
    local routeId = data.routeId
    if routeId and Config.PatrolRoutes[routeId] then
        spawnPatrolVehicle(routeId)
        QBCore.Functions.Notify(('Spawning patrol: %s'):format(Config.PatrolRoutes[routeId].name), 'success')
    end
    cb('ok')
end)

RegisterNUICallback('clearAllPatrols', function(data, cb)
    for _, patrol in pairs(patrols) do
        if patrol.vehicles then
            for _, entry in ipairs(patrol.vehicles) do
                safeDelete(entry.driver)
                safeDelete(entry.vehicle)
            end
        else
            safeDelete(patrol.driver)
            safeDelete(patrol.vehicle)
        end
    end
    patrols = {}
    QBCore.Functions.Notify('All patrols cleared', 'success')
    cb('ok')
end)

RegisterNUICallback('spawnHunters', function(data, cb)
    local level = data.level or 1
    local count = data.count or 1
    local targetId = data.targetId
    local hunterType = data.hunterType or 'vehicle' -- 'vehicle' or 'pedestrian'
    
    -- If no target ID provided, use local player
    if not targetId or targetId == 0 then
        targetId = GetPlayerServerId(PlayerId())
    end
    
    if hunterType == 'pedestrian' then
        -- Request target player coordinates from server
        TriggerServerEvent('prelude-npc:server:requestPlayerCoords', targetId, level, count, hunterType)
    else
        -- For vehicle hunters, spawn on the target player
        TriggerServerEvent('prelude-npc:server:requestPlayerCoords', targetId, level, count, hunterType)
    end
    
    QBCore.Functions.Notify(('Spawning %d %s hunter(s) on player %d'):format(count, hunterType, targetId), 'success')
    cb('ok')
end)

RegisterNUICallback('clearHunters', function(data, cb)
    cleanupHunters()
    QBCore.Functions.Notify('All hunters cleared', 'success')
    cb('ok')
end)

RegisterNUICallback('giveBodyguard', function(data, cb)
    TriggerServerEvent('prelude-npc:server:adminGiveBodyguard', data.playerId, data.tier)
    cb('ok')
end)

RegisterNUICallback('clearBodyguards', function(data, cb)
    TriggerServerEvent('prelude-npc:server:adminClearBodyguards', data.playerId)
    cb('ok')
end)

-- Zone and Route Builder Callbacks
RegisterNUICallback('createZone', function(data, cb)
    cb('ok')
    StartZoneBuilder() -- Function from client_builders.lua
end)

RegisterNUICallback('createRoute', function(data, cb)
    cb('ok')
    StartRouteBuilder() -- Function from client_builders.lua
end)

RegisterNUICallback('deleteZone', function(data, cb)
    TriggerServerEvent('prelude-npc:server:deleteGuardZone', data.zoneName)
    cb('ok')
end)

RegisterNUICallback('deleteRoute', function(data, cb)
    TriggerServerEvent('prelude-npc:server:deletePatrolRoute', data.routeName)
    cb('ok')
end)

-- Scenario/Template callbacks
RegisterNUICallback('activateScenario', function(data, cb)
    TriggerEvent('prelude-npc:client:activateTemplate', data.scenarioName)
    cb('ok')
end)

RegisterNUICallback('deactivateScenario', function(data, cb)
    TriggerEvent('prelude-npc:client:deactivateTemplate', data.scenarioName)
    cb('ok')
end)

-- Quick Action callbacks
RegisterNUICallback('spawnAllGuards', function(data, cb)
    TriggerEvent('prelude-npc:client:spawnAllGuards')
    cb('ok')
end)

RegisterNUICallback('clearEverything', function(data, cb)
    TriggerEvent('prelude-npc:client:clearEverything')
    cb('ok')
end)

RegisterNUICallback('emergencyLockdown', function(data, cb)
    TriggerEvent('prelude-npc:client:emergencyLockdown')
    cb('ok')
end)

RegisterNUICallback('performanceCheck', function(data, cb)
    TriggerEvent('prelude-npc:client:performanceCheck')
    cb('ok')
end)

-- Settings callbacks
RegisterNUICallback('toggleWarnings', function(data, cb)
    Config.EnableWarnings = data.enabled
    QBCore.Functions.Notify(string.format('Player warnings %s', data.enabled and 'enabled' or 'disabled'), 'success')
    cb('ok')
end)

RegisterNUICallback('toggleAI', function(data, cb)
    Config.GuardBehaviors.enabled = data.enabled
    QBCore.Functions.Notify(string.format('Enhanced AI %s', data.enabled and 'enabled' or 'disabled'), 'success')
    cb('ok')
end)

-- Aggressive NPC Zone callbacks
RegisterNUICallback('spawnAggressiveZone', function(data, cb)
    local zoneId = tonumber(data.zoneId)
    if zoneId and Config.AggressiveNPCZones[zoneId] then
        spawnAggressiveZone(zoneId)
        QBCore.Functions.Notify(('Spawning street NPCs in: %s'):format(Config.AggressiveNPCZones[zoneId].name), 'success')
    end
    cb('ok')
end)

RegisterNUICallback('clearAggressiveZone', function(data, cb)
    local zoneId = tonumber(data.zoneId)
    if zoneId and aggressiveNPCZones[zoneId] then
        for _, npcData in ipairs(aggressiveNPCZones[zoneId].npcs) do
            safeDelete(npcData.ped)
        end
        aggressiveNPCZones[zoneId] = nil
        QBCore.Functions.Notify('Street NPCs cleared from zone', 'success')
    end
    cb('ok')
end)

RegisterNUICallback('spawnAllAggressiveZones', function(data, cb)
    if Config.AggressiveNPCZones then
        for i = 1, #Config.AggressiveNPCZones do
            spawnAggressiveZone(i)
            Wait(200)
        end
        QBCore.Functions.Notify('All street NPC zones spawned!', 'success')
    end
    cb('ok')
end)

RegisterNUICallback('clearAllAggressiveZones', function(data, cb)
    clearAllAggressiveNPCZones()
    QBCore.Functions.Notify('All street NPC zones cleared!', 'success')
    cb('ok')
end)

-- Admin-only command to open control panel
RegisterCommand('npcpanel', function()
    local PlayerData = QBCore.Functions.GetPlayerData()
    if not PlayerData then return end
    
    -- Check admin permission - you can verify this server-side if needed
    -- For now, allow anyone to open (you can add server callback for permission check)
    openControlPanel()
end, false)

-- Force close command (emergency fix for stuck UI)
RegisterCommand('closenpc', function()
    tabletOpen = false
    SetNuiFocus(false, false)
    SendNUIMessage({ action = 'closeTablet' })
    print('^2[NPC Panel]^7 Force closed UI and released focus')
end, false)

-- ESC key handler to close panel
CreateThread(function()
    while true do
        Wait(0)
        if tabletOpen and IsControlJustPressed(0, 322) then -- ESC key
            closeControlPanel()
        end
    end
end)

log('NPC Control Panel loaded. Use /npcpanel to open (Admin only).')


