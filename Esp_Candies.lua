-- ======================================================
-- 🍬 Candy Billboard Dynamic (sin brillo + con filtro de carpetas)
-- Ultra optimizado: Throttle + Cache + MagnitudeSqr
-- ======================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")

local CandiesFolder = Workspace:WaitForChild("Candies")
local Player = Players.LocalPlayer

-- ==============================
-- ⚙️ CONFIGURACIÓN
-- ==============================
local Settings = {
	MaxVisibleBillboards = 7,   -- máximo de Candies visibles
	BillboardSize = UDim2.new(0, 16, 0, 16),
	BillboardOffset = Vector3.new(0, 2.5, 0),
	CircleColor = Color3.fromRGB(255, 140, 0),
	AllowedFolder = "Students", -- (no usado activamente, conservado)
	BlockedFolders = {"Alices", "Teachers"}, -- no aplicar si está dentro de estas carpetas
	UpdateRate = 0.1,           -- segundos entre actualizaciones (10 veces/seg)
}

-- ==============================
-- 🧩 Detectar carpeta actual del jugador (función original)
-- ==============================
local function getParentFolderName()
	local char = Player.Character
	if not char then return nil end

	local parent = char.Parent
	if parent and parent:IsA("Folder") then
		return parent.Name
	end
	return nil
end

-- ==============================
-- 🔒 Cache del estado de bloqueo (optimización 2)
-- ==============================
local isBlocked = false

local function updateBlockedState()
	local parentFolder = getParentFolderName()
	isBlocked = false
	for _, name in ipairs(Settings.BlockedFolders) do
		if parentFolder == name then
			isBlocked = true
			break
		end
	end
end

-- Actualizar cuando el personaje aparece / cambia de ancestro
Player.CharacterAdded:Connect(function(char)
	-- actualizar inmediatamente al aparecer
	updateBlockedState()

	-- si el personaje cambia de padre (se movió a otra carpeta), actualizar cache
	char.AncestorChanged:Connect(function(child, parent)
		if child == char then
			updateBlockedState()
		end
	end)
end)

-- Estado inicial (si el Character ya existe)
if Player.Character then
	updateBlockedState()
end

-- ==============================
-- 🌀 Crear Billboard sobre un Candy (sin cambios funcionales)
-- ==============================
local function createBillboard(candy)
	if candy:FindFirstChild("CandyBillboard") then
		return candy.CandyBillboard
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CandyBillboard"
	billboard.AlwaysOnTop = true
	billboard.Size = Settings.BillboardSize
	billboard.LightInfluence = 0
	billboard.StudsOffset = Settings.BillboardOffset

	local adornee = candy:FindFirstChildWhichIsA("BasePart") or candy
	billboard.Adornee = adornee
	billboard.Parent = adornee

	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.Size = UDim2.new(1, 0, 1, 0)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundColor3 = Settings.CircleColor
	circle.BackgroundTransparency = 0.2
	circle.BorderSizePixel = 0
	circle.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	return billboard
end

-- ==============================
-- 📦 Manejo de Candies (sin cambios funcionales)
-- ==============================
local allCandies = {}
local allBillboards = {}

-- Crear billboards para todos los existentes
for _, c in ipairs(CandiesFolder:GetChildren()) do
	if c:IsA("BasePart") and c.Name == "Candy" then
		local bb = createBillboard(c)
		allCandies[#allCandies+1] = c
		allBillboards[c] = bb
	end
end

CandiesFolder.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") and child.Name == "Candy" then
		local bb = createBillboard(child)
		allCandies[#allCandies+1] = child
		allBillboards[child] = bb
	end
end)

CandiesFolder.ChildRemoved:Connect(function(child)
	allBillboards[child] = nil
	for i, c in ipairs(allCandies) do
		if c == child then
			table.remove(allCandies, i)
			break
		end
	end
end)

-- ==============================
-- 🔍 Obtener los 7 Candies más cercanos al jugador
-- (optimización 3: usar MagnitudeSqr en vez de Magnitude)
-- ==============================
local function getClosestCandies()
	local character = Player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end

	local pos = character.HumanoidRootPart.Position
	local distances = {}

	for _, candy in ipairs(allCandies) do
		if candy and candy:IsDescendantOf(Workspace) then
			-- <<< CAMBIO: use MagnitudeSqr (más rápido) >>>
			local dist = (candy.Position - pos).MagnitudeSqr
			table.insert(distances, {candy = candy, dist = dist})
		end
	end

	table.sort(distances, function(a, b)
		return a.dist < b.dist
	end)

	local closest = {}
	for i = 1, math.min(Settings.MaxVisibleBillboards, #distances) do
		table.insert(closest, distances[i].candy)
	end

	return closest
end

-- ==============================
-- 🚦 Control principal (Throttle en lugar de RenderStepped)
-- (optimización 1: actualiza solo Settings.UpdateRate veces/seg)
-- ==============================
task.spawn(function()
	while true do
		task.wait(Settings.UpdateRate)

		if #allCandies == 0 then
			-- nada que hacer si no hay candies
		else
			-- usar el estado cacheado isBlocked (actualizado solo cuando corresponde)
			if isBlocked then
				-- Desactivar todos los billboards si está en una carpeta bloqueada
				for _, bb in pairs(allBillboards) do
					if bb and bb.Enabled then
						bb.Enabled = false
					end
				end
			else
				-- Mostrar solo los 7 más cercanos si no está bloqueado
				local closest = getClosestCandies()
				local visibleSet = {}
				for _, c in ipairs(closest) do
					visibleSet[c] = true
				end

				for candy, bb in pairs(allBillboards) do
					if bb and bb.Parent then
						local shouldBe = visibleSet[candy] or false
						-- Micro-opt: solo escribir si cambia
						if bb.Enabled ~= shouldBe then
							bb.Enabled = shouldBe
						end
					end
				end
			end
		end
	end
end)
