-- 🧠 Local Script optimizado solo con eventos (sin Heartbeat)
repeat task.wait() until game:IsLoaded()

--// Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

--// Variables principales
local LocalPlayer = Players.LocalPlayer

local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

--// Configuración
local MAX_RENDER_DISTANCE = 250

--// Colores
local COLORS = {
	Teachers = Color3.fromRGB(255, 0, 0),
	Alices = Color3.fromRGB(150, 0, 0),
}

--// Cache
local HighlightCache = Workspace:FindFirstChild("HighlightCache_Main") or Instance.new("Folder")
HighlightCache.Name = "HighlightCache_Main"
HighlightCache.Parent = Workspace

local ActiveHighlights = {}
local HeadCache = {}

------------------------------------------------------------
-- 🧩 Obtener cabeza real
------------------------------------------------------------
local function getRealHead(model)
	if not model or not model:IsA("Model") then return nil end
	if HeadCache[model] then return HeadCache[model] end

	local teacherName = model:GetAttribute("TeacherName")
	local head = model:FindFirstChild("Head")
	if not head then return nil end

	if teacherName == "AlicePhase2" and head:IsA("Model") then
		local inner = head:FindFirstChild("Head")
		if inner and inner:IsA("BasePart") then
			HeadCache[model] = inner
			return inner
		end
	end

	if head:IsA("BasePart") then
		HeadCache[model] = head
		return head
	end
	return nil
end

------------------------------------------------------------
-- 🧩 Detectar carpeta local
------------------------------------------------------------
local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

------------------------------------------------------------
-- 🧩 Crear o usar Highlight
------------------------------------------------------------
local function getOrCreateHighlight(model, folderName)
	if ActiveHighlights[model] then
		return ActiveHighlights[model].Highlight
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = model.Name .. "_HL_" .. folderName
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
-- 🧩 Desactivar y limpiar highlight
------------------------------------------------------------
local function disableHighlight(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		data.Highlight.Enabled = false
		data.Highlight.Adornee = nil
	end
end

------------------------------------------------------------
-- 🧩 Control de distancia
------------------------------------------------------------
local function updateHighlightDistance()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	if not myHead then return end
	local myPos = myHead.Position

	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		local targetHead = getRealHead(model)
		if not hl or not targetHead then
			disableHighlight(model)
			continue
		end

		local dist = (targetHead.Position - myPos).Magnitude
		hl.Enabled = dist <= MAX_RENDER_DISTANCE
	end
end

------------------------------------------------------------
-- 🧩 Escanear carpetas según rol (dividido en frames)
------------------------------------------------------------
local function scanFolder(folder, localFolderName)
	local models = folder:GetChildren()
	for _, model in ipairs(models) do
		task.wait() -- 🔥 reduce pico de FPS
		if not model:IsA("Model") or model.Name == LocalPlayer.Name then
			disableHighlight(model)
			continue
		end

		local head = getRealHead(model)
		if not head then
			disableHighlight(model)
			continue
		end

		local allowHighlight = false
		if localFolderName == "Teachers" and folder.Name == "Alices" then
			allowHighlight = true
		elseif localFolderName == "Alices" and folder.Name == "Teachers" then
			allowHighlight = true
		elseif localFolderName == "Students" and (folder.Name == "Alices" or folder.Name == "Teachers") then
			allowHighlight = true
		end

		if not allowHighlight then
			disableHighlight(model)
			continue
		end

		local hl = getOrCreateHighlight(model, folder.Name)
		if hl then
			hl.Adornee = model
		end
	end
	updateHighlightDistance()
end

------------------------------------------------------------
-- 🧩 Escaneo principal
------------------------------------------------------------
local function performScan()
	local myFolder = detectPlayerFolder()
	if not myFolder then return end
	local myFolderName = myFolder.Name

	for folderName, folder in pairs(Folders) do
		task.defer(function()
			scanFolder(folder, myFolderName)
		end)
	end
end

------------------------------------------------------------
-- 🧩 Eventos principales
------------------------------------------------------------

LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	performScan()
end)

-- Actualizar al moverse el jugador
local function connectHeadPosition()
	local char = LocalPlayer.Character
	if not char then return end
	local head = getRealHead(char)
	if not head then return end

	head:GetPropertyChangedSignal("Position"):Connect(updateHighlightDistance)
end

LocalPlayer.CharacterRemoving:Connect(function()
	for _, data in pairs(ActiveHighlights) do
		if data.Highlight then
			data.Highlight.Enabled = false
		end
	end
end)

connectHeadPosition()

-- Reaccionar a cambios en carpetas
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(child)
		task.defer(performScan)
	end)
	folder.ChildRemoved:Connect(function(child)
		disableHighlight(child)
	end)
end

performScan()
