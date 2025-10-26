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

-- 🎥 Aplica la cámara de tercera persona
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

-- 🧩 Configurador principal
local function setupThirdPersonWatcher()
	local value = player:WaitForChild("ThirdPersonEnabled", 10)
	if not value then return end

	-- 🔸 Esperamos TeacherName para la nueva condición
	local teacherName = player:FindFirstChild("TeacherName")
	if not teacherName then
		player.ChildAdded:Connect(function(child)
			if child.Name == "TeacherName" then
				teacherName = child
			end
		end)
	end

	-- 🔍 Función para saber si estamos en AlicePhase2
	local function isAlicePhase2()
		return teacherName and teacherName.Value == "AlicePhase2"
	end

	-- 🔄 Detectar cambios en el atributo TeacherName
	if teacherName then
		teacherName.Changed:Connect(function()
			if not isAlicePhase2() and value.Value then
				task.wait(0.3)
				applyThirdPerson()
			end
		end)
	end

	-- 🔄 Si el valor cambia
	value.Changed:Connect(function()
		if value.Value and not isAlicePhase2() then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	-- 🔁 Cuando reaparece el jugador
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if value.Value and not isAlicePhase2() then
			applyThirdPerson()
		end
	end)

	-- 🔃 Mantener cámara forzada solo si no es AlicePhase2
	RunService.RenderStepped:Connect(function()
		if not value.Value or isAlicePhase2() then return end

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
end

setupThirdPersonWatcher()
