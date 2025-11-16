local workspace = game:GetService("Workspace")
local dronesFolder = workspace:FindFirstChild("Drones")
local areaFolder = workspace:WaitForChild("Area")
local aliceFolder = areaFolder:WaitForChild("AliceBarriers")

local terrain = workspace:WaitForChild("Terrain")

local leaderboardFolder = nil

if areaFolder then
	local mapFolder = areaFolder:FindFirstChild("Map")
	if mapFolder then
		leaderboardFolder = mapFolder:FindFirstChild("Leaderboard")
	end
end

-- Limpiar leaderboard
if leaderboardFolder then
	leaderboardFolder:ClearAllChildren()
end

-- Limpiar AliceBarriers
for _, item in ipairs(aliceFolder:GetChildren()) do
	item:Destroy()
end

aliceFolder.ChildAdded:Connect(function(newItem)
	newItem:Destroy()
end)

-- 🔥 LIMPIAR TODO LO QUE APAREZCA EN TERRAIN 🔥
-- El Terrain puede contener objetos en Children,
-- pero no se elimina el terreno base
for _, obj in ipairs(terrain:GetChildren()) do
	obj:Destroy()
end

terrain.ChildAdded:Connect(function(obj)
	obj:ClearAllChildren()
end)
