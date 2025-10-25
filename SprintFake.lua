-- SERVICIOS Y JUGADOR
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local player = Players.LocalPlayer

-- =================================================================
-- 2. VERIFICACIÓN DE JUGADOR
-- =================================================================
if player.Name ~= "MINIGUEINS_PRO" then
	return -- Detener el script si no es el jugador
end

-- SERVICIOS DEL JUGADOR
local playerGui = player:WaitForChild("PlayerGui")

-- 4. CARPETAS OBJETIVO (Con el timeout de 5 segundos)
local folders = {
	Workspace:WaitForChild("Students", 5),
	Workspace:FindFirstChild("Alices"),
	Workspace:FindFirstChild("Teachers")
}

-- FUNCIONES DE SPRINT

---
-- Busca el modelo del jugador dentro de las carpetas especificadas.
--
local function findPlayerModel()
	for _, folder in ipairs(folders) do
		if folder then
			local model = folder:FindFirstChild(player.Name)
			if model then
				return model
			end
		end
	end
	return nil
end

---
-- 5. Cambia el atributo "Running" del modelo del jugador.
--
local function toggleRunning()
	local model = findPlayerModel()
	if not model then 
		-- 1. Se eliminó el print()
		return 
	end
	
	local current = model:GetAttribute("Running")
	if current == nil then return end
	
	local newState = not current
	model:SetAttribute("Running", newState)
end

-- INTERFAZ DE USUARIO (UI)
local gameUi = playerGui:WaitForChild("GameUI")
local mobileFrame = gameUi:WaitForChild("Mobile")
local sprintButton = mobileFrame:WaitForChild("Sprint") -- El original

-- 3. GESTIÓN DE BOTONES
-- Ocultar el botón original PERMANENTEMENTE
sprintButton.Visible = false

-- Clonar el botón
local sprintInfButton = sprintButton:Clone()
sprintInfButton.Name = "Sprint_Inf"
sprintInfButton.Parent = mobileFrame
-- (Su visibilidad se define abajo)

---
-- Comprueba si el jugador está en las carpetas y
-- actualiza la visibilidad del BOTÓN CLONADO.
--
local function updateSprintButtonVisibility()
	local inSpecialFolder = false
	
	for _, folder in ipairs(folders) do
		if folder and folder:FindFirstChild(player.Name) then
			inSpecialFolder = true -- Sí está en una carpeta
			break
		end
	end
	
	-- 3. El botón CLONADO se muestra (true) si NO estás en una carpeta (not inSpecialFolder)
	--    y se oculta (false) si SÍ estás en una carpeta.
	sprintInfButton.Visible = not inSpecialFolder
end

-- CONEXIONES

-- 5. Conectar el clic del botón CLONADO
sprintInfButton.MouseButton1Click:Connect(toggleRunning)

-- 1. Detectar movimiento entre carpetas (Optimizado)
-- Esta función solo se llamará si algo entra/sale de las carpetas
local function onFolderChanged(child)
	-- Solo reaccionamos si el 'child' que se movió es nuestro jugador
	if child.Name == player.Name then
		updateSprintButtonVisibility()
	end
end

-- Conectamos la función a las 3 carpetas
for _, folder in ipairs(folders) do
	if folder then
		folder.ChildAdded:Connect(onFolderChanged)
		folder.ChildRemoved:Connect(onFolderChanged)
	end
end

-- 2. Conectar la aparición del personaje (Respawn)
player.CharacterAdded:Connect(function(character)
	task.wait(0.5) 
	updateSprintButtonVisibility() -- Comprobar visibilidad al aparecer

	local humanoid = character:WaitForChild("Humanoid")
	humanoid.Died:Connect(function()
		-- Ocultar el botón CLONADO al morir
		if sprintInfButton then
			sprintInfButton.Visible = false
		end
	end)
end)

-- 3. Comprobación inicial
-- (Por si el script se cargó después de que el personaje ya existía)
if player.Character then
	task.wait(0.5)
	updateSprintButtonVisibility()
	
	local humanoid = player.Character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			if sprintInfButton then
				sprintInfButton.Visible = false
			end
		end)
	end
end
