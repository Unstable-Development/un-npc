-- Client-side zone and route builder tools
-- Allows admins to create zones and patrol routes in-game

local QBCore = exports['qb-core']:GetCoreObject()

-- Builder state
local zoneBuilderActive = false
local routeBuilderActive = false
local currentZoneData = {}
local currentRouteData = {}
local previewMarker = nil
local waypointMarkers = {}

-- ============================================
-- UTILITY FUNCTIONS
-- ============================================

local function log(msg)
    print(('[prelude-npc] %s'):format(msg))
end

local function DrawText3D(coords, text)
    local onScreen, x, y = World3dToScreen2d(coords.x, coords.y, coords.z)
    if onScreen then
        SetTextScale(0.35, 0.35)
        SetTextFont(4)
        SetTextProportional(1)
        SetTextEntry("STRING")
        SetTextCentre(1)
        AddTextComponentString(text)
        DrawText(x, y)
        local factor = (string.len(text)) / 370
        DrawRect(x, y + 0.0125, 0.015 + factor, 0.03, 0, 0, 0, 75)
    end
end

local function ShowNotification(msg, type)
    QBCore.Functions.Notify(msg, type or 'primary', 5000)
end

-- Draw a circle on the ground
local function DrawCircle(center, radius, r, g, b, a)
    local points = 32
    for i = 0, points do
        local angle1 = (i / points) * 2 * math.pi
        local angle2 = ((i + 1) / points) * 2 * math.pi
        
        local x1 = center.x + radius * math.cos(angle1)
        local y1 = center.y + radius * math.sin(angle1)
        local x2 = center.x + radius * math.cos(angle2)
        local y2 = center.y + radius * math.sin(angle2)
        
        local z1 = center.z
        local z2 = center.z
        
        DrawLine(x1, y1, z1, x2, y2, z2, r, g, b, a)
    end
end

-- ============================================
-- ZONE BUILDER
-- ============================================

-- Initialize zone builder
function StartZoneBuilder()
    if not Config.EnableZoneCreator then
        ShowNotification('Zone creator is disabled in config', 'error')
        return
    end
    
    zoneBuilderActive = true
    currentZoneData = {
        center = nil,
        radius = Config.ZoneBuilder.defaultRadius,
        guardCount = 5,
        pedModels = {'s_m_m_security_01'},
        weapons = {'WEAPON_PISTOL'},
        accuracy = 50,
        health = 200,
        armor = 100,
        requiredItem = nil,
        requiresIdentifier = nil,
    }
    
    ShowNotification('~g~Zone Builder Started~w~\n~y~INSTRUCTIONS:~w~\nPress ~b~E~w~ to set zone center\nScroll to adjust radius\nPress ~r~X~w~ to cancel\nPress ~g~ENTER~w~ to save', 'success')
    
    CreateThread(ZoneBuilderThread)
end

-- Zone builder thread
function ZoneBuilderThread()
    while zoneBuilderActive do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local groundZ = playerCoords.z
        
        -- Get ground Z
        local foundGround, groundPos = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y, playerCoords.z, false)
        if foundGround then
            groundZ = groundPos
        end
        
        local previewCoords = currentZoneData.center or vector3(playerCoords.x, playerCoords.y, groundZ)
        
        -- Draw preview
        DrawMarker(
            Config.ZoneBuilder.markerType,
            previewCoords.x, previewCoords.y, previewCoords.z,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            2.0, 2.0, 2.0,
            Config.ZoneBuilder.markerColor.r,
            Config.ZoneBuilder.markerColor.g,
            Config.ZoneBuilder.markerColor.b,
            Config.ZoneBuilder.markerColor.a,
            false, false, 2, false, nil, nil, false
        )
        
        -- Draw radius circle
        DrawCircle(previewCoords, currentZoneData.radius, 255, 0, 0, 150)
        
        -- Draw info text
        local infoText = string.format(
            '~y~Zone Builder~w~\nRadius: ~b~%.1fm~w~\nGuards: ~b~%d~w~\n\n~g~E~w~: Set Center | ~y~Scroll~w~: Adjust Radius\n~g~ENTER~w~: Save | ~r~X~w~: Cancel',
            currentZoneData.radius,
            currentZoneData.guardCount
        )
        DrawText3D(previewCoords + vector3(0, 0, 1.5), infoText)
        
        -- Set zone center
        if IsControlJustPressed(0, 38) then -- E key
            currentZoneData.center = vector3(playerCoords.x, playerCoords.y, groundZ)
            ShowNotification('Zone center set! Adjust radius with mouse wheel', 'success')
        end
        
        -- Adjust radius
        if currentZoneData.center then
            if IsControlJustPressed(0, 241) then -- Scroll up
                currentZoneData.radius = math.min(currentZoneData.radius + 5.0, Config.ZoneBuilder.maxRadius)
            elseif IsControlJustPressed(0, 242) then -- Scroll down
                currentZoneData.radius = math.max(currentZoneData.radius - 5.0, Config.ZoneBuilder.minRadius)
            end
        end
        
        -- Cancel
        if IsControlJustPressed(0, 73) then -- X key
            zoneBuilderActive = false
            ShowNotification('Zone builder cancelled', 'error')
            return
        end
        
        -- Save
        if IsControlJustPressed(0, 18) and currentZoneData.center then -- ENTER key
            OpenZoneNamingMenu()
            return
        end
    end
end

-- Open menu to name and configure the zone
function OpenZoneNamingMenu()
    local zoneName = nil
    
    -- Use QB input for zone name
    local dialog = exports['qb-input']:ShowInput({
        header = "Create Guard Zone",
        submitText = "Create Zone",
        inputs = {
            {
                text = "Zone Name",
                name = "zoneName",
                type = "text",
                isRequired = true,
                default = ""
            },
            {
                text = "Guard Count",
                name = "guardCount",
                type = "number",
                isRequired = true,
                default = currentZoneData.guardCount
            },
            {
                text = "Required Item (optional)",
                name = "requiredItem",
                type = "text",
                isRequired = false,
                default = ""
            },
            {
                text = "Guard Health",
                name = "health",
                type = "number",
                isRequired = true,
                default = currentZoneData.health
            },
            {
                text = "Guard Armor",
                name = "armor",
                type = "number",
                isRequired = true,
                default = currentZoneData.armor
            },
            {
                text = "Accuracy (0-100)",
                name = "accuracy",
                type = "number",
                isRequired = true,
                default = currentZoneData.accuracy
            },
        }
    })
    
    if dialog then
        currentZoneData.name = dialog.zoneName
        currentZoneData.guardCount = tonumber(dialog.guardCount) or 5
        currentZoneData.requiredItem = dialog.requiredItem ~= "" and dialog.requiredItem or nil
        currentZoneData.health = tonumber(dialog.health) or 200
        currentZoneData.armor = tonumber(dialog.armor) or 100
        currentZoneData.accuracy = tonumber(dialog.accuracy) or 50
        
        -- Send to server to create
        TriggerServerEvent('prelude-npc:server:createGuardZone', currentZoneData)
        zoneBuilderActive = false
        ShowNotification('Zone creation request sent!', 'success')
    else
        zoneBuilderActive = false
        ShowNotification('Zone creation cancelled', 'error')
    end
end

-- ============================================
-- ROUTE BUILDER
-- ============================================

-- Initialize route builder
function StartRouteBuilder()
    if not Config.EnableRouteBuilder then
        ShowNotification('Route builder is disabled in config', 'error')
        return
    end
    
    routeBuilderActive = true
    currentRouteData = {
        waypoints = {},
        vehicleModel = 'police',
        pedModel = 's_m_y_cop_01',
        weapon = 'WEAPON_PISTOL',
        speed = 25.0,
        guardZone = nil,
    }
    
    waypointMarkers = {}
    
    ShowNotification('~g~Route Builder Started~w~\n~y~INSTRUCTIONS:~w~\nPress ~b~E~w~ to add waypoint\nPress ~y~Z~w~ to undo last waypoint\nPress ~r~X~w~ to cancel\nPress ~g~ENTER~w~ to save (min 2 waypoints)', 'success')
    
    CreateThread(RouteBuilderThread)
end

-- Route builder thread
function RouteBuilderThread()
    while routeBuilderActive do
        Wait(0)
        
        local playerPed = PlayerPedId()
        local playerCoords = GetEntityCoords(playerPed)
        local playerHeading = GetEntityHeading(playerPed)
        
        -- Draw current waypoints
        for i, wp in ipairs(currentRouteData.waypoints) do
            DrawMarker(
                Config.RouteBuilder.waypointMarker,
                wp.x, wp.y, wp.z,
                0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                1.5, 1.5, 1.5,
                Config.RouteBuilder.waypointColor.r,
                Config.RouteBuilder.waypointColor.g,
                Config.RouteBuilder.waypointColor.b,
                Config.RouteBuilder.waypointColor.a,
                false, false, 2, false, nil, nil, false
            )
            
            DrawText3D(wp, string.format('WP #%d', i))
            
            -- Draw connection line to next waypoint
            if Config.RouteBuilder.showConnections and i < #currentRouteData.waypoints then
                local nextWp = currentRouteData.waypoints[i + 1]
                DrawLine(
                    wp.x, wp.y, wp.z,
                    nextWp.x, nextWp.y, nextWp.z,
                    0, 255, 255, 200
                )
            end
        end
        
        -- Draw preview for next waypoint
        local groundZ = playerCoords.z
        local foundGround, groundPos = GetGroundZFor_3dCoord(playerCoords.x, playerCoords.y, playerCoords.z, false)
        if foundGround then
            groundZ = groundPos
        end
        
        local previewPos = vector3(playerCoords.x, playerCoords.y, groundZ)
        DrawMarker(
            Config.RouteBuilder.waypointMarker,
            previewPos.x, previewPos.y, previewPos.z + 0.5,
            0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
            1.0, 1.0, 1.0,
            0, 255, 0, 100,
            false, true, 2, false, nil, nil, false
        )
        
        -- Info text
        local infoText = string.format(
            '~y~Route Builder~w~\nWaypoints: ~b~%d~w~ / %d\n\n~g~E~w~: Add Waypoint | ~y~Z~w~: Undo\n~g~ENTER~w~: Save | ~r~X~w~: Cancel',
            #currentRouteData.waypoints,
            Config.RouteBuilder.maxWaypoints
        )
        DrawText3D(previewPos + vector3(0, 0, 2.0), infoText)
        
        -- Add waypoint
        if IsControlJustPressed(0, 38) then -- E key
            if #currentRouteData.waypoints < Config.RouteBuilder.maxWaypoints then
                table.insert(currentRouteData.waypoints, vector4(previewPos.x, previewPos.y, previewPos.z, playerHeading))
                ShowNotification(string.format('Waypoint #%d added', #currentRouteData.waypoints), 'success')
            else
                ShowNotification('Maximum waypoints reached!', 'error')
            end
        end
        
        -- Undo last waypoint
        if IsControlJustPressed(0, 20) then -- Z key
            if #currentRouteData.waypoints > 0 then
                table.remove(currentRouteData.waypoints)
                ShowNotification('Last waypoint removed', 'error')
            end
        end
        
        -- Cancel
        if IsControlJustPressed(0, 73) then -- X key
            routeBuilderActive = false
            ShowNotification('Route builder cancelled', 'error')
            return
        end
        
        -- Save
        if IsControlJustPressed(0, 18) and #currentRouteData.waypoints >= Config.RouteBuilder.minWaypoints then -- ENTER key
            OpenRouteNamingMenu()
            return
        elseif IsControlJustPressed(0, 18) then
            ShowNotification(string.format('Need at least %d waypoints!', Config.RouteBuilder.minWaypoints), 'error')
        end
    end
end

-- Open menu to name and configure the route
function OpenRouteNamingMenu()
    local dialog = exports['qb-input']:ShowInput({
        header = "Create Patrol Route",
        submitText = "Create Route",
        inputs = {
            {
                text = "Route Name",
                name = "routeName",
                type = "text",
                isRequired = true,
                default = ""
            },
            {
                text = "Vehicle Model",
                name = "vehicleModel",
                type = "text",
                isRequired = true,
                default = currentRouteData.vehicleModel
            },
            {
                text = "Ped Model",
                name = "pedModel",
                type = "text",
                isRequired = true,
                default = currentRouteData.pedModel
            },
            {
                text = "Weapon",
                name = "weapon",
                type = "text",
                isRequired = true,
                default = currentRouteData.weapon
            },
            {
                text = "Patrol Speed (mph)",
                name = "speed",
                type = "number",
                isRequired = true,
                default = currentRouteData.speed
            },
            {
                text = "Guard Zone Name (optional)",
                name = "guardZone",
                type = "text",
                isRequired = false,
                default = ""
            },
        }
    })
    
    if dialog then
        currentRouteData.name = dialog.routeName
        currentRouteData.vehicleModel = dialog.vehicleModel
        currentRouteData.pedModel = dialog.pedModel
        currentRouteData.weapon = dialog.weapon
        currentRouteData.speed = tonumber(dialog.speed) or 25.0
        currentRouteData.guardZone = dialog.guardZone ~= "" and dialog.guardZone or nil
        
        -- Send to server to create
        TriggerServerEvent('prelude-npc:server:createPatrolRoute', currentRouteData)
        routeBuilderActive = false
        ShowNotification('Patrol route creation request sent!', 'success')
    else
        routeBuilderActive = false
        ShowNotification('Route creation cancelled', 'error')
    end
end

-- ============================================
-- COMMANDS
-- ============================================

-- Zone builder command
RegisterCommand('createzone', function()
    if QBCore.Functions.HasPermission(source, Config.AdminPermissions.createZones) then
        StartZoneBuilder()
    else
        ShowNotification('You do not have permission to use this command!', 'error')
    end
end, false)

-- Route builder command
RegisterCommand('createroute', function()
    if QBCore.Functions.HasPermission(source, Config.AdminPermissions.createZones) then
        StartRouteBuilder()
    else
        ShowNotification('You do not have permission to use this command!', 'error')
    end
end, false)

-- ============================================
-- EVENTS
-- ============================================

-- Reload zones from server
RegisterNetEvent('prelude-npc:client:reloadZones', function()
    ShowNotification('Guard zones reloaded from database', 'success')
    TriggerServerEvent('prelude-npc:server:getGuardZones')
end)

-- Reload patrols from server  
RegisterNetEvent('prelude-npc:client:reloadPatrols', function()
    ShowNotification('Patrol routes reloaded from database', 'success')
    TriggerServerEvent('prelude-npc:server:getPatrolRoutes')
end)

-- Receive zones from server
RegisterNetEvent('prelude-npc:client:receiveGuardZones', function(zones)
    if not zones then return end
    log(('Received %d guard zones from server'):format(#zones))
    
    -- Update Config.GuardZones with database data
    Config.GuardZones = zones
end)

-- Receive patrols from server
RegisterNetEvent('prelude-npc:client:receivePatrolRoutes', function(dbPatrols)
    if not dbPatrols then return end
    log(('Received %d patrol routes from server'):format(#dbPatrols))

    -- Merge: config routes take priority (they have spawnPoints, requiredJob, etc.)
    -- Only append DB routes that are admin-created (isCustom) and not already in config
    for _, dbRoute in ipairs(dbPatrols) do
        if dbRoute.isCustom then
            local found = false
            for _, cfgRoute in ipairs(Config.PatrolRoutes) do
                if cfgRoute.name == dbRoute.name then
                    found = true
                    break
                end
            end
            if not found then
                table.insert(Config.PatrolRoutes, dbRoute)
                log(('Added custom DB patrol route: %s'):format(dbRoute.name))
            end
        end
    end
end)

-- ============================================
-- INITIALIZATION
-- ============================================

CreateThread(function()
    Wait(2000)
    
    if Config.UseDatabase then
        log('Requesting guard zones and patrol routes from server...')
        TriggerServerEvent('prelude-npc:server:getGuardZones')
        TriggerServerEvent('prelude-npc:server:getPatrolRoutes')
    end
end)
