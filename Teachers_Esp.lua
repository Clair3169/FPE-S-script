local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerModel = nil

local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

local MAX_RENDER_DISTANCE = 300
-- cuantas imágenes flotantes se permite
local CHECK_INTERVAL = 5
local ENRAGED_IMAGE = "rbxassetid://108867117884833"

local TeacherImages = {
	Thavel = "rbxassetid://126007170470250",
	Circle = "rbxassetid://72842137403522",
	Bloomie = "rbxassetid://129090409260807",
	Alice = "rbxassetid://94023609108845",
	AlicePhase2 = "rbxassetid://78066130044573",
}

-- Definimos las teachers a mostrar si el jugador está en la carpeta 'Teachers'
local TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER = {
	Alice = true,
	AlicePhase2 = true,
}

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

local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do -- Asegúrate de incluir 'Teachers' aquí para la detección
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

local ActiveBillboards = {}

local function attachFloatingImage(model, imageId)
	if not model or not model:FindFirstChild("Head") then return end
	local teacherName = model:GetAttribute("TeacherName")
	local headPart = nil
	if teacherName == "AlicePhase2" then
		local headModel = model:FindFirstChild("Head")
		if headModel and headModel:IsA("Model") then
			headPart = headModel:FindFirstChild("Head")
		end
	else
		headPart = model:FindFirstChild("Head")
	end
	if not headPart then return end
	if ActiveBillboards[model] then
		-- Si ya existe, actualiza la imagen si es diferente o simplemente retorna
		if ActiveBillboards[model].ImageLabel.Image ~= imageId then
			ActiveBillboards[model].ImageLabel.Image = imageId
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

local function removeFloatingImage(model)
	if ActiveBillboards[model] then
		ActiveBillboards[model].Billboard:Destroy()
		ActiveBillboards[model] = nil
	end
end

local function clearAllBillboardsFromFolder(folder)
	for _, model in ipairs(folder:GetChildren()) do
		-- Solo intentamos remover si el modelo está en nuestra lista de activos
		if ActiveBillboards[model] then
			removeFloatingImage(model)
		end
	end
end

local function monitorAttributes(model)
	if not model or not model:GetAttribute("TeacherName") then return end
	local teacherName = model:GetAttribute("TeacherName")
	local normalImage = TeacherImages[teacherName]
	if not normalImage then return end
	
	-- Aquí es donde se adjunta inicialmente
	attachFloatingImage(model, normalImage)
	
	local function updateImage()
		local enraged = model:GetAttribute("Enraged")
		if enraged == true then
			attachFloatingImage(model, ENRAGED_IMAGE)
		else
			attachFloatingImage(model, normalImage)
		end
	end
	
	-- Conectamos la señal para actualizar si el estado "Enraged" cambia
	model:GetAttributeChangedSignal("Enraged"):Connect(updateImage)
	
	-- Llamamos una vez para asegurar el estado inicial
	updateImage()
end

-- Modificamos scanFolder para aceptar un filtro de nombres
local function scanFolder(folder, skipLocal, onlyTeachersToShow)
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Head") then
			if skipLocal and model.Name == LocalPlayer.Name then
				continue
			end
			
			local teacherName = model:GetAttribute("TeacherName")
			
			-- Aplicar la lógica de filtrado solo si 'onlyTeachersToShow' está presente
			if onlyTeachersToShow and teacherName and not onlyTeachersToShow[teacherName] then
				-- Si no es Alice o AlicePhase2, asegúrate de que no tenga un Billboard activo
				removeFloatingImage(model) 
				continue
			end
			
			-- Si llegamos aquí, creamos/actualizamos el Billboard
			monitorAttributes(model)
		end
	end
end

-- ✅ Función auxiliar para obtener la cabeza física (BasePart o MeshPart real)
local function getRealHead(model)
	if not model then return nil end

	local head = model:FindFirstChild("Head")
	if not head then return nil end

	-- Si el "Head" es un Model (caso AlicePhase2), busca dentro el verdadero MeshPart
	if head:IsA("Model") then
		local innerHead = head:FindFirstChild("Head")
		if innerHead and innerHead:IsA("BasePart") then
			return innerHead
		end
	end

	-- Si el Head ya es un BasePart normal
	if head:IsA("BasePart") then
		return head
	end

	return nil
end


-- 💫 Bucle principal: control de distancia sin errores
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	if not myChar then return end

	local myHead = getRealHead(myChar)
	if not myHead then return end

	local ok, myPos = pcall(function() return myHead.Position end)
	if not ok then return end

	for model, data in pairs(ActiveBillboards) do
		local targetHead = getRealHead(model)

		if targetHead then
			local success, dist = pcall(function()
				return (targetHead.Position - myPos).Magnitude
			end)

			if success then
				data.Billboard.Enabled = dist <= MAX_RENDER_DISTANCE
			else
				data.Billboard.Enabled = false
			end
		else
			removeFloatingImage(model)
		end
	end
end)

local function autoCheckFolders()
	while task.wait(CHECK_INTERVAL) do
		local myFolder = detectPlayerFolder()
		local isPlayerInTeachersFolder = myFolder and myFolder.Name == "Teachers"
		
		-- Lógica para la carpeta "Teachers"
		local teacherCount = #Folders.Teachers:GetChildren()
		if teacherCount >= 1 then
			-- Si estamos en la carpeta "Teachers", aplicamos el filtro de solo Alice y AlicePhase2
			local filter = isPlayerInTeachersFolder and TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER or nil
			-- Para Teachers, siempre pasamos false para skipLocal porque no es la carpeta de 'Alices' o 'Students'
			-- De todas formas, si estás en 'Teachers', tu modelo no tiene TeacherName, por lo que monitorAttributes no haría nada.
			scanFolder(Folders.Teachers, false, filter) 
		else
			clearAllBillboardsFromFolder(Folders.Teachers)
		end
		
		-- Lógica para la carpeta "Alices"
		local aliceCount = #Folders.Alices:GetChildren()
		-- La carpeta Alices es la única que tiene skipLocal como true si el jugador está en Alices
		local skipLocalInAlices = myFolder and myFolder.Name == "Alices" 
		
		if aliceCount >= 1 then
			-- En la carpeta Alices NUNCA aplicamos el filtro de solo Alice/AlicePhase2
			scanFolder(Folders.Alices, skipLocalInAlices, nil) 
		else
			clearAllBillboardsFromFolder(Folders.Alices)
		end
	end
end

task.spawn(function()
	repeat
		-- Asegúrate de que la detección para 'Teachers' también esté aquí
		for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do 
			local folder = Folders[folderName]
			if folder and folder:FindFirstChild(LocalPlayer.Name) then
				PlayerModel = folder[LocalPlayer.Name]
				break
			end
		end
		task.wait(1)
	until PlayerModel
	task.spawn(autoCheckFolders)
end)
