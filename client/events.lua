--Recupero della marcia corrente
RegisterNetEvent("lele_gearsystem:changeGear")

--Sincronizzare i danni al veicolo tra i client
RegisterNetEvent("lele_gearsystem:client:applyEngineDamage")
AddEventHandler("lele_gearsystem:client:applyEngineDamage", function(vehicle, damage)
    if DoesEntityExist(vehicle) then
        local currentHealth = GetVehicleEngineHealth(vehicle)
        SetVehicleEngineHealth(vehicle, currentHealth * damage)
    end
end)

--Sincronizzare lo spegnimento del veicolo tra i client
RegisterNetEvent("lele_gearsystem:client:turnOffVehicle")
AddEventHandler("lele_gearsystem:client:turnOffVehicle", function(vehicle)
    if DoesEntityExist(vehicle) then
        SetVehicleEngineOn(vehicle, false, true, true)
    end
end)