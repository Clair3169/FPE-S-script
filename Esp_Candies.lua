-- ======================================================
-- 🍬 Candy Billboard Dynamic (sin brillo + con filtro de carpetas)
-- ⚡ Versión final: Throttle + Cache + DotDistance + Filtro de Distancia
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
	MaxRenderDistance = 100,     -- 🆕 ¡NUEVO! Distancia máxima de renderizado (en studs)
	BillboardSize = UDim2.new(0, 16, 0, 16),
	BillboardOffset = Vector3.new(0, 2.5, 0),
	CircleColor = Color3.fromRGB(255, 140, 0),
	BlockedFolders = {"Alices", "Teachers"}, -- carpetas bloqueadas
	UpdateRate = 0.1,          -- segundos entre actualizaciones (10 veces/seg)
}

-- ==============================
-- 🧩 Detectar carpeta actual del jugador
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
-- 🔒 Cache del estado de bloqueo (solo se actualiza cuando cambia)
-- ==============================
local isBlocked = false

local function updateBlockedState()
	local parentFolder = getParentFolderName()
	local newBlocked = false
	for _, name in ipairs(Settings.BlockedFolders) do
		if parentFolder == name then
			newBlocked = true
			break
		end
	end
	if newBlocked ~= isBlocked then
		isBlocked = newBlocked
	end
end

-- Escuchar cambios solo cuando sea necesario
Player.CharacterAdded:Connect(function(char)
	updateBlockedState()
	char:GetPropertyChangedSignal("Parent"):Connect(updateBlockedState)
end)

if Player.Character then
	updateBlockedState()
end

-- ==============================
-- 🌀 Crear Billboard sobre un Candy
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
	billboard.MaxDistance = Settings.MaxRenderDistance

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
-- 📦 Manejo de Candies
-- ==============================
local allCandies = {}
local allBillboards = {}

-- Inicialización
for _, c in ipairs(CandiesFolder:GetChildren()) do
	if c:IsA("BasePart") and c.Name == "Candy" then
		local bb = createBillboard(c)
		allCandies[#allCandies + 1] = c
		allBillboards[c] = bb
	end
end

CandiesFolder.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") and child.Name == "Candy" then
		local bb = createBillboard(child)
		allCandies[#allCandies + 1] = child
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
-- 🔍 Obtener los 7 Candies más cercanos (¡OPTIMIZADO!)
-- ==============================
local function getClosestCandies()
	local character = Player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		return {}
	end

	local pos = character.HumanoidRootPart.Position
	local distances = {}

	local maxDistSq = Settings.MaxRenderDistance * Settings.MaxRenderDistance

	for _, candy in ipairs(allCandies) do
		if candy and candy:IsDescendantOf(Workspace) then
			local diff = candy.Position - pos
			local dist = diff:Dot(diff)
			if dist < maxDistSq then
				table.insert(distances, {candy = candy, dist = dist})
			end
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
-- 🚦 Control principal (Throttle Loop)
-- ==============================
task.spawn(function()
	while true do
		task.wait(Settings.UpdateRate)

		if #allCandies == 0 then
			continue
		end

		if isBlocked then
			for _, bb in pairs(allBillboards) do
				if bb and bb.Enabled then
					bb.Enabled = false
				end
			end
		else
			local closest = getClosestCandies()
			local visibleSet = {}
			for _, c in ipairs(closest) do
				visibleSet[c] = true
			end

			for candy, bb in pairs(allBillboards) do
				if bb and bb.Parent then
					local shouldBe = visibleSet[candy] or false
					if bb.Enabled ~= shouldBe then
						bb.Enabled = shouldBe
					end
				end
			end
		end
	end
end)
