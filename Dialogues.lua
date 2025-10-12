-- // LocalScript: Diálogo animado + sistema de respuestas (solo tras fade out) + seguridad
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Crear GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.Name = "FolderStatusGui"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- === Texto principal ===
local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 0, 28)
TextLabel.Position = UDim2.new(0, 0, 0.83, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextStrokeTransparency = 0
TextLabel.Font = Enum.Font.GothamMedium
TextLabel.TextScaled = true
TextLabel.Visible = false
TextLabel.ZIndex = 999999
TextLabel.Parent = ScreenGui

-- === Texto de respuesta ===
local ResponseLabel = Instance.new("TextLabel")
ResponseLabel.Size = UDim2.new(1, 0, 0, 22)
ResponseLabel.Position = UDim2.new(0, 0, 0.88, 0)
ResponseLabel.BackgroundTransparency = 1
ResponseLabel.TextStrokeTransparency = 0.5
ResponseLabel.Font = Enum.Font.Gotham
ResponseLabel.TextScaled = true
ResponseLabel.Visible = false
ResponseLabel.ZIndex = 999998
ResponseLabel.TextColor3 = Color3.fromRGB(210, 210, 210)
ResponseLabel.Parent = ScreenGui

-- Posición original
local originalPos = TextLabel.Position
local originalRot = TextLabel.Rotation

-- Carpetas válidas
local validFolders = {
	["Alices"] = true,
	["Teachers"] = true
}

-- Diálogos
local dialogues = {
	Alices = {
		"I'm hungry..",
		"Mission: KILL EVERYONE",
		"This will be so much fun.. HAHAHA",
		"Who will want to play with me?.",
		"My dinner is served"
	},
	Teachers = {
		"They all got F-...",
		"I will kill them all...",
		"I hate extra work shifts.",
		"All students are stupid.",
		"This is ridiculous, work at night argh!"
	}
}

-- Respuestas
local dialogueResponses = {
	["I'm hungry.."] = "...",
	["Mission: KILL EVERYONE"] = "Have mercy.",
	["This will be so much fun.. HAHAHA"] = "",
	["Who will want to play with me?."] = "...",
	["My dinner is served"] = "I hope you like it",
	["They all got F-..."] = "",
	["I will kill them all..."] = "",
	["I hate extra work shifts."] = "You chose this.",
	["All students are stupid."] = "XDDDDD",
	["This is ridiculous, work at night argh!"] = "Welcome to reality."
}

-- Tiempos
local fadeTime = 4
local delayBeforeShow = 3
local displayDurationTeachers = 11
local displayDurationAlices = 10
local responseDuration = 5

local currentFolder = nil

-- Seguridad de posición
local function ensureCorrectPosition()
	if TextLabel.Position ~= originalPos then
		TextLabel.Position = originalPos
	end
	if TextLabel.Rotation ~= originalRot then
		TextLabel.Rotation = originalRot
	end
end

-- Diálogo aleatorio
local function getRandomDialogue(folderName)
	local list = dialogues[folderName]
	if not list then return "" end
	return list[math.random(1, #list)]
end

-- Mostrar respuesta solo cuando el diálogo está completamente invisible
local function playResponse(dialogue)
	local response = dialogueResponses[dialogue]
	if not response then return end

	-- Mostrar respuesta
	ResponseLabel.Text = response
	ResponseLabel.TextTransparency = 1
	ResponseLabel.Visible = true

	-- Fade in
	TweenService:Create(ResponseLabel, TweenInfo.new(fadeTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{TextTransparency = 0}):Play()

	task.wait(responseDuration)

	-- Fade out
	TweenService:Create(ResponseLabel, TweenInfo.new(fadeTime / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{TextTransparency = 1}):Play()
	task.wait(fadeTime / 2)
	ResponseLabel.Visible = false
end

-- Animación Teachers
local function animateTeachers(dialogue)
	task.wait(delayBeforeShow)
	ensureCorrectPosition()

	TextLabel.TextTransparency = 1
	TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0)
	TextLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0)
	TextLabel.Visible = true

	-- Fade in
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{TextTransparency = 0}):Play()

	task.wait(displayDurationTeachers - fadeTime * 2)

	-- Fade out completo
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{TextTransparency = 1}):Play()
	task.wait(fadeTime)

	TextLabel.Visible = false
	task.wait(0.1) -- aseguramos invisibilidad total

	-- Mostrar respuesta solo ahora
	playResponse(dialogue)
end

-- Animación Alices
local function animateAlices(dialogue)
	task.wait(delayBeforeShow)
	ensureCorrectPosition()

	TextLabel.TextTransparency = 1
	TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
	TextLabel.TextStrokeColor3 = Color3.fromRGB(139,0,0)
	TextLabel.Visible = true

	local waveAmplitude = 0.03
	local waveDuration = 1.2
	local rotationAmplitude = 2
	local running = true

	-- Fade in
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{TextTransparency = 0}):Play()

	-- Movimiento tipo ola
	task.spawn(function()
		local t = 0
		while running do
			t += RunService.Heartbeat:Wait()
			local offset = math.sin(t * (math.pi * 2 / waveDuration)) * waveAmplitude
			TextLabel.Position = originalPos + UDim2.new(0, 0, offset, 0)
		end
	end)

	-- Rotación alternante
	task.spawn(function()
		while running do
			TextLabel.Rotation = rotationAmplitude
			task.wait(waveDuration / 2)
			TextLabel.Rotation = -rotationAmplitude
			task.wait(waveDuration / 2)
		end
	end)

	-- Palpitar borde
	task.spawn(function()
		while running do
			TweenService:Create(TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextStrokeTransparency = 0.5}):Play()
			task.wait(0.5)
			TweenService:Create(TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
				{TextStrokeTransparency = 0}):Play()
			task.wait(0.5)
		end
	end)

	task.wait(displayDurationAlices - fadeTime * 2)

	-- Fade out completo
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{TextTransparency = 1}):Play()
	task.wait(fadeTime)

	running = false
	ensureCorrectPosition()
	TextLabel.Visible = false
	TextLabel.TextStrokeTransparency = 0

	task.wait(0.1) -- aseguramos invisibilidad total
	playResponse(dialogue)
end

-- Mostrar diálogo
local function showDialogue(folderName)
	local dialogue = getRandomDialogue(folderName)
	TextLabel.Text = dialogue
	TextLabel.TextTransparency = 0

	if folderName == "Teachers" then
		task.spawn(animateTeachers, dialogue)
	elseif folderName == "Alices" then
		task.spawn(animateAlices, dialogue)
	end
end

-- Ocultar todo
local function hideDialogue()
	TextLabel.Visible = false
	ResponseLabel.Visible = false
end

-- Detección de carpeta
local currentFolder = nil
local function checkFolder()
	local char = player.Character
	if not char then return end

	local parent = char.Parent
	if parent and validFolders[parent.Name] then
		if currentFolder ~= parent.Name then
			currentFolder = parent.Name
			showDialogue(currentFolder)
		end
	else
		if currentFolder then
			hideDialogue()
			currentFolder = nil
		end
	end
end

-- Conexiones
RunService.Heartbeat:Connect(checkFolder)
player.CharacterAdded:Connect(function(char)
	char.AncestryChanged:Connect(checkFolder)
end)

if player.Character then
	checkFolder()
end
