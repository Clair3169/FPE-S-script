local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- ⚙️ Esperar cámara
local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

-- 🎥 Forzar cámara en tercera persona (idéntico a tu original)
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

-- 🎥 Liberar la cámara (sin forzar nada)
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

-- 🧠 Obtener el atributo TeacherName desde Workspace.Alices
local function getTeacherNameAttribute()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then return nil end

	local myModel = folder:FindFirstChild(player.Name)
	if not myModel then return nil end

	return myModel:FindFirstChild("TeacherName")
end

-- 🧩 Núcleo principal (basado fielmente en tu script original)
local function setupThirdPersonWatcher()
	local value = player:WaitForChild("ThirdPersonEnabled", 10)
	if not value then return end

	-- 🔍 Buscar el atributo TeacherName dentro del modelo del jugador en Alices
	local teacherName = getTeacherNameAttribute()
	local isAlicePhase2 = teacherName and teacherName.Value == "AlicePhase2"

	-- 🔄 Actualizar estado cuando cambie TeacherName
	local function updateTeacherState()
		local newTeacherName = getTeacherNameAttribute()
		if not newTeacherName then return end
		isAlicePhase2 = (newTeacherName.Value == "AlicePhase2")

		if isAlicePhase2 then
			releaseCamera()
		elseif value.Value then
			task.wait(0.3)
			applyThirdPerson()
		end
	end

	if teacherName then
		teacherName:GetPropertyChangedSignal("Value"):Connect(updateTeacherState)
	end

	-- 🔁 Mismo comportamiento del script original
	value.Changed:Connect(function()
		if value.Value and not isAlicePhase2 then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if value.Value and not isAlicePhase2 then
			applyThirdPerson()
		elseif isAlicePhase2 then
			releaseCamera()
		end
	end)

	-- 🔃 Bucle de refuerzo (idéntico al original, con pausa si eres AlicePhase2)
	RunService.RenderStepped:Connect(function()
		if not value.Value then return end

		local cam = Workspace:FindFirstChildOfClass("Camera")
		local char = player.Character
		if not cam or not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- 🚫 Si eres AlicePhase2 → pausa el forzado temporalmente
		if isAlicePhase2 then return end

		-- ✅ Si no eres AlicePhase2 → comportamiento normal del script original
		pcall(function()
			if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
			if cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
			if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
			if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
			if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
		end)
	end)

	-- Aplicación inicial
	if value.Value and not isAlicePhase2 then
		task.wait(0.3)
		applyThirdPerson()
	end
end

setupThirdPersonWatcher()
