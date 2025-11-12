-- 🧿 Student Highlighter (Reglas estrictas de creación)
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
HighlightCache.Name = "HighlightTeachers_Main"
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

-- Reglas estrictas: devuelve true solo si, según tu carpeta, debes ver objetivos de targetFolderName
local function canSeeTarget(localFolderName, targetFolderName)
	if localFolderName == "Teachers" then
		-- Teacher solo ve Alices
		return targetFolderName == "Alices"
	elseif localFolderName == "Alices" then
		-- Alice solo ve Teachers
		return targetFolderName == "Teachers"
	elseif localFolderName == "Students" then
		-- Student ve Alices y Teachers
		return targetFolderName == "Alices" or targetFolderName == "Teachers"
	end
	return false
end

------------------------------------------------------------
-- Highlight: crear solo si es necesario
------------------------------------------------------------
local function getOrCreateHighlight(model, folderName)
	-- Protección: no crear si ya existe
	if ActiveHighlights[model] and ActiveHighlights[model].Highlight then
		return ActiveHighlights[model].Highlight
	end

	-- Crear highlight (inicialmente desactivado)
	local hl = Instance.new("Highlight")
	hl.Name = model.Name .. "_HL_" .. folderName
	hl.Adornee = model
	hl.OutlineColor = COLORS[folderName] or Color3.new(1,1,1)
	hl.FillTransparency = 1
	hl.OutlineTransparency = 0
	hl.Enabled = false -- inicialmente desactivado, se activa por distancia
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
-- Actualización por distancia (hiberna en lugar de destruir por rango)
------------------------------------------------------------
local function updateHighlightDistance()
	local char = LocalPlayer.Character
	local myHead = getRealHead(char)
	if not myHead then return end
	local myPos = myHead.Position

	local aliceDistances, teacherDistances = {}, {}

	-- Recalcular distancias para los highlights existentes
	for model, data in pairs(ActiveHighlights) do
		local targetHead = getRealHead(model)
		-- si el modelo fue eliminado o no tiene cabeza → destruir
		if not targetHead or not model:IsDescendantOf(Workspace) then
			disableHighlight(model)
			continue
		end

		local dist = (targetHead.Position - myPos).Magnitude
		data.Distance = dist

		-- Si fuera de rango, hibernar (desactivar), pero no destruir
		if dist > MAX_RENDER_DISTANCE then
			if data.Highlight then
				data.Highlight.Enabled = false
			end
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

	-- Ordenar por distancia y seleccionar los que deben mostrarse
	table.sort(aliceDistances, function(a,b) return a[2] < b[2] end)
	table.sort(teacherDistances, function(a,b) return a[2] < b[2] end)

	local visible = {}

	for i = 1, math.min(#aliceDistances, MAX_VISIBLE_ALICES) do
		visible[aliceDistances[i][1]] = true
	end
	for i = 1, math.min(#teacherDistances, MAX_VISIBLE_TEACHERS) do
		visible[teacherDistances[i][1]] = true
	end

	-- Activar solo los necesarios; los demás quedan hibernando (Enabled = false)
	for model, data in pairs(ActiveHighlights) do
		local hl = data.Highlight
		if hl then
			if data.InRange and visible[model] then
				-- activar si está en rango y es uno de los más cercanos
				hl.Enabled = true
			else
				hl.Enabled = false
			end
		end
	end
end

------------------------------------------------------------
-- Escaneo inicial filtrado y estricto
------------------------------------------------------------
local function performScan()
	local myFolder = detectPlayerFolder()
	if not myFolder then return end
	local myFolderName = myFolder.Name

	-- Solo crear highlights para carpetas que realmente puedes ver según tus reglas
	for targetName, folder in pairs(Folders) do
		if canSeeTarget(myFolderName, targetName) then
			for _, model in ipairs(folder:GetChildren()) do
				-- Seguridad: no crear highlight para quien esté en la misma carpeta que tú
				if model:IsA("Model") and model.Name ~= LocalPlayer.Name then
					-- Excluir modelos que pertenezcan a tu propia carpeta (duplicado de seguridad)
					local parentFolder = model.Parent
					if parentFolder == Folders[myFolderName] then
						-- si el modelo está en la misma carpeta del jugador, NO crear highlight
						continue
					end

					local head = getRealHead(model)
					if head then
						getOrCreateHighlight(model, targetName)
					end
				end
			end
		end
	end

	updateHighlightDistance()
end

------------------------------------------------------------
-- Movimiento del jugador (conexión segura)
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
-- Eventos (ChildAdded/ChildRemoved estrictos)
------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	-- Hibernar todos los highlights actuales (no destruir)
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

-- ChildAdded: solo crear si la regla lo permite (según carpeta actual)
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function(model)
		task.defer(function()
			local myFolder = detectPlayerFolder()
			if not myFolder then return end
			local myFolderName = myFolder.Name

			-- Solo si tú (local) tienes permiso de ver esta carpeta
			if not canSeeTarget(myFolderName, folder.Name) then
				return
			end

			-- No crear highlight para alguien de tu misma carpeta
			if model.Parent == Folders[myFolderName] then
				return
			end

			-- Validación final
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
		-- Si un modelo sale, limpiarlo totalmente
		disableHighlight(model)
	end)
end

-- Limpieza si algo es eliminado desde otro lugar
Workspace.DescendantRemoving:Connect(function(obj)
	if ActiveHighlights[obj] then
		disableHighlight(obj)
	end
end)

------------------------------------------------------------
-- Revisión ligera periódica
------------------------------------------------------------
task.spawn(function()
	while task.wait(3) do
		updateHighlightDistance()
	end
end)

-- Inicio
performScan()
connectHeadMovement()
