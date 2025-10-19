-- ======================================================
-- 💪 BOOST DE STAMINA (Atributos del modelo del jugador)
-- ======================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- Carpetas donde puede estar el modelo del jugador
local validFolders = {"Students", "Alices", "Teachers"}

-- 🧭 Busca el modelo actual del jugador en las carpetas válidas
local function getCharacterModel()
	for _, folderName in ipairs(validFolders) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			local model = folder:FindFirstChild(LocalPlayer.Name)
			if model and model:IsA("Model") then
				return model
			end
		end
	end
	return nil
end

-- ⚙️ Aplica los atributos de stamina al modelo
local function applyBoost()
	local model = getCharacterModel()
	if model then
		if model:GetAttribute("Stamina") ~= nil then
			model:SetAttribute("Stamina", 5000)
		end
		if model:GetAttribute("MaxStamina") ~= nil then
			model:SetAttribute("MaxStamina", 5000)
		end
	end
end

-- 🔁 Sistema de refuerzo automático (al morir, reaparecer o moverse de carpeta)
local function setupAutoBoost()
	-- Cuando reaparece el personaje
	LocalPlayer.CharacterAdded:Connect(function()
		repeat task.wait(0.3) until getCharacterModel()
		applyBoost()
	end)

	-- Revisa cada cierto tiempo si el jugador fue movido de carpeta
	task.spawn(function()
		while task.wait(1) do
			applyBoost()
		end
	end)
end

-- 🚀 Inicio del script
task.spawn(function()
	repeat task.wait(0.5) until getCharacterModel()
	applyBoost()
	setupAutoBoost()
end)

