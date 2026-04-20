local spawnedPed = nil
local spawnedVehicle = nil
local jobBlip = nil
local isOnJob = false
local jobZone = nil
local lastLocationIndex = nil

math.randomseed(GetGameTimer())

CreateThread(function()
    local model = GetHashKey(Config.Gardener.Ped.model)
    lib.requestModel(model)

    local blip = AddBlipForCoord(Config.Gardener.Ped.coords.xyz)
    SetBlipSprite(blip, Config.Gardener.Blip.sprite)
    SetBlipDisplay(blip, 4)
    SetBlipScale(blip, Config.Gardener.Blip.scale)
    SetBlipColour(blip, Config.Gardener.Blip.color)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(Config.Gardener.Blip.label)
    EndTextCommandSetBlipName(blip)

    spawnedPed = CreatePed(4, model, Config.Gardener.Ped.coords.x, Config.Gardener.Ped.coords.y, Config.Gardener.Ped.coords.z - 1.0, Config.Gardener.Ped.coords.w, false, true)
    FreezeEntityPosition(spawnedPed, true)
    SetEntityInvincible(spawnedPed, true)
    SetBlockingOfNonTemporaryEvents(spawnedPed, true)

    exports.ox_target:addLocalEntity(spawnedPed, {
        {
            name = 'gardener_start',
            icon = 'fa-solid fa-leaf',
            label = 'Start Brigade',
            canInteract = function() return not isOnJob end,
            onSelect = function()
                StartGardeningJob()
            end
        },
        {
            name = 'gardener_cancel',
            icon = 'fa-solid fa-xmark',
            label = 'End Work',
            canInteract = function() return isOnJob end,
            onSelect = function()
                ResetJob()
                lib.notify({description = 'Work Completed', type = 'inform'})
            end
        }
    })
end)

function StartGardeningJob()
    local playerPed = PlayerPedId()
    local pedCoords = GetEntityCoords(spawnedPed)
    
    TaskTurnPedToFaceCoord(playerPed, pedCoords.x, pedCoords.y, pedCoords.z, 1000)
    Wait(1000) 

    local animDict = 'misscarsteal4@actor'
    local animClip = 'actor_berating_loop'
    lib.requestAnimDict(animDict)

    local success = lib.progressBar({
        duration = 5000,
        label = 'You negotiate a job...',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = animDict,
            clip = animClip,
            flag = 49
        },
    })

    if success then 
        isOnJob = true
        if Config.Gardener.Vehicle.enabled then
            local vModel = GetHashKey(Config.Gardener.Vehicle.model)
            lib.requestModel(vModel)
            spawnedVehicle = CreateVehicle(vModel, Config.Gardener.Vehicle.spawnCoords.x, Config.Gardener.Vehicle.spawnCoords.y, Config.Gardener.Vehicle.spawnCoords.z, Config.Gardener.Vehicle.spawnCoords.w, true, false)
            TaskWarpPedIntoVehicle(PlayerPedId(), spawnedVehicle, -1)
        end
        GenerateNewTask()
    else
        lib.notify({description = 'The deal failed....', type = 'error'})
    end
end

function GenerateNewTask()
    if not isOnJob then return end

    if DoesBlipExist(jobBlip) then RemoveBlip(jobBlip) end
    if jobZone then jobZone:remove() end

    local locations = Config.Locations
    local randomIndex = math.random(1, #locations)
    
    if #locations > 1 then
        while randomIndex == lastLocationIndex do
            randomIndex = math.random(1, #locations)
        end
    end
    
    lastLocationIndex = randomIndex
    local randomLoc = locations[randomIndex]

    TriggerServerEvent('ykaa_gardener:setNextLocation', randomLoc.coords)

    jobBlip = AddBlipForCoord(randomLoc.coords.xyz)
    SetBlipSprite(jobBlip, 1)
    SetBlipColour(jobBlip, 5)
    SetBlipRoute(jobBlip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString("Leaves")
    EndTextCommandSetBlipName(jobBlip)

    lib.notify({title = 'Gardener', description = 'New location marked!', type = 'inform'})

    jobZone = lib.zones.sphere({
        coords = randomLoc.coords.xyz,
        radius = 3.0,
        debug = Config.Debug,
        inside = function()
            lib.showTextUI('[E] - Vacuum Leaves')
            if IsControlJustPressed(0, 38) then
                lib.hideTextUI()
                FinishWork()
            end
        end,
        onExit = function()
            lib.hideTextUI()
        end
    })
end

function FinishWork()
    TriggerServerEvent('ykaa_gardener:startWork')

    local animDict = "amb@world_human_gardener_leaf_blower@idle_a"
    lib.requestAnimDict(animDict)

    local success = lib.progressBar({
        duration = 8000,
        label = 'You vacuum the leaves....',
        useWhileDead = false,
        canCancel = true,
        disable = { car = true, move = true, combat = true },
        anim = {
            dict = animDict,
            clip = "idle_a"
        },
        prop = {
            model = `prop_leaf_blower_01`,
            bone = 28422,
            pos = vec3(0.01, 0.0, 0.0),
            rot = vec3(0.0, 0.0, 0.0)
        }
    })

    if success then
        TriggerServerEvent('ykaa_gardener:giveReward')
        lib.notify({title = 'Gardener', description = 'Money paid out!', type = 'success'})
        GenerateNewTask()
    else
        lib.notify({description = 'You stopped vacuuming....', type = 'error'})
    end
end

function ResetJob()
    isOnJob = false
    lastLocationIndex = nil
    if DoesBlipExist(jobBlip) then RemoveBlip(jobBlip) end
    if jobZone then jobZone:remove() end
    if Config.Gardener.Vehicle.enabled and DoesEntityExist(spawnedVehicle) then
        DeleteVehicle(spawnedVehicle)
        spawnedVehicle = nil
    end
    lib.hideTextUI()
end
