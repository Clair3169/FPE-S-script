-- 🟢 Student Highlighter, Teachers System (Cache persistente + Optimizado + Sin dependencias de cabeza)
repeat task.wait() until game:IsLoaded()

-- ⚙️ Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 👤 Jugador local
local localPlayer = Players.LocalPlayer

-- 📂 Carpetas principales
local studentsFolder = Workspace:WaitForChild("Students")
local VALID_FOLDERS = { "Alices", "Teachers" } -- Solo en estas se activará el sistema

-- ⚙️ Configuración
local MAX_VISIBLE = 10
local MAX_DISTANCE = 200
local UPDATE_THRESHOLD = 5
local systemActive = false

-- 🧠 Estado de caché
local activeHighlights = {} -- { [character] = Highlight }
local visibleStudents = {}
local currentCamera = Workspace.CurrentCamera

-- 🔧 Carpeta cache persistente
local highlightCache = Workspace:FindFirstChild("HighlightCache_Students") or Instance.new("Folder")
highlightCache.Name = "HighlightCache_Students"
highlightCache.Parent = Workspace

------------------------------------------------------------
-- 🧩 Fallback seguro para obtener posición del modelo
------------------------------------------------------------
local function getModelPosition(model)
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	-- fallback: tomar la primera parte válida
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			return part.Position
		end
	end
	return nil
end

------------------------------------------------------------
-- 🧩 Función: Crear o recuperar Highlight de cache
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
	highlight.FillTransparency = 0.85 -- un poco visible
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Adornee = character
	highlight.Parent = highlightCache

	activeHighlights[character] = highlight
	return highlight
end

------------------------------------------------------------
-- 🧩 Pre-generar cache de todos los Students al inicio
------------------------------------------------------------
task.defer(function()
	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student:IsA("Model") and student ~= localPlayer.Character then
			getOrCreateHighlight(student)
		end
	end
end)

------------------------------------------------------------
-- 🧩 Activar/Desactivar Highlight
------------------------------------------------------------
local function updateHighlightState(character, state)
	local highlight = getOrCreateHighlight(character)
	if not highlight then return end
	highlight.Enabled = state
	highlight.Adornee = character
end

------------------------------------------------------------
-- 🧩 Actualizar lista de visibles por distancia
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
-- 🧩 Estado del sistema (solo si está en Alices o Teachers)
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
-- 🧠 Monitor de Students
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child ~= localPlayer.Character then
		getOrCreateHighlight(child)
		if systemActive then
			task.defer(updateVisibleStudents)
		end
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	if activeHighlights[child] then
		local hl = activeHighlights[child]
		if hl then
			hl.Enabled = false
			hl.Adornee = nil
		end
		activeHighlights[child] = nil
	end
	visibleStudents[child] = nil
end)

------------------------------------------------------------
-- 🧩 Control del personaje local
------------------------------------------------------------
local function onCharacterAdded(character)
	updateSystemStatus(true)
	character:GetPropertyChangedSignal("Parent"):Connect(updateSystemStatus)
end

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

------------------------------------------------------------
-- ♻️ OPTIMIZACIÓN: actualización por movimiento
------------------------------------------------------------
task.spawn(function()
	local lastPos = Vector3.zero
	while RunService.Heartbeat:Wait() do
		if not systemActive or not localPlayer.Character then continue end
		local pos = getModelPosition(localPlayer.Character)
		if not pos then continue end

		if (pos - lastPos).Magnitude > UPDATE_THRESHOLD then
			lastPos = pos
			updateVisibleStudents()
		end
	end
end)

------------------------------------------------------------
-- ♻️ Limpieza lógica (sin eliminar cache)
------------------------------------------------------------
RunService.Stepped:Connect(function()
	for char, highlight in pairs(activeHighlights) do
		if not char or not char.Parent then
			if highlight then
				highlight.Enabled = false
				highlight.Adornee = nil
			end
			activeHighlights[char] = nil
		end
	end
end)
