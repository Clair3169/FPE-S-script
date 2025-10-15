-- =====================================================
-- 🎯 Aimbot combinado (LibraryBook / Thavel / Circle / Bloomie)
-- =====================================================

repeat task.wait() until game:IsLoaded()

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- ====== CONFIG ======
local LIBRARY_TARGET_FOLDERS = {"Teachers", "Alices"}
local THAVEL_TARGET_FOLDERS  = {"Students", "Alices"}
local CIRCLE_TARGET_FOLDERS  = {"Students", "Alices"}
local BLOOMIE_TARGET_FOLDERS = {"Students", "Alices"}

local TARGET_PRIORITY_TORSO = {"UpperTorso", "Torso", "HumanoidRootPart", "Head"}
local TARGET_PRIORITY_HEAD  = {"Head", "UpperTorso", "HumanoidRootPart"}

local ANGLE_THRESHOLD = 0.85
local CAMERA_HEIGHT_OFFSET_TORSO = Vector3.new(0, 0, 0)
local CAMERA_HEIGHT_OFFSET_HEAD  = Vector3.new(0, 0, 0)

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local currentTarget = nil

-- ====== Estado Circle (toggle) ======
local circleActive = false
local circleButtonConnected = false
local circleButtonReference = nil

-- ====== UTILIDADES ======

local function hasLibraryBook(character)
	if not character then return false end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Tool") and obj.Name == "LibraryBook" then
			return true
		end
	end
	return false
end

local function getModelsFromFolder(folderName)
	local models = {}
	local folder = Workspace:FindFirstChild(folderName)
	if not folder then return models end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	return models
end

local function getModelsFromFolders(folderList)
	local models = {}
	for _, folderName in ipairs(folderList) do
		for _, m in ipairs(getModelsFromFolder(folderName)) do
			table.insert(models, m)
		end
	end
	return models
end

local function getTargetPartByPriority(model, priorityList)
	for _, name in ipairs(priorityList) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function chooseTarget(models, priorityList)
	if #models == 0 then return nil end
	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local bestModel = nil
	local bestDot = -1

	for _, model in ipairs(models) do
		if model and model:IsA("Model") then
			local part = getTargetPartByPriority(model, priorityList)
			if part then
				local dir = part.Position - camPos
				if dir.Magnitude > 0 then
					local dot = camLook:Dot(dir.Unit)
					if dot > bestDot then
						bestDot = dot
						bestModel = model
					end
				end
			end
		end
	end
	if bestDot >= ANGLE_THRESHOLD then
		return bestModel
	end
	return nil
end

local function lockCameraToTargetPart(targetPart, offset)
	if not targetPart then return end
	local camPos = Camera.CFrame.Position
	local targetPos = targetPart.Position + (offset or Vector3.new(0,0,0))
	Camera.CFrame = CFrame.lookAt(camPos, targetPos)
end

-- ====== TIMER CHECK (GameUI>Mobile>Alt>Timer) ======
local function isTimerVisible()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	local gameUI = pg:FindFirstChild("GameUI")
	if not gameUI then return false end
	local mobile = gameUI:FindFirstChild("Mobile")
	if not mobile then return false end
	local alt = mobile:FindFirstChild("Alt")
	if not alt then return false end
	local timer = alt:FindFirstChild("Timer")
	if not timer or not timer:IsA("TextLabel") then return false end
	local ok, vis = pcall(function() return timer.Visible end)
	return ok and vis == true
end

-- ====== Circle Button (GameUI>Mobile>Alt) ======
local function tryConnectCircleButton()
	if circleButtonConnected then return end
	circleButtonConnected = true

	spawn(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
		if not pg then circleButtonConnected = false return end
		local gameUI = pg:WaitForChild("GameUI", 5)
		if not gameUI then circleButtonConnected = false return end
		local mobile = gameUI:WaitForChild("Mobile", 5)
		if not mobile then circleButtonConnected = false return end
		local altButton = mobile:WaitForChild("Alt", 5)
		if not altButton or not altButton:IsA("ImageButton") then
			circleButtonConnected = false
			return
		end
		circleButtonReference = altButton

		altButton.Activated:Connect(function()
			if isTimerVisible() then
				circleActive = false
				currentTarget = nil
				pcall(function() altButton.ImageTransparency = 0.5 end)
				return
			end
			circleActive = not circleActive
			if not circleActive then currentTarget = nil end
			pcall(function() altButton.ImageTransparency = circleActive and 0 or 0.5 end)
		end)
	end)
end

tryConnectCircleButton()

-- ====== Toggle PC (click derecho) ======
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local char = LocalPlayer.Character
		if not char then return end
		if char:GetAttribute("TeacherName") ~= "Circle" then return end
		if isTimerVisible() then
			circleActive = false
			currentTarget = nil
			if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = 0.5 end) end
			return
		end
		circleActive = not circleActive
		if not circleActive then currentTarget = nil end
		if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = circleActive and 0 or 0.5 end) end
	end
end)

-- ====== MODOS ======
local function getLibraryBookTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end
	local inStudents = char.Parent and char.Parent.Name == "Students"
	if inStudents and hasLibraryBook(char) then
		for _, m in ipairs(getModelsFromFolders(LIBRARY_TARGET_FOLDERS)) do
			if m ~= char and m:FindFirstChild("Head", true) then
				table.insert(models, m)
			end
		end
	end
	return models
end

local function getThavelTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end
	if char:GetAttribute("TeacherName") == "Thavel" and char:GetAttribute("Charging") == true then
		for _, m in ipairs(getModelsFromFolders(THAVEL_TARGET_FOLDERS)) do
			if m ~= char and m:FindFirstChild("Head", true) then
				table.insert(models, m)
			end
		end
	end
	return models
end

local function getCircleTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end
	if char:GetAttribute("TeacherName") == "Circle" and circleActive and not isTimerVisible() then
		for _, m in ipairs(getModelsFromFolders(CIRCLE_TARGET_FOLDERS)) do
			if m ~= char and m:FindFirstChild("Head", true) then
				table.insert(models, m)
			end
		end
	end
	return models
end

local function getBloomieTargets()
	local models = {}
	local teachersFolder = Workspace:FindFirstChild("Teachers")
	if not teachersFolder then return models end
	local myModel = teachersFolder:FindFirstChild(LocalPlayer.Name)
	if not myModel then return models end
	if myModel:GetAttribute("TeacherName") == "Bloomie" and myModel:GetAttribute("Aiming") == true then
		for _, m in ipairs(getModelsFromFolders(BLOOMIE_TARGET_FOLDERS)) do
			if m ~= myModel and m:FindFirstChild("Head", true) then
				table.insert(models, m)
			end
		end
	end
	return models
end

-- ====== LOOP PRINCIPAL ======
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end

	local libTargets = getLibraryBookTargets()
	local thavelTargets = getThavelTargets()
	local circleTargets = getCircleTargets()
	local bloomTargets = getBloomieTargets()

	local targetPart, offset

	if #libTargets > 0 then
		currentTarget = chooseTarget(libTargets, TARGET_PRIORITY_TORSO)
		targetPart = currentTarget and getTargetPartByPriority(currentTarget, TARGET_PRIORITY_TORSO)
		offset = CAMERA_HEIGHT_OFFSET_TORSO

	elseif #thavelTargets > 0 then
		currentTarget = chooseTarget(thavelTargets, TARGET_PRIORITY_HEAD)
		targetPart = currentTarget and getTargetPartByPriority(currentTarget, TARGET_PRIORITY_HEAD)
		offset = CAMERA_HEIGHT_OFFSET_HEAD

	elseif #circleTargets > 0 then
		currentTarget = chooseTarget(circleTargets, TARGET_PRIORITY_HEAD)
		targetPart = currentTarget and getTargetPartByPriority(currentTarget, TARGET_PRIORITY_HEAD)
		offset = CAMERA_HEIGHT_OFFSET_HEAD

	elseif #bloomTargets > 0 then
		currentTarget = chooseTarget(bloomTargets, TARGET_PRIORITY_HEAD)
		targetPart = currentTarget and getTargetPartByPriority(currentTarget, TARGET_PRIORITY_HEAD)
		offset = CAMERA_HEIGHT_OFFSET_HEAD
	else
		currentTarget = nil
	end

	if targetPart then
		lockCameraToTargetPart(targetPart, offset)
	end
end)
