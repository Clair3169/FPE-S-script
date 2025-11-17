local SoundService = game:GetService("SoundService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer or Players:GetPlayers()[1]
local playerGui = player:WaitForChild("PlayerGui")

local screenGui = playerGui:FindFirstChild("MusicTimerGui") or Instance.new("ScreenGui")
screenGui.Name = "MusicTimerGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local label = screenGui:FindFirstChild("TimerLabel") or Instance.new("TextLabel")
label.Name = "TimerLabel"
label.Size = UDim2.new(0, 90, 0, 28)
label.Position = UDim2.new(0.5, -45, 0, -3)
label.BackgroundTransparency = 1
label.TextColor3 = Color3.fromRGB(255, 255, 255)
label.TextScaled = true
label.Font = Enum.Font.GothamBold
label.Text = "0:00"
label.Visible = true
label.Parent = screenGui

local phaseSongs = SoundService:WaitForChild("AllMusic"):WaitForChild("PhaseSongs")
local baseFolder = phaseSongs:WaitForChild("Base")
local phase2Folder = phaseSongs:WaitForChild("Phase2")

local quietHalls = baseFolder:WaitForChild("QuietHalls")
local properBehavior = baseFolder:WaitForChild("ProperBehavior")
local studentSound = phase2Folder:WaitForChild("Student")

local trackedSounds = {
	quietHalls,
	properBehavior,
	studentSound
}

local soundDurations = {
	[quietHalls] = 6*60,
	[properBehavior] = (2*60)+1,
	[studentSound] = (3*60)+16
}

local currentSound = nil
local hbConn = nil
local char = nil

local function format(sec)
	return string.format("%d:%02d", sec//60, sec%60)
end

local function isExcluded()
	char = player.Character
	if not char then return false end
	local parent = char.Parent
	if not parent then return false end
	return parent.Name == "Alices" or parent.Name == "Teachers"
end

local function stopTimer()
	if hbConn then hbConn:Disconnect() end
	hbConn = nil
end

local function update()
	if not currentSound then return end

	local dur = soundDurations[currentSound]
	local rem = math.max(dur - currentSound.TimePosition, 0)

	label.Text = format(rem)
	label.TextColor3 = (rem <= 26)
		and Color3.fromRGB(255,0,0)
		or Color3.fromRGB(255,255,255)

	if rem <= 0 then
		currentSound = nil
		label.Text = "0:00"
		stopTimer()
	end
end

local function onPlay(s)
	if isExcluded() then return end
	if table.find(trackedSounds, s) then
		currentSound = s
		if not hbConn then
			hbConn = RunService.Heartbeat:Connect(update)
		end
		update()
	end
end

local function bind(s)
	s.Played:Connect(function() onPlay(s) end)
	s.Stopped:Connect(function()
		label.Text = "0:00"
		stopTimer()
	end)
	s.Paused:Connect(update)
end

for _, s in ipairs(trackedSounds) do
	bind(s)
end

local function checkCharacter()
	if isExcluded() then
		label.Visible = false
		stopTimer()
		return
	end
	
	label.Visible = true

	for _, s in ipairs(trackedSounds) do
		if s.IsPlaying then
			onPlay(s)
			return
		end
	end
end

player.CharacterAdded:Connect(function()
	task.wait(0.2)
	checkCharacter()
end)

task.defer(checkCharacter)
