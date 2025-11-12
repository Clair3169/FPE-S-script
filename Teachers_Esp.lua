-- 🧠 Local Script optimizado solo con eventos (sin Heartbeat)
repeat task.wait() until game:IsLoaded()

--// Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--// Variables principales
local LocalPlayer = Players.LocalPlayer

local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

--// Configuración
local MAX_RENDER_DISTANCE = 250
local UPDATE_THRESHOLD = 5 -- (Copiado del Script 1) Umbral de movimiento para actualizar
local MAX_VISIBLE_ALICES = 2
local MAX_VISIBLE_TEACHERS = 4

--// Colores
local COLORS = {
	Teachers = Color3.fromRGB(255, 0, 0),
	Alices = Color3.fromRGB(150, 0, 0),
}

--// Cache
local HighlightCache = Workspace:FindFirstChild("HighlightCache_Main") or Instance.new("Folder")
HighlightCache.Name = "HighlightCache_Main"
HighlightCache.Parent = Workspace

local ActiveHighlights = {}
local HeadCache = {}

------------------------------------------------------------
-- 🧩 Obtener cabeza real
------------------------------------------------------------
local function getRealHead(model)
	if not model or not model:IsA("Model") then return nil end
	if HeadCache[model] then return HeadCache[model] end

	local teacherName = model:GetAttribute("TeacherName")
	local head = model:FindFirstChild("Head")
	if not head then return nil end

	if teacherName == "AlicePhase2" and head:IsA("Model") then
		local inner = head:FindFirstChild("Head")
		if inner and inner:IsA("BasePart") then
			HeadCache[model] = inner
			return inner
		end
	end

	if head:IsA("BasePart") then
		HeadCache[model] = head
		return head
	end
	return nil
end

------------------------------------------------------------
-- 🧩 Detectar carpeta local
------------------------------------------------------------
local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

------------------------------------------------------------
-- 🧩 Crear o usar Highlight
------------------------------------------------------------
local function getOrCreateHighlight(model, folderName)
	if ActiveHighlights[model] then
		return ActiveHighlights[model].Highlight
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = model.Name .. "_HL_" .. folderName
	highlight.Adornee = model
	highlight.Enabled = false
	highlight.OutlineColor = COLORS[folderName] or Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Parent = HighlightCache

	ActiveHighlights[model] = { Highlight = highlight, Folder = folderName }
	return highlight
end

------------------------------------------------------------
-- 🧩 Desactivar y limpiar highlight
------------------------------------------------------------
local function disableHighlight(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		data.Highlight.Enabled = false
		data.Highlight.Adornee = nil
	end
end

------------------------------------------------------------
-- 🧩 Control de distancia (Versión 2.0 con Límites)
------------------------------------------------------------
local function updateHighlightDistance()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	if not myHead then return end
	local myPos = myHead.Position

	local aliceDistances = {}
	local teacherDistances = {}
	
	-- 1. Calcular distancias y clasificar por equipo
	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		local targetHead = getRealHead(model)

		if not hl or not targetHead then
			disableHighlight(model)
			continue
		end

		local dist = (targetHead.Position - myPos).Magnitude

		if dist > MAX_RENDER_DISTANCE then
			hl.Enabled = false -- Desactivar si está fuera de rango máximo
			continue
		end
		
		-- Clasificar por carpeta para aplicar límites
		if data.Folder == "Alices" then
			table.insert(aliceDistances, {model, dist})
		elseif data.Folder == "Teachers" then
			table.insert(teacherDistances, {model, dist})
		end
	end

	-- 2. Ordenar las listas por distancia (más cercano primero)
	table.sort(aliceDistances, function(a, b) return a[2] < b[2] end)
	table.sort(teacherDistances, function(a, b) return a[2] < b[2] end)

	local newVisible = {} -- Un "mapa" para saber quién debe estar visible

	-- 3. Añadir Alices más cercanas (hasta el límite)
	for i = 1, math.min(MAX_VISIBLE_ALICES, #aliceDistances) do
		newVisible[aliceDistances[i][1]] = true -- Marcar este modelo como visible
	end

	-- 4. Añadir Teachers más cercanos (hasta el límite)
	for i = 1, math.min(MAX_VISIBLE_TEACHERS, #teacherDistances) do
		newVisible[teacherDistances[i][1]] = true -- Marcar este modelo como visible
	end

	-- 5. Actualizar el estado de TODOS los highlights
	for model, data in pairs(ActiveHighlights) do
		-- Solo activar si el modelo está en nuestra lista de "newVisible"
		if newVisible[model] then
			data.Highlight.Enabled = true
			data.Highlight.Adornee = model -- Re-asegurar el Adornee
		else
			-- Desactivar si no está en la lista (o estaba fuera de rango)
			data.Highlight.Enabled = false
		end
	end
end

------------------------------------------------------------
-- 🧩 Escanear carpetas según rol (dividido en frames)
------------------------------------------------------------
local function scanFolder(folder, localFolderName)
	local models = folder:GetChildren()
	for _, model in ipairs(models) do
		task.wait() -- 🔥 reduce pico de FPS
		if not model:IsA("Model") or model.Name == LocalPlayer.Name then
			disableHighlight(model)
			continue
		end

		local head = getRealHead(model)
		if not head then
			disableHighlight(model)
			continue
		end

		local allowHighlight = false
		if localFolderName == "Teachers" and folder.Name == "Alices" then
			allowHighlight = true
		elseif localFolderName == "Alices" and folder.Name == "Teachers" then
			allowHighlight = true
		elseif localFolderName == "Students" and (folder.Name == "Alices" or folder.Name == "Teachers") then
			allowHighlight = true
		end

		if not allowHighlight then
			disableHighlight(model)
			continue
		end

		local hl = getOrCreateHighlight(model, folder.Name)
		if hl then
			hl.Adornee = model
		end
	end
	updateHighlightDistance()
end

------------------------------------------------------------
-- 🧩 Escaneo principal
------------------------------------------------------------
local function performScan()
	local myFolder = detectPlayerFolder()
	if not myFolder then return end
	local myFolderName = myFolder.Name

	for folderName, folder in pairs(Folders) do
		task.defer(function()
			scanFolder(folder, myFolderName)
		end)
	end
end

------------------------------------------------------------
-- 🧩 Eventos principales
------------------------------------------------------------

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	performScan()
end)

-- Almacenar la última posición fuera de la función
local lastPos = Vector3.zero

-- Actualizar al moverse el jugador
local function connectHeadPosition()
	local char = LocalPlayer.Character
	if not char then return end
	local head = getRealHead(char)
	if not head then return end

	-- Inicializar la posición
	lastPos = head.Position 

	head:GetPropertyChangedSignal("Position"):Connect(function()
		local newPos = head.Position
		-- ⬇️ Comprobar si nos movimos lo suficiente ⬇️
		if (newPos - lastPos).Magnitude > UPDATE_THRESHOLD then
			lastPos = newPos
			updateHighlightDistance() -- Solo actualizar si el movimiento supera el umbral
		end
	end)
end

LocalPlayer.CharacterRemoving:Connect(function()
	for _, data in pairs(ActiveHighlights) do
		if data.Highlight then
			data.Highlight.Enabled = false
		end
	end
end)

connectHeadPosition()

-- Reaccionar a cambios en carpetas
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(child)
		task.defer(performScan)
	end)
	folder.ChildRemoved:Connect(function(child)
		disableHighlight(child)
		-- ⬇️ ¡IMPORTANTE! Limpiar las tablas de caché ⬇️
		ActiveHighlights[child] = nil
		HeadCache[child] = nil
	end)
end

performScan()

------------------------------------------------------------
-- ♻️ Limpieza automática por evento (¡COPIADO DEL SCRIPT 1!)
------------------------------------------------------------
Workspace.DescendantRemoving:Connect(function(obj)
	-- Si el objeto que se está eliminando es un modelo que teníamos cacheado
	if ActiveHighlights[obj] then
		local data = ActiveHighlights[obj]
		if data and data.Highlight then
			data.Highlight:Destroy() -- Destruir el highlight para no dejar basura
		end
		-- Limpiar ambas tablas
		ActiveHighlights[obj] = nil
		HeadCache[obj] = nil
	end
end)
