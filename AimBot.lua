-- =====================================================
-- 🎯 Aimbot combinado optimizado (LibraryBook / Thavel / Circle / Bloomie)
-- Actualización inmediata por frame y micro-optimización para FPS
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
local currentTarget = nil
local currentMode = nil
local circleActive = false

-- Reutilizar RaycastParams para evitar asignaciones por cada comprobación
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Blacklist

-- Cache de carpetas (puede actualizarse si falta alguna)
local function getFolder(name) return Workspace:FindFirstChild(name) end

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

-- Obtiene la parte objetivo, revisando prioridades
local function getTargetPartByPriority(model, priorityList)
    for _, name in ipairs(priorityList) do
        -- Primero intento directo (no recursivo) para ser más rápido
        local part = model:FindFirstChild(name)
        if part and part:IsA("BasePart") then
            return part
        end
        -- Si no existe, chequeo recursivo como fallback (más lento)
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
    local camPos = cam.CFrame.Position
    cam.CFrame = CFrame.lookAt(camPos, targetPart.Position)
end

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
    return timer.Visible
end

-- =====================================================
-- 🧠 MODOS (LibraryBook / Thavel / Bloomie / Circle)
-- =====================================================

local function getLibraryBookTargets()
    local models = {}
    local char = LocalPlayer.Character
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
    local char = LocalPlayer.Character
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
    local char = LocalPlayer.Character
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
    local myModel = teachers:FindFirstChild(LocalPlayer.Name)
    if myModel and myModel:GetAttribute("TeacherName") == "Bloomie" and myModel:GetAttribute("Aiming") == true then
        for _, m in ipairs(getModelsFromFolders({"Students", "Alices"})) do
            if m ~= myModel and (m:FindFirstChild("Head") or m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso")) then
                table.insert(models, m)
            end
        end
    end
    return models
end

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
    rayParams.FilterDescendantsInstances = { LocalPlayer.Character }

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
-- 🔁 LOOP PRINCIPAL (actualiza e intenta apuntar cada frame)
-- =====================================================

RunService.RenderStepped:Connect(function()
    local char = LocalPlayer.Character
    if not char then return end

-- 💤 Reposo total hasta que se cumpla algún modo
local function hasAnyModeActive()
	local char = LocalPlayer.Character
	if not char then return false end
	return (
		(#getLibraryBookTargets() > 0)
		or (#getThavelTargets() > 0)
		or (#getCircleTargets() > 0)
		or (#getBloomieTargets() > 0)
	)
end

-- Si no hay ningún modo activo, el script se "duerme" hasta que algo cambie
if not hasAnyModeActive() then
	local awakened = false
	local char = LocalPlayer.Character

	-- Crea conexiones temporales que "despiertan" al script
	local conns = {}

	local function wake()
		awakened = true
		for _, c in ipairs(conns) do
			if c and c.Disconnect then c:Disconnect() end
		end
		conns = {}
	end

	-- Escucha cambios de atributos y herramientas del personaje
	if char then
		table.insert(conns, char.AttributeChanged:Connect(wake))
		table.insert(conns, char.ChildAdded:Connect(wake))
		table.insert(conns, char.ChildRemoved:Connect(wake))
	end

	-- Espera dormido hasta que se cumpla una condición o se despierte por evento
	repeat task.wait() until awakened or hasAnyModeActive()
		end

    -- reset relativo y selección inmediata cada frame
    currentTarget, currentMode = nil, nil

    -- recolectar candidatos por prioridad de modo
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

    if currentTarget and currentMode then
        local part = getTargetPartByPriority(currentTarget, AIM_PARTS[currentMode])
        if part then
            lockCameraToTargetPart(part)
        else
            currentTarget, currentMode = nil, nil
        end
    end
end)
