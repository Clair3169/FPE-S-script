--============================================================--
-- AUTO-BLOCK / PARRY MEJORADO (LocalScript)
--============================================================--

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("ReliableRedEvent")

local teachersFolder = Workspace:WaitForChild("Teachers")
local alicesFolder   = Workspace:WaitForChild("Alices")
local studentsFolder = Workspace:WaitForChild("Students")

local RANGE = 16
local PREDICTION_BUFFER = 2
local TRUE_RANGE = RANGE + PREDICTION_BUFFER * 4

local ARGS  = { { ["^"] = { { n = 0 } } }, {} }

local myRoot = nil
local myTeam = "None"

local soundLastTriggered = setmetatable({}, { __mode = "k" })
local attackerLastTriggered = setmetatable({}, { __mode = "k" })

local function updateTeamFromParent(parent)
	if parent == teachersFolder then
		myTeam = "Teachers"
	elseif parent == alicesFolder then
		myTeam = "Alices"
	elseif parent == studentsFolder then
		myTeam = "Students"
	else
		myTeam = "None"
	end
end

local function detectLocalTeam()
	local char = player.Character
	if not char then
		myRoot = nil
		myTeam = "None"
		return
	end

	myRoot = char:FindFirstChild("HumanoidRootPart")
	updateTeamFromParent(char.Parent)
	char:GetPropertyChangedSignal("Parent"):Connect(function()
		updateTeamFromParent(char.Parent)
	end)
end

player.CharacterAdded:Connect(detectLocalTeam)
detectLocalTeam()

local function shouldBlock(attackerFolder)
	if myTeam == "Teachers" then
		return attackerFolder == alicesFolder
	elseif myTeam == "Alices" then
		return attackerFolder == teachersFolder
	elseif myTeam == "Students" then
		return attackerFolder == teachersFolder or attackerFolder == alicesFolder
	else
		if attackerFolder == teachersFolder or attackerFolder == alicesFolder then return true end
		return true
	end
end

local function getAttackerTeam(model)
	if not model then return nil end
	local parent = model.Parent
	if parent == teachersFolder then return teachersFolder end
	if parent == alicesFolder then return alicesFolder end
	if parent == studentsFolder then return studentsFolder end
	return nil
end

local function tryBlock(attackerModel)
	local now = os.clock()
	if attackerModel then
		local last = attackerLastTriggered[attackerModel]
		if last and now - last < 0.03 then return end
		attackerLastTriggered[attackerModel] = now
	else
		local last = attackerLastTriggered.__global
		if last and now - last < 0.03 then return end
		attackerLastTriggered.__global = now
	end

	remoteEvent:FireServer(unpack(ARGS))
end

local function checkProximityAndPredict(enemyPart, attackerModel)
	if not myRoot or not enemyPart or not attackerModel then return end

	local attackerHRP = attackerModel:FindFirstChild("HumanoidRootPart")
	if not attackerHRP then return end

	local myPos = myRoot.Position
	local atkPos = attackerHRP.Position
	local toPlayer = myPos - atkPos
	local dist = toPlayer.Magnitude

	if dist > TRUE_RANGE then return end

	local atkVel = attackerHRP.Velocity
	local atkSpeed = atkVel.Magnitude
	local myVel = myRoot.Velocity
	local relVel = (atkVel - myVel).Magnitude

	local atkDirDot = 0
	if atkSpeed > 0.001 then
		atkDirDot = atkVel.Unit:Dot(toPlayer.Unit)
	end

	local estSpeed = math.max(atkSpeed, 6)
	local timeToReach = dist / estSpeed
	local predictionTime = math.min(timeToReach, PREDICTION_BUFFER)

	local predictedPos = atkPos + atkVel * predictionTime
	local predictedDist = (myPos - predictedPos).Magnitude

	local SHORT = 6
	local MEDIUM = 12
	local LONG = TRUE_RANGE

	local should = false

	if dist <= SHORT or predictedDist <= SHORT then
		should = true
	elseif dist <= MEDIUM or predictedDist <= MEDIUM then
		if atkSpeed > 1 or atkDirDot > 0.2 or relVel > 1.5 then
			should = true
		end
	else
		if atkSpeed > 8 and atkDirDot > 0.4 then
			should = true
		elseif predictedDist <= MEDIUM and (atkSpeed > 3 or atkDirDot > 0.2) then
			should = true
		end
	end

	if should then
		tryBlock(attackerModel)
	end
end

local function fastHook(descendant)
	if not descendant or not descendant:IsA("Sound") then return end

	local n = descendant.Name
	if not (n == "SwingSFX" or n == "Swing" or n == "Attack") then return end

	local sound = descendant
	if sound:GetAttribute("__autoParryHooked") then return end
	sound:SetAttribute("__autoParryHooked", true)

	local function trigger()
		local now = os.clock()
		local last = soundLastTriggered[sound]
		if last and now - last < 0.02 then return end
		soundLastTriggered[sound] = now

		local p = sound.Parent
		if not p then return end

		local attackerModel = p.Parent
		if not attackerModel then
			if p:IsA("Model") then attackerModel = p end
			if not attackerModel then return end
		end

		local attackerTeam = getAttackerTeam(attackerModel)

		if attackerTeam then
			if shouldBlock(attackerTeam) then
				checkProximityAndPredict(p, attackerModel)
			end
		else
			checkProximityAndPredict(p, attackerModel)
		end
	end

	pcall(function()
		sound.Played:Connect(trigger)
	end)

	sound:GetPropertyChangedSignal("Playing"):Connect(function()
		if sound.Playing then trigger() end
	end)

	if sound.Playing then trigger() end
end

local function startMonitoring(folder)
	for _, d in ipairs(folder:GetDescendants()) do
		pcall(function() fastHook(d) end)
	end
	folder.DescendantAdded:Connect(fastHook)
end

startMonitoring(teachersFolder)
startMonitoring(alicesFolder)
startMonitoring(studentsFolder)
