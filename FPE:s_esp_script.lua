-- === SCRIPT UNIFICADO: Hella Mode ReMAKE + Floating Image Guides + Camera Control + Leaderboard Cleanup + ColorCorrection Control + Sprint Infinito ===

-- SERVICIOS
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

-- VARIABLES COMUNES
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- =========================================================================================================
--                                          ⚙️ LÓGICA DE SHIFTLOCK
-- =========================================================================================================

local ShiftLockScreenGui = Instance.new("ScreenGui")
local ShiftLockButton = Instance.new("ImageButton")
local ShiftlockCursor = Instance.new("ImageLabel")

local States = {
    Off = "rbxasset://textures/ui/mouseLock_off@2x.png",
    On = "rbxasset://textures/ui/mouseLock_on@2x.png",
    Lock = "rbxasset://textures/MouseLockedCursor.png",
    Lock2 = "rbxasset://SystemCursors/Cross"
}
local MaxLength = 900000
local EnabledOffset = CFrame.new(1.7, 0, 0)
local DisabledOffset = CFrame.new(-1.7, 0, 0)
local Active

ShiftLockScreenGui.Name = "Shiftlock (CoreGui)"
ShiftLockScreenGui.Parent = CoreGui
ShiftLockScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ShiftLockScreenGui.ResetOnSpawn = false

ShiftLockButton.Parent = ShiftLockScreenGui
ShiftLockButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
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
ShiftlockCursor.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
ShiftlockCursor.Visible = false

-- Ojo Fake
local frame = Workspace:FindFirstChild("Debris") and Workspace.Debris:FindFirstChild("FakeCursor") and Workspace.Debris.FakeCursor:FindFirstChild("Attachment") and Workspace.Debris.FakeCursor.Attachment:FindFirstChild("BillboardGui") and Workspace.Debris.FakeCursor.Attachment.BillboardGui:FindFirstChild("Frame")
local uiStroke = frame and frame:FindFirstChildOfClass("UIStroke")

if uiStroke then
    uiStroke:GetPropertyChangedSignal("Thickness"):Connect(function()
        if uiStroke.Thickness == 1.5 then
            frame.Visible = true
        end
    end)
end

ShiftLockButton.MouseButton1Click:Connect(function()
    if not Active then
        Active = RunService.RenderStepped:Connect(function()
            if player.Character and player.Character:FindFirstChild("Humanoid") then
                player.Character.Humanoid.AutoRotate = false
                ShiftLockButton.Image = States.On
                ShiftlockCursor.Visible = true
                if frame and uiStroke.Thickness ~= 1.5 then
                    frame.Visible = false
                end
                if player.Character:FindFirstChild("HumanoidRootPart") then
                    player.Character.HumanoidRootPart.CFrame = CFrame.new(
                        player.Character.HumanoidRootPart.Position,
                        Vector3.new(
                            camera.CFrame.LookVector.X * MaxLength,
                            player.Character.HumanoidRootPart.Position.Y,
                            camera.CFrame.LookVector.Z * MaxLength
                        )
                    )
                end
                camera.CFrame = camera.CFrame * EnabledOffset
                camera.Focus = CFrame.fromMatrix(
                    camera.Focus.Position,
                    camera.CFrame.RightVector,
                    camera.CFrame.UpVector
                ) * EnabledOffset
            end
        end)
    else
        if player.Character and player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid.AutoRotate = true
        end
        ShiftLockButton.Image = States.Off
        camera.CFrame = camera.CFrame * DisabledOffset
        ShiftlockCursor.Visible = false
        if frame and uiStroke.Thickness ~= 1.5 then
            frame.Visible = true
        end
        pcall(function()
            Active:Disconnect()
            Active = nil
        end)
    end
end)

local function ShiftLock() end
local ShiftLockAction = ContextActionService:BindAction("Shift Lock", ShiftLock, false, "On")
ContextActionService:SetPosition("Shift Lock", UDim2.new(1, -70, 1, -70))

-- =========================================================================================================
-- 👤 ICONOS FLOTANTES Y CÁMARA
-- =========================================================================================================

local TeachersFolder = Workspace:WaitForChild("Teachers")
local AlicesFolder = Workspace:WaitForChild("Alices")

local teacherImages = {
	Thavel = "rbxassetid://126007170470250",
	Bloomie = "rbxassetid://116769479448758",
	Circle = "rbxassetid://72842137403522",
	Alice = "rbxassetid://94023609108845",
	AlicePhase2 = "rbxassetid://78066130044573"
}
local enragedImage = "rbxassetid://108867117884833"

-- Helper: busca el "Head" real (BasePart/ MeshPart). Si Head es un Model, busca dentro su MeshPart real
local function findRealHead(model)
	if not model or not model:IsA("Model") then return nil end
	local head = model:FindFirstChild("Head")
	if not head then return nil end

	-- Si Head ya es una parte (BasePart), la devolvemos
	if head:IsA("BasePart") then
		return head
	end

	-- Si Head es un Model, buscar el MeshPart real dentro (descendientes)
	if head:IsA("Model") then
		for _, v in ipairs(head:GetDescendants()) do
			if v:IsA("MeshPart") or v:IsA("BasePart") then
				-- preferimos MeshPart, pero aceptamos cualquier BasePart por seguridad
				if v:IsA("MeshPart") then
					return v
				end
			end
		end
		-- si no encontramos MeshPart, intentar devolver la primera BasePart disponible
		for _, v in ipairs(head:GetDescendants()) do
			if v:IsA("BasePart") then
				return v
			end
		end
	end

	return nil
end

local function createFloatingImage(headPart, imageId)
	-- headPart must be a BasePart (MeshPart, Part, etc.)
	if not headPart or not headPart:IsA("BasePart") then return end
	if headPart:FindFirstChild("TeacherBillboard") then return end

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
	imageLabel.ImageTransparency = 0
	imageLabel.Parent = billboard

	-- Guardar la conexión en el billboard para poder limpiar si el head cambia
	local conn
	conn = RunService.RenderStepped:Connect(function()
		if not billboard or not headPart or not headPart.Parent then
			if conn then
				conn:Disconnect()
			end
			return
		end
		-- calcular escala en base a distancia
		local headPos = headPart.Position
		local camPos = camera.CFrame.Position
		local distance = (headPos - camPos).Magnitude
		local scale = math.clamp(distance / 25, 0.8, 3.5)
		billboard.Size = UDim2.new(size * scale, 0, size * scale, 0)
	end)
end

local function monitorEnraged(model)
	local headPart = findRealHead(model)
	if not headPart then return end
	local billboard = headPart:FindFirstChild("TeacherBillboard")
	if not billboard then return end
	local icon = billboard:FindFirstChild("Icon")
	if not icon then return end

	local function updateImage()
		local enraged = model:GetAttribute("Enraged")
		icon.Image = (enraged == true) and enragedImage or teacherImages["Circle"]
	end

	updateImage()
	model:GetAttributeChangedSignal("Enraged"):Connect(updateImage)
end

local function processCharacter(model)
    if not model or not model:IsA("Model") then return end

    local teacherName = model:GetAttribute("TeacherName")
    if not teacherName then return end

    local imageId = teacherImages[teacherName]
    if imageId then
        local headPart = findRealHead(model)
        if headPart then
            createFloatingImage(headPart, imageId)
            if teacherName == "Circle" then
                monitorEnraged(model)
            end
        end
    end
end

local function isLocalInFolders()
	return TeachersFolder:FindFirstChild(player.Name) or AlicesFolder:FindFirstChild(player.Name)
end

for _, t in ipairs(TeachersFolder:GetChildren()) do
    if not isLocalInFolders() or t.Name ~= player.Name then
        processCharacter(t)
    end
end
for _, a in ipairs(AlicesFolder:GetChildren()) do
    if not isLocalInFolders() or a.Name ~= player.Name then
        processCharacter(a)
    end
end

TeachersFolder.ChildAdded:Connect(function(child)
    task.wait(1)
    if not isLocalInFolders() or child.Name ~= player.Name then
        processCharacter(child)
    end
end)
AlicesFolder.ChildAdded:Connect(function(child)
    task.wait(1)
    if not isLocalInFolders() or child.Name ~= player.Name then
        processCharacter(child)
    end
end)

-- === CONTROL DE CÁMARA ===
local MIN_ZOOM = 6
local MAX_ZOOM = 100
local function forceThirdPerson(plr)
	plr.CameraMode = Enum.CameraMode.Classic
	plr.CameraMinZoomDistance = MIN_ZOOM
	plr.CameraMaxZoomDistance = MAX_ZOOM
end

task.spawn(function()
	while task.wait(1) do
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr.CameraMode == Enum.CameraMode.LockFirstPerson then
				forceThirdPerson(plr)
			end
		end
	end
end)

Players.PlayerAdded:Connect(function(plr)
	forceThirdPerson(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		forceThirdPerson(plr)
	end)
end)
for _, plr in ipairs(Players:GetPlayers()) do
	forceThirdPerson(plr)
	plr.CharacterAdded:Connect(function()
		task.wait(0.5)
		forceThirdPerson(plr)
	end)
end

-- =========================================================================================================
-- 🧹 LIMPIEZA Y AJUSTES
-- =========================================================================================================

local area = Workspace:WaitForChild("Area")
local map = area:WaitForChild("Map")
local leaderboard = map:WaitForChild("Leaderboard")

for _, child in ipairs(leaderboard:GetChildren()) do
	child:Destroy()
end
leaderboard.ChildAdded:Connect(function(child)
	child:Destroy()
end)

local blackout = Lighting:FindFirstChild("BlackoutColorCorrection")
local darkness = Lighting:FindFirstChild("DarknessColorCorrection")

RunService.RenderStepped:Connect(function()
	if blackout and blackout.Enabled then blackout.Enabled = false end
	if darkness and darkness.Enabled then darkness.Enabled = false end
end)

-- =========================================================================================================
-- 🏃 SPRINT INFINITO (MÓVIL + PC)
-- =========================================================================================================

local player = game.Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local folders = {
	game.Workspace:WaitForChild("Students", 5),
	game.Workspace:FindFirstChild("Alices"),
	game.Workspace:FindFirstChild("Teachers")
}

local function findPlayerModel()
	for _, folder in ipairs(folders) do
		if folder then
			local model = folder:FindFirstChild(player.Name)
			if model then
				return model
			end
		end
	end
	return nil
end

local function toggleRunning()
	local model = findPlayerModel()
	if not model then
		warn("⚠️ No se encontró el modelo del jugador.")
		return
	end

	local current = model:GetAttribute("Running")
	if current == nil then
		warn("⚠️ El modelo no tiene el atributo 'Running'.")
		return
	end

	local newState = not current
	model:SetAttribute("Running", newState)
	print("🏃 Sprint infinito:", newState and "ACTIVADO ✅" or "DESACTIVADO ❌")
end

local gameUi = playerGui:WaitForChild("GameUI")
local mobileFrame = gameUi:WaitForChild("Mobile")
local sprintButton = mobileFrame:WaitForChild("Sprint")

sprintButton.Visible = false

local sprintInfButton = sprintButton:Clone()
sprintInfButton.Name = "Sprint_Inf"
sprintInfButton.Visible = true
sprintInfButton.Parent = mobileFrame

sprintInfButton.MouseButton1Click:Connect(function()
	toggleRunning()
end)

local UserInputService = game:GetService("UserInputService")

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift
	or input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.RightControl then
		toggleRunning()
	end
end)

player.CharacterAdded:Connect(function(character)
	local humanoid = character:WaitForChild("Humanoid")

	humanoid.Died:Connect(function()
		if sprintButton then
			sprintButton.Visible = false
		end
		task.wait(1)
		local model = findPlayerModel()
		if model then
			model:SetAttribute("Running", true)
		end
	end)

	task.wait(1)
	if sprintButton then
		sprintButton.Visible = false
	end

	local model = findPlayerModel()
	if model then
		model:SetAttribute("Running", true)
	end
end)

return {} and ShiftLockAction
