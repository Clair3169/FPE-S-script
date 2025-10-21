task.wait(1)

local player = game.Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

local hasThirdPerson = Instance.new("BoolValue")
hasThirdPerson.Name = "ThirdPersonEnabled"
hasThirdPerson.Value = false
hasThirdPerson.Parent = player

local bindableFunction = Instance.new("BindableFunction")
bindableFunction.OnInvoke = function(buttonClicked)
	if buttonClicked == "Yess!!" then
		hasThirdPerson.Value = true
		-- Tercera persona
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/3rd_Person.lua", true))()
		-- Shift Lock
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Shiftlock.lua", true))()
	elseif buttonClicked == "Nha" then
		hasThirdPerson.Value = false
	end
end

StarterGui:SetCore("SendNotification", {
	Title = "Hey you!",
	Text = "Do you want to activate third person mode?",
	Icon = "rbxassetid://97207642508375",
	Duration = 20,
	Callback = bindableFunction,
	Button1 = "Yess!!",
	Button2 = "Nha"
})
