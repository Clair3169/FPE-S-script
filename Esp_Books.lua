-- 🟦 Book Highlighter Robusto (visible si el script corre tarde)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then return end

-- Configuración
local RENDER_DISTANCE = 150
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(135, 206, 250)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 255)

-- Estado
local highlights = {} -- [BasePart] = Highlight
local highlightsFolder = Workspace:FindFirstChild("HighligthsBooks_Main") or Instance.new("Folder")
highlightsFolder.Name = "HighligthsBooks_Main"
highlightsFolder.Parent = Workspace

local booksFolder = Workspace:FindFirstChild("Books")
local asleep = false

-- Utilidad: devuelve la parte válida a la que se adornea (si se pasa un Model, intenta PrimaryPart o la primera BasePart)
local function getTargetPartFromInstance(inst)
	if not inst then return nil end
	if inst:IsA("BasePart") then
		return inst
	elseif inst:IsA("Model") then
		if inst.PrimaryPart and inst.PrimaryPart:IsA("BasePart") then
			return inst.PrimaryPart
		end
		-- buscar la primera BasePart descendiente
		for _, d in ipairs(inst:GetDescendants()) do
			if d:IsA("BasePart") then
				return d
			end
		end
	end
	return nil
end

-- Posición local segura (espera HumanoidRootPart si necesario)
local function getLocalPos()
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

-- Remove
local function removeHighlight(meshPart)
	if not meshPart then return end
	local hl = highlights[meshPart]
	if hl then
		if hl.Parent then hl:Destroy() end
		highlights[meshPart] = nil
	end
end

-- Create single highlight for a target BasePart
local function createHighlightForPart(part)
	if not part or not part:IsA("BasePart") then return end
	if asleep then return end

	-- Evitar duplicados si ya existe
	local existing = highlights[part]
	if existing and existing.Parent then
		return
	elseif existing then
		existing:Destroy()
		highlights[part] = nil
	end

	-- Asegurar que la parte esté en el Workspace (replicada)
	if not part:IsDescendantOf(Workspace) then
		task.wait(0.05)
		if not part:IsDescendantOf(Workspace) then
			-- si aún no está, abortamos de forma segura
			return
		end
	end

	local hl = Instance.new("Highlight")
	hl.Name = "BookHighlight"
	hl.FillColor = HIGHLIGHT_FILL_COLOR
	hl.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
	hl.FillTransparency = 0
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = part
	hl.Parent = highlightsFolder

	-- NO establecemos Enabled aquí a true incondicionalmente; lo dejamos en nil/false y lo controlamos por distancia
	hl.Enabled = false

	highlights[part] = hl
end

-- Crear highlight dado un objeto de Books (puede ser BasePart o Model)
local function createHighlightForBookObject(bookObj)
	if not bookObj then return end
	local target = getTargetPartFromInstance(bookObj)
	if target then
		createHighlightForPart(target)
	end
end

-- Actualiza visibilidad según distancia; forceUpdate obliga recalculo incluso si Estado coincide
local function updateHighlightsInRange(forceUpdate)
	local localPos = getLocalPos()
	if not localPos or asleep then
		-- Si estamos dormidos, aseguramos apagar todo
		for part, hl in pairs(highlights) do
			if hl and hl.Enabled then
				hl.Enabled = false
			end
		end
		return
	end

	for part, hl in pairs(highlights) do
		if not part or not part.Parent then
			removeHighlight(part)
		else
			local dist = (part.Position - localPos).Magnitude
			local shouldBeVisible = dist <= RENDER_DISTANCE
			-- Si no hay highlight (por alguna razón), lo recreamos
			if (not hl or not hl.Parent) then
				highlights[part] = nil
				createHighlightForPart(part)
				hl = highlights[part]
			end
			if hl then
				if forceUpdate or hl.Enabled ~= shouldBeVisible then
					hl.Enabled = shouldBeVisible
				end
			end
		end
	end
end

-- Recorrer la carpeta Books (y sus hijos) y crear highlights
local function scanAndActivateExistingBooks()
	if not booksFolder then return end
	for _, child in ipairs(booksFolder:GetChildren()) do
		-- si es modelo o basepart -- soporta estructuras donde book es un Model
		createHighlightForBookObject(child)
		-- Si el child es Model, también conectar DescendantAdded para detectar partes agregadas luego
		if child:IsA("Model") then
			child.DescendantAdded:Connect(function(desc)
				-- si añade una BasePart dentro del modelo, y no tenemos highlight, crearla
				if desc:IsA("BasePart") then
					-- Si el model tiene PrimaryPart, preferimos esa; pero si no, aceptamos esta parte
					local primary = getTargetPartFromInstance(child)
					if primary and not highlights[primary] then
						createHighlightForPart(primary)
					end
				end
			end)
		end
	end
	-- Forzamos actualización inmediata de visibilidad (por si el jugador está cerca ahora)
	updateHighlightsInRange(true)
end

-- Connect events for Books folder (only once)
local function connectBookEvents()
	if not booksFolder then return end
	if booksFolder:GetAttribute("EventsConnected") then return end
	booksFolder:SetAttribute("EventsConnected", true)

	-- Si se añade un child nuevo (BasePart o Model), crear highlight inmediato
	booksFolder.ChildAdded:Connect(function(child)
		if asleep then return end
		createHighlightForBookObject(child)

		-- Si es Model, conectar DescendantAdded para detectar partes internas
		if child:IsA("Model") then
			child.DescendantAdded:Connect(function(desc)
				if asleep then return end
				if desc:IsA("BasePart") then
					local primary = getTargetPartFromInstance(child)
					if primary and not highlights[primary] then
						createHighlightForPart(primary)
					end
				end
			end)
		end

		-- Forzamos sync de visibilidad (útil cuando el script corre tarde)
		updateHighlightsInRange(true)
	end)

	booksFolder.ChildRemoved:Connect(function(child)
		-- al eliminar un book (modelo o parte), buscamos su target y lo removemos
		local target = getTargetPartFromInstance(child)
		if target then
			removeHighlight(target)
		end
	end)
end

-- Inicialización robusta: esperar Character+Root, Books folder y luego escanear + conectar
local function initialize()
	-- 1) Esperar Character y HumanoidRootPart
	local char = player.Character
	if not char then
		char = player.CharacterAdded:Wait()
	end
	local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 10)

	-- 2) Asegurar carpeta Books (puede existir ya)
	booksFolder = booksFolder or Workspace:FindFirstChild("Books")
	if not booksFolder then
		-- esperar un corto tiempo si no existe aun
		local tries = 0
		while not booksFolder and tries < 40 do
			booksFolder = Workspace:FindFirstChild("Books")
			if booksFolder then break end
			tries = tries + 1
			task.wait(0.1)
		end
	end

	-- 3) Conectar y escanear si existe
	if booksFolder then
		connectBookEvents()
		-- ESCANEAR y crear highlights para TODOS los libros existentes (funciona si script corre tarde)
		scanAndActivateExistingBooks()
	end

	-- 4) Hook de movimiento: actualizar cuando te mueves lo suficiente
	local lastPos = root.Position
	root:GetPropertyChangedSignal("Position"):Connect(function()
		if asleep then return end
		local newPos = root.Position
		-- umbral para evitar demasiadas actualizaciones (ajusta si quieres)
		if (newPos - lastPos).Magnitude > 4 then
			lastPos = newPos
			updateHighlightsInRange()
		end
	end)
end

-- Check sleep state (Alices / Teachers)
local function checkSleepState()
	local char = player.Character
	if not char then return end
	local parent = char.Parent
	local newAsleep = parent and (parent.Name == "Alices" or parent.Name == "Teachers")

	if newAsleep ~= asleep then
		asleep = newAsleep
		if asleep then
			-- apagar todos
			for part, hl in pairs(highlights) do
				if hl and hl.Enabled then
					hl.Enabled = false
				end
			end
		else
			-- al despertar, forzamos rescan y update inmediato
			booksFolder = booksFolder or Workspace:FindFirstChild("Books")
			if booksFolder then
				scanAndActivateExistingBooks()
			end
			updateHighlightsInRange(true)
		end
	end
end

-- Listeners para Workspace (libros recreados)
Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Books" and child:IsA("Folder") then
		booksFolder = child
		-- permitimos reconnect
		if booksFolder then
			connectBookEvents()
			scanAndActivateExistingBooks()
		end
	end
end)

Workspace.ChildRemoved:Connect(function(child)
	if child == booksFolder then
		for p in pairs(highlights) do removeHighlight(p) end
		booksFolder = nil
	end
end)

-- Monitor de CharacterAdded
player.CharacterAdded:Connect(function(char)
	char:GetPropertyChangedSignal("Parent"):Connect(checkSleepState)
	checkSleepState()
	-- re-inicializar (si el script ya corría)
	task.defer(function()
		initialize()
		updateHighlightsInRange(true)
	end)
end)

-- Si el Character ya existe al inicio
if player.Character then
	player.Character:GetPropertyChangedSignal("Parent"):Connect(checkSleepState)
	checkSleepState()
	task.defer(function()
		initialize()
		updateHighlightsInRange(true)
	end)
end

-- Auto-verificador periódicamente reconcilia highlights huérfanos y asegura visibilidad
task.spawn(function()
	while task.wait(3) do
		-- Si no hay carpeta Books, saltar
		if not booksFolder then continue end
		-- Asegurar que cada book tenga su highlight
		for _, child in ipairs(booksFolder:GetChildren()) do
			local target = getTargetPartFromInstance(child)
			if target and not highlights[target] and not asleep then
				createHighlightForPart(target)
			end
		end
		-- Remover highlights sin target
		for part, hl in pairs(highlights) do
			if not part or not part.Parent then
				removeHighlight(part)
			end
		end
		-- Forzar refresco visual (si el jugador ya tiene root)
		updateHighlightsInRange(true)
	end
end)
