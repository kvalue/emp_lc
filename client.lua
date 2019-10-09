local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')
local Tools = module('vrp', 'lib/Tools')
emP = Tunnel.getInterface('emp_lc2')
vRP = Proxy.getInterface('vRP')

local happening = false
local startingPoints = {
	[1] = {-774.19, -254.45, 37.10},
	[2] = {-231.64, -1170.94, 22.83},
	[3] = {925.59, -8.79, 78.76},
	[4] = {-506.18, -2191.37, 6.53},
	[5] = {1209.15, 2712.03, 38.00},
	[6] = {1181.46, -334.74, 69.17},
	[7] = {2567.72, 362.65, 108.45}
}
local endingPoints = {
	[1] = {-774.19, -254.45, 37.10},
	[2] = {-231.64, -1170.94, 22.83},
	[3] = {925.59, -8.79, 78.76},
	[4] = {-506.18, -2191.37, 6.53},
	[5] = {1209.15, 2712.03, 38.00},
	[6] = {1181.46, -334.74, 69.17},
	[7] = {2567.72, 362.65, 108.45}
}
local selectedIndex = nil
local endingIndex = nil
local vehicles = {}
local seconds = 0
local empVehicle = nil
local endingBlip = nil

Citizen.CreateThread(
	function()
		while true do
			Citizen.Wait(1)

			local ped = PlayerPedId()

			if happening == false then
				local pedCoords = GetEntityCoords(ped)
				for index, values in pairs(startingPoints) do
					local x, y, z = table.unpack(values)

					local distance = Vdist2(pedCoords, x, y, z)

					if distance <= 50.0 then
						DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 72, 120, 0, 0, 0, 0)
					end

					if distance <= 3.0 then
						if vehicles[index] then
							if not IsPedInAnyVehicle(ped, true) then
								drawHelpTxt('Pressione ~INPUT_PICKUP~ parar roubar um <FONT color="#8de090">' .. vehicles[index].name .. '~s~.')

								if IsControlJustPressed(0, 38) then -- Press E BUTTON
									if emP.hasPermission() then
										if not emP.hasCooldown() then
											if not emP.isHappening() then
												empVehicle = spawnVehicle(vehicles[index].model)
												selectedIndex = index
												seconds = 5
												happening = true
												emP.setHappening(true)
												emP.networkVehicle(VehToNet(empVehicle))
												TriggerEvent('LCNotify', '~o~A policia foi alertada do roubo e estará seguindo-o pelo rastreador.')
											else
												TriggerEvent('LCNotify', '~r~Aguarde o roubo em andamento terminar.')
											end
										else
											TriggerEvent('LCNotify', '~r~Não temos carros pra voce no momento, volte mais tarde.')
										end
									else
										TriggerEvent('LCNotify', '~r~Você não tem permissão.')
									end
								end
							else
								drawHelpTxt('Você precisa estar a pé.')
							end
						else
							drawHelpTxt('Nenhum veiculo disponivel, volte mais tarde!')
						end
					end
				end
			end

			if happening == true and seconds <= 0 and endingIndex ~= nil then
				local pedCoords = GetEntityCoords(ped)
				local x, y, z = table.unpack(endingPoints[endingIndex])

				local distance = Vdist2(pedCoords, x, y, z)

				if distance <= 50.0 then
					DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 72, 120, 0, 0, 0, 0)
				end

				if distance <= 3.0 then
					-- Draw help text
					-- Draw text
					if IsPedInAnyVehicle(ped, true) then
						if IsPedInVehicle(ped, empVehicle, true) then
							drawHelpTxt('Pressione ~INPUT_PICKUP~ para vender o <FONT color="#8de090">' .. vehicles[selectedIndex].name .. '~s~ por R$' .. format(vehicles[selectedIndex].reward) .. '~s~.')

							if IsControlJustPressed(0, 38) then -- Press E BUTTON
								emP.collectReward(selectedIndex)
								DeleteVehicle(empVehicle)
								empVehicle = nil
								seconds = 0
								happening = false
								endingIndex = nil
								selectedIndex = nil
								RemoveBlip(endingBlip)
								endingBlip = nil
								emP.setHappening(false)
								emP.unNetworkVehicle()
							end
						else
							drawHelpTxt('Que carro é esse?')
						end
					else
						drawHelpTxt('Cade o carro que eu pedi?')
					end
				end
			end

			if happening == true then
				if not DoesEntityExist(empVehicle) then
					DeleteVehicle(empVehicle)
					empVehicle = nil
					seconds = 0
					happening = false
					endingIndex = nil
					selectedIndex = nil
					RemoveBlip(endingBlip)
					endingBlip = nil
					emP.setHappening(false)
					emP.unNetworkVehicle()
				else
					if seconds > 0 then
						drawTxt('Rastreador: <FONT color="#8de090">' .. math.floor(seconds / 60) .. ' minutos e ' .. math.floor(seconds % 60) .. ' segundos ~s~restantes', 6, 0.16, 0.87, 0.5, 255, 255, 255, 255)
					end

					if seconds <= 0 then
						drawTxt('Rastreador: <FONT color="#e08d8d">desativado', 6, 0.16, 0.87, 0.5, 255, 255, 255, 255)
						drawTxt('Vá até o local marcado no mapa e venda o veiculo.', 6, 0.16, 0.890, 0.45, 255, 255, 255, 120)
					end

					if seconds <= 0 and endingIndex == nil then
						endingIndex = math.random(#endingPoints)
						endingBlip = addEndingBlip(table.unpack(endingPoints[endingIndex]))
						emP.unNetworkVehicle()
					end

					if empVehicle ~= nil and GetVehicleDoorLockStatus(empVehicle) ~= 1 then
						SetVehicleDoorsLocked(empVehicle, false)
					end
				end
			end
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
		end
	end
)

function drawTxt(text, font, x, y, scale, r, g, b, a)
	SetTextFont(font)
	SetTextScale(scale, scale)
	SetTextColour(r, g, b, a)
	SetTextOutline()
	SetTextEntry('STRING')
	AddTextComponentString(text)
	DrawText(x, y)
end

function drawHelpTxt(text)
	SetTextComponentFormat('STRING')
	AddTextComponentString(text)
	DisplayHelpTextFromStringLabel(0, 0, 1, -1)
end

function _addBlipForEntity(entity)
	local blip = AddBlipForEntity(entity)
	SetBlipSprite(blip, 161)
	SetBlipColour(blip, 6)
	SetBlipScale(blip, 1.4)
	SetBlipAsShortRange(blip, false)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Rastreador')
	EndTextCommandSetBlipName(blip)
	return blip
end

function addEndingBlip(x, y, z)
	local blip = AddBlipForCoord(x, y, z)
	SetBlipSprite(blip, 1)
	SetBlipColour(blip, 5)
	SetBlipScale(blip, 0.4)
	SetBlipAsShortRange(blip, true)
	SetBlipRoute(blip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString('Entrega')
	EndTextCommandSetBlipName(blip)
	return blip
end

function format(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end

RegisterNetEvent('lc_client:updatevehicles')
AddEventHandler(
	'lc_client:updatevehicles',
	function(received)
		vehicles = received
	end
)

local blips = {}

RegisterNetEvent('lc_client:addblipforvehicle')
AddEventHandler(
	'lc_client:addblipforvehicle',
	function(owner_id, netid)
		if blips[owner_id] then
			RemoveBlip(blips[owner_id])
			blips[owner_id] = nil
		end

		blips[owner_id] = _addBlipForEntity(NetToVeh(netid))
	end
)

RegisterNetEvent('lc_client:removeblipforvehicle')
AddEventHandler(
	'lc_client:removeblipforvehicle',
	function(owner_id)
		if blips[owner_id] then
			RemoveBlip(blips[owner_id])
			blips[owner_id] = nil
		end
	end
)

function spawnVehicle(model)
	local mhash = GetHashKey(model)
	RequestModel(mhash)
	while not HasModelLoaded(mhash) do
		Citizen.Wait(10)
	end

	if HasModelLoaded(mhash) then
		local ped = PlayerPedId()
		local nveh = CreateVehicle(mhash, GetEntityCoords(ped), GetEntityHeading(ped), true, false)

		SetVehicleOnGroundProperly(nveh)
		SetEntityAsMissionEntity(nveh, true, true)
		TaskWarpPedIntoVehicle(ped, nveh, -1)

		SetModelAsNoLongerNeeded(mhash)

		TriggerEvent('reparar', nveh)

		return nveh
	end
end

RegisterNetEvent('LCNotify')
AddEventHandler(
	'LCNotify',
	function(text)
		AddTextEntry('MESSAGE_LCNOTIFY', text)
		SetNotificationTextEntry('MESSAGE_LCNOTIFY')
		DrawNotification(true, false)
	end
)