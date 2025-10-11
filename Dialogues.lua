-- // LocalScript: Diálogo animado con bordes y animaciones
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- Crear GUI principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.DisplayOrder = 999999
ScreenGui.Name = "FolderStatusGui"
ScreenGui.Parent = player:WaitForChild("PlayerGui")

-- Crear TextLabel
local TextLabel = Instance.new("TextLabel")
TextLabel.Size = UDim2.new(1, 0, 0, 28)
TextLabel.Position = UDim2.new(0, 0, 0.83, 0)
TextLabel.BackgroundTransparency = 1
TextLabel.TextStrokeTransparency = 0 -- visible siempre
TextLabel.Font = Enum.Font.GothamMedium
TextLabel.TextScaled = true
TextLabel.Visible = false
TextLabel.ZIndex = 999999
TextLabel.Parent = ScreenGui

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

local currentFolder = nil
local fadeTime = 4
local delayBeforeShow = 3
local displayDurationTeachers = 11
local displayDurationAlices = 10

-- Obtener diálogo aleatorio
local function getRandomDialogue(folderName)
	local list = dialogues[folderName]
	if not list then return "" end
	return list[math.random(1, #list)]
end

-- Animación para Teachers
local function animateTeachers()
	task.wait(delayBeforeShow)
	TextLabel.TextTransparency = 1
	TextLabel.TextColor3 = Color3.fromRGB(255, 0, 0) -- rojo
	TextLabel.TextStrokeColor3 = Color3.fromRGB(0,0,0) -- borde negro estático
	TextLabel.Visible = true

	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{TextTransparency = 0}):Play()
	task.wait(displayDurationTeachers - fadeTime * 2)
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{TextTransparency = 1}):Play()
	task.wait(fadeTime)
	TextLabel.Visible = false
end

-- Animación para Alices (olas + rotación + borde palpitante)
local function animateAlices()
	task.wait(delayBeforeShow)
	TextLabel.TextTransparency = 1
	TextLabel.TextColor3 = Color3.fromRGB(0, 0, 0) -- negro
	TextLabel.TextStrokeColor3 = Color3.fromRGB(139,0,0) -- rojo oscuro
	TextLabel.Visible = true

	local originalPos = TextLabel.Position
	local waveAmplitude = 0.03
	local waveDuration = 1.2
	local rotationAmplitude = 2
	local running = true

	-- Fade in
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
		{TextTransparency = 0}):Play()

	-- Movimiento tipo ola y rotación
	task.spawn(function()
		while running do
			local upTween = TweenService:Create(TextLabel, TweenInfo.new(waveDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
				{Position = originalPos - UDim2.new(0, 0, waveAmplitude, 0)})
			upTween:Play()
			upTween.Completed:Wait()

			local downTween = TweenService:Create(TextLabel, TweenInfo.new(waveDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
				{Position = originalPos + UDim2.new(0, 0, waveAmplitude, 0)})
			downTween:Play()
			downTween.Completed:Wait()
		end
	end)

	task.spawn(function()
		while running do
			TextLabel.Rotation = rotationAmplitude
			task.wait(waveDuration/2)
			TextLabel.Rotation = -rotationAmplitude
			task.wait(waveDuration/2)
		end
	end)

	-- Palpitar borde rojo oscuro
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

	-- Fade out
	TweenService:Create(TextLabel, TweenInfo.new(fadeTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In),
		{TextTransparency = 1}):Play()
	task.wait(fadeTime)

	running = false
	TextLabel.Position = originalPos
	TextLabel.Rotation = 0
	TextLabel.Visible = false
	TextLabel.TextStrokeTransparency = 0
end

-- Mostrar diálogo
local function showDialogue(folderName)
	TextLabel.Text = getRandomDialogue(folderName)
	TextLabel.TextTransparency = 0

	if folderName == "Teachers" then
		task.spawn(animateTeachers)
	elseif folderName == "Alices" then
		task.spawn(animateAlices)
	end
end

-- Ocultar texto
local function hideDialogue()
	TextLabel.Visible = false
end

-- Comprobar carpeta actual
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
