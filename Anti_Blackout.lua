do
    local Lighting = game:GetService("Lighting")
    local Players = game:GetService("Players")
    local player = Players.LocalPlayer
    local character = player.Character

    local isInSpecialFolder = false
    if character and character.Parent then
        local parentName = character.Parent.Name
        if parentName == "Alices" or parentName == "Teachers" then
            isInSpecialFolder = true
        end
    end

    local function disableBlackoutEffects()
        local effects = {
            Lighting:FindFirstChild("BlackoutColorCorrection"),
            Lighting:FindFirstChild("DarknessColorCorrection")
        }

        for _, effect in ipairs(effects) do
            if effect then
                effect.Enabled = false
                effect:GetPropertyChangedSignal("Enabled"):Connect(function()
                    if effect.Enabled == true then
                        effect.Enabled = false
                    end
                end)
            end
        end
    end

    if not isInSpecialFolder then
        disableBlackoutEffects()
    end
end
