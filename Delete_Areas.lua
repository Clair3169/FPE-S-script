local workspace = game:GetService("Workspace")

local dronesFolder = workspace:FindFirstChild("Drones")

local areaFolder = workspace:FindFirstChild("Area")
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
