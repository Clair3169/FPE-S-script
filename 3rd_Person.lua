local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- ⚙️ Espera a que la cámara exista
local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

-- 🎥 Aplica cámara forzada (tercera persona)
local function applyThirdPerson()
	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = MIN_ZOOM
		player.CameraMaxZoomDistance = MAX_ZOOM
	end)

	local cam = waitCamera()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid", 10)

	pcall(function()
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = humanoid
	end)
end

-- 🎥 Libera la cámara completamente (modo libre)
local function releaseCamera()
	pcall(function()
		local cam = Workspace:FindFirstChildOfClass("Camera")
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or nil
		end
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 128
	end)
end

-- 🧩 Control principal
local function setupThirdPersonWatcher()
	local thirdPersonValue = player:WaitForChild("ThirdPersonEnabled", 10)
	if not thirdPersonValue then return end

	local teacherName = player:WaitForChild("TeacherName", 10)
	if not teacherName then return end

	-- Estado actual
	local isAlicePhase2 = (teacherName.Value == "AlicePhase2")

	-- 🔁 Actualiza según TeacherName
	local function updateCameraMode()
		isAlicePhase2 = (teacherName.Value == "AlicePhase2")
		if isAlicePhase2 then
			releaseCamera()
		else
			if thirdPersonValue.Value then
				task.wait(0.3)
				applyThirdPerson()
			end
		end
	end

	-- 📡 Eventos reactivos
	teacherName.Changed:Connect(updateCameraMode)

	thirdPersonValue.Changed:Connect(function()
		if thirdPersonValue.Value and not isAlicePhase2 then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if isAlicePhase2 then
			releaseCamera()
		elseif thirdPersonValue.Value then
			applyThirdPerson()
		end
	end)

	-- 🔃 Render loop activo (solo pausa acciones si eres AlicePhase2)
	RunService.RenderStepped:Connect(function()
		local cam = Workspace:FindFirstChildOfClass("Camera")
		local char = player.Character
		if not cam or not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")

		-- Si no está activado el modo 3ra persona → no hace nada
		if not thirdPersonValue.Value then return end

		-- 🚫 Si eres AlicePhase2 → solo mantiene la cámara libre
		if isAlicePhase2 then
			pcall(function()
				if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
				player.CameraMinZoomDistance = 0.5
				player.CameraMaxZoomDistance = 128
			end)
			return
		end

		-- ✅ Si NO eres AlicePhase2 → aplica la cámara forzada normal
		pcall(function()
			if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
			if humanoid and cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
			if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
			if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
			if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
		end)
	end)

	-- Llamada inicial
	updateCameraMode()
end

setupThirdPersonWatcher()
