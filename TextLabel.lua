-- 📜 Script: Etiquetas "Script in beta" y "Ctrl = InfStamina"

-- Crear la interfaz principal (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusLabels"
screenGui.ResetOnSpawn = false
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Función para crear etiquetas
local function createLabel(text, color, yOffset)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 150, 0, 20)
	label.Position = UDim2.new(0, 10, 1, -30 + yOffset) -- Esquina inferior izquierda
	label.AnchorPoint = Vector2.new(0, 1)
	label.BackgroundTransparency = 0.3
	label.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 0.7
	label.Parent = screenGui
	return label
end

-- Crear las dos etiquetas
local greenLabel = createLabel("Ctrl = InfStamina", Color3.fromRGB(0, 255, 0), -22) -- Verde arriba
local redLabel = createLabel("Script in beta", Color3.fromRGB(255, 0, 0), 0)       -- Rojo abajo

