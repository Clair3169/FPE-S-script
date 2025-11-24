-- 📜 Script: Status Labels Fusionado (Ping + Jugadores + Diálogos Custom)

-- Servicios
local players = game:GetService("Players")
local stats = game:GetService("Stats") -- ✅ Agregado para el Ping
local localPlayer = players.LocalPlayer

-- Crear la interfaz principal
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "StatusLabels"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50 -- Siempre encima
screenGui.Parent = localPlayer:WaitForChild("PlayerGui")

-- Función para crear etiquetas de texto
local function createLabel(text, color, position)
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(0, 200, 0, 20)
	label.Position = position
	label.AnchorPoint = Vector2.new(0, 1)
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	label.Text = text
	label.TextColor3 = color
	label.TextTransparency = 0.2 -- Mantenemos el estilo de tu script antiguo (más visible)
	label.TextScaled = true
	label.Font = Enum.Font.SourceSansBold
	label.TextStrokeTransparency = 1
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextYAlignment = Enum.TextYAlignment.Bottom
	label.Parent = screenGui
	return label
end

-- ============================================================
-- 🔹 1. Contador de Jugadores
-- ============================================================
-- Posición: Base (0 px)
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
-- 🔹 2. Ping Monitor (Agregado del script nuevo)
-- ============================================================
-- Posición: -15 px (Justo encima de Players)
local pingLabel = createLabel("Ping: 0", Color3.fromRGB(255, 255, 255), UDim2.new(0, 2, 1, -15))
pingLabel.TextTransparency = 0.3 -- El ping se ve mejor totalmente opaco

-- Referencia directa al valor de Ping
local performanceStats = stats:WaitForChild("Network"):WaitForChild("ServerStatsItem"):WaitForChild("Data Ping")

local function updatePingRecursive()
	-- Obtenemos valor actual
	local pingValue = performanceStats:GetValue()
	local pingInt = math.floor(pingValue + 0.5) -- Redondear
	
	-- Lógica de color
	if pingInt == 0 then
		pingLabel.TextColor3 = Color3.fromRGB(139, 0, 0) -- Error
	elseif pingInt < 100 then
		pingLabel.TextColor3 = Color3.fromRGB(0, 255, 0) -- Verde
	elseif pingInt < 250 then
		pingLabel.TextColor3 = Color3.fromRGB(247, 241, 141) -- Amarillo
	else
		pingLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- Rojo
	end
	
	pingLabel.Text = "Ping: " .. pingInt .. " ms"

	-- Recursión programada (Optimización)
	task.delay(1.7, updatePingRecursive)
end

updatePingRecursive()

-- ============================================================
-- 🔹 3. Diálogos estáticos (Tus textos)
-- ============================================================

local dialogueConfig = {
	{text = "MD me on Discord: cesartorres6209", color = Color3.fromRGB(255, 0, 0)},
	{text = "Suggestions?", color = Color3.fromRGB(0, 255, 255)},
	-- {text = "Otro más", color = Color3.fromRGB(255, 0, 255)},
}

local labelHeight = 10
local spacing = 1

-- ⚠️ CAMBIO IMPORTANTE:
-- Antes el baseY era -15. Ahora es -35 para dejar espacio al Ping que insertamos.
local baseY = -35 
local offset = labelHeight + spacing 

for i, config in ipairs(dialogueConfig) do
	local posY = baseY - ((i - 1) * offset)
	createLabel(config.text, config.color, UDim2.new(0, 2, 1, posY))
end
