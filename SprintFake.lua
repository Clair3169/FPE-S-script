-- LocalScript: Toggle Shift (PC) + Botón móvil para MINIGUEINS_PRO
do
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    if not LocalPlayer then return end

    -- Estado que este script desea imponer
    local desiredRunningState = false
    local attributeWatcherConnection

    -- Asegura el atributo Running en el personaje y vigila cambios externos
    local function ensureAttributeAndWatcher(char)
        if not char then return end

        -- Si no existe, inicia el atributo
        if char:GetAttribute("Running") == nil then
            char:SetAttribute("Running", false)
        end

        -- Desconectar watcher previo si existe
        if attributeWatcherConnection then
            attributeWatcherConnection:Disconnect()
            attributeWatcherConnection = nil
        end

        -- Forzar estado deseado
        if char:GetAttribute("Running") ~= desiredRunningState then
            char:SetAttribute("Running", desiredRunningState)
        end

        -- Vigilar cambios y revertirlos si no coinciden con desiredRunningState
        attributeWatcherConnection = char:GetAttributeChangedSignal("Running"):Connect(function()
            local current = char:GetAttribute("Running")
            if current ~= desiredRunningState then
                char:SetAttribute("Running", desiredRunningState)
            end
        end)
    end

    -- Limpiar watcher cuando el personaje se elimina (respawn)
    local function clearWatcher()
        if attributeWatcherConnection then
            attributeWatcherConnection:Disconnect()
            attributeWatcherConnection = nil
        end
    end

    -- Conectar CharacterAdded / CharacterRemoving para mantener consistencia
    if LocalPlayer.Character then
        ensureAttributeAndWatcher(LocalPlayer.Character)
    end

    LocalPlayer.CharacterAdded:Connect(function(char)
        -- esperar humanoid solo por seguridad
        pcall(function() char:WaitForChild("Humanoid", 5) end)
        ensureAttributeAndWatcher(char)
    end)

    LocalPlayer.CharacterRemoving:Connect(function()
        clearWatcher()
    end)

    -- PC: Toggle con Shift (aplica para cualquier jugador local)
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
            local char = LocalPlayer.Character
            if char then
                desiredRunningState = not desiredRunningState
                char:SetAttribute("Running", desiredRunningState)
            end
        end
    end)

    -- ---------------------------------------------------------------------
    -- MÓVIL: resto del código solo para jugador específico
    -- ---------------------------------------------------------------------
    if LocalPlayer.Name ~= "MINIGUEINS_PRO" then
        return
    end

    local CARPETAS_VALIDAS = {
        ["Alices"] = true,
        ["Teachers"] = true,
        ["Students"] = true
    }

    local PlayerGui = LocalPlayer:WaitForChild("PlayerGui", 10)
    if not PlayerGui then
        return
    end

    local GameUI = PlayerGui:WaitForChild("GameUI", 5)
    local Mobile = GameUI and GameUI:WaitForChild("Mobile", 5)
    local SprintOriginal = Mobile and Mobile:WaitForChild("Sprint", 5)

    if not SprintOriginal then
        return
    end

    SprintOriginal.Visible = false

    local SprintInf = Mobile:FindFirstChild("SprintInf")
    if not SprintInf then
        SprintInf = SprintOriginal:Clone()
        SprintInf.Name = "SprintInf"
        SprintInf.Parent = Mobile

        SprintInf.MouseButton1Click:Connect(function()
            local charActual = LocalPlayer.Character
            if charActual then
                desiredRunningState = not desiredRunningState
                charActual:SetAttribute("Running", desiredRunningState)
            end
        end)
    end

    SprintInf.Visible = false

    if _G.SprintInfLoopConnection then
        _G.SprintInfLoopConnection:Disconnect()
    end

    _G.SprintInfLoopConnection = RunService.RenderStepped:Connect(function()
        if SprintOriginal.Visible then
            SprintOriginal.Visible = false
        end

        local char = LocalPlayer.Character
        local estaEnCarpetaValida = false

        if char then
            local parent = char.Parent
            if parent and CARPETAS_VALIDAS[parent.Name] then
                estaEnCarpetaValida = true
            end
        end

        SprintInf.Visible = estaEnCarpetaValida
    end)
end
