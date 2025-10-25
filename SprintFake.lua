do
	local Players = game:GetService("Players")
	local RunService = game:GetService("RunService")
	local LocalPlayer = Players.LocalPlayer

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
			if charActual and charActual:GetAttribute("Running") ~= nil then
				local estadoActual = charActual:GetAttribute("Running")
				charActual:SetAttribute("Running", not estadoActual)
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
