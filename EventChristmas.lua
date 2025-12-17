local Workspace = game:GetService("Workspace")

-- CONFIGURACIÓN VISUAL
local CARPETA_OBJETIVO = "EventPresents"
local NOMBRE_CARPETA_CACHE = "EventoHighlightsCache" -- Nombre para la carpeta física de los efectos
local COLOR_BORDE = Color3.fromRGB(0, 255, 127) -- Verde brillante

-- PREPARACIÓN: Crear carpeta física para guardar los Highlights ordenadamente
local carpetaCache = Workspace:FindFirstChild(NOMBRE_CARPETA_CACHE) or Instance.new("Folder")
carpetaCache.Name = NOMBRE_CARPETA_CACHE
carpetaCache.Parent = Workspace

-- SISTEMA DE MEMORIA (Caché lógica)
-- Relaciona [Objeto Real] = [Instance Highlight]
local memoriaHighlights = {}
local carpetaEventos = Workspace:WaitForChild(CARPETA_OBJETIVO)

-------------------------------------------------------------------------
-- FUNCIONES DEL NÚCLEO
-------------------------------------------------------------------------

local function crearHighlight(objeto)
	-- Evitar duplicados si el objeto ya tiene efecto
	if memoriaHighlights[objeto] then return end
	
	-- Crear el efecto de resaltado nativo
	local highlight = Instance.new("Highlight")
	highlight.Name = "Highlight_" .. objeto.Name
	
	-- PROPIEDADES VISUALES (El contorno verde)
	highlight.FillTransparency = 1 -- Hacemos transparente el relleno interno
	highlight.OutlineTransparency = 0 -- Hacemos sólido el borde
	highlight.OutlineColor = COLOR_BORDE
	
	-- VISIBILIDAD (Clave para verlo desde lejos)
	-- 'AlwaysOnTop' hace que se renderice sobre todo lo demás, incluso paredes.
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	
	-- SISTEMA DE CACHÉ LIMPIO
	-- Parent: Se guarda físicamente en nuestra carpeta de caché (no ensucia el modelo)
	highlight.Parent = carpetaCache
	-- Adornee: Le dice al motor gráfico a qué objeto debe aplicarle el efecto
	highlight.Adornee = objeto 
	
	-- Registrar en memoria
	memoriaHighlights[objeto] = highlight

	-- RED DE SEGURIDAD NATIVA EXTRA
	-- Si el objeto es destruido (Destroy) sin pasar por ChildRemoved, esto lo atrapa.
	local connection
	connection = objeto.AncestryChanged:Connect(function(_, parent)
		if not parent then
			-- El objeto dejó de existir en el juego
			if connection then connection:Disconnect() end
			if memoriaHighlights[objeto] then
				memoriaHighlights[objeto]:Destroy()
				memoriaHighlights[objeto] = nil
			end
		end
	end)
end

local function eliminarHighlight(objeto)
	-- Si el objeto sale de la carpeta "EventPresents", borramos su efecto.
	if memoriaHighlights[objeto] then
		if memoriaHighlights[objeto].Parent then
			memoriaHighlights[objeto]:Destroy()
		end
		memoriaHighlights[objeto] = nil
	end
end

-------------------------------------------------------------------------
-- CONEXIONES 100% NATIVAS (EVENT-DRIVEN)
-- Cero bucles, máximo rendimiento.
-------------------------------------------------------------------------

-- 1. Detectar entrada (Infinito)
carpetaEventos.ChildAdded:Connect(function(hijo)
	-- 'task.defer' permite que el objeto termine de inicializarse en el motor
	-- antes de aplicarle el efecto, asegurando que funcione en modelos complejos.
	task.defer(function()
		if hijo:IsDescendantOf(Workspace) then
			crearHighlight(hijo)
		end
	end)
end)

-- 2. Detectar salida (Limpieza)
carpetaEventos.ChildRemoved:Connect(function(hijo)
	eliminarHighlight(hijo)
end)

-- 3. Carga inicial (Ejecución única al entrar)
for _, hijo in ipairs(carpetaEventos:GetChildren()) do
	crearHighlight(hijo)
end
