local Tunnel = module('vrp', 'lib/Tunnel')
local Proxy = module('vrp', 'lib/Proxy')

vRP = Proxy.getInterface('vRP')
lcSERVER = Tunnel.getInterface('emp_lc')

lcCLIENT = {}
Tunnel.bindInterface('emp_lc', lcCLIENT)
Proxy.addInterface('emp_lc', lcCLIENT)

-- USER ONLY
local varSeconds = 0
local varVehicle
local varSelectedIndex
local varDBlip
local varDelivering = false

local pLocations = {
	-- Pickup
	[1] = {-595.40, 28.95, 43.44},
	[2] = {-277.47, -1064.10, 25.84},
	[3] = {921.90, 47.69, 80.76},
	[4] = {-42.45, -785.42, 44.28},
	[5] = {-72.95, 146.52, 81.35},
	[6] = {-774.23, 305.76, 85.70},
	[7] = {-1041.06, -768.85, 19.12}
}

local dLocations = {
	-- Delivery
	--[[
	[1] = {421.51, -1561.19, 29.28},
	[2] = {-77.43, -1393.51, 29.32},
	[3] = {167.23, -1273.72, 29.03},
	[4] = {824.86, -1056.42, 27.94},
	[5] = {681.60, 73.65, 83.34},
	[6] = {-1879.96, -307.33, 49.24},
	[7] = {-585.68, -754.08, 29.49},
	]]
	[1] = {-595.40, 28.95, 43.44},
	[2] = {-277.47, -1064.10, 25.84},
	[3] = {921.90, 47.69, 80.76},
	[4] = {-42.45, -785.42, 44.28},
	[5] = {-72.95, 146.52, 81.35},
	[6] = {-774.23, 305.76, 85.70},
	[7] = {-1041.06, -768.85, 19.12}
}

-- GLOBAL
local gVehicles = {} -- [i] = {model, name, price}
--local gBlip
local gGlobalVehicleID

Citizen.CreateThread(
	function()
		for _, values in pairs(pLocations) do
			local blip = AddBlipForCoord(table.unpack(values))
			SetBlipSprite(blip, 225)
			SetBlipColour(blip, 41)
			SetBlipScale(blip, 0.5)
			SetBlipAsShortRange(blip, true)
			BeginTextCommandSetBlipName('STRING')
			AddTextComponentString('Roubo de Veiculo')
			EndTextCommandSetBlipName(blip)
		end

		local dx, dy, dz
		while true do
			Citizen.Wait(1)

			if #gVehicles <= 0 then
				lcCLIENT.SetVehicles(lcSERVER.GetVehicles())
			end

			local ped = PlayerPedId()
			local px, py, pz = table.unpack(GetEntityCoords(ped))

			if varSelectedIndex == nil and varVehicle == nil and #gVehicles > 0 then
				for index, coords in pairs(pLocations) do
					local x, y, z = table.unpack(coords)
					local distance = #(vec3(x, y, z) - GetEntityCoords(ped))

					if distance <= 70.0 then
						DrawMarker(23, x, y, z - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 120, 120, 0, 0, 0, 0)
					end

					if distance <= 2.5 then
						drawHelpTxt('~INPUT_PICKUP~~n~Veículo disponível: ~o~' .. gVehicles[index][2] .. '~n~~s~Recompensa:~g~ R$' .. format(gVehicles[index][3]) .. ' sujo')
						if IsControlJustPressed(0, 38) then
							if lcSERVER.HasPermission() then
								varSelectedIndex = index
								newVehicle()
								local netID = VehToNet(varVehicle)
								if lcSERVER.Start(index, netID) then
									newSecondsCountdown()
								end
							end
						end
					end
				end
			end

			-- Setup new delivery location
			if varVehicle ~= nil and gGlobalVehicleID == nil and varSeconds <= 0 and not varDelivering then
				varDelivering = true
				varSeconds = 0

				varSelectedIndex = math.random(#dLocations)

				while dLocations[varSelectedIndex] == nil do
					Citizen.Wait(1)
					varSelectedIndex = math.random(#dLocations)
				end
				
				if lcSERVER.StartDelivery(varSelectedIndex) then
					dx, dy, dz = table.unpack(dLocations[varSelectedIndex])
					newDeliveryBlip()
				end
			end

			-- Check if player is in the delivery location
			if varDelivering and varVehicle ~= nil then
				local distance = #(vec3(dx, dy, dz) - GetEntityCoords(ped))

				if distance <= 70.0 then
					DrawMarker(23, dx, dy, dz - 0.96, 0, 0, 0, 0, 0, 0, 3.0, 3.0, 0.5, 211, 176, 120, 120, 0, 0, 0, 0)
				end

				if distance <= 2.5 then
					drawHelpTxt('~INPUT_PICKUP~~n~Receber Recompensa:~g~ R$' .. format(gVehicles[varSelectedIndex][3]) .. ' sujo')
					if IsControlJustPressed(0, 38) then
						if GetVehiclePedIsIn(ped, false) == varVehicle then
							if lcSERVER.GetPayment() then
								lcSERVER.End()

								DeleteVehicle(varVehicle)
								varSeconds = 0
								varVehicle = nil
								varSelectedIndex = nil
								if varDBlip ~= nil then
									RemoveBlip(varDBlip)
									varDBlip = nil
								end
								varDelivering = false
							else
								lcCLIENT.Notification('x')
							end
						else
							lcCLIENT.Notification('Este não é o veiculo que eu pedi')
						end
					end
				end
			end

			if varVehicle ~= nil then
				if not DoesEntityExist(varVehicle) or DoesEntityExist(varVehicle) and GetEntityHealth(varVehicle) <= 90 then
					lcCLIENT.Notification('~o~O veículo desapareceu ou está danificado.')
					lcSERVER.End()
					lcSERVER.ClearGlobalVehicleNetID()

					varSeconds = 0
					varVehicle = nil
					varSelectedIndex = nil
					if varDBlip ~= nil then
						RemoveBlip(varDBlip)
						varDBlip = nil
					end
					varDelivering = false
				end
			end

			if varVehicle ~= nil then
				if varSeconds > 0 and not varDelivering then
					drawTxt('Rastreador: <FONT color="#8de090">' .. math.floor(varSeconds / 60) .. ' minutos e ' .. math.floor(varSeconds % 60) .. ' segundos ~s~restantes', 6, 0.16, 0.87, 0.5, 255, 255, 255, 255)
				end

				if varSeconds <= 0 and varDelivering then
					drawTxt('Rastreador: <FONT color="#e08d8d">desativado', 6, 0.16, 0.87, 0.5, 255, 255, 255, 255)
					drawTxt('Vá até o local marcado no mapa e venda o veiculo.', 6, 0.16, 0.890, 0.45, 255, 255, 255, 120)
				end
			end
		end
	end
)

function lcCLIENT.SetVehicles(value)
	gVehicles = value
end

function lcCLIENT.ClearGlobalVehicleNetID()
	RemoveBlip(GetBlipFromEntity(NetToEnt(gVehicleNetID)))
	--gBlip = nil
	gVehicleNetID = nil
end

function lcCLIENT.SetGlobalVehicleNetID(value)
	-- if gBlip then
	-- 	RemoveBlip(gBlip)
	-- end

	if gVehicleNetID ~= nil then
		RemoveBlip(GetBlipFromEntity(NetToEnt(gVehicleNetID)))
	end

	if value ~= nil then
		gVehicleNetID = value

		newRadarBlip()
	end
end

function lcCLIENT.Notification(text)
	AddTextEntry('MESSAGE_LCNOTIFY', '<FONT color="#8de090">LC</FONT> | ' .. text)
	SetNotificationTextEntry('MESSAGE_LCNOTIFY')
	DrawNotification(true, false)
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

function newSecondsCountdown()
	varSeconds = lcSERVER.GetSeconds()
	Citizen.CreateThread(
		function()
			while varVehicle ~= nil do
				Citizen.Wait(1000)
				varSeconds = lcSERVER.GetSeconds)
			end
		end
	)
end

function newVehicle()
	if varSelectedIndex == nil or gVehicles[varSelectedIndex] == nil then
		return nil
	end

	local model = gVehicles[varSelectedIndex][1]

	local modelhash = GetHashKey(model)
	RequestModel(modelhash)
	while not HasModelLoaded(modelhash) do
		Citizen.Wait(1)
	end

	if HasModelLoaded(modelhash) then
		local ped = PlayerPedId()
		varVehicle = CreateVehicle(modelhash, GetEntityCoords(ped), GetEntityHeading(ped), true, false)
		SetVehicleHasBeenOwnedByPlayer(varVehicle, true)
		NetworkRegisterEntityAsNetworked(varVehicle)

		SetVehicleOnGroundProperly(varVehicle)
		TaskWarpPedIntoVehicle(ped, varVehicle, -1)
		SetVehicleFixed(varVehicle)
		SetVehicleDirtLevel(varVehicle, 0.0)

		SetModelAsNoLongerNeeded(modelhash)

		TriggerEvent('reparar', varVehicle)

		netID = VehToNet(varVehicle)
		local entity = NetToEnt(netID)

		NetworkFadeInEntity(entity, true)

		SetNetworkIdExistsOnAllMachines(netID, true)

		Citizen.Wait(250)

		varVehicle = NetToVeh(netID)
	-- local attempts = 0
	-- while not NetworkDoesEntityExistWithNetworkId(gGlobalVehicleID) and attempts < 10 do
	-- 	Citizen.Wait(50)
	-- 	gGlobalVehicleID = VehToNet(varVehicle)
	-- 	NetworkRegisterEntityAsNetworked(entity)
	-- 	SetEntityAsMissionEntity(entity)

	-- 	SetNetworkIdCanMigrate(gGlobalVehicleID, true)
	-- 	SetNetworkIdExistsOnAllMachines(gGlobalVehicleID, true)

	-- 	NetworkRequestControlOfEntity(entity)
	-- 	attempts = attempts + 1
	-- end
	-- if attempts >= 10 then
	-- 	Citizen.Trace('Failed to register entity on net')
	-- 	return nil
	-- else
	-- 	Citizen.Trace('Registered UselessCar on net as NetID: ' .. gGlobalVehicleID)
	-- end
	end
end

function newRadarBlip()
	if gVehicleNetID == nil then
		return
	end

	local vehicle = NetToVeh(gVehicleNetID)

	if not DoesEntityExist(vehicle) then
		return
	end

	local blip = AddBlipForEntity(vehicle)
	SetBlipSprite(blip, 161)
	SetBlipColour(blip, 6)
	SetBlipScale(blip, 1.4)
	SetBlipAsShortRange(blip, false)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(' Rastreador')
	EndTextCommandSetBlipName(blip)

	Citizen.CreateThread(
		function()
			while gVehicleNetID ~= nil do
				Citizen.Wait(100)

				if DoesEntityExist(vehicle) then
					if GetBlipFromEntity(vehicle) == 0 then
						newRadarBlip()
						break
					end
				else
					vehicle = NetToVeh(gVehicleNetID)
				end
			end
		end
	)
end

function newDeliveryBlip()
	if varSelectedIndex == nil or dLocations[varSelectedIndex] == nil then
		return
	end

	local x, y, z = table.unpack(dLocations[varSelectedIndex])

	varDBlip = AddBlipForCoord(x, y, z)
	SetBlipSprite(varDBlip, 1)
	SetBlipColour(varDBlip, 5)
	SetBlipScale(varDBlip, 0.4)
	SetBlipAsShortRange(varDBlip, true)
	SetBlipRoute(varDBlip, true)
	BeginTextCommandSetBlipName('STRING')
	AddTextComponentString(' Entrega de Veiculo')
	EndTextCommandSetBlipName(varDBlip)
end

function format(n)
	local left, num, right = string.match(n, '^([^%d]*%d)(%d*)(.-)$')
	return left .. (num:reverse():gsub('(%d%d%d)', '%1.'):reverse()) .. right
end
