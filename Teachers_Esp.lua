-- 🧿 Teachers ESP optimizado (creación escalonada, slots dinámicos, sin cola)
repeat task.wait() until game:IsLoaded()

------------------------------------------------------------
-- ⚙️ Servicios
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
-- ⚙️ Configuración
------------------------------------------------------------
local MAX_RENDER_DISTANCE = 250
local UPDATE_THRESHOLD = 5
local COLOR_UPDATE_INTERVAL = 0.25

local SLOTS_A = 1
local SLOTS_T = 3
local TOTAL_SLOTS = SLOTS_A + SLOTS_T

local CREATION_INTERVAL = 1

local DISTANCES = {
	Close = 30,
	Medium = 55,
}

local COLORS = {
	Alices_Close = Color3.fromRGB(150, 0, 0),
	Teachers_Close = Color3.fromRGB(255, 0, 0),
	Medium = Color3.fromRGB(255, 165, 0),
	Far = Color3.fromRGB(0, 255, 0),
}

------------------------------------------------------------
-- 🧠 Caches
------------------------------------------------------------
local HighlightCache = Workspace:FindFirstChild("HighlightTeachers_Main") or Instance.new("Folder")
HighlightCache.Name = "HighlightTeachers_Main"
HighlightCache.Parent = Workspace

local ActiveHighlights = {}
local HeadCache = {}
local freePool = {}
local createdCount = 0

------------------------------------------------------------
-- 🔎 Utilidades
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

local function getAnyPart(model)
	if not model or not model:IsDescendantOf(Workspace) then return nil end
	local ok, desc = pcall(model.GetDescendants, model)
	if not ok then return nil end
	for _, v in ipairs(desc) do
		if v:IsA("BasePart") then
			return v
		end
	end
	return nil
end

local function detectPlayerFolder()
	for _, name in ipairs({"Alices", "Students", "Teachers"}) do
		local f = Folders[name]
		if f and f:FindFirstChild(LocalPlayer.Name) then
			return f
		end
	end
	return nil
end

local function canSeeTarget(my, target)
	if my == "Teachers" then
		return target == "Alices"
	elseif my == "Alices" then
		return target == "Teachers"
	elseif my == "Students" then
		return target == "Alices" or target == "Teachers"
	end
	return false
end

local function modelIsReady(model)
	if not model or not model:IsA("Model") then return false end
	for _, p in ipairs(model:GetChildren()) do
		if p:IsA("BasePart") then return true end
	end
	return false
end

------------------------------------------------------------
-- 💡 Helper de Color
------------------------------------------------------------
local function getColorFromDistance(folder, distance)
	if distance <= DISTANCES.Close then
		return (folder == "Alices") and COLORS.Alices_Close or COLORS.Teachers_Close
	elseif distance <= DISTANCES.Medium then
		return COLORS.Medium
	else
		return COLORS.Far
	end
end

------------------------------------------------------------
-- 💡 Highlight Helpers
------------------------------------------------------------
local function createHighlightInstance(index, folderName)
	local hl = Instance.new("Highlight")
	hl.Name = "HL_" .. tostring(index)
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Enabled = false
	hl.OutlineColor = COLORS.Far 
	hl.Parent = HighlightCache
	return hl
end

local function releaseHighlight(hl)
	if not hl then return end
	hl.Enabled = false
	hl.Adornee = nil
	table.insert(freePool, hl)
end

local function destroyHighlightForModel(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		releaseHighlight(data.Highlight)
	end
	ActiveHighlights[model] = nil
	HeadCache[model] = nil
end

local function assignHighlight(hl, model, folder, distance)
	if not hl or not model then return end
	hl.Adornee = model
	hl.OutlineColor = getColorFromDistance(folder, distance)
	hl.Enabled = true
	ActiveHighlights[model] = {
		Highlight = hl,
		Folder = folder,
		Distance = distance,
		InRange = (distance <= MAX_RENDER_DISTANCE)
	}
end

------------------------------------------------------------
-- 📏 Distancias
------------------------------------------------------------
local function updateActiveColors()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar) or getAnyPart(myChar)
	if not myHead then return end
	local myPos = myHead.Position

	for model, data in pairs(ActiveHighlights) do
		if not model:IsDescendantOf(Workspace) then
			data.Highlight.Enabled = false
		else
			local part = getRealHead(model) or getAnyPart(model)
			if not part then
				data.Distance = math.huge
				data.InRange = false
				data.Highlight.Enabled = false
			else
				local d = (part.Position - myPos).Magnitude
				data.Distance = d
				
				if d > MAX_RENDER_DISTANCE then
					data.InRange = false
					data.Highlight.Enabled = false
				else
					data.InRange = true
					local newColor = getColorFromDistance(data.Folder, d)
					if data.Highlight.OutlineColor ~= newColor then
						data.Highlight.OutlineColor = newColor
					end
					
					if not data.Highlight.Enabled then
						data.Highlight.Enabled = true
					end
				end
			end
		end
	end
end

------------------------------------------------------------
-- 🎯 Selección de candidatos (Corregida)
------------------------------------------------------------
local function buildDesired()
	local plFolder = detectPlayerFolder()
	if not plFolder then return {} end
	local my = plFolder.Name

	local A = {}
	local T = {}

	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar) or getAnyPart(myChar)
	if not myHead then return {} end
	local myPos = myHead.Position

	for groupName, folder in pairs(Folders) do
		
		-- Esta es la ÚNICA comprobación de equipo necesaria.
		-- Si my = "Teachers", esta línea SOLO será true si groupName = "Alices".
		-- NUNCA escaneará la carpeta "Teachers".
		if canSeeTarget(my, groupName) then
			
			for _, model in ipairs(folder:GetChildren()) do
				
				-- Como canSeeTarget ya filtró, sabemos que CUALQUIER
				-- modelo aquí es un enemigo.
				--
				-- Ya NO necesitamos "model.Parent ~= plFolder"
				-- Ya NO necesitamos "model.Name ~= LocalPlayer.Name"
				--
				-- Es imposible que se cree un Highlight para tu equipo
				-- porque este bucle NUNCA correrá en tu propia carpeta.
				
				if model:IsA("Model") then
					
					local part = getRealHead(model) or getAnyPart(model)
					if part then
						local dist = (part.Position - myPos).Magnitude
						if dist <= MAX_RENDER_DISTANCE then
							if groupName == "Alices" then
								table.insert(A, {model=model, distance=dist})
							else
								table.insert(T, {model=model, distance=dist})
							end
						end
					end
				end
			end
		end
	end

	table.sort(A, function(a,b) return a.distance < b.distance end)
	table.sort(T, function(a,b) return a.distance < b.distance end)

	local desired = {}
	for i = 1, math.min(#A, SLOTS_A) do
		desired[A[i].model] = {folder="Alices", distance=A[i].distance}
	end
	for i = 1, math.min(#T, SLOTS_T) do
		desired[T[i].model] = {folder="Teachers", distance=T[i].distance}
	end
	
	return desired
end

------------------------------------------------------------
-- 🔁 performScan
------------------------------------------------------------
local function performScan()
	local desired = buildDesired()

	for model, _ in pairs(ActiveHighlights) do
		if not desired[model] then
			destroyHighlightForModel(model)
		end
	end

	local need = {}
	for model, info in pairs(desired) do
		if not ActiveHighlights[model] then
			table.insert(need, {model=model, folder=info.folder, distance=info.distance})
		end
	end
	
	if #need == 0 then return end

	table.sort(need, function(a,b) return a.distance < b.distance end)

	for _, entry in ipairs(need) do
		if #freePool > 0 then
			local hl = table.remove(freePool)
			assignHighlight(hl, entry.model, entry.folder, entry.distance)
		else
			break
		end
	end
	
	updateActiveColors()
end

------------------------------------------------------------
-- 🏭 Creator (1 highlight por segundo)
------------------------------------------------------------
task.spawn(function()
	while true do
		if createdCount < TOTAL_SLOTS then
			local desired = buildDesired()
			local need = {}

			for m, info in pairs(desired) do
				if not ActiveHighlights[m] then
					table.insert(need, {model=m, folder=info.folder, distance=info.distance})
				end
			end

			table.sort(need, function(a,b) return a.distance < b.distance end)

			if #need > 0 then
				createdCount += 1
				local entry = need[1]
				local hl = createHighlightInstance(createdCount, entry.folder)
				assignHighlight(hl, entry.model, entry.folder, entry.distance)

				task.wait(CREATION_INTERVAL)
				continue
			end
		end
			
		task.wait(0.25)
	end
end)

------------------------------------------------------------
-- ⚡ Eventos
------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(0.5)
	for _, d in pairs(ActiveHighlights) do
		if d.Highlight then d.Highlight.Enabled = false end
	end

	performScan()

	local char = LocalPlayer.Character
	local head = getRealHead(char) or getAnyPart(char)
	if head then
		local lastPos = head.Position
		head:GetPropertyChangedSignal("Position"):Connect(function()
			local newPos = head.Position
			if (newPos - lastPos).Magnitude > UPDATE_THRESHOLD then
				lastPos = newPos
				performScan()
			end
		end)
	end
end)

for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function()
		task.defer(performScan)
	end)
	folder.ChildRemoved:Connect(function(model)
		if ActiveHighlights[model] then
			destroyHighlightForModel(model)
		end
	end)
end

Workspace.DescendantRemoving:Connect(function(obj)
	for model, _ in pairs(ActiveHighlights) do
		if model == obj or not model:IsDescendantOf(Workspace) then
			destroyHighlightForModel(model)
		end
	end
end)

task.spawn(function()
	while task.wait(5) do
		performScan()
	end
end)

task.spawn(function()
	while task.wait(COLOR_UPDATE_INTERVAL) do
		updateActiveColors()
	end
end)

task.defer(function()
	task.wait(1)
	performScan()
end)
