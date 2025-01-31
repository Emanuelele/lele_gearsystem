local currentVehicle, currentGear
local animationDict = "veh@driveby@first_person@passenger_rear_right_handed@smg"
local animationName = "outro_90r"
local acc, topspeedGTA, topspeedms, currspeedlimit, gears
local canSwitchGear
local speed, minspeed

function startVehicleThreads()
    Citizen.CreateThread(function() 
        --Contorlli sulla velocità
        while currentVehicle and IsPedInAnyVehicle(PlayerPedId(), false) do

            --Calcolo valori di controllo
            speed = GetEntitySpeed(currentVehicle)
            minspeed = currspeedlimit * 0.5

            --Controllo velocità troppo elevate o troppo basse
            if speed >= currspeedlimit then
                SetVehicleCurrentRpm(currentVehicle, 0.99)
                SetVehicleCheatPowerIncrease(currentVehicle, 0.0)
            elseif speed < minspeed and currentGear > 2 and GetVehicleCurrentRpm(currentVehicle) > 0.20 then
                SetVehicleEngineOn(currentVehicle, false, true, true)
            elseif currentGear == -1 then
                if IsControlPressed(0, 71) then
                    SetVehicleCurrentRpm(currentVehicle, 0.99)
                end
                SetVehicleCheatPowerIncrease(currentVehicle, 0.0)
            end

            --Blocco comandi indetro/avanti in base alla marcia
            if currentGear > 0 and speed < 1 then
                DisableControlAction(0, 72, true)
            elseif currentGear == 0 and speed < 1 then
                DisableControlAction(0, 71, true)
            end

            --hud di test (da rimuovere a script ultimato e mettere nell'hud tramite export)
            if Config.gearhud then
                drawTextFrame({
                    msg = string.format(
                        "Marcia: %d    Giri: %.2f   Vel min: %.2f   Vel: %.2f   Vel max: %.2f   Vel rott: %.2f",
                        currentGear, 
                        GetVehicleCurrentRpm(currentVehicle), 
                        minspeed, 
                        speed,
                        currspeedlimit,
                        currspeedlimit * 1.6 + 5
                    ), 
                    x = 0.8, 
                    y = 0.8
                })
            end
            Citizen.Wait(0)
        end
        --Quando l'utente esce dal veicolo, rimposto i valori a quelli iniziali
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", acc)
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        SetVehicleHighGear(currentVehicle, gears)
        ModifyVehicleTopSpeed(currentVehicle, 1)
        currentVehicle = nil
    end)
end

--Controllo quando l'utente entra in un veicolo
AddEventHandler('gameEventTriggered', function(eventName, args)
    if eventName == "CEventNetworkPlayerEnteredVehicle" then
        local playerId = args[1]
        local vehicle = args[2]
        if playerId == PlayerId() and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() and not currentVehicle then
            --Inizializzo i dati e salvo i dati da ripristinare 
            currentVehicle = vehicle
            gears = GetVehicleHighGear(currentVehicle)
            topspeedGTA = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
            topspeedms = (topspeedGTA * 1.32) / 3.6
            acc = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce")
            currspeedlimit = 0
            currentGear = -1
            canSwitchGear = true
            startVehicleThreads()
        end
    end
end)

--Funzione per fare l'animazione del cambio marcia
function PlayGearChangeAnimation()
    Citizen.CreateThread(function()
        RequestAnimDict(animationDict)
        while not HasAnimDictLoaded(animationDict) do
            Citizen.Wait(0)
        end
        TaskPlayAnim(PlayerPedId(), animationDict, animationName, 2.5, 1.0, 100, 16, 0, false, false, false)
        Citizen.Wait(100)
        StopAnimTask(PlayerPedId(), animationDict, animationName, 1.0)
        RemoveAnimDict(animationDict)
    end)
end

--Funzione per riprodurre il suono del cambio marcia
function PlayGearChangeSound()
    SendNUIMessage({
        transactionType = 'playSound',
        transactionVolume = 0.5
    })
end

--Comando marcia inferiore
RegisterCommand('gearsu', function()
    --Contorllo che l'utente sia nel veicolo
    if not currentVehicle or not IsPedInAnyVehicle(PlayerPedId(), false) then return end
    --Creo il thread del cambio marcia
    Citizen.CreateThread(function()
        --logica di cambio marcia
        if currentVehicle and currentGear < gears and canSwitchGear  then
            canSwitchGear = false
            if currentGear == -1 then
                currentGear = 1
            elseif currentGear == 0 then
                currentGear = -1
            else
                currentGear = currentGear + 1
            end
             --Simulo il cambio marcia
            simulateGears()
            --Applico l'attesa tra un cambio marcia e l'altro
            Citizen.Wait(Config.wait)
            canSwitchGear = true
        end
    end)
end, false)

--Comando marcia superiore
RegisterCommand('geargiu', function()
    --Contorllo che l'utente sia nel veicolo
    if not currentVehicle or not IsPedInAnyVehicle(PlayerPedId(), false) then return end
    --Creo il thread del cambio marcia
    Citizen.CreateThread(function()
        --logica di cambio marcia
        if currentVehicle and currentGear ~= 0 and canSwitchGear then
            canSwitchGear = false
            if currentGear == 1 then
                currentGear = -1
            elseif currentGear == -1 then
                currentGear = 0
            else
                currentGear = currentGear - 1
            end
            --Simulo il cambio marcia
            simulateGears()
            --Applico l'attesa tra un cambio marcia e l'altro
            Citizen.Wait(Config.wait)
            canSwitchGear = true
        end
    end)
end, false)

--Comando marcia folle
RegisterCommand('gearfolle', function()
    --Contorllo che l'utente sia nel veicolo
    if not currentVehicle or not IsPedInAnyVehicle(PlayerPedId(), false) then return end
    --Creo il thread del cambio marcia
    Citizen.CreateThread(function()
        if currentVehicle and currentGear ~= 0 and canSwitchGear then
            canSwitchGear = false
            currentGear = -1
            --Simulo il cambio marcia
            simulateGears()
            Citizen.Wait(Config.wait)
            canSwitchGear = true
        end
    end)
end, false)

--Key mapping dei comandi sulle marce
RegisterKeyMapping('gearsu', 'Cambio marcia (in su)', 'keyboard', 'LSHIFT')
RegisterKeyMapping('geargiu', 'Cambio marcia (in giù)', 'keyboard', 'LCONTROL')
RegisterKeyMapping('gearfolle', 'Cambio marcia (in folle)', 'keyboard', '')

--Funzione per simulare il cambio marcia
function simulateGears()
    --Starto animazioni e suoni
    PlayGearChangeAnimation()
    PlayGearChangeSound()
    --marcia positiva
    if currentGear > 0 then
        --calcolo ratio di cambio 
        local ratio = Config.gears[gears][currentGear] * (1 / 0.9)
        --Imposto il veicolo ad una sola marcia
        SetVehicleHighGear(currentVehicle, 1)
        --Calcolo i valori di accelerazione e velocità
        local newacc = ratio * acc
        local newtopspeedGTA = topspeedGTA / ratio
        local newtopspeedms = topspeedms / ratio
        --Applico i nuovi valori appena calcolati
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", newacc)
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", newtopspeedGTA)
        ModifyVehicleTopSpeed(currentVehicle, 1)
        --Aggiorno il limite di velocità per la marcia selezionata
        currspeedlimit = newtopspeedms

        --Controllo sulla velocità per applicare danni in caso di cambio marcia non corretto
        local speed = GetEntitySpeed(currentVehicle)
        if speed >= currspeedlimit * 1.6 then 
            local heal = GetVehicleEngineHealth(currentVehicle)
            heal = heal * 0.9
            SetVehicleEngineHealth(currentVehicle, heal)
            SetVehicleEngineOn(currentVehicle, false, true, false)
        end
    --Retromarcia
    elseif currentGear == 0 then
        --Se la velocità è positiva e maggiore di 10 rompo il motore
        local speed = GetEntitySpeed(currentVehicle)
        if speed > 10 then 
            SetVehicleEngineHealth(currentVehicle, 0)
        end
        --Applico i valori normali del veicolo
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", acc)
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        SetVehicleHighGear(currentVehicle, gears)
        ModifyVehicleTopSpeed(currentVehicle, 1)
    end
end

--Evitiamo di buggare il veicolo se viene stoppata o riavviata la risorsa
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == "lele_gearsystem" then
        --Reimporto i valori a quelli normali
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", acc)
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        SetVehicleHighGear(currentVehicle, gears)
        ModifyVehicleTopSpeed(currentVehicle, 1)
    end
end)

--Funzione per stampare l'hud
function drawTextFrame(data)
    SetTextFont(4)
    SetTextScale(0.0, 0.5)
    SetTextColour(255, 255, 255, 255)
    SetTextDropshadow(0, 0, 0, 0, 255)
    SetTextDropShadow()
    SetTextOutline()
    SetTextCentre(true)
    SetTextEntry('STRING')
    AddTextComponentString(data.msg)
    DrawText(data.x, data.y)
end