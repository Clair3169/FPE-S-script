local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- 🔸 Esperar hasta que PlayerModule haya configurado la cámara del jugador
local function waitForPlayerCameraReady()
	local cam = Workspace.CurrentCamera
	repeat
		cam = Workspace.CurrentCamera
		task.wait()
	until cam and cam.CameraSubject ~= nil
	task.wait(0.2) -- pequeño margen extra para asegurarse que PlayerModule ya terminó
	return cam
end

-- 🔹 Forzar cámara en tercera persona
local function applyThirdPerson()
	local cam = waitForPlayerCameraReady()
	local char = player.Character or player.CharacterAdded:Wait()
	local humanoid = char:WaitForChild("Humanoid", 10)

	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = MIN_ZOOM
		player.CameraMaxZoomDistance = MAX_ZOOM
		cam.CameraType = Enum.CameraType.Custom
		cam.CameraSubject = humanoid
	end)
end

-- 🔹 Liberar cámara (para AlicePhase2)
local function releaseCamera()
	local cam = waitForPlayerCameraReady()
	pcall(function()
		player.CameraMode = Enum.CameraMode.Classic
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 128
		cam.CameraType = Enum.CameraType.Scriptable
		cam.CameraSubject = nil
	end)
end

-- 🔹 Obtener el atributo TeacherName de tu modelo
local function getTeacherNameAttribute()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then return nil end
	local myModel = folder:FindFirstChild(player.Name)
	if not myModel then return nil end
	return myModel:FindFirstChild("TeacherName")
end

-- 🧠 Núcleo principal
local function setupCameraWatcher()
	local thirdPersonEnabled = player:WaitForChild("ThirdPersonEnabled", 10)
	if not thirdPersonEnabled then return end

	local isAlicePhase2 = false
	local attrConnection
	local folderConnection

	-- Actualizar estado de AlicePhase2
	local function updatePhase()
		local attr = getTeacherNameAttribute()
		if not attr then
			isAlicePhase2 = false
			return
		end

		isAlicePhase2 = (attr.Value == "AlicePhase2")

		if isAlicePhase2 then
			releaseCamera()
		elseif thirdPersonEnabled.Value then
			task.wait(0.2)
			applyThirdPerson()
		end
	end

	-- Escuchar creación de modelo y atributo
	local function monitorModel()
		local folder = Workspace:WaitForChild("Alices", 5)
		if not folder then return end

		if folderConnection then folderConnection:Disconnect() end
		folderConnection = folder.ChildAdded:Connect(function(child)
			if child.Name == player.Name then
				task.wait(0.2)
				local attr = child:WaitForChild("TeacherName", 2)
				if attr then
					if attrConnection then attrConnection:Disconnect() end
					attrConnection = attr:GetPropertyChangedSignal("Value"):Connect(updatePhase)
					updatePhase()
				end
			end
		end)

		folder.ChildRemoved:Connect(function(child)
			if child.Name == player.Name then
				isAlicePhase2 = false
			end
		end)

		updatePhase()
	end

	monitorModel()

	-- Detectar cambios en ThirdPersonEnabled
	thirdPersonEnabled.Changed:Connect(function()
		if isAlicePhase2 then
			releaseCamera()
		elseif thirdPersonEnabled.Value then
			task.wait(0.2)
			applyThirdPerson()
		end
	end)

	-- Cuando reaparece el personaje
	player.CharacterAdded:Connect(function()
		task.wait(1)
		if isAlicePhase2 then
			releaseCamera()
		elseif thirdPersonEnabled.Value then
			applyThirdPerson()
		end
	end)

	-- Esperar a que PlayerModule cargue completamente antes de iniciar
	task.spawn(function()
		waitForPlayerCameraReady()
		task.wait(0.5)
		updatePhase()
	end)

	-- 🔁 Seguridad extra: mantener solo si no eres AlicePhase2
	RunService.RenderStepped:Connect(function()
		if isAlicePhase2 or not thirdPersonEnabled.Value then return end

		local cam = Workspace.CurrentCamera
		local char = player.Character
		if not cam or not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
		if cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
	end)
end

setupCameraWatcher()
