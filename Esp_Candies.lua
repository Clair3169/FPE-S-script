-- ======================================================
-- 🍬 Candy Billboard Dynamic (7 más cercanos al jugador)
-- Sin bucles infinitos, ultra eficiente
-- ======================================================

local Workspace = game:GetService("Workspace")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Carpeta Candies
local CandiesFolder = Workspace:WaitForChild("Candies")
local Player = Players.LocalPlayer

-- ==============================
-- ⚙️ CONFIGURACIÓN
-- ==============================
local Settings = {
	MaxVisibleBillboards = 7,   -- máximo de billboards visibles
	BillboardSize = UDim2.new(0, 16, 0, 16),
	BillboardOffset = Vector3.new(0, 2.5, 0),
	CircleColor = Color3.fromRGB(255, 140, 0),
	TransMin = 0.15,
	TransMax = 0.4,
	PulseSpeed = 1.5,           -- velocidad del brillo
}

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

	local adornee = candy:FindFirstChildWhichIsA("BasePart") or candy
	billboard.Adornee = adornee
	billboard.Parent = adornee

	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.Size = UDim2.new(1, 0, 1, 0)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.BackgroundColor3 = Settings.CircleColor
	circle.BackgroundTransparency = Settings.TransMin
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
-- ==============================
local function getClosestCandies()
	local character = Player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then return {} end

	local pos = character.HumanoidRootPart.Position
	local distances = {}

	for _, candy in ipairs(allCandies) do
		if candy and candy:IsDescendantOf(Workspace) then
			local dist = (candy.Position - pos).Magnitude
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
-- ✨ Animación + actualización por frame
-- ==============================
local start = tick()
RunService.RenderStepped:Connect(function()
	if #allCandies == 0 then return end

	local t = tick() - start
	local pulse = (math.sin(t * Settings.PulseSpeed * math.pi * 2) + 1) / 2
	local transparency = Settings.TransMin + pulse * (Settings.TransMax - Settings.TransMin)

	local closest = getClosestCandies()
	local visibleSet = {}
	for _, c in ipairs(closest) do
		visibleSet[c] = true
	end

	for candy, bb in pairs(allBillboards) do
		if bb and bb.Parent then
			bb.Enabled = visibleSet[candy] or false
			local circle = bb:FindFirstChild("Circle")
			if circle and bb.Enabled then
				circle.BackgroundTransparency = transparency
			end
		end
	end
end)
