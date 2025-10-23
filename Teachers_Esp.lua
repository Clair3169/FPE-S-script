--// 🧠 Local Script Ultra Optimizado (Highlights en lugar de BillboardGui)
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

--// Crear un Highlight
local function createHighlight(model, folderName)
	if not model or ActiveHighlights[model] then return end
	local highlight = Instance.new("Highlight")
	highlight.Name = "ModelHighlighter"
	highlight.Adornee = model
	highlight.Enabled = false
	highlight.OutlineColor = COLORS[folderName] or Color3.fromRGB(255, 255, 255)
	highlight.FillTransparency = 1 -- sin relleno
	highlight.OutlineTransparency = 0
	highlight.Parent = model
	ActiveHighlights[model] = { Highlight = highlight, Folder = folderName }
end

--// Eliminar Highlight
local function removeHighlight(model)
	local data = ActiveHighlights[model]
	if data then
		if data.Highlight and data.Highlight.Parent then
			data.Highlight:Destroy()
		end
		ActiveHighlights[model] = nil
	end
end

--// Escanear una carpeta
local function scanFolder(folder, skipLocal, onlyTeachersToShow)
	for _, model in ipairs(folder:GetChildren()) do
		if not model:IsA("Model") then
			removeHighlight(model)
			continue
		end

		if skipLocal and model.Name == LocalPlayer.Name then
			continue
		end

		local head = getRealHead(model)
		if not head then
			removeHighlight(model)
			continue
		end

		local teacherName = model:GetAttribute("TeacherName")
		if onlyTeachersToShow and teacherName and not onlyTeachersToShow[teacherName] then
			removeHighlight(model)
			continue
		end

		if not ActiveHighlights[model] then
			createHighlight(model, folder.Name)
		end
	end
end

--// Limpiar carpeta completa
local function clearHighlightsFromFolder(folder)
	for _, model in ipairs(folder:GetChildren()) do
		removeHighlight(model)
	end
end

--// Control visual por distancia (Frame optimizado)
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	if not myHead then return end

	local ok, myPos = pcall(function() return myHead.Position end)
	if not ok then return end

	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		if not hl or not model.Parent then
			removeHighlight(model)
			continue
		end

		local targetHead = getRealHead(model)
		if not targetHead then
			removeHighlight(model)
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

--// Reaccionar a cambios de contenido
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(child)
		if child:IsA("Model") then
			task.defer(function()
				local folderName = folder.Name
				createHighlight(child, folderName)
			end)
		end
		if not autoCheckActive then
			startAutoCheck()
		end
	end)

	folder.ChildRemoved:Connect(function(child)
		removeHighlight(child)
		local total = 0
		for _, f in pairs(Folders) do
			total += #f:GetChildren()
		end
		if total == 0 then
			autoCheckActive = false
		end
	end)
end

--// Detección inicial del modelo del jugador
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
