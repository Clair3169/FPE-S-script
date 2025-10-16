-- =====================================================
-- 🎯 Aimbot combinado (LibraryBook / Thavel / Circle / Bloomie)
-- - Mejora: Line of Sight robusta + comprobaciones nil + actualización de Camera
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
local Camera = Workspace.CurrentCamera -- referencia inicial
local currentTarget = nil

-- ====== Estado Circle (toggle) ======
local circleActive = false
local circleButtonConnected = false
local circleButtonReference = nil

-- ====== Mantener Camera actualizada (en caso de recarga o cambios) ======
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
		-- FindFirstChild(name, true) válido en Roblox
		local part = model:FindFirstChild(name, true)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function lockCameraToTargetPart(targetPart, offset)
	if not targetPart then return end
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera then return end

	local camPos = Camera.CFrame.Position
	local targetPos = targetPart.Position + (offset or Vector3.new(0,0,0))
	-- Mantener la misma posición de cámara, orientar hacia targetPos
	Camera.CFrame = CFrame.lookAt(camPos, targetPos)
end

-- ====== TIMER CHECK (GameUI>Mobile>Alt>Timer) ======
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

-- ====== Circle Button (GameUI>Mobile>Alt) ======
local function tryConnectCircleButton()
	if circleButtonConnected then return end
	circleButtonConnected = true

	spawn(function()
		-- Usar WaitForChild sin timeout para mayor robustez
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

		-- Conectar con protección pcall
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

-- ====== Elección de Target con Line of Sight robusta ======
local function chooseTarget(models, priorityList)
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera then return nil end
	if not models or #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local bestModel = nil
	local bestDot = -1

	for _, model in ipairs(models) do
		if not (model and model:IsA("Model")) then
			-- ignorar
		else
			local part = getTargetPartByPriority(model, priorityList)
			if part and part.Position then
				local dir = part.Position - camPos
				local dist = dir.Magnitude
				if dist > 0 then
					-- Preparar RaycastParams
					local rayParams = RaycastParams.new()
					rayParams.FilterType = Enum.RaycastFilterType.Blacklist
					-- Siempre asegurarse que es una tabla (evitar nil)
					if LocalPlayer and LocalPlayer.Character then
						rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
					else
						rayParams.FilterDescendantsInstances = {}
					end
					rayParams.IgnoreWater = true

					-- Ejecutar raycast sólo hasta la distancia entre cámara y parte objetivo
					local ok, rayResult = pcall(function()
						return Workspace:Raycast(camPos, dir.Unit * dist, rayParams)
					end)

					-- Si pcall fallo, tratar como bloqueado para seguridad
					local blocked = true
					if ok then
						-- Si no hubo impacto => no bloqueado
						if not rayResult or not rayResult.Instance then
							blocked = false
						else
							-- Si el impacto es descendiente del modelo objetivo => no bloqueado
							if rayResult.Instance:IsDescendantOf(model) then
								blocked = false
							else
								blocked = true
							end
						end
					end

					if not blocked then
						local dirUnit = dir.Unit
						local dot = camLook:Dot(dirUnit)
						if dot > bestDot then
							bestDot = dot
							bestModel = model
						end
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

-- ====== LOOP PRINCIPAL ======
RunService.RenderStepped:Connect(function()
	-- Asegurarse que los servicios y camera estén listos
	if not LocalPlayer then return end
	local char = LocalPlayer.Character
	if not char then
		currentTarget = nil
		return
	end

	-- Mantener Camera actualizada si estaba a nil
	if not Camera then
		Camera = Workspace.CurrentCamera
		if not Camera then return end
	end

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
