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

-- 🎥 Restaurar cámara predeterminada (modo libre)
local function restoreDefaultCamera()
	pcall(function()
		local cam = Workspace:FindFirstChildOfClass("Camera")
		if cam then
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = player.Character and player.Character:FindFirstChildOfClass("Humanoid") or nil
		end

		-- 🔁 Volver a la configuración libre
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 128
	end)
end

-- 🧠 Obtener el atributo TeacherName del modelo del jugador dentro de Workspace.Alices
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

	-- 🔄 Reacción a los cambios en TeacherName
	local function updateTeacherState()
		local newTeacherName = getTeacherNameAttribute()
		if not newTeacherName then return end

		isAlicePhase2 = (newTeacherName.Value == "AlicePhase2")

		if isAlicePhase2 then
			-- 🔁 Si somos AlicePhase2, restaurar cámara predeterminada
			restoreDefaultCamera()
		else
			-- 🔁 Si ya no somos AlicePhase2, volver a forzar tercera persona
			if value.Value then
				task.wait(0.3)
				applyThirdPerson()
			end
		end
	end

	if teacherName then
		teacherName:GetPropertyChangedSignal("Value"):Connect(updateTeacherState)
	end

	-- 🔁 Activar tercera persona si corresponde
	value.Changed:Connect(function()
		if value.Value and not isAlicePhase2 then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	-- 🧍‍♂️ Cuando reaparecemos
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if value.Value then
			if isAlicePhase2 then
				restoreDefaultCamera()
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

		-- 🚫 Si somos AlicePhase2 → dejar cámara libre
		if isAlicePhase2 then return end

		-- ✅ Si no lo somos → mantener la cámara forzada (igual que original)
		pcall(function()
			if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
			if cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
			if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
			if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
			if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
		end)
	end)

	-- 🧠 Configuración inicial al iniciar el juego
	if value.Value then
		if isAlicePhase2 then
			restoreDefaultCamera()
		else
			task.wait(0.3)
			applyThirdPerson()
		end
	end
end

setupThirdPersonWatcher()
