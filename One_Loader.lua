--// LoadOnceManager.lua
-- Coloca este script en StarterPlayerScripts o similar.

-- CONFIGURACIÓN
local urls = {
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
  "https://raw.githubusercontent.com/Clair3169/FPE-S-script/refs/heads/main/Anti_Camera.lua"
}

-- NOMBRE DE LA MARCA PARA RECORDAR QUE YA SE EJECUTÓ
local flagName = "HasLoadedScriptsOnce"

-- SERVICIOS
local player = game.Players.LocalPlayer
local replicatedStorage = game:GetService("ReplicatedStorage")

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

-- Función para cargar scripts desde URL (solo si no se ha ejecutado antes)
local function loadOnce()
	if hasExecuted() then
		warn("⚠️ El script ya esta cargado.")
		return
	end

	for _, url in ipairs(urls) do
		task.spawn(function()
			local success, response = pcall(function()
				return game:HttpGet(url)
			end)
			if success and response then
				local runSuccess, err = pcall(function()
					loadstring(response)()
				end)
				if not runSuccess then
					warn("❌ Error ejecutando script desde URL:", url, "\n", err)
				else
					-- print("✅ Script cargado exitosamente")
				end
			else
				warn("⚠️ No se pudo obtener el script desde:", url)
			end
		end)
	end

	setExecutedFlag()
end

-- Ejecutar una vez
loadOnce()
