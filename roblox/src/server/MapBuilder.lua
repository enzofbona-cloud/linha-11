local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local MapBuilder = {}

local COLORS = {
	wall = Color3.fromRGB(104, 94, 81),
	wallDark = Color3.fromRGB(65, 61, 55),
	floor = Color3.fromRGB(48, 42, 37),
	wood = Color3.fromRGB(72, 49, 35),
	woodLight = Color3.fromRGB(102, 73, 52),
	metal = Color3.fromRGB(53, 58, 59),
	rust = Color3.fromRGB(84, 50, 36),
	paper = Color3.fromRGB(185, 171, 142),
	fabric = Color3.fromRGB(68, 63, 58),
	light = Color3.fromRGB(255, 184, 101),
	black = Color3.fromRGB(16, 17, 17),
}

local world
local prompts = {}
local doors = {}
local lights = {}
local roomPositions = {}
local levers = {}

local function makePart(parent, name, size, cf, color, material, transparency, canCollide, shape)
	local item = Instance.new("Part")
	item.Name = name
	item.Size = size
	item.CFrame = cf
	item.Anchored = true
	item.CanCollide = canCollide ~= false
	item.CanTouch = false
	item.CanQuery = true
	item.CastShadow = true
	item.TopSurface = Enum.SurfaceType.Smooth
	item.BottomSurface = Enum.SurfaceType.Smooth
	item.Color = color or COLORS.wall
	item.Material = material or Enum.Material.Concrete
	item.Transparency = transparency or 0
	if shape then
		item.Shape = shape
	end
	item.Parent = parent
	return item
end

local function addPrompt(host, actionId, actionText, objectText, hold, distance)
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "Interact_" .. actionId
	prompt.ActionText = actionText
	prompt.ObjectText = objectText
	prompt.KeyboardKeyCode = Enum.KeyCode.E
	prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
	prompt.HoldDuration = hold or 0.25
	prompt.MaxActivationDistance = distance or 9
	prompt.RequiresLineOfSight = false
	prompt.Style = Enum.ProximityPromptStyle.Default
	prompt:SetAttribute("ActionId", actionId)
	prompt.Parent = host
	table.insert(prompts, prompt)
	return prompt
end

local function addText(parent, text, position, size, face, color, fontSize)
	local board = makePart(parent, "Placa", size, CFrame.new(position), color or COLORS.wood, Enum.Material.Wood)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "TextSurface"
	surface.Face = face or Enum.NormalId.Front
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 45
	surface.AlwaysOnTop = false
	surface.Parent = board
	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = Color3.fromRGB(228, 215, 188)
	label.TextStrokeTransparency = 0.75
	label.Font = Enum.Font.Garamond
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = surface
	return board
end

local function makePromptAnchor(parent, name, position, actionId, actionText, objectText, hold, distance)
	local anchor = makePart(parent, name, Vector3.new(1.1, 1.1, 1.1), CFrame.new(position), COLORS.black, Enum.Material.SmoothPlastic, 1, false)
	anchor.CanQuery = false
	addPrompt(anchor, actionId, actionText, objectText, hold, distance)
	return anchor
end

local function addDoor(parent, roomId, x, side, actionId, objectText, initiallyOpen)
	local z = side * 6.22
	local cf = CFrame.new(x, 4.3, z)
	local door = makePart(parent, "Porta_" .. roomId, Vector3.new(5.5, 8.6, 0.42), cf, COLORS.wood, Enum.Material.WoodPlanks)
	local upper = makePart(parent, "Painel_da_porta", Vector3.new(4.85, 3.1, 0.12), cf * CFrame.new(0, 1.55, -0.28), COLORS.woodLight, Enum.Material.Wood)
	local lower = makePart(parent, "Painel_inferior", Vector3.new(4.85, 2.0, 0.12), cf * CFrame.new(0, -2.5, -0.28), COLORS.woodLight, Enum.Material.Wood)
	local knob = makePart(parent, "Macaneta", Vector3.new(0.18, 0.18, 0.3), cf * CFrame.new(2.05, -0.1, -0.32), Color3.fromRGB(147, 112, 67), Enum.Material.Metal, 0, false, Enum.PartType.Ball)
	upper.CanCollide = false
	lower.CanCollide = false
	knob.CanCollide = false
	local prompt = addPrompt(door, actionId, initiallyOpen and "Fechar" or "Abrir", objectText, 0.2, 9)
	doors[roomId] = {
		part = door,
		panels = { upper, lower, knob },
		panelClosedCFrames = { upper.CFrame, lower.CFrame, knob.CFrame },
		prompt = prompt,
		closedCFrame = cf,
		isOpen = initiallyOpen or false,
	}
	if initiallyOpen then
		door.Transparency = 1
		door.CanCollide = false
		for _, p in ipairs({ upper, lower, knob }) do
			p.Transparency = 1
		end
	end
	return door
end

local function addCeilingLight(parent, position, id)
	local fixture = makePart(parent, "Luminaria_" .. id, Vector3.new(2.2, 0.22, 0.75), CFrame.new(position), Color3.fromRGB(44, 40, 35), Enum.Material.Metal)
	local bulb = makePart(parent, "Difusor_" .. id, Vector3.new(1.8, 0.1, 0.48), CFrame.new(position - Vector3.new(0, 0.16, 0)), COLORS.black, Enum.Material.Glass)
	local point = Instance.new("PointLight")
	point.Name = "Luz_" .. id
	point.Color = COLORS.light
	point.Brightness = 0
	point.Range = 22
	point.Shadows = false
	point.Parent = bulb
	table.insert(lights, { light = point, bulb = bulb, fixture = fixture })
end

local function addWallLamp(parent, position, id)
	local base = makePart(parent, "Arandela_" .. id, Vector3.new(0.7, 0.85, 0.35), CFrame.new(position), COLORS.wood, Enum.Material.Wood)
	local glass = makePart(parent, "Vidro_" .. id, Vector3.new(0.42, 0.55, 0.24), CFrame.new(position + Vector3.new(0, 0, -0.2)), COLORS.black, Enum.Material.Glass)
	local point = Instance.new("PointLight")
	point.Name = "LuzParede_" .. id
	point.Color = COLORS.light
	point.Brightness = 0
	point.Range = 12
	point.Shadows = false
	point.Parent = glass
	table.insert(lights, { light = point, bulb = glass, fixture = base })
end

local function addShelf(parent, position, width, id)
	local x, y, z = position.X, position.Y, position.Z
	for _, dx in ipairs({ -width * 0.45, width * 0.45 }) do
		makePart(parent, "Estante_lateral_" .. id, Vector3.new(0.35, 7, 0.55), CFrame.new(x + dx, y + 3.5, z), COLORS.metal, Enum.Material.CorrodedMetal)
	end
	for level = 0, 3 do
		makePart(parent, "Prateleira_" .. id, Vector3.new(width, 0.35, 1.15), CFrame.new(x, y + 0.65 + level * 1.75, z), COLORS.wood, Enum.Material.WoodPlanks)
	end
	for i = 1, 7 do
		local bookHeight = 1.05 + ((i * 7) % 4) * 0.2
		local bookColor = ({ COLORS.paper, COLORS.rust, COLORS.fabric, COLORS.wallDark })[(i % 4) + 1]
		makePart(parent, "Pasta_" .. id, Vector3.new(0.48, bookHeight, 0.82), CFrame.new(x - width * 0.38 + i * 0.85, y + 1.2, z), bookColor, Enum.Material.Fabric)
	end
end

local function addTable(parent, position, width, depth, id, color)
	local top = makePart(parent, "Mesa_" .. id, Vector3.new(width, 0.38, depth), CFrame.new(position + Vector3.new(0, 2.45, 0)), color or COLORS.wood, Enum.Material.WoodPlanks)
	for _, dx in ipairs({ -width * 0.42, width * 0.42 }) do
		for _, dz in ipairs({ -depth * 0.34, depth * 0.34 }) do
			makePart(parent, "Perna_" .. id, Vector3.new(0.28, 2.4, 0.28), CFrame.new(position + Vector3.new(dx, 1.2, dz)), COLORS.woodDark or COLORS.wood, Enum.Material.Wood)
		end
	end
	return top
end

local function addCabinet(parent, position, id, width)
	width = width or 4.4
	local body = makePart(parent, "Armario_" .. id, Vector3.new(width, 5.7, 1.8), CFrame.new(position + Vector3.new(0, 2.85, 0)), COLORS.wood, Enum.Material.WoodPlanks)
	makePart(parent, "Tampo_armario_" .. id, Vector3.new(width + 0.25, 0.2, 2.0), CFrame.new(position + Vector3.new(0, 5.8, 0)), COLORS.woodLight, Enum.Material.Wood)
	makePart(parent, "Divisoria_armario_" .. id, Vector3.new(0.14, 5.3, 1.7), CFrame.new(position + Vector3.new(0, 2.85, 0)), COLORS.woodLight, Enum.Material.Wood)
	for _, dx in ipairs({ -width * 0.25, width * 0.25 }) do
		makePart(parent, "Puxador_" .. id, Vector3.new(0.12, 0.48, 0.18), CFrame.new(position + Vector3.new(dx, 2.75, -0.96)), Color3.fromRGB(143, 110, 73), Enum.Material.Metal, 0, false)
	end
	return body
end

local function addKeyVisual(parent, position, id)
	local gold = Color3.fromRGB(170, 132, 72)
	makePart(parent, "Argola_chave_" .. id, Vector3.new(0.32, 0.16, 0.32), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), gold, Enum.Material.Metal, 0, false, Enum.PartType.Cylinder)
	makePart(parent, "Haste_chave_" .. id, Vector3.new(0.9, 0.14, 0.16), CFrame.new(position + Vector3.new(0.53, 0, 0)), gold, Enum.Material.Metal, 0, false)
	makePart(parent, "Dente_chave_" .. id, Vector3.new(0.13, 0.3, 0.15), CFrame.new(position + Vector3.new(0.82, -0.12, 0)), gold, Enum.Material.Metal, 0, false)
end

local function addFuseVisual(parent, position)
	makePart(parent, "Fusivel_vermelho", Vector3.new(0.36, 1.05, 0.36), CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)), Color3.fromRGB(151, 44, 34), Enum.Material.Metal, 0, false, Enum.PartType.Cylinder)
	makePart(parent, "Contato_fusivel", Vector3.new(0.48, 0.12, 0.43), CFrame.new(position + Vector3.new(0.55, 0, 0)), Color3.fromRGB(166, 139, 91), Enum.Material.Metal, 0, false)
end

local function addCrowbarVisual(parent, position)
	local rust = Color3.fromRGB(97, 57, 39)
	makePart(parent, "Pe_de_cabra_haste", Vector3.new(2.2, 0.22, 0.22), CFrame.new(position), rust, Enum.Material.CorrodedMetal, 0, false)
	makePart(parent, "Pe_de_cabra_ponta", Vector3.new(0.22, 0.85, 0.22), CFrame.new(position + Vector3.new(1.0, 0.37, 0)), rust, Enum.Material.CorrodedMetal, 0, false)
	makePart(parent, "Pe_de_cabra_gancho", Vector3.new(0.68, 0.18, 0.18), CFrame.new(position + Vector3.new(1.3, 0.75, 0)), rust, Enum.Material.CorrodedMetal, 0, false)
end

local function addTapeVisual(parent, position)
	local reelColor = Color3.fromRGB(42, 39, 34)
	for _, offset in ipairs({ -0.62, 0.62 }) do
		local reel = makePart(parent, "Carretel_da_fita", Vector3.new(0.18, 1.18, 1.18), CFrame.new(position + Vector3.new(offset, 0, 0)) * CFrame.Angles(0, 0, math.rad(90)), reelColor, Enum.Material.Metal, 0, false, Enum.PartType.Cylinder)
		makePart(parent, "Cubo_do_carretel", Vector3.new(0.38, 0.2, 0.38), reel.CFrame, Color3.fromRGB(132, 105, 72), Enum.Material.Metal, 0, false, Enum.PartType.Cylinder)
	end
	makePart(parent, "Fita_entre_carretel", Vector3.new(0.8, 0.08, 0.22), CFrame.new(position + Vector3.new(0, -0.08, -0.3)), COLORS.black, Enum.Material.SmoothPlastic, 0, false)
	makePart(parent, "Etiqueta_fita_11", Vector3.new(0.85, 0.06, 0.5), CFrame.new(position + Vector3.new(0, 0.14, 0.58)), COLORS.paper, Enum.Material.Cardboard, 0, false)
end

local function addLever(parent, actionId, position)
	local base = makePart(parent, "Base_" .. actionId, Vector3.new(1.5, 1.7, 0.55), CFrame.new(position + Vector3.new(0, 0.9, 0)), COLORS.metal, Enum.Material.Metal)
	makePart(parent, "Placa_" .. actionId, Vector3.new(1.15, 0.2, 0.1), base.CFrame * CFrame.new(0, 0.42, -0.33), COLORS.rust, Enum.Material.Metal, 0, false)
	local handle = makePart(parent, "Haste_" .. actionId, Vector3.new(0.22, 1.65, 0.24), base.CFrame * CFrame.new(0, 1.35, -0.08) * CFrame.Angles(0, 0, math.rad(25)), Color3.fromRGB(122, 84, 52), Enum.Material.Metal, 0, false)
	local grip = makePart(parent, "Puxador_" .. actionId, Vector3.new(0.42, 0.38, 0.42), handle.CFrame * CFrame.new(0, 0.82, 0), COLORS.black, Enum.Material.Rubber, 0, false, Enum.PartType.Ball)
	addPrompt(base, actionId, "Puxar", actionId == "RelayA" and "Alavanca A" or "Alavanca B", 0.8, 8)
	levers[actionId] = {
		handle = handle,
		grip = grip,
		baseCFrame = base.CFrame,
		initial = handle.CFrame,
	}
end

local function addHideCloset(parent, roomId, position)
	local body = makePart(parent, "Guarda_roupa_" .. roomId, Vector3.new(4.3, 8.7, 2.2), CFrame.new(position + Vector3.new(0, 4.35, 0)), COLORS.wood, Enum.Material.WoodPlanks)
	for _, dx in ipairs({ -1.05, 1.05 }) do
		makePart(parent, "Porta_guarda_roupa_" .. roomId, Vector3.new(2.0, 8.3, 0.12), CFrame.new(position + Vector3.new(dx, 4.35, -1.16)), COLORS.woodLight, Enum.Material.Wood)
		makePart(parent, "Puxador_guarda_roupa_" .. roomId, Vector3.new(0.1, 0.55, 0.12), CFrame.new(position + Vector3.new(dx + (dx < 0 and 0.7 or -0.7), 4.3, -1.28)), Color3.fromRGB(143, 110, 73), Enum.Material.Metal, 0, false)
	end
	makePromptAnchor(parent, "Esconderijo_" .. roomId, position + Vector3.new(0, 3.4, -2.1), "Hide_" .. roomId, "Esconder-se", "Guarda-roupa", 0.35, 8)
	return body
end

local function addRoomShell(parent, roomId, centerX, side, title, doorInitiallyOpen)
	local room = Instance.new("Model")
	room.Name = "Apartamento_" .. roomId
	room.Parent = parent
	local centerZ = side * 15.5
	roomPositions[roomId] = Vector3.new(centerX, 1, centerZ)
	makePart(room, "Piso_" .. roomId, Vector3.new(20, 0.45, 19), CFrame.new(centerX, 0.02, centerZ), COLORS.floor, Enum.Material.WoodPlanks)
	makePart(room, "Teto_" .. roomId, Vector3.new(20, 0.5, 19), CFrame.new(centerX, 11.9, centerZ), COLORS.wallDark, Enum.Material.Concrete)
	makePart(room, "Parede_esquerda_" .. roomId, Vector3.new(0.55, 12, 19), CFrame.new(centerX - 10, 6, centerZ), COLORS.wall, Enum.Material.Plaster)
	makePart(room, "Parede_direita_" .. roomId, Vector3.new(0.55, 12, 19), CFrame.new(centerX + 10, 6, centerZ), COLORS.wall, Enum.Material.Plaster)
	makePart(room, "Parede_fundo_" .. roomId, Vector3.new(20, 12, 0.55), CFrame.new(centerX, 6, side * 25), COLORS.wall, Enum.Material.Plaster)
	makePart(room, "Parede_frontal_esq_" .. roomId, Vector3.new(7.2, 12, 0.55), CFrame.new(centerX - 6.4, 6, side * 6.35), COLORS.wall, Enum.Material.Plaster)
	makePart(room, "Parede_frontal_dir_" .. roomId, Vector3.new(7.2, 12, 0.55), CFrame.new(centerX + 6.4, 6, side * 6.35), COLORS.wall, Enum.Material.Plaster)
	local door = addDoor(room, roomId, centerX, side, "Door_" .. roomId, title, doorInitiallyOpen)
	local signZ = side * 5.55
	addText(room, title, Vector3.new(centerX, 9.35, signZ), Vector3.new(4.5, 1.2, 0.18), side < 0 and Enum.NormalId.Back or Enum.NormalId.Front, COLORS.wood)
	addCeilingLight(room, Vector3.new(centerX, 11.45, centerZ), "Apt_" .. roomId)
	addHideCloset(room, roomId, Vector3.new(centerX + 7, 0.3, centerZ + side * -4))
	return room, door, centerZ
end

local function addNote(parent, id, title, body, position, actionId)
	local paper = makePart(parent, "Documento_" .. id, Vector3.new(2.8, 0.12, 2.0), CFrame.new(position), COLORS.paper, Enum.Material.Cardboard)
	local surface = Instance.new("SurfaceGui")
	surface.Name = "DocumentoLegivel"
	surface.Face = Enum.NormalId.Top
	surface.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	surface.PixelsPerStud = 80
	surface.Parent = paper
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(194, 180, 150)
	label.BackgroundTransparency = 0.05
	label.TextColor3 = Color3.fromRGB(34, 28, 22)
	label.Font = Enum.Font.Garamond
	label.TextScaled = true
	label.TextWrapped = true
	label.Text = title .. "\n" .. body
	label.Parent = surface
	makePromptAnchor(parent, "Ler_" .. id, position + Vector3.new(0, 1, 0), actionId, "Ler", title, 0.25, 8)
	return paper
end

local function roomFurniture(parent, roomId, centerX, side, centerZ)
	local front = side * 1
	local function pos(dx, dz)
		return Vector3.new(centerX + dx, 0.25, centerZ + dz * front)
	end
	if roomId == "301" then
		addShelf(parent, pos(-6.2, -4.5), 7.2, "301")
		addCabinet(parent, pos(5.5, -5), "301")
		addTable(parent, pos(-1, 3.2), 5.2, 3.1, "301")
		addNote(parent, "Clue7", "ANOTAÇÃO • 304", "7 — A linha continuou tocando.", pos(-1, 3.2) + Vector3.new(0, 2.8, 0), "Clue7")
		local drawerPosition = pos(5.5, -5) + Vector3.new(0, 2.2, -1.15)
		makePart(parent, "Frente_gaveta_fusivel", Vector3.new(3.5, 1.0, 0.22), CFrame.new(drawerPosition), COLORS.woodLight, Enum.Material.WoodPlanks)
		makePart(parent, "Fechadura_gaveta", Vector3.new(0.22, 0.3, 0.1), CFrame.new(drawerPosition + Vector3.new(0, 0.05, -0.18)), Color3.fromRGB(144, 112, 71), Enum.Material.Metal, 0, false)
		addFuseVisual(parent, drawerPosition + Vector3.new(0, 1.05, -0.7))
		makePromptAnchor(parent, "Gaveta_trancada", drawerPosition + Vector3.new(0, 1.1, -1.1), "FuseDrawer", "Abrir gaveta", "Gaveta trancada", 1.1, 8)
	elseif roomId == "302" then
		addCabinet(parent, pos(-6.5, -5), "302-A", 5)
		addTable(parent, pos(1.5, 2.8), 5.3, 3.4, "302")
		addShelf(parent, pos(6.1, 3.4), 4.6, "302")
		addNote(parent, "Clue03", "REGISTRO • 03", "03 — O ECO transmitiu às 03:17.", pos(1.5, 2.8) + Vector3.new(0, 2.8, 0), "Clue03")
	elseif roomId == "305" then
		addCabinet(parent, pos(-6.5, -4.8), "305", 5.2)
		addShelf(parent, pos(6.1, -4), 5.4, "305")
		addTable(parent, pos(-1.4, 3.2), 5.4, 3.1, "305")
		addNote(parent, "Clue1", "RECIBO • 1", "1 — Uma fita saiu do arquivo.", pos(-1.4, 3.2) + Vector3.new(0, 2.8, 0), "Clue1")
		local keyPosition = pos(-0.5, 3.2) + Vector3.new(0, 2.75, 0)
		addKeyVisual(parent, keyPosition, "Manutencao")
		makePromptAnchor(parent, "Chave_manutenção", keyPosition + Vector3.new(0, 0.6, 0), "StorageKey", "Pegar", "Chave do armário", 0.35, 8)
		local washer = makePart(parent, "Lavadora_305", Vector3.new(3.1, 4.6, 3.0), CFrame.new(pos(-6.2, 4.1) + Vector3.new(0, 2.3, 0)), Color3.fromRGB(86, 91, 91), Enum.Material.Metal)
		makePart(parent, "Visor_lavadora", Vector3.new(1.65, 1.65, 0.12), washer.CFrame * CFrame.new(0, 0.2, -1.58), COLORS.black, Enum.Material.Glass, 0.08, false)
	elseif roomId == "303" then
		addShelf(parent, pos(-6.2, -4.2), 7.2, "ArquivoA")
		addShelf(parent, pos(6.2, -4.2), 7.2, "ArquivoB")
		addTable(parent, pos(0, 3.6), 6.8, 3.6, "Arquivo")
		addTapeVisual(parent, pos(0, 3.6) + Vector3.new(0, 2.73, 0))
		addNote(parent, "ArquivoVazio", "CAIXA 11", "A etiqueta foi arrancada. A fita está no fundo.", pos(0, 3.6) + Vector3.new(0, 2.8, 0), "ArchiveTape")
		makePromptAnchor(parent, "Painel_codigo", Vector3.new(36, 4, side * 6.8), "Keypad", "Digitar senha", "Teclado do arquivo", 0.25, 8)
	elseif roomId == "304" then
		local sofa = makePart(parent, "Sofá_304", Vector3.new(7.4, 2.2, 2.7), CFrame.new(pos(-5.2, -3.5) + Vector3.new(0, 1.3, 0)), COLORS.fabric, Enum.Material.Fabric)
		makePart(parent, "Encosto_sofa", Vector3.new(7.4, 2.7, 0.65), sofa.CFrame * CFrame.new(0, 1.55, 0.95), Color3.fromRGB(58, 52, 47), Enum.Material.Fabric)
		addTable(parent, pos(4.2, -3.2), 3.4, 2.5, "Telefone")
		makePart(parent, "Telefone_antigo", Vector3.new(1.4, 0.55, 0.9), CFrame.new(pos(4.2, -3.2) + Vector3.new(0, 2.95, 0)), COLORS.black, Enum.Material.SmoothPlastic)
		makePromptAnchor(parent, "Telefone", pos(4.2, -3.2) + Vector3.new(0, 3.5, 0), "Phone", "Atender", "Telefone sem linha", 0.8, 8)
		makePart(parent, "Aparador_televisao", Vector3.new(5.8, 1.5, 2.4), CFrame.new(centerX + 7.2, 1.1, centerZ + 1.3), COLORS.wood, Enum.Material.WoodPlanks)
		local tvCFrame = CFrame.new(centerX + 8.5, 5.0, centerZ + 1.3) * CFrame.Angles(0, math.rad(90), 0)
		makePart(parent, "Televisao_CRT", Vector3.new(4.6, 3.5, 0.9), tvCFrame, COLORS.black, Enum.Material.SmoothPlastic)
		local tvScreen = makePart(parent, "Tela_CRT", Vector3.new(3.8, 2.75, 0.08), tvCFrame * CFrame.new(0, 0, -0.5), Color3.fromRGB(37, 45, 49), Enum.Material.Glass, 0.08, false)
		local tvGui = Instance.new("SurfaceGui")
		tvGui.Name = "Imagem_do_tubo"
		tvGui.Face = Enum.NormalId.Front
		tvGui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		tvGui.PixelsPerStud = 55
		tvGui.Parent = tvScreen
		local tvText = Instance.new("TextLabel")
		tvText.Size = UDim2.fromScale(1, 1)
		tvText.BackgroundColor3 = Color3.fromRGB(24, 32, 35)
		tvText.BackgroundTransparency = 0
		tvText.Text = "03:17\\nSEM SINAL"
		tvText.TextColor3 = Color3.fromRGB(161, 177, 180)
		tvText.Font = Enum.Font.Code
		tvText.TextScaled = true
		tvText.TextWrapped = true
		tvText.Parent = tvGui
		local tvGlow = Instance.new("PointLight")
		tvGlow.Color = Color3.fromRGB(125, 163, 176)
		tvGlow.Brightness = 0.45
		tvGlow.Range = 8
		tvGlow.Shadows = false
		tvGlow.Parent = tvScreen
		addCabinet(parent, pos(5.8, 4), "304", 3.4)
		local crowbarPosition = pos(2.5, -1.5) + Vector3.new(0, 0.11, 0)
		addCrowbarVisual(parent, crowbarPosition)
		makePromptAnchor(parent, "Pe_de_cabra", crowbarPosition + Vector3.new(0, 0.8, 0), "Crowbar", "Pegar", "Pé de cabra", 0.4, 8)
		addNote(parent, "Foto304", "FOTOGRAFIA", "Uma turma diante do prédio. Onze rostos foram riscados.", pos(-5.2, -3.5) + Vector3.new(0, 2.8, 0), "Photo304")
	else
		addTable(parent, pos(-2.5, 2.5), 6, 3, "Zeladoria")
		addShelf(parent, pos(6, -4), 6, "Zeladoria")
		addCabinet(parent, pos(-6.7, -4), "Zeladoria", 4)
		addNote(parent, "LogPlantao", "LIVRO DO PLANTÃO", "A ordem veio da prefeitura. O circuito 11 não aparece na planta.", pos(-2.5, 2.5) + Vector3.new(0, 2.8, 0), "LogPlantao")
	end
end

local function addRoomWallDetails(parent, centerX, side, roomId, centerZ)
	local frontSurfaceZ = side * 6.05
	addWallLamp(parent, Vector3.new(centerX - 7.6, 8.3, frontSurfaceZ), "Corredor_" .. roomId)
	local trimY = 0.9
	makePart(parent, "Rodape_esquerdo_" .. roomId, Vector3.new(7.2, 0.3, 0.18), CFrame.new(centerX - 6.4, trimY, side * 6.0), COLORS.wood, Enum.Material.Wood)
	makePart(parent, "Rodape_direito_" .. roomId, Vector3.new(7.2, 0.3, 0.18), CFrame.new(centerX + 6.4, trimY, side * 6.0), COLORS.wood, Enum.Material.Wood)
	makePart(parent, "Moldura_superior_" .. roomId, Vector3.new(19.1, 0.25, 0.2), CFrame.new(centerX, 11.2, side * 6.0), COLORS.wallDark, Enum.Material.Wood)
end

local function buildWorld()
	local previous = workspace:FindFirstChild("Linha11World")
	if previous then
		previous:Destroy()
	end
	world = Instance.new("Model")
	world.Name = "Linha11World"
	world.Parent = workspace

	prompts = {}
	doors = {}
	lights = {}
	roomPositions = {}
	levers = {}

	Lighting.ClockTime = 0.15
	Lighting.Brightness = 0.8
	Lighting.Ambient = Color3.fromRGB(29, 30, 32)
	Lighting.OutdoorAmbient = Color3.fromRGB(16, 17, 19)
	Lighting.FogColor = Color3.fromRGB(24, 26, 29)
	Lighting.FogStart = 24
	Lighting.FogEnd = 135
	Lighting.EnvironmentDiffuseScale = 0.25
	Lighting.EnvironmentSpecularScale = 0.2
	local atmosphere = Lighting:FindFirstChild("Linha11Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Name = "Linha11Atmosphere"
	atmosphere.Color = Color3.fromRGB(126, 133, 145)
	atmosphere.Decay = Color3.fromRGB(47, 48, 53)
	atmosphere.Density = 0.28
	atmosphere.Glare = 0
	atmosphere.Haze = 1.2
	atmosphere.Parent = Lighting
	local colorGrade = Lighting:FindFirstChild("Linha11ColorGrade") or Instance.new("ColorCorrectionEffect")
	colorGrade.Name = "Linha11ColorGrade"
	colorGrade.Brightness = -0.04
	colorGrade.Contrast = 0.12
	colorGrade.Saturation = -0.18
	colorGrade.TintColor = Color3.fromRGB(210, 202, 187)
	colorGrade.Parent = Lighting

	makePart(world, "Laje_do_andar", Vector3.new(120, 0.6, 52), CFrame.new(0, -0.72, 0), COLORS.floor, Enum.Material.Concrete)
	makePart(world, "Piso_do_corredor", Vector3.new(120, 0.6, 12), CFrame.new(0, -0.35, 0), COLORS.floor, Enum.Material.WoodPlanks)
	makePart(world, "Teto_do_corredor", Vector3.new(120, 0.6, 12), CFrame.new(0, 12.2, 0), COLORS.wallDark, Enum.Material.Concrete)
	makePart(world, "Parede_externa_norte", Vector3.new(120, 16, 0.8), CFrame.new(0, 7.5, -26.5), COLORS.wallDark, Enum.Material.Concrete)
	makePart(world, "Parede_externa_sul", Vector3.new(120, 16, 0.8), CFrame.new(0, 7.5, 26.5), COLORS.wallDark, Enum.Material.Concrete)
	makePart(world, "Limite_oeste", Vector3.new(0.8, 16, 54), CFrame.new(-60.5, 7.5, 0), COLORS.wallDark, Enum.Material.Concrete)
	makePart(world, "Limite_leste", Vector3.new(0.8, 16, 54), CFrame.new(60.5, 7.5, 0), COLORS.wallDark, Enum.Material.Concrete)
	local doorsNorth = { -36, -12, 12, 36 }
	local doorsSouth = { -36, 12, 48 }
	for _, side in ipairs({ -1, 1 }) do
		local centers = side < 0 and doorsNorth or doorsSouth
		local cursor = -60
		for _, x in ipairs(centers) do
			local leftEdge = x - 3
			if leftEdge > cursor then
				makePart(world, "Parede_corredor", Vector3.new(leftEdge - cursor, 12, 0.55), CFrame.new((leftEdge + cursor) / 2, 6, side * 6), COLORS.wall, Enum.Material.Plaster)
			end
			cursor = x + 3
		end
		if cursor < 60 then
			makePart(world, "Parede_corredor", Vector3.new(60 - cursor, 12, 0.55), CFrame.new((60 + cursor) / 2, 6, side * 6), COLORS.wall, Enum.Material.Plaster)
		end
	end

	for index, x in ipairs({ -47, -31, -15, 1, 17, 33, 49 }) do
		addCeilingLight(world, Vector3.new(x, 11.8, 0), "Hall_" .. index)
	end
	for i, x in ipairs({ -50, -18, 18, 50 }) do
		local indicator = makePart(world, "Sinalização_saida_" .. i, Vector3.new(2.8, 0.9, 0.18), CFrame.new(x, 10.1, -5.55), Color3.fromRGB(58, 44, 35), Enum.Material.Metal)
		addText(world, "DISTRITO 11  •  ANDAR 3", indicator.Position + Vector3.new(0, 0, -0.11), Vector3.new(2.75, 0.84, 0.08), Enum.NormalId.Front, Color3.fromRGB(63, 50, 40))
	end

	local roomData = {
		{ id = "301", x = -36, side = -1, title = "301 • MANUTENÇÃO", open = true },
		{ id = "302", x = -12, side = -1, title = "302 • QUADROS", open = true },
		{ id = "305", x = 12, side = -1, title = "305 • LAVANDERIA", open = true },
		{ id = "303", x = 36, side = -1, title = "303 • ARQUIVO", open = false },
		{ id = "Zeladoria", x = -36, side = 1, title = "ZELADORIA", open = true },
		{ id = "304", x = 12, side = 1, title = "304 • RESIDÊNCIA", open = true },
		{ id = "Repetidor", x = 48, side = 1, title = "SALA DO REPETIDOR", open = false },
	}
	for _, data in ipairs(roomData) do
		if data.id ~= "Repetidor" then
			local room, _, centerZ = addRoomShell(world, data.id, data.x, data.side, data.title, data.open)
			roomFurniture(room, data.id, data.x, data.side, centerZ)
			addRoomWallDetails(world, data.x, data.side, data.id, centerZ)
		else
			local room, _, centerZ = addRoomShell(world, data.id, data.x, data.side, data.title, data.open)
			addCabinet(room, Vector3.new(data.x - 6, 0.3, centerZ - 4), "Repetidor", 5)
			addShelf(room, Vector3.new(data.x + 6, 0.3, centerZ - 4), 5, "Repetidor")
			makePart(room, "Repetidor_ECO", Vector3.new(5.5, 5.5, 3), CFrame.new(data.x, 3.1, centerZ), COLORS.metal, Enum.Material.CorrodedMetal)
			addText(room, "ECO / CIRCUITO 11", Vector3.new(data.x, 6.2, centerZ - 1.65), Vector3.new(4.5, 1.1, 0.12), Enum.NormalId.Front, COLORS.black)
			addLever(room, "RelayA", Vector3.new(data.x - 3.5, 0.3, centerZ + 1))
			addLever(room, "RelayB", Vector3.new(data.x + 3.5, 0.3, centerZ + 1))
			makePromptAnchor(room, "Terminal", Vector3.new(data.x, 3, centerZ + 5), "EndingConsole", "Usar terminal", "Repetidor ECO", 0.5, 8)
			addRoomWallDetails(world, data.x, data.side, data.id, centerZ)
		end
	end

	local maintenance = makePart(world, "Quadro_geral", Vector3.new(2.4, 3.8, 0.5), CFrame.new(0, 3.4, -5.35), COLORS.metal, Enum.Material.CorrodedMetal)
	makePart(world, "Visor_quadro", Vector3.new(1.5, 0.75, 0.12), maintenance.CFrame * CFrame.new(0, 0.5, -0.32), COLORS.black, Enum.Material.Glass)
	makePromptAnchor(world, "Disjuntor", Vector3.new(0, 3.4, -4.5), "Breaker", "Instalar fusível", "Quadro do andar", 0.9, 8)

	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "InicioDoTurno"
	spawn.Size = Vector3.new(5, 0.6, 5)
	spawn.CFrame = CFrame.lookAt(Vector3.new(-53, 0.1, 0), Vector3.new(-48, 0.1, 0))
	spawn.Anchored = true
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = world

	makePart(world, "Porta_de_entrada", Vector3.new(0.5, 10, 12), CFrame.new(-59, 5, 0), COLORS.wood, Enum.Material.Wood)
	addText(world, "DISTRITO 11 • ANDAR 3", Vector3.new(-57.7, 8.2, 0), Vector3.new(0.12, 3.2, 3.8), Enum.NormalId.Right, COLORS.wood)

	return world, spawn
end

function MapBuilder.Build()
	return buildWorld()
end

function MapBuilder.SetPower(enabled)
	for _, record in ipairs(lights) do
		record.light.Brightness = enabled and 1.5 or 0
		record.light.Range = enabled and 22 or 0
		record.bulb.Color = enabled and COLORS.light or COLORS.black
		record.bulb.Material = enabled and Enum.Material.Neon or Enum.Material.Glass
	end
	if world then
		world:SetAttribute("PowerOn", enabled)
	end
end

function MapBuilder.OpenDoor(roomId, open)
	local record = doors[roomId]
	if not record then
		return false
	end
	record.isOpen = open
	record.prompt.ActionText = open and "Fechar" or "Abrir"
	if open then
		record.part.CanCollide = false
	else
		record.part.CanCollide = true
	end
	local target = record.closedCFrame * CFrame.Angles(0, math.rad(open and 82 or 0), 0)
	TweenService:Create(record.part, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target }):Play()
	for index, p in ipairs(record.panels) do
		local panelTarget = record.panelClosedCFrames[index] * CFrame.Angles(0, math.rad(open and 82 or 0), 0)
		TweenService:Create(p, TweenInfo.new(0.35), { CFrame = panelTarget, Transparency = open and 1 or 0 }):Play()
	end
	return true
end

function MapBuilder.SetLever(actionId, enabled)
	local record = levers[actionId]
	if not record then
		return false
	end
	local angle = enabled and math.rad(-30) or math.rad(25)
	local target = record.baseCFrame * CFrame.new(0, 1.35, -0.08) * CFrame.Angles(0, 0, angle)
	TweenService:Create(record.handle, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target }):Play()
	TweenService:Create(record.grip, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { CFrame = target * CFrame.new(0, 0.82, 0) }):Play()
	return true
end

function MapBuilder.GetPrompts()
	return prompts
end

function MapBuilder.GetDoorState(roomId)
	return doors[roomId] and doors[roomId].isOpen or false
end

function MapBuilder.GetWorld()
	return world
end

function MapBuilder.GetRoomPosition(roomId)
	return roomPositions[roomId]
end

function MapBuilder.GetPositionForAction(actionId)
	for _, prompt in ipairs(prompts) do
		if prompt:GetAttribute("ActionId") == actionId and prompt.Parent and prompt.Parent:IsA("BasePart") then
			return prompt.Parent.Position
		end
	end
	return nil
end

return MapBuilder








