local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

-- === CONFIGURACIÓN ===

local ALICE_ZOOM_MIN = 6
local ALICE_ZOOM_MAX = 15

local NORMAL_ZOOM_MIN = 4
local NORMAL_ZOOM_MAX = 4

local MODO_CAMARA = Enum.CameraMode.Classic
local TOUCH_MODO_CAMARA = Enum.DevTouchCameraMovementMode.Classic
local NOMBRE_CARPETA_ESPECIAL = "Alices"

-- ======================

local function obtenerConfiguracionActual()
	local character = LocalPlayer.Character
	
	if character and character.Parent and character.Parent.Name == NOMBRE_CARPETA_ESPECIAL then
		return ALICE_ZOOM_MIN, ALICE_ZOOM_MAX
	else
		return NORMAL_ZOOM_MIN, NORMAL_ZOOM_MAX
	end
end

local function forzarConfiguracion()
	local targetMin, targetMax = obtenerConfiguracionActual()

	-- Forzar cámara Classic
	if LocalPlayer.CameraMode ~= MODO_CAMARA then
		LocalPlayer.CameraMode = MODO_CAMARA
	end

	-- Forzar DevTouchCameraMode Classic
	if LocalPlayer.DevTouchCameraMode ~= TOUCH_MODO_CAMARA then
		LocalPlayer.DevTouchCameraMode = TOUCH_MODO_CAMARA
	end

	-- Forzar Zoom
	if LocalPlayer.CameraMaxZoomDistance ~= targetMax then
		LocalPlayer.CameraMaxZoomDistance = targetMax
	end
	if LocalPlayer.CameraMinZoomDistance ~= targetMin then
		LocalPlayer.CameraMinZoomDistance = targetMin
	end
end

local function conectarPersonaje(character)
	forzarConfiguracion()

	-- Cambio de carpeta
	character.AncestryChanged:Connect(function(_, parent)
		if parent then
			forzarConfiguracion()
		end
	end)
end

-- Listeners anti-cambio externo
LocalPlayer:GetPropertyChangedSignal("CameraMode"):Connect(forzarConfiguracion)
LocalPlayer:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(forzarConfiguracion)
LocalPlayer:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(forzarConfiguracion)

-- Detectar intento de cambiar DevTouchCameraMode
LocalPlayer:GetPropertyChangedSignal("DevTouchCameraMode"):Connect(function()
	if LocalPlayer.DevTouchCameraMode ~= TOUCH_MODO_CAMARA then
		LocalPlayer.DevTouchCameraMode = TOUCH_MODO_CAMARA
	end
end)

-- Respawn
LocalPlayer.CharacterAdded:Connect(conectarPersonaje)

-- Inicial
if LocalPlayer.Character then
	conectarPersonaje(LocalPlayer.Character)
else
	forzarConfiguracion()
end
