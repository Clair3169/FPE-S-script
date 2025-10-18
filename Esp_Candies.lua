-- ======================================================
-- 🍭 Candy Billboard Visible + AutoRespawn
-- (Optimizado y sin task.wait)
-- ======================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CandiesFolder = Workspace:FindFirstChild("Candies") or Instance.new("Folder", Workspace)
CandiesFolder.Name = "Candies"

-- ==============================
-- ⚙️ CONFIGURACIÓN
-- ==============================
local Settings = {
	MaxVisibleBillboards = 7,   -- cuántos círculos se muestran a la vez
	MinCandiesAlive = 7,        -- mínimo de Candies vivos
	BillboardSize = UDim2.new(0, 16, 0, 16),
	BillboardOffset = Vector3.new(0, 2.5, 0),
	CircleColor = Color3.fromRGB(255, 140, 0),
	TransMin = 0.15,
	TransMax = 0.4,
	PulseSpeed = 1.5,
	RespawnRadius = 40,
	RespawnCenter = Vector3.new(0, 3, 0),
}

-- ==============================
-- 🧁 Crear Candy simple (de ejemplo)
-- ==============================
local function spawnCandy()
	local candy = Instance.new("MeshPart")
	candy.Name = "Candy"
	candy.Size = Vector3.new(1, 1, 1)
	candy.Material = Enum.Material.SmoothPlastic
	candy.Color = Color3.fromRGB(255, 170, 0)
	candy.Anchored = true
	candy.CanCollide = false

	local offset = Vector3.new(
		math.random(-Settings.RespawnRadius, Settings.RespawnRadius),
		0,
		math.random(-Settings.RespawnRadius, Settings.RespawnRadius)
	)
	candy.Position = Settings.RespawnCenter + offset
	candy.Parent = CandiesFolder

	return candy
end

-- ==============================
-- 🌀 Crear Billboard
-- ==============================
local function createBillboard(candy)
	if candy:FindFirstChild("CandyBillboard") then
		return candy.CandyBillboard
	end

	-- BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CandyBillboard"
	billboard.AlwaysOnTop = true
	billboard.Size = Settings.BillboardSize
	billboard.LightInfluence = 0
	billboard.StudsOffset = Settings.BillboardOffset

	-- Buscar la parte visible principal
	local adornee = candy:FindFirstChildWhichIsA("BasePart") or candy
	billboard.Adornee = adornee
	billboard.Parent = adornee

	-- Círculo naranja
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
-- 📦 LISTA DE BILLBOARDS
-- ==============================
local allBillboards = {}

-- Inicializar los existentes
for _, c in ipairs(CandiesFolder:GetChildren()) do
	if c:IsA("BasePart") and c.Name == "Candy" then
		local bb = createBillboard(c)
		table.insert(allBillboards, bb)
	end
end

-- ==============================
-- ⚡ Mantener mínimo de Candies
-- ==============================
local function ensureMinCandies()
	local current = 0
	for _, c in ipairs(CandiesFolder:GetChildren()) do
		if c:IsA("BasePart") and c.Name == "Candy" then
			current += 1
		end
	end
	while current < Settings.MinCandiesAlive do
		local newCandy = spawnCandy()
		local bb = createBillboard(newCandy)
		table.insert(allBillboards, bb)
		current += 1
	end
end

CandiesFolder.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") and child.Name == "Candy" then
		local bb = createBillboard(child)
		table.insert(allBillboards, bb)
	end
end)

CandiesFolder.ChildRemoved:Connect(function()
	for i = #allBillboards, 1, -1 do
		if not allBillboards[i] or allBillboards[i].Parent == nil then
			table.remove(allBillboards, i)
		end
	end
	ensureMinCandies()
end)

-- ==============================
-- ✨ Brillo animado global (RenderStepped único)
-- ==============================
local start = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - start
	local pulse = (math.sin(t * Settings.PulseSpeed * math.pi * 2) + 1) / 2
	local transparency = Settings.TransMin + pulse * (Settings.TransMax - Settings.TransMin)

	for i, bb in ipairs(allBillboards) do
		if bb and bb.Parent then
			bb.Enabled = i <= Settings.MaxVisibleBillboards
			local circle = bb:FindFirstChild("Circle")
			if circle then
				circle.BackgroundTransparency = transparency
			end
		end
	end
end)

-- ==============================
-- 🚀 Inicio
-- ==============================
ensureMinCandies()
