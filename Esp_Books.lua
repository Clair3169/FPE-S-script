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
	if asleep or not meshPart:IsA("BasePart") or highlights[meshPart] then return end

	local hl = Instance.new("Highlight")
	hl.Name = "BookHighlight"
	hl.FillColor = HIGHLIGHT_FILL_COLOR
	hl.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
	hl.FillTransparency = 0
	hl.OutlineTransparency = 0.5
	hl.Enabled = false
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

	booksFolder.ChildAdded:Connect(function(child)
		if asleep then return end
		if child:IsA("BasePart") then
			createHighlight(child)
			updateHighlightsInRange()
		end
	end)

	booksFolder.ChildRemoved:Connect(removeHighlight)
	activateBooks()
end

Workspace.ChildAdded:Connect(function(child)
	if child.Name == "Books" and child:IsA("Folder") then
		booksFolder = child
		connectBookEvents()
	end
end)

Workspace.ChildRemoved:Connect(function(child)
	if child == booksFolder then
		for meshPart in pairs(highlights) do
			removeHighlight(meshPart)
		end
		booksFolder = nil
	end
end)

if Workspace:FindFirstChild("Books") then
	booksFolder = Workspace.Books
	connectBookEvents()
end

------------------------------------------------------
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

	-- 🔹 Reforzar los highlights al reaparecer si seguimos en Students
	task.defer(function()
		if not asleep and booksFolder then
			activateBooks()
		end
	end)

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
end
-- ----------------------------------------------------
-- ‼️ CAPA DE SEGURIDAD ADICIONAL (AÑADIR AL FINAL) ‼️
-- ----------------------------------------------------
-- Esto fuerza una segunda verificación explícita para los libros existentes
-- justo después de que el script se haya cargado e inicializado por completo.
task.wait(1) -- Damos un breve respiro para asegurar que todo esté cargado
if booksFolder and not asleep then
	activateBooks()
end
