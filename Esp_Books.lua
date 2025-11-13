-- 🟦 Book Highlighter Optimizado (Persistente tras muerte)
repeat task.wait() until game:IsLoaded()

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local booksFolder
local asleep = false

-- ⚙️ Configuración
local RENDER_DISTANCE = 150
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(135, 206, 250)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 255)

-- 🧠 Estado
local highlights = {}
local highlightsFolder = Workspace:FindFirstChild("HighligthsBooks_Main") or Instance.new("Folder")
highlightsFolder.Name = "HighligthsBooks_Main"
highlightsFolder.Parent = Workspace

------------------------------------------------------
-- 🧩 Obtener posición segura del jugador
------------------------------------------------------
local function getLocalPos()
	local char = player.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

------------------------------------------------------
-- 🧩 Crear y destruir Highlights
------------------------------------------------------
local function removeHighlight(meshPart)
	local hl = highlights[meshPart]
	if hl then
		hl:Destroy()
		highlights[meshPart] = nil
	end
end

local function createHighlight(meshPart)
	if asleep or not meshPart:IsA("BasePart") then return end

	-- Elimina highlight duplicado o roto
	if highlights[meshPart] then
		if highlights[meshPart].Parent then
			highlights[meshPart]:Destroy()
		end
		highlights[meshPart] = nil
	end

	-- ⚡ Espera a que el objeto esté completamente replicado
	if not meshPart:IsDescendantOf(Workspace) then
		task.wait(0.1)
	end

	-- 🟦 Crear highlight visible inmediatamente
	local hl = Instance.new("Highlight")
	hl.Name = "BookHighlight"
	hl.FillColor = HIGHLIGHT_FILL_COLOR
	hl.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
	hl.FillTransparency = 0 -- 💡 visible pero no sólido
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop -- 👈 fuerza visibilidad
	hl.Enabled = true
	hl.Adornee = meshPart
	hl.Parent = highlightsFolder

	highlights[meshPart] = hl
end

------------------------------------------------------
-- 🧩 Activar/desactivar por distancia
------------------------------------------------------
local function updateHighlightsInRange()
	local localPos = getLocalPos()
	if asleep or not booksFolder or not localPos then return end

	for meshPart, hl in pairs(highlights) do
		if meshPart and meshPart.Parent then
			-- 🔍 Si el Highlight fue eliminado por el sistema de caché, lo recreamos
			if not hl or not hl.Parent then
				highlights[meshPart] = nil
				createHighlight(meshPart)
				hl = highlights[meshPart]
			end

			local dist = (meshPart.Position - localPos).Magnitude
			local visible = dist <= RENDER_DISTANCE
			if hl.Enabled ~= visible then
				hl.Enabled = visible
			end
		else
			removeHighlight(meshPart)
		end
	end
end

------------------------------------------------------
-- 🧩 Activar libros existentes
------------------------------------------------------
local function activateBooks()
	if asleep or not booksFolder then return end
	for _, obj in ipairs(booksFolder:GetChildren()) do
		if obj:IsA("BasePart") then
			createHighlight(obj)
		end
	end
	updateHighlightsInRange()
end

------------------------------------------------------
-- 🧩 Control de carpeta Books
------------------------------------------------------
local function connectBookEvents()
	if not booksFolder then return end

	-- Solo conecta los listeners una vez usando un atributo
	if booksFolder:GetAttribute("EventsConnected") then return end
	booksFolder:SetAttribute("EventsConnected", true) -- Marca para evitar duplicados

	booksFolder.ChildAdded:Connect(function(child)
		if asleep then return end
		if child:IsA("BasePart") then
			createHighlight(child)
			updateHighlightsInRange()
		end
	end)

	booksFolder.ChildRemoved:Connect(removeHighlight)
	-- Ya no llamamos activateBooks aquí. Se hará en initializeBookHighlighter.
end

------------------------------------------------------
-- 🧩 Inicialización robusta de los Books (sin duplicar ni perder carga)
------------------------------------------------------
local initializing = false
local initialized = false

local function initializeBookHighlighter()
	-- ⛔ Evita múltiples ejecuciones simultáneas
	if initializing then return end
	initializing = true

	task.spawn(function()
		local tries = 0
		while not booksFolder or not booksFolder:IsDescendantOf(Workspace) do
			booksFolder = Workspace:FindFirstChild("Books")
			if booksFolder then break end
			tries += 1
			if tries > 50 then
				warn("⚠️ No se encontró carpeta 'Books' tras 50 intentos.")
				initializing = false
				return
			end
			task.wait(0.5)
		end

		-- 🔹 Esperar a que los libros existan en la carpeta
		local timeout = os.clock() + 5
		repeat
			task.wait(0.25)
		until (booksFolder and #booksFolder:GetChildren() > 0) or os.clock() > timeout

		-- 🧠 Conectamos eventos solo una vez
		connectBookEvents()

		-- 🟦 Activamos Highlights una sola vez
		task.wait(0.1)
		activateBooks()

		initialized = true
		initializing = false
	end)
end
------------------------------------------------------
-- 🧩 Reintento si los libros se recrean en tiempo real
------------------------------------------------------
Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Books" and child:IsA("Folder") then
		booksFolder = child
		initialized = false
		task.defer(initializeBookHighlighter)
	end
end)

Workspace.ChildRemoved:Connect(function(child)
	if child == booksFolder then
		for meshPart in pairs(highlights) do
			removeHighlight(meshPart)
		end
		booksFolder = nil
		initialized = false
	end
end)
-----------------------------------------------------
-- 🧩 Estado dormido (Alices / Teachers)
------------------------------------------------------
local function checkSleepState()
	local char = player.Character
	if not char then return end

	local parent = char.Parent
	local newAsleep = parent and (parent.Name == "Alices" or parent.Name == "Teachers")

	if newAsleep ~= asleep then
		asleep = newAsleep
		if asleep then
			for _, hl in pairs(highlights) do
				hl.Enabled = false
			end
		else
			-- 🔹 Reforzamos la activación tras despertar o reaparecer
			task.defer(activateBooks)
		end
	end
end
------------------------------------------------------
-- 🧩 Evento de respawn persistente
------------------------------------------------------
player.CharacterAdded:Connect(function(char)
	char:GetPropertyChangedSignal("Parent"):Connect(checkSleepState)
	checkSleepState()
	
	-- 🆕 INICIALIZACIÓN CLAVE: Inicializa la carpeta Books y activa highlights 
	-- justo después de que el Character se haya cargado.
	task.defer(initializeBookHighlighter)

	-- 🧩 Solo se actualiza por movimiento real, no cada frame
	local root = char:WaitForChild("HumanoidRootPart", 3)
	if root then
		local lastPos = root.Position
		root:GetPropertyChangedSignal("Position"):Connect(function()
			if not asleep then
				local newPos = root.Position
				if (newPos - lastPos).Magnitude > 4 then
					lastPos = newPos
					updateHighlightsInRange()
				end
			end
		end)
	end
end)

if player.Character then
	player.Character:GetPropertyChangedSignal("Parent"):Connect(checkSleepState)
	checkSleepState()
	-- 🆕 También inicializar para el caso en que el Character ya existe al inicio
	task.defer(initializeBookHighlighter)
end
