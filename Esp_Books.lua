-- LocalScript
-- Colócalo en StarterPlayerScripts o StarterCharacterScripts

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer

-- Ya no se necesitan IMAGE_ID ni BILLBOARD_SIZE para Highlights
local RENDER_DISTANCE = 150 -- Los Highlights no tienen un MaxDistance automático como los Billboards
-- Tendremos que manejar la visibilidad de los Highlights manualmente si se desea un render distance

local highlights = {} -- Cambiado de 'billboards' a 'highlights'
local booksFolder
local asleep = false -- estado dormido si estamos en Alices o Teachers

-- Colores para el Highlight (Azul claro 💙)
local HIGHLIGHT_FILL_COLOR = Color3.fromRGB(135, 206, 250) -- SkyBlue (Azul cielo)
local HIGHLIGHT_OUTLINE_COLOR = Color3.fromRGB(0, 0, 255) -- Un azul más oscuro para el contorno

------------------------------------------------------
-- Funciones auxiliares
------------------------------------------------------

local function clearAll()
	for meshPart, _ in pairs(highlights) do
		if highlights[meshPart] then
			highlights[meshPart]:Destroy()
		end
	end
	highlights = {}
end

local function createHighlight(meshPart)
	if asleep or not meshPart:IsA("BasePart") or highlights[meshPart] then return end

	local highlight = Instance.new("Highlight")
	highlight.Name = "BookHighlight"
	highlight.FillColor = HIGHLIGHT_FILL_COLOR
	highlight.OutlineColor = HIGHLIGHT_OUTLINE_COLOR
	highlight.FillTransparency = 0 -- 0 para un color sólido, 1 para transparente
	highlight.OutlineTransparency = 0.5 -- Un poco de transparencia para el contorno
	highlight.Adornee = meshPart -- El Highlight se "adhiere" al MeshPart

	highlight.Parent = meshPart -- Generalmente se parenta al Adornee o a una carpeta de Highlights
	highlights[meshPart] = highlight
end

local function removeHighlight(meshPart)
	if highlights[meshPart] then
		highlights[meshPart]:Destroy()
		highlights[meshPart] = nil
	end
end

local function activateBooks()
	if asleep or not booksFolder then return end
	for _, obj in ipairs(booksFolder:GetChildren()) do
		if obj:IsA("MeshPart") then
			createHighlight(obj)
		end
	end
end

------------------------------------------------------
-- Control de carpeta Books (creación / eliminación)
------------------------------------------------------

local function connectBookEvents()
	if not booksFolder then return end

	booksFolder.ChildAdded:Connect(function(child)
		if not asleep and child:IsA("MeshPart") then
			createHighlight(child)
		end
	end)

	booksFolder.ChildRemoved:Connect(function(child)
		removeHighlight(child)
	end)

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
		clearAll()
		booksFolder = nil
	end
end)

if Workspace:FindFirstChild("Books") then
	booksFolder = Workspace.Books
	connectBookEvents()
end

------------------------------------------------------
-- Detección de si el jugador está en Alices o Teachers
------------------------------------------------------

local function checkSleepState()
	local char = player.Character or player.CharacterAdded:Wait()
	local parent = char.Parent
	local newAsleep = false

	if parent and (parent.Name == "Alices" or parent.Name == "Teachers") then
		newAsleep = true
	end

	if newAsleep ~= asleep then
		asleep = newAsleep
		if asleep then
			-- Dormir → eliminar todos los Highlights
			clearAll()
		else
			-- Despertar → volver a activar si hay libros
			if booksFolder and #booksFolder:GetChildren() > 0 then
				activateBooks()
			end
		end
	end
end

-- Escucha cuando cambie el parent del Character (entra o sale de carpetas)
player.CharacterAdded:Connect(function(char)
	char:GetPropertyChangedSignal("Parent"):Connect(checkSleepState)
	checkSleepState()
end)

-- Si ya hay personaje cargado al inicio
if player.Character then
	player.Character:GetPropertyChangedSignal("Parent"):Connect(checkSleepState)
	checkSleepState()
end
