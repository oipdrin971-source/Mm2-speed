--========================================================--
--                SERVIÇOS E REFERÊNCIAS                  --
--========================================================--

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

--========================================================--
--                   VARIÁVEIS GERAIS                     --
--========================================================--

local animator
local animationBlocked = false
local animConnection

--========================================================--
--      SISTEMA 1 → BLOQUEAR ANIMAÇÕES + GUI DRAG         --
--========================================================--

local gui = Instance.new("ScreenGui")
gui.Name = "AnimationBlockerGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(120, 40)
frame.Position = UDim2.fromScale(0.4, 0.4)
frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
frame.BorderSizePixel = 0
frame.Active = true
frame.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = frame

local button = Instance.new("TextButton")
button.Size = UDim2.fromScale(1, 1)
button.BackgroundTransparency = 1
button.Text = "OFF"
button.TextScaled = true
button.Font = Enum.Font.GothamBold
button.TextColor3 = Color3.fromRGB(255, 60, 60)
button.Parent = frame

-- DRAG
local dragging = false
local dragStart, startPos

button.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)

button.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

UIS.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(
			startPos.X.Scale,
			startPos.X.Offset + delta.X,
			startPos.Y.Scale,
			startPos.Y.Offset + delta.Y
		)
	end
end)

-- Função que ativa e desativa o bloqueio
local function enableBlock()
	animationBlocked = true
	button.Text = "ON"
	button.TextColor3 = Color3.fromRGB(80, 255, 80)

	if animator then
		if animConnection then animConnection:Disconnect() end
		animConnection = animator.AnimationPlayed:Connect(function(track)
			if track.Priority == Enum.AnimationPriority.Action then
				track:Stop()
			end
		end)
	end
end

local function disableBlock()
	animationBlocked = false
	button.Text = "OFF"
	button.TextColor3 = Color3.fromRGB(255, 60, 60)

	if animConnection then
		animConnection:Disconnect()
		animConnection = nil
	end
end

button.MouseButton1Click:Connect(function()
	if animationBlocked then disableBlock() else enableBlock() end
end)

--========================================================--
--   SETUP DO PERSONAGEM PARA SISTEMAS (RESPAWN SAFE)     --
--========================================================--

local holdingS = false
local holdingAorD = false
local boostForce = 170

local speedBoost = 220
local speedSistemaAtivo = false
local impulsoAtivo = true

local baseWalkSpeed = 16
local boostPower = 50
local cooldown = 0
local lastTick = 0

local function setupCharacter(char)
	local humanoid = char:WaitForChild("Humanoid")
	local hrp = char:WaitForChild("HumanoidRootPart")

	-- Atualiza base walkspeed
	baseWalkSpeed = humanoid.WalkSpeed

	-- Reativa speed system
	if speedSistemaAtivo then
		humanoid.WalkSpeed = baseWalkSpeed + speedBoost
	end

	-- Reativa bloqueio de animação
	animator = humanoid:WaitForChild("Animator")

	if animationBlocked then
		if animConnection then animConnection:Disconnect() end
		animConnection = animator.AnimationPlayed:Connect(function(track)
			if track.Priority == Enum.AnimationPriority.Action then
				track:Stop()
			end
		end)
	end

	-- FUNÇÃO DO PULO INCLINADO
	local function isInclined()
		return hrp.CFrame.UpVector.Y < 0.7
	end

	humanoid.Jumping:Connect(function()
		if isInclined() and holdingS and holdingAorD then
			hrp.AssemblyLinearVelocity = Vector3.new(0,0,0)
			hrp.AssemblyLinearVelocity += Vector3.new(0, boostForce, 0)
		end
	end)

	-- Speed boost ao pular (do 3º script)
	humanoid.StateChanged:Connect(function(_, new)
		if speedSistemaAtivo then
			if new == Enum.HumanoidStateType.Jumping then
				humanoid.WalkSpeed = baseWalkSpeed + speedBoost
			elseif new == Enum.HumanoidStateType.Landed then
				humanoid.WalkSpeed = baseWalkSpeed
			end
		end
	end)
end

-- Conecta no respawn
player.CharacterAdded:Connect(setupCharacter)
if player.Character then setupCharacter(player.Character) end

--========================================================--
--        SISTEMA 2 → DETECTAR TECLAS S + A/D             --
--========================================================--

UIS.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.S then holdingS = true end
	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then holdingAorD = true end
end)

UIS.InputEnded:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.S then holdingS = false end
	if input.KeyCode == Enum.KeyCode.A or input.KeyCode == Enum.KeyCode.D then holdingAorD = false end
end)

--========================================================--
--        UI EXTRA (SPEED & IMPULSO)                      --
--========================================================--

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "UnifiedGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local speedButton = Instance.new("TextButton")
speedButton.Size = UDim2.new(0, 140, 0, 50)
speedButton.Position = UDim2.new(0.05, 0, 0.1, 0)
speedButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
speedButton.TextColor3 = Color3.new(1,1,1)
speedButton.Text = "Speed: OFF"
speedButton.Parent = screenGui
speedButton.Active = true
speedButton.Draggable = true

local impulsoButton = Instance.new("TextButton")
impulsoButton.Size = UDim2.new(0, 100, 0, 40)
impulsoButton.Position = UDim2.new(0.05, 0, 0.4, 0)
impulsoButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
impulsoButton.TextColor3 = Color3.new(1,1,1)
impulsoButton.Text = "Impulso: ON"
impulsoButton.Parent = screenGui

local corner2 = Instance.new("UICorner")
corner2.CornerRadius = UDim.new(0, 8)
corner2.Parent = impulsoButton

-- Atualiza botões
local function atualizarSpeedButton()
	if speedSistemaAtivo then
		speedButton.Text = "Speed: ON"
		speedButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
	else
		speedButton.Text = "Speed: OFF"
		speedButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
	end
end

local function atualizarImpulsoButton()
	if impulsoAtivo then
		impulsoButton.Text = "Impulso: ON"
		impulsoButton.BackgroundColor3 = Color3.fromRGB(0, 255, 100)
	else
		impulsoButton.Text = "Impulso: OFF"
		impulsoButton.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	end
end

-- BOTÕES
speedButton.MouseButton1Click:Connect(function()
	speedSistemaAtivo = not speedSistemaAtivo
	atualizarSpeedButton()
end)

impulsoButton.MouseButton1Click:Connect(function()
	impulsoAtivo = not impulsoAtivo
	atualizarImpulsoButton()
end)

--========================================================--
--   SISTEMA 3 → IMPULSO DIRECIONAL (NO AR)               --
--========================================================--

local function applyBoost(dir)
	if not impulsoAtivo then return end

	local char = player.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end

	local hrp = char.HumanoidRootPart
	local force = Vector3.new(dir.X, 0, dir.Z).Unit * boostPower
	hrp.Velocity = hrp.Velocity + force
end

UIS.InputBegan:Connect(function(input)
	if not impulsoAtivo then return end
	if tick() - lastTick < cooldown then return end

	local hum = player.Character and player.Character:FindFirstChild("Humanoid")
	if not hum then return end

	local noAr = (
		hum.FloorMaterial == Enum.Material.Air or
		hum:GetState() == Enum.HumanoidStateType.Freefall or
		hum:GetState() == Enum.HumanoidStateType.Jumping
	)

	if not noAr then return end

	local camCF = camera.CFrame

	if input.KeyCode == Enum.KeyCode.A then
		applyBoost(-camCF.RightVector)
		lastTick = tick()
	elseif input.KeyCode == Enum.KeyCode.D then
		applyBoost(camCF.RightVector)
		lastTick = tick()
	elseif input.KeyCode == Enum.KeyCode.S then
		applyBoost(-camCF.LookVector)
		lastTick = tick()
	end
end)

-- Atualiza UI inicial
atualizarSpeedButton()
atualizarImpulsoButton()
