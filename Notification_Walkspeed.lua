local player = game.Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local SoundService = game:GetService("SoundService")
local warningSound = Instance.new("Sound")
warningSound.SoundId = "rbxassetid://104980570072214"-- <-- ¡Recuerda cambiar este ID!
warningSound.Volume = 1
warningSound.Parent = SoundService

local bindableFunction = Instance.new("BindableFunction")

warningSound:Play()

warningSound.Ended:Connect(function()
    warningSound:Destroy()
end)

bindableFunction.OnInvoke = function(buttonClicked)
	if buttonClicked == "Yes" then
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Walkspeed.lua", true))()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Notification_Warning.lua", true))()
	elseif buttonClicked == "No" then
		-- no se hace nada
	end
end

StarterGui:SetCore("SendNotification", {
	Title = "Hey again!",
	Text = "Do you want to activate speed mode?",
	Icon = "rbxassetid://97207642508375",
	Duration = 20,
	Callback = bindableFunction,
	Button1 = "Yes",
	Button2 = "No"
})
