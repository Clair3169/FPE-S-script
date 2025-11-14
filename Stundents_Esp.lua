-- 🟢 Student Highlighter Optimizado con POOLING (PoolSize = 26)
repeat task.wait() until game:IsLoaded()

------------------------------------------------------------
-- ⚙️ Servicios y referencias
------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local localPlayer = Players.LocalPlayer
local studentsFolder = Workspace:WaitForChild("Students")
local VALID_FOLDERS = { "Alices", "Teachers" }

------------------------------------------------------------
-- ⚙️ Configuración (mantener tus valores)
------------------------------------------------------------
local MAX_VISIBLE = 10
local MAX_DISTANCE = 200
local UPDATE_THRESHOLD = 5

-- POOL
local POOL_SIZE = 25 -- <-- pedido por ti

------------------------------------------------------------
-- 🧠 Estado
------------------------------------------------------------
local systemActive = false
local activeHighlights = {}  -- [model] = highlight (actualmente asignado)
local visibleStudents = {}   -- [model] = true (los que están marcados visibles)

------------------------------------------------------------
-- 🔧 Cache persistente (carpeta para almacenar highlights del pool)
------------------------------------------------------------
local highlightCache = Workspace:FindFirstChild("HighlightStudents_Main")
if not highlightCache then
	highlightCache = Instance.new("Folder")
	highlightCache.Name = "HighlightStudents_Main"
	highlightCache.Parent = Workspace
end

------------------------------------------------------------
-- 🔁 POOL DE HIGHLIGHTS (centralizado)
------------------------------------------------------------
local highlightPool = {}

local function createPoolHighlight(idx)
	local hl = Instance.new("Highlight")
	hl.Name = ("Pooled_HL_%d"):format(idx)
	hl.Enabled = false
	-- Mantener estilo similar a tu original
	hl.OutlineColor = Color3.fromRGB(0, 255, 0)
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Parent = highlightCache
	return hl
end

-- Prellenar el pool
for i = 1, POOL_SIZE do
	table.insert(highlightPool, createPoolHighlight(i))
end

local function getHighlightFromPool()
	-- Reutiliza si hay disponibles, sino crear uno nuevo y añadir al cache
	if #highlightPool > 0 then
		local hl = table.remove(highlightPool)
		-- Asegurarse de que esté limpio
		hl.Enabled = false
		hl.Adornee = nil
		return hl
	end

	-- si se agotó el pool, crear uno extra (crecimiento dinámico)
	local hl = createPoolHighlight(POOL_SIZE + 1)
	POOL_SIZE = POOL_SIZE + 1
	return hl
end

local function releaseHighlightToPool(hl)
	if not hl then return end
	hl.Enabled = false
	hl.Adornee = nil
	-- devolver al pool
	table.insert(highlightPool, hl)
end

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

------------------------------------------------------------
-- 🔧 Funciones para asignar / liberar highlights (usando pool)
------------------------------------------------------------
local function assignHighlightToModel(model)
	if not model or not model:IsA("Model") or not systemActive then return end
	-- si ya tiene highlight asignado, devolverlo
	if activeHighlights[model] then
		return activeHighlights[model]
	end

	local hl = getHighlightFromPool()
	hl.Adornee = model
	hl.Enabled = false -- se activará según visibilidad
	activeHighlights[model] = hl
	return hl
end

local function removeHighlightFromModel(model)
	local hl = activeHighlights[model]
	if not hl then return end
	activeHighlights[model] = nil
	visibleStudents[model] = nil
	-- en vez de destruir, devolvemos al pool
	releaseHighlightToPool(hl)
end

local function updateHighlightState(model, state)
	if not model then return end
	local hl = activeHighlights[model]
	if not hl and state then
		hl = assignHighlightToModel(model)
	end
	if hl then
		hl.Enabled = state
		hl.Adornee = model
	end
end

------------------------------------------------------------
-- 🎯 Actualizar visibles (top-N por distancia)
-- acepta 'force' para forzar activación inmediata
------------------------------------------------------------
local function updateVisibleStudents(force)
	if not systemActive or not localPlayer.Character then return end

	local localPos = getModelPosition(localPlayer.Character)
	if not localPos then return end

	-- Recolectar distancias de candidatos
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

	-- ordenar por distancia ascendente
	table.sort(distances, function(a, b) return a[2] < b[2] end)

	-- construir nueva tabla de visibles (top MAX_VISIBLE)
	local newVisible = {}
	for i = 1, math.min(MAX_VISIBLE, #distances) do
		newVisible[distances[i][1]] = true
	end

	-- desactivar highlights que ya no están en newVisible
	for student in pairs(visibleStudents) do
		if not newVisible[student] then
			updateHighlightState(student, false)
		end
	end

	-- activar nuevos visibles (o forzar)
	for student in pairs(newVisible) do
		if force or not visibleStudents[student] then
			-- asigna highlight si hace falta y activa
			local hl = activeHighlights[student] or assignHighlightToModel(student)
			if hl then
				hl.Adornee = student
				hl.Enabled = true
			end
		end
	end

	-- asignar la nueva referencia
	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🔒 Estado del sistema (activación/desactivación según carpeta)
------------------------------------------------------------
local cleanupTimer = nil
local function scheduleHighlightCleanup()
	if cleanupTimer then return end
	cleanupTimer = task.delay(50, function()
		-- si se activó el sistema, cancelar limpieza
		if systemActive then
			cleanupTimer = nil
			return
		end

		-- devolver todos los highlights al pool
		for model, hl in pairs(activeHighlights) do
			if hl then
				releaseHighlightToPool(hl)
			end
		end
		activeHighlights = {}
		visibleStudents = {}

		-- (opcional) mantener los objetos en highlightCache para pool,
		-- no los destruimos porque estamos usando pool centralizado
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
		-- desactivar y devolver highlights al pool (sin destruir)
		for model, hl in pairs(activeHighlights) do
			if hl then
				hl.Enabled = false
				hl.Adornee = nil
				releaseHighlightToPool(hl)
			end
		end
		activeHighlights = {}
		visibleStudents = {}
		scheduleHighlightCleanup()
	end
end

------------------------------------------------------------
-- 🧍‍♂️ Eventos del folder Students
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	-- si el sistema no está activo, no hacemos nada
	if not systemActive then return end
	if child:IsA("Model") and child ~= localPlayer.Character then
		-- asigna (o reutiliza) un highlight para este modelo
		assignHighlightToModel(child)

		-- activación inmediata si ya está en rango (capa de seguridad)
		local localPos = getModelPosition(localPlayer.Character)
		local studentPos = getModelPosition(child)
		if localPos and studentPos then
			local dist = (localPos - studentPos).Magnitude
			if dist <= MAX_DISTANCE then
				updateHighlightState(child, true)
				visibleStudents[child] = true
			end
		end

		-- forzar evaluación general
		task.defer(function()
			updateVisibleStudents(true)
		end)
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	-- liberar highlight asociado
	removeHighlightFromModel(child)

	-- (opcional) Si había un cached highlight con nombre, lo dejamos en pool
	local cached = highlightCache:FindFirstChild(child.Name .. "_HL_Student")
	if cached and cached:IsA("Highlight") then
		-- si este highlight existe en cache pero no está en pool,
		-- devolverlo al pool para reutilización futura
		if not table.find(highlightPool, cached) then
			releaseHighlightToPool(cached)
		end
	end
end)

-- cuando un Player se va del juego
Players.PlayerRemoving:Connect(function(player)
	-- recorrer activeHighlights y liberar los que correspondan
	for model, hl in pairs(activeHighlights) do
		if model and model.Name == player.Name then
			if hl then
				releaseHighlightToPool(hl)
			end
			activeHighlights[model] = nil
			visibleStudents[model] = nil
		end
	end

	-- no destruimos highlights del pool; si existieran highlights nombrados en highlightCache,
	-- los dejamos para reutilizar (no eliminar)
end)

------------------------------------------------------------
-- 👤 Manejo de Character local
------------------------------------------------------------
local function onCharacterAdded(character)
	-- reset seguro (devolvemos todo al pool)
	for model, hl in pairs(activeHighlights) do
		if hl then
			hl.Enabled = false
			hl.Adornee = nil
			releaseHighlightToPool(hl)
		end
	end
	activeHighlights = {}
	visibleStudents = {}

	updateSystemStatus(true)

	-- forzar un pase inicial
	task.defer(function()
		updateVisibleStudents(true)
	end)

	-- conectamos movimiento para actualizar según umbral
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
	-- desactivar highlights visibles (devueltos al pool)
	for model, hl in pairs(activeHighlights) do
		if hl then
			hl.Enabled = false
			hl.Adornee = nil
			releaseHighlightToPool(hl)
		end
	end
	activeHighlights = {}
	visibleStudents = {}
end)

------------------------------------------------------------
-- ♻️ Limpieza global (cuando un descendant se está removiendo)
------------------------------------------------------------
Workspace.DescendantRemoving:Connect(function(obj)
	-- si un modelo se remueve, liberar su highlight si existe
	if activeHighlights[obj] then
		local hl = activeHighlights[obj]
		if hl then
			hl.Enabled = false
			hl.Adornee = nil
			releaseHighlightToPool(hl)
		end
		activeHighlights[obj] = nil
		visibleStudents[obj] = nil
	end
end)

------------------------------------------------------------
-- 🔁 Auto-verificador (elimina referencias huérfanas y reevalúa)
------------------------------------------------------------
task.spawn(function()
	while task.wait(5) do
		if not systemActive then continue end

		local missing = false
		-- detecta modelos en Students que no tienen highlight asignado (posible inconsistencia)
		for _, student in ipairs(studentsFolder:GetChildren()) do
			if student:IsA("Model") and student ~= localPlayer.Character then
				if not activeHighlights[student] then
					missing = true
					break
				end
			end
		end

		-- limpiar huérfanos en activeHighlights
		for model, hl in pairs(activeHighlights) do
			if not model or not model.Parent then
				if hl then
					releaseHighlightToPool(hl)
				end
				activeHighlights[model] = nil
				visibleStudents[model] = nil
			end
		end

		if missing then
			updateVisibleStudents(true)
		end
	end
end)

------------------------------------------------------------
-- 🔁 Heartbeat ligero para llamadas periódicas (puede ayudar en algunos escenarios)
------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	if systemActive then
		-- actualizamos sin forzar para no spamear
		updateVisibleStudents()
	end
end)

-- Inicialización
task.defer(function()
	updateSystemStatus(true)
	updateVisibleStudents(true)
end)
