-- LocalScript: Fake CFrame WalkSpeed (optimizado, sin mover cámara)
-- Simula un WalkSpeed visual usando CFrame local sin afectar al servidor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

-- ==== CONFIGURACIÓN ====
local FakeSpeed = 120           -- velocidad visual (aparente)
local MoveSmoothness = 0.15    -- 0.05 = muy rápido, 0.25 = más suave
-- ========================

local char, hrp, humanoid
local moving = false
local connStep, connMove

-- Función principal para configurar el personaje
local function setupCharacter(c)
	char = c
	hrp = c:WaitForChild("HumanoidRootPart")
	humanoid = c:WaitForChild("Humanoid")

	-- Desconectar conexiones anteriores si las hubiera
	if connStep then connStep:Disconnect() end
	if connMove then connMove:Disconnect() end

	-- Detectar cuando el jugador empieza o deja de moverse
	connMove = humanoid:GetPropertyChangedSignal("MoveDirection"):Connect(function()
		moving = humanoid.MoveDirection.Magnitude > 0
	end)

	-- Aplicar movimiento visual solo cuando haya movimiento real
	connStep = RunService.RenderStepped:Connect(function(dt)
		if not moving or not hrp or not humanoid then return end

		local dir = humanoid.MoveDirection
		if dir.Magnitude == 0 then return end

		-- Calcular desplazamiento visual
		local moveDist = FakeSpeed * dt
		local newPos = hrp.Position + dir * moveDist

		-- Aplicar suavizado y orientación del cuerpo
		local newCFrame = hrp.CFrame:Lerp(CFrame.new(newPos, newPos + hrp.CFrame.LookVector), MoveSmoothness)
		hrp.CFrame = newCFrame
	end)
end

-- Reiniciar automáticamente cuando el jugador reaparece
player.CharacterAdded:Connect(setupCharacter)
if player.Character then
	setupCharacter(player.Character)
end

print("[Fake WalkSpeed CFrame] activo – cámara sin modificar, velocidad visual:", FakeSpeed)￼Enter
