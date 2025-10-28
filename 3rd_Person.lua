local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local MIN_ZOOM = 7
local MAX_ZOOM = 13

-- Estado
local isAlicePhase2 = false
local thirdPersonEnabled = true -- ajusta según tu sistema real

-- 🟩 Forzar cámara en tercera persona (solo cuando NO somos AlicePhase2)
local function forceThirdPerson()
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end
	
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = MIN_ZOOM
		player.CameraMaxZoomDistance = MAX_ZOOM
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

-- 🔁 Actualización periódica (sin sobrecargar)
task.spawn(function()
	while true do
		updateAliceState()

		if thirdPersonEnabled and not isAlicePhase2 then
			forceThirdPerson()
		end

		task.wait(0.5)
	end
end)
