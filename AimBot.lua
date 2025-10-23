-- =====================================================
-- 🎯 Aimbot combinado (LibraryBook / Thavel / Circle / Bloomie)
-- - Mejora: Line of Sight robusta + comprobaciones nil + actualización de Camera
-- =====================================================
-- ======================================================
-- ⚙️ CONFIGURACIÓN DE PUNTOS DE APUNTADO POR MODO
-- ======================================================

-- Puedes modificar estas listas a tu gusto:
local AIM_PARTS = {
    LibraryBook = {"HumanoidRootPart", "Torso", "UpperTorso"},
    Thavel = {"UpperTorso", "Torso"},
    Circle = {"UpperTorso", "Head"},
    Bloomie = {"Head", "Torso"}
}

-- Ya sin offset (todo 0):
local AIM_OFFSETS = {
    LibraryBook = 0,
    Thavel = 0,
    Circle = 0,
    Bloomie = 0
}

-- Configuración del intervalo de búsqueda
local TARGET_UPDATE_INTERVAL = 5 -- Cuantos frames esperar entre búsquedas (5 = cada ~0.08s a 60fps)

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

-- ====== Estado Circle ======
local circleActive = false
local circleButtonConnected = false
local circleButtonReference = nil

Workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
	Camera = Workspace.CurrentCamera
end)

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
		if child and child:IsA("Model") then
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
	if not (model and priorityList) then return nil end
	for _, name in ipairs(priorityList) do
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

-- ✅ NUEVA FUNCIÓN DE APUNTADO PRECISA
local function lockCameraToTargetPart(targetPart)
	if not targetPart or not Workspace.CurrentCamera then 
		return 
	end

	-- Usa directamente la cámara actual
	local camera = Workspace.CurrentCamera
	local cameraPosition = camera.CFrame.Position

	-- Apunta exactamente al centro del part
	local targetPosition = targetPart.Position

	-- Actualiza la cámara mirando directamente al objetivo (sin offsets)
	camera.CFrame = CFrame.lookAt(cameraPosition, targetPosition)
end

-- ====== TIMER CHECK ======
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
	local ok, vis = pcall(function() return timer.Visible end)
	return ok and vis == true
end

-- ====== Circle Button ======
local function tryConnectCircleButton()
	if circleButtonConnected then return end
	circleButtonConnected = true
	spawn(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 10)
		if not pg then circleButtonConnected = false return end
		local gameUI = pg:FindFirstChild("GameUI")
		if not gameUI then circleButtonConnected = false return end
		local mobile = gameUI:FindFirstChild("Mobile")
		if not mobile then circleButtonConnected = false return end
		local altButton = mobile:FindFirstChild("Alt")
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

-- ====== Toggle PC ======
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local char = LocalPlayer and LocalPlayer.Character
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
	local char = LocalPlayer and LocalPlayer.Character
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
	local char = LocalPlayer and LocalPlayer.Character
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
	local char = LocalPlayer and LocalPlayer.Character
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
	local myModel = teachersFolder:FindFirstChild(LocalPlayer and LocalPlayer.Name or "")
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

-- ====== Elección de Target ======
local function chooseTarget(models, priorityList)
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera then return nil end
	if not models or #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local bestModel = nil
	local closestDistance = math.huge

	for _, model in ipairs(models) do
		if model and model:IsA("Model") then
			local part = getTargetPartByPriority(model, priorityList)
			if part and part.Position then
				local dir = part.Position - camPos
				local dist = dir.Magnitude
				if dist > 0 then
					local dirUnit = dir.Unit
					local dot = camLook:Dot(dirUnit)
					if dot >= ANGLE_THRESHOLD then
						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Blacklist
						rayParams.IgnoreWater = true
						rayParams.FilterDescendantsInstances = {LocalPlayer.Character or nil}

						local ok, rayResult = pcall(function()
							return Workspace:Raycast(camPos, dirUnit * dist, rayParams)
						end)
						local visible = false
						if ok then
							if not rayResult or not rayResult.Instance then
								visible = true
							elseif rayResult.Instance:IsDescendantOf(model) then
								visible = true
							end
						end
						if visible and dist < closestDistance then
							closestDistance = dist
							bestModel = model
						end
					end
				end
			end
		end
	end
	return bestModel
end

-- ======================================================
-- 🔁 LOOP PRINCIPAL
-- ======================================================
local targetUpdateCounter = 0
local currentMode = nil
local currentTarget = nil

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then 
		if currentMode == "Circle" then
			circleActive = false
			if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = 0.5 end) end
		end
		currentTarget = nil
		currentMode = nil
		return 
	end

	if currentMode then
		local conditionsMet = true
		if currentMode == "Circle" then
			if char:GetAttribute("TeacherName") ~= "Circle" or isTimerVisible() then
				conditionsMet = false
				circleActive = false
				if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = 0.5 end) end
			end
		elseif currentMode == "Thavel" then
			if char:GetAttribute("TeacherName") ~= "Thavel" or not char:GetAttribute("Charging") then
				conditionsMet = false
			end
		elseif currentMode == "LibraryBook" then
			if not hasLibraryBook(char) then
				conditionsMet = false
			end
		elseif currentMode == "Bloomie" then
			local teachersFolder = Workspace:FindFirstChild("Teachers")
			local myModel = teachersFolder and teachersFolder:FindFirstChild(LocalPlayer.Name or "")
			if not myModel or myModel:GetAttribute("TeacherName") ~= "Bloomie" or not myModel:GetAttribute("Aiming") then
				conditionsMet = false
			end
		end
		if not conditionsMet then
			currentTarget = nil
			currentMode = nil
			return
		end
	end

	targetUpdateCounter += 1
	if not currentTarget or targetUpdateCounter >= TARGET_UPDATE_INTERVAL then
		targetUpdateCounter = 0
		currentTarget = nil
		currentMode = nil

		local libTargets = getLibraryBookTargets()
		local thavelTargets = getThavelTargets()
		local circleTargets = getCircleTargets()
		local bloomTargets = getBloomieTargets()

		if #libTargets > 0 then
			currentTarget = chooseTarget(libTargets, AIM_PARTS.LibraryBook)
			currentMode = "LibraryBook"
		elseif #thavelTargets > 0 then
			currentTarget = chooseTarget(thavelTargets, AIM_PARTS.Thavel)
			currentMode = "Thavel"
		elseif #circleTargets > 0 then
			currentTarget = chooseTarget(circleTargets, AIM_PARTS.Circle)
			currentMode = "Circle"
		elseif #bloomTargets > 0 then
			currentTarget = chooseTarget(bloomTargets, AIM_PARTS.Bloomie)
			currentMode = "Bloomie"
		end
	end

	if currentTarget and currentMode then
		local targetParts = AIM_PARTS[currentMode]
		local targetPart = getTargetPartByPriority(currentTarget, targetParts)
		if targetPart then
			lockCameraToTargetPart(targetPart)
		else
			currentTarget = nil
			currentMode = nil
		end
	end
end)
