-- LocalScript: FPE Loader mejorado (soporta añadir URLs dinámicamente)
local global_env = (type(getgenv) == "function" and getgenv()) or _G

-- Si ya existe el loader, reutilizarlo (para evitar recrearlo)
if global_env.FPE_Loader then
    -- Ya tienes el manager disponible como global_env.FPE_Loader
    return
end

local Loader = {}
Loader.__index = Loader

-- Crear nueva instancia
local function new_loader()
    local self = setmetatable({}, Loader)

    -- tabla de scripts: lista de {name=..., url=...}
    self.scripts = {
        {name = "Script FPE", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/FPE%3As_esp_script.lua"},
        {name = "TextLabel", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/TextLabel.lua"},
        {name = "JumpPower Perma", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/JumpPower_Perma.lua"},
        {name = "Timer", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Time.lua"},
        {name = "Students ESP", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Stundents_Esp.lua"},
        {name = "Dialogue_Random", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Dialogues.lua"},
        {name = "AimBot", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/AimBot.lua"},
        {name = "Inf Stamina", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Stamina_INF.lua"},
        {name = "Welcome Dialogue", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Welcome_Script.lua"},
        {name = "Esp_Candies (TEMPORAL)", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Esp_Candies.lua"},
    }

    -- tabla/set para URLs ya cargadas (evita duplicados)
    self.loaded_urls = global_env.FPE_loaded_urls or {}
    global_env.FPE_loaded_urls = self.loaded_urls

    -- banderas y configuración
    self.FLAG_NAME = "FPE_SCRIPTS_LOADED_ONCE" -- evita re-ejecución del paquete completo
    self.loaded_flag_set = global_env[self.FLAG_NAME] == true

    -- si no estaba marcada la bandera global, la ponemos para evitar reentradas
    global_env[self.FLAG_NAME] = true

    -- si ya tenía elementos en loaded_urls, consideramos que algunos ya estaban cargados
    self.loaded = false -- si preferís marcar true si hay elementos en loaded_urls, cambiaría comportamiento
    return self
end

-- helper: checkea si url ya existe en loaded_urls
function Loader:is_url_loaded(url)
    for _, u in ipairs(self.loaded_urls) do
        if u == url then return true end
    end
    return false
end

-- helper: intenta cargar una URL con pcall
function Loader:load_url_entry(entry)
    local name, url = entry.name or ("URL: "..tostring(entry.url)), entry.url
    if not url or url == "" then
        warn("FPE Loader: URL inválida para "..tostring(name))
        return false
    end
    if self:is_url_loaded(url) then
        print(("FPE Loader: '%s' ya cargado, omitiendo."):format(name))
        return true
    end

    local ok, err = pcall(function()
        local res = game:HttpGet(url, true)
        local func = loadstring(res)
        if type(func) ~= "function" then
            error("loadstring no devolvió función para "..tostring(url))
        end
        func()
    end)

    if ok then
        table.insert(self.loaded_urls, url)
        print(("FPE Loader: '%s' cargado correctamente."):format(name))
        return true
    else
        warn(("FPE Loader: fallo al cargar '%s' -> %s"):format(name, tostring(err)))
        return false
    end
end

-- Cargar todo lo que falte en la lista scripts
function Loader:load_all()
    for _, entry in ipairs(self.scripts) do
        self:load_url_entry(entry)
    end
    self.loaded = true
end

-- Añadir single URL (name opcional). autoload: si true, la carga se hace inmediatamente.
function Loader:add(url, name, autoload)
    if type(url) ~= "string" or url == "" then
        error("FPE Loader: url inválida en add(url, name, autoload)")
    end
    local entry = {name = name or url, url = url}

    -- evitar duplicar en lista scripts
    for _, e in ipairs(self.scripts) do
        if e.url == url then
            -- si autoload y ya está en lista, intentar cargar si no estaba cargada
            if autoload then
                self:load_url_entry(e)
            end
            return
        end
    end

    table.insert(self.scripts, entry)

    if autoload or self.loaded then
        -- si el manager ya corrió antes o pedimos autoload, cargar inmediatamente
        self:load_url_entry(entry)
    end
end

-- Añadir multiples en formato { {url=...,name=...}, ... } o {"url1","url2",...}
function Loader:add_many(t, autoload)
    if type(t) ~= "table" then return end
    -- si es lista simple de strings
    if #t > 0 and type(t[1]) == "string" then
        for _, url in ipairs(t) do
            self:add(url, nil, autoload)
        end
    else
        -- lista de objetos
        for _, obj in ipairs(t) do
            if type(obj) == "table" then
                self:add(obj.url or obj[1], obj.name or obj[2], autoload)
            end
        end
    end
end

-- crear instancia y exponerla globalmente
local instance = new_loader()
global_env.FPE_Loader = instance

-- Auto-load inicial (intentar cargar todos los scripts conocidos)
instance:load_all()

-- FIN del LocalScript. Ahora puedes usar global_env.FPE_Loader desde la consola o desde otros scripts.
-- Ejemplos de uso:
-- global_env.FPE_Loader:add("https://tu-url-aqui.lua", "MiScriptNuevo", true) -- añade y carga de inmediato
-- global_env.FPE_Loader:add_many({"https://u1.lua", "https://u2.lua"}, true)
-- global_env.FPE_Loader:load_all() -- vuelve a intentar cargar todo lo que falte
