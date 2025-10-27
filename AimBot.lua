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

-- Apunta la cámara exactamente al centro del target (independiente de shiftlock / offsets)
local function lockCameraToTargetPart(targetPart)
    if not targetPart or not Workspace.CurrentCamera then return end
    if not LocalPlayer or not LocalPlayer.Character then return end

    local cam = Workspace.CurrentCamera

    -- Calcula el centro del target (ajusta si quieres más/menos offset vertical)
    local targetPos = targetPart.Position
    -- Si la parte tiene tamaño, centra un poco verticalmente (opcional)
    if targetPart:IsA("BasePart") then
        targetPos = targetPos + Vector3.new(0, targetPart.Size.Y * 0.0, 0)
    end

    -- Forzamos la cámara a mirar exactamente al centro del objetivo (desde la cámara actual)
    cam.CFrame = CFrame.lookAt(cam.CFrame.Position, targetPos)
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

    if not char then return end

    -- Detectar cambios en atributos del Character
    pcall(function()
        table.insert(charConnections, char:GetAttributeChangedSignal("TeacherName"):Connect(function()
            circleActive = checkCircleConditions(char)
        end))
    end)

    -- Detectar si el Character cambia de carpeta (Teachers u otra)
    local ok, parentConn = pcall(function()
        return char:GetPropertyChangedSignal("Parent"):Connect(function()
            circleActive = checkCircleConditions(char)
        end)
    end)
    if ok and parentConn then table.insert(charConnections, parentConn) end

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
-- 🔁 CONTROL DE ACTIVACIÓN / DESACTIVACIÓN TOTAL DEL AIMBOT
-- =====================================================

local aimbotConnection = nil
local activationConns = {}

-- Comprueba si el jugador cumple algún requisito de modo
local function isEligible()
    local char = LocalPlayer.Character
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

-- Función principal del Aimbot (loop por frame)
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

        local char = LocalPlayer.Character
        if not char then return end

        -- Optimización: chequeo rápido de atributos para evitar cálculos innecesarios
        local teacher = char:GetAttribute("TeacherName")
        local hasBook = hasLibraryBook(char)
        local humanoid = char:FindFirstChild("Humanoid")
        local sprintLock = humanoid and humanoid:FindFirstChild("SprintLock")

        -- Si claramente no cumple modos, salimos rápido (esto reduce trabajo cerca de muchos players)
        if not (hasBook or (teacher == "Thavel" and char:GetAttribute("Charging") == true) or (teacher == "Circle" and sprintLock) or (teacher == "Bloomie" and char:GetAttribute("Aiming") == true)) then
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

-- =====================================================
-- 🎧 Sistema de escucha (enciende el aimbot cuando cumple requisitos)
-- =====================================================

local function clearActivationConns()
    for _, c in ipairs(activationConns) do
        if c and c.Disconnect then
            pcall(function() c:Disconnect() end)
        end
    end
    activationConns = {}
end

local function bindAutoActivation()
    clearActivationConns()

    local function checkAndRun()
        if not aimbotConnection and isEligible() then
            runAimbot()
        end
    end

    -- Escuchar eventos clave del Character y del Player
    local function bindForChar(char)
        if not char then return end
        table.insert(activationConns, char:GetAttributeChangedSignal("TeacherName"):Connect(checkAndRun))
        table.insert(activationConns, char.ChildAdded:Connect(checkAndRun))
        table.insert(activationConns, char.ChildRemoved:Connect(checkAndRun))
        -- Atributos que pueden cambiar en el personaje (Charging, Aiming)
        table.insert(activationConns, char:GetAttributeChangedSignal("Charging"):Connect(checkAndRun))
        table.insert(activationConns, char:GetAttributeChangedSignal("Aiming"):Connect(checkAndRun))
    end

    if LocalPlayer.Character then
        bindForChar(LocalPlayer.Character)
    end

    table.insert(activationConns, LocalPlayer.CharacterAdded:Connect(function(char)
        task.wait(0.5)
        bindForChar(char)
        checkAndRun()
    end))

    table.insert(activationConns, LocalPlayer.CharacterRemoving:Connect(function()
        clearActivationConns()
        if aimbotConnection then
            aimbotConnection:Disconnect()
            aimbotConnection = nil
        end
    end))

    -- Comprobación inicial
    checkAndRun()
end

if LocalPlayer then
    bindAutoActivation()
end

-- Fin del script
