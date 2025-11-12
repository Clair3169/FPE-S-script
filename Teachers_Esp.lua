-- 🧿 Student Highlighter (FIX: Adornee + visibilidad por distancia corregida)
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

local ActiveHighlights = {} -- [model] = { Highlight = hl, Folder = string, InRange = bool, Distance = number }
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

local function getAnyPart(model)
	-- Fallback: devuelve cualquier BasePart dentro del modelo
	if not model or not model:IsA("Model") then return nil end
	for _, c in ipairs(model:GetDescendants()) do
		if c:IsA("BasePart") then
			return c
		end
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
-- Highlight handling (FIX de creación invisible y robust Adornee)
------------------------------------------------------------
local function modelIsReady(model)
	if not model or not model:IsA("Model") then return false end
	for _, part in ipairs(model:GetChildren()) do
		if part:IsA("BasePart") then
			return true
		end
	end
	return false
end

local function createHighlightForModel(model, folderName)
	-- crea siempre el Highlight (asume modelo listo)
	local hl = Instance.new("Highlight")
	hl.Name = model.Name .. "_HL_" .. folderName
	-- preferimos adornee al modelo (funciona si el modelo tiene partes),
	-- pero si en alguna plataforma falla, nos aseguramos de que haya al menos una BasePart
	hl.Adornee = model
	hl.OutlineColor = COLORS[folderName] or Color3.new(1,1,1)
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Enabled = false
	hl.Parent = HighlightCache
	return hl
end

local function getOrCreateHighlight(model, folderName)
	-- si ya existe, actualizar folder si fue pasado distinto
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		if data.Folder ~= folderName then
			data.Folder = folderName
		end
		-- reforzar Adornee si fue invalidado
		if not data.Highlight.Adornee or not data.Highlight.Adornee:IsDescendantOf(Workspace) then
			data.Highlight.Adornee = model
		end
		return data.Highlight
	end

	-- esperar si el modelo no tiene BaseParts aún (hasta 1s)
	if not modelIsReady(model) then
		for i = 1, 10 do
			task.wait(0.1)
			if modelIsReady(model) then break end
		end
	end
	if not modelIsReady(model) then
		-- Si sigue sin partes, intentar con cualquier parte profunda (fallback)
		local anyPart = getAnyPart(model)
		if not anyPart then return nil end
		-- si hay alguna parte, permitimos crear igualmente
	end

	local hl = createHighlightForModel(model, folderName)
	ActiveHighlights[model] = { Highlight = hl, Folder = folderName, InRange = false, Distance = math.huge }
	return hl
end

local function disableHighlight(model)
	local data = ActiveHighlights[model]
	if data and data.Highlight then
		pcall(function() data.Highlight:Destroy() end)
	end
	ActiveHighlights[model] = nil
	HeadCache[model] = nil
end

------------------------------------------------------------
-- Actualización por distancia (FIX: lógica robusta y forzado Enabled)
------------------------------------------------------------
local function updateHighlightDistance()
	-- obtener referencia a la cabeza/local part para calcular distancias
	local char = LocalPlayer.Character
	local myHead = getRealHead(char) or getAnyPart(char)
	if not myHead then return end
	local myPos = myHead.Position

	-- acumular distancias por tipo
	local aliceDistances, teacherDistances = {}, {}

	-- recorrer y calcular distancia; si target no válido, deshabilitar
	for model, data in pairs(ActiveHighlights) do
		-- si el model ya no existe en workspace, limpiar
		if not model or not model:IsDescendantOf(Workspace) then
			disableHighlight(model)
		else
			-- obtener referencia para distancia (preferir cabeza real)
			local targetPart = getRealHead(model) or getAnyPart(model)
			if not targetPart then
				-- si no existe parte valida: intentar recrear el highlight más tarde
				data.Distance = math.huge
				data.InRange = false
				if data.Highlight then data.Highlight.Enabled = false end
			else
				local dist = (targetPart.Position - myPos).Magnitude
				data.Distance = dist
				if dist > MAX_RENDER_DISTANCE then
					data.InRange = false
					if data.Highlight then data.Highlight.Enabled = false end
				else
					data.InRange = true
					if data.Folder == "Alices" then
						table.insert(aliceDistances, {model, dist})
					elseif data.Folder == "Teachers" then
						table.insert(teacherDistances, {model, dist})
					end
				end
			end
		end
	end

	-- ordenar y elegir los más cercanos según límites
	table.sort(aliceDistances, function(a,b) return a[2] < b[2] end)
	table.sort(teacherDistances, function(a,b) return a[2] < b[2] end)

	local visible = {}
	for i = 1, math.min(#aliceDistances, MAX_VISIBLE_ALICES) do
		visible[aliceDistances[i][1]] = true
	end
	for i = 1, math.min(#teacherDistances, MAX_VISIBLE_TEACHERS) do
		visible[teacherDistances[i][1]] = true
	end

	-- aplicar visibilidad final (forzando Enabled true/false)
	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		if hl then
			local shouldBe = (data.InRange and visible[model]) or false
			-- reforzar Adornee si dejó de apuntar correctamente
			if (not hl.Adornee or not hl.Adornee:IsDescendantOf(Workspace)) and model:IsDescendantOf(Workspace) then
				hl.Adornee = model
			end
			-- forzar el estado
			if hl.Enabled ~= shouldBe then
				hl.Enabled = shouldBe
			end
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
						-- intentar crear highlight (getOrCreateHighlight espera modelo listo o fallback)
						local ok = getOrCreateHighlight(model, targetName)
						-- si se creó, actualizar distancia inmediatamente
						if ok then
							-- nothing extra, updateHighlightDistance será llamado después
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
	local head = getRealHead(char) or getAnyPart(char)
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
	-- espera mínima para estabilizar folder/character
	task.wait(0.5)
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
				-- crear highlight si es posible y recalcular distancias
				local created = getOrCreateHighlight(model, folder.Name)
				if created then
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
	-- si eliminan partes internas, puede que el modelo siga en ActiveHighlights;
	-- la función updateHighlightDistance limpiará modelos invalidos. Además, si
	-- directamente eliminaron el modelo, este key existirá y debemos limpiar.
	for model,_ in pairs(ActiveHighlights) do
		if model == obj or (model and not model:IsDescendantOf(Workspace)) then
			disableHighlight(model)
		end
	end
end)

------------------------------------------------------------
-- 🔁 Auto-verificador ligero
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
		else
			-- aunque no haya missing, actualizamos distancia para corregir estados
			updateHighlightDistance()
		end
	end
end)

------------------------------------------------------------
-- Inicio
------------------------------------------------------------
task.defer(function()
	task.wait(1)
	performScan()
	connectHeadMovement()
end)
