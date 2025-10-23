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

-- También puedes personalizar los offsets verticales para cada modo:
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
	-- Obtenemos el personaje del jugador y su cabeza. Si no existen, no hacemos nada.
	local character = LocalPlayer.Character
	local head = character and character:FindFirstChild("Head")
	
	if not targetPart or not Workspace.CurrentCamera or not head then 
		return 
	end

	-- 1. Calculamos la posición final del objetivo (esto ya lo tenías bien)
	local targetCenterPosition = targetPart.Position
	local verticalOffset = Vector3.new(0, (type(offset) == "number" and offset) or 0, 0)
	local finalTargetPosition = targetCenterPosition + verticalOffset

	-- 2. Calculamos la nueva POSICIÓN de la cámara para que siga al jugador
	-- Mantenemos la distancia de zoom actual que el jugador tiene con su personaje.
	local currentZoomDistance = (Workspace.CurrentCamera.CFrame.Position - head.Position).Magnitude
	
	-- Calculamos la dirección desde el objetivo hacia la cabeza de nuestro jugador.
	local directionFromTargetToHead = (head.Position - finalTargetPosition).Unit
	
	-- La nueva posición de la cámara será detrás de la cabeza del jugador, a la distancia de zoom actual.
	local newCameraPosition = head.Position + (directionFromTargetToHead * currentZoomDistance)

	-- 3. Actualizamos la cámara para que esté en la nueva posición y apunte al objetivo.
	Workspace.CurrentCamera.CFrame = CFrame.lookAt(newCameraPosition, finalTargetPosition)
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
	local closestDistance = math.huge -- distancia más corta encontrada

	for _, model in ipairs(models) do
		if model and model:IsA("Model") then
			local part = getTargetPartByPriority(model, priorityList)
			if part and part.Position then
				local dir = part.Position - camPos
				local dist = dir.Magnitude
				if dist > 0 then
					-- Calcular ángulo (dot product)
					local dirUnit = dir.Unit
					local dot = camLook:Dot(dirUnit)

					-- Solo considerar si está dentro del campo de visión permitido
					if dot >= ANGLE_THRESHOLD then
						
						-- ======= 🌐 Verificación de visibilidad (Line of Sight) =======
						local rayParams = RaycastParams.new()
						rayParams.FilterType = Enum.RaycastFilterType.Blacklist
						rayParams.IgnoreWater = true
						if LocalPlayer and LocalPlayer.Character then
							rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
						else
							rayParams.FilterDescendantsInstances = {}
						end

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
						-- ============================================================

						-- Si el objetivo está visible y más cercano, actualizar
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
-- 🔁 LOOP PRINCIPAL (VERSIÓN FINAL CON MÁXIMA SEGURIDAD)
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

	-- =================================================================
	-- 🛡️ SUPERBLOQUE DE SEGURIDAD PARA TODOS LOS MODOS 🛡️
	-- Se ejecuta en cada frame para una desactivación instantánea.
	-- =================================================================
	if currentMode then
		local conditionsMet = true -- Asumimos que todo está bien al principio

		if currentMode == "Circle" then
			if char:GetAttribute("TeacherName") ~= "Circle" or isTimerVisible() then
				conditionsMet = false
				circleActive = false -- Específico de Circle
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

		-- Si alguna condición falló, limpiamos y salimos.
		if not conditionsMet then
			currentTarget = nil
			currentMode = nil
			return
		end
	end
	-- =================================================================

	targetUpdateCounter += 1

	-- ======= Buscar objetivo cada cierto número de frames =======
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

	-- ======= Apuntar (en todos los frames) =======
	if currentTarget and currentMode then
		local targetParts = AIM_PARTS[currentMode]
		local targetPart = getTargetPartByPriority(currentTarget, targetParts)
		if targetPart then
			local offset = AIM_OFFSETS[currentMode] or 2.5
			lockCameraToTargetPart(targetPart, offset)
		else
			currentTarget = nil
			currentMode = nil
		end
	end
end)
