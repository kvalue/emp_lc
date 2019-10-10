local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')
vRP = Proxy.getInterface('vRP')
vRPclient = Tunnel.getInterface('vRP')
emP = {}
Tunnel.bindInterface('emp_lc2', emP)

-------------------------------------------------------
--------------------  CONFIG  -------------------------
local lc_permission = 'admin.permissao'
local lc_cooldown = 60 * 5 -- em segundos
local lc_scramble = 60 * 30 -- em segundos ( a cada x segundos os lugares dos veiculos vao mudar )
local vehicles = {
    [1] = {model = 'nmax155', name = 'Policia1', reward = 50000},
    [2] = {model = 'nmax155', name = 'Policia2', reward = 1000},
    [3] = {model = 'nmax155', name = 'Policia3', reward = 22000},
    [4] = {model = 'nmax155', name = 'Policia4', reward = 700},
    [5] = {model = 'nmax155', name = 'Policia4', reward = 700},
    [6] = {model = 'nmax155', name = 'Policia4', reward = 700},
    [7] = {model = 'nmax155', name = 'Policia4', reward = 700}
}
-------------------------------------------------------

local happening = false
local cooldown = false
local seconds = 0
local secondstoscramble = 0

function scramble()
    secondstoscramble = lc_scramble
    local old_vehicles = vehicles
    vehicles = {}

    while #vehicles ~= #old_vehicles do
        Citizen.Wait(1)
        local rndindex = math.random(#old_vehicles)

        if vehicles[rndindex] == nil then
            vehicles[rndindex] = old_vehicles[rndindex]
        end
    end
    
    TriggerClientEvent('lc_client:updatevehicles', -1, vehicles)
end

function emP.hasPermission()

    if lc_permission == '' then
        return true
    end

    local user_id = vRP.getUserId(source)
    return vRP.hasPermission(user_id, lc_permission)
end

function emP.hasCooldown()
    return cooldown == true
end

function emP.isHappening()
    return happening == true
end

function emP.setHappening(value)
    happening = value

    if value == false and cooldown == false then
        cooldown = true
        seconds = lc_cooldown
        TriggerClientEvent('lc_client:updatevehicles', -1, {})
    end
end

function emP.networkVehicle(netid)
    print('server received ' .. netid)
    local owner_id = vRP.getUserId(source)
    TriggerClientEvent('lc_client:addblipforvehicle', -1, owner_id, netid)
end

function emP.unNetworkVehicle()
    local owner_id = vRP.getUserId(source)
    TriggerClientEvent('lc_client:removeblipforvehicle', -1, owner_id)
end

function emP.collectReward(index)
    local user_id = vRP.getUserId(source)
    vRP.giveMoney(user_id, vehicles[index].reward)
    TriggerClientEvent('LCNotify', source, '<FONT color="#40f549">+ ~s~R$' .. vRP.format(vehicles[index].reward))
end

Citizen.CreateThread(
    function()
        while true do
            Citizen.Wait(1000)

            if seconds > 0 then
                seconds = seconds - 1
            end

            if seconds <= 0 then
                if cooldown == true then
                    cooldown = false
                    scramble()
                end
            end

            if secondstoscramble > 0 then
                secondstoscramble = secondstoscramble - 1
            end

            if secondstoscramble <= 0 then
                if happening == false and cooldown == false then
                    scramble()
                end
            end
        end
    end
)
AddEventHandler(
    'vRP:playerSpawn',
    function(user_id, source, first_spawn)
        if first_spawn then
            TriggerClientEvent('lc_client:updatevehicles', source, vehicles)
        end
    end
)
