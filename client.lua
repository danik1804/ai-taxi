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

local function addTargetToNpc(npc)
    local target = Config.TargetSystem

    if target == 'qtarget' then
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

    elseif target == 'ox_target' then
        exports.ox_target:addLocalEntity(npc, {
            {
                label = 'Promluvit si',
                icon = 'fas fa-taxi',
                onSelect = function()
                    TriggerEvent('aitaxi:startConversation')
                end,
            },
        })

    elseif target == 'qb-target' then
        exports['qb-target']:AddTargetEntity(npc, {
            options = {
                {
                    type = "client",
                    event = "aitaxi:startConversation",
                    icon = "fas fa-taxi",
                    label = "Promluvit si"
                }
            },
            distance = 2.5
        })

    else
        print('[AI Taxi] Neplatný target systém v config.lua: ' .. tostring(target))
    end
end

Citizen.CreateThread(function()
    local npcCoords = Config.NpcCoords
    local npcModel = Config.NpcModel or `a_m_y_business_01`

    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Wait(100)
    end

    local npc = CreatePed(4, npcModel, npcCoords.x, npcCoords.y, npcCoords.z, 0.0, false, true)
    SetEntityInvincible(npc, true)
    FreezeEntityPosition(npc, true)
    SetBlockingOfNonTemporaryEvents(npc, true)

    setNpcLookAtPlayer(npc)
    addTargetToNpc(npc)
end)

RegisterNetEvent('aitaxi:startConversation')
AddEventHandler('aitaxi:startConversation', function()
    local options = {}
    for i, location in ipairs(Config.Locations) do
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

    local taxiSpawn = Config.TaxiSpawnCoords
    local taxi = CreateVehicle(taxiModel, taxiSpawn.x, taxiSpawn.y, taxiSpawn.z, 240.9, true, false)
    SetEntityHeading(taxi, 240.9)
    SetVehicleDoorsLockedForAllPlayers(taxi, false)

    local playerPed = PlayerPedId()

    local npcModel = Config.NpcModel or `a_m_y_business_01`
    RequestModel(npcModel)
    while not HasModelLoaded(npcModel) do
        Citizen.Wait(100)
    end

    local npc = CreatePed(4, npcModel, taxiSpawn.x, taxiSpawn.y, taxiSpawn.z, 240.9, true, false)
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
        label = 'Jedeš taxíkem...',
        useWhileDead = false,
        canCancel = false,
    })

    Citizen.Wait(100)

    local stopDistance = 2.0
    local direction = GetEntityForwardVector(taxi)
    local offsetCoords = coords - (direction * stopDistance)

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

-- Rychlé teleporty
RegisterNetEvent('db_core:TaxiToGarage')
AddEventHandler('db_core:TaxiToGarage', function()
    teleportPlayer(Config.Locations[1].coords, Config.Locations[1].heading)
end)

RegisterNetEvent('db_core:TaxiToPD')
AddEventHandler('db_core:TaxiToPD', function()
    teleportPlayer(Config.Locations[2].coords, Config.Locations[2].heading)
end)

RegisterNetEvent('db_core:TaxiToDL')
AddEventHandler('db_core:TaxiToDL', function()
    teleportPlayer(Config.Locations[3].coords, Config.Locations[3].heading)
end)

RegisterNetEvent('db_core:TaxiToBank')
AddEventHandler('db_core:TaxiToBank', function()
    teleportPlayer(Config.Locations[4].coords, Config.Locations[4].heading)
end)

RegisterNetEvent('db_core:TaxiToTH')
AddEventHandler('db_core:TaxiToTH', function()
    teleportPlayer(Config.Locations[5].coords, Config.Locations[5].heading)
end)
