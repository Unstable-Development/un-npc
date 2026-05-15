-- Server-side SQL handler for NPC system
-- Handles database operations for zones, patrols, and NPCs

-- Ensure Config is available (shared_script loads before server_scripts)
if not Config then
    error('[un-npc] server_sql.lua loaded before config.lua - check fxmanifest.lua load order')
end

local QBCore = exports['qb-core']:GetCoreObject()

-- Cache for loaded data
local cachedZones = {}
local cachedPatrols = {}
local dataLoaded = false

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

local function log(msg)
    print(('[prelude-npc] %s'):format(msg))
end

local function HasPermission(source, permission)
    if Config.Framework == 'qb' then
        return QBCore.Functions.HasPermission(source, permission)
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.getGroup() == permission
    end
    return false
end

local function GetIdentifier(source)
    if Config.Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        return Player and Player.PlayerData.license or nil
    elseif Config.Framework == 'esx' then
        local xPlayer = ESX.GetPlayerFromId(source)
        return xPlayer and xPlayer.identifier or nil
    end
    return nil
end

-- ============================================
-- DATABASE FUNCTIONS - GUARD ZONES
-- ============================================

-- Load all guard zones from database
function LoadGuardZones()
    if not Config.UseDatabase then
        log('Database mode disabled, using config zones only')
        return Config.GuardZones or {}
    end
    
    local zones = {}
    local result = MySQL.query.await('SELECT * FROM npc_guard_zones ORDER BY name ASC')
    
    if result then
        for _, row in ipairs(result) do
            table.insert(zones, {
                id = row.id,
                name = row.name,
                center = vector3(row.center_x, row.center_y, row.center_z),
                radius = row.radius,
                guardCount = row.guard_count,
                requiredItem = row.required_item,
                requiresIdentifier = row.requires_identifier,
                pedModels = json.decode(row.ped_models),
                weapons = json.decode(row.weapons),
                accuracy = row.accuracy,
                health = row.health,
                armor = row.armor,
                isActive = row.is_active == 1,
                isCustom = row.is_custom == 1,
                createdBy = row.created_by,
            })
        end
        log(('Loaded %d guard zones from database'):format(#zones))
    else
        log('No zones found in database, using config zones')
        return Config.GuardZones or {}
    end
    
    cachedZones = zones
    dataLoaded = true
    return zones
end

-- Create new guard zone
RegisterNetEvent('prelude-npc:server:createGuardZone', function(zoneData)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.createZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    local identifier = GetIdentifier(src)
    
    MySQL.insert('INSERT INTO npc_guard_zones (name, center_x, center_y, center_z, radius, guard_count, required_item, requires_identifier, ped_models, weapons, accuracy, health, armor, is_custom, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        zoneData.name,
        zoneData.center.x,
        zoneData.center.y,
        zoneData.center.z,
        zoneData.radius,
        zoneData.guardCount,
        zoneData.requiredItem,
        zoneData.requiresIdentifier,
        json.encode(zoneData.pedModels),
        json.encode(zoneData.weapons),
        zoneData.accuracy,
        zoneData.health,
        zoneData.armor,
        1,
        identifier or 'system'
    }, function(insertId)
        if insertId then
            log(('Zone "%s" created by %s (ID: %d)'):format(zoneData.name, GetPlayerName(src), insertId))
            LoadGuardZones() -- Reload cache
            TriggerClientEvent('prelude-npc:client:reloadZones', -1)
            TriggerClientEvent('QBCore:Notify', src, 'Guard zone "' .. zoneData.name .. '" created!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to create zone (name may already exist)', 'error')
        end
    end)
end)

-- Delete guard zone
RegisterNetEvent('prelude-npc:server:deleteGuardZone', function(zoneName)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.deleteZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    MySQL.query('DELETE FROM npc_guard_zones WHERE name = ?', {zoneName}, function(result)
        if result and result.affectedRows > 0 then
            log(('Zone "%s" deleted by %s'):format(zoneName, GetPlayerName(src)))
            LoadGuardZones() -- Reload cache
            TriggerClientEvent('prelude-npc:client:reloadZones', -1)
            TriggerClientEvent('QBCore:Notify', src, 'Zone "' .. zoneName .. '" deleted!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Zone not found or already deleted', 'error')
        end
    end)
end)

-- Update guard zone
RegisterNetEvent('prelude-npc:server:updateGuardZone', function(zoneName, updateData)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.createZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    local updates = {}
    local params = {}
    
    if updateData.radius then
        table.insert(updates, 'radius = ?')
        table.insert(params, updateData.radius)
    end
    if updateData.guardCount then
        table.insert(updates, 'guard_count = ?')
        table.insert(params, updateData.guardCount)
    end
    if updateData.accuracy then
        table.insert(updates, 'accuracy = ?')
        table.insert(params, updateData.accuracy)
    end
    if updateData.health then
        table.insert(updates, 'health = ?')
        table.insert(params, updateData.health)
    end
    if updateData.armor then
        table.insert(updates, 'armor = ?')
        table.insert(params, updateData.armor)
    end
    
    if #updates == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'No updates provided', 'error')
        return
    end
    
    table.insert(params, zoneName)
    
    MySQL.query('UPDATE npc_guard_zones SET ' .. table.concat(updates, ', ') .. ' WHERE name = ?', params, function(result)
        if result and result.affectedRows > 0 then
            log(('Zone "%s" updated by %s'):format(zoneName, GetPlayerName(src)))
            LoadGuardZones()
            TriggerClientEvent('prelude-npc:client:reloadZones', -1)
            TriggerClientEvent('QBCore:Notify', src, 'Zone updated successfully!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Zone not found', 'error')
        end
    end)
end)

-- Get all zones
RegisterNetEvent('prelude-npc:server:getGuardZones', function()
    local src = source
    local zones = Config.UseDatabase and cachedZones or (Config.GuardZones or {})
    TriggerClientEvent('prelude-npc:client:receiveGuardZones', src, zones)
end)

-- ============================================
-- DATABASE FUNCTIONS - PATROL ROUTES
-- ============================================

-- Load all patrol routes from database
function LoadPatrolRoutes()
    if not Config.UseDatabase then
        log('Database mode disabled, using config patrols only')
        return Config.PatrolRoutes or {}
    end
    
    local patrols = {}
    local result = MySQL.query.await('SELECT * FROM npc_patrol_routes ORDER BY name ASC')
    
    if result then
        for _, row in ipairs(result) do
            local waypoints = json.decode(row.waypoints)
            local waypointsVec4 = {}
            
            -- Convert JSON waypoints to vector4
            for _, wp in ipairs(waypoints) do
                table.insert(waypointsVec4, vector4(wp.x, wp.y, wp.z, wp.w or 0.0))
            end
            
            table.insert(patrols, {
                id = row.id,
                name = row.name,
                guardZone = row.guard_zone,
                requiredJob = row.required_job or nil,
                vehicleModel = row.vehicle_model,
                pedModel = row.ped_model,
                weapon = row.weapon,
                speed = row.speed,
                waypoints = waypointsVec4,
                isActive = row.is_active == 1,
                isCustom = row.is_custom == 1,
                createdBy = row.created_by,
            })
        end
        log(('Loaded %d patrol routes from database'):format(#patrols))
    else
        log('No patrols found in database, using config patrols')
        return Config.PatrolRoutes or {}
    end
    
    cachedPatrols = patrols
    return patrols
end

-- Create new patrol route
RegisterNetEvent('prelude-npc:server:createPatrolRoute', function(routeData)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.createZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    local identifier = GetIdentifier(src)
    
    -- Convert waypoints to JSON
    local waypointsJson = {}
    for _, wp in ipairs(routeData.waypoints) do
        table.insert(waypointsJson, {x = wp.x, y = wp.y, z = wp.z, w = wp.w or 0.0})
    end
    
    MySQL.insert('INSERT INTO npc_patrol_routes (name, guard_zone, vehicle_model, ped_model, weapon, speed, waypoints, is_custom, created_by) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', {
        routeData.name,
        routeData.guardZone,
        routeData.vehicleModel,
        routeData.pedModel,
        routeData.weapon,
        routeData.speed,
        json.encode(waypointsJson),
        1,
        identifier or 'system'
    }, function(insertId)
        if insertId then
            log(('Patrol route "%s" created by %s (ID: %d)'):format(routeData.name, GetPlayerName(src), insertId))
            LoadPatrolRoutes()
            TriggerClientEvent('prelude-npc:client:reloadPatrols', -1)
            TriggerClientEvent('QBCore:Notify', src, 'Patrol route "' .. routeData.name .. '" created!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to create route (name may already exist)', 'error')
        end
    end)
end)

-- Delete patrol route
RegisterNetEvent('prelude-npc:server:deletePatrolRoute', function(routeName)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.deleteZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    MySQL.query('DELETE FROM npc_patrol_routes WHERE name = ?', {routeName}, function(result)
        if result and result.affectedRows > 0 then
            log(('Patrol route "%s" deleted by %s'):format(routeName, GetPlayerName(src)))
            LoadPatrolRoutes()
            TriggerClientEvent('prelude-npc:client:reloadPatrols', -1)
            TriggerClientEvent('QBCore:Notify', src, 'Route "' .. routeName .. '" deleted!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Route not found or already deleted', 'error')
        end
    end)
end)

-- Get all patrol routes
RegisterNetEvent('prelude-npc:server:getPatrolRoutes', function()
    local src = source
    local patrols = Config.UseDatabase and cachedPatrols or (Config.PatrolRoutes or {})
    TriggerClientEvent('prelude-npc:client:receivePatrolRoutes', src, patrols)
end)

-- ============================================
-- ZONE ACCESS LOGGING
-- ============================================

RegisterNetEvent('prelude-npc:server:logZoneAccess', function(zoneName, action)
    if not Config.UseDatabase then return end
    
    local src = source
    local identifier = GetIdentifier(src)
    local playerName = GetPlayerName(src)
    
    -- Get zone ID from name
    MySQL.query('SELECT id FROM npc_guard_zones WHERE name = ?', {zoneName}, function(result)
        if result and result[1] then
            local zoneId = result[1].id
            
            MySQL.insert('INSERT INTO npc_zone_access_log (zone_id, player_identifier, player_name, action) VALUES (?, ?, ?, ?)', {
                zoneId,
                identifier,
                playerName,
                action
            })
        end
    end)
end)

-- ============================================
-- PRESETS SYSTEM
-- ============================================

-- Save current configuration as preset
RegisterNetEvent('prelude-npc:server:savePreset', function(presetName, description, isPublic)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.createZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    local identifier = GetIdentifier(src)
    
    local presetData = {
        zones = cachedZones,
        patrols = cachedPatrols
    }
    
    MySQL.insert('INSERT INTO npc_presets (name, description, preset_data, created_by, is_public) VALUES (?, ?, ?, ?, ?) ON DUPLICATE KEY UPDATE description = ?, preset_data = ?, is_public = ?', {
        presetName,
        description,
        json.encode(presetData),
        identifier or 'system',
        isPublic and 1 or 0,
        description,
        json.encode(presetData),
        isPublic and 1 or 0
    }, function(insertId)
        if insertId then
            log(('Preset "%s" saved by %s'):format(presetName, GetPlayerName(src)))
            TriggerClientEvent('QBCore:Notify', src, 'Preset "' .. presetName .. '" saved!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Failed to save preset', 'error')
        end
    end)
end)

-- Load preset
RegisterNetEvent('prelude-npc:server:loadPreset', function(presetName)
    local src = source
    
    if not HasPermission(src, Config.AdminPermissions.createZones) then
        TriggerClientEvent('QBCore:Notify', src, 'No permission!', 'error')
        return
    end
    
    if not Config.UseDatabase then
        TriggerClientEvent('QBCore:Notify', src, 'Database mode is disabled!', 'error')
        return
    end
    
    MySQL.query('SELECT preset_data FROM npc_presets WHERE name = ?', {presetName}, function(result)
        if result and result[1] then
            local presetData = json.decode(result[1].preset_data)
            TriggerClientEvent('prelude-npc:client:loadPresetData', src, presetData)
            TriggerClientEvent('QBCore:Notify', src, 'Preset "' .. presetName .. '" loaded!', 'success')
        else
            TriggerClientEvent('QBCore:Notify', src, 'Preset not found', 'error')
        end
    end)
end)

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    Wait(1000)
    if Config.UseDatabase then
        log('Loading zones and patrols from database...')
        LoadGuardZones()
        LoadPatrolRoutes()
        log('Database load complete')
    else
        log('Using config-only mode')
    end
end)

-- Export functions
exports('GetCachedZones', function()
    return Config.UseDatabase and cachedZones or (Config.GuardZones or {})
end)

exports('GetCachedPatrols', function()
    return Config.UseDatabase and cachedPatrols or (Config.PatrolRoutes or {})
end)

exports('ReloadFromDatabase', function()
    if Config.UseDatabase then
        LoadGuardZones()
        LoadPatrolRoutes()
    end
end)
