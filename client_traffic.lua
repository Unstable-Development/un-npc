-- Traffic Speed Control
-- Raises AI vehicle cruise speeds to feel more natural

local CRUISE_SPEED = 25.0    -- m/s: 15=34mph, 20=45mph, 25=56mph, 40=90mph, 60=134mph (unrealistic)
local UPDATE_INTERVAL = 3000 -- ms between updates
local DRIVE_STYLE = 786603   -- normal driving: avoids vehicles/peds/objects
local DEBUG = true           -- set false once confirmed working

print("[traffic] client_traffic.lua LOADED")

CreateThread(function()
    print("[traffic] thread STARTED")
    while true do
        Wait(UPDATE_INTERVAL)
        local count = 0

        local handle, veh = FindFirstVehicle()
        local found = true
        while found do
            if DoesEntityExist(veh) and not IsVehicleSeatFree(veh, -1) then
                local driver = GetPedInVehicleSeat(veh, -1)
                if driver ~= 0 and not IsEntityAPlayer(driver) then
                    SetVehicleMaxSpeed(veh, CRUISE_SPEED)
                    TaskVehicleDriveWander(driver, veh, CRUISE_SPEED, DRIVE_STYLE)
                    count = count + 1
                end
            end
            found, veh = FindNextVehicle(handle)
        end
        EndFindVehicle(handle)

        if DEBUG then
            print("[traffic] applied to " .. count .. " AI vehicles")
        end
    end
end)
