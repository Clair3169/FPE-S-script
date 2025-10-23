-- 🧠 Local Script Ultra Optimizado (Cache persistente + Highlights invisibles + Sin duplicados)
repeat task.wait() until game:IsLoaded()

--// Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// Variables principales
local LocalPlayer = Players.LocalPlayer
local PlayerModel = nil

local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

--// Configuración
local MAX_RENDER_DISTANCE = 300
local CHECK_INTERVAL = 5

--// Colores por carpeta
local COLORS = {
	Teachers = Color3.fromRGB(255, 0, 0), -- rojo brillante
	Alices = Color3.fromRGB(150, 0, 0),   -- rojo oscuro
	Students = Color3.fromRGB(0, 255, 0), -- verde (por consistencia)
}

local TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER = {
	Alice = true,
	AlicePhase2 = true,
}

-- 🗂️ Carpeta cache persistente para todos los highlights
local HighlightCache = Workspace:FindFirstChild("HighlightCache_Main") or Instance.new("Folder")
HighlightCache.Name = "HighlightCache_Main"
HighlightCache.Parent = Workspace

--// Obtener cabeza real
local function getRealHead(model)
	if not model or not model:IsA("Model") then return nil end
	local teacherName = model:GetAttribute("TeacherName")
	local head = model:FindFirstChild("Head")
	if not head then return nil end

	if teacherName == "AlicePhase2" and head:IsA("Model") then
		local inner = head:FindFirstChild("Head")
		if inner and inner:IsA("BasePart") then
			return inner
		end
	end

	if head:IsA("BasePart") then
		return head
	end
	return nil
end

--// Detectar carpeta del jugador local
local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

--// Cache de highlights activos
local ActiveHighlights = {}

------------------------------------------------------------
-- 🧩 Obtener o crear Highlight en cache
------------------------------------------------------------
local function getOrCreateHighlight(model, folderName)
	if not model or not model:IsA("Model") then return end

	if ActiveHighlights[model] then
		return ActiveHighlights[model].Highlight
	end

	local cacheName = model.Name .. "_HL_" .. folderName
	local cached = HighlightCache:FindFirstChild(cacheName)

	if cached and cached:IsA("Highlight") then
		cached.Adornee = model
		cached.Enabled = false
		ActiveHighlights[model] = { Highlight = cached, Folder = folderName }
		return cached
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = cacheName
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
-- 🧩 Pre-generar todos los highlights al inicio
------------------------------------------------------------
task.defer(function()
	for folderName, folder in pairs(Folders) do
		for _, model in ipairs(folder:GetChildren()) do
			if model:IsA("Model") then
				getOrCreateHighlight(model, folderName)
			end
		end
	end
end)

------------------------------------------------------------
-- 🧩 Remover (desactivar) Highlight sin destruirlo
------------------------------------------------------------
local function disableHighlight(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		data.Highlight.Enabled = false
		data.Highlight.Adornee = nil
	end
	ActiveHighlights[model] = nil
end

------------------------------------------------------------
-- 🧩 Escanear una carpeta
------------------------------------------------------------
local function scanFolder(folder, skipLocal, onlyTeachersToShow)
	for _, model in ipairs(folder:GetChildren()) do
		if not model:IsA("Model") then
			disableHighlight(model)
			continue
		end

		if skipLocal and model.Name == LocalPlayer.Name then
			continue
		end

		local head = getRealHead(model)
		if not head then
			disableHighlight(model)
			continue
		end

		local teacherName = model:GetAttribute("TeacherName")
		if onlyTeachersToShow and teacherName and not onlyTeachersToShow[teacherName] then
			disableHighlight(model)
			continue
		end

		local hl = getOrCreateHighlight(model, folder.Name)
		if hl then
			hl.Adornee = model
		end
	end
end

------------------------------------------------------------
-- 🧩 Control visual por distancia (Frame optimizado)
------------------------------------------------------------
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	if not myHead then return end

	local ok, myPos = pcall(function() return myHead.Position end)
	if not ok then return end

	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		if not hl then continue end

		if not model or not model.Parent then
			disableHighlight(model)
			continue
		end

		local targetHead = getRealHead(model)
		if not targetHead then
			disableHighlight(model)
			continue
		end

		local success, dist = pcall(function()
			return (targetHead.Position - myPos).Magnitude
		end)

		if success then
			hl.Enabled = dist <= MAX_RENDER_DISTANCE
		else
			hl.Enabled = false
		end
	end
end)

------------------------------------------------------------
-- 🧩 Estado de escaneo
------------------------------------------------------------
local autoCheckActive = false
local lastScanTick = 0

local function performScan()
	local now = tick()
	if now - lastScanTick < CHECK_INTERVAL then return end
	lastScanTick = now

	local myFolder = detectPlayerFolder()
	local isPlayerInTeachersFolder = myFolder and myFolder.Name == "Teachers"

	-- Teachers
	local filter = isPlayerInTeachersFolder and TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER or nil
	scanFolder(Folders.Teachers, false, filter)

	-- Alices
	local skipLocalInAlices = myFolder and myFolder.Name == "Alices"
	scanFolder(Folders.Alices, skipLocalInAlices, nil)

	-- Students
	scanFolder(Folders.Students, false, nil)
end

------------------------------------------------------------
-- 🧩 Escaneo automático con throttling
------------------------------------------------------------
local function startAutoCheck()
	if autoCheckActive then return end
	autoCheckActive = true
	task.spawn(function()
		while autoCheckActive do
			performScan()
			task.wait(CHECK_INTERVAL)
		end
	end)
end

------------------------------------------------------------
-- 🧩 Monitoreo de contenido
------------------------------------------------------------
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			getOrCreateHighlight(child, folder.Name)
			task.defer(performScan)
		end
	end)

	folder.ChildRemoved:Connect(function(child)
		disableHighlight(child)
	end)
end

------------------------------------------------------------
-- 🧩 Detección inicial del modelo del jugador
------------------------------------------------------------
task.spawn(function()
	repeat
		for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
			local folder = Folders[folderName]
			if folder and folder:FindFirstChild(LocalPlayer.Name) then
				PlayerModel = folder[LocalPlayer.Name]
				break
			end
		end
		task.wait(0.5)
	until PlayerModel
	startAutoCheck()
end)
