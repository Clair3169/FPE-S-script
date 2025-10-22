local global_env = (type(getgenv) == "function" and getgenv()) or _G

if global_env.FPE_Loader then
    return
end

local Loader = {}
Loader.__index = Loader

local function new_loader()
    local self = setmetatable({}, Loader)

    self.scripts = {
        {name = "Script FPE", url = "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Principal_Loader.lua"}    
    }

    self.loaded_urls = global_env.FPE_loaded_urls or {}
    global_env.FPE_loaded_urls = self.loaded_urls
    
    self.loading_urls = {}

    self.FLAG_NAME = "FPE_SCRIPTS_LOADED_ONCE"
    self.loaded_flag_set = global_env[self.FLAG_NAME] == true

    global_env[self.FLAG_NAME] = true

    self.loaded = false
    return self
end

function Loader:is_url_loaded(url)
    for _, u in ipairs(self.loaded_urls) do
        if u == url then return true end
    end
    return false
end

function Loader:load_url_entry(entry)
    local name, url = entry.name or ("URL: "..tostring(entry.url)), entry.url
    if not url or url == "" then
        return false
    end
    
    if self:is_url_loaded(url) then
        return true
    end

    if self.loading_urls[url] then
        return true
    end

    self.loading_urls[url] = true

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
    end
    
    self.loading_urls[url] = nil

    return ok
end

function Loader:load_all()
    for _, entry in ipairs(self.scripts) do
        task.spawn(self.load_url_entry, self, entry)
    end
    self.loaded = true
end

function Loader:add(url, name, autoload)
    if type(url) ~= "string" or url == "" then
        error("FPE Loader: url inválida en add(url, name, autoload)")
    end
    local entry = {name = name or url, url = url}

    for _, e in ipairs(self.scripts) do
        if e.url == url then
            if autoload then
                task.spawn(self.load_url_entry, self, e)
            end
            return
        end
    end

    table.insert(self.scripts, entry)

    if autoload or self.loaded then
        task.spawn(self.load_url_entry, self, entry)
    end
end

function Loader:add_many(t, autoload)
    if type(t) ~= "table" then return end
    if #t > 0 and type(t[1]) == "string" then
        for _, url in ipairs(t) do
            self:add(url, nil, autoload)
        end
    else
        for _, obj in ipairs(t) do
            if type(obj) == "table" then
                self:add(obj.url or obj[1], obj.name or obj[2], autoload)
            end
        end
    end
end

local instance = new_loader()
global_env.FPE_Loader = instance

instance:load_all()
