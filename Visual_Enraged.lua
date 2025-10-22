-- Local Script
local Players = game:GetService("Players")
local player = Players.LocalPlayer

if not player then
    player = Players.LocalPlayerAdded:Wait()
end

local playerGui = player:WaitForChild("PlayerGui")
local gameUI = playerGui:WaitForChild("GameUI")
local visuals = gameUI:WaitForChild("Visuals")
local missCircle = visuals:WaitForChild("MissCircle")
local enragedVisuals = missCircle:WaitForChild("EnragedVisuals")

local function onVisibilityChanged()
    if enragedVisuals.Visible == true then
        enragedVisuals.Visible = false
    end
end

enragedVisuals:GetPropertyChangedSignal("Visible"):Connect(onVisibilityChanged)
onVisibilityChanged()
