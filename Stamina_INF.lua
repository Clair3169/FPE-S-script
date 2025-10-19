-- ======================================================
-- 💪 BOOST DE STAMINA (Optimizado)
-- ======================================================

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

-- --- OPTIMIZACIÓN 1: Cache de referencias ---
-- Guardamos las carpetas aquí para no buscarlas cada vez
local folderCache = {}
local validFolderNames = {"Students", "Alices", "Teachers"}

-- Guardamos el modelo del jugador aquí para no buscarlo cada segundo
local cachedModel = nil

-- ------------------------------------------------------

-- 🧭 Busca el modelo del jugador (versión optimizada)
local function getCharacterModel()
	-- 1. Revisa si el modelo en caché sigue siendo válido
	if cachedModel and cachedModel.Parent then
		-- Revisa si el padre sigue siendo una de las carpetas válidas
		local parentName = cachedModel.Parent.Name
		if folderCache[parentName] then
			return cachedModel -- ¡Sigue válido! No busques más.
		end
	end

	-- 2. Si no es válido o no existe, busca de nuevo
	cachedModel = nil -- Limpia el caché
	for folderName, folder in pairs(folderCache) do
		if folder then -- Asegurarse que la carpeta existe
			local model = folder:FindFirstChild(LocalPlayer.Name)
			if model and model:IsA("Model") then
				cachedModel = model -- ¡Encontrado! Guárdalo en el caché
				return model
			end
		end
	end
	
	return nil -- No se encontró en ninguna carpeta
end

-- ⚙️ Aplica los atributos de stamina al modelo
local function applyBoost(model)
	-- Se le pasa el modelo para no tener que buscarlo otra vez
	if not model then return end

	-- Usamos un solo SetAttribute. Si el atributo no existe, esto lo creará.
	-- Si tu juego REQUIERE que el atributo exista, vuelve a tu método con GetAttribute
	model:SetAttribute("Stamina", 1000)
	model:SetAttribute("MaxStamina", 1000)
end

-- === OPTIMIZACIÓN 2: Lógica Principal Unificada ===

-- Función que se ejecuta una sola vez y maneja todo
local function main()
	
	-- 1. Espera y encuentra las carpetas válidas UNA SOLA VEZ
	for _, name in ipairs(validFolderNames) do
		-- Espera hasta 15 segundos por cada carpeta. Si no aparece, la ignora.
		local folder = Workspace:WaitForChild(name, 15)
		if folder then
			folderCache[name] = folder -- Guarda la carpeta en el caché
		end
	end

	-- 2. Conexión al respawn (CharacterAdded)
	-- Esto solo limpia el caché. El loop principal se encargará de buscar el nuevo.
	LocalPlayer.CharacterAdded:Connect(function(character)
		cachedModel = nil -- El modelo antiguo ya no sirve, bórralo del caché
		-- El loop de abajo se encargará de encontrar el nuevo modelo
	end)

	-- 3. Loop principal de actualización (¡SOLO UNO!)
	-- Este loop se encarga de:
	--    a) Aplicar el boost la primera vez.
	--    b) Aplicar el boost después de un respawn (porque cachedModel será nil).
	--    c) Aplicar el boost si el modelo se mueve de carpeta (porque el caché se invalidará).
	while true do 
		local model = getCharacterModel() -- Esta función ahora es muy rápida gracias al caché
		if model then
			applyBoost(model)
		end
		task.wait(1) -- Revisa solo una vez por segundo
	end
end

-- 🚀 Inicia el script principal en un hilo separado
task.spawn(main)
