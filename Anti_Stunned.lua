-- ======================================================
-- 🟢 CLIENTE: Protección de Stunned + Velocidad Persistente
-- ======================================================

repeat task.wait() until game:IsLoaded()

-- Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local character = nil
local heartbeatConnection = nil

-- ==============================
-- CONFIGURACIÓN DE VELOCIDADES
-- ==============================

local speedSettings = {
	["Alice"] = 31,
	["Thavel"] = 28,
	["Circle"] = 28,
	["Bloomie"] = 27
}

-- ==============================
-- PROTECCIÓN DE STUNNED
-- ==============================

local allowedFolders = {"Alices", "Teachers"}

local function isInAllowedFolder(character)
	if not character or not character.Parent then return false end
	for _, folderName in ipairs(allowedFolders) do
		local folder = Workspace:FindFirstChild(folderName)
		if folder and character:IsDescendantOf(folder) then
			return true
		end
	end
	return false
end

local function findStunnedHandler(character)
	if not character then return nil end

	-- Caso 1: Atributo
	if character:GetAttribute("Stunned") ~= nil then
		return {
			get = function() return character:GetAttribute("Stunned") end,
			set = function(v) character:SetAttribute("Stunned", v) end,
			connect = function(cb) return character:GetAttributeChangedSignal("Stunned"):Connect(cb) end
		}
	end

	-- Caso 2: BoolValue dentro de Attributes
	local attrs = character:FindFirstChild("Attributes")
	if attrs then
		local b = attrs:FindFirstChild("Stunned")
		if b and b:IsA("BoolValue") then
			return {
				get = function() return b.Value end,
				set = function(v) b.Value = v end,
				connect = function(cb) return b.Changed:Connect(cb) end
			}
		end
	end

	-- Caso 3: BoolValue directo
	local direct = character:FindFirstChild("Stunned")
	if direct and direct:IsA("BoolValue") then
		return {
			get = function() return direct.Value end,
			set = function(v) direct.Value = v end,
			connect = function(cb) return direct.Changed:Connect(cb) end
		}
	end

	return nil
end

local function protectCharacter(character)
	local handler = findStunnedHandler(character)

	if not handler then
		character.ChildAdded:Connect(function(child)
			if child.Name == "Attributes" or child.Name == "Stunned" then
				task.wait(0.1)
				protectCharacter(character)
			end
		end)
		return
	end

	if isInAllowedFolder(character) then
		handler.set(false)
	end

	handler.connect(function()
		if handler.get() == true and isInAllowedFolder(character) then
			handler.set(false)
		end
	end)

	character.AncestryChanged:Connect(function()
		if isInAllowedFolder(character) then
			handler.set(false)
		end
	end)
end

-- ==============================
-- VELOCIDAD PERSISTENTE
-- ==============================

local function checkAndEnforceSpeed()
	if not character or not character.Parent then
		return
	end

	local alicesFolder = Workspace:FindFirstChild("Alices")
	local teachersFolder = Workspace:FindFirstChild("Teachers")
	local studentsFolder = Workspace:FindFirstChild("Students")

	local isInAlices = alicesFolder and character:IsDescendantOf(alicesFolder)
	local isInTeachers = teachersFolder and character:IsDescendantOf(teachersFolder)
	local isInStudents = studentsFolder and character:IsDescendantOf(studentsFolder)

	if isInAlices or isInTeachers then
		local teacherName = character:GetAttribute("TeacherName")
		if teacherName then
			local requiredSpeed = speedSettings[teacherName]
			if requiredSpeed then
				character:SetAttribute("RunSpeed", requiredSpeed)
			end
		end
	elseif isInStudents then
		character:SetAttribute("RunSpeed", 30)
	else
		character:SetAttribute("RunSpeed", 27)
	end
end

-- ==============================
-- CONEXIÓN PRINCIPAL
-- ==============================

local function onCharacterAdded(newCharacter)
	character = newCharacter

	if heartbeatConnection then
		heartbeatConnection:Disconnect()
	end

	task.wait(0.5)
	protectCharacter(character)
	heartbeatConnection = RunService.Heartbeat:Connect(checkAndEnforceSpeed)
end

if LocalPlayer.Character then
	onCharacterAdded(LocalPlayer.Character)
end

LocalPlayer.CharacterAdded:Connect(onCharacterAdded)
