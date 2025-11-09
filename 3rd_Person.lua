local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- 🔧 Valores base
local MIN_ZOOM = 4
local MAX_ZOOM = 4
local ALICE_MIN_ZOOM = 8
local ALICE_MAX_ZOOM = 10

-- Estado
local isAlicePhase2 = false
local thirdPersonEnabled = true
local aliceFree = false

-- 🟩 Forzar cámara en tercera persona (ahora usa los valores actuales del jugador)
local function forceThirdPerson()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	player.CameraMode = Enum.CameraMode.Classic

	-- 👇 Ya no forzamos MIN_ZOOM/MAX_ZOOM aquí.
	-- Así respeta el zoom configurado según el estado Alice o normal.
end

-- 🔍 Detección del estado AlicePhase2
local function updateAliceState()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then
		isAlicePhase2 = false
		return
	end

	local model = folder:FindFirstChild(player.Name)
	if not model then
		isAlicePhase2 = false
		return
	end

	local attrValue = model:GetAttribute("TeacherName")
	isAlicePhase2 = (attrValue == "AlicePhase2")
end

-- 🔁 Actualización periódica
task.spawn(function()
	while true do
		updateAliceState()

		if isAlicePhase2 and not aliceFree then
			-- 📏 Aplicar zoom de AlicePhase2
			player.CameraMinZoomDistance = ALICE_MIN_ZOOM
			player.CameraMaxZoomDistance = ALICE_MAX_ZOOM
			forceThirdPerson()
			task.delay(15, function() aliceFree = true end)

		elseif not isAlicePhase2 then
			aliceFree = false
			-- 📏 Restaurar zoom normal
			player.CameraMinZoomDistance = MIN_ZOOM
			player.CameraMaxZoomDistance = MAX_ZOOM
			if thirdPersonEnabled then
				forceThirdPerson()
			end
		end

		task.wait(0.5)
	end
end)
