-- 📜 Script: Etiquetas "Script in beta" y "Ctrl = InfStamina" (versión final)

-- Crear la interfaz principal (ScreenGui)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusLabels"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")

-- Función para crear etiquetas
local function createLabel(text, color, position)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 0, 22)
	label.Position = position
	label.AnchorPoint = Vector2.new(0, 1)
	label.BackgroundTransparency = 1 -- 🔹 Fondo totalmente invisible
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.TextTransparency = 0.5 -- 🔹 Texto semitransparente
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 1 -- 🔹 Sin contorno
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Bottom
	label.Parent = screenGui
	return label
end

-- Crear las dos etiquetas con tus posiciones exactas
local greenLabel = createLabel("", Color3.fromRGB(0, 255, 0), UDim2.new(0, 5, 1, -15))
local redLabel = createLabel("Script in beta", Color3.fromRGB(255, 0, 0), UDim2.new(0, 5, 1, 0))
