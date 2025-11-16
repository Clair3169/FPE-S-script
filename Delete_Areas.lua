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

if leaderboardFolder then
	leaderboardFolder:ClearAllChildren()
end

for _, item in ipairs(aliceFolder:GetChildren()) do
	item:Destroy()
end

aliceFolder.ChildAdded:Connect(function(newItem)
	newItem:Destroy()
end)

terrain:ClearAllChildren()

terrain.ChildAdded:Connect(function(child)
	if child:IsA("BasePart") or child:IsA("Model") or child:IsA("Folder") then
		child:Destroy()
	end
end)
