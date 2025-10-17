-- ======================================================
-- 🟢 BOOST DE ATRIBUTOS CON "BAT"
-- ======================================================

repeat task.wait() until game:IsLoaded()

-- Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- Jugador local
local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then
	warn("No se encontró el jugador local.")
	return
end

-- Configuración de valores
local DEFAULT_MAX = 100
local DEFAULT_STAMINA = 100
local BOOST_MAX = 2000
local BOOST_STAMINA = 2000

-- Función para obtener el modelo del jugador dentro de Workspace.Students
local function getStudentCharacter()
	local studentsFolder = Workspace:FindFirstChild("Students")
	if not studentsFolder then return nil end
	return studentsFolder:FindFirstChild(LocalPlayer.Name)
end

-- Aplica boost o restaura según la presencia del "Bat"
local function applyStaminaBoost(character)
	if not character then return end

	local hasBat = character:FindFirstChild("Bat")
	if hasBat then
		character:SetAttribute("MaxStamina", BOOST_MAX)
		character:SetAttribute("Stamina", BOOST_STAMINA)
	else
		character:SetAttribute("MaxStamina", DEFAULT_MAX)
		character:SetAttribute("Stamina", DEFAULT_STAMINA)
	end
end

-- Configura listeners dentro del modelo del jugador
local function setupCharacterListeners(character)
	if not character then return end

	-- Comprobación inicial
	applyStaminaBoost(character)

	-- Cuando se agrega un objeto (por ejemplo el "Bat")
	character.ChildAdded:Connect(function(child)
		if child.Name == "Bat" then
			applyStaminaBoost(character)
		end
	end)

	-- Cuando se elimina un objeto (por ejemplo se suelta o destruye el "Bat")
	character.ChildRemoved:Connect(function(child)
		if child.Name == "Bat" then
			applyStaminaBoost(character)
		end
	end)

	-- Seguridad: Si el modelo cambia de carpeta (sale de Students o se mueve)
	character.AncestryChanged:Connect(function(_, newParent)
		if not newParent or newParent ~= Workspace:FindFirstChild("Students") then
			-- Restaurar valores al salir de Students
			applyStaminaBoost(character)
		end
	end)
end

-- Manejar respawns o muertes
local function onCharacterAdded(newCharacter)
	if not newCharacter then return end

	-- Esperar a que el modelo se mueva dentro de Workspace.Students
	newCharacter.AncestryChanged:Connect(function(_, newParent)
		if newParent == Workspace:FindFirstChild("Students") then
			task.defer(function()
				setupCharacterListeners(newCharacter)
			end)
		end
	end)

	-- Si ya inicia dentro de Students
	if newCharacter.Parent == Workspace:FindFirstChild("Students") then
		setupCharacterListeners(newCharacter)
	end
end

-- Conectarse al evento CharacterAdded (para respawns)
LocalPlayer.CharacterAdded:Connect(onCharacterAdded)

-- Si ya tiene un modelo existente dentro de Students, iniciar de inmediato
local currentChar = getStudentCharacter()
if currentChar then
	setupCharacterListeners(currentChar)
end
