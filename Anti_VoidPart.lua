local player = game.Players.LocalPlayer
local workspace = game.Workspace
local TweenService = game:GetService("TweenService")

-- 1. Crear la parte y configurar lo básico
local part = Instance.new("Part")
part.Name = "PlataformaNeonTween"
part.Size = Vector3.new(12, 1, 12)
part.CFrame = CFrame.new(-231.786987, 125.599998, 267.095856, 1, 0, 0, 0, 1, 0, 0, 0, 1)
part.Material = Enum.Material.ForceField
part.Anchored = true
part.CanCollide = true
part.Parent = workspace

-- 2. Definir la lista de colores del Arcoíris
-- Usaremos una lista ordenada de colores para que la transición sea suave
local coloresRainbow = {
	Color3.fromRGB(255, 0, 0),   -- Rojo
	Color3.fromRGB(255, 255, 0), -- Amarillo
	Color3.fromRGB(0, 255, 0),   -- Verde
	Color3.fromRGB(0, 255, 255), -- Cian
	Color3.fromRGB(0, 0, 255),   -- Azul
	Color3.fromRGB(255, 0, 255)  -- Magenta
}

-- 3. Configuración de la animación (Info)
-- Tiempo: 2 segundos para pasar de un color a otro
local tweenInfo = TweenInfo.new(6, Enum.EasingStyle.Linear) 

-- 4. Función recursiva para cambiar el color
local colorActual = 0

local function siguienteColor()
	-- Aumentamos el índice (1, 2, 3... hasta llegar al final y volver a empezar)
	colorActual = (colorActual % #coloresRainbow) + 1
	local objetivo = { Color = coloresRainbow[colorActual] }
	
	-- Creamos la animación
	local tween = TweenService:Create(part, tweenInfo, objetivo)
	
	-- IMPORTANTE: Esto reemplaza al bucle.
	-- Cuando termina la animación (Completed), llamamos a la función de nuevo.
	tween.Completed:Connect(siguienteColor)
	
	tween:Play()
end

-- 5. Iniciar la cadena
siguienteColor()
