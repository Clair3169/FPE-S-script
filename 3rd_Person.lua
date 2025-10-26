local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local MIN_ZOOM = 4
local MAX_ZOOM = 4

-- 🔹 Variables de control
local isAlicePhase2 = false
local thirdPersonEnabled = true -- Asúmelo activo mientras lo pruebas

-- 🔸 Forzar tercera persona (independiente del PlayerModule)
local function forceThirdPerson()
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return end

	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = humanoid
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = MIN_ZOOM
	player.CameraMaxZoomDistance = MAX_ZOOM
end

-- 🔸 Liberar cámara (para AlicePhase2)
local function releaseCamera()
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CameraSubject = nil
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 128
end

-- 🔹 Detectar si el jugador es AlicePhase2
local function updateAliceState()
	local folder = Workspace:FindFirstChild("Alices")
	if not folder then return end
	local model = folder:FindFirstChild(player.Name)
	if not model then return end

	local attr = model:FindFirstChild("TeacherName")
	if not attr then return end

	isAlicePhase2 = (attr.Value == "AlicePhase2")
end

-- 🔁 Ciclo continuo para forzar o liberar cámara
RunService.Heartbeat:Connect(function()
	updateAliceState()

	if not thirdPersonEnabled then return end

	if isAlicePhase2 then
		releaseCamera()
	else
		forceThirdPerson()
	end
end)

print("✅ Cámara personalizada activa para scripts ejecutados en juego.")
