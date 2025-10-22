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

local function clearAllBillboardsFromFolder(folder)
	for _, model in ipairs(folder:GetChildren()) do
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

local function scanFolder(folder, skipLocal, onlyTeachersToShow)
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and getRealHead(model) then
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
end

RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	local myHead = getRealHead(myChar)
	if not myHead then return end
	local ok, myPos = pcall(function() return myHead.Position end)
	if not ok then return end
	if next(ActiveBillboards) == nil then return end
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
		local isInTeachers = myFolder and myFolder.Name == "Teachers"
		local teachers = Folders.Teachers
		local alices = Folders.Alices
		if #teachers:GetChildren() >= 1 then
			local filter = isInTeachers and TEACHERS_TO_SHOW_IN_TEACHERS_FOLDER or nil
			scanFolder(teachers, false, filter)
		else
			clearAllBillboardsFromFolder(teachers)
		end
		if #alices:GetChildren() >= 1 then
			local skipLocal = myFolder and myFolder.Name == "Alices"
			scanFolder(alices, skipLocal, nil)
		else
			clearAllBillboardsFromFolder(alices)
		end
		if next(ActiveBillboards) == nil then
			repeat task.wait(2) until next(ActiveBillboards) ~= nil
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
