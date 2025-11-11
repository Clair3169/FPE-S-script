-- 🟢 Student Highlighter Optimizado (solo eventos, sin Heartbeat)
repeat task.wait() until game:IsLoaded()

-- ⚙️ Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

-- 👤 Jugador local
local localPlayer = Players.LocalPlayer

-- 📂 Carpetas
local studentsFolder = Workspace:WaitForChild("Students")
local VALID_FOLDERS = { "Alices", "Teachers" }

-- ⚙️ Configuración
local MAX_VISIBLE = 10
local MAX_DISTANCE = 200
local UPDATE_THRESHOLD = 5

-- 🧠 Estado
local systemActive = false
local activeHighlights = {}
local visibleStudents = {}

-- 🔧 Carpeta cache persistente
local highlightCache = Workspace:FindFirstChild("HighlightCache_Students") or Instance.new("Folder")
highlightCache.Name = "HighlightCache_Students"
highlightCache.Parent = Workspace

------------------------------------------------------------
-- 🧩 Obtener posición del modelo
------------------------------------------------------------
local function getModelPosition(model)
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			return part.Position
		end
	end
	return nil
end

------------------------------------------------------------
-- 🧩 Crear o recuperar Highlight de cache
------------------------------------------------------------
local function getOrCreateHighlight(character)
	if not character or not character:IsA("Model") then return end

	if activeHighlights[character] then
		return activeHighlights[character]
	end

	local cacheName = character.Name .. "_HL_Student"
	local cached = highlightCache:FindFirstChild(cacheName)
	if cached and cached:IsA("Highlight") then
		cached.Adornee = character
		cached.Enabled = false
		activeHighlights[character] = cached
		return cached
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = cacheName
	highlight.OutlineColor = Color3.fromRGB(0, 255, 0)
	highlight.FillTransparency = 0.85
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Adornee = character
	highlight.Parent = highlightCache

	activeHighlights[character] = highlight
	return highlight
end

------------------------------------------------------------
-- 🧩 Cambiar estado del Highlight
------------------------------------------------------------
local function updateHighlightState(character, state)
	local highlight = getOrCreateHighlight(character)
	if not highlight then return end
	highlight.Enabled = state
	highlight.Adornee = character
end

------------------------------------------------------------
-- 🧩 Actualizar lista visible
------------------------------------------------------------
local function updateVisibleStudents()
	if not systemActive or not localPlayer.Character then return end

	local localPos = getModelPosition(localPlayer.Character)
	if not localPos then return end

	local distances = {}
	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student ~= localPlayer.Character and student:IsA("Model") then
			local targetPos = getModelPosition(student)
			if targetPos then
				local dist = (localPos - targetPos).Magnitude
				if dist <= MAX_DISTANCE then
					table.insert(distances, {student, dist})
				end
			end
		end
	end

	table.sort(distances, function(a, b)
		return a[2] < b[2]
	end)

	local newVisible = {}
	for i = 1, math.min(MAX_VISIBLE, #distances) do
		newVisible[distances[i][1]] = true
	end

	-- Desactivar los que ya no están visibles
	for student in pairs(visibleStudents) do
		if not newVisible[student] then
			updateHighlightState(student, false)
		end
	end

	-- Activar los nuevos visibles
	for student in pairs(newVisible) do
		if not visibleStudents[student] then
			updateHighlightState(student, true)
		end
	end

	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🧩 Verificar si el jugador puede usar el sistema
------------------------------------------------------------
local function isInValidFolder()
	local char = localPlayer.Character
	if not char or not char.Parent then return false end
	for _, folderName in ipairs(VALID_FOLDERS) do
		if char.Parent.Name == folderName then
			return true
		end
	end
	return false
end

local function updateSystemStatus(force)
	local shouldBeActive = isInValidFolder()
	if shouldBeActive == systemActive and not force then return end
	systemActive = shouldBeActive

	if systemActive then
		updateVisibleStudents()
	else
		for student in pairs(visibleStudents) do
			updateHighlightState(student, false)
		end
		visibleStudents = {}
	end
end

------------------------------------------------------------
-- 🧩 Monitor de Students
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child ~= localPlayer.Character then
		getOrCreateHighlight(child)
		if systemActive then
			task.defer(updateVisibleStudents)
		end
	end
end)

task.defer(function()
	local hl = getOrCreateHighlight(child)
	if systemActive then
		updateVisibleStudents()
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	local hl = activeHighlights[child]
	if hl then
	hl.Enabled = false
    hl.Adornee = nil		
	end
	activeHighlights[child] = nil
	visibleStudents[child] = nil
end)

------------------------------------------------------------
-- 🧩 Control del personaje local
------------------------------------------------------------
local function onCharacterAdded(character)
	updateSystemStatus(true)

	-- Escucha el cambio de posición (en vez de usar Heartbeat)
	task.defer(function()
		local root = character:WaitForChild("HumanoidRootPart", 3)
		if not root then return end

		local lastPos = root.Position
		root:GetPropertyChangedSignal("Position"):Connect(function()
			if not systemActive then return end
			local newPos = root.Position
			if (newPos - lastPos).Magnitude > UPDATE_THRESHOLD then
				lastPos = newPos
				updateVisibleStudents()
			end
		end)
	end)

	character:GetPropertyChangedSignal("Parent"):Connect(updateSystemStatus)
end

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

localPlayer.CharacterRemoving:Connect(function()
	systemActive = false
	for _, hl in pairs(activeHighlights) do
		if hl then hl.Enabled = false end
	end
end)


------------------------------------------------------------
-- ♻️ Limpieza automática por evento
------------------------------------------------------------
Workspace.DescendantRemoving:Connect(function(obj)
	if activeHighlights[obj] then
		local hl = activeHighlights[obj]
		if hl then
			hl.Enabled = false
			hl.Adornee = nil
			hl:Destroy()
		end
		activeHighlights[obj] = nil
		visibleStudents[obj] = nil
	end
end)
