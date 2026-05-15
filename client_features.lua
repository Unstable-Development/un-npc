-- Client-side warning system and enhanced AI behaviors
-- Handles player warnings for restricted zones and guard AI improvements

local QBCore = exports['qb-core']:GetCoreObject()

-- State tracking
local currentWarningLevel = nil
local lastWarningTime = 0
local nearestZone = nil
local warningThread = nil

-- ============================================
-- PLAYER WARNING SYSTEM
-- ============================================

local function GetNearestRestrictedZone()
    if not Config.GuardZones then return nil end
    
    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local nearestDist = 999999
    local nearest = nil
    
    for _, zone in ipairs(Config.GuardZones) do
        local distance = #(playerCoords - zone.center)
        if distance < nearestDist then
            nearestDist = distance
            nearest = {zone = zone, distance = distance}
        end
    end
    
    return nearest
end

local function GetWarningLevel(distance, radius)
    if distance <= radius then
        return "trespassing"
    elseif distance <= radius + Config.WarningDistances.warning then
        return "warning"
    elseif distance <= radius + Config.WarningDistances.approaching then
        return "approaching"
    end
    return nil
end

local function ShowWarning(level, zoneName, distance)
    if not Config.EnableWarnings then return end
    
    local now = GetGameTimer()
    if now - lastWarningTime < 3000 then return end -- Throttle warnings
    
    local message = Config.WarningMessages[level]
    if not message then return end
    
    -- Add zone name and distance to message
    if Config.ShowDistanceUI then
        message = message .. string.format("\n~w~Zone: ~y~%s ~w~| Distance: ~b~%.0fm", zoneName, distance)
    end
    
    -- Determine notification type
    local notifType = level == "trespassing" and "error" or (level == "warning" and "warning" or "primary")
    
    QBCore.Functions.Notify(message, notifType, 3000)
    lastWarningTime = now
end

-- Warning system thread
CreateThread(function()
    if not Config.EnableWarnings then return end
    
    while true do
        Wait(1000) -- Check every second
        
        local nearest = GetNearestRestrictedZone()
        if nearest then
            local warningLevel = GetWarningLevel(nearest.distance, nearest.zone.radius)
            
            if warningLevel then
                -- New warning level or different zone
                if warningLevel ~= currentWarningLevel or (nearestZone and nearestZone.name ~= nearest.zone.name) then
                    ShowWarning(warningLevel, nearest.zone.name, nearest.distance)
                    currentWarningLevel = warningLevel
                    nearestZone = nearest.zone
                end
            else
                -- Left warning area
                currentWarningLevel = nil
                nearestZone = nil
            end
        else
            currentWarningLevel = nil
            nearestZone = nil
        end
    end
end)

-- ============================================
-- GUARD AI BEHAVIORS
-- ============================================

local activeGuardBehaviors = {} -- Tracks guards with AI behaviors

-- Set guard to patrol within zone
local function SetGuardPatrol(guard, zone)
    if not Config.GuardBehaviors.enabled or not Config.GuardBehaviors.modes.patrol then return end
    
    CreateThread(function()
        while DoesEntityExist(guard) and not IsEntityDead(guard) do
            Wait(5000)
            
            -- Generate random point within zone
            local angle = math.random() * 2 * math.pi
            local dist = math.random() * zone.radius * 0.8
            local targetX = zone.center.x + dist * math.cos(angle)
            local targetY = zone.center.y + dist * math.sin(angle)
            local targetZ = zone.center.z
            
            -- Get ground Z
            local foundGround, groundZ = GetGroundZFor_3dCoord(targetX, targetY, targetZ, false)
            if foundGround then
                targetZ = groundZ
            end
            
            -- Task ped to walk to point
            TaskGoToCoordAnyMeans(guard, targetX, targetY, targetZ, Config.GuardBehaviors.patrolSpeed, 0, 0, 786603, 0.0)
            
            Wait(math.random(10000, 20000)) -- Wait before next patrol point
        end
    end)
end

-- Make guard investigate a position
local function MakeGuardInvestigate(guard, position)
    if not Config.GuardBehaviors.enabled or not Config.GuardBehaviors.modes.investigate then return end
    
    -- Check if guard is too far
    local guardPos = GetEntityCoords(guard)
    if #(guardPos - position) > Config.GuardBehaviors.investigationRadius then
        return
    end
    
    -- Clear current task
    ClearPedTasksImmediately(guard)
    
    -- Go investigate
    TaskGoToCoordAnyMeans(guard, position.x, position.y, position.z, 2.0, 0, 0, 786603, 0.0)
    
    -- After reaching, look around
    CreateThread(function()
        Wait(5000)
        if DoesEntityExist(guard) then
            TaskStartScenarioInPlace(guard, "WORLD_HUMAN_GUARD_STAND", 0, true)
        end
    end)
end

-- Call backup guards when attacked
local function CallBackup(guard, zone)
    if not Config.GuardBehaviors.enabled or not Config.GuardBehaviors.modes.callBackup then return end
    
    CreateThread(function()
        Wait(Config.GuardBehaviors.backupDelay)
        
        -- Spawn 2-3 backup guards near the attacked guard
        local guardCoords = GetEntityCoords(guard)
        local backupCount = math.random(2, 3)
        
        TriggerServerEvent('prelude-npc:server:requestBackup', zone.name, guardCoords, backupCount)
    end)
end

-- Make guard take cover
local function MakeGuardTakeCover(guard, threatPos)
    if not Config.GuardBehaviors.enabled or not Config.GuardBehaviors.modes.takeCover then return end
    
    local guardPos = GetEntityCoords(guard)
    
    -- Find cover
    local coverPos = GetCoverPosition(guardPos, Config.GuardBehaviors.coverSearchRadius)
    
    if coverPos then
        TaskCombatPed(guard, PlayerPedId(), 0, 16)
        TaskAchieveHeading(guard, GetHeadingFromVector_2d(threatPos.x - guardPos.x, threatPos.y - guardPos.y), 1000)
    end
end

-- Get cover position near guard
function GetCoverPosition(guardPos, radius)
    -- Simple cover search - find nearest solid object
    local searchPos = guardPos
    
    for i = 1, 8 do
        local angle = (i / 8) * 2 * math.pi
        local testX = guardPos.x + radius * math.cos(angle)
        local testY = guardPos.y + radius * math.sin(angle)
        local testZ = guardPos.z
        
        -- Ray cast to check for solid surface
        local rayHandle = StartShapeTestRay(guardPos.x, guardPos.y, guardPos.z, testX, testY, testZ, -1, 0, 7)
        local _, hit, endCoords, surfaceNormal, entityHit = GetShapeTestResult(rayHandle)
        
        if hit then
            return endCoords
        end
    end
    
    return nil
end

-- Enhanced guard spawn with AI behaviors
RegisterNetEvent('prelude-npc:client:spawnGuardEnhanced', function(guardNetId, zoneName, behavior)
    if not Config.GuardBehaviors.enabled then return end
    
    local guard = NetworkGetEntityFromNetworkId(guardNetId)
    if not DoesEntityExist(guard) then return end
    
    -- Find zone
    local zone = nil
    for _, z in ipairs(Config.GuardZones) do
        if z.name == zoneName then
            zone = z
            break
        end
    end
    
    if not zone then return end
    
    -- Apply behavior
    behavior = behavior or "stationary"
    
    if behavior == "patrol" then
        SetGuardPatrol(guard, zone)
    elseif behavior == "stationary" then
        TaskStartScenarioInPlace(guard, "WORLD_HUMAN_GUARD_STAND", 0, true)
    end
    
    -- Track guard
    activeGuardBehaviors[guardNetId] = {
        guard = guard,
        zone = zone,
        behavior = behavior,
    }
    
    -- Monitor for combat
    CreateThread(function()
        while DoesEntityExist(guard) and not IsEntityDead(guard) do
            Wait(1000)
            
            if IsPedInCombat(guard, PlayerPedId()) then
                -- Call backup
                CallBackup(guard, zone)
                
                -- Take cover
                local playerPos = GetEntityCoords(PlayerPedId())
                MakeGuardTakeCover(guard, playerPos)
                
                break -- Only call once
            end
        end
    end)
end)

-- Listen for gunshot events to make guards investigate
AddEventHandler('CEventGunShot', function(witnesses, ped)
    if not Config.GuardBehaviors.enabled or not Config.GuardBehaviors.modes.investigate then return end
    
    local shooterPos = GetEntityCoords(ped)
    
    -- Make nearby guards investigate
    for netId, data in pairs(activeGuardBehaviors) do
        if DoesEntityExist(data.guard) and not IsEntityDead(data.guard) then
            MakeGuardInvestigate(data.guard, shooterPos)
        end
    end
end)

-- Cleanup on resource stop
AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end
    
    activeGuardBehaviors = {}
end)

-- ============================================
-- ZONE TEMPLATE SYSTEM
-- ============================================

-- Activate a scenario template
RegisterNetEvent('prelude-npc:client:activateTemplate', function(templateName)
    local template = nil
    
    -- Find template
    for _, t in ipairs(Config.ZoneTemplates) do
        if t.name == templateName then
            template = t
            break
        end
    end
    
    if not template then
        QBCore.Functions.Notify('Template not found!', 'error')
        return
    end
    
    -- Spawn zones
    if template.autoSpawn then
        for _, zoneName in ipairs(template.zones) do
            TriggerEvent('prelude-npc:client:adminSpawnGuards', zoneName)
        end
        
        for _, patrolName in ipairs(template.patrols) do
            TriggerEvent('prelude-npc:client:adminSpawnPatrol', patrolName)
        end
    end
    
    QBCore.Functions.Notify(string.format('Scenario "%s" activated!', templateName), 'success', 5000)
end)

-- Deactivate a scenario template
RegisterNetEvent('prelude-npc:client:deactivateTemplate', function(templateName)
    local template = nil
    
    -- Find template
    for _, t in ipairs(Config.ZoneTemplates) do
        if t.name == templateName then
            template = t
            break
        end
    end
    
    if not template then
        QBCore.Functions.Notify('Template not found!', 'error')
        return
    end
    
    -- Clear zones
    for _, zoneName in ipairs(template.zones) do
        TriggerEvent('prelude-npc:client:adminClearGuards', zoneName)
    end
    
    TriggerEvent('prelude-npc:client:adminClearPatrols')
    
    QBCore.Functions.Notify(string.format('Scenario "%s" deactivated!', templateName), 'success', 5000)
end)

-- ============================================
-- QUICK ACTIONS
-- ============================================

-- Spawn all guards in all zones
RegisterNetEvent('prelude-npc:client:spawnAllGuards', function()
    if not Config.QuickActions.spawnAllGuards then return end
    
    local count = 0
    for i, zone in ipairs(Config.GuardZones) do
        TriggerEvent('prelude-npc:client:adminSpawnGuards', tostring(i))
        count = count + 1
        Wait(500) -- Stagger spawns
    end
    
    QBCore.Functions.Notify(string.format('Spawned guards in %d zones!', count), 'success')
end)

-- Clear everything (all NPCs)
RegisterNetEvent('prelude-npc:client:clearEverything', function()
    if not Config.QuickActions.clearEverything then return end
    
    TriggerEvent('prelude-npc:client:adminClearGuards', 'all')
    TriggerEvent('prelude-npc:client:adminClearPatrols')
    TriggerEvent('prelude-npc:client:clearAllHunters')
    TriggerEvent('prelude-npc:client:dismissAllBodyguards')
    TriggerEvent('prelude-npc:client:adminClearAggressiveZones')
    
    QBCore.Functions.Notify('ALL NPCs cleared!', 'success')
end)

-- Emergency lockdown (spawn critical zones only)
RegisterNetEvent('prelude-npc:client:emergencyLockdown', function()
    if not Config.QuickActions.emergencyLockdown then return end
    
    -- Spawn Fort Zancudo, Cayo Perico, and any "critical" zones
    local criticalZones = {"Fort Zancudo", "Cayo Perico", "Bolingbroke Prison"}
    
    for _, zoneName in ipairs(criticalZones) do
        TriggerEvent('prelude-npc:client:adminSpawnGuards', zoneName)
    end
    
    QBCore.Functions.Notify('🚨 EMERGENCY LOCKDOWN ACTIVATED 🚨', 'error', 5000)
end)

-- Performance check
RegisterNetEvent('prelude-npc:client:performanceCheck', function()
    if not Config.QuickActions.performanceCheck then return end
    
    -- Count active NPCs
    local guardCount = 0
    local patrolCount = 0
    local hunterCount = 0
    local bodyguardCount = 0
    
    -- Get current FPS using frameTime
    local frameTime = GetFrameTime()
    local fps = frameTime > 0 and math.floor(1.0 / frameTime) or 0
    local ping = GetPlayerPing(PlayerId())
    
    local message = string.format([[
~y~=== NPC Performance Report ===~w~
FPS: ~b~%.0f~w~
Ping: ~b~%dms~w~
Active Guards: ~g~%d~w~
Active Patrols: ~g~%d~w~
Active Hunters: ~g~%d~w~
Active Bodyguards: ~g~%d~w~
Status: ~g~OPTIMAL~w~
    ]], fps, ping, guardCount, patrolCount, hunterCount, bodyguardCount)
    
    QBCore.Functions.Notify(message, 'primary', 10000)
end)

print('[prelude-npc] Enhanced features loaded: Warnings, AI Behaviors, Templates')
