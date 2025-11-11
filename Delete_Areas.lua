local workspace = game:GetService("Workspace")
local dronesFolder = workspace:FindFirstChild("Drones")
local areaFolder = workspace:WaitForChild("Area")
local aliceFolder = areaFolder:WaitForChild("AliceBarriers")

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
