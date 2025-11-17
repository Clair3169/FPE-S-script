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
label.TextColor3 = Color3.fromRGB(255,255,255)
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

local trackedSounds = { quietHalls, properBehavior, studentSound }

local soundDurations = {
    [quietHalls] = 6*60,
    [properBehavior] = (2*60)+1,
    [studentSound] = (3*60)+16
}

local currentSound = nil
local hbConn = nil
local blinkingConn = nil
local pausedAnimConn = nil

local symbols = {"∆∆∆∆","!¡?¿","!¡!!!¿!!","??¡???!??","∆∆∆∆∆∆∆∆∆∆∆", "XD"}

local function format(sec)
    return string.format("%d:%02d", sec//60, sec%60)
end

local function isExcluded()
    local char = player.Character
    if not char or not char.Parent then return false end
    local parent = char.Parent.Name
    return parent == "Alices" or parent == "Teachers"
end

local function stopBlink()
    if blinkingConn then blinkingConn:Disconnect() end
    blinkingConn = nil
end

local function stopPausedAnim()
    if pausedAnimConn then pausedAnimConn:Disconnect() end
    pausedAnimConn = nil
end

local function stopTimer()
    if hbConn then hbConn:Disconnect() end
    hbConn = nil
    stopBlink()
    stopPausedAnim()
end

local function beginBlink()
    stopBlink()
    blinkingConn = RunService.Heartbeat:Connect(function()
        local t = tick() % 1
        label.TextColor3 = (t < 0.5)
            and Color3.fromRGB(255,0,0)
            or Color3.fromRGB(255,255,255)
    end)
end

local function update()
    if not currentSound then return end

    if not currentSound.IsPlaying then return end
    stopPausedAnim()

    local dur = soundDurations[currentSound]
    local rem = math.max(dur - currentSound.TimePosition, 0)
    label.Text = format(rem)
    label.Visible = true

    if rem <= 26 then
        if not blinkingConn then beginBlink() end
    else
        stopBlink()
        label.TextColor3 = Color3.fromRGB(255,255,255)
    end
end

local function beginTimer(s)
    stopTimer()
    currentSound = s
    hbConn = RunService.Heartbeat:Connect(update)
    update()
end

local function pausedAnim()
    stopBlink()
    stopPausedAnim()

    label.TextColor3 = Color3.fromRGB(255,0,0)
    local dur = soundDurations[currentSound]
    local rem = math.max(dur - currentSound.TimePosition, 0)

    local i = 0
    pausedAnimConn = RunService.Heartbeat:Connect(function(dt)
        i = i + dt*20
        label.Text = symbols[(math.floor(i)%#symbols)+1]
    end)

    task.delay(1, function()
        if pausedAnimConn then pausedAnimConn:Disconnect() end
        pausedAnimConn = nil
        label.Text = format(rem)
        label.TextColor3 = Color3.fromRGB(255,0,0)
    end)
end

local function onPlay(s)
    if isExcluded() then
        stopTimer()
        label.Visible = false
        return
    end

    label.Visible = true
    if table.find(trackedSounds, s) then
        beginTimer(s)
    end
end

local function onPause(s)
    if s == currentSound then
        pausedAnim()
    end
end

local function bind(s)
    s.Played:Connect(function() onPlay(s) end)
    s.Paused:Connect(function() onPause(s) end)
    s.Stopped:Connect(stopTimer)
end

for _,s in ipairs(trackedSounds) do bind(s) end

local function checkChar()
    if isExcluded() then
        stopTimer()
        label.Visible = false
        return
    end

    label.Visible = true
    for _, s in ipairs(trackedSounds) do
        if s.IsPlaying then beginTimer(s) return end
    end
    stopTimer()
end

player.CharacterAdded:Connect(function()
    task.wait(0.2)
    checkChar()
end)

task.defer(checkChar)
