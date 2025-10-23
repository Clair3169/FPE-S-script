-- 🟢 Student Highlighter System (Optimizado + Prioridad de Highlight)
repeat task.wait() until game:IsLoaded()

-- ⚙️ Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 👤 Jugador local
local localPlayer = Players.LocalPlayer

-- 📂 Carpetas
local studentsFolder = Workspace:WaitForChild("Students")
local VALID_FOLDERS = { "Alices", "Teachers" }

-- ⚙️ Configuración
local MAX_VISIBLE = 10
local MAX_DISTANCE = 200
local UPDATE_THRESHOLD = 5
local systemActive = false

-- 🧠 Estado de caché
local activeHighlights = {} -- { [character] = Highlight }
local visibleStudents = {}
local currentCamera = Workspace.CurrentCamera

------------------------------------------------------------
-- 🧩 Función: Crear Highlight (una sola vez)
------------------------------------------------------------
local function createHighlight(character)
	if not character or not character:IsA("Model") then return end
	if activeHighlights[character] then return activeHighlights[character] end

	local highlight = Instance.new("Highlight")
	highlight.Name = "StudentHighlight"
	highlight.FillColor = Color3.fromRGB(0, 255, 0)
	highlight.FillTransparency = 0.2
	highlight.OutlineTransparency = 1
	highlight.Adornee = character
	highlight.Enabled = false
	highlight.Parent = character

	activeHighlights[character] = highlight
	return highlight
end

------------------------------------------------------------
-- 🧩 Función: Verificar prioridad de Highlight
------------------------------------------------------------
local function checkHighlightPriority(character)
	local highlight = activeHighlights[character]
	if not highlight then return end

	-- Si hay otro Highlight activo en el mismo modelo
	for _, child in ipairs(character:GetChildren()) do
		if child:IsA("Highlight") and child ~= highlight and child.Enabled then
			highlight.Enabled = false
			return
		end
	end

	-- Si no hay otro activo, mostrar el nuestro
	highlight.Enabled = true
end

------------------------------------------------------------
-- 🧩 Activar/Desactivar Highlight según visibilidad
------------------------------------------------------------
local function updateHighlightState(character, state)
	local highlight = createHighlight(character)
	if not highlight then return end
	highlight.Enabled = state
	if state then
		checkHighlightPriority(character)
	end
end

------------------------------------------------------------
-- 🧩 Visibilidad de los más cercanos
------------------------------------------------------------
local function updateVisibleStudents()
	if not systemActive or not localPlayer.Character then return end

	local localHead = localPlayer.Character:FindFirstChild("Head")
	if not localHead then return end
	local localPos = localHead.Position

	local distances = {}
	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student ~= localPlayer.Character and student:IsA("Model") then
			local head = student:FindFirstChild("Head")
			if head then
				local dist = (localPos - head.Position).Magnitude
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
		else
			checkHighlightPriority(student)
		end
	end

	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🧩 Estado del sistema (activar/desactivar según carpeta)
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
	if systemActive and child ~= localPlayer.Character then
		createHighlight(child)
		task.defer(updateVisibleStudents)
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	if activeHighlights[child] then
		activeHighlights[child]:Destroy()
		activeHighlights[child] = nil
	end
	if visibleStudents[child] then
		visibleStudents[child] = nil
	end
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
-- ♻️ OPTIMIZACIÓN: actualización inteligente por movimiento
------------------------------------------------------------
task.spawn(function()
	local lastPos = Vector3.zero
	while RunService.Heartbeat:Wait() do
		if not systemActive or not localPlayer.Character then continue end
		local head = localPlayer.Character:FindFirstChild("Head")
		if not head then continue end

		local pos = head.Position
		if (pos - lastPos).Magnitude > UPDATE_THRESHOLD then
			lastPos = pos
			updateVisibleStudents()
		end
	end
end)

------------------------------------------------------------
-- ♻️ Limpieza automática (garbage-safe)
------------------------------------------------------------
RunService.Stepped:Connect(function()
	for char, highlight in pairs(activeHighlights) do
		if not char.Parent then
			activeHighlights[char] = nil
			if highlight then highlight:Destroy() end
		end
	end
end)
