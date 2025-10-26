local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- ⚙️ Espera a que exista una cámara
local function waitCamera()
	local cam
	repeat
		cam = Workspace:FindFirstChildOfClass("Camera")
		task.wait()
	until cam
	return cam
end

-- 🎥 Forzar cámara en tercera persona
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

-- 🎥 Liberar la cámara completamente (modo libre / sin forzar)
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

-- 🧠 Busca y retorna el modelo de jugador dentro de Workspace.Alices
local function getAliceModel()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then return nil end
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model.Name == player.Name then
			return model
		end
	end
	return nil
end

-- 🧩 Control principal
local function setupThirdPersonWatcher()
	local thirdPersonValue = player:WaitForChild("ThirdPersonEnabled", 10)
	if not thirdPersonValue then return end

	local aliceModel = getAliceModel()
	if not aliceModel then
		-- Esperamos a que aparezca el modelo del jugador en Alices
		Workspace:WaitForChild("Alices"):ChildAdded:Connect(function(child)
			if child.Name == player.Name then
				aliceModel = child
			end
		end)
	end

	local teacherName = aliceModel and aliceModel:FindFirstChild("TeacherName")
	if not teacherName and aliceModel then
		aliceModel.ChildAdded:Connect(function(child)
			if child.Name == "TeacherName" then
				teacherName = child
			end
		end)
	end

	-- Estado actual de AlicePhase2
	local isAlicePhase2 = (teacherName and teacherName.Value == "AlicePhase2") or false

	-- 🔄 Función para actualizar el estado según TeacherName
	local function updateCameraState()
		if not teacherName then return end
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

	-- Detectar cambios del atributo TeacherName
	if teacherName then
		teacherName:GetPropertyChangedSignal("Value"):Connect(updateCameraState)
	end

	-- Detectar cambios del valor ThirdPersonEnabled
	thirdPersonValue.Changed:Connect(function()
		if thirdPersonValue.Value and not isAlicePhase2 then
			task.wait(0.3)
			applyThirdPerson()
		end
	end)

	-- Reaparecer personaje
	player.CharacterAdded:Connect(function()
		task.wait(0.3)
		if isAlicePhase2 then
			releaseCamera()
		elseif thirdPersonValue.Value then
			applyThirdPerson()
		end
	end)

	-- 🔃 Bucle constante optimizado (no se detiene, pero se pausa si es AlicePhase2)
	RunService.RenderStepped:Connect(function()
		local cam = Workspace:FindFirstChildOfClass("Camera")
		local char = player.Character
		if not cam or not char then return end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if not humanoid or not thirdPersonValue.Value then return end

		-- 🚫 Si es AlicePhase2, no forzamos cámara
		if isAlicePhase2 then return end

		-- ✅ Si no es AlicePhase2, aplicamos el forzado normal
		pcall(function()
			if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
			if cam.CameraSubject ~= humanoid then cam.CameraSubject = humanoid end
			if player.CameraMode ~= Enum.CameraMode.Classic then player.CameraMode = Enum.CameraMode.Classic end
			if player.CameraMinZoomDistance ~= MIN_ZOOM then player.CameraMinZoomDistance = MIN_ZOOM end
			if player.CameraMaxZoomDistance ~= MAX_ZOOM then player.CameraMaxZoomDistance = MAX_ZOOM end
		end)
	end)

	-- Aplicación inicial
	updateCameraState()
end

setupThirdPersonWatcher()
