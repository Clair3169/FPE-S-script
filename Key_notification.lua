task.wait(6)

local player = game.Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")

local hasThirdPerson = Instance.new("BoolValue")
hasThirdPerson.Name = "ThirdPersonEnabled"
hasThirdPerson.Value = false
hasThirdPerson.Parent = player

local SoundService = game:GetService("SoundService")
local warningSound = Instance.new("Sound")
warningSound.SoundId = "rbxassetid://8382337318" -- <-- ¡Recuerda cambiar este ID!
warningSound.Volume = 1
warningSound.Parent = SoundService

local bindableFunction = Instance.new("BindableFunction")

warningSound:Play()

warningSound.Ended:Connect(function()
    warningSound:Destroy()
end)

-- ----------------------------------------------------
-- LISTA DE URLs RAW (Tal cual aparecen en GitHub)
-- ----------------------------------------------------
local RAW_URLS_TO_LOAD = {
    -- 1. Tercera persona
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/3rd_Person.lua",
    
    -- 2. Shift Lock
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Shiftlock.lua",
    
    -- 3. Cframe Walkspeed (Nombre corregido a la versión funcional)
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Notification_Walkspeed.lua",
}

-- ----------------------------------------------------
-- FUNCIÓN DE CARGA ROBUSTA (Anti-Caché, Anti-Nil Value, Paralela)
-- ----------------------------------------------------
local function LoadScriptRobusto(url)
    task.spawn(function()
        -- 1. Anti-Caché: Agregamos un parámetro aleatorio
        local cleanUrl = url .. "?nocache=" .. tostring(math.random(1, 1000000))
        
        -- 2. Descarga Segura
        local success, content = pcall(function()
            return game:HttpGet(cleanUrl, true)
        end)

        if not success then
            warn("❌ [RED] Fallo al descargar: " .. url)
            return
        end

        -- 3. Verificación de contenido
        if type(content) ~= "string" or #content < 10 then
            warn("⚠️ [VACÍO] El script descargado parece estar vacío o roto: " .. url)
            return
        end

        -- 4. Compilación (Evita el error 'attempt to call a nil value')
        local func, loadErr = loadstring(content)
        if not func then
            warn("❌ [SINTAXIS] Error en el código del script externo:", url, "\n", loadErr)
            return
        end

        -- 5. Ejecución Protegida
        local runSuccess, runErr = pcall(func)
        if not runSuccess then
            warn("⚠️ [EJECUCIÓN] Error al correr el script:", url, "\n", runErr)
        end
    end)
end

bindableFunction.OnInvoke = function(buttonClicked)
	if buttonClicked == "Yess!!" then
		hasThirdPerson.Value = true
        
        -- Itera sobre la lista y carga cada script de forma segura y paralela
        for _, url in ipairs(RAW_URLS_TO_LOAD) do
            LoadScriptRobusto(url)
        end
		
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
