-- Server-side handler per danni al motore
RegisterNetEvent("lele_gearsystem:server:applyEngineDamage")
AddEventHandler("lele_gearsystem:server:applyEngineDamage", function(vehicle, damage)
    if not DoesEntityExist(vehicle) then return end
    TriggerClientEvent("lele_gearsystem:client:applyEngineDamage", -1, vehicle, damage)
end)

-- Server-side evento per spegnere il veicolo
RegisterNetEvent("lele_gearsystem:server:turnOffVehicle")
    if not DoesEntityExist(vehicle) then return end
AddEventHandler("lele_gearsystem:server:turnOffVehicle", function(vehicle)
    TriggerClientEvent("lele_gearsystem:client:turnOffVehicle", -1, vehicle)
end)