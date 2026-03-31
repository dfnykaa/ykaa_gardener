local ESX = exports["es_extended"]:getSharedObject()

RegisterNetEvent('ykaa_gardener:giveReward')
AddEventHandler('ykaa_gardener:giveReward', function()
    local _source = source
    local xPlayer = ESX.GetPlayerFromId(_source)
    
    if xPlayer then
        local price = math.random(150, 300)
        xPlayer.addMoney(price)
        
        TriggerClientEvent('ox_lib:notify', _source, {
            title = 'Gardener', 
            description = 'You got price $'..price, 
            type = 'success', 
            position = 'top-right', 
            icon = 'money-bill-wave'
        })
    end
end)
