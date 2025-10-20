-- LocalScript (puedes ejecutar en la Command Bar o como GUI script)

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
label.Position = UDim2.new(0.5, -45, 0, 8) -- arriba y centrado
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "--:--"
label.Visible = true
label.Parent = screenGui

-- Ruta base de los sonidos
local base = SoundService
	:WaitForChild("AllMusic")
	:WaitForChild("PhaseSongs")
	:WaitForChild("Base")

local quietHalls = base:WaitForChild("QuietHalls")
local properBehavior = base:WaitForChild("ProperBehavior")

-- Función de formato MM:SS
local function formatTime(seconds)
	local minutes = math.floor(seconds / 60)
	local secs = math.floor(seconds % 60)
	return string.format("%02d:%02d", minutes, secs)
end

-- Esperar hasta que los sonidos tengan duración
repeat task.wait() until quietHalls.TimeLength > 0 and properBehavior.TimeLength > 0

print("[Temporizador activo]")
print("QuietHalls:", quietHalls.TimeLength, "ProperBehavior:", properBehavior.TimeLength)

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
		-- Ocultar si está en carpeta excluida
		label.Visible = not isInExcludedFolder()

		-- Detectar qué sonido está activo
		local activeSound
		if properBehavior.IsPlaying then
			activeSound = properBehavior
		elseif quietHalls.IsPlaying then
			activeSound = quietHalls
		end

		if activeSound then
			local remaining = math.max(activeSound.TimeLength - activeSound.TimePosition, 0)
			label.Text = formatTime(remaining)

			-- Cambiar color cuando queden <= 25s
			if remaining <= 25 then
				label.TextColor3 = Color3.fromRGB(139, 0, 0) -- rojo oscuro
			else
				label.TextColor3 = Color3.fromRGB(255, 255, 255)
			end
		end
	end
end)
