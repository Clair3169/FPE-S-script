-- 🧿 Student Billboard ESP (Optimizado con Cache y Limpieza)
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
local activeBillboards = {}
local visibleStudents = {}
local cleanupTimer = nil

------------------------------------------------------------
-- 📦 Cache persistente
------------------------------------------------------------
local billboardCache = Workspace:FindFirstChild("BillboardCache_Students") or Instance.new("Folder")
billboardCache.Name = "BillboardCache_Students"
billboardCache.Parent = Workspace

------------------------------------------------------------
-- 🔧 Utilidades
------------------------------------------------------------
local function getModelPosition(model)
	if not model or not model:IsA("Model") then return nil end
	if model.PrimaryPart then
		return model.PrimaryPart.Position
	end
	local head = model:FindFirstChild("Head") or model:FindFirstChildWhichIsA("BasePart")
	return head and head.Position
end

local function ensureAdornee(character, billboard)
	if not character or not billboard then return end
	local head = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
	if head and billboard.Adornee ~= head then
		billboard.Adornee = head
	end
end

local function getOrCreateBillboard(character)
	if not character or not character:IsA("Model") or not systemActive then return end

	if activeBillboards[character] then
		return activeBillboards[character]
	end

	local cacheName = character.Name .. "_BB_Student"
	local cached = billboardCache:FindFirstChild(cacheName)
	if cached and cached:IsA("BillboardGui") then
		ensureAdornee(character, cached)
		cached.Enabled = false
		activeBillboards[character] = cached
		return cached
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = cacheName
	billboard.Size = UDim2.new(0, 45, 0, 45)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.Enabled = false
	billboard.MaxDistance = MAX_DISTANCE
	billboard.Adornee = character:FindFirstChild("Head") or character:FindFirstChildWhichIsA("BasePart")
	billboard.Parent = billboardCache

	local image = Instance.new("ImageLabel")
	image.BackgroundTransparency = 1
	image.Size = UDim2.new(1, 0, 1, 0)
	image.Image = "rbxassetid://126500139798475" -- ID de la imagen del estudiante
	image.ScaleType = Enum.ScaleType.Fit
	image.Parent = billboard

	activeBillboards[character] = billboard
	return billboard
end

local function updateBillboardState(character, state)
	local billboard = activeBillboards[character]
	if not billboard and state then
		billboard = getOrCreateBillboard(character)
	end
	if billboard then
		ensureAdornee(character, billboard)
		billboard.Enabled = state
	end
end

------------------------------------------------------------
-- 🔍 Control de carpeta del jugador local
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

------------------------------------------------------------
-- 🎯 Actualizar visibles
------------------------------------------------------------
local function updateVisibleStudents()
	if not systemActive or not localPlayer.Character then return end
	local localPos = getModelPosition(localPlayer.Character)
	if not localPos then return end

	local distances = {}
	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student:IsA("Model") and student ~= localPlayer.Character then
			local pos = getModelPosition(student)
			if pos then
				local dist = (localPos - pos).Magnitude
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

	for student in pairs(visibleStudents) do
		if not newVisible[student] then
			updateBillboardState(student, false)
		end
	end

	for student in pairs(newVisible) do
		if not visibleStudents[student] then
			updateBillboardState(student, true)
		end
	end

	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🧹 Limpieza programada (cuando se desactiva el sistema)
------------------------------------------------------------
local function scheduleBillboardCleanup()
	if cleanupTimer then return end
	cleanupTimer = task.delay(50, function()
		if systemActive then cleanupTimer = nil return end

		for student, bb in pairs(activeBillboards) do
			if bb then bb:Destroy() end
		end
		activeBillboards = {}
		visibleStudents = {}

		for _, obj in ipairs(billboardCache:GetChildren()) do
			if obj:IsA("BillboardGui") then
				obj:Destroy()
			end
		end

		cleanupTimer = nil
	end)
end

------------------------------------------------------------
-- 🔒 Sistema principal
------------------------------------------------------------
local function updateSystemStatus(force)
	local shouldBeActive = isInValidFolder()
	if shouldBeActive == systemActive and not force then return end
	systemActive = shouldBeActive

	if systemActive then
		updateVisibleStudents()
	else
		for _, bb in pairs(activeBillboards) do
			if bb then
				bb.Enabled = false
				bb.Adornee = nil
			end
		end
		scheduleBillboardCleanup()
	end
end

------------------------------------------------------------
-- 🧍‍♂️ Eventos Students
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	if not systemActive then return end
	if child:IsA("Model") and child ~= localPlayer.Character then
		getOrCreateBillboard(child)
		task.defer(updateVisibleStudents)
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	local bb = activeBillboards[child]
	if bb then
		bb.Enabled = false
		bb.Adornee = nil
	end
	activeBillboards[child] = nil
	visibleStudents[child] = nil

	local cached = billboardCache:FindFirstChild(child.Name .. "_BB_Student")
	if cached and cached:IsA("BillboardGui") then
		cached:Destroy()
	end
end)

------------------------------------------------------------
-- 🧹 Limpieza si un jugador abandona
------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
	for student, bb in pairs(activeBillboards) do
		if student.Name == player.Name then
			if bb then bb:Destroy() end
			activeBillboards[student] = nil
			visibleStudents[student] = nil
		end
	end

	for _, obj in ipairs(billboardCache:GetChildren()) do
		if obj:IsA("BillboardGui") and obj.Name:find(player.Name .. "_BB_Student") then
			obj:Destroy()
		end
	end
end)

------------------------------------------------------------
-- 👤 Personaje local
------------------------------------------------------------
local function onCharacterAdded(character)
	for _, bb in pairs(activeBillboards) do
		if bb then bb.Enabled = false bb.Adornee = nil end
	end
	activeBillboards = {}
	visibleStudents = {}

	updateSystemStatus(true)

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
	for _, bb in pairs(activeBillboards) do
		if bb then bb.Enabled = false end
	end
end)

------------------------------------------------------------
-- ♻️ Limpieza global
------------------------------------------------------------
Workspace.DescendantRemoving:Connect(function(obj)
	if activeBillboards[obj] then
		local bb = activeBillboards[obj]
		if bb then
			bb.Enabled = false
			bb.Adornee = nil
		end
		activeBillboards[obj] = nil
		visibleStudents[obj] = nil
	end
end)

------------------------------------------------------------
-- 🔁 Auto-verificador (detecta billboards huérfanos)
------------------------------------------------------------
task.spawn(function()
	while task.wait(5) do
		if not systemActive then continue end
		local missing = false
		for _, student in ipairs(studentsFolder:GetChildren()) do
			if student:IsA("Model") and student ~= localPlayer.Character then
				if not activeBillboards[student] then
					missing = true
					break
				end
			end
		end

		-- 🔥 Limpieza de billboards huérfanos
		for student, bb in pairs(activeBillboards) do
			if not student or not student.Parent then
				if bb then bb:Destroy() end
				activeBillboards[student] = nil
				visibleStudents[student] = nil
			end
		end

		if missing then
			updateVisibleStudents()
		end
	end
end)

------------------------------------------------------------
-- 🚀 Inicialización
------------------------------------------------------------
for _, student in ipairs(studentsFolder:GetChildren()) do
	if student:IsA("Model") and student ~= localPlayer.Character then
		getOrCreateBillboard(student)
	end
end

task.defer(function()
	updateSystemStatus(true)
end)
