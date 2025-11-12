-- 🧿 Student Highlighter (Reglas estrictas de creación - FIX AutoRespawn)
repeat task.wait() until game:IsLoaded()

------------------------------------------------------------
-- Servicios y variables
------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer

local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

------------------------------------------------------------
-- Configuración
------------------------------------------------------------
local MAX_RENDER_DISTANCE = 250
local UPDATE_THRESHOLD = 5
local MAX_VISIBLE_ALICES = 2
local MAX_VISIBLE_TEACHERS = 4

local COLORS = {
	Alices = Color3.fromRGB(150, 0, 0),
	Teachers = Color3.fromRGB(255, 0, 0),
}

------------------------------------------------------------
-- Caches
------------------------------------------------------------
local HighlightCache = Workspace:FindFirstChild("HighlightCache_Main") or Instance.new("Folder")
HighlightCache.Name = "HighlightCache_Main"
HighlightCache.Parent = Workspace

local ActiveHighlights = {}
local HeadCache = {}

------------------------------------------------------------
-- Utilidades
------------------------------------------------------------
local function getRealHead(model)
	if not model or not model:IsA("Model") then return nil end
	if HeadCache[model] then return HeadCache[model] end

	local head = model:FindFirstChild("Head")
	if not head then return nil end

	local teacherName = model:GetAttribute("TeacherName")
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

local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

local function canSeeTarget(localFolderName, targetFolderName)
	if localFolderName == "Teachers" then
		return targetFolderName == "Alices"
	elseif localFolderName == "Alices" then
		return targetFolderName == "Teachers"
	elseif localFolderName == "Students" then
		return targetFolderName == "Alices" or targetFolderName == "Teachers"
	end
	return false
end

------------------------------------------------------------
-- Highlight handling
------------------------------------------------------------
local function getOrCreateHighlight(model, folderName)
	if ActiveHighlights[model] and ActiveHighlights[model].Highlight then
		return ActiveHighlights[model].Highlight
	end

	local hl = Instance.new("Highlight")
	hl.Name = model.Name .. "_HL_" .. folderName
	hl.Adornee = model
	hl.OutlineColor = COLORS[folderName] or Color3.new(1,1,1)
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Enabled = false
	hl.Parent = HighlightCache

	ActiveHighlights[model] = { Highlight = hl, Folder = folderName, InRange = false, Distance = math.huge }
	return hl
end

local function disableHighlight(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		data.Highlight:Destroy()
	end
	ActiveHighlights[model] = nil
	HeadCache[model] = nil
end

------------------------------------------------------------
-- Actualización por distancia
------------------------------------------------------------
local function updateHighlightDistance()
	local char = LocalPlayer.Character
	local myHead = getRealHead(char)
	if not myHead then return end
	local myPos = myHead.Position

	local aliceDistances, teacherDistances = {}, {}

	for model, data in pairs(ActiveHighlights) do
		local targetHead = getRealHead(model)
		if not targetHead or not model:IsDescendantOf(Workspace) then
			disableHighlight(model)
			continue
		end

		local dist = (targetHead.Position - myPos).Magnitude
		data.Distance = dist

		if dist > MAX_RENDER_DISTANCE then
			if data.Highlight then data.Highlight.Enabled = false end
			data.InRange = false
		else
			data.InRange = true
			if data.Folder == "Alices" then
				table.insert(aliceDistances, {model, dist})
			elseif data.Folder == "Teachers" then
				table.insert(teacherDistances, {model, dist})
			end
		end
	end

	table.sort(aliceDistances, function(a,b) return a[2] < b[2] end)
	table.sort(teacherDistances, function(a,b) return a[2] < b[2] end)

	local visible = {}
	for i = 1, math.min(#aliceDistances, MAX_VISIBLE_ALICES) do
		visible[aliceDistances[i][1]] = true
	end
	for i = 1, math.min(#teacherDistances, MAX_VISIBLE_TEACHERS) do
		visible[teacherDistances[i][1]] = true
	end

	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		if hl then
			hl.Enabled = data.InRange and visible[model] or false
		end
	end
end

------------------------------------------------------------
-- Escaneo completo
------------------------------------------------------------
local function performScan()
	local myFolder = detectPlayerFolder()
	if not myFolder then return end
	local myFolderName = myFolder.Name

	for targetName, folder in pairs(Folders) do
		if canSeeTarget(myFolderName, targetName) then
			for _, model in ipairs(folder:GetChildren()) do
				if model:IsA("Model") and model.Name ~= LocalPlayer.Name then
					if model.Parent ~= Folders[myFolderName] then
						local head = getRealHead(model)
						if head then
							getOrCreateHighlight(model, targetName)
						end
					end
				end
			end
		end
	end
	updateHighlightDistance()
end

------------------------------------------------------------
-- Movimiento
------------------------------------------------------------
local lastPos = Vector3.new(0,0,0)
local function connectHeadMovement()
	local char = LocalPlayer.Character
	if not char then return end
	local head = getRealHead(char)
	if not head then return end
	lastPos = head.Position

	head:GetPropertyChangedSignal("Position"):Connect(function()
		local newPos = head.Position
		if (newPos - lastPos).Magnitude > UPDATE_THRESHOLD then
			lastPos = newPos
			updateHighlightDistance()
		end
	end)
end

------------------------------------------------------------
-- Eventos
------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	for _, data in pairs(ActiveHighlights) do
		if data.Highlight then data.Highlight.Enabled = false end
	end
	performScan()
	connectHeadMovement()
end)

LocalPlayer.CharacterRemoving:Connect(function()
	for _, data in pairs(ActiveHighlights) do
		if data.Highlight then data.Highlight.Enabled = false end
	end
end)

for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(model)
		task.defer(function()
			local myFolder = detectPlayerFolder()
			if not myFolder then return end
			local myFolderName = myFolder.Name
			if not canSeeTarget(myFolderName, folder.Name) then return end
			if model.Parent == Folders[myFolderName] then return end

			if model:IsA("Model") and model.Name ~= LocalPlayer.Name then
				local head = getRealHead(model)
				if head then
					getOrCreateHighlight(model, folder.Name)
					updateHighlightDistance()
				end
			end
		end)
	end)

	folder.ChildRemoved:Connect(function(model)
		disableHighlight(model)
	end)
end

Workspace.DescendantRemoving:Connect(function(obj)
	if ActiveHighlights[obj] then
		disableHighlight(obj)
	end
end)

------------------------------------------------------------
-- 🔁 Auto-verificador ligero (solución al problema reportado)
------------------------------------------------------------
task.spawn(function()
	while task.wait(5) do
		local missing = false
		local myFolder = detectPlayerFolder()
		if myFolder then
			local myFolderName = myFolder.Name
			for targetName, folder in pairs(Folders) do
				if canSeeTarget(myFolderName, targetName) then
					for _, model in ipairs(folder:GetChildren()) do
						if model:IsA("Model") and model.Name ~= LocalPlayer.Name then
							if not ActiveHighlights[model] then
								missing = true
								break
							end
						end
					end
				end
			end
		end
		if missing then
			performScan()
		end
	end
end)

------------------------------------------------------------
-- Inicio
------------------------------------------------------------
performScan()
connectHeadMovement()
