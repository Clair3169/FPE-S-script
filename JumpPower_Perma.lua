-- Script: Mantener JumpPower constante

local JUMP_POWER_CONSTANT = 35.012

-- Espera a que el personaje cargue
local player = game.Players.LocalPlayer

local function setupCharacter(character)
	local humanoid = character:WaitForChild("Humanoid")

	-- Asigna el JumpPower inicial
	humanoid.JumpPower = JUMP_POWER_CONSTANT

	-- Asegura que nunca cambie
	humanoid:GetPropertyChangedSignal("JumpPower"):Connect(function()
		if humanoid.JumpPower ~= JUMP_POWER_CONSTANT then
			humanoid.JumpPower = JUMP_POWER_CONSTANT
		end
	end)
end

-- Detecta cuando aparece el personaje
player.CharacterAdded:Connect(setupCharacter)

-- Si ya está cargado, lo configura también
if player.Character then
	setupCharacter(player.Character)
end
