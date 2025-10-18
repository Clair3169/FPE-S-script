-- ======================================================
-- 🍬 Candy Billboard + AutoSpawner (Mantiene 7 Candies activos)
-- Ejecutar desde consola del cliente en Play Mode
-- ======================================================

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")

local CandiesFolder = Workspace:FindFirstChild("Candies") or Instance.new("Folder", Workspace)
CandiesFolder.Name = "Candies"

-- ==============================
-- ⚙️ CONFIGURACIÓN
-- ==============================
local Settings = {
	MaxVisibleBillboards = 7,   -- Cuántos se ven activos
	MinCandiesAlive = 7,        -- Cuántos Candies debe haber siempre en el mapa
	BillboardSize = UDim2.new(0, 12, 0, 12),
	BillboardOffset = Vector3.new(0, 2, 0),
	CircleColor = Color3.fromRGB(255, 140, 0),
	TransMin = 0.15,
	TransMax = 0.4,
	PulseSpeed = 2,             -- velocidad del brillo
	RespawnRadius = 40,         -- radio aleatorio para generar nuevos Candies
	RespawnCenter = Vector3.new(0, 2, 0), -- posición central del spawn
}

-- ==============================
-- 🔧 FUNCIÓN PARA CREAR UN NUEVO CANDY (MeshPart)
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
		Settings.RespawnCenter.Y,
		math.random(-Settings.RespawnRadius, Settings.RespawnRadius)
	)
	candy.Position = Settings.RespawnCenter + offset
	candy.Parent = CandiesFolder

	return candy
end

-- ==============================
-- 🌀 CREAR BILLBOARD
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
	billboard.Adornee = candy
	billboard.Enabled = false
	billboard.Parent = candy

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

	return billboard, circle
end

-- ==============================
-- 📦 LISTA GLOBAL
-- ==============================
local allBillboards = {}
local circles = {}

-- ==============================
-- 🔄 MANTENER SIEMPRE 7 CANDIES ACTIVOS
-- ==============================
local function maintainCandies()
	while true do
		local count = #CandiesFolder:GetChildren()
		if count < Settings.MinCandiesAlive then
			for _ = 1, Settings.MinCandiesAlive - count do
				local newCandy = spawnCandy()
				local billboard, circle = createBillboard(newCandy)
				table.insert(allBillboards, billboard)
				table.insert(circles, circle)
			end
		end
		task.wait(1) -- revisa cada segundo
	end
end

-- ==============================
-- 🧩 INICIALIZACIÓN DE EXISTENTES
-- ==============================
for _, candy in ipairs(CandiesFolder:GetChildren()) do
	if candy:IsA("MeshPart") and candy.Name == "Candy" then
		local billboard, circle = createBillboard(candy)
		table.insert(allBillboards, billboard)
		table.insert(circles, circle)
	end
end

-- ==============================
-- 🔔 NUEVOS O ELIMINADOS
-- ==============================
CandiesFolder.ChildAdded:Connect(function(child)
	if child:IsA("MeshPart") and child.Name == "Candy" then
		local billboard, circle = createBillboard(child)
		table.insert(allBillboards, billboard)
		table.insert(circles, circle)
		for i, bb in ipairs(allBillboards) do
			bb.Enabled = i <= Settings.MaxVisibleBillboards
		end
	end
end)

CandiesFolder.ChildRemoved:Connect(function()
	task.defer(function()
		for i = #allBillboards, 1, -1 do
			local bb = allBillboards[i]
			if not bb or not bb.Parent then
				table.remove(allBillboards, i)
				table.remove(circles, i)
			end
		end
	end)
end)

-- ==============================
-- ✨ ANIMACIÓN GLOBAL DE BRILLO
-- ==============================
local startTime = tick()
RunService.RenderStepped:Connect(function()
	local t = tick() - startTime
	local pulse = (math.sin(t * Settings.PulseSpeed * math.pi * 2) + 1) / 2
	local trans = Settings.TransMin + pulse * (Settings.TransMax - Settings.TransMin)

	for i, bb in ipairs(allBillboards) do
		if bb and bb.Parent then
			bb.Enabled = i <= Settings.MaxVisibleBillboards
			local circle = bb:FindFirstChild("Circle")
			if circle then
				circle.BackgroundTransparency = trans
			end
		end
	end
end)

-- ==============================
-- 🕓 INICIAR LOOP DE REABASTECIMIENTO
-- ==============================
task.spawn(maintainCandies)
