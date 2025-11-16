-- 📜 Script: Contador de jugadores + Diálogos súper compactos (Versión final, siempre encima)

-- Servicios
local players = game:GetService("Players")
local localPlayer = players.LocalPlayer

-- Crear la interfaz principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusLabels"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50 -- 👈 Siempre encima de todo
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Función para crear etiquetas de texto
local function createLabel(text, color, position)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 0, 20) -- compacto
	label.Position = position
	label.AnchorPoint = Vector2.new(0, 1)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.TextTransparency = 0.2
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Bottom
	label.Parent = screenGui
	return label
end

-- ============================================================
-- 🔹 Contador de Jugadores
-- ============================================================

local playerCountLabel = createLabel("Players: 0", Color3.fromRGB(0, 255, 0), UDim2.new(0, 2, 1, 0))
playerCountLabel.Name = "PlayerCountLabel"

local function updatePlayerCount()
	local totalPlayers = #players:GetPlayers()
	playerCountLabel.Text = "Players: " .. totalPlayers
end

players.PlayerAdded:Connect(updatePlayerCount)
players.PlayerRemoving:Connect(updatePlayerCount)
updatePlayerCount()

-- ============================================================
-- 🔹 Diálogos estáticos (encima del contador, bien pegados)
-- ============================================================

local dialogueConfig = {
	{text = "MD me on Discord: cesartorres6209", color = Color3.fromRGB(255, 0, 0)},
	{text = "Suggestions?", color = Color3.fromRGB(0, 255, 255)},
	-- {text = "Otro más", color = Color3.fromRGB(255, 0, 255)},
}

-- Base justo encima del contador
local baseY = -15 -- justo encima de “Jugadores”
local offset = 18 + 1 -- altura del texto + 1 píxel de separación mínima

-- Crear cada diálogo, apilándolos hacia arriba
for i, config in ipairs(dialogueConfig) do
	local posY = baseY - ((i - 1) * offset)
	createLabel(config.text, config.color, UDim2.new(0, 2, 1, posY))
end
