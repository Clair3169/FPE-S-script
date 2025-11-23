--============================================================--
-- CONFIG
--============================================================--
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remoteEvent = ReplicatedStorage:WaitForChild("ReliableRedEvent")

local teachersFolder = Workspace:WaitForChild("Teachers")
local alicesFolder   = Workspace:WaitForChild("Alices")

local RANGE = 15
local args  = { { ["^"] = { { n = 0 } } }, {} }

--============================================================--
-- PERSONAJE
--============================================================--
local character = player.Character or player.CharacterAdded:Wait()
local rootPart  = character:WaitForChild("HumanoidRootPart")

player.CharacterAdded:Connect(function(newChar)
	character = newChar
	rootPart = newChar:WaitForChild("HumanoidRootPart")
end)

--============================================================--
-- EQUIPOS
--============================================================--

local function getTeamFolder(model)
	local parent = model and model.Parent
	if parent == teachersFolder then return "Teacher" end
	if parent == alicesFolder   then return "Alice" end
	return "None"
end

local function isFriendlyHit(attackerModel)
	local myTeam       = getTeamFolder(character)
	local attackerTeam = getTeamFolder(attackerModel)
	return myTeam == attackerTeam
end

--============================================================--
-- CORE
--============================================================--

local function executeBlock()
	remoteEvent:FireServer(unpack(args))
end

local function checkAndBlock(parentPart)
	if not rootPart or not parentPart then return end

	local model = parentPart.Parent
	if not model then return end

	if isFriendlyHit(model) then
		return
	end

	if (rootPart.Position - parentPart.Position).Magnitude <= RANGE then
		executeBlock()
	end
end

--============================================================--
-- HANDLER SUPREMO ESTABLE
--============================================================--

local function attachUltraFastHooks(sound)
	if not sound:IsA("Sound") then return end

	local name = sound.Name
	local isAtk = (name == "SwingSFX" or name == "Swing")
	if not isAtk then return end

	-- Evitar duplicar conexiones
	if sound:FindFirstChild("AntiDup") then return end
	Instance.new("BoolValue", sound).Name = "AntiDup"

	------------------------------------------------------------
	-- 0. Si aparece sin Parent aún, esperamos su primer Parent real
	------------------------------------------------------------
	if not sound.Parent then
		sound.AncestryChanged:Connect(function(_, parent)
			if parent and sound.Parent then
				checkAndBlock(sound.Parent)
			end
		end)
		return
	end

	------------------------------------------------------------
	-- 1. Spawn detection (primer frame con parent)
	------------------------------------------------------------
	checkAndBlock(sound.Parent)

	------------------------------------------------------------
	-- 2. AncestryChanged → el sonido se reasigna de nil → brazo
	------------------------------------------------------------
	sound.AncestryChanged:Connect(function(_, parent)
		if parent and sound.Parent then
			checkAndBlock(sound.Parent)
		end
	end)

	------------------------------------------------------------
	-- 3. Played (solo como respaldo)
	------------------------------------------------------------
	sound.Played:Connect(function()
		if sound.Parent then
			checkAndBlock(sound.Parent)
		end
	end)
end

--============================================================--
-- MONITOREO
--============================================================--

local function monitorFolder(folder)
	folder.DescendantAdded:Connect(attachUltraFastHooks)
	for _, d in ipairs(folder:GetDescendants()) do
		attachUltraFastHooks(d)
	end
end

monitorFolder(teachersFolder)
monitorFolder(alicesFolder)
