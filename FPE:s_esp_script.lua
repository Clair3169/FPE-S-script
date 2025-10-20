-- 🅱️ BLOQUE B — HELLA MODE REMAKE + FLOATING IMAGES + CÁMARA TERCERA PERSONA + SHIFTLOCK + SPRINT
-- VERSIÓN ULTRA OPTIMIZADA (VERSIÓN LIMPIA)

local camaraEsperandoRespuesta = true
local forzarTerceraPersonaYShiftLock = true
local modoPredeterminado = false

local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local activeBillboards = {}

local ShiftLockScreenGui = Instance.new("ScreenGui")
local ShiftLockButton = Instance.new("ImageButton")
local ShiftlockCursor = Instance.new("ImageLabel")

local modoPrimeraPersona = false
local otroScriptControlandoCamara = false

local States = {
	Off = "rbxassetid://70491444431002",
	On = "rbxassetid://139177094823080",
	Lock = "rbxassetid://18969983652",
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
ShiftLockButton.Size = UDim2.new(0.100000001, 5, 0.100000001, 5)
ShiftLockButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
ShiftLockButton.Image = States.Off
ShiftLockButton.Visible = false

local function notificationCallback(buttonText)
	if buttonText == "Nha" then
		forzarTerceraPersonaYShiftLock = false
		modoPredeterminado = true
		ShiftLockButton.Visible = false
	else
		forzarTerceraPersonaYShiftLock = true
		modoPredeterminado = false
		ShiftLockButton.Visible = true
	end
	camaraEsperandoRespuesta = false
end

local bindableFunction = Instance.new("BindableFunction")
bindableFunction.OnInvoke = notificationCallback

game:GetService("StarterGui"):SetCore("SendNotification", {
	Title = "Hey you!";
	Text = "Do you want to activate third person mode?";
	Icon = "rbxassetid://97207642508375";
	Duration = 20;
	Callback = bindableFunction;
	Button1 = "Nha";
	Button2 = "Yess!!";
})

ShiftlockCursor.Name = "ShiftlockCursor"
ShiftlockCursor.Parent = ShiftLockScreenGui
ShiftlockCursor.Image = States.Lock
ShiftlockCursor.AnchorPoint = Vector2.new(0.5, 0.5)
ShiftlockCursor.BackgroundTransparency = 1
ShiftlockCursor.Visible = false
ShiftlockCursor.Size = UDim2.new(0, 27, 0, 27)

local debrisFolder = Workspace:WaitForChild("Debris")
local fakeCursor = debrisFolder and debrisFolder:FindFirstChild("FakeCursor")
local fakeCursorAttachment = fakeCursor and fakeCursor:FindFirstChild("Attachment")
local fakeCursorGui = fakeCursorAttachment and fakeCursorAttachment:FindFirstChild("BillboardGui")
local frame = fakeCursorGui and fakeCursorGui:FindFirstChild("Frame")
local uiScale = frame and frame:FindFirstChildOfClass("UIScale")
local uiStroke = frame and frame:FindFirstChildOfClass("UIStroke")

local verticalOffset = -56
local horizontalOffset = 5

local viewport = camera.ViewportSize
local centerX = viewport.X / 2
local centerY = viewport.Y / 2

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	viewport = camera.ViewportSize
	centerX = viewport.X / 2
	centerY = viewport.Y / 2
end)

local cursorHeartbeatConn
cursorHeartbeatConn = RunService.RenderStepped:Connect(function()
	if not ShiftlockCursor.Visible then return end

	if fakeCursorAttachment and camera then
		local worldPos = fakeCursorAttachment.WorldPosition
		local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)
		if onScreen then
			ShiftlockCursor.Position = UDim2.fromOffset(centerX + horizontalOffset, centerY + verticalOffset)
			ShiftlockCursor.Visible = true
		else
			ShiftlockCursor.Visible = false
		end
	else
		ShiftlockCursor.Position = UDim2.fromOffset(centerX + horizontalOffset, centerY + verticalOffset)
	end

	if uiScale then
		if math.abs(uiScale.Scale - 1.4) < 0.05 then
			ShiftlockCursor.Visible = false
		else
			ShiftlockCursor.Visible = true
		end
	end
end)

if uiStroke then
	uiStroke:GetPropertyChangedSignal("Thickness"):Connect(function()
		if uiStroke.Thickness == 1.5 then
			if frame then frame.Visible = true end
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
				if frame and uiStroke and uiStroke.Thickness ~= 1.5 then
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
		if frame and uiStroke and uiStroke.Thickness ~= 1.5 then
			frame.Visible = true
		end
		pcall(function()
			Active:Disconnect()
			Active = nil
		end)
	end
end)

local function ShiftLock() end
ContextActionService:BindAction("Shift Lock", ShiftLock, false, "On")
ContextActionService:SetPosition("Shift Lock", UDim2.new(1, -70, 1, -70))

local TeachersFolder = Workspace:WaitForChild("Teachers")
local AlicesFolder = Workspace:WaitForChild("Alices")

local teacherImages = {
	Thavel = "rbxassetid://126007170470250",
	Bloomie = "rbxassetid://129090409260807",
	Circle = "rbxassetid://72842137403522",
	Alice = "rbxassetid://94023609108845",
	AlicePhase2 = "rbxassetid://78066130044573"
}
local enragedImage = "rbxassetid://108867117884833"

local function findRealHead(model)
	if not model or not model:IsA("Model") then return nil end
	local head = model:FindFirstChild("Head")
	if not head then return nil end
	if head:IsA("BasePart") then
		return head
	end
	if head:IsA("Model") then
		local meshPart = head:FindFirstChildOfClass("MeshPart")
		if meshPart then return meshPart end
		local basePart = head:FindFirstChildOfClass("BasePart")
		if basePart then return basePart end
	end
	return nil
end

local function createFloatingImage(headPart, imageId)
	if not headPart or not headPart:IsA("BasePart") then return end
	if headPart:FindFirstChild("TeacherBillboard") then return end
	if TeachersFolder:FindFirstChild(player.Name) then
		return
	end

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

	table.insert(activeBillboards, {
		billboard = billboard,
		headPart = headPart,
		baseSize = size,
		lastScale = nil
	})
end

local billboardHeartbeatConn
billboardHeartbeatConn = RunService.Heartbeat:Connect((function()
	local accumulator = 0
	local interval = 0.12
	return function(dt)
		accumulator = accumulator + dt
		if accumulator < interval then return end
		accumulator = 0
		if #activeBillboards == 0 then return end
		local camPos = camera.CFrame.Position
		for i = #activeBillboards, 1, -1 do
			local data = activeBillboards[i]
			local billboard = data.billboard
			local headPart = data.headPart
			if not billboard.Parent or not headPart.Parent then
				table.remove(activeBillboards, i)
			else
				local headPos = headPart.Position
				local distance = (headPos - camPos).Magnitude
				local scale = math.clamp(distance / 25, 0.8, 3.5)
				if not data.lastScale or math.abs(scale - data.lastScale) > 0.01 then
					billboard.Size = UDim2.new(data.baseSize * scale, 0, data.baseSize * scale, 0)
					data.lastScale = scale
				end
			end
		end
	end
end)())

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
	local conn
	conn = model:GetAttributeChangedSignal("Enraged"):Connect(function()
		if not model.Parent then
			if conn then conn:Disconnect() end
			return
		end
		updateImage()
	end)
end

local function isLocalInFolders()
	return TeachersFolder:FindFirstChild(player.Name) or AlicesFolder:FindFirstChild(player.Name)
end

local function processCharacter(model)
	if not model or not model:IsA("Model") then return end
	if model == player.Character or model.Name == player.Name then
		local parent = model.Parent
		if parent == TeachersFolder or parent == AlicesFolder then
			return
		end
	end

	local teacherName = model:GetAttribute("TeacherName")
	if not teacherName then return end

	local imageId = teacherImages[teacherName]
	if imageId then
		local headPart = findRealHead(model)
		if headPart then
			if model.Name == player.Name and (TeachersFolder:FindFirstChild(player.Name) or AlicesFolder:FindFirstChild(player.Name)) then
				return
			end
			createFloatingImage(headPart, imageId)
			if teacherName == "Circle" then
				monitorEnraged(model)
			end
		end
	end
end

for _, t in ipairs(TeachersFolder:GetChildren()) do
	processCharacter(t)
end
for _, a in ipairs(AlicesFolder:GetChildren()) do
	processCharacter(a)
end

TeachersFolder.ChildAdded:Connect(function(child)
	task.wait(1)
	processCharacter(child)
end)
AlicesFolder.ChildAdded:Connect(function(child)
	task.wait(1)
	processCharacter(child)
end)

local MIN_ZOOM = 4
local MAX_ZOOM = 100

local function forceThirdPerson(plr)
	if camaraEsperandoRespuesta then return end
	if not forzarTerceraPersonaYShiftLock then return end
	plr.CameraMode = Enum.CameraMode.Classic
	plr.CameraMinZoomDistance = MIN_ZOOM
	plr.CameraMaxZoomDistance = MAX_ZOOM
end

local cameraConn
task.spawn(function()
	while camaraEsperandoRespuesta do
		task.wait(0.25)
	end
	if forzarTerceraPersonaYShiftLock then
		forceThirdPerson(player)
	end
	local accumulator = 0
	local checkInterval = 0.5
	cameraConn = RunService.Heartbeat:Connect(function(dt)
		accumulator = accumulator + dt
		if accumulator < checkInterval then return end
		accumulator = 0
		if camaraEsperandoRespuesta then return end
		if forzarTerceraPersonaYShiftLock then
			forceThirdPerson(player)
		else
			if cameraConn then
				cameraConn:Disconnect()
				cameraConn = nil
			end
		end
	end)
end)

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	if modoPredeterminado then
		ShiftLockButton.Visible = false
	else
		forceThirdPerson(player)
	end
end)

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

local function forceDisable(effect)
	if effect and effect.Enabled then
		effect.Enabled = false
	end
end

if blackout then
	blackout.Enabled = false
	blackout:GetPropertyChangedSignal("Enabled"):Connect(function()
		forceDisable(blackout)
	end)
end

if darkness then
	darkness.Enabled = false
	darkness:GetPropertyChangedSignal("Enabled"):Connect(function()
		forceDisable(darkness)
	end)
end

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
	if not model then return end
	local current = model:GetAttribute("Running")
	if current == nil then return end
	local newState = not current
	model:SetAttribute("Running", newState)
end

local gameUi = playerGui:WaitForChild("GameUI")
local mobileFrame = gameUi:WaitForChild("Mobile")
local sprintButton = mobileFrame:WaitForChild("Sprint")

sprintButton.Visible = false

local function hideSprintIfInFolders()
	local foldersToCheck = {
		game.Workspace:FindFirstChild("Students"),
		game.Workspace:FindFirstChild("Alices"),
		game.Workspace:FindFirstChild("Teachers")
	}
	for _, folder in ipairs(foldersToCheck) do
		if folder and folder:FindFirstChild(player.Name) then
			sprintButton.Visible = false
			return
		end
	end
end

player.CharacterAdded:Connect(function(character)
	task.wait(0.5)
	hideSprintIfInFolders()
end)

local sprintInfButton = sprintButton:Clone()
sprintInfButton.Name = "Sprint_Inf"
sprintInfButton.Visible = true
sprintInfButton.Parent = mobileFrame

sprintInfButton.MouseButton1Click:Connect(function()
	toggleRunning()
end)

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
	end)
end)
