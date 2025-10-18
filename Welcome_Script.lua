-- ======================================================
-- 💬 Random Dialogue Once (Espacio ultra reducido)
-- ======================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local dialogues = {
	"Welcome.",
	"HAPPY HALLOWEEN!!",
	"This script works more for mobile than for PC",
	"Did you read that this is in beta?",
	"Hi how are things? everything okay Bro?",
	"Hi",
	"this programming thing is veeeery difficult..."
}

-- GUI principal
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RandomDialogueGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = PlayerGui

-- 🖤 Cuadro de diálogo
local Frame = Instance.new("Frame")
Frame.AnchorPoint = Vector2.new(0.5, 1)
Frame.Position = UDim2.new(0.5, 0, 0.82, 0)
Frame.Size = UDim2.new(0.46, 0, 0.12, 0)
Frame.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
Frame.BorderSizePixel = 2
Frame.BorderColor3 = Color3.fromRGB(255, 255, 255)
Frame.Parent = ScreenGui

-- 📸 Imagen del personaje
local Image = Instance.new("ImageLabel")
Image.Size = UDim2.new(0.26, 0, 1.25, 0)
Image.Position = UDim2.new(-0.045, 0, -0.1, 0)
Image.BackgroundTransparency = 1
Image.Image = "rbxassetid://120898460944463"
Image.ScaleType = Enum.ScaleType.Fit
Image.Parent = Frame

-- ✍️ Texto del diálogo (mucho más pegado)
local DialogueLabel = Instance.new("TextLabel")
DialogueLabel.AnchorPoint = Vector2.new(0, 0.5)
DialogueLabel.Position = UDim2.new(0.212, 0, 0.5, 0) -- 👈 margen reducido 86%
DialogueLabel.Size = UDim2.new(0.76, 0, 0.8, 0)
DialogueLabel.BackgroundTransparency = 1
DialogueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DialogueLabel.TextScaled = true
DialogueLabel.Font = Enum.Font.GothamSemibold
DialogueLabel.TextWrapped = true
DialogueLabel.Text = ""
DialogueLabel.Parent = Frame

-- Diálogo aleatorio
local randomDialogue = dialogues[math.random(1, #dialogues)]

-- 🌀 Animación flotante + rotación suave
local startTime = tick()
local amplitudeX = 6
local amplitudeY = 3
local rotAmplitude = 8
local speed = 2.2

local connection
connection = RunService.RenderStepped:Connect(function()
	local t = tick() - startTime
	local offsetX = math.sin(t * speed) * amplitudeX
	local offsetY = math.cos(t * speed) * amplitudeY
	Image.Position = UDim2.new(-0.045, offsetX, -0.1, offsetY)
	Image.Rotation = math.sin(t * speed * 0.8) * rotAmplitude
end)

-- ✨ Efecto de escritura
local function typewrite(text)
	DialogueLabel.Text = ""
	for i = 1, #text do
		DialogueLabel.Text = string.sub(text, 1, i)
		task.wait(0.035)
	end
end

-- Mostrar el diálogo
typewrite(randomDialogue)

task.wait(4)

-- 💨 Desvanecimiento suave
for i = 0, 1, 0.05 do
	Frame.BackgroundTransparency = i
	DialogueLabel.TextTransparency = i
	Image.ImageTransparency = i
	task.wait(0.05)
end

if connection then connection:Disconnect() end
ScreenGui:Destroy()
script:Destroy()
