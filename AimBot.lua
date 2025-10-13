-- =====================================================
-- 🎯 Aimbot con Cámara Fija — Bloqueo Total al Head
-- =====================================================

repeat task.wait() until game:IsLoaded()

-- Servicios
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- ⚙️ CONFIGURACIÓN
local TARGET_FOLDER_NAME = "Students"
local TARGET_PRIORITY = {"Head", "UpperTorso", "HumanoidRootPart"}
local ANGLE_THRESHOLD = 0.85 -- para elegir objetivo visible
local CAMERA_HEIGHT_OFFSET = Vector3.new(0, 0.3, 0) -- ajustar la altura de mira

-- VARIABLES
local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera
local TargetFolder = Workspace:WaitForChild(TARGET_FOLDER_NAME)
local currentTarget = nil

-- 🔹 Obtener parte objetivo (Head > UpperTorso > Root)
local function getTargetPart(model)
	for _, name in ipairs(TARGET_PRIORITY) do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			return part
		end
	end
	return nil
end

-- 🔹 Obtener modelos válidos
local function getAllValidModels()
	local models = {}
	for _, obj in ipairs(TargetFolder:GetChildren()) do
		if obj:IsA("Model") and obj ~= LocalPlayer.Character and obj:FindFirstChild("Head") then
			table.insert(models, obj)
		end
	end
	return models
end

-- 🔹 Elegir objetivo según dirección de cámara
local function chooseTarget(models)
	if #models == 0 then return nil end

	local camPos = Camera.CFrame.Position
	local camLook = Camera.CFrame.LookVector
	local bestModel = nil
	local bestDot = -1

	for _, model in ipairs(models) do
		local part = getTargetPart(model)
		if part then
			local dir = (part.Position - camPos).Unit
			local dot = camLook:Dot(dir)
			if dot > bestDot then
				bestDot = dot
				bestModel = model
			end
		end
	end

	if bestDot >= ANGLE_THRESHOLD then
		return bestModel
	end

	return currentTarget
end

-- 🔹 Apuntar directamente y bloquear cámara al objetivo
local function lockCameraToTarget(targetPart)
	if not targetPart then return end

	local camPos = Camera.CFrame.Position
	local targetPos = targetPart.Position + CAMERA_HEIGHT_OFFSET

	-- 🔸 Bloquear completamente la cámara al objetivo
	Camera.CFrame = CFrame.lookAt(camPos, targetPos)
end

-- 🔹 Loop principal
RunService.RenderStepped:Connect(function()
	local char = LocalPlayer.Character
	if not char then return end

	local teacher = char:GetAttribute("TeacherName")
	local aiming = char:GetAttribute("Aiming")

	if teacher == "Bloomie" and aiming == true then
		local models = getAllValidModels()
		currentTarget = chooseTarget(models)
		if currentTarget then
			local targetPart = getTargetPart(currentTarget)
			if targetPart then
				lockCameraToTarget(targetPart)
			end
		end
	else
		currentTarget = nil
	end
end)
