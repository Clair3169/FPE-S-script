-- ===================================================================================
-- 🧩 SCRIPT UNIFICADO (3 BLOQUES AISLADOS)
--  🔸 Bloque A → Boost de Thavel (tecla F / botón Alt2)
--  🔸 Bloque B → Hella Mode ReMAKE + Floating Images + Cámara + ShiftLock + Sprint
--  🔸 Bloque C → Control de Stamina dentro de workspace.Alices
-- ===================================================================================

------------------------------------------------------------------------------------
-- 🅰️ BLOQUE A — BOOST DE THAVEL
------------------------------------------------------------------------------------
do
	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")

	local localPlayer = Players.LocalPlayer

	local BOOST_VALUE = 2000
	local isBoostActive = false
	local debounce = false
	local currentCharacter = nil
	local teacherActive = false

	local function getTimerLabel()
		local playerGui = localPlayer:FindFirstChild("PlayerGui")
		if not playerGui then return nil end

		local gameUI = playerGui:FindFirstChild("GameUI")
		if not gameUI then return nil end

		local mobileFrame = gameUI:FindFirstChild("Mobile")
		if not mobileFrame then return nil end

		local alt2 = mobileFrame:FindFirstChild("Alt2")
		if not alt2 then return nil end

		return alt2:FindFirstChild("Timer")
	end

	local function restoreDefaults(char, originalMax, originalStamina)
		if char and char.Parent then
			char:SetAttribute("MaxStamina", originalMax)
			char:SetAttribute("Stamina", originalStamina)
		end
	end

	local function applyBoost(char)
		if not char or debounce then return end
		if not teacherActive then return end

		local timer = getTimerLabel()
		if timer and timer.Visible then
			return
		end

		local originalMax = char:GetAttribute("MaxStamina") or 100
		local originalStamina = char:GetAttribute("Stamina") or 100
		if isBoostActive then return end

		isBoostActive = true
		debounce = true

		if not char:GetAttribute("OriginalMax") then
			char:SetAttribute("OriginalMax", originalMax)
		end
		if not char:GetAttribute("OriginalStamina") then
			char:SetAttribute("OriginalStamina", originalStamina)
		end

		char:SetAttribute("MaxStamina", BOOST_VALUE)
		char:SetAttribute("Stamina", BOOST_VALUE)

		debounce = false
	end

	local function monitorTimer()
		local timer = getTimerLabel()
		if not timer then return end

		timer:GetPropertyChangedSignal("Visible"):Connect(function()
			if timer.Visible and isBoostActive then
				local char = currentCharacter
				if char then
					local originalMax = char:GetAttribute("OriginalMax") or 100
					local originalStamina = char:GetAttribute("OriginalStamina") or 100
					restoreDefaults(char, originalMax, originalStamina)
				end
				isBoostActive = false
			end
		end)
	end

	local function validateCharacter(char)
		task.wait(0.5)
		local teacherName = char:GetAttribute("TeacherName")

		if teacherName == "Thavel" then
			currentCharacter = char
			teacherActive = true
		else
			teacherActive = false
		end

		local humanoid = char:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Died:Connect(function()
				isBoostActive = false
				debounce = false
				currentCharacter = nil
				teacherActive = false
			end)
		end
	end

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

			if alt2Button and (alt2Button:IsA("TextButton") or alt2Button:IsA("ImageButton")) then
				alt2Button.MouseButton1Click:Connect(function()
					if currentCharacter then
						applyBoost(currentCharacter)
					end
				end)
			end
		end)
	end

	setupControls()
	monitorTimer()

	if localPlayer.Character then
		validateCharacter(localPlayer.Character)
	end

	localPlayer.CharacterAdded:Connect(function(newChar)
		validateCharacter(newChar)
		task.wait(1)
		monitorTimer()
	end)
end

------------------------------------------------------------------------------------
-- 🅱️ BLOQUE B — HELLA MODE REMAKE + FLOATING IMAGES + CÁMARA + SHIFTLOCK + SPRINT
------------------------------------------------------------------------------------
do
	-- 🔒 Controla si el script puede modificar la cámara (espera a que el jugador elija)
local camaraEsperandoRespuesta = true
local forzarTerceraPersonaYShiftLock = true
local modoLibre = false
local otroScriptControlandoCamara = false

	local CoreGui = game:GetService("CoreGui")
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local ContextActionService = game:GetService("ContextActionService")
	local UserInputService = game:GetService("UserInputService")
	local Workspace = game:GetService("Workspace")
	local Lighting = game:GetService("Lighting")

	local player = Players.LocalPlayer
	local camera = Workspace.CurrentCamera

	local ShiftLockScreenGui = Instance.new("ScreenGui")
	local ShiftLockButton = Instance.new("ImageButton")
	local ShiftlockCursor = Instance.new("ImageLabel")

	-- ================================================================================
	-- ✨ MODIFICACIÓN 1: Variable para controlar si la cámara forzada está activa
	-- ================================================================================
	local forzarTerceraPersonaYShiftLock = true
	-- 🔸 NUEVAS VARIABLES DE CONTROL DE CÁMARA
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

	-- ================================================================================
	-- ✨ MODIFICACIÓN 2: Notificación para preguntar al jugador
	-- ================================================================================

	local function notificationCallback(buttonText)
	if buttonText == "Sí" then
		-- Dejar la cámara como está por defecto del juego
		forzarTerceraPersonaYShiftLock = false
		print("[Cámara] Se mantiene configuración predeterminada del juego.")
	else
		forzarTerceraPersonaYShiftLock = true
		ShiftLockButton.Visible = true
		print("[Cámara] Tercera persona forzada activada.")
	end

	camaraEsperandoRespuesta = false
end

	local bindableFunction = Instance.new("BindableFunction")
	bindableFunction.OnInvoke = notificationCallback

	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Configuración de Cámara";
		Text = "¿Deseas desactivar la 3ra persona forzada y el botón de ShiftLock?";
		Icon = ""; -- Sin ícono
		Duration = 15; -- Duración en segundos
		Callback = bindableFunction; -- La función que se ejecuta al presionar un botón
		Button1 = "Sí";
		Button2 = "No";
	})
	
	ShiftlockCursor.Name = "ShiftlockCursor"
	ShiftlockCursor.Parent = ShiftLockScreenGui
	ShiftlockCursor.Image = States.Lock
	ShiftlockCursor.AnchorPoint = Vector2.new(0.5, 0.5)
	ShiftlockCursor.BackgroundTransparency = 1
	ShiftlockCursor.Visible = false
	ShiftlockCursor.Size = UDim2.new(0, 27, 0, 27)

	local function getFakeCursorAttachment()
		local debris = Workspace:FindFirstChild("Debris")
		if not debris then return nil end
		local fake = debris:FindFirstChild("FakeCursor")
		if not fake then return nil end
		return fake:FindFirstChild("Attachment")
	end

	local function getFakeCursorUIScale()
		local debris = Workspace:FindFirstChild("Debris")
		if not debris then return nil end
		local fake = debris:FindFirstChild("FakeCursor")
		if not fake then return nil end
		local attach = fake:FindFirstChild("Attachment")
		if not attach then return nil end
		local gui = attach:FindFirstChild("BillboardGui")
		if not gui then return nil end
		local frame = gui:FindFirstChild("Frame")
		if not frame then return nil end
		return frame:FindFirstChildOfClass("UIScale")
	end

	local verticalOffset = -56
	local horizontalOffset = 5

	RunService.RenderStepped:Connect(function()
		if not ShiftlockCursor.Visible then return end

		local attachment = getFakeCursorAttachment()
		local uiScale = getFakeCursorUIScale()
		local viewport = camera.ViewportSize
		local centerX = viewport.X / 2
		local centerY = viewport.Y / 2

		if attachment and camera then
			local worldPos = attachment.WorldPosition
			local screenPos, onScreen = camera:WorldToViewportPoint(worldPos)

			if onScreen then
				ShiftlockCursor.Position = UDim2.fromOffset(
					centerX + horizontalOffset,
					centerY + verticalOffset
				)
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
			for _, v in ipairs(head:GetDescendants()) do
				if v:IsA("MeshPart") or v:IsA("BasePart") then
					if v:IsA("MeshPart") then
						return v
					end
				end
			end
			for _, v in ipairs(head:GetDescendants()) do
				if v:IsA("BasePart") then
					return v
				end
			end
		end

		return nil
	end

	local function createFloatingImage(headPart, imageId)
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

		local conn
		conn = RunService.RenderStepped:Connect(function()
			if not billboard or not headPart or not headPart.Parent then
				if conn then
					conn:Disconnect()
				end
				return
			end
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

	-- 📸 Control seguro de cámara — se ejecuta solo cuando ya se respondió
local MIN_ZOOM = 4
local MAX_ZOOM = 100

local function forceThirdPerson(plr)
	if camaraEsperandoRespuesta then return end -- ❗ Evita que se ejecute antes
	plr.CameraMode = Enum.CameraMode.Classic
	plr.CameraMinZoomDistance = MIN_ZOOM
	plr.CameraMaxZoomDistance = MAX_ZOOM
end


	
	-- ================================================================================
	-- ✨ MODIFICACIÓN 3: Se condiciona la ejecución de la cámara forzada
	-- ================================================================================
	task.spawn(function()
	while task.wait(1) do
		if camaraEsperandoRespuesta then continue end -- Espera la respuesta antes de tocar cámara

		if forzarTerceraPersonaYShiftLock then
			for _, plr in ipairs(Players:GetPlayers()) do
				if plr.CameraMode ~= Enum.CameraMode.Classic then
					forceThirdPerson(plr)
				end
			end
		else
			-- ✅ Modo libre: no tocar la cámara, queda como la configuración predeterminada del juego
		end
	end
end)


	
	Players.PlayerAdded:Connect(function(plr)
		if forzarTerceraPersonaYShiftLock then
			forceThirdPerson(plr)
			plr.CharacterAdded:Connect(function()
				task.wait(0.5)
				forceThirdPerson(plr)
			end)
		end
	end)
	
	for _, plr in ipairs(Players:GetPlayers()) do
		if forzarTerceraPersonaYShiftLock then
			forceThirdPerson(plr)
			plr.CharacterAdded:Connect(function()
				task.wait(0.5)
				forceThirdPerson(plr)
			end)
		end
	end

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
end

------------------------------------------------------------------------------------
-- 🅲 BLOQUE C — CONTROL DE STAMINA EN "workspace.Alices"
------------------------------------------------------------------------------------
do
	local Workspace = game:GetService("Workspace")
	local AlicesFolder = Workspace:WaitForChild("Alices")
	local Players = game:GetService("Players")

	local function keepStaminaRegen()
		for _, alice in ipairs(AlicesFolder:GetChildren()) do
			if alice:IsA("Model") and alice:FindFirstChild("Humanoid") then
				alice:SetAttribute("StaminaRegen", 100)
			end
		end
	end

	task.spawn(function()
		while task.wait(1) do
			keepStaminaRegen()
		end
	end)

	AlicesFolder.ChildAdded:Connect(function(child)
		task.wait(1)
		if child:IsA("Model") and child:FindFirstChild("Humanoid") then
			child:SetAttribute("StaminaRegen", 100)
		end
	end)
end
