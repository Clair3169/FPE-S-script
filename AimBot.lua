-- =====================================================
-- 🎯 Aimbot combinado (LibraryBook / Thavel / Circle / Bloomie)
-- Activación automática del modo Circle según atributos y SprintLock
-- =====================================================

local AIM_PARTS = {
    LibraryBook = {"HumanoidRootPart", "Torso", "UpperTorso"},
    Thavel = {"UpperTorso", "Torso"},
    Circle = {"UpperTorso", "Head"},
    Bloomie = {"Head", "Torso"}
}

local TARGET_UPDATE_INTERVAL = 5

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local currentTarget = nil
local currentMode = nil
local circleActive = false

-- Actualizar cámara si se reinicia
Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

-- =====================================================
-- 🔧 FUNCIONES UTILITARIAS
-- =====================================================

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

local function lockCameraToTargetPart(targetPart)
	if not targetPart or not Workspace.CurrentCamera then return end
	local cam = Workspace.CurrentCamera
	local camPos = cam.CFrame.Position
	cam.CFrame = CFrame.lookAt(camPos, targetPart.Position)
end

local function isTimerVisible()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end
	local timer = pg:FindFirstChild("GameUI") and pg.GameUI:FindFirstChild("Mobile") and pg.GameUI.Mobile:FindFirstChild("Alt") and pg.GameUI.Mobile.Alt:FindFirstChild("Timer")
	if not timer or not timer:IsA("TextLabel") then return false end
	return timer.Visible
end

-- =====================================================
-- 🧠 MODOS (LibraryBook / Thavel / Bloomie)
-- =====================================================

local function getLibraryBookTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end
	if char.Parent and char.Parent.Name == "Students" and hasLibraryBook(char) then
		for _, m in ipairs(getModelsFromFolders({"Teachers", "Alices"})) do
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
		for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
			if m ~= char and m:FindFirstChild("Head", true) then
				table.insert(models, m)
			end
		end
	end
	return models
end

-- =====================================================
-- ⚙️ NUEVO SISTEMA AUTOMÁTICO DE MODO CIRCLE
-- =====================================================

local charConnections = {}

local function clearCharConnections()
	for _, conn in ipairs(charConnections) do
		if conn and conn.Disconnect then conn:Disconnect() end
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

	-- Detectar cambios en atributos del Character
	local attrConn = char:GetAttributeChangedSignal("TeacherName"):Connect(function()
		circleActive = checkCircleConditions(char)
	end)
	table.insert(charConnections, attrConn)

	-- Detectar si el Character cambia de carpeta (Teachers u otra)
	local parentConn = char:GetPropertyChangedSignal("Parent"):Connect(function()
		circleActive = checkCircleConditions(char)
	end)
	table.insert(charConnections, parentConn)

	-- Detectar cambios dentro del Humanoid (aparición/desaparición de SprintLock)
	local humanoid = char:WaitForChild("Humanoid", 5)
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
	local char = LocalPlayer.Character
	if not char then return models end
	if not circleActive then return models end
	if isTimerVisible() then return models end

	for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
		if m ~= char and m:FindFirstChild("Head", true) then
			table.insert(models, m)
		end
	end
	return models
end

local function getBloomieTargets()
	local models = {}
	local teachers = Workspace:FindFirstChild("Teachers")
	if not teachers then return models end
	local myModel = teachers:FindFirstChild(LocalPlayer.Name)
	if myModel and myModel:GetAttribute("TeacherName") == "Bloomie" and myModel:GetAttribute("Aiming") == true then
		for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
			if m ~= myModel and m:FindFirstChild("Head", true) then
				table.insert(models, m)
			end
		end
	end
	return models
end

-- =====================================================
-- 🎯 SELECCIÓN DE OBJETIVO
-- =====================================================

local function chooseTarget(models, parts)
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera or #models == 0 then return nil end

	local camPos, camLook = Camera.CFrame.Position, Camera.CFrame.LookVector
	local best, closest = nil, math.huge

	for _, model in ipairs(models) do
		local part = getTargetPartByPriority(model, parts)
		if part then
			local dir = part.Position - camPos
			local dist = dir.Magnitude
			if dist > 0 then
				local dot = camLook:Dot(dir.Unit)
				if dot > 0.85 then
					local params = RaycastParams.new()
					params.FilterType = Enum.RaycastFilterType.Blacklist
					params.FilterDescendantsInstances = {LocalPlayer.Character}
					local result = Workspace:Raycast(camPos, dir, params)
					local visible = not result or (result.Instance and result.Instance:IsDescendantOf(model))
					if visible and dist < closest then
						closest = dist
						best = model
					end
				end
			end
		end
	end
	return best
end

-- =====================================================
-- 🔁 LOOP PRINCIPAL
-- =====================================================

local targetUpdateCounter = 0

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end

	targetUpdateCounter += 1
	if not currentTarget or targetUpdateCounter >= TARGET_UPDATE_INTERVAL then
		targetUpdateCounter = 0
		currentTarget, currentMode = nil, nil

		local lib = getLibraryBookTargets()
		local thavel = getThavelTargets()
		local circle = getCircleTargets()
		local bloomie = getBloomieTargets()

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
	end

	if currentTarget and currentMode then
		local part = getTargetPartByPriority(currentTarget, AIM_PARTS[currentMode])
		if part then
			lockCameraToTargetPart(part)
		else
			currentTarget, currentMode = nil, nil
		end
	end
end)
