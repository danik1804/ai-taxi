local locations = {
    { name = "Hlavní Garáže", coords = vector3(221.2, -789.4, 29.6), heading = 337.1 },
    { name = "LSPD Stanice", coords = vector3(407.5, -988.4, 28.1), heading = 230.4 },
    { name = "Autoškola", coords = vector3(243.5, -1416.2, 29.4), heading = 144.7 },
    { name = "Banka", coords = vector3(152.6, -1027.3, 28.2), heading = 249.6 },
    { name = "Radnice", coords = vector3(-515.8, -263.9, 34.3), heading = 296.2 },
}

local function teleportPlayer(coords, heading)
    local playerPed = PlayerPedId()
    SetEntityCoords(playerPed, coords.x, coords.y, coords.z, false, false, false, true)
    SetEntityHeading(playerPed, heading)
end

local function setNpcLookAtPlayer(npc)
    Citizen.CreateThread(function()
        while true do
            Citizen.Wait(0)
            local playerPed = PlayerPedId()
            local playerCoords = GetEntityCoords(playerPed)
            local npcCoords = GetEntityCoords(npc)

            local heading = GetHeadingFromVector_2d(playerCoords.x - npcCoords.x, playerCoords.y - npcCoords.y)
            SetEntityHeading(npc, heading)
        end
    end)
end

Citizen.CreateThread(function()
    local npcCoords = vector3(-1038.6, -2730.8, 19.1)
    local npcModel = `a_m_y_business_01`

    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end

    local npc = CreatePed(4, npcModel, npcCoords.x, npcCoords.y, npcCoords.z, 0.0, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    setNpcLookAtPlayer(npc)

    exports['qtarget']:AddTargetEntity(npc, {
        options = {
            {
                event = 'aitaxi:startConversation',
                icon = 'fas fa-taxi',
                label = 'Promluvit si',
            },
        },
        distance = 2.5,
    })
end)

RegisterNetEvent('aitaxi:startConversation')
AddEventHandler('aitaxi:startConversation', function()
    local options = {}
    for i, location in ipairs(locations) do
        table.insert(options, {
            title = location.name,
            event = 'aitaxi:selectDestination',
            args = location,
        })
    end

    lib.registerContext({
        id = 'aitaxi_menu',
        title = 'Kam chceš jet?',
        options = options,
    })
    lib.showContext('aitaxi_menu')
end)

RegisterNetEvent('aitaxi:selectDestination')
AddEventHandler('aitaxi:selectDestination', function(location)
    local coords = location.coords
    local heading = location.heading

    local taxiModel = `taxi`
    RequestModel(taxiModel)
    while not HasModelLoaded(taxiModel) do
        Citizen.Wait(100)
    end

    local taxiSpawnCoords = vector3(-1034.3, -2730.1, 20.0)
    local taxi = CreateVehicle(taxiModel, taxiSpawnCoords.x, taxiSpawnCoords.y, taxiSpawnCoords.z, 240.9, true, false)

    SetEntityHeading(taxi, 240.9)
    SetVehicleDoorsLockedForAllPlayers(taxi, false)

    local playerPed = PlayerPedId()

    local npcModel = `a_m_y_business_01`
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Citizen.Wait(100)
    end

    local npc = CreatePed(4, npcModel, taxiSpawnCoords.x, taxiSpawnCoords.y, taxiSpawnCoords.z, 240.9, true, false)

    TaskWarpPedIntoVehicle(npc, taxi, -1)

    SetEntityAsMissionEntity(taxi, true, true) 
    SetPedAsNoLongerNeeded(npc)
    SetEntityInvincible(npc, true) 
    SetBlockingOfNonTemporaryEvents(npc, true) 

    FreezeEntityPosition(taxi, true)

    TaskEnterVehicle(playerPed, taxi, 10000, 2, 1.0, 1, 0)

    while not IsPedInVehicle(playerPed, taxi, false) do
        Citizen.Wait(100)
    end

    FreezeEntityPosition(taxi, false)

    lib.progressBar({
        duration = 10000,
        label = 'Jedeš taxikem...',
        useWhileDead = false,
        canCancel = false,
    })

    Citizen.Wait(100)

    local stopDistance = 2.0 
    local targetCoords = vector3(coords.x, coords.y, coords.z) 
    local direction = GetEntityForwardVector(taxi) 
    local offsetCoords = targetCoords - (direction * stopDistance) 

    SetEntityCoords(taxi, offsetCoords.x, offsetCoords.y, offsetCoords.z, false, false, false, true) 
    SetEntityHeading(taxi, heading)

    FreezeEntityPosition(taxi, true)

    TaskLeaveVehicle(playerPed, taxi, 0)
    Citizen.Wait(1000)

    while IsPedInVehicle(playerPed, taxi, false) do
        Citizen.Wait(100)
    end

    FreezeEntityPosition(taxi, false)

    Citizen.Wait(10000)

    DeleteVehicle(taxi)
    DeletePed(npc)
end)

RegisterNetEvent('db_core:TaxiToGarage')
AddEventHandler('db_core:TaxiToGarage', function()
    print('Teleporting to garage')
    teleportPlayer(locations[1].coords, locations[1].heading)
end)

RegisterNetEvent('db_core:TaxiToPD')
AddEventHandler('db_core:TaxiToPD', function()
    print('Teleporting to PD')
    teleportPlayer(locations[2].coords, locations[2].heading)
end)

RegisterNetEvent('db_core:TaxiToDL')
AddEventHandler('db_core:TaxiToDL', function()
    print('Teleporting to DL')
    teleportPlayer(locations[3].coords, locations[3].heading)
end)

RegisterNetEvent('db_core:TaxiToBank')
AddEventHandler('db_core:TaxiToBank', function()
    print('Teleporting to Bank')
    teleportPlayer(locations[4].coords, locations[4].heading)
end)

RegisterNetEvent('db_core:TaxiToTH')
AddEventHandler('db_core:TaxiToTH', function()
    print('Teleporting to Town Hall')
    teleportPlayer(locations[5].coords, locations[5].heading)
end)
