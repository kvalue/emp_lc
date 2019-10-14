local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

lcSERVER = {}
Proxy.addInterface('emp_lc', lcSERVER)
Tunnel.bindInterface('emp_lc', lcSERVER)
vRP = Proxy.getInterface('vRP')
lcCLIENT = Tunnel.getInterface('emp_lc')

-------------------------------------------------------
--------------------  CONFIG  -------------------------
local lc_permissao = 'admin.permissao'
local lc_policia = 'policia.permissao'
local lc_policiais = 0 -- Quantidade minima de policias para iniciar o roubo
local lc_cooldown = 60 * 5 -- em segundos
local lc_scramble = 60 * 30 -- em segundos ( a cada x segundos os lugares dos veiculos vao mudar )
local vehicles = {
    [1] = {model = 'zentorno', name = 'Zentorno', reward = 60000},
    [2] = {model = 'italigto', name = 'Itali GTO', reward = 60000},
    [3] = {model = 'jester', name = 'Jester', reward = 60000},
    [4] = {model = 'carbonizzare', name = 'Carbonizzare', reward = 60000},
    [5] = {model = 'elegy', name = 'Elegy', reward = 60000},
    [6] = {model = 'khamelion', name = 'Khamelion', reward = 60000},
    [7] = {model = 'locust', name = 'Locust', reward = 60000}
}
-------------------------------------------------------

local happening = false
local cooldown = false
local seconds = 0
local secondstoscramble = 0

local function scramble()
    secondstoscramble = lc_scramble
    local old_vehicles = vehicles
    vehicles = {}

    for i = 1, #old_vehicles do
        local rndindex = math.random(#old_vehicles)

        while vehicles[rndindex] ~= nil do
            rndindex = math.random(#old_vehicles)
        end

        vehicles[rndindex] = old_vehicles[rndindex]
    end

    lcCLIENT.SyncVehicles(-1, vehicles)
end

function lcSERVER.GetNetworkID(user_id)
    return lcCLIENT.GetNetworkID(vRP.getUserSource(user_id)) 
end

function lcSERVER.HasPermission()
    local user_id = vRP.getUserId(source)

    if lc_policia ~= '' and vRP.hasPermission(user_id, lc_policia) then
        lcCLIENT.Notify(source, '~r~Você é um policial e provavelmente não deveria estar aqui.')
        return false
    end

    if lc_policia ~= '' and #vRP.getUsersByPermission(lc_policia) < lc_policiais then
        lcCLIENT.Notify(source, '~r~Número insuficiente de policiais.')
        return false
    end

    if lc_permissao == '' or vRP.hasPermission(user_id, lc_permissao) then
        return true
    end

    lcCLIENT.Notify(source, '~r~Você não tem permissão.')
    return false
end

function lcSERVER.HasCooldown()
    return cooldown
end

function lcSERVER.IsHappening()
    return happening
end

function lcSERVER.SetHappening(value)
    happening = value

    if value == false and cooldown == false then
        cooldown = true
        seconds = lc_cooldown
        lcCLIENT.SyncVehicles(-1, {})
    end
end

function lcSERVER.RegisterNetworkedVehicle(netid)
    print(netid)
    local user_id = vRP.getUserId(source)

    if lc_policia ~= '' then
        for _, t_id in pairs(vRP.getUsersByPermission(lc_policia)) do
            local t_source = vRP.getUserSource(t_id)
            lcCLIENT.Notify(t_source, '~o~ALERTA ~w~Roubo de veiculo em andamento! Acompanhe-o pelo rastreador.')
        end
    end

    lcCLIENT.AddBlipForNetworkID(-1, user_id, netid)
end

function lcSERVER.UnregisterNetworkedVehicle()
    local owner_id = vRP.getUserId(source)
    lcCLIENT.RemoveBlipFrom(-1, owner_id)
end

function lcSERVER.CollectReward(index)
    local user_id = vRP.getUserId(source)
    vRP.giveInventoryItem(user_id, 'dinheirosujo', vehicles[index].reward)
    lcCLIENT.Notify(source, '<FONT color="#40f549">+ ~s~R$' .. vRP.format(vehicles[index].reward) .. ' em dinheiro sujo')
end

AddEventHandler(
    'vRP:playerSpawn',
    function(user_id, source, first_spawn)
        if first_spawn then
            lcCLIENT.SyncVehicles(source, vehicles)
        end
    end
)

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