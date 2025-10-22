-- 🟢 Imagen flotante (Optimizado + pausa inteligente + límite de 27)
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

-- 🖼️ Configuración
local IMAGE_ID = "rbxassetid://126500139798475"
local MAX_VISIBLE = 7               -- Número normal de visibles dinámicos
local MAX_BILLBOARDS = 27           -- Límite absoluto de Billboards creados
local MAX_STUD_DISTANCE = 200       -- Distancia máxima de detección

-- ⚙️ Estado
local systemActive = false
local activeBillboards = {}
local visibleStudents = {}
local currentCamera = Workspace.CurrentCamera

-- 🕹️ Control de actividad automática
local autoCheckActive = false
local totalStudents = 0

------------------------------------------------------------
-- 🎥 RenderStepped (escala dinámica, ultra liviano)
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not systemActive or not next(activeBillboards) then return end
	currentCamera = Workspace.CurrentCamera or currentCamera
	local camPos = currentCamera.CFrame.Position

	for billboard, head in pairs(activeBillboards) do
		if not billboard.Parent or not head.Parent then
			activeBillboards[billboard] = nil
			continue
		end
		local distance = (camPos - head.Position).Magnitude
		local scale = math.clamp(distance / 30, 0.6, 3.5)
		billboard.Size = UDim2.new(scale * 3, 0, scale * 3, 0)
	end
end)

------------------------------------------------------------
-- 🧩 Crear / Destruir Billboard
------------------------------------------------------------
local function createFloatingImage(character)
	if not character or not character:IsA("Model") then return end
	local head = character:FindFirstChild("Head")
	if not head or head:FindFirstChild("FloatingImageBillboard") then return end

	-- No crear más de MAX_BILLBOARDS en total
	local count = 0
	for _ in pairs(activeBillboards) do
		count += 1
	end
	if count >= MAX_BILLBOARDS then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingImageBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(3, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	billboard.Parent = head

	local image = Instance.new("ImageLabel")
	image.Name = "FloatingImage"
	image.Size = UDim2.new(1, 0, 1, 0)
	image.BackgroundTransparency = 1
	image.Image = IMAGE_ID
	image.Parent = billboard

	activeBillboards[billboard] = head
end

local function destroyFloatingImage(character)
	if not character or not character:IsA("Model") then return end
	local head = character:FindFirstChild("Head")
	if not head then return end
	local billboard = head:FindFirstChild("FloatingImageBillboard")
	if billboard then
		activeBillboards[billboard] = nil
		billboard:Destroy()
	end
end

------------------------------------------------------------
-- 🧩 Visibilidad de los más cercanos
------------------------------------------------------------
local function updateVisibleStudents()
	if not systemActive or not localPlayer.Character then return end
	if totalStudents == 0 then return end

	local localHead = localPlayer.Character:FindFirstChild("Head")
	if not localHead then return end
	
	local localPos = localHead.Position
	local distances = {}

	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student ~= localPlayer.Character and student:IsA("Model") then
			local head = student:FindFirstChild("Head")
			if head then
				local dist = (localPos - head.Position).Magnitude
				if dist < MAX_STUD_DISTANCE then
					table.insert(distances, {student, dist})
				end
			end
		end
	end

	table.sort(distances, function(a, b)
		return a[2] < b[2]
	end)

	local newVisible = {}
	local totalCreated = 0

	for i = 1, math.min(MAX_VISIBLE, #distances) do
		if totalCreated >= MAX_BILLBOARDS then break end
		newVisible[distances[i][1]] = true
		totalCreated += 1
	end

	-- Quitar los que ya no son visibles
	for student in pairs(visibleStudents) do
		if not newVisible[student] then
			destroyFloatingImage(student)
		end
	end
	
	-- Agregar nuevos visibles
	for student in pairs(newVisible) do
		if not visibleStudents[student] then
			createFloatingImage(student)
		end
	end

	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🧩 Estado del sistema
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
			destroyFloatingImage(student)
		end
		visibleStudents = {}
	end
end

------------------------------------------------------------
-- 🧠 Monitor de Students (pausa inteligente)
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	totalStudents += 1
	if not autoCheckActive then
		autoCheckActive = true
	end
	if systemActive and child ~= localPlayer.Character then
		task.defer(updateVisibleStudents)
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	totalStudents = math.max(0, totalStudents - 1)
	if visibleStudents[child] then
		visibleStudents[child] = nil
	end
	if totalStudents == 0 then
		autoCheckActive = false
		for student in pairs(visibleStudents) do
			destroyFloatingImage(student)
		end
		visibleStudents = {}
	end
end)

------------------------------------------------------------
-- 🧩 Control de tu personaje
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
-- ♻️ OPTIMIZACIÓN: Actualización inteligente
------------------------------------------------------------
task.spawn(function()
	local lastPlayerPosition = Vector3.zero
	while RunService.Heartbeat:Wait() do
		if not systemActive or not autoCheckActive then continue end
		if not localPlayer.Character then continue end
		local head = localPlayer.Character:FindFirstChild("Head")
		if not head then continue end
		local currentPos = head.Position
		if (currentPos - lastPlayerPosition).Magnitude > 5 then
			lastPlayerPosition = currentPos
			updateVisibleStudents()
		end
	end
end)
