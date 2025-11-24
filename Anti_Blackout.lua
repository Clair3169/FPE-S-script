local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Nombres de los efectos que deseas bloquear
local effectNames = {
    "BlackoutColorCorrection",
    "DarknessColorCorrection"
}

local connections = {}
local protectionActive = false

-- Devuelve true si el personaje está dentro de Alices o Teachers
local function isInSpecialFolder(char)
    local parent = char and char.Parent
    if not parent then return false end
    return parent.Name == "Alices" or parent.Name == "Teachers"
end

-- Protege: desactiva y evita que se activen los efectos
local function enableProtection()
    if protectionActive then return end
    protectionActive = true

    -- Guarda y vigila los efectos actuales (si existen)
    for _, name in ipairs(effectNames) do
        local effect = Lighting:FindFirstChild(name)

        if effect then
            effect.Enabled = false
            connections[name] = effect:GetPropertyChangedSignal("Enabled"):Connect(function()
                if effect.Enabled then
                    effect.Enabled = false
                end
            end)
        end
    end

    -- Detectar si más adelante aparecen efectos nuevos con esos nombres
    connections._child = Lighting.ChildAdded:Connect(function(child)
        if table.find(effectNames, child.Name) then
            child.Enabled = false
            connections[child.Name] = child:GetPropertyChangedSignal("Enabled"):Connect(function()
                if child.Enabled then
                    child.Enabled = false
                end
            end)
        end
    end)
end

-- Desactiva la protección y desconecta eventos
local function disableProtection()
    if not protectionActive then return end
    protectionActive = false
    
    for _, conn in pairs(connections) do
        conn:Disconnect()
    end

    connections = {}
end

-- Activar o desactivar protección dependiendo del folder donde está el personaje
local function updateProtection(char)
    if isInSpecialFolder(char) then
        disableProtection()
    else
        enableProtection()
    end
end

-- ---- EVENTOS DEL PLAYER ----
local function onCharacterAdded(char)
    updateProtection(char)

    -- Detectar cambio de carpeta del personaje
    char:GetPropertyChangedSignal("Parent"):Connect(function()
        updateProtection(char)
    end)
end

-- Suscripción a CharacterAdded
player.CharacterAdded:Connect(onCharacterAdded)

-- Si ya existe personaje, evaluarlo
if player.Character then
    onCharacterAdded(player.Character)
end
