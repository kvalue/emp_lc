local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

lcCLIENT = {}
Tunnel.bindInterface('emp_lc', lcCLIENT)
vRP = Tunnel.getInterface('vRP')
lcSERVER = Tunnel.getInterface('emp_lc')
Proxy.addInterface('emp_lc', lcCLIENT)

local startingPoints = {
	[1] = {-595.40, 28.95, 43.44}, --
	[2] = {-277.47, -1064.10, 25.84}, --
	[3] = {921.90, 47.69, 80.76}, --
	[4] = {-42.45, -785.42, 44.28}, --
	[5] = {-72.95, 146.52, 81.35}, --
	[6] = {-774.23, 305.76, 85.70}, --
	[7] = {-1041.06, -768.85, 19.12} --
}

local endingPoints = {
	[1] = {421.51, -1561.19, 29.28}, --
	[2] = {-77.43, -1393.51, 29.32}, --
	[3] = {167.23, -1273.72, 29.03}, --
	[4] = {824.86, -1056.42, 27.94}, --
	[5] = {681.60, 73.65, 83.34}, --
	[6] = {-1879.96, -307.33, 49.24}, --
	[7] = {-585.68, -754.08, 29.49} --
}

local happening = false
local selectedIndex = nil
local endingIndex = nil
local vehicles = {}
local seconds = 0
local empVehicle = nil
local endingBlip = nil

Citizen.CreateThread(
	function()
		for _, values in pairs(startingPoints) do
			local blip = AddBlipForCoord(table.unpack(values))
			SetBlipSprite(blip, 225)
			SetBlipColour(blip, 41)
			SetBlipScale(blip, 0.5)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString('Roubo de Veiculo')
			EndTextCommandSetBlipName(blip)
		end

		while true do
			Citizen.Wait(1)

			local ped = PlayerPedId()

			if happening == false then
				local pedCoords = GetEntityCoords(ped)
				for index, values in pairs(startingPoints) do
					local x, y, z = table.unpack(values)

					local distance = Vdist2(pedCoords, x, y, z)

					if distance <= 100.0 then
						DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 72, 120, 0, 0, 0, 0)
					end

					if distance <= 3.0 then
						if vehicles[index] then
							if not IsPedInAnyVehicle(ped, true) then
								drawHelpTxt('Pressione ~INPUT_PICKUP~ parar roubar um <FONT color="#8de090">' .. vehicles[index].name .. '~s~.')

								if IsControlJustPressed(0, 38) then -- Press E BUTTON
									if lcSERVER.HasPermission() then
										if not lcSERVER.HasCooldown() then
											if not lcSERVER.IsHappening() then
												empVehicle = spawnVehicle(vehicles[index].model)
												if empVehicle ~= nil then
													selectedIndex = index
													seconds = 180
													happening = true
													lcSERVER.SetHappening(true)
													lcSERVER.RegisterNetworkedVehicle(VehToNet(empVehicle))
												end
												lcCLIENT.Notify('~o~LC ~s~| Despiste a policia enquanto o rastreador é desativado.')
											else
												lcCLIENT.Notify('~r~Aguarde o roubo em andamento terminar.')
											end
										else
											lcCLIENT.Notify('~r~Não temos carros pra voce no momento, volte mais tarde.')
										end
									end
								end
							else
								drawHelpTxt('~s~Você precisa estar a pé.')
							end
						else
							drawHelpTxt('~s~Nenhum veiculo disponivel, volte mais tarde!')
						end
					end
				end
			end

			if happening == true and seconds <= 0 and endingIndex ~= nil then
				local pedCoords = GetEntityCoords(ped)
				local x, y, z = table.unpack(endingPoints[endingIndex])

				local distance = Vdist2(pedCoords, x, y, z)

				if distance <= 100.0 then
					DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 72, 120, 0, 0, 0, 0)
				end

				if distance <= 3.0 then
					-- Draw help text
					-- Draw text
					if IsPedInAnyVehicle(ped, true) then
						if IsPedInVehicle(ped, empVehicle, true) then
							drawHelpTxt('Pressione ~INPUT_PICKUP~ para vender o <FONT color="#8de090">' .. vehicles[selectedIndex].name .. '~s~ por R$' .. format(vehicles[selectedIndex].reward) .. '~s~.')

							if IsControlJustPressed(0, 38) then -- Press E BUTTON
								lcSERVER.CollectReward(selectedIndex)
								DeleteVehicle(empVehicle)
								empVehicle = nil
								seconds = 0
								happening = false
								endingIndex = nil
								selectedIndex = nil
								RemoveBlip(endingBlip)
								endingBlip = nil
								lcSERVER.SetHappening(false)
								lcSERVER.UnregisterNetworkedVehicle()
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
					lcSERVER.SetHappening(false)
					lcSERVER.UnregisterNetworkedVehicle()
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
						lcSERVER.UnregisterNetworkedVehicle()
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

local blips = {}

function lcCLIENT.SyncVehicles(value)
	vehicles = value
end

function lcCLIENT.GetNetworkID()
	return empVehicle
end

function lcCLIENT.AddBlipForNetworkID(user_id, netid)
	if blips[user_id] then
		RemoveBlip(blips[user_id])
		blips[user_id] = nil
	end

	local entity = NetToEnt(netid)
	while not DoesEntityExist(entity) do
		Citizen.Wait(1)
	end

	blips[user_id] = _addBlipForEntity(entity)

	--[[
	Citizen.CreateThread(
		function()
			while blips[user_id] ~= nil do
				Citizen.Wait(1)

				if not DoesEntityExist(entity) then
					local newid = lcSERVER.GetNetworkID(user_id)
					entity = NetToVeh(lcSERVER.GetNetworkID(user_id))
					blips[user_id] = _addBlipForEntity(entity)
					print(newid)
				end
			end
		end
	)
	]]
end

function lcCLIENT.RemoveBlipFrom(user_id)
	if not blips[user_id] then
		return
	end

	RemoveBlip(blips[user_id])
	blips[user_id] = nil
end

function lcCLIENT.Notify(text)
	AddTextEntry('MESSAGE_LCNOTIFY', text)
	SetNotificationTextEntry('MESSAGE_LCNOTIFY')
	DrawNotification(true, false)
end

function spawnVehicle(model)
	local mhash = GetHashKey(model)
	RequestModel(mhash)
	while not HasModelLoaded(mhash) do
		Citizen.Wait(10)
	end

	if HasModelLoaded(mhash) then
		local ped = PlayerPedId()
		local vehicle = CreateVehicle(mhash, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
		--SetEntityAsMissionEntity(vehicle, true, true)
		SetVehicleHasBeenOwnedByPlayer(vehicle, true)

		local netID = VehToNet(vehicle)
		SetNetworkIdExistsOnAllMachines(netId, true)
		NetworkSetNetworkIdDynamic(netID, false)
		SetNetworkIdCanMigrate(netId, true)

		NetworkFadeInEntity(NetToEnt(netID), true)
		SetVehicleOnGroundProperly(vehicle)
		TaskWarpPedIntoVehicle(ped, vehicle, -1)

		SetVehicleFixed(vehicle)
		SetVehicleDirtLevel(vehicle, 0.0)

		SetModelAsNoLongerNeeded(mhash)

		TriggerEvent('reparar', vehicle)

		return vehicle
	end
end

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
	AddTextComponentString(' Rastreador')
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
