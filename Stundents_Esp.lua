-- 🟢 Student Highlighter Optimizado (con limpieza de jugadores desconectados)
repeat task.wait() until game:IsLoaded()

------------------------------------------------------------
-- ⚙️ Servicios
------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
local studentsFolder = Workspace:WaitForChild("Students")
local VALID_FOLDERS = { "Alices", "Teachers" }

------------------------------------------------------------
-- ⚙️ Configuración
------------------------------------------------------------
local MAX_VISIBLE = 10
local MAX_DISTANCE = 200
local UPDATE_THRESHOLD = 5

------------------------------------------------------------
-- 🧠 Estado
------------------------------------------------------------
local systemActive = false
local activeHighlights = {}
local visibleStudents = {}

------------------------------------------------------------
-- 🔧 Cache persistente
------------------------------------------------------------
local highlightCache = Workspace:FindFirstChild("HighlightStudents_Main") or Instance.new("Folder")
highlightCache.Name = "HighlightStudents_Main"
highlightCache.Parent = Workspace

------------------------------------------------------------
-- 🔍 Utilidades
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

local function getOrCreateHighlight(character)
	if not character or not character:IsA("Model") or not systemActive then return end

	if activeHighlights[character] then
		return activeHighlights[character]
	end

	local cacheName = character.Name .. "_HL_Student"
	local cached = highlightCache:FindFirstChild(cacheName)
	if cached and cached:IsA("Highlight") then
		-- reasignar adornee y reiniciar estado
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

local function updateHighlightState(character, state)
	local highlight = activeHighlights[character]
	if not highlight and state then
		highlight = getOrCreateHighlight(character)
	end
	if highlight then
		highlight.Enabled = state
		highlight.Adornee = character
	end
end

------------------------------------------------------------
-- 🎯 Actualizar visibles
-- ahora con parámetro force para forzar activación inmediata
------------------------------------------------------------
local function updateVisibleStudents(force)
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

	table.sort(distances, function(a, b) return a[2] < b[2] end)

	local newVisible = {}
	for i = 1, math.min(MAX_VISIBLE, #distances) do
		newVisible[distances[i][1]] = true
	end

	-- Desactivar los que ya no están en la nueva lista
	for student in pairs(visibleStudents) do
		if not newVisible[student] then
			updateHighlightState(student, false)
		end
	end

	-- Activar los nuevos (o forzar si se pidió)
	for student in pairs(newVisible) do
		if force or not visibleStudents[student] then
			updateHighlightState(student, true)
		end
	end

	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🔒 Estado del sistema
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

local cleanupTimer = nil
local function scheduleHighlightCleanup()
	if cleanupTimer then return end
	cleanupTimer = task.delay(50, function()
		-- si el sistema se activó mientras esperamos, cancelar cleanup
		if systemActive then cleanupTimer = nil return end

		for student, hl in pairs(activeHighlights) do
			if hl then hl:Destroy() end
		end
		activeHighlights = {}
		visibleStudents = {}

		for _, obj in ipairs(highlightCache:GetChildren()) do
			if obj:IsA("Highlight") then
				obj:Destroy()
			end
		end
		cleanupTimer = nil
	end)
end

local function updateSystemStatus(force)
	local shouldBeActive = isInValidFolder()
	if shouldBeActive == systemActive and not force then return end
	systemActive = shouldBeActive

	if systemActive then
		updateVisibleStudents(force)
	else
		for _, hl in pairs(activeHighlights) do
			if hl then
				hl.Enabled = false
				hl.Adornee = nil
			end
		end
		scheduleHighlightCleanup()
	end
end

------------------------------------------------------------
-- 🧍‍♂️ Eventos de Students
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	if not systemActive then return end
	if child:IsA("Model") and child ~= localPlayer.Character then
		-- crear o reutilizar highlight en cache
		local highlight = getOrCreateHighlight(child)

		-- 🔥 Capa de seguridad: activar si ya está en rango (inmediato)
		local localPos = getModelPosition(localPlayer.Character)
		local studentPos = getModelPosition(child)

		if localPos and studentPos then
			local dist = (localPos - studentPos).Magnitude
			if dist <= MAX_DISTANCE then
				highlight.Enabled = true
				visibleStudents[child] = true
			end
		end

		-- forzar una actualización completa después de añadir
		task.defer(function()
			updateVisibleStudents(true)
		end)
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

	-- 🔥 Limpieza directa del highlight en cache si existe
	local cached = highlightCache:FindFirstChild(child.Name .. "_HL_Student")
	if cached and cached:IsA("Highlight") then
		cached:Destroy()
	end
end)

-- 🧹 Limpieza segura cuando un jugador abandona el juego
Players.PlayerRemoving:Connect(function(player)
	for student, hl in pairs(activeHighlights) do
		if student.Name == player.Name then
			if hl then hl:Destroy() end
			activeHighlights[student] = nil
			visibleStudents[student] = nil
		end
	end

	-- 🔥 Eliminar cualquier highlight residual en cache
	for _, obj in ipairs(highlightCache:GetChildren()) do
		if obj:IsA("Highlight") and obj.Name:find(player.Name .. "_HL_Student") then
			obj:Destroy()
		end
	end
end)

------------------------------------------------------------
-- 👤 Personaje local
------------------------------------------------------------
local function onCharacterAdded(character)
	for _, hl in pairs(activeHighlights) do
		if hl then hl.Enabled = false hl.Adornee = nil end
	end
	activeHighlights = {}
	visibleStudents = {}

	updateSystemStatus(true)

	task.defer(function()
		updateVisibleStudents(true)
	end)

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

	character:GetPropertyChangedSignal("Parent"):Connect(function()
		updateSystemStatus()
	end)
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
-- ♻️ Limpieza global
------------------------------------------------------------
Workspace.DescendantRemoving:Connect(function(obj)
	if activeHighlights[obj] then
		local hl = activeHighlights[obj]
		if hl then
			hl.Enabled = false
			hl.Adornee = nil
		end
		activeHighlights[obj] = nil
		visibleStudents[obj] = nil
	end
end)

------------------------------------------------------------
-- 🔁 Auto-verificador (mejorado: elimina highlights huérfanos)
------------------------------------------------------------
task.spawn(function()
	while task.wait(5) do
		if not systemActive then continue end
		local missing = false
		for _, student in ipairs(studentsFolder:GetChildren()) do
			if student:IsA("Model") and student ~= localPlayer.Character then
				if not activeHighlights[student] then
					missing = true
					break
				end
			end
		end

		-- 🔥 Limpieza de highlights huérfanos (jugadores que ya no existen)
		for student, hl in pairs(activeHighlights) do
			if not student or not student.Parent then
				if hl then hl:Destroy() end
				activeHighlights[student] = nil
				visibleStudents[student] = nil
			end
		end

		if missing then
			updateVisibleStudents(true)
		end
	end
end)
