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

-- Apunta la cámara de manera que el centro del target quede centrado en el crosshair
-- Ignora offsets laterales: apuntado directo al centro del objetivo
local function lockCameraToTargetPart(targetPart)
    if not targetPart or not Workspace.CurrentCamera then return end
    local cam = Workspace.CurrentCamera
    local char = LocalPlayer and LocalPlayer.Character
    if not char then
        -- fallback si no hay character: apuntar desde la cámara hacia la parte
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
        return
    end

    -- Intentamos usar HumanoidRootPart como referencia del jugador; si no, Head
    local root = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("Head")
    if not root then
        cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPart.Position)
        return
    end

    -- Calculamos la posición exacta del centro del target.
    -- Tomamos la posición del part y compensamos ligeramente para centrar verticalmente.
    local targetPos = targetPart.Position
    if targetPart:IsA("BasePart") then
        -- Ajuste vertical para acercarnos al centro del torso/cabeza
        targetPos = targetPos + Vector3.new(0, targetPart.Size.Y * 0.0, 0)
    end

    -- Forzamos la cámara a mirar exactamente al centro del target.
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
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
-- 🧠 Activación / desactivación total del Aimbot
-- =====================================================

local aimbotConnection = nil
local activationConns = {}

-- Comprueba si el jugador cumple algún requisito de modo
local function isEligible()
    local char = LocalPlayer and LocalPlayer.Character
    if not char then return false end

    local teacher = char:GetAttribute("TeacherName")
    local hasBook = hasLibraryBook(char)
    local humanoid = char:FindFirstChild("Humanoid")
    local sprintLock = humanoid and humanoid:FindFirstChild("SprintLock")

    if (char.Parent and char.Parent.Name == "Students" and hasBook) then
        return true
    elseif (teacher == "Thavel" and char:GetAttribute("Charging") == true) then
        return true
    elseif (teacher == "Circle" and sprintLock) then
        return true
    elseif (teacher == "Bloomie" and char:GetAttribute("Aiming") == true) then
        return true
    end
    return false
end

-- Función principal del Aimbot (loop por frame mientras está activo)
local function runAimbot()
    if aimbotConnection then aimbotConnection:Disconnect() end

    aimbotConnection = RunService.RenderStepped:Connect(function()
        if not isEligible() then
            if aimbotConnection then
                aimbotConnection:Disconnect()
                aimbotConnection = nil
            end
            return
        end

        local char = LocalPlayer and LocalPlayer.Character
        if not char then return end

        -- PRE-FILTER RÁPIDO: si claramente no cumples condiciones internas, evitar recolectar modelos
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
    end)
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
        if not aimbotConnection and isEligible() then
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
end)

LocalPlayer.CharacterRemoving:Connect(function()
    -- Desconectar aimbot si está corriendo y limpiar listeners
    if aimbotConnection then
        aimbotConnection:Disconnect()
        aimbotConnection = nil
    end
    clearActivationConns()
end)

-- FIN
