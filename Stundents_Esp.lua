-- 🟢 Imagen flotante dinámica para jugadores en carpeta "Students"
repeat task.wait() until game:IsLoaded()

-- ⚙️ Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 👤 Jugador local
local localPlayer = Players.LocalPlayer

-- 📂 Carpetas de control
local validFolders = { "Alices", "Teachers" }
local studentsFolder = Workspace:FindFirstChild("Students")

-- 🖼️ Imagen
local IMAGE_ID = "rbxassetid://126500139798475"

-- Estado
local systemActive = false
local currentFolder = nil

-- 🧩 Crear imagen flotante
local function createFloatingImage(character)
	if not character or not character:IsA("Model") then return end
	local head = character:FindFirstChild("Head")
	if not head or head:FindFirstChild("FloatingImageBillboard") then return end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "FloatingImageBillboard"
	billboard.Adornee = head
	billboard.Size = UDim2.new(3, 0, 3, 0)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 200
	billboard.Parent = head

	local image = Instance.new("ImageLabel")
	image.Name = "FloatingImage"
	image.Size = UDim2.new(1, 0, 1, 0)
	image.BackgroundTransparency = 1
	image.Image = IMAGE_ID
	image.ImageTransparency = 1
	image.Parent = billboard

	-- Fade IN suave
	task.spawn(function()
		for i = 1, 25 do
			image.ImageTransparency = 1 - (i / 25)
			task.wait(0.03)
		end
	end)

	-- Escalado dinámico según distancia
	local connection
	connection = RunService.RenderStepped:Connect(function()
		if not billboard.Parent then
			connection:Disconnect()
			return
		end

		local cam = Workspace.CurrentCamera
		if not cam then return end

		local distance = (cam.CFrame.Position - head.Position).Magnitude
		local scale = math.clamp(distance / 30, 0.6, 2.5)
		billboard.Size = UDim2.new(scale * 3, 0, scale * 3, 0)
	end)
end

-- 🧩 Fade Out (más lento si slower = true)
local function fadeOutImage(character, slower)
	if not character then return end
	local head = character:FindFirstChild("Head")
	if not head then return end
	local billboard = head:FindFirstChild("FloatingImageBillboard")
	if not billboard then return end

	local image = billboard:FindFirstChild("FloatingImage")
	if not image then billboard:Destroy() return end

	task.spawn(function()
		-- 🔹 3 segundos exactos → 90 pasos
		local steps = slower and 90 or 25
		for i = 1, steps do
			local t = i / steps
			local eased = t * t -- curva suave
			image.ImageTransparency = eased
			task.wait(0.033)
		end
		billboard:Destroy()
	end)
end

-- 🧩 Aplicar imágenes a todos los Students
local function applyToAllStudents()
	if not studentsFolder then return end
	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student ~= localPlayer.Character then
			createFloatingImage(student)
		end
	end
end

-- 🧩 Limpiar todos los BillboardGui
local function clearAllImages(slower)
	if not studentsFolder then return end
	for _, student in ipairs(studentsFolder:GetChildren()) do
		fadeOutImage(student, slower)
	end
end

-- 🧩 Detectar carpeta actual del jugador
local function checkPlayerFolder()
	local char = localPlayer.Character or localPlayer.CharacterAdded:Wait()
	local parent = char.Parent
	if not parent then return end

	local newFolderName = parent.Name
	if currentFolder == newFolderName then return end
	currentFolder = newFolderName

	-- ¿Está en Alices o Teachers?
	local inValidFolder = false
	for _, name in ipairs(validFolders) do
		if newFolderName == name then
			inValidFolder = true
			break
		end
	end

	if inValidFolder and not systemActive then
		-- Entró en una carpeta válida → activar sistema
		systemActive = true
		applyToAllStudents()

		studentsFolder.ChildAdded:Connect(function(child)
			task.wait(0.5)
			if systemActive and child ~= localPlayer.Character then
				createFloatingImage(child)
			end
		end)

		studentsFolder.ChildRemoved:Connect(function(child)
			fadeOutImage(child, true)
		end)
	elseif not inValidFolder and systemActive then
		-- Salió de Alices/Teachers
		systemActive = false

		-- Si ahora está en "Students" → fade-out más lento (3 s)
		local slower = (newFolderName == "Students")
		clearAllImages(slower)
	end
end

-- 🧩 Revisar carpeta del jugador en tiempo real
task.spawn(function()
	while task.wait(1) do
		if localPlayer.Character and localPlayer.Character.Parent then
			checkPlayerFolder()
		end
	end
end)

-- 🧩 Fade-out al morir
localPlayer.CharacterAdded:Connect(function(char)
	char:WaitForChild("Humanoid").Died:Connect(function()
		if systemActive then
			fadeOutImage(char, true)
		end
	end)
end)
