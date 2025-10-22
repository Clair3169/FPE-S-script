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
	for _, folderName in ipairs({"Alices", "Students", "Teachers"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

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
	local headPart = model:FindFirstChild("Head")
	if not headPart then return end
	local teacherName = model:GetAttribute("TeacherName")
	if teacherName == "AlicePhase2" then
		local headModel = model:FindFirstChild("Head")
		if headModel and headModel:IsA("Model") then
			headPart = headModel:FindFirstChild("Head")
		end
	end
	if not headPart then return end

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

local function scanFolder(folder, skipLocal, onlyTeachersToShow)
	for _, model in ipairs(folder:GetChildren()) do
		if not model:IsA("Model") or not model:FindFirstChild("Head") then
			removeFloatingImage(model)
			continue
		end
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

RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("Head") then return end
	local myPos = myChar.Head.Position

	for model, data in pairs(ActiveBillboards) do
		if model and model:FindFirstChild("Head") and data.Billboard then
			local dist = (model.Head.Position - myPos).Magnitude
			data.Billboard.Enabled = dist <= MAX_RENDER_DISTANCE
		else
			removeFloatingImage(model)
		end
	end

	for model in pairs(ActiveBillboards) do
		if not model.Parent then
			removeFloatingImage(model)
		end
	end
end)

local function autoCheckFolders()
	while task.wait(CHECK_INTERVAL) do
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
	end
end

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
	task.spawn(autoCheckFolders)
end)
