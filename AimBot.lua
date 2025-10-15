-- =====================================================
-- 🎯 Aimbot combinado (LibraryBook / Thavel / Circle / Bloomie)
--    - Ahora cada modo acepta múltiples carpetas de blancos (arrays)
--    - Circle: toggle Mobile->Alt ImageButton OR Right-Click (PC)
--    - Timer bloquea Circle mientras esté visible
-- =====================================================

repeat task.wait() until game:IsLoaded()

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

-- ====== CONFIG (ahora con arrays para carpetas) ======
local LIBRARY_TARGET_FOLDERS = {"Teachers", "Alices"}   -- LibraryBook targets (agrega aquí más: "Momos", etc.)
local THAVEL_TARGET_FOLDERS  = {"Students", "Alices"}            -- Thavel targets (ej: {"Students","Momos"})
local CIRCLE_TARGET_FOLDERS  = {"Students", "Alices"}            -- Circle targets (ej: {"Students","Momos"})
local BLOOMIE_TARGET_FOLDERS = {"Students", "Alices"}            -- Bloomie targets

-- Prioridades de partes
local TARGET_PRIORITY_TORSO = {"UpperTorso", "Torso", "HumanoidRootPart", "Head"} -- torso-first
local TARGET_PRIORITY_HEAD  = {"Head", "UpperTorso", "HumanoidRootPart"}           -- head-first

-- Sensibilidad del ángulo y offsets
local ANGLE_THRESHOLD = 0.85
local CAMERA_HEIGHT_OFFSET_TORSO = Vector3.new(0, 0, 0)
local CAMERA_HEIGHT_OFFSET_HEAD  = Vector3.new(0, 0.3, 0)

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local currentTarget = nil

-- ====== Estado Circle (toggle) ======
local circleActive = false
local circleButtonConnected = false
local circleButtonReference = nil -- guardamos referencia si existe

-- ====== UTILIDADES ======

-- Chequea si el character contiene la Tool "LibraryBook"
local function hasLibraryBook(character)
	if not character then return false end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Tool") and obj.Name == "LibraryBook" then
			return true
		end
	end
	return false
end

-- Devuelve lista de modelos desde una carpeta (si existe)
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

-- Devuelve lista de modelos desde varias carpetas (array de nombres)
local function getModelsFromFolders(folderList)
	local models = {}
	for _, folderName in ipairs(folderList) do
		for _, m in ipairs(getModelsFromFolder(folderName)) do
			table.insert(models, m)
		end
	end
	return models
end

-- retorna la primera parte válida según prioridad
local function getTargetPartByPriority(model, priorityList)
	for _, name in ipairs(priorityList) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

-- Selección por dot product (común)
local function chooseTarget(models, priorityList)
	if #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local bestModel = nil
	local bestDot = -1

	for _, model in ipairs(models) do
		-- evitar apuntar a modelos inválidos
		if model and model:IsA("Model") and model ~= LocalPlayer.Character then
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

	return currentTarget
end

local function lockCameraToTargetPart(targetPart, offset)
	if not targetPart then return end
	local camPos = Camera.CFrame.Position
	local targetPos = targetPart.Position + (offset or Vector3.new(0, 0, 0))
	Camera.CFrame = CFrame.lookAt(camPos, targetPos)
end

-- ====== MODOS DE BLANCO (AHORA CON MULTIPLES CARPETAS) ======

-- LibraryBook mode: si estás en Students y tienes LibraryBook -> targets = LIBRARY_TARGET_FOLDERS
local function getLibraryBookTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end

	local inStudents = char.Parent and char.Parent.Name == "Students"
	local hasBook = hasLibraryBook(char)

	if inStudents and hasBook then
		-- obtener modelos de todas las carpetas listadas
		local folderModels = getModelsFromFolders(LIBRARY_TARGET_FOLDERS)
		for _, m in ipairs(folderModels) do
			if m ~= char and m:FindFirstChild("Head") then
				table.insert(models, m)
			end
		end
	end

	return models
end

-- Thavel mode: TeacherName == "Thavel" and Charging == true -> targets = THAVEL_TARGET_FOLDERS
local function getThavelTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end

	local teacherAttr = char:GetAttribute("TeacherName")
	local chargingAttr = char:GetAttribute("Charging")

	if teacherAttr == "Thavel" and chargingAttr == true then
		local folderModels = getModelsFromFolders(THAVEL_TARGET_FOLDERS)
		for _, m in ipairs(folderModels) do
			if m ~= char and m:FindFirstChild("Head") then
				table.insert(models, m)
			end
		end
	end

	return models
end

-- Circle mode: TeacherName == "Circle" AND circleActive == true -> targets = CIRCLE_TARGET_FOLDERS
local function getCircleTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end

	local teacherAttr = char:GetAttribute("TeacherName")
	if teacherAttr == "Circle" and circleActive == true then
		local folderModels = getModelsFromFolders(CIRCLE_TARGET_FOLDERS)
		for _, m in ipairs(folderModels) do
			if m ~= char and m:FindFirstChild("Head") then
				table.insert(models, m)
			end
		end
	end

	return models
end

-- Bloomie mode: TeacherName == "Bloomie" and Aiming == true -> targets = BLOOMIE_TARGET_FOLDERS
local function getBloomieTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end

	local teacherAttr = char:GetAttribute("TeacherName")
	local aimingAttr = char:GetAttribute("Aiming")

	if teacherAttr == "Bloomie" and aimingAttr == true then
		local folderModels = getModelsFromFolders(BLOOMIE_TARGET_FOLDERS)
		for _, m in ipairs(folderModels) do
			if m ~= char and m:FindFirstChild("Head") then
				table.insert(models, m)
			end
		end
	end

	return models
end

-- ====== TIMER CHECK (varias rutas) ======
-- Devuelve true si encuentra un TextLabel "Timer" y su Visible == true
local function isTimerVisible()
	local pg = LocalPlayer:FindFirstChild("PlayerGui")
	if not pg then return false end

	local paths = {
		{"GameUI", "Mobile", "Alt", "Timer"},
		{"GameUI", "Mobile", "Timer"},
		{"GameUI", "Desktop", "Alt", "Timer"},
		{"GameUI", "Desktop", "Timer"},
		{"GameUI", "Timer"},
	}

	for _, path in ipairs(paths) do
		local current = pg
		local found = true
		for _, name in ipairs(path) do
			current = current:FindFirstChild(name)
			if not current then
				found = false
				break
			end
		end
		if found and current and current:IsA("TextLabel") then
			local ok, vis = pcall(function() return current.Visible end)
			if ok and vis == true then
				return true
			end
		end
	end

	return false
end

-- ====== Conexión segura al ImageButton (Mobile->Alt) para controlar circleActive ======
local function tryConnectCircleButton()
	if circleButtonConnected then return end -- ya conectado o intentando
	circleButtonConnected = true

	spawn(function()
		local pg = LocalPlayer:WaitForChild("PlayerGui", 5)
		if not pg then
			circleButtonConnected = false
			return
		end

		local gameUI = pg:FindFirstChild("GameUI") or pg:WaitForChild("GameUI", 5)
		if not gameUI then
			circleButtonConnected = false
			return
		end

		-- buscar Mobile -> Alt
		local mobile = gameUI:FindFirstChild("Mobile")
		if not mobile then
			mobile = gameUI:WaitForChild("Mobile", 5)
			if not mobile then
				circleButtonConnected = false
				return
			end
		end

		local altButton = mobile:FindFirstChild("Alt") or mobile:WaitForChild("Alt", 5)
		if not altButton then
			circleButtonConnected = false
			return
		end

		if not altButton:IsA("ImageButton") then
			circleButtonConnected = false
			return
		end

		circleButtonReference = altButton

		altButton.Activated:Connect(function()
			-- antes de alternar, comprobar Timer: si Timer visible -> no permitir toggle (y asegurar desactivado)
			if isTimerVisible() then
				circleActive = false
				currentTarget = nil
				pcall(function() altButton.ImageTransparency = 0.5 end)
				return
			end

			-- alternar
			circleActive = not circleActive
			if not circleActive then currentTarget = nil end

			-- feedback visual (opcional)
			pcall(function()
				altButton.ImageTransparency = circleActive and 0 or 0.5
			end)
		end)
	end)
end

-- iniciar intento de conexión al botón y reintentos periódicos
tryConnectCircleButton()
spawn(function()
	while true do
		if not circleButtonConnected then
			tryConnectCircleButton()
		end
		task.wait(3)
	end
end)

-- ====== Toggle por click derecho (PC) ======
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		local char = LocalPlayer.Character
		if not char then return end
		local teacherAttr = char:GetAttribute("TeacherName")
		if teacherAttr ~= "Circle" then return end

		-- si Timer visible -> forzar desactivado y no permitir toggle
		if isTimerVisible() then
			circleActive = false
			currentTarget = nil
			if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = 0.5 end) end
			return
		end

		-- alternar
		circleActive = not circleActive
		if not circleActive then currentTarget = nil end
		if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = circleActive and 0 or 0.5 end) end
	end
end)

-- ====== LOOP PRINCIPAL ======
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end

	-- Si Timer aparece visible en cualquier momento: desactivar circle automáticamente
	if isTimerVisible() and circleActive then
		circleActive = false
		currentTarget = nil
		if circleButtonReference then pcall(function() circleButtonReference.ImageTransparency = 0.5 end) end
	end

	-- 1) LibraryBook mode (prioridad alta)
	local libTargets = getLibraryBookTargets()
	if #libTargets > 0 then
		currentTarget = chooseTarget(libTargets, TARGET_PRIORITY_TORSO)
		if currentTarget then
			local targetPart = getTargetPartByPriority(currentTarget, TARGET_PRIORITY_TORSO)
			if targetPart then
				lockCameraToTargetPart(targetPart, CAMERA_HEIGHT_OFFSET_TORSO)
			end
		end
		return
	end

	-- 2) Thavel mode (siguiente prioridad)
	local thavelTargets = getThavelTargets()
	if #thavelTargets > 0 then
		currentTarget = chooseTarget(thavelTargets, TARGET_PRIORITY_TORSO)
		if currentTarget then
			local targetPart = getTargetPartByPriority(currentTarget, TARGET_PRIORITY_TORSO)
			if targetPart then
				lockCameraToTargetPart(targetPart, CAMERA_HEIGHT_OFFSET_TORSO)
			end
		end
		return
	end

	-- 3) Circle mode (toggle por botón o click derecho) -> solo si circleActive y Timer no visible
	if circleActive and not isTimerVisible() then
		local circleTargets = getCircleTargets()
		if #circleTargets > 0 then
			currentTarget = chooseTarget(circleTargets, TARGET_PRIORITY_TORSO)
			if currentTarget then
				local targetPart = getTargetPartByPriority(currentTarget, TARGET_PRIORITY_TORSO)
				if targetPart then
					lockCameraToTargetPart(targetPart, CAMERA_HEIGHT_OFFSET_TORSO)
				end
			end
		end
		return
	end

	-- 4) Bloomie mode (última prioridad)
	local bloomTargets = getBloomieTargets()
	if #bloomTargets > 0 then
		currentTarget = chooseTarget(bloomTargets, TARGET_PRIORITY_HEAD)
		if currentTarget then
			local targetPart = getTargetPartByPriority(currentTarget, TARGET_PRIORITY_HEAD)
			if targetPart then
				lockCameraToTargetPart(targetPart, CAMERA_HEIGHT_OFFSET_HEAD)
			end
		end
		return
	end

	-- Ningún modo activo
	currentTarget = nil
end)
