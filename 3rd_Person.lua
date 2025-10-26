local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- 🧩 Esperar a que la cámara exista
local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

-- 🎥 Forzar cámara en tercera persona (igual al original)
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

-- 🎥 Activar modo primera persona bloqueada (para AlicePhase2)
local function applyFirstPersonLock()
	pcall(function()
		local cam = Workspace:FindFirstChildOfClass("Camera")
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or nil
		end

		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMinZoomDistance = 0
		player.CameraMaxZoomDistance = 0
	end)
end

-- 🧠 Obtener atributo TeacherName dentro de Workspace.Alices
local function getTeacherNameAttribute()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then return nil end
	local myModel = folder:FindFirstChild(player.Name)
	if not myModel then return nil end
	return myModel:FindFirstChild("TeacherName")
end

-- 🧩 Núcleo principal
local function setupThirdPersonWatcher()
	local value = player:WaitForChild("ThirdPersonEnabled", 10)
	if not value then return end

	local teacherName = getTeacherNameAttribute()
	local isAlicePhase2 = teacherName and teacherName.Value == "AlicePhase2"

	-- 🔄 Reacción a cambios del atributo TeacherName
	local function updateTeacherState()
		local newTeacherName = getTeacherNameAttribute()
		if not newTeacherName then return end
		isAlicePhase2 = (newTeacherName.Value == "AlicePhase2")

		if isAlicePhase2 then
			applyFirstPersonLock()
		else
			if value.Value then
				task.wait(0.3)
				applyThirdPerson()
			end
		end
	end

	if teacherName then
		teacherName:GetPropertyChangedSignal("Value"):Connect(updateTeacherState)
	end

	-- 🔁 Cuando el valor de ThirdPersonEnabled cambia
	value.Changed:Connect(function()
		if value.Value then
			if isAlicePhase2 then
				applyFirstPersonLock()
			else
				task.wait(0.3)
				applyThirdPerson()
			end
		end
	end)

	-- 🧍‍♂️ Cuando el jugador reaparece
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if value.Value then
			if isAlicePhase2 then
				applyFirstPersonLock()
			else
				applyThirdPerson()
			end
		end
	end)

	-- 🔄 Bucle continuo optimizado
	RunService.RenderStepped:Connect(function()
		if not value.Value then return end
		local cam = Workspace:FindFirstChildOfClass("Camera")
		local char = player.Character
		if not cam or not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		-- 🚫 Si somos AlicePhase2, no forzar nada (ya estamos en primera persona)
		if isAlicePhase2 then return end

		-- ✅ Si no somos AlicePhase2, forzar cámara como en el original
		pcall(function()
			if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
			if cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
			if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
			if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
			if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
		end)
	end)

	-- 🔧 Configuración inicial al entrar en el juego
	if value.Value then
		if isAlicePhase2 then
			applyFirstPersonLock()
		else
			task.wait(0.3)
			applyThirdPerson()
		end
	end
end

setupThirdPersonWatcher()
