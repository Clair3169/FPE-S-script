-- 🟢 Imagen flotante (Optimizado para los 10 más cercanos)
repeat task.wait() until game:IsLoaded()

-- ⚙️ Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

-- 👤 Jugador local
local localPlayer = Players.LocalPlayer

-- 📂 Carpetas
local studentsFolder = Workspace:WaitForChild("Students")
local VALID_FOLDERS = { "Alices", "Teachers" }

-- 🖼️ Configuración
local IMAGE_ID = "rbxassetid://126500139798475"
local MAX_VISIBLE = 10

-- ⚙️ Estado
local systemActive = false
local activeBillboards = {}
local visibleStudents = {} -- Solo los 10 más cercanos
local currentCamera = Workspace.CurrentCamera

------------------------------------------------------------
-- 🎥 RenderStepped (escala dinámica, ultra liviano)
-- (Esta parte está perfecta, no se toca)
------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	if not systemActive or not next(activeBillboards) then return end
	currentCamera = Workspace.CurrentCamera or currentCamera
	local camPos = currentCamera.CFrame.Position

	for billboard, head in pairs(activeBillboards) do
		if not billboard.Parent or not head.Parent then
			activeBillboards[billboard] = nil
			continue
		end
		local distance = (camPos - head.Position).Magnitude
		-- Aumenta el límite máximo para que crezca más con la distancia
        local scale = math.clamp(distance / 30, 0.6, 3.5)
        billboard.Size = UDim2.new(scale * 3, 0, scale * 3, 0)
	end
end)

------------------------------------------------------------
-- 🧩 Crear / Destruir Billboard
-- (Esta parte está perfecta, no se toca)
------------------------------------------------------------
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
	image.Parent = billboard

	activeBillboards[billboard] = head
end

local function destroyFloatingImage(character)
	if not character or not character:IsA("Model") then return end
	local head = character:FindFirstChild("Head")
	if not head then return end
	local billboard = head:FindFirstChild("FloatingImageBillboard")
	if billboard then
		activeBillboards[billboard] = nil
		billboard:Destroy()
	end
end

------------------------------------------------------------
-- 🧩 Visibilidad de los 10 más cercanos
-- (Esta función es "cara", así que solo la llamaremos cuando sea necesario)
------------------------------------------------------------
local function updateVisibleStudents()
	if not systemActive or not localPlayer.Character then return end

	local localHead = localPlayer.Character:FindFirstChild("Head")
	if not localHead then return end
	
	local localPos = localHead.Position

	-- Recolectar distancias
	local distances = {}
	for _, student in ipairs(studentsFolder:GetChildren()) do
		if student ~= localPlayer.Character and student:IsA("Model") then
			local head = student:FindFirstChild("Head")
			if head then
				local dist = (localPos - head.Position).Magnitude
				table.insert(distances, {student, dist})
			end
		end
	end

	-- Ordenar por distancia (Esta es la parte "cara")
	table.sort(distances, function(a, b)
		return a[2] < b[2]
	end)

	-- Elegir los 10 más cercanos
	local newVisible = {}
	for i = 1, math.min(MAX_VISIBLE, #distances) do
		newVisible[distances[i][1]] = true
	end

	-- Aplicar cambios: Ocultar los que ya no están
	for student, _ in pairs(visibleStudents) do
		if not newVisible[student] then
			destroyFloatingImage(student)
		end
	end
	
	-- Aplicar cambios: Mostrar los nuevos
	for student, _ in pairs(newVisible) do
		if not visibleStudents[student] then
			createFloatingImage(student)
		end
	end

	visibleStudents = newVisible
end

------------------------------------------------------------
-- 🧩 Estado del sistema
------------------------------------------------------------
local function isInValidFolder()
	local char = localPlayer.Character
	if not char or not char.Parent then return false end
	for _, folderName in ipairs(VALID_FOLDERS) do
		if char.Parent.Name == folderName then
			return true
		end
	end
	return false
end

local function updateSystemStatus(force)
	local shouldBeActive = isInValidFolder()
	if shouldBeActive == systemActive and not force then return end
	systemActive = shouldBeActive

	if systemActive then
		updateVisibleStudents()
	else
		-- === CORRECCIÓN DEL BUG ===
		-- Iteramos sobre las LLAVES (student), no los valores (true)
		for student, _ in pairs(visibleStudents) do
			destroyFloatingImage(student)
		end
		visibleStudents = {}
	end
end

------------------------------------------------------------
-- 🧠 Monitor de Students (Perfecto)
------------------------------------------------------------
studentsFolder.ChildAdded:Connect(function(child)
	if systemActive and child ~= localPlayer.Character then
		task.defer(updateVisibleStudents)
	end
end)

studentsFolder.ChildRemoved:Connect(function(child)
	-- No es necesario revisar si 'systemActive' aquí.
	-- Si un jugador se va, DEBE ser procesado para
	-- eliminarlo de 'visibleStudents' si estaba allí.
	if visibleStudents[child] then
		visibleStudents[child] = nil
		-- 'destroyFloatingImage' ya se encarga de limpiarlo
		-- de 'activeBillboards', pero la lista principal
		-- 'visibleStudents' también debe limpiarse.
	end
	
	-- Si un jugador que no era visible se va, no pasa nada.
	-- Si un jugador visible se va, deja un espacio
	-- que el bucle de "movimiento" (abajo) llenará.
end)

------------------------------------------------------------
-- 🧩 Control de tu personaje (Perfecto)
------------------------------------------------------------
local function onCharacterAdded(character)
	updateSystemStatus(true)
	character:GetPropertyChangedSignal("Parent"):Connect(updateSystemStatus)
end

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(onCharacterAdded)

------------------------------------------------------------
-- ♻️ OPTIMIZACIÓN: Actualización inteligente (no cada 0.5s)
------------------------------------------------------------
task.spawn(function()
	local lastPlayerPosition = Vector3.zero
	-- Usamos un 'heartbeat' (latido) que es más eficiente que task.wait
	while RunService.Heartbeat:Wait() do
		
		if not systemActive or not localPlayer.Character then continue end
		
		local head = localPlayer.Character:FindFirstChild("Head")
		if not head then continue end
		
		local currentPos = head.Position
		
		-- Solo recalcula la lista si el jugador se movió más de 5 studs
		if (currentPos - lastPlayerPosition).Magnitude > 5 then
			lastPlayerPosition = currentPos
			updateVisibleStudents() -- ¡Llama a la función "cara" solo ahora!
		end
	end
end)
