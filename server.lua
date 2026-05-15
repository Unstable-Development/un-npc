local QBCore = exports['qb-core']:GetCoreObject()
local activeBodyguards = {} -- [source] = { guards = {}, expireTime = timestamp }
local guardZoneData = {} -- Server-side guard zone tracking
local Framework = 'qb' -- Change to 'esx' if using ESX

-- Helper Functions
local function log(msg)
    print(('[prelude-npc] %s'):format(msg))
end

local function GetPlayer(source)
    if Framework == 'qb' then
        return QBCore.Functions.GetPlayer(source)
    elseif Framework == 'esx' then
        return ESX.GetPlayerFromId(source)
    end
end

local function GetPlayerMoney(player, type)
    if Framework == 'qb' then
        return player.Functions.GetMoney(type or 'cash')
    elseif Framework == 'esx' then
        return player.getMoney()
    end
end

local function RemoveMoney(player, amount, type)
    if Framework == 'qb' then
        return player.Functions.RemoveMoney(type or 'cash', amount)
    elseif Framework == 'esx' then
        return player.removeMoney(amount)
    end
end

local function HasItem(source, itemName)
    if Framework == 'qb' then
        local Player = QBCore.Functions.GetPlayer(source)
        if not Player then return false end
        local item = Player.Functions.GetItemByName(itemName)
        return item ~= nil and item.amount > 0
    elseif Framework == 'esx' then
        -- ESX item check
        local xPlayer = ESX.GetPlayerFromId(source)
        if not xPlayer then return false end
        local item = xPlayer.getInventoryItem(itemName)
        return item and item.count > 0
    end
    return false
end

-- Bodyguard System
RegisterNetEvent('prelude-npc:server:hireBodyguard', function(tier)
    local src = source
    local Player = GetPlayer(src)
    
    if not Player then return end
    
    -- Check if player already has max bodyguards
    if activeBodyguards[src] and #activeBodyguards[src].guards >= Config.MaxBodyguards then
        TriggerClientEvent('QBCore:Notify', src, 'You already have the maximum number of bodyguards!', 'error')
        return
    end
    
    local tierConfig = Config.BodyguardTiers[tier]
    if not tierConfig then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid bodyguard tier!', 'error')
        return
    end
    
    -- Check money
    local money = GetPlayerMoney(Player, 'cash')
    if money < tierConfig.price then
        TriggerClientEvent('QBCore:Notify', src, 'You don\'t have enough cash! ($'..tierConfig.price..' required)', 'error')
        return
    end
    
    -- Remove money
    RemoveMoney(Player, tierConfig.price, 'cash')
    
    -- Initialize bodyguard data if needed
    if not activeBodyguards[src] then
        activeBodyguards[src] = { guards = {}, expireTime = 0 }
    end
    
    -- Add bodyguard
    local guardId = #activeBodyguards[src].guards + 1
    table.insert(activeBodyguards[src].guards, {
        tier = tier,
        spawnTime = os.time()
    })
    
    -- Update expire time
    local expireTime = os.time() + (tierConfig.duration * 60)
    if expireTime > activeBodyguards[src].expireTime then
        activeBodyguards[src].expireTime = expireTime
    end
    
    TriggerClientEvent('QBCore:Notify', src, 'Bodyguard hired! ('..#activeBodyguards[src].guards..'/'..Config.MaxBodyguards..')', 'success')
    TriggerClientEvent('prelude-npc:client:spawnBodyguard', src, tier, guardId)
    
    log(('Player %s hired tier %d bodyguard'):format(GetPlayerName(src), tier))
end)

RegisterNetEvent('prelude-npc:server:dismissBodyguards', function()
    local src = source
    
    if activeBodyguards[src] then
        activeBodyguards[src] = nil
        TriggerClientEvent('prelude-npc:client:dismissAllBodyguards', src)
        TriggerClientEvent('QBCore:Notify', src, 'All bodyguards dismissed', 'success')
    else
        TriggerClientEvent('QBCore:Notify', src, 'You have no active bodyguards', 'error')
    end
end)

-- Check for required item in guard zones
RegisterNetEvent('prelude-npc:server:checkItemAccess', function(zoneName, requiredItem)
    local src = source
    
    if not requiredItem then
        TriggerClientEvent('prelude-npc:client:zoneAccessResult', src, zoneName, true)
        return
    end
    
    local hasAccess = HasItem(src, requiredItem)
    TriggerClientEvent('prelude-npc:client:zoneAccessResult', src, zoneName, hasAccess)
end)

-- Check for required job in guard zones (Cayo Perico etc.)
RegisterNetEvent('prelude-npc:server:checkJobAccess', function(zoneName, requiredJob)
    local src = source
    
    if not requiredJob then
        TriggerClientEvent('prelude-npc:client:zoneAccessResult', src, zoneName, false)
        return
    end
    
    local Player = GetPlayer(src)
    if not Player then
        TriggerClientEvent('prelude-npc:client:zoneAccessResult', src, zoneName, false)
        return
    end
    
    local playerJob = Player.PlayerData.job.name
    local hasAccess = (playerJob == requiredJob)
    TriggerClientEvent('prelude-npc:client:zoneAccessResult', src, zoneName, hasAccess)
end)

-- Admin Commands
QBCore.Commands.Add('spawnguards', 'Spawn guards in a zone (Admin)', {{name = 'zonename', help = 'Zone name or number'}}, false, function(source, args)
    local src = source
    if not args[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /spawnguards [zone name or number]', 'error')
        return
    end
    
    TriggerClientEvent('prelude-npc:client:adminSpawnGuards', src, args[1])
    TriggerClientEvent('QBCore:Notify', src, 'Spawning guards in zone: '..args[1], 'success')
end, 'admin')

QBCore.Commands.Add('clearguards', 'Clear all guards in a zone (Admin)', {{name = 'zonename', help = 'Zone name or number, or "all"'}}, false, function(source, args)
    local src = source
    local zone = args[1] or 'all'
    
    TriggerClientEvent('prelude-npc:client:adminClearGuards', -1, zone)
    TriggerClientEvent('QBCore:Notify', src, 'Clearing guards: '..zone, 'success')
end, 'admin')

QBCore.Commands.Add('spawnpatrol', 'Spawn a patrol route (Admin)', {{name = 'routename', help = 'Route name or number'}}, false, function(source, args)
    local src = source
    if not args[1] then
        TriggerClientEvent('QBCore:Notify', src, 'Usage: /spawnpatrol [route name or number]', 'error')
        return
    end
    
    TriggerClientEvent('prelude-npc:client:adminSpawnPatrol', src, args[1])
    TriggerClientEvent('QBCore:Notify', src, 'Spawning patrol: '..args[1], 'success')
end, 'admin')

QBCore.Commands.Add('clearpatrols', 'Clear all patrols (Admin)', {}, false, function(source)
    local src = source
    TriggerClientEvent('prelude-npc:client:adminClearPatrols', -1)
    TriggerClientEvent('QBCore:Notify', src, 'All patrols cleared', 'success')
end, 'admin')

QBCore.Commands.Add('listzones', 'List all guard zones (Admin)', {}, false, function(source)
    local src = source
    local msg = 'Guard Zones:\n'
    for i, zone in ipairs(Config.GuardZones) do
        msg = msg .. i .. '. ' .. zone.name .. ' (Guards: ' .. zone.guardCount .. ')\n'
    end
    TriggerClientEvent('QBCore:Notify', src, msg, 'primary', 10000)
end, 'admin')

QBCore.Commands.Add('listpatrols', 'List all patrol routes (Admin)', {}, false, function(source)
    local src = source
    local msg = 'Patrol Routes:\n'
    for i, route in ipairs(Config.PatrolRoutes) do
        msg = msg .. i .. '. ' .. route.name .. ' (' .. #route.waypoints .. ' waypoints)\n'
    end
    TriggerClientEvent('QBCore:Notify', src, msg, 'primary', 10000)
end, 'admin')

QBCore.Commands.Add('givebodyguard', 'Give bodyguard to player (Admin)', {
    {name = 'id', help = 'Player ID'},
    {name = 'tier', help = 'Tier (1-3)'}
}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    local tier = tonumber(args[2]) or 1
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player ID', 'error')
        return
    end
    
    if tier < 1 or tier > 3 then
        TriggerClientEvent('QBCore:Notify', src, 'Tier must be 1-3', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    -- Initialize bodyguard data if needed
    if not activeBodyguards[targetId] then
        activeBodyguards[targetId] = { guards = {}, expireTime = 0 }
    end
    
    if #activeBodyguards[targetId].guards >= Config.MaxBodyguards then
        TriggerClientEvent('QBCore:Notify', src, 'Player already has max bodyguards', 'error')
        return
    end
    
    -- Add bodyguard
    local guardId = #activeBodyguards[targetId].guards + 1
    table.insert(activeBodyguards[targetId].guards, {
        tier = tier,
        spawnTime = os.time()
    })
    
    local tierConfig = Config.BodyguardTiers[tier]
    local expireTime = os.time() + (tierConfig.duration * 60)
    if expireTime > activeBodyguards[targetId].expireTime then
        activeBodyguards[targetId].expireTime = expireTime
    end
    
    TriggerClientEvent('prelude-npc:client:spawnBodyguard', targetId, tier, guardId)
    TriggerClientEvent('QBCore:Notify', src, 'Bodyguard given to player '..targetId, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'You received a tier '..tier..' bodyguard!', 'success')
end, 'admin')

QBCore.Commands.Add('clearbodyguards', 'Clear all bodyguards from player (Admin)', {
    {name = 'id', help = 'Player ID'}
}, true, function(source, args)
    local src = source
    local targetId = tonumber(args[1])
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player ID', 'error')
        return
    end
    
    if activeBodyguards[targetId] then
        activeBodyguards[targetId] = nil
        TriggerClientEvent('prelude-npc:client:dismissAllBodyguards', targetId)
        TriggerClientEvent('QBCore:Notify', src, 'Cleared bodyguards from player '..targetId, 'success')
        TriggerClientEvent('QBCore:Notify', targetId, 'Your bodyguards were dismissed', 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Player has no bodyguards', 'error')
    end
end, 'admin')

QBCore.Commands.Add('toggleguardzones', 'Toggle all guard zones on/off (Admin)', {}, false, function(source)
    local src = source
    TriggerClientEvent('prelude-npc:client:toggleGuardZones', -1)
    TriggerClientEvent('QBCore:Notify', src, 'Guard zones toggled', 'success')
end, 'admin')

-- Cleanup on player disconnect
AddEventHandler('playerDropped', function()
    local src = source
    if activeBodyguards[src] then
        activeBodyguards[src] = nil
    end
end)

-- Bodyguard expiration check
CreateThread(function()
    while true do
        Wait(60000) -- Check every minute
        
        local currentTime = os.time()
        for source, data in pairs(activeBodyguards) do
            if currentTime >= data.expireTime then
                activeBodyguards[source] = nil
                TriggerClientEvent('prelude-npc:client:dismissAllBodyguards', source)
                TriggerClientEvent('QBCore:Notify', source, 'Your bodyguards\' contract has expired', 'error')
                log(('Bodyguards expired for player %s'):format(GetPlayerName(source)))
            end
        end
    end
end)

-- Export functions for other resources
exports('HasActiveBodyguards', function(source)
    return activeBodyguards[source] ~= nil and #activeBodyguards[source].guards > 0
end)

exports('GetBodyguardCount', function(source)
    if not activeBodyguards[source] then return 0 end
    return #activeBodyguards[source].guards
end)

-- ============================================
-- NUI CONTROL PANEL EVENTS
-- ============================================

RegisterNetEvent('prelude-npc:server:adminGiveBodyguard', function(targetId, tier)
    local src = source
    
    -- Check if source has admin permission
    local Player = GetPlayer(src)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission!', 'error')
        return
    end
    
    targetId = tonumber(targetId)
    tier = tonumber(tier) or 1
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player ID', 'error')
        return
    end
    
    if tier < 1 or tier > 3 then
        TriggerClientEvent('QBCore:Notify', src, 'Tier must be 1-3', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    -- Initialize bodyguard data if needed
    if not activeBodyguards[targetId] then
        activeBodyguards[targetId] = { guards = {}, expireTime = 0 }
    end
    
    if #activeBodyguards[targetId].guards >= Config.MaxBodyguards then
        TriggerClientEvent('QBCore:Notify', src, 'Player already has max bodyguards', 'error')
        return
    end
    
    -- Add bodyguard
    local guardId = #activeBodyguards[targetId].guards + 1
    table.insert(activeBodyguards[targetId].guards, {
        tier = tier,
        spawnTime = os.time()
    })
    
    local tierConfig = Config.BodyguardTiers[tier]
    local expireTime = os.time() + (tierConfig.duration * 60)
    if expireTime > activeBodyguards[targetId].expireTime then
        activeBodyguards[targetId].expireTime = expireTime
    end
    
    TriggerClientEvent('prelude-npc:client:spawnBodyguard', targetId, tier, guardId)
    TriggerClientEvent('QBCore:Notify', src, 'Bodyguard given to player '..targetId, 'success')
    TriggerClientEvent('QBCore:Notify', targetId, 'You received a tier '..tier..' bodyguard!', 'success')
end)

RegisterNetEvent('prelude-npc:server:adminClearBodyguards', function(targetId)
    local src = source
    
    -- Check if source has admin permission
    local Player = GetPlayer(src)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission!', 'error')
        return
    end
    
    targetId = tonumber(targetId)
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player ID', 'error')
        return
    end
    
    if activeBodyguards[targetId] then
        activeBodyguards[targetId] = nil
        TriggerClientEvent('prelude-npc:client:dismissAllBodyguards', targetId)
        TriggerClientEvent('QBCore:Notify', src, 'Cleared bodyguards from player '..targetId, 'success')
        TriggerClientEvent('QBCore:Notify', targetId, 'Your bodyguards were dismissed', 'error')
    else
        TriggerClientEvent('QBCore:Notify', src, 'Player has no bodyguards', 'error')
    end
end)

-- Hunter spawn request handler
RegisterNetEvent('prelude-npc:server:requestPlayerCoords', function(targetId, level, count, hunterType)
    local src = source
    
    -- Check if source has admin permission
    local Player = GetPlayer(src)
    if not Player then return end
    
    if not QBCore.Functions.HasPermission(src, 'admin') then
        TriggerClientEvent('QBCore:Notify', src, 'You do not have permission!', 'error')
        return
    end
    
    targetId = tonumber(targetId)
    level = tonumber(level) or 1
    count = tonumber(count) or 1
    
    if not targetId then
        TriggerClientEvent('QBCore:Notify', src, 'Invalid player ID', 'error')
        return
    end
    
    local targetPlayer = QBCore.Functions.GetPlayer(targetId)
    if not targetPlayer then
        TriggerClientEvent('QBCore:Notify', src, 'Player not found', 'error')
        return
    end
    
    -- Get target player's coordinates
    local targetPed = GetPlayerPed(targetId)
    if targetPed == 0 then
        TriggerClientEvent('QBCore:Notify', src, 'Failed to get player position', 'error')
        return
    end
    
    local targetCoords = GetEntityCoords(targetPed)
    
    -- Trigger spawn on the requesting admin's client
    TriggerClientEvent('prelude-npc:client:spawnHunterAtCoords', src, targetCoords, targetId, level, count, hunterType)
end)

