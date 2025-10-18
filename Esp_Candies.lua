-- ======================================================
-- 🍊 Candy Billboard Marker (Tiny + Soft Glow)
-- ======================================================

local Workspace = game:GetService("Workspace")
local CandiesFolder = Workspace:WaitForChild("Candies")

-- 🎯 Crea un pequeño círculo naranja con brillo sutil sobre cada Candy
local function createBillboard(candy)
	if candy:FindFirstChild("CandyBillboard") then
		return
	end

	-- BillboardGui
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "CandyBillboard"
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.new(0, 10, 0, 10) -- 🔸 Muy pequeño
	billboard.LightInfluence = 0
	billboard.StudsOffset = Vector3.new(0, 1.5, 0)

	-- Frame circular naranja
	local circle = Instance.new("Frame")
	circle.Name = "Circle"
	circle.Size = UDim2.new(1, 0, 1, 0)
	circle.BackgroundColor3 = Color3.fromRGB(255, 140, 0)
	circle.BackgroundTransparency = 0.2
	circle.BorderSizePixel = 0
	circle.AnchorPoint = Vector2.new(0.5, 0.5)
	circle.Position = UDim2.new(0.5, 0, 0.5, 0)
	circle.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = circle

	-- Adjuntar
	local adornee = candy:FindFirstChildWhichIsA("BasePart") or candy
	billboard.Adornee = adornee
	billboard.Parent = adornee

	-- ✨ Efecto de brillo sutil (sin task.wait)
	task.spawn(function()
		local direction = 1
		while billboard.Parent do
			circle.BackgroundTransparency += direction * 0.02
			if circle.BackgroundTransparency >= 0.4 then
				direction = -1
			elseif circle.BackgroundTransparency <= 0.15 then
				direction = 1
			end
			game:GetService("RunService").RenderStepped:Wait()
		end
	end)
end

-- 🎯 Añadir a todos los Candy actuales
for _, item in ipairs(CandiesFolder:GetChildren()) do
	if item.Name == "Candy" then
		createBillboard(item)
	end
end

-- 🎯 Nuevos Candy que aparezcan
CandiesFolder.ChildAdded:Connect(function(child)
	if child.Name == "Candy" then
		createBillboard(child)
	end
end)

