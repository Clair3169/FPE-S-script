-- =====================================================
-- 🟣 ShiftLock con control persistente de Frame y UiStroke
-- Mantiene el Frame visible cuando Thickness = 1.5 hasta que cambie
-- v2 (Optimizada)
-- =====================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ContextActionService = game:GetService("ContextActionService")
local CoreGui = game:GetService("CoreGui")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local hasThirdPerson = player:WaitForChild("ThirdPersonEnabled", 10)
if not hasThirdPerson then return end

if not hasThirdPerson.Value then
	local gui = CoreGui:FindFirstChild("Shiftlock (CoreGui)")
	if gui then gui:Destroy() end
	return
end

-- 📦 Interfaz
local ShiftLockScreenGui = Instance.new("ScreenGui")
local ShiftLockButton = Instance.new("ImageButton")
local ShiftlockCursor = Instance.new("ImageLabel")

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
ShiftLockButton.BackgroundTransparency = 1
ShiftLockButton.AnchorPoint = Vector2.new(1, 1)
ShiftLockButton.Position = UDim2.new(1, 0, 1, 0)
ShiftLockButton.Size = UDim2.new(0.1, 5, 0.1, 5)
ShiftLockButton.SizeConstraint = Enum.SizeConstraint.RelativeYY
ShiftLockButton.Image = States.Off
ShiftLockButton.Visible = true

ShiftlockCursor.Name = "ShiftlockCursor"
ShiftlockCursor.Parent = ShiftLockScreenGui
ShiftlockCursor.Image = States.Lock
ShiftlockCursor.AnchorPoint = Vector2.new(0.5, 0.5)
ShiftlockCursor.BackgroundTransparency = 1
ShiftlockCursor.Visible = false -- Cursor siempre invisible
ShiftlockCursor.Size = UDim2.new(0, 27, 0, 27)

-- 🧭 Posición del cursor
local verticalOffset = -57
local horizontalOffset = 0
local viewport = camera.ViewportSize
local centerX = viewport.X / 2
local centerY = viewport.Y / 2

camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
	viewport = camera.ViewportSize
	centerX = viewport.X / 2
	centerY = viewport.Y / 2
end)

-- 🎯 Objetos en Debris/FakeCursor
local debrisFolder = Workspace:FindFirstChild("Debris")
local fakeCursor = debrisFolder and debrisFolder:FindFirstChild("FakeCursor")
local fakeCursorAttachment = fakeCursor and fakeCursor:FindFirstChild("Attachment")
local fakeCursorGui = fakeCursorAttachment and fakeCursorAttachment:FindFirstChild("BillboardGui")
local frame = fakeCursorGui and fakeCursorGui:FindFirstChild("Frame")
local uiScale = frame and frame:FindFirstChildOfClass("UIScale")
local uiStroke = frame and frame:FindFirstChildOfClass("UIStroke")

-- ⚙️ Sistema de control persistente del frame
local frameControlledByStroke = false
local TOLERANCE = 0.01 -- precisión estricta, pero estable

if uiStroke then
	uiStroke:GetPropertyChangedSignal("Thickness"):Connect(function()
		if not frame then return end

		-- Si Thickness = 1.5 (con tolerancia) → mantener visible
		if math.abs(uiStroke.Thickness - 1.5) <= TOLERANCE then
			if not frameControlledByStroke then
				frameControlledByStroke = true
				frame.Visible = true
			end
		else
			-- Cuando cambie de 1.5 → liberar y ocultar
			if frameControlledByStroke then
				frameControlledByStroke = false
				frame.Visible = false
			end
		end
	end)

	-- Estado inicial (por si ya estaba en 1.5 al iniciar)
	if frame and math.abs(uiStroke.Thickness - 1.5) <= TOLERANCE then
		frameControlledByStroke = true
		frame.Visible = true
	end
end

-- 🧍‍♂️ Lógica de ShiftLock (Optimizada)
local function toggleShiftLock()
	if not Active then
		-- ⭐ [OPTIMIZACIÓN] Verificar personaje y humanoide ANTES de conectar el bucle
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		
		if not humanoid then return end -- No activar si no hay humanoide

		-- ⭐ [OPTIMIZACIÓN] Establecer propiedades UNA SOLA VEZ al activar
		humanoid.AutoRotate = false
		ShiftLockButton.Image = States.On
		ShiftlockCursor.Visible = false -- Cursor invisible

		-- Frame solo se oculta si no está controlado por Stroke
		if frame and not frameControlledByStroke then
			frame.Visible = false
		end

		-- ⭐ [OPTIMIZACIÓN] El bucle RenderStepped ahora SOLO hace lo esencial (actualizar CFrame)
		Active = RunService.RenderStepped:Connect(function()
			-- Volver a comprobar el RootPart por si el jugador muere/respawnea
			local currentCharacter = player.Character
			local root = currentCharacter and currentCharacter:FindFirstChild("HumanoidRootPart")

			if root then
				root.CFrame = CFrame.new(
					root.Position,
					Vector3.new(
						camera.CFrame.LookVector.X * MaxLength,
						root.Position.Y,
						camera.CFrame.LookVector.Z * MaxLength
					)
				)
				camera.CFrame = camera.CFrame * EnabledOffset
				camera.Focus = CFrame.fromMatrix(
					camera.Focus.Position,
					camera.CFrame.RightVector,
					camera.CFrame.UpVector
				) * EnabledOffset
			end
		end)
	else
		-- ⭐ [OPTIMIZACIÓN] Desconectar el bucle PRIMERO
		pcall(function()
			Active:Disconnect()
			Active = nil
		end)
		
		-- ⭐ [OPTIMIZACIÓN] Aplicar cambios de estado DESPUÉS de desconectar
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.AutoRotate = true
		end
		
		ShiftLockButton.Image = States.Off
		camera.CFrame = camera.CFrame * DisabledOffset
		ShiftlockCursor.Visible = false

		-- Solo modificar visibilidad si no lo controla Stroke
		if frame then
			if not frameControlledByStroke then
				if uiStroke and uiStroke.Thickness ~= 1.5 then
					frame.Visible = true
				else
					frame.Visible = false
				end
			end
		end
	end
end

-- 🖥️ Entrada (PC o móvil)
local isPC = UserInputService.KeyboardEnabled
if isPC then
	ShiftLockButton.Visible = false

	local function handleKeyInput(actionName, inputState, inputObject)
		if inputState == Enum.UserInputState.Begin then
			toggleShiftLock()
		end
	end

	ContextActionService:BindAction("CustomShiftLockToggle", handleKeyInput, false, Enum.KeyCode.LeftControl, Enum.KeyCode.RightControl)
else
	ShiftLockButton.MouseButton1Click:Connect(toggleShiftLock)
end

-- Acción virtual (dummy)
local function ShiftLock() end
ContextActionService:BindAction("Shift Lock", ShiftLock, false, "On")
ContextActionService:SetPosition("Shift Lock", UDim2.new(1, -70, 1, -70))
