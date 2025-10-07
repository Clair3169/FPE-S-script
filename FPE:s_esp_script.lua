-- === SCRIPT UNIFICADO: Hella Mode ReMAKE + Floating Image Guides + Camera Control + Leaderboard Cleanup + ColorCorrection Control + Stamina Bloqueada + Running True ===

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
-- ⚙️ LÓGICA DE SHIFTLOCK
-- =========================================================================================================

local ShiftLockScreenGui = Instance.new("ScreenGui")
local ShiftLockButton = Instance.new("ImageButton")
local ShiftlockCursor = Instance.new("ImageLabel")

local States = {
    Off = "rbxasset://textures/ui/mouseLock_off@2x.png",
    On = "rbxasset://textures/ui/mouseLock_on@2x.png",
    Lock = "rbxasset://textures/MouseLockedCursor.png"
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
ShiftlockCursor.BackgroundTransparency = 1
ShiftlockCursor.Visible = false

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

local function createFloatingImage(head, imageId)
	if head:FindFirstChild("TeacherBillboard") then return end
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "TeacherBillboard"
	local size = (imageId == teacherImages.AlicePhase2) and 6 or 4
	billboard.Size = UDim2.new(size, 0, size, 0)
	billboard.AlwaysOnTop = true
	billboard.LightInfluence = 0
	billboard.StudsOffset = Vector3.new(0, 2.7, 0)
	billboard.Parent = head
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = "Icon"
	imageLabel.Size = UDim2.new(1, 0, 1, 0)
	imageLabel.BackgroundTransparency = 1
	imageLabel.Image = imageId
	imageLabel.Parent = billboard
	RunService.RenderStepped:Connect(function()
		if not billboard or not head or not head.Parent then return end
		local headPos = head.Position
		local camPos = camera.CFrame.Position
		local distance = (headPos - camPos).Magnitude
		local scale = math.clamp(distance / 25, 0.8, 3.5)
		billboard.Size = UDim2.new(size * scale, 0, size * scale, 0)
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
-- 💪 STAMINA BLOQUEADA EN 100 + RUNNING TRUE
-- =========================================================================================================

local localPlayer = Players.LocalPlayer
local playerName = localPlayer.Name

local possibleFolders = {
	Workspace:WaitForChild("Students"),
	Workspace:WaitForChild("Teachers"),
	Workspace:WaitForChild("Alices")
}

local function findPlayerModel()
	for _, folder in ipairs(possibleFolders) do
		local model = folder:FindFirstChild(playerName)
		if model then
			return model
		end
	end
	return nil
end

-- Bloquear stamina y mantener running en true
local function lockStaminaAndRunning(playerModel)
	if not playerModel then return end

	-- Mantener stamina fija en 100
	if playerModel:GetAttribute("MaxStamina") ~= nil then
		playerModel:SetAttribute("MaxStamina", 100)
	end
	if playerModel:GetAttribute("Stamina") ~= nil then
		playerModel:SetAttribute("Stamina", 100)
	end

	-- Mantener "Running" siempre en true
	if playerModel:GetAttribute("Running") ~= nil then
		playerModel:SetAttribute("Running", true)
	end

	-- Volver a bloquear si cambian
	playerModel:GetAttributeChangedSignal("Stamina"):Connect(function()
		if playerModel:GetAttribute("Stamina") ~= 100 then
			playerModel:SetAttribute("Stamina", 100)
		end
	end)
	playerModel:GetAttributeChangedSignal("MaxStamina"):Connect(function()
		if playerModel:GetAttribute("MaxStamina") ~= 100 then
			playerModel:SetAttribute("MaxStamina", 100)
		end
	end)
	playerModel:GetAttributeChangedSignal("Running"):Connect(function()
		if playerModel:GetAttribute("Running") ~= true then
			playerModel:SetAttribute("Running", true)
		end
	end)

	print("[✅] Stamina bloqueada y Running forzado en true para:", playerModel.Name)
end

local function setupCharacterListener(model)
	if not model then return end
	lockStaminaAndRunning(model)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Died:Connect(function()
			task.wait(1)
			local newModel = findPlayerModel()
			if newModel then
				lockStaminaAndRunning(newModel)
				setupCharacterListener(newModel)
			end
		end)
	end
end

local playerModel = findPlayerModel()
if playerModel then
	lockStaminaAndRunning(playerModel)
	setupCharacterListener(playerModel)
else
	warn("⚠️ No se encontró el jugador en Students, Teachers ni Alices.")
end

for _, folder in ipairs(possibleFolders) do
	folder.ChildAdded:Connect(function(child)
		if child.Name == playerName then
			task.wait(1)
			lockStaminaAndRunning(child)
			setupCharacterListener(child)
		end
	end)
end

return {}
