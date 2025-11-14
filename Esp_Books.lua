-- 🟦 BOOK ESP (versión optimizada estilo B, robusta y limpia)
repeat task.wait() until game:IsLoaded()

---------------------------------------------------------------------
-- ⚙️ Servicios
---------------------------------------------------------------------
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
if not LocalPlayer then return end

---------------------------------------------------------------------
-- ⚙️ Configuración
---------------------------------------------------------------------
local MAX_DISTANCE = 150
local COLOR_FILL   = Color3.fromRGB(135, 206, 250)
local COLOR_OUT    = Color3.fromRGB(0, 0, 255)

---------------------------------------------------------------------
-- 🧠 Estado interno
---------------------------------------------------------------------
local BooksFolder = Workspace:FindFirstChild("Books")
local asleep = false

local HighlightFolder = Workspace:FindFirstChild("HighlightBooks_Main") or Instance.new("Folder")
HighlightFolder.Name = "HighlightBooks_Main"
HighlightFolder.Parent = Workspace

local Active = {} -- part → highlight

---------------------------------------------------------------------
-- 🔍 Utilidades
---------------------------------------------------------------------
local function getLocalPos()
	local char = LocalPlayer.Character
	if not char then return nil end
	local root = char:FindFirstChild("HumanoidRootPart")
	return root and root.Position or nil
end

local function getTargetPart(obj)
	if not obj then return nil end

	if obj:IsA("BasePart") then
		return obj
	elseif obj:IsA("Model") then
		if obj.PrimaryPart and obj.PrimaryPart:IsA("BasePart") then
			return obj.PrimaryPart
		end
		for _, d in ipairs(obj:GetDescendants()) do
			if d:IsA("BasePart") then
				return d
			end
		end
	end

	return nil
end

---------------------------------------------------------------------
-- ✏️ Crear Highlight
---------------------------------------------------------------------
local function createHL(part)
	if not part or not part:IsA("BasePart") then return end
	if asleep then return end

	-- evitar duplicados
	if Active[part] then
		if Active[part].Parent then return end
		Active[part]:Destroy()
		Active[part] = nil
	end

	-- asegurarse que esté replicado
	if not part:IsDescendantOf(Workspace) then
		task.wait(0.05)
		if not part:IsDescendantOf(Workspace) then return end
	end

	local hl = Instance.new("Highlight")
	hl.Name = "BookHL"
	hl.FillColor = COLOR_FILL
	hl.OutlineColor = COLOR_OUT
	hl.FillTransparency = 0
	hl.OutlineTransparency = 1
	hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	hl.Adornee = part
	hl.Enabled = false
	hl.Parent = HighlightFolder

	Active[part] = hl
end

---------------------------------------------------------------------
-- ❌ Remover Highlight
---------------------------------------------------------------------
local function removeHL(part)
	local hl = Active[part]
	if hl then
		hl:Destroy()
	end
	Active[part] = nil
end

---------------------------------------------------------------------
-- 🌓 Actualizar distancia
---------------------------------------------------------------------
local function updateRange(force)
	local pos = getLocalPos()
	if not pos or asleep then
		for part, hl in pairs(Active) do
			if hl.Enabled then hl.Enabled = false end
		end
		return
	end

	for part, hl in pairs(Active) do
		if not part or not part.Parent then
			removeHL(part)
		else
			if not hl or not hl.Parent then
				removeHL(part)
				createHL(part)
				hl = Active[part]
			end

			local dist = (part.Position - pos).Magnitude
			local visible = dist <= MAX_DISTANCE

			if force or hl.Enabled ~= visible then
				hl.Enabled = visible
			end
		end
	end
end

---------------------------------------------------------------------
-- 📚 Escaneo inicial
---------------------------------------------------------------------
local function scanBooks()
	if not BooksFolder then return end

	for _, child in ipairs(BooksFolder:GetChildren()) do
		local part = getTargetPart(child)
		if part then createHL(part) end

		-- si es modelo, escuchar partes internas
		if child:IsA("Model") then
			child.DescendantAdded:Connect(function(d)
				if asleep then return end
				if d:IsA("BasePart") then
					local primary = getTargetPart(child)
					if primary and not Active[primary] then
						createHL(primary)
					end
				end
			end)
		end
	end

	updateRange(true)
end

---------------------------------------------------------------------
-- 🔌 Eventos de Books
---------------------------------------------------------------------
local function hookBooks()
	if not BooksFolder or BooksFolder:GetAttribute("Hooked") then return end
	BooksFolder:SetAttribute("Hooked", true)

	BooksFolder.ChildAdded:Connect(function(child)
		if asleep then return end
		local part = getTargetPart(child)
		if part then createHL(part) end
		updateRange(true)

		if child:IsA("Model") then
			child.DescendantAdded:Connect(function(d)
				if asleep then return end
				if d:IsA("BasePart") then
					local p = getTargetPart(child)
					if p and not Active[p] then createHL(p) end
				end
			end)
		end
	end)

	BooksFolder.ChildRemoved:Connect(function(child)
		local p = getTargetPart(child)
		if p then removeHL(p) end
	end)
end

---------------------------------------------------------------------
-- 😴 Detección de Sleep (Alices / Teachers)
---------------------------------------------------------------------
local function checkSleep()
	local char = LocalPlayer.Character
	if not char then return end

	local parent = char.Parent
	local new = parent and (parent.Name == "Alices" or parent.Name == "Teachers")

	if new ~= asleep then
		asleep = new
		if asleep then
			for _, hl in pairs(Active) do
				hl.Enabled = false
			end
		else
			if BooksFolder then scanBooks() end
			updateRange(true)
		end
	end
end

---------------------------------------------------------------------
-- 🛠 Inicialización
---------------------------------------------------------------------
local function init()
	-- esperar root
	local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local root = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart")

	-- asegurar carpeta Books
	if not BooksFolder then
		for i = 1, 40 do
			BooksFolder = Workspace:FindFirstChild("Books")
			if BooksFolder then break end
			task.wait(0.1)
		end
	end

	if BooksFolder then
		hookBooks()
		scanBooks()
	end

	local last = root.Position
	root:GetPropertyChangedSignal("Position"):Connect(function()
		if asleep then return end
		local new = root.Position
		if (new - last).Magnitude > 4 then
			last = new
			updateRange()
		end
	end)
end

---------------------------------------------------------------------
-- 🌍 Detectar recreación de Books
---------------------------------------------------------------------
Workspace.ChildAdded:Connect(function(c)
	if c.Name == "Books" and c:IsA("Folder") then
		BooksFolder = c
		hookBooks()
		scanBooks()
	end
end)

Workspace.ChildRemoved:Connect(function(c)
	if c == BooksFolder then
		for part in pairs(Active) do removeHL(part) end
		BooksFolder = nil
	end
end)

---------------------------------------------------------------------
-- 🧬 Character events
---------------------------------------------------------------------
LocalPlayer.CharacterAdded:Connect(function(char)
	char:GetPropertyChangedSignal("Parent"):Connect(checkSleep)
	checkSleep()
	task.defer(function()
		init()
		updateRange(true)
	end)
end)

if LocalPlayer.Character then
	LocalPlayer.Character:GetPropertyChangedSignal("Parent"):Connect(checkSleep)
	checkSleep()
	task.defer(function()
		init()
		updateRange(true)
	end)
end

---------------------------------------------------------------------
-- 🔧 Auto-Repair
---------------------------------------------------------------------
task.spawn(function()
	while task.wait(3) do
		if not BooksFolder then continue end

		-- asegurar highlight por cada libro
		for _, child in ipairs(BooksFolder:GetChildren()) do
			local part = getTargetPart(child)
			if part and not Active[part] and not asleep then
				createHL(part)
			end
		end

		-- limpiar huérfanos
		for part in pairs(Active) do
			if not part or not part.Parent then
				removeHL(part)
			end
		end

		updateRange(true)
	end
end)
