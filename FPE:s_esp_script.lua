-- ===================================================================================
-- 🚀 SCRIPT UNIFICADO PARA EL CLIENTE (VERSIÓN SILENCIOSA)
-- ===================================================================================
-- Este LocalScript gestiona múltiples funcionalidades del lado del jugador:
-- 
--  1. Control de Stamina en la zona "Alices".
--  2. Boost de habilidad para el personaje "Thavel".
--  3. Sistemas generales (Hella Mode, ShiftLock, Iconos Flotantes, Cámara, etc.).
--
-- Cada funcionalidad principal está encapsulada en un bloque `do ... end` para
-- asegurar que las variables locales no interfieran entre sí.
-- ===================================================================================

-- 🔹 SERVICIOS GLOBALES (Definidos una vez para todo el script)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- 🔹 VARIABLES GLOBALES
local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ===================================================================================
-- ⚙️ CONFIGURACIÓN CENTRAL
-- ===================================================================================
local CONFIG = {
    ALICES_STAMINA_VALUE = 2000, -- Stamina otorgada al hacer "grab" dentro de Alices.
    THAVEL_BOOST_VALUE = 1500,   -- Stamina otorgada por el boost de Thavel.
    CAMERA_MIN_ZOOM = 6,         -- Zoom mínimo de la cámara.
    CAMERA_MAX_ZOOM = 100        -- Zoom máximo de la cámara.
}

-- ===================================================================================
-- BLOQUE 1: CONTROL DE STAMINA EN ZONA "ALICES"
-- ===================================================================================
do
    -- Variables específicas del bloque
    local Alices = Workspace:WaitForChild("Alices")
    local character
    local insideAlices = false
    local defaultMaxStamina, defaultCurrentStamina
    local doingGrabConnection

    -- Función para aplicar o restaurar la stamina según el estado
    local function updateStamina()
        if not character then return end
        local doingGrab = character:GetAttribute("DoingGrab")

        if insideAlices and doingGrab then
            character:SetAttribute("MaxStamina", CONFIG.ALICES_STAMINA_VALUE)
            character:SetAttribute("Stamina", CONFIG.ALICES_STAMINA_VALUE)
        elseif defaultMaxStamina and defaultCurrentStamina then
            character:SetAttribute("MaxStamina", defaultMaxStamina)
            character:SetAttribute("Stamina", defaultCurrentStamina)
        end
    end

    -- Revisa constantemente si el jugador está dentro de la zona "Alices"
    local function checkIfInsideAlices()
        if not character or not Alices then return end
        local isCurrentlyInAlices = character:IsDescendantOf(Alices)

        -- El jugador acaba de entrar
        if isCurrentlyInAlices and not insideAlices then
            insideAlices = true
            -- Guardar valores originales de stamina
            defaultMaxStamina = character:GetAttribute("MaxStamina")
            defaultCurrentStamina = character:GetAttribute("Stamina")

            -- Conectar el evento de cambio del atributo "DoingGrab"
            if doingGrabConnection then doingGrabConnection:Disconnect() end
            doingGrabConnection = character:GetAttributeChangedSignal("DoingGrab"):Connect(updateStamina)
            updateStamina() -- Comprobar estado inicial

        -- El jugador acaba de salir
        elseif not isCurrentlyInAlices and insideAlices then
            insideAlices = false
            -- Desconectar el evento y restaurar valores
            if doingGrabConnection then
                doingGrabConnection:Disconnect()
                doingGrabConnection = nil
            end

            if defaultMaxStamina and defaultCurrentStamina then
                character:SetAttribute("MaxStamina", defaultMaxStamina)
                character:SetAttribute("Stamina", defaultCurrentStamina)
            end
        end
    end

    -- Función de inicialización para el personaje
    local function setupCharacter(newCharacter)
        character = newCharacter
        insideAlices = false
        task.wait(0.1)
        checkIfInsideAlices()
    end

    -- Conexiones de personaje
    RunService.Heartbeat:Connect(checkIfInsideAlices)
    localPlayer.CharacterAdded:Connect(setupCharacter)
    if localPlayer.Character then
        setupCharacter(localPlayer.Character)
    end
end

-- ===================================================================================
-- BLOQUE 2: BOOST DE HABILIDAD "THAVEL" (TECLA F / BOTÓN ALT2)
-- ===================================================================================
do
    -- Variables específicas del bloque
    local isBoostActive = false
    local debounce = false
    local currentCharacter = nil
    local isThavelActive = false

    -- Obtiene la etiqueta "Timer" del botón de la habilidad
    local function getTimerLabel()
        local playerGui = localPlayer:FindFirstChild("PlayerGui")
        local gameUI = playerGui and playerGui:FindFirstChild("GameUI")
        local mobileFrame = gameUI and gameUI:FindFirstChild("Mobile")
        local alt2 = mobileFrame and mobileFrame:FindFirstChild("Alt2")
        return alt2 and alt2:FindFirstChild("Timer")
    end

    -- Restaura los valores de stamina originales
    local function restoreDefaults(char)
        if char and char.Parent then
            local originalMax = char:GetAttribute("OriginalMax") or 100
            local originalStamina = char:GetAttribute("OriginalStamina") or 100
            char:SetAttribute("MaxStamina", originalMax)
            char:SetAttribute("Stamina", originalStamina)
        end
    end

    -- Aplica el boost de stamina
    local function applyBoost(char)
        if not char or debounce or not isThavelActive or isBoostActive then return end
        local timer = getTimerLabel()
        if timer and timer.Visible then return end

        isBoostActive = true
        debounce = true

        if not char:GetAttribute("OriginalMax") then
            char:SetAttribute("OriginalMax", char:GetAttribute("MaxStamina") or 100)
        end
        if not char:GetAttribute("OriginalStamina") then
            char:SetAttribute("OriginalStamina", char:GetAttribute("Stamina") or 100)
        end

        char:SetAttribute("MaxStamina", CONFIG.THAVEL_BOOST_VALUE)
        char:SetAttribute("Stamina", CONFIG.THAVEL_BOOST_VALUE)
        debounce = false
    end

    -- Monitorea el temporizador de la UI
    local function monitorTimer()
        local timer = getTimerLabel()
        if not timer then return end
        timer:GetPropertyChangedSignal("Visible"):Connect(function()
            if timer.Visible and isBoostActive then
                if currentCharacter then
                    restoreDefaults(currentCharacter)
                end
                isBoostActive = false
            end
        end)
    end

    -- Valida si el personaje es "Thavel"
    local function validateCharacter(char)
        task.wait(0.5)
        local teacherName = char:GetAttribute("TeacherName")
        isThavelActive = (teacherName == "Thavel")
        if isThavelActive then
            currentCharacter = char
        else
            currentCharacter = nil
        end
        
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.Died:Connect(function()
                isBoostActive = false
                debounce = false
                currentCharacter = nil
                isThavelActive = false
            end)
        end
    end

    -- Configura los controles
    local function setupControls()
        UserInputService.InputBegan:Connect(function(input, processed)
            if processed then return end
            if input.KeyCode == Enum.KeyCode.F and currentCharacter then
                applyBoost(currentCharacter)
            end
        end)

        task.defer(function()
            local playerGui = localPlayer:WaitForChild("PlayerGui")
            local gameUI = playerGui:WaitForChild("GameUI")
            local mobileFrame = gameUI:WaitForChild("Mobile")
            local alt2Button = mobileFrame:WaitForChild("Alt2")
            if alt2Button then
                alt2Button.MouseButton1Click:Connect(function()
                    if currentCharacter then
                        applyBoost(currentCharacter)
                    end
                end)
            end
        end)
    end

    -- Inicialización
    setupControls()
    monitorTimer()
    localPlayer.CharacterAdded:Connect(function(newChar)
        validateCharacter(newChar)
        task.wait(1)
        monitorTimer()
    end)
    if localPlayer.Character then
        validateCharacter(localPlayer.Character)
    end
end

-- ===================================================================================
-- BLOQUE 3: SISTEMAS GENERALES (HELLA MODE, SHIFTLOCK, ICONOS, CÁMARA, SPRINT)
-- ===================================================================================
do
    -- 3.1: SHIFTLOCK PERSONALIZADO
    local ShiftLockScreenGui = Instance.new("ScreenGui")
	local ShiftLockButton = Instance.new("ImageButton")
	local ShiftlockCursor = Instance.new("ImageLabel")
	local States = {
		Off = "rbxasset://textures/ui/mouseLock_off@2x.png",
		On = "rbxasset://textures/ui/mouseLock_on@2x.png",
		Lock = "rbxasset://textures/MouseLockedCursor.png",
	}
	local MaxLength = 900000
	local EnabledOffset = CFrame.new(1.7, 0, 0)
	local DisabledOffset = CFrame.new(-1.7, 0, 0)
	local ActiveConnection
	ShiftLockScreenGui.Name = "Shiftlock (CoreGui)"
	ShiftLockScreenGui.Parent = CoreGui
	ShiftLockScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	ShiftLockScreenGui.ResetOnSpawn = false
	ShiftLockButton.Parent = ShiftLockScreenGui
	ShiftLockButton.BackgroundTransparency = 1
	ShiftLockButton.AnchorPoint = Vector2.new(1, 1)
	ShiftLockButton.Position = UDim2.new(1, 0, 1, 0)
	ShiftLockButton.Size = UDim2.new(0.08, 0, 0.08, 0)
	ShiftLockButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
	ShiftLockButton.Image = States.Off
	ShiftlockCursor.Name = "Shiftlock Cursor"
	ShiftlockCursor.Parent = ShiftLockScreenGui
	ShiftlockCursor.Image = States.Lock
	ShiftlockCursor.Size = UDim2.new(0.03, 0, 0.03, 0)
	ShiftlockCursor.Position = UDim2.new(0.5, 0, 0.4, 7)
	ShiftlockCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	ShiftlockCursor.SizeConstraint = Enum.SizeConstraint.RelativeXX
	ShiftlockCursor.BackgroundTransparency = 1
	ShiftlockCursor.Visible = false
	local frame = Workspace:FindFirstChild("Debris") and Workspace.Debris:FindFirstChild("FakeCursor") and Workspace.Debris.FakeCursor:FindFirstChild("Attachment") and Workspace.Debris.FakeCursor.Attachment:FindFirstChild("BillboardGui") and Workspace.Debris.FakeCursor.Attachment.BillboardGui:FindFirstChild("Frame")
	local uiStroke = frame and frame:FindFirstChildOfClass("UIStroke")
	if uiStroke then
		uiStroke:GetPropertyChangedSignal("Thickness"):Connect(function()
			if uiStroke.Thickness == 1.5 then frame.Visible = true end
		end)
	end
	ShiftLockButton.MouseButton1Click:Connect(function()
		if not ActiveConnection then
			ActiveConnection = RunService.RenderStepped:Connect(function()
				if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
					localPlayer.Character.Humanoid.AutoRotate = false
					ShiftLockButton.Image = States.On
					ShiftlockCursor.Visible = true
					if frame and uiStroke.Thickness ~= 1.5 then frame.Visible = false end
					if localPlayer.Character:FindFirstChild("HumanoidRootPart") then
						local hrp = localPlayer.Character.HumanoidRootPart
						hrp.CFrame = CFrame.new(hrp.Position, Vector3.new(camera.CFrame.LookVector.X * MaxLength, hrp.Position.Y, camera.CFrame.LookVector.Z * MaxLength))
					end
					camera.CFrame = camera.CFrame * EnabledOffset
					camera.Focus = CFrame.fromMatrix(camera.Focus.Position, camera.CFrame.RightVector, camera.CFrame.UpVector) * EnabledOffset
				end
			end)
		else
			if localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid") then
				localPlayer.Character.Humanoid.AutoRotate = true
			end
			ShiftLockButton.Image = States.Off
			camera.CFrame = camera.CFrame * DisabledOffset
			ShiftlockCursor.Visible = false
			if frame and uiStroke.Thickness ~= 1.5 then frame.Visible = true end
			ActiveConnection:Disconnect()
			ActiveConnection = nil
		end
	end)
	ContextActionService:BindAction("Shift Lock", function() end, false, "On")
	ContextActionService:SetPosition("Shift Lock", UDim2.new(1, -70, 1, -70))

    -- 3.2: ICONOS FLOTANTES Y CÁMARA
    local TeachersFolder = Workspace:WaitForChild("Teachers")
    local AlicesFolder = Workspace:WaitForChild("Alices")
    local teacherImages = { Thavel = "rbxassetid://126007170470250", Bloomie = "rbxassetid://116769479448758", Circle = "rbxassetid://72842137403522", Alice = "rbxassetid://94023609108845", AlicePhase2 = "rbxassetid://78066130044573" }
    local enragedImage = "rbxassetid://108867117884833"
    local function findRealHead(model)
        if not model or not model:IsA("Model") then return nil end
        local head = model:FindFirstChild("Head")
        if not head then return nil end
        if head:IsA("BasePart") then return head end
        if head:IsA("Model") then return head:FindFirstChildOfClass("MeshPart") or head:FindFirstChildOfClass("BasePart") end
        return nil
    end
    local function createFloatingImage(headPart, imageId)
        if not headPart or not headPart:IsA("BasePart") or headPart:FindFirstChild("TeacherBillboard") then return end
        local billboard = Instance.new("BillboardGui")
        billboard.Name = "TeacherBillboard"
        local size = (imageId == teacherImages.AlicePhase2) and 6 or 4
        billboard.Size = UDim2.new(size, 0, size, 0)
        billboard.AlwaysOnTop = true
        billboard.LightInfluence = 0
        billboard.StudsOffset = Vector3.new(0, 2.7, 0)
        billboard.Parent = headPart
        local imageLabel = Instance.new("ImageLabel")
        imageLabel.Name = "Icon"
        imageLabel.Size = UDim2.new(1, 0, 1, 0)
        imageLabel.BackgroundTransparency = 1
        imageLabel.Image = imageId
        imageLabel.Parent = billboard
        local conn = RunService.RenderStepped:Connect(function()
            if not billboard.Parent then conn:Disconnect() return end
            local distance = (headPart.Position - camera.CFrame.Position).Magnitude
            local scale = math.clamp(distance / 25, 0.8, 3.5)
            billboard.Size = UDim2.new(size * scale, 0, size * scale, 0)
        end)
    end
    local function monitorEnraged(model)
        local headPart = findRealHead(model)
        if not headPart or not billboard then return end
        local billboard = headPart:FindFirstChild("TeacherBillboard")
        if not billboard then return end
        local icon = billboard:FindFirstChild("Icon")
        if not icon then return end
        local function updateImage() icon.Image = (model:GetAttribute("Enraged") == true) and enragedImage or teacherImages["Circle"] end
        updateImage()
        model:GetAttributeChangedSignal("Enraged"):Connect(updateImage)
    end
    local function processCharacter(model)
        if not model or not model:IsA("Model") then return end
        local teacherName = model:GetAttribute("TeacherName")
        if teacherName and teacherImages[teacherName] then
            local headPart = findRealHead(model)
            if headPart then
                createFloatingImage(headPart, teacherImages[teacherName])
                if teacherName == "Circle" then monitorEnraged(model) end
            end
        end
    end
    local function isPlayerInSpecialFolder() return TeachersFolder:FindFirstChild(localPlayer.Name) or AlicesFolder:FindFirstChild(localPlayer.Name) end
    for _, t in ipairs(TeachersFolder:GetChildren()) do if not isPlayerInSpecialFolder() or t.Name ~= localPlayer.Name then processCharacter(t) end end
    for _, a in ipairs(AlicesFolder:GetChildren()) do if not isPlayerInSpecialFolder() or a.Name ~= localPlayer.Name then processCharacter(a) end end
    TeachersFolder.ChildAdded:Connect(function(child) task.wait(1) if not isPlayerInSpecialFolder() or child.Name ~= localPlayer.Name then processCharacter(child) end end)
    AlicesFolder.ChildAdded:Connect(function(child) task.wait(1) if not isPlayerInSpecialFolder() or child.Name ~= localPlayer.Name then processCharacter(child) end end)
    local function forceThirdPerson(plr) plr.CameraMode = Enum.CameraMode.Classic; plr.CameraMinZoomDistance = CONFIG.CAMERA_MIN_ZOOM; plr.CameraMaxZoomDistance = CONFIG.CAMERA_MAX_ZOOM; end
    task.spawn(function() while task.wait(1) do for _, plr in ipairs(Players:GetPlayers()) do if plr.CameraMode == Enum.CameraMode.LockFirstPerson then forceThirdPerson(plr) end end end end)
    Players.PlayerAdded:Connect(function(plr) forceThirdPerson(plr) plr.CharacterAdded:Connect(function() task.wait(0.5) forceThirdPerson(plr) end) end)
    for _, plr in ipairs(Players:GetPlayers()) do forceThirdPerson(plr) plr.CharacterAdded:Connect(function() task.wait(0.5) forceThirdPerson(plr) end) end

    -- 3.3: LIMPIEZA DE ENTORNO Y AJUSTES VISUALES
    local leaderboard = Workspace:WaitForChild("Area"):WaitForChild("Map"):WaitForChild("Leaderboard")
    for _, child in ipairs(leaderboard:GetChildren()) do child:Destroy() end
    leaderboard.ChildAdded:Connect(function(child) child:Destroy() end)
    local blackout = Lighting:FindFirstChild("BlackoutColorCorrection")
    local darkness = Lighting:FindFirstChild("DarknessColorCorrection")
    RunService.RenderStepped:Connect(function()
        if blackout and blackout.Enabled then blackout.Enabled = false end
        if darkness and darkness.Enabled then darkness.Enabled = false end
    end)

    -- 3.4: SPRINT INFINITO (MÓVIL + PC)
    local playerGui = localPlayer:WaitForChild("PlayerGui")
    local potentialFolders = { Workspace:WaitForChild("Students"), Workspace:FindFirstChild("Alices"), Workspace:FindFirstChild("Teachers") }
    local function findPlayerModel() for _, folder in ipairs(potentialFolders) do if folder then local model = folder:FindFirstChild(localPlayer.Name) if model then return model end end end return nil end
    local function toggleRunning() local model = findPlayerModel() if not model then return end local current = model:GetAttribute("Running") if current ~= nil then model:SetAttribute("Running", not current) end end
    local sprintButton = playerGui:WaitForChild("GameUI"):WaitForChild("Mobile"):WaitForChild("Sprint")
    sprintButton.Visible = false
    local sprintInfButton = sprintButton:Clone()
    sprintInfButton.Name = "Sprint_Inf"
    sprintInfButton.Visible = true
    sprintInfButton.Parent = sprintButton.Parent
    sprintInfButton.MouseButton1Click:Connect(toggleRunning)
    UserInputService.InputBegan:Connect(function(input, gameProcessed) if gameProcessed then return end if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift or input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then toggleRunning() end end)
    localPlayer.CharacterAdded:Connect(function(character)
        task.wait(1)
        sprintButton.Visible = false
        local model = findPlayerModel()
        if model then model:SetAttribute("Running", true) end
        local humanoid = character:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            sprintButton.Visible = false
            task.wait(1)
            local modelOnRespawn = findPlayerModel()
            if modelOnRespawn then modelOnRespawn:SetAttribute("Running", true) end
        end)
    end)
end
