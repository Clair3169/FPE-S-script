local Lighting = game:GetService("Lighting")

local function disableBlackoutEffects()
    local effects = {
        Lighting:FindFirstChild("BlackoutColorCorrection"),
        Lighting:FindFirstChild("DarknessColorCorrection")
    }

    for _, effect in ipairs(effects) do
        if effect then
            effect.Enabled = false
            effect:GetPropertyChangedSignal("Enabled"):Connect(function()
                effect.Enabled = false
            end)
        end
    end
end

disableBlackoutEffects()
