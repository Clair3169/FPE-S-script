local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- Esperar cámara
local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

-- Forzar cámara tercera persona
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

-- Buscar atributo TeacherName del modelo de Alice
local function getTeacherNameAttribute()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then return nil end
	local myModel = folder:FindFirstChild(player.Name)
	if not myModel then return nil end
	return myModel:FindFirstChild("TeacherName")
end

-- Núcleo principal
local function setupThirdPersonWatcher()
	local thirdPersonEnabled = player:WaitForChild("ThirdPersonEnabled", 10)
	if not thirdPersonEnabled then return end

	local isAlicePhase2 = false
	local teacherConnection -- conexión al atributo TeacherName
	local modelConnection -- conexión al modelo del jugador

	-- Función para actualizar estado
	local function updateTeacherState()
		local attr = getTeacherNameAttribute()
		if not attr then
			isAlicePhase2 = false
			return
		end
		isAlicePhase2 = (attr.Value == "AlicePhase2")
	end

	-- 🔄 Escuchar cambios en el modelo dentro de Workspace.Alices
	local function monitorAliceModel()
		if modelConnection then
			modelConnection:Disconnect()
			modelConnection = nil
		end
		if teacherConnection then
			teacherConnection:Disconnect()
			teacherConnection = nil
		end

		local folder = Workspace:WaitForChild("Alices", 5)
		if not folder then return end

		local function tryAttach()
			local model = folder:FindFirstChild(player.Name)
			if not model then return end
			local teacherAttr = model:FindFirstChild("TeacherName")
			if teacherAttr then
				updateTeacherState()
				teacherConnection = teacherAttr:GetPropertyChangedSignal("Value"):Connect(updateTeacherState)
			end
		end

		-- Escuchar cuando aparece o desaparece el modelo
		modelConnection = folder.ChildAdded:Connect(function(child)
			if child.Name == player.Name then
				task.wait(0.2)
				tryAttach()
			end
		end)

		folder.ChildRemoved:Connect(function(child)
			if child.Name == player.Name then
				isAlicePhase2 = false
			end
		end)

		-- Intentar conectar si ya existe
		tryAttach()
	end

	monitorAliceModel()

	-- 🔁 Cuando cambia ThirdPersonEnabled
	thirdPersonEnabled.Changed:Connect(function()
		if thirdPersonEnabled.Value and not isAlicePhase2 then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	-- 🔁 Cuando reaparece el jugador
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if thirdPersonEnabled.Value and not isAlicePhase2 then
			applyThirdPerson()
		end
	end)

	-- 🔄 Bucle constante
	RunService.RenderStepped:Connect(function()
		if not thirdPersonEnabled.Value then return end
		if isAlicePhase2 then return end -- 🚫 respetar AlicePhase2

		local cam = Workspace:FindFirstChildOfClass("Camera")
		local char = player.Character
		if not cam or not char then return end
		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		pcall(function()
			if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
			if cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
			if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
			if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
			if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
		end)
	end)

	-- Aplicar al inicio
	if thirdPersonEnabled.Value and not isAlicePhase2 then
		task.wait(0.3)
		applyThirdPerson()
	end
end

setupThirdPersonWatcher()
