local ESX = exports["es_extended"]:getSharedObject()
local playerTasks = {} 

RegisterNetEvent('ykaa_gardener:setNextLocation')
AddEventHandler('ykaa_gardener:setNextLocation', function(coords)
    local _source = source
    playerTasks[_source] = {
        coords = coords,
        startTime = os.time(),
        canEarn = true
    }
end)

RegisterNetEvent('ykaa_gardener:giveReward')
AddEventHandler('ykaa_gardener:giveReward', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    local task = playerTasks[_source]

    if not xPlayer or not task or not task.canEarn then return end

    local playerPed = GetPlayerPed(_source)
    local playerCoords = GetEntityCoords(playerPed)

    local distance = #(playerCoords - vector3(task.coords.x, task.coords.y, task.coords.z))
    if distance > 15.0 then 
        return
    end

    if (os.time() - task.startTime) < 7 then
        return
    end

    playerTasks[_source].canEarn = false 

    local price = math.random(50, 80)
    xPlayer.addMoney(price)
    
    TriggerClientEvent('ox_lib:notify', _source, {
        title = 'Gardener', 
        description = 'You got paid. $'..price, 
        type = 'success', 
        position = 'top-right', 
        icon = 'money-bill-wave'
    })
end)

AddEventHandler('playerDropped', function()
    playerTasks[source] = nil
end)
