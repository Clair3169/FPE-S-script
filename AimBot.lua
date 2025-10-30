local AIM_PARTS = {
	LibraryBook = {"HumanoidRootPart", "Torso", "UpperTorso"},
	Thavel = {"UpperTorso", "Torso"},
	Circle = {"UpperTorso", "Head"},
	Bloomie = {"Head", "Torso"}
}

local MAX_TARGET_DISTANCE = 150

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local circleActive = false

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

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
	if folder then
		for _, child in ipairs(folder:GetChildren()) do
			if child:IsA("Model") then
				table.insert(models, child)
			end
		end
	end
	return models
end

local function getModelsFromFolders(folderList)
	local models = {}
	for _, folderName in ipairs(folderList) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder then
			for _, child in ipairs(folder:GetChildren()) do
				if child:IsA("Model") then
					table.insert(models, child)
				end
			end
		end
	end
	return models
end

local function getTargetPartByPriority(model, priorityList)
	for _, name in ipairs(priorityList) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
		part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function lockCameraToTargetPart(targetPart)
	if not targetPart or not Workspace.CurrentCamera then return end
	local cam = Workspace.CurrentCamera
	local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
	if not root then return end
	local camPos = cam.CFrame.Position
	local targetPos = targetPart.Position
	cam.CFrame = CFrame.lookAt(camPos, targetPos, root.CFrame.UpVector)
end

local function isTimerVisible()
	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	local gameUI = pg:FindFirstChild("GameUI")
	if not gameUI then return false end
	local mobile = gameUI:FindFirstChild("Mobile")
	if not mobile then return false end
	local alt = mobile:FindFirstChild("Alt")
	if not alt then return false end
	local timer = alt:FindFirstChild("Timer")
	if not timer or not timer:IsA("TextLabel") then return false end
	return timer.Visible
end

local function getLibraryBookTargets()
	local models = {}
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return models end
	if char.Parent and char.Parent.Name == "Students" and hasLibraryBook(char) then
		for _, m in ipairs(getModelsFromFolders({"Teachers", "Alices"})) do
			if m ~= char and (m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")) then
				table.insert(models, m)
			end
		end
	end
	return models
end

local function getThavelTargets()
	local models = {}
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return models end
	if char:GetAttribute("TeacherName") == "Thavel" and char:GetAttribute("Charging") == true then
		for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
			if m ~= char and (m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")) then
				table.insert(models, m)
			end
		end
	end
	return models
end

local charConnections = {}

local function clearCharConnections()
	for _, conn in ipairs(charConnections) do
		if conn and conn.Disconnect then
			conn:Disconnect()
		end
	end
	charConnections = {}
end

local function checkCircleConditions(char)
	if not char then return false end
	if char.Parent ~= Workspace:FindFirstChild("Teachers") then return false end
	if char:GetAttribute("TeacherName") ~= "Circle" then return false end
	local humanoid = char:FindFirstChild("Humanoid")
	if not humanoid then return false end
	return humanoid:FindFirstChild("SprintLock") ~= nil
end

local function bindCircleDetection(char)
	clearCharConnections()
	circleActive = checkCircleConditions(char)

	local attrConn = char:GetAttributeChangedSignal("TeacherName"):Connect(function()
		circleActive = checkCircleConditions(char)
	end)
	table.insert(charConnections, attrConn)

	local parentConn = char:GetPropertyChangedSignal("Parent"):Connect(function()
		circleActive = checkCircleConditions(char)
	end)
	table.insert(charConnections, parentConn)

	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		local addConn = humanoid.ChildAdded:Connect(function(child)
			if child.Name == "SprintLock" then
				circleActive = checkCircleConditions(char)
			end
		end)
		local remConn = humanoid.ChildRemoved:Connect(function(child)
			if child.Name == "SprintLock" then
				circleActive = checkCircleConditions(char)
			end
		end)
		table.insert(charConnections, addConn)
		table.insert(charConnections, remConn)
	end
end

if LocalPlayer then
	LocalPlayer.CharacterAdded:Connect(function(char)
		bindCircleDetection(char)
	end)
	LocalPlayer.CharacterRemoving:Connect(function()
		clearCharConnections()
		circleActive = false
	end)
	if LocalPlayer.Character then
		bindCircleDetection(LocalPlayer.Character)
	end
end

local function getCircleTargets()
	local models = {}
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return models end
	if not circleActive then return models end
	if isTimerVisible() then return models end

	for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
		if m ~= char and (m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")) then
			table.insert(models, m)
		end
	end
	return models
end

local function getBloomieTargets()
	local models = {}
	local teachers = Workspace:FindFirstChild("Teachers")
	if not teachers then return models end
	local myModel = teachers:FindFirstChild(LocalPlayer and LocalPlayer.Name)
	if myModel and myModel:GetAttribute("TeacherName") == "Bloomie" and myModel:GetAttribute("Aiming") == true then
		for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
			if m ~= myModel and (m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")) then
				table.insert(models, m)
			end
		end
	end
	return models
end

local function chooseTarget(models, parts)
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera or #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local best = nil
	local bestDist = math.huge

	if LocalPlayer.Character then
		rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
	else
		rayParams.FilterDescendantsInstances = {}
	end

	for _, model in ipairs(models) do
		local part = getTargetPartByPriority(model, parts)
		if part and part.Position then
			local dir = part.Position - camPos
			local dist = dir.Magnitude
			if dist > 0 and dist <= MAX_TARGET_DISTANCE and dist < bestDist then
				local dot = camLook:Dot(dir.Unit)
				if dot > 0.6 then
					local result = Workspace:Raycast(camPos, dir, rayParams)
					local visible = not result or (result.Instance and result.Instance:IsDescendantOf(model))
					if visible then
						bestDist = dist
						best = model
					end
				end
			end
		end
	end

	return best
end

local isAimbotRunning = false
local AIMBOT_RENDER_NAME = "CustomAimbotLoop"
local activationConns = {}

local function isEligible()
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return false end

	local teacher = char:GetAttribute("TeacherName")
	local hasBook = hasLibraryBook(char)
	local humanoid = char:FindFirstChild("Humanoid")
	local sprintLock = humanoid and humanoid:FindFirstChild("SprintLock")
	
	local isLibrary = (char.Parent and char.Parent.Name == "Students" and hasBook)
	local isThavel = (teacher == "Thavel" and char:GetAttribute("Charging") == true)
	local isCircle = (teacher == "Circle" and sprintLock and not isTimerVisible())
	local isBloomie = (teacher == "Bloomie" and char:GetAttribute("Aiming") == true)
	
	if (isLibrary or isThavel or isCircle or isBloomie) then
		return true
	end
	return false
end

local function aimbotUpdateFunction()
	if not isEligible() then
		RunService:UnbindFromRenderStep(AIMBOT_RENDER_NAME)
		isAimbotRunning = false
		return
	end

	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end

	local attrTeacher = char:GetAttribute("TeacherName")
	local hasBook = hasLibraryBook(char)
	local humanoid = char:FindFirstChild("Humanoid")
	local sprintLock = humanoid and humanoid:FindFirstChild("SprintLock")
	if not (hasBook or (attrTeacher == "Thavel" and char:GetAttribute("Charging")) or (attrTeacher == "Circle" and sprintLock) or (attrTeacher == "Bloomie" and char:GetAttribute("Aiming"))) then
		return
	end

	local lib = getLibraryBookTargets()
	local thavel = getThavelTargets()
	local circle = getCircleTargets()
	local bloomie = getBloomieTargets()

	local currentTarget, currentMode = nil, nil

	if #lib > 0 then
		currentTarget = chooseTarget(lib, AIM_PARTS.LibraryBook)
		currentMode = "LibraryBook"
	elseif #thavel > 0 then
		currentTarget = chooseTarget(thavel, AIM_PARTS.Thavel)
		currentMode = "Thavel"
	elseif #circle > 0 then
		currentTarget = chooseTarget(circle, AIM_PARTS.Circle)
		currentMode = "Circle"
	elseif #bloomie > 0 then
		currentTarget = chooseTarget(bloomie, AIM_PARTS.Bloomie)
		currentMode = "Bloomie"
	end

	if currentTarget and currentMode then
		local part = getTargetPartByPriority(currentTarget, AIM_PARTS[currentMode])
		if part then
			lockCameraToTargetPart(part)
		end
	end
end

local function runAimbot()
	if isAimbotRunning then return end
	isAimbotRunning = true
	
	local camPriority = Enum.RenderPriority.Last.Value
	RunService:BindToRenderStep(AIMBOT_RENDER_NAME, camPriority, aimbotUpdateFunction)
end

local function stopAimbot()
	if not isAimbotRunning then return end
	RunService:UnbindFromRenderStep(AIMBOT_RENDER_NAME)
	isAimbotRunning = false
end

local function clearActivationConns()
	for _, c in ipairs(activationConns) do
		if c and c.Disconnect then
			c:Disconnect()
		end
	end
	activationConns = {}
end

local function bindAutoActivation()
	clearActivationConns()

	local function checkAndRun()
		if not isAimbotRunning and isEligible() then
			runAimbot()
		end
	end

	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end

	table.insert(activationConns, char:GetAttributeChangedSignal("TeacherName"):Connect(checkAndRun))
	table.insert(activationConns, char:GetAttributeChangedSignal("Charging"):Connect(checkAndRun))
	table.insert(activationConns, char:GetAttributeChangedSignal("Aiming"):Connect(checkAndRun))

	table.insert(activationConns, char.ChildAdded:Connect(checkAndRun))
	table.insert(activationConns, char.ChildRemoved:Connect(checkAndRun))

	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		table.insert(activationConns, humanoid.ChildAdded:Connect(checkAndRun))
		table.insert(activationConns, humanoid.ChildRemoved:Connect(checkAndRun))
	end

	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		local timer = pg:FindFirstChild("GameUI.Mobile.Alt.Timer", true)
		if timer then
			table.insert(activationConns, timer:GetPropertyChangedSignal("Visible"):Connect(checkAndRun))
		end
	end

	checkAndRun()
end

if LocalPlayer.Character then
	bindAutoActivation()
end

LocalPlayer.CharacterAdded:Connect(function(char)
	task.wait(0.5)
	bindAutoActivation()
	bindCircleDetection(char)
end)

LocalPlayer.CharacterRemoving:Connect(function()
	stopAimbot()
	clearActivationConns()
	clearCharConnections()
	circleActive = false
end)
