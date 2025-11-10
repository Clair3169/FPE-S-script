local SoundService = game:GetService("SoundService")

local warningSound = Instance.new("Sound")
warningSound.SoundId = "rbxassetid://1570162306" -- <-- ¡Recuerda cambiar este ID!
warningSound.Parent = SoundService

warningSound:Play()

warningSound.Ended:Connect(function()
    warningSound:Destroy()
end)

game.StarterGui:SetCore("SendNotification", {
    Title = "Warning!";
    Text = "Be careful, this action cannot be undone";
    Icon = ""; 
    Duration = 5; 
})
