task.wait(2)

local player = game.Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

local bindableFunction = Instance.new("BindableFunction")
bindableFunction.OnInvoke = function(buttonClicked)
	if buttonClicked == "Yes" then
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Clair3169/FPE-S-script-Test/refs/heads/main/Cframe_Walkspeed.lua", true))()
		loadstring(game:HttpGet("https://raw.githubusercontent.com/Clair3169/FPE-S-script-Test/refs/heads/main/Notification_Warning.lua", true))()
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
})￼Enter
