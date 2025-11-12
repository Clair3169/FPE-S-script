local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players:GetPlayers()[1]
local playerGui = player:WaitForChild("PlayerGui")

-- Crear GUI si no existe
local screenGui = playerGui:FindFirstChild("MusicTimerGui") or Instance.new("ScreenGui")
screenGui.Name = "MusicTimerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

-- Crear etiqueta del temporizador si no existe
local label = screenGui:FindFirstChild("TimerLabel") or Instance.new("TextLabel")
label.Name = "TimerLabel"
label.Size = UDim2.new(0, 90, 0, 28) -- más pequeño
label.Position = UDim2.new(0.5, -45, 0, -3) -- arriba y centrado
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "-:--"
label.Visible = true
label.Parent = screenGui

-- Referencias de sonidos
local phaseSongs = SoundService:WaitForChild("AllMusic"):WaitForChild("PhaseSongs")
local base = phaseSongs:WaitForChild("Base")
local phase2 = phaseSongs:WaitForChild("Phase2")

local quietHalls = base:WaitForChild("QuietHalls")
local properBehavior = base:WaitForChild("ProperBehavior")
local studentSound = phase2:WaitForChild("Student")

-- [[ ¡AQUÍ ESTÁ LA SOLUCIÓN! ]]
-- En esta tabla, defines cuántos segundos quieres "recortar" del final de cada música.
-- ¡Puedes cambiar estos valores como quieras!
-- para retar minutos es escribir un calculo (2 * 60) + 13, 2 min con 13 segundos
-- (-- * 60) + --
local soundOffsets = {
	[quietHalls] = 0,     -- Ejemplo: Resta 3.5 segundos al total de quietHalls
	[properBehavior] = 3,  -- Ejemplo: Resta 2 segundos al total de properBehavior
	[studentSound] = 13    -- Ejemplo: No resta nada a studentSound (puedes poner el valor que quieras)
}

-- Función de formato M:SS (MODIFICADA)
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	-- Se cambió %02d por %d para los minutos
	return string.format("%d:%02d", minutes, secs) 
end

-- Esperar hasta que los sonidos tengan duración
repeat task.wait() until quietHalls.TimeLength > 0 and properBehavior.TimeLength > 0 and studentSound.TimeLength > 0

-- Comprobar si el jugador está en Alices o Teachers
local function isInExcludedFolder()
	local char = player.Character
	if not char then return false end
	local parent = char.Parent
	return parent and (parent.Name == "Alices" or parent.Name == "Teachers")
end

-- Bucle principal del temporizador
task.spawn(function()
	while task.wait(0.1) do
		label.Visible = not isInExcludedFolder()

		local activeSound
		if studentSound.IsPlaying then
			activeSound = studentSound
		elseif properBehavior.IsPlaying then
			activeSound = properBehavior
		elseif quietHalls.IsPlaying then
			activeSound = quietHalls
		end

		if activeSound then
			-- [[ MODIFICACIÓN DEL CÁLCULO ]]
			
			-- 1. Obtenemos el descuento de tiempo para la canción actual (0 si no está en la tabla)
			local offset = soundOffsets[activeSound] or 0
			
			-- 2. Calculamos la duración "efectiva" restando ese descuento
			local effectiveTimeLength = activeSound.TimeLength - offset
			
			-- 3. Calculamos el tiempo restante usando la nueva duración efectiva
			local remaining = math.max(effectiveTimeLength - activeSound.TimePosition, 0)
			
			-- [[ FIN DE LA MODIFICACIÓN ]]

			label.Text = formatTime(remaining)

			-- Cambiar color cuando queden <= 25s
			if remaining <= 26 then
				label.TextColor3 = Color3.fromRGB(255, 0, 0)
			else
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end)
