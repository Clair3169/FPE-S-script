-- =====================================================
-- 🎯 Aimbot combinado: 
--    📘 LibraryBook mode → targets = Teachers + Alice (TORSO)
--    🍎 Bloomie mode → targets = Students (HEAD)
-- =====================================================

repeat task.wait() until game:IsLoaded()

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- ⚙️ CONFIGURACIÓN
local STUDENTS_FOLDER = "Students"
local LIBRARY_TARGET_FOLDERS = {"Teachers", "Alice"}   -- 🎯 solo Teachers y Alice
local BLOOMIE_TARGET_FOLDER = "Students"

-- Prioridades de partes
local TARGET_PRIORITY_TORSO = {"UpperTorso", "Torso", "HumanoidRootPart", "Head"} -- LibraryBook
local TARGET_PRIORITY_HEAD = {"Head", "UpperTorso", "HumanoidRootPart"}           -- Bloomie

-- Sensibilidad del ángulo y offsets
local ANGLE_THRESHOLD = 0.85
local CAMERA_HEIGHT_OFFSET_TORSO = Vector3.new(0, 0, 0)
local CAMERA_HEIGHT_OFFSET_HEAD = Vector3.new(0, 0.3, 0)

-- Variables principales
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local currentTarget = nil

-- =====================================================
-- 🔧 FUNCIONES AUXILIARES
-- =====================================================

local function hasLibraryBook(character)
	if not character then return false end
	for _, obj in ipairs(character:GetChildren()) do
		if obj:IsA("Tool") and obj.Name == "LibraryBook" then
			return true
		end
	end
	return false
end

local function getModelsFromFolder(folderName)
	local models = {}
	local folder = Workspace:FindFirstChild(folderName)
	if not folder then return models end
	for _, child in ipairs(folder:GetChildren()) do
		if child:IsA("Model") then
			table.insert(models, child)
		end
	end
	return models
end

local function getTargetPartByPriority(model, priorityList)
	for _, name in ipairs(priorityList) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

local function chooseTarget(models, priorityList)
	if #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local bestModel = nil
	local bestDot = -1

	for _, model in ipairs(models) do
		local part = getTargetPartByPriority(model, priorityList)
		if part then
			local dir = part.Position - camPos
			if dir.Magnitude > 0 then
				local dot = camLook:Dot(dir.Unit)
				if dot > bestDot then
					bestDot = dot
					bestModel = model
				end
			end
		end
	end

	if bestDot >= ANGLE_THRESHOLD then
		return bestModel
	end

	return currentTarget
end

local function lockCameraToTargetPart(targetPart, offset)
	if not targetPart then return end
	local camPos = Camera.CFrame.Position
	local targetPos = targetPart.Position + (offset or Vector3.new(0, 0, 0))
	Camera.CFrame = CFrame.lookAt(camPos, targetPos)
end

-- =====================================================
-- 📘 MODO LIBRARYBOOK (STUDENT + LIBRARYBOOK)
-- =====================================================

local function getLibraryBookTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end

	local inStudents = char.Parent and char.Parent.Name == STUDENTS_FOLDER
	local hasBook = hasLibraryBook(char)

	if inStudents and hasBook then
		for _, fname in ipairs(LIBRARY_TARGET_FOLDERS) do
			for _, m in ipairs(getModelsFromFolder(fname)) do
				if m ~= char and m:FindFirstChild("Head") then
					table.insert(models, m)
				end
			end
		end
	end

	return models
end

-- =====================================================
-- 🍎 MODO BLOOMIE (TEACHER BLOOMIE + AIMING)
-- =====================================================

local function getBloomieTargets()
	local models = {}
	local char = LocalPlayer.Character
	if not char then return models end

	local teacherAttr = char:GetAttribute("TeacherName")
	local aimingAttr = char:GetAttribute("Aiming")

	if teacherAttr == "Bloomie" and aimingAttr == true then
		for _, m in ipairs(getModelsFromFolder(BLOOMIE_TARGET_FOLDER)) do
			if m ~= char and m:FindFirstChild("Head") then
				table.insert(models, m)
			end
		end
	end

	return models
end

-- =====================================================
-- 🔁 LOOP PRINCIPAL
-- =====================================================

RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end

	-- 1️⃣ LibraryBook Mode
	local libTargets = getLibraryBookTargets()
	if #libTargets > 0 then
		currentTarget = chooseTarget(libTargets, TARGET_PRIORITY_TORSO)
		if currentTarget then
			local targetPart = getTargetPartByPriority(currentTarget, TARGET_PRIORITY_TORSO)
			if targetPart then
				lockCameraToTargetPart(targetPart, CAMERA_HEIGHT_OFFSET_TORSO)
			end
		end
		return
	end

	-- 2️⃣ Bloomie Mode
	local bloomTargets = getBloomieTargets()
	if #bloomTargets > 0 then
		currentTarget = chooseTarget(bloomTargets, TARGET_PRIORITY_HEAD)
		if currentTarget then
			local targetPart = getTargetPartByPriority(currentTarget, TARGET_PRIORITY_HEAD)
			if targetPart then
				lockCameraToTargetPart(targetPart, CAMERA_HEIGHT_OFFSET_HEAD)
			end
		end
		return
	end

	-- 3️⃣ Ningún modo activo
	currentTarget = nil
end)
