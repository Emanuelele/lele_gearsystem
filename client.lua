local currentVehicle, currentGear
local animationDict = "veh@driveby@first_person@passenger_rear_right_handed@smg"
local animationName = "outro_90r"
local acc, topspeedGTA, topspeedms, currspeedlimit, gears
local canSwitchGear
local speed, minspeed

function startVehicleThreads()
    Citizen.CreateThread(function()
        --Triggeriamo l'evento per restituire la marcia corrente
        TriggerEvent("lele_gearsystem:changeGear", formatCurrentGear())

        --Contorlli sulla velocità
        while currentVehicle and IsPedInAnyVehicle(PlayerPedId(), false) do

            --Calcolo valori di velocità
            speed = GetEntitySpeed(currentVehicle)
            minspeed = currspeedlimit * 0.5

            --Controllo delle velocità (sia troppo alte che troppo basse)
            --Velocità troppo alta per la marcia (sei al massimo dei giri)
            if speed >= currspeedlimit then
                --Imposto i giri motore al massimo (altrimenti non ci sarebbe sound)
                SetVehicleCurrentRpm(currentVehicle, 0.99)
                --Tolgo potenza al motore
                SetVehicleCheatPowerIncrease(currentVehicle, 0.0)

            --Velocità troppo bassa (escluse le prime due marce altrimenti sarebbe molto difficile guidare)
            elseif speed < minspeed and currentGear > 2 and GetVehicleCurrentRpm(currentVehicle) > 0.20 then
                --Spengo il motore
                SetVehicleEngineOn(currentVehicle, false, true, true)

            --Marcia inserita folle
            elseif currentGear == -1 then
                --Premo W mentre sono in folle
                if IsControlPressed(0, 71) then
                    --Imposto i giri motore al massimo (altrimenti non ci sarebbe sound)
                    SetVehicleCurrentRpm(currentVehicle, 0.99)
                end
                --Tolgo potenza al motore per simulare la frizione abbassata / folle inserita
                SetVehicleCheatPowerIncrease(currentVehicle, 0.0)
            end

            --Blocco comandi indetro/avanti in base alla marcia
            --Blocco la S per marce positive se la velocità è minore di 1ms (altrimenti non potresti frenare)
            if currentGear > 0 and speed < 1 then
                DisableControlAction(0, 72, true)
            --Blocco la W in retromarcia se la velocità è minore di 1ms (altrimenti non potresti frenare)
            elseif currentGear == 0 and speed < 1 then
                DisableControlAction(0, 71, true)
            end

            Citizen.Wait(0)
        end
        --Quando l'utente esce dal veicolo, rimposto i valori a quelli iniziali
        --Valore di accelerazione
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", acc)
        --Valore di velocità massima
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        --Numero di marce
        SetVehicleHighGear(currentVehicle, gears)
        --Trucchetto per applicare immediatamente i cambiamenti
        ModifyVehicleTopSpeed(currentVehicle, 1)
        --Imposto il veicolo corrente a nil per evitare bug
        currentVehicle = nil
    end)
end

--Controllo quando l'utente entra in un veicolo
AddEventHandler('gameEventTriggered', function(eventName, args)
    --Catturo l'evento di player che entra nel veicolo
    if eventName == "CEventNetworkPlayerEnteredVehicle" then
        local playerId = args[1]
        local vehicle = args[2]
        --Controllo che l'utente entrato nel veicolo sia il client guidatore
        if playerId == PlayerId() and GetPedInVehicleSeat(vehicle, -1) == PlayerPedId() and not currentVehicle then
            --Inizializzo i dati e salvo i dati da ripristinare poi in seguito
            currentVehicle = vehicle
            gears = GetVehicleHighGear(currentVehicle)
            topspeedGTA = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel")
            topspeedms = (topspeedGTA * 1.32) / 3.6
            acc = GetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce")
            currspeedlimit = 0
            currentGear = -1
            canSwitchGear = true
            --Starto il thread di controllo per le marce
            startVehicleThreads()
        end
    end
end)

--Funzione per fare l'animazione del cambio marcia
function PlayGearChangeAnimation()
    Citizen.CreateThread(function()
        --Richiedo il dizionario dell'anim
        RequestAnimDict(animationDict)
        --Aspetto che sia caricato
        while not HasAnimDictLoaded(animationDict) do
            Citizen.Wait(0)
        end
        --Eseguo l'anim
        TaskPlayAnim(PlayerPedId(), animationDict, animationName, 2.5, 1.0, 100, 16, 0, false, false, false)
        Citizen.Wait(100)
        --La stoppo dopo 100ms (altrimenti il braccio nell'anim andrebbe troppo in fuori)
        StopAnimTask(PlayerPedId(), animationDict, animationName, 1.0)
        --Pulisco la memoria
        RemoveAnimDict(animationDict)
    end)
end

--Funzione per riprodurre il suono del cambio marcia
function PlayGearChangeSound()
    --Messaggio alla nui per eseguire il suono
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
        --Accelerazione nuova (per la marcia corrente)
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", newacc)
        --Limite di velocità nuovo (per la marcia corrente)
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", newtopspeedGTA)
        ModifyVehicleTopSpeed(currentVehicle, 1)
        --Aggiorno il limite di velocità per la marcia selezionata
        currspeedlimit = newtopspeedms

        --Controllo sulla velocità per applicare danni in caso di cambio marcia non corretto
        local speed = GetEntitySpeed(currentVehicle)
        --Calcolo della velocità di rottura e controllo della velocità corrente
        if speed >= currspeedlimit * 1.6 then 
            --Calcolo il 10% della vita corrente del veicolo e la rimuovo
            local heal = GetVehicleEngineHealth(currentVehicle)
            heal = heal * 0.9
            SetVehicleEngineHealth(currentVehicle, heal)
            --Spengo il motore
            SetVehicleEngineOn(currentVehicle, false, true, true)
        end
    --Retromarcia
    elseif currentGear == 0 then
        --Se la velocità è positiva e maggiore di 10 rompo il motore
        local speed = GetEntitySpeed(currentVehicle)
        if speed > 10 then 
            SetVehicleEngineHealth(currentVehicle, 0)
        end
        --Applico i valori normali del veicolo
        --Accelerazione
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", acc)
        --Velocità massima
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        --Numero di marce
        SetVehicleHighGear(currentVehicle, gears)
        --Applico le modifiche
        ModifyVehicleTopSpeed(currentVehicle, 1)
    end
    --Triggeriamo l'evento per restituire la marcia corrente
    TriggerEvent("lele_gearsystem:changeGear", formatCurrentGear())
end

--Evitiamo di buggare il veicolo se viene stoppata o riavviata la risorsa
AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == "lele_gearsystem" then
        --Reimporto i valori a quelli normali
        --Accelerazione
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveForce", acc)
        --Velocità massima
        SetVehicleHandlingFloat(currentVehicle, "CHandlingData", "fInitialDriveMaxFlatVel", topspeedGTA)
        --Numero di marce
        SetVehicleHighGear(currentVehicle, gears)
        --Applico le modifiche
        ModifyVehicleTopSpeed(currentVehicle, 1)
    end
end)

--Funzione per formattare le marce in stringhe
function formatCurrentGear()
    local gear = nil
    if currentGear > 0 then
        gear = tostring(currentGear)
    elseif currentGear == 0 then
        gear = "R"
    else
        gear = "N"
    end
    return gear
end

--Registrazione vento per restituire la marcia corrente
RegisterNetEvent("lele_gearsystem:changeGear", function(gear) end)
