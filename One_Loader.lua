--// LoadOnceManager.lua
-- Coloca este script en StarterPlayerScripts o similar.

-- SERVICIOS
local replicatedStorage = game:GetService("ReplicatedStorage")

-- NOMBRE DE LA MARCA PARA RECORDAR QUE YA SE EJECUTÓ
local flagName = "HasLoadedScriptsOnce"

-- ----------------------------------------------------
-- LISTA DE URLs RAW (Tal cual aparecen en GitHub)
-- ----------------------------------------------------
local urls_raw = {
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/AimBot.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Anti_Blackout.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Delete_Areas.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Dialogues.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/JumpPower_Perma.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Key_notification.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/SprintFake.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Stamina_INF.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Stundents_Esp.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Teachers_Esp.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/TextLabel.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Time.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Visual_Enraged.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Welcome_Script.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Esp_Books.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Anti_Camera.lua",
    "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/NO_RAGDOLL.lua",
	"https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Anti_VoidPart.lua",
	"https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Auto_Block.lua"
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
        else
            -- nada XDDD
        end
    end)
end

-- Función para marcar que ya se ejecutó
local function setExecutedFlag()
	local flag = Instance.new("BoolValue")
	flag.Name = flagName
	flag.Value = true
	flag.Parent = replicatedStorage
end

-- Función para verificar si ya se ejecutó
local function hasExecuted()
	return replicatedStorage:FindFirstChild(flagName) ~= nil
end

-- Función Principal: Cargar una sola vez
local function loadOnce()
	if hasExecuted() then
		warn("⚠️ Los scripts ya se han cargado anteriormente.")
		return
	end

    -- Iteramos sobre la lista y aplicamos la carga robusta a cada URL
	for _, url in ipairs(urls_raw) do
		LoadScriptRobusto(url)
	end

	setExecutedFlag()
end

-- Ejecutar
loadOnce()
