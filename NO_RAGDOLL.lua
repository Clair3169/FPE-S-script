local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer

local debrisFolder = workspace:WaitForChild("Debris")

debrisFolder.ChildAdded:Connect(function(model)
    task.wait(0.05)

    local player = Players:GetPlayerFromCharacter(model)
    if player and player ~= localPlayer then
        model:Destroy()
        return
    end

    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if humanoid and model ~= localPlayer.Character then
        model:Destroy()
    end
end)
