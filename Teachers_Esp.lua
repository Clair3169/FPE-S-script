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

local MAX_RENDER_DISTANCE = 300
local CHECK_INTERVAL = 5
local ENRAGED_IMAGE = "rbxassetid://108867117884833"

local TeacherImages = {
	Thavel = "rbxassetid://126007170470250",
	Circle = "rbxassetid://72842137403522",
	Bloomie = "rbxassetid://129090409260807",
	Alice = "rbxassetid://94023609108845",
	AlicePhase2 = "rbxassetid://78066130044573",
}

local TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER = {
	Alice = true,
	AlicePhase2 = true,
}

--// (SOLUCIÓN IMPORTADA DE SCRIPT1)
--// Función robusta para obtener la cabeza (BasePart) real
local function getRealHead(model)
	if not model then return nil end
	local teacherName = model:GetAttribute("TeacherName")
	local head = model:FindFirstChild("Head")
	if not head then return nil end
	
	-- Maneja el caso especial donde "Head" es un Modelo (ej: AlicePhase2)
	if teacherName == "AlicePhase2" and head:IsA("Model") then
		local inner = head:FindFirstChild("Head")
		if inner and inner:IsA("BasePart") then
			return inner -- Devuelve la BasePart interna
		end
	end
	
	-- Devuelve la cabeza si es una BasePart normal
	if head:IsA("BasePart") then
		return head
	end
	
	-- Si "Head" existe pero no es ni una BasePart ni el caso especial, no es válido
	return nil
end

--// Función para crear el BillboardGui
local function createBillboard(imageId)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingImage"
	billboard.Size = UDim2.new(0, 65, 0, 65)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = true
	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = imageId
	img.Parent = billboard
	return billboard
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

--// Almacenamiento de billboards activos
local ActiveBillboards = {}

local function removeFloatingImage(model)
	local data = ActiveBillboards[model]
	if data and data.Billboard then
		data.Billboard:Destroy()
	end
	ActiveBillboards[model] = nil
end

local function attachFloatingImage(model, imageId)
	if not model then return end
	
	--// (MODIFICADO) Usa la función getRealHead
	local headPart = getRealHead(model)
	if not headPart then return end -- Si no hay cabeza válida, no hace nada

	--// El resto de la lógica de Script2 se mantiene
	local existing = ActiveBillboards[model]
	if existing then
		if existing.ImageLabel and existing.ImageLabel.Image ~= imageId then
			existing.ImageLabel.Image = imageId
		end
		return
	end

	local billboard = createBillboard(imageId)
	billboard.Adornee = headPart
	billboard.Parent = model
	ActiveBillboards[model] = {
		Billboard = billboard,
		ImageLabel = billboard:FindFirstChildOfClass("ImageLabel"),
	}
end

local function clearAllBillboardsFromFolder(folder)
	for _, model in ipairs(folder:GetChildren()) do
		if ActiveBillboards[model] then
			removeFloatingImage(model)
		end
	end
end

--// Manejo de atributos (Enraged / Normal)
local function monitorAttributes(model)
	if not model then return end
	local teacherName = model:GetAttribute("TeacherName")
	if not teacherName then return end
	local normalImage = TeacherImages[teacherName]
	if not normalImage then return end

	attachFloatingImage(model, normalImage)

	local function updateImage()
		local enraged = model:GetAttribute("Enraged")
		if enraged then
			attachFloatingImage(model, ENRAGED_IMAGE)
		else
			attachFloatingImage(model, normalImage)
		end
	end

	model:GetAttributeChangedSignal("Enraged"):Connect(updateImage)
	updateImage()
end

--// Escanear modelos en carpeta
local function scanFolder(folder, skipLocal, onlyTeachersToShow)
	for _, model in ipairs(folder:GetChildren()) do
		
		--// (MODIFICADO) Usa getRealHead para validar el modelo
		if not model:IsA("Model") or not getRealHead(model) then
			removeFloatingImage(model)
			continue
		end
		
		--// El resto de la lógica de Script2 se mantiene
		if skipLocal and model.Name == LocalPlayer.Name then
			continue
		end

		local teacherName = model:GetAttribute("TeacherName")
		if onlyTeachersToShow and teacherName and not onlyTeachersToShow[teacherName] then
			removeFloatingImage(model)
			continue
		end

		monitorAttributes(model)
	end
end

--// Control visual en tiempo real
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	
	--// (MODIFICADO) Usa getRealHead para el jugador local y pcall para seguridad
	local myHead = getRealHead(myChar)
	if not myHead then return end
	
	local ok, myPos = pcall(function() return myHead.Position end)
	if not ok then return end -- Si falla al obtener la posición, detiene este frame

	for model, data in pairs(ActiveBillboards) do
		--// (MODIFICADO) Usa getRealHead para el modelo objetivo y pcall
		local targetHead = getRealHead(model)
		if targetHead and data.Billboard then
			
			local success, dist = pcall(function()
				return (targetHead.Position - myPos).Magnitude
			end)
			
			if success then
				data.Billboard.Enabled = dist <= MAX_RENDER_DISTANCE
			else
				data.Billboard.Enabled = false -- Oculta si hay error al calcular dist
			end
		else
			removeFloatingImage(model)
		end
	end

	--// Esta parte de la optimización de Script2 se mantiene
	for model in pairs(ActiveBillboards) do
		if not model.Parent then
			removeFloatingImage(model)
		end
	end
end)

--// NUEVO: Control inteligente de escaneo (pausa/reanuda según contenido)
local autoCheckActive = false
local autoCheckConnection = nil

local function startAutoCheck()
	if autoCheckActive then return end
	autoCheckActive = true
	autoCheckConnection = task.spawn(function()
		while autoCheckActive do
			local totalObjects = 0
			for _, f in pairs(Folders) do
				totalObjects += #f:GetChildren()
			end

			if totalObjects == 0 then
				autoCheckActive = false
				break
			end

			local myFolder = detectPlayerFolder()
			local isPlayerInTeachersFolder = myFolder and myFolder.Name == "Teachers"

			local teacherCount = #Folders.Teachers:GetChildren()
			if teacherCount > 0 then
				local filter = isPlayerInTeachersFolder and TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER or nil
				scanFolder(Folders.Teachers, false, filter)
			else
				clearAllBillboardsFromFolder(Folders.Teachers)
			end

			local aliceCount = #Folders.Alices:GetChildren()
			local skipLocalInAlices = myFolder and myFolder.Name == "Alices"
			if aliceCount > 0 then
				scanFolder(Folders.Alices, skipLocalInAlices, nil)
			else
				clearAllBillboardsFromFolder(Folders.Alices)
			end

			task.wait(CHECK_INTERVAL)
		end
	end)
end

--// Evento que detecta cuando se añaden o eliminan objetos para pausar/reanudar
for _, folder in pairs(Folders) do
	folder.ChildAdded:Connect(function()
		if not autoCheckActive then
			startAutoCheck()
		end
	end)

	folder.ChildRemoved:Connect(function()
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
		task.wait(1)
	until PlayerModel
	startAutoCheck()
end)
