-- =====================================================
-- 🎯 Aimbot combinado optimizado (LibraryBook / Thavel / Circle / Bloomie)
-- Activación/desactivación completa y apuntado al centro del objetivo
-- =====================================================

local AIM_PARTS = {
	LibraryBook = {"HumanoidRootPart", "Torso", "UpperTorso"},
	Thavel = {"UpperTorso", "Torso"},
	Circle = {"UpperTorso", "Head"},
	Bloomie = {"Head", "Torso"}
}

-- Máximo en studs para considerar un objetivo (ajusta si quieres más alcance)
local MAX_TARGET_DISTANCE = 150

repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local circleActive = false
-- 📷 Control interno de la cámara del aimbot
local cameraOverridden = false
local prevCameraType = nil
local prevCameraSubject = nil
local prevCameraCFrame = nil
local camOffset = nil -- offset entre cámara y jugador para mantener seguimiento

-- Reutilizar RaycastParams para evitar asignaciones por cada comprobación
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

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



-- Obtiene la parte objetivo, revisando prioridades (intento directo + fallback recursivo)
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

-- 📸 Toma control de la cámara y calcula el offset respecto al jugador
local function overrideCamera()
	if not Workspace.CurrentCamera or cameraOverridden then return end
	local cam = Workspace.CurrentCamera
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end

	-- Guardar estado anterior
	prevCameraType = cam.CameraType
	prevCameraSubject = cam.CameraSubject
	prevCameraCFrame = cam.CFrame

	-- Buscar parte base del personaje
	local root = char:FindFirstChild("HumanoidRootPart") 
		or char:FindFirstChild("UpperTorso") 
		or char:FindFirstChild("Torso") 
		or char:FindFirstChild("Head")
	if not root then return end

	-- Calcular distancia actual entre cámara y jugador
	camOffset = cam.CFrame.Position - root.Position

	-- Poner la cámara en modo scriptable (ningún otro script podrá moverla)
	pcall(function()
		cam.CameraType = Enum.CameraType.Scriptable
	end)

	cameraOverridden = true
end

-- 🔁 Devuelve el control de la cámara al juego cuando terminas de apuntar
local function restoreCamera()
	local cam = Workspace.CurrentCamera
	if not cam or not cameraOverridden then return end

	pcall(function()
		if prevCameraType then
			cam.CameraType = prevCameraType
		end
		if prevCameraSubject then
			cam.CameraSubject = prevCameraSubject
		end
	end)

	-- (No restauramos el CFrame exacto para evitar "saltos bruscos")

	cameraOverridden = false
	prevCameraType = nil
	prevCameraSubject = nil
	prevCameraCFrame = nil
	camOffset = nil
end

-- 🎯 Fija la cámara mirando al objetivo sin romper el movimiento del jugador
local function lockCameraToTargetPart(targetPart)
	if not targetPart or not Workspace.CurrentCamera then return end
	local cam = Workspace.CurrentCamera
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end

	-- Asegurar que la cámara está bajo nuestro control
	if not cameraOverridden or not camOffset then
		overrideCamera()
		if not camOffset then return end
	end

	-- Buscar parte base del jugador
	local root = char:FindFirstChild("HumanoidRootPart") 
		or char:FindFirstChild("UpperTorso") 
		or char:FindFirstChild("Torso") 
		or char:FindFirstChild("Head")
	if not root then return end

	-- La cámara sigue la posición del jugador manteniendo la misma distancia
	local camPos = root.Position + camOffset

	-- Apunta hacia el objetivo (centro del target)
	local newCFrame = CFrame.lookAt(camPos, targetPart.Position)

	pcall(function()
		cam.CFrame = newCFrame
	end)
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

-- =====================================================
-- 🧠 MODOS (LibraryBook / Thavel / Bloomie / Circle)
-- =====================================================
-- (Todo el código de getLibraryBookTargets, getThavelTargets, bindCircleDetection, etc. va aquí)
-- (Es idéntico al script anterior, no es necesario copiarlo si solo cambias la función de cámara)
-- ...
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

	-- Detectar cambios en atributos del Character (TeacherName)
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
-- ... (Fin de la sección de modos)


-- =====================================================
-- 🎯 SELECCIÓN DE OBJETIVO (optimizada)
-- =====================================================

local function chooseTarget(models, parts)
	if not Camera then Camera = Workspace.CurrentCamera end
	if not Camera or #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local best = nil
	local bestDist = math.huge

	-- Actualizar filtro de raycast para ignorar al jugador local
	if LocalPlayer.Character then
		rayParams.FilterDescendantsInstances = { LocalPlayer.Character }
	else
		rayParams.FilterDescendantsInstances = {}
	end


	for _, model in ipairs(models) do
		-- obtener la parte prioritaria
		local part = getTargetPartByPriority(model, parts)
		if part and part.Position then
			local dir = part.Position - camPos
			local dist = dir.Magnitude
			if dist > 0 and dist <= MAX_TARGET_DISTANCE and dist < bestDist then
				local dot = camLook:Dot(dir.Unit)
				-- Sólo considerar si está razonablemente en frente
				if dot > 0.6 then
					-- Raycast para comprobar visibilidad (usa rayParams reutilizable)
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

-- =====================================================
-- 🧠 Activación / desactivación total del Aimbot (BindToRenderStep)
-- =====================================================

local isAimbotRunning = false
local AIMBOT_RENDER_NAME = "CustomAimbotLoop" -- Nombre para el loop de RenderStepped
local activationConns = {}

-- Comprueba si el jugador cumple algún requisito de modo
local function isEligible()
	local char = LocalPlayer and LocalPlayer.Character
	if not char then return false end

	local teacher = char:GetAttribute("TeacherName")
	local hasBook = hasLibraryBook(char)
	local humanoid = char:FindFirstChild("Humanoid")
	local sprintLock = humanoid and humanoid:FindFirstChild("SprintLock")
	
	-- Comprobación rápida de condiciones
	local isLibrary = (char.Parent and char.Parent.Name == "Students" and hasBook)
	local isThavel = (teacher == "Thavel" and char:GetAttribute("Charging") == true)
	local isCircle = (teacher == "Circle" and sprintLock and not isTimerVisible())
	local isBloomie = (teacher == "Bloomie" and char:GetAttribute("Aiming") == true)
	
	if (isLibrary or isThavel or isCircle or isBloomie) then
		return true
	end
	return false
end

-- Función principal del Aimbot (loop por frame mientras está activo)
local function aimbotUpdateFunction()
	if not isEligible() then
		-- Si no somos elegibles, paramos el loop
		RunService:UnbindFromRenderStep(AIMBOT_RENDER_NAME)
		isAimbotRunning = false
		return
	end

	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end

	-- PRE-FILTER RÁPIDO: si claramente no cumples condiciones internas, evitar recolectar modelos
	-- (Re-usamos isEligible que ya hace esto, pero verificamos rápido de nuevo)
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

-- Inicia el loop del Aimbot
local function runAimbot()
	if isAimbotRunning then return end -- Ya está corriendo
	isAimbotRunning = true
	
	-- Bindeamos la función para que se ejecute DESPUÉS de la cámara
	-- Usa .Last.Value (2000) para máxima prioridad
	local camPriority = Enum.RenderPriority.Last.Value
	RunService:BindToRenderStep(AIMBOT_RENDER_NAME, camPriority, aimbotUpdateFunction)
end

local function stopAimbot()
	if not isAimbotRunning then return end
	pcall(function()
		RunService:UnbindFromRenderStep(AIMBOT_RENDER_NAME)
	end)
	isAimbotRunning = false

	-- ✅ Restaurar cámara al terminar
	restoreCamera()
end

-- Limpia conexiones de activación automáticas
local function clearActivationConns()
	for _, c in ipairs(activationConns) do
		if c and c.Disconnect then
			c:Disconnect()
		end
	end
	activationConns = {}
end

-- =====================================================
-- 🎧 Sistema de escucha (enciende el aimbot cuando cumple requisitos)
-- =====================================================

local function bindAutoActivation()
	-- limpiar conexiones previas (si las hay)
	clearActivationConns()

	local function checkAndRun()
		-- Esta función ahora es más simple:
		-- Si somos elegibles y el loop no corre, iniciarlo.
		-- La propia función 'aimbotUpdateFunction' se parará sola si dejamos de ser elegibles.
		if not isAimbotRunning and isEligible() then
			runAimbot()
		end
	end

	local char = LocalPlayer and LocalPlayer.Character
	if not char then return end

	-- Escuchar varios cambios que puedan activar el modo: atributos relevantes y cambios del Character
	table.insert(activationConns, char:GetAttributeChangedSignal("TeacherName"):Connect(checkAndRun))
	table.insert(activationConns, char:GetAttributeChangedSignal("Charging"):Connect(checkAndRun))
	table.insert(activationConns, char:GetAttributeChangedSignal("Aiming"):Connect(checkAndRun))

	-- ChildAdded/Removed despiertan (herramientas, SprintLock, etc.)
	table.insert(activationConns, char.ChildAdded:Connect(checkAndRun))
	table.insert(activationConns, char.ChildRemoved:Connect(checkAndRun))

	-- Si hay Humanoid, escuchar cambios internos por si aparece SprintLock
	local humanoid = char:FindFirstChild("Humanoid")
	if humanoid then
		table.insert(activationConns, humanoid.ChildAdded:Connect(checkAndRun))
		table.insert(activationConns, humanoid.ChildRemoved:Connect(checkAndRun))
	end

	-- Escuchar también cambios en el Timer
	local pg = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if pg then
		local timer = pg:FindFirstChild("GameUI.Mobile.Alt.Timer", true)
		if timer then
			table.insert(activationConns, timer:GetPropertyChangedSignal("Visible"):Connect(checkAndRun))
		end
	end

	-- Lanzamiento inicial
	checkAndRun()
end

-- Inicialización
if LocalPlayer.Character then
	bindAutoActivation()
end

LocalPlayer.CharacterAdded:Connect(function(char)
	-- esperar un pelín a que se creen atributos y humanoid
	task.wait(0.5)
	bindAutoActivation()
	-- Asegurarse de re-bindear la detección de Circle
	bindCircleDetection(char)
end)

LocalPlayer.CharacterRemoving:Connect(function()
	-- Desconectar aimbot si está corriendo y limpiar listeners
	stopAimbot()
	clearActivationConns()
	-- Limpiar también las conexiones de Circle
	clearCharConnections()
	circleActive = false
end)

-- FIN
