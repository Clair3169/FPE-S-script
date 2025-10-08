-- 📜 Script: Etiquetas "Script in beta" y "Ctrl = InfStamina" (versión mejorada)

-- Crear la interfaz principal (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusLabels"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Función para crear etiquetas
local function createLabel(text, color, yOffset)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 0, 22)
	label.Position = UDim2.new(0, 5, 1, -5 + yOffset) -- esquina inferior izquierda
	label.AnchorPoint = Vector2.new(0, 1)
	label.BackgroundTransparency = 1 -- 🔹 Fondo completamente invisible
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.5 -- contorno leve
	label.TextXAlignment = Enum.TextXAlignment.Left -- alineado a la izquierda
	label.TextYAlignment = Enum.TextYAlignment.Bottom
	label.Parent = screenGui
	return label
end

-- Crear las dos etiquetas
local greenLabel = createLabel("Ctrl = InfStamina", Color3.fromRGB(0, 255, 0), -25) -- verde arriba
local redLabel = createLabel("Script in beta", Color3.fromRGB(255, 0, 0), 0)       -- rojo abajo
