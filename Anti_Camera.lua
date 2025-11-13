-- LocalScript: Anti-ScreenGui creado dinámicamente
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Función para eliminar ScreenGui no deseado
local function eliminarScreenGui(gui)
	if gui:IsA("ScreenGui") and gui.Name == "ScreenGui" then
		gui:Destroy()
	end
end

-- Revisar si ya existe uno al iniciar (por si acaso)
for _, child in ipairs(playerGui:GetChildren()) do
	eliminarScreenGui(child)
end

-- Conectar evento para detectar creaciones futuras
playerGui.ChildAdded:Connect(eliminarScreenGui)

-- (Opcional) También escuchar si se inserta desde StarterGui a PlayerGui en tiempo de ejecución
local StarterGui = game:GetService("StarterGui")

StarterGui.ChildAdded:Connect(function(gui)
	if gui:IsA("ScreenGui") and gui.Name == "ScreenGui" then
		gui:Destroy()
	end
end)
