local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- ⚙️ Espera la cámara
local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

-- 🎥 Aplica la cámara fija de tercera persona
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

-- 🎥 Libera la cámara completamente (para AlicePhase2)
local function releaseCamera()
	pcall(function()
		local cam = Workspace:FindFirstChildOfClass("Camera")
		if cam then
			cam.CameraType = Enum.CameraType.Custom -- libre
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

	local isAlicePhase2 = false

	-- 🔄 Actualiza el estado de cámara según TeacherName
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

	-- 📡 Reacciona a cambios de TeacherName
	teacherName.Changed:Connect(updateCameraMode)

	-- 📡 Reacciona a cambios de ThirdPersonEnabled
	thirdPersonValue.Changed:Connect(function()
		if thirdPersonValue.Value and not isAlicePhase2 then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	-- 📡 Reacciona a reaparecer personaje
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if thirdPersonValue.Value and not isAlicePhase2 then
			applyThirdPerson()
		elseif isAlicePhase2 then
			releaseCamera()
		end
	end)

	-- 🔁 Ciclo optimizado de mantenimiento de cámara
	RunService.RenderStepped:Connect(function()
		-- 🚫 Si está en AlicePhase2, no forzamos nada
		if not thirdPersonValue.Value or isAlicePhase2 then return end

		local cam = Workspace:FindFirstChildOfClass("Camera")
		local char = player.Character
		if not cam or not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")

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
