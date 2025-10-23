--// 🧠 Local Script Ultra Optimizado (Highlights con cache persistente)
--// Mantiene todas las mecánicas originales, mejorando el rendimiento

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
}

local TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER = {
	Alice = true,
	AlicePhase2 = true,
}

--// 🔧 Crear carpeta de cache global (persistente)
local HighlightCache = Workspace:FindFirstChild("HighlightCache") or Instance.new("Folder")
HighlightCache.Name = "HighlightCache"
HighlightCache.Parent = Workspace

--// Cache activa en memoria
local ActiveHighlights = {} -- [model] = {Highlight = h, Folder = "Teachers"}

--// Buscar o crear Highlight reutilizable
local function getOrCreateHighlight(model, folderName)
	if not model then return end

	-- Buscar si ya existe uno en cache
	local cached = HighlightCache:FindFirstChild(model.Name .. "_HL")
	if cached and cached:IsA("Highlight") then
		cached.Adornee = model
		cached.Enabled = false
		ActiveHighlights[model] = { Highlight = cached, Folder = folderName }
		return cached
	end

	-- Crear nuevo highlight si no hay uno en cache
	local highlight = Instance.new("Highlight")
	highlight.Name = model.Name .. "_HL"
	highlight.OutlineColor = COLORS[folderName] or Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 0
	highlight.Enabled = false
	highlight.Adornee = model
	highlight.Parent = HighlightCache

	ActiveHighlights[model] = { Highlight = highlight, Folder = folderName }
	return highlight
end

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

--// Eliminar (desactivar) Highlight
local function disableHighlight(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		data.Highlight.Adornee = nil
		data.Highlight.Enabled = false
		ActiveHighlights[model] = nil
	end
end

--// Escanear carpeta
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

		if not ActiveHighlights[model] then
			getOrCreateHighlight(model, folder.Name)
		else
			local hl = ActiveHighlights[model].Highlight
			if hl then hl.Adornee = model end
		end
	end
end

--// Limpiar carpeta completa
local function clearHighlightsFromFolder(folder)
	for _, model in ipairs(folder:GetChildren()) do
		disableHighlight(model)
	end
end

--// Control visual por distancia
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	if not myHead then return end

	local ok, myPos = pcall(function() return myHead.Position end)
	if not ok then return end

	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		if not hl then
			disableHighlight(model)
			continue
		end

		if not model.Parent then
			-- Modelo desapareció (por muerte o eliminación)
			hl.Enabled = false
			hl.Adornee = nil
			ActiveHighlights[model] = nil
			continue
		end

		local targetHead = getRealHead(model)
		if not targetHead then
			hl.Enabled = false
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

--// Estado de escaneo
local autoCheckActive = false
local lastScanTick = 0

local function performScan()
	local now = tick()
	if now - lastScanTick < CHECK_INTERVAL then return end
	lastScanTick = now

	local myFolder = detectPlayerFolder()
	local isPlayerInTeachersFolder = myFolder and myFolder.Name == "Teachers"

	-- Teachers
	local teacherCount = #Folders.Teachers:GetChildren()
	if teacherCount > 0 then
		local filter = isPlayerInTeachersFolder and TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER or nil
		scanFolder(Folders.Teachers, false, filter)
	else
		clearHighlightsFromFolder(Folders.Teachers)
	end

	-- Alices
	local aliceCount = #Folders.Alices:GetChildren()
	local skipLocalInAlices = myFolder and myFolder.Name == "Alices"
	if aliceCount > 0 then
		scanFolder(Folders.Alices, skipLocalInAlices, nil)
	else
		clearHighlightsFromFolder(Folders.Alices)
	end
end

--// Escaneo automático con throttling
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

--// Reaccionar a cambios en las carpetas
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(function()
				getOrCreateHighlight(child, folder.Name)
			end)
		end
		if not autoCheckActive then
			startAutoCheck()
		end
	end)

	folder.ChildRemoved:Connect(function(child)
		disableHighlight(child)
	end)
end

--// Detección inicial
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

--// 🔁 Reasignación al reaparecer
LocalPlayer.CharacterAdded:Connect(function(newChar)
	PlayerModel = nil
	task.defer(function()
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
		task.wait(1)
		performScan()
	end)
end)
