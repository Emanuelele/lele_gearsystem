-- Server-side handler per danni al motore
RegisterNetEvent("lele_gearsystem:applyEngineDamage")
AddEventHandler("lele_gearsystem:applyEngineDamage", function(vehicle, damage)
    if DoesEntityExist(vehicle) then
        local currentHealth = GetVehicleEngineHealth(vehicle)
        SetVehicleEngineHealth(vehicle, currentHealth * damage)
        TriggerEvent("lele_gearsystem:turnOffVehicle", vehicle)
    end
end)

-- Server-side evento per spegnere il veicolo
RegisterNetEvent("lele_gearsystem:turnOffVehicle")
AddEventHandler("lele_gearsystem:turnOffVehicle", function(vehicle)
    if DoesEntityExist(vehicle) then
        SetVehicleEngineOn(vehicle, false, true, true)
    end
end)