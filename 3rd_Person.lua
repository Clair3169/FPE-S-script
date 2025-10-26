local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

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

local function setupThirdPersonWatcher()
	local thirdPersonEnabled = player:WaitForChild("ThirdPersonEnabled", 10)
	local teacherName = player:WaitForChild("TeacherName", 10)
	if not thirdPersonEnabled then return end
	if not teacherName then return end

	local function isAlicePhase2()
		return teacherName.Value == "AlicePhase2"
	end

	local function updateCameraBehavior()
		if isAlicePhase2() then
			-- 🔸 Dejar la cámara libre (sin forzar nada)
			pcall(function()
				local cam = Workspace:FindFirstChildOfClass("Camera")
				if cam then
					cam.CameraType = Enum.CameraType.Custom
					player.CameraMode = Enum.CameraMode.Classic
					player.CameraMinZoomDistance = 0.5
					player.CameraMaxZoomDistance = 128
				end
			end)
		else
			-- 🔸 Comportamiento normal (forzar cámara 3ra persona)
			if thirdPersonEnabled.Value then
				task.wait(0.3)
				applyThirdPerson()
			end
		end
	end

	-- Detectar cambios en TeacherName
	teacherName.Changed:Connect(updateCameraBehavior)

	-- Detectar cambios en ThirdPersonEnabled
	thirdPersonEnabled.Changed:Connect(function()
		if thirdPersonEnabled.Value and not isAlicePhase2() then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	-- Cuando reaparezca el jugador
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if thirdPersonEnabled.Value and not isAlicePhase2() then
			applyThirdPerson()
		end
	end)

	-- RenderStepped loop optimizado
	RunService.RenderStepped:Connect(function()
		if not thirdPersonEnabled.Value or isAlicePhase2() then return end

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
	updateCameraBehavior()
end

setupThirdPersonWatcher()
