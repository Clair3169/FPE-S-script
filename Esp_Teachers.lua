--=========================================================
-- 🎓 Floating Images System (Alices & Students → Teachers)
-- ⚡ Versión 5.0 — Activación permanente + Limpieza + FPS óptimo
--=========================================================

--// 🔹 Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

--// 🔹 Jugador local
local LocalPlayer = Players.LocalPlayer
local PlayerModel = nil

--// 🔹 Carpetas
local Folders = {
	Alices = Workspace:WaitForChild("Alices"),
	Students = Workspace:WaitForChild("Students"),
	Teachers = Workspace:WaitForChild("Teachers"),
}

--// 🔹 Configuración general
local MAX_RENDER_DISTANCE = 200
local CHECK_INTERVAL = 4
local ENRAGED_IMAGE = "rbxassetid://108867117884833"

--// 🔹 Imágenes base por TeacherName
local TeacherImages = {
	Thavel = "rbxassetid://126007170470250",
	Circle = "rbxassetid://72842137403522",
	Bloomie = "rbxassetid://129090409260807",
	Alice = "rbxassetid://94023609108845",
	AlicePhase2 = "rbxassetid://78066130044573",
}

--// 🔹 Crear BillboardGui (tamaño medio-pequeño)
local function createBillboard(imageId)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingImage"
	billboard.Size = UDim2.new(0, 65, 0, 65)
	billboard.StudsOffset = Vector3.new(0, 2.5, 0)
	billboard.AlwaysOnTop = true
	billboard.Enabled = true

	local img = Instance.new("ImageLabel")
	img.BackgroundTransparency = 1
	img.Size = UDim2.new(1, 0, 1, 0)
	img.Image = imageId
	img.Parent = billboard

	return billboard
end

--// 🔹 Detectar carpeta del jugador local
local function detectPlayerFolder()
	for _, folderName in ipairs({"Alices", "Students"}) do
		local folder = Folders[folderName]
		if folder and folder:FindFirstChild(LocalPlayer.Name) then
			return folder
		end
	end
	return nil
end

--// 🔹 Gestión de imágenes activas
local ActiveBillboards = {}

local function attachFloatingImage(model, imageId)
	if not model or not model:FindFirstChild("Head") then return end
	if ActiveBillboards[model] then
		ActiveBillboards[model].ImageLabel.Image = imageId
		return
	end

	local billboard = createBillboard(imageId)
	billboard.Adornee = model.Head
	billboard.Parent = model

	ActiveBillboards[model] = {
		Billboard = billboard,
		ImageLabel = billboard:FindFirstChildOfClass("ImageLabel"),
	}
end

local function removeFloatingImage(model)
	if ActiveBillboards[model] then
		ActiveBillboards[model].Billboard:Destroy()
		ActiveBillboards[model] = nil
	end
end

local function clearAllBillboardsFromFolder(folder)
	for _, model in ipairs(folder:GetChildren()) do
		removeFloatingImage(model)
	end
end

--// 🔹 Monitoreo de atributos dinámico
local function monitorAttributes(model)
	if not model or not model:GetAttribute("TeacherName") then return end
	local teacherName = model:GetAttribute("TeacherName")
	local normalImage = TeacherImages[teacherName]

	if not normalImage then return end
	attachFloatingImage(model, normalImage)

	local function updateImage()
		local enraged = model:GetAttribute("Enraged")
		if enraged == true then
			attachFloatingImage(model, ENRAGED_IMAGE)
		else
			attachFloatingImage(model, normalImage)
		end
	end

	model:GetAttributeChangedSignal("Enraged"):Connect(updateImage)
	updateImage()
end

--// 🔹 Escanear modelos válidos (Teachers/Alices)
local function scanFolder(folder, skipLocal)
	for _, model in ipairs(folder:GetChildren()) do
		if model:IsA("Model") and model:FindFirstChild("Head") then
			if skipLocal and model.Name == LocalPlayer.Name then
				continue
			end
			monitorAttributes(model)
		end
	end
end

--// 🔹 Control de renderizado por distancia
RunService.Heartbeat:Connect(function()
	local myChar = LocalPlayer.Character
	if not myChar or not myChar:FindFirstChild("Head") then return end

	local myPos = myChar.Head.Position
	for model, data in pairs(ActiveBillboards) do
		if model and model:FindFirstChild("Head") then
			local dist = (model.Head.Position - myPos).Magnitude
			data.Billboard.Enabled = dist <= MAX_RENDER_DISTANCE
		else
			removeFloatingImage(model)
		end
	end
end)

--// 🔹 Sistema dinámico: activar si hay ≥1 jugador, limpiar si no hay
local function autoCheckFolders()
	while true do
		local teacherCount = #Folders.Teachers:GetChildren()
		local aliceCount = #Folders.Alices:GetChildren()
		local myFolder = detectPlayerFolder()

		if myFolder then
			-- Teachers: mientras haya al menos 1 jugador
			if teacherCount >= 1 then
				scanFolder(Folders.Teachers, myFolder.Name == "Alices")
			else
				clearAllBillboardsFromFolder(Folders.Teachers)
			end

			-- Alices: mientras haya al menos 1 jugador
			if aliceCount >= 1 then
				scanFolder(Folders.Alices, myFolder.Name == "Alices")
			else
				clearAllBillboardsFromFolder(Folders.Alices)
			end
		end

		task.wait(CHECK_INTERVAL)
	end
end

--// 🔹 Inicialización principal
task.spawn(function()
	repeat
		for _, folderName in ipairs({"Alices", "Students"}) do
			local folder = Folders[folderName]
			if folder and folder:FindFirstChild(LocalPlayer.Name) then
				PlayerModel = folder[LocalPlayer.Name]
				break
			end
		end
		task.wait(1)
	until PlayerModel

	task.spawn(autoCheckFolders)
end)
