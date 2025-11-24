local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")

local effectsToMonitor = {
    Lighting:FindFirstChild("BlackoutColorCorrection"),
    Lighting:FindFirstChild("DarknessColorCorrection")
}

local currentConnections = {}
local protectionActive = true

local function checkIfInSpecialFolder(char)
    local character = char or Players.LocalPlayer.Character
    if character and character.Parent then
        local parentName = character.Parent.Name
        return parentName == "Alices" or parentName == "Teachers"
    end
    return false
end

local function applyProtection()
    if protectionActive then return end

    for _, effect in ipairs(effectsToMonitor) do
        if effect then
            effect.Enabled = false
            
            local connection = effect:GetPropertyChangedSignal("Enabled"):Connect(function()
                if effect.Enabled == true then
                    effect.Enabled = false
                end
            end)
            table.insert(currentConnections, connection)
        end
    end
    protectionActive = true
end

local function removeProtection()
    if not protectionActive then return end
    
    for _, connection in ipairs(currentConnections) do
        connection:Disconnect()
    end
    
    currentConnections = {}
    protectionActive = false
end

local function checkAndToggleProtection(char)
    if char and checkIfInSpecialFolder(char) then
        removeProtection()
    else
        applyProtection()
    end
end

local player = Players.LocalPlayer or Players.PlayerAdded:Wait()

local function onCharacterAdded(char)
    checkAndToggleProtection(char)
    
    char:GetPropertyChangedSignal("Parent"):Connect(function()
        checkAndToggleProtection(char)
    end)
end

player.CharacterAdded:Connect(onCharacterAdded)

if player.Character then
    onCharacterAdded(player.Character)
end
