local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer

-- --- Configuración ---

local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

local MAX_RENDER_DISTANCE = 300
local MAX_RENDER_DISTANCE_SQUARED = MAX_RENDER_DISTANCE * MAX_RENDER_DISTANCE -- Más rápido para comparar distancias
local DISTANCE_CHECK_INTERVAL = 0.25 -- Comprobar 4 veces por segundo, no 60+

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

-- --- Variables de Estado ---

local ActiveBillboards = {} -- Almacena los carteles activos y sus conexiones
local PlayerFolder = nil -- Almacena la carpeta actual del jugador

-- --- Funciones de Ayuda ---

local function getRealHead(model)
	if not model then return nil end
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
	
	return billboard, img
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

-- --- Lógica Principal del Script ---

-- Limpia un cartel y todas sus conexiones
local function removeFloatingImage(model)
	local data = ActiveBillboards[model]
	if data then
		data.Billboard:Destroy()
		-- Desconecta todas las señales para prevenir fugas de memoria
		for _, connection in ipairs(data.Connections) do
			connection:Disconnect()
		end
		ActiveBillboards[model] = nil
	end
end

-- Procesa un modelo UNA SOLA VEZ cuando aparece
local function processModel(model)
	if not model:IsA("Model") then return end
	if ActiveBillboards[model] then return end -- Ya está procesado

	local headPart = getRealHead(model)
	if not headPart then return end -- No tiene cabeza válida

	-- --- Aplicar Filtros ---
	local teacherName = model:GetAttribute("TeacherName")
	
	-- Filtro 1: Si estoy en "Alices", no me muestro mi propio cartel
	if PlayerFolder and PlayerFolder.Name == "Alices" and model.Name == LocalPlayer.Name then
		return
	end
	
	-- Filtro 2: Si estoy en "Teachers", solo veo a los teachers permitidos
	if PlayerFolder and PlayerFolder.Name == "Teachers" then
		if not teacherName or not TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER[teacherName] then
			return
		end
	end
	
	local normalImage = teacherName and TeacherImages[teacherName]
	if not normalImage then return end -- No es un teacher con imagen

	-- --- Crear y Configurar ---
	local billboard, imageLabel = createBillboard(normalImage)
	billboard.Adornee = headPart
	billboard.Parent = model

	local connections = {} -- Tabla para guardar las conexiones y limpiarlas luego

	-- Función que se conectará al atributo "Enraged"
	local function updateImage()
		local enraged = model:GetAttribute("Enraged")
		if enraged == true then
			imageLabel.Image = ENRAGED_IMAGE
		else
			imageLabel.Image = normalImage
		end
	end

	-- Conectar señales UNA SOLA VEZ
	table.insert(connections, model:GetAttributeChangedSignal("Enraged"):Connect(updateImage))
	
	-- Conectar señal de destrucción para limpieza
	table.insert(connections, model.Destroying:Connect(function()
		removeFloatingImage(model)
	end))

	-- Guardar toda la información
	ActiveBillboards[model] = {
		Billboard = billboard,
		ImageLabel = imageLabel,
		Head = headPart, -- Guardamos la cabeza para no buscarla más
		Connections = connections,
	}

	updateImage() -- Establecer la imagen inicial correcta
end

-- --- Bucle de Comprobación de Distancia (Optimizado) ---

task.spawn(function()
	while task.wait(DISTANCE_CHECK_INTERVAL) do
		local myChar = LocalPlayer.Character
		local myHead = getRealHead(myChar) -- Usamos la función para ser consistentes
		
		if not myHead then
			-- Si el jugador no tiene cabeza (muerto o no cargado), ocultar todo
			for _, data in pairs(ActiveBillboards) do
				data.Billboard.Enabled = false
			end
			continue -- Saltar esta iteración
		end
		
		local myPos = myHead.Position

		for model, data in pairs(ActiveBillboards) do
			if data.Head and data.Head.Parent then
				-- Usamos MagnitudeSqr (más rápido)
				local distanceSqr = (data.Head.Position - myPos).MagnitudeSqr
				data.Billboard.Enabled = distanceSqr <= MAX_RENDER_DISTANCE_SQUARED
			else
				-- El modelo o su cabeza ya no existen, limpiarlo
				removeFloatingImage(model)
			end
		end
	end
end)

-- --- Configuración de Eventos (Reemplaza autoCheckFolders) ---

local function setupFolderEvents(folder)
	-- 1. Procesar todos los modelos que YA existen
	for _, model in ipairs(folder:GetChildren()) do
		task.spawn(processModel, model) -- task.spawn por si un modelo da error
	end
	
	-- 2. Conectar eventos para modelos futuros
	folder.ChildAdded:Connect(processModel)
	folder.ChildRemoved:Connect(removeFloatingImage)
end

-- Detectar la carpeta del jugador al inicio
PlayerFolder = detectPlayerFolder()

-- Re-detectar si el personaje reaparece (por si cambia de equipo/carpeta)
LocalPlayer.CharacterAdded:Connect(function(character)
	task.wait(0.5) -- Dar tiempo a que el personaje sea asignado a una carpeta
	PlayerFolder = detectPlayerFolder()
end)

-- Iniciar los listeners
setupFolderEvents(Folders.Alices)
setupFolderEvents(Folders.Teachers)
