local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local ReliableRedEvent = ReplicatedStorage:WaitForChild("ReliableRedEvent")

local TOOL_NAME = "HealPotion"
local MIN_HEALTH = 35
local RUNS_PER_HEAL = 3
local HEAL_COOLDOWN = 1

-- Estado interno
local canHeal = true
local characterConnections = {}

-- 🔹 Función de curación (Lógica de red)
local function silentDoubleHeal(tool)
	if not canHeal then return end
	canHeal = false

	for i = 1, RUNS_PER_HEAL do
		local args = {
			{ ["?"] = { { tool, n = 1 } } },
			{}
		}
		ReliableRedEvent:FireServer(unpack(args))
	end

	task.delay(HEAL_COOLDOWN, function()
		canHeal = true
	end)
end

-- 🔹 Lógica MAESTRA: Verifica vida Y existencia del item
local function enforceHealthCheck()
	local char = player.Character
	if not char then return end
	
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid or humanoid.Health <= 0 then return end

	-- 1. Si la vida está bien, no hacemos nada
	if humanoid.Health > MIN_HEALTH then 
		return 
	end

	-- >>> VERIFICACIÓN DE EXISTENCIA <<<
	local backpack = player:FindFirstChild("Backpack")
	local currentTool = char:FindFirstChildOfClass("Tool")
	
	-- Buscamos si la tool existe en Backpack O si ya la tenemos en la mano
	local potionInBackpack = backpack and backpack:FindFirstChild(TOOL_NAME)
	local holdingPotion = currentTool and currentTool.Name == TOOL_NAME

	-- ¡AQUÍ ESTÁ EL CAMBIO!
	-- Si NO la tenemos en la mochila Y NO la tenemos en la mano...
	if not potionInBackpack and not holdingPotion then
		-- ...El script se duerme y te deja usar cualquier otra arma libremente.
		return 
	end

	-- >>> MODO PRIORIDAD (Solo si tenemos la poción y vida baja) <<<

	-- CASO A: Ya la tenemos equipada
	if holdingPotion then
		silentDoubleHeal(currentTool)
		return
	end

	-- CASO B: Tenemos OTRA cosa equipada (y sí tenemos la poción guardada)
	if currentTool and currentTool.Name ~= TOOL_NAME then
		-- Desequipamos la otra arma forzosamente para dar espacio a la poción
		currentTool.Parent = backpack
	end

	-- CASO C: La buscamos en la mochila y la equipamos
	if potionInBackpack then
		potionInBackpack.Parent = char -- Equipar
		
		-- Pequeña espera técnica para asegurar el equipamiento
		local equippedTool = char:FindFirstChild(TOOL_NAME)
		if equippedTool then
			silentDoubleHeal(equippedTool)
		end
	end
end

-- 🔹 Gestión de Eventos del Personaje
local function connectCharacterListeners(char)
	-- Limpiar conexiones anteriores
	for _, conn in pairs(characterConnections) do
		conn:Disconnect()
	end
	characterConnections = {}

	local humanoid = char:WaitForChild("Humanoid")

	-- 1. Cambio de Salud
	local healthConn = humanoid.HealthChanged:Connect(function()
		enforceHealthCheck()
	end)
	table.insert(characterConnections, healthConn)

	-- 2. Alguien quitó una tool (o la guardamos)
	local childRemovedConn = char.ChildRemoved:Connect(function(child)
		if child:IsA("Tool") then
			enforceHealthCheck()
		end
	end)
	table.insert(characterConnections, childRemovedConn)

	-- 3. Alguien equipó una tool
	local childAddedConn = char.ChildAdded:Connect(function(child)
		if child:IsA("Tool") then
			-- Usamos defer para dejar que ocurra el equipamiento y luego verificar si es legal
			task.defer(enforceHealthCheck)
		end
	end)
	table.insert(characterConnections, childAddedConn)

	-- Chequeo inicial
	enforceHealthCheck()
end

-- Inicialización
if player.Character then
	connectCharacterListeners(player.Character)
end

player.CharacterAdded:Connect(connectCharacterListeners)

-- 🔹 Listener del Backpack (IMPORTANTE)
-- Si estamos a poca vida pero sin poción, y de repente recogemos una,
-- este evento activará el script inmediatamente.
local function monitorBackpack()
	local backpack = player:WaitForChild("Backpack")
	
	backpack.ChildAdded:Connect(function(child)
		if child.Name == TOOL_NAME then
			enforceHealthCheck()
		end
	end)
end
monitorBackpack()
