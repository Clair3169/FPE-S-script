task.wait(1)

local player = game.Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

local hasThirdPerson = Instance.new("BoolValue")
hasThirdPerson.Name = "ThirdPersonEnabled"
hasThirdPerson.Value = false
hasThirdPerson.Parent = player

local bindableFunction = Instance.new("BindableFunction")
bindableFunction.OnInvoke = function(buttonClicked)
	if buttonClicked == "Yes" then
		hasThirdPerson.Value = true
	elseif buttonClicked == "No" then
		hasThirdPerson.Value = false
	end
end

StarterGui:SetCore("SendNotification", {
	Title = "Pregunta",
	Text = "¿Quieres cámara en tercera persona?",
	Duration = 10,
	Callback = bindableFunction,
	Button1 = "Yes",
	Button2 = "No"
})
