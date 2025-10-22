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
	return billboard
end

local ActiveBillboards = {}

local function removeFloatingImage(model)
	if ActiveBillboards[model] then
		ActiveBillboards[model].Billboard:Destroy()
		ActiveBillboards[model] = nil
	end
end

local function attachFloatingImage(model, imageId)
	if not model then return end
	local headPart = getRealHead(model)
	if not headPart then return end
	if ActiveBillboards[model] then
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

local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

local function monitorAttributes(model)
	if not model or not model:GetAttribute("TeacherName") then return end
	local teacherName = model:GetAttribute("TeacherName")
	local normalImage = TeacherImages[teacherName]
	if not normalImage then return end
	attachFloatingImage(model, normalImage)
	local function updateImage()
		local enraged = model:GetAttribute("Enraged")
		if enraged == true then
			attachFloatingImage(model, ENRAGED_IMAGE)
		else
			attachFloatingImage(model, normalImage)
		end
	end
	model:GetAttributeChangedSignal("Enraged"):Connect(updateImage)
	updateImage()
end

local lastRenderCheck = 0
local RENDER_CHECK_THROTTLE = 0.1 

RunService.Heartbeat:Connect(function()
	local now = os.clock()
	if now - lastRenderCheck < RENDER_CHECK_THROTTLE then
		return
	end
	lastRenderCheck = now
	
	if next(ActiveBillboards) == nil then return end

	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	
	if not myHead or not myHead.Parent then return end
	
	local myPos = myHead.Position

	for model, data in pairs(ActiveBillboards) do
		if not model or not model.Parent then
			removeFloatingImage(model)
			continue
		end
		
		local targetHead = getRealHead(model)

		if targetHead and targetHead.Parent then
			local dist = (targetHead.Position - myPos).Magnitude
			data.Billboard.Enabled = dist <= MAX_RENDER_DISTANCE
		else
			removeFloatingImage(model)
		end
	end
end)

-- === LÓGICA DE EVENTOS (REEMPLAZA autoCheckFolders) ===

local function onModelRemoved(model)
	if model:IsA("Model") then
		removeFloatingImage(model)
	end
end

local function onModelAdded(model)
	if not model:IsA("Model") then return end
	
	local head = getRealHead(model)
	if not head then return end

	local myFolder = detectPlayerFolder()
	local isInTeachers = myFolder and myFolder.Name == "Teachers"
	local isInAlices = myFolder and myFolder.Name == "Alices"
	
	local modelFolder = model.Parent
	if not modelFolder then return end

	-- Filtro: Omitir al jugador local si está en la carpeta "Alices"
	if isInAlices and modelFolder.Name == "Alices" and model.Name == LocalPlayer.Name then
		return
	end

	-- Filtro: Si estoy en "Teachers", solo mostrar Alice/AliceP2
	if isInTeachers and modelFolder.Name == "Teachers" then
		local teacherName = model:GetAttribute("TeacherName")
		if teacherName and not TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER[teacherName] then
			removeFloatingImage(model)
			return
		end
	end

	-- Si pasa todos los filtros, monitorear
	monitorAttributes(model)
end

-- Conectar los eventos
Folders.Alices.ChildAdded:Connect(onModelAdded)
Folders.Teachers.ChildAdded:Connect(onModelAdded)

Folders.Alices.ChildRemoved:Connect(onModelRemoved)
Folders.Teachers.ChildRemoved:Connect(onModelRemoved)

-- Escaneo inicial para modelos que ya existen al unirse
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
	
	-- Una vez que sabemos dónde está el jugador, ejecutar el escaneo inicial
	for _, model in ipairs(Folders.Alices:GetChildren()) do
		onModelAdded(model)
	end
	for _, model in ipairs(Folders.Teachers:GetChildren()) do
		onModelAdded(model)
	end
end)
