-- Obtenemos el servicio de jugadores y al jugador local
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Función que se encargará de forzar el modo a Classic (Tercera persona)
local function forceClassicCamera()
	if player.CameraMode ~= Enum.CameraMode.Classic then
		player.CameraMode = Enum.CameraMode.Classic
	end
end

-- 1. Lo aplicamos inmediatamente al cargar el script
forceClassicCamera()

-- 2. Conectamos la señal de cambio para que vigile la propiedad "CameraMode"
-- Si cualquier otro script intenta cambiarlo a LockFirstPerson, esto lo regresará a Classic.
player:GetPropertyChangedSignal("CameraMode"):Connect(function()
	forceClassicCamera()
end)
