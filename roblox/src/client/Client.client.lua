local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContextActionService = game:GetService("ContextActionService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local remote = ReplicatedStorage:WaitForChild("Linha11Remote")

local COLORS = {
	panel = Color3.fromRGB(17, 17, 18),
	panel2 = Color3.fromRGB(30, 29, 27),
	line = Color3.fromRGB(102, 77, 57),
	text = Color3.fromRGB(225, 215, 195),
	muted = Color3.fromRGB(160, 153, 140),
	red = Color3.fromRGB(139, 37, 34),
	gold = Color3.fromRGB(193, 151, 91),
}

local gui = Instance.new("ScreenGui")
gui.Name = "Linha11Interface"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 20
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

local function corner(instance, radius)
	local item = Instance.new("UICorner")
	item.CornerRadius = UDim.new(0, radius or 5)
	item.Parent = instance
	return item
end

local function stroke(instance, color, transparency, thickness)
	local item = Instance.new("UIStroke")
	item.Color = color or COLORS.line
	item.Transparency = transparency or 0
	item.Thickness = thickness or 1
	item.Parent = instance
	return item
end

local function label(parent, name, position, size, text, font, textSize, color, align)
	local item = Instance.new("TextLabel")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundTransparency = 1
	item.Text = text or ""
	item.TextColor3 = color or COLORS.text
	item.Font = font or Enum.Font.Garamond
	item.TextSize = textSize or 20
	item.TextWrapped = true
	item.TextXAlignment = align or Enum.TextXAlignment.Left
	item.TextYAlignment = Enum.TextYAlignment.Center
	item.Parent = parent
	return item
end

local function button(parent, name, position, size, text, primary)
	local item = Instance.new("TextButton")
	item.Name = name
	item.Position = position
	item.Size = size
	item.BackgroundColor3 = primary and COLORS.red or COLORS.panel2
	item.BorderSizePixel = 0
	item.AutoButtonColor = true
	item.Text = text
	item.TextColor3 = COLORS.text
	item.Font = Enum.Font.GothamMedium
	item.TextSize = 16
	item.TextWrapped = true
	item.Parent = parent
	corner(item, 5)
	stroke(item, primary and Color3.fromRGB(174, 68, 58) or COLORS.line, 0.22, 1)
	return item
end

local function panel(name, size, position)
	local item = Instance.new("Frame")
	item.Name = name
	item.Size = size
	item.Position = position
	item.BackgroundColor3 = COLORS.panel
	item.BackgroundTransparency = 0.05
	item.BorderSizePixel = 0
	item.Visible = false
	item.Parent = gui
	corner(item, 7)
	stroke(item, COLORS.line, 0.15, 1)
	return item
end

local overlay = Instance.new("Frame")
overlay.Name = "FundoMenu"
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(8, 8, 9)
overlay.BackgroundTransparency = 0.1
overlay.BorderSizePixel = 0
overlay.Parent = gui
local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(7, 7, 8)),
	ColorSequenceKeypoint.new(0.58, Color3.fromRGB(19, 18, 17)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 6, 7)),
})
gradient.Rotation = 18
gradient.Parent = overlay

local menu = Instance.new("Frame")
menu.Name = "MenuPrincipal"
menu.Size = UDim2.fromScale(1, 1)
menu.BackgroundTransparency = 1
menu.Parent = overlay

local title = label(menu, "Titulo", UDim2.new(0.07, 0, 0.14, 0), UDim2.new(0.7, 0, 0.14, 0), "LINHA 11", Enum.Font.Garamond, 62, COLORS.text)
title.TextXAlignment = Enum.TextXAlignment.Left
local subtitle = label(menu, "Subtitulo", UDim2.new(0.075, 0, 0.27, 0), UDim2.new(0.65, 0, 0.06, 0), "A  Ú L T I M A   C H A M A D A", Enum.Font.Garamond, 19, COLORS.gold)
local teaser = label(menu, "Contexto", UDim2.new(0.075, 0, 0.37, 0), UDim2.new(0.39, 0, 0.16, 0), "Distrito 11 • 02:41\nO prédio será demolido ao amanhecer.\nA central ainda recebe chamadas do circuito 11.\nEntre com um amigo pelo Roblox para jogar em cooperação.", Enum.Font.Garamond, 19, COLORS.muted)
teaser.TextYAlignment = Enum.TextYAlignment.Top

local startButton = button(menu, "Comecar", UDim2.new(0.075, 0, 0.58, 0), UDim2.new(0.28, 0, 0.075, 0), "INICIAR INVESTIGAÇÃO", true)
local shopMenuButton = button(menu, "Cosmeticos", UDim2.new(0.075, 0, 0.67, 0), UDim2.new(0.28, 0, 0.065, 0), "COSMÉTICOS OPCIONAIS", false)
local version = label(menu, "Versao", UDim2.new(0.075, 0, 0.86, 0), UDim2.new(0.34, 0, 0.035, 0), "PROTÓTIPO ROBLOX  •  0.1.0", Enum.Font.Gotham, 12, COLORS.muted)

local controls = Instance.new("Frame")
controls.Name = "Controles"
controls.AnchorPoint = Vector2.new(1, 0.5)
controls.Position = UDim2.new(0.92, 0, 0.66, 0)
controls.Size = UDim2.new(0.26, 0, 0.28, 0)
controls.BackgroundColor3 = COLORS.panel
controls.BackgroundTransparency = 0.23
controls.BorderSizePixel = 0
controls.Parent = menu
corner(controls, 6)
stroke(controls, COLORS.line, 0.45, 1)
label(controls, "ControlTitle", UDim2.new(0.08, 0, 0.07, 0), UDim2.new(0.84, 0, 0.18, 0), "CONTROLES", Enum.Font.GothamMedium, 14, COLORS.gold)
label(controls, "ControlText", UDim2.new(0.08, 0, 0.28, 0), UDim2.new(0.84, 0, 0.66, 0), "WASD  mover\nMouse  olhar\nE  interagir / esconder\nF  lanterna\nShift  correr (faz barulho)\nNo celular: controles Roblox + prompts", Enum.Font.Gotham, 14, COLORS.muted)

local intro = panel("Intro", UDim2.new(0.66, 0, 0.45, 0), UDim2.new(0.17, 0, 0.275, 0))
intro.BackgroundTransparency = 0.02
local introHeader = label(intro, "Cabecalho", UDim2.new(0.07, 0, 0.08, 0), UDim2.new(0.86, 0, 0.12, 0), "ORDEM DE SERVIÇO  •  02:41", Enum.Font.GothamMedium, 14, COLORS.gold)
local introBody = label(intro, "Texto", UDim2.new(0.08, 0, 0.25, 0), UDim2.new(0.84, 0, 0.48, 0), "", Enum.Font.Garamond, 25, COLORS.text)
introBody.TextYAlignment = Enum.TextYAlignment.Center
introBody.TextXAlignment = Enum.TextXAlignment.Center
local introCount = label(intro, "Contador", UDim2.new(0.08, 0, 0.73, 0), UDim2.new(0.84, 0, 0.07, 0), "", Enum.Font.Gotham, 12, COLORS.muted, Enum.TextXAlignment.Center)
local introNext = button(intro, "Continuar", UDim2.new(0.08, 0, 0.83, 0), UDim2.new(0.37, 0, 0.11, 0), "CONTINUAR", true)
local introSkip = button(intro, "Pular", UDim2.new(0.55, 0, 0.83, 0), UDim2.new(0.37, 0, 0.11, 0), "PULAR INTRO", false)

local hud = Instance.new("Frame")
hud.Name = "HUD"
hud.Size = UDim2.new(0.45, 0, 0.14, 0)
hud.Position = UDim2.new(0.035, 0, 0.045, 0)
hud.BackgroundColor3 = COLORS.panel
hud.BackgroundTransparency = 0.18
hud.BorderSizePixel = 0
hud.Visible = false
hud.Parent = gui
corner(hud, 5)
stroke(hud, COLORS.line, 0.48, 1)
local hudTitle = label(hud, "HudTitulo", UDim2.new(0.045, 0, 0.1, 0), UDim2.new(0.8, 0, 0.25, 0), "DISTRITO 11  /  ANDAR 3", Enum.Font.GothamMedium, 13, COLORS.gold)
local objectiveLabel = label(hud, "Objetivo", UDim2.new(0.045, 0, 0.38, 0), UDim2.new(0.9, 0, 0.5, 0), "Entre no terceiro andar.", Enum.Font.Garamond, 19, COLORS.text)

local shopHudButton = button(gui, "LojaHud", UDim2.new(0.86, 0, 0.045, 0), UDim2.new(0.105, 0, 0.055, 0), "APOIAR", false)
shopHudButton.Visible = false
local toast = Instance.new("TextLabel")
toast.Name = "Aviso"
toast.AnchorPoint = Vector2.new(0.5, 0)
toast.Position = UDim2.new(0.5, 0, 0.08, 0)
toast.Size = UDim2.new(0.62, 0, 0.07, 0)
toast.BackgroundColor3 = COLORS.panel
toast.BackgroundTransparency = 0.08
toast.BorderSizePixel = 0
toast.TextColor3 = COLORS.text
toast.Font = Enum.Font.Garamond
toast.TextSize = 21
toast.TextWrapped = true
toast.Visible = false
toast.Parent = gui
corner(toast, 5)
stroke(toast, COLORS.line, 0.35, 1)

local documentPanel = panel("Documento", UDim2.new(0.62, 0, 0.43, 0), UDim2.new(0.19, 0, 0.285, 0))
local docTitle = label(documentPanel, "Titulo", UDim2.new(0.07, 0, 0.08, 0), UDim2.new(0.86, 0, 0.15, 0), "", Enum.Font.Garamond, 25, COLORS.gold)
local docText = label(documentPanel, "Corpo", UDim2.new(0.08, 0, 0.28, 0), UDim2.new(0.84, 0, 0.47, 0), "", Enum.Font.Garamond, 22, COLORS.text)
docText.TextYAlignment = Enum.TextYAlignment.Top
local docClose = button(documentPanel, "Fechar", UDim2.new(0.31, 0, 0.82, 0), UDim2.new(0.38, 0, 0.12, 0), "FECHAR", false)

local keypadPanel = panel("Teclado", UDim2.new(0.37, 0, 0.69, 0), UDim2.new(0.315, 0, 0.155, 0))
label(keypadPanel, "Titulo", UDim2.new(0.08, 0, 0.035, 0), UDim2.new(0.84, 0, 0.09, 0), "ARQUIVO 303", Enum.Font.Garamond, 24, COLORS.gold, Enum.TextXAlignment.Center)
local codeDisplay = label(keypadPanel, "Codigo", UDim2.new(0.1, 0, 0.13, 0), UDim2.new(0.8, 0, 0.1, 0), "— — — —", Enum.Font.GothamMedium, 25, COLORS.text, Enum.TextXAlignment.Center)
local keypadGrid = Instance.new("Frame")
keypadGrid.Name = "Numeros"
keypadGrid.Position = UDim2.new(0.12, 0, 0.27, 0)
keypadGrid.Size = UDim2.new(0.76, 0, 0.56, 0)
keypadGrid.BackgroundTransparency = 1
keypadGrid.Parent = keypadPanel
local grid = Instance.new("UIGridLayout")
grid.CellPadding = UDim2.new(0.035, 0, 0.035, 0)
grid.CellSize = UDim2.new(0.31, 0, 0.21, 0)
grid.FillDirectionMaxCells = 3
grid.SortOrder = Enum.SortOrder.LayoutOrder
grid.Parent = keypadGrid

local codeBuffer = ""
local function formatCode(value)
	if value == "" then
		return "— — — —"
	end
	local spaced = string.gsub(value, ".", "%0 ")
	return string.sub(spaced, 1, #spaced - 1)
end
local flashlightOn = true
local modalActive = false
local playing = false
local menuActive = true
local introLines = {}
local introIndex = 0
local readySent = false
local finalShown = false
local toastToken = 0
local menuCameraCFrame = CFrame.lookAt(Vector3.new(18.6, 6.5, 21.0), Vector3.new(12, 3.7, 7.5))
local menuLightPart

local function showMenuCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	camera.CameraType = Enum.CameraType.Scriptable
	camera.CFrame = menuCameraCFrame
	if not menuLightPart then
		menuLightPart = Instance.new("Part")
		menuLightPart.Name = "Linha11MenuLuzLocal"
		menuLightPart.Size = Vector3.new(0.1, 0.1, 0.1)
		menuLightPart.Transparency = 1
		menuLightPart.Anchored = true
		menuLightPart.CanCollide = false
		menuLightPart.CanTouch = false
		menuLightPart.CanQuery = false
		local light = Instance.new("PointLight")
		light.Color = Color3.fromRGB(255, 205, 151)
		light.Brightness = 1.1
		light.Range = 48
		light.Shadows = false
		light.Parent = menuLightPart
	end
	menuLightPart.CFrame = menuCameraCFrame
	menuLightPart.Parent = camera
end

local function restoreGameplayCamera()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	if menuLightPart then
		menuLightPart.Parent = nil
	end
	camera.CameraType = Enum.CameraType.Custom
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		camera.CameraSubject = humanoid
	end
end

local function setCapture(enabled)
	modalActive = not enabled
	if enabled then
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	else
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	end
end

local function closeOverlays()
	documentPanel.Visible = false
	keypadPanel.Visible = false
	local active = gui:FindFirstChild("LojaRoblox")
	if active then
		active.Visible = false
	end
	local ending = gui:FindFirstChild("Finais")
	if ending then
		ending.Visible = false
	end
	if playing and intro.Visible == false then
		setCapture(true)
	end
end

local function showToast(text, kind)
	toastToken += 1
	local token = toastToken
	toast.Text = text
	toast.TextColor3 = kind == "error" and Color3.fromRGB(238, 142, 131) or kind == "success" and Color3.fromRGB(210, 194, 156) or COLORS.text
	toast.Visible = true
	toast.BackgroundTransparency = 0.08
	task.delay(4.3, function()
		if token == toastToken then
			local fade = TweenService:Create(toast, TweenInfo.new(0.35), { BackgroundTransparency = 1, TextTransparency = 1 })
			fade:Play()
			fade.Completed:Wait()
			if token == toastToken then
				toast.Visible = false
				toast.TextTransparency = 0
			end
		end
	end)
end

local function showDocument(data)
	closeOverlays()
	docTitle.Text = data.title or "REGISTRO"
	docText.Text = data.text or ""
	documentPanel.Visible = true
	setCapture(false)
end

local function ensureFlashlight()
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local holder = camera:FindFirstChild("Linha11Flashlight")
	if not holder then
		holder = Instance.new("Part")
		holder.Name = "Linha11Flashlight"
		holder.Size = Vector3.new(0.1, 0.1, 0.1)
		holder.Transparency = 1
		holder.Anchored = true
		holder.CanCollide = false
		holder.CanTouch = false
		holder.CanQuery = false
		holder.Parent = camera
		local attachment = Instance.new("Attachment")
		attachment.Parent = holder
		local light = Instance.new("SpotLight")
		light.Name = "Facho"
		light.Angle = 57
		light.Range = 36
		light.Brightness = 2.7
		light.Shadows = false
		light.Parent = attachment
	end
	local attachment = holder:FindFirstChildWhichIsA("Attachment")
	local light = attachment and attachment:FindFirstChild("Facho")
	if light then
		light.Enabled = flashlightOn
		light.Color = player:GetAttribute("Linha11AmberLight") == true and Color3.fromRGB(255, 196, 128) or Color3.fromRGB(229, 235, 240)
	end
	return light
end

local function completeIntro()
	if readySent then
		return
	end
	readySent = true
	intro.Visible = false
	playing = true
	menuActive = false
	restoreGameplayCamera()
	flashlightOn = true
	ensureFlashlight()
	hud.Visible = true
	shopHudButton.Visible = true
	setCapture(true)
	remote:FireServer("Ready")
	showToast("Lanterna ligada  •  F para apagar  •  Jogue com um amigo pelo Roblox para cooperar.", "info")
end

local function advanceIntro()
	introIndex += 1
	if introIndex > #introLines then
		completeIntro()
		return
	end
	introBody.Text = introLines[introIndex]
	introCount.Text = string.format("REGISTRO %02d / %02d", introIndex, #introLines)
end

introNext.Activated:Connect(advanceIntro)
introSkip.Activated:Connect(completeIntro)
docClose.Activated:Connect(function()
	documentPanel.Visible = false
	if finalShown then
		finalShown = false
		playing = false
		hud.Visible = false
		shopHudButton.Visible = false
		overlay.Visible = true
		menu.Visible = true
		menuActive = true
		docClose.Text = "FECHAR"
		player.CameraMode = Enum.CameraMode.Classic
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		showMenuCamera()
	elseif playing then
		setCapture(true)
	end
end)

local function openKeypad()
	closeOverlays()
	codeBuffer = ""
	codeDisplay.Text = "— — — —"
	keypadPanel.Visible = true
	setCapture(false)
end

for number = 1, 9 do
	local digit = tostring(number)
	local key = button(keypadGrid, "Tecla" .. digit, UDim2.fromScale(0, 0), UDim2.fromScale(0, 0), digit, false)
	key.LayoutOrder = number
	key.TextSize = 22
	key.Activated:Connect(function()
		if #codeBuffer < 4 then
			codeBuffer ..= digit
			codeDisplay.Text = formatCode(codeBuffer)
		end
	end)
end
local clearKey = button(keypadGrid, "Limpar", UDim2.fromScale(0, 0), UDim2.fromScale(0, 0), "LIMPAR", false)
clearKey.LayoutOrder = 10
clearKey.TextSize = 13
clearKey.Activated:Connect(function()
	codeBuffer = ""
	codeDisplay.Text = "— — — —"
end)
local zeroKey = button(keypadGrid, "Tecla0", UDim2.fromScale(0, 0), UDim2.fromScale(0, 0), "0", false)
zeroKey.LayoutOrder = 11
zeroKey.TextSize = 22
zeroKey.Activated:Connect(function()
	if #codeBuffer < 4 then
		codeBuffer ..= "0"
		codeDisplay.Text = formatCode(codeBuffer)
	end
end)
local enterKey = button(keypadGrid, "Confirmar", UDim2.fromScale(0, 0), UDim2.fromScale(0, 0), "OK", true)
enterKey.LayoutOrder = 12
enterKey.TextSize = 15
enterKey.Activated:Connect(function()
	if #codeBuffer == 4 then
		remote:FireServer("Code", codeBuffer)
		keypadPanel.Visible = false
		setCapture(true)
	end
end)

local function createShop(data)
	local old = gui:FindFirstChild("LojaRoblox")
	if old then
		old:Destroy()
	end
	local shop = panel("LojaRoblox", UDim2.new(0.66, 0, 0.62, 0), UDim2.new(0.17, 0, 0.19, 0))
	shop.Visible = true
	shop.Name = "LojaRoblox"
	label(shop, "Titulo", UDim2.new(0.055, 0, 0.045, 0), UDim2.new(0.75, 0, 0.12, 0), "APOIE O PROJETO", Enum.Font.Garamond, 30, COLORS.gold)
	label(shop, "Aviso", UDim2.new(0.06, 0, 0.17, 0), UDim2.new(0.88, 0, 0.12, 0), "A história, os itens de missão e os dois finais são gratuitos. Estes passes são apenas cosméticos.", Enum.Font.Gotham, 15, COLORS.muted)
	local close = button(shop, "Fechar", UDim2.new(0.83, 0, 0.045, 0), UDim2.new(0.12, 0, 0.09, 0), "FECHAR", false)
	close.Activated:Connect(function()
		shop.Visible = false
		if playing then
			setCapture(true)
		else
			overlay.Visible = true
			setCapture(false)
		end
	end)
	for index, item in ipairs(data.items or {}) do
		local tile = Instance.new("Frame")
		tile.Name = item.key
		tile.Position = UDim2.new(0.06, 0, 0.33 + (index - 1) * 0.29, 0)
		tile.Size = UDim2.new(0.88, 0, 0.24, 0)
		tile.BackgroundColor3 = COLORS.panel2
		tile.BackgroundTransparency = 0.1
		tile.BorderSizePixel = 0
		tile.Parent = shop
		corner(tile, 5)
		stroke(tile, COLORS.line, 0.4, 1)
		label(tile, "Nome", UDim2.new(0.045, 0, 0.08, 0), UDim2.new(0.62, 0, 0.28, 0), item.name, Enum.Font.GothamMedium, 17, COLORS.text)
		label(tile, "Descricao", UDim2.new(0.045, 0, 0.42, 0), UDim2.new(0.61, 0, 0.48, 0), item.description, Enum.Font.Gotham, 13, COLORS.muted)
		local actionText = item.owned and "ADQUIRIDO" or item.enabled and "VER COMPRA" or "EM PREPARAÇÃO"
		local buy = button(tile, "Comprar", UDim2.new(0.7, 0, 0.26, 0), UDim2.new(0.25, 0, 0.48, 0), actionText, item.enabled and not item.owned)
		buy.TextSize = 13
		buy.Activated:Connect(function()
			if item.owned then
				showToast("Você já tem este cosmético.", "info")
			elseif item.enabled then
				remote:FireServer("Purchase", item.key)
			else
				showToast("A compra será ativada quando o jogo estiver publicado no Roblox.", "info")
			end
		end)
	end
	label(shop, "Nota", UDim2.new(0.06, 0, 0.91, 0), UDim2.new(0.88, 0, 0.06, 0), "Sem bônus de velocidade, luz, dano ou acesso à história.", Enum.Font.Gotham, 12, COLORS.muted)
	setCapture(false)
end

local function openEnding(data)
	closeOverlays()
	local ending = gui:FindFirstChild("Finais")
	if ending then
		ending:Destroy()
	end
	ending = panel("Finais", UDim2.new(0.64, 0, 0.58, 0), UDim2.new(0.18, 0, 0.21, 0))
	ending.Visible = true
	label(ending, "Titulo", UDim2.new(0.07, 0, 0.07, 0), UDim2.new(0.86, 0, 0.13, 0), "A ÚLTIMA CHAMADA", Enum.Font.Garamond, 30, COLORS.gold, Enum.TextXAlignment.Center)
	label(ending, "Texto", UDim2.new(0.08, 0, 0.25, 0), UDim2.new(0.84, 0, 0.24, 0), "A gravação está pronta. O que vocês fazem com ela?", Enum.Font.Garamond, 21, COLORS.text, Enum.TextXAlignment.Center)
	local transmit = button(ending, "Transmitir", UDim2.new(0.08, 0, 0.57, 0), UDim2.new(0.39, 0, 0.2, 0), "TRANSMITIR\n" .. (data.transmit or "A verdade"), true)
	local cut = button(ending, "Cortar", UDim2.new(0.53, 0, 0.57, 0), UDim2.new(0.39, 0, 0.2, 0), "CORTAR A LINHA\n" .. (data.cut or "O silêncio"), false)
	transmit.TextSize = 15
	cut.TextSize = 15
	transmit.Activated:Connect(function()
		remote:FireServer("Ending", "Transmit")
		ending.Visible = false
		setCapture(true)
	end)
	cut.Activated:Connect(function()
		remote:FireServer("Ending", "Cut")
		ending.Visible = false
		setCapture(true)
	end)
	setCapture(false)
end

local latestState = nil
local function updateState(state)
	latestState = state
	if state.objective then
		objectiveLabel.Text = string.format("OBJETIVO %02d  •  %s", state.stage or 0, state.objective)
	end
end

remote.OnClientEvent:Connect(function(eventName, data)
	if eventName == "StartGame" then
		menuActive = false
		restoreGameplayCamera()
		overlay.Visible = false
		menu.Visible = false
		playing = false
		readySent = false
		hud.Visible = false
		shopHudButton.Visible = false
		introLines = data.prologue or {}
		introIndex = 0
		intro.Visible = true
		advanceIntro()
	elseif eventName == "MissionState" then
		updateState(data)
	elseif eventName == "Message" then
		showToast(data.text or "", data.kind)
	elseif eventName == "Document" then
		showDocument(data)
	elseif eventName == "OpenKeypad" then
		openKeypad()
	elseif eventName == "Shop" then
		createShop(data)
	elseif eventName == "OpenEnding" then
		openEnding(data)
	elseif eventName == "Ending" then
		closeOverlays()
		finalShown = true
		documentPanel.Visible = true
		docTitle.Text = data.title or "FIM"
		docText.Text = data.text or ""
		docClose.Text = "ENCERRAR TURNO"
		setCapture(false)
	elseif eventName == "Caught" then
		showToast(data.text or "O Ouvinte encontrou você.", "error")
	end
end)

local shopFunction = function()
	if not playing then
		overlay.Visible = false
	end
	remote:FireServer("OpenShop")
end
shopMenuButton.Activated:Connect(shopFunction)
shopHudButton.Activated:Connect(shopFunction)

startButton.Activated:Connect(function()
	remote:FireServer("Start")
end)

local function toggleFlashlight(_, inputState)
	if inputState ~= Enum.UserInputState.Begin or not playing or modalActive then
		return Enum.ContextActionResult.Pass
	end
	flashlightOn = not flashlightOn
	local light = ensureFlashlight()
	if light then
		light.Enabled = flashlightOn
	end
	showToast(flashlightOn and "Lanterna ligada  •  F para apagar" or "Lanterna apagada", "info")
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Linha11Flashlight", toggleFlashlight, true, Enum.KeyCode.F, Enum.KeyCode.ButtonY)
ContextActionService:SetTitle("Linha11Flashlight", "Lanterna")
ContextActionService:SetPosition("Linha11Flashlight", UDim2.new(0.8, 0, 0.55, 0))

local function sprintAction(_, inputState)
	if not playing or modalActive then
		return Enum.ContextActionResult.Pass
	end
	if inputState == Enum.UserInputState.Begin then
		remote:FireServer("Sprint", true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		remote:FireServer("Sprint", false)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("Linha11Sprint", sprintAction, true, Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3)
ContextActionService:SetTitle("Linha11Sprint", "Correr")
ContextActionService:SetPosition("Linha11Sprint", UDim2.new(0.68, 0, 0.68, 0))

RunService:BindToRenderStep("Linha11CameraLight", Enum.RenderPriority.Camera.Value + 1, function()
	local camera = workspace.CurrentCamera
	if not camera then
		return
	end
	local holder = camera:FindFirstChild("Linha11Flashlight")
	if playing and not holder then
		ensureFlashlight()
		holder = camera:FindFirstChild("Linha11Flashlight")
	end
	if holder then
		holder.CFrame = camera.CFrame
		local attachment = holder:FindFirstChildWhichIsA("Attachment")
		local light = attachment and attachment:FindFirstChild("Facho")
		if light then
			light.Enabled = flashlightOn
			light.Color = player:GetAttribute("Linha11AmberLight") == true and Color3.fromRGB(255, 196, 128) or Color3.fromRGB(229, 235, 240)
		end
	end
end)

task.defer(function()
	task.wait(0.8)
	if menuActive then
		showMenuCamera()
	end
end)

local characterAudioConnection

local function softenDefaultFootsteps(character)
	if characterAudioConnection then
		characterAudioConnection:Disconnect()
		characterAudioConnection = nil
	end
	local function silenceFootstep(item)
		if item:IsA("Sound") and (item.Name == "Running" or item.Name == "Walking" or item.Name == "Jumping" or item.Name == "Landing") then
			item.Volume = 0
			item:Stop()
		end
	end
	for _, item in ipairs(character:GetDescendants()) do
		silenceFootstep(item)
	end
	characterAudioConnection = character.DescendantAdded:Connect(silenceFootstep)
end

if player.Character then
	softenDefaultFootsteps(player.Character)
end

player.CharacterAdded:Connect(function(character)
	task.wait(0.4)
	softenDefaultFootsteps(character)
	if playing then
		setCapture(not modalActive)
	end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not keypadPanel.Visible then
		return
	end
	local key = input.KeyCode
	local digits = {
		[Enum.KeyCode.Zero] = "0",
		[Enum.KeyCode.One] = "1",
		[Enum.KeyCode.Two] = "2",
		[Enum.KeyCode.Three] = "3",
		[Enum.KeyCode.Four] = "4",
		[Enum.KeyCode.Five] = "5",
		[Enum.KeyCode.Six] = "6",
		[Enum.KeyCode.Seven] = "7",
		[Enum.KeyCode.Eight] = "8",
		[Enum.KeyCode.Nine] = "9",
	}
	if digits[key] and #codeBuffer < 4 then
		codeBuffer ..= digits[key]
		codeDisplay.Text = formatCode(codeBuffer)
	elseif key == Enum.KeyCode.Backspace then
		codeBuffer = string.sub(codeBuffer, 1, math.max(0, #codeBuffer - 1))
		codeDisplay.Text = #codeBuffer > 0 and formatCode(codeBuffer) or "— — — —"
	elseif key == Enum.KeyCode.Return and #codeBuffer == 4 then
		remote:FireServer("Code", codeBuffer)
		keypadPanel.Visible = false
		setCapture(true)
	end
end)









