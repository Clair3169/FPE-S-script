--// Servicios
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local backpack = player:WaitForChild("Backpack")
local leaderstats = player:WaitForChild("leaderstats")
local points = leaderstats:WaitForChild("Points")

local event = ReplicatedStorage:WaitForChild("ReliableRedEvent")

-- Configuración
local COST = 50
local TIMEOUT = 1 -- reintento si el server no entrega la poción

local isDormant = false
local pending = false

local buyArgs = {
	{
		["5"] = {
			{
				"HealPotion",
				n = 1
			}
		}
	},
	{}
}

--// Dormancia: cuando el character está en Alices o Teachers
local function updateDormant()
	local char = player.Character
	if not char then return end

	local parent = char.Parent
	local A = Workspace:FindFirstChild("Alices")
	local T = Workspace:FindFirstChild("Teachers")

	local wasDormant = isDormant
	isDormant = (parent == A or parent == T)

	if wasDormant and not isDormant then
		-- salimos de zona dormida → reactivar compra
		task.defer(function()
			pending = false
			tryBuy()
		end)
	end
end

--// Lógica principal de compra
function tryBuy()
	if isDormant then return end

	-- Ya tengo la poción → no hacer nada
	if backpack:FindFirstChild("HealPotion") then
		pending = false
		return
	end

	-- Estoy esperando una compra del server
	if pending then return end

	-- ¿Tengo puntos suficientes?
	local amount = tonumber(points.Value) or 0
	if amount < COST then return end

	-- Enviar compra
	pending = true
	event:FireServer(unpack(buyArgs))

	-- Si en X segundos no llegó la poción, reintento
	task.delay(TIMEOUT, function()
		if pending and not backpack:FindFirstChild("HealPotion") then
			pending = false
			tryBuy()
		end
	end)
end

--// EVENTOS IMPORTANTES

-- Si cambian los puntos (quizá luego tengo 50)
points.Changed:Connect(tryBuy)

-- Cuando aparece algo en el backpack
backpack.ChildAdded:Connect(function(child)
	if child.Name == "HealPotion" then
		pending = false -- Confirmamos compra
	else
		tryBuy()
	end
end)

-- Cuando desaparece la poción por usarla → RESUPPLY AUTOMÁTICO
backpack.ChildRemoved:Connect(function(child)
	if child.Name == "HealPotion" then
		pending = false
		tryBuy()
	end
end)

-- Respawn
player.CharacterAdded:Connect(function(char)
	char:GetPropertyChangedSignal("Parent"):Connect(updateDormant)
	task.defer(updateDormant)
	task.defer(tryBuy)
end)

-- Primera ejecución
task.defer(function()
	if player.Character then updateDormant() end
	tryBuy()
end)
