-- Servicios
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local localPlayer = Players.LocalPlayer
if not localPlayer then return end

-- Carpetas válidas
local targetFolderNames = {
	Alices = true,
	Teachers = true,
	Students = true
}

-- Caché y conexiones
local staminaCache = {}
local activeConnections = {}

local function disconnectAll()
	for _, conn in ipairs(activeConnections) do
		if conn and conn.Connected then
			conn:Disconnect()
		end
	end
	table.clear(activeConnections)
end

local function applyInfiniteStamina(character)
	if not character or not character:IsA("Model") then return end
	if staminaCache[character] then return end

	local playerFromCharacter = Players:GetPlayerFromCharacter(character)
	if playerFromCharacter ~= localPlayer then return end

	character:SetAttribute("Stamina", math.huge)
	character:SetAttribute("MaxStamina", math.huge)
	staminaCache[character] = true

	-- Limpiar al destruirse
	local destroyConn
	destroyConn = character.AncestryChanged:Connect(function(_, parent)
		if not parent then
			staminaCache[character] = nil
			if destroyConn and destroyConn.Connected then
				destroyConn:Disconnect()
			end
		end
	end)
	table.insert(activeConnections, destroyConn)
end

local function watchParentChanges(character)
	if not character then return end
	local conn = character:GetPropertyChangedSignal("Parent"):Connect(function()
		local parent = character.Parent
		if parent and targetFolderNames[parent.Name] then
			task.defer(function()
				if character.Parent then
					applyInfiniteStamina(character)
				end
			end)
		end
	end)
	table.insert(activeConnections, conn)
end

local function monitorFolder(folder)
	local function handleChild(child)
		if child:IsA("Model") then
			task.defer(function()
				applyInfiniteStamina(child)
				watchParentChanges(child)
			end)
		end
	end

	for _, child in ipairs(folder:GetChildren()) do
		handleChild(child)
	end

	local conn = folder.ChildAdded:Connect(handleChild)
	table.insert(activeConnections, conn)
end

local function connectTargetFolders()
	for folderName in pairs(targetFolderNames) do
		local folderInstance = Workspace:FindFirstChild(folderName)
		if folderInstance then
			monitorFolder(folderInstance)
		else
			local conn
			conn = Workspace.ChildAdded:Connect(function(child)
				if child.Name == folderName then
					monitorFolder(child)
					conn:Disconnect()
				end
			end)
			table.insert(activeConnections, conn)
		end
	end
end

-- Espera segura: el personaje debe estar en el Workspace y en carpeta válida
local function waitForValidParent(character)
	local start = os.clock()
	while character and os.clock() - start < 1 do -- 1 segundo máximo
		local parent = character.Parent
		if parent and targetFolderNames[parent.Name] then
			return true
		end
		task.wait(0.05)
	end
	return false
end

local function onCharacterAdded(character)
	disconnectAll()

	task.defer(function()
		if not character then return end

		-- Espera a que el personaje esté realmente en juego
		if not waitForValidParent(character) then
			-- incluso si no está en carpeta válida aún, aplicamos por seguridad
			applyInfiniteStamina(character)
		end

		watchParentChanges(character)
		connectTargetFolders()
	end)
end

localPlayer.CharacterAdded:Connect(onCharacterAdded)

if localPlayer.Character then
	onCharacterAdded(localPlayer.Character)
end
